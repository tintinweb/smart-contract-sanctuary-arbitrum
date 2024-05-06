/**
 *Submitted for verification at Arbiscan.io on 2024-05-06
*/

/*

FFFFF  TTTTTTT  M   M         GGGGG  U    U  RRRRR     U    U
FF       TTT   M M M M       G       U    U  RR   R    U    U
FFFFF    TTT   M  M  M      G  GGG   U    U  RRRRR     U    U
FF       TTT   M  M  M   O  G    G   U    U  RR R      U    U
FF       TTT   M     M       GGGGG    UUUU   RR  RRR    UUUU



						Contact us at:
			https://discord.com/invite/QpyfMarNrV
					https://t.me/FTM1337

	Community Mediums:
		https://medium.com/@ftm1337
		https://twitter.com/ftm1337

	SPDX-License-Identifier: UNLICENSED


	eTHENA.sol

	eTHENA is a Liquid Staking Derivate for veTHE (Vote-Escrowed Thena NFT).
	It can be minted by burning (veTHE) veNFTs.
	eTHENA is an ERC20 based token.
	It can be staked with Guru Network to earn pure BNB instead of multiple small tokens.
	eTHENA can be further deposited into Kompound Protocol to mint iTHENA.

	iTHENA is a doubly-compounding interest-bearing veTHE at its core.
	iTHENA is an ERC4626 based token, which also adheres to the EIP20 Standard.
	iTHENA uses eTHENA's BNB yield to buyback more eTHENA from the open-market via JIT Aggregation.

	The price (in THE) to mint eTHENA goes up every epoch due to positive rebasing.
	This property gives iTHENA a "hyper-compounding" double-exponential trajectory against raw THE tokens.

*/

pragma solidity 0.8.9;

interface IVotingEscrow {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}
interface IManager {
	function dao() external view returns (address);
	function VENFT() external view returns (address);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

contract elTokenRedeemVault {

	IManager public elTokenManager;
	IVotingEscrow public VENFT;

	function initialize(IManager _m) external {
		require(address(elTokenManager)==address(0), "initialized");
		elTokenManager = _m;
		require(msg.sender == elTokenManager.dao(), "!dao");
		VENFT = IVotingEscrow(elTokenManager.VENFT());
	}

	function dao() public view returns (address) {
		return elTokenManager.dao();
	}

	function reclaim(address _sendTo, uint _nftId) external {
		require(msg.sender== address(elTokenManager) || msg.sender == dao());
		VENFT.safeTransferFrom(address(this), _sendTo, _nftId);
	}

    function onERC721Received(address, address,  uint256, bytes calldata) external view returns (bytes4) {
        require(msg.sender == address(VENFT), "!veToken");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

}