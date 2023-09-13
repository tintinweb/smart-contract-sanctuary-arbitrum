// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICore {
    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isMultistrategy(address _address) external view returns (bool);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function grantMultistrategy(address multistrategy) external;

    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFarmTokenPool {
    struct User {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct Pool {
        bool isActive;
        uint256 creationTS;
        uint256 accRewardPerShare;
        uint256 totalStaked;
    }

    // function pool(uint256 trancheId) external view returns (Pool memory);

    // function users(uint256 trancheId, address user) external view returns (User memory);

    function sendRewards(address rewardToken, uint256 trancheId, uint256 _amount) external;

    function unstake(address rewardToken, uint256 trancheId, address account, uint256 _amount) external;

    function stake(address rewardToken, uint256 trancheId, address account, uint256 _amount) external;

    function changeRewardTokens(address[] memory toAdd, address[] memory toPause, address[] memory newTokens) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeRewards {
    function sendRewards(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMasterPoints {
    function rewardToken() external view returns (address);

    function rewardPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function cycleId() external view returns (uint256);

    function rewarding() external view returns (bool);

    function votingEscrow() external view returns (address);

    function poolInfo(uint256 pid) external view returns (uint256);

    function userInfo(uint256 pid, address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 cid,
            uint256 earned
        );

    function poolSnapshot(uint256 cid, uint256 pid)
        external
        view
        returns (
            uint256 totalSupply,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare
        );

    function poolLength() external view returns (uint256);

    function add(uint256 _allocPoint) external;

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external;

    function setVotingEscrow(address _votingEscrow) external;

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingReward(address _user, uint256 _pid) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function updateStake(
        uint256 _pid,
        address _account,
        uint256 _amount
    ) external;

    function start(uint256 _endBlock) external;

    function next(uint256 _cid) external;

    function claim(
        uint256 _pid,
        uint256 _lockDurationIfNoLock,
        uint256 _newLockExpiryTsIfLockExists
    ) external;

    function claimAll(uint256 _lockDurationIfNoLock, uint256 _newLockExpiryTsIfLockExists) external;

    function updateRewardPerBlock(uint256 _rewardPerBlock) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStrategyToken {
    function token() external view returns (address);

    function deposit(uint256 _amount) external;

    function withdraw(address[] memory _strategyAddresses) external;

    function approveToken() external;
}

interface IMultiStrategyToken is IStrategyToken {
    function strategies(uint256 idx) external view returns (address);

    function strategyCount() external view returns (uint256);

    function ratios(address _strategy) external view returns (uint256);

    function ratioTotal() external view returns (uint256);

    function updateStrategiesAndRatios(address[] calldata _strategies, uint256[] calldata _ratios) external;

    function changeRatio(uint256 _index, uint256 _value) external;

    function inCaseTokensGetStuck(
        address _token,
        uint256 _amount,
        address _to
    ) external;

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITrancheYieldCurve {
    struct YieldDistrib {
        uint256 fixedSeniorYield;
        uint256 juniorYield;
        uint256[] seniorFarmYield;
        uint256[] juniorFarmYield;
    }

    function getYieldDistribution(
        uint256 _seniorProportion,
        uint256 _totalPrincipal,
        uint256 _restCapital,
        uint256 _cycleDuration,
        uint256[] memory _farmedTokensAmts
    ) external view returns (YieldDistrib memory);

    function setSeniorAPR(uint256 _apr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../refs/CoreRefUpgradeable.sol";
import "../interfaces/ITrancheYieldCurve.sol";
import "../interfaces/IMasterPoints.sol";
import "../interfaces/IStrategyToken.sol";
import "../interfaces/IFeeRewards.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IFarmTokenPool.sol";

contract TrancheMasterPerpetualUpgradeable is Initializable, CoreRefUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct TrancheParams {
        uint256 fee;
        bool principalFee;
    }

    struct Tranche {
        uint256 principal;
        uint256 autoPrincipal;
        uint256 validPercent; // do we need this
        uint256 fee;
        uint256 autoValid;
        bool principalFee;
    }

    struct TrancheSnapshot {
        uint256 principal;
        uint256 capital;
        uint256 validPercent;
        uint256 rate;
        uint256 fee;
        uint256 startAt;
        uint256 stopAt;
    }

    struct Investment {
        uint256 cycle;
        uint256 principal;
    }

    struct UserInfo {
        uint256 balance;
        bool isAuto;
    }

    uint256 private PERCENTAGE_PARAM_SCALE;
    uint256 public PERCENTAGE_SCALE;
    uint256 private MAX_FEE;
    uint256 public pendingStrategyWithdrawal;
    uint256 public producedFee;
    uint256 public duration;
    uint256 public investmentWindow;
    uint256 public cycle;
    uint256 public actualStartAt;
    bool public active;
    Tranche[] public tranches;
    address public wNative;
    address public currency;
    address[] public farmTokens;
    address public farmTokensPool;
    address public staker;
    address public strategy;
    address public trancheYieldCurve;
    address public devAddress;
    address[] private zeroAddressArr;
    address[] public userInvestPendingAddressArr;

    mapping(address => UserInfo) public userInfo;
    // userAddress => tid => pendingAmount
    mapping(address => mapping(uint256 => uint256)) public userInvestPending;
    mapping(address => mapping(uint256 => Investment)) public userInvest;

    // cycle => trancheID => snapshot
    mapping(uint256 => mapping(uint256 => TrancheSnapshot)) public trancheSnapshots;

    event Deposit(address account, uint256 amount);

    event Invest(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Redeem(address account, uint256 tid, uint256 cycle, uint256 amount);

    event Withdraw(address account, uint256 amount);

    event Harvest(address account, uint256 tid, uint256 cycle, uint256 principal, uint256 capital);

    event TrancheAdd(uint256 tid, uint256 fee, bool principalFee);

    event TrancheUpdated(uint256 tid, uint256 fee, bool principalFee);

    event TrancheStart(uint256 tid, uint256 cycle, uint256 principal);

    event TrancheSettle(uint256 tid, uint256 cycle, uint256 principal, uint256 capital, uint256 rate);

    // Error Code
    // E1 = tranches is incomplete
    // E2 = invalid tranche id
    // E3 = not active
    // E4 = already active
    // E5 = user autorolling
    // E6 = at least 1 strategy is pending for withdrawal
    // E7 = currency is not wNative
    // E8 = value != msg.value
    // E9 = invalid fee
    // E10 = cannot switch ON autoroll while the cycle is active
    // E11 = invalid amountIn
    // E12 = invalid amountInvest
    // E13 = balance not enough
    // E14 = invalid amount
    // E15 = not enough principal
    // E16 = nothing for redemption
    // E17 = MUST be 2 tranches
    // E18 = cycle not expired
    // E19 = no strategy is pending for withdrawal
    // E20 = not enough balance for fee
    // E21 = investmentWindow is missed
    // E22 = both tranches should have positive principal/autoprincipal
    // E23 = a new cycle can be started only after investment window completed
    // E24 = invalid investmentWindow

    modifier checkActive() {
        require(active, "E3");
        _;
    }

    modifier checkNotActive() {
        require(!active, "E4");
        _;
    }

    modifier checkNotAuto() {
        require(!userInfo[msg.sender].isAuto, "E5");
        _;
    }

    modifier checkNoPendingStrategyWithdrawal() {
        require(pendingStrategyWithdrawal == 0, "E6");
        _;
    }

    function transferTokenToVault(uint256 value) internal {
        if (msg.value != 0) {
            require(currency == wNative, "E7");
            require(value == msg.value, "E8");
            IWETH(currency).deposit{value: msg.value}();
        } else {
            IERC20Upgradeable(currency).safeTransferFrom(msg.sender, address(this), value);
        }
    }

    function init(
        address[] memory _coreAndWNative,
        address _currency,
        address[] memory _farmTokens,
        address _farmTokensPool,
        address _strategy,
        address _staker,
        address _devAddress,
        uint256 _duration,
        uint256 _investmentWindow,
        TrancheParams[] memory _params
    ) public initializer {
        CoreRefUpgradeable.initialize(_coreAndWNative[0]);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        wNative = _coreAndWNative[1];
        currency = _currency;
        farmTokens = _farmTokens;
        farmTokensPool = _farmTokensPool;
        strategy = _strategy;
        staker = _staker;
        devAddress = _devAddress;
        duration = _duration;
        investmentWindow = _investmentWindow;
        PERCENTAGE_PARAM_SCALE = 1e5;
        PERCENTAGE_SCALE = 1e18;
        MAX_FEE = 50000;
        pendingStrategyWithdrawal = 0;

        IERC20Upgradeable(currency).safeApprove(strategy, type(uint256).max);

        for (uint256 i = 0; i < _params.length; i++) {
            _add(_params[i].fee, _params[i].principalFee);
        }
        zeroAddressArr.push(address(0));
    }

    function _add(uint256 fee, bool principalFee) internal {
        require(fee <= MAX_FEE, "E9");
        tranches.push(
            Tranche({
                fee: fee,
                principal: 0,
                autoPrincipal: 0,
                validPercent: 0,
                autoValid: 0,
                principalFee: principalFee
            })
        );
        emit TrancheAdd(tranches.length - 1, fee, principalFee);
    }

    function set(uint256 tid, uint256 fee, bool principalFee) public onlyTimelock {
        require(fee <= MAX_FEE, "E9");
        tranches[tid].fee = fee;
        tranches[tid].principalFee = principalFee;
        emit TrancheUpdated(tid, fee, principalFee);
    }

    // Updating invest

    function _updateInvest(address account) internal {
        UserInfo storage u = userInfo[account];
        uint256 initPrincipal;
        uint256 principal;
        uint256 capital;
        for (uint i = 0; i < tranches.length; i++) {
            Investment storage inv = userInvest[account][i];
            initPrincipal = inv.principal;
            principal = inv.principal;
            // check principal. If it's zero then set the user's latest invest cycle to the current invest cycle
            if (principal == 0) {
                inv.cycle = cycle;
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    capital = principal.mul(snapshot.rate).div(PERCENTAGE_SCALE);
                    emit Harvest(account, i, j, principal, capital);
                    principal = capital;
                }
                inv.principal = principal;
                IMasterPoints(staker).updateStake(i, account, inv.principal);
            } else {
                if (inv.cycle < cycle) {
                    // after queueing withdrawal the funds no longer participate in the cycle
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    capital = principal.mul(snapshot.rate).div(PERCENTAGE_SCALE);
                    u.balance = u.balance.add(capital);
                    inv.principal = 0;
                    IMasterPoints(staker).updateStake(i, account, 0);
                    emit Harvest(account, i, inv.cycle, principal, capital);
                }
            }
            inv.cycle = cycle;
            // update farm token pools with user principal
            for (uint256 s = 0; s < farmTokens.length; s++) {
                if (initPrincipal < inv.principal) {
                    IFarmTokenPool(farmTokensPool).stake(farmTokens[s], i, account, inv.principal.sub(initPrincipal));
                } else if (initPrincipal > inv.principal) {
                    IFarmTokenPool(farmTokensPool).unstake(farmTokens[s], i, account, initPrincipal.sub(inv.principal));
                }
            }
        }
    }

    function queueWithdrawal() public nonReentrant {
        _switchAuto(false, msg.sender);
    }

    function _switchAuto(bool _auto, address userAddress) internal {
        _updateInvest(userAddress);
        if (_auto) {
            require(active == false, "E10");
        }
        UserInfo storage u = userInfo[userAddress];
        if (u.isAuto == _auto) {
            return;
        }

        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[userAddress][i];
            if (inv.principal == 0) {
                continue;
            }
            Tranche storage t = tranches[i];
            if (_auto) {
                t.principal = t.principal.sub(inv.principal);
                t.autoPrincipal = t.autoPrincipal.add(inv.principal);
            } else {
                t.principal = t.principal.add(inv.principal);
                t.autoPrincipal = t.autoPrincipal.sub(inv.principal);
                // here we basically subtract inv.principal from autoValid so that on the next cycle the contract knows
                // that user asked for funds withdrawal and subtract them from autoPrincipal
                if (active) {
                    t.autoValid = t.autoValid > inv.principal ? t.autoValid.sub(inv.principal) : 0; // make sure it's compatible with startCycle autoValid logic
                }
            }
        }
        u.isAuto = _auto;
    }

    function investDirect(
        uint256 amountIn,
        uint256 tid,
        uint256 amountInvest
    ) public payable checkNotActive checkNoPendingStrategyWithdrawal nonReentrant {
        // ensure that the investment is within investment window
        if (cycle > 0) {
            TrancheSnapshot memory snapshot = trancheSnapshots[cycle - 1][0];
            require(block.timestamp.sub(snapshot.stopAt) <= investmentWindow, "E21");
        }
        _updateInvest(msg.sender);
        transferTokenToVault(amountIn);
        require(amountIn > 0, "E11");
        require(amountInvest > 0, "E12");

        UserInfo storage u = userInfo[msg.sender];
        require(u.balance.add(amountIn) >= amountInvest, "E13");

        u.balance = u.balance.add(amountIn);
        emit Deposit(msg.sender, amountIn);

        _invest(tid, amountInvest, msg.sender);
        _switchAuto(true, msg.sender);
    }

    function _invest(uint256 tid, uint256 amount, address userAddress) private {
        UserInfo storage u = userInfo[userAddress];
        require(amount <= u.balance, "E13");

        Tranche storage t = tranches[tid];
        Investment storage inv = userInvest[userAddress][tid];
        inv.principal = inv.principal.add(amount);
        u.balance = u.balance.sub(amount);
        if (u.isAuto) {
            t.autoPrincipal = t.autoPrincipal.add(amount); // make sure this logic is compatible with the _invest -> _switchAuto sequence in the public function triggering _invest
        } else {
            t.principal = t.principal.add(amount);
        }
        IMasterPoints(staker).updateStake(tid, userAddress, inv.principal);

        // update farm token pools with user amount invested
        for (uint256 s = 0; s < farmTokens.length; s++) {
            IFarmTokenPool(farmTokensPool).stake(farmTokens[s], tid, userAddress, amount);
        }
        emit Invest(userAddress, tid, cycle, amount);
    }

    function _redeem(uint256 tid) private returns (uint256) {
        UserInfo storage u = userInfo[msg.sender];
        Investment storage inv = userInvest[msg.sender][tid];
        uint256 principal = inv.principal;

        Tranche storage t = tranches[tid];
        u.balance = u.balance.add(principal);
        t.principal = t.principal.sub(principal);

        IMasterPoints(staker).updateStake(tid, msg.sender, 0);
        inv.principal = 0;
        emit Redeem(msg.sender, tid, cycle, principal);
        return principal;
    }

    function redeemDirect() public checkNotActive checkNotAuto nonReentrant {
        _updateInvest(msg.sender);
        for (uint256 i = 0; i < tranches.length; i++) {
            uint256 amount = _redeem(i);
            UserInfo storage u = userInfo[msg.sender];
            u.balance = u.balance.sub(amount);
            _safeUnwrap(msg.sender, amount);
            emit Withdraw(msg.sender, amount);
        }
    }

    function redeemDirectPartial(uint256 tid) public checkNotActive checkNotAuto nonReentrant {
        _updateInvest(msg.sender);
        uint256 amount = _redeem(tid);
        UserInfo storage u = userInfo[msg.sender];
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant {
        _updateInvest(msg.sender); // here if the auto=false the updateInvest adds investment to balance so we can withdraw
        require(amount > 0, "E14");
        UserInfo storage u = userInfo[msg.sender];
        require(amount <= u.balance, "E13");
        u.balance = u.balance.sub(amount);
        _safeUnwrap(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function start() public checkNoPendingStrategyWithdrawal {
        if (cycle > 0) {
            TrancheSnapshot memory snapshot = trancheSnapshots[cycle - 1][0];
            require(block.timestamp >= snapshot.stopAt.add(investmentWindow), "E23");
        }
        _startCycle();
    }

    function _startCycle() internal checkNotActive {
        for (uint256 i = 0; i < tranches.length; i++) {
            require(tranches[i].principal.add(tranches[i].autoPrincipal) >= 0, "E22");
        }
        uint256 total = 0;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche memory t = tranches[i];
            total = total.add(t.principal).add(t.autoPrincipal);
        }
        IStrategyToken(strategy).deposit(total);
        actualStartAt = block.timestamp;
        active = true;
        for (uint256 i = 0; i < tranches.length; i++) {
            Tranche storage t = tranches[i];
            t.autoValid = t.principal == 0 ? t.principal.add(t.autoPrincipal) : t.autoPrincipal;
            emit TrancheStart(i, cycle, t.principal.add(t.autoPrincipal));
        }
        IMasterPoints(staker).start(block.number.add(duration.div(3)));
    }

    function _stopCycle(address[] memory _strategyAddresses) internal {
        _processExit(_strategyAddresses);
        active = false;
        cycle++;
        IMasterPoints(staker).next(cycle);
    }

    struct ProcessExitVariables {
        uint256 totalPrincipal;
        uint256 totalYield;
        uint256 seniorYield;
        uint256 seniorYieldDistribution;
        uint256 seniorProportion;
        uint256 seniorIndex;
        uint256 juniorIndex;
    }

    function withdrawFromStrategy(
        address[] memory _strategyAddresses
    ) internal returns (uint256 totalWant, uint256[] memory afterFarmTokens) {
        uint256 beforeWant = IERC20Upgradeable(currency).balanceOf(address(this)); // dont need to touch aacum fees
        afterFarmTokens = new uint256[](farmTokens.length);
        IStrategyToken(strategy).withdraw(_strategyAddresses);
        totalWant = IERC20Upgradeable(currency).balanceOf(address(this)).sub(beforeWant);
        for (uint256 i = 0; i < farmTokens.length; i++) {
            afterFarmTokens[i] = IERC20Upgradeable(farmTokens[i]).balanceOf((address(this)));
        }
    }

    function _calculateExchangeRate(
        uint256 current,
        uint256 base,
        uint256 percentage_scale
    ) internal pure returns (uint256) {
        if (current == base) {
            return percentage_scale;
        } else if (current > base) {
            return percentage_scale.add((current - base).mul(percentage_scale).div(base));
        } else {
            return percentage_scale.sub((base - current).mul(percentage_scale).div(base));
        }
    }

    function _processExit(address[] memory _strategyAddresses) internal {
        require(tranches.length == 2, "E17");

        (uint256 total, uint256[] memory farmTokensAmts) = withdrawFromStrategy(_strategyAddresses);
        uint256 restCapital = total; // total is the amount of currency after withdrawal
        uint256 cycleExchangeRate;
        uint256 capital;
        uint256 principal;
        uint256 shortage;

        ProcessExitVariables memory p;
        ITrancheYieldCurve.YieldDistrib memory y;
        p.seniorIndex = 0;
        Tranche storage senior = tranches[p.seniorIndex];
        p.juniorIndex = tranches.length - 1;
        Tranche storage junior = tranches[p.juniorIndex];
        p.totalPrincipal = senior.principal.add(senior.autoPrincipal).add(junior.principal).add(junior.autoPrincipal);
        if (restCapital >= p.totalPrincipal) {
            p.totalYield = restCapital.sub(p.totalPrincipal);
        } else {
            p.totalYield = 0;
        }

        // senior
        principal = senior.principal + senior.autoPrincipal;
        capital = 0;
        p.seniorProportion = principal.mul(PERCENTAGE_SCALE).div(p.totalPrincipal);

        y = ITrancheYieldCurve(trancheYieldCurve).getYieldDistribution(
            p.seniorProportion,
            p.totalPrincipal,
            restCapital,
            duration,
            farmTokensAmts
        );

        p.seniorYield = y.fixedSeniorYield;

        if (p.seniorYield > p.totalYield) {
            shortage = p.seniorYield.sub(p.totalYield);
            shortage = shortage < junior.principal.add(junior.autoPrincipal)
                ? shortage
                : junior.principal.add(junior.autoPrincipal); // we dont' need to leave positive amount in junior because autorestart of cycles is not enabled
        }

        uint256 all = principal.add(p.seniorYield);
        bool satisfied = restCapital >= all;

        // If restCapital >= senior principal + seniorYield we just subtract this senior volume from restCapital.
        if (!satisfied) {
            capital = restCapital;
            restCapital = 0;
        } else {
            capital = all;
            restCapital = restCapital.sub(all); // this is now can be distributed to junior tranche
        }

        uint256 fee;
        // here we take the fee on the capital (principal + yield)
        if (senior.principalFee) {
            fee = satisfied ? capital.mul(senior.fee).div(PERCENTAGE_PARAM_SCALE) : 0;
        } else if (capital > principal) {
            // here we take fee on the yield only
            fee = (capital.sub(principal)).mul(senior.fee).div(PERCENTAGE_PARAM_SCALE);
        }
        if (fee > 0) {
            producedFee = producedFee.add(fee);
            capital = capital.sub(fee);
        }

        cycleExchangeRate = _calculateExchangeRate(capital, principal, PERCENTAGE_SCALE);

        trancheSnapshots[cycle][p.seniorIndex] = TrancheSnapshot({
            principal: principal,
            capital: capital,
            validPercent: senior.validPercent,
            rate: cycleExchangeRate,
            fee: senior.fee,
            startAt: actualStartAt,
            stopAt: block.timestamp
        });

        senior.principal = 0;

        senior.autoPrincipal = senior.autoValid.mul(cycleExchangeRate).div(PERCENTAGE_SCALE).add(
            senior.autoPrincipal > senior.autoValid ? senior.autoPrincipal.sub(senior.autoValid) : 0
        );

        emit TrancheSettle(p.seniorIndex, cycle, principal, capital, cycleExchangeRate);

        principal = junior.principal + junior.autoPrincipal;
        capital = restCapital;
        if (p.seniorYield > p.totalYield) {
            if (capital >= shortage) {
                capital = capital.sub(shortage);
            } else {
                capital = 0;
            }
        }
        if (junior.principalFee && capital != 0) {
            // apply principal fee only if capital !=0 after paying senior
            fee = capital.mul(junior.fee).div(PERCENTAGE_PARAM_SCALE);
        } else if (capital > principal && shortage == 0) {
            fee = capital.sub(principal).mul(junior.fee).div(PERCENTAGE_PARAM_SCALE);
        } // apply fee only if junior shortage is  zero
        if (fee > 0) {
            producedFee = producedFee.add(fee);
            capital = capital.sub(fee);
        }
        cycleExchangeRate = _calculateExchangeRate(capital, principal, PERCENTAGE_SCALE);
        trancheSnapshots[cycle][p.juniorIndex] = TrancheSnapshot({
            principal: principal,
            capital: capital,
            validPercent: junior.validPercent,
            rate: cycleExchangeRate,
            fee: junior.fee,
            startAt: actualStartAt,
            stopAt: block.timestamp
        });

        junior.principal = 0;
        junior.autoPrincipal = junior.autoValid.mul(cycleExchangeRate).div(PERCENTAGE_SCALE).add(
            junior.autoPrincipal > junior.autoValid ? junior.autoPrincipal.sub(junior.autoValid) : 0
        );

        // send tokens to the farm rewards contract
        for (uint256 t = 0; t < farmTokens.length; t++) {
            IERC20Upgradeable(farmTokens[t]).approve(farmTokensPool, y.seniorFarmYield[t].add(y.juniorFarmYield[t]));
            IFarmTokenPool(farmTokensPool).sendRewards(farmTokens[t], 0, y.seniorFarmYield[t]);
            IFarmTokenPool(farmTokensPool).sendRewards(farmTokens[t], 1, y.juniorFarmYield[t]);
        }
        emit TrancheSettle(p.juniorIndex, cycle, principal, capital, cycleExchangeRate);
    }

    function stop() public checkActive nonReentrant {
        require(block.timestamp >= actualStartAt + duration, "E18");
        _stopCycle(zeroAddressArr);
    }

    function balanceOf(address account) external view returns (uint256 balance, uint256 invested) {
        UserInfo memory u = userInfo[account];
        uint256 capital;
        uint256 principal;
        balance = u.balance;
        for (uint i = 0; i < tranches.length; i++) {
            Investment memory inv = userInvest[account][i];
            principal = inv.principal;
            if (principal == 0) {
                continue;
            }
            if (u.isAuto) {
                for (uint j = inv.cycle; j < cycle; j++) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[j][i];
                    capital = principal.mul(snapshot.rate).div(PERCENTAGE_SCALE);
                    principal = capital;
                }
            } else {
                if (inv.cycle < cycle) {
                    TrancheSnapshot memory snapshot = trancheSnapshots[inv.cycle][i];
                    capital = principal.mul(snapshot.rate).div(PERCENTAGE_SCALE);
                    principal = capital;
                }
            }
            invested = invested.add(principal);
        }
    }

    /************ Admin functions ****************/

    function setDuration(uint256 _duration) public onlyGovernor {
        duration = _duration;
    }

    function setDevAddress(address _devAddress) public onlyGovernor {
        devAddress = _devAddress;
    }

    function setInvestmentWindow(uint256 _window) public onlyGovernor {
        require(investmentWindow > 0, "E24");
        investmentWindow = _window;
    }

    function stopAndUpdateStrategiesAndRatios(
        address[] calldata _strategies,
        uint256[] calldata _ratios,
        address[] calldata toAdd,
        address[] calldata toPause,
        address[] calldata newTokens
    ) public checkActive nonReentrant onlyTimelock {
        require(block.timestamp >= actualStartAt + duration, "E18");
        _stopCycle(zeroAddressArr);
        IFarmTokenPool(farmTokensPool).changeRewardTokens(toAdd, toPause, newTokens);
        farmTokens = newTokens;
        IMultiStrategyToken(strategy).updateStrategiesAndRatios(_strategies, _ratios);
    }

    function emergencyStop(address[] memory _strategyAddresses) public checkActive nonReentrant onlyGovernor {
        pendingStrategyWithdrawal = IMultiStrategyToken(strategy).strategyCount() - _strategyAddresses.length;
        _stopCycle(_strategyAddresses);
    }

    function recoverFund(address[] memory _strategyAddresses) public checkNotActive nonReentrant onlyGovernor {
        require(pendingStrategyWithdrawal > 0, "E19");
        pendingStrategyWithdrawal -= _strategyAddresses.length;
        uint256 before = IERC20Upgradeable(currency).balanceOf(address(this));
        IStrategyToken(strategy).withdraw(_strategyAddresses);
        uint256 total = IERC20Upgradeable(currency).balanceOf(address(this)).sub(before);
        _safeUnwrap(devAddress, total);
    }

    function setStaker(address _staker) public onlyGovernor {
        staker = _staker;
    }

    function setStrategy(address _strategy) public onlyGovernor {
        strategy = _strategy;
    }

    function setTrancheYieldCurve(address _trancheYieldCurve) public onlyGovernor {
        trancheYieldCurve = _trancheYieldCurve;
    }

    function withdrawFee(uint256 amount) public {
        require(amount <= producedFee, "E20");
        producedFee = producedFee.sub(amount);
        if (devAddress != address(0)) {
            _safeUnwrap(devAddress, amount);
        }
    }

    function transferFeeToStaking(uint256 _amount, address _pool) public onlyGovernor {
        require(_amount > 0, "E14");
        IERC20Upgradeable(currency).safeApprove(_pool, _amount);
        IFeeRewards(_pool).sendRewards(_amount);
    }

    function _safeUnwrap(address to, uint256 amount) internal {
        if (currency == wNative) {
            IWETH(currency).withdraw(amount);
            AddressUpgradeable.sendValue(payable(to), amount);
        } else {
            IERC20Upgradeable(currency).safeTransfer(to, amount);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ICore.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract CoreRefUpgradeable is PausableUpgradeable {
    event CoreUpdate(address indexed _core);

    ICore private _core;

    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    function initialize(address core_) public onlyInitializing {
        _core = ICore(core_);
        PausableUpgradeable.__Pausable_init_unchained();
    }

    modifier onlyGovernor() {
        require(_core.isGovernor(msg.sender), "CoreRef::onlyGovernor: Caller is not a governor");
        _;
    }

    modifier onlyGuardian() {
        require(_core.isGuardian(msg.sender), "CoreRef::onlyGuardian: Caller is not a guardian");
        _;
    }

    modifier onlyGuardianOrGovernor() {
        require(
            _core.isGovernor(msg.sender) || _core.isGuardian(msg.sender),
            "CoreRef::onlyGuardianOrGovernor: Caller is not a guardian or governor"
        );
        _;
    }

    modifier onlyMultistrategy() {
        require(_core.isMultistrategy(msg.sender), "CoreRef::onlyMultistrategy: Caller is not a multistrategy");
        _;
    }

    modifier onlyTimelock() {
        require(_core.hasRole(TIMELOCK_ROLE, msg.sender), "CoreRef::onlyTimelock: Caller is not a timelock");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(_core.hasRole(role, msg.sender), "CoreRef::onlyRole: Not permit");
        _;
    }

    modifier onlyRoleOrOpenRole(bytes32 role) {
        require(
            _core.hasRole(role, address(0)) || _core.hasRole(role, msg.sender),
            "CoreRef::onlyRoleOrOpenRole: Not permit"
        );
        _;
    }

    modifier onlyNonZeroAddress(address targetAddress) {
        require(targetAddress != address(0), "address cannot be set to 0x0");
        _;
    }

    modifier onlyNonZeroAddressArray(address[] calldata targetAddresses) {
        for (uint256 i = 0; i < targetAddresses.length; i++) {
            require(targetAddresses[i] != address(0), "address cannot be set to 0x0");
        }
        _;
    }

    function setCore(address core_) external onlyGovernor {
        _core = ICore(core_);
        emit CoreUpdate(core_);
    }

    function pause() public onlyGuardianOrGovernor {
        _pause();
    }

    function unpause() public onlyGuardianOrGovernor {
        _unpause();
    }

    function core() public view returns (ICore) {
        return _core;
    }
}