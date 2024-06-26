// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
        ///                       Not implemented / used yet (msg.value broadcaster should send along)
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
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import { IAvoFactory } from "./interfaces/IAvoFactory.sol";
import { IAvoForwarder } from "./interfaces/IAvoForwarder.sol";
import { IAvocadoMultisigV1 } from "./interfaces/IAvocadoMultisigV1.sol";

// empty interface used for Natspec docs for nice layout in automatically generated docs:
//
/// @title  AvoForwarder v1.1.0
/// @notice Handles executing authorized actions (through signatures) at Avocados, triggered by allow-listed broadcasters.
/// @dev Only compatible with forwarding `cast` calls to Avocado smart wallet contracts.
/// This is not a generic forwarder.
/// This is NOT a "TrustedForwarder" as proposed in EIP-2770, see info in Avocado smart wallet contracts.
///
/// Does not validate the EIP712 signature (instead this is done in the smart wallet itself).
///
/// Upgradeable through AvoForwarderProxy
interface AvoForwarder_V1 {}

abstract contract AvoForwarderConstants is IAvoForwarder {
    /// @notice AvoFactory (proxy) used to deploy new Avocado smart wallets.
    //
    // @dev     If this changes then the deployment addresses for Avocado smart wallets change too. A more complex
    //          system with versioning would have to be implemented then for most methods.
    IAvoFactory public immutable avoFactory;

    /// @notice cached Avocado Bytecode to directly compute address in this contract to optimize gas usage.
    //
    // @dev If this changes because of an Avocado change (and AvoFactory upgrade),
    // then this variable must be updated through an upgrade, deploying a new AvoForwarder!
    bytes32 public constant avocadoBytecode = 0x6b106ae0e3afae21508569f62d81c7d826b900a2e9ccc973ba97abfae026fc54;

    /// @dev amount of gas to keep in cast caller method as reserve for emitting Executed / ExecuteFailed event.
    /// ~6920 gas + buffer. the dynamic part is covered with EMIT_EVENT_COST_PER_BYTE (for metadata).
    uint256 internal constant EVENTS_RESERVE_GAS = 8_500;

    /// @dev emitting one byte in an event costs 8 byte see https://github.com/wolflo/evm-opcodes/blob/main/gas.md#a8-log-operations
    uint256 internal constant EMIT_EVENT_COST_PER_BYTE = 8;

    constructor(IAvoFactory avoFactory_) {
        avoFactory = avoFactory_;
    }
}

abstract contract AvoForwarderVariables is AvoForwarderConstants, Initializable, OwnableUpgradeable {
    // @dev variables here start at storage slot 101, before is:
    // - Initializable with storage slot 0:
    // uint8 private _initialized;
    // bool private _initializing;
    // - OwnableUpgradeable with slots 1 to 100:
    // uint256[50] private __gap; (from ContextUpgradeable, slot 1 until slot 50)
    // address private _owner; (at slot 51)
    // uint256[49] private __gap; (slot 52 until slot 100)

    // ---------------- slot 101 -----------------

    /// @notice allowed broadcasters that can call `execute()` methods. allowed if set to `1`
    mapping(address => uint256) internal _broadcasters;

    // ---------------- slot 102 -----------------

    /// @notice allowed auths. allowed if set to `1`
    mapping(address => uint256) internal _auths;
}

abstract contract AvoForwarderErrors {
    /// @notice thrown when a method is called with invalid params (e.g. zero address)
    error AvoForwarder__InvalidParams();

    /// @notice thrown when a caller is not authorized to execute a certain action
    error AvoForwarder__Unauthorized();

    /// @notice thrown when trying to execute legacy methods for a not yet deployed Avocado smart wallet
    error AvoForwarder__LegacyVersionNotDeployed();

    /// @notice thrown when an unsupported method is called (e.g. renounceOwnership)
    error AvoForwarder__Unsupported();
}

abstract contract AvoForwarderStructs {
    /// @notice struct mapping an address value to a boolean flag.
    //
    // @dev when used as input param, removes need to make sure two input arrays are of same length etc.
    struct AddressBool {
        address addr;
        bool value;
    }

    struct ExecuteBatchParams {
        address from;
        uint32 index;
        IAvocadoMultisigV1.CastChainAgnosticParams params;
        IAvocadoMultisigV1.SignatureParams[] signaturesParams;
        IAvocadoMultisigV1.ChainAgnosticHash[] chainAgnosticHashes;
    }

    struct SimulateBatchResult {
        uint256 castGasUsed;
        bool success;
        string revertReason;
    }
}

abstract contract AvoForwarderEvents is AvoForwarderStructs {
    /// @notice emitted when all actions for `cast()` in an `execute()` method are executed successfully
    event Executed(
        address indexed avocadoOwner,
        uint32 index,
        address indexed avocadoAddress,
        address indexed source,
        bytes metadata
    );

    /// @notice emitted if one of the actions for `cast()` in an `execute()` method fails
    event ExecuteFailed(
        address indexed avocadoOwner,
        uint32 index,
        address indexed avocadoAddress,
        address indexed source,
        bytes metadata,
        string reason
    );

    /// @notice emitted if a broadcaster's allowed status is updated
    event BroadcasterUpdated(address indexed broadcaster, bool indexed status);

    /// @notice emitted if an auth's allowed status is updated
    event AuthUpdated(address indexed auth, bool indexed status);
}

