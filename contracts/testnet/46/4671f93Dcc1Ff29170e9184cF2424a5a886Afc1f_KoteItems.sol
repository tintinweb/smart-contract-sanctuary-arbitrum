// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract KoteItems is ERC1155, Ownable {

    address BRIDGE_ADDRESS;
    string tokenURI = "ipfs://Qmb38d2NQ4tVr31fyFnPoiFPnZsEyru1PndDmojiN27Jkr/";


    modifier onlyBridge() {
        require(msg.sender == BRIDGE_ADDRESS, "Not bridge address");
        _;
    }

    constructor() ERC1155("Kote Items") {
        
    }

    function adminMint(address[] memory wallets, uint256[] memory ids, uint256[] memory amounts) public onlyOwner {

        for(uint i = 0; i < wallets.length; i++)
            _mint(wallets[i], ids[i], amounts[i], "");
    }

    function mint(address wallet, uint256 id, uint256 amount) public onlyBridge {
        _mint(wallet, id, amount, "");
    }

    function burn(address wallet, uint256 id, uint256 amount) public onlyBridge {
        _burn(wallet, id, amount);
    }

    function uri(uint256 tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(tokenURI, Strings.toString(tokenId), ".json"));
    }

    function setURI(string memory _URI) public onlyOwner {
        tokenURI = _URI;
    }

    function setBridgeContract(address bridge) public onlyOwner {
        BRIDGE_ADDRESS = bridge;
    }


}