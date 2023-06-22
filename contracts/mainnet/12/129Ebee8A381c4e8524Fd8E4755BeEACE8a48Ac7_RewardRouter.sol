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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
library SafeMath {
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
pragma solidity ^0.8.9;

contract GovernableUpgradeable {
    address public gov;

    event GovChanged(address indexed oldGov, address indexed newGov);


    function __Governable_init() internal {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        emit GovChanged(gov, _gov);
        gov = _gov;
    }
}

pragma solidity ^0.8.9;

import "./IVault.sol";

interface ILpManager {
    function plpToken() external view returns (address);

    function usdp() external view returns (address);

    function vault() external view returns (IVault);

    function getAumInUsdp(bool maximise) external view returns (uint256);

    function lastAddedAt(address _account) external returns (uint256);

    function addLiquidity(
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external returns (uint256);

    function addLiquidityForAccount(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external returns (uint256);

    function removeLiquidity(
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function removeLiquidityForAccount(
        address _account,
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function cooldownDuration() external view returns (uint256);

    /* Owner function */
    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external;

    function setCooldownDuration(uint256 _cooldownDuration) external;
}

pragma solidity ^0.8.9;

import "./IVaultUtils.sol";
import "../protocol/libraries/TokenConfiguration.sol";
import "../protocol/libraries/PositionInfo.sol";

interface IVault {
    /* Variables Getter */
    function priceFeed() external view returns (address);

    function vaultUtils() external view returns (address);

    function usdp() external view returns (address);

    function hasDynamicFees() external view returns (bool);

    function poolAmounts(address token) external view returns (uint256);

    function minProfitTime() external returns (uint256);

    function inManagerMode() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    /* Write Functions */
    function buyUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function swapWithoutFees(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function claimFund(
        address _collateralToken,
        address _account,
        bool _isLong,
        uint256 _amountOutUsd,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        uint256 _feeUsd
    ) external;

    function decreasePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutUsd,
        uint256 _feeUsd
    ) external returns (uint256);

    function liquidatePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _positionSize,
        uint256 _positionMargin,
        bool _isLong
    ) external;

    function addCollateral(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _feeToken
    ) external;

    function removeCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken
    ) external;

    /* Goivernance function */
    function setWhitelistCaller(address caller, bool val) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setConfigToken(
        address _token,
        uint8 _tokenDecimals,
        uint64 _minProfitBps,
        uint128 _tokenWeight,
        uint128 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setPriceFeed(address _priceFeed) external;

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setBorrowingRate(
        uint256 _borrowingRateInterval,
        uint256 _borrowingRateFactor,
        uint256 _stableBorrowingRateFactor
    ) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    /* End Goivernance function */

    /* View Functions */
    function getBidPrice(address _token) external view returns (uint256);

    function getAskPrice(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function isStableToken(address _token) external view returns (bool);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256 i) external view returns (address);

    function isWhitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function borrowingRateInterval() external view returns (uint256);

    function borrowingRateFactor() external view returns (uint256);

    function stableBorrowingRateFactor() external view returns (uint256);

    function lastBorrowingRateTimes(
        address _token
    ) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function cumulativeBorrowingRates(
        address _token
    ) external view returns (uint256);

    function getNextBorrowingRate(
        address _token
    ) external view returns (uint256);

    function getBorrowingFee(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getSwapFee(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    // pool info
    function usdpAmount(address _token) external view returns (uint256);

    function getTargetUsdpAmount(
        address _token
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdpDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getTokenConfiguration(
        address _token
    ) external view returns (TokenConfiguration.Data memory);

    function getPositionInfo(
        address _account,
        address _indexToken,
        bool _isLong
    ) external view returns (PositionInfo.Data memory);

    function getAvailableReservedAmount(
        address _collateralToken
    ) external view returns (uint256);

    function adjustDecimalToUsd(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function adjustDecimalToToken(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function tokenToUsdMinWithAdjustment(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function usdToTokenMinWithAdjustment(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);
}

pragma solidity ^0.8.9;

interface IVaultUtils {
    function getBuyUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSellUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getBorrowingFee(
        address _collateralToken,
        uint256 _size,
        uint256 _entryBorrowingRate
    ) external view returns (uint256);

    function updateCumulativeBorrowingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);
}

pragma solidity ^0.8.9;

library PositionInfo {
    struct Data {
        uint256 reservedAmount;
        uint128 entryBorrowingRates;
        address collateralToken;
    }

    function setEntryBorrowingRates(
        Data storage _self,
        uint256 _rate
    ) internal {
        _self.entryBorrowingRates = uint128(_rate);
    }

    function addReservedAmount(Data storage _self, uint256 _amount) internal {
        _self.reservedAmount = _self.reservedAmount + _amount;
    }

    function subReservedAmount(
        Data storage _self,
        uint256 _amount
    ) internal returns (uint256) {
        // Position already decreased on process chain -> no point in reverting
        // require(
        //    _amount <= _self.reservedAmount,
        //    "Vault: reservedAmount exceeded"
        // );
        if (_amount >= _self.reservedAmount) {
            _amount = _self.reservedAmount;
        }
        _self.reservedAmount = _self.reservedAmount - _amount;
        return _amount;
    }

    function setCollateralToken(Data storage _self, address _token) internal {
        if (_self.collateralToken == address(0)) {
            _self.collateralToken = _token;
            return;
        }
        require(_self.collateralToken == _token);
    }
}

pragma solidity ^0.8.9;

library TokenConfiguration {
    struct Data {
        // packable storage
        bool isWhitelisted;
        uint8 tokenDecimals;
        bool isStableToken;
        bool isShortableToken;
        uint64 minProfitBasisPoints;
        uint128 tokenWeight;
        // maxUsdpAmounts allows setting a max amount of USDP debt for a token
        uint128 maxUsdpAmount;
    }

    function getIsWhitelisted(Data storage _self) internal view returns (bool) {
        return _self.isWhitelisted;
    }

    function getTokenDecimals(
        Data storage _self
    ) internal view returns (uint8) {
        return _self.tokenDecimals;
    }

    function getTokenWeight(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.tokenWeight);
    }

    function getIsStableToken(Data storage _self) internal view returns (bool) {
        return _self.isStableToken;
    }

    function getIsShortableToken(
        Data storage _self
    ) internal view returns (bool) {
        return _self.isShortableToken;
    }

    function getMinProfitBasisPoints(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.minProfitBasisPoints);
    }

    function getMaxUsdpAmount(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.maxUsdpAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRewardRouter {
    function feePlpTracker() external view returns (address);

    function stakedPlpTracker() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRewardTracker {
    function depositBalances(
        address _account,
        address _depositToken
    ) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(
        address _account
    ) external view returns (uint256);

    function cumulativeRewards(
        address _account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(
        address _account
    ) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(
        address _account
    ) external view returns (uint256);

    function transferredCumulativeRewards(
        address _account
    ) external view returns (uint256);

    function cumulativeRewardDeductions(
        address _account
    ) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(
        address _account,
        uint256 _amount
    ) external;

    function setTransferredCumulativeRewards(
        address _account,
        uint256 _amount
    ) external;

    function setCumulativeRewardDeductions(
        address _account,
        uint256 _amount
    ) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(
        address _account
    ) external view returns (uint256);

    function getCombinedAverageStakedAmount(
        address _account
    ) external view returns (uint256);
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IRewardRouter.sol";
import "./interfaces/IVester.sol";
import "../token/interface/IMintable.sol";
import "../token/interface/IWETH.sol";
import "../interfaces/ILpManager.sol";
import "../access/GovernableUpgradeable.sol";

contract RewardRouter is
    IRewardRouter,
    ReentrancyGuardUpgradeable,
    GovernableUpgradeable
{
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;
    address public weth;

    address public posi;
    address public esPosi;
    address public bnPosi;

    address public plp; // posi Liquidity Provider token

    address public stakedPosiTracker;
    address public bonusPosiTracker;
    address public feePosiTracker;

    address public override stakedPlpTracker;
    address public override feePlpTracker;

    address public plpManager;

    address public posiVester;
    address public plpVester;

    mapping(address => address) public pendingReceivers;

    event StakePosi(address account, address token, uint256 amount);
    event UnstakePosi(address account, address token, uint256 amount);

    event StakePlp(address account, uint256 amount);
    event UnstakePlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    struct ParamToken {
        address weth;
        address posi;
        address esPosi;
        address bnPosi;
        address plp;
    }

    function initialize(
        ParamToken memory _paramToken,
        address _stakedPosiTracker,
        address _bonusPosiTracker,
        address _feePosiTracker,
        address _feePlpTracker,
        address _stakedPlpTracker,
        address _plpManager,
        address _posiVester,
        address _plpVester
    ) external initializer {
        __ReentrancyGuard_init();
        __Governable_init();

        weth = _paramToken.weth;
        posi = _paramToken.posi;
        esPosi = _paramToken.esPosi;
        bnPosi = _paramToken.bnPosi;
        plp = _paramToken.plp;

        stakedPosiTracker = _stakedPosiTracker;
        bonusPosiTracker = _bonusPosiTracker;
        feePosiTracker = _feePosiTracker;
        feePlpTracker = _feePlpTracker;
        stakedPlpTracker = _stakedPlpTracker;
        plpManager = _plpManager;
        posiVester = _posiVester;
        plpVester = _plpVester;
    }

    // to help users who accidentally send their tokens to this contract
    // only gov can withdraw tokens
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        IERC20Upgradeable(_token).safeTransfer(_account, _amount);
    }

    function batchStakePosiForAccount(
        address[] memory _accounts,
        uint256[] memory _amounts
    ) external nonReentrant onlyGov {
        address _posi = posi;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakePosi(msg.sender, _accounts[i], _posi, _amounts[i]);
        }
    }

    function stakePosiForAccount(
        address _account,
        uint256 _amount
    ) external nonReentrant onlyGov {
        _stakePosi(msg.sender, _account, posi, _amount);
    }

    function isInitialized() external view returns (bool) {
        return _getInitializedVersion() > 0;
    }

    /// @notice stake posi
    /// @param _amount the amount to stake
    function stakePosi(uint256 _amount) external nonReentrant {
        _stakePosi(msg.sender, msg.sender, posi, _amount);
    }

    /// @notice stake esPOSI
    /// @param _amount the amount to stake
    function stakeEsPosi(uint256 _amount) external nonReentrant {
        _stakePosi(msg.sender, msg.sender, esPosi, _amount);
    }

    /// @notice un stake posi
    /// @param _amount the amount to unstake
    function unstakePosi(uint256 _amount) external nonReentrant {
        _unstakePosi(msg.sender, posi, _amount, true);
    }

    /// @notice un stake esPOSI
    /// @param _amount the amount to unstake
    function unstakeEsPosi(uint256 _amount) external nonReentrant {
        _unstakePosi(msg.sender, esPosi, _amount, true);
    }

    /// @notice stake _token, mint plp, then auto stake to the pool
    /// @param _token the token to purchase plp
    /// @param _amount the amount to purchase plp
    /// @param _minUsdp min usdp, avoid slippage
    /// @param _minPlp min plp, avoid slippage
    function mintAndStakePlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 plpAmount = ILpManager(plpManager).addLiquidityForAccount(
            account,
            account,
            _token,
            _amount,
            _minUsdp,
            _minPlp
        );
        IRewardTracker(feePlpTracker).stakeForAccount(
            account,
            account,
            plp,
            plpAmount
        );
        IRewardTracker(stakedPlpTracker).stakeForAccount(
            account,
            account,
            feePlpTracker,
            plpAmount
        );

        emit StakePlp(account, plpAmount);

        return plpAmount;
    }

    function mintAndStakePlpETH(
        uint256 _minUsdp,
        uint256 _minPlp
    ) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20Upgradeable(weth).approve(plpManager, msg.value);

        address account = msg.sender;
        uint256 plpAmount = ILpManager(plpManager).addLiquidityForAccount(
            address(this),
            account,
            weth,
            msg.value,
            _minUsdp,
            _minPlp
        );

        IRewardTracker(feePlpTracker).stakeForAccount(
            account,
            account,
            plp,
            plpAmount
        );
        IRewardTracker(stakedPlpTracker).stakeForAccount(
            account,
            account,
            feePlpTracker,
            plpAmount
        );

        emit StakePlp(account, plpAmount);

        return plpAmount;
    }


    /// @notice stake _token, mint plp, then auto stake to the pool
    /// @param plpAmount the amount of PLP to stake
    function stakePlp(
        uint256 plpAmount
    ) external nonReentrant returns (uint256) {
        require(plpAmount > 0, "RewardRouter: invalid _amount");
        address account = msg.sender;

        IRewardTracker(feePlpTracker).stakeForAccount(
            account,
            account,
            plp,
            plpAmount
        );

        IRewardTracker(stakedPlpTracker).stakeForAccount(
            account,
            account,
            feePlpTracker,
            plpAmount
        );

        emit StakePlp(account, plpAmount);

        return plpAmount;
    }

    /// @notice stake _token, mint plp, then auto stake to the pool
    /// @param _token the token to purchase plp
    /// @param _amount the amount to purchase plp
    /// @param _minUsdp min usdp, avoid slippage
    /// @param _minPlp min plp, avoid slippage
    function mintPlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 plpAmount = ILpManager(plpManager).addLiquidityForAccount(
            account,
            account,
            _token,
            _amount,
            _minUsdp,
            _minPlp
        );
        emit StakePlp(account, plpAmount);

        return plpAmount;
    }

    function mintPlpETH(
        uint256 _minUsdp,
        uint256 _minPlp
    ) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20Upgradeable(weth).approve(plpManager, msg.value);

        address account = msg.sender;
        uint256 plpAmount = ILpManager(plpManager).addLiquidityForAccount(
            address(this),
            account,
            weth,
            msg.value,
            _minUsdp,
            _minPlp
        );

        emit StakePlp(account, plpAmount);
        return plpAmount;
    }

    /// @notice redeem plp and unstake PLP
    /// @param _tokenOut receive token
    /// @param _plpAmount plp amount
    /// @param _minOut min amount out
    /// @param _receiver receive address
    function unstakeAndRedeemPlp(
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external nonReentrant returns (uint256) {
        require(_plpAmount > 0, "RewardRouter: invalid _plpAmount");

        address account = msg.sender;
        IRewardTracker(stakedPlpTracker).unstakeForAccount(
            account,
            feePlpTracker,
            _plpAmount,
            account
        );
        IRewardTracker(feePlpTracker).unstakeForAccount(
            account,
            plp,
            _plpAmount,
            account
        );
        uint256 amountOut = ILpManager(plpManager).removeLiquidityForAccount(
            account,
            _tokenOut,
            _plpAmount,
            _minOut,
            _receiver
        );

        emit UnstakePlp(account, _plpAmount);

        return amountOut;
    }

    /// @notice unstakePlp
    /// @param _plpAmount plp amount
    function unstakePlp(
        uint256 _plpAmount
    ) external nonReentrant {
        require(_plpAmount > 0, "RewardRouter: invalid _plpAmount");

        address account = msg.sender;
        IRewardTracker(stakedPlpTracker).unstakeForAccount(
            account,
            feePlpTracker,
            _plpAmount,
            account
        );
        IRewardTracker(feePlpTracker).unstakeForAccount(
            account,
            plp,
            _plpAmount,
            account
        );
        emit UnstakePlp(account, _plpAmount);
    }

    /// @notice redeem plp
    /// @param _tokenOut receive token
    /// @param _plpAmount plp amount
    /// @param _minOut min amount out
    /// @param _receiver receive address
    function redeemPlp(
        address _tokenOut,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external nonReentrant returns (uint256) {
        require(_plpAmount > 0, "RewardRouter: invalid _plpAmount");

        address account = msg.sender;

        uint256 amountOut = ILpManager(plpManager).removeLiquidityForAccount(
            account,
            _tokenOut,
            _plpAmount,
            _minOut,
            _receiver
        );

        emit UnstakePlp(account, _plpAmount);

        return amountOut;
    }

    /// @notice redeem plp
    /// @param _plpAmount the Plp amount to redeem
    /// @param _minOut min amount out
    /// @param _receiver receive address
    function redeemPlpETH(
        uint256 _plpAmount,
        uint256 _minOut,
        address payable _receiver
    ) external nonReentrant returns (uint256) {
        require(_plpAmount > 0, "RewardRouter: invalid _plpAmount");

        address account = msg.sender;

        uint256 amountOut = ILpManager(plpManager).removeLiquidityForAccount(
            account,
            weth,
            _plpAmount,
            _minOut,
            address(this)
        );

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakePlp(account, _plpAmount);

        return amountOut;
    }

    /// @notice claim rewards
    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feePosiTracker).claimForAccount(account, account);
        IRewardTracker(feePlpTracker).claimForAccount(account, account);
        IRewardTracker(stakedPosiTracker).claimForAccount(account, account);
        IRewardTracker(stakedPlpTracker).claimForAccount(account, account);
    }

    /// @notice claim esPosi
    function claimEsPosi() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedPosiTracker).claimForAccount(account, account);
        IRewardTracker(stakedPlpTracker).claimForAccount(account, account);
    }

    /// @notice claim fees
    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feePosiTracker).claimForAccount(account, account);
        IRewardTracker(feePlpTracker).claimForAccount(account, account);
    }

    /// @notice compound rewards
    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    /// @notice cound for an account. only Gov
    /// @param _account the account to compound
    function compoundForAccount(
        address _account
    ) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimPosi,
        bool _shouldStakePosi,
        bool _shouldClaimEsPosi,
        bool _shouldStakeEsPosi,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 posiAmount = 0;
        if (_shouldClaimPosi) {
            uint256 posiAmount0 = IVester(posiVester).claimForAccount(
                account,
                account
            );
            uint256 posiAmount1 = IVester(plpVester).claimForAccount(
                account,
                account
            );
            posiAmount = posiAmount0.add(posiAmount1);
        }

        if (_shouldStakePosi && posiAmount > 0) {
            _stakePosi(account, account, posi, posiAmount);
        }

        uint256 esPosiAmount = 0;
        if (_shouldClaimEsPosi) {
            uint256 esPosiAmount0 = IRewardTracker(stakedPosiTracker)
                .claimForAccount(account, account);
            uint256 esPosiAmount1 = IRewardTracker(stakedPlpTracker)
                .claimForAccount(account, account);
            esPosiAmount = esPosiAmount0.add(esPosiAmount1);
        }

        if (_shouldStakeEsPosi && esPosiAmount > 0) {
            _stakePosi(account, account, esPosi, esPosiAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnPosiAmount = IRewardTracker(bonusPosiTracker)
                .claimForAccount(account, account);
            if (bnPosiAmount > 0) {
                IRewardTracker(feePosiTracker).stakeForAccount(
                    account,
                    account,
                    bnPosi,
                    bnPosiAmount
                );
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker(feePosiTracker).claimForAccount(
                    account,
                    address(this)
                );
                uint256 weth1 = IRewardTracker(feePlpTracker).claimForAccount(
                    account,
                    address(this)
                );

                uint256 wethAmount = weth0.add(weth1);
                IWETH(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feePosiTracker).claimForAccount(
                    account,
                    account
                );
                IRewardTracker(feePlpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(
        address[] memory _accounts
    ) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(
            IERC20Upgradeable(posiVester).balanceOf(msg.sender) == 0,
            "RewardRouter: sender has vested tokens"
        );
        require(
            IERC20Upgradeable(plpVester).balanceOf(msg.sender) == 0,
            "RewardRouter: sender has vested tokens"
        );

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(
            IERC20Upgradeable(posiVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );
        require(
            IERC20Upgradeable(plpVester).balanceOf(_sender) == 0,
            "RewardRouter: sender has vested tokens"
        );

        address receiver = msg.sender;
        require(
            pendingReceivers[_sender] == receiver,
            "RewardRouter: transfer not signalled"
        );
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedPosi = IRewardTracker(stakedPosiTracker).depositBalances(
            _sender,
            posi
        );
        if (stakedPosi > 0) {
            _unstakePosi(_sender, posi, stakedPosi, false);
            _stakePosi(_sender, receiver, posi, stakedPosi);
        }

        uint256 stakedEsPosi = IRewardTracker(stakedPosiTracker)
            .depositBalances(_sender, esPosi);
        if (stakedEsPosi > 0) {
            _unstakePosi(_sender, esPosi, stakedEsPosi, false);
            _stakePosi(_sender, receiver, esPosi, stakedEsPosi);
        }

        uint256 stakedBnPosi = IRewardTracker(feePosiTracker).depositBalances(
            _sender,
            bnPosi
        );
        if (stakedBnPosi > 0) {
            IRewardTracker(feePosiTracker).unstakeForAccount(
                _sender,
                bnPosi,
                stakedBnPosi,
                _sender
            );
            IRewardTracker(feePosiTracker).stakeForAccount(
                _sender,
                receiver,
                bnPosi,
                stakedBnPosi
            );
        }

        uint256 esPosiBalance = IERC20Upgradeable(esPosi).balanceOf(_sender);
        if (esPosiBalance > 0) {
            IERC20Upgradeable(esPosi).transferFrom(_sender, receiver, esPosiBalance);
        }

        uint256 plpAmount = IRewardTracker(feePlpTracker).depositBalances(
            _sender,
            plp
        );
        if (plpAmount > 0) {
            IRewardTracker(stakedPlpTracker).unstakeForAccount(
                _sender,
                feePlpTracker,
                plpAmount,
                _sender
            );
            IRewardTracker(feePlpTracker).unstakeForAccount(
                _sender,
                plp,
                plpAmount,
                _sender
            );

            IRewardTracker(feePlpTracker).stakeForAccount(
                _sender,
                receiver,
                plp,
                plpAmount
            );
            IRewardTracker(stakedPlpTracker).stakeForAccount(
                receiver,
                receiver,
                feePlpTracker,
                plpAmount
            );
        }

        IVester(posiVester).transferStakeValues(_sender, receiver);
        IVester(plpVester).transferStakeValues(_sender, receiver);
    }

    /* PRIVATE FUNCTIONS */

    function _validateReceiver(address _receiver) private view {
        require(
            IRewardTracker(stakedPosiTracker).averageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: stakedPosiTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedPosiTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedPosiTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(bonusPosiTracker).averageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: bonusPosiTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(bonusPosiTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: bonusPosiTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feePosiTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feePosiTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feePosiTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feePosiTracker.cumulativeRewards > 0"
        );

        require(
            IVester(posiVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: posiVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(posiVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: posiVester.transferredCumulativeRewards > 0"
        );

        require(
            IRewardTracker(stakedPlpTracker).averageStakedAmounts(_receiver) ==
                0,
            "RewardRouter: stakedPlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(stakedPlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: stakedPlpTracker.cumulativeRewards > 0"
        );

        require(
            IRewardTracker(feePlpTracker).averageStakedAmounts(_receiver) == 0,
            "RewardRouter: feePlpTracker.averageStakedAmounts > 0"
        );
        require(
            IRewardTracker(feePlpTracker).cumulativeRewards(_receiver) == 0,
            "RewardRouter: feePlpTracker.cumulativeRewards > 0"
        );

        require(
            IVester(plpVester).transferredAverageStakedAmounts(_receiver) == 0,
            "RewardRouter: posiVester.transferredAverageStakedAmounts > 0"
        );
        require(
            IVester(plpVester).transferredCumulativeRewards(_receiver) == 0,
            "RewardRouter: posiVester.transferredCumulativeRewards > 0"
        );

        require(
            IERC20Upgradeable(posiVester).balanceOf(_receiver) == 0,
            "RewardRouter: posiVester.balance > 0"
        );
        require(
            IERC20Upgradeable(plpVester).balanceOf(_receiver) == 0,
            "RewardRouter: plpVester.balance > 0"
        );
    }

    function _compound(address _account) private {
        _compoundPosi(_account);
        _compoundPlp(_account);
    }

    function _compoundPosi(address _account) private {
        uint256 esPosiAmount = IRewardTracker(stakedPosiTracker)
            .claimForAccount(_account, _account);
        if (esPosiAmount > 0) {
            _stakePosi(_account, _account, esPosi, esPosiAmount);
        }

        uint256 bnPosiAmount = IRewardTracker(bonusPosiTracker).claimForAccount(
            _account,
            _account
        );
        if (bnPosiAmount > 0) {
            IRewardTracker(feePosiTracker).stakeForAccount(
                _account,
                _account,
                bnPosi,
                bnPosiAmount
            );
        }
    }

    function _compoundPlp(address _account) private {
        uint256 esPosiAmount = IRewardTracker(stakedPlpTracker).claimForAccount(
            _account,
            _account
        );
        if (esPosiAmount > 0) {
            _stakePosi(_account, _account, esPosi, esPosiAmount);
        }
    }

    function _stakePosi(
        address _fundingAccount,
        address _account,
        address _token,
        uint256 _amount
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedPosiTracker).stakeForAccount(
            _fundingAccount,
            _account,
            _token,
            _amount
        );
        IRewardTracker(bonusPosiTracker).stakeForAccount(
            _account,
            _account,
            stakedPosiTracker,
            _amount
        );
        IRewardTracker(feePosiTracker).stakeForAccount(
            _account,
            _account,
            bonusPosiTracker,
            _amount
        );

        emit StakePosi(_account, _token, _amount);
    }

    function _unstakePosi(
        address _account,
        address _token,
        uint256 _amount,
        bool _shouldReduceBnPosi
    ) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedPosiTracker).stakedAmounts(
            _account
        );

        IRewardTracker(feePosiTracker).unstakeForAccount(
            _account,
            bonusPosiTracker,
            _amount,
            _account
        );
        IRewardTracker(bonusPosiTracker).unstakeForAccount(
            _account,
            stakedPosiTracker,
            _amount,
            _account
        );
        IRewardTracker(stakedPosiTracker).unstakeForAccount(
            _account,
            _token,
            _amount,
            _account
        );

        if (_shouldReduceBnPosi) {
            uint256 bnPosiAmount = IRewardTracker(bonusPosiTracker)
                .claimForAccount(_account, _account);
            if (bnPosiAmount > 0) {
                IRewardTracker(feePosiTracker).stakeForAccount(
                    _account,
                    _account,
                    bnPosi,
                    bnPosiAmount
                );
            }

            uint256 stakedBnPosi = IRewardTracker(feePosiTracker)
                .depositBalances(_account, bnPosi);
            if (stakedBnPosi > 0) {
                uint256 reductionAmount = stakedBnPosi.mul(_amount).div(
                    balance
                );
                IRewardTracker(feePosiTracker).unstakeForAccount(
                    _account,
                    bnPosi,
                    reductionAmount,
                    _account
                );
                IMintable(bnPosi).burn(_account, reductionAmount);
            }
        }

        emit UnstakePosi(_account, _token, _amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

}

pragma solidity ^0.8.9;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}