abstract contract AvoForwarderCore is
    AvoForwarderConstants,
    AvoForwarderVariables,
    AvoForwarderStructs,
    AvoForwarderEvents,
    AvoForwarderErrors
{
    /***********************************|
    |             MODIFIERS             |
    |__________________________________*/

    /// @dev checks if `msg.sender` is an allowed broadcaster
    modifier onlyBroadcaster() {
        if (_broadcasters[msg.sender] != 1) {
            revert AvoForwarder__Unauthorized();
        }
        _;
    }

    /// @dev checks if an address is not the zero address
    modifier validAddress(address _address) {
        if (_address == address(0)) {
            revert AvoForwarder__InvalidParams();
        }
        _;
    }

    /***********************************|
    |            CONSTRUCTOR            |
    |__________________________________*/

    constructor(IAvoFactory avoFactory_) validAddress(address(avoFactory_)) AvoForwarderConstants(avoFactory_) {
        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev gets or if necessary deploys an Avocado for owner `from_` and `index_` and returns the address
    function _getDeployedAvocado(address from_, uint32 index_) internal returns (address) {
        address computedAvocadoAddress_ = _computeAvocado(from_, index_);
        if (Address.isContract(computedAvocadoAddress_)) {
            return computedAvocadoAddress_;
        } else {
            return avoFactory.deploy(from_, index_);
        }
    }

    /// @dev executes `_getDeployedAvocado` with gas measurements
    function _getSimulateDeployedAvocado(
        address from_,
        uint32 index_
    ) internal returns (IAvocadoMultisigV1 avocado_, uint256 deploymentGasUsed_, bool isDeployed_) {
        if (msg.sender != 0x000000000000000000000000000000000000dEaD) {
            revert AvoForwarder__Unauthorized();
        }

        uint256 gasSnapshotBefore_ = gasleft();
        // `_getDeployedAvocado()` automatically checks if Avocado has to be deployed
        // or if it already exists and simply returns the address in that case
        avocado_ = IAvocadoMultisigV1(_getDeployedAvocado(from_, index_));
        deploymentGasUsed_ = gasSnapshotBefore_ - gasleft();

        isDeployed_ = deploymentGasUsed_ < 100_000; // avocado for sure not yet deployed if gas used > 100k
        // (deployment costs > 200k)
    }

    /// @dev computes the deterministic contract address for an Avocado deployment for `owner_` and `index_`
    function _computeAvocado(address owner_, uint32 index_) internal view returns (address computedAddress_) {
        // replicate Create2 address determination logic
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(avoFactory), _getSalt(owner_, index_), avocadoBytecode)
        );

        // cast last 20 bytes of hash to address via low level assembly
        assembly {
            computedAddress_ := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /// @dev gets the bytes32 salt used for deterministic Avocado deployment for `owner_` and `index_`, same as on AvoFactory
    function _getSalt(address owner_, uint32 index_) internal pure returns (bytes32) {
        // use owner + index of avocado nr per EOA (plus "type", currently always 0)
        // Note CREATE2 deployments take into account the deployers address (i.e. this factory address)
        return keccak256(abi.encode(owner_, index_, 0));
    }

    /// @dev returns the dynamic reserve gas to be kept back for emitting the Executed or ExecuteFailed event
    function _dynamicReserveGas(uint256 metadataLength_) internal pure returns (uint256 reserveGas_) {
        unchecked {
            // the gas usage for the emitting the CastExecuted/CastFailed events depends on the  metadata bytes length,
            // dynamically calculated with cost per byte for emit event
            reserveGas_ = EVENTS_RESERVE_GAS + (EMIT_EVENT_COST_PER_BYTE * metadataLength_);
        }
    }

    /// @dev Deploys Avocado for owner if necessary and calls `cast()` on it with given input params.
    function _executeV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastParams calldata params_,
        IAvocadoMultisigV1.CastForwardParams calldata forwardParams_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_
    ) internal returns (bool success_) {
        // `_getDeployedAvocado()` automatically checks if Avocado has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvocadoMultisigV1 avocadoMultisig_ = IAvocadoMultisigV1(_getDeployedAvocado(from_, index_));

        string memory revertReason_;
        (success_, revertReason_) = avocadoMultisig_.cast{
            value: forwardParams_.value,
             // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
             // will be kept back or 1/64th according to EIP150 (whichever is bigger).
            gas: gasleft() - _dynamicReserveGas(params_.metadata.length)
        }(params_, forwardParams_, signaturesParams_);

        // @dev on changes in the code below this point, measure the needed reserve gas via `gasleft()` anew
        // and update the reserve gas constant amount.
        // gas measurement currently: ~6920 gas for emit event with max revertReason length
        if (success_) {
            emit Executed(from_, index_, address(avocadoMultisig_), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(
                from_,
                index_,
                address(avocadoMultisig_),
                params_.source,
                params_.metadata,
                revertReason_
            );
        }
        // @dev ending point for measuring reserve gas should be here.
    }

    /// @dev Deploys Avocado for owner if necessary and calls `castChainAgnostic()` on it with given input params.
    function _executeChainAgnosticV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastChainAgnosticParams calldata params_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_,
        IAvocadoMultisigV1.ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) internal returns (bool success_) {
        // `_getDeployedAvocado()` automatically checks if Avocado has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvocadoMultisigV1 avocadoMultisig_ = IAvocadoMultisigV1(_getDeployedAvocado(from_, index_));

        string memory revertReason_;
        (success_, revertReason_) = avocadoMultisig_.castChainAgnostic{ 
                value: params_.forwardParams.value,
                // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
                // will be kept back or 1/64th according to EIP150 (whichever is bigger).
                gas: gasleft() - _dynamicReserveGas(params_.params.metadata.length)
            }(
            params_,
            signaturesParams_,
            chainAgnosticHashes_
        );

        // @dev on changes below, reserve gas must be updated. see _executeV1.
        if (success_) {
            emit Executed(from_, index_, address(avocadoMultisig_), params_.params.source, params_.params.metadata);
        } else {
            emit ExecuteFailed(
                from_,
                index_,
                address(avocadoMultisig_),
                params_.params.source,
                params_.params.metadata,
                revertReason_
            );
        }
    }
}

