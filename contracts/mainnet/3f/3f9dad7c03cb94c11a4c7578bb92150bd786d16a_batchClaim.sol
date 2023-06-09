/**
 *Submitted for verification at Arbiscan on 2023-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface shibaiClaim {
    function sendMessageETH(string calldata _content) external payable;
}

interface token {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract claimcontract {
    function mint(string calldata content,address to) public  payable  {
        shibaiClaim claimB = shibaiClaim(
            0x4ae71875395079425eAfb804b925E5d9F315C238
        );
        claimB.sendMessageETH{value: msg.value}(content);
        token arbchat = token(0xb13bF254044db6831a079d5446c4836a381d3Ba8);
        arbchat.transfer(to, arbchat.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }

 
}

contract batchClaim {
    address public owner;
    uint256 sendvalue = 0.0005 ether;

    constructor() public {
        owner = msg.sender;
    }

    function batchMint(uint256 count) public payable {

        require(msg.value == sendvalue*count,"qiongbi");
        for (uint256 i = 0; i < count; i++) {
            claimcontract claim=new claimcontract();
            claim.mint{value: sendvalue}("xiaopang", msg.sender);
        }
    }
}