/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}

contract PointTokenDistributor {
    address private _owner;
    address private _tokenAddress;
    uint256 private _airdropTokenAmount;
    uint256 private _referralTokenPercentage;
    uint256 private _ethFee;
    uint256 private _maxAirdropLimit;
    uint256 private _totalReferralEarnings;
    uint256 private _totalReferredUsers;
    uint256 private _totalAirdropTokensDistributed;
    bool private _airdropEnabled;

    mapping(address => uint256) private _referralCount;
    mapping(address => uint256) private _referralEarnings;
    mapping(address => bool) private _claimedAirdrop;
    mapping(address => address) private _referrers;
    address[] private _referralAddresses;

    struct ReferralInfo {
    address wallet;
    uint256 referralCount;
    uint256 totalReferralEarnings;
}

    event AirdropEnabled(bool enabled);
    event Airdrop(address indexed recipient, address indexed referrer, uint256 amount);

    modifier withinAirdropLimit(uint256 amount) {
        require(amount <= _maxAirdropLimit, "Exceeded maximum Airdrop limit");
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Only the owner can call this function");
        _;
    }

    constructor(address tokenAddress) {
        _owner = msg.sender;
        _tokenAddress = tokenAddress;
        _referralTokenPercentage = 10; // 10% Initial
        _ethFee = 0.00055 ether;
        _airdropEnabled = true;
        _maxAirdropLimit = 10000 * 10**18; // 10000 tokens in wei
        _airdropTokenAmount = _maxAirdropLimit;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setAirdropEnabled(bool enabled) external onlyOwner {
        _airdropEnabled = enabled;
        emit AirdropEnabled(enabled);
    }

    function setTokenAddress(address tokenAddress) external onlyOwner {
        _tokenAddress = tokenAddress;
    }

    function setAirdropTokenAmount(uint256 airdropTokenAmount) external onlyOwner {
        _airdropTokenAmount = airdropTokenAmount;
    }

    function setReferralTokenPercentage(uint256 referralTokenPercentage) external onlyOwner {
        _referralTokenPercentage = referralTokenPercentage;
    }

    function setEthFee(uint256 ethFee) external onlyOwner {
        _ethFee = ethFee;
    }

    function getReferralCount(address wallet) public view returns (uint256) {
        return _referralCount[wallet];
    }

    function getReferralEarnings(address wallet) public view returns (uint256) {
        return _referralEarnings[wallet];
    }

    function getTotalReferralEarnings() public view returns (uint256) {
        return _totalReferralEarnings;
    }

    function getTotalReferredUsers() public view returns (uint256) {
        return _totalReferredUsers;
    }

    function getTotalAirdropTokensDistributed() public view returns (uint256) {
        return _totalAirdropTokensDistributed;
    }

    function getMaxAirdropLimit() public view returns (uint256) {
        return _maxAirdropLimit;
    }

    function clearETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function clearToken(address tokenAddress) external onlyOwner {
        ERC20Token token = ERC20Token(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance > 0, "No tokens available for withdrawal");

        bool success = token.transfer(msg.sender, contractBalance);
        require(success, "Token transfer failed");
    }

    function getUserBalance() public view returns (uint256) {
        ERC20Token token = ERC20Token(_tokenAddress);
        return token.balanceOf(msg.sender);
    }

    function getTokenAddress() public view returns (address) {
        return _tokenAddress;
    }

    function getReferralAddressAtIndex(uint256 index) public view returns (address) {
        require(index < _referralAddresses.length, "Invalid index");
        return _referralAddresses[index];
    }

    function hasClaimedAirdrop(address user) public view returns (bool) {
        return _claimedAirdrop[user];
    }

    function getAllReferralWallets() public view returns (ReferralInfo[] memory) {
        ReferralInfo[] memory referralInfoArray = new ReferralInfo[](_referralAddresses.length);
        
        for (uint256 i = 0; i < _referralAddresses.length; i++) {
            address wallet = _referralAddresses[i];
            uint256 referralCount = _referralCount[wallet];
            uint256 totalReferralEarnings = _referralEarnings[wallet];
            
            referralInfoArray[i] = ReferralInfo(wallet, referralCount, totalReferralEarnings);
        }
        
        return referralInfoArray;
    }
    function airdrop(address referrer, uint256 points) public payable withinAirdropLimit(points) {
        require(_airdropEnabled, "Airdrop is currently disabled");
        require(msg.value == _ethFee, "Invalid ETH fee");

        address recipient = msg.sender;

        require(!_claimedAirdrop[recipient], "Airdrop already claimed");

        uint256 tokenAmount = (_airdropTokenAmount * points) / 10;

        ERC20Token token = ERC20Token(_tokenAddress);
        token.transfer(recipient, tokenAmount);
        _totalAirdropTokensDistributed += tokenAmount;

        if (referrer != address(0) && referrer != recipient) {
            _referrers[recipient] = referrer;
            _referralCount[referrer]++;
        }

        address existingReferrer = _referrers[recipient];
        if (existingReferrer != address(0) && _referralTokenPercentage > 0) {
            uint256 referralTokenAmount = (tokenAmount * _referralTokenPercentage) / 100;
            token.transfer(existingReferrer, referralTokenAmount);
            _referralEarnings[existingReferrer] += referralTokenAmount;
            _totalReferralEarnings += referralTokenAmount;

            // Update referral count and total referral earnings for the referrer's referrer (if exists)
            address referrerOfReferrer = _referrers[existingReferrer];
            if (referrerOfReferrer != address(0)) {
                _referralCount[referrerOfReferrer]++;
                _referralEarnings[referrerOfReferrer] += referralTokenAmount;
            }
        }

        _claimedAirdrop[recipient] = true;
        _totalReferredUsers++;

        if (!_claimedAirdrop[referrer] && referrer != address(0) && referrer != recipient) {
            _referralAddresses.push(referrer);
        }

        emit Airdrop(recipient, referrer, tokenAmount);
    }
}

interface ERC20Token {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}