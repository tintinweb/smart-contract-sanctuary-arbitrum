// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
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
    function _remove(Set storage set, bytes32 value) private returns (bool) {
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
                bytes32 lastValue = set._values[lastIndex];

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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
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
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface AggregatorInterface {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    function getPrice(
        uint,
        OrderType,
        uint,
        bytes[] calldata
    ) external returns (uint);

    function tokenPriceUSDT() external view returns (uint);

    function pairMinOpenLimitSlippageP(uint) external view returns (uint);

    function closeFeeP(uint) external view returns (uint);

    function linkFee(uint, uint) external view returns (uint);

    function openFeeP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function pairsCount() external view returns (uint);

    function tokenUSDTReservesLp() external view returns (uint, uint);

    function referralP(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairInfoInterface {
    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (USDT)
    ) external returns (uint); // 1e18 (USDT)

    function getAccFundingFeesLong(uint pairIndex) external view returns (int);

    function getAccFundingFeesShort(uint pairIndex) external view returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PausableInterface {
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PoolInterface {
    function increaseAccTokens(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/AggregatorInterface.sol";
import "./interfaces/PoolInterface.sol";
import "./interfaces/PausableInterface.sol";
import "./interfaces/PairInfoInterface.sol";

contract TradingStorage is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.UintSet;

    // Constants
    uint public PRECISION;
    address public USDT;

    // Contracts (updatable)
    AggregatorInterface public priceAggregator;
    PairInfoInterface public pairInfos;
    PoolInterface public pool;
    address public trading;
    address public callbacks;

    address public vault;
    // Trading variables
    uint public maxTradesPerPair;
    uint public maxPendingMarketOrders;
    uint[5] public spreadReductionsP; // %

    // Gov (updatable)
    address public gov;
    address public pendingGov;

    mapping(uint256 => address) public keeperForOrder;

    // Enums
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    
    // Events
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // usdtDecimals
        uint positionSizeUSDT; // usdtDecimals
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl;
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUSDT; // PRECISION
        uint openInterestUSDT; // usdtDecimals
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // usdtDecimals
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId;
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;
    }

    struct PendingLimitOrder {
        address limitHolder;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    // Trades mappings
    mapping(address => mapping(uint => mapping(uint => Trade)))
        public openTrades;
    mapping(address => mapping(uint => mapping(uint => bool)))
        public tempTradeStatus;
    mapping(address => mapping(uint => mapping(uint => uint256)))
        public openTimestamp;
    mapping(address => mapping(uint => mapping(uint => int256)))
        public accPerOiOpen;
    mapping(address => mapping(uint => mapping(uint => TradeInfo)))
        public openTradesInfo;
    mapping(address => mapping(uint => uint)) public openTradesCount;
    mapping(uint => PendingLimitOrder) public reqID_pendingLimitOrder;

    // Limit orders mappings
    mapping(address => mapping(uint => mapping(uint => uint)))
        public openLimitOrderIds;
    mapping(address => mapping(uint => uint)) public openLimitOrdersCount;
    OpenLimitOrder[] public openLimitOrders;

    // Pending orders mappings
    mapping(uint => PendingMarketOrder) public reqID_pendingMarketOrder;
    mapping(address => EnumerableSet.UintSet) private pendingOrderIds;
    mapping(address => mapping(uint => uint)) public pendingMarketOpenCount;
    mapping(address => mapping(uint => uint)) public pendingMarketCloseCount;

    // List of open trades & limit orders
    mapping(uint => address[]) public pairTraders;
    mapping(address => mapping(uint => uint)) public pairTradersId;

    // Current and max open interests for each pair
    mapping(uint => uint[5]) public openInterestUSDT; // usdtDecimals [long,short,max OI,max netOI, min netOI]
    

    // Restrictions & Timelocks
    mapping(uint => uint) public tradesPerBlock;

    // List of allowed contracts => can update storage + mint/burn tokens
    mapping(address => bool) public isTradingContract;

    // Events
    event SupportedTokenAdded(address a);
    event TradingContractAdded(address a);
    event TradingContractRemoved(address a);
    event AddressUpdated(string name, address a);
    event NumberUpdated(string name, uint value);
    event NumberUpdatedPair(string name, uint pairIndex, uint value);
    event SpreadReductionsUpdated(uint[5]);

    function initialize(
        address _USDT
        ) public initializer {
        gov = msg.sender;
        maxTradesPerPair = 3;
        maxPendingMarketOrders = 5;
        spreadReductionsP = [15, 20, 25, 30, 35]; // %
        PRECISION = 1e10;
        require(address(_USDT) != address(0), "ADDRESS_0");
        USDT = _USDT;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov, "Not gov");
        _;
    }
    modifier onlyTrading() {
        require(isTradingContract[msg.sender], "Not allowed");
        _;
    }

    // Set addresses
    function setPendingGovFund(address _gov) external onlyGov {
        require(_gov != address(0), "ADDRESS_0");
        pendingGov = _gov;
    }

    function confirmGovFund() external onlyGov {
        gov = pendingGov;
        emit AddressUpdated("govFund", gov);
    }

    // Trading + callbacks contracts
    function addTradingContract(address _trading) external onlyGov {
        require(_trading != address(0),"ADDRESS_0");
        isTradingContract[_trading] = true;
        emit TradingContractAdded(_trading);
    }

    function removeTradingContract(address _trading) external onlyGov {
        require(_trading != address(0),"ADDRESS_0");
        require(isTradingContract[_trading],"Not a trading contract");
        isTradingContract[_trading] = false;
        emit TradingContractRemoved(_trading);
    }

    function setPriceAggregator(address _aggregator) external onlyGov {
        require(_aggregator != address(0),"ADDRESS_0");
        priceAggregator = AggregatorInterface(_aggregator);
        emit AddressUpdated("priceAggregator", _aggregator);
    }

    function setPairInfos(PairInfoInterface _pairInfos) external onlyGov {
        require(address(_pairInfos) != address(0),"ADDRESS_0");
        pairInfos = _pairInfos;
        emit AddressUpdated("_pairInfos", address(_pairInfos));
    }

    function setPool(address _pool) external onlyGov {
        require(_pool != address(0),"ADDRESS_0");
        pool = PoolInterface(_pool);
        IERC20Upgradeable(USDT).approve(address(pool), type(uint256).max);
        emit AddressUpdated("pool", _pool);
    }

    function setVault(address _vault) external onlyGov {
        require(_vault != address(0),"ADDRESS_0");
        vault = _vault;
        emit AddressUpdated("vault", _vault);
    }

    function setTrading(address _trading) external onlyGov {
        require(_trading != address(0),"ADDRESS_0");
        trading = _trading;
        emit AddressUpdated("trading", _trading);
    }

    function setCallbacks(address _callbacks) external onlyGov {
        require(_callbacks != address(0),"ADDRESS_0");
        callbacks = _callbacks;
        emit AddressUpdated("callbacks", _callbacks);
    }

    function setMaxTradesPerPair(uint _maxTradesPerPair) external onlyGov {
        require(_maxTradesPerPair > 0,"MUST_ABOVE_0");
        maxTradesPerPair = _maxTradesPerPair;
        emit NumberUpdated("maxTradesPerPair", _maxTradesPerPair);
    }

    function setMaxPendingMarketOrders(
        uint _maxPendingMarketOrders
    ) external onlyGov {
        require(_maxPendingMarketOrders > 0,"MAX_PENDING_MARKET_ORDERS");
        maxPendingMarketOrders = _maxPendingMarketOrders;
        emit NumberUpdated("maxPendingMarketOrders", _maxPendingMarketOrders);
    }

    function setSpreadReductionsP(uint[5] calldata _r) external onlyGov {
        require(
            _r[0] > 0 &&
                _r[1] > _r[0] &&
                _r[2] > _r[1] &&
                _r[3] > _r[2] &&
                _r[4] > _r[3]
        ,"WRONG_SPREAD");
        spreadReductionsP = _r;
        emit SpreadReductionsUpdated(_r);
    }

    function setMaxOpenInterestUSDT(
        uint _pairIndex,
        uint _newMaxOpenInterest,
        uint _newMaxNetOpenInterest,
        uint _newMinNetOpenInterest
    ) external onlyGov {
        // Can set max open interest to 0 to pause trading on this pair only
        openInterestUSDT[_pairIndex][2] = _newMaxOpenInterest;
        openInterestUSDT[_pairIndex][3] = _newMaxNetOpenInterest;
        openInterestUSDT[_pairIndex][4] = _newMinNetOpenInterest;
        emit NumberUpdatedPair(
            "maxOpenInterestUSDT",
            _pairIndex,
            _newMaxOpenInterest
        );
    }

    function storePendingLimitOrder(
        PendingLimitOrder memory _limitOrder,
        uint _orderId
    ) external onlyTrading {
        reqID_pendingLimitOrder[_orderId] = _limitOrder;
        keeperForOrder[_orderId] = _limitOrder.limitHolder;
    }

    function unregisterPendingLimitOrder(uint _order) external onlyTrading {
        delete reqID_pendingLimitOrder[_order];
        keeperForOrder[_order] = address(0);
    }

    // Manage stored trades
    function storeTrade(
        Trade memory _trade,
        TradeInfo memory _tradeInfo
    ) external onlyTrading {
        require(_trade.index == firstEmptyTradeIndex(_trade.trader, _trade.pairIndex), "Wrong index");
        openTrades[_trade.trader][_trade.pairIndex][_trade.index] = _trade;
        openTimestamp[_trade.trader][_trade.pairIndex][_trade.index] = block.timestamp;
        if (_trade.buy) {
            accPerOiOpen[_trade.trader][_trade.pairIndex][_trade.index] = pairInfos.getAccFundingFeesLong(_trade.pairIndex);
        } else {
            accPerOiOpen[_trade.trader][_trade.pairIndex][_trade.index] = pairInfos.getAccFundingFeesShort(_trade.pairIndex);
        }
        openTradesCount[_trade.trader][_trade.pairIndex]++;
        tradesPerBlock[block.number]++;

        if (openTradesCount[_trade.trader][_trade.pairIndex] == 1) {
            pairTradersId[_trade.trader][_trade.pairIndex] = pairTraders[
                _trade.pairIndex
            ].length;
            pairTraders[_trade.pairIndex].push(_trade.trader);
        }

        _tradeInfo.beingMarketClosed = false;
        openTradesInfo[_trade.trader][_trade.pairIndex][
            _trade.index
        ] = _tradeInfo;

        updateOpenInterestUSDT(
            _trade.pairIndex,
            _tradeInfo.openInterestUSDT,
            true,
            _trade.buy
        );

        //Pre registering value to false to get a true at close
        tempTradeStatus[_trade.trader][_trade.pairIndex][_trade.index] = false;
    }

    function unregisterTrade(
        address trader,
        uint pairIndex,
        uint index
    ) external onlyTrading {
        Trade storage t = openTrades[trader][pairIndex][index];
        TradeInfo storage i = openTradesInfo[trader][pairIndex][index];
        if (t.leverage == 0) {
            return;
        }

        updateOpenInterestUSDT(pairIndex, i.openInterestUSDT, false, t.buy);

        if (openTradesCount[trader][pairIndex] == 1) {
            uint _pairTradersId = pairTradersId[trader][pairIndex];
            address[] storage p = pairTraders[pairIndex];

            p[_pairTradersId] = p[p.length - 1];
            pairTradersId[p[_pairTradersId]][pairIndex] = _pairTradersId;

            delete pairTradersId[trader][pairIndex];
            p.pop();
        }
        uint256 openTime = openTimestamp[trader][pairIndex][index];
        delete openTrades[trader][pairIndex][index];
        delete openTimestamp[trader][pairIndex][index];
        delete openTradesInfo[trader][pairIndex][index];
        delete accPerOiOpen[t.trader][t.pairIndex][t.index];
        tempTradeStatus[trader][pairIndex][index] = true;

        openTradesCount[trader][pairIndex]--;
        tradesPerBlock[block.number]++;
    }

    // Manage pending market orders
    function storePendingMarketOrder(
        PendingMarketOrder memory _order,
        uint _id,
        bool _open
    ) external onlyTrading {
        pendingOrderIds[_order.trade.trader].add(_id);
        reqID_pendingMarketOrder[_id] = _order;
        reqID_pendingMarketOrder[_id].block = block.number;

        if (_open) {
            pendingMarketOpenCount[_order.trade.trader][
                _order.trade.pairIndex
            ]++;
        } else {
            pendingMarketCloseCount[_order.trade.trader][
                _order.trade.pairIndex
            ]++;
            openTradesInfo[_order.trade.trader][_order.trade.pairIndex][
                _order.trade.index
            ].beingMarketClosed = true;
        }
    }

    function unregisterPendingMarketOrder(
        uint _id,
        bool _open
    ) external onlyTrading {
        PendingMarketOrder memory _order = reqID_pendingMarketOrder[_id];
        bool removed = pendingOrderIds[_order.trade.trader].remove(_id);

        if (removed) {
            if (_open) {
                pendingMarketOpenCount[_order.trade.trader][
                    _order.trade.pairIndex
                ]--;
            } else {
                pendingMarketCloseCount[_order.trade.trader][
                    _order.trade.pairIndex
                ]--;
                openTradesInfo[_order.trade.trader][_order.trade.pairIndex][
                    _order.trade.index
                ].beingMarketClosed = false;
            }
            delete reqID_pendingMarketOrder[_id];
        }
    }

    // Manage open interest
    function updateOpenInterestUSDT(
        uint _pairIndex,
        uint _leveragedPosUSDT,
        bool _open,
        bool _long
    ) private {
        uint index = _long ? 0 : 1;
        uint[5] storage o = openInterestUSDT[_pairIndex];
        o[index] = _open
            ? o[index] + _leveragedPosUSDT
            : o[index] - _leveragedPosUSDT;
    }

    // Manage open limit orders
    function storeOpenLimitOrder(OpenLimitOrder memory o) external onlyTrading {
        o.index = firstEmptyOpenLimitIndex(o.trader, o.pairIndex);
        o.block = block.number;
        openLimitOrders.push(o);
        openLimitOrderIds[o.trader][o.pairIndex][o.index] =
            openLimitOrders.length -
            1;
        openLimitOrdersCount[o.trader][o.pairIndex]++;
    }

    function updateOpenLimitOrder(
        OpenLimitOrder calldata _o
    ) external onlyTrading {
        if (!hasOpenLimitOrder(_o.trader, _o.pairIndex, _o.index)) {
            return;
        }
        OpenLimitOrder storage o = openLimitOrders[
            openLimitOrderIds[_o.trader][_o.pairIndex][_o.index]
        ];
        o.positionSize = _o.positionSize;
        o.buy = _o.buy;
        o.leverage = _o.leverage;
        o.tp = _o.tp;
        o.sl = _o.sl;
        o.minPrice = _o.minPrice;
        o.maxPrice = _o.maxPrice;
        o.block = block.number;
    }

    function unregisterOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external onlyTrading {
        if (!hasOpenLimitOrder(_trader, _pairIndex, _index)) {
            return;
        }

        // Copy last order to deleted order => update id of this limit order
        uint id = openLimitOrderIds[_trader][_pairIndex][_index];
        openLimitOrders[id] = openLimitOrders[openLimitOrders.length - 1];
        openLimitOrderIds[openLimitOrders[id].trader][
            openLimitOrders[id].pairIndex
        ][openLimitOrders[id].index] = id;

        // Remove
        delete openLimitOrderIds[_trader][_pairIndex][_index];
        openLimitOrders.pop();

        openLimitOrdersCount[_trader][_pairIndex]--;
    }

    // Manage open trade
    function updateSl(
        address _trader,
        uint _pairIndex,
        uint _index,
        uint _newSl
    ) external onlyTrading {
        Trade storage t = openTrades[_trader][_pairIndex][_index];
        TradeInfo storage i = openTradesInfo[_trader][_pairIndex][_index];
        if (t.leverage == 0) {
            return;
        }
        t.sl = _newSl;
        i.slLastUpdated = block.number;
    }

    function updateTp(
        address _trader,
        uint _pairIndex,
        uint _index,
        uint _newTp
    ) external onlyTrading {
        Trade storage t = openTrades[_trader][_pairIndex][_index];
        TradeInfo storage i = openTradesInfo[_trader][_pairIndex][_index];
        if (t.leverage == 0) {
            return;
        }
        t.tp = _newTp;
        i.tpLastUpdated = block.number;
    }

    function updateTrade(Trade memory _t) external onlyTrading {
        // useful when partial adding/closing
        Trade storage t = openTrades[_t.trader][_t.pairIndex][_t.index];
        if (t.leverage == 0) {
            return;
        }
        t.initialPosToken = _t.initialPosToken;
        t.positionSizeUSDT = _t.positionSizeUSDT;
        t.openPrice = _t.openPrice;
        t.leverage = _t.leverage;
    }

    // Manage rewards
    function distributeLpRewards(uint _amount) external onlyTrading {
        pool.increaseAccTokens(_amount);
    }

    function transferUSDT(
        address _from,
        address _to,
        uint _amount
    ) external onlyTrading {
        if (_from == address(this)) {
            IERC20Upgradeable(USDT).safeTransfer(_to, _amount);
            
        } else {
            IERC20Upgradeable(USDT).safeTransferFrom(_from, _to, _amount);
        }
    }

    function getNetOI(uint256 _pairIndex, bool _long) external view returns (uint256) {
        int256 longOI = int256(openInterestUSDT[_pairIndex][0]);
        int256 shortOI = int256(openInterestUSDT[_pairIndex][1]);

        int256 netOI;
        if (_long) {
            netOI = longOI - shortOI;
        } else {
            netOI = shortOI - longOI;
        }
        
        return abs(netOI);
    }

    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    // View utils functions
    function firstEmptyTradeIndex(
        address trader,
        uint pairIndex
    ) public view returns (uint index) {
        bool allOccupied = true;

        for (uint i = 0; i < maxTradesPerPair; i++) {
            if (openTrades[trader][pairIndex][i].leverage == 0) {
                index = i;
                allOccupied = false;
                break;
            }
        }

        require(!allOccupied, "All open limit slots are full");
        return index;
    }

    function firstEmptyOpenLimitIndex(
        address trader,
        uint pairIndex
    ) public view returns (uint index) {
        bool allOccupied = true;
        for (uint i = 0; i < maxTradesPerPair; i++) {
            if (!hasOpenLimitOrder(trader, pairIndex, i)) {
                index = i;
                allOccupied = false;
                break;
            }
        }
        
        require(!allOccupied, "All open limit slots are full");
        return index;
    }

    function hasOpenLimitOrder(
        address trader,
        uint pairIndex,
        uint index
    ) public view returns (bool) {
        if (openLimitOrders.length == 0) {
            return false;
        }
        OpenLimitOrder storage o = openLimitOrders[
            openLimitOrderIds[trader][pairIndex][index]
        ];
        return
            o.trader == trader && o.pairIndex == pairIndex && o.index == index;
    }

    function pairTradersArray(
        uint _pairIndex
    ) external view returns (address[] memory) {
        return pairTraders[_pairIndex];
    }


    function getPendingOrderIds(
        address _trader
    ) external view returns (uint[] memory) {
        EnumerableSet.UintSet storage idsSet = pendingOrderIds[_trader];
        uint256 length = idsSet.length();
        uint[] memory idsArray = new uint[](length);

        for (uint256 i = 0; i < length; i++) {
            idsArray[i] = idsSet.at(i);
        }

        return idsArray;
    }

    function pendingOrderIdsCount(
        address _trader
    ) external view returns (uint) {
        return pendingOrderIds[_trader].length();
    }

    function getOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external view returns (OpenLimitOrder memory) {
        require(hasOpenLimitOrder(_trader, _pairIndex, _index),"MUST_HAVE_OPEN_LIMIT");
        return openLimitOrders[openLimitOrderIds[_trader][_pairIndex][_index]];
    }

    function getOpenLimitOrders()
        external
        view
        returns (OpenLimitOrder[] memory)
    {
        return openLimitOrders;
    }

    function getSpreadReductionsArray() external view returns (uint[5] memory) {
        return spreadReductionsP;
    }
}