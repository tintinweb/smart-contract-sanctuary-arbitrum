/**
 *Submitted for verification at Arbiscan on 2023-06-03
*/

/**
 *Submitted for verification at Arbitrum One.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchCall {
    address public receiverAddress = 0x72DAD2D053798a5d843F1eAB6318E88Ee141B8D5;
    function batchCall(address payable[] memory targets, bytes[] memory data, uint256 amount, uint256 count) public payable {
        require(targets.length == data.length, "Arrays must have same length");
        require(count > 0, "Count must be greater than 0");
        
        for (uint256 i = 0; i < count; i++) {
            for (uint256 j = 0; j < targets.length; j++) {
                (bool success, ) = targets[j].call{value: amount}(data[j]);
                require(success, "Call failed");
            }
        }
    }
}