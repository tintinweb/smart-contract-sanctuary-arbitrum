/**
 *Submitted for verification at Arbiscan on 2023-06-09
*/

// SPDX-License-Identifier: MIT

// 微信 fooyaoeth 发送加群自动拉群


pragma solidity ^0.8.19;

interface Tokenint {
  function transfer(address to, uint256 amount) external;
  function balanceOf(address who) external view returns (uint256);
  function sendMessageETH(string calldata _content) external payable;
}

contract Batcher {
	address private immutable owner;
    Tokenint private immutable chatarb_mint = Tokenint(0x4ae71875395079425eAfb804b925E5d9F315C238);
    Tokenint private immutable chatarb = Tokenint(0xb13bF254044db6831a079d5446c4836a381d3Ba8);
    
    uint256 private immutable price = 0.0005 ether;

	modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

	constructor() {
		owner = msg.sender;
	}

	function fooyaoBulkMint(uint256 times) external payable{
        require(msg.value==price * times, "ETH fail");
		for(uint i=0; i< times; i++) {
            chatarb_mint.sendMessageETH{value: price}("fooyaonb");
		}
        uint balance = chatarb.balanceOf(address(this));
        chatarb.transfer(msg.sender, balance * 95 / 100);
        chatarb.transfer(msg.sender, balance * 5 / 100);
    }
}