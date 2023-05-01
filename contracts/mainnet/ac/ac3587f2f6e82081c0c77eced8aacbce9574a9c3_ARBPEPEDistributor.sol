// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

interface IWhitelist {
    function _claimedUser(address _user) external view returns (bool);
}

contract ARBPEPEDistributor {
    address private whitelistContractAddress;
    IERC20 public tokenContract;
    uint256 public TOKEN_AMOUNT = 13000000000;
    address private owner;
    bool private launched;
    mapping (address => bool) private claimed;

    constructor(address _whitelistContractAddress) {
        whitelistContractAddress = _whitelistContractAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    function initialize(address _tokenContractAddress) public onlyOwner {
        require(!launched, "Contract already launched");
        tokenContract = IERC20(_tokenContractAddress);
        launched = true;
    }

    function isWhitelisted(address _userAddress) public view returns (bool) {
        return IWhitelist(whitelistContractAddress)._claimedUser(_userAddress);
    }

    function claim(address referral) public returns (bool) {
        require(launched, "Claim not yet launched");
        bool isClaimed = isWhitelisted(msg.sender);
        require(isClaimed, "You are not whitelisted");
        require(!claimed[msg.sender], "ARBPEPE already claimed");
        require(referral != msg.sender, "You cannot refer yourself");
        claimed[msg.sender] = true;
        uint256 tokenAmount = SafeMath.mul(TOKEN_AMOUNT, 10**6);
        uint256 referralTokenAmount = SafeMath.div(tokenAmount, 10);
        uint256 userTokenAmount = SafeMath.sub(tokenAmount, referralTokenAmount);
        require(userTokenAmount > 0, "Token amount must be greater than zero");
        if (referral != address(0)) {
            require(isWhitelisted(referral), "Referral is not whitelisted");
            require(tokenContract.transfer(referral, referralTokenAmount), "ARBPEPE transfer failed");
        }
        require(tokenContract.transfer(msg.sender, userTokenAmount), "ARBPEPE transfer failed");
        return true;
    }
    
    function setTokenAmount(uint256 _newAmount) external onlyOwner { 
        TOKEN_AMOUNT = _newAmount;
    }

    function reclaimRemainingTokens() public onlyOwner returns (bool) {
        uint256 remainingBalance = tokenContract.balanceOf(address(this));
        require(remainingBalance > 0, "No remaining tokens to reclaim");
        require(tokenContract.transfer(owner, remainingBalance), "ARBPEPE transfer failed");
        return true;
    }
}