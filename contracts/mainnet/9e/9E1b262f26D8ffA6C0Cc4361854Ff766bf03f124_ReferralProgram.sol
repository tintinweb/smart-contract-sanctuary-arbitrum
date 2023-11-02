// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// admin roles
bytes32 constant BIG_TIMELOCK_ADMIN = 0x00; // It's primary admin.
bytes32 constant MEDIUM_TIMELOCK_ADMIN = keccak256("MEDIUM_TIMELOCK_ADMIN");
bytes32 constant SMALL_TIMELOCK_ADMIN = keccak256("SMALL_TIMELOCK_ADMIN");
bytes32 constant EMERGENCY_ADMIN = keccak256("EMERGENCY_ADMIN");
bytes32 constant GUARDIAN_ADMIN = keccak256("GUARDIAN_ADMIN");
bytes32 constant NFT_MINTER = keccak256("NFT_MINTER");
bytes32 constant TRUSTED_TOLERABLE_LIMIT_ROLE = keccak256("TRUSTED_TOLERABLE_LIMIT_ROLE");

// inter-contract interactions roles
bytes32 constant NO_FEE_ROLE = keccak256("NO_FEE_ROLE");
bytes32 constant VAULT_ACCESS_ROLE = keccak256("VAULT_ACCESS_ROLE");
bytes32 constant PM_ROLE = keccak256("PM_ROLE");
bytes32 constant LOM_ROLE = keccak256("LOM_ROLE");
bytes32 constant BATCH_MANAGER_ROLE = keccak256("BATCH_MANAGER_ROLE");

// token constants
address constant NATIVE_CURRENCY = address(uint160(bytes20(keccak256("NATIVE_CURRENCY"))));
address constant USD = 0x0000000000000000000000000000000000000348;
uint256 constant USD_MULTIPLIER = 10 ** (18 - 8); // usd decimals in chainlink is 8
uint8 constant MAX_ASSET_DECIMALS = 18;

// time constants
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_DAY = 1 days;
uint256 constant HOUR = 1 hours;
uint256 constant TEN_WAD = 10 ether;

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// solhint-disable-next-line func-visibility
function _require(bool condition, bytes4 selector) pure {
    if (!condition) _revert(selector);
}

// solhint-disable-next-line func-visibility
function _revert(bytes4 selector) pure {
    // solhint-disable-next-line no-inline-assembly
    assembly ("memory-safe") {
        let free_mem_ptr := mload(64)
        mstore(free_mem_ptr, selector)
        revert(free_mem_ptr, 4)
    }
}

