// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity ^0.8.0;

/// @notice Interface for Chainlink Aggregator V3
interface AggregatorV3Interface {
    /// @notice Returns the number of decimals used by the price feed
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// @notice Returns a description of the price feed
    /// @return The description of the price feed
    function description() external view returns (string memory);

    /// @notice Returns the version number of the price feed
    /// @return The version number
    function version() external view returns (uint256);

    /// @notice Returns the latest answer from the price feed
    /// @return The latest answer
    function latestAnswer() external view returns (int256);

    /// @notice Returns the data for the latest round of the price feed
    /// @return roundId The ID of the latest round
    /// @return answer The latest answer
    /// @return startedAt The timestamp when the latest round started
    /// @return updatedAt The timestamp when the latest round was last updated
    /// @return answeredInRound The ID of the round when the latest answer was computed
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @notice Interface for the ERC20 token contract
interface IERC20 is IERC20Upgradeable {
    /// @notice Returns the number of decimals used by the token
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// dev Returns the name of the Wrapped Ether token.
    /// return A string representing the token name.
    function name() external view returns (string memory);

    /// dev Returns the symbol of the Wrapped Ether token.
    /// return A string representing the token symbol.
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Uniswap V3 Router contract
interface IUniswapRouterV3 {
    /// @notice Parameters for single-token exact input swaps
    struct ExactInputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the output tokens
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @notice Parameters for multi-hop exact input swaps
    struct ExactInputParams {
        bytes path; // The path of tokens to swap
        address recipient; // The address to receive the output tokens
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the input tokens
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path; // The path of tokens to swap (reversed)
        address recipient; // The address to receive the input tokens
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

/// @notice Interface for the Uniswap V3 Router contract with deadline support
interface IUniswapRouterV3WithDeadline {
    /// @notice Parameters for single-token exact input swaps

    struct ExactInputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the output tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path; // The path of tokens to swap
        address recipient; // The address to receive the output tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the input tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path; // The path of tokens to swap (reversed)
        address recipient; // The address to receive the input tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Convex Booster contract
interface IConvexBoosterL1 {
    /// @notice Deposits funds into the booster
    /// @param pid The pool ID
    /// @param amount The amount to deposit
    /// @param stake Flag indicating whether to stake the deposited funds
    /// @return True if the deposit was successful
    function deposit(uint256 pid, uint256 amount, bool stake) external returns (bool);

    /// @notice Returns the address of the CVX token
    function minter() external view returns (address);

    /// @notice Earmarks rewards for the specified pool
    /// @param _pid The pool ID
    function earmarkRewards(uint256 _pid) external;

    /// @notice Retrieves information about a pool
    /// @param pid The pool ID
    /// @return lptoken The LP token address
    /// @return token The token address
    /// @return gauge The gauge address
    /// @return crvRewards The CRV rewards address
    /// @return stash The stash address
    /// @return shutdown Flag indicating if the pool is shutdown
    function poolInfo(
        uint256 pid
    )
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );
}

/// @notice Interface for the Convex Booster L2 contract
interface IConvexBoosterL2 {
    /// @notice Deposits funds into the L2 booster
    /// @param _pid The pool ID
    /// @param _amount The amount to deposit
    /// @return True if the deposit was successful
    function deposit(uint256 _pid, uint256 _amount) external returns (bool);

    /// @notice Deposits all available funds into the L2 booster
    /// @param _pid The pool ID
    /// @return True if the deposit was successful
    function depositAll(uint256 _pid) external returns (bool);

    /// @notice Retrieves information about a pool
    /// @param pid The pool ID
    /// @return lptoken The LP token address
    /// @return gauge The gauge address
    /// @return rewards The rewards address
    /// @return shutdown Flag indicating if the pool is shutdown
    /// @return factory The curve factory address used to create the pool
    function poolInfo(
        uint256 pid
    )
        external
        view
        returns (
            address lptoken, //the curve lp token
            address gauge, //the curve gauge
            address rewards, //the main reward/staking contract
            bool shutdown, //is this pool shutdown?
            address factory //a reference to the curve factory used to create this pool (needed for minting crv)
        );
}

interface IConvexRewardPoolL1 {
    /// @notice Retrieves the balance of the specified account
    /// @param account The account address
    /// @return The account balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieves the claimable rewards for the specified account
    /// @param _account The account address
    /// @return the amount representing the claimable rewards
    function earned(address _account) external view returns (uint256);

    /// @dev Calculates the reward in CVX based on the reward of CRV
    /// @dev Used for mock purposes only
    /// @param _crvAmount The amount of CRV amount.
    /// @return returns the amount of cvx rewards to get
    function getCVXAmount(uint256 _crvAmount) external view returns (uint256);

    /// @notice Retrieves the period finish timestamp
    /// @return The period finish timestamp
    function periodFinish() external view returns (uint256);

    /// @notice Claims the available rewards for the caller
    function getReward() external;

    /// @notice Gets the address of the reward token
    function rewardToken() external view returns (address);

    /// @notice Withdraws and unwraps the specified amount of tokens
    /// @param _amount The amount to withdraw and unwrap
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAndUnwrap(uint256 _amount, bool claim) external;

    /// @notice Withdraws all funds and unwraps the tokens
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAllAndUnwrap(bool claim) external;
}

/// @notice Interface for the Convex Reward Pool L2 contract
interface IConvexRewardPoolL2 {
    /// @notice Struct containing information about an earned reward
    struct EarnedData {
        address token;
        uint256 amount;
    }

    /// @notice Retrieves the balance of the specified account
    /// @param account The account address
    /// @return The account balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieves the claimable rewards for the specified account
    /// @param _account The account address
    /// @return claimable An array of EarnedData representing the claimable rewards
    function earned(address _account) external returns (EarnedData[] memory claimable);

    /// @notice Retrieves the period finish timestamp
    /// @return The period finish timestamp
    function periodFinish() external view returns (uint256);

    /// @notice Claims the available rewards for the specified account
    /// @param _account The account address
    function getReward(address _account) external;

    /// @notice Withdraws the specified amount of tokens
    /// @param _amount The amount to withdraw
    /// @param _claim Flag indicating whether to claim rewards
    function withdraw(uint256 _amount, bool _claim) external;

    /// @notice Withdraws all funds
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAll(bool claim) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the CurveSwap contract
interface ICurveSwap {
    /// @notice Retrieves the fee applied by the CurveSwap contract
    /// @return The fee amount
    function fee() external view returns (uint256);

    /// @notice Retrieves the balance of a token at a specific index within the CurveSwap contract
    /// @param index The index of the token
    /// @return The balance of the token
    function balances(uint256 index) external view returns (uint256);

    /// @notice Retrieves the total supply of LP (Liquidity Provider) tokens in the CurveSwap contract
    /// @return The total supply of LP tokens
    function totalSupply() external view returns (uint256);

