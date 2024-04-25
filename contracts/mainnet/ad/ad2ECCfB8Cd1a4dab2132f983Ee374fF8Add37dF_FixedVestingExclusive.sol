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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
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

pragma solidity ^0.8.19;

interface IFixedVestingFactoryV2 {
  event VestingCreated(address indexed vesting, uint index);

  function owner() external view returns (address);

  function beacon() external view returns (address);

  function allVestingsLength() external view returns (uint256);

  function allVestings(uint256) external view returns (address);

  function createVesting(
    address _token,
    address _stable,
    address _projectOwner,
    uint256 _tokenPrice,
    uint256 _lastRefundAt,
    uint256[] calldata _datetime,
    uint256[] calldata _ratio_d2
  ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IFixedVestingV2 {
  function init(
    address _token,
    address _stable,
    address _projectOwner,
    uint256 _tokenPrice,
    uint256 _lastRefundAt,
    uint256[] calldata _datetime,
    uint256[] calldata _ratio_d2
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

import '../../interface/IFixedVestingFactoryV2.sol';
import '../../interface/IFixedVestingV2.sol';

contract FixedVestingExclusive is Initializable, PausableUpgradeable, IFixedVestingV2 {
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  uint256 public sold;
  uint256 public tokenPrice; // Use stable decimal. If refund is done on another chain, use 18 as decimal
  uint256 public lastRefundAt; // epoch

  address[] public buyers;

  address public token;
  address public projectOwner;
  address public stable; // ignore if refund is done on another chain

  IFixedVestingFactoryV2 public factory;

  struct ProjectPayment {
    uint256 tokenReturned;
    uint256 stablePaid;
    bool isPaid;
  }

  struct Detail {
    uint256 datetime;
    uint256 ratio_d2;
  }

  struct RefundDetail {
    address buyer;
    uint256 stableRefunded;
  }

  struct Bought {
    uint128 buyerIndex;
    uint128 completed_d2; // in percent (2 decimal)
    uint256 purchased;
    uint256 claimed;
    uint256 stableRefunded;
  }

  RefundDetail[] internal refunds;
  mapping(address => uint256) internal refundIndex;

  Detail[] public vestings;
  ProjectPayment public projectPayment;
  mapping(address => Bought) public invoice;

  event Claim(
    address buyer,
    uint256 completed_d2,
    uint256 purchased,
    uint256 claimed,
    uint256 stableRefunded,
    uint256 claimedAt
  );
  event Refund(
    address buyer,
    uint256 completed_d2,
    uint256 purchased,
    uint256 claimed,
    uint256 stableRefunded,
    uint256 refundedAt
  );
  event PayToProject(address projectOwner, uint256 tokenReturned, uint256 stablePaid, uint256 paidAt);

  modifier onlyFactoryOwner() {
    require(_msgSender() == factory.owner(), '!owner');
    _;
  }

  /**
   * @dev Initialize vesting token distribution
   * @param _token Token project address
   * @param _stable Stable token address
   * @param _tokenPrice Token price (in stable decimal)
   * @param _refundPeriodInDays Refund period in days
   * @param _projectOwner Project owner address
   * @param _datetime Vesting datetime (epoch)
   * @param _ratio_d2 Vesting ratio in percent (decimal 2)
   */
  function init(
    address _token,
    address _stable,
    address _projectOwner,
    uint256 _tokenPrice,
    uint256 _refundPeriodInDays,
    uint256[] calldata _datetime,
    uint256[] calldata _ratio_d2
  ) external override initializer {
    factory = IFixedVestingFactoryV2(_msgSender());

    _setToken(_token);
    _setStable(_stable);
    _setTokenPrice(_tokenPrice);
    _setLastRefundAt(_datetime[0] + (_refundPeriodInDays * 86400));
    _setProjectOwner(_projectOwner);
    _newVesting(_datetime, _ratio_d2);
  }

  /**
   * @dev Get length of buyer
   */
  function buyerLength() external view virtual returns (uint256 length) {
    length = buyers.length;
  }

  /**
   * @dev Get length of vesting
   */
  function vestingLength() public view virtual returns (uint256 length) {
    length = vestings.length;
    if (length > 0) length -= 1;
  }

  /**
   * @dev Get length of buyer refund
   */
  function refundLength() public view virtual returns (uint256 length) {
    length = refunds.length;
  }

  /**
   * @dev Get refund payload
   */
  function refundPayload() external view virtual returns (bytes memory payloadValue) {
    payloadValue = abi.encode(projectPayment.stablePaid, refunds);
    if (block.timestamp <= lastRefundAt || stable != address(0)) payloadValue = new bytes(0);
  }

  /**
   * @dev Get vesting runnning
   */
  function vestingRunning() public view virtual returns (uint256 round, uint256 totalPercent_d2) {
    uint256 vestingSize = vestingLength();
    uint256 total;
    for (uint256 i = 1; i <= vestingSize; ++i) {
      Detail memory temp = vestings[i];
      total += temp.ratio_d2;

      if (
        (i < vestingSize && temp.datetime <= block.timestamp && block.timestamp <= vestings[i + 1].datetime) ||
        (i == vestingSize && block.timestamp >= temp.datetime)
      ) {
        round = i;
        totalPercent_d2 = total;
        break;
      }
    }
  }

  /**
   * @dev Calculate total ratio
   */
  function totalRatio() public view virtual returns (uint256 total) {
    uint256 vestingSize = vestingLength();
    for (uint256 i = 1; i <= vestingSize; ++i) {
      Detail memory temp = vestings[i];
      total += temp.ratio_d2;
    }
  }

  /**
   * @dev Calculate stable token amount have to be paid
   */
  function _calculateStableAmount(uint256 tokenAmount) internal view virtual returns (uint256) {
    return (tokenAmount * tokenPrice) / (10 ** IERC20MetadataUpgradeable(token).decimals());
  }

  /**
   * @dev Set token project
   * @param _token Token project address
   */
  function _setToken(address _token) internal virtual {
    token = _token;
  }

  /**
   * @dev Set stable project
   * @param _stable Stable project address
   */
  function _setStable(address _stable) internal virtual {
    stable = _stable;
  }

  /**
   * @dev Set last refund project
   * @param _lastRefundAt Last refund project
   */
  function _setLastRefundAt(uint256 _lastRefundAt) internal virtual {
    require(_lastRefundAt > block.timestamp, 'bad');
    lastRefundAt = _lastRefundAt;
  }

  /**
   * @dev Set token pice project
   * @param _tokenPrice Token project address
   */
  function _setTokenPrice(uint256 _tokenPrice) internal virtual {
    require(_tokenPrice > 0, 'bad');
    tokenPrice = _tokenPrice;
  }

  /**
   * @dev Set project owner to receive returned token & stable
   * @param _projectOwner Token project address
   */
  function _setProjectOwner(address _projectOwner) internal virtual {
    projectOwner = _projectOwner;
  }

  /**
   * @dev Insert new vestings
   * @param _datetime Vesting datetime
   * @param _ratio_d2 Vesting ratio in percent (decimal 2)
   */
  function _newVesting(uint256[] calldata _datetime, uint256[] calldata _ratio_d2) internal virtual {
    require(_datetime.length == _ratio_d2.length, 'misslength');

    if (vestingLength() == 0) vestings.push();

    for (uint256 i = 0; i < _datetime.length; ++i) {
      if (i != _datetime.length - 1) require(_datetime[i] < _datetime[i + 1], 'bad');
      vestings.push(Detail(_datetime[i], _ratio_d2[i]));
    }
  }

  /**
   * @dev Insert new vestings
   * @param _datetime Vesting datetime
   * @param _ratio_d2 Vesting ratio in percent (decimal 2)
   */
  function newVesting(uint256[] calldata _datetime, uint256[] calldata _ratio_d2) external virtual onlyFactoryOwner {
    _newVesting(_datetime, _ratio_d2);
  }

  /**
   * @dev Update vestings datetime
   * @param _vestingRound Vesting round
   * @param _newDatetime new datetime in epoch
   */
  function updateVestingDatetimes(
    uint256[] calldata _vestingRound,
    uint256[] calldata _newDatetime
  ) external virtual onlyFactoryOwner {
    uint256 vestingSize = vestingLength();

    require(_vestingRound.length == _newDatetime.length && _vestingRound.length <= vestingSize, 'misslength');

    (uint256 round, ) = vestingRunning();

    for (uint256 i = 0; i < _vestingRound.length; ++i) {
      if (_vestingRound[i] > vestingSize || round >= _vestingRound[i]) continue;

      vestings[_vestingRound[i]].datetime = _newDatetime[i];
    }
  }

  /**
   * @dev Update vestings ratio
   * @param _vestingRound Vesting round
   * @param _newRatio_d2 New ratio in percent (decimal 2)
   */
  function updateVestingRatios(
    uint256[] calldata _vestingRound,
    uint256[] calldata _newRatio_d2
  ) external virtual onlyFactoryOwner {
    uint256 vestingSize = vestingLength();
    require(_vestingRound.length == _newRatio_d2.length && _vestingRound.length <= vestingSize, 'misslength');

    (uint256 round, ) = vestingRunning();

    for (uint256 i = 0; i < _vestingRound.length; ++i) {
      if (_vestingRound[i] > vestingSize || round >= _vestingRound[i]) continue;

      vestings[_vestingRound[i]].ratio_d2 = _newRatio_d2[i];
    }
  }

  /**
   * @dev Remove last vesting round
   */
  function removeLastVestingRound() external virtual onlyFactoryOwner {
    vestings.pop();
  }

  /**
   * @dev Insert new buyers & purchases
   * @param _buyer Buyer address
   * @param _purchased Buyer purchase
   */
  function newBuyers(address[] calldata _buyer, uint256[] calldata _purchased) external virtual onlyFactoryOwner {
    require(_buyer.length == _purchased.length && token != address(0) && tokenPrice > 0, 'misslength');

    uint256 soldTemp = sold;
    for (uint128 i = 0; i < _buyer.length; ++i) {
      if (_buyer[i] == address(0) || _purchased[i] == 0) continue;

      Bought memory temp = invoice[_buyer[i]];

      if (temp.purchased == 0) {
        invoice[_buyer[i]].buyerIndex = uint128(buyers.length);
        buyers.push(_buyer[i]);
      }

      invoice[_buyer[i]].purchased = temp.purchased + _purchased[i];
      soldTemp += _purchased[i];
    }

    sold = soldTemp;
    projectPayment.stablePaid = _calculateStableAmount(soldTemp);
  }

  /**
   * @dev Replace buyers address
   * @param _oldBuyer Old address
   * @param _newBuyer New purchase
   */
  function replaceBuyers(address[] calldata _oldBuyer, address[] calldata _newBuyer) external virtual onlyFactoryOwner {
    require(_oldBuyer.length == _newBuyer.length && buyers.length > 0, 'misslength');

    for (uint128 i = 0; i < _oldBuyer.length; ++i) {
      Bought memory temp = invoice[_oldBuyer[i]];

      if (temp.purchased == 0 || _oldBuyer[i] == address(0) || _newBuyer[i] == address(0)) continue;

      buyers[temp.buyerIndex] = _newBuyer[i];
      invoice[_newBuyer[i]] = temp;
      delete invoice[_oldBuyer[i]];

      uint256 refundOldBuyerIndex = refundIndex[_oldBuyer[i]];
      if (refunds.length == 0 || (refunds.length > 0 && refunds[refundOldBuyerIndex].buyer != _oldBuyer[i])) continue;

      refunds[refundOldBuyerIndex].buyer = _newBuyer[i];
      refundIndex[_newBuyer[i]] = refundOldBuyerIndex;
      delete refundIndex[_oldBuyer[i]];
    }
  }

  /**
   * @dev Remove buyers
   * @param _buyer Buyer address
   */
  function removeBuyers(address[] calldata _buyer) external virtual onlyFactoryOwner {
    require(buyers.length > 0 && token != address(0) && tokenPrice > 0, 'bad');

    uint256 soldTemp = sold;
    for (uint128 i = 0; i < _buyer.length; ++i) {
      Bought memory temp = invoice[_buyer[i]];

      if (temp.purchased == 0 || _buyer[i] == address(0)) continue;

      soldTemp -= temp.purchased;

      address addressToMove = buyers[buyers.length - 1];

      buyers[temp.buyerIndex] = addressToMove;
      invoice[addressToMove].buyerIndex = temp.buyerIndex;

      buyers.pop();
      delete invoice[_buyer[i]];
    }

    sold = soldTemp;
    projectPayment.stablePaid = _calculateStableAmount(soldTemp);
  }

  /**
   * @dev Replace buyers purchase
   * @param _buyer Buyer address
   * @param _newPurchased new purchased
   */
  function replacePurchases(
    address[] calldata _buyer,
    uint256[] calldata _newPurchased
  ) external virtual onlyFactoryOwner {
    require(
      _buyer.length == _newPurchased.length && buyers.length > 0 && token != address(0) && tokenPrice > 0,
      'misslength'
    );

    uint256 soldTemp = sold;
    for (uint128 i = 0; i < _buyer.length; ++i) {
      Bought memory temp = invoice[_buyer[i]];

      if (temp.purchased == 0 || temp.completed_d2 > 0 || _buyer[i] == address(0) || _newPurchased[i] == 0) continue;

      soldTemp = soldTemp - temp.purchased + _newPurchased[i];
      invoice[_buyer[i]].purchased = _newPurchased[i];
    }

    sold = soldTemp;
    projectPayment.stablePaid = _calculateStableAmount(soldTemp);
  }

  /**
   * @dev Token claim
   */
  function claimToken() external virtual whenNotPaused {
    (uint256 round, uint256 totalPercent_d2) = vestingRunning();

    address buyer = _msgSender();
    Bought memory temp = invoice[buyer];

    require(round > 0 && token != address(0) && totalRatio() == 10000, 'bad');
    require(temp.purchased > 0, '!buyer');
    require(temp.completed_d2 < totalPercent_d2, 'claimed');
    require(temp.stableRefunded == 0, 'refunded');

    uint256 amountToClaim;
    if (temp.completed_d2 == 0) {
      amountToClaim = (temp.purchased * totalPercent_d2) / 10000;
    } else {
      amountToClaim = ((temp.claimed * totalPercent_d2) / temp.completed_d2) - temp.claimed;
    }

    require(
      IERC20MetadataUpgradeable(token).balanceOf(address(this)) >= amountToClaim && amountToClaim > 0,
      'insufficient'
    );

    invoice[buyer].completed_d2 = uint128(totalPercent_d2);
    invoice[buyer].claimed = temp.claimed + amountToClaim;

    IERC20MetadataUpgradeable(token).safeTransfer(buyer, amountToClaim);

    emit Claim(
      buyer,
      totalPercent_d2,
      temp.purchased,
      temp.claimed + amountToClaim,
      temp.stableRefunded,
      block.timestamp
    );
  }

  /**
   * @dev Token refund
   */
  function refund() external virtual whenNotPaused {
    address buyer = _msgSender();
    Bought memory temp = invoice[buyer];

    require(block.timestamp <= lastRefundAt, 'over');
    require(temp.purchased > 0 && token != address(0) && tokenPrice > 0 && totalRatio() == 10000, 'bad');
    require(temp.claimed == 0, 'claimed');
    require(temp.stableRefunded == 0, 'refunded');

    uint256 tokenReturned = temp.purchased - temp.claimed;
    uint256 stablePaid = _calculateStableAmount(tokenReturned);

    refundIndex[buyer] = refunds.length;
    refunds.push(RefundDetail(buyer, stablePaid));

    invoice[buyer].stableRefunded = stablePaid;

    projectPayment.tokenReturned += tokenReturned;
    projectPayment.stablePaid -= stablePaid;

    // refund stable if possible
    if (stable != address(0)) {
      require(
        IERC20MetadataUpgradeable(stable).balanceOf(address(this)) >= stablePaid && stablePaid > 0,
        'insufficient'
      );
      IERC20MetadataUpgradeable(stable).safeTransfer(buyer, stablePaid);
    }

    emit Refund(buyer, temp.completed_d2, temp.purchased, temp.claimed, temp.stableRefunded, block.timestamp);
  }

  /**
   * @dev Token payment to project owner
   */
  function payToProject() external virtual whenNotPaused {
    require(block.timestamp > lastRefundAt && totalRatio() == 10000, '!claimable');
    require(_msgSender() == projectOwner, '!projectOwner');

    ProjectPayment memory temp = projectPayment;
    require(!temp.isPaid, 'paid');

    projectPayment.isPaid = true;

    require(
      token != address(0) && IERC20MetadataUpgradeable(token).balanceOf(address(this)) >= temp.tokenReturned,
      'insufficient'
    );

    // return token
    if (temp.tokenReturned > 0) {
      IERC20MetadataUpgradeable(token).safeTransfer(projectOwner, temp.tokenReturned);
    }

    // pay stable if possible
    if (stable != address(0)) {
      if (temp.stablePaid > 0) {
        require(IERC20MetadataUpgradeable(stable).balanceOf(address(this)) >= temp.stablePaid, 'insufficient');
        IERC20MetadataUpgradeable(stable).safeTransfer(projectOwner, temp.stablePaid);
      }
    }

    emit PayToProject(projectOwner, temp.tokenReturned, temp.stablePaid, block.timestamp);
  }

  /**
   * @dev Emergency condition to withdraw any token
   * @param _token Token address
   * @param _target Target address
   * @param _amount Amount to withdraw
   */
  function emergencyWithdraw(address _token, address _target, uint256 _amount) external virtual onlyFactoryOwner {
    require(_target != address(0), 'bad');

    uint256 contractBalance = uint256(IERC20MetadataUpgradeable(_token).balanceOf(address(this)));
    if (_amount > contractBalance) _amount = contractBalance;

    IERC20MetadataUpgradeable(_token).safeTransfer(_target, _amount);
  }

  /**
   * @dev Set token price project
   * @dev If refund is done on another chain, use 18 as default decimal
   * @dev Otherwise, use stable decimal
   * @param _tokenPrice Token project address
   */
  function setTokenPrice(uint256 _tokenPrice) external virtual onlyFactoryOwner {
    _setTokenPrice(_tokenPrice);
  }

  /**
   * @dev Set stable project
   * @param _stable Token project address
   */
  function setStable(address _stable) external virtual onlyFactoryOwner {
    _setStable(_stable);
  }

  /**
   * @dev Set lastRefundAt project
   * @param _lastRefundAt Last refund project address
   */
  function setLastRefundAt(uint256 _lastRefundAt) external virtual onlyFactoryOwner {
    _setLastRefundAt(_lastRefundAt);
  }

  /**
   * @dev Set token project
   * @param _token Token project address
   */
  function setToken(address _token) external virtual onlyFactoryOwner {
    require(_token != address(0), 'bad');
    _setToken(_token);
  }

  /**
   * @dev Set project owner to receive returned token & stable
   * @param _projectOwner Token project address
   */
  function setProjectOwner(address _projectOwner) external virtual onlyFactoryOwner {
    require(_projectOwner != address(0), 'bad');
    _setProjectOwner(_projectOwner);
  }

  /**
   * @dev Pause vesting activity
   */
  function togglePause() external virtual onlyFactoryOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }
}