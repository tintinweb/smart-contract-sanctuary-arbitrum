// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
pragma solidity 0.8.19;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPlpManagerPyth.sol";
import "./interfaces/IShortsTracker.sol";
import "../tokens/interfaces/IMintable.sol";
import "../oracle/interfaces/IPythPriceFeed.sol";

contract PlpManager is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IPlpManagerPyth
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDP_DECIMALS = 18;
    uint256 public constant PLP_PRECISION = 10 ** 18;
    uint256 public constant MAX_COOLDOWN_DURATION = 48 hours;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    IVault public override vault;
    IShortsTracker public shortsTracker;
    address public override collateralToken;
    address public override plp;

    uint256 public override cooldownDuration;
    mapping(address => uint256) public override lastAddedAt;
    mapping(address => bool) public override plpWhitelistedUsers;

    uint256 public aumAddition;
    uint256 public aumDeduction;

    bool public inPrivateMode;
    bool public inWhitelistMode;
    uint256 public shortsTrackerAveragePriceWeight;
    mapping(address => bool) public isHandler;
    IPythPriceFeed public pythPriceFeed;

    event AddLiquidity(
        address account,
        uint256 amount,
        uint256 aumInUsdp,
        uint256 plpSupply,
        uint256 usdpAmount,
        uint256 mintAmount
    );

    event RemoveLiquidity(
        address account,
        uint256 plpAmount,
        uint256 aumInUsdp,
        uint256 plpSupply,
        uint256 usdpAmount,
        uint256 amountOut
    );

    event SetPythPriceFeed(address pythPriceFeed);

    function initialize(
        address _vault,
        address _collateralToken,
        address _plp,
        address _shortsTracker,
        uint256 _cooldownDuration,
        bool _inPrivateMode,
        uint256 _shortsTrackerAveragePriceWeight
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        vault = IVault(_vault);
        collateralToken = _collateralToken;
        plp = _plp;
        shortsTracker = IShortsTracker(_shortsTracker);
        cooldownDuration = _cooldownDuration;
        inPrivateMode = _inPrivateMode;
        shortsTrackerAveragePriceWeight = _shortsTrackerAveragePriceWeight;
    }

    function setInPrivateMode(bool _inPrivateMode) external onlyOwner {
        inPrivateMode = _inPrivateMode;
    }

    function setShortsTracker(
        IShortsTracker _shortsTracker
    ) external onlyOwner {
        shortsTracker = _shortsTracker;
    }

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external override onlyOwner {
        require(
            _shortsTrackerAveragePriceWeight <= BASIS_POINTS_DIVISOR,
            "PlpManager: invalid weight"
        );
        shortsTrackerAveragePriceWeight = _shortsTrackerAveragePriceWeight;
    }

    function setHandler(address _handler, bool _isActive) external onlyOwner {
        isHandler[_handler] = _isActive;
    }

    function setCooldownDuration(
        uint256 _cooldownDuration
    ) external override onlyOwner {
        require(
            _cooldownDuration <= MAX_COOLDOWN_DURATION,
            "PlpManager: invalid _cooldownDuration"
        );
        cooldownDuration = _cooldownDuration;
    }

    function setAumAdjustment(
        uint256 _aumAddition,
        uint256 _aumDeduction
    ) external onlyOwner {
        aumAddition = _aumAddition;
        aumDeduction = _aumDeduction;
    }

    function setWhitelist(
        address[] calldata _users,
        bool[] calldata _status
    ) external onlyOwner {
        uint index;
        for (; index < _users.length; ++ index) {
            plpWhitelistedUsers[_users[index]] = _status[index];
        }
    }

    function setWhitelistMode(bool _whiteListMode) external onlyOwner {
        inWhitelistMode = _whiteListMode;
    }

    function setPythPriceFeed(address _pythPriceFeed) external onlyOwner {
        pythPriceFeed = IPythPriceFeed(_pythPriceFeed);
        emit SetPythPriceFeed(_pythPriceFeed);
    }

    function addLiquidity(
        bytes[] calldata priceUpdateData,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external payable override nonReentrant returns (uint256) {
        if (inPrivateMode) {
            revert("PlpManager: action not enabled");
        }
        return
            _addLiquidity(
                priceUpdateData,
                msg.sender,
                msg.sender,
                _amount,
                _minUsdp,
                _minPlp
            );
    }

    function addLiquidityForAccount(
        bytes[] calldata priceUpdateData,
        address _fundingAccount,
        address _account,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external payable override returns (uint256) {
        _validateHandler();
        return
            _addLiquidity(
                priceUpdateData,
                _fundingAccount,
                _account,
                _amount,
                _minUsdp,
                _minPlp
            );
    }

    function removeLiquidity(
        bytes[] calldata priceUpdateData,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external payable override nonReentrant returns (uint256) {
        if (inPrivateMode) {
            revert("PlpManager: action not enabled");
        }
        return
            _removeLiquidity(
                priceUpdateData,
                msg.sender,
                _plpAmount,
                _minOut,
                _receiver
            );
    }

    function removeLiquidityForAccount(
        bytes[] calldata priceUpdateData,
        address _account,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external payable override nonReentrant returns (uint256) {
        _validateHandler();
        return
            _removeLiquidity(
                priceUpdateData,
                _account,
                _plpAmount,
                _minOut,
                _receiver
            );
    }

    function getAums(
        uint256[] memory tokenPrices
    ) public view returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);

        amounts[0] = getAumAtPrice(true, tokenPrices);
        amounts[1] = getAumAtPrice(false, tokenPrices);
        return amounts;
    }

    function getAumInUsdpAtPrice(
        bool maximise,
        uint256[] memory tokenPrices
    ) public view override returns (uint256) {
        uint256 aum = getAumAtPrice(maximise, tokenPrices);
        return (aum * (10 ** USDP_DECIMALS)) / PRICE_PRECISION;
    }

    function _getAumInUsdp(bool maximise) internal view returns (uint256) {
        uint256 aum = _getAum(maximise);
        return (aum * (10 ** USDP_DECIMALS)) / PRICE_PRECISION;
    }

    function getAumAtPrice(
        bool maximise,
        uint256[] memory tokenPrices
    ) public view returns (uint256) {
        uint256 length = vault.allWhitelistedTokensLength();
        uint256 aum = aumAddition;
        IVault _vault = vault;

        uint256 currentAmmDeduction;

        bool _maximise = maximise;

        for (uint256 i; i < length; i++) {
            address token = vault.allWhitelistedTokens(i);
            bool isWhitelisted = vault.whitelistedTokens(token);

            if (!isWhitelisted) {
                continue;
            }
            uint256 offchainPrice = tokenPrices[i];
            uint256 maxPrice = pythPriceFeed.getOffchainPrice(
                token,
                offchainPrice,
                true
            );
            uint256 minPrice = pythPriceFeed.getOffchainPrice(
                token,
                offchainPrice,
                false
            );

            if (token == collateralToken) {
                uint256 collateralDecimals = _vault.tokenDecimals(
                    collateralToken
                );
                aum +=
                    (vault.poolAmount() * (_maximise ? maxPrice : minPrice)) /
                    (10 ** collateralDecimals);
                continue;
            }

            // add global profit / loss
            uint256 shortSize = _vault.globalShortSizes(token);
            uint256 longSize = _vault.globalLongSizes(token);

            if (longSize > 0) {
                (uint256 delta, bool hasProfit) = getGlobalDelta(
                    token,
                    _maximise ? minPrice : maxPrice,
                    longSize,
                    true
                );
                if (!hasProfit) {
                    // add lossees from longs
                    aum += delta;
                } else {
                    currentAmmDeduction += delta;
                }
            }

            if (shortSize > 0) {
                (uint256 delta, bool hasProfit) = getGlobalDelta(
                    token,
                    _maximise ? maxPrice : minPrice,
                    shortSize,
                    false
                );
                if (!hasProfit) {
                    // add losses from shorts
                    aum += delta;
                } else {
                    currentAmmDeduction += delta;
                }
            }
        }

        aum = currentAmmDeduction > aum ? 0 : aum - currentAmmDeduction;
        return aumDeduction > aum ? 0 : aum - aumDeduction;
    }

    function _getAum(bool maximise) internal view returns (uint256) {
        uint256 length = vault.allWhitelistedTokensLength();
        uint256 aum = aumAddition;
        IVault _vault = vault;

        uint256 collateralTokenPrice = maximise
            ? _vault.getMaxPrice(collateralToken)
            : _vault.getMinPrice(collateralToken);

        uint256 collateralDecimals = _vault.tokenDecimals(collateralToken);

        uint256 currentAmmDeduction;

        aum +=
            (vault.poolAmount() * collateralTokenPrice) /
            (10 ** collateralDecimals);

        bool _maximise = maximise;

        for (uint256 i; i < length; i++) {
            address token = vault.allWhitelistedTokens(i);
            bool isWhitelisted = vault.whitelistedTokens(token);

            if (!isWhitelisted || token == collateralToken) {
                continue;
            }

            uint256 maxPrice = _vault.getMaxPrice(token);
            uint256 minPrice = _vault.getMinPrice(token);

            // add global profit / loss
            uint256 shortSize = _vault.globalShortSizes(token);
            uint256 longSize = _vault.globalLongSizes(token);

            if (longSize > 0) {
                (uint256 delta, bool hasProfit) = getGlobalDelta(
                    token,
                    _maximise ? minPrice : maxPrice,
                    longSize,
                    true
                );
                if (!hasProfit) {
                    // add lossees from longs
                    aum += delta;
                } else {
                    currentAmmDeduction += delta;
                }
            }

            if (shortSize > 0) {
                (uint256 delta, bool hasProfit) = getGlobalDelta(
                    token,
                    _maximise ? maxPrice : minPrice,
                    shortSize,
                    false
                );
                if (!hasProfit) {
                    // add losses from shorts
                    aum += delta;
                } else {
                    currentAmmDeduction += delta;
                }
            }
        }

        aum = currentAmmDeduction > aum ? 0 : aum - currentAmmDeduction;
        return aumDeduction > aum ? 0 : aum - aumDeduction;
    }

    function getGlobalDelta(
        address _token,
        uint256 _price,
        uint256 _size,
        bool _isLong
    ) public view returns (uint256, bool) {
        uint256 averagePrice = _isLong
            ? getGlobalLongAveragePrice(_token)
            : getGlobalShortAveragePrice(_token);
        uint256 priceDelta = averagePrice > _price
            ? averagePrice - _price
            : _price - averagePrice;
        uint256 delta = (_size * priceDelta) / averagePrice;
        return (delta, _isLong ? averagePrice < _price : averagePrice > _price);
    }

    function getGlobalShortAveragePrice(
        address _token
    ) public view returns (uint256) {
        IShortsTracker _shortsTracker = shortsTracker;
        if (
            address(_shortsTracker) == address(0) ||
            !_shortsTracker.isGlobalShortDataReady()
        ) {
            return vault.globalShortAveragePrices(_token);
        }

        uint256 _shortsTrackerAveragePriceWeight = shortsTrackerAveragePriceWeight;
        if (_shortsTrackerAveragePriceWeight == 0) {
            return vault.globalShortAveragePrices(_token);
        } else if (_shortsTrackerAveragePriceWeight == BASIS_POINTS_DIVISOR) {
            return _shortsTracker.globalShortAveragePrices(_token);
        }

        uint256 vaultAveragePrice = vault.globalShortAveragePrices(_token);
        uint256 shortsTrackerAveragePrice = _shortsTracker
            .globalShortAveragePrices(_token);

        return
            (vaultAveragePrice *
                (BASIS_POINTS_DIVISOR - _shortsTrackerAveragePriceWeight) +
                (shortsTrackerAveragePrice *
                    _shortsTrackerAveragePriceWeight)) / BASIS_POINTS_DIVISOR;
    }

    function getGlobalLongAveragePrice(
        address _token
    ) public view returns (uint256) {
        return vault.globalLongAveragePrices(_token);
    }

    function estimatePlpOut(
        uint256[] memory tokenPrices,
        uint256 _amount
    ) external view override returns (uint256 plpAmount) {
        uint256 aumInUsdp = getAumInUsdpAtPrice(true, tokenPrices);
        uint256 plpSupply = IERC20Upgradeable(plp).totalSupply();
        uint256 usdpAmount = vault.estimateUSDPOut(_amount);

        plpAmount = aumInUsdp == 0
            ? usdpAmount
            : (usdpAmount * plpSupply) / aumInUsdp;
    }

    function estimateTokenIn(
        uint256[] memory tokenPrices,
        uint256 _plpAmount
    ) external view override returns (uint256 amountIn) {
        uint256 aumInUsdp = getAumInUsdpAtPrice(true, tokenPrices);
        uint256 plpSupply = IERC20Upgradeable(plp).totalSupply();

        uint256 usdpAmount = plpSupply == 0
            ? _plpAmount
            : (_plpAmount * aumInUsdp) / plpSupply;

        amountIn = vault.estimateTokenIn(usdpAmount);
    }

    function _addLiquidity(
        bytes[] calldata priceUpdateData,
        address _fundingAccount,
        address _account,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) private returns (uint256) {
        require(_amount > 0, "PlpManager: invalid _amount");
        _validateWhitelist();

        pythPriceFeed.updatePriceFeeds{value: msg.value}(
            priceUpdateData,
            _account
        );

        // calculate aum before addLiquidity
        uint256 aumInUsdp = _getAumInUsdp(true);
        uint256 plpSupply = IERC20Upgradeable(plp).totalSupply();

        IERC20Upgradeable(collateralToken).safeTransferFrom(
            _fundingAccount,
            address(vault),
            _amount
        );
        uint256 usdpAmount = vault.addLiquidity();
        require(usdpAmount >= _minUsdp, "PlpManager: insufficient USDP output");

        uint256 mintAmount = aumInUsdp == 0
            ? usdpAmount
            : (usdpAmount * plpSupply) / aumInUsdp;

        require(mintAmount >= _minPlp, "PlpManager: insufficient PLP output");

        IMintable(plp).mint(_account, mintAmount);

        lastAddedAt[_account] = block.timestamp;

        emit AddLiquidity(
            _account,
            _amount,
            aumInUsdp,
            plpSupply,
            usdpAmount,
            mintAmount
        );

        return mintAmount;
    }

    function _removeLiquidity(
        bytes[] calldata priceUpdateData,
        address _account,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) private returns (uint256) {
        require(_plpAmount > 0, "PlpManager: invalid _plpAmount");
        require(
            lastAddedAt[_account] + cooldownDuration <= block.timestamp,
            "PlpManager: cooldown duration not yet passed"
        );

        pythPriceFeed.updatePriceFeeds{value: msg.value}(
            priceUpdateData,
            _account
        );

        // calculate aum before removeLiquidity
        uint256 aumInUsdp = _getAumInUsdp(false);
        uint256 plpSupply = IERC20Upgradeable(plp).totalSupply();

        uint256 usdpAmount = (_plpAmount * aumInUsdp) / plpSupply;

        IMintable(plp).burn(_account, _plpAmount);

        uint256 amountOut = vault.removeLiquidity(_receiver, usdpAmount);
        require(amountOut >= _minOut, "PlpManager: insufficient output");

        emit RemoveLiquidity(
            _account,
            _plpAmount,
            aumInUsdp,
            plpSupply,
            usdpAmount,
            amountOut
        );

        return amountOut;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "PlpManager: forbidden");
    }

    function _validateWhitelist() private view {
        if (inWhitelistMode) {
            require(plpWhitelistedUsers[msg.sender], "PlpManager: Not whitelisted");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IVault.sol";

interface IPlpManagerPyth {
    function plp() external view returns (address);

    function vault() external view returns (IVault);

    function collateralToken() external view returns (address);

    function cooldownDuration() external view returns (uint256);

    function getAumInUsdpAtPrice(
        bool maximise,
        uint256[] memory tokenPrices
    ) external view returns (uint256);

    function estimatePlpOut(
        uint256[] memory tokenPrices,
        uint256 _amount
    ) external view returns (uint256);

    function estimateTokenIn(
        uint256[] memory tokenPrices,
        uint256 _plpAmount
    ) external view returns (uint256);

    function lastAddedAt(address _account) external view returns (uint256);

    function plpWhitelistedUsers(address _user) external view returns (bool);

    function addLiquidity(
        bytes[] calldata priceUpdateData,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external payable returns (uint256);

    function addLiquidityForAccount(
        bytes[] calldata priceUpdateData,
        address _fundingAccount,
        address _account,
        uint256 _amount,
        uint256 _minUsdp,
        uint256 _minPlp
    ) external payable returns (uint256);

    function removeLiquidity(
        bytes[] calldata priceUpdateData,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external payable returns (uint256);

    function removeLiquidityForAccount(
        bytes[] calldata priceUpdateData,
        address _account,
        uint256 _plpAmount,
        uint256 _minOut,
        address _receiver
    ) external payable returns (uint256);

    function setShortsTrackerAveragePriceWeight(
        uint256 _shortsTrackerAveragePriceWeight
    ) external;

    function setCooldownDuration(uint256 _cooldownDuration) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IShortsTracker {
    function isGlobalShortDataReady() external view returns (bool);

    function globalShortAveragePrices(address _token)
        external
        view
        returns (uint256);

    function getNextGlobalShortData(
        address _account,
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        bool _isIncrease
    ) external view returns (uint256, uint256);

    function updateGlobalShortData(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;

    function setIsGlobalShortDataReady(bool value) external;

    function setInitData(
        address[] calldata _tokens,
        uint256[] calldata _averagePrices
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IVault {
    function isInitialized() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function collateralToken() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router)
        external
        view
        returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function plpManager() external view returns (address);

    function minProfitBasisPoints(address _token)
        external
        view
        returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function estimateUSDPOut(uint256 _amount) external view returns (uint256);

    function estimateTokenIn(uint256 _usdpAmount)
        external
        view
        returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setPlpManager(address _manager) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdpAmount(uint256 _amount) external;

    function setMaxGlobalSize(
        address _token,
        uint256 _longAmount,
        uint256 _shortAmount
    ) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor
    ) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime
    ) external;

    function setMaxUsdpAmounts(uint256 _maxUsdpAmounts) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(address _receiver) external returns (uint256);

    function directPoolDeposit() external;

    function addLiquidity() external returns (uint256);

    function removeLiquidity(address _receiver, uint256 _usdpAmount)
        external
        returns (uint256);

    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);

    function liquidatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(address _token, uint256 _tokenAmount)
        external
        view
        returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function getNextFundingRate(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserve() external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalLongSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(address _token)
        external
        view
        returns (uint256);

    function globalLongAveragePrices(address _token)
        external
        view
        returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);

    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function poolAmount() external view returns (uint256);

    function reservedAmounts(address _token, bool _isLong)
        external
        view
        returns (uint256);

    function totalReservedAmount() external view returns (uint256);

    function usdpAmount() external view returns (uint256);

    function maxUsdpAmount() external view returns (uint256);

    function getRedemptionAmount(uint256 _usdpAmount)
        external
        view
        returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPythPriceFeed {
    function pythIds(address token) external view returns (bytes32);

    function getUpdateFee(
        bytes[] calldata priceUpdateData
    ) external view returns (uint256 fee);

    function updatePriceFeeds(
        bytes[] calldata priceUpdateData,
        address refundee
    ) external payable;

    function getOffchainPrice(
        address _token,
        uint256 _offchainPrice,
        bool _maximise
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}