library Errors {
    event Log(bytes4 error);

    //common
    error ADDRESS_NOT_SUPPORTED();
    error FORBIDDEN();
    error AMOUNT_IS_0();
    error CALLER_IS_NOT_TRADER();
    error CONDITION_INDEX_IS_OUT_OF_BOUNDS();
    error INVALID_PERCENT_NUMBER();
    error INVALID_SECURITY_BUFFER();
    error INVALID_MAINTENANCE_BUFFER();
    error TOKEN_ADDRESS_IS_ZERO();
    error IDENTICAL_TOKEN_ADDRESSES();
    error ASSET_DECIMALS_EXCEEDS_MAX_VALUE();
    error CAN_NOT_ADD_WITH_ZERO_ADDRESS();
    error SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT();
    error TOKEN_NOT_SUPPORTED();
    error INSUFFICIENT_DEPOSIT();
    error DEPOSIT_IN_THIRD_ASSET_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    error SHOULD_NOT_HAVE_DUPLICATES();
    error DEPOSITED_TO_BORROWED_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    error DEPOSIT_TO_BORROWED_SHARES_ON_DEX_LENGTH_SHOULD_BE_0();
    // error LIMIT_PRICE_IS_ZERO();
    error BUCKET_IS_NOT_ACTIVE();
    error DIFFERENT_DATA_LENGTH();
    error RECIPIENT_OR_SENDER_MUST_BE_ON_WHITE_LIST();
    error SLIPPAGE_TOLERANCE_EXCEEDED();
    error OPERATION_NOT_SUPPORTED();
    error SENDER_IS_BLACKLISTED();
    error NATIVE_CURRENCY_CANNOT_BE_ASSET();
    error DISABLED_TRANSFER_NATIVE_CURRENCY();
    error INVALID_AMOUNT();

    // bonus executor
    error CALLER_IS_NOT_NFT();
    error BONUS_FOR_BUCKET_ALREADY_ACTIVATED();
    error WRONG_LENGTH();
    error BONUS_DOES_NOT_EXIST();
    error CALLER_IS_NOT_DEBT_TOKEN();
    error CALLER_IS_NOT_P_TOKEN();
    error MAX_BONUS_COUNT_EXCEEDED();
    error TIER_IS_NOT_ACTIVE();
    error BONUS_PERCENT_IS_ZERO();

    // bucket
    error INCORRECT_LIQUIDITY_MINING_PARAMS();
    error PAIR_PRICE_DROP_IS_NOT_CORRECT();
    error ASSET_IS_NOT_SUPPORTED();
    error BUCKET_OUTSIDE_PRIMEX_PROTOCOL();
    error DEADLINE_IS_PASSED();
    error DEADLINE_IS_NOT_PASSED();
    error BUCKET_IS_NOT_LAUNCHED();
    error BURN_AMOUNT_EXCEEDS_PROTOCOL_DEBT();
    error LIQUIDITY_INDEX_OVERFLOW();
    error BORROW_INDEX_OVERFLOW();
    error BAR_OVERFLOW();
    error LAR_OVERFLOW();
    error UR_IS_MORE_THAN_1();
    error ASSET_ALREADY_SUPPORTED();
    error DEPOSIT_IS_MORE_AMOUNT_PER_USER();
    error DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT();
    error MINING_AMOUNT_WITHDRAW_IS_LOCKED_ON_STABILIZATION_PERIOD();
    error WITHDRAW_RATE_IS_MORE_10_PERCENT();
    error INVALID_FEE_BUFFER();
    error RESERVE_RATE_SHOULD_BE_LESS_THAN_1();
    error MAX_TOTAL_DEPOSIT_IS_ZERO();
    error AMOUNT_SCALED_SHOULD_BE_GREATER_THAN_ZERO();
    error NOT_ENOUGH_LIQUIDITY_IN_THE_BUCKET();

    // p/debt token, PMXToken
    error BUCKET_IS_IMMUTABLE();
    error INVALID_MINT_AMOUNT();
    error INVALID_BURN_AMOUNT();
    error TRANSFER_NOT_SUPPORTED();
    error APPROVE_NOT_SUPPORTED();
    error CALLER_IS_NOT_BUCKET();
    error CALLER_IS_NOT_A_BUCKET_FACTORY();
    error CALLER_IS_NOT_P_TOKEN_RECEIVER();
    error DURATION_MUST_BE_MORE_THAN_0();
    error INCORRECT_ID();
    error THERE_ARE_NO_LOCK_DEPOSITS();
    error LOCK_TIME_IS_NOT_EXPIRED();
    error TRANSFER_AMOUNT_EXCEED_ALLOWANCE();
    error CALLER_IS_NOT_A_MINTER();
    error ACTION_ONLY_WITH_AVAILABLE_BALANCE();
    error FEE_DECREASER_CALL_FAILED();
    error TRADER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error INTEREST_INCREASER_CALL_FAILED();
    error LENDER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error DEPOSIT_DOES_NOT_EXIST();
    error RECIPIENT_IS_BLACKLISTED();

    //LOM
    error ORDER_CAN_NOT_BE_FILLED();
    error ORDER_DOES_NOT_EXIST();
    error ORDER_IS_NOT_SPOT();
    error LEVERAGE_MUST_BE_MORE_THAN_1();
    error CANNOT_CHANGE_SPOT_ORDER_TO_MARGIN();
    error SHOULD_HAVE_OPEN_CONDITIONS();
    error INCORRECT_LEVERAGE();
    error INCORRECT_DEADLINE();
    error LEVERAGE_SHOULD_BE_1();
    error LEVERAGE_EXCEEDS_MAX_LEVERAGE();
    error SHOULD_OPEN_POSITION();
    error IS_SPOT_ORDER();
    error SHOULD_NOT_HAVE_CLOSE_CONDITIONS();
    error ORDER_HAS_EXPIRED();

    // LiquidityMiningRewardDistributor
    error BUCKET_IS_NOT_STABLE();
    error ATTEMPT_TO_WITHDRAW_MORE_THAN_DEPOSITED();
    error WITHDRAW_PMX_BY_ADMIN_FORBIDDEN();

    // nft
    error TOKEN_IS_BLOCKED();
    error ONLY_MINTERS();
    error PROGRAM_IS_NOT_ACTIVE();
    error CALLER_IS_NOT_OWNER();
    error TOKEN_IS_ALREADY_ACTIVATED();
    error WRONG_NETWORK();
    error ID_DOES_NOT_EXIST();
    error WRONG_URIS_LENGTH();

    // PM
    error ASSET_ADDRESS_NOT_SUPPORTED();
    error IDENTICAL_ASSET_ADDRESSES();
    error POSITION_DOES_NOT_EXIST();
    error AMOUNT_IS_MORE_THAN_POSITION_AMOUNT();
    error BORROWED_AMOUNT_IS_ZERO();
    error IS_SPOT_POSITION();
    error AMOUNT_IS_MORE_THAN_DEPOSIT();
    error DECREASE_AMOUNT_IS_ZERO();
    error INSUFFICIENT_DEPOSIT_SIZE();
    error IS_NOT_RISKY_OR_CANNOT_BE_CLOSED();
    error BUCKET_SHOULD_BE_UNDEFINED();
    error DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0();
    error POSITION_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error ADDRESS_IS_ZERO();
    error WRONG_TRUSTED_MULTIPLIER();
    error POSITION_SIZE_EXCEEDED();
    error POSITION_BUCKET_IS_INCORRECT();
    error THERE_MUST_BE_AT_LEAST_ONE_POSITION();
    error NOTHING_TO_CLOSE();

    // BatchManager
    error PARAMS_LENGTH_MISMATCH();
    error BATCH_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error CLOSE_CONDITION_IS_NOT_CORRECT();
    error SOLD_ASSET_IS_INCORRECT();

    // Price Oracle
    error ZERO_EXCHANGE_RATE();
    error NO_PRICEFEED_FOUND();
    error NO_PRICE_DROP_FEED_FOUND();

    //DNS
    error INCORRECT_FEE_RATE();
    error BUCKET_ALREADY_FROZEN();
    error BUCKET_IS_ALREADY_ADDED();
    error DEX_IS_ALREADY_ACTIVATED();
    error DEX_IS_ALREADY_FROZEN();
    error DEX_IS_ALREADY_ADDED();
    error BUCKET_NOT_ADDED();
    error DEX_NOT_ACTIVE();
    error BUCKET_ALREADY_ACTIVATED();
    error DEX_NOT_ADDED();
    error BUCKET_IS_INACTIVE();
    error WITHDRAWAL_NOT_ALLOWED();
    error BUCKET_IS_ALREADY_DEPRECATED();

    // Primex upkeep
    error NUMBER_IS_0();

    //referral program, WhiteBlackList
    error CALLER_ALREADY_REGISTERED();
    error MISMATCH();
    error PARENT_NOT_WHITELISTED();
    error ADDRESS_ALREADY_WHITELISTED();
    error ADDRESS_ALREADY_BLACKLISTED();
    error ADDRESS_NOT_BLACKLISTED();
    error ADDRESS_NOT_WHITELISTED();
    error ADDRESS_NOT_UNLISTED();
    error ADDRESS_IS_WHITELISTED();
    error ADDRESS_IS_NOT_CONTRACT();

    //Reserve
    error BURN_AMOUNT_IS_ZERO();
    error CALLER_IS_NOT_EXECUTOR();
    error ADDRESS_NOT_PRIMEX_BUCKET();
    error NOT_SUFFICIENT_RESERVE_BALANCE();
    error INCORRECT_TRANSFER_RESTRICTIONS();

    //Vault
    error AMOUNT_EXCEEDS_AVAILABLE_BALANCE();
    error INSUFFICIENT_FREE_ASSETS();
    error CALLER_IS_NOT_SPENDER();

    //Pricing Library
    error IDENTICAL_ASSETS();
    error SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO();
    error DIFFERENT_PRICE_DEX_AND_ORACLE();
    error TAKE_PROFIT_IS_LTE_LIMIT_PRICE();
    error STOP_LOSS_IS_GTE_LIMIT_PRICE();
    error STOP_LOSS_IS_LTE_LIQUIDATION_PRICE();
    error INSUFFICIENT_POSITION_SIZE();
    error INCORRECT_PATH();
    error DEPOSITED_TO_BORROWED_ROUTES_LENGTH_SHOULD_BE_0();
    error INCORRECT_CM_TYPE();

    // Token transfers
    error TOKEN_TRANSFER_IN_FAILED();
    error TOKEN_TRANSFER_IN_OVERFLOW();
    error TOKEN_TRANSFER_OUT_FAILED();
    error NATIVE_TOKEN_TRANSFER_FAILED();

    // Conditional Managers
    error LOW_PRICE_ROUND_IS_LESS_HIGH_PRICE_ROUND();
    error TRAILING_DELTA_IS_INCORRECT();
    error DATA_FOR_ROUND_DOES_NOT_EXIST();
    error HIGH_PRICE_TIMESTAMP_IS_INCORRECT();
    error NO_PRICE_FEED_INTERSECTION();
    error SHOULD_BE_CCM();
    error SHOULD_BE_COM();

    //Lens
    error DEPOSITED_AMOUNT_IS_0();
    error SPOT_DEPOSITED_ASSET_SHOULD_BE_EQUAL_BORROWED_ASSET();
    error ZERO_ASSET_ADDRESS();
    error ASSETS_SHOULD_BE_DIFFERENT();
    error ZERO_SHARES();
    error SHARES_AMOUNT_IS_GREATER_THAN_AMOUNT_TO_SELL();
    error NO_ACTIVE_DEXES();

    //Bots
    error WRONG_BALANCES();
    error INVALID_INDEX();
    error INVALID_DIVIDER();
    error ARRAYS_LENGTHS_IS_NOT_EQUAL();
    error DENOMINATOR_IS_0();

    //DexAdapter
    error ZERO_AMOUNT_IN();
    error ZERO_AMOUNT();
    error UNKNOWN_DEX_TYPE();
    error REVERTED_WITHOUT_A_STRING_TRY_TO_CHECK_THE_ANCILLARY_DATA();
    error DELTA_OF_TOKEN_OUT_HAS_POSITIVE_VALUE();
    error DELTA_OF_TOKEN_IN_HAS_NEGATIVE_VALUE();
    error QUOTER_IS_NOT_PROVIDED();
    error DEX_ROUTER_NOT_SUPPORTED();
    error QUOTER_NOT_SUPPORTED();
    error SWAP_DEADLINE_PASSED();

    //SpotTradingRewardDistributor
    error PERIOD_DURATION_IS_ZERO();
    error REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_PERIOD_IS_NOT_CORRECT();

    //ActivityRewardDistributor
    error TOTAL_REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_DAY_IS_NOT_CORRECT();
    error ZERO_BUCKET_ADDRESS();
    //KeeperRewardDistributor
    error INCORRECT_PART_IN_REWARD();

    //Treasury
    error TRANSFER_RESTRICTIONS_NOT_MET();
    error INSUFFICIENT_NATIVE_TOKEN_BALANCE();
    error INSUFFICIENT_TOKEN_BALANCE();
    error EXCEEDED_MAX_AMOUNT_DURING_TIMEFRAME();
    error EXCEEDED_MAX_SPENDING_LIMITS();
    error SPENDING_LIMITS_ARE_INCORRECT();
    error SPENDER_IS_NOT_EXIST();
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IReferralProgramStorage} from "./IReferralProgramStorage.sol";

