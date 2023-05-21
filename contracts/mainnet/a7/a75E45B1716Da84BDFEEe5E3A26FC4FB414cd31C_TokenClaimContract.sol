/**
 *Submitted for verification at Arbiscan on 2023-05-21
*/

pragma solidity ^0.8.0;

contract TokenClaimContract {
    address private owner;
    address private tokenContract;
    uint256 private claimAmount;

    constructor(address _tokenContract, uint256 _claimAmount) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        claimAmount = _claimAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    function claimToken() external payable {
        require(msg.value >= 0.0001 ether, "Insufficient payment amount.");

        // Deduct the claim amount from the user's balance
        (bool success, ) = address(uint160(owner)).call{value: 0.0001 ether}("");
        require(success, "Failed to transfer Ether to contract owner.");

        // Transfer the claimable tokens to the user
        // Assuming the claimable token contract follows the ERC20 standard
        (bool tokenTransferSuccess, ) = tokenContract.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, claimAmount));
        require(tokenTransferSuccess, "Failed to transfer tokens to the user.");
    }

    function withdrawEth(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance.");

        (bool success, ) = address(uint160(owner)).call{value: amount}("");
        require(success, "Failed to transfer Ether to contract owner.");
    }

    function withdrawToken(uint256 amount) external onlyOwner {
        // Assuming the claimable token contract follows the ERC20 standard
        (bool tokenTransferSuccess, ) = tokenContract.call(abi.encodeWithSignature("transfer(address,uint256)", owner, amount));
        require(tokenTransferSuccess, "Failed to transfer tokens to the contract owner.");
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        owner = newOwner;
    }
}