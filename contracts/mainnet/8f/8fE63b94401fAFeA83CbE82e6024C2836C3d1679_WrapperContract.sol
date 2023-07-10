/**
 *Submitted for verification at Arbiscan on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WrapperContract {
    address fiat24ContractAddress;  // Address of the first contract

    // person who deploys contract is the owner
    address payable public owner;

    // allows owner only
    modifier onlyOwner(){
        require(owner == msg.sender, "Sender not authorized");
        _;
    }

    constructor(address _fiat24ContractAddress) {
        fiat24ContractAddress = _fiat24ContractAddress;
        // owner = payable(msg.sender);
    }

    function depositTokenViaUsdc(address _inputToken, address _outputToken, uint256 _amount) external returns (uint256) {
        // Call the depositTokenViaUsdc() method in the first contract
        
        (bool success, bytes memory result) = fiat24ContractAddress.delegatecall(
            abi.encodeWithSignature("depositTokenViaUsdc(address,address,uint256)",
            _inputToken, 
            _outputToken, 
            _amount
            )
        );
        
        require(success, "Failed to call depositTokenViaUsdc() in the fiat 24 contract");
        
        // Decode and return the result (if necessary)
        return abi.decode(result, (uint256));
    }
}