    /// @notice Retrieves the admin fee applied by the CurveSwap contract
    /// @return The admin fee amount
    function admin_fee() external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to mint or burn for a given token input or output amounts
    /// @param amounts The token input or output amounts
    /// @param is_deposit Boolean indicating if it's a deposit or withdrawal operation
    /// @return The calculated amount of LP tokens
    function calc_token_amount(
        uint256[2] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to mint or burn for a given token input or output amounts
    /// @param amounts The token input or output amounts
    /// @param is_deposit Boolean indicating if it's a deposit or withdrawal operation
    /// @return The calculated amount of LP tokens
    function calc_token_amount(
        uint256[3] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    /// @notice Removes liquidity from the CurveSwap contract
    /// @param _burn_amount The amount of LP tokens to burn
    /// @param _min_amounts The minimum acceptable token amounts to receive
    /// @return The actual amounts received after removing liquidity
    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] memory _min_amounts
    ) external returns (uint256[2] memory);

    /// @notice Removes liquidity from the CurveSwap contract for a single token
    /// @param token_amount The amount of the token to remove
    /// @param i The index of the token in the pool
    /// @param min_amount The minimum acceptable token amount to receive
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    /// @notice Removes liquidity from the CurveSwap contract for a single token
    /// @param token_amount The amount of the token to remove
    /// @param i The index of the token in the pool
    /// @param min_amount The minimum acceptable token amount to receive
    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    /// @notice Calculates the amount of tokens to receive when withdrawing a single token from the CurveSwap contract
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token in the pool
    /// @return The calculated amount of tokens to receive
    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    /// @notice Calculates the amount of tokens to receive when withdrawing a single token from the CurveSwap contract
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token in the pool
    /// @return The calculated amount of tokens to receive
    function calc_withdraw_one_coin(uint256 tokenAmount, uint256 i) external view returns (uint256);

    /// @notice Retrieves the address of a token in the CurveSwap pool by its index
    /// @param arg0 The index of the token in the pool
    /// @return The address of the token
    function coins(uint256 arg0) external view returns (address);

    /// @notice Retrieves the virtual price of the CurveSwap pool
    /// @return The virtual price
    function get_virtual_price() external view returns (uint256);

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract with an option to use underlying tokens
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    /// @param _use_underlying Boolean indicating whether to use underlying tokens
    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) external;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract with an option to use underlying tokens
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    /// @param _use_underlying Boolean indicating whether to use underlying tokens
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[6] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[6] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Exchanges tokens on the CurveSwap contract
    /// @param i The index of the input token in the pool
    /// @param j The index of the output token in the pool
    /// @param dx The amount of the input token to exchange
    /// @param min_dy The minimum acceptable amount of the output token to receive
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Gauge Factory
interface IGaugeFactory {
    /// @notice Mints a gauge token
    /// @param _gauge The address of the gauge to be minted
    function mint(address _gauge) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @dev Interface for managing the super admin role.
interface ISuperAdmin {
    /// @dev Emitted when the super admin role is transferred.
    /// @param oldAdmin The address of the old super admin.
    /// @param newAdmin The address of the new super admin.
    event SuperAdminTransfer(address oldAdmin, address newAdmin);

    /// @notice Returns the address of the super admin.
    /// @return The address of the super admin.
    function superAdmin() external view returns (address);

    /// @notice Checks if the caller is a valid super admin.
    /// @param caller The address to check.
    function isValidSuperAdmin(address caller) external view;

    /// @notice Transfers the super admin role to a new address.
    /// @param _superAdmin The address of the new super admin.
    function transferSuperAdmin(address _superAdmin) external;
}

/// @dev Interface for managing admin roles.
interface IAdminStructure is ISuperAdmin {
    /// @dev Emitted when an admin is added.
    /// @param admin The address of the added admin.
    event AddedAdmin(address admin);

    /// @dev Emitted when an admin is removed.
    /// @param admin The address of the removed admin.
    event RemovedAdmin(address admin);

    /// @notice Checks if the caller is a valid admin.
    /// @param caller The address to check.
    function isValidAdmin(address caller) external view;

    /// @notice Checks if an account is an admin.
    /// @param account The address to check.
    /// @return A boolean indicating if the account is an admin.
    function isAdmin(address account) external view returns (bool);

    /// @notice Adds multiple addresses as admins.
    /// @param _admins The addresses to add as admins.
    function addAdmins(address[] calldata _admins) external;

    /// @notice Removes multiple addresses from admins.
    /// @param _admins The addresses to remove from admins.
    function removeAdmins(address[] calldata _admins) external;

    /// @notice Returns all the admin addresses.
    /// @return An array of admin addresses.
    function getAllAdmins() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @notice Interface for the Strategy Calculations contract
/// @dev This interface provides functions for performing various calculations related to the strategy.
interface IStrategyCalculations {
    /// @return The address of the Admin Structure contract
    function adminStructure() external view returns (address);

    /// @return The address of the Strategy contract
    function strategy() external view returns (address);

    /// @return The address of the Quoter contract
    function quoter() external view returns (address);

    /// @dev Constant for representing 100 (100%)
    /// @return The value of 100
    function ONE_HUNDRED() external pure returns (uint256);

    /// @notice Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum amount of tokens to receive from Curve
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _token The token to estimate the deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 estimate);

    /// @notice Estimates the deposit details for a specific token and amount
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return amountWant The minimum amount of tokens to get on the curve deposit
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 amountWant);

    /// @notice Estimates the withdrawal details for a specific user, token, maximum amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return withdrawable The minimum amount of tokens to get after the withdrawal
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 withdrawable);

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return rewardAmounts rewards the amount representing the pending rewards
    /// @return rewardTokens addresses of the reward tokens
    /// @return enoughRewards list indicating if the reward token is enough to harvest
    /// @return atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvestView()
        external
        view
        returns (
            uint256[] memory rewardAmounts,
            address[] memory rewardTokens,
            bool[] memory enoughRewards,
            bool atLeastOne
        );

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return rewardAmounts rewards the amount representing the pending rewards
    /// @return rewardTokens addresses of the reward tokens
    /// @return enoughRewards list indicating if the reward token is enough to harvest
    /// @return atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        external
        returns (
            uint256[] memory rewardAmounts,
            address[] memory rewardTokens,
            bool[] memory enoughRewards,
            bool atLeastOne
        );

    /// @notice Estimates the rewards details for a specific user, token, amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return claimable The minimum amount of tokens to get after the claim of rewards
    function estimateRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 minCurveOutput, uint256 claimable);

    /// @notice Estimates the total claimable rewards for all users using a specific token and slippage
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return claimable The total claimable amount of tokens
    function estimateAllUsersRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256 claimable);

    /// @dev Returns the amount of tokens deposited by a specific user in the indicated token
    /// @param _user The address of the user.
    /// @param _token The address of the token.
    /// @return The amount of tokens deposited by the user.
    function userDeposit(address _user, address _token) external view returns (uint256);

