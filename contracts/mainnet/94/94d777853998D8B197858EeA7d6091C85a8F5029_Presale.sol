// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

contract Presale {
    struct AIRDROP {
        address user;
        uint256 claimable;
        uint256 claimed;
    }

    address public targetToken;
    address public contributeCoin;

    uint256 private constant RESOLUTION_CV_RATIO = 10 ** 9;
    uint256 public salePrice;

    mapping (address => uint256) public targetTokenRequested;
    mapping (address => uint256) public targetTokenClaimed;
    mapping (address => uint256) public coinContributed;
    uint256 public totalTargetTokenRequested;
    uint256 public totalCoinContributed;

    uint256 public minPerWallet;
    uint256 public maxPerWallet;

    uint256 public totalTargetCap;

    uint256 public startTimestamp;
    uint256 public endTimestamp;

    mapping(address => bool) public isWhitelisted;
    uint256 public saleType;

    address public owner;
    bool private initialized;

    mapping(address => AIRDROP) airdropContext;
    uint256 public totalAirdropClaimable;
    uint256 public claimableStart;
    uint256 public claimableEnd;
    uint256 public totalAirdropClaimed;

    uint256 public constant MAX_ADDRESSES = 625143;

    uint256 public airdropClaimedCount;
    uint256 public airdropClaimedPercentage;

    event TransferOwnership(address _oldOwner, address _newOwner);
    event Requested(address user, uint256 deposit, uint256 coin);
    event Gifted(address user, uint256 amount);
    event Refunded(address user, uint256 amount, uint256 coin);
    event Whitelist(address[] users, bool set);
    event CanClaim(address indexed recipient, uint256 amount);
    event HasClaimed(address indexed recipient, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier isWhitelistMode() {
        require(saleType == 0, "Sale type is not set to WHITELIST");
        _;
    }

    modifier isPublicMode() {
        require(saleType == 1, "Sale type is not set to PUBLIC_SALE");
        _;
    }

    modifier whitelisted() {
        require(checkWhitelisted(msg.sender), "Not whitelisted account");
        _;
    }

    modifier underWay() {
        require(block.timestamp >= startTimestamp, "Presale not started");
        require(block.timestamp <= endTimestamp, "Presale ended");
        _;
    }

    modifier whenExpired() {
        require(block.timestamp > endTimestamp, "Presale not ended");
        _;
    }

    function initialize(address _targetToken, address _coinToken) external {
        require (!initialized, "Already initialized");
        initialized = true;

        owner = msg.sender;
        emit TransferOwnership(address(0), owner);

        targetToken = _targetToken;
        contributeCoin = _coinToken;

        salePrice = RESOLUTION_CV_RATIO / 1000; // 1 $ZKASH = 0.001 $ETH
        minPerWallet = 10 * (10 ** 18); // 10 $ZKASH per wallet at minimum
        maxPerWallet = 5000 * (10 ** 18); // 5000 $ZKASH per wallet at maximum

        totalTargetCap = 2_000_000 * (10 ** 18); // 2m $ZKASH at maximum
        saleType = 0; // 0: whitelist, 1: public sale
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Zero address");
        emit TransferOwnership(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit TransferOwnership(owner, address(0));
        owner = address(0);
    }

    function launchPresale(uint256 _secAfter, uint256 _secDuration) external onlyOwner {
        startTimestamp = block.timestamp + _secAfter;
        endTimestamp = block.timestamp + _secAfter + _secDuration;
    }

    function expandPresale(uint256 _secDuration) external onlyOwner underWay {
        endTimestamp = block.timestamp + _secDuration;
    }

    function updateVTokenPrice(uint256 _newSalePriceInResolution9) external onlyOwner {
        require(salePrice != _newSalePriceInResolution9, "Already set");
        salePrice = _newSalePriceInResolution9;
    }

    function updateMinMaxTokenPerWallet(uint256 _minAmount, uint256 _maxAmount) external onlyOwner {
        minPerWallet = _minAmount;
        maxPerWallet = _maxAmount;
    }

    function setTotalCap(uint256 _totalAmount) external onlyOwner {
        totalTargetCap = _totalAmount;
    }

    function updateSaleType(uint256 _saleType) external onlyOwner {
        require(saleType != _saleType, "Already set");
        require(saleType == 0 || saleType == 1, "Unknown sale type");
        saleType = _saleType;
    }

    function setWhitelisted(address[] calldata users, bool set) external onlyOwner {
        uint256 i;
        for (i = 0; i < users.length; i ++) {
            if (isWhitelisted[users[i]] != set) {
                isWhitelisted[users[i]] = set;
            }
        }
        emit Whitelist(users, set);
    }

    function updateTokens(address _targetToken, address _coinToken) external onlyOwner {
        require(totalTargetTokenRequested == 0, "Unable to update token addresses");
        targetToken = _targetToken;
        contributeCoin = _coinToken;
    }

    function convertC2V(uint256 _cAmount) internal view returns (uint256) {
        uint256 cDecimal = 18;
        if (contributeCoin != address(0)) {
            cDecimal = IToken(contributeCoin).decimals();
        }
        uint256 vDecimal = IToken(targetToken).decimals();
        return _cAmount * RESOLUTION_CV_RATIO * (10 ** vDecimal) / (salePrice * (10 ** cDecimal));
    }

    function convertV2C(uint256 _vAmount) internal view returns (uint256) {
        uint256 cDecimal = 18;
        if (contributeCoin != address(0)) {
            cDecimal = IToken(contributeCoin).decimals();
        }

        uint256 vDecimal = IToken(targetToken).decimals();
        return _vAmount * salePrice * (10 ** cDecimal) / (RESOLUTION_CV_RATIO * (10 ** vDecimal));
    }

    function sellVToken(address _to, uint256 _coinAmount) internal returns (uint256, uint256) {
        uint256 cReceived;
        if (contributeCoin == address(0)) {
            cReceived = msg.value;
        } else {
            address feeRx = address(this);
            uint256 _oldCBalance = IToken(contributeCoin).balanceOf(feeRx);
            IToken(contributeCoin).transferFrom(_to, feeRx, _coinAmount);
            uint256 _newCBalance = IToken(contributeCoin).balanceOf(feeRx);

            cReceived = _newCBalance - _oldCBalance;
        }

        uint256 targetAmount = convertC2V(cReceived);

        require(targetTokenRequested[_to] + targetAmount <= maxPerWallet, "Too much requested");
        require(targetTokenRequested[_to] + targetAmount >= minPerWallet, "Too small requested");

        targetTokenRequested[_to] += targetAmount;
        coinContributed[_to] += cReceived;

        totalTargetTokenRequested += targetAmount;
        totalCoinContributed += cReceived;

        return (targetAmount, cReceived);
    }

    function giftVToken(address _to, uint256 _vAmount) internal returns (uint256) {
        uint256 targetAmount = _vAmount;

        totalTargetTokenRequested += targetAmount;
        targetTokenRequested[_to] += targetAmount;

        return targetAmount;
    }

    function refundVToken(address to) internal returns (uint256, uint256) {
        uint256 targetAmount = targetTokenRequested[to];
        uint256 coinAmount = coinContributed[to];

        totalTargetTokenRequested -= targetTokenRequested[to];
        targetTokenRequested[to] = 0;
        coinContributed[to] = 0;

        if (coinAmount > 0) {
            payCoin(to, coinAmount);
        }

        return (targetAmount, coinAmount);
    }

    function sellWhitelist(uint256 _coinAmount) external payable
        isWhitelistMode whitelisted() underWay
    {
        (uint256 target, uint256 coin) = sellVToken(msg.sender, _coinAmount);
        emit Requested(msg.sender, target, coin);
    }

    function sellPublic(uint256 _coinAmount) external payable
        isPublicMode underWay
    {
        (uint256 target, uint256 coin) = sellVToken(msg.sender, _coinAmount);
        emit Requested(msg.sender, target, coin);
    }

    function gift(address _to, uint256 _vAmount) external 
        onlyOwner underWay
    {
        uint256 amount = giftVToken(_to, _vAmount);
        emit Gifted(_to, amount);
    }

    function forceRefund(address _user) external payable
        onlyOwner
    {
        (uint256 target, uint256 coin) = refundVToken(_user);
        emit Refunded(_user, target, coin);
    }

    function checkWhitelisted(address _user) public view returns (bool) {
        return isWhitelisted[_user];
    }

    function recoverCoin(address _to, uint256 _amount) external payable onlyOwner {
        if (_amount == 0) {
            if (contributeCoin == address(0)) {
                _amount = address(this).balance;
            } else {
                _amount = IToken(contributeCoin).balanceOf(address(this));
            }
        }

        payCoin(_to, _amount);
    }

    function payCoin(address _to, uint256 _amount) internal {
        if (contributeCoin == address(0)) {
            (bool success,) = payable(_to).call{value: _amount}("");
            require(success, "Failed to recover");
        } else {
            IToken(contributeCoin).transfer(_to, _amount);
        }
    }

    function claim(uint256 _amount) external payable whenExpired {
        address user = msg.sender;
        uint256 claimableAmount = getClaimableAmount(user);
        require(_amount <= claimableAmount, "Claiming too much");

//        if (totalTargetCap < totalTargetTokenRequested) { // overflown
//            uint256 _targetTokenAmount = _amount * totalTargetCap / totalTargetTokenRequested;
//            IToken(targetToken).transfer(user, _targetTokenAmount);

//            uint256 _totalCoinOverflownAmount = convertV2C(totalTargetTokenRequested - totalTargetCap);
//            payCoin(user, _totalCoinOverflownAmount * _amount / totalTargetTokenRequested);
//        } else {
            IToken(targetToken).transfer(user, _amount);
//        }

        targetTokenClaimed[user] += _amount;

        require(targetTokenClaimed[user] <= targetTokenRequested[user], "Claimed too much");
    }

    function getClaimableAmount(address user) public view returns (uint256) {
        uint256 requestedAmount = targetTokenRequested[user];
        uint256 claimedAmount = targetTokenClaimed[user];

        uint256 ret;
        if (block.timestamp < endTimestamp) {
            ret = 0;
//        } else if (block.timestamp < endTimestamp + (30 days)) {
//            ret = ((requestedAmount * 80) / 100) - claimedAmount;
//        } else if (block.timestamp < endTimestamp + (60 days)) {
//            ret = ((requestedAmount * 90) / 100) - claimedAmount;
        } else {
            ret = requestedAmount - claimedAmount;
        }

        return ret;
    }

    /// @notice Allows owner to set a list of recipients to receive tokens
    /// @dev This may need to be called many times to set the full list of recipients
    function setAirdropAmount(uint256 amount)
        external
        onlyOwner
    {
        totalAirdropClaimable = amount;
    }

    /// @notice Allows a recipient to claim their tokens
    /// @dev Can only be called during the claim period
    function airdropClaim() external {
        require(block.timestamp >= claimableStart, "Airdrop: claim not started");
        require(block.timestamp < claimableEnd, "Airdrop: claim ended");

        AIRDROP storage ad = airdropContext[msg.sender];
        require(ad.claimed == 0, "Airdrop: already claimed");

        uint256 amount = getAirdropClaimableAmount(msg.sender);
        require(amount > 0, "Airdrop: nothing to claim");

        ad.user = msg.sender;
        ad.claimable = amount;
        ad.claimed = amount;

        totalAirdropClaimed += amount;

        airdropClaimedCount ++;

        if (airdropClaimedCount > 0) {
            airdropClaimedPercentage = (airdropClaimedCount * 100) / MAX_ADDRESSES;
        }

        // we don't use safeTransfer since impl is assumed to be OZ
        IToken(targetToken).transfer(msg.sender, amount);
        emit HasClaimed(msg.sender, amount);
    }

    function getAirdropClaimableAmount(address user) public view returns (uint256) {
        if (airdropClaimedCount >= MAX_ADDRESSES) {
            return 0;
        }

        uint256 supplyPerAddress = totalAirdropClaimable * 1_000_000_000_000 / 4942353924769 * 20 / MAX_ADDRESSES;
        uint256 curClaimedCount = airdropClaimedCount + 1;
        uint256 claimedPercent = curClaimedCount * 100e6 / MAX_ADDRESSES;
        uint256 curPercent = 5e6;

        while (curPercent <= claimedPercent) {
            supplyPerAddress = (supplyPerAddress * 80) / 100;
            curPercent += 5e6;
        }

        return supplyPerAddress;
    }

    function getAirdropClaimedAmount(address user) public view returns (uint256) {
        AIRDROP storage ad = airdropContext[user];
        return (ad.user != user)? 0: ad.claimed;
    }

    function launchAirdrop(uint256 _secAfter, uint256 _secDuration) external onlyOwner {
        claimableStart = block.timestamp + _secAfter;
        claimableEnd = block.timestamp + _secAfter + _secDuration;
    }

    receive() external payable {}
}