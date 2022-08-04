pragma solidity ^0.8.0;

import "./JoyNFT.sol";
import "./Constants.sol";
import "./Ownable.sol";

contract JoyNFTMinter is Ownable, Constants {
	uint[4] public mintingLimits;
	uint[4] public mintedAmounts;

	JoyNFT public immutable nft;

	event JoyNFTMinted(address indexed owner, uint indexed id, uint number);

	constructor(string memory name, string memory symbol, string memory uri) {
        mintedAmounts = [0, 0, 0];
        mintingLimits = [300, 300, 300, 300]; 
        nft = new JoyNFT(name, symbol, uri);
    }

    function mint(uint id) external {
    	require(id >= Constants.COMMON && id <= Constants.EPIC, "Not valid id");

    	uint currentlyMinted = mintedAmounts[id];
    	require(currentlyMinted < mintingLimits[id], "Mint limit");
    	mintedAmounts[id] = currentlyMinted + 1;
    	nft.mint(_msgSender(), id, 1, "");

    	emit JoyNFTMinted(_msgSender(), id, currentlyMinted);
    }

    function withdraw() external onlyOwner {
    	payable(msg.sender).transfer(address(this).balance);
    }

    function allMintinfLimits() public view returns (uint[4] memory) {
    	return mintingLimits;
    }

    function allMintedAmounts() public view returns (uint[4] memory) {
    	return mintedAmounts;
    }

    receive() external payable {}

    fallback() external payable {}

}