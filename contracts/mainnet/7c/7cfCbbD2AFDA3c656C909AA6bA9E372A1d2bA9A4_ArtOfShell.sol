// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract ArtOfShell is ERC721, Ownable {

    using Strings for uint256;

    string private baseURI;
    uint256 public mintIndex = 0;

    constructor(string memory name, string memory symbol, string memory uri) ERC721(name, symbol) {
        baseURI = uri;
    }

    function mint(address to, uint256 mintAmount) external onlyOwner {

        for(uint8 i = 0; i < mintAmount; ++i) {
            _safeMint(to, mintIndex);
            mintIndex++;
        }

    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
}