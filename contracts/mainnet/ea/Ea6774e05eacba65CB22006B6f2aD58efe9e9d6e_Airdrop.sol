/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract Airdrop {
    address public owner;
    address public tokenAddress;
    uint256 public airdropAmount;
    uint256 public claimFee;
    mapping(address => bool) public claimed;
    address[] public recipients;

    constructor(
        address _tokenAddress,
        uint256 _airdropAmount,
        uint256 _claimFeeInEth
    ) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        airdropAmount = convertToWei(_airdropAmount);
        claimFee = _claimFeeInEth;
    }

    function claimAirdrop() external payable {
        require(msg.value == claimFee, "Invalid claim fee");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= airdropAmount,
            "Insufficient airdrop tokens"
        );
        require(!claimed[msg.sender], "Already claimed airdrop");

        bool success = IERC20(tokenAddress).transfer(msg.sender, airdropAmount);
        require(success, "Airdrop transfer failed");

        claimed[msg.sender] = true;
        recipients.push(msg.sender);
    }

    function setAirdropAmount(
        uint256 _newAirdropAmountInEth
    ) external onlyOwner {
        airdropAmount = convertToWei(_newAirdropAmountInEth);
    }

    function setClaimFee(uint256 _newClaimFeeInEth) external onlyOwner {
        claimFee = convertToWei(_newClaimFeeInEth);
    }

    function hasClaimed(address user) external view returns (bool) {
        return claimed[user];
    }

    function getAllRecipients() external view returns (address[] memory) {
        return recipients;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can perform this action"
        );
        _;
    }

    receive() external payable {}

    function convertToWei(uint256 amountInEth) internal pure returns (uint256) {
        return amountInEth * 1 ether;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No ether to withdraw");
        payable(owner).transfer(address(this).balance);
    }
}