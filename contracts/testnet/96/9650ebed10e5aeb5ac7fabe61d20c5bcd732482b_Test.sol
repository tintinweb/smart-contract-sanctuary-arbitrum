/**
 *Submitted for verification at arbiscan.io on 2022-03-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    uint256 public minted = 0;
    uint256 private constant FIXED_PRICE = 0x0429d069189e0000;

    function getPrice(uint8 quantity) public pure returns (uint256) {
        return uint256(quantity * FIXED_PRICE);
    }

    function mint(uint8 quantity) external payable returns (uint256 price) {
        price = getPrice(quantity);
        minted = minted + quantity;
        payable(msg.sender).transfer(address(this).balance);
        return price;
    }
}