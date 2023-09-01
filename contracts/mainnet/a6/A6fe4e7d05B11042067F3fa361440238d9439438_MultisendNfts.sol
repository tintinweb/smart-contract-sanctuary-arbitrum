/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

// Multisend.sol
// SPDX-License-Identifier: MIT

//solc --bin --optimize MultisendNfts.sol
pragma solidity 0.8.16;

interface IERC721 {
	function transferFrom(address from, address to, uint256 id) external;
}

struct Recipient {
	uint256 tokenId;
	address recipient;
}

contract MultisendNfts {
	constructor(IERC721 _nft, Recipient[] memory _recipients) {
		for (uint i = 0; i < _recipients.length; i++)
			_nft.transferFrom(msg.sender, _recipients[i].recipient, _recipients[i].tokenId);
	}
}