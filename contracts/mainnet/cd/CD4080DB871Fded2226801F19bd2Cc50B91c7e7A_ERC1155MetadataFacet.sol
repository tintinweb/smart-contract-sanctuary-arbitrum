// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when trying to transfer tokens without calldata to the contract.
error EtherReceptionDisabled();

/// @notice Thrown when the multiple related arrays have different lengths.
error InconsistentArrayLengths();

/// @notice Thrown when an ETH transfer has failed.
error TransferFailed();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when setting the illegal interfaceId 0xffffffff.
error IllegalInterfaceId();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ERC165 Interface Detection Standard.
/// @dev See https://eips.ethereum.org/EIPS/eip-165.
/// @dev Note: The ERC-165 identifier for this interface is 0x01ffc9a7.
interface IERC165 {
    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId the interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(bytes4 interfaceId) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IllegalInterfaceId} from "./../errors/InterfaceDetectionErrors.sol";
import {IERC165} from "./../interfaces/IERC165.sol";

library InterfaceDetectionStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.introspection.InterfaceDetection.storage")) - 1);

    bytes4 internal constant ILLEGAL_INTERFACE_ID = 0xffffffff;

    /// @notice Sets or unsets an ERC165 interface.
    /// @dev Revertswith {IllegalInterfaceId} if `interfaceId` is `0xffffffff`.
    /// @param interfaceId the interface identifier.
    /// @param supported True to set the interface, false to unset it.
    function setSupportedInterface(Layout storage s, bytes4 interfaceId, bool supported) internal {
        if (interfaceId == ILLEGAL_INTERFACE_ID) revert IllegalInterfaceId();
        s.supportedInterfaces[interfaceId] = supported;
    }

    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId The interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(Layout storage s, bytes4 interfaceId) internal view returns (bool supported) {
        if (interfaceId == ILLEGAL_INTERFACE_ID) {
            return false;
        }
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        return s.supportedInterfaces[interfaceId];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";
import {ERC2771Calldata} from "./../libraries/ERC2771Calldata.sol";

/// @title Meta-Transactions Forwarder Registry Context (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
abstract contract ForwarderRegistryContextBase {
    IForwarderRegistry internal immutable _FORWARDER_REGISTRY;

    constructor(IForwarderRegistry forwarderRegistry) {
        _FORWARDER_REGISTRY = forwarderRegistry;
    }

    /// @notice Returns the message sender depending on the ForwarderRegistry-based meta-transaction context.
    function _msgSender() internal view virtual returns (address) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.sender;
        }

        address sender = ERC2771Calldata.msgSender();

        // Return the EIP-2771 calldata-appended sender address if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_FORWARDER_REGISTRY) || _FORWARDER_REGISTRY.isApprovedForwarder(sender, msg.sender)) {
            return sender;
        }

        return msg.sender;
    }

    /// @notice Returns the message data depending on the ForwarderRegistry-based meta-transaction context.
    function _msgData() internal view virtual returns (bytes calldata) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.data;
        }

        // Return the EIP-2771 calldata (minus the appended sender) if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_FORWARDER_REGISTRY) || _FORWARDER_REGISTRY.isApprovedForwarder(ERC2771Calldata.msgSender(), msg.sender)) {
            return ERC2771Calldata.msgData();
        }

        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as an approved meta-transaction forwarder for a sender account.
    /// @param sender The sender account.
    /// @param forwarder The forwarder account.
    /// @return isApproved True if `forwarder` is an approved meta-transaction forwarder for `sender`, false otherwise.
    function isApprovedForwarder(address sender, address forwarder) external view returns (bool isApproved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT licence)
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
library ERC2771Calldata {
    /// @notice Returns the sender address appended at the end of the calldata, as specified in EIP-2771.
    function msgSender() internal pure returns (address sender) {
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /// @notice Returns the calldata while omitting the appended sender address, as specified in EIP-2771.
    function msgData() internal pure returns (bytes calldata data) {
        unchecked {
            return msg.data[:msg.data.length - 20];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when the initial admin is not set.
error NoInitialProxyAdmin();

/// @notice Thrown when an account is not the proxy admin but is required to.
/// @param account The account that was checked.
error NotProxyAdmin(address account);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Emitted when trying to set a phase value that has already been reached.
/// @param currentPhase The current phase.
/// @param newPhase The new phase trying to be set.
error InitializationPhaseAlreadyReached(uint256 currentPhase, uint256 newPhase);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Emitted when the proxy admin changes.
/// @param previousAdmin the previous admin.
/// @param newAdmin the new admin.
event AdminChanged(address previousAdmin, address newAdmin);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {NoInitialProxyAdmin, NotProxyAdmin} from "./../errors/ProxyAdminErrors.sol";
import {AdminChanged} from "./../events/ProxyAdminEvents.sol";
import {ProxyInitialization} from "./ProxyInitialization.sol";

library ProxyAdminStorage {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    struct Layout {
        address admin;
    }

    // bytes32 public constant PROXYADMIN_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin.phase")) - 1);

    /// @notice Initializes the storage with an initial admin (immutable version).
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Reverts {NoInitialProxyAdmin} if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function constructorInit(Layout storage s, address initialAdmin) internal {
        if (initialAdmin == address(0)) revert NoInitialProxyAdmin();
        s.admin = initialAdmin;
        emit AdminChanged(address(0), initialAdmin);
    }

    /// @notice Initializes the storage with an initial admin (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts with {InitializationPhaseAlreadyReached} if the proxy initialization phase is set to `1` or above.
    /// @dev Reverts {NoInitialProxyAdmin} if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function proxyInit(Layout storage s, address initialAdmin) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialAdmin);
    }

    /// @notice Sets a new proxy admin.
    /// @dev Reverts with {NotProxyAdmin} if `sender` is not the proxy admin.
    /// @dev Emits an {AdminChanged} event if `newAdmin` is different from the current proxy admin.
    /// @param newAdmin The new proxy admin.
    function changeProxyAdmin(Layout storage s, address sender, address newAdmin) internal {
        address previousAdmin = s.admin;
        if (sender != previousAdmin) revert NotProxyAdmin(sender);
        if (previousAdmin != newAdmin) {
            s.admin = newAdmin;
            emit AdminChanged(previousAdmin, newAdmin);
        }
    }

    /// @notice Gets the proxy admin.
    /// @return admin The proxy admin
    function proxyAdmin(Layout storage s) internal view returns (address admin) {
        return s.admin;
    }

    /// @notice Ensures that an account is the proxy admin.
    /// @dev Reverts with {NotProxyAdmin} if `account` is not the proxy admin.
    /// @param account The account.
    function enforceIsProxyAdmin(Layout storage s, address account) internal view {
        if (account != s.admin) revert NotProxyAdmin(account);
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {InitializationPhaseAlreadyReached} from "./../errors/ProxyInitializationErrors.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice Multiple calls protection for storage-modifying proxy initialization functions.
library ProxyInitialization {
    /// @notice Sets the initialization phase during a storage-modifying proxy initialization function.
    /// @dev Reverts with {InitializationPhaseAlreadyReached} if `phase` has been reached already.
    /// @param storageSlot the storage slot where `phase` is stored.
    /// @param phase the initialization phase.
    function setPhase(bytes32 storageSlot, uint256 phase) internal {
        StorageSlot.Uint256Slot storage currentVersion = StorageSlot.getUint256Slot(storageSlot);
        uint256 currentPhase = currentVersion.value;
        if (currentPhase >= phase) revert InitializationPhaseAlreadyReached(currentPhase, phase);
        currentVersion.value = phase;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {InconsistentArrayLengths} from "./../../../CommonErrors.sol";
import {NotMetadataResolver} from "./../../metadata/errors/TokenMetadataErrors.sol";
import {URI} from "./../events/ERC1155Events.sol";
import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {IERC1155MetadataSetter} from "./../interfaces/IERC1155MetadataSetter.sol";
import {TokenMetadataStorage} from "./../../metadata/libraries/TokenMetadataStorage.sol";
import {TokenMetadataBase} from "./../../metadata/base/TokenMetadataBase.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Metadata (proxiable version).
/// @notice This contracts uses an external resolver for managing individual tokens metadata.
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
abstract contract ERC1155MetadataBase is TokenMetadataBase, IERC1155MetadataURI, IERC1155MetadataSetter {
    using TokenMetadataStorage for TokenMetadataStorage.Layout;

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256 tokenId) external view virtual returns (string memory metadataURI) {
        return TokenMetadataStorage.layout().tokenMetadataURI(address(this), tokenId);
    }

    /// @notice Emits the URI event when a token metadata URI is set by the metadata resolver.
    /// @dev Reverts if the caller is not the metadata resolver.
    /// @dev Emits a {URI} event.
    /// @param tokenId The token identifier.
    /// @param tokenURI The token metadata URI.
    function setTokenURI(uint256 tokenId, string calldata tokenURI) external virtual {
        if (msg.sender != address(TokenMetadataStorage.layout().metadataResolver())) revert NotMetadataResolver(msg.sender);
        emit URI(tokenURI, tokenId);
    }

    /// @notice Emits URI events when a batch of token metadata URIs is set by the metadata resolver.
    /// @dev Reverts if `tokenIds` and `tokenURIs` have different lengths.
    /// @dev Reverts if the caller is not the metadata resolver.
    /// @dev Emits a {URI} event for each token.
    /// @param tokenIds The token identifiers.
    /// @param tokenURIs The token metadata URIs.
    function batchSetTokenURI(uint256[] calldata tokenIds, string[] calldata tokenURIs) external virtual {
        if (tokenIds.length != tokenURIs.length) revert InconsistentArrayLengths();
        if (msg.sender != address(TokenMetadataStorage.layout().metadataResolver())) revert NotMetadataResolver(msg.sender);

        for (uint256 i; i < tokenIds.length; ++i) {
            emit URI(tokenURIs[i], tokenIds[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when trying to approveForAll oneself.
/// @param account The account trying to approveForAll itself.
error ERC1155SelfApprovalForAll(address account);

/// @notice Thrown when transferring tokens to the zero address.
error ERC1155TransferToAddressZero();

/// @notice Thrown when a sender tries to transfer tokens but is neither the owner nor approved by the owner.
/// @param sender The sender.
/// @param owner The owner.
error ERC1155NonApproved(address sender, address owner);

/// @notice Thrown when transferring an amount of tokens greater than the current balance.
/// @param owner The owner.
/// @param id The token identifier.
/// @param balance The current balance.
/// @param value The amount of tokens to transfer.
error ERC1155InsufficientBalance(address owner, uint256 id, uint256 balance, uint256 value);

/// @notice Thrown when minting or transferring an amount of tokens that would overflow the recipient's balance.
/// @param recipient The recipient.
/// @param id The token identifier.
/// @param balance The current balance.
/// @param value The amount of tokens to transfer.
error ERC1155BalanceOverflow(address recipient, uint256 id, uint256 balance, uint256 value);

/// @notice Thrown when a safe transfer is rejected by the recipient contract.
/// @param recipient The recipient contract.
/// @param id The token identifier.
/// @param value The amount of tokens to transfer.
error ERC1155SafeTransferRejected(address recipient, uint256 id, uint256 value);

/// @notice Thrown when a safe batch transfer is rejected by the recipient contract.
/// @param recipient The recipient contract.
/// @param ids The token identifiers.
/// @param values The amounts of tokens to transfer.
error ERC1155SafeBatchTransferRejected(address recipient, uint256[] ids, uint256[] values);

/// @notice Thrown when querying the balance of the zero address.
error ERC1155BalanceOfAddressZero();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when minting tokens to the zero address.
error ERC1155MintToAddressZero();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Emitted when some token is transferred.
/// @param operator The initiator of the transfer.
/// @param from The previous token owner.
/// @param to The new token owner.
/// @param id The transferred token identifier.
/// @param value The amount of token.
event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

/// @notice Emitted when a batch of tokens is transferred.
/// @param operator The initiator of the transfer.
/// @param from The previous tokens owner.
/// @param to The new tokens owner.
/// @param ids The transferred tokens identifiers.
/// @param values The amounts of tokens.
event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

/// @notice Emitted when an approval for all tokens is set or unset.
/// @param owner The tokens owner.
/// @param operator The approved address.
/// @param approved True when then approval is set, false when it is unset.
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

/// @notice Emitted when a token metadata URI is set updated.
/// @param value The token metadata URI.
/// @param id The token identifier.
event URI(string value, uint256 indexed id);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ITokenMetadataResolver} from "./../../metadata/interfaces/ITokenMetadataResolver.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {TokenMetadataStorage} from "./../../metadata/libraries/TokenMetadataStorage.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {ERC1155MetadataBase} from "./../base/ERC1155MetadataBase.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Metadata (facet version).
/// @notice This contracts uses an external resolver for managing individual tokens metadata.
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet} and {InterfaceDetectionFacet}.
contract ERC1155MetadataFacet is ERC1155MetadataBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using TokenMetadataStorage for TokenMetadataStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with the contract metadata.
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interfaces as supported: ERC1155MetadataURI.
    /// @dev Reverts with {NotProxyAdmin} if the sender is not the proxy admin.
    /// @dev Reverts with {InitializationPhaseAlreadyReached} if the proxy initialization phase is set to `1` or above.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param metadataResolver The address of the metadata resolver contract.
    function initERC1155MetadataStorage(string calldata name, string calldata symbol, ITokenMetadataResolver metadataResolver) external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        TokenMetadataStorage.layout().proxyInit(name, symbol, metadataResolver);
        ERC1155Storage.initERC1155MetadataURI();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ERC1155 Multi Token Standard, basic interface (functions).
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 {
    /// @notice Safely transfers some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /// @notice Safely transfers a batch of tokens.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;

    /// @notice Enables or disables an operator's approval.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator) external view returns (bool approved);

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance);

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts if `owners` and `ids` have different lengths.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

/// @title ERC1155 Multi Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x921ed8d1.
interface IERC1155Burnable {
    /// @notice Burns some token.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(address from, uint256 id, uint256 value) external;

    /// @notice Burns multiple tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(address from, uint256[] calldata ids, uint256[] calldata values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ERC1155 Multi Token Standard, optional extension: Deliverable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0xe8ab9ccc.
interface IERC1155Deliverable {
    /// @notice Safely mints tokens to multiple recipients.
    /// @dev Reverts if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `recipients` balance overflows.
    /// @dev Reverts if one of `recipients` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event from the zero address for each transfer.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IERC1155MetadataSetter {
    /// @notice Sets the metadata URI for a token.
    /// @dev Emits a {URI} event.
    /// @param tokenId The token identifier.
    /// @param tokenURI The token metadata URI.
    function setTokenURI(uint256 tokenId, string calldata tokenURI) external;

    /// @notice Sets the metadata URIs for a batch of tokens.
    /// @dev Reverts with {InconsistentArrayLengths} if the arrays are of inconsistent lengths.
    /// @dev Emits a {URI} event for each token.
    /// @param tokenIds The token identifiers.
    /// @param tokenURIs The token metadata URIs.
    function batchSetTokenURI(uint256[] calldata tokenIds, string[] calldata tokenURIs) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x0e89341c.
interface IERC1155MetadataURI {
    /// @notice Retrieves the URI for a given token.
    /// @dev URIs are defined in RFC 3986.
    /// @dev The URI MUST point to a JSON file that conforms to the "ERC1155 Metadata URI JSON Schema".
    /// @dev The uri function SHOULD be used to retrieve values if no event was emitted.
    /// @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
    /// @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
    ///  an implementation to return a valid string even if the token does not exist.
    /// @return metadataURI The URI associated to the token.
    function uri(uint256 id) external view returns (string memory metadataURI);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

/// @title ERC1155 Multi Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x5190c92c.
interface IERC1155Mintable {
    /// @notice Safely mints some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(address to, uint256 id, uint256 value, bytes calldata data) external;

    /// @notice Safely mints a batch of tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ERC1155 Multi Token Standard, Tokens Receiver.
/// @notice Interface for any contract that wants to support transfers from ERC1155 asset contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
interface IERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC1155 token type.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
    /// @dev Return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (`0xf23a6e61`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param id The ID of the token being transferred
    /// @param value The amount of tokens being transferred
    /// @param data Additional data with no specified format
    /// @return magicValue `0xf23a6e61` to accept the transfer, or any other value to reject it.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4 magicValue);

    /// @notice Handles the receipt of multiple ERC1155 token types.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
    /// @dev Return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (`0xbc197c81`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the batch transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param ids An array containing ids of each token being transferred (order and length must match _values array)
    /// @param values An array containing amounts of each token being transferred (order and length must match _ids array)
    /// @param data Additional data with no specified format
    /// @return magicValue `0xbc197c81` to accept the transfer, or any other value to reject it.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// solhint-disable-next-line max-line-length
import {ERC1155SelfApprovalForAll, ERC1155TransferToAddressZero, ERC1155NonApproved, ERC1155InsufficientBalance, ERC1155BalanceOverflow, ERC1155SafeTransferRejected, ERC1155SafeBatchTransferRejected, ERC1155BalanceOfAddressZero} from "./../errors/ERC1155Errors.sol";
import {ERC1155MintToAddressZero} from "./../errors/ERC1155MintableErrors.sol";
import {InconsistentArrayLengths} from "./../../../CommonErrors.sol";
import {TransferSingle, TransferBatch, ApprovalForAll} from "./../events/ERC1155Events.sol";
import {IERC1155} from "./../interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {IERC1155Mintable} from "./../interfaces/IERC1155Mintable.sol";
import {IERC1155Deliverable} from "./../interfaces/IERC1155Deliverable.sol";
import {IERC1155Burnable} from "./../interfaces/IERC1155Burnable.sol";
import {IERC1155TokenReceiver} from "./../interfaces/IERC1155TokenReceiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC1155Storage {
    using Address for address;
    using ERC1155Storage for ERC1155Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operators;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC1155.ERC1155.storage")) - 1);

    bytes4 internal constant ERC1155_SINGLE_RECEIVED = IERC1155TokenReceiver.onERC1155Received.selector;
    bytes4 internal constant ERC1155_BATCH_RECEIVED = IERC1155TokenReceiver.onERC1155BatchReceived.selector;

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155MetadataURI.
    function initERC1155MetadataURI() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155MetadataURI).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Mintable.
    function initERC1155Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Deliverable.
    function initERC1155Deliverable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Deliverable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Burnable.
    function initERC1155Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Burnable).interfaceId, true);
    }

    /// @notice Safely transfers some token by a sender.
    /// @dev Note: This function implements {ERC1155-safeTransferFrom(address,address,uint256,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts with {ERC1155TransferToAddressZero} if `to` is the zero address.
    /// @dev Reverts with {ERC1155NonApproved} if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts with {ERC1155InsufficientBalance} if `from` has an insufficient balance of `id`.
    /// @dev Reverts with {ERC1155BalanceOverflow} if `to`'s balance of `id` overflows.
    /// @dev Reverts with {ERC1155SafeTransferRejected} if `to` is a contract and the call to
    ///  {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 id, uint256 value, bytes calldata data) internal {
        if (to == address(0)) revert ERC1155TransferToAddressZero();
        if (!_isOperatable(s, from, sender)) revert ERC1155NonApproved(sender, from);

        _transferToken(s, from, to, id, value);

        emit TransferSingle(sender, from, to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, from, to, id, value, data);
        }
    }

    /// @notice Safely transfers a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts with {ERC1155TransferToAddressZero} if `to` is the zero address.
    /// @dev Reverts with {InconsistentArrayLengths} if `ids` and `values` have different lengths.
    /// @dev Reverts with {ERC1155NonApproved} if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts with {ERC1155InsufficientBalance} if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts with {ERC1155BalanceOverflow} if `to`'s balance of any of `ids` overflows.
    /// @dev Reverts with {ERC1155SafeBatchTransferRejected} if `to` is a contract and the call to
    ///  {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(
        Layout storage s,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) internal {
        if (to == address(0)) revert ERC1155TransferToAddressZero();
        uint256 length = ids.length;
        if (length != values.length) revert InconsistentArrayLengths();

        if (!_isOperatable(s, from, sender)) revert ERC1155NonApproved(sender, from);

        for (uint256 i; i < length; ++i) {
            _transferToken(s, from, to, ids[i], values[i]);
        }

        emit TransferBatch(sender, from, to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, from, to, ids, values, data);
        }
    }

    /// @notice Safely mints some token by a sender.
    /// @dev Note: This function implements {ERC1155Mintable-safeMint(address,uint256,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts with {ERC1155MintToAddressZero} if `to` is the zero address.
    /// @dev Reverts with {ERC1155BalanceOverflow} if `to`'s balance of `id` overflows.
    /// @dev Reverts with {ERC1155SafeTransferRejected} if `to` is a contract and the call to
    ///  {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(Layout storage s, address sender, address to, uint256 id, uint256 value, bytes memory data) internal {
        if (to == address(0)) revert ERC1155MintToAddressZero();

        _mintToken(s, to, id, value);

        emit TransferSingle(sender, address(0), to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, address(0), to, id, value, data);
        }
    }

    /// @notice Safely mints a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC1155Mintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts with {ERC1155MintToAddressZero} if `to` is the zero address.
    /// @dev Reverts with {InconsistentArrayLengths} if `ids` and `values` have different lengths.
    /// @dev Reverts with {ERC1155BalanceOverflow} if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts with {ERC1155SafeBatchTransferRejected} if `to` is a contract and the call to
    ///  {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(Layout storage s, address sender, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        if (to == address(0)) revert ERC1155MintToAddressZero();
        uint256 length = ids.length;
        if (length != values.length) revert InconsistentArrayLengths();

        for (uint256 i; i < length; ++i) {
            _mintToken(s, to, ids[i], values[i]);
        }

        emit TransferBatch(sender, address(0), to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, address(0), to, ids, values, data);
        }
    }

    /// @notice Safely mints tokens to multiple recipients by a sender.
    /// @dev Note: This function implements {ERC1155Deliverable-safeDeliver(address[],uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts with {InconsistentArrayLengths} if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts with {ERC1155MintToAddressZero} if one of `recipients` is the zero address.
    /// @dev Reverts with {ERC1155BalanceOverflow} if one of the `recipients`' balance overflows for the associated `ids`.
    /// @dev Reverts with {ERC1155SafeTransferRejected} if one of `recipients` is a contract and the call to
    ///  {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event from the zero address for each transfer.
    /// @param sender The message sender.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(
        Layout storage s,
        address sender,
        address[] memory recipients,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        uint256 length = recipients.length;
        if (length != ids.length || length != values.length) revert InconsistentArrayLengths();
        for (uint256 i; i < length; ++i) {
            s.safeMint(sender, recipients[i], ids[i], values[i], data);
        }
    }

    /// @notice Burns some token by a sender.
    /// @dev Reverts with {ERC1155NonApproved} if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts with {ERC1155InsufficientBalance} if `from` has an insufficient balance of `id`.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 id, uint256 value) internal {
        if (!_isOperatable(s, from, sender)) revert ERC1155NonApproved(sender, from);
        _burnToken(s, from, id, value);
        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @notice Burns multiple tokens by a sender.
    /// @dev Reverts with {InconsistentArrayLengths} if `ids` and `values` have different lengths.
    /// @dev Reverts with {ERC1155NonApproved} if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts with {ERC1155InsufficientBalance} if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address from, uint256[] calldata ids, uint256[] calldata values) internal {
        uint256 length = ids.length;
        if (length != values.length) revert InconsistentArrayLengths();
        if (!_isOperatable(s, from, sender)) revert ERC1155NonApproved(sender, from);

        for (uint256 i; i < length; ++i) {
            _burnToken(s, from, ids[i], values[i]);
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /// @notice Enables or disables an operator's approval by a sender.
    /// @dev Reverts with {ERC1155SelfApprovalForAll} if `sender` is `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param sender The message sender.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(Layout storage s, address sender, address operator, bool approved) internal {
        if (operator == sender) revert ERC1155SelfApprovalForAll(sender);
        s.operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(Layout storage s, address owner, address operator) internal view returns (bool approved) {
        return s.operators[owner][operator];
    }

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @dev Reverts with {ERC1155BalanceOfAddressZero} if `owner` is the zero address.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(Layout storage s, address owner, uint256 id) internal view returns (uint256 balance) {
        if (owner == address(0)) revert ERC1155BalanceOfAddressZero();
        return s.balances[id][owner];
    }

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts with {InconsistentArrayLengths} if `owners` and `ids` have different lengths.
    /// @dev Reverts with {ERC1155BalanceOfAddressZero} if one of `owners` is the zero address.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(Layout storage s, address[] calldata owners, uint256[] calldata ids) internal view returns (uint256[] memory balances) {
        uint256 length = owners.length;
        if (length != ids.length) revert InconsistentArrayLengths();

        balances = new uint256[](owners.length);

        for (uint256 i; i < length; ++i) {
            balances[i] = s.balanceOf(owners[i], ids[i]);
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Returns whether an account is authorised to make a transfer on behalf of an owner.
    /// @param owner The token owner.
    /// @param account The account to check the operatability of.
    /// @return operatable True if `account` is `owner` or is an operator for `owner`, false otherwise.
    function _isOperatable(Layout storage s, address owner, address account) private view returns (bool operatable) {
        return (owner == account) || s.operators[owner][account];
    }

    function _transferToken(Layout storage s, address from, address to, uint256 id, uint256 value) private {
        if (value != 0) {
            uint256 fromBalance = s.balances[id][from];
            unchecked {
                uint256 newFromBalance = fromBalance - value;
                if (newFromBalance >= fromBalance) revert ERC1155InsufficientBalance(from, id, fromBalance, value);
                if (from != to) {
                    uint256 toBalance = s.balances[id][to];
                    uint256 newToBalance = toBalance + value;
                    if (newToBalance <= toBalance) revert ERC1155BalanceOverflow(to, id, toBalance, value);

                    s.balances[id][from] = newFromBalance;
                    s.balances[id][to] = newToBalance;
                }
            }
        }
    }

    function _mintToken(Layout storage s, address to, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][to];
                uint256 newBalance = balance + value;
                if (newBalance <= balance) revert ERC1155BalanceOverflow(to, id, balance, value);
                s.balances[id][to] = newBalance;
            }
        }
    }

    function _burnToken(Layout storage s, address from, uint256 id, uint256 value) private {
        if (value != 0) {
            uint256 balance = s.balances[id][from];
            unchecked {
                uint256 newBalance = balance - value;
                if (newBalance >= balance) revert ERC1155InsufficientBalance(from, id, balance, value);
                s.balances[id][from] = newBalance;
            }
        }
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
    /// @dev Reverts with {ERC1155SafeTransferRejected} if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param id Identifier of the token transferred.
    /// @param value Value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155Received(address sender, address from, address to, uint256 id, uint256 value, bytes memory data) private {
        if (IERC1155TokenReceiver(to).onERC1155Received(sender, from, id, value, data) != ERC1155_SINGLE_RECEIVED)
            revert ERC1155SafeTransferRejected(to, id, value);
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155BatchReceived} on a target contract.
    /// @dev Reverts with {ERC1155SafeBatchTransferRejected} if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param ids Identifiers of the tokens transferred.
    /// @param values Values transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155BatchReceived(
        address sender,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        if (IERC1155TokenReceiver(to).onERC1155BatchReceived(sender, from, ids, values, data) != ERC1155_BATCH_RECEIVED)
            revert ERC1155SafeBatchTransferRejected(to, ids, values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ITokenMetadataResolver} from "./../interfaces/ITokenMetadataResolver.sol";
