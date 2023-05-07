/**
 *Submitted for verification at Arbiscan on 2023-05-06
*/

pragma solidity ^0.8.0;

interface ARBToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract AirdropContract {
    ARBToken public arbToken;
    address public owner;
    uint256 public airdropAmount;

    mapping(address => bool) public claimed;

    event TokensAirdropped(address indexed recipient, uint256 amount);

    constructor(address arbTokenAddress) {
        arbToken = ARBToken(arbTokenAddress);
        owner = msg.sender;
        airdropAmount = 0; // Update with your desired airdrop amount
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function claimAirdrop() external {
        require(!claimed[msg.sender], "Address has already claimed the airdrop");
        require(arbToken.balanceOf(msg.sender) > 0, "Address has no ARB tokens");

        claimed[msg.sender] = true;
        arbToken.transfer(msg.sender, airdropAmount);

        emit TokensAirdropped(msg.sender, airdropAmount);
    }

    function withdrawTokens() external onlyOwner {
        uint256 remainingBalance = arbToken.balanceOf(address(this));
        arbToken.transfer(owner, remainingBalance);
    }

    function setAirdropAmount(uint256 amount) external onlyOwner {
        airdropAmount = amount;
    }
}