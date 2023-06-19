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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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

interface IVaultPriceFeed {
    function getPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256);

    function getPrimaryPrice(
        address _token,
        bool _maximise
    ) external view returns (uint256);

    function setPriceFeedConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        uint256 _spreadBasisPoints,
        bool _isStrictStable
    ) external;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

/**
 * @title Errors libraries
 * @author Position Exchange
 * @notice Defines the error messages emitted by the different contracts of the Position Exchange protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - P = Pausable
 *  - A = Amm
 */
library Errors {
    //common errors

    //contract specific errors
    //    string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
    string public constant VL_EMPTY_ADDRESS = "2";
    string public constant VL_INVALID_QUANTITY = "3"; // 'IQ'
    string public constant VL_INVALID_LEVERAGE = "4"; // 'IL'
    string public constant VL_INVALID_CLOSE_QUANTITY = "5"; // 'ICQ'
    string public constant VL_INVALID_CLAIM_FUND = "6"; // 'ICF'
    string public constant VL_NOT_ENOUGH_MARGIN_RATIO = "7"; // 'NEMR'
    string public constant VL_NO_POSITION_TO_REMOVE = "8"; // 'NPTR'
    string public constant VL_NO_POSITION_TO_ADD = "9"; // 'NPTA'
    string public constant VL_INVALID_QUANTITY_INTERNAL_CLOSE = "10"; // 'IQIC'
    string public constant VL_NOT_ENOUGH_LIQUIDITY = "11"; // 'NELQ'
    string public constant VL_INVALID_REMOVE_MARGIN = "12"; // 'IRM'
    string public constant VL_NOT_COUNTERPARTY = "13"; // 'IRM'
    string public constant VL_INVALID_INPUT = "14"; // 'IP'
    string public constant VL_SETTLE_FUNDING_TOO_EARLY = "15"; // 'SFTE'
    string public constant VL_LONG_PRICE_THAN_CURRENT_PRICE = "16"; // '!B'
    string public constant VL_SHORT_PRICE_LESS_CURRENT_PRICE = "17"; // '!S'
    string public constant VL_INVALID_SIZE = "18"; // ''
    string public constant VL_NOT_WHITELIST_MANAGER = "19"; // ''
    string public constant VL_INVALID_ORDER = "20"; // ''
    string public constant VL_ONLY_PENDING_ORDER = "21"; // ''
    string public constant VL_MUST_SAME_SIDE_SHORT = "22.1";
    string public constant VL_MUST_SAME_SIDE_LONG = "22.2";
    string public constant VL_MUST_SMALLER_REVERSE_QUANTITY = "23";
    string public constant VL_MUST_CLOSE_TO_INDEX_PRICE_SHORT = "24.1";
    string public constant VL_MUST_CLOSE_TO_INDEX_PRICE_LONG = "24.2";
    string public constant VL_MARKET_ORDER_MUST_CLOSE_TO_INDEX_PRICE = "25";
    string public constant VL_EXCEED_MAX_NOTIONAL = "26";
    string public constant VL_MUST_HAVE_POSITION = "27";
    string public constant VL_MUST_REACH_CONDITION = "28";
    string public constant VL_ONLY_POSITION_STRATEGY_ORDER = "29";
    string public constant VL_ONLY_POSITION_HOUSE = "30";
    string public constant VL_ONLY_VALIDATED_TRIGGERS = "31";
    string public constant VL_INVALID_CONDITION = "32";
    string public constant VL_MUST_BE_INTEGER = "33";

    string public constant V_CALLER_NOT_WHITELISTED = "V-40101";
    string public constant V_ONLY_FUTURX_GATEWAY = "V-40102";
    string public constant V_TOKEN_NOT_WHITELISTED = "V-40001";
    string public constant V_COLLATERAL_LESS_THAN_FEE = "V-40002";
    string public constant V_MIN_BORROWING_RATE_NOT_REACHED = "V-40003";
    string public constant V_MAX_BORROWING_RATE_EXCEEDED = "V-40004";
    string public constant V_MAX_BORROWING_RATE_FACTOR_EXCEEDED = "V-40005";
    string public constant V_DEPOSIT_AMOUNT_MUST_NOT_BE_ZERO = "V-40006";
    string public constant V_SWAP_IS_NOT_SUPPORTED = "V-40007";
    string public constant V_DUPLICATE_TOKENS = "V-40008";
    string public constant V_WITHDRAW_AMOUNT_MUST_NOT_BE_ZERO = "V-50001";
    string public constant V_MISSING_VAULT_UTILS = "V-50002";
    string public constant V_MISSING_VAULT_PRICE_FEED = "V-50002";
    string public constant V_USDP_AMOUNT_MUST_NOT_BE_ZERO = "V-50003";
    string public constant V_REDEMPTION_AMOUNT_MUST_NOT_BE_ZERO = "V-50004";
    string public constant V_INSUFFICIENT_BALANCE = "V-50005";
    string public constant V_INSUFFICIENT_POOL_AMOUNT = "V-50006";
    string public constant V_MAX_SHORTS_EXCEEDED = "V-50007";
    string public constant V_MAX_GAS_PRICE_EXCEEDED = "V-50008";

    string public constant FGW_CALLER_NOT_WHITELISTED = "FGW-40101";
    string public constant FGW_NOT_OWNER_OF_ORDER = "FGW-40102";
    string public constant FGW_TOKEN_MUST_BE_ETH = "FGW-40001";
    string public constant FGW_INDEX_TOKEN_MUST_NOT_BE_EMPTY = "FGW-40002";
    string public constant FGW_COLLATERAL_MUST_NOT_BE_EMPTY = "FGW-40003";
    string public constant FGW_INVALID_PATH_LENGTH = "FGW-40004";

    string public constant FGWS_CALLER_NOT_WHITELISTED = "FGWS-40101";
    string public constant FGWS_PENDING_COLLATERAL_MISMATCHED = "FGWS-40001";
    string public constant FGWS_MISSING_ACCOUNT_01 = "FGWS-40002";
    string public constant FGWS_MISSING_ACCOUNT_02 = "FGWS-40003";
    string public constant FGWS_MISSING_ACCOUNT_03 = "FGWS-40004";
    string public constant FGWS_MISSING_ACCOUNT_04 = "FGWS-40005";

    string public constant FGWU_EXECUTION_FEE_MISMATCHED = "FGWU-40001";
    string public constant FGWU_INVALID_PATH_LENGTH = "FGWU-40002";
    string public constant FGWU_MIN_LEVERAGE_NOT_REACHED = "FGWU-40003";
    string public constant FGWU_VOUCHER_IS_INACTIVE = "FGWU-40004";
    string public constant FGWU_VOUCHER_IS_EXPIRED = "FGWU-40005";
    string public constant FGWU_VOUCHER_MINIMUM_TIME_NOT_MET = "FGWU-40006";
    string public constant FGWU_V1_INSUFFICIENT_AMOUNT_01 = "FGWU-40007";
    string public constant FGWU_V1_INSUFFICIENT_AMOUNT_02 = "FGWU-40008";
    string public constant FGWU_COLLATERAL_AND_INDEX_MISMATCHED = "FGWU-40009";
    string public constant FGWU_COLLATERAL_NOT_WHITELISTED_01 = "FGWU-40010";
    string public constant FGWU_COLLATERAL_NOT_WHITELISTED_02 = "FGWU-40011";
    string public constant FGWU_COLLATERAL_MUST_NOT_BE_STABLE = "FGWU-40012";
    string public constant FGWU_COLLATERAL_MUST_BE_STABLE = "FGWU-40013";
    string public constant FGWU_INDEX_TOKEN_MUST_NOT_BE_STABLE = "FGWU-40014";
    string public constant FGWU_INDEX_TOKEN_MUST_BE_SHORTABLE = "FGWU-40015";
    string public constant FGWU_INVALID_POSITION_COLLATERAL = "FGWU-40016";
    string public constant FGWU_INVALID_PENDING_COLLATERAL = "FGWU-40017";
    string public constant FGWU_MINIMUM_SIZE_NOT_REACHED = "FGWU-40018";
    string public constant FGWU_INVALID_STEP_BASE_SIZE = "FGWU-40019";
    string public constant FGWU_INSUFFICIENT_RESERVED_AMOUNT = "FGWU-50001";

    enum CollateralManagerErrors {
        NO_ERROR
    }
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

pragma solidity ^0.8.9;

library VaultInfo {
    // TODO explain struct data for a dev
    struct Data {
        uint128 feeReserves;
        uint128 usdpAmounts;
        uint128 poolAmounts;
        uint128 reservedAmounts;
    }

    function addFees(Data storage self, uint256 feeAmount) internal {
        self.feeReserves = self.feeReserves + uint128(feeAmount);
    }

    function addUsdp(Data storage self, uint256 usdpAmount) internal {
        self.usdpAmounts = self.usdpAmounts + uint128(usdpAmount);
    }

    function subUsdp(Data storage self, uint256 usdpAmount) internal {
        self.usdpAmounts = self.usdpAmounts - uint128(usdpAmount);
    }

    function addPoolAmount(Data storage self, uint256 poolAmounts) internal {
        self.poolAmounts = self.poolAmounts + uint128(poolAmounts);
    }

    function subPoolAmount(Data storage self, uint256 poolAmounts) internal {
        require(poolAmounts <= self.poolAmounts, "Vault: poolAmount exceeded");
        self.poolAmounts = self.poolAmounts - uint128(poolAmounts);
        require(
            self.reservedAmounts <= self.poolAmounts,
            "Vault: reserved poolAmount"
        );
    }

    function increaseUsdpAmount(
        Data storage self,
        uint256 _amount,
        uint256 _maxUsdpAmount
    ) internal {
        addUsdp(self, _amount);
        if (_maxUsdpAmount != 0) {
            require(
                self.usdpAmounts <= _maxUsdpAmount,
                "Vault: Max debt amount exceeded"
            );
        }
    }

    function addReservedAmount(Data storage _self, uint256 _amount) internal {
        _self.reservedAmounts = _self.reservedAmounts + uint128(_amount);
        require(
            _self.reservedAmounts <= _self.poolAmounts,
            "Vault: reservedAmount exceeded poolAmount"
        );
    }

    function subReservedAmount(Data storage _self, uint256 _amount) internal {
        require(
            _amount <= _self.reservedAmounts,
            "Vault: reservedAmount exceeded"
        );
        _self.reservedAmounts = _self.reservedAmounts - uint128(_amount);
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./libraries/TokenConfiguration.sol";
import "./libraries/VaultInfo.sol";
import "./libraries/PositionInfo.sol";
import {Errors} from "./libraries/helpers/Errors.sol";

import "../interfaces/IVault.sol";
import "../token/interface/IUSDP.sol";
import "../interfaces/IVaultUtils.sol";
import "../interfaces/IVaultPriceFeed.sol";

contract Vault is IVault, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using TokenConfiguration for TokenConfiguration.Data;
    using VaultInfo for VaultInfo.Data;
    using PositionInfo for PositionInfo.Data;

    uint256 public constant BORROWING_RATE_PRECISION = 1000000;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    // TODO: MUST UPDATE MIN_BORROWING_RATE_INTERVAL BEFORE DEPLOY MAINNET
    //    uint256 public constant MIN_BORROWING_RATE_INTERVAL = 1 hours;
    uint256 public constant MIN_BORROWING_RATE_INTERVAL = 1;
    uint256 public constant MAX_BORROWING_RATE_FACTOR = 10000; // 1%
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant DEAFULT_DECIMALS = 18;
    uint256 public constant WEI_DECIMALS = 10 ** 18;

    IVaultPriceFeed private _priceFeed;
    IVaultUtils private _vaultUtils;

    address public usdp;
    uint256 public totalTokenWeight;
    uint256 public override mintBurnFeeBasisPoints;
    uint256 public override swapFeeBasisPoints;
    uint256 public override stableSwapFeeBasisPoints;
    uint256 public override marginFeeBasisPoints;
    uint256 public override taxBasisPoints;
    uint256 public override stableTaxBasisPoints;

    bool public override hasDynamicFees;
    bool public override inManagerMode;
    bool public override isSwapEnabled;

    // TODO: Update this config to 8 hours
    uint256 public override borrowingRateInterval;
    uint256 public override borrowingRateFactor;
    uint256 public override stableBorrowingRateFactor;

    // mapping(address => bool) public whitelistTokens;
    mapping(address => bool) public whitelistCaller;
    mapping(address => uint256) public tokenBalances;
    // mapping(address => uint256) public tokenDecimals;
    mapping(address => TokenConfiguration.Data) public tokenConfigurations;
    mapping(address => VaultInfo.Data) public vaultInfo;

    // bufferAmounts allows specification of an amount to exclude from swaps
    // this can be used to ensure a certain amount of liquidity is available for leverage positions
    mapping(address => uint256) public override bufferAmounts;

    address[] public whitelistedTokens;
    uint256 public minProfitTime;
    /* mapping(address => uint256) public feeReserves; */
    /* mapping(address => uint256) public usdpAmounts; */
    /* mapping(address => uint256) public poolAmounts; */
    /* mapping(address => uint256) public reservedAmounts; */

    mapping(address => uint256) public override globalShortSizes;
    mapping(address => uint256) public override globalShortAveragePrices;
    mapping(address => uint256) public override maxGlobalShortSizes;

    // cumulativeBorrowingRates tracks the  rates based on utilization
    mapping(address => uint256) public override cumulativeBorrowingRates;
    // lastBorrowingRateTimes tracks the last time borrowing rate was updated for a token
    mapping(address => uint256) public override lastBorrowingRateTimes;

    // positionInfo tracks all open positions entry borrowing rates
    mapping(bytes32 => PositionInfo.Data) public positionInfo;

    mapping(address => uint256) public debtAmount; // TODO: Remove later
    mapping(address => uint256) public debtAmountUsd;

    // guaranteedUsd tracks the amount of USD that is "guaranteed" by opened leverage positions
    // this value is used to calculate the redemption values for selling of USDG
    // this is an estimated amount, it is possible for the actual guaranteed value to be lower
    // in the case of sudden price decreases, the guaranteed value should be corrected
    // after liquidations are carried out
    mapping(address => uint256) private _guaranteedUsd;

    address public futurXGateway;

    uint256 public maxGasPrice;

    modifier onlyWhitelistToken(address token) {
        _validate(
            tokenConfigurations[token].isWhitelisted,
            Errors.V_TOKEN_NOT_WHITELISTED
        );
        _;
    }

    modifier onlyWhitelistCaller() {
        if (inManagerMode) {
            _validate(
                whitelistCaller[msg.sender],
                Errors.V_CALLER_NOT_WHITELISTED
            );
        }
        _;
    }

    modifier onlyFuturXGateway(address _account) {
        _validate(_account == futurXGateway, Errors.V_ONLY_FUTURX_GATEWAY);
        _;
    }

    event BuyUSDP(
        address account,
        address token,
        uint256 tokenAmount,
        uint256 usdgAmount,
        uint256 feeBasisPoints
    );
    event SellUSDP(
        address account,
        address token,
        uint256 usdgAmount,
        uint256 tokenAmount,
        uint256 feeBasisPoints
    );
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );
    event CollectFees(uint256 positionFee, uint256 borrowFee, uint256 totalFee);

    event IncreaseUsdgAmount(address token, uint256 amount);
    event DecreaseUsdgAmount(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);
    event IncreaseFeeReserves(address token, uint256 amount);
    event IncreasePositionReserves(uint256 amount);
    event DecreasePositionReserves(uint256 amount);
    event IncreaseDebtAmount(address account, uint256 amount);
    event DecreaseDebtAmount(address account, uint256 amount);

    event WhitelistCallerChanged(address account, bool oldValue, bool newValue);
    event UpdateBorrowingRate(address token, uint256 borrowingRate);

    function initialize(
        address vaultUtils_,
        address vaultPriceFeed_,
        address usdp_
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        _vaultUtils = IVaultUtils(vaultUtils_);
        _priceFeed = IVaultPriceFeed(vaultPriceFeed_);
        usdp = usdp_;

        mintBurnFeeBasisPoints = 100;
        // 1%
        swapFeeBasisPoints = 30;
        // 0.3%
        stableSwapFeeBasisPoints = 4;
        // 0.04%
        marginFeeBasisPoints = 10;
        // 0.1%
        taxBasisPoints = 50;
        // 0.5%
        stableTaxBasisPoints = 20;
        // 0.2%

        hasDynamicFees = false;
        inManagerMode = false;
        isSwapEnabled = true;

        borrowingRateInterval = 5 minutes;
        borrowingRateFactor = 600;
        stableBorrowingRateFactor = 600;
    }

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        uint256 _feeUsd
    ) external override onlyFuturXGateway(msg.sender) nonReentrant {
        _validateGasPrice();

        _updateCumulativeBorrowingRate(_collateralToken, _indexToken);
        bytes32 key = getPositionInfoKey(_account, _indexToken, _isLong);
        {
            _setCollateralToken(key, _collateralToken);
            uint256 borrowingFee = _getBorrowingFee(
                _account,
                _collateralToken,
                _indexToken,
                _isLong
            );
            _increaseDebtAmount(_account, borrowingFee);
            _updatePositionEntryBorrowingRate(key, _collateralToken);
        }

        uint256 collateralDeltaToken = _transferIn(_collateralToken);
        uint256 collateralDeltaUsd = tokenToUsdMin(
            _collateralToken,
            collateralDeltaToken
        );
        _validate(
            collateralDeltaUsd >= _feeUsd,
            Errors.V_COLLATERAL_LESS_THAN_FEE
        );

        _increaseFeeReserves(_collateralToken, _feeUsd);

        _sizeDeltaToken = adjustDecimalToToken(
            _collateralToken,
            _sizeDeltaToken
        );
        uint256 reservedAmountDelta = _increasePositionReservedAmount(
            key,
            _sizeDeltaToken,
            _entryPrice,
            _isLong
        );
        _increaseReservedAmount(_collateralToken, reservedAmountDelta);

        uint256 sizeDelta = tokenToUsdMin(_collateralToken, _sizeDeltaToken);
        if (_isLong) {
            // guaranteedUsd stores the sum of (position.size - position.collateral) for all positions
            // if a fee is charged on the collateral then guaranteedUsd should be increased by that fee amount
            // since (position.size - position.collateral) would have increased by `fee`
            _increaseGuaranteedUsd(_collateralToken, sizeDelta.add(_feeUsd));
            _decreaseGuaranteedUsd(_collateralToken, collateralDeltaUsd);
            // treat the deposited collateral as part of the pool
            _increasePoolAmount(_collateralToken, collateralDeltaToken);
            // fees need to be deducted from the pool since fees are deducted from position.collateral
            // and collateral is treated as part of the pool
            _decreasePoolAmount(
                _collateralToken,
                usdToTokenMin(_collateralToken, _feeUsd)
            );
            return;
        }

        uint256 price = _isLong
            ? getMaxPrice(_indexToken)
            : getMinPrice(_indexToken);

        if (globalShortSizes[_indexToken] == 0) {
            globalShortAveragePrices[_indexToken] = price;
        } else {
            globalShortAveragePrices[
                _indexToken
            ] = getNextGlobalShortAveragePrice(_indexToken, price, sizeDelta);
        }

        _increaseGlobalShortSize(_indexToken, sizeDelta);
    }

    function decreasePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutUsdAfterFees,
        uint256 _feeUsd
    )
        external
        override
        onlyFuturXGateway(msg.sender)
        nonReentrant
        returns (uint256)
    {
        _validateGasPrice();

        return
            _decreasePosition(
                _trader,
                _collateralToken,
                _indexToken,
                _entryPrice,
                _sizeDeltaToken,
                _isLong,
                _receiver,
                _amountOutUsdAfterFees,
                _feeUsd
            );
    }

    function _decreasePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutAfterFeesUsd,
        uint256 _feeUsd
    ) private returns (uint256) {
        _updateCumulativeBorrowingRate(_collateralToken, _indexToken);
        uint256 borrowingFee = _getBorrowingFee(
            _trader,
            _collateralToken,
            _indexToken,
            _isLong
        );
        emit CollectFees(_feeUsd, borrowingFee, _feeUsd.add(borrowingFee));

        bytes32 key = getPositionInfoKey(_trader, _indexToken, _isLong);
        _updatePositionEntryBorrowingRate(key, _collateralToken);

        if (_amountOutAfterFeesUsd > 0) {
            uint256 prevDebt = _getDebtAmount(_trader);
            uint256 nextDebt = prevDebt + borrowingFee;

            if (_amountOutAfterFeesUsd > nextDebt) {
                _decreaseDebtAmount(_trader, prevDebt);
                _amountOutAfterFeesUsd -= nextDebt;
            } else {
                _decreaseDebtAmount(_trader, _amountOutAfterFeesUsd);
                _amountOutAfterFeesUsd = 0;
            }
        } else {
            _increaseDebtAmount(_trader, borrowingFee);
        }

        _feeUsd = _feeUsd.add(borrowingFee);

        // Add fee to feeReserves open
        _increaseFeeReserves(_collateralToken, _feeUsd);

        _sizeDeltaToken = adjustDecimalToToken(
            _collateralToken,
            _sizeDeltaToken
        );
        {
            uint256 reservedAmountDelta = _decreasePositionReservedAmount(
                key,
                _sizeDeltaToken,
                _entryPrice,
                _isLong
            );
            _decreaseReservedAmount(_collateralToken, reservedAmountDelta);
        }

        uint256 sizeDelta = tokenToUsdMin(_collateralToken, _sizeDeltaToken);
        if (_isLong) {
            _decreaseGuaranteedUsd(_collateralToken, sizeDelta);
        } else {
            _decreaseGlobalShortSize(_indexToken, sizeDelta);
        }

        uint256 _amountOutUsd = _amountOutAfterFeesUsd.add(_feeUsd);
        if (_amountOutUsd == 0) {
            return 0;
        }

        if (_isLong) {
            uint256 amountOutToken = usdToTokenMin(
                _collateralToken,
                _amountOutUsd
            );
            _decreasePoolAmount(_collateralToken, amountOutToken);
        }

        uint256 amountOutAfterFeesToken = usdToTokenMin(
            _collateralToken,
            _amountOutAfterFeesUsd
        );
        _transferOut(_collateralToken, amountOutAfterFeesToken, _receiver);
        return amountOutAfterFeesToken;
    }

    // TODO: refactor later using _decreasePosition function
    function liquidatePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _positionSize,
        uint256 _positionMargin,
        bool _isLong
    ) external override onlyFuturXGateway(msg.sender) nonReentrant {
        _updateCumulativeBorrowingRate(_collateralToken, _indexToken);

        uint256 borrowingFee = _getBorrowingFee(
            _trader,
            _collateralToken,
            _indexToken,
            _isLong
        );

        bytes32 key = getPositionInfoKey(_trader, _indexToken, _isLong);

        uint256 positionAmountUsd = tokenToUsdMin(
            _collateralToken,
            _positionMargin
        );
        if (borrowingFee >= positionAmountUsd) {
            borrowingFee = positionAmountUsd;
        }
        _increaseFeeReserves(_collateralToken, borrowingFee);
        _decreaseReservedAmount(
            _collateralToken,
            positionInfo[key].reservedAmount
        );
        _decreasePoolAmount(
            _collateralToken,
            usdToTokenMin(_collateralToken, borrowingFee)
        );

        if (_isLong) {
            _decreaseGuaranteedUsd(_collateralToken, _positionSize);
        } else {
            _decreaseGlobalShortSize(_indexToken, _positionSize);
        }

        delete positionInfo[key];
    }

    function addCollateral(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _feeToken
    ) external override onlyFuturXGateway(msg.sender) nonReentrant {
        address collateralToken = _path[_path.length - 1];
        bytes32 key = getPositionInfoKey(_account, _indexToken, _isLong);
        uint256 amountInToken = _transferIn(collateralToken);
        if (_isLong) {
            _increasePoolAmount(collateralToken, amountInToken);
        }
        _updateCumulativeBorrowingRate(collateralToken, _indexToken);

        if (_feeToken > 0) {
            _increaseFeeReservesToken(collateralToken, _feeToken);
        }
    }

    function removeCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken
    ) external override onlyFuturXGateway(msg.sender) nonReentrant {
        if (_isLong) {
            _decreasePoolAmount(_collateralToken, _amountInToken);
        }
        _updateCumulativeBorrowingRate(_collateralToken, _indexToken);
        _transferOut(_collateralToken, _amountInToken, msg.sender);
    }

    function _decreaseGlobalShortSize(address _token, uint256 _amount) private {
        uint256 size = globalShortSizes[_token];
        if (_amount > size) {
            globalShortSizes[_token] = 0;
            return;
        }

        globalShortSizes[_token] = size.sub(_amount);
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextGlobalShortAveragePrice(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        uint256 size = globalShortSizes[_indexToken];
        uint256 averagePrice = globalShortAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice
            ? averagePrice.sub(_nextPrice)
            : _nextPrice.sub(averagePrice);
        uint256 delta = size.mul(priceDelta).div(averagePrice);
        bool hasProfit = averagePrice > _nextPrice;

        uint256 nextSize = size.add(_sizeDelta);
        uint256 divisor = hasProfit ? nextSize.sub(delta) : nextSize.add(delta);

        return _nextPrice.mul(nextSize).div(divisor);
    }

    function getTokenConfiguration(
        address _token
    ) external view override returns (TokenConfiguration.Data memory) {
        return tokenConfigurations[_token];
    }

    function getPositionInfo(
        address _account,
        address _indexToken,
        bool _isLong
    ) external view override returns (PositionInfo.Data memory) {
        bytes32 key = getPositionInfoKey(_account, _indexToken, _isLong);
        return positionInfo[key];
    }

    function getAvailableReservedAmount(
        address _collateralToken
    ) external view returns (uint256) {
        VaultInfo.Data memory info = vaultInfo[_collateralToken];
        return info.poolAmounts - info.reservedAmounts;
    }

    /** OWNER FUNCTIONS **/

    function setConfigToken(
        address _token,
        uint8 _tokenDecimals,
        uint64 _minProfitBps,
        uint128 _tokenWeight,
        uint128 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) public onlyOwner {
        if (!tokenConfigurations[_token].isWhitelisted) {
            whitelistedTokens.push(_token);
        }

        uint256 _totalTokenWeight = totalTokenWeight;
        // minus the old token weight
        _totalTokenWeight = _totalTokenWeight.sub(
            tokenConfigurations[_token].tokenWeight
        );
        tokenConfigurations[_token] = TokenConfiguration.Data({
            isWhitelisted: true,
            tokenDecimals: _tokenDecimals,
            minProfitBasisPoints: _minProfitBps,
            tokenWeight: _tokenWeight,
            maxUsdpAmount: _maxUsdgAmount,
            isShortableToken: _isShortable,
            isStableToken: _isStable
        });
        // reset total token weight
        totalTokenWeight = _totalTokenWeight.add(_tokenWeight);
        _validate(
            address(_vaultUtils) != address(0),
            Errors.V_MISSING_VAULT_UTILS
        );
        _validate(
            address(_priceFeed) != address(0),
            Errors.V_MISSING_VAULT_PRICE_FEED
        );
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external onlyOwner {
        _validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, "M1");
        _validate(_stableTaxBasisPoints <= MAX_FEE_BASIS_POINTS, "M2");
        _validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "M3");
        _validate(_swapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "M4");
        _validate(_stableSwapFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "M5");
        _validate(_marginFeeBasisPoints <= MAX_FEE_BASIS_POINTS, "M6");
        taxBasisPoints = _taxBasisPoints;
        stableTaxBasisPoints = _stableTaxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        swapFeeBasisPoints = _swapFeeBasisPoints;
        stableSwapFeeBasisPoints = _stableSwapFeeBasisPoints;
        marginFeeBasisPoints = _marginFeeBasisPoints;
        minProfitTime = _minProfitTime;
        hasDynamicFees = _hasDynamicFees;
    }

    function setWhitelistCaller(address caller, bool val) public onlyOwner {
        emit WhitelistCallerChanged(caller, whitelistCaller[caller], val);
        whitelistCaller[caller] = val;
    }

    function setIsSwapEnabled(bool _isSwapEnabled) external override onlyOwner {
        isSwapEnabled = _isSwapEnabled;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external override onlyOwner {
        maxGasPrice = _maxGasPrice;
    }

    function setUsdgAmount(
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        uint256 usdgAmount = usdgAmounts(_token);
        if (_amount > usdgAmount) {
            _increaseUsdpAmount(_token, _amount.sub(usdgAmount));
            return;
        }

        _decreaseUsdpAmount(_token, usdgAmount.sub(_amount));
    }

    function setBufferAmount(
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        bufferAmounts[_token] = _amount;
    }

    function setMaxGlobalShortSize(
        address _token,
        uint256 _amount
    ) external override onlyOwner {
        maxGlobalShortSizes[_token] = _amount;
    }

    function setPriceFeed(address _feed) external override onlyOwner {
        _priceFeed = IVaultPriceFeed(_feed);
    }

    function setVaultUtils(IVaultUtils _address) external override onlyOwner {
        _vaultUtils = IVaultUtils(_address);
    }

    function withdrawFees(
        address _token,
        address _receiver
    ) external override onlyOwner returns (uint256) {
        uint256 amount = uint256(vaultInfo[_token].feeReserves);
        if (amount == 0) {
            return 0;
        }
        vaultInfo[_token].feeReserves = 0;
        _transferOut(_token, amount, _receiver);
        return amount;
    }

    function setInManagerMode(bool _inManagerMode) external override onlyOwner {
        inManagerMode = _inManagerMode;
    }

    function setBorrowingRate(
        uint256 _borrowingRateInterval,
        uint256 _borrowingRateFactor,
        uint256 _stableBorrowingRateFactor
    ) external override onlyOwner {
        _validate(
            _borrowingRateInterval >= MIN_BORROWING_RATE_INTERVAL,
            Errors.V_MIN_BORROWING_RATE_NOT_REACHED
        );
        _validate(
            _borrowingRateFactor <= MAX_BORROWING_RATE_FACTOR,
            Errors.V_MAX_BORROWING_RATE_EXCEEDED
        );
        _validate(
            _stableBorrowingRateFactor <= MAX_BORROWING_RATE_FACTOR,
            Errors.V_MAX_BORROWING_RATE_FACTOR_EXCEEDED
        );
        borrowingRateInterval = _borrowingRateInterval;
        borrowingRateFactor = _borrowingRateFactor;
        stableBorrowingRateFactor = _stableBorrowingRateFactor;
    }

    /** END OWNER FUNCTIONS **/

    /// @notice Pay token to purchase USDP at the ask price
    /// @param _token the pay token
    /// @param _receiver the receiver for USDP
    function buyUSDP(
        address _token,
        address _receiver
    )
        external
        override
        onlyWhitelistCaller
        onlyWhitelistToken(_token)
        nonReentrant
        returns (uint256)
    {
        uint256 tokenAmount = _transferIn(_token);
        _validate(tokenAmount > 0, Errors.V_DEPOSIT_AMOUNT_MUST_NOT_BE_ZERO);

        _updateCumulativeBorrowingRate(_token, _token);
        uint256 price = getAskPrice(_token);

        uint256 usdpAmount = tokenAmount.mul(price).div(PRICE_PRECISION);
        usdpAmount = adjustForDecimals(usdpAmount, _token, usdp);
        _validate(usdpAmount > 0, Errors.V_USDP_AMOUNT_MUST_NOT_BE_ZERO);

        uint256 feeBasisPoints = _vaultUtils.getBuyUsdgFeeBasisPoints(
            _token,
            usdpAmount
        );

        uint256 amountAfterFees = _collectSwapFees(
            _token,
            tokenAmount,
            feeBasisPoints
        );
        uint256 mintAmount = amountAfterFees.mul(price).div(PRICE_PRECISION);
        mintAmount = adjustForDecimals(mintAmount, _token, usdp);

        _increaseUsdpAmount(_token, mintAmount);
        _increasePoolAmount(_token, amountAfterFees);

        IUSDP(usdp).mint(_receiver, mintAmount);

        emit BuyUSDP(
            _receiver,
            _token,
            tokenAmount,
            mintAmount,
            feeBasisPoints
        );
        return mintAmount;
    }

    /// @notice sell USDP for a token, at the bid price
    /// @param _token the receive token
    /// @param _receiver the receiver of the token
    function sellUSDP(
        address _token,
        address _receiver
    )
        external
        override
        onlyWhitelistCaller
        onlyWhitelistToken(_token)
        nonReentrant
        returns (uint256)
    {
        uint256 usdpAmount = _transferIn(usdp);
        _validate(usdpAmount > 0, Errors.V_DEPOSIT_AMOUNT_MUST_NOT_BE_ZERO);

        _updateCumulativeBorrowingRate(_token, _token);

        uint256 redemptionAmount = getRedemptionAmount(_token, usdpAmount);
        _validate(
            redemptionAmount > 0,
            Errors.V_REDEMPTION_AMOUNT_MUST_NOT_BE_ZERO
        );

        _decreaseUsdpAmount(_token, usdpAmount);
        _decreasePoolAmount(_token, redemptionAmount);

        IUSDP(usdp).burn(address(this), usdpAmount);

        // the _transferIn call increased the value of tokenBalances[usdg]
        // usually decreases in token balances are synced by calling _transferOut
        // however, for usdg, the tokens are burnt, so _updateTokenBalance should
        // be manually called to record the decrease in tokens
        _updateTokenBalance(usdp);

        uint256 feeBasisPoints = _vaultUtils.getSellUsdgFeeBasisPoints(
            _token,
            usdpAmount
        );
        uint256 amountOut = _collectSwapFees(
            _token,
            redemptionAmount,
            feeBasisPoints
        );
        _validate(amountOut > 0, Errors.V_WITHDRAW_AMOUNT_MUST_NOT_BE_ZERO);

        _transferOut(_token, amountOut, _receiver);

        emit SellUSDP(_receiver, _token, usdpAmount, amountOut, feeBasisPoints);
        return amountOut;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    )
        external
        override
        onlyWhitelistToken(_tokenIn)
        onlyWhitelistToken(_tokenOut)
        returns (uint256)
    {
        return _swap(_tokenIn, _tokenOut, _receiver, true);
    }

    function swapWithoutFees(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    )
        external
        override
        onlyWhitelistToken(_tokenIn)
        onlyWhitelistToken(_tokenOut)
        onlyFuturXGateway(msg.sender)
        returns (uint256)
    {
        return _swap(_tokenIn, _tokenOut, _receiver, false);
    }

    function claimFund(
        address _collateralToken,
        address _account,
        bool _isLong,
        uint256 _amountOutUsd,
        address _receiver
    )
        external
        override
        onlyFuturXGateway(msg.sender)
        onlyWhitelistToken(_collateralToken)
        returns (uint256)
    {
        if (_amountOutUsd == 0) {
            return 0;
        }

        uint256 prevDebt = _getDebtAmount(_account);
        if (_amountOutUsd > prevDebt) {
            _decreaseDebtAmount(_account, prevDebt);
            _amountOutUsd -= prevDebt;
        } else {
            _decreaseDebtAmount(_account, _amountOutUsd);
            _amountOutUsd = 0;
        }

        if (_amountOutUsd == 0) {
            return 0;
        }

        uint256 amountOutToken = usdToTokenMin(_collateralToken, _amountOutUsd);
        _transferOut(_collateralToken, amountOutToken, _receiver);
        if (_isLong) {
            _decreasePoolAmount(_collateralToken, amountOutToken);
        }
        return amountOutToken;
    }

    function poolAmounts(
        address token
    ) external view override returns (uint256) {
        return uint256(vaultInfo[token].poolAmounts);
    }

    function priceFeed() external view override returns (address) {
        return address(_priceFeed);
    }

    function vaultUtils() external view override returns (address) {
        return address(_vaultUtils);
    }

    function isStableToken(
        address _token
    ) external view override returns (bool) {
        return tokenConfigurations[_token].isStableToken;
    }

    /// @notice get total usdpAmount by token
    /// @param _token the token address
    function usdpAmount(
        address _token
    ) external view override returns (uint256) {
        return vaultInfo[_token].usdpAmounts;
    }

    /// @notice get the target usdp amount weighted for a token
    /// @param _token the address of the token
    function getTargetUsdpAmount(
        address _token
    ) external view override returns (uint256) {
        uint256 supply = IERC20Upgradeable(usdp).totalSupply();
        if (supply == 0) {
            return 0;
        }
        uint256 weight = tokenConfigurations[_token].tokenWeight;
        return weight.mul(supply).div(totalTokenWeight);
    }

    function getBidPrice(
        address _token
    ) public view override returns (uint256) {
        return _priceFeed.getPrice(_token, true);
    }

    function getAskPrice(
        address _token
    ) public view override returns (uint256) {
        return _priceFeed.getPrice(_token, false);
    }

    function adjustDecimalToUsd(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        return adjustForDecimals(_amount, _token, usdp);
    }

    function adjustDecimalToToken(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        return adjustForDecimals(_amount, usdp, _token);
    }

    /// @notice Adjusts the amount for the decimals of the token
    /// @dev Converts the amount to the decimals of the tokenMul
    /// Eg. given convert BUSD (decimals 9) to USDP (decimals 18), amount should be amount * 10**(18-9)
    /// @param _amount the amount to be adjusted
    /// @param _tokenDiv the address of the convert token
    /// @param _tokenMul the address of the destination token
    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) public view returns (uint256) {
        uint256 decimalsDiv = _tokenDiv == usdp
            ? DEAFULT_DECIMALS
            : tokenConfigurations[_tokenDiv].tokenDecimals;
        uint256 decimalsMul = _tokenMul == usdp
            ? DEAFULT_DECIMALS
            : tokenConfigurations[_tokenMul].tokenDecimals;
        return _amount.mul(10 ** decimalsMul).div(10 ** decimalsDiv);
    }

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) public view override returns (uint256) {
        uint256 price = getBidPrice(_token);
        uint256 redemptionAmount = _usdgAmount.mul(PRICE_PRECISION).div(price);
        return adjustForDecimals(redemptionAmount, usdp, _token);
    }

    function getNextBorrowingRate(
        address _token
    ) public view override returns (uint256) {
        if (
            lastBorrowingRateTimes[_token].add(borrowingRateInterval) >
            block.timestamp
        ) {
            return 0;
        }

        uint256 intervals = block
            .timestamp
            .sub(lastBorrowingRateTimes[_token])
            .div(borrowingRateInterval);
        uint256 poolAmount = vaultInfo[_token].poolAmounts;
        if (poolAmount == 0) {
            return 0;
        }

        uint256 _borrowingRateFactor = tokenConfigurations[_token].isStableToken
            ? stableBorrowingRateFactor
            : borrowingRateFactor;
        return
            _borrowingRateFactor
                .mul(vaultInfo[_token].reservedAmounts)
                .mul(intervals)
                .div(poolAmount);
    }

    function getBorrowingFee(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256) {
        return
            _getBorrowingFee(_trader, _collateralToken, _indexToken, _isLong);
    }

    function getSwapFee(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256) {
        uint256 priceIn = getAskPrice(_tokenIn);
        uint256 priceOut = getBidPrice(_tokenOut);
        uint256 amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = adjustForDecimals(amountOut, _tokenIn, _tokenOut);

        // adjust usdgAmounts by the same usdgAmount as debt is shifted between the assets
        uint256 usdgAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
        usdgAmount = adjustForDecimals(usdgAmount, _tokenIn, usdp);

        uint256 feeBasisPoints = _vaultUtils.getSwapFeeBasisPoints(
            _tokenIn,
            _tokenOut,
            usdgAmount
        );

        uint256 afterFeeAmount = amountOut
            .mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints))
            .div(BASIS_POINTS_DIVISOR);

        return amountOut.sub(afterFeeAmount);
    }

    function getPositionInfoKey(
        address _trader,
        address _indexToken,
        bool _isLong
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(_trader, _indexToken, _isLong));
    }

    function getUtilisation(address _token) public view returns (uint256) {
        VaultInfo.Data memory _vaultInfo = vaultInfo[_token];
        uint256 poolAmount = _vaultInfo.poolAmounts;
        if (poolAmount == 0) {
            return 0;
        }
        uint256 reservedAmounts = _vaultInfo.reservedAmounts;
        return reservedAmounts.mul(BORROWING_RATE_PRECISION).div(poolAmount);
    }

    /* PRIVATE FUNCTIONS */
    function _swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver,
        bool _shouldCollectFee
    ) private returns (uint256) {
        _validate(isSwapEnabled, Errors.V_SWAP_IS_NOT_SUPPORTED);
        _validate(_tokenIn != _tokenOut, Errors.V_DUPLICATE_TOKENS);

        _updateCumulativeBorrowingRate(_tokenIn, _tokenIn);
        _updateCumulativeBorrowingRate(_tokenOut, _tokenOut);

        uint256 amountIn = _transferIn(_tokenIn);
        _validate(amountIn > 0, Errors.V_DEPOSIT_AMOUNT_MUST_NOT_BE_ZERO);

        uint256 priceIn = getAskPrice(_tokenIn);
        uint256 priceOut = getBidPrice(_tokenOut);

        uint256 amountOut = amountIn.mul(priceIn).div(priceOut);
        amountOut = adjustForDecimals(amountOut, _tokenIn, _tokenOut);

        uint256 amountOutAfterFees = amountOut;
        uint256 feeBasisPoints;
        if (_shouldCollectFee) {
            // adjust usdgAmounts by the same usdgAmount as debt is shifted between the assets
            uint256 usdgAmount = amountIn.mul(priceIn).div(PRICE_PRECISION);
            usdgAmount = adjustForDecimals(usdgAmount, _tokenIn, usdp);

            feeBasisPoints = _vaultUtils.getSwapFeeBasisPoints(
                _tokenIn,
                _tokenOut,
                usdgAmount
            );

            amountOutAfterFees = _collectSwapFees(
                _tokenOut,
                amountOut,
                feeBasisPoints
            );

            _increaseUsdpAmount(_tokenIn, usdgAmount);
            _decreaseUsdpAmount(_tokenOut, usdgAmount);
        }

        _increasePoolAmount(_tokenIn, amountIn);
        _decreasePoolAmount(_tokenOut, amountOut);

        // validate buffer amount
        _validate(
            vaultInfo[_tokenOut].poolAmounts >= bufferAmounts[_tokenOut],
            Errors.V_INSUFFICIENT_POOL_AMOUNT
        );

        _transferOut(_tokenOut, amountOutAfterFees, _receiver);

        emit Swap(
            _receiver,
            _tokenIn,
            _tokenOut,
            amountIn,
            amountOut,
            amountOutAfterFees,
            feeBasisPoints
        );

        return amountOutAfterFees;
    }

    function _updateCumulativeBorrowingRate(
        address _collateralToken,
        address _indexToken
    ) private {
        bool shouldUpdate = _vaultUtils.updateCumulativeBorrowingRate(
            _collateralToken,
            _indexToken
        );
        if (!shouldUpdate) {
            return;
        }

        if (lastBorrowingRateTimes[_collateralToken] == 0) {
            lastBorrowingRateTimes[_collateralToken] = block
                .timestamp
                .div(borrowingRateInterval)
                .mul(borrowingRateInterval);
            return;
        }

        if (
            lastBorrowingRateTimes[_collateralToken].add(
                borrowingRateInterval
            ) > block.timestamp
        ) {
            return;
        }

        uint256 borrowingRate = getNextBorrowingRate(_collateralToken);
        cumulativeBorrowingRates[_collateralToken] = cumulativeBorrowingRates[
            _collateralToken
        ].add(borrowingRate);
        lastBorrowingRateTimes[_collateralToken] = block
            .timestamp
            .div(borrowingRateInterval)
            .mul(borrowingRateInterval);

        emit UpdateBorrowingRate(
            _collateralToken,
            cumulativeBorrowingRates[_collateralToken]
        );
    }

    function _updatePositionEntryBorrowingRate(
        bytes32 _key,
        address _collateralToken
    ) private {
        positionInfo[_key].setEntryBorrowingRates(
            cumulativeBorrowingRates[_collateralToken]
        );
    }

    function _setCollateralToken(
        bytes32 _key,
        address _collateralToken
    ) private {
        positionInfo[_key].setCollateralToken(_collateralToken);
    }

    function _getBorrowingFee(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) private view returns (uint256) {
        bytes32 _key = getPositionInfoKey(_trader, _indexToken, _isLong);
        PositionInfo.Data memory _positionInfo = positionInfo[_key];
        uint256 borrowingFee = _vaultUtils.getBorrowingFee(
            _collateralToken,
            tokenToUsdMin(_collateralToken, _positionInfo.reservedAmount),
            _positionInfo.entryBorrowingRates
        );
        return borrowingFee;
    }

    function _transferIn(address _token) private returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;
        return nextBalance.sub(prevBalance);
    }

    function _transferOut(
        address _token,
        uint256 _amount,
        address _receiver
    ) private {
        if (_amount == 0) {
            return;
        }
        uint256 prevBalance = tokenBalances[_token];
        _validate(prevBalance >= _amount, Errors.V_INSUFFICIENT_BALANCE);
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
    }

    /// Calculate and collect swap fees
    /// @param _token the token to collect fees
    /// @param _amount the amount to collect
    /// @param _feeBasisPoints the fee rate
    /// Eg. given _feeBasisPoints = 100 (1% or 100/10000), _amount = 1000, the fee is 10, the amount after fee is 990
    function _collectSwapFees(
        address _token,
        uint256 _amount,
        uint256 _feeBasisPoints
    ) private returns (uint256) {
        uint256 afterFeeAmount = _amount
            .mul(BASIS_POINTS_DIVISOR.sub(_feeBasisPoints))
            .div(BASIS_POINTS_DIVISOR);

        uint256 feeAmount = _amount.sub(afterFeeAmount);
        // cr_increaseUsdpAmount
        _increaseFeeReservesToken(_token, feeAmount);
        // emit CollectSwapFees(_token, tokenToUsdMin(_token, feeAmount), feeAmount);
        return afterFeeAmount;
    }

    /// Increase usdp amount for a token
    /// @dev this function may reverted if the total amount for a token exceeds the maximum amount for a token
    /// @param _token the token to increase
    /// @param _amount the amount to increase
    function _increaseUsdpAmount(address _token, uint256 _amount) private {
        vaultInfo[_token].increaseUsdpAmount(
            _amount,
            tokenConfigurations[_token].getMaxUsdpAmount()
        );
        emit IncreaseUsdgAmount(_token, _amount);
    }

    /// Decrease usdp amount for a token
    /// @param _token the usdp amount map to a token
    /// @param _amount the usdp amount
    function _decreaseUsdpAmount(address _token, uint256 _amount) private {
        uint256 value = vaultInfo[_token].usdpAmounts;
        // since USDP can be minted using multiple assets
        // it is possible for the USDP debt for a single asset to be less than zero
        // the USDP debt is capped to zero for this case
        if (value <= _amount) {
            vaultInfo[_token].usdpAmounts = 0;
            emit DecreaseUsdgAmount(_token, value);
            return;
        }
        vaultInfo[_token].subUsdp(_amount);
        emit DecreaseUsdgAmount(_token, _amount);
    }

    /// Increase the pool amount for a token
    /// @param _token the token address
    /// @param _amount the deposited amount after fees
    function _increasePoolAmount(address _token, uint256 _amount) private {
        vaultInfo[_token].addPoolAmount(_amount);
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        _validate(
            vaultInfo[_token].poolAmounts <= balance,
            Errors.V_INSUFFICIENT_POOL_AMOUNT
        );
        emit IncreasePoolAmount(_token, _amount);
    }

    function _decreasePoolAmount(address _token, uint256 _amount) private {
        vaultInfo[_token].subPoolAmount(_amount);
        emit DecreasePoolAmount(_token, _amount);
    }

    function _increaseReservedAmount(address _token, uint256 _amount) private {
        vaultInfo[_token].addReservedAmount(_amount);
        emit IncreaseReservedAmount(_token, _amount);
    }

    function _decreaseReservedAmount(address _token, uint256 _amount) private {
        vaultInfo[_token].subReservedAmount(_amount);
        emit DecreaseReservedAmount(_token, _amount);
    }

    function _increasePositionReservedAmount(
        bytes32 _key,
        uint256 _amount,
        uint256 _entryPrice,
        bool _isLong
    ) private returns (uint256 delta) {
        delta = _isLong ? _amount : _entryPrice.mul(_amount).div(WEI_DECIMALS);
        _increasePositionReservedAmount(_key, delta);
    }

    function _increasePositionReservedAmount(
        bytes32 _key,
        uint256 _amount
    ) private {
        positionInfo[_key].addReservedAmount(_amount);
        emit IncreasePositionReserves(_amount);
    }

    function _decreasePositionReservedAmount(
        bytes32 _key,
        uint256 _amount,
        uint256 _entryPrice,
        bool _isLong
    ) private returns (uint256 delta) {
        if (_isLong) {
            delta = _amount;
            return _decreasePositionReservedAmount(_key, delta);
        }

        if (_entryPrice == 0) {
            delta = positionInfo[_key].reservedAmount;
            return _decreasePositionReservedAmount(_key, delta);
        }

        delta = _entryPrice.mul(_amount).div(WEI_DECIMALS);
        return _decreasePositionReservedAmount(_key, delta);
    }

    function _decreasePositionReservedAmount(
        bytes32 _key,
        uint256 _amount
    ) private returns (uint256) {
        emit DecreasePositionReserves(_amount);
        return positionInfo[_key].subReservedAmount(_amount);
    }

    function _increaseGuaranteedUsd(
        address _token,
        uint256 _usdAmount
    ) private {
        _guaranteedUsd[_token] = _guaranteedUsd[_token].add(_usdAmount);
        emit IncreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _decreaseGuaranteedUsd(
        address _token,
        uint256 _usdAmount
    ) private {
        _guaranteedUsd[_token] = _guaranteedUsd[_token].sub(_usdAmount);
        emit DecreaseGuaranteedUsd(_token, _usdAmount);
    }

    function _increaseFeeReserves(
        address _collateralToken,
        uint256 _feeUsd
    ) private {
        uint256 feeToken = usdToTokenMin(_collateralToken, _feeUsd);
        _increaseFeeReservesToken(_collateralToken, feeToken);
    }

    function _increaseFeeReservesToken(
        address _collateralToken,
        uint256 _feeToken
    ) private {
        vaultInfo[_collateralToken].addFees(_feeToken);
        emit IncreaseFeeReserves(_collateralToken, _feeToken);
    }

    function _getDebtAmount(address _account) private returns (uint256) {
        return debtAmountUsd[_account];
    }

    function _increaseDebtAmount(address _account, uint256 _amount) private {
        debtAmountUsd[_account] += _amount;
        emit IncreaseDebtAmount(_account, _amount);
    }

    function _decreaseDebtAmount(address _account, uint256 _amount) private {
        debtAmountUsd[_account] -= _amount;
        emit DecreaseDebtAmount(_account, _amount);
    }

    function _updateTokenBalance(address _token) private {
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;
    }

    function getFeeBasisPoints(
        address _token,
        uint256 _usdpDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view override returns (uint256) {
        uint256 feesBasisPoints = _vaultUtils.getFeeBasisPoints(
            _token,
            _usdpDelta,
            _feeBasisPoints,
            _taxBasisPoints,
            _increment
        );
        return feesBasisPoints;
    }

    function allWhitelistedTokensLength()
        external
        view
        override
        returns (uint256)
    {
        return whitelistedTokens.length;
    }

    function allWhitelistedTokens(
        uint256 i
    ) external view override returns (address) {
        return whitelistedTokens[i];
    }

    function stableTokens(
        address _token
    ) external view override returns (bool) {
        return tokenConfigurations[_token].isStableToken;
    }

    function shortableTokens(
        address _token
    ) external view override returns (bool) {
        return tokenConfigurations[_token].isShortableToken;
    }

    function feeReserves(
        address _token
    ) external view override returns (uint256) {
        return uint256(vaultInfo[_token].feeReserves);
    }

    function tokenDecimals(
        address _token
    ) external view override returns (uint256) {
        return uint256(tokenConfigurations[_token].tokenDecimals);
    }

    function tokenWeights(
        address _token
    ) external view override returns (uint256) {
        return uint256(tokenConfigurations[_token].tokenWeight);
    }

    function guaranteedUsd(
        address _token
    ) external view override returns (uint256) {
        return _guaranteedUsd[_token];
    }

    function reservedAmounts(
        address _token
    ) external view override returns (uint256) {
        return uint256(vaultInfo[_token].reservedAmounts);
    }

    // @deprecated use usdpAmount
    function usdgAmounts(
        address _token
    ) public view override returns (uint256) {
        return uint256(vaultInfo[_token].usdpAmounts);
    }

    function usdpAmounts(address _token) external view returns (uint256) {
        return uint256(vaultInfo[_token].usdpAmounts);
    }

    function maxUsdgAmounts(
        address _token
    ) external view override returns (uint256) {
        return uint256(tokenConfigurations[_token].getMaxUsdpAmount());
    }

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        uint256 price = getMinPrice(_token);
        uint256 decimals = tokenConfigurations[_token].tokenDecimals;
        return _tokenAmount.mul(price).div(10 ** decimals);
    }

    function tokenToUsdMax(
        address _token,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        uint256 price = getMaxPrice(_token);
        uint256 decimals = tokenConfigurations[_token].tokenDecimals;
        return _tokenAmount.mul(price).div(10 ** decimals);
    }

    function tokenToUsdMinWithAdjustment(
        address _token,
        uint256 _tokenAmount
    ) public view returns (uint256) {
        uint256 usdAmount = tokenToUsdMin(_token, _tokenAmount);
        return adjustForDecimals(usdAmount, usdp, _token);
    }

    function usdToTokenMax(
        address _token,
        uint256 _usdAmount
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return usdToToken(_token, _usdAmount, getMinPrice(_token));
    }

    function usdToTokenMinWithAdjustment(
        address _token,
        uint256 _usdAmount
    ) public view returns (uint256) {
        uint256 tokenAmount = usdToTokenMin(_token, _usdAmount);
        return adjustForDecimals(tokenAmount, _token, usdp);
    }

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return usdToToken(_token, _usdAmount, getMaxPrice(_token));
    }

    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        uint256 decimals = tokenConfigurations[_token].tokenDecimals;
        return _usdAmount.mul(10 ** decimals).div(_price);
    }

    function getMaxPrice(
        address _token
    ) public view override returns (uint256) {
        return IVaultPriceFeed(_priceFeed).getPrice(_token, true);
    }

    function getMinPrice(
        address _token
    ) public view override returns (uint256) {
        return IVaultPriceFeed(_priceFeed).getPrice(_token, false);
    }

    function isWhitelistedTokens(
        address _token
    ) external view override returns (bool) {
        return tokenConfigurations[_token].isWhitelisted;
    }

    function _increaseGlobalShortSize(
        address _token,
        uint256 _amount
    ) internal {
        globalShortSizes[_token] = globalShortSizes[_token].add(_amount);

        uint256 maxSize = maxGlobalShortSizes[_token];
        if (maxSize != 0) {
            _validate(
                globalShortSizes[_token] <= maxSize,
                Errors.V_MAX_SHORTS_EXCEEDED
            );
        }
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateGasPrice() private view {
        if (maxGasPrice == 0) {
            return;
        }
        _validate(tx.gasprice <= maxGasPrice, Errors.V_MAX_GAS_PRICE_EXCEEDED);
    }

    function _validate(bool _condition, string memory _errorCode) private view {
        require(_condition, _errorCode);
    }
}

pragma solidity ^0.8.9;

interface IUSDP {
    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function addVault(address _vault) external;

    function removeVault(address _vault) external;
    // Other standard ERC20 functions
}