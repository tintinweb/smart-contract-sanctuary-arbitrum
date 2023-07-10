// STARLAB LAYER 0 BRIDGE
// ARBITRUM

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./NonblockingLzApp.sol";

error NotTokenOwner();
error InsufficientGas();
error SupplyExceeded();

contract StarLabLayer0 is Ownable, ERC721, NonblockingLzApp {
    uint256 public counter;
    uint public mintcost = 0.0003 ether;

    event ReceivedNFT(
        uint16 _srcChainId,
        address _from,
        uint256 _tokenId,
        uint256 counter
    );

    constructor(
        address _endpoint
    ) ERC721("StarLab 0", "STAR") NonblockingLzApp(_endpoint) {}

    function mint() external payable {
        require(msg.value >= mintcost, "Starlab : Not enough ether sent");
        _mint(
            msg.sender,
            (uint256(keccak256(abi.encode(counter, block.timestamp))) %
                10000000) + 1
        );
        unchecked {
            ++counter;
        }
    }

    function safeWithdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function crossChain(uint16 dstChainId, uint256 tokenId) public payable {
        if (msg.sender != ownerOf(tokenId)) revert NotTokenOwner();

        // Remove NFT on current chain
        unchecked {
            --counter;
        }
        _burn(tokenId);

        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        if (msg.value <= messageFee) revert InsufficientGas();

        _lzSend(
            dstChainId,
            payload,
            payable(msg.sender),
            address(0x0),
            adapterParams,
            msg.value
        );
    }

    function setMintCost(uint _mintcost) public onlyOwner {
        mintcost = _mintcost;
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 /*_nonce*/,
        bytes memory _payload
    ) internal override {
        address from;
        assembly {
            from := mload(add(_srcAddress, 20))
        }
        (address toAddress, uint256 tokenId) = abi.decode(
            _payload,
            (address, uint256)
        );

        _mint(toAddress, tokenId);
        unchecked {
            ++counter;
        }
        emit ReceivedNFT(_srcChainId, from, tokenId, counter);
    }

    // Endpoint.sol estimateFees() returns the fees for the message
    function estimateFees(
        uint16 dstChainId,
        uint256 tokenId
    ) external view returns (uint256) {
        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        uint256 gasForLzReceive = 350000;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            dstChainId,
            address(this),
            payload,
            false,
            adapterParams
        );
        return messageFee;
    }
}