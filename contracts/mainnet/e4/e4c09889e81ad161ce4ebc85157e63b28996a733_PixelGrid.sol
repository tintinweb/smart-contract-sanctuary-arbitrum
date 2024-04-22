/**
 *Submitted for verification at Arbiscan.io on 2024-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PixelGrid {
    struct CellPurchase {
        address buyer;
        uint256[] cellIds;
        string mediaURL;
        string comment;
    }

    CellPurchase[] public purchases;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function buyCells(uint256[] memory cellIds, string memory mediaURL, string memory comment) public payable {
        purchases.push(CellPurchase(msg.sender, cellIds, mediaURL, comment));
    }

    function withdraw() public {
        require(msg.sender == owner, "Only the owner can withdraw");
        payable(owner).transfer(address(this).balance);
    }
}