    /// @dev Returns the total amount of tokens deposited in the strategy in the indicated token
    /// @param _token The address of the token.
    /// @return The total amount of tokens deposited.
    function totalDeposits(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum amount of tokens to swap from a specific fromToken to toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @return The minimum amount of tokens to swap
    function getAutomaticSwapMin(address _fromToken, address _toToken) external returns (uint256);

    /// @notice Retrieves the minimum amount of LP tokens to obtained from a curve deposit
    /// @param _depositAmount The amount to deposit
    /// @return The minimum amount of LP tokens to obtained from the deposit on curve
    function getAutomaticCurveMinLp(uint256 _depositAmount) external returns (uint256);

    /// @notice Retrieves the balance of a specific token held by the Strategy
    /// @param _token The address of the token
    /// @return The token balance
    function _getTokenBalance(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum value between a specific amount and a slippage percentage
    /// @param _amount The amount
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum value
    function _getMinimum(uint256 _amount, uint256 _slippage) external pure returns (uint256);

    /// @notice Estimates the want balance after a harvest
    /// @param _slippage The allowed slippage percentage
    /// @return Returns the new want amount
    function estimateWantAfterHarvest(uint256 _slippage) external returns (uint256);
}

interface IStrategyCalculationsTwocrypto is IStrategyCalculations {
    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) external view returns (uint256[2] memory amounts);
}

interface IStrategyCalculationsTricryptoL1 is IStrategyCalculations {
    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) external view returns (uint256[3] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { IStrategyCalculations } from "./IStrategyCalculations.sol";

/// @notice Interface for the Convex Strategy contract
interface IStrategyConvex {
    /// @dev Struct representing a pool token
    struct PoolToken {
        bool isAllowed; /// Flag indicating if the token is allowed
        uint8 index; /// Index of the token
    }

    /// @dev Struct representing an oracle
    struct Oracle {
        address token; /// Token address
        address oracle; /// Oracle address
    }

    /// @dev Struct representing default slippages
    struct DefaultSlippages {
        uint256 curve; /// Default slippage for Curve swaps
        uint256 uniswap; /// Default slippage for Uniswap swaps
    }

    /// @dev Struct representing reward information
    struct RewardInfo {
        address[] tokens; /// Array of reward tokens
        uint256[] minAmount; /// Array of minimum reward amounts
    }

    /// @dev Enum representing fee types
    enum FeeType {
        MANAGEMENT, /// Management fee
        PERFORMANCE /// Performance fee
    }

    /// @dev Event emitted when a harvest is executed
    /// @param harvester The address of the harvester
    /// @param amount The amount harvested
    /// @param wantBal The balance of the want token after the harvest
    event Harvested(address indexed harvester, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when a deposit is made
    /// @param user The address of the user
    /// @param token The address of the token deposited
    /// @param wantBal The balance of the want token generated with the deposit
    event Deposit(address user, address token, uint256 wantBal);

    /// @dev Event emitted when a withdrawal is made
    /// @param user The address of the user
    /// @param token The address of the token being withdrawn
    /// @param amount The amount withdrawn
    /// @param wantBal The balance of the want token after the withdrawal
    event Withdraw(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when rewards are claimed
    /// @param user The address of the user
    /// @param token The address of the reward token
    /// @param amount The amount of rewards claimed
    /// @param wantBal The balance of the want token after claiming rewards
    event ClaimedRewards(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when fees are charged
    /// @param feeType The type of fee (Management or Performance)
    /// @param amount The amount of fees charged
    /// @param feeRecipient The address of the fee recipient
    event ChargedFees(FeeType indexed feeType, uint256 amount, address feeRecipient);

    /// @dev Event emitted when allowed tokens are edited
    /// @param token The address of the token
    /// @param status The new status (true or false)
    event EditedAllowedTokens(address token, bool status);

    /// @dev Event emitted when the pause status is changed
    /// @param status The new pause status (true or false)
    event PauseStatusChanged(bool status);

    /// @dev Event emitted when a swap path is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param path The swap path
    event SetPath(address from, address to, bytes path);

    /// @dev Event emitted when a swap route is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param route The swap route
    event SetRoute(address from, address to, address[] route);

    /// @dev Event emitted when an oracle is set
    /// @param token The address of the token
    /// @param oracle The address of the oracle
    event SetOracle(address token, address oracle);

    /// @dev Event emitted when the slippage value is set
    /// @param oldValue The old slippage value
    /// @param newValue The new slippage value
    /// @param kind The kind of slippage (Curve or Uniswap)
    event SetSlippage(uint256 oldValue, uint256 newValue, string kind);

    /// @dev Event emitted when the minimum amount to harvest is changed
    /// @param token The address of the token
    /// @param minimum The new minimum amount to harvest
    event MinimumToHarvestChanged(address token, uint256 minimum);

    /// @dev Event emitted when a reward token is added
    /// @param token The address of the reward token
    /// @param minimum The minimum amount of the reward token
    event AddedRewardToken(address token, uint256 minimum);

    /// @dev Event emitted when a panic is executed
    event PanicExecuted();
}

/// @notice Extended interface for the Convex Strategy contract
interface IStrategyConvexExtended is IStrategyConvex {
    /// @dev Returns the address of the pool contract
    /// @return The address of the pool contract
    function pool() external view returns (address);

    /// @dev Returns how many tokens the pool accepts
    /// @return The number of tokens the pool accepts
    function poolSize() external view returns (uint256);

    /// @dev Returns the address of the calculations contract
    /// @return The address of the calculations contract
    function calculations() external view returns (IStrategyCalculations);

    /// @dev Returns the address of the admin structure contract
    /// @return The address of the admin structure contract
    function adminStructure() external view returns (address);

    /// @dev Minimum amount to execute reinvestment in harvest
    function minimumToHarvest(address _token) external view returns (uint256);

    /// @dev Executes the harvest operation, it is also the function compound, reinvests rewards
    function harvest() external;

    /// @dev Executes the harvest operation on deposits, it is also the function compound, reinvests rewards
    function harvestOnDeposit() external;

    /// @dev Executes a panic operation, withdraws all the rewards from convex
    function panic() external;

    /// @dev Pauses the strategy, pauses deposits
    function pause() external;

    /// @dev Unpauses the strategy
    function unpause() external;

    /// @dev Withdraws tokens from the strategy
    /// @param _user The address of the user
    /// @param _amount The amount of tokens to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum LP output from Curve
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput
    ) external;

    /// @dev Claims rewards for the user
    /// @param _user The address of the user
    /// @param _token The address of the reward token
    /// @param _amount The amount of rewards to claim
    /// @param _minCurveOutput The minimum LP token output from Curve swap
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput
    ) external;

    /// @dev Returns the address of the reward pool contract
    /// @return The address of the reward pool contract
    function rewardPool() external view returns (address);

    /// @dev Returns the address of the deposit token
    /// @return The address of the deposit token
    function depositToken() external view returns (address);

    /// @dev Checks if a token is allowed for deposit
    /// @param token The address of the token
    /// @return isAllowed True if the token is allowed, false otherwise
    /// @return index The index of the token
    function allowedDepositTokens(address token) external view returns (bool, uint8);

    /// @dev Returns the swap path for a token pair
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @return The swap path
    function paths(address _from, address _to) external view returns (bytes memory);

    /// @dev Returns the want deposit amount of a user in the deposit token
    /// @param _user The address of the user
    /// @return The deposit amount for the user
    function userWantDeposit(address _user) external view returns (uint256);

    /// @dev Returns the total want deposits in the strategy
    /// @return The total deposits in the strategy
    function totalWantDeposits() external view returns (uint256);

    /// @dev Returns the oracle address for a token
    /// @param _token The address of the token
    /// @return The oracle address
    function oracle(address _token) external view returns (address);

    /// @dev Returns the default slippage for Curve swaps used in harvest
    /// @return The default slippage for Curve swaps
    function defaultSlippageCurve() external view returns (uint256);

    /// @dev Returns the default slippage for Uniswap swaps used in harvest
    /// @return The default slippage for Uniswap swaps
    function defaultSlippageUniswap() external view returns (uint256);

    /// @dev Returns the want token
    /// @return The want token
    function want() external view returns (IERC20Upgradeable);

    /// @dev Returns the balance of the strategy held in the strategy
    /// @return The balance of the strategy
    function balanceOf() external view returns (uint256);

    /// @dev Returns the balance of the want token held in the strategy
    /// @return The balance of the want token
    function balanceOfWant() external view returns (uint256);

    /// @dev Returns the balance of want in the strategy
    /// @return The balance of the pool
    function balanceOfPool() external view returns (uint256);

    /// @dev Returns the pause status of the strategy
    /// @return True if the strategy is paused, false otherwise
    function paused() external view returns (bool);

    /// @dev Returns the address of the weth token
    /// @return The address of the weth router
    function weth() external view returns (address);

    /// @dev Returns the address of the Uniswap router
    /// @return The address of the Uniswap router
    function unirouter() external view returns (address);

    /// @dev Returns the address of the vault contract
    /// @return The address of the vault contract
    function vault() external view returns (address);

    /// @dev Returns the address of Convex booster
    /// @return The address of the Convex booster
    function booster() external view returns (address);

    /// @dev Returns the address of Uniswap V2 router
    /// @return The address of Uniswap V2 router
    function unirouterV2() external view returns (address);

    /// @dev Returns the address of Uniswap V3 router
    /// @return The address of Uniswap V3 router
    function unirouterV3() external view returns (address);

    /// @dev Returns the performance fee
    /// @return The performance fee
    function performanceFee() external view returns (uint256);

    /// @dev Returns the management fee
    /// @return The management fee
    function managementFee() external view returns (uint256);

    /// @dev Returns the performance fee recipient
    /// @return The performance fee recipient
    function performanceFeeRecipient() external view returns (address);

    /// @dev Returns the management fee recipient
    /// @return The management fee recipient
    function managementFeeRecipient() external view returns (address);

    /// @dev Returns the fee cap
    /// @return The fee cap
    function FEE_CAP() external view returns (uint256);

    /// @dev Returns the constant value of 100
    /// @return The constant value of 100
    function ONE_HUNDRED() external view returns (uint256);

    /// @dev Sets the performance fee
    /// @param _fee The new performance fee
    function setPerformanceFee(uint256 _fee) external;

    /// @dev Sets the management fee
    /// @param _fee The new management fee
    function setManagementFee(uint256 _fee) external;

    /// @dev Sets the performance fee recipient
    /// @param recipient The new performance fee recipient
    function setPerformanceFeeRecipient(address recipient) external;

    /// @dev Sets the management fee recipient
    /// @param recipient The new management fee recipient
    function setManagementFeeRecipient(address recipient) external;

    /// @dev Sets the vault contract
    /// @param _vault The address of the vault contract
    function setVault(address _vault) external;

    /// @dev Sets the Uniswap V2 router address
    /// @param _unirouterV2 The address of the Uniswap V2 router
    function setUnirouterV2(address _unirouterV2) external;

    /// @dev Sets the Uniswap V3 router address
    /// @param _unirouterV3 The address of the Uniswap V3 router
    function setUnirouterV3(address _unirouterV3) external;

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return _rewardAmounts rewards the amount representing the pending rewards
    /// @return _rewardTokens addresses of the reward tokens
    /// @return _enoughRewards list indicating if the reward token is enough to harvest
    /// @return _atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        external
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        );

    // List of the reward tokens
    function getRewardTokens() external view returns (address[] memory);
}

/// @title IStrategyConvexNonPayable
/// @notice Extended interface for the Convex Strategy contract
interface IStrategyConvexNonPayable is IStrategyConvexExtended {
    /// @dev Deposits tokens into the strategy
    /// @param _token The address of the token to deposit
    /// @param _user The address of the user
    /// @param _minWant The minimum amount of want tokens to get from curve
    function deposit(address _token, address _user, uint256 _minWant) external;
}

/// @title IStrategyConvexPayable
/// @notice Extended interface for the Convex Strategy contract
interface IStrategyConvexPayable is IStrategyConvexExtended {
    /// @dev Deposits tokens into the strategy
    /// @param _token The address of the token to deposit
    /// @param _user The address of the user
    /// @param _minWant The minimum amount of want tokens to get from curve
    function deposit(address _token, address _user, uint256 _minWant) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IAdminStructure } from "../../interfaces/dollet/IAdminStructure.sol";

/// @title Handles fees and admin validations
/// @dev Contract that manages the fees for a strategy.
abstract contract StratFeeManager is PausableUpgradeable {
    // Address of contract that stores the information of the admins.
    IAdminStructure public adminStructure;
    /// @notice Address of the vault contract.
    address public vault;
    /// @notice Address of the Uniswap V3 router.
    address public unirouterV3;
    /// @notice Performance fee for the strategy.
    uint256 public performanceFee;
    /// @notice Management fee for the strategy.
    uint256 public managementFee;
    /// @notice Address of the performance fee recipient.
    address public performanceFeeRecipient;
    /// @notice Address of the management fee recipient.
    address public managementFeeRecipient;

    /// @dev Cap for performance and management fees.
    uint256 public constant FEE_CAP = 35 ether;
    /// @dev Value representing 100%.
    uint256 public constant ONE_HUNDRED = 100 ether;

    /// @dev Struct for common addresses used in initialization.
    struct CommonAddresses {
        IAdminStructure adminStructure;
        address vault;
        address unirouterV3;
        uint256 performanceFee;
        uint256 managementFee;
        address performanceFeeRecipient;
        address managementFeeRecipient;
    }

    /// @notice Emitted when the vault address is set.
    event SetVault(address vault);
    /// @notice Emitted when the Uniswap V3 router address is set.
    event SetUnirouterV3(address unirouter);
    /// @notice Emitted when the performance fee is set.
    event SetPerformanceFee(uint256 feeAmount);
    /// @notice Emitted when the management fee is set.
    event SetManagementFee(uint256 feeAmount);
    /// @notice Emitted when the performance fee recipient is set.
    event SetPerformanceFeeRecipient(address recipient);
    /// @notice Emitted when the management fee recipient is set.
    event SetManagementFeeRecipient(address recipient);

    /// @dev Initializes the contract.
    /// @param _commonAddresses Struct containing common addresses for initialization.
    function __StratFeeManager_init(
        CommonAddresses memory _commonAddresses
    ) internal onlyInitializing {
        require(address(_commonAddresses.adminStructure) != address(0), "ZeroAdminStructure");
        adminStructure = _commonAddresses.adminStructure;

        vault = _commonAddresses.vault;

        require(_commonAddresses.unirouterV3 != address(0), "ZeroRouter");
        unirouterV3 = _commonAddresses.unirouterV3;

        require(_commonAddresses.performanceFeeRecipient != address(0), "ZeroRecipient");
        performanceFeeRecipient = _commonAddresses.performanceFeeRecipient;

        require(_commonAddresses.managementFeeRecipient != address(0), "ZeroRecipient");
        managementFeeRecipient = _commonAddresses.managementFeeRecipient;

        require(_commonAddresses.performanceFee <= FEE_CAP, "PerformanceFeeCap");
        performanceFee = _commonAddresses.performanceFee;

        require(_commonAddresses.managementFee <= FEE_CAP, "ManagementFeeCap");
        managementFee = _commonAddresses.managementFee;
    }

    /// @dev Modifier to restrict access to super admin only.
    modifier onlySuperAdmin() {
        adminStructure.isValidSuperAdmin(msg.sender);
        _;
    }
    /// @dev Modifier to restrict access to admins and super admins only.
    modifier onlyAdmin() {
        adminStructure.isValidAdmin(msg.sender);
        _;
    }

    /// @dev Sets the performance fee for the strategy.
    /// @param _fee The new performance fee
    function setPerformanceFee(uint256 _fee) external onlyAdmin {
        require(_fee <= FEE_CAP, "PerformanceFeeCap");

        performanceFee = _fee;

        emit SetPerformanceFee(_fee);
    }

    /// @dev Sets the management fee for the strategy.
    /// @param _fee The new management fee
    function setManagementFee(uint256 _fee) external onlyAdmin {
        require(_fee <= FEE_CAP, "ManagementFeeCap");

        managementFee = _fee;

        emit SetManagementFee(_fee);
    }

    /// @dev Sets the performance fee recipient address.
    /// @param recipient The new performance fee recipient address
    function setPerformanceFeeRecipient(address recipient) external onlySuperAdmin {
        require(recipient != address(0), "ZeroRecipient");

        performanceFeeRecipient = recipient;

        emit SetPerformanceFeeRecipient(recipient);
    }

    /// @dev Sets the management fee recipient address.
    /// @param recipient The new management fee recipient address
    function setManagementFeeRecipient(address recipient) external onlySuperAdmin {
        require(recipient != address(0), "ZeroRecipient");

        managementFeeRecipient = recipient;

        emit SetManagementFeeRecipient(recipient);
    }

    /// @dev Sets the vault address.
    /// @param _vault The new vault address
    function setVault(address _vault) external onlySuperAdmin {
        require(_vault != address(0), "ZeroVault");

        vault = _vault;

        emit SetVault(_vault);
    }

    /// @dev Sets the Uniswap V3 router address.
    /// @param _unirouterV3 The new Uniswap V3 router address
    function setUnirouterV3(address _unirouterV3) external onlySuperAdmin {
        require(_unirouterV3 != address(0), "ZeroRouter");

        unirouterV3 = _unirouterV3;

        emit SetUnirouterV3(_unirouterV3);
    }

    uint256[60] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IStrategyCalculationsTwocrypto as IStrategyCalculations } from "../../interfaces/dollet/IStrategyCalculations.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { AggregatorV3Interface } from "../../interfaces/chainlink/AggregatorV3Interface.sol";
import { IConvexBoosterL2, IConvexRewardPoolL2 } from "../../interfaces/convex/IConvex.sol";
import { IStrategyConvex } from "../../interfaces/dollet/IStrategyConvex.sol";
import { IGaugeFactory } from "../../interfaces/curve/IGaugeFactory.sol";
import { ICurveSwap } from "../../interfaces/curve/ICurveSwap.sol";
import { StratFeeManager } from "../common/StratFeeManager.sol";
import { IQuoter } from "../../interfaces/common/IQuoter.sol";
import { IERC20 } from "../../interfaces/common/IERC20.sol";
import { UniV3Actions } from "../../utils/UniV3Actions.sol";

/// @title Strategy intermediary to interact with defi protocols
/// @notice The StrategyConvexBicryptoL2 contract is a crucial component of a project focused on optimizing
/// yield farming on Convex Finance. It facilitates the management of a strategy by interacting with
/// external contracts, such as a Convex booster, a calculations contract, and a Curve swap pool. The contract
/// allows users to deposit funds, claim rewards, and perform harvesting operations. It supports multiple tokens
/// for deposit and incorporates checks and validations to ensure secure operations. With features like token
/// swapping and reinvestment strategies, the contract helps users maximize their yields and earn rewards effectively.
contract StrategyConvexBicryptoL2 is IStrategyConvex, StratFeeManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Address of the booster contract
    IConvexBoosterL2 public booster;
    /// @notice Address of the calculations contract
    IStrategyCalculations public calculations;
    bool public isPanicActive; // True if panic is active
    address public want; // Curve LP Token
    address public pool; // Curve swap pool
    address public depositToken; // Token used to reinvest in harvest
    address public rewardPool; // Convex base reward pool
    uint256 public pid; // Convex booster poolId
    uint256 public poolSize; // Pool size
    uint256 public depositIndex; // Index of depositToken in pool
    uint256 public lastHarvest; // Last timestamp when the harvest occurred
    uint256 public totalWantDeposits; // Total of deposits in Curve LP
    uint256 public defaultSlippageCurve; // Curve slippage used in harvest
    uint256 public defaultSlippageUniswap; // Uniswap slippage used in harvest
    mapping(address => uint256) public userWantDeposit; // Total user deposited in Curve LP
    mapping(address => uint256) public minimumToHarvest; // Minimum amount to execute reinvestment in harvest
    mapping(address => mapping(address => bytes)) public paths; // From => To returns path for Uniswap
    mapping(address => AggregatorV3Interface) public oracle; // Price oracle for a token
    mapping(address => PoolToken) public allowedDepositTokens; // Indicates what token is allowed
    address[] private rewardTokens; // List of the reward tokens
    address[] public listAllowedDepositTokens; // List of the allowed tokens

    /// @dev Modifier to restrict access to vault only.
    modifier onlyVault() {
        require(msg.sender == vault, "InvalidCaller");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract
    /// @param _want The address of the curve lpToken
    /// @param _pool The address of the curve swap pool
    /// @param _booster The address of the Convex booster contract
    /// @param _pid The pool ID of the Convex booster
    /// @param _depositToken The token sent to the pool to receive want
    /// @param _oracles The array of oracle token and oracle address pairs
    /// @param _params The array of poolSize and depositIndex parameters
    /// @param _defaultSlippages The default slippages for curve and Uniswap
    /// @param rewardInfo The reward token addresses and minimum amounts for rewards
    /// @param _commonAddresses The addresses of common contracts
    function initialize(
        address _want,
        address _pool,
        address _booster,
        uint256 _pid,
        address _depositToken,
        Oracle[] calldata _oracles,
        uint256[] calldata _params, // [poolSize, depositIndex]
        DefaultSlippages calldata _defaultSlippages,
        RewardInfo calldata rewardInfo,
        CommonAddresses calldata _commonAddresses
    ) public initializer {
        __StratFeeManager_init(_commonAddresses);
        require(_want != address(0), "ZeroWant");
        require(_pool != address(0), "ZeroPool");
        require(_booster != address(0), "ZeroBooster");
        require(_depositToken != address(0), "ZeroDeposit");
        require(ONE_HUNDRED >= _defaultSlippages.curve, "InvalidDefaultSlippageCurve");
        require(ONE_HUNDRED >= _defaultSlippages.uniswap, "InvalidDefaultSlippageUniswap");

        for (uint256 i; i < _oracles.length; i++) {
            require(_oracles[i].token != address(0), "ZeroOracleToken");
            require(_oracles[i].oracle != address(0), "ZeroOracleOracle");
            oracle[_oracles[i].token] = AggregatorV3Interface(_oracles[i].oracle);
        }
        defaultSlippageCurve = _defaultSlippages.curve;
        defaultSlippageUniswap = _defaultSlippages.uniswap;
        (want, pool, pid, depositToken) = (_want, _pool, _pid, _depositToken);
        booster = IConvexBoosterL2(_booster);
        poolSize = _params[0];
        depositIndex = _params[1];
        (, , rewardPool, , ) = booster.poolInfo(_pid);
        addRewardToken(rewardInfo.tokens, rewardInfo.minAmount);

        // Adding valid tokens
        uint256 _poolSize = poolSize;
        for (uint256 i; i < _poolSize; i++) {
            address coin = ICurveSwap(_pool).coins(i);
            allowedDepositTokens[coin] = PoolToken(true, uint8(i));
            listAllowedDepositTokens.push(coin);
        }
        _modifyAllowances(type(uint).max);
    }

    /// @notice Deposits funds into the strategy
    /// @dev Only the vault contract can call this function
    /// @param _token The address of the token to deposit
    /// @param _user The address of the user making the deposit
    /// @param _minWant The minimum amount of want tokens to get from the curve deposit
    function deposit(
        address _token,
        address _user,
        uint256 _minWant
    ) external whenNotPaused onlyVault {
        require(allowedDepositTokens[_token].isAllowed, "TokenNotAllowed");
        uint256 wantBefore = balanceOfWant();
        _addLiquidityCurve(_token, _minWant);
        uint256 depositedWant = balanceOfWant() - wantBefore;
        userWantDeposit[_user] += depositedWant;
        totalWantDeposits += depositedWant;
        _addLiquidityConvex();
        emit Deposit(_user, _token, depositedWant);
    }

    /// @notice Withdraws funds from the strategy
    /// @dev Only the vault contract can call this function
    /// @param _user The address of the user making the withdrawal
    /// @param _amount The amount to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput
    ) external onlyVault {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed, "TokenNotAllowed");
        uint256 wantBal = balanceOfWant();
        if (wantBal < _amount) {
            IConvexRewardPoolL2(rewardPool).withdraw(_amount - wantBal, false);
            wantBal = balanceOfWant();
        }
        if (wantBal > _amount) wantBal = _amount;

        ICurveSwap(pool).remove_liquidity_one_coin(
            wantBal,
            int128(uint128(poolToken.index)),
            _minCurveOutput
        );
        // Subtracts to the user deposit
        uint256 tokenBal = _getTokenBalance(_token);
        uint256 _userDeposit = userWantDeposit[_user];
        userWantDeposit[_user] = 0;
        totalWantDeposits -= _userDeposit;
        // Calculates percentage of fees
        uint256 _rewards = 0;
        if (_userDeposit < wantBal) {
            uint256 rewardsPercentage = ((wantBal - _userDeposit) * 1e18) / wantBal;
            _rewards = (tokenBal * rewardsPercentage) / 1e18;
        }
        chargeFees(FeeType.PERFORMANCE, _token, _rewards);
        uint256 depositMinusRewards = tokenBal - _rewards;
        chargeFees(FeeType.MANAGEMENT, _token, depositMinusRewards);
        // Sends tokens
        uint256 withdrawAmount = _getTokenBalance(_token);
        IERC20Upgradeable(_token).safeTransfer(vault, withdrawAmount);
        emit Withdraw(_user, _token, withdrawAmount, balanceOf());
    }