interface IReferralProgram is IReferralProgramStorage {
    /**
     * @dev event of register success
     * @param user  address
     * @param parent referrerOf of user
     */
    event RegisteredUser(address indexed user, address indexed parent);

    /**
     * @dev The event for set referrer by Admin.
     * @param referrer Address of a referrer added by Admin.
     */
    event SetReferrerByAdmin(address indexed referrer);

    /**
     * @dev The event for set referral by admin. The referral is set in accordance with her referrer.
     * @param referrer The address of a referrer.
     * @param referral The address of a referrer's referral.
     */
    event SetReferralByAdmin(address indexed referrer, address indexed referral);

    /**
     * @dev contract initializer
     * @param _registry The Registry contract address
     */
    function initialize(address _registry) external;

    /**
     * @dev Function to add new referral. Adds address that signed a hashed message as referrer
     * @param _referrerSignature Hash of MAGIC_MESSAGE signed by referrer
     */
    function register(bytes calldata _referrerSignature) external;

    /**
     *
     * @param referralProgramUnits Array of referrers with their referrals
     */
    function setReferrals(ReferralProgramUnit[] calldata referralProgramUnits) external;

    /**
     * @dev get list of referrers
     */
    function getReferrers() external view returns (address[] memory);

    /**
     * @dev Gets referrals array of particular referrer
     * @param _referrer The address of a referrer
     */
    function getReferralsOf(address _referrer) external view returns (address[] memory);

