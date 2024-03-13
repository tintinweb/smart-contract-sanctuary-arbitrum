// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IAdapter.sol";
import "../interfaces/ITeahouseVault.sol";

contract TeahouseAdapterInitializable is IAdapter, Initializable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string public constant PROTOCOL = "Teahouse";
    uint8 public constant VERSION = 3;
    uint256 public constant PRECISION = 1e18;

    address public wrapper;
    address public vault;
    address public token0;
    address public token1;
    address public lpToken;

    event SetWrapper(address indexed oldWrapper, address indexed newWrapper);
    event SetVault(address indexed oldVault, address indexed newVault, address token0, address token1, address lpToken);
    event ApproveToken(IERC20 indexed _token, address indexed _spender, uint256 _amount);
    event TransferToken(IERC20 indexed _token, address indexed _recipient, uint256 _amount);

    modifier onlyWrapper() {
        require(wrapper == msg.sender, "onlyWrapper: caller is not the wrapper");
        _;
    }

    /// * INIT *
    constructor() {}

    function initialize(
        address _wrapper,
        address _vault,
        address _admin
    ) external initializer {
        require(_wrapper != address(0) && _vault != address(0) && _admin != address(0), "initialize: address cant be zero");
        wrapper = _wrapper;
        vault = _vault;
        token0 = ITeahouseVault(vault).assetToken0();
        token1 = ITeahouseVault(vault).assetToken1();
        lpToken = vault;
        transferOwnership(_admin);
    }

    receive() external payable {}
    fallback() external {}

    /// * GETTER *
    function totalSupply(
    ) public view returns(uint256) {
        return ITeahouseVault(vault).totalSupply();
    }

    function tokenPerShare(
    ) public view returns(uint256 _token0PerShare, uint256 _token1PerShare) {
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ > 0) {
            (uint256 amount0, uint256 amount1) = ITeahouseVault(vault).vaultAllUnderlyingAssets();
            _token0PerShare = amount0 * PRECISION / totalSupply_;
            _token1PerShare = amount1 * PRECISION / totalSupply_;
        } else {
            return (0, 0);
        }
    }

    function pool(
    ) public view returns(address) {
        return ITeahouseVault(vault).pool();
    }

    function manager(
    ) public view returns(address) {
        return ITeahouseVault(vault).manager();
    }

    function managerFee(
    ) public view returns(uint256) {
        (, , , uint256 performanceFee, )  = ITeahouseVault(vault).feeConfig();
        return performanceFee * PRECISION / 1000000;
    }

    /// * OWNER *
    function setWrapper(
        address _newWrapper
    ) external onlyOwner {
        require(_newWrapper != address(0), "setWrapper: address cant be zero");

        address oldWrapper = wrapper;

        wrapper = _newWrapper;

        emit SetWrapper(oldWrapper, wrapper);
    }

    function setVault(
        address _newVault
    ) external onlyOwner {
        require(_newVault != address(0), "setVault: address cant be zero");

        address oldVault = vault;

        vault = _newVault;

        token0 = ITeahouseVault(vault).assetToken0();
        token1 = ITeahouseVault(vault).assetToken1();
        lpToken = vault;

        emit SetVault(oldVault, vault, token0, token1, lpToken);
    }

    function approveToken(
        IERC20 _token, 
        address _spender, 
        uint256 _amount
    ) external onlyOwner {
        _token.approve(_spender, _amount);

        emit ApproveToken(_token, _spender, _amount);
    }

    function transferToken(
        IERC20 _token, 
        address _recipient, 
        uint256 _amount
    ) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        if (balance < _amount) {
            _amount = balance;
        }

        _token.safeTransfer(_recipient, _amount);

        emit TransferToken(_token, _recipient, _amount);
    }

    /// * VAULT *
    function deposit(
        uint256 _amount0,
        uint256 _amount1,
        address _user,
        bytes calldata _data
    ) external nonReentrant onlyWrapper returns(uint256 _share) {
        require(_data.length > 0, "deposit: slippage is mandatory");

        IERC20(token0).safeTransferFrom(wrapper, address(this), _amount0);
        IERC20(token1).safeTransferFrom(wrapper, address(this), _amount1);
        IERC20(token0).forceApprove(vault, _amount0);
        IERC20(token1).forceApprove(vault, _amount1);
        
        uint256 amount0Used;
        uint256 amount1Used;

        {
        (uint256 slippage) = abi.decode(_data, (uint256));
        (uint256 token0PerShare, uint256 token1PerShare) = tokenPerShare();
        uint256 targetShares0 = _amount0 * PRECISION / token0PerShare;
        uint256 targetShares1 = _amount1 * PRECISION / token1PerShare;
        uint256 targetShares = targetShares0 <= targetShares1 ? targetShares0 : targetShares1;
        _share = targetShares * (PRECISION - slippage) / PRECISION;
        }
        
        (amount0Used, amount1Used) = ITeahouseVault(vault).deposit(_share, _amount0, _amount1);
  
        require(_amount0 >= amount0Used && _amount1 >= amount1Used, "deposit: incorrect token amount");

        IERC20(lpToken).safeTransfer(wrapper, _share);

        if (IERC20(token0).balanceOf(address(this)) > 0) IERC20(token0).safeTransfer(_user, IERC20(token0).balanceOf(address(this)));
        if (IERC20(token1).balanceOf(address(this)) > 0) IERC20(token1).safeTransfer(_user, IERC20(token1).balanceOf(address(this)));
    }

    function withdraw(
        uint256 _share,
        address _user,
        bytes calldata _data
    ) external nonReentrant onlyWrapper returns(uint256 _amount0, uint256 _amount1) {
        require(_data.length > 0, "withdraw: slippage is mandatory");

        IERC20(lpToken).safeTransferFrom(wrapper, address(this), _share);
        IERC20(lpToken).forceApprove(vault, _share);

        (uint256 slippage) = abi.decode(_data, (uint256));
        (uint256 token0PerShare, uint256 token1PerShare) = tokenPerShare();
        uint256 targetAmount0 = _share * token0PerShare * (PRECISION - slippage) / 1e36;
        uint256 targetAmount1 = _share * token1PerShare * (PRECISION - slippage) / 1e36;

        (_amount0, _amount1) = ITeahouseVault(vault).withdraw(_share, targetAmount0, targetAmount1);

        IERC20(token0).safeTransfer(_user, _amount0);
        IERC20(token1).safeTransfer(_user, _amount1);

        if (IERC20(lpToken).balanceOf(address(this)) > 0) IERC20(lpToken).safeTransfer(_user, IERC20(lpToken).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IAdapter {
    function initialize(
        address _wrapper,
        address _vault,
        address _admin
    ) external;

    function wrapper() external returns(address);

    function vault() external returns(address);

    function token0() external returns(address);

    function token1() external returns(address);

    function lpToken() external returns(address);

    function PROTOCOL() external returns(string memory);

    function VERSION() external returns(uint8);

    function PRECISION() external returns(uint256);

    function totalSupply() external view returns(uint256);

    function tokenPerShare() external view returns(uint256 _token0PerShare, uint256 _token1PerShare);

    function pool() external view returns(address);

    function deposit(
        uint256 _amount0,
        uint256 _amount1,
        address _user,
        bytes calldata _data
    ) external returns(uint256 _share);

    function withdraw(
        uint256 _share,
        address _user,
        bytes calldata _data
    ) external returns(uint256 _amount0, uint256 _amount1);
}

// SPDX-License-Identifier: BUSL-1.1
// Teahouse Finance

pragma solidity ^0.8.19;

interface ITeahouseVault {
    error PoolNotInitialized();
    error InvalidFeePercentage();
    error InvalidFeeCap();
    error InvalidShareAmount();
    error PositionLengthExceedsLimit();
    error InvalidPriceSlippage(uint256 amount0, uint256 amount1);
    error PositionDoesNotExist();
    error ZeroLiquidity();
    error CallerIsNotManager();
    error InvalidCallbackStatus();
    error InvalidCallbackCaller();
    error SwapInZeroLiquidityRegion();
    error TransactionExpired();
    error InvalidSwapToken();
    error InvalidSwapReceiver();
    error InsufficientSwapResult(uint256 minAmount, uint256 convertedAmount);
    error InvalidTokenOrder();

    event TeaVaultV3PairCreated(address indexed teaVaultAddress);
    event ManagerChanged(address indexed sender, address indexed newManager);
    event ManagementFeeCollected(uint256 shares);
    event DepositShares(address indexed shareOwner, uint256 shares, uint256 amount0, uint256 amount1, uint256 feeAmount0, uint256 feeAmount1);
    event WithdrawShares(address indexed shareOwner, uint256 shares, uint256 amount0, uint256 amount1, uint256 feeShares);
    event AddLiquidity(address indexed pool, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event RemoveLiquidity(address indexed pool, int24 tickLower, int24 tickUpper, uint128 liquidity, uint256 amount0, uint256 amount1);
    event Collect(address indexed pool, int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1);
    event CollectSwapFees(address indexed pool, uint256 amount0, uint256 amount1, uint256 feeAmount0, uint256 feeAmount1);
    event Swap(bool indexed zeroForOne, bool indexed exactInput, uint256 amountIn, uint256 amountOut);

    /**
    /// @notice Fee config structure
    /// @param vault Fee goes to this address
    /// @param entryFee Entry fee in 0.0001% (collected when depositing)
    /// @param exitFee Exit fee in 0.0001% (collected when withdrawing)
    /// @param performanceFee Platform performance fee in 0.0001% (collected for each cycle, from profits)
    /// @param managementFee Platform yearly management fee in 0.0001% (collected when depositing/withdrawing)
    struct FeeConfig {
        address vault;
        uint24 entryFee;
        uint24 exitFee;
        uint24 performanceFee;
        uint24 managementFee;
    }
    */

    /// @notice Uniswap V3 position structure
    /// @param tickLower Tick lower bound
    /// @param tickUpper Tick upper bound
    /// @param liquidity Liquidity size
    struct Position {
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
    }

    function feeConfig() external view returns (address vault, uint24 entryFee, uint24 exitFee, uint24 performanceFee, uint24 managementFee);

    /// @notice get asset token0 address
    /// @return token0 token0 address
    function assetToken0() external view returns (address token0);

    /// @notice get asset token1 address
    /// @return token1 token1 address
    function assetToken1() external view returns (address token1);

    /// @notice get vault balance of token0
    /// @return amount vault balance of token0
    function getToken0Balance() external view returns (uint256 amount);

    /// @notice get vault balance of token1
    /// @return amount vault balance of token1
    function getToken1Balance() external view returns (uint256 amount);

    /// @notice get pool token and price info
    /// @return token0 token0 address
    /// @return token1 token1 address
    /// @return decimals0 token0 decimals
    /// @return decimals1 token1 decimals
    /// @return feeTier current pool price in tick
    /// @return sqrtPriceX96 current pool price in sqrtPriceX96
    /// @return tick current pool price in tick
    function getPoolInfo() external view returns (
        address token0,
        address token1,
        uint8 decimals0,
        uint8 decimals1,
        uint24 feeTier,
        uint160 sqrtPriceX96,
        int24 tick
    );

    /**
    /// @notice Set fee structure and vault addresses
    /// @notice Only available to admins
    /// @param _feeConfig Fee structure settings
    function setFeeConfig(FeeConfig calldata _feeConfig) external;
    */

    /// @notice Assign fund manager
    /// @notice Only the owner can do this
    /// @param _manager Fund manager address
    function assignManager(address _manager) external;

    /// @notice Collect management fee by share token inflation
    /// @notice Only fund manager can do this
    /// @return collectedShares Share amount collected by minting
    function collectManagementFee() external returns (uint256 collectedShares);

    /// @notice Mint shares and deposit token0 and token1
    /// @param _shares Share amount to be mint
    /// @param _amount0Max Max token0 amount to be deposited
    /// @param _amount1Max Max token1 amount to be deposited
    /// @return depositedAmount0 Deposited token0 amount
    /// @return depositedAmount1 Deposited token1 amount
    function deposit(
        uint256 _shares,
        uint256 _amount0Max,
        uint256 _amount1Max
    ) external returns (uint256 depositedAmount0, uint256 depositedAmount1);

    /// @notice Burn shares and withdraw token0 and token1
    /// @param _shares Share amount to be burnt
    /// @param _amount0Min Min token0 amount to be withdrawn
    /// @param _amount1Min Min token1 amount to be withdrawn
    /// @return withdrawnAmount0 Withdrew token0 amount
    /// @return withdrawnAmount1 Withdrew token1 amount
    function withdraw(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external returns (uint256 withdrawnAmount0, uint256 withdrawnAmount1);

    /// @notice Add liquidity to a position from this vault
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @param _liquidity Liquidity to be added to the position
    /// @param _amount0Min Minimum token0 amount to be added to the position
    /// @param _amount1Min Minimum token1 amount to be added to the position
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amount0 Token0 amount added to the position
    /// @return amount1 Token1 amount added to the position
    function addLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint64 _deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Remove liquidity from a position from this vault
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @param _liquidity Liquidity to be removed from the position
    /// @param _amount0Min Minimum token0 amount to be removed from the position
    /// @param _amount1Min Minimum token1 amount to be removed from the position
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amount0 Token0 amount removed from the position
    /// @return amount1 Token1 amount removed from the position
    function removeLiquidity(
        int24 _tickLower,
        int24 _tickUpper,
        uint128 _liquidity,
        uint256 _amount0Min,
        uint256 _amount1Min,
        uint64 _deadline
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collect swap fee of a position
    /// @notice Only fund manager can do this
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @return amount0 Token0 amount collected from the position
    /// @return amount1 Token1 amount collected from the position
    function collectPositionSwapFee(
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Collect swap fee of all positions
    /// @notice Only fund manager can do this
    /// @return amount0 Token0 amount collected from the positions
    /// @return amount1 Token1 amount collected from the positions
    function collectAllSwapFee() external returns (uint128 amount0, uint128 amount1);

    /// @notice Swap tokens on the pool with exact input amount
    /// @notice Only fund manager can do this
    /// @param _zeroForOne Swap direction from token0 to token1 or not
    /// @param _amountIn Amount of input token
    /// @param _amountOutMin Required minimum output token amount
    /// @param _minPriceInSqrtPriceX96 Minimum price in sqrtPriceX96
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amountOut Output token amount
    function swapInputSingle(
        bool _zeroForOne,
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint160 _minPriceInSqrtPriceX96,
        uint64 _deadline
    ) external returns (uint256 amountOut);


    /// @notice Swap tokens on the pool with exact output amount
    /// @notice Only fund manager can do this
    /// @param _zeroForOne Swap direction from token0 to token1 or not
    /// @param _amountOut Output token amount
    /// @param _amountInMax Required maximum input token amount
    /// @param _maxPriceInSqrtPriceX96 Maximum price in sqrtPriceX96
    /// @param _deadline Deadline of the transaction (transaction will revert if after this timestamp)
    /// @return amountIn Input token amount
    function swapOutputSingle(
        bool _zeroForOne,
        uint256 _amountOut,
        uint256 _amountInMax,
        uint160 _maxPriceInSqrtPriceX96,
        uint64 _deadline
    ) external returns (uint256 amountIn);

    /// @notice Process batch operations in one transation
    /// @return results Results in bytes array
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);

    /// @notice Get position info by specifying tickLower and tickUpper of the position
    /// @param _tickLower Tick lower bound
    /// @param _tickUpper Tick upper bound
    /// @return amount0 Current position token0 amount
    /// @return amount1 Current position token1 amount
    /// @return fee0 Pending fee token0 amount
    /// @return fee1 Pending fee token1 amount
    function positionInfo(
        int24 _tickLower,
        int24 _tickUpper
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get position info by specifying position index
    /// @param _index Position index
    /// @return amount0 Current position token0 amount
    /// @return amount1 Current position token1 amount
    /// @return fee0 Pending fee token0 amount
    /// @return fee1 Pending fee token1 amount
    function positionInfo(
        uint256 _index
    ) external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get all position info
    /// @return amount0 All positions token0 amount
    /// @return amount1 All positions token1 amount
    /// @return fee0 All positions pending fee token0 amount
    /// @return fee1 All positions pending fee token1 amount
    function allPositionInfo() external view returns (uint256 amount0, uint256 amount1, uint256 fee0, uint256 fee1);

    /// @notice Get underlying assets hold by this vault
    /// @return amount0 Total token0 amount
    /// @return amount1 Total token1 amount
    function vaultAllUnderlyingAssets() external view returns (uint256 amount0, uint256 amount1);

    /// @notice Get vault value in token0
    /// @return value0 Vault value in token0
    function estimatedValueInToken0() external view returns (uint256 value0);

    /// @notice Get vault value in token1
    /// @return value1 Vault value in token1
    function estimatedValueInToken1() external view returns (uint256 value1);

    /// @notice Calculate liquidity of a position from amount0 and amount1
    /// @param tickLower lower tick of the position
    /// @param tickUpper upper tick of the position
    /// @param amount0 amount of token0
    /// @param amount1 amount of token1
    /// @return liquidity calculated liquidity 
    function getLiquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) external view returns (uint128 liquidity);

    /// @notice Calculate amount of tokens required for liquidity of a position
    /// @param tickLower lower tick of the position
    /// @param tickUpper upper tick of the position
    /// @param liquidity amount of liquidity
    /// @return amount0 amount of token0 required
    /// @return amount1 amount of token1 required
    function getAmountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external view returns (uint256 amount0, uint256 amount1);

    /// @notice Get all open positions
    /// @return results Array of all open positions
    function getAllPositions() external view returns (Position[] memory results);

    function lastCollectManagementFee() external view returns(uint256);

    function totalSupply() external view returns (uint256);

    function pool() external view returns(address);

    function manager() external view returns (address);
}