// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Extension} from "0xrails/extension/Extension.sol";
import {NFTMetadataRouter} from "./NFTMetadataRouter.sol";

contract NFTMetadataRouterExtension is NFTMetadataRouter, Extension {
    /*=======================
        CONTRACT METADATA
    =======================*/

    constructor(address router) Extension() NFTMetadataRouter(router) {}

    function _contractRoute() internal pure override returns (string memory route) {
        return "extension";
    }

    /*===============
        EXTENSION
    ===============*/

    /// @inheritdoc Extension
    function getAllSelectors() public pure override returns (bytes4[] memory selectors) {
        selectors = new bytes4[](2);
        selectors[0] = this.ext_contractURI.selector;
        selectors[1] = this.ext_tokenURI.selector;
        return selectors;
    }

    /// @inheritdoc Extension
    function signatureOf(bytes4 selector) public pure override returns (string memory) {
        if (selector == this.ext_contractURI.selector) {
            return "ext_contractURI()";
        } else if (selector == this.ext_tokenURI.selector) {
            return "ext_tokenURI(uint256)";
        } else {
            return "";
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtension} from "./interface/IExtension.sol";

abstract contract Extension is IExtension {
    constructor() {
        getAllSignatures(); // verify selectors properly synced
    }

    /// @inheritdoc IExtension
    function signatureOf(bytes4 selector) public pure virtual returns (string memory signature) {}

    /// @inheritdoc IExtension
    function getAllSelectors() public pure virtual returns (bytes4[] memory selectors) {}

    /// @inheritdoc IExtension
    function getAllSignatures() public pure returns (string[] memory signatures) {
        bytes4[] memory selectors = getAllSelectors();
        uint256 len = selectors.length;
        signatures = new string[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = selectors[i];
            string memory signature = signatureOf(selector);
            require(bytes4(keccak256(abi.encodePacked(signature))) == selector, "SELECTOR_SIGNATURE_MISMATCH");
            signatures[i] = signature;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {INFTMetadata} from "./INFTMetadata.sol";
import {IMetadataRouter} from "../../../metadataRouter/IMetadataRouter.sol";

contract NFTMetadataRouter is INFTMetadata {
    address public immutable metadataRouter;

    constructor(address _metadataRouter) {
        metadataRouter = _metadataRouter;
    }

    /// @dev Returns the contract URI for this contract, a modern standard for NFTs
    /// @notice Intended to be invoked in the context of a delegatecall
    function contractURI() public view virtual returns (string memory uri) {
        return IMetadataRouter(metadataRouter).uriOf(_contractRoute(), address(this));
    }

    function _contractRoute() internal pure virtual returns (string memory route) {
        return "contract";
    }

    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc INFTMetadata
    function ext_contractURI() external view returns (string memory uri) {
        return IMetadataRouter(metadataRouter).uriOf("collection", address(this));
    }

    /// @inheritdoc INFTMetadata
    function ext_tokenURI(uint256 tokenId) external view returns (string memory uri) {
        return IMetadataRouter(metadataRouter).tokenURI(address(this), tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtension {
    /// @dev Function to get the signature string for a specific function selector.
    /// @param selector The function selector to query.
    /// @return signature The signature string for the given function.
    function signatureOf(bytes4 selector) external pure returns (string memory signature);

    /// @dev Function to get an array of all recognized function selectors.
    /// @return selectors An array containing all 4-byte function selectors.
    function getAllSelectors() external pure returns (bytes4[] memory selectors);

    /// @dev Function to get an array of all recognized function signature strings.
    /// @return signatures An array containing all function signature strings.
    function getAllSignatures() external pure returns (string[] memory signatures);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface INFTMetadata {
    /// @dev Function to extend the `contractURI()` function
    /// @notice Intended to be invoked in the context of a delegatecall
    function ext_contractURI() external view returns (string memory uri);

    /// @dev Function to extend the `tokenURI()` function
    /// @notice Intended to be invoked in the context of a delegatecall
    function ext_tokenURI(uint256 tokenId) external view returns (string memory uri);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMetadataRouter {
    // events
    event DefaultURIUpdated(string uri);
    event RouteURIUpdated(string route, string uri);
    event ContractRouteURIUpdated(string route, string uri, address indexed contractAddress);

    /// @dev Get the base URI for a specific route and contract address.
    /// @param route The name of the route.
    /// @param contractAddress The address of the contract for which to request a URI.
    /// @return '' The base URI for the specified route and contract address.
    /// @notice If a route-specific URI is not configured for the contract address, the default URI will be used.
    function baseURI(string memory route, address contractAddress) external view returns (string memory);

    /// @dev Get the default URI for cases where no specific URI is configured.
    /// @return '' The default URI.
    function defaultURI() external view returns (string memory);

    /// @dev Get the URI for the MetadataRouter contract itself.
    /// @return uri The URI for the MetadataRouter contract.
    function contractURI() external view returns (string memory uri);

    /// @dev Get the URI configured for a specific route.
    /// @param route The name of the route.
    /// @return uri The URI configured for the specified route.
    function routeURI(string memory route) external view returns (string memory);

    /// @dev Get the URI configured for a specific route and contract address.
    /// @param route The name of the route.
    /// @param contractAddress The address of the contract for which to request a URI.
    /// @return '' The URI configured for the specified route and contract address.
    function contractRouteURI(string memory route, address contractAddress) external view returns (string memory);

    /// @dev Get the full URI for a specific route and contract address.
    /// @param route The name of the route.
    /// @param contractAddress The address of the contract for which to request a URI.
    /// @return '' The full URI for the specified route and contract address.
    function uriOf(string memory route, address contractAddress) external view returns (string memory);

    /// @dev Get the full URI for a specific route and contract address, with additional appended data.
    /// @param route The name of the route.
    /// @param contractAddress The address of the contract for which the URI is requested.
    /// @param appendData Additional data to append to the URI.
    /// @return '' The full URI with appended data for the specified route and contract address.
    function uriOf(string memory route, address contractAddress, string memory appendData)
        external
        view
        returns (string memory);

    /// @dev Get the token URI for an NFT tokenId within a specific collection.
    /// @param collection The address of the NFT collection contract.
    /// @param tokenId The ID of the NFT token within the collection.
    /// @return '' The token URI for the specified NFT token.
    function tokenURI(address collection, uint256 tokenId) external view returns (string memory);

    /// @dev Set the default URI to be used when no specific URI is configured.
    /// @param uri The new default URI.
    /// @notice Only the contract owner can set the default URI.
    function setDefaultURI(string memory uri) external;

    /// @dev Set the URI for a specific route.
    /// @param uri The new URI to be configured for the route.
    /// @param route The name of the route.
    /// @notice Only the contract owner can set route-specific URIs.
    function setRouteURI(string memory uri, string memory route) external;

    /// @dev Set the URI for a specific route and contract address.
    /// @param uri The new URI to be configured for the route and contract address.
    /// @param route The name of the route.
    /// @param contractAddress The address of the contract for which the URI is configured.
    /// @notice Only the contract owner can set contract-specific URIs.
    function setContractRouteURI(string memory uri, string memory route, address contractAddress) external;
}