    /// @notice Claims rewards for a user
    /// @dev Only the vault contract can call this function
    /// @param _user The address of the user claiming rewards
    /// @param _token The address of the token to receive rewards
    /// @param _amount The amount of tokens to claim as rewards
    /// @param _minCurveOutput The minimum amount of tokens to receive from Curve
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput
    ) external onlyVault {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed, "TokenNotAllowed");
        uint256 _userDeposit = userWantDeposit[_user];
        require(_userDeposit > 0, "InsufficientDeposit");
        require(_amount > _userDeposit, "ZeroRewards");
        uint256 rewardAmount = _amount - _userDeposit;
        uint256 wantBal = balanceOfWant();
        if (wantBal < rewardAmount) {
            IConvexRewardPoolL2(rewardPool).withdraw(rewardAmount - wantBal, false);
            wantBal = balanceOfWant();
        }
        if (wantBal > rewardAmount) wantBal = rewardAmount;

        ICurveSwap(pool).remove_liquidity_one_coin(
            wantBal,
            int128(uint128(poolToken.index)),
            _minCurveOutput
        );
        uint256 totalRewards = _getTokenBalance(_token);
        chargeFees(FeeType.PERFORMANCE, _token, totalRewards);
        uint256 userRewards = _getTokenBalance(_token);
        IERC20Upgradeable(_token).safeTransfer(vault, userRewards);
        emit ClaimedRewards(_user, _token, userRewards, balanceOf());
    }