abstract contract AvoForwarderViews is AvoForwarderCore {
    /// @notice checks if a `broadcaster_` address is an allowed broadcaster
    function isBroadcaster(address broadcaster_) external view returns (bool) {
        return _broadcasters[broadcaster_] == 1;
    }

    /// @notice checks if an `auth_` address is an allowed auth
    function isAuth(address auth_) external view returns (bool) {
        return _auths[auth_] == 1;
    }
}

abstract contract AvoForwarderViewsAvocado is AvoForwarderCore {
    /// @notice        Retrieves the current avoNonce of AvocadoMultisig for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  Avocado owner to retrieve the nonce for.
    /// @param index_  index number of Avocado for `owner_` EOA
    /// @return        returns the avoNonce for the `owner_` necessary to sign a meta transaction
    function avoNonce(address owner_, uint32 index_) external view returns (uint256) {
        address avoAddress_ = _computeAvocado(owner_, index_);
        if (Address.isContract(avoAddress_)) {
            return IAvocadoMultisigV1(avoAddress_).avoNonce();
        }

        return 0;
    }

    /// @notice        Retrieves the current AvocadoMultisig implementation name for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  Avocado owner to retrieve the name for.
    /// @param index_  index number of Avocado for `owner_` EOA
    /// @return        returns the domain separator name for the `owner_` necessary to sign a meta transaction
    function avocadoVersionName(address owner_, uint32 index_) external view returns (string memory) {
        address avoAddress_ = _computeAvocado(owner_, index_);
        if (Address.isContract(avoAddress_)) {
            // if AvocadoMultisig is deployed, return value from deployed contract
            return IAvocadoMultisigV1(avoAddress_).DOMAIN_SEPARATOR_NAME();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvocadoMultisigV1(avoFactory.avoImpl()).DOMAIN_SEPARATOR_NAME();
    }

    /// @notice        Retrieves the current AvocadoMultisig implementation version for `owner_` address.
    ///                Needed for signatures.
    /// @param owner_  Avocado owner to retrieve the version for.
    /// @param index_  index number of Avocado for `owner_` EOA
    /// @return        returns the domain separator version for the `owner_` necessary to sign a meta transaction
    function avocadoVersion(address owner_, uint32 index_) external view returns (string memory) {
        address avoAddress_ = _computeAvocado(owner_, index_);
        if (Address.isContract(avoAddress_)) {
            // if AvocadoMultisig is deployed, return value from deployed contract
            return IAvocadoMultisigV1(avoAddress_).DOMAIN_SEPARATOR_VERSION();
        }

        // otherwise return default value for current implementation that will be deployed
        return IAvocadoMultisigV1(avoFactory.avoImpl()).DOMAIN_SEPARATOR_VERSION();
    }

    /// @notice Computes the deterministic Avocado address for `owner_` and `index_`
    function computeAvocado(address owner_, uint32 index_) external view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a Avocado must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeAvocado(owner_, index_);
    }

    /// @notice returns the hashes struct for each `CastChainAgnosticParams` element of `params_`. The returned array must be
    ///         passed into `castChainAgnostic()` as the param `chainAgnosticHashes_` there (order must be the same).
    ///         The returned hash for each element is the EIP712 type hash for `CAST_CHAIN_AGNOSTIC_PARAMS_TYPE_HASH`,
    ///         as used when the signature digest is built.
    /// @dev    Deploys the Avocado if necessary. Expected to be called with callStatic.
    function getAvocadoChainAgnosticHashes(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastChainAgnosticParams[] calldata params_
    ) external returns (IAvocadoMultisigV1.ChainAgnosticHash[] memory chainAgnosticHashes_) {
        // `_getDeployedAvocado()` automatically checks if Avocado has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvocadoMultisigV1 avocadoMultisig_ = IAvocadoMultisigV1(_getDeployedAvocado(from_, index_));

        return avocadoMultisig_.getChainAgnosticHashes(params_);
    }
}

