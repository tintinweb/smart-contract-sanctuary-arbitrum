pragma solidity ^0.8.0;

import "./PortalNFT.sol";
import "./Constants.sol";
import "./Ownable.sol";

contract PortalNFTMinter is Ownable, Constants {
	uint[3] public prices;
	uint[3] public mintingLimits;
	uint[3] public mintedAmounts;

	PortalNFT public immutable nft;

	event PortalNFTMinted(address indexed owner, uint indexed id, uint number);

	constructor(string memory name, string memory symbol, string memory uri) {
        mintedAmounts = [0, 0, 0];
        mintingLimits = [20, 15, 10]; 
        prices = [0.0025 ether, 0.0060 ether, 0.0100 ether];

        /*mintingLimits[Constants.COMMON] = 20;// 2000;
        mintingLimits[Constants.RARE] = 15;//1250;
        mintingLimits[Constants.LEGENDARY] = 10;//750;

        prices[Constants.COMMON] = 0.025 ether; //25 ether;
        prices[Constants.RARE] = 0.060 ether; //60 ether;
        prices[Constants.LEGENDARY] = 0.100 ether; //100 ether*/

        nft = new PortalNFT(name, symbol, uri);
    }

    function mint(uint id) external payable {
    	require(msg.value >= prices[id], "Not enough FTM");
    	require(id >= Constants.COMMON && id <= Constants.LEGENDARY, "Not valid id");

    	uint currentlyMinted = mintedAmounts[id];
    	require(currentlyMinted < mintingLimits[id], "Mint limit");
    	mintedAmounts[id] = currentlyMinted + 1;
    	nft.mint(_msgSender(), id, 1, "");

    	emit PortalNFTMinted(_msgSender(), id, currentlyMinted);
    }

    function withdraw() external onlyOwner {
    	payable(msg.sender).transfer(address(this).balance);
    }

    function allPrices() public view returns (uint[3] memory) {
    	return prices;
    }

    function allMintinfLimits() public view returns (uint[3] memory) {
    	return mintingLimits;
    }

    function allMintedAmounts() public view returns (uint[3] memory) {
    	return mintedAmounts;
    }

    receive() external payable {}

    fallback() external payable {}

}