/**
 *Submitted for verification at Arbiscan on 2023-06-09
*/

/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface myERC20 {
  function sendMessageETH(string calldata _content) external payable;

}


contract Batch3 {
	address private immutable owner;
    address public  contractAddress ;
	modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

	constructor(address _contractAddress) {
		owner = msg.sender;
        contractAddress = _contractAddress;
	}

	function fooyaoBulkMint(uint256 times) external payable{
        uint price;
        if (msg.value > 0){
            price = msg.value / times;
        }
        
		for(uint i=0; i< times; i++) {
			
			myERC20(contractAddress).sendMessageETH{value: price}("ok");
        }
			
	}
}