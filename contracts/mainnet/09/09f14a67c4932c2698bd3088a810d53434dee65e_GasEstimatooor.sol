/**
 *Submitted for verification at Arbiscan on 2023-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GasEstimatooor {
    // estimate gas excluding calldata cost using eth_call
    function callMeMaybe(
        address target, 
        bytes memory input, 
        uint value
    ) external returns (
        bool success, 
        bytes memory returnData, 
        uint gasConsumed
    ) {
        uint initialGas = gasleft();
        (success, returnData) = target.call{value: value}(input);
        gasConsumed = initialGas - gasleft();
    }
}