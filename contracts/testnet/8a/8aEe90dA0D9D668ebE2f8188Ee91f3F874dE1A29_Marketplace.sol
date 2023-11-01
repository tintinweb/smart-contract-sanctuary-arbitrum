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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./interface/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
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
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

interface IContractMetadata {
    /// @dev Returns the metadata URI of the contract.
    function contractURI() external view returns (string memory);

    /**
     *  @dev Sets contract URI for the storefront-level metadata of the contract.
     *       Only module admin can call this function.
     */
    function setContractURI(string calldata _uri) external;

    /// @dev Emitted when the contract URI is updated.
    event ContractURIUpdated(string prevURI, string newURI);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IERC2771Context {
    function isTrustedForwarder(address forwarder) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
interface IMulticall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IPermissions {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./IPermissions.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IPermissionsEnumerable is IPermissions {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * [forum post](https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296)
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 *  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about platform fees, if desired.
 */

interface IPlatformFee {
    /// @dev Fee type variants: percentage fee and flat fee
    enum PlatformFeeType {
        Bps,
        Flat
    }

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event PlatformFeeInfoUpdated(address indexed platformFeeRecipient, uint256 platformFeeBps);

    /// @dev Emitted when the flat platform fee is updated.
    event FlatPlatformFeeUpdated(address platformFeeRecipient, uint256 flatFee);

    /// @dev Emitted when the platform fee type is updated.
    event PlatformFeeTypeUpdated(PlatformFeeType feeType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyEngineV1 is IERC165 {
    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * View only version of getRoyalty
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyaltyView(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external view returns (address payable[] memory recipients, uint256[] memory amounts);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Read royalty info for a token.
 *      Supports RoyaltyEngineV1 and RoyaltyRegistry by manifold.xyz.
 */
interface IRoyaltyPayments is IERC165 {
    /// @dev Emitted when the address of RoyaltyEngine is set or updated.
    event RoyaltyEngineUpdated(address indexed previousAddress, address indexed newAddress);

    /**
     * Get the royalty for a given token (address, id) and value amount.
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts);

    /**
     * Set or override RoyaltyEngine address
     *
     * @param _royaltyEngineAddress - RoyaltyEngineV1 address
     */
    function setRoyaltyEngine(address _royaltyEngineAddress) external;
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../lib/TWAddress.sol";
import "./interface/IMulticall.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
contract Multicall is IMulticall {
    /**
     *  @notice Receives and executes a batch of function calls on this contract.
     *  @dev Receives and executes a batch of function calls on this contract.
     *
     *  @param data The bytes data that makes up the batch of function calls to execute.
     *  @return results The bytes data that makes up the result of the batch of function calls executed.
     */
    function multicall(bytes[] calldata data) external virtual override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = TWAddress.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IContractMetadata.sol";

/**
 *  @author  thirdweb.com
 *
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */

library ContractMetadataStorage {
    /// @custom:storage-location erc7201:contract.metadata.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("contract.metadata.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant CONTRACT_METADATA_STORAGE_POSITION =
        0x4bc804ba64359c0e35e5ed5d90ee596ecaa49a3a930ddcb1470ea0dd625da900;

    struct Data {
        /// @notice Returns the contract metadata URI.
        string contractURI;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = CONTRACT_METADATA_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract ContractMetadata is IContractMetadata {
    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function setContractURI(string memory _uri) external override {
        if (!_canSetContractURI()) {
            revert("Not authorized");
        }

        _setupContractURI(_uri);
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setupContractURI(string memory _uri) internal {
        string memory prevURI = _contractMetadataStorage().contractURI;
        _contractMetadataStorage().contractURI = _uri;

        emit ContractURIUpdated(prevURI, _uri);
    }

    /// @notice Returns the contract metadata URI.
    function contractURI() public view virtual override returns (string memory) {
        return _contractMetadataStorage().contractURI;
    }

    /// @dev Returns the AccountPermissions storage.
    function _contractMetadataStorage() internal pure returns (ContractMetadataStorage.Data storage data) {
        data = ContractMetadataStorage.data();
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../interface/IERC2771Context.sol";
import "./Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */

library ERC2771ContextStorage {
    /// @custom:storage-location erc7201:erc2771.context.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("erc2771.context.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ERC2771_CONTEXT_STORAGE_POSITION =
        0x82aadcdf5bea62fd30615b6c0754b644e71b6c1e8c55b71bb927ad005b504f00;

    struct Data {
        mapping(address => bool) trustedForwarder;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = ERC2771_CONTEXT_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable {
    function __ERC2771Context_init(address[] memory trustedForwarder) internal onlyInitializing {
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address[] memory trustedForwarder) internal onlyInitializing {
        for (uint256 i = 0; i < trustedForwarder.length; i++) {
            _erc2771ContextStorage().trustedForwarder[trustedForwarder[i]] = true;
        }
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _erc2771ContextStorage().trustedForwarder[forwarder];
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    /// @dev Returns the ERC2771ContextStorage storage.
    function _erc2771ContextStorage() internal pure returns (ERC2771ContextStorage.Data storage data) {
        data = ERC2771ContextStorage.data();
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from "../ReentrancyGuard.sol";
import "../Initializable.sol";

contract ReentrancyGuardInit is Initializable {
    uint256 private constant _NOT_ENTERED = 1;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        ReentrancyGuardStorage.Data storage data = ReentrancyGuardStorage.data();
        data._status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

import "../../lib/TWAddress.sol";

library InitStorage {
    /// @custom:storage-location erc7201:init.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("init.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 constant INIT_STORAGE_POSITION = 0x322cf19c484104d3b1a9c2982ebae869ede3fa5f6c4703ca41b9a48c76ee0300;

    /// @dev Layout of the entrypoint contract's storage.
    struct Data {
        uint8 initialized;
        bool initializing;
    }

    /// @dev Returns the entrypoint contract's data at the relevant storage location.
    function data() internal pure returns (Data storage data_) {
        bytes32 position = INIT_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract Initializable {
    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        uint8 _initialized = _initStorage().initialized;
        bool _initializing = _initStorage().initializing;

        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!TWAddress.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initStorage().initialized = 1;
        if (isTopLevelCall) {
            _initStorage().initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initStorage().initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        uint8 _initialized = _initStorage().initialized;
        bool _initializing = _initStorage().initializing;

        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initStorage().initialized = version;
        _initStorage().initializing = true;
        _;
        _initStorage().initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initStorage().initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        uint8 _initialized = _initStorage().initialized;
        bool _initializing = _initStorage().initializing;

        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initStorage().initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /// @dev Returns the InitStorage storage.
    function _initStorage() internal pure returns (InitStorage.Data storage data) {
        data = InitStorage.data();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPermissions.sol";
import "../../lib/TWStrings.sol";

/**
 *  @title   Permissions
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms
 */

library PermissionsStorage {
    /// @custom:storage-location erc7201:permissions.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("permissions.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant PERMISSIONS_STORAGE_POSITION =
        0x0a7b0f5c59907924802379ebe98cdc23e2ee7820f63d30126e10b3752010e500;

    struct Data {
        /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
        mapping(bytes32 => mapping(address => bool)) _hasRole;
        /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
        mapping(bytes32 => bytes32) _getRoleAdmin;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = PERMISSIONS_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

contract Permissions is IPermissions {
    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     *  @notice         Checks whether an account has a particular role.
     *  @dev            Returns `true` if `account` has been granted `role`.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _permissionsStorage()._hasRole[role][account];
    }

    /**
     *  @notice         Checks whether an account has a particular role;
     *                  role restrictions can be swtiched on and off.
     *
     *  @dev            Returns `true` if `account` has been granted `role`.
     *                  Role restrictions can be swtiched on and off:
     *                      - If address(0) has ROLE, then the ROLE restrictions
     *                        don't apply.
     *                      - If address(0) does not have ROLE, then the ROLE
     *                        restrictions will apply.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(bytes32 role, address account) public view returns (bool) {
        if (!_permissionsStorage()._hasRole[role][address(0)]) {
            return _permissionsStorage()._hasRole[role][account];
        }

        return true;
    }

    /**
     *  @notice         Returns the admin role that controls the specified role.
     *  @dev            See {grantRole} and {revokeRole}.
     *                  To change a role's admin, use {_setRoleAdmin}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(bytes32 role) external view override returns (bytes32) {
        return _permissionsStorage()._getRoleAdmin[role];
    }

    /**
     *  @notice         Grants a role to an account, if not previously granted.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleGranted Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account to which the role is being granted.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        _checkRole(_permissionsStorage()._getRoleAdmin[role], _msgSender());
        if (_permissionsStorage()._hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    /**
     *  @notice         Revokes role from an account.
     *  @dev            Caller must have admin role for the `role`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        _checkRole(_permissionsStorage()._getRoleAdmin[role], _msgSender());
        _revokeRole(role, account);
    }

    /**
     *  @notice         Revokes role from the account.
     *  @dev            Caller must have the `role`, with caller being the same as `account`.
     *                  Emits {RoleRevoked Event}.
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account  Address of the account from which the role is being revoked.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        if (_msgSender() != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _permissionsStorage()._getRoleAdmin[role];
        _permissionsStorage()._getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        _permissionsStorage()._hasRole[role][account] = true;
        emit RoleGranted(role, account, _msgSender());
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        _checkRole(role, account);
        delete _permissionsStorage()._hasRole[role][account];
        emit RoleRevoked(role, account, _msgSender());
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_permissionsStorage()._hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(bytes32 role, address account) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        TWStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        TWStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function _msgSender() internal view virtual returns (address sender) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /// @dev Returns the Permissions storage.
    function _permissionsStorage() internal pure returns (PermissionsStorage.Data storage data) {
        data = PermissionsStorage.data();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPermissionsEnumerable.sol";
import "./Permissions.sol";

/**
 *  @title   PermissionsEnumerable
 *  @dev     This contracts provides extending-contracts with role-based access control mechanisms.
 *           Also provides interfaces to view all members with a given role, and total count of members.
 */

library PermissionsEnumerableStorage {
    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant PERMISSIONS_ENUMERABLE_STORAGE_POSITION =
        keccak256(abi.encode(uint256(keccak256("permissions.enumerable.storage")) - 1)) & ~bytes32(uint256(0xff));

    /**
     *  @notice A data structure to store data of members for a given role.
     *
     *  @param index    Current index in the list of accounts that have a role.
     *  @param members  map from index => address of account that has a role
     *  @param indexOf  map from address => index which the account has.
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    struct Data {
        /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
        mapping(bytes32 => RoleMembers) roleMembers;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = PERMISSIONS_ENUMERABLE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

contract PermissionsEnumerable is IPermissionsEnumerable, Permissions {
    /**
     *  @notice         Returns the role-member from a list of members for a role,
     *                  at a given index.
     *  @dev            Returns `member` who has `role`, at `index` of role-members list.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index    Index in list of current members for the role.
     *
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(bytes32 role, uint256 index) external view override returns (address member) {
        uint256 currentIndex = _permissionsEnumerableStorage().roleMembers[role].index;
        uint256 check;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (_permissionsEnumerableStorage().roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = _permissionsEnumerableStorage().roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (
                hasRole(role, address(0)) && i == _permissionsEnumerableStorage().roleMembers[role].indexOf[address(0)]
            ) {
                check += 1;
            }
        }
    }

    /**
     *  @notice         Returns total number of accounts that have a role.
     *  @dev            Returns `count` of accounts that have `role`.
     *                  See struct {RoleMembers}, and mapping {roleMembers}
     *
     *  @param role     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *
     *  @return count   Total number of accounts that have `role`
     */
    function getRoleMemberCount(bytes32 role) external view override returns (uint256 count) {
        uint256 currentIndex = _permissionsEnumerableStorage().roleMembers[role].index;

        for (uint256 i = 0; i < currentIndex; i += 1) {
            if (_permissionsEnumerableStorage().roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    ///      See {_removeMember}
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    ///      See {_addMember}
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        uint256 idx = _permissionsEnumerableStorage().roleMembers[role].index;
        _permissionsEnumerableStorage().roleMembers[role].index += 1;

        _permissionsEnumerableStorage().roleMembers[role].members[idx] = account;
        _permissionsEnumerableStorage().roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = _permissionsEnumerableStorage().roleMembers[role].indexOf[account];

        delete _permissionsEnumerableStorage().roleMembers[role].members[idx];
        delete _permissionsEnumerableStorage().roleMembers[role].indexOf[account];
    }

    /// @dev Returns the PermissionsEnumerable storage.
    function _permissionsEnumerableStorage() internal pure returns (PermissionsEnumerableStorage.Data storage data) {
        data = PermissionsEnumerableStorage.data();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IPlatformFee.sol";

/**
 *  @author  thirdweb.com
 */
library PlatformFeeStorage {
    /// @custom:storage-location erc7201:platform.fee.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("platform.fee.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant PLATFORM_FEE_STORAGE_POSITION =
        0xc0c34308b4a2f4c5ee9af8ba82541cfb3c33b076d1fd05c65f9ce7060c64c400;

    struct Data {
        /// @dev The address that receives all platform fees from all sales.
        address platformFeeRecipient;
        /// @dev The % of primary sales collected as platform fees.
        uint16 platformFeeBps;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = PLATFORM_FEE_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

/**
 *  @author  thirdweb.com
 *
 *  @title   Platform Fee
 *  @notice  Thirdweb's `PlatformFee` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *           the recipient of platform fee and the platform fee basis points, and lets the inheriting contract perform conditional logic
 *           that uses information about platform fees, if desired.
 */

abstract contract PlatformFee is IPlatformFee {
    /// @dev Returns the platform fee recipient and bps.
    function getPlatformFeeInfo() public view override returns (address, uint16) {
        return (_platformFeeStorage().platformFeeRecipient, uint16(_platformFeeStorage().platformFeeBps));
    }

    /**
     *  @notice         Updates the platform fee recipient and bps.
     *  @dev            Caller should be authorized to set platform fee info.
     *                  See {_canSetPlatformFeeInfo}.
     *                  Emits {PlatformFeeInfoUpdated Event}; See {_setupPlatformFeeInfo}.
     *
     *  @param _platformFeeRecipient   Address to be set as new platformFeeRecipient.
     *  @param _platformFeeBps         Updated platformFeeBps.
     */
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) external override {
        if (!_canSetPlatformFeeInfo()) {
            revert("Not authorized");
        }
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a contract admin update the platform fee recipient and bps
    function _setupPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps) internal {
        if (_platformFeeBps > 10_000) {
            revert("Exceeds max bps");
        }
        if (_platformFeeRecipient == address(0)) {
            revert("Invalid recipient");
        }

        _platformFeeStorage().platformFeeBps = uint16(_platformFeeBps);
        _platformFeeStorage().platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Returns the PlatformFee storage.
    function _platformFeeStorage() internal pure returns (PlatformFeeStorage.Data storage data) {
        data = PlatformFeeStorage.data();
    }

    /// @dev Returns whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    /// @custom:storage-location erc7201:reentrancy.guard.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("reentrancy.guard.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant REENTRANCY_GUARD_STORAGE_POSITION =
        0x1d281c488dae143b6ea4122e80c65059929950b9c32f17fc57be22089d9c3b00;

    struct Data {
        uint256 _status;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = REENTRANCY_GUARD_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    constructor() {
        _reentrancyGuardStorage()._status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_reentrancyGuardStorage()._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyGuardStorage()._status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyGuardStorage()._status = _NOT_ENTERED;
    }

    /// @dev Returns the ReentrancyGuard storage.
    function _reentrancyGuardStorage() internal pure returns (ReentrancyGuardStorage.Data storage data) {
        data = ReentrancyGuardStorage.data();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "../interface/IRoyaltyPayments.sol";
import "../interface/IRoyaltyEngineV1.sol";
import { IERC2981 } from "../../eip/interface/IERC2981.sol";

library RoyaltyPaymentsStorage {
    /// @custom:storage-location erc7201:royalty.payments.storage
    /// @dev keccak256(abi.encode(uint256(keccak256("royalty.payments.storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 public constant ROYALTY_PAYMENTS_STORAGE_POSITION =
        0xc802b338f3fb784853cf3c808df5ff08335200e394ea2c687d12571a91045000;

    struct Data {
        /// @dev The address of RoyaltyEngineV1, replacing the one set during construction.
        address royaltyEngineAddressOverride;
    }

    function royaltyPaymentsStorage() internal pure returns (Data storage royaltyPaymentsData) {
        bytes32 position = ROYALTY_PAYMENTS_STORAGE_POSITION;
        assembly {
            royaltyPaymentsData.slot := position
        }
    }
}

/**
 *  @author  thirdweb.com
 *
 *  @title   Royalty Payments
 *  @notice  Thirdweb's `RoyaltyPayments` is a contract extension to be used with a marketplace contract.
 *           It exposes functions for fetching royalty settings for a token.
 *           It Supports RoyaltyEngineV1 and RoyaltyRegistry by manifold.xyz.
 */

abstract contract RoyaltyPaymentsLogic is IRoyaltyPayments {
    // solhint-disable-next-line var-name-mixedcase
    address immutable ROYALTY_ENGINE_ADDRESS;

    constructor(address _royaltyEngineAddress) {
        // allow address(0) in case RoyaltyEngineV1 not present on a network
        require(
            _royaltyEngineAddress == address(0) ||
                IERC165(_royaltyEngineAddress).supportsInterface(type(IRoyaltyEngineV1).interfaceId),
            "Doesn't support IRoyaltyEngineV1 interface"
        );

        ROYALTY_ENGINE_ADDRESS = _royaltyEngineAddress;
    }

    /**
     * Get the royalty for a given token (address, id) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param tokenAddress - The address of the token
     * @param tokenId      - The id of the token
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(
        address tokenAddress,
        uint256 tokenId,
        uint256 value
    ) external returns (address payable[] memory recipients, uint256[] memory amounts) {
        address royaltyEngineAddress = getRoyaltyEngineAddress();

        if (royaltyEngineAddress == address(0)) {
            try IERC2981(tokenAddress).royaltyInfo(tokenId, value) returns (address recipient, uint256 amount) {
                require(amount < value, "Invalid royalty amount");

                recipients = new address payable[](1);
                amounts = new uint256[](1);
                recipients[0] = payable(recipient);
                amounts[0] = amount;
            } catch {}
        } else {
            (recipients, amounts) = IRoyaltyEngineV1(royaltyEngineAddress).getRoyalty(tokenAddress, tokenId, value);
        }
    }

    /**
     * Set or override RoyaltyEngine address
     *
     * @param _royaltyEngineAddress - RoyaltyEngineV1 address
     */
    function setRoyaltyEngine(address _royaltyEngineAddress) external {
        if (!_canSetRoyaltyEngine()) {
            revert("Not authorized");
        }

        require(
            _royaltyEngineAddress != address(0) &&
                IERC165(_royaltyEngineAddress).supportsInterface(type(IRoyaltyEngineV1).interfaceId),
            "Doesn't support IRoyaltyEngineV1 interface"
        );

        _setupRoyaltyEngine(_royaltyEngineAddress);
    }

    /// @dev Returns original or overridden address for RoyaltyEngineV1
    function getRoyaltyEngineAddress() public view returns (address royaltyEngineAddress) {
        RoyaltyPaymentsStorage.Data storage data = RoyaltyPaymentsStorage.royaltyPaymentsStorage();
        address royaltyEngineOverride = data.royaltyEngineAddressOverride;
        royaltyEngineAddress = royaltyEngineOverride != address(0) ? royaltyEngineOverride : ROYALTY_ENGINE_ADDRESS;
    }

    /// @dev Lets a contract admin update the royalty engine address
    function _setupRoyaltyEngine(address _royaltyEngineAddress) internal {
        RoyaltyPaymentsStorage.Data storage data = RoyaltyPaymentsStorage.royaltyPaymentsStorage();
        address currentAddress = data.royaltyEngineAddressOverride;

        data.royaltyEngineAddressOverride = _royaltyEngineAddress;

        emit RoyaltyEngineUpdated(currentAddress, _royaltyEngineAddress);
    }

    /// @dev Returns whether royalty engine address can be set in the given execution context.
    function _canSetRoyaltyEngine() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev Collection of functions related to the address type
 */
library TWAddress {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * [EIP1884](https://eips.ethereum.org/EIPS/eip-1884) increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

/// @author thirdweb

/**
 * @dev String operations.
 */
library TWStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

//   $$\     $$\       $$\                 $$\                         $$\
//   $$ |    $$ |      \__|                $$ |                        $$ |
// $$$$$$\   $$$$$$$\  $$\  $$$$$$\   $$$$$$$ |$$\  $$\  $$\  $$$$$$\  $$$$$$$\
// \_$$  _|  $$  __$$\ $$ |$$  __$$\ $$  __$$ |$$ | $$ | $$ |$$  __$$\ $$  __$$\
//   $$ |    $$ |  $$ |$$ |$$ |  \__|$$ /  $$ |$$ | $$ | $$ |$$$$$$$$ |$$ |  $$ |
//   $$ |$$\ $$ |  $$ |$$ |$$ |      $$ |  $$ |$$ | $$ | $$ |$$   ____|$$ |  $$ |
//   \$$$$  |$$ |  $$ |$$ |$$ |      \$$$$$$$ |\$$$$$\$$$$  |\$$$$$$$\ $$$$$$$  |
//    \____/ \__|  \__|\__|\__|       \_______| \_____\____/  \_______|\_______/

// ====== External imports ======
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ERC1155Holder, ERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

//  ==========  Internal imports    ==========
import { BaseRouter, IRouter, IRouterState } from "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter.sol";
import { ERC165 } from "../../../eip/ERC165.sol";

import "../../../extension/Multicall.sol";
import "../../../extension/upgradeable/Initializable.sol";
import "../../../extension/upgradeable/ContractMetadata.sol";
import "../../../extension/upgradeable/PlatformFee.sol";
import "../../../extension/upgradeable/PermissionsEnumerable.sol";
import "../../../extension/upgradeable/init/ReentrancyGuardInit.sol";
import "../../../extension/upgradeable/ERC2771ContextUpgradeable.sol";
import { RoyaltyPaymentsLogic } from "../../../extension/upgradeable/RoyaltyPayments.sol";

/**
 * @author  thirdweb.com
 */
contract MarketplaceV3 is
    Initializable,
    Multicall,
    BaseRouter,
    ContractMetadata,
    PlatformFee,
    PermissionsEnumerable,
    ReentrancyGuardInit,
    ERC2771ContextUpgradeable,
    RoyaltyPaymentsLogic,
    ERC721Holder,
    ERC1155Holder,
    ERC165
{
    /// @dev Only EXTENSION_ROLE holders can perform upgrades.
    bytes32 private constant EXTENSION_ROLE = keccak256("EXTENSION_ROLE");

    bytes32 private constant MODULE_TYPE = bytes32("MarketplaceV3");
    uint256 private constant VERSION = 3;

    /// @dev The address of the native token wrapper contract.
    address private immutable nativeTokenWrapper;

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    /// @dev We accept constructor params as a struct to avoid `Stack too deep` errors.
    struct MarketplaceConstructorParams {
        Extension[] extensions;
        address royaltyEngineAddress;
        address nativeTokenWrapper;
    }

    constructor(MarketplaceConstructorParams memory _marketplaceV3Params)
        BaseRouter(_marketplaceV3Params.extensions)
        RoyaltyPaymentsLogic(_marketplaceV3Params.royaltyEngineAddress)
    {
        nativeTokenWrapper = _marketplaceV3Params.nativeTokenWrapper;
        _disableInitializers();
    }

    receive() external payable {
        assert(msg.sender == nativeTokenWrapper); // only accept ETH via fallback from the native token wrapper contract
    }

    /// @dev Initializes the contract, like a constructor.
    function initialize(
        address _defaultAdmin,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _platformFeeRecipient,
        uint16 _platformFeeBps
    ) external initializer {
        // Initialize BaseRouter
        __BaseRouter_init();

        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __ERC2771Context_init(_trustedForwarders);

        // Initialize this contract's state.
        _setupContractURI(_contractURI);
        _setupPlatformFeeInfo(_platformFeeRecipient, _platformFeeBps);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _setupRole(EXTENSION_ROLE, _defaultAdmin);
        _setupRole(keccak256("LISTER_ROLE"), address(0));
        _setupRole(keccak256("ASSET_ROLE"), address(0));

        _setupRole(EXTENSION_ROLE, _defaultAdmin);
        _setRoleAdmin(EXTENSION_ROLE, EXTENSION_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        Generic contract logic
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /*///////////////////////////////////////////////////////////////
                        ERC 165 / 721 / 1155 logic
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165, ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IRouter).interfaceId ||
            interfaceId == type(IRouterState).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        Overridable Permissions
    //////////////////////////////////////////////////////////////*/

    /// @dev Checks whether platform fee info can be set in the given execution context.
    function _canSetPlatformFeeInfo() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Returns whether royalty engine address can be set in the given execution context.
    function _canSetRoyaltyEngine() internal view override returns (bool) {
        return _hasRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Checks whether an account has a particular role.
    function _hasRole(bytes32 _role, address _account) internal view returns (bool) {
        PermissionsStorage.Data storage data = PermissionsStorage.data();
        return data._hasRole[_role][_account];
    }

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return _hasRole(EXTENSION_ROLE, msg.sender);
    }

    function _msgSender() internal view override(ERC2771ContextUpgradeable, Permissions) returns (address sender) {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData() internal view override(ERC2771ContextUpgradeable, Permissions) returns (bytes calldata) {
        return ERC2771ContextUpgradeable._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IRouter.sol";

/// @title ERC-7504 Dynamic Contracts: Router.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Routes an incoming call to an appropriate implementation address.

abstract contract Router is IRouter {

    /**
	 *	@notice delegateCalls the appropriate implementation address for the given incoming function call.
	 *	@dev The implementation address to delegateCall MUST be retrieved from calling `getImplementationForFunction` with the
     *       incoming call's function selector.
	 */
    fallback() external payable virtual {
        address implementation = getImplementationForFunction(msg.sig);
        require(implementation != address(0), "Router: function does not exist.");
        _delegate(implementation);
    }

    /// @dev delegateCalls an `implementation` smart contract.
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
	 *	@notice Returns the implementation address to delegateCall for the given function selector.
	 *	@param _functionSelector The function selector to get the implementation address for.
	 *	@return implementation The implementation address to delegateCall for the given function selector.
	 */
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address implementation);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/// @title IExtension
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Provides an `Extension` abstraction for a router's implementation contracts.

interface IExtension {
    /*///////////////////////////////////////////////////////////////
                                Structs
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice An interface to describe an extension's metadata.
     *
     *  @param name             The unique name of the extension.
     *  @param metadataURI      The URI where the metadata for the extension lives.
     *  @param implementation   The implementation smart contract address of the extension.
     */
    struct ExtensionMetadata {
        string name;
        string metadataURI;
        address implementation;
    }

    /**
     *  @notice An interface to describe an extension's function.
     *
     *  @param functionSelector    The 4 byte selector of the function.
     *  @param functionSignature   Function signature as a string. E.g. "transfer(address,address,uint256)"
     */
    struct ExtensionFunction {
        bytes4 functionSelector;
        string functionSignature;
    }

    /**
     *  @notice An interface to describe an extension.
     *
     *  @param metadata     The extension's metadata; it's name, metadata URI and implementation contract address.
     *  @param functions    The functions that belong to the extension.
     */
    struct Extension {
        ExtensionMetadata metadata;
        ExtensionFunction[] functions;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtension.sol";

/// @title IExtensionManager
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage and API for managing a router's extensions.

interface IExtensionManager is IExtension {

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added.
    event ExtensionAdded(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is replaced.
    event ExtensionReplaced(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is removed.
    event ExtensionRemoved(string indexed name, Extension extension);

    /// @dev Emitted when a function is enabled i.e. made callable.
    event FunctionEnabled(string indexed name, bytes4 indexed functionSelector, ExtensionFunction extFunction, ExtensionMetadata extMetadata);

    /// @dev Emitted when a function is disabled i.e. made un-callable.
    event FunctionDisabled(string indexed name, bytes4 indexed functionSelector, ExtensionMetadata extMetadata);

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Add a new extension to the router.
     *  @param extension The extension to add.
     */
    function addExtension(Extension memory extension) external;

    /**
     *  @notice Fully replace an existing extension of the router.
     *  @dev The extension with name `extension.name` is the extension being replaced.
     *  @param extension The extension to replace or overwrite.
     */
    function replaceExtension(Extension memory extension) external;

    /**
     *  @notice Remove an existing extension from the router.
     *  @param extensionName The name of the extension to remove.
     */
    function removeExtension(string memory extensionName) external;

    /**
     *  @notice Enables a single function in an existing extension.
     *  @dev Makes the given function callable on the router.
     *
     *  @param extensionName The name of the extension to which `extFunction` belongs.
     *  @param extFunction The function to enable.
     */
    function enableFunctionInExtension(string memory extensionName, ExtensionFunction memory extFunction) external;
    
    /**
     *  @notice Disables a single function in an Extension.
     *
     *  @param extensionName The name of the extension to which the function of `functionSelector` belongs.
     *  @param functionSelector The function to disable.
     */
    function disableFunctionInExtension(string memory extensionName, bytes4 functionSelector) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-7504 Dynamic Contracts: IRouter.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Routes an incoming call to an appropriate implementation address.
/// @dev Fallback function delegateCalls `getImplementationForFunction(msg.sig)` for a given incoming call.
/// NOTE: The ERC-165 identifier for this interface is 0xce0b6013.

interface IRouter {

	/**
	 *	@notice delegateCalls the appropriate implementation address for the given incoming function call.
	 *	@dev The implementation address to delegateCall MUST be retrieved from calling `getImplementationForFunction` with the
     *       incoming call's function selector.
	 */
	fallback() external payable;

	/*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

	/**
	 *	@notice Returns the implementation address to delegateCall for the given function selector.
	 *	@param _functionSelector The function selector to get the implementation address for.
	 *	@return implementation The implementation address to delegateCall for the given function selector.
	 */
    function getImplementationForFunction(bytes4 _functionSelector) external view returns (address implementation);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtension.sol";

/// @title ERC-7504 Dynamic Contracts: IRouterState.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defines an API to expose a router's extensions.

interface IRouterState is IExtension {

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions of the Router.
     *  @return allExtensions An array of all extensions.
     */
    function getAllExtensions() external view returns (Extension[] memory allExtensions);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtension.sol";

/// @title IRouterStateGetters.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Helper view functions to inspect a router's state.

interface IRouterStateGetters is IExtension {

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the extension metadata for a given function.
     *  @param functionSelector The function selector to get the extension metadata for.
     *  @return metadata The extension metadata for a given function.
     */
    function getMetadataForFunction(bytes4 functionSelector) external view returns (ExtensionMetadata memory metadata);

    /**
     *  @notice Returns the extension metadata and functions for a given extension.
     *  @param extensionName The name of the extension to get the metadata and functions for.
     *  @return extension The extension metadata and functions for a given extension.
     */
    function getExtension(string memory extensionName) external view returns (Extension memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BaseRouterStorage
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage for base router

library BaseRouterStorage {

    /// @custom:storage-location erc7201:base.router.storage
    bytes32 public constant BASE_ROUTER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("base.router.storage")) - 1));

    struct Data {
        /// @dev Mapping used only for checking default extension validity in constructor.
        mapping(bytes4 => bool) functionMap;
        /// @dev Mapping used only for checking default extension validity in constructor.
        mapping(string => bool) extensionMap;
    }

    /// @dev Returns access to base router storage.
    function data() internal pure returns (Data storage data_) {
        bytes32 position = BASE_ROUTER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StringSet.sol";
import "../interface/IExtension.sol";

/// @title IExtensionManagerStorage
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage for managing a router's extensions.

library ExtensionManagerStorage {

    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant EXTENSION_MANAGER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("extension.manager.storage")) - 1));

    struct Data {
        /// @dev Set of names of all extensions of the router.
        StringSet.Set extensionNames;
        /// @dev Mapping from extension name => `Extension` i.e. extension metadata and functions.
        mapping(string => IExtension.Extension) extensions;
        /// @dev Mapping from function selector => metadata of the extension the function belongs to.
        mapping(bytes4 => IExtension.ExtensionMetadata) extensionMetadata;
    }

    /// @dev Returns access to the extension manager's storage.
    function data() internal pure returns (Data storage data_) {
        bytes32 position = EXTENSION_MANAGER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringSet {
    struct Set {
        // Storage of set values
        string[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(string => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, string memory value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, string memory value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, string memory value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (string memory) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (string[] memory) {
        return set._values;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, string memory value) internal returns (bool) {
        return _add(set, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Set storage set, string memory value) internal returns (bool) {
        return _remove(set, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Set storage set, string memory value) internal view returns (bool) {
        return _contains(set, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
        return _length(set);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Set storage set, uint256 index) internal view returns (string memory) {
        return _at(set, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (string[] memory) {
        return _values(set);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Router, IRouter } from "../core/Router.sol";
import { IRouterState } from "../interface/IRouterState.sol";
import { IRouterStateGetters } from "../interface/IRouterStateGetters.sol";
import { BaseRouterStorage } from "../lib/BaseRouterStorage.sol";
import { ExtensionManager } from "./ExtensionManager.sol";
import { StringSet } from "../lib/StringSet.sol";
import "lib/sstore2/contracts/SSTORE2.sol";

/// @title BaseRouter
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice A router with an API to manage its extensions.

abstract contract BaseRouter is Router, ExtensionManager {

    using StringSet for StringSet.Set;

    /// @notice The address where the router's default extension set is stored.
    address public immutable defaultExtensions;
    
    /// @notice Initialize the Router with a set of default extensions.
    constructor(Extension[] memory _extensions) {
        address pointer;
        if(_extensions.length > 0) {
            _validateExtensions(_extensions);
            pointer = SSTORE2.write(abi.encode(_extensions));
        }

        defaultExtensions = pointer;
    }

    /// @notice Initialize the Router with a set of default extensions.
    function __BaseRouter_init() internal {
        if(defaultExtensions == address(0)) {
            return;
        }
        
        bytes memory data = SSTORE2.read(defaultExtensions);
        Extension[] memory defaults = abi.decode(data, (Extension[]));

        // Unchecked since we already validated extensions in constructor.
        __BaseRouter_init_unchecked(defaults);
    }

    /// @notice Initializes the Router with a set of extensions.
    function __BaseRouter_init_checked(Extension[] memory _extensions) internal {
        _validateExtensions(_extensions);
        __BaseRouter_init_unchecked(_extensions);
    }

    /// @notice Initializes the Router with a set of extensions.
    function __BaseRouter_init_unchecked(Extension[] memory _extensions) internal {
        for(uint256 i = 0; i < _extensions.length; i += 1) {

            Extension memory extension = _extensions[i];
            // Store: new extension name.
            _extensionManagerStorage().extensionNames.add(extension.metadata.name);

            // 1. Store: metadata for extension.
            _setMetadataForExtension(extension.metadata.name, extension.metadata);

            uint256 len = extension.functions.length;
            for (uint256 j = 0; j < len; j += 1) {                
                // 2. Store: name -> extension.functions map
                _extensionManagerStorage().extensions[extension.metadata.name].functions.push(extension.functions[j]);
                // 3. Store: metadata for function.
                _setMetadataForFunction(extension.functions[j].functionSelector, extension.metadata);
            }

            emit ExtensionAdded(extension.metadata.name, extension.metadata.implementation, extension);
        }
    }

    /// @notice Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return getMetadataForFunction(_functionSelector).implementation;
    }

    /// @dev Validates default extensions.
    function _validateExtensions(Extension[] memory _extensions) internal {  
        uint256 len = _extensions.length;

        bool isValid = true;

        for (uint256 i = 0; i < len; i += 1) {
            isValid = _isValidExtension(_extensions[i]);
            if(!isValid) {
                break;
            }
        }
        require(isValid, "BaseRouter: invalid extension.");
    }

    function _isValidExtension(Extension memory _extension) internal returns (bool isValid) {
        isValid  = bytes(_extension.metadata.name).length > 0 // non-empty name
            && !BaseRouterStorage.data().extensionMap[_extension.metadata.name] // unused name
            && _extension.metadata.implementation != address(0); // non-empty implementation
        
        BaseRouterStorage.data().extensionMap[_extension.metadata.name] = true;

        if(!isValid) {
            return false;
        }
        
        uint256 len = _extension.functions.length;

        for(uint256 i = 0; i < len; i += 1) {

            if(!isValid) {
                break;
            }

            ExtensionFunction memory _extFunction = _extension.functions[i];

            /**
            *  Note: `bytes4(0)` is the function selector for the `receive` function.
            *        So, we maintain a special fn selector-signature mismatch check for the `receive` function.
            **/
            bool mismatch = false;
            if(_extFunction.functionSelector == bytes4(0)) {
                mismatch = keccak256(abi.encode(_extFunction.functionSignature)) != keccak256(abi.encode("receive()"));
            } else {
                mismatch = _extFunction.functionSelector !=
                    bytes4(keccak256(abi.encodePacked(_extFunction.functionSignature)));
            }

            // No fn signature-selector mismatch and no duplicate function.
            isValid = !mismatch && !BaseRouterStorage.data().functionMap[_extFunction.functionSelector];
            
            BaseRouterStorage.data().functionMap[_extFunction.functionSelector] = true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IExtensionManager.sol";
import "../interface/IRouterState.sol";
import "../interface/IRouterStateGetters.sol";
import "../lib/ExtensionManagerStorage.sol";

/// @title ExtensionManager
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage and API for managing a router's extensions.

abstract contract ExtensionManager is IExtensionManager, IRouterState, IRouterStateGetters {

    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Modifier
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks that a call to any external function is authorized.
    modifier onlyAuthorizedCall() {
        require(_isAuthorizedCallToUpgrade(), "ExtensionManager: unauthorized.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions of the Router.
     *  @return allExtensions An array of all extensions.
     */
    function getAllExtensions() external view virtual override returns (Extension[] memory allExtensions) {

        string[] memory names = _extensionManagerStorage().extensionNames.values();
        uint256 len = names.length;
        
        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allExtensions[i] = _getExtension(names[i]);
        }
    }

    /**
     *  @notice Returns the extension metadata for a given function.
     *  @param functionSelector The function selector to get the extension metadata for.
     *  @return metadata The extension metadata for a given function.
     */
    function getMetadataForFunction(bytes4 functionSelector) public view virtual returns (ExtensionMetadata memory) {
        return _extensionManagerStorage().extensionMetadata[functionSelector];
    }

    /**
     *  @notice Returns the extension metadata and functions for a given extension.
     *  @param extensionName The name of the extension to get the metadata and functions for.
     *  @return extension The extension metadata and functions for a given extension.
     */
    function getExtension(string memory extensionName) public view virtual returns (Extension memory) {
        return _getExtension(extensionName);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Add a new extension to the router.
     *  @param _extension The extension to add.
     */
    function addExtension(Extension memory _extension) public virtual onlyAuthorizedCall {    
        _addExtension(_extension);
    }

    /**
     *  @notice Fully replace an existing extension of the router.
     *  @dev The extension with name `extension.name` is the extension being replaced.
     *  @param _extension The extension to replace or overwrite.
     */
    function replaceExtension(Extension memory _extension) public virtual onlyAuthorizedCall {
        _replaceExtension(_extension);
    }

    /**
     *  @notice Remove an existing extension from the router.
     *  @param _extensionName The name of the extension to remove.
     */
    function removeExtension(string memory _extensionName) public virtual onlyAuthorizedCall {
        _removeExtension(_extensionName);
    }

    /**
     *  @notice Enables a single function in an existing extension.
     *  @dev Makes the given function callable on the router.
     *
     *  @param _extensionName The name of the extension to which `extFunction` belongs.
     *  @param _function The function to enable.
     */
    function enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function) public virtual onlyAuthorizedCall {
        _enableFunctionInExtension(_extensionName, _function);
    }

    /**
     *  @notice Disables a single function in an Extension.
     *
     *  @param _extensionName The name of the extension to which the function of `functionSelector` belongs.
     *  @param _functionSelector The function to disable.
     */
    function disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) public virtual onlyAuthorizedCall {
        _disableFunctionInExtension(_extensionName, _functionSelector);
    }
    
    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Add a new extension to the router.
    function _addExtension(Extension memory _extension) internal virtual {    
        // Check: extension namespace must not already exist.
        // Check: provided extension namespace must not be empty.
        // Check: provided extension implementation must be non-zero.
        // Store: new extension name.
        require(_canAddExtension(_extension), "ExtensionManager: cannot add extension.");

        // 1. Store: metadata for extension.
        _setMetadataForExtension(_extension.metadata.name, _extension.metadata);

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            // 2. Store: function for extension.
            _addToFunctionMap(_extension.metadata.name, _extension.functions[i]);
            // 3. Store: metadata for function.
            _setMetadataForFunction(_extension.functions[i].functionSelector, _extension.metadata);
        }

        emit ExtensionAdded(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @dev Fully replace an existing extension of the router.
    function _replaceExtension(Extension memory _extension) internal virtual {
        // Check: extension namespace must already exist.
        // Check: provided extension implementation must be non-zero.
        require(_canReplaceExtension(_extension), "ExtensionManager: cannot replace extension.");
        
        // 1. Store: metadata for extension.
        _setMetadataForExtension(_extension.metadata.name, _extension.metadata);
        // 2. Delete: existing extension.functions and metadata for each function.
        _removeAllFunctionsFromExtension(_extension.metadata.name);
        
        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            // 2. Store: function for extension.
            _addToFunctionMap(_extension.metadata.name, _extension.functions[i]);
            // 3. Store: metadata for function.
            _setMetadataForFunction(_extension.functions[i].functionSelector, _extension.metadata);
        }

        emit ExtensionReplaced(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @dev Remove an existing extension from the router.
    function _removeExtension(string memory _extensionName) internal virtual {
        // Check: extension namespace must already exist.
        // Delete: extension namespace.
        require(_canRemoveExtension(_extensionName), "ExtensionManager: cannot remove extension.");

        Extension memory extension = _extensionManagerStorage().extensions[_extensionName];

        // 1. Delete: metadata for extension.
        _deleteMetadataForExtension(_extensionName);
        // 2. Delete: existing extension.functions and metadata for each function.
        _removeAllFunctionsFromExtension(_extensionName);

        emit ExtensionRemoved(_extensionName, extension);
    }

    /// @dev Makes the given function callable on the router.
    function _enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function) internal virtual {
        // Check: extension namespace must already exist.
        require(_canEnableFunctionInExtension(_extensionName, _function), "ExtensionManager: cannot Store: function for extension.");
        
        // 1. Store: function for extension.
        _addToFunctionMap(_extensionName, _function);

        ExtensionMetadata memory metadata = _extensionManagerStorage().extensions[_extensionName].metadata;
        // 2. Store: metadata for function.
        _setMetadataForFunction(_function.functionSelector, metadata);

        emit FunctionEnabled(_extensionName, _function.functionSelector, _function, metadata);
    }

    /// @dev Disables a single function in an Extension.
    function _disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) public virtual onlyAuthorizedCall {
        // Check: extension namespace must already exist.
        // Check: function must be mapped to provided extension.
        require(_canDisableFunctionInExtension(_extensionName, _functionSelector), "ExtensionManager: cannot remove function from extension.");
    
        ExtensionMetadata memory extMetadata = _extensionManagerStorage().extensionMetadata[_functionSelector];

        // 1. Delete: function from extension.
        _deleteFromFunctionMap(_extensionName, _functionSelector);
        // 2. Delete: metadata for function.
        _deleteMetadataForFunction(_functionSelector);

        emit FunctionDisabled(_extensionName, _functionSelector, extMetadata);
    }

    /// @dev Returns the Extension for a given name.
    function _getExtension(string memory _extensionName) internal view returns (Extension memory) {
        return _extensionManagerStorage().extensions[_extensionName];
    }

    /// @dev Sets the ExtensionMetadata for a given extension.
    function _setMetadataForExtension(string memory _extensionName, ExtensionMetadata memory _metadata) internal {
        _extensionManagerStorage().extensions[_extensionName].metadata = _metadata;
    }

    /// @dev Deletes the ExtensionMetadata for a given extension.
    function _deleteMetadataForExtension(string memory _extensionName) internal {
        delete _extensionManagerStorage().extensions[_extensionName].metadata;
    }

    /// @dev Sets the ExtensionMetadata for a given function.
    function _setMetadataForFunction(bytes4 _functionSelector, ExtensionMetadata memory _metadata) internal {
        _extensionManagerStorage().extensionMetadata[_functionSelector] = _metadata;
    }

    /// @dev Deletes the ExtensionMetadata for a given function.
    function _deleteMetadataForFunction(bytes4 _functionSelector) internal {
        delete _extensionManagerStorage().extensionMetadata[_functionSelector];
    }

    /// @dev Adds a function to the function map of an extension.
    function _addToFunctionMap(string memory _extensionName, ExtensionFunction memory _extFunction) internal virtual {
        /**
         *  Note: `bytes4(0)` is the function selector for the `receive` function.
         *        So, we maintain a special fn selector-signature mismatch check for the `receive` function.
        **/
        bool mismatch = false;
        if(_extFunction.functionSelector == bytes4(0)) {
            mismatch = keccak256(abi.encode(_extFunction.functionSignature)) != keccak256(abi.encode("receive()"));
        } else {
            mismatch = _extFunction.functionSelector !=
                bytes4(keccak256(abi.encodePacked(_extFunction.functionSignature)));
        }
            
        // Check: function selector and signature must match.
        require(
            !mismatch,
            "ExtensionManager: fn selector and signature mismatch."
        );
        // Check: function must not already be mapped to an implementation.
        require(
            _extensionManagerStorage().extensionMetadata[_extFunction.functionSelector].implementation == address(0),
            "ExtensionManager: function impl already exists."
        );

        // Store: name -> extension.functions map
        _extensionManagerStorage().extensions[_extensionName].functions.push(_extFunction);
    }

    /// @dev Deletes a function from an extension's function map.
    function _deleteFromFunctionMap(string memory _extensionName, bytes4 _functionSelector) internal {
        ExtensionFunction[] memory extensionFunctions = _extensionManagerStorage().extensions[_extensionName].functions;

        uint256 len = extensionFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            if(extensionFunctions[i].functionSelector == _functionSelector) {

                // Delete: particular function from name -> extension.functions map
                _extensionManagerStorage().extensions[_extensionName].functions[i] = _extensionManagerStorage().extensions[_extensionName].functions[len - 1];
                _extensionManagerStorage().extensions[_extensionName].functions.pop();
                break;
            }
        }
    }

    /// @dev Removes all functions from an Extension.
    function _removeAllFunctionsFromExtension(string memory _extensionName) internal {        
        ExtensionFunction[] memory functions = _extensionManagerStorage().extensions[_extensionName].functions;
        
        // Delete: existing name -> extension.functions map
        delete _extensionManagerStorage().extensions[_extensionName].functions;

        for(uint256 i = 0; i < functions.length; i += 1) {
            // Delete: metadata for function.
            _deleteMetadataForFunction(functions[i].functionSelector);
        }
    }

    /// @dev Returns whether a new extension can be added in the given execution context.
    function _canAddExtension(Extension memory _extension) internal virtual returns (bool) {
        // Check: provided extension namespace must not be empty.
        require(bytes(_extension.metadata.name).length > 0, "ExtensionManager: empty name.");
        
        // Check: extension namespace must not already exist.
        // Store: new extension name.
        require(_extensionManagerStorage().extensionNames.add(_extension.metadata.name), "ExtensionManager: extension already exists.");

        // Check: extension implementation must be non-zero.
        require(_extension.metadata.implementation != address(0), "ExtensionManager: adding extension without implementation.");

        return true;
    }

    /// @dev Returns whether an extension can be replaced in the given execution context.
    function _canReplaceExtension(Extension memory _extension) internal virtual returns (bool) {
        // Check: extension namespace must already exist.
        require(_extensionManagerStorage().extensionNames.contains(_extension.metadata.name), "ExtensionManager: extension does not exist.");

        // Check: extension implementation must be non-zero.
        require(_extension.metadata.implementation != address(0), "ExtensionManager: adding extension without implementation.");

        return true;
    }

    /// @dev Returns whether an extension can be removed in the given execution context.
    function _canRemoveExtension(string memory _extensionName) internal virtual returns (bool) {
        // Check: extension namespace must already exist.
        // Delete: extension namespace.
        require(_extensionManagerStorage().extensionNames.remove(_extensionName), "ExtensionManager: extension does not exist.");

        return true;
    }

    /// @dev Returns whether a function can be enabled in an extension in the given execution context.
    function _canEnableFunctionInExtension(string memory _extensionName, ExtensionFunction memory) internal view virtual returns (bool) {
        // Check: extension namespace must already exist.
        require(_extensionManagerStorage().extensionNames.contains(_extensionName), "ExtensionManager: extension does not exist.");

        return true;
    }

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function _canDisableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) internal view virtual returns (bool) {
        // Check: extension namespace must already exist.
        require(_extensionManagerStorage().extensionNames.contains(_extensionName), "ExtensionManager: extension does not exist.");
        // Check: function must be mapped to provided extension.
        require(keccak256(abi.encode(_extensionManagerStorage().extensionMetadata[_functionSelector].name)) == keccak256(abi.encode(_extensionName)), "ExtensionManager: incorrect extension.");

        return true;
    }

    
    /// @dev Returns the ExtensionManager storage.
    function _extensionManagerStorage() internal pure returns (ExtensionManagerStorage.Data storage data) {
        data = ExtensionManagerStorage.data();
    }

    /// @dev To override; returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import '@thirdweb-dev/contracts/prebuilts/marketplace/entrypoint/MarketplaceV3.sol';

contract Marketplace is MarketplaceV3 {
    constructor(MarketplaceConstructorParams memory _marketplaceV3Params) MarketplaceV3(_marketplaceV3Params) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}