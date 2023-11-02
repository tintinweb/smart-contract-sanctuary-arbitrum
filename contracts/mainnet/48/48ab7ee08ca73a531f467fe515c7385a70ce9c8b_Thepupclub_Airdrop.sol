/**
 *Submitted for verification at Arbiscan.io on 2023-11-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= type(uint256).max - a, "SafeMath: addition overflow");
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        require(b <= type(uint256).max / a, "SafeMath: multiplication overflow");
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Thepupclub_Airdrop {
    using SafeMath for uint256;

    address public owner;
    IERC20 public token;
    address public feeReceiver;
    uint256 public claimFee;
    uint256 public tokenReward;
    uint256 public referralTokenPercentage;
    uint256 public referralEthPercentage;
    uint256 public airdropAmount;
    bool public isAirdropActive;
    mapping(address => bool) public hasClaimed;
    mapping(address => address) public referrers;

    event TokensClaimed(address indexed receiver, uint256 tokensReceived, uint256 ethReceived);
    event ReferralBonusPaid(address indexed referrer, address indexed referred, uint256 tokensReceived, uint256 ethReceived);
    event AirdropStarted();
    event AirdropStopped();
    event AirdropAmountSet(uint256 newAmount);
    event TokenRewardsSet(uint256 newTokenReward);
    event FeeReceiverSet(address newFeeReceiver);

    constructor(address _token, address _feeReceiver, uint256 _initialTokenReward, uint256 _initialAirdropAmount) {
        owner = msg.sender;
        token = IERC20(_token);
        setFeeReceiver(_feeReceiver);
        claimFee = 1500000000000000; // 0.0015 ETH in wei
        tokenReward = _initialTokenReward;
        referralTokenPercentage = 30;
        referralEthPercentage = 20;
        airdropAmount = _initialAirdropAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier airdropIsActive() {
        require(isAirdropActive, "Airdrop is not active");
        _;
    }

    function setFeeReceiver(address _newFeeReceiver) public onlyOwner {
        require(_newFeeReceiver != address(0), "Invalid fee receiver address");
        feeReceiver = _newFeeReceiver;
        emit FeeReceiverSet(_newFeeReceiver);
    }

    function startAirdrop() external onlyOwner {
        isAirdropActive = true;
        emit AirdropStarted();
    }

    function stopAirdrop() external onlyOwner {
        isAirdropActive = false;
        emit AirdropStopped();
    }

    function setClaimFee(uint256 _newFee) external onlyOwner {
        claimFee = _newFee;
    }

    function setReferralBonuses(uint256 _tokenPercentage, uint256 _ethPercentage) external onlyOwner {
        require(_tokenPercentage.add(_ethPercentage) <= 100, "Total percentage exceeds 100%");
        referralTokenPercentage = _tokenPercentage;
        referralEthPercentage = _ethPercentage;
    }

    function setAirdropAmount(uint256 _newAmount) external onlyOwner {
        airdropAmount = _newAmount;
        emit AirdropAmountSet(_newAmount);
    }

    function setTokenRewards(uint256 _newTokenReward) external onlyOwner {
        tokenReward = _newTokenReward;
        emit TokenRewardsSet(_newTokenReward);
    }

    function claimAirdrop() external payable airdropIsActive {
        require(!hasClaimed[msg.sender], "You have already claimed tokens");
        require(msg.value >= claimFee, "Insufficient claim fee");
        require(airdropAmount >= tokenReward, "Airdrop tokens exhausted");

        hasClaimed[msg.sender] = true;
        airdropAmount = airdropAmount.sub(tokenReward);

        token.transfer(msg.sender, tokenReward);

        address payable feeReceiverAddress = payable(feeReceiver);
        feeReceiverAddress.transfer(msg.value);

        if (referrers[msg.sender] != address(0)) {
            address referrer = referrers[msg.sender];
            uint256 referralTokenBonus = claimFee.mul(referralTokenPercentage).div(100);
            uint256 referralEthBonus = msg.value.mul(referralEthPercentage).div(100);

            token.transfer(referrer, referralTokenBonus);
            address payable referrerAddress = payable(referrer);
            referrerAddress.transfer(referralEthBonus);

            emit ReferralBonusPaid(referrer, msg.sender, referralTokenBonus, referralEthBonus);
        }

        emit TokensClaimed(msg.sender, tokenReward, msg.value);
    }

    function setReferrer(address referrer) external {
        require(referrer != address(0) && referrer != msg.sender, "Invalid referrer address");
        require(referrers[msg.sender] == address(0), "Referrer already set");
        referrers[msg.sender] = referrer;
    }

    function generateReferralLink() public view returns (string memory) {
        string memory contractAddress = addressToString(address(this));
        return string(abi.encodePacked("https://airdrop.thepupclub.tech/?ref=", contractAddress));
    }

    function addressToString(address _address) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function withdrawEth() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawTokens() external onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        token.transfer(owner, contractBalance);
    }
}