import {TokenMetadataStorage} from "./../libraries/TokenMetadataStorage.sol";

/// @title TokenMetadataBase (proxiable version).
/// @notice Provides metadata management for token contracts (ERC721/ERC1155) which uses an external resolver for managing individual tokens metadata.
/// @dev This contract is to be used via inheritance in a proxied implementation.
abstract contract TokenMetadataBase {
    using TokenMetadataStorage for TokenMetadataStorage.Layout;

    /// @notice Gets the token name. E.g. "My Token".
    /// @return tokenName The token name.
    function name() public view virtual returns (string memory tokenName) {
        return TokenMetadataStorage.layout().name();
    }

    /// @notice Gets the token symbol. E.g. "TOK".
    /// @return tokenSymbol The token symbol.
    function symbol() public view virtual returns (string memory tokenSymbol) {
        return TokenMetadataStorage.layout().symbol();
    }

    /// @notice Gets the token metadata resolver address.
    /// @return tokenMetadataResolver The token metadata resolver address.
    function metadataResolver() external view virtual returns (ITokenMetadataResolver tokenMetadataResolver) {
        return TokenMetadataStorage.layout().metadataResolver();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @notice Thrown when an account is not the metadata resolver but is required to.
/// @param account The account that was checked.
error NotMetadataResolver(address account);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title ITokenMetadataResolver
/// @notice Interface for Token Metadata Resolvers.
interface ITokenMetadataResolver {
    /// @notice Gets the token metadata URI for a token.
    /// @param tokenContract The token contract for which to retrieve the token URI.
    /// @param tokenId The token identifier.
    /// @return tokenURI The token metadata URI.
    function tokenMetadataURI(address tokenContract, uint256 tokenId) external view returns (string memory tokenURI);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ITokenMetadataResolver} from "./../interfaces/ITokenMetadataResolver.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";

library TokenMetadataStorage {
    struct Layout {
        string tokenName;
        string tokenSymbol;
        ITokenMetadataResolver tokenMetadataResolver;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.metadata.TokenMetadata.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.token.metadata.TokenMetadata.phase")) - 1);

    /// @notice Initializes the metadata storage (immutable version).
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    /// @param tokenMetadataResolver The address of the metadata resolver contract.
    function constructorInit(
        Layout storage s,
        string memory tokenName,
        string memory tokenSymbol,
        ITokenMetadataResolver tokenMetadataResolver
    ) internal {
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        s.tokenMetadataResolver = tokenMetadataResolver;
    }

    /// @notice Initializes the metadata storage (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts with {InitializationPhaseAlreadyReached} if the proxy initialization phase is set to `1` or above.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    /// @param tokenMetadataResolver The address of the metadata resolver contract.
    function proxyInit(
        Layout storage s,
        string calldata tokenName,
        string calldata tokenSymbol,
        ITokenMetadataResolver tokenMetadataResolver
    ) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        s.tokenMetadataResolver = tokenMetadataResolver;
    }

    /// @notice Gets the name of the token.
    /// @return tokenName The name of the token contract.
    function name(Layout storage s) internal view returns (string memory tokenName) {
        return s.tokenName;
    }

    /// @notice Gets the symbol of the token.
    /// @return tokenSymbol The symbol of the token contract.
    function symbol(Layout storage s) internal view returns (string memory tokenSymbol) {
        return s.tokenSymbol;
    }

    /// @notice Gets the address of the token metadata resolver.
    /// @return tokenMetadataResolver The address of the token metadata resolver.
    function metadataResolver(Layout storage s) internal view returns (ITokenMetadataResolver tokenMetadataResolver) {
        return s.tokenMetadataResolver;
    }

    /// @notice Gets the token metadata URI retieved from the metadata resolver contract.
    /// @param tokenContract The address of the token contract.
    /// @param tokenId The ID of the token.
    function tokenMetadataURI(Layout storage s, address tokenContract, uint256 tokenId) internal view returns (string memory) {
        return s.tokenMetadataResolver.tokenMetadataURI(tokenContract, tokenId);
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}