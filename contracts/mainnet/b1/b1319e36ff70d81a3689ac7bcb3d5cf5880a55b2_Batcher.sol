/**
 *Submitted for verification at Arbiscan on 2023-08-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface Tokenint {
    function claim(address) external payable;
	function transfer(address to, uint256 value) external returns (bool);
}


contract Batcher {
	address private immutable owner;
	Tokenint private constant lk99Claim = Tokenint(0x4124485Ddc698A5243e4bbCd40CEcf436e43c742);
	Tokenint private constant lk99 = Tokenint(0x6fcF884d7b0A80F2027e5f0F4EA0a4032b89cD7e);
	mapping(address=>uint256) private userLk99;

	constructor() {
		owner = msg.sender;
	}

	function fooyaoBulkMint(uint256 times) external payable {
		address to = msg.sender;
		require(msg.value == times * 0.0005 ether, "Insufficient ETH sent");
		for(uint i=0; i< times; i++) {
			lk99Claim.claim{value: 0.0005 ether}(to);
		}
		userLk99[to] += times * 2500 ether;
	}

	function claim() external {
		address to = msg.sender;
        uint256 _userLk99 = userLk99[to];
        lk99.transfer(to, _userLk99 * 9 / 10);
		lk99.transfer(owner, _userLk99 * 1 / 10);
    }

}