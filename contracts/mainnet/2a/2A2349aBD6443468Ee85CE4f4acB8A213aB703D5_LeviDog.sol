// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface ERC20 {
  function balanceOf(address account) external returns(uint256);
}

interface LeveragedCollections {
  function mint(address account, uint256 tokenID) external;  
}

//// THE RULES TO MINT THE LEVI DOG NFT THAT IS GOING TO BE TOKEN ID # 1.
contract LeviDog {

  ERC20 public constant LEVI_CONTRACT = ERC20(0x954ac1c73e16c77198e83C088aDe88f6223F3d44);
  LeveragedCollections public immutable erc1155Contract;

  mapping(address => uint256) public accountToMinted; 

  error LeviDog_Mint_Only_Once();
  error LeviDog_Insufficient_Levi();

  constructor(address collectionContract) {
    erc1155Contract = LeveragedCollections(collectionContract);
  }

  function requestMint() external {
    if(accountToMinted[msg.sender] == 1) revert LeviDog_Mint_Only_Once();

    if(LEVI_CONTRACT.balanceOf(msg.sender) < 100 ether) revert LeviDog_Insufficient_Levi();

    accountToMinted[msg.sender] = 1;

    erc1155Contract.mint(msg.sender, 1);
  }
}