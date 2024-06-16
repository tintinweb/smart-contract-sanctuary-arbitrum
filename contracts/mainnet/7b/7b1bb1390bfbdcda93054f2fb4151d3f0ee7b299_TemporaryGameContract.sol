/**
 *Submitted for verification at Arbiscan.io on 2024-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface GameNFTcollection {
    function mintMaterial(address player, uint256 contentID, uint256 amount) external;
    function mintContent(address player, uint256 contentGroup) external returns (uint256);
    function mintConcreteNFTcontent(address player, uint256 contentID) external returns (uint256);
    function setNFTskin(address player, uint256 skin, uint256 NFT_ID) external returns (uint256);
    function burnContent(address player, uint256 NFT_ID, uint256 amount) external;
    }


contract TemporaryGameContract {

    address private _owner;
    constructor() {_owner = msg.sender;}
    modifier onlyOwner() {if (_owner != msg.sender) {revert genericError();} _;}
    GameNFTcollection public AstrineaNFTcollection;
    error genericError();

    function setNFTcontract(GameNFTcollection NFTcollection) external onlyOwner {AstrineaNFTcollection = NFTcollection;}
    function mintMaterial(address player, uint256 contentID, uint256 amount) external onlyOwner {
        AstrineaNFTcollection.mintMaterial(player, contentID, amount);
    }
    function mintContent(address player, uint256 contentGroup, uint256 runs) external onlyOwner {
        for (uint256 i = 1; i <= runs; i++) { AstrineaNFTcollection.mintContent(player, contentGroup);}
    }
    function mintConcreteNFTcontent(address player, uint256 contentID) external onlyOwner {
        AstrineaNFTcollection.mintConcreteNFTcontent(player, contentID);
    }
    function burnContent(address player, uint256 NFT_ID, uint256 amount) external onlyOwner {
        AstrineaNFTcollection.burnContent(player, NFT_ID, amount);
    }
    function setNFTskin(uint256 skin, uint256 NFT_ID) external {
        address player = msg.sender;
        AstrineaNFTcollection.setNFTskin(player, skin, NFT_ID);
    }
}