abstract contract AvoForwarderV1 is AvoForwarderCore {
    /// @notice                  Deploys Avocado for owner if necessary and calls `cast()` on it.
    ///                          For Avocado v1.
    ///                          Only callable by allowed broadcasters.
    /// @param from_             Avocado owner
    /// @param index_            index number of Avocado for `owner_` EOA
    /// @param params_           Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ SignatureParams structs array for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                            For smart contract signatures it must fulfill the requirements for the relevant
    ///                            smart contract `.isValidSignature()` EIP1271 logic
    ///                          - signer: address of the signature signer.
    ///                            Must match the actual signature signer or refer to the smart contract
    ///                            that must be an allowed signer and validates signature via EIP1271
    function executeV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastParams calldata params_,
        IAvocadoMultisigV1.CastForwardParams calldata forwardParams_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_
    ) external payable onlyBroadcaster {
        _executeV1(from_, index_, params_, forwardParams_, signaturesParams_);
    }

    /// @notice                  Verify the transaction is valid and can be executed.
    ///                          IMPORTANT: Expected to be called via callStatic.
    ///
    ///                          Returns true if valid, reverts otherwise:
    ///                          e.g. if input params, signature or avoNonce etc. are invalid.
    /// @param from_             Avocado owner
    /// @param index_            index number of Avocado for `owner_` EOA
    /// @param params_           Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ SignatureParams structs array for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                            For smart contract signatures it must fulfill the requirements for the relevant
    ///                            smart contract `.isValidSignature()` EIP1271 logic
    ///                          - signer: address of the signature signer.
    ///                            Must match the actual signature signer or refer to the smart contract
    ///                            that must be an allowed signer and validates signature via EIP1271
    /// @return                  returns true if everything is valid, otherwise reverts.
    //
    // @dev can not be marked as view because it does potentially modify state by deploying the
    //      AvocadoMultisig for `from_` if it does not exist yet. Thus expected to be called via callStatic
    function verifyV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastParams calldata params_,
        IAvocadoMultisigV1.CastForwardParams calldata forwardParams_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_
    ) external returns (bool) {
        // `_getDeployedAvocado()` automatically checks if Avocado has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvocadoMultisigV1 avocadoMultisig_ = IAvocadoMultisigV1(_getDeployedAvocado(from_, index_));

        return avocadoMultisig_.verify(params_, forwardParams_, signaturesParams_);
    }
}

abstract contract AvoForwarderChainAgnosticV1 is AvoForwarderCore {
    /// @notice                     Deploys Avocado for owner if necessary and calls `castChainAgnostic()` on it.
    ///                             For Avocado v1.
    ///                             Only callable by allowed broadcasters.
    /// @param from_                Avocado owner
    /// @param index_               index number of Avocado for `owner_` EOA
    /// @param params_              Chain agnostic params containing CastParams, ForwardParams and chain id.
    ///                             Note chain id must match block.chainid.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ hashes struct for each original `CastChainAgnosticParams` struct as used when signing the
    ///                             txs to be executed. Result of `.getChainAgnosticHashes()`.
    function executeChainAgnosticV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastChainAgnosticParams calldata params_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_,
        IAvocadoMultisigV1.ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external payable onlyBroadcaster {
        _executeChainAgnosticV1(from_, index_, params_, signaturesParams_, chainAgnosticHashes_);
    }

    /// @notice                     Verify the transaction is a valid chain agnostic tx and can be executed.
    ///                             IMPORTANT: Expected to be called via callStatic.
    ///
    ///                             Returns true if valid, reverts otherwise:
    ///                             e.g. if input params, signature or avoNonce etc. are invalid.
    /// @param from_                Avocado owner
    /// @param index_               index number of Avocado for `owner_` EOA
    /// @param params_              Chain agnostic params containing CastParams, ForwardParams and chain id.
    ///                             Note chain id must match block.chainid.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ hashes struct for each original `CastChainAgnosticParams` struct as used when signing the
    ///                             txs to be executed. Result of `.getChainAgnosticHashes()`.
    /// @return                     returns true if everything is valid, otherwise reverts.
    //
    // @dev can not be marked as view because it does potentially modify state by deploying the
    //      AvocadoMultisig for `from_` if it does not exist yet. Thus expected to be called via callStatic
    function verifyChainAgnosticV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastChainAgnosticParams calldata params_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_,
        IAvocadoMultisigV1.ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external returns (bool) {
        // `_getDeployedAvocado()` automatically checks if Avocado has to be deployed
        // or if it already exists and simply returns the address in that case
        IAvocadoMultisigV1 avocadoMultisig_ = IAvocadoMultisigV1(_getDeployedAvocado(from_, index_));

        return avocadoMultisig_.verifyChainAgnostic(params_, signaturesParams_, chainAgnosticHashes_);
    }
}

