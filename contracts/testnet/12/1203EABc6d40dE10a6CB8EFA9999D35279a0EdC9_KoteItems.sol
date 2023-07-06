// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract KoteItems is ERC1155, Ownable {

    string tokenURI = "ipfs://QmZ1uycD52AD5oSA16bUFJR5s3nzgBuJKFi7VXdcCWF1WN/";

    mapping(address => bool) public admin;

    modifier onlyAdmin() {
        require(admin[msg.sender], "Not admin");
        _;
    }

    constructor() ERC1155("Kote Items") {
        
    }

    function adminMint(address[] memory wallets, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {

        for(uint i = 0; i < wallets.length; i++)
            for(uint j = 0; j < ids.length; j++)
                _mint(wallets[i], ids[j], amounts[j], "");
    }

    function mint(address wallet, uint256 id, uint256 amount) public onlyAdmin {
        _mint(wallet, id, amount, "");
    }

    function burn(address wallet, uint256 id, uint256 amount) public onlyAdmin {
        _burn(wallet, id, amount);
    }

    function uri(uint256 tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(tokenURI, Strings.toString(tokenId), ".json"));
    }

    function setURI(string memory _URI) public onlyOwner {
        tokenURI = _URI;
    }

    function setAdmin(address wallet, bool state) public onlyOwner {
        admin[wallet] = state;
    }


}