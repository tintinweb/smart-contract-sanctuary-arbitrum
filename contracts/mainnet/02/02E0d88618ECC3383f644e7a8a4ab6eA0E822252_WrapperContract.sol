/**
 *Submitted for verification at Arbiscan on 2023-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WrapperContract {
    function depositTokenViaUsdc(address _inputToken, address _outputToken, uint256 _amount, address _fiat24DepositContract) external returns (uint256) {
        // Call the depositTokenViaUsdc() method in the first contract
        
        (bool success, bytes memory result) = _fiat24DepositContract.delegatecall(
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