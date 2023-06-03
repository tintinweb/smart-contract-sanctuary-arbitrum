/**
 *Submitted for verification at Arbiscan on 2023-06-03
*/

// SPDX-License-Identifier: MIT

// 微信 fooyao
pragma solidity ^0.8.19;

interface Tokenint {
  function transfer(address to, uint256 amount) external;
  function balanceOf(address who) external view returns (uint256);
  function mintClips(address) payable external;
}



contract Batch {
    address private immutable owner;

	constructor() {
		owner = msg.sender;
	}


    function batch_mint(address contractAddress, uint batchCount) payable external {
        Tokenint target = Tokenint(contractAddress);
        uint price;
        if (msg.value > 0){
            price = msg.value / batchCount;
        }
        for (uint i = 0; i < batchCount; i++) {
            target.mintClips{value: price}(owner);
        }
        uint balance = target.balanceOf(address(this));
        target.transfer(msg.sender, balance);
    }

}