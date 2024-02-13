pragma solidity ^0.8.0;

import "./ERC404.sol";
import "./Strings.sol";

contract PANDORA is ERC404 {
    string public dataURI = "https://404arb.github.io/pandora/";
    string public baseTokenURI;
    string public baseExtension = ".gif";

    constructor(
        address _owner
    ) ERC404("Arb404", "Arb404", 18, 10000, _owner) {
        balanceOf[_owner] = 10000 * 10 ** 18;
    }

    function setDataURI(string memory _dataURI) public onlyOwner {
        dataURI = _dataURI;
    }

    function setTokenURI(string memory _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }

    function setExtension(string memory _baseExtension) public onlyOwner {
        baseExtension = _baseExtension;
    }

    function setNameSymbol(
        string memory _name,
        string memory _symbol
    ) public onlyOwner {
        _setNameSymbol(_name, _symbol);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = dataURI;
        return
            bytes(currentBaseURI).length > 0
                ? string( abi.encodePacked( currentBaseURI, "pandora", baseExtension ) ) : "";
    }
}