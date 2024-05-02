// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
interface IERC20Permit {
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
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library Constants {
    uint256 internal constant YEAR_IN_SECONDS = 365 days;
    uint256 internal constant BASE = 1e18;
    uint256 internal constant MAX_FEE_PER_ANNUM = 0.05e18; // 5% max in base
    uint256 internal constant MAX_SWAP_PROTOCOL_FEE = 0.01e18; // 1% max in base
    uint256 internal constant MAX_TOTAL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MAX_P2POOL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MIN_TIME_BETWEEN_EARLIEST_REPAY_AND_EXPIRY =
        1 days;
    uint256 internal constant MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE = 1 days;
    uint256 internal constant SEQUENCER_GRACE_PERIOD = 1 hours;
    uint256 internal constant MIN_UNSUBSCRIBE_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_UNSUBSCRIBE_GRACE_PERIOD = 14 days;
    uint256 internal constant MIN_CONVERSION_GRACE_PERIOD = 1 days;
    uint256 internal constant MIN_REPAYMENT_GRACE_PERIOD = 1 days;
    uint256 internal constant LOAN_EXECUTION_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD =
        30 days;
    uint256 internal constant MIN_TIME_UNTIL_FIRST_DUE_DATE = 1 days;
    uint256 internal constant MIN_TIME_BETWEEN_DUE_DATES = 7 days;
    uint256 internal constant MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE = 60 seconds;
    uint256 internal constant MAX_ARRANGER_FEE = 0.5e18; // 50% max in base
    uint256 internal constant LOAN_TERMS_UPDATE_COOL_OFF_PERIOD = 15 minutes;
    uint256 internal constant MAX_REPAYMENT_SCHEDULE_LENGTH = 20;
    uint256 internal constant SINGLE_WRAPPER_MIN_MINT = 1000; // in wei
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
    error UnregisteredVault();
    error InvalidDelegatee();
    error InvalidSender();
    error InvalidFee();
    error InsufficientSendAmount();
    error NoOracle();
    error InvalidOracleAnswer();
    error InvalidOracleDecimals();
    error InvalidOracleVersion();
    error InvalidAddress();
    error InvalidArrayLength();
    error InvalidQuote();
    error OutdatedQuote();
    error InvalidOffChainSignature();
    error InvalidOffChainMerkleProof();
    error InvalidCollUnlock();
    error InvalidAmount();
    error UnknownOnChainQuote();
    error NeitherTokenIsGOHM();
    error NoLpTokens();
    error ZeroReserve();
    error IncorrectGaugeForLpToken();
    error InvalidGaugeIndex();
    error AlreadyStaked();
    error InvalidWithdrawAmount();
    error InvalidBorrower();
    error OutsideValidRepayWindow();
    error InvalidRepayAmount();
    error ReclaimAmountIsZero();
    error UnregisteredGateway();
    error NonWhitelistedOracle();
    error NonWhitelistedCompartment();
    error NonWhitelistedCallback();
    error NonWhitelistedToken();
    error LtvHigherThanMax();
    error InsufficientVaultFunds();
    error InvalidInterestRateFactor();
    error InconsistentUnlockTokenAddresses();
    error InvalidEarliestRepay();
    error InvalidNewMinNumOfSigners();
    error AlreadySigner();
    error InvalidArrayIndex();
    error InvalidSignerRemoveInfo();
    error InvalidSendAmount();
    error TooSmallLoanAmount();
    error DeadlinePassed();
    error WithdrawEntered();
    error DuplicateAddresses();
    error OnChainQuoteAlreadyAdded();
    error OffChainQuoteHasBeenInvalidated();
    error Uninitialized();
    error InvalidRepaymentScheduleLength();
    error FirstDueDateTooCloseOrPassed();
    error InvalidGracePeriod();
    error UnregisteredLoanProposal();
    error NotInSubscriptionPhase();
    error NotInUnsubscriptionPhase();
    error InsufficientBalance();
    error InsufficientFreeSubscriptionSpace();
    error BeforeEarliestUnsubscribe();
    error InconsistentLastLoanTermsUpdateTime();
    error InvalidActionForCurrentStatus();
    error FellShortOfTotalSubscriptionTarget();
    error InvalidRollBackRequest();
    error UnsubscriptionAmountTooLarge();
    error InvalidSubscriptionRange();
    error InvalidMaxTotalSubscriptions();
    error OutsideConversionTimeWindow();
    error OutsideRepaymentTimeWindow();
    error NoDefault();
    error LoanIsFullyRepaid();
    error RepaymentIdxTooLarge();
    error AlreadyClaimed();
    error AlreadyConverted();
    error InvalidDueDates();
    error LoanTokenDueIsZero();
    error WaitForLoanTermsCoolOffPeriod();
    error ZeroConversionAmount();
    error InvalidNewOwnerProposal();
    error CollateralMustBeCompartmentalized();
    error InvalidCompartmentForToken();
    error InvalidSignature();
    error InvalidUpdate();
    error CannotClaimOutdatedStatus();
    error DelegateReducedBalance();
    error FundingPoolAlreadyExists();
    error InvalidLender();
    error NonIncreasingTokenAddrs();
    error NonIncreasingNonFungibleTokenIds();
    error TransferToWrappedTokenFailed();
    error TransferFromWrappedTokenFailed();
    error StateAlreadySet();
    error ReclaimableCollateralAmountZero();
    error InvalidSwap();
    error InvalidUpfrontFee();
    error InvalidOracleTolerance();
    error ReserveRatiosSkewedFromOraclePrice();
    error SequencerDown();
    error GracePeriodNotOver();
    error LoanExpired();
    error NoDsEth();
    error TooShortTwapInterval();
    error TooLongTwapInterval();
    error TwapExceedsThreshold();
    error Reentrancy();
    error TokenNotStuck();
    error InconsistentExpTransferFee();
    error InconsistentExpVaultBalIncrease();
    error DepositLockActive();
    error DisallowedSubscriptionLockup();
    error IncorrectLoanAmount();
    error Disabled();
    error CannotRemintUnlessZeroSupply();
    error TokensStillMissingFromWrapper();
    error OnlyMintFromSingleTokenWrapper();
    error NonMintableTokenState();
    error NoTokensTransferred();
    error TokenAlreadyCountedInWrapper();
    error TokenNotOwnedByWrapper();
    error TokenDoesNotBelongInWrapper(address tokenAddr, uint256 tokenId);
    error InvalidMintAmount();
    error QuoteViolatesPolicy();
    error AlreadyPublished();
    error PolicyAlreadySet();
    error NoPolicyToDelete();
    error InvalidTenorBounds();
    error InvalidLtvBounds();
    error InvalidLoanPerCollBounds();
    error InvalidMinApr();
    error NoPolicy();
    error InvalidMinFee();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";

interface IMysoTokenManager {
    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams);

    function processP2PCreateVault(
        uint256 numRegisteredVaults,
        address vaultCreator,
        address newLenderVaultAddr
    ) external;

    function processP2PCreateWrappedTokenForERC721s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PCreateWrappedTokenForERC20s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolDeposit(
        address fundingPool,
        address depositor,
        uint256 depositAmount,
        uint256 depositLockupDuration,
        uint256 transferFee
    ) external;

    function processP2PoolSubscribe(
        address fundingPool,
        address subscriber,
        address loanProposal,
        uint256 subscriptionAmount,
        uint256 subscriptionLockupDuration,
        uint256 totalSubscriptions,
        DataTypesPeerToPool.LoanTerms calldata loanTerms
    ) external;

    function processP2PoolLoanFinalization(
        address loanProposal,
        address fundingPool,
        address arranger,
        address borrower,
        uint256 grossLoanAmount,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolCreateLoanProposal(
        address fundingPool,
        address proposalCreator,
        address collToken,
        uint256 arrangerFee,
        uint256 numLoanProposals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPeer {
    struct Loan {
        // address of borrower
        address borrower;
        // address of coll token
        address collToken;
        // address of loan token
        address loanToken;
        // timestamp after which any portion of loan unpaid defaults
        uint40 expiry;
        // timestamp before which borrower cannot repay
        uint40 earliestRepay;
        // initial collateral amount of loan
        uint128 initCollAmount;
        // loan amount given
        uint128 initLoanAmount;
        // full repay amount at start of loan
        uint128 initRepayAmount;
        // amount repaid (loan token) up until current time
        // note: partial repayments are allowed
        uint128 amountRepaidSoFar;
        // amount reclaimed (coll token) up until current time
        // note: partial repayments are allowed
        uint128 amountReclaimedSoFar;
        // flag tracking if collateral has been unlocked by vault
        bool collUnlocked;
        // address of the compartment housing the collateral
        address collTokenCompartmentAddr;
    }

    struct QuoteTuple {
        // loan amount per one unit of collateral if no oracle
        // LTV in terms of the constant BASE (10 ** 18) if using oracle
        uint256 loanPerCollUnitOrLtv;
        // interest rate percentage in BASE (can be negative but greater than -BASE)
        // i.e. -100% < interestRatePct since repay amount of 0 is not allowed
        // also interestRatePctInBase is not annualized
        int256 interestRatePctInBase;
        // fee percentage,in BASE, which will be paid in upfront in collateral
        uint256 upfrontFeePctInBase;
        // length of the loan in seconds
        uint256 tenor;
    }

    struct GeneralQuoteInfo {
        // address of collateral token
        address collToken;
        // address of loan token
        address loanToken;
        // address of oracle (optional)
        address oracleAddr;
        // min loan amount (in loan token) prevent griefing attacks or
        // amounts lender feels isn't worth unlocking on default
        uint256 minLoan;
        // max loan amount (in loan token) if lender wants a cap
        uint256 maxLoan;
        // timestamp after which quote automatically invalidates
        uint256 validUntil;
        // time, in seconds, that loan cannot be exercised
        uint256 earliestRepayTenor;
        // address of compartment implementation (optional)
        address borrowerCompartmentImplementation;
        // will invalidate quote after one use
        // if false, will be a standing quote
        bool isSingleUse;
        // whitelist address (optional)
        address whitelistAddr;
        // flag indicating whether whitelistAddr refers to a single whitelisted
        // borrower or to a whitelist authority that can whitelist multiple addresses
        bool isWhitelistAddrSingleBorrower;
    }

    struct OnChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // array of quote parameters
        QuoteTuple[] quoteTuples;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
    }

    struct OffChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // root of the merkle tree, where the merkle tree encodes all QuoteTuples the lender accepts
        bytes32 quoteTuplesRoot;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
        // for invalidating multiple parallel quotes in one click
        uint256 nonce;
        // array of compact signatures from vault signers
        bytes[] compactSigs;
    }

    struct LoanRepayInstructions {
        // loan id being repaid
        uint256 targetLoanId;
        // repay amount after transfer fees in loan token
        uint128 targetRepayAmount;
        // expected transfer fees in loan token (=0 for tokens without transfer fee)
        // note: amount that borrower sends is targetRepayAmount + expectedTransferFee
        uint128 expectedTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // e.g., for using collateral to payoff debt via DEX
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
    }

    struct BorrowTransferInstructions {
        // amount of collateral sent
        uint256 collSendAmount;
        // sum of (i) protocol fee and (ii) transfer fees (if any) associated with sending any collateral to vault
        uint256 expectedProtocolAndVaultTransferFee;
        // transfer fees associated with sending any collateral to compartment (if used)
        uint256 expectedCompartmentTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // slippage protection if oracle price is too loose
        uint256 minLoanAmount;
        // e.g., for one-click leverage
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
        // any data needed by myso token manager
        bytes mysoTokenManagerData;
    }

    struct TransferInstructions {
        // collateral token receiver
        address collReceiver;
        // effective upfront fee in collateral tokens (vault or compartment)
        uint256 upfrontFee;
    }

    struct WrappedERC721TokenInfo {
        // address of the ERC721_TOKEN
        address tokenAddr;
        // array of ERC721_TOKEN ids
        uint256[] tokenIds;
    }

    struct WrappedERC20TokenInfo {
        // token addresse
        address tokenAddr;
        // token amounts
        uint256 tokenAmount;
    }

    struct OnChainQuoteInfo {
        // hash of on chain quote
        bytes32 quoteHash;
        // valid until timestamp
        uint256 validUntil;
    }

    enum WhitelistState {
        // not whitelisted
        NOT_WHITELISTED,
        // can be used as loan or collateral token
        ERC20_TOKEN,
        // can be be used as oracle
        ORACLE,
        // can be used as compartment
        COMPARTMENT,
        // can be used as callback contract
        CALLBACK,
        // can be used as loan or collateral token, but if collateral then must
        // be used in conjunction with a compartment (e.g., for stETH with possible
        // negative rebase that could otherwise affect other borrowers in the vault)
        ERC20_TOKEN_REQUIRING_COMPARTMENT,
        // can be used in conjunction with an ERC721 wrapper
        ERC721_TOKEN,
        // can be used as ERC721 wrapper contract
        ERC721WRAPPER,
        // can be used as ERC20 wrapper contract
        ERC20WRAPPER,
        // can be used as MYSO token manager contract
        MYSO_TOKEN_MANAGER,
        // can be used as quote policy manager contract
        QUOTE_POLICY_MANAGER
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPool {
    struct Repayment {
        // The loan token amount due for given period; initially, expressed in relative terms (100%=BASE), once
        // finalized in absolute terms (in loanToken)
        uint128 loanTokenDue;
        // The coll token amount that can be converted for given period; initially, expressed in relative terms w.r.t.
        // loanTokenDue (e.g., convert every 1 loanToken for 8 collToken), once finalized in absolute terms (in collToken)
        uint128 collTokenDueIfConverted;
        // Timestamp when repayment is due
        uint40 dueTimestamp;
    }

    struct LoanTerms {
        // Min subscription amount (in loan token) that the borrower deems acceptable
        uint128 minTotalSubscriptions;
        // Max subscription amount (in loan token) that the borrower deems acceptable
        uint128 maxTotalSubscriptions;
        // The number of collateral tokens the borrower pledges per loan token borrowed as collateral for default case
        uint128 collPerLoanToken;
        // Borrower who can finalize given loan proposal
        address borrower;
        // Array of scheduled repayments
        Repayment[] repaymentSchedule;
    }

    struct StaticLoanProposalData {
        // Factory address from which the loan proposal is created
        address factory;
        // Funding pool address that is associated with given loan proposal and from which loan liquidity can be
        // sourced
        address fundingPool;
        // Address of collateral token to be used for given loan proposal
        address collToken;
        // Address of arranger who can manage the loan proposal contract
        address arranger;
        // Address of whitelist authority who can manage the lender whitelist (optional)
        address whitelistAuthority;
        // Unsubscribe grace period (in seconds), i.e., after acceptance by borrower lenders can unsubscribe and
        // remove liquidity for this duration before being locked-in
        uint256 unsubscribeGracePeriod;
        // Conversion grace period (in seconds), i.e., lenders can exercise their conversion right between
        // [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
        uint256 conversionGracePeriod;
        // Repayment grace period (in seconds), i.e., borrowers can repay between
        // [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
        uint256 repaymentGracePeriod;
    }

    struct DynamicLoanProposalData {
        // Arranger fee charged on final loan amount, initially in relative terms (100%=BASE), and after finalization
        // in absolute terms (in loan token)
        uint256 arrangerFee;
        // The gross loan amount; initially this is zero and gets set once loan proposal gets accepted and finalized;
        // note that the borrower receives the gross loan amount minus any arranger and protocol fees
        uint256 grossLoanAmount;
        // Final collateral amount reserved for defaults; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForDefault;
        // Final collateral amount reserved for conversions; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForConversions;
        // Timestamp when the loan terms get accepted by borrower and after which they cannot be changed anymore
        uint256 loanTermsLockedTime;
        // Current repayment index, mapping to currently relevant repayment schedule element; note the
        // currentRepaymentIdx (initially 0) only ever gets incremented on repay
        uint256 currentRepaymentIdx;
        // Status of current loan proposal
        DataTypesPeerToPool.LoanStatus status;
        // Protocol fee, initially in relative terms (100%=BASE), and after finalization in absolute terms (in loan token);
        // note that the relative protocol fee is locked in at the time when the loan proposal is created
        uint256 protocolFee;
    }

    enum LoanStatus {
        WITHOUT_LOAN_TERMS,
        IN_NEGOTIATION,
        LOAN_TERMS_LOCKED,
        READY_TO_EXECUTE,
        ROLLBACK,
        LOAN_DEPLOYED,
        DEFAULTED
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Constants} from "../Constants.sol";
import {DataTypesPeerToPool} from "./DataTypesPeerToPool.sol";
import {Errors} from "../Errors.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IFundingPoolImpl} from "./interfaces/IFundingPoolImpl.sol";
import {ILoanProposalImpl} from "./interfaces/ILoanProposalImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

contract FundingPoolImpl is Initializable, ReentrancyGuard, IFundingPoolImpl {
    using SafeERC20 for IERC20Metadata;

    address public factory;
    address public depositToken;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public depositUnlockTime;
    mapping(address => uint256) public totalSubscriptions;
    mapping(address => mapping(address => uint256)) public subscriptionAmountOf;
    // note: earliest unsubscribe time is to prevent griefing loans through atomic flashborrow,
    // deposit, subscribe, lock, unsubscribe, and withdraw
    mapping(address => mapping(address => uint256))
        internal _earliestUnsubscribe;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _factory,
        address _depositToken
    ) external initializer {
        if (_factory == address(0) || _depositToken == address(0)) {
            revert Errors.InvalidAddress();
        }
        factory = _factory;
        depositToken = _depositToken;
    }

    function deposit(
        uint256 amount,
        uint256 transferFee,
        uint256 depositLockupDuration
    ) external nonReentrant {
        if (amount == 0) {
            revert Errors.InvalidSendAmount();
        }
        if (depositLockupDuration > 0) {
            uint256 _depositUnlockTime = depositUnlockTime[msg.sender];
            if (_depositUnlockTime < block.timestamp + depositLockupDuration) {
                depositUnlockTime[msg.sender] =
                    block.timestamp +
                    depositLockupDuration;
            }
        }
        address mysoTokenManager = IFactory(factory).mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PoolDeposit(
                address(this),
                msg.sender,
                amount,
                depositLockupDuration,
                transferFee
            );
        }
        address _depositToken = depositToken;
        uint256 preBal = IERC20Metadata(_depositToken).balanceOf(address(this));
        IERC20Metadata(_depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount + transferFee
        );
        uint256 postBal = IERC20Metadata(_depositToken).balanceOf(
            address(this)
        );
        if (postBal != preBal + amount) {
            revert Errors.InvalidSendAmount();
        }
        balanceOf[msg.sender] += amount;
        emit Deposited(msg.sender, amount, depositLockupDuration);
    }

    function withdraw(uint256 amount) external {
        uint256 _balanceOf = balanceOf[msg.sender];
        if (amount == 0 || amount > _balanceOf) {
            revert Errors.InvalidWithdrawAmount();
        }
        if (block.timestamp < depositUnlockTime[msg.sender]) {
            revert Errors.DepositLockActive();
        }
        unchecked {
            balanceOf[msg.sender] = _balanceOf - amount;
        }
        IERC20Metadata(depositToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function subscribe(
        address loanProposal,
        uint256 minSubscriptionAmount,
        uint256 maxSubscriptionAmount,
        uint256 subscriptionLockupDuration
    ) external nonReentrant {
        if (
            maxSubscriptionAmount == 0 ||
            minSubscriptionAmount > maxSubscriptionAmount
        ) {
            revert Errors.InvalidAmount();
        }
        address _factory = factory;
        if (!IFactory(_factory).isLoanProposal(loanProposal)) {
            revert Errors.UnregisteredLoanProposal();
        }
        if (!ILoanProposalImpl(loanProposal).canSubscribe()) {
            revert Errors.NotInSubscriptionPhase();
        }
        (, , , , address whitelistAuthority, , , ) = ILoanProposalImpl(
            loanProposal
        ).staticData();
        if (
            whitelistAuthority != address(0) &&
            !IFactory(_factory).isWhitelistedLender(
                whitelistAuthority,
                msg.sender
            )
        ) {
            revert Errors.InvalidLender();
        }
        uint256 _balanceOf = balanceOf[msg.sender];
        if (maxSubscriptionAmount > _balanceOf) {
            revert Errors.InsufficientBalance();
        }
        DataTypesPeerToPool.LoanTerms memory loanTerms = ILoanProposalImpl(
            loanProposal
        ).loanTerms();
        if (subscriptionLockupDuration > 0) {
            (
                ,
                ,
                ,
                ,
                ,
                ,
                DataTypesPeerToPool.LoanStatus status,

            ) = ILoanProposalImpl(loanProposal).dynamicData();
            if (status != DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED) {
                revert Errors.DisallowedSubscriptionLockup();
            }
        }
        uint256 _totalSubscriptions = totalSubscriptions[loanProposal];
        uint256 _freeSubscriptionSpace = loanTerms.maxTotalSubscriptions -
            _totalSubscriptions;
        if (_freeSubscriptionSpace < minSubscriptionAmount) {
            revert Errors.InsufficientFreeSubscriptionSpace();
        }
        uint256 effectiveSubscriptionAmount = maxSubscriptionAmount <
            _freeSubscriptionSpace
            ? maxSubscriptionAmount
            : _freeSubscriptionSpace;
        address mysoTokenManager = IFactory(factory).mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PoolSubscribe(
                address(this),
                msg.sender,
                loanProposal,
                effectiveSubscriptionAmount,
                subscriptionLockupDuration,
                _totalSubscriptions,
                loanTerms
            );
        }
        unchecked {
            // @dev: can't underflow due to previous `maxSubscriptionAmount > _balanceOf` check
            balanceOf[msg.sender] = _balanceOf - effectiveSubscriptionAmount;
        }
        totalSubscriptions[loanProposal] =
            _totalSubscriptions +
            effectiveSubscriptionAmount;
        subscriptionAmountOf[loanProposal][
            msg.sender
        ] += effectiveSubscriptionAmount;
        _earliestUnsubscribe[loanProposal][msg.sender] =
            block.timestamp +
            (
                subscriptionLockupDuration <
                    Constants.MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE
                    ? Constants.MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE
                    : subscriptionLockupDuration
            );
        emit Subscribed(
            msg.sender,
            loanProposal,
            effectiveSubscriptionAmount,
            subscriptionLockupDuration
        );
    }

    function unsubscribe(address loanProposal, uint256 amount) external {
        if (amount == 0) {
            revert Errors.InvalidAmount();
        }
        if (!IFactory(factory).isLoanProposal(loanProposal)) {
            revert Errors.UnregisteredLoanProposal();
        }
        if (!ILoanProposalImpl(loanProposal).canUnsubscribe()) {
            revert Errors.NotInUnsubscriptionPhase();
        }
        mapping(address => uint256)
            storage subscriptionAmountPerLender = subscriptionAmountOf[
                loanProposal
            ];
        if (amount > subscriptionAmountPerLender[msg.sender]) {
            revert Errors.UnsubscriptionAmountTooLarge();
        }
        mapping(address => uint256)
            storage earliestUnsubscribePerLender = _earliestUnsubscribe[
                loanProposal
            ];
        (
            ,
            ,
            ,
            ,
            ,
            ,
            DataTypesPeerToPool.LoanStatus status,

        ) = ILoanProposalImpl(loanProposal).dynamicData();
        if (
            status != DataTypesPeerToPool.LoanStatus.ROLLBACK &&
            block.timestamp < earliestUnsubscribePerLender[msg.sender]
        ) {
            revert Errors.BeforeEarliestUnsubscribe();
        }
        balanceOf[msg.sender] += amount;
        totalSubscriptions[loanProposal] -= amount;
        subscriptionAmountPerLender[msg.sender] -= amount;
        earliestUnsubscribePerLender[msg.sender] = 0;

        emit Unsubscribed(msg.sender, loanProposal, amount);
    }

    function executeLoanProposal(address loanProposal) external {
        address _factory = factory;
        if (!IFactory(_factory).isLoanProposal(loanProposal)) {
            revert Errors.UnregisteredLoanProposal();
        }

        (
            uint256 arrangerFee,
            uint256 grossLoanAmount,
            ,
            ,
            ,
            ,
            ,
            uint256 protocolFee
        ) = ILoanProposalImpl(loanProposal).dynamicData();
        DataTypesPeerToPool.LoanTerms memory loanTerms = ILoanProposalImpl(
            loanProposal
        ).loanTerms();
        if (
            block.timestamp + Constants.MIN_TIME_UNTIL_FIRST_DUE_DATE >
            loanTerms.repaymentSchedule[0].dueTimestamp
        ) {
            revert Errors.FirstDueDateTooCloseOrPassed();
        }
        ILoanProposalImpl(loanProposal).checkAndUpdateStatus();
        if (grossLoanAmount != totalSubscriptions[loanProposal]) {
            revert Errors.IncorrectLoanAmount();
        }
        IERC20Metadata(depositToken).safeTransfer(
            loanTerms.borrower,
            grossLoanAmount - arrangerFee - protocolFee
        );
        (, , , address arranger, , , , ) = ILoanProposalImpl(loanProposal)
            .staticData();

        address _depositToken = depositToken;
        if (arrangerFee > 0) {
            IERC20Metadata(_depositToken).safeTransfer(arranger, arrangerFee);
        }
        if (protocolFee > 0) {
            IERC20Metadata(_depositToken).safeTransfer(
                IFactory(factory).owner(),
                protocolFee
            );
        }

        emit LoanProposalExecuted(
            loanProposal,
            loanTerms.borrower,
            grossLoanAmount,
            arrangerFee,
            protocolFee
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFactory {
    event LoanProposalCreated(
        address indexed loanProposalAddr,
        address indexed fundingPool,
        address indexed sender,
        address collToken,
        uint256 arrangerFee,
        uint256 unsubscribeGracePeriod,
        uint256 numLoanProposals
    );
    event FundingPoolCreated(
        address indexed newFundingPool,
        address indexed depositToken,
        uint256 numFundingPools
    );
    event ProtocolFeeUpdated(uint256 oldProtocolFee, uint256 newProtocolFee);
    event LenderWhitelistStatusClaimed(
        address indexed whitelistAuthority,
        address indexed lender,
        uint256 whitelistedUntil
    );
    event LenderWhitelistUpdated(
        address indexed whitelistAuthority,
        address[] indexed lender,
        uint256 whitelistedUntil
    );
    event MysoTokenManagerUpdated(
        address oldTokenManager,
        address newTokenManager
    );

    /**
     * @notice Creates a new loan proposal
     * @param _fundingPool The address of the funding pool from which lenders are allowed to subscribe, and -if loan proposal is successful- from where loan amount is sourced
     * @param _collToken The address of collateral token to be provided by borrower
     * @param _whitelistAuthority The address of the whitelist authority that can manage the lender whitelist (optional)
     * @param _arrangerFee The relative arranger fee (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function createLoanProposal(
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Creates a new funding pool
     * @param _depositToken The address of the deposit token to be accepted by the given funding pool
     */
    function createFundingPool(address _depositToken) external;

    /**
     * @notice Sets the protocol fee
     * @dev Can only be called by the loan proposal factory owner
     * @param _newProtocolFee The given protocol fee; note that this amount must be smaller than Constants.MAX_P2POOL_PROTOCOL_FEE (<5%)
     */
    function setProtocolFee(uint256 _newProtocolFee) external;

    /**
     * @notice Allows user to claim whitelisted status
     * @param whitelistAuthority Address of whitelist authorithy
     * @param whitelistedUntil Timestamp until when user is whitelisted
     * @param compactSig Compact signature from whitelist authority
     * @param salt Salt to make signature unique
     */
    function claimLenderWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external;

    /**
     * @notice Allows a whitelist authority to set the whitelistedUntil state for a given lender
     * @dev Anyone can create their own whitelist, and borrowers can decide if and which whitelist they want to use
     * @param lenders Array of lender addresses
     * @param whitelistedUntil Timestamp until which lenders shall be whitelisted under given whitelist authority
     */
    function updateLenderWhitelist(
        address[] calldata lenders,
        uint256 whitelistedUntil
    ) external;

    /**
     * @notice Sets a new MYSO token manager contract
     * @dev Can only be called by registry owner
     * @param newTokenManager Address of the new MYSO token manager contract
     */
    function setMysoTokenManager(address newTokenManager) external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns the address of the funding pool implementation
     * @return The address of the funding pool implementation
     */
    function fundingPoolImpl() external view returns (address);

    /**
     * @notice Returns the address of the proposal implementation
     * @return The address of the proposal implementation
     */
    function loanProposalImpl() external view returns (address);

    /**
     * @notice Returns the address of a registered loan proposal
     * @param idx The index of the given loan proposal
     * @return The address of a registered loan proposal
     */
    function loanProposals(uint256 idx) external view returns (address);

    /**
     * @notice Returns the address of a registered funding pool
     * @param idx The index of the given funding pool
     * @return The address of a registered funding pool
     */
    function fundingPools(uint256 idx) external view returns (address);

    /**
     * @notice Returns flag whether given address is a registered loan proposal contract
     * @param addr The address to check if its a registered loan proposal
     * @return Flag indicating whether address is a registered loan proposal contract
     */
    function isLoanProposal(address addr) external view returns (bool);

    /**
     * @notice Returns flag whether given address is a registered funding pool contract
     * @param addr The address to check if its a registered funding pool
     * @return Flag indicating whether address is a registered funding pool contract
     */
    function isFundingPool(address addr) external view returns (bool);

    /**
     * @notice Returns the protocol fee
     * @return The protocol fee
     */
    function protocolFee() external view returns (uint256);

    /**
     * @notice Returns the address of the owner of this contract
     * @return The address of the owner of this contract
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Returns the address of the MYSO token manager
     * @return Address of the MYSO token manager contract
     */
    function mysoTokenManager() external view returns (address);

    /**
     * @notice Returns boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     * @param whitelistAuthority Addresses of the whitelist authority
     * @param lender Addresses of the lender
     * @return Boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     */
    function isWhitelistedLender(
        address whitelistAuthority,
        address lender
    ) external view returns (bool);

    /**
     * @notice Returns the number of loan proposals created
     * @return Number of loan proposals created
     */
    function numLoanProposals() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IFundingPoolImpl {
    event Deposited(
        address user,
        uint256 amount,
        uint256 depositLockupDuration
    );
    event Withdrawn(address user, uint256 amount);
    event Subscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount,
        uint256 subscriptionLockupDuration
    );
    event Unsubscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount
    );
    event LoanProposalExecuted(
        address indexed loanProposal,
        address indexed borrower,
        uint256 grossLoanAmount,
        uint256 arrangerFee,
        uint256 protocolFee
    );

    /**
     * @notice Initializes funding pool
     * @param _factory Address of the factory contract spawning the given funding pool
     * @param _depositToken Address of the deposit token for the given funding pool
     */
    function initialize(address _factory, address _depositToken) external;

    /**
     * @notice function allows users to deposit into funding pool
     * @param amount amount to deposit
     * @param transferFee this accounts for any transfer fee token may have (e.g. paxg token)
     * @param depositLockupDuration the duration for which the deposit shall be locked (optional for tokenomics)
     */
    function deposit(
        uint256 amount,
        uint256 transferFee,
        uint256 depositLockupDuration
    ) external;

    /**
     * @notice function allows users to withdraw from funding pool
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice function allows users from funding pool to subscribe as lenders to a proposal
     * @param loanProposal address of the proposal to which user wants to subscribe
     * @param minAmount the desired minimum subscription amount
     * @param maxAmount the desired maximum subscription amount
     * @param subscriptionLockupDuration the duration for which the subscription shall be locked (optional for tokenomics)
     */
    function subscribe(
        address loanProposal,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 subscriptionLockupDuration
    ) external;

    /**
     * @notice function allows subscribed lenders to unsubscribe from a proposal
     * @dev there is a cooldown period after subscribing to mitigate possible griefing attacks
     * of subscription followed by quick unsubscription
     * @param loanProposal address of the proposal to which user wants to unsubscribe
     * @param amount amount of subscription removed
     */
    function unsubscribe(address loanProposal, uint256 amount) external;

    /**
     * @notice function allows execution of a proposal
     * @param loanProposal address of the proposal executed
     */
    function executeLoanProposal(address loanProposal) external;

    /**
     * @notice function returns factory address
     */
    function factory() external view returns (address);

    /**
     * @notice function returns address of deposit token for pool
     */
    function depositToken() external view returns (address);

    /**
     * @notice function returns balance deposited into pool
     * note: balance is tracked only through using deposit function
     * direct transfers into pool are not credited
     */
    function balanceOf(address) external view returns (uint256);

    /**
     * @notice function tracks total subscription amount for a given proposal address
     */
    function totalSubscriptions(address) external view returns (uint256);

    /**
     * @notice function tracks subscription amounts for a given proposal address and subsciber address
     */
    function subscriptionAmountOf(
        address,
        address
    ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {DataTypesPeerToPool} from "../DataTypesPeerToPool.sol";

interface ILoanProposalImpl {
    event LoanTermsProposed(DataTypesPeerToPool.LoanTerms loanTerms);
    event LoanTermsLocked();
    event LoanTermsAndTransferCollFinalized(
        uint256 grossLoanAmount,
        uint256[2] collAmounts,
        uint256[2] fees
    );
    event Rolledback(address sender);
    event LoanDeployed();
    event ConversionExercised(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event RepaymentClaimed(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event Repaid(
        uint256 remainingLoanTokenDue,
        uint256 collTokenLeftUnconverted,
        uint256 repaymentIdx
    );
    event LoanDefaulted();
    event DefaultProceedsClaimed(address indexed sender);

    /**
     * @notice Initializes loan proposal
     * @param _factory Address of the factory contract from which proposal is created
     * @param _arranger Address of the arranger of the proposal
     * @param _fundingPool Address of the funding pool to be used to source liquidity, if successful
     * @param _collToken Address of collateral token to be used in loan
     * @param _whitelistAuthority Address of whitelist authority who can manage the lender whitelist (optional)
     * @param _arrangerFee Arranger fee in percent (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower 
     lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function initialize(
        address _factory,
        address _arranger,
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Propose new loan terms
     * @param newLoanTerms The new loan terms
     * @dev Can only be called by the arranger
     */
    function updateLoanTerms(
        DataTypesPeerToPool.LoanTerms calldata newLoanTerms
    ) external;

    /**
     * @notice Lock loan terms
     * @param loanTermsUpdateTime The timestamp at which loan terms are locked
     * @dev Can only be called by the arranger or borrower
     */
    function lockLoanTerms(uint256 loanTermsUpdateTime) external;

    /**
     * @notice Finalize the loan terms and transfer final collateral amount
     * @param expectedTransferFee The expected transfer fee (if any) of the collateral token
     * @param mysoTokenManagerData Data to be passed to MysoTokenManager
     * @dev Can only be called by the borrower
     */
    function finalizeLoanTermsAndTransferColl(
        uint256 expectedTransferFee,
        bytes calldata mysoTokenManagerData
    ) external;

    /**
     * @notice Rolls back the loan proposal
     * @dev Can be called by borrower during the unsubscribe grace period or by anyone in case the total totalSubscriptions fell below the minTotalSubscriptions
     */
    function rollback() external;

    /**
     * @notice Checks and updates the status of the loan proposal from 'READY_TO_EXECUTE' to 'LOAN_DEPLOYED'
     * @dev Can only be called by funding pool in conjunction with executing the loan proposal and settling amounts, i.e., sending loan amount to borrower and fees
     */
    function checkAndUpdateStatus() external;

    /**
     * @notice Allows lenders to exercise their conversion right for given repayment period
     * @dev Can only be called by entitled lenders and during conversion grace period of given repayment period
     */
    function exerciseConversion() external;

    /**
     * @notice Allows borrower to repay
     * @param expectedTransferFee The expected transfer fee (if any) of the loan token
     * @dev Can only be called by borrower and during repayment grace period of given repayment period. If borrower doesn't repay in time the loan can be marked as defaulted and borrowers loses control over pledged collateral. Note that the repayment amount can be lower than the loanTokenDue if lenders convert (potentially 0 if all convert, in which case borrower still needs to call the repay function to not default). Also note that on repay any unconverted collateral token reserved for conversions for that period get transferred back to borrower.
     */
    function repay(uint256 expectedTransferFee) external;

    /**
     * @notice Allows lenders to claim any repayments for given repayment period
     * @param repaymentIdx the given repayment period index
     * @dev Can only be called by entitled lenders and if they didn't make use of their conversion right
     */
    function claimRepayment(uint256 repaymentIdx) external;

    /**
     * @notice Marks loan proposal as defaulted
     * @dev Can be called by anyone but only if borrower failed to repay during repayment grace period
     */
    function markAsDefaulted() external;

    /**
     * @notice Allows lenders to claim default proceeds
     * @dev Can only be called if borrower defaulted and loan proposal was marked as defaulted; default proceeds are whatever is left in collateral token in loan proposal contract; proceeds are splitted among all lenders taking into account any conversions lenders already made during the default period.
     */
    function claimDefaultProceeds() external;

    /**
     * @notice Returns the amount of subscriptions that converted for given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of subscriptions that converted for given repayment period
     */
    function totalConvertedSubscriptionsPerIdx(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns the amount of collateral tokens that were converted during given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of collateral tokens that were converted during given repayment period
     */
    function collTokenConverted(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns core dynamic data for given loan proposal
     * @return arrangerFee The arranger fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC)
     * @return grossLoanAmount The final loan amount, which initially is zero and gets set once the proposal gets finalized
     * @return finalCollAmountReservedForDefault The final collateral amount reserved for default case, which initially is zero and gets set once the proposal gets finalized.
     * @return finalCollAmountReservedForConversions The final collateral amount reserved for lender conversions, which initially is zero and gets set once the proposal gets finalized
     * @return loanTermsLockedTime The timestamp when loan terms got locked in, which initially is zero and gets set once the proposal gets finalized
     * @return currentRepaymentIdx The current repayment index, which gets incremented on every repay
     * @return status The current loan proposal status.
     * @return protocolFee The protocol fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC). Note that the relative protocol fee is locked in at the time when the proposal is first created
     * @dev Note that finalCollAmountReservedForDefault is a lower bound for the collateral amount that lenders can claim in case of a default. This means that in case all lenders converted and the borrower defaults then this amount will be distributed as default recovery value on a pro-rata basis to lenders. In the other case where no lenders converted then finalCollAmountReservedForDefault plus finalCollAmountReservedForConversions will be available as default recovery value for lenders, hence finalCollAmountReservedForDefault is a lower bound for a lender's default recovery value.
     */
    function dynamicData()
        external
        view
        returns (
            uint256 arrangerFee,
            uint256 grossLoanAmount,
            uint256 finalCollAmountReservedForDefault,
            uint256 finalCollAmountReservedForConversions,
            uint256 loanTermsLockedTime,
            uint256 currentRepaymentIdx,
            DataTypesPeerToPool.LoanStatus status,
            uint256 protocolFee
        );

    /**
     * @notice Returns core static data for given loan proposal
     * @return factory The address of the factory contract from which the proposal was created
     * @return fundingPool The address of the funding pool from which lenders can subscribe, and from which 
     -upon acceptance- the final loan amount gets sourced
     * @return collToken The address of the collateral token to be provided by the borrower
     * @return arranger The address of the arranger of the proposal
     * @return whitelistAuthority Addresses of the whitelist authority who can manage a lender whitelist (optional)
     * @return unsubscribeGracePeriod Unsubscribe grace period until which lenders can unsubscribe after a loan 
     proposal got accepted by the borrower
     * @return conversionGracePeriod Conversion grace period during which lenders can convert, i.e., between 
     [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
     * @return repaymentGracePeriod Repayment grace period during which borrowers can repay, i.e., between 
     [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
     */
    function staticData()
        external
        view
        returns (
            address factory,
            address fundingPool,
            address collToken,
            address arranger,
            address whitelistAuthority,
            uint256 unsubscribeGracePeriod,
            uint256 conversionGracePeriod,
            uint256 repaymentGracePeriod
        );

    /**
     * @notice Returns the timestamp of when loan terms were last updated
     * @return lastLoanTermsUpdateTime The timestamp when the loan terms were last updated
     */
    function lastLoanTermsUpdateTime()
        external
        view
        returns (uint256 lastLoanTermsUpdateTime);

    /**
     * @notice Returns the current loan terms
     * @return The current loan terms
     */
    function loanTerms()
        external
        view
        returns (DataTypesPeerToPool.LoanTerms memory);

    /**
     * @notice Returns flag indicating whether lenders can currently unsubscribe from loan proposal
     * @return Flag indicating whether lenders can currently unsubscribe from loan proposal
     */
    function canUnsubscribe() external view returns (bool);

    /**
     * @notice Returns flag indicating whether lenders can currently subscribe to loan proposal
     * @return Flag indicating whether lenders can currently subscribe to loan proposal
     */
    function canSubscribe() external view returns (bool);

    /**
     * @notice Returns indicative final loan terms
     * @param _tmpLoanTerms The current (or assumed) relative loan terms
     * @param totalSubscriptions The current (or assumed) total subscription amount
     * @param loanTokenDecimals The loan token decimals
     * @return loanTerms The loan terms in absolute terms
     * @return collAmounts Array containing collateral amount reserved for default and for conversions
     * @return fees Array containing arranger fee and protocol fee
     */
    function getAbsoluteLoanTerms(
        DataTypesPeerToPool.LoanTerms memory _tmpLoanTerms,
        uint256 totalSubscriptions,
        uint256 loanTokenDecimals
    )
        external
        view
        returns (
            DataTypesPeerToPool.LoanTerms memory loanTerms,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        );
}