    /// @notice Harvests rewards without convex deposit
    function harvestOnDeposit() external whenNotPaused onlyVault {
        _harvest(false);
    }

    /// @notice Harvests earnings (compounds rewards) and charges performance fee
    function harvest() external {
        _harvest(true);
    }

    /// @notice Harvests earnings (compounds rewards) and charges performance fee
    function _harvest(bool _depositConvex) private {
        (, , , bool atLeastOneToHarvest) = getPendingToHarvest();
        if (!atLeastOneToHarvest) return;
        IConvexRewardPoolL2(rewardPool).getReward(address(this));
        address _depositToken = depositToken;
        uint256 rewardTokensLength = rewardTokens.length;
        for (uint256 i = 0; i < rewardTokensLength; i++) {
            _exchangeAllToken(
                rewardTokens[i],
                _depositToken,
                calculations.getAutomaticSwapMin(rewardTokens[i], _depositToken)
            );
        }
        uint256 depositBal = _getTokenBalance(_depositToken);
        _addLiquidityCurve(_depositToken, calculations.getAutomaticCurveMinLp(depositBal));
        if (_depositConvex && !paused()) _addLiquidityConvex();
        lastHarvest = block.timestamp;
        emit Harvested(msg.sender, depositBal, balanceOf());
    }

