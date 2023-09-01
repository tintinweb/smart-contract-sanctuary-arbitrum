/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BatchTransfer {
    function batchTransferToken(address token, address[] memory receivers, uint256[] memory amounts) public {
        IERC20 erc20Token = IERC20(token);

        for (uint i = 0; i < receivers.length; i++) {
            require(erc20Token.transferFrom(msg.sender, receivers[i], amounts[i]), "Transfer failed");
        }
    }
}