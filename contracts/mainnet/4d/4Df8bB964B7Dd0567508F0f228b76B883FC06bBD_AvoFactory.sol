// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
pragma solidity >=0.8.18;

/// @title   IAvocado
/// @notice  interface to access internal vars on-chain
interface IAvocado {
    function _avoImpl() external view returns (address);

    function _data() external view returns (uint256);

    function _owner() external view returns (address);
}

/// @title      Avocado
/// @notice     Proxy for Avocados as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
//
// @dev        If this contract changes then the deployment addresses for new Avocados through factory change too!!
//             Relayers might want to pass in version as new param then to forward to the correct factory
contract Avocado {
    /// @notice flexible immutable data slot.
    /// first 20 bytes: address owner
    /// next 4 bytes: uint32 index
    /// next 1 byte: uint8 type
    /// next 9 bytes: used flexible for use-cases found in the future
    uint256 internal immutable _data;

    /// @notice address of the Avocado logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    //
    // @dev    _avoImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    //         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    //         To reduce deployment costs this variable is internal but can still be retrieved with
    //         _avoImpl(), see code and comments in fallback below
    address internal _avoImpl;

    /// @notice   sets _avoImpl & immutable _data, fetching it from msg.sender.
    //
    // @dev      those values are not input params to not influence the deterministic Create2 address!
    constructor() {
        // "\x8c\x65\x73\x89" is hardcoded bytes of function selector for transientDeployData()
        (, bytes memory deployData_) = msg.sender.staticcall(bytes("\x8c\x65\x73\x89"));

        address impl_;
        uint256 data_;
        assembly {
            // cast first 20 bytes to version address (_avoImpl)
            impl_ := mload(add(deployData_, 0x20))

            // cast bytes in position 0x40 to uint256 data; deployData_ plus 0x40 due to padding
            data_ := mload(add(deployData_, 0x40))
        }

        _data = data_;
        _avoImpl = impl_;
    }

    /// @notice Delegates the current call to `_avoImpl` unless one of the view methods is called:
    ///         `_avoImpl()` returns the address for `_avoImpl`, `_owner()` returns the first
    ///         20 bytes of `_data`, `_data()` returns `_data`.
    //
    // @dev    Mostly based on OpenZeppelin Proxy.sol
    // logic contract must not implement a function `_avoImpl()`, `_owner()` or  `_data()`
    // as they will not be callable due to collision
    fallback() external payable {
        uint256 data_ = _data;
        assembly {
            let functionSelector_ := calldataload(0)

            // 0xb2bdfa7b = function selector for _owner()
            if eq(functionSelector_, 0xb2bdfa7b00000000000000000000000000000000000000000000000000000000) {
                // store address owner at memory address 0x0, loading only last 20 bytes through the & mask
                mstore(0, and(data_, 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff))
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // 0x68beab3f = function selector for _data()
            if eq(functionSelector_, 0x68beab3f00000000000000000000000000000000000000000000000000000000) {
                mstore(0, data_) // store uint256 _data at memory address 0x0
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // load address avoImpl_ from storage
            let avoImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == 874095c6 (function selector for _avoImpl()) then we return the _avoImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(functionSelector_, 0x874095c600000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoImpl_) // store address avoImpl_ at memory address 0x0
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoImpl_, 0, calldatasize(), 0, 0)

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
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface AvocadoMultisigStructs {
    /// @notice a combination of a bytes signature and its signer.
    struct SignatureParams {
        ///
        /// @param signature ECDSA signature of `getSigDigest()` for default flow or EIP1271 smart contract signature
        bytes signature;
        ///
        /// @param signer signer of the signature. Can be set to smart contract address that supports EIP1271
        address signer;
    }

    /// @notice an arbitrary executable action
    struct Action {
        ///
        /// @param target the target address to execute the action on
        address target;
        ///
        /// @param data the calldata to be passed to the call for each target
        bytes data;
        ///
        /// @param value the msg.value to be passed to the call for each target. set to 0 if none
        uint256 value;
        ///
        /// @param operation type of operation to execute:
        /// 0 -> .call; 1 -> .delegateCall, 2 -> flashloan (via .call)
        uint256 operation;
    }

    /// @notice common params for both `cast()` and `castAuthorized()`
    struct CastParams {
        Action[] actions;
        ///
        /// @param id             Required:
        ///                       id for actions, e.g. 0 = CALL, 1 = MIXED (call and delegatecall),
        ///                                           20 = FLASHLOAN_CALL, 21 = FLASHLOAN_MIXED
        uint256 id;
        ///
        /// @param avoNonce   Required:
        ///                       avoNonce to be used for this tx. Must equal the avoNonce value on smart
        ///                       wallet or alternatively it must be set to -1 to use a non-sequential nonce instead
        int256 avoNonce;
        ///
        /// @param salt           Optional:
        ///                       Salt to customize non-sequential nonce (if `avoNonce` is set to -1)
        bytes32 salt;
        ///
        /// @param source         Optional:
        ///                       Source / referral for this tx
        address source;
        ///
        /// @param metadata       Optional:
        ///                       metadata for any potential additional data to be tracked in the tx
        bytes metadata;
    }

    /// @notice `cast()` input params related to forwarding validity
    struct CastForwardParams {
        ///
        /// @param gas            Optional:
        ///                       As EIP-2770: user instructed minimum amount of gas that the relayer (AvoForwarder)
        ///                       must send for the execution. Sending less gas will fail the tx at the cost of the relayer.
        ///                       Also protects against potential gas griefing attacks
        ///                       See https://ronan.eth.limo/blog/ethereum-gas-dangers/
        uint256 gas;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
        ///
        /// @param value          Optional:
        ///                       Not implemented / used yet (`msg.value` amount the broadcaster should send along)
        uint256 value;
    }

    /// @notice `castAuthorized()` input params
    struct CastAuthorizedParams {
        ///
        /// @param maxFee         Optional:
        ///                       the maximum Avocado charge-up allowed to be paid for tx execution
        uint256 maxFee;
        ///
        /// @param gasPrice       Optional:
        ///                       Not implemented / used yet
        uint256 gasPrice;
        ///
        /// @param validAfter     Optional:
        ///                       the earliest block timestamp that the request can be forwarded in,
        ///                       or 0 if the request is not time-limited to occur after a certain time.
        ///                       Protects against relayers executing a certain transaction at an earlier moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validAfter;
        ///
        /// @param validUntil     Optional:
        ///                       Similar to EIP-2770: the latest block timestamp (instead of block number) the request
        ///                       can be forwarded, or 0 if request should be valid forever.
        ///                       Protects against relayers executing a certain transaction at a later moment
        ///                       not intended by the user, where it might have a completely different effect.
        uint256 validUntil;
    }

    /// @notice params for `castChainAgnostic()` to be used when casting txs on multiple chains with one signature
    struct CastChainAgnosticParams {
        ///
        /// @param params cast params containing actions to be executed etc.
        CastParams params;
        ///
        /// @param forwardParams params related to forwarding validity
        CastForwardParams forwardParams;
        ///
        /// @param chainId chainId where these actions are valid
        uint256 chainId;
    }

    /// @notice unique chain agnostic hash with chain id to be used for chain agnostic interactions
    struct ChainAgnosticHash {
        ///
        /// @param hash EIP712 type `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` hash for one specific `CastChainAgnosticParams` struct
        bytes32 hash;
        ///
        /// @param chainId chainId where this `hash` is for
        uint256 chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IAvocado } from "./Avocado.sol";
import { IAvocadoMultisigV1 } from "./interfaces/IAvocadoMultisigV1.sol";
import { IAvoRegistry } from "./interfaces/IAvoRegistry.sol";
import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoForwarder } from "./interfaces/IAvoForwarder.sol";

// --------------------------- DEVELOPER NOTES -----------------------------------------
// @dev To deploy a new version of Avocado (proxy), the new factory contract must be deployed
// and AvoFactoryProxy upgraded to that new contract (to update the cached bytecode).
// -------------------------------------------------------------------------------------

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoFactory v1.1.0
/// @notice Deploys Avocado smart wallet contracts at deterministic addresses using Create2.
///
/// Upgradeable through AvoFactoryProxy
interface AvoFactory_V1 {}

abstract contract AvoFactoryErrors {
    /// @notice thrown when trying to deploy an Avocado for a smart contract as owner
    error AvoFactory__NotEOA();

    /// @notice thrown when a caller is not authorized to execute a certain action
    error AvoFactory__Unauthorized();

    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoFactory__InvalidParams();

    /// @notice thrown when deploy is called with an index where index-1 is not deployed yet.
    ///         After index > 5, index must be used sequential.
    error AvoFactory__IndexNonSequential();

    /// @notice thrown when deploy methods are called before an implementation is defined
    error AvoFactory__ImplementationNotDefined();
}

abstract contract AvoFactoryConstants is AvoFactoryErrors, IAvoFactory {
    /// @notice hardcoded Avocado creation code.
    //
    // Avocado (proxy) should never change because it influences the deterministic address
    bytes public constant avocadoCreationCode =
        hex"60a060405234801561001057600080fd5b5060408051808201825260048152638c65738960e01b60208201529051600091339161003c91906100b2565b600060405180830381855afa9150503d8060008114610077576040519150601f19603f3d011682016040523d82523d6000602084013e61007c565b606091505b506020810151604090910151608052600080546001600160a01b0319166001600160a01b03909216919091179055506100e19050565b6000825160005b818110156100d357602081860181015185830152016100b9565b506000920191825250919050565b6080516101476100fb6000396000600601526101476000f3fe60806040527f00000000000000000000000000000000000000000000000000000000000000006000357f4d42058500000000000000000000000000000000000000000000000000000000810161006f5773ffffffffffffffffffffffffffffffffffffffff821660005260206000f35b7f68beab3f0000000000000000000000000000000000000000000000000000000081036100a0578160005260206000f35b73ffffffffffffffffffffffffffffffffffffffff600054167f874095c60000000000000000000000000000000000000000000000000000000082036100ea578060005260206000f35b3660008037600080366000845af49150503d6000803e80801561010c573d6000f35b3d6000fdfea2646970667358221220bf171834b0948ebffd196d6a4208dbd5d0a71f76dfac9d90499de318c59558fc64736f6c63430008120033";

    /// @notice cached avocado (proxy) bytecode hash to optimize gas usage
    bytes32 public constant avocadoBytecode = keccak256(abi.encodePacked(avocadoCreationCode));

    /// @notice  registry holding the valid versions (addresses) for Avocado smart wallet implementation contracts.
    ///          The registry is used to verify a valid version before setting a new `avoImpl`
    ///          as default for new deployments.
    IAvoRegistry public immutable avoRegistry;

    /// @dev maximum count of avocado wallets that can be created non continuously
    uint256 internal constant _MAX_NON_CONTINUOUS_AVOCADOS = 20;

    constructor(IAvoRegistry avoRegistry_) {
        avoRegistry = avoRegistry_;

        // check hardcoded avocadoBytecode matches expected value
        if (avocadoBytecode != 0x6b106ae0e3afae21508569f62d81c7d826b900a2e9ccc973ba97abfae026fc54) {
            revert AvoFactory__InvalidParams();
        }
    }
}

abstract contract AvoFactoryVariables is AvoFactoryConstants, Initializable {
    // @dev Before variables here are vars from Initializable:
    // uint8 private _initialized;
    // bool private _initializing;

    /// @notice Avocado logic contract address that new Avocado deployments point to.
    ///         Modifiable only by `avoRegistry`.
    address public avoImpl;

    // 10 bytes empty

    // ----------------------- slot 1 to 101 ---------------------------

    // create some storage slot gaps because variables below will be replaced with transient storage vars after
    // EIP-1153 becomes available.
    uint256[101] private __gaps;

    // ----------------------- slot 102 ----------------------------

    /// @dev owner of Avocado that is currently being deployed.
    // set before deploying proxy, to return in callback `transientDeployData()`
    address internal _transientDeployOwner;

    /// @dev index of Avocado that is currently being deployed.
    // set before deploying proxy, to return in callback `transientDeployData()`
    uint32 internal _transientDeployIndex;

    // 8 bytes empty

    // ----------------------- slot 103 ----------------------------
    /// @dev version address Avocado that is currently being deployed.
    // set before deploying proxy, to return in callback `transientDeployData()`
    address internal _transientDeployVersion;

    // 12 bytes empty

    /// @dev resets transient storage to default value (1). 1 is better than 0 for optimizing gas refunds
    /// because total refund amount is capped to 20% of tx gas cost (EIP-3529).
    function _resetTransientStorage() internal {
        assembly {
            // Store 1 in the transient storage slots 102 & 103
            sstore(102, 1)
            sstore(103, 1)
        }
    }
}

abstract contract AvoFactoryEvents {
    /// @notice Emitted when a new Avocado has been deployed
    event AvocadoDeployed(address indexed owner, uint32 indexed index, uint16 avoType, address indexed avocado);

    /// @notice Emitted when a new Avocado has been deployed with a non-default version
    event AvocadoDeployedWithVersion(
        address indexed owner,
        uint32 index,
        uint16 avoType,
        address indexed avocado,
        address indexed version
    );
}

abstract contract AvoFactoryCore is AvoFactoryErrors, AvoFactoryConstants, AvoFactoryVariables, AvoFactoryEvents {
    constructor(IAvoRegistry avoRegistry_) AvoFactoryConstants(avoRegistry_) {
        if (address(avoRegistry_) == address(0)) {
            revert AvoFactory__InvalidParams();
        }

        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev            gets the salt used for deterministic deployment for `owner_` and `index_`
    /// @return         the bytes32 (keccak256) salt
    function _getSalt(address owner_, uint32 index_) internal pure returns (bytes32) {
        // use owner + index of wallet nr per EOA (plus "type", currently always 0)
        // Note CREATE2 deployments take into account the deployers address (i.e. this factory address)
        return keccak256(abi.encode(owner_, index_, 0));
    }
}

contract AvoFactory is AvoFactoryCore {
    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @dev reverts if `owner_` is a contract
    modifier onlyEOA(address owner_) {
        if (owner_ == address(0) || Address.isContract(owner_)) {
            revert AvoFactory__NotEOA();
        }
        _;
    }

    /// @dev reverts if `msg.sender` is not `avoRegistry`
    modifier onlyRegistry() {
        if (msg.sender != address(avoRegistry)) {
            revert AvoFactory__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice constructor sets the immutable `avoRegistry` address
    constructor(IAvoRegistry avoRegistry_) AvoFactoryCore(avoRegistry_) {}

    /// @notice initializes the contract
    function initialize() public initializer {
        _resetTransientStorage();
    }

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IAvoFactory
    function isAvocado(address avoSmartWallet_) external view returns (bool) {
        if (avoSmartWallet_ == address(0) || !Address.isContract(avoSmartWallet_)) {
            // can not recognize isAvocado when not yet deployed
            return false;
        }

        // get the owner from the Avocado smart wallet
        try IAvocado(avoSmartWallet_)._data() returns (uint256 data_) {
            address owner_;
            uint32 index_;

            // cast last 20 bytes of hash to owner address and 2 bytes before to index via low level assembly
            assembly {
                owner_ := and(data_, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                index_ := and(shr(160, data_), 0xFFFFFFFF) // shift right and mask to read index
            }

            // compute the Avocado address for that owner & index and check it against given address. if it
            // matches it guarantees the address is an Avocado deployed by this AvoFactory because factory
            // address is part of deterministic address computation
            if (computeAvocado(owner_, index_) == avoSmartWallet_) {
                return true;
            }
        } catch {
            // if fetching data_ (owner & index) doesn't work, can not determine if it's an Avocado smart wallet
            return false;
        }

        return false;
    }

    /// @inheritdoc IAvoFactory
    function deploy(address owner_, uint32 index_) external onlyEOA(owner_) returns (address deployedAvocado_) {
        _transientDeployVersion = avoImpl;
        if (_transientDeployVersion == address(0)) {
            revert AvoFactory__ImplementationNotDefined();
        }
        // check that a smart wallet at index -1 already exists (if > 0) to guarantee sequential use (easier to iterate)
        if (index_ > _MAX_NON_CONTINUOUS_AVOCADOS && !Address.isContract(computeAvocado(owner_, index_ - 1))) {
            revert AvoFactory__IndexNonSequential();
        }

        _transientDeployOwner = owner_;
        _transientDeployIndex = index_;

        // deploy Avocado deterministically using low level CREATE2 opcode to use hardcoded Avocado bytecode
        bytes32 salt_ = _getSalt(owner_, index_);
        bytes memory byteCode_ = avocadoCreationCode;
        assembly {
            deployedAvocado_ := create2(0, add(byteCode_, 0x20), mload(byteCode_), salt_)
        }

        _resetTransientStorage();

        // initialize AvocadoMultisig through proxy with IAvocadoMultisig interface.
        // if version or owner would not be correctly set at the deployed contract, this would revert.
        IAvocadoMultisigV1(deployedAvocado_).initialize();

        emit AvocadoDeployed(owner_, index_, 0, deployedAvocado_);
    }

    /// @inheritdoc IAvoFactory
    function deployWithVersion(
        address owner_,
        uint32 index_,
        address avoVersion_
    ) external onlyEOA(owner_) returns (address deployedAvocado_) {
        avoRegistry.requireValidAvoVersion(avoVersion_);

        // check that a smart wallet at index -1 already exists (if > 0) to guarantee sequential use (easier to iterate)
        if (index_ > _MAX_NON_CONTINUOUS_AVOCADOS && !Address.isContract(computeAvocado(owner_, index_ - 1))) {
            revert AvoFactory__InvalidParams();
        }

        _transientDeployOwner = owner_;
        _transientDeployIndex = index_;
        _transientDeployVersion = avoVersion_;

        // deploy Avocado deterministically using low level CREATE2 opcode to use hardcoded Avocado bytecode
        bytes32 salt_ = _getSalt(owner_, index_);
        bytes memory byteCode_ = avocadoCreationCode;
        assembly {
            deployedAvocado_ := create2(0, add(byteCode_, 0x20), mload(byteCode_), salt_)
        }

        _resetTransientStorage();

        // initialize AvocadoMultisig through proxy with IAvocadoMultisig interface.
        // if version or owner would not be correctly set at the deployed contract, this would revert.
        IAvocadoMultisigV1(deployedAvocado_).initialize();

        emit AvocadoDeployedWithVersion(owner_, index_, 0, deployedAvocado_, avoVersion_);
    }

    /// @inheritdoc IAvoFactory
    function computeAvocado(address owner_, uint32 index_) public view returns (address computedAddress_) {
        if (Address.isContract(owner_)) {
            // owner of a Avocado must be an EOA, if it's a contract return zero address
            return address(0);
        }

        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _getSalt(owner_, index_), avocadoBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @notice returns transient data used to pass variables into the Avocado proxy during deployment.
    /// Reduces gas cost and dependency of deterministic address on constructor args.
    function transientDeployData() external view returns (address version_, uint256 data_) {
        data_ =
            /* (uint256(0) << 192) | type currently not used, always 0 */
            (uint256(_transientDeployIndex) << 160) |
            uint256(uint160(_transientDeployOwner));
        return (_transientDeployVersion, data_);
    }

    /***********************************|
    |            ONLY  REGISTRY         |
    |__________________________________*/

    /// @inheritdoc IAvoFactory
    function setAvoImpl(address avoImpl_) external onlyRegistry {
        // do not `registry.requireValidAvoVersion()` because sender is registry anyway
        avoImpl = avoImpl_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { AvocadoMultisigStructs } from "../AvocadoMultisig/AvocadoMultisigStructs.sol";

// @dev base interface without getters for storage variables (to avoid overloads issues)
interface IAvocadoMultisigV1Base is AvocadoMultisigStructs {
    /// @notice initializer called by AvoFactory after deployment, sets the `owner_` as the only signer
    function initialize() external;

    /// @notice returns the domainSeparator for EIP712 signature
    function domainSeparatorV4() external view returns (bytes32);

    /// @notice returns the domainSeparator for EIP712 signature for `castChainAgnostic`
    function domainSeparatorV4ChainAgnostic() external view returns (bytes32);

    /// @notice               gets the digest (hash) used to verify an EIP712 signature for `cast()`.
    ///
    ///                       This is also used as the non-sequential nonce that will be marked as used when the
    ///                       request with the matching `params_` and `forwardParams_` is executed via `cast()`.
    /// @param params_        Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_ Cast params related to validity of forwarding as instructed and signed
    /// @return               bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigest(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_
    ) external view returns (bytes32);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castAuthorized()`.
    ///
    ///                           This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` and `authorizedParams_` is executed via `castAuthorized()`.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @return                   bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_
    ) external view returns (bytes32);

    /// @notice                   Verify the signatures for a `cast()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verify(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Verify the signatures for a `castAuthorized()' call are valid and can be executed.
    ///                           This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                           Does not revert and returns successfully if the input is valid.
    ///                           Reverts if input params, signature or avoNonce etc. are invalid.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return                   returns true if everything is valid, otherwise reverts
    function verifyAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external view returns (bool);

    /// @notice                   Executes arbitrary actions with valid signatures. Only executable by AvoForwarder.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_     Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails in the following format:
    ///                           The revert reason will be prefixed with the index of the action.
    ///                           e.g. if action 1 fails, then the reason will be "1_reason".
    ///                           if an action in the flashloan callback fails (or an otherwise nested action),
    ///                           it will be prefixed with with two numbers: "1_2_reason".
    ///                           e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                           the reason will be 1_2_reason.
    function cast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   Simulates a `cast()` call with exact same params and execution logic except for:
    ///                           - any `gasleft()` use removed to remove potential problems when estimating gas.
    ///                           - reverts on param validations removed (verify validity with `verify` instead).
    ///                           - signature validation is skipped (must be manually added to gas estimations).
    /// @dev                      tx.origin must be dead address, msg.sender must be AvoForwarder.
    /// @dev                      - set `signaturesParams_` to empty to automatically simulate with required signers length.
    ///                           - if `signaturesParams_` first element signature is not set, or if first signer is set to
    ///                             0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, then gas usage burn is simulated
    ///                             for verify signature functionality. DO NOT set signature to non-empty for subsequent
    ///                             elements then; set all signatures to empty!
    ///                           - if `signaturesParams_` is set normally, signatures are verified as in actual execute
    ///                           - buffer amounts for mock smart contract signers signature verification must be added
    ///                             off-chain as this varies on a case per case basis.
    function simulateCast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_);

    /// @notice                   Exact same as `simulateCast`, just reverts in case of `success_` = false to optimize
    ///                           for use with .estimateGas().
    function estimateCast(
        CastParams calldata params_,
        CastForwardParams calldata forwardParams_,
        SignatureParams[] memory signaturesParams_
    ) external payable returns (bool success_, string memory revertReason_);

    /// @notice                   Executes arbitrary actions through authorized transaction sent with valid signatures.
    ///                           Includes a fee in native network gas token, amount depends on registry `calcFee()`.
    ///                           If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                           In that case, all previous actions are reverted.
    ///                           On success, emits CastExecuted event.
    /// @dev                      executes a .call or .delegateCall for every action (depending on params)
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @param authorizedParams_  Cast params related to authorized execution such as maxFee, as signed
    /// @param signaturesParams_  SignatureParams structs array for signature and signer:
    ///                           - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                             For smart contract signatures it must fulfill the requirements for the relevant
    ///                             smart contract `.isValidSignature()` EIP1271 logic
    ///                           - signer: address of the signature signer.
    ///                             Must match the actual signature signer or refer to the smart contract
    ///                             that must be an allowed signer and validates signature via EIP1271
    /// @return success           true if all actions were executed succesfully, false otherwise.
    /// @return revertReason      revert reason if one of the actions fails in the following format:
    ///                           The revert reason will be prefixed with the index of the action.
    ///                           e.g. if action 1 fails, then the reason will be "1_reason".
    ///                           if an action in the flashloan callback fails (or an otherwise nested action),
    ///                           it will be prefixed with with two numbers: "1_2_reason".
    ///                           e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                           the reason will be 1_2_reason.
    function castAuthorized(
        CastParams calldata params_,
        CastAuthorizedParams calldata authorizedParams_,
        SignatureParams[] calldata signaturesParams_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice returns the hashes struct for each `CastChainAgnosticParams` element of `params_`. The returned array must be
    ///         passed into `castChainAgnostic()` as the param `chainAgnosticHashes_` there (order must be the same).
    ///         The returned hash for each element is the EIP712 type hash for `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH`,
    ///         as used when the signature digest is built.
    function getChainAgnosticHashes(
        CastChainAgnosticParams[] calldata params_
    ) external pure returns (ChainAgnosticHash[] memory chainAgnosticHashes_);

    /// @notice                   gets the digest (hash) used to verify an EIP712 signature for `castChainAgnostic()`,
    ///                           built from the `CastChainAgnosticParams`.
    ///
    ///                           This is also the non-sequential nonce that will be marked as used when the request
    ///                           with the matching `params_` is executed via `castChainAgnostic()`.
    /// @param params_            Cast params such as id, avoNonce and actions to execute
    /// @return                   bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestChainAgnostic(CastChainAgnosticParams[] calldata params_) external view returns (bytes32);

    /// @notice                     gets the digest (hash) used to verify an EIP712 signature for `castChainAgnostic()`,
    ///                             built from the chain agnostic hashes (result of `getChainAgnosticHashes()`).
    ///
    ///                             This is also the non-sequential nonce that will be marked as used when the request
    ///                             with the matching `params_` is executed via `castChainAgnostic()`.
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return                     bytes32 digest to verify signature (or used as non-sequential nonce)
    function getSigDigestChainAgnosticFromHashes(
        ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external view returns (bytes32);

    /// @notice                     Executes arbitrary actions with valid signatures. Only executable by AvoForwarder.
    ///                             If one action fails, the transaction doesn't revert, instead emits the `CastFailed` event.
    ///                             In that case, all previous actions are reverted.
    ///                             On success, emits CastExecuted event.
    /// @dev                        validates EIP712 signature then executes each action via .call or .delegatecall
    /// @param params_              params containing info and intents regarding actions to be executed. Made up of
    ///                             same params as for `cast()` plus chain id.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return success             true if all actions were executed succesfully, false otherwise.
    /// @return revertReason        revert reason if one of the actions fails in the following format:
    ///                             The revert reason will be prefixed with the index of the action.
    ///                             e.g. if action 1 fails, then the reason will be "1_reason".
    ///                             if an action in the flashloan callback fails (or an otherwise nested action),
    ///                             it will be prefixed with with two numbers: "1_2_reason".
    ///                             e.g. if action 1 is the flashloan, and action 2 of flashloan actions fails,
    ///                             the reason will be 1_2_reason.
    function castChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external payable returns (bool success, string memory revertReason);

    /// @notice                   Simulates a `castChainAgnostic()` call with exact same params and execution logic except for:
    ///                           - any `gasleft()` use removed to remove potential problems when estimating gas.
    ///                           - reverts on param validations removed (verify validity with `verify` instead).
    ///                           - signature validation is skipped (must be manually added to gas estimations).
    /// @dev                      tx.origin must be dead address, msg.sender must be AvoForwarder.
    /// @dev                      - set `signaturesParams_` to empty to automatically simulate with required signers length.
    ///                           - if `signaturesParams_` first element signature is not set, or if first signer is set to
    ///                             0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, then gas usage burn is simulated
    ///                             for verify signature functionality. DO NOT set signature to non-empty for subsequent
    ///                             elements then; set all signatures to empty!
    ///                           - if `signaturesParams_` is set normally, signatures are verified as in actual execute
    ///                           - buffer amounts for mock smart contract signers signature verification must be added
    ///                             off-chain as this varies on a case per case basis.
    function simulateCastChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external payable returns (bool success_, string memory revertReason_);

    /// @notice                   Exact same as `simulateCastChainAgnostic`, just reverts in case of `success_` = false to
    ///                           optimize for use with .estimateGas().
    function estimateCastChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] memory signaturesParams_,
        ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external payable returns (bool success_, string memory revertReason_);

    /// @notice                     Verify the signatures for a `castChainAgnostic()' call are valid and can be executed.
    ///                             This does not guarantuee that the tx will not revert, simply that the params are valid.
    ///                             Does not revert and returns successfully if the input is valid.
    ///                             Reverts if input params, signature or avoNonce etc. are invalid.
    /// @param params_              params containing info and intents regarding actions to be executed. Made up of
    ///                             same params as for `cast()` plus chain id.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ EIP712 type hashes of `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH` for all `CastChainAgnosticParams`
    ///                             struct array elements as used when creating the signature. Result of `getChainAgnosticHashes()`.
    ///                             must be set in the same order as when creating the signature.
    /// @return                     returns true if everything is valid, otherwise reverts
    function verifyChainAgnostic(
        CastChainAgnosticParams calldata params_,
        SignatureParams[] calldata signaturesParams_,
        ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external view returns (bool);

    /// @notice checks if an address `signer_` is an allowed signer (returns true if allowed)
    function isSigner(address signer_) external view returns (bool);

    /// @notice returns allowed signers on Avocado wich can trigger actions if reaching quorum `requiredSigners`.
    ///         signers automatically include owner.
    function signers() external view returns (address[] memory signers_);

    /// @notice returns the number of required signers
    function requiredSigners() external view returns (uint8);

    /// @notice returns the number of allowed signers
    function signersCount() external view returns (uint8);

    /// @notice Avocado owner
    function owner() external view returns (address);

    /// @notice Avocado index (number of Avocado for EOA owner)
    function index() external view returns (uint32);
}

// @dev full interface with some getters for storage variables
interface IAvocadoMultisigV1 is IAvocadoMultisigV1Base {
    /// @notice Domain separator name for signatures
    function DOMAIN_SEPARATOR_NAME() external view returns (string memory);

    /// @notice Domain separator version for signatures
    function DOMAIN_SEPARATOR_VERSION() external view returns (string memory);

    /// @notice incrementing nonce for each valid tx executed (to ensure uniqueness)
    function avoNonce() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IAvoRegistry } from "./IAvoRegistry.sol";

interface IAvoFactory {
    /// @notice returns AvoRegistry (proxy) address
    function avoRegistry() external view returns (IAvoRegistry);

    /// @notice returns Avocado logic contract address that new Avocado deployments point to
    function avoImpl() external view returns (address);

    /// @notice                 Checks if a certain address is an Avocado smart wallet.
    ///                         Only works for already deployed wallets.
    /// @param avoSmartWallet_  address to check
    /// @return                 true if address is an Avocado
    function isAvocado(address avoSmartWallet_) external view returns (bool);

    /// @notice                     Computes the deterministic Avocado address for `owner_` based on Create2
    /// @param owner_               Avocado owner
    /// @param index_               index number of Avocado for `owner_` EOA
    /// @return computedAddress_    computed address for the Avocado contract
    function computeAvocado(address owner_, uint32 index_) external view returns (address computedAddress_);

    /// @notice         Deploys an Avocado for a certain `owner_` deterministcally using Create2.
    ///                 Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_   Avocado owner
    /// @param index_   index number of Avocado for `owner_` EOA
    /// @return         deployed address for the Avocado contract
    function deploy(address owner_, uint32 index_) external returns (address);

    /// @notice                    Deploys an Avocado with non-default version for an `owner_`
    ///                            deterministcally using Create2.
    ///                            Does not check if contract at address already exists (AvoForwarder does that)
    /// @param owner_              Avocado owner
    /// @param index_              index number of Avocado for `owner_` EOA
    /// @param avoVersion_         Version of Avocado logic contract to deploy
    /// @return                    deployed address for the Avocado contract
    function deployWithVersion(address owner_, uint32 index_, address avoVersion_) external returns (address);

    /// @notice                 registry can update the current Avocado implementation contract set as default
    ///                         `_avoImpl` logic contract address for new deployments
    /// @param avoImpl_ the new avoImpl address
    function setAvoImpl(address avoImpl_) external;

    /// @notice returns the bytecode (hash) for the Avocado contract used for Create2 address computation
    function avocadoBytecode() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { IAvoFactory } from "./IAvoFactory.sol";

interface IAvoForwarder {
    /// @notice returns the AvoFactory (proxy) address
    function avoFactory() external view returns (IAvoFactory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

interface IAvoFeeCollector {
    /// @notice fee config params used to determine the fee for Avocado smart wallet `castAuthorized()` calls
    struct FeeConfig {
        ///
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        ///
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        ///
        /// @param fee current fee amount:
        /// - for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%)
        /// - for static mode: absolute amount in native gas token to charge
        ///                    (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the `feeAmount_` for an Avocado (`msg.sender`) transaction `gasUsed_` based on
    ///         fee configuration present on the contract
    /// @param  gasUsed_       amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculated fee amount to be paid
    /// @return feeCollector_ address to send the fee to
    function calcFee(uint256 gasUsed_) external view returns (uint256 feeAmount_, address payable feeCollector_);
}

interface IAvoRegistry is IAvoFeeCollector {
    /// @notice                      checks if an address is listed as allowed AvoForwarder version, reverts if not.
    /// @param avoForwarderVersion_  address of the AvoForwarder logic contract to check
    function requireValidAvoForwarderVersion(address avoForwarderVersion_) external view;

    /// @notice                     checks if an address is listed as allowed Avocado version, reverts if not.
    /// @param avoVersion_          address of the Avocado logic contract to check
    function requireValidAvoVersion(address avoVersion_) external view;
}