    /**
     * @dev The amount of referrals for a particular referrer
     * @param _referrer The address of a referrer
     */
    function getReferralsOfLength(address _referrer) external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IReferralProgramStorage {
    struct ReferralProgramUnit {
        address referrer;
        address[] referrals;
    }

    /**
     * @dev registry address
     */
    function registry() external view returns (address);

    /**
     * @dev referrer of address
     */
    function referrerOf(address) external view returns (address);

    /**
     * @dev referral Of address at index
     * @param _referrer address
     * @param _index index of referral
     * @return referral address
     */
    function referralsOf(address _referrer, uint256 _index) external view returns (address referral);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../libraries/Errors.sol";

import {ReferralProgramStorage} from "./ReferralProgramStorage.sol";
import {MEDIUM_TIMELOCK_ADMIN} from "../Constants.sol";
import {IReferralProgram} from "./IReferralProgram.sol";

contract ReferralProgram is IReferralProgram, ReferralProgramStorage {
    bytes public constant MAGIC_MESSAGE = "Referral link";

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Throws if caller is not granted with _role
     * @param _role The role that is being checked for a function caller
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControlUpgradeable(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function initialize(address _registry) external override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControlUpgradeable).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        registry = _registry;
        __ERC165_init();
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function register(bytes calldata _sig) external override {
        _require(
            referrerOf[msg.sender] == address(0) && !alreadyReferrer[msg.sender],
            Errors.CALLER_ALREADY_REGISTERED.selector
        );
        address parent = ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(MAGIC_MESSAGE), _sig);
        _require(msg.sender != parent, Errors.MISMATCH.selector);

        if (!alreadyReferrer[parent]) {
            alreadyReferrer[parent] = true;
            referrers.push(parent);
        }
        referrerOf[msg.sender] = parent;
        referralsOf[parent].push(msg.sender);
        emit RegisteredUser(msg.sender, parent);
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function setReferrals(
        ReferralProgramUnit[] calldata referralProgramUnits
    ) external override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        for (uint256 i; i < referralProgramUnits.length; i++) {
            if (referralProgramUnits[i].referrals.length > 0) {
                for (uint256 j; j < referralProgramUnits[i].referrals.length; j++) {
                    if (referrerOf[referralProgramUnits[i].referrals[j]] == address(0)) {
                        referralsOf[referralProgramUnits[i].referrer].push(referralProgramUnits[i].referrals[j]);
                        referrerOf[referralProgramUnits[i].referrals[j]] = referralProgramUnits[i].referrer;
                        emit SetReferralByAdmin(referralProgramUnits[i].referrer, referralProgramUnits[i].referrals[j]);
                    }
                }
            }
            if (
                !alreadyReferrer[referralProgramUnits[i].referrer] &&
                referralsOf[referralProgramUnits[i].referrer].length > 0
            ) {
                alreadyReferrer[referralProgramUnits[i].referrer] = true;
                referrers.push(referralProgramUnits[i].referrer);
                emit SetReferrerByAdmin(referralProgramUnits[i].referrer);
            }
        }
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function getReferralsOf(address _referrer) external view override returns (address[] memory) {
        return referralsOf[_referrer];
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function getReferralsOfLength(address _referrer) external view override returns (uint256) {
        return referralsOf[_referrer].length;
    }

    /**
     * @inheritdoc IReferralProgram
     */
    function getReferrers() external view override returns (address[] memory) {
        return referrers;
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == type(IReferralProgram).interfaceId;
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

import {IReferralProgramStorage} from "./IReferralProgramStorage.sol";

abstract contract ReferralProgramStorage is IReferralProgramStorage, ERC165Upgradeable {
    address public override registry;
    mapping(address => address) public referrerOf; // referral => referrer
    mapping(address => address[]) public referralsOf; // referrer => referrals
    address[] public referrers; // list of all referrers
    mapping(address => bool) internal alreadyReferrer;
}