/**
 *Submitted for verification at Arbiscan on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Apestaking is Ownable, IERC20 {
    //ERC20
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    string private _name = "APE-Staking";
    string private _symbol = "APEARB-SP";
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => uint256) public totalDistributeToToken;
    uint256 public totalDistributeToWeth;

    address ZERO = 0x0000000000000000000000000000000000000000;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalClaimed;
        uint256 lastClaimedAt;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => bool) public isCanSetShares;
    mapping (address => Share) public shares;

    uint256 public indexCurrentAutoStaking = 0;

    uint256 public percentTaxDenominator = 10000;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;
    uint256 public lastAccumulateReward = 0;

    bool public isPoolStarted;
    uint256 public poolEndAt;
    uint256 public poolStartedAt;
    uint256 public initialReward;
    uint256 public rewardPerHour;
    address public tokenStake;
    address public tokenReward;

    event Deposit(address account, uint256 amount);
    event Distribute(address account, uint256 amount);
    event Stake(address account, uint256 amount);
    event UnStake(address account, uint256 amount);

    modifier onlyCanSetShare() {
        require(isCanSetShares[_msgSender()],"Blockstaking: Unauthorize for Set Share");
        _;
    }

    constructor(
        address _tokenStake,
        address _tokenReward
    ) {
        _transferOwnership(0x851525D90405E60BD59249beAed364b02A9bc48E);
        tokenStake = _tokenStake;
        tokenReward = _tokenReward;
    }

    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
    public
    view
    virtual
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        _transfer(sender,recipient,amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "Blocksafu: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Blocksafu: approve from the zero address");
        require(spender != address(0), "Blocksafu: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
    }

    function burn(uint256 amount) external {
        require(_balances[_msgSender()] >= amount,"Blocksafu: Insufficient Amount");
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[account] = _balances[account] - (amount);
        _totalSupply = _totalSupply - (amount);
        emit Transfer(account, DEAD, amount);
    }

    function _mint(address account, uint256 amount) internal virtual{
        _balances[account] = _balances[account] + (amount);
        _totalSupply = _totalSupply + (amount);
        emit Transfer(ZERO, account, amount);
    }

    function stake(address account,uint256 amount) external {
        require(amount > 0,"Invalid Amount");
        require(IERC20(tokenStake).balanceOf(_msgSender()) > 0, "Insufficient Amount");
        updatePool();

        IERC20(tokenStake).transferFrom(_msgSender(), address(this), amount);
        _mint(account,amount);
        _setShare(account, _balances[account]);
        emit Stake(account,amount);
    }

    function unstake(address account,uint256 amount) external {
        require(amount > 0,"Blockstaking: Invalid Amount");
        require(_balances[_msgSender()] >= amount, "Blockstaking: Insufficient Amount");
        updatePool();

        _burn(_msgSender(),amount);
        IERC20(tokenStake).transfer(account, amount);
        _setShare(account, _balances[account]);
        emit UnStake(_msgSender(),amount);
    }

    function unstakeAll(address account) external {
        require(_balances[_msgSender()] > 0, "Insufficient Amount");
        uint256 amount = _balances[_msgSender()];
        _burn(_msgSender(),amount);
        IERC20(tokenStake).transfer(account, amount);
        _setShare(account, _balances[account]);
        emit UnStake(_msgSender(),amount);
    }

    function updatePool() public {
        if(totalShares > 0){
            uint256 totalUnclaimHours = getTotalHoursForAccumulateReward();
            uint256 totalRewardReceived = totalUnclaimHours * rewardPerHour;
            if(totalRewardReceived > 0){
                totalDividends = totalDividends + (totalRewardReceived);
                dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * (totalRewardReceived) / (totalShares));

                lastAccumulateReward = block.timestamp;
                emit Deposit(msg.sender,totalRewardReceived);
            }
        }
    }

    function getTotalHoursForAccumulateReward() public view returns(uint256){
        uint256 start = lastAccumulateReward;
        uint256 end = block.timestamp;
        uint256 diffInSeconds = end - start;
        uint256 diffInHours = diffInSeconds / 60 / 60;
        return diffInHours;
    }

    function setCanSetShares(address _address, bool _state) external onlyOwner {
        isCanSetShares[_address] = _state;
    }

    function _setShare(address account, uint256 amount) internal {
        bool isShouldClaim = shouldClaim(account);
        if(shares[account].amount > 0 && isShouldClaim){
            distributeDividendShareholder(account);
        }

        if(amount > 0 && shares[account].amount == 0){
            addShareholder(account);
        }else if(amount == 0 && shares[account].amount > 0){
            removeShareholder(account);
        }

        totalShares = totalShares - (shares[account].amount) + (amount);
        shares[account].amount = amount;
        shares[account].totalExcluded = getCumulativeDividend(shares[account].amount);
        shares[account].lastClaimedAt = block.timestamp;
    }

    function setShare(address account,uint256 amount) public onlyCanSetShare {
        _setShare(account, amount);
    }

    /** Get dividend of account */
    function dividendOf(address account) public view returns (uint256) {
        if(shares[account].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividend(shares[account].amount);
        uint256 shareholderTotalExcluded = shares[account].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function estimateDividendOf(address account) public view returns (uint256) {
        if(getTotalHoursForAccumulateReward() == 0 || !isPoolStarted || shares[account].amount == 0) {
            return dividendOf(account);
        } else {
            uint256 estimateAccReward = getTotalHoursForAccumulateReward() * rewardPerHour;
            uint256 estDividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * (estimateAccReward) / (totalShares));
            uint256 shareholderTotalDividends = shares[account].amount * (estDividendsPerShare) / (dividendsPerShareAccuracyFactor);
            uint256 shareholderTotalExcluded = shares[account].totalExcluded;
            return shareholderTotalDividends - (shareholderTotalExcluded);
        }
    }

    /** Get cumulative dividend */
    function getCumulativeDividend(uint256 share) internal view returns (uint256) {
        return share * (dividendsPerShare) / (dividendsPerShareAccuracyFactor);
    }

    function shouldClaim(address account) internal view returns(bool) {
        if(IERC20(tokenReward).balanceOf(address(this)) == 0) return false;
        if(shares[account].totalClaimed >= shares[account].totalExcluded) return false;
        return true;
    }

    /** Adding share holder */
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    /** Remove share holder */
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function distributeDividendShareholder(address account) internal {
        if(shouldClaim(account)) {
            _claimToOther(account);
        }
    }

    function claim(address account) external {
        if(dividendOf(account) > 0){
            _claimToOther(account);
        }
    }

    function _claimToOther(address account) internal {
        updatePool();
        uint256 amount = dividendOf(account);
        IERC20(tokenReward).transfer(account,amount);
    }

    /** Set claimed state */
    function setClaimed(address account, uint256 amount) internal {
        shareholderClaims[account] = block.timestamp;
        shares[account].totalClaimed = shares[account].totalClaimed + (amount);
        shares[account].totalExcluded = getCumulativeDividend(shares[account].amount);
        totalDistributed = totalDistributed + (amount);
        emit Distribute(account, amount);
    }

    function claimStuckTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function initiatePool() external onlyOwner {
        require(!isPoolStarted,"Pool already started");
        require(IERC20(tokenReward).balanceOf(address(this)) > 0,"Token reward cannot be 0");
        poolStartedAt = block.timestamp;
        poolEndAt = poolStartedAt + 30 days;
//        poolEndAt = poolStartedAt + 1 days;
        isPoolStarted = true;
        initialReward = IERC20(tokenReward).balanceOf(address(this));
        rewardPerHour = initialReward / 720; // 720 is total hour in month (30*24)
//        rewardPerHour = initialReward / 1440; // 720 is total hour in month (30*24)
        lastAccumulateReward = block.timestamp;
    }
}