    /// @notice Edits the "isAllowed" status of the deposit tokens
    /// @dev Only the admin and super admin can call this function
    /// @param _token The address of the token to edit
    /// @param _status The new status of the token (allowed=true or not allowed=false)
    function editAllowedDepositTokens(address _token, bool _status) external onlyAdmin {
        PoolToken memory poolToken = allowedDepositTokens[_token];
        require(poolToken.isAllowed != _status, "TokenWontChange");
        require(ICurveSwap(pool).coins(poolToken.index) == _token, "TokenNotValid");
        allowedDepositTokens[_token].isAllowed = _status;
        // Excluded because it is needed to harvest (compound)
        if (depositToken != _token) {
            uint256 approvalAmount = _status ? type(uint).max : 0;
            IERC20Upgradeable(_token).safeApprove(pool, approvalAmount);
        }
        uint256 allowedLength = listAllowedDepositTokens.length;
        bool atLeastOne;
        for (uint256 i; i < allowedLength; i++) {
            if (allowedDepositTokens[listAllowedDepositTokens[i]].isAllowed) {
                atLeastOne = true;
                continue;
            }
        }
        require(atLeastOne, "CantDisableAllTokens");
        emit EditedAllowedTokens(_token, _status);
    }

    /// @notice Edits the minimum token harvest amounts
    /// @dev Only the admin and super admin can call this function
    /// @param _tokens An array of token addresses to edit
    /// @param _minAmounts An array of minimum harvest amounts corresponding to the tokens
    function editMinimumTokenHarvest(
        address[] calldata _tokens,
        uint256[] calldata _minAmounts
    ) external onlyAdmin {
        require(_tokens.length == _minAmounts.length, "LengthsMismatch");
        for (uint256 i = 0; i < _tokens.length; i++) {
            minimumToHarvest[_tokens[i]] = _minAmounts[i];
            emit MinimumToHarvestChanged(_tokens[i], _minAmounts[i]);
        }
    }

