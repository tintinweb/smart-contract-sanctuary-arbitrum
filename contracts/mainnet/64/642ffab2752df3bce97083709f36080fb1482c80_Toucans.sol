// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract Toucans is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string private baseURI;
    bool public isMintingEnabled = false;
    uint256 public mintIndex = 0;
    mapping(address => bool) public minted;

    modifier canMint {
        require(isMintingEnabled, "Minting is disabled");
        _;
    }

    constructor() ERC721("Government Toucans", "TOUCAN") {}

    function mint() public canMint {
        require(minted[msg.sender] == false, "Wallet has already minted a toucan");
        _safeMint(msg.sender, mintIndex++);
        minted[msg.sender] = true;
    }

    function setMintingEnabled(bool _mintingEnabled) external onlyOwner {
        isMintingEnabled = _mintingEnabled;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }
}