/**
 *Submitted for verification at Arbiscan.io on 2024-05-10
*/

/**
 *Submitted for verification at basescan.org on 2024-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BatchTransfer {
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function multiSend(
        address payable[] memory _recipients,
        uint256[] memory _amounts
    ) public payable {
        require(
            _recipients.length == _amounts.length,
            "receipent must be same"
        );

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount += _amounts[i];
        }
        require(msg.value >= totalAmount, "Amount not match");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(_amounts[i]);
        }
    }

    function withdraw() public {
        require(msg.sender == owner, "only owner");
        uint256 balanceBeforeWithdraw = address(this).balance;
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send");
        require(
            address(this).balance ==
                balanceBeforeWithdraw - address(this).balance,
            "Balance mismatch after withdraw"
        );
    }
}