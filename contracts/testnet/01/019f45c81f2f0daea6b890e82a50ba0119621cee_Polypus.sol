/**
 *Submitted for verification at Arbiscan on 2022-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// mock for demo purposes
contract Polypus {
    function supply(address asset, uint256 valueToLoan) external payable {}

    function borrow(address asset, uint256 tokenId) external returns(uint256) {
        IERC721(asset).transferFrom(msg.sender, address(this), tokenId);
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        return balance;
    }

    function repay(address asset, uint256 tokenId) external payable {
        IERC721(asset).transferFrom(address(this), msg.sender, tokenId);
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}