abstract contract AvoForwarderBatchV1 is AvoForwarderCore {
    /// @notice                  Executes multiple txs as batch.
    ///                          For Avocado v1.
    ///                          Only callable by allowed broadcasters.
    /// @param batches_          Execute batch txs array, same as inputs for `executeChainAgnosticV1()` just as struct array.
    ///                          If `chainAgnosticHashes` is set (length > 0), then `executeChainAgnosticV1()` is executed,
    ///                          otherwise `executeV1()` is executed with the given array element.
    /// @param continueOnRevert_ flag to signal if one `ExecuteBatchParams` in `batches_` fails, should the rest of them
    ///                          still continue to be executed.
    function executeBatchV1(
        ExecuteBatchParams[] calldata batches_,
        bool continueOnRevert_
    ) external payable onlyBroadcaster {
        uint256 length_ = batches_.length;

        if (length_ < 2) {
            revert AvoForwarder__InvalidParams();
        }

        bool success_;
        for (uint256 i; i < length_; ) {
            if (batches_[i].chainAgnosticHashes.length > 0) {
                success_ = _executeChainAgnosticV1(
                    batches_[i].from,
                    batches_[i].index,
                    batches_[i].params,
                    batches_[i].signaturesParams,
                    batches_[i].chainAgnosticHashes
                );
            } else {
                success_ = _executeV1(
                    batches_[i].from,
                    batches_[i].index,
                    batches_[i].params.params,
                    batches_[i].params.forwardParams,
                    batches_[i].signaturesParams
                );
            }

            if (!success_ && !continueOnRevert_) {
                break;
            }

            unchecked {
                ++i;
            }
        }
    }
}

