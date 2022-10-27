/**
 *Submitted for verification at Arbiscan on 2022-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Spreader {
    struct Item {
        address payable account;
        uint96 amount;
    }

    function spread(Item[] calldata items) external payable {
        unchecked {
            for (uint256 i = 0; i < items.length; ++i) {
                Item memory item = items[i];
                item.account.transfer(item.amount);
            }
            uint256 balance = address(this).balance;
            if (balance > 0) {
                payable(msg.sender).transfer(balance);
            }
        }
    }
}