    /// @notice Sets the path for token swaps
    /// @dev Only the admin and super admin can call this function
    /// @param _from An array of source token addresses
    /// @param _to An array of target token addresses
    /// @param _path An array of encoded swap paths for each token pair
    function setPath(
        address[] calldata _from,
        address[] calldata _to,
        bytes[] calldata _path
    ) external onlyAdmin {
        uint256 inputsLength = _from.length;
        require(inputsLength == _to.length && inputsLength == _path.length, "LengthsMismatch");
        for (uint256 i = 0; i < inputsLength; i++) {
            paths[_from[i]][_to[i]] = _path[i];
            emit SetPath(_from[i], _to[i], _path[i]);
        }
    }

    /// @notice Sets the strategy calculations contract
    /// @dev Only the super admin can call this function
    /// @param _calculations The address of the strategy calculations contract
    function setStrategyCalculations(IStrategyCalculations _calculations) external onlySuperAdmin {
        require(address(_calculations) != address(0), "ZeroCalculations");
        calculations = _calculations;
    }

    /// @notice Sets the oracles for token price feeds
    /// @dev Only the super admin can call this function
    /// @param _oracles An array of Oracle structs containing token and oracle addresses
    function setOracles(Oracle[] calldata _oracles) external onlySuperAdmin {
        for (uint256 i; i < _oracles.length; i++) {
            require(_oracles[i].token != address(0), "ZeroOracleToken");
            require(_oracles[i].oracle != address(0), "ZeroOracleOracle");
            oracle[_oracles[i].token] = AggregatorV3Interface(_oracles[i].oracle);
            emit SetOracle(_oracles[i].token, _oracles[i].oracle);
        }
    }

    /// @notice Sets the default slippage for Curve swaps used during harvest
    /// @dev Only the admin and super admin can call this function
    /// @param _defaultSlippage The default slippage percentage (0-100)
    function setDefaultSlippageCurve(uint256 _defaultSlippage) external onlyAdmin {
        require(ONE_HUNDRED >= _defaultSlippage, "InvalidDefaultSlippage");
        emit SetSlippage(defaultSlippageCurve, _defaultSlippage, "Curve");
        defaultSlippageCurve = _defaultSlippage;
    }

    /// @notice Sets the default slippage for Uniswap swaps
    /// @dev Only the admin and super admin can call this function
    /// @param _defaultSlippage The default slippage percentage (0-100)
    function setDefaultSlippageUniswap(uint256 _defaultSlippage) external onlyAdmin {
        require(ONE_HUNDRED >= _defaultSlippage, "InvalidDefaultSlippage");
        emit SetSlippage(defaultSlippageUniswap, _defaultSlippage, "Uniswap");
        defaultSlippageUniswap = _defaultSlippage;
    }

    /// @notice Deletes the reward tokens array
    /// @dev Only the super admin can call this function
    function deleteRewards() external onlySuperAdmin {
        delete rewardTokens;
    }

    /// @notice Unpauses the contract deposits and increases the token allowances
    /// @dev Only the admin and super admin can call this function
    /// @dev This function also reactivates everything after a panic
    function unpause() external onlyAdmin {
        _unpause();
        _modifyAllowances(type(uint).max);
        _addLiquidityConvex();
        isPanicActive = false;
        emit PauseStatusChanged(false);
    }

    /// @notice Retrieves the reward tokens array
    /// @return An array of reward token addresses
    function getRewardTokens() external view returns (address[] memory) {
        return rewardTokens;
    }

    /// @notice Retrieves the allowed deposit tokens array
    /// @return An array of allowed deposit token addresses
    function getAllowedDepositTokens() external view returns (address[] memory) {
        return listAllowedDepositTokens;
    }

    /// @notice Pauses deposits, and withdraws all funds from the convex pool
    /// @dev Only the super admin can call this function
    /// @dev Users can still withdraw their deposit tokens
    function panic() public onlySuperAdmin {
        pause();
        isPanicActive = true;
        IConvexRewardPoolL2(rewardPool).withdrawAll(false);
        emit PanicExecuted();
    }

    /// @notice Pauses deposits and modifies token allowances
    /// @dev Only the admin and super admin can call this function
    /// @dev Users can still withdraw their deposit tokens
    function pause() public onlyAdmin {
        _pause();
        _modifyAllowances(0);
        emit PauseStatusChanged(true);
    }

