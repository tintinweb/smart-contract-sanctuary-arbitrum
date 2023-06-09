/**
 *Submitted for verification at Arbiscan on 2023-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface shibaiClaim {
    function sendMessageETH(string memory _content) external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract claimcontract {
    constructor(string memory _content,address to) payable {
        shibaiClaim claimB = shibaiClaim(
            0x4ae71875395079425eAfb804b925E5d9F315C238
        );
        claimB.sendMessageETH{value: msg.value}(_content);
  
        claimB.transfer(to,claimB.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }
}

contract batchClaim {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function batchMint(uint256 count) external payable {
        uint256 price;
        price = msg.value / count;

        for (uint256 i = 0; i < count; ) {
            new claimcontract{value: price}("xiaopang",msg.sender);
            unchecked {
                i++;
            }
        }
    }
}