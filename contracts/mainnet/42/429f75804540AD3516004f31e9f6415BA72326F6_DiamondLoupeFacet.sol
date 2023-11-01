// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC165} from "../../interfaces/ERC/IERC165.sol";
import {IERC1271} from "../../interfaces/ERC/IERC1271.sol";
import {IERC677Receiver} from "../../interfaces/ERC/IERC677Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {LibLoupe} from "../../libraries/LibLoupe.sol";
import {LibUtils} from "../../libraries/LibUtils.sol";
import {IDiamondCut} from "../../facets/base/interfaces/IDiamondCut.sol";
import {IStorageLoupe} from "./interfaces/IStorageLoupe.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";

/**
 * @title DiamondLoupe Facet
 * @dev DiamondLoupe contract compatible with EIP-2535
 * @author David Yongjun Kim (@Powerstream3604)
 */
contract DiamondLoupeFacet is IDiamondLoupe, IStorageLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools off-chain.

    /**
     * @notice Gets all facets and their selectors.
     * @dev Barz uses a special architecture called default fallback handler. Default Fallback handler is used as a middleware
     *      that holds the mapping of facet function selector and facet address that Barz uses. This helps Barz to reduce
     *      significant amount of gas during the initialization process.
     *      Hence, this method aggregates both the facet information from DefaulFallbackHandler and in diamond storage and shows the data to users.
     * @return facets_ Facet
     */
    function facets() public view override returns (Facet[] memory facets_) {
        Facet[] memory defaultFacet = LibDiamond
            .diamondStorage()
            .defaultFallbackHandler
            .facets();
        Facet[] memory _facets = LibLoupe.facets();
        uint256 numFacets = _facets.length;
        bytes4[] memory keys;
        address[] memory values;
        for (uint256 i; i < numFacets; ) {
            uint256 selectorsLength = _facets[i].functionSelectors.length;
            for (uint256 j; j < selectorsLength; ) {
                (keys, values) = LibUtils.setValue(
                    keys,
                    values,
                    _facets[i].functionSelectors[j],
                    _facets[i].facetAddress
                );
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        {
            bool iIncrement;
            for (uint256 i; i < defaultFacet.length; ) {
                bool jIncrement;
                for (
                    uint256 j;
                    j < defaultFacet[i].functionSelectors.length;

                ) {
                    if (
                        LibUtils.getValue(
                            keys,
                            values,
                            defaultFacet[i].functionSelectors[j]
                        ) != address(0)
                    ) {
                        if (defaultFacet[i].functionSelectors.length == 1) {
                            defaultFacet = LibUtils.removeFacetElement(
                                defaultFacet,
                                i
                            );
                            iIncrement = true;
                            break;
                        }
                        defaultFacet[i].functionSelectors = LibUtils
                            .removeElement(
                                defaultFacet[i].functionSelectors,
                                j
                            );
                        jIncrement = true;
                    }
                    if (!jIncrement) {
                        unchecked {
                            ++j;
                        }
                    } else {
                        jIncrement = false;
                    }
                }
                if (!iIncrement) {
                    unchecked {
                        ++i;
                    }
                } else {
                    iIncrement = false;
                }
            }
        }
        {
            uint256 facetLength = numFacets + defaultFacet.length;
            facets_ = new Facet[](facetLength);
            uint256 defaultFacetIndex;
            for (uint256 i; i < facetLength; ) {
                if (i < numFacets) {
                    facets_[i] = _facets[i];
                    bool jIncrementor;
                    for (uint256 j; j < defaultFacet.length; ) {
                        if (
                            facets_[i].facetAddress ==
                            defaultFacet[j].facetAddress
                        ) {
                            facets_[i].functionSelectors = LibUtils.mergeArrays(
                                _facets[i].functionSelectors,
                                defaultFacet[j].functionSelectors
                            );
                            defaultFacet = LibUtils.removeFacetElement(
                                defaultFacet,
                                j
                            );
                            jIncrementor = true;
                            {
                                facets_ = LibUtils.removeFacetElement(
                                    facets_,
                                    facets_.length - 1
                                );
                            }
                            --facetLength;
                        }
                        if (!jIncrementor) {
                            unchecked {
                                ++j;
                            }
                        } else {
                            jIncrementor = false;
                        }
                    }
                } else {
                    facets_[i] = defaultFacet[defaultFacetIndex];
                    ++defaultFacetIndex;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Gets all the function selectors provided by a facet.
     * @param _facet The facet address.
     * @return facetFunctionSelectors_
     */
    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        Facet[] memory facet = facets();
        uint256 facetLength = facet.length;
        for (uint256 i; i < facetLength; ) {
            if (facet[i].facetAddress == _facet)
                return facet[i].functionSelectors;
            unchecked {
                ++i;
            }
        }
        return facetFunctionSelectors_;
    }

    /**
     * @notice Get all the facet addresses used by Barz.
     * @return facetAddresses_
     */
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        Facet[] memory facet = facets();
        uint256 facetLength = facet.length;
        facetAddresses_ = new address[](facetLength);
        for (uint256 i; i < facetLength; ) {
            facetAddresses_[i] = facet[i].facetAddress;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Gets the facet that supports the given selector.
     * @dev If facet is not found return address(0).
     * @param _functionSelector The function selector.
     * @return facetAddress_ The facet address.
     */
    function facetAddress(
        bytes4 _functionSelector
    ) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
        if (facetAddress_ == address(0)) {
            facetAddress_ = IDiamondLoupe(ds.defaultFallbackHandler)
                .facetAddress(_functionSelector);
        }
    }

    /**
     * @notice SupportInterface to be compatible with EIP 165
     * @param _interfaceId Interface ID for detecting the interface
     * @return isSupported Bool value showing if the standard is supported in the contract
     */
    function supportsInterface(
        bytes4 _interfaceId
    ) external view override returns (bool isSupported) {
        isSupported =
            _interfaceId == type(IERC165).interfaceId ||
            _interfaceId == IDiamondCut.diamondCut.selector ||
            _interfaceId == type(IDiamondLoupe).interfaceId ||
            _interfaceId == type(IERC1155Receiver).interfaceId ||
            _interfaceId == type(IERC721Receiver).interfaceId ||
            _interfaceId == type(IERC777Recipient).interfaceId ||
            _interfaceId == IERC1271.isValidSignature.selector ||
            _interfaceId == type(IERC677Receiver).interfaceId ||
            LibDiamond.diamondStorage().supportedInterfaces[_interfaceId];
    }

    /**
     * @notice Returns the facet from the diamond storage. This excludes the facets from the default fallback handler
     * @return facets_ Facet information attached directly to diamond storage
     */
    function facetsFromStorage()
        external
        view
        override
        returns (Facet[] memory facets_)
    {
        facets_ = LibLoupe.facets();
    }

    /**
     * @notice Returns the facet address attached to the given function selector. This excludes the facets from the default fallback handler
     * @param _functionSelector Function selector to fetch the facet address from diamond storage
     * @return facetAddress_ Facet address mapped with the function selector
     */
    function facetAddressFromStorage(
        bytes4 _functionSelector
    ) external view override returns (address facetAddress_) {
        facetAddress_ = LibLoupe.facetAddress(_functionSelector);
    }

    /**
     * @notice Returns all facet addresses attached directly to diamond storage. This excludes the facets from the default fallback handler
     * @return facetAddresses_ All facet addresses attached directly to diamond storage
     */
    function facetAddressesFromStorage()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        facetAddresses_ = LibLoupe.facetAddresses();
    }

    /**
     * @notice Returns function selectors of given facet address attached directly to diamond storage. This excludes the facets from the default fallback handler
     * @param _facet Facet address to fetch the facet function selectors from diamond storage
     * @return facetFunctionSelectors_ Facet function selectors of the given facet address
     */
    function facetFunctionSelectorsFromStorage(
        address _facet
    ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        facetFunctionSelectors_ = LibLoupe.facetFunctionSelectors(_facet);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

/**
 * @title DiamondCut Facet Interface
 * @dev Interface for DiamondCut Facet responsible for adding/removing/replace facets in Barz
 * @author David Yongjun Kim (@Powerstream3604)
 */
interface IDiamondCut {
    error DiamondCutFacet__InvalidRouteWithGuardian();
    error DiamondCutFacet__InvalidRouteWithoutGuardian();
    error DiamondCutFacet__InvalidArrayLength();
    error DiamondCutFacet__InsufficientApprovers();
    error DiamondCutFacet__InvalidApprover();
    error DiamondCutFacet__InvalidApproverSignature();
    error DiamondCutFacet__InvalidApprovalValidationPeriod();
    error DiamondCutFacet__CannotRevokeUnapproved();
    error DiamondCutFacet__GuardianApprovalNotRequired();
    error DiamondCutFacet__LackOfOwnerApproval();
    error DiamondCutFacet__OwnerAlreadyApproved();
    error DiamondCutFacet__DuplicateApproval();

    event DiamondCutApproved(
        FacetCut[] diamondCut,
        address init,
        bytes initCalldata
    );
    event DiamondCutApprovalRevoked(
        FacetCut[] diamondCut,
        address init,
        bytes initCalldata
    );

    event SupportsInterfaceUpdated(bytes4 interfaceId, bool _lag);

    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param diamondCut Contains the facet addresses and function selectors
    /// @param init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external;

    function updateSupportsInterface(bytes4 interfaceId, bool flag) external;

    function diamondCutWithGuardian(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata,
        address[] calldata approvers,
        bytes[] calldata signatures
    ) external;

    function approveDiamondCut(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external;

    function revokeDiamondCutApproval(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external;

    function getDiamondCutApprovalCountWithTimeValidity(
        bytes32 diamondCutHash
    ) external view returns (uint256);

    function getOwnerCutApprovalWithTimeValidity(
        bytes32 diamondCutHash
    ) external view returns (bool);

    function isCutApproved(
        bytes32 diamondCutHash,
        address approver
    ) external view returns (bool);

    function getDiamondCutHash(
        FacetCut[] calldata diamondCut,
        address init,
        bytes calldata _calldata
    ) external view returns (bytes32);

    function getDiamondCutNonce() external view returns (uint128);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(
        address _facet
    ) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {IDiamondLoupe} from "./IDiamondLoupe.sol";

/**
 * @title LoupeFromStorage Interface
 * @dev Interface contract to function as a loupe facet directly attached to diamond storage of Barz
 * @author David Yongjun Kim (@Powerstream3604)
 */
interface IStorageLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facetsFromStorage()
        external
        view
        returns (IDiamondLoupe.Facet[] memory);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    function facetFunctionSelectorsFromStorage(
        address _facet
    ) external view returns (bytes4[] memory);

    /// @notice Get all the facet addresses used by a diamond.
    function facetAddressesFromStorage()
        external
        view
        returns (address[] memory);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    function facetAddressFromStorage(
        bytes4 _functionSelector
    ) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

interface IERC1271 {
    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

interface IERC677Receiver {
    function onTokenTransfer(
        address sender,
        uint value,
        bytes calldata data
    ) external pure returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {IDiamondCut} from "../facets/base/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../facets/base/interfaces/IDiamondLoupe.sol";

error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("trustwallet.barz.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Default Fallback Handler of the barz.
        IDiamondLoupe defaultFallbackHandler;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enforceIsSelf() internal view {
        require(msg.sender == address(this), "LibDiamond: Caller not self");
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );

            unchecked {
                facetIndex++;
            }
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(
            _selectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Add facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "LibDiamondCut: Can't add function that already exists"
                );
                // add facet for selector
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                // " << 5 is the same as multiplying by 32 ( * 32)
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot =
                    (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
                "LibDiamondCut: Replace facet has no code"
            );
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(
                    oldFacetAddress != address(this),
                    "LibDiamondCut: Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "LibDiamondCut: Can't replace function with same function"
                );
                require(
                    oldFacetAddress != address(0),
                    "LibDiamondCut: Can't replace function that doesn't exist"
                );
                // replace old facet address
                ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);

                unchecked {
                    selectorIndex++;
                }
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "LibDiamondCut: Remove facet address must be address(0)"
            );
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; ) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(
                        address(bytes20(oldFacet)) != address(0),
                        "LibDiamondCut: Can't remove function that doesn't exist"
                    );
                    // only useful if immutable functions exist
                    require(
                        address(bytes20(oldFacet)) != address(this),
                        "LibDiamondCut: Can't remove immutable function"
                    );
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    // " << 5 is the same as multiplying by 32 ( * 32)
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }

                unchecked {
                    selectorIndex++;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(
            _init,
            "LibDiamondCut: _init address has no code"
        );
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    function restrictionsFacet() internal view returns (address facetAddress_) {
        bytes4 selector = bytes4(
            keccak256("verifyRestrictions(address,address,uint256,bytes)")
        );
        facetAddress_ = address(
            bytes20(LibDiamond.diamondStorage().facets[selector])
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {IDiamondLoupe} from "../facets/base/interfaces/IDiamondLoupe.sol";
import {LibDiamond} from "./LibDiamond.sol";

/**
 * @title LibLoupe
 * @dev Internal Library to provide utility feature for reading the state of diamond facets
 * @author David Yongjun Kim (@Powerstream3604)
 */
library LibLoupe {
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets()
        internal
        view
        returns (IDiamondLoupe.Facet[] memory facets_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new IDiamondLoupe.Facet[](ds.selectorCount);
        uint16[] memory numFacetSelectors = new uint16[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                // " << 5 is the same as multiplying by 32 ( * 32)
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[
                            numFacetSelectors[facetIndex]
                        ] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](
                    ds.selectorCount
                );
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(
        address _facet
    ) internal view returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                // " << 5 is the same as multiplying by 32 ( * 32)
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    _facetFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        internal
        view
        returns (address[] memory facetAddresses_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                // " << 5 is the same as multiplying by 32 ( * 32)
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(
        bytes4 _functionSelector
    ) internal view returns (address facetAddress_) {
        facetAddress_ = address(
            bytes20(LibDiamond.diamondStorage().facets[_functionSelector])
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import {IDiamondLoupe} from "../facets/base/interfaces/IDiamondLoupe.sol";

library LibUtils {
    // Internal utility functions
    function mergeArrays(
        bytes4[] memory _array1,
        bytes4[] memory _array2
    ) internal pure returns (bytes4[] memory) {
        uint256 length1 = _array1.length;
        uint256 length2 = _array2.length;
        bytes4[] memory mergedArray = new bytes4[](length1 + length2);

        for (uint256 i; i < length1; ) {
            mergedArray[i] = _array1[i];
            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < length2; ) {
            mergedArray[length1 + i] = _array2[i];
            unchecked {
                ++i;
            }
        }

        return mergedArray;
    }

    function removeFacetElement(
        IDiamondLoupe.Facet[] memory _facets,
        uint256 _index
    ) internal pure returns (IDiamondLoupe.Facet[] memory) {
        require(_index < _facets.length, "Invalid index");
        require(_facets.length != 0, "Invalid array");

        // Create a new array with a length of `_facets.length - 1`
        IDiamondLoupe.Facet[] memory newArray = new IDiamondLoupe.Facet[](
            _facets.length - 1
        );
        uint256 newArrayLength = newArray.length;
        // Iterate over the original array, skipping the element at the specified `index`
        for (uint256 i; i < newArrayLength; ) {
            if (i < _index) {
                newArray[i] = _facets[i];
            } else {
                newArray[i] = _facets[i + 1];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    function removeElement(
        bytes4[] memory _array,
        uint256 _index
    ) internal pure returns (bytes4[] memory) {
        require(_index < _array.length, "Invalid index");
        require(_array.length != 0, "Invalid array");

        bytes4[] memory newArray = new bytes4[](_array.length - 1);
        uint256 newArrayLength = newArray.length;
        for (uint256 i; i < newArrayLength; ) {
            if (i < _index) {
                newArray[i] = _array[i];
            } else {
                newArray[i] = _array[i + 1];
            }
            unchecked {
                ++i;
            }
        }

        return newArray;
    }

    function setValue(
        bytes4[] memory _keys,
        address[] memory _values,
        bytes4 _key,
        address _value
    ) internal pure returns (bytes4[] memory, address[] memory) {
        uint256 index = findIndex(_keys, _key);
        uint256 keysLength = _keys.length;
        if (index < keysLength) {
            _values[index] = _value;
        } else {
            // Create new storage arrays
            bytes4[] memory newKeys = new bytes4[](keysLength + 1);
            address[] memory newValues = new address[](_values.length + 1);

            // Copy values to the new storage arrays
            for (uint256 i; i < keysLength; ) {
                newKeys[i] = _keys[i];
                newValues[i] = _values[i];

                unchecked {
                    ++i;
                }
            }

            // Add the new key-value pair
            newKeys[keysLength] = _key;
            newValues[_values.length] = _value;

            return (newKeys, newValues);
        }

        // If the key already exists, return the original arrays
        return (_keys, _values);
    }

    function getValue(
        bytes4[] memory _keys,
        address[] memory _values,
        bytes4 _key
    ) internal pure returns (address) {
        uint256 index = findIndex(_keys, _key);
        if (index >= _keys.length) return address(0);

        return _values[index];
    }

    function findIndex(
        bytes4[] memory _keys,
        bytes4 _key
    ) internal pure returns (uint256) {
        uint256 keysLength = _keys.length;
        for (uint256 i; i < keysLength; ) {
            if (_keys[i] == _key) {
                return i;
            }
            unchecked {
                ++i;
            }
        }
        return keysLength;
    }
}