abstract contract AvoForwarderSimulateV1 is AvoForwarderCore {
    uint256 internal constant SIMULATE_WASTE_GAS_MARGIN = 10; // 10% added in used gas for simulations

    // @dev helper struct to work around Stack too deep Errors
    struct SimulationVars {
        IAvocadoMultisigV1 avocadoMultisig;
        uint256 initialGas;
    }

    /// @dev see `simulateV1()`. Reverts on `success_` = false for accurate .estimateGas() usage.
    ///                          Helpful to estimate gas for an Avocado tx. Note: resulting gas usage will usually be
    ///                          with at least ~10k gas buffer compared to actual execution.
    ///                          For Avocado v1.
    ///                          Deploys the Avocado smart wallet if necessary.
    /// @dev  Expected use with `.estimateGas()`. User signed `CastForwardParams.gas` should be set to the estimated
    ///       amount minus gas used in AvoForwarder (until AvocadoMultisig logic where the gas param is validated).
    function estimateV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastParams calldata params_,
        IAvocadoMultisigV1.CastForwardParams calldata forwardParams_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_
    ) external payable {
        (, , , bool success_, string memory revertReason_) = simulateV1(
            from_,
            index_,
            params_,
            forwardParams_,
            signaturesParams_
        );

        if (!success_) {
            revert(revertReason_);
        }
    }

    /// @notice                  Simulates a `executeV1()` tx, callable only by msg.sender = dead address
    ///                          (0x000000000000000000000000000000000000dEaD). Useful to determine success / error
    ///                          and other return values of `executeV1()` with a `.callstatic`.
    ///                          For Avocado v1.
    /// @dev                      - set `signaturesParams_` to empty to automatically simulate with required signers length.
    ///                           - if `signaturesParams_` first element signature is not set, or if first signer is set to
    ///                             0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, then gas usage burn is simulated
    ///                             for verify signature functionality. DO NOT set signature to non-empty for subsequent
    ///                             elements then; set all signatures to empty!
    ///                           - if `signaturesParams_` is set normally, signatures are verified as in actual execute
    ///                           - buffer amounts for mock smart contract signers signature verification must be added
    ///                             off-chain as this varies on a case per case basis.
    /// @param from_             AvocadoMultisig owner
    /// @param index_            index number of Avocado for `owner_` EOA
    /// @param params_           Cast params such as id, avoNonce and actions to execute
    /// @param forwardParams_    Cast params related to validity of forwarding as instructed and signed
    /// @param signaturesParams_ SignatureParams structs array for signature and signer:
    ///                          - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                            For smart contract signatures it must fulfill the requirements for the relevant
    ///                            smart contract `.isValidSignature()` EIP1271 logic
    ///                          - signer: address of the signature signer.
    ///                            Must match the actual signature signer or refer to the smart contract
    ///                            that must be an allowed signer and validates signature via EIP1271
    /// @return castGasUsed_        amount of gas used for executing `cast`
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the contract if already deployed)
    /// @return isDeployed_         boolean flag indicating if Avocado is already deployed
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    /// @return revertReason_       revert reason original error in default format "<action_index>_error"
    function simulateV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastParams calldata params_,
        IAvocadoMultisigV1.CastForwardParams calldata forwardParams_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_
    )
        public
        payable
        returns (
            uint256 castGasUsed_,
            uint256 deploymentGasUsed_,
            bool isDeployed_,
            bool success_,
            string memory revertReason_
        )
    {
        SimulationVars memory vars_; 

        vars_.initialGas = gasleft();

        (vars_.avocadoMultisig, deploymentGasUsed_, isDeployed_) = _getSimulateDeployedAvocado(from_, index_);

        {
            uint256 gasSnapshotBefore_;
            bytes32 avoVersion_ = keccak256(bytes(vars_.avocadoMultisig.DOMAIN_SEPARATOR_VERSION()));
            if (avoVersion_ == keccak256(bytes("1.0.0")) || avoVersion_ == keccak256(bytes("1.0.1"))) {
                gasSnapshotBefore_ = gasleft();
                (success_, revertReason_) = vars_.avocadoMultisig.cast{ value: forwardParams_.value,
                // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
                // will be kept back or 1/64th according to EIP150 (whichever is bigger).
                gas: gasleft() - _dynamicReserveGas(params_.metadata.length)
             }(
                    params_,
                    forwardParams_,
                    signaturesParams_
                );
            } else {
                gasSnapshotBefore_ = gasleft();
                (success_, revertReason_) = vars_.avocadoMultisig.simulateCast{ value: forwardParams_.value, 
                    // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
                    // will be kept back or 1/64th according to EIP150 (whichever is bigger).
                    gas: gasleft() - _dynamicReserveGas(params_.metadata.length) }(
                    params_,
                    forwardParams_,
                    signaturesParams_
                );
            }
            castGasUsed_ = gasSnapshotBefore_ - gasleft();
        }

        if (success_) {
            emit Executed(from_, index_, address(vars_.avocadoMultisig), params_.source, params_.metadata);
        } else {
            emit ExecuteFailed(
                from_,
                index_,
                address(vars_.avocadoMultisig),
                params_.source,
                params_.metadata,
                revertReason_
            );
        }

        _wasteGas(((vars_.initialGas - gasleft()) * SIMULATE_WASTE_GAS_MARGIN) / 100); // e.g. 10% of used gas
    }

    /// @dev see `simulateChainAgnosticV1()`. Reverts on `success_` = false for accurate .estimateGas() usage.
    ///                          Helpful to estimate gas for an Avocado tx. Note: resulting gas usage will usually be
    ///                          with at least ~10k gas buffer compared to actual execution.
    ///                          For Avocado v1.
    ///                          Deploys the Avocado smart wallet if necessary.
    /// @dev  Expected use with `.estimateGas()`. User signed `CastForwardParams.gas` should be set to the estimated
    ///       amount minus gas used in AvoForwarder (until AvocadoMultisig logic where the gas param is validated).
    function estimateChainAgnosticV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastChainAgnosticParams calldata params_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_,
        IAvocadoMultisigV1.ChainAgnosticHash[] calldata chainAgnosticHashes_
    ) external payable {
        (, , , bool success_, string memory revertReason_) = simulateChainAgnosticV1(
            from_,
            index_,
            params_,
            signaturesParams_,
            chainAgnosticHashes_
        );

        if (!success_) {
            revert(revertReason_);
        }
    }

    /// @notice                   Simulates a `executeChainAgnosticV1()` tx, callable only by msg.sender = dead address
    ///                           (0x000000000000000000000000000000000000dEaD). Useful to determine success / error
    ///                           and other return values of `executeV1()` with a `.callstatic`.
    ///                           For Avocado v1.
    ///                           Deploys the Avocado smart wallet if necessary.
    /// @dev                      - set `signaturesParams_` to empty to automatically simulate with required signers length.
    ///                           - if `signaturesParams_` first element signature is not set, or if first signer is set to
    ///                             0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF, then gas usage burn is simulated
    ///                             for verify signature functionality. DO NOT set signature to non-empty for subsequent
    ///                             elements then; set all signatures to empty!
    ///                           - if `signaturesParams_` is set normally, signatures are verified as in actual execute
    ///                           - buffer amounts for mock smart contract signers signature verification must be added
    ///                             off-chain as this varies on a case per case basis.
    /// @param from_                Avocado owner
    /// @param index_               index number of Avocado for `owner_` EOA
    /// @param params_              Chain agnostic params containing CastParams, ForwardParams and chain id.
    ///                             Note chain id must match block.chainid.
    /// @param signaturesParams_    SignatureParams structs array for signature and signer:
    ///                             - signature: the EIP712 signature, 65 bytes ECDSA signature for a default EOA.
    ///                               For smart contract signatures it must fulfill the requirements for the relevant
    ///                               smart contract `.isValidSignature()` EIP1271 logic
    ///                             - signer: address of the signature signer.
    ///                               Must match the actual signature signer or refer to the smart contract
    ///                               that must be an allowed signer and validates signature via EIP1271
    /// @param chainAgnosticHashes_ hashes struct for each original `CastChainAgnosticParams` struct as used when signing the
    ///                             txs to be executed. Result of `.getChainAgnosticHashes()`.
    /// @return castGasUsed_        amount of gas used for executing `cast`
    /// @return deploymentGasUsed_  amount of gas used for deployment (or for getting the contract if already deployed)
    /// @return isDeployed_         boolean flag indicating if Avocado is already deployed
    /// @return success_            boolean flag indicating whether executing actions reverts or not
    /// @return revertReason_       revert reason original error in default format "<action_index>_error"
    function simulateChainAgnosticV1(
        address from_,
        uint32 index_,
        IAvocadoMultisigV1.CastChainAgnosticParams calldata params_,
        IAvocadoMultisigV1.SignatureParams[] calldata signaturesParams_,
        IAvocadoMultisigV1.ChainAgnosticHash[] calldata chainAgnosticHashes_
    )
        public
        payable
        returns (
            uint256 castGasUsed_,
            uint256 deploymentGasUsed_,
            bool isDeployed_,
            bool success_,
            string memory revertReason_
        )
    {
        SimulationVars memory vars_; 

        vars_.initialGas = gasleft();

        (vars_.avocadoMultisig, deploymentGasUsed_, isDeployed_) = _getSimulateDeployedAvocado(from_, index_);

        {
            uint256 gasSnapshotBefore_ = gasleft();
            (success_, revertReason_) = vars_.avocadoMultisig.simulateCastChainAgnostic{
                value: params_.forwardParams.value,
                // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
                // will be kept back or 1/64th according to EIP150 (whichever is bigger).
                gas: gasleft() - _dynamicReserveGas(params_.params.metadata.length)
            }(params_, signaturesParams_, chainAgnosticHashes_);
            castGasUsed_ = gasSnapshotBefore_ - gasleft();
        }

        if (success_) {
            emit Executed(from_, index_, address(vars_.avocadoMultisig), params_.params.source, params_.params.metadata);
        } else {
            emit ExecuteFailed(
                from_,
                index_,
                address(vars_.avocadoMultisig),
                params_.params.source,
                params_.params.metadata,
                revertReason_
            );
        }

        _wasteGas(((vars_.initialGas - gasleft()) * SIMULATE_WASTE_GAS_MARGIN) / 100); // e.g. 10% of used gas
    }

    /// @notice                  Simulates a `executeBatchV1()` tx, callable only by msg.sender = dead address
    ///                          (0x000000000000000000000000000000000000dEaD)
    ///                          Helpful to estimate gas for an Avocado tx. Note: resulting gas usage will usually be
    ///                          with at least ~10k gas buffer compared to actual execution.
    ///                          For Avocado v1.
    ///                          Deploys the Avocado smart wallet if necessary.
    /// @dev  Expected use with `.estimateGas()`.
    ///       Best to combine with a `.callstatic` to determine success / error and other return values of `executeV1()`.
    ///       For indidividual measurements of each `ExecuteBatchParams` execute the respective simulate() single method for it.
    /// @param batches_          Execute batch txs array, same as inputs for `simulateChainAgnosticV1()` just as struct array.
    /// @param continueOnRevert_ flag to signal if one `ExecuteBatchParams` in `batches_` fails, should the rest of them
    ///                          still continue to be executed.
    function simulateBatchV1(ExecuteBatchParams[] calldata batches_, bool continueOnRevert_) external payable returns(SimulateBatchResult[] memory results_){
        uint256 initialGas_ = gasleft();

        uint256 length_ = batches_.length;

        if (length_ < 2) {
            revert AvoForwarder__InvalidParams();
        }

        results_ = new SimulateBatchResult[](length_);
        IAvocadoMultisigV1 avocadoMultisig_;
        uint256 gasSnapshotBefore_;
        for (uint256 i; i < length_; ) {

             (avocadoMultisig_ , , ) = _getSimulateDeployedAvocado(batches_[i].from, batches_[i].index);

             gasSnapshotBefore_ = gasleft();
            if (batches_[i].chainAgnosticHashes.length > 0) {
                (results_[i].success, results_[i].revertReason) = avocadoMultisig_.simulateCastChainAgnostic{
                    value: batches_[i].params.forwardParams.value,
                    // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
                    // will be kept back or 1/64th according to EIP150 (whichever is bigger).
                    gas: gasleft() - _dynamicReserveGas(batches_[i].params.params.metadata.length)
                }(batches_[i].params, batches_[i].signaturesParams, batches_[i].chainAgnosticHashes);
            } else {
                (results_[i].success, results_[i].revertReason) = avocadoMultisig_.simulateCast{
                    value: batches_[i].params.forwardParams.value,
                    // keep back at least enough gas to ensure we can emit events logic below. either calculated reserve gas amount
                    // will be kept back or 1/64th according to EIP150 (whichever is bigger).
                    gas: gasleft() - _dynamicReserveGas(batches_[i].params.params.metadata.length)
                }(batches_[i].params.params, batches_[i].params.forwardParams, batches_[i].signaturesParams);
            }
            results_[i].castGasUsed = gasSnapshotBefore_ - gasleft();

            if (results_[i].success) {
                emit Executed(
                    batches_[i].from,
                    batches_[i].index,
                    address(avocadoMultisig_),
                    batches_[i].params.params.source,
                    batches_[i].params.params.metadata
                );
            } else {
                emit ExecuteFailed(
                    batches_[i].from,
                    batches_[i].index,
                    address(avocadoMultisig_),
                    batches_[i].params.params.source,
                    batches_[i].params.params.metadata,
                    results_[i].revertReason
                );
            }

            if (!results_[i].success && !continueOnRevert_) {
                break;
            }

            unchecked {
                ++i;
            }
        }

        _wasteGas(((initialGas_ - gasleft()) * SIMULATE_WASTE_GAS_MARGIN) / 100); // e.g. 10% of used gas
    }

    /// @dev uses up `wasteGasAmount_` of gas
    function _wasteGas(uint256 wasteGasAmount_) internal view {
        uint256 gasLeft_ = gasleft();
        uint256 wasteGasCounter_;
        while (gasLeft_ - gasleft() < wasteGasAmount_) wasteGasCounter_++;
    }
}