    /// @notice Adds reward tokens to the strategy
    /// @notice New reward tokens need to add an oracle and swap path to be reinvested
    /// @dev Only the super admin can call this function
    /// @param tokens An array of token addresses to add as reward tokens
    /// @param minAmounts An array of minimum harvest amounts corresponding to the reward tokens
    function addRewardToken(
        address[] calldata tokens,
        uint256[] calldata minAmounts
    ) public onlySuperAdmin {
        uint256 tokensLength = tokens.length;
        require(tokensLength == minAmounts.length, "LengthsMismatch");
        for (uint256 i; i < tokensLength; i++) {
            address token = tokens[i];
            require(token != address(0), "ZeroRewardToken");
            require(token != want, "CannotUseWant");
            require(token != rewardPool, "CannotUseRewardPool");
            uint256 rewardTokensLength = rewardTokens.length;
            for (uint256 j; j < rewardTokensLength; j++) {
                require(token != rewardTokens[j], "TokenAlreadyExists");
            }
            rewardTokens.push(token);
            minimumToHarvest[token] = minAmounts[i];
            IERC20Upgradeable(token).safeApprove(unirouterV3, 0);
            IERC20Upgradeable(token).safeApprove(unirouterV3, type(uint).max);
            emit AddedRewardToken(token, minAmounts[i]);
        }
    }

    /// @notice Retrieves information about the pending rewards to harvest from the convex pool
    /// @return _rewardAmounts rewards the amount representing the pending rewards
    /// @return _rewardTokens addresses of the reward tokens
    /// @return _enoughRewards list indicating if the reward token is enough to harvest
    /// @return _atLeastOne indicates if there is at least one reward to harvest
    function getPendingToHarvest()
        public
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        )
    {
        return calculations.getPendingToHarvest();
    }

    /// @notice Calculates the total balance of the strategy
    /// @return The total balance of the strategy
    function balanceOf() public view returns (uint256) {
        return balanceOfWant() + balanceOfPool();
    }

    /// @notice Calculates the balance of the 'want' token held by the strategy
    /// @return The balance of the 'want' token
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(want).balanceOf(address(this));
    }

    /// @notice Calculates the balance of the 'want' token in the convex pool
    /// @return The balance of the 'want' token in the convex pool
    function balanceOfPool() public view returns (uint256) {
        return IConvexRewardPoolL2(rewardPool).balanceOf(address(this));
    }

    /// @notice Charges fees (performance or management) in the specified token
    /// @param feeType The type of fee to charge (performance or management)
    /// @param token The token in which to charge the fees
    /// @param amount The amount of tokens to charge fees on
    function chargeFees(FeeType feeType, address token, uint256 amount) internal {
        (uint256 percentage, address feeRecipient) = feeType == FeeType.PERFORMANCE
            ? (performanceFee, performanceFeeRecipient)
            : (managementFee, managementFeeRecipient);
        if (percentage > 0) {
            uint256 feeAmount = (amount * percentage) / ONE_HUNDRED;
            IERC20Upgradeable(token).safeTransfer(feeRecipient, feeAmount);
            emit ChargedFees(feeType, feeAmount, feeRecipient);
        }
    }

    /// @notice Adds liquidity to the convex pool using the 'want' token
    /// @dev This function is private and used internally
    function _addLiquidityConvex() private {
        uint256 wantBal = balanceOfWant();
        if (wantBal > 0) {
            booster.deposit(pid, wantBal);
        }
    }

    /// @notice Adds liquidity to the Curve pool using the deposit token
    /// @param _minWant The minimum amount of 'want' tokens to obtain from the Curve pool
    /// @dev This function is private and used internally
    function _addLiquidityCurve(address _token, uint256 _minWant) private {
        uint256 depositAmount = _getTokenBalance(_token);
        uint256[2] memory amounts = calculations.getCurveAmounts(_token, depositAmount);
        if (paused()) IERC20Upgradeable(_token).safeApprove(pool, depositAmount);
        ICurveSwap(pool).add_liquidity(amounts, _minWant);
    }

    /// @notice Modifies token allowances for the strategy
    /// @param _amount The new allowance amount
    /// @dev This function is private and used internally
    function _modifyAllowances(uint256 _amount) private {
        IERC20Upgradeable(want).safeApprove(address(booster), _amount);
        address[] memory allowedTokens = listAllowedDepositTokens;
        uint256 tokensLength = allowedTokens.length;
        for (uint256 i = 0; i < tokensLength; i++) {
            IERC20Upgradeable(allowedTokens[i]).safeApprove(pool, _amount);
        }
    }

    /// @notice Swaps all of the given token for another token
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _minSwap The minimum amount of tokens to receive from the swap
    /// @return amountOut The amount of tokens received from the swap
    /// @dev This function is private and used internally
    function _exchangeAllToken(
        address _from,
        address _to,
        uint256 _minSwap
    ) private returns (uint256 amountOut) {
        return _exchangeTokenAmount(_from, _to, _getTokenBalance(_from), _minSwap);
    }

    /// @notice Swaps the specified amount of tokens from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _minSwap The minimum amount of tokens to receive from the swap
    /// @return amountOut The amount of tokens received from the swap
    /// @dev This function is private and used internally
    function _exchangeTokenAmount(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _minSwap
    ) private returns (uint256 amountOut) {
        if (_amount < minimumToHarvest[_from]) return 0;
        bytes memory path = paths[_from][_to];
        require(path.length > 0, "Nonexistent Path");
        return UniV3Actions.swapV3WithDeadline(unirouterV3, path, _amount, _minSwap);
    }

    /// @notice Retrieves the balance of the specified token held by the strategy
    /// @param _token The address of the token
    /// @return The balance of the token
    /// @dev This function is private and used internally
    function _getTokenBalance(address _token) private view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import { IUniswapRouterV3WithDeadline } from "../interfaces/common/IUniswapRouterV3WithDeadline.sol";
import { IUniswapRouterV3 } from "../interfaces/common/IUniswapRouterV3.sol";

/// @title Library to interact with uniswap v3
/// @dev Library for Uniswap V3 actions.
library UniV3Actions {
    /// @dev Performs a Uniswap V3 swap with a deadline.
    /// @param _router The address of the Uniswap V3 router.
    /// @param _path The path of tokens for the swap.
    /// @param _amount The input amount for the swap.
    /// @param _amountOutMinimum The minimum amount of output tokens expected from the swap.
    /// @return amountOut The amount of output tokens received from the swap.
    function swapV3WithDeadline(
        address _router,
        bytes memory _path,
        uint256 _amount,
        uint256 _amountOutMinimum
    ) internal returns (uint256 amountOut) {
        IUniswapRouterV3WithDeadline.ExactInputParams
            memory swapParams = IUniswapRouterV3WithDeadline.ExactInputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: _amountOutMinimum
            });
        return IUniswapRouterV3WithDeadline(_router).exactInput(swapParams);
    }
}