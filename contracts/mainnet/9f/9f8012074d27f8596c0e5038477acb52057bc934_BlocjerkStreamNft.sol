// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SignerRole.sol";
import "./ERC1155Base.sol";

/// @title blocjerk stream nft contract supports erc1155
contract BlocjerkStreamNft is Ownable, SignerRole, ERC1155Base {
    string public name;
    string public symbol;
    address public controller;

    uint256 private expiredTime;

    error notController();

    constructor(
        string memory _name,
        string memory _symbol,
        address signer,
        address _controller,
        string memory contractURI,
        string memory tokenURIPrefix
    ) ERC1155Base(contractURI, tokenURIPrefix) {
        expiredTime = 300;
        name = _name;
        symbol = _symbol;
        controller = _controller;
        _addSigner(signer);
        _registerInterface(bytes4(keccak256("MINT_WITH_ADDRESS")));
    }

    function mintFromController(
        uint256 id,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 supply,
        string memory uri,
        address creator
    ) public {
        if (msg.sender != controller) revert notController();
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            isSigner(
                ecrecover(toEthSignedMessageHash(keccak256(abi.encodePacked(this, id, chainId, supply, timestamp))), v, r, s)
            ),
            "signer should sign tokenId"
        );
        require(timestamp > block.timestamp - expiredTime, "token id expired");
        Fee[] memory fees;
        _mint(id, fees, supply, uri, creator);
    }

    function mint(
        uint256 id,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s,
        Fee[] memory fees,
        uint256 supply,
        string memory uri
    ) public {
        uint256 chainId;
        uint256 _timestamp = timestamp;
        uint256 _tokenId = id;
        assembly {
            chainId := chainid()
        }
        require(
            isSigner(
                ecrecover(toEthSignedMessageHash(keccak256(abi.encodePacked(this, _tokenId, chainId, supply, _timestamp))), v, r, s)
            ),
            "signer should sign tokenId"
        );
        require(_timestamp > block.timestamp - expiredTime, "token id expired");
        _mint(_tokenId, fees, supply, uri, address(0x0));
    }

    function setController(address _controller) external onlyOwner {
        controller = _controller;
    }

    function setExpiredTime(uint256 _expiredTime) external onlyOwner {
        expiredTime = _expiredTime;
    }

    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function encodePackedData(uint256 id) public view returns (bytes32) {
        return keccak256(abi.encodePacked(this, id));
    }

    function getecrecover(uint256 id, uint8 v, bytes32 r, bytes32 s) public view returns (address) {
        return ecrecover(toEthSignedMessageHash(keccak256(abi.encodePacked(this, id))), v, r, s);
    }
}