abstract contract AvoForwarderOwnerActions is AvoForwarderCore {
    /// @dev modifier checks if `msg.sender` is either owner or allowed auth, reverts if not.
    modifier onlyAuthOrOwner() {
        if (!(msg.sender == owner() || _auths[msg.sender] == 1)) {
            revert AvoForwarder__Unauthorized();
        }

        _;
    }

    /// @notice updates allowed status for broadcasters based on `broadcastersStatus_` and emits `BroadcastersUpdated`.
    /// Executable by allowed auths or owner only.
    function updateBroadcasters(AddressBool[] calldata broadcastersStatus_) external onlyAuthOrOwner {
        uint256 length_ = broadcastersStatus_.length;
        for (uint256 i; i < length_; ) {
            if (broadcastersStatus_[i].addr == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            _broadcasters[broadcastersStatus_[i].addr] = broadcastersStatus_[i].value ? 1 : 0;

            emit BroadcasterUpdated(broadcastersStatus_[i].addr, broadcastersStatus_[i].value);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice updates allowed status for a auths based on `authsStatus_` and emits `AuthsUpdated`.
    /// Executable by allowed auths or owner only (auths can only remove themselves).
    function updateAuths(AddressBool[] calldata authsStatus_) external onlyAuthOrOwner {
        uint256 length_ = authsStatus_.length;

        bool isMsgSenderOwner = msg.sender == owner();

        for (uint256 i; i < length_; ) {
            if (authsStatus_[i].addr == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            uint256 setStatus_ = authsStatus_[i].value ? 1 : 0;

            // if `msg.sender` is auth, then operation must be remove and address to be removed must be auth itself
            if (!(isMsgSenderOwner || (setStatus_ == 0 && msg.sender == authsStatus_[i].addr))) {
                revert AvoForwarder__Unauthorized();
            }

            _auths[authsStatus_[i].addr] = setStatus_;

            emit AuthUpdated(authsStatus_[i].addr, authsStatus_[i].value);

            unchecked {
                ++i;
            }
        }
    }
}

contract AvoForwarder is
    AvoForwarderCore,
    AvoForwarderViews,
    AvoForwarderViewsAvocado,
    AvoForwarderV1,
    AvoForwarderChainAgnosticV1,
    AvoForwarderBatchV1,
    AvoForwarderSimulateV1,
    AvoForwarderOwnerActions
{
    /// @notice constructor sets the immutable `avoFactory` (proxy) address and cached bytecodes derived from it
    constructor(IAvoFactory avoFactory_) AvoForwarderCore(avoFactory_) {}

    /// @notice initializes the contract, setting `owner_` and initial `allowedBroadcasters_`
    /// @param owner_                address of owner_ allowed to executed auth limited methods
    /// @param allowedBroadcasters_  initial list of allowed broadcasters to be enabled right away
    function initialize(
        address owner_,
        address[] calldata allowedBroadcasters_
    ) public validAddress(owner_) initializer {
        _transferOwnership(owner_);

        // set initial allowed broadcasters
        uint256 length_ = allowedBroadcasters_.length;
        for (uint256 i; i < length_; ) {
            if (allowedBroadcasters_[i] == address(0)) {
                revert AvoForwarder__InvalidParams();
            }

            _broadcasters[allowedBroadcasters_[i]] = 1;

            emit BroadcasterUpdated(allowedBroadcasters_[i], true);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice override renounce ownership as it could leave the contract in an unwanted state if called by mistake.
    function renounceOwnership() public view override onlyOwner {
        revert AvoForwarder__Unsupported();
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

    /// @notice returns the byteCode for the Avocado contract used for Create2 address computation
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
        /// @param feeCollector address that the fee should be paid to
        address payable feeCollector;
        /// @param mode current fee mode: 0 = percentage fee (gas cost markup); 1 = static fee (better for L2)
        uint8 mode;
        /// @param fee current fee amount:
        /// - for mode percentage: fee in 1e6 percentage (1e8 = 100%, 1e6 = 1%)
        /// - for static mode: absolute amount in native gas token to charge
        ///                    (max value 30_9485_009,821345068724781055 in 1e18)
        uint88 fee;
    }

    /// @notice calculates the `feeAmount_` for an Avocado (`msg.sender`) transaction `gasUsed_` based on
    ///         fee configuration present on the contract
    /// @param  gasUsed_       amount of gas used, required if mode is percentage. not used if mode is static fee.
    /// @return feeAmount_    calculate fee amount to be paid
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