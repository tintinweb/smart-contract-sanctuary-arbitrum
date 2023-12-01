// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGuard} from "0xrails/guard/interface/IGuard.sol";
import {IERC721} from "0xrails/cores/ERC721/interface/IERC721.sol";

/// @title GroupOS OnePerAddressGuard Contract
/// @author symmetry (@symmtry69)
/// @notice This contract serves as a guard pattern implementation, similar to that of Gnosis Safe contracts,
/// designed to ensure that an address can only own one ERC-721 token at a time.
contract OnePerAddressGuard is IGuard {
    error OnePerAddress(address owner, uint256 balance);

    /*===========
        VIEWS
    ===========*/

    /// @dev Hook to perform pre-call checks and return guard information.
    /// @param data The data associated with the action, including relevant parameters.
    /// @return checkBeforeData Additional data to be passed to the `checkAfter` function.
    function checkBefore(address, bytes calldata data) external view returns (bytes memory checkBeforeData) {
        // (address operator, address from, address to, uint256 startTokenId, uint256 quantity)
        (,, address owner,, uint256 quantity) = abi.decode(data, (address, address, address, uint256, uint256));

        uint256 balanceBefore = IERC721(msg.sender).balanceOf(owner);
        if (balanceBefore + quantity > 1) {
            revert OnePerAddress(owner, balanceBefore + quantity);
        }

        return abi.encode(owner); // only need to pass the owner forward to checkAfter
    }

    /// @dev Hook to perform post-call checks.
    /// @param checkBeforeData Data passed from the `checkBefore` function.
    function checkAfter(bytes calldata checkBeforeData, bytes calldata) external view {
        address owner = abi.decode(checkBeforeData, (address));
        uint256 balanceAfter = IERC721(msg.sender).balanceOf(owner);
        if (balanceAfter > 1) revert OnePerAddress(owner, balanceAfter);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGuard {
    function checkBefore(address operator, bytes calldata data) external view returns (bytes memory checkBeforeData);
    function checkAfter(bytes calldata checkBeforeData, bytes calldata executionData) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721 {
    // events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // errors
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApprovalInvalidOperator();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    error MintERC2309QuantityExceedsLimit();
    error OwnershipNotInitializedForExtraData();
    error ExceedsMaxMintBatchSize(uint256 quantity);

    // ERC721 spec
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // base
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function totalBurned() external view returns (uint256);
    function numberMinted(address tokenOwner) external view returns (uint256);
    function numberBurned(address tokenOwner) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}