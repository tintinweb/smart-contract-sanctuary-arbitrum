// SPDX-License-Identifier: MIT
// Creator: Rui Maximo
// Owner: curie.io
pragma solidity ^0.8.15;

// https://github.com/estarriolvetch/ERC721Psi
import "./ERC721Psi.sol";
import "./AccessControl.sol";

// to install ERC721Psi:
// npm install --save-dev erc721psi

contract Curie is ERC721Psi, AccessControl {
    uint256 lastTokenId;
    address[] authorizedMarketplaces;
    string public baseURI;
    string private key;
    mapping(uint256 => string) curieIDs;

    bytes32 public constant MINTER = keccak256("MINTER_ROLE");

    event ModifiedMarketplace(address[] list);
    event MarketplaceListCleared();

    constructor(string memory uri, string memory apiKey) ERC721Psi("Curie", "CURIE") {
        baseURI = uri;
        key = apiKey;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER, _msgSender());
    }

    function supportsInterface(bytes4 interfaceID) public view override(ERC721Psi, AccessControl) returns (bool) {
        return (
            ERC721Psi.supportsInterface(interfaceID) ||
            AccessControl.supportsInterface(interfaceID)
        );
    }

    function mint(address to, string memory id) external onlyRole(MINTER) returns (uint256) {
        _safeMint(to, 1);
        uint256 tokenId = lastTokenId;
        curieIDs[tokenId] = id;
        lastTokenId += 1;
        return tokenId;
    }

    function batchMint(string[] memory ids) external onlyRole(MINTER) returns (uint256) {
        _safeMint(msg.sender, ids.length);
        uint256 tokenId = lastTokenId;
        for (uint256 i = 0; i < ids.length; ++i) {
            curieIDs[tokenId + i] = ids[i];
        }
        lastTokenId += ids.length;
        return tokenId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string memory curieId = curieIDs[tokenId];
        require(bytes(curieId).length !=0, "Invalid token ID");
        return string(abi.encodePacked(baseURI, curieId, "?api_key=", key));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI; 
    }

    function setBaseURI(string memory newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    function setApiKey(string memory newKey) external onlyRole(DEFAULT_ADMIN_ROLE) {
        key = newKey;
    }

    function setMarketplace(address [] calldata authorizedList) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < authorizedList.length; i++) {
            authorizedMarketplaces.push(authorizedList[i]);
        }
        emit ModifiedMarketplace(authorizedList);
    }
    
    function getMarketplace() external view returns (address[] memory) {
        return authorizedMarketplaces;
    }

    function clearMarketplace() external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete authorizedMarketplaces;
        emit MarketplaceListCleared();
    }
}