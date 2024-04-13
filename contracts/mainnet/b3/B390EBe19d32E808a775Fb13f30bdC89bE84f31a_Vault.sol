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

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IAdmin {
    function admin() external view returns (address);

    function setAdmin(address _admin) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IVaultPyth.sol";
import "./interfaces/IVaultPriceFeed.sol";
import "./interfaces/IVaultAfterHook.sol";
import "./interfaces/IBasePositionManager.sol";

contract Vault is ReentrancyGuardUpgradeable, OwnableUpgradeable, IVaultPyth {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Position {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnl;
        uint256 lastIncreasedTime;
    }

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant USDP_DECIMALS = 18;
    uint256 public constant MAX_FEE_BASIS_POINTS = 500; // 5%
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%

    bool public override isInitialized;
    bool public override isLeverageEnabled;

    address public errorController;

    address public override router;
    address public override priceFeed;

    address public override collateralToken;
    uint256 public override whitelistedTokenCount;

    uint256 public override maxLeverage;

    uint256 public override liquidationFeeUsd;
    uint256 public override taxBasisPoints;
    uint256 public override mintBurnFeeBasisPoints;
    uint256 public override marginFeeBasisPoints;

    uint256 public override minProfitTime;

    uint256 public override fundingInterval;
    uint256 public override fundingRateFactor;

    bool public includeAmmPrice;
    bool public useSwapPricing;

    uint256 public override maxGasPrice;

    mapping(address => mapping(address => bool))
        public
        override approvedRouters;
    mapping(address => bool) public override isLiquidator;
    address public override plpManager;

    address[] public override allWhitelistedTokens;

    mapping(address => bool) public override whitelistedTokens;
    mapping(address => uint256) public override tokenDecimals;
    mapping(address => uint256) public override minProfitBasisPoints;
    mapping(address => bool) public override stableTokens;
    mapping(address => bool) public override shortableTokens;

    // tokenBalances is used only to determine _transferIn values
    mapping(address => uint256) public override tokenBalances;

    // usdpAmount tracks the amount of USDP debt for collateral token
    uint256 public override usdpAmount;

    // maxUsdpAmount allows setting a max amount of USDP debt
    uint256 public override maxUsdpAmount;

    // poolAmount tracks the number of collateral token that can be used for leverage
    // this is tracked separately from tokenBalances to exclude funds that are deposited as margin collateral
    uint256 public override poolAmount;

    // reservedAmounts tracks the number of tokens reserved for open leverage positions
    mapping(address => mapping(bool => uint256))
        public
        override reservedAmounts;

    // total reserved amount for open leverage positions
    uint256 public override totalReservedAmount;

    // cumulativeFundingRates tracks the funding rates based on utilization
    mapping(address => mapping(bool => uint256))
        public
        override cumulativeFundingRates;
    // lastFundingTimes tracks the last time funding was updated for a token
    mapping(address => mapping(bool => uint256))
        public
        override lastFundingTimes;

    // positions tracks all open positions
    mapping(bytes32 => Position) public positions;

    // feeReserve tracks the amount of trading fee
    uint256 public override feeReserve;

    mapping(address => uint256) public override globalShortSizes;
    mapping(address => uint256) public override globalShortAveragePrices;
    mapping(address => uint256) public override maxGlobalShortSizes;

    mapping(address => uint256) public override globalLongSizes;
    mapping(address => uint256) public override globalLongAveragePrices;
    mapping(address => uint256) public override maxGlobalLongSizes;

    mapping(uint256 => string) public errors;

    address public afterHook;
    mapping(address => uint256) public maxLeveragePerToken;

    address public positionRouter;

    event LiquidityAdded(
        uint256 tokenAmount,
        uint256 usdpAmount,
        uint256 feeBasisPoints
    );
    event LiquidityRemoved(
        uint256 usdpAmount,
        uint256 tokenAmount,
        uint256 feeBasisPoints
    );

    event IncreasePosition(
        bytes32 key,
        address account,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    event UpdateFundingRate(
        address indexed token,
        bool indexed isLong,
        uint256 fundingRate
    );
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);

    event CollectMarginFees(uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(uint256 amount);
    event IncreasePoolAmount(uint256 amount);
    event DecreasePoolAmount(uint256 amount);
    event IncreaseUsdpAmount(uint256 amount);
    event DecreaseUsdpAmount(uint256 amount);
    event IncreaseReservedAmount(
        address indexed token,
        bool indexed isLong,
        uint256 amount
    );
    event DecreaseReservedAmount(
        address indexed token,
        bool indexed isLong,
        uint256 amount
    );

    function initialize(
        address _collateralToken,
        uint256 _liquidationFeeUsd,
        uint256 _fundingRateFactor
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        _validate(_liquidationFeeUsd <= MAX_LIQUIDATION_FEE_USD, 5);
        _validate(_fundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 7);

        isLeverageEnabled = true;
        maxLeverage = 50 * 10000; // 50x
        taxBasisPoints = 50; // 0.5%
        mintBurnFeeBasisPoints = 30; // 0.3%
        marginFeeBasisPoints = 10; // 0.1%
        fundingInterval = 1 hours;
        includeAmmPrice = true;

        collateralToken = _collateralToken;
        liquidationFeeUsd = _liquidationFeeUsd;
        fundingRateFactor = _fundingRateFactor;
    }

    function setParams(address _router, address _priceFeed) external {
        _checkOwner();
        _validate(!isInitialized, 0);

        isInitialized = true;

        router = _router;
        priceFeed = _priceFeed;
    }

    function setErrorController(address _errorController) external {
        _checkOwner();
        errorController = _errorController;
    }

    function setError(
        uint256 _errorCode,
        string calldata _error
    ) external override {
        require(
            msg.sender == errorController,
            "Vault: invalid errorController"
        );
        errors[_errorCode] = _error;
    }

    function allWhitelistedTokensLength()
        external
        view
        override
        returns (uint256)
    {
        return allWhitelistedTokens.length;
    }

    function setPlpManager(address _manager) external override {
        _checkOwner();
        plpManager = _manager;
    }

    function setLiquidator(
        address _liquidator,
        bool _isActive
    ) external override {
        _checkOwner();
        isLiquidator[_liquidator] = _isActive;
    }

    function setIsLeverageEnabled(bool _isLeverageEnabled) external override {
        _checkOwner();
        isLeverageEnabled = _isLeverageEnabled;
    }

    function setMaxGasPrice(uint256 _maxGasPrice) external override {
        _checkOwner();
        maxGasPrice = _maxGasPrice;
    }

    function setPriceFeed(address _priceFeed) external override {
        _checkOwner();
        priceFeed = _priceFeed;
    }

    function setMaxLeverage(uint256 _maxLeverage) external override {
        _checkOwner();
        _validate(_maxLeverage > MIN_LEVERAGE, 1);
        maxLeverage = _maxLeverage;
    }

    function setMaxLeveragePerToken(
        address _token,
        uint256 _maxLeverage
    ) external {
        _checkOwner();
        _validate(_maxLeverage == 0 || _maxLeverage > MIN_LEVERAGE, 1);
        _validate(whitelistedTokens[_token], 8);
        maxLeveragePerToken[_token] = _maxLeverage;
    }

    function setMaxGlobalSize(
        address _token,
        uint256 _longAmount,
        uint256 _shortAmount
    ) external override {
        _checkOwner();

        maxGlobalLongSizes[_token] = _longAmount;
        maxGlobalShortSizes[_token] = _shortAmount;
    }

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime
    ) external override {
        _checkOwner();
        _validate(_taxBasisPoints <= MAX_FEE_BASIS_POINTS, 2);
        _validate(_mintBurnFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 3);
        _validate(_marginFeeBasisPoints <= MAX_FEE_BASIS_POINTS, 4);
        _validate(_liquidationFeeUsd <= MAX_LIQUIDATION_FEE_USD, 5);
        taxBasisPoints = _taxBasisPoints;
        mintBurnFeeBasisPoints = _mintBurnFeeBasisPoints;
        marginFeeBasisPoints = _marginFeeBasisPoints;
        liquidationFeeUsd = _liquidationFeeUsd;
        minProfitTime = _minProfitTime;
    }

    function setFundingRate(
        uint256 _fundingInterval,
        uint256 _fundingRateFactor
    ) external override {
        _checkOwner();
        _validate(_fundingInterval >= MIN_FUNDING_RATE_INTERVAL, 6);
        _validate(_fundingRateFactor <= MAX_FUNDING_RATE_FACTOR, 7);
        fundingInterval = _fundingInterval;
        fundingRateFactor = _fundingRateFactor;
    }

    function setMaxUsdpAmounts(uint256 _maxUsdpAmounts) external override {
        _checkOwner();

        maxUsdpAmount = _maxUsdpAmounts;
    }

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _minProfitBps,
        bool _isStable,
        bool _isShortable
    ) external override {
        _checkOwner();
        // increment token count for the first time
        if (!whitelistedTokens[_token]) {
            whitelistedTokenCount += 1;
            allWhitelistedTokens.push(_token);
        }

        whitelistedTokens[_token] = true;
        tokenDecimals[_token] = _tokenDecimals;
        minProfitBasisPoints[_token] = _minProfitBps;
        stableTokens[_token] = _isStable;
        shortableTokens[_token] = _isShortable;

        // validate price feed
        getMaxPrice(_token);
    }

    function setPositionRouter(
        address _positionRouter
    ) external override {
        positionRouter = _positionRouter;
    }

    function clearTokenConfig(address _token) external {
        _checkOwner();
        require(
            _token != collateralToken,
            "Vault: Cannot clear collateralToken"
        );
        _validate(whitelistedTokens[_token], 8);
        delete whitelistedTokens[_token];
        delete tokenDecimals[_token];
        delete minProfitBasisPoints[_token];
        delete stableTokens[_token];
        delete shortableTokens[_token];
        whitelistedTokenCount -= 1;
    }

    function withdrawFees(
        address _receiver
    ) external override returns (uint256) {
        _checkOwner();
        uint256 amount = feeReserve;
        if (amount == 0) {
            return 0;
        }
        feeReserve = 0;
        _transferOut(amount, _receiver);
        return amount;
    }

    function addRouter(address _router) external {
        approvedRouters[msg.sender][_router] = true;
    }

    function removeRouter(address _router) external {
        approvedRouters[msg.sender][_router] = false;
    }

    function setUsdpAmount(uint256 _amount) external override {
        _checkOwner();

        uint256 _usdpAmount = usdpAmount;
        if (_amount > _usdpAmount) {
            _increaseUsdpAmount(_amount - _usdpAmount);
            return;
        }

        _decreaseUsdpAmount(_usdpAmount - _amount);
    }

    // deposit into the pool without minting USDP tokens
    // useful in allowing the pool to become over-collaterised
    function directPoolDeposit() external override nonReentrant {
        uint256 tokenAmount = _transferIn(collateralToken);
        _validate(tokenAmount > 0, 9);
        _increasePoolAmount(tokenAmount);
        emit DirectPoolDeposit(tokenAmount);
    }

    function estimateUSDPOut(
        uint256 _amount
    ) external view override returns (uint256) {
        _validate(_amount > 0, 9);

        uint256 price = getMinPrice(collateralToken);

        uint256 feeBasisPoints = mintBurnFeeBasisPoints;

        uint256 afterFeeAmount = (_amount *
            (BASIS_POINTS_DIVISOR - feeBasisPoints)) / BASIS_POINTS_DIVISOR;

        uint256 mintAmount = (afterFeeAmount * price) / PRICE_PRECISION;
        mintAmount = _adjustForRawDecimals(
            mintAmount,
            tokenDecimals[collateralToken],
            USDP_DECIMALS
        );

        return mintAmount;
    }

    function estimateTokenIn(
        uint256 _usdpAmount
    ) external view override returns (uint256) {
        _validate(_usdpAmount > 0, 10);

        uint256 price = getMinPrice(collateralToken);

        _usdpAmount = _adjustForRawDecimals(
            _usdpAmount,
            USDP_DECIMALS,
            tokenDecimals[collateralToken]
        );

        uint256 amountAfterFees = (_usdpAmount * PRICE_PRECISION) / price;
        uint256 feeBasisPoints = mintBurnFeeBasisPoints;

        return
            (amountAfterFees * BASIS_POINTS_DIVISOR) /
            (BASIS_POINTS_DIVISOR - feeBasisPoints);
    }

    function addLiquidity() external override nonReentrant returns (uint256) {
        _validatePlpManager();

        address _collateralToken = collateralToken;
        useSwapPricing = true;

        uint256 tokenAmount = _transferIn(_collateralToken);
        _validate(tokenAmount > 0, 9);

        uint256 price = getMinPrice(_collateralToken);

        uint256 feeBasisPoints = mintBurnFeeBasisPoints;

        uint256 amountAfterFees = (tokenAmount *
            (BASIS_POINTS_DIVISOR - feeBasisPoints)) / BASIS_POINTS_DIVISOR;

        uint256 mintAmount = (amountAfterFees * price) / PRICE_PRECISION;

        mintAmount = _adjustForRawDecimals(
            mintAmount,
            tokenDecimals[_collateralToken],
            USDP_DECIMALS
        );
        _validate(mintAmount > 0, 10);

        _increaseUsdpAmount(mintAmount);
        _increasePoolAmount(tokenAmount);

        emit LiquidityAdded(tokenAmount, mintAmount, feeBasisPoints);

        useSwapPricing = false;
        return mintAmount;
    }

    function removeLiquidity(
        address _receiver,
        uint256 _usdpAmount
    ) external override nonReentrant returns (uint256) {
        _validatePlpManager();
        useSwapPricing = true;

        _validate(_usdpAmount > 0, 10);

        uint256 redemptionAmount = getRedemptionAmount(_usdpAmount);

        _validate(redemptionAmount > 0, 11);

        uint256 feeBasisPoints = mintBurnFeeBasisPoints;

        uint256 amountOut = (redemptionAmount *
            (BASIS_POINTS_DIVISOR - feeBasisPoints)) / BASIS_POINTS_DIVISOR;

        _decreaseUsdpAmount(_usdpAmount);
        _decreasePoolAmount(amountOut);

        _validate(amountOut > 0, 12);

        _transferOut(amountOut, _receiver);

        emit LiquidityRemoved(_usdpAmount, amountOut, feeBasisPoints);

        useSwapPricing = false;
        return amountOut;
    }

    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external override nonReentrant {
        _validate(isLeverageEnabled, 13);
        _validateGasPrice();
        _validateRouter(_account);
        _validateTokens(_indexToken, _isLong);
        address _collateralToken = collateralToken;

        updateCumulativeFundingRate(_indexToken, _isLong);

        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 price = _isLong
            ? getMaxPrice(_indexToken)
            : getMinPrice(_indexToken);

        if (position.size == 0) {
            position.averagePrice = price;
        }

        if (position.size > 0 && _sizeDelta > 0) {
            position.averagePrice = getNextAveragePrice(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                price,
                _sizeDelta,
                position.lastIncreasedTime
            );
        }

        uint256 fee = _collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta,
            position.size,
            position.entryFundingRate
        );
        uint256 collateralDelta = _transferIn(_collateralToken);
        uint256 collateralDeltaUsd = tokenToUsdMin(
            _collateralToken,
            collateralDelta
        );

        position.collateral = position.collateral + collateralDeltaUsd;

        _validate(position.collateral >= fee, 14);

        position.collateral -= fee;
        position.entryFundingRate = getEntryFundingRate(_indexToken, _isLong);
        position.size += _sizeDelta;
        position.lastIncreasedTime = block.timestamp;

        _validate(position.size > 0, 15);
        _validatePosition(position.size, position.collateral);
        validateLiquidation(_account, _indexToken, _isLong, true);

        // reserve token to pay profits on the position
        uint256 reserveDelta = usdToCollateralTokenMax(_sizeDelta);
        position.reserveAmount += reserveDelta;
        _increaseReservedAmount(_indexToken, _isLong, reserveDelta);

        if (_isLong) {
            if (globalLongSizes[_indexToken] == 0) {
                globalLongAveragePrices[_indexToken] = price;
            } else {
                globalLongAveragePrices[
                    _indexToken
                ] = getNextGlobalLongAveragePrice(
                    _indexToken,
                    price,
                    _sizeDelta
                );
            }

            _increaseGlobalLongSize(_indexToken, _sizeDelta);
        } else {
            if (globalShortSizes[_indexToken] == 0) {
                globalShortAveragePrices[_indexToken] = price;
            } else {
                globalShortAveragePrices[
                    _indexToken
                ] = getNextGlobalShortAveragePrice(
                    _indexToken,
                    price,
                    _sizeDelta
                );
            }

            _increaseGlobalShortSize(_indexToken, _sizeDelta);
        }

        _handleAfterTrade(_account, _sizeDelta);

        emit IncreasePosition(
            key,
            _account,
            _indexToken,
            collateralDeltaUsd,
            _sizeDelta,
            _isLong,
            price,
            fee
        );
        emit UpdatePosition(
            key,
            position.size,
            position.collateral,
            position.averagePrice,
            position.entryFundingRate,
            position.reserveAmount,
            position.realisedPnl,
            price
        );
    }

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external override nonReentrant returns (uint256) {
        _validateGasPrice();
        _validateRouter(_account);
        return
            _decreasePosition(
                _account,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _isLong,
                _receiver
            );
    }

    function _decreasePosition(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) private returns (uint256) {
        _validateAddr(_receiver);
        updateCumulativeFundingRate(_indexToken, _isLong);

        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];
        _validate(position.size > 0, 16);
        _validate(position.size >= _sizeDelta, 17);
        _validate(position.collateral >= _collateralDelta, 18);

        // scrop variables to avoid stack too deep errors
        {
            uint256 reserveDelta = (position.reserveAmount * _sizeDelta) /
                position.size;
            position.reserveAmount -= reserveDelta;
            _decreaseReservedAmount(_indexToken, _isLong, reserveDelta);
        }

        (uint256 usdOut, uint256 usdOutAfterFee) = _reduceCollateral(
            _account,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong
        );

        if (position.size != _sizeDelta) {
            position.entryFundingRate = getEntryFundingRate(
                _indexToken,
                _isLong
            );
            position.size -= _sizeDelta;

            _validatePosition(position.size, position.collateral);
            validateLiquidation(_account, _indexToken, _isLong, true);

            uint256 price = _isLong
                ? getMinPrice(_indexToken)
                : getMaxPrice(_indexToken);
            emit DecreasePosition(
                key,
                _account,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _isLong,
                price,
                usdOut - usdOutAfterFee
            );
            emit UpdatePosition(
                key,
                position.size,
                position.collateral,
                position.averagePrice,
                position.entryFundingRate,
                position.reserveAmount,
                position.realisedPnl,
                price
            );
        } else {
            uint256 price = _isLong
                ? getMinPrice(_indexToken)
                : getMaxPrice(_indexToken);
            emit DecreasePosition(
                key,
                _account,
                _indexToken,
                _collateralDelta,
                _sizeDelta,
                _isLong,
                price,
                usdOut - usdOutAfterFee
            );
            emit ClosePosition(
                key,
                position.size,
                position.collateral,
                position.averagePrice,
                position.entryFundingRate,
                position.reserveAmount,
                position.realisedPnl
            );

            delete positions[key];
        }

        if (!_isLong) {
            _decreaseGlobalShortSize(_indexToken, _sizeDelta);
        } else {
            _decreaseGlobalLongSize(_indexToken, _sizeDelta);
        }

        _handleAfterTrade(_account, _sizeDelta);

        if (usdOut > 0) {
            uint256 amountOutAfterFees = usdToCollateralTokenMin(
                usdOutAfterFee
            );
            _transferOut(amountOutAfterFees, _receiver);
            return amountOutAfterFees;
        }

        return 0;
    }

    function liquidatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external override nonReentrant {
        _validate(isLiquidator[msg.sender], 19);

        // set includeAmmPrice to false to prevent manipulated liquidations
        includeAmmPrice = false;

        updateCumulativeFundingRate(_indexToken, _isLong);

        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        _validate(position.size > 0, 16);

        (uint256 liquidationState, uint256 marginFees) = validateLiquidation(
            _account,
            _indexToken,
            _isLong,
            false
        );
        _validate(liquidationState != 0, 20);
        if (liquidationState == 2) {
            // max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(
                _account,
                _indexToken,
                0,
                position.size,
                _isLong,
                _account
            );
            includeAmmPrice = true;
            return;
        }

        uint256 feeTokens = usdToCollateralTokenMin(marginFees);
        feeReserve += feeTokens;
        emit CollectMarginFees(marginFees, feeTokens);

        _decreaseReservedAmount(_indexToken, _isLong, position.reserveAmount);

        uint256 markPrice = _isLong
            ? getMinPrice(_indexToken)
            : getMaxPrice(_indexToken);
        emit LiquidatePosition(
            key,
            _account,
            _indexToken,
            _isLong,
            position.size,
            position.collateral,
            position.reserveAmount,
            position.realisedPnl,
            markPrice
        );

        if (marginFees < position.collateral) {
            uint256 remainingCollateral = position.collateral - marginFees;
            _increasePoolAmount(usdToCollateralTokenMin(remainingCollateral));
        }

        if (!_isLong) {
            _decreaseGlobalShortSize(_indexToken, position.size);
        } else {
            _decreaseGlobalLongSize(_indexToken, position.size);
        }

        delete positions[key];

        // pay the fee receiver using the pool, we assume that in general the liquidated amount should be sufficient to cover
        // the liquidation fees
        _decreasePoolAmount(usdToCollateralTokenMin(liquidationFeeUsd));
        _transferOut(usdToCollateralTokenMin(liquidationFeeUsd), _feeReceiver);

        includeAmmPrice = true;
    }

    // validateLiquidation returns (state, fees)
    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) public view override returns (uint256, uint256) {
        (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            ,
            ,
            ,
            uint256 lastIncreasedTime
        ) = getPosition(_account, _indexToken, _isLong);

        (bool hasProfit, uint256 delta) = getDelta(
            _indexToken,
            size,
            averagePrice,
            _isLong,
            lastIncreasedTime
        );
        uint256 marginFees = getFundingFee(
            _account,
            _indexToken,
            _isLong,
            size,
            entryFundingRate
        );
        marginFees += getPositionFee(_account, _indexToken, _isLong, size);

        if (!hasProfit && collateral < delta) {
            if (_raise) {
                revert("Vault: losses exceed collateral");
            }
            return (1, marginFees);
        }

        uint256 remainingCollateral = collateral;
        if (!hasProfit) {
            remainingCollateral = collateral - delta;
        }

        if (remainingCollateral < marginFees) {
            if (_raise) {
                revert("Vault: fees exceed collateral");
            }
            // cap the fees to the remainingCollateral
            return (1, remainingCollateral);
        }

        if (remainingCollateral < marginFees + liquidationFeeUsd) {
            if (_raise) {
                revert("Vault: liquidation fees exceed collateral");
            }
            return (1, marginFees);
        }

        uint256 _maxLeverage = getMaxLeverage(_indexToken);
        if (remainingCollateral * _maxLeverage < size * BASIS_POINTS_DIVISOR) {
            if (_raise) {
                revert("Vault: maxLeverage exceeded");
            }
            return (2, marginFees);
        }

        return (0, marginFees);
    }

    function getMaxPrice(
        address _token
    ) public view override returns (uint256) {
        return
            IVaultPriceFeed(priceFeed).getPrice(
                _token,
                true,
                includeAmmPrice,
                useSwapPricing
            );
    }

    function getMinPrice(
        address _token
    ) public view override returns (uint256) {
        return
            IVaultPriceFeed(priceFeed).getPrice(
                _token,
                false,
                includeAmmPrice,
                useSwapPricing
            );
    }

    function getRedemptionAmount(
        uint256 _usdpAmount
    ) public view override returns (uint256) {
        address _token = collateralToken;
        uint256 price = getMaxPrice(_token);
        uint256 redemptionAmount = (_usdpAmount * PRICE_PRECISION) / price;
        return
            _adjustForRawDecimals(
                redemptionAmount,
                USDP_DECIMALS,
                tokenDecimals[_token]
            );
    }

    function adjustForDecimals(
        uint256 _amount,
        address _tokenDiv,
        address _tokenMul
    ) public view returns (uint256) {
        return
            _adjustForRawDecimals(
                _amount,
                tokenDecimals[_tokenDiv],
                tokenDecimals[_tokenMul]
            );
    }

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) public view override returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }
        uint256 price = getMinPrice(_token);
        uint256 decimals = tokenDecimals[_token];
        return (_tokenAmount * price) / (10 ** decimals);
    }

    function usdToCollateralTokenMax(
        uint256 _usdAmount
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return
            usdToToken(
                collateralToken,
                _usdAmount,
                getMinPrice(collateralToken)
            );
    }

    function usdToCollateralTokenMin(
        uint256 _usdAmount
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        return
            usdToToken(
                collateralToken,
                _usdAmount,
                getMaxPrice(collateralToken)
            );
    }

    function usdToToken(
        address _token,
        uint256 _usdAmount,
        uint256 _price
    ) public view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        uint256 decimals = tokenDecimals[_token];
        return (_usdAmount * (10 ** decimals)) / _price;
    }

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong
    )
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        )
    {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        uint256 realisedPnl = position.realisedPnl > 0
            ? uint256(position.realisedPnl)
            : uint256(-position.realisedPnl);
        return (
            position.size, // 0
            position.collateral, // 1
            position.averagePrice, // 2
            position.entryFundingRate, // 3
            position.reserveAmount, // 4
            realisedPnl, // 5
            position.realisedPnl >= 0, // 6
            position.lastIncreasedTime // 7
        );
    }

    function getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong));
    }

    function updateCumulativeFundingRate(
        address _indexToken,
        bool _isLong
    ) public {
        address indexToken = _indexToken;
        bool isLong = _isLong;

        if (lastFundingTimes[indexToken][isLong] == 0) {
            lastFundingTimes[indexToken][isLong] =
                (block.timestamp / fundingInterval) *
                fundingInterval;
            return;
        }

        if (
            lastFundingTimes[indexToken][isLong] + fundingInterval >
            block.timestamp
        ) {
            return;
        }

        uint256 fundingRate = getNextFundingRate(indexToken, isLong);
        cumulativeFundingRates[indexToken][isLong] += fundingRate;
        lastFundingTimes[indexToken][isLong] =
            (block.timestamp / fundingInterval) *
            fundingInterval;

        emit UpdateFundingRate(
            indexToken,
            isLong,
            cumulativeFundingRates[indexToken][isLong]
        );
    }

    function getNextFundingRate(
        address _token,
        bool _isLong
    ) public view override returns (uint256) {
        uint256 poolSize = IBasePositionManager(positionRouter).maxGlobalLongSizes(_token) / 1e30;

        if (
            lastFundingTimes[_token][_isLong] + fundingInterval >
            block.timestamp
        ) {
            return 0;
        }

        uint256 intervals = (block.timestamp -
            lastFundingTimes[_token][_isLong]) / fundingInterval;
        if (poolSize == 0) {
            return 0;
        }

        return
            (fundingRateFactor * reservedAmounts[_token][_isLong] * intervals) /
            poolSize;
    }

    function getUtilisation(
        address _token,
        bool _isLong
    ) public view returns (uint256) {
        if (poolAmount == 0) {
            return 0;
        }

        return
            (reservedAmounts[_token][_isLong] * FUNDING_RATE_PRECISION) /
            poolAmount;
    }

    function getPositionLeverage(
        address _account,
        address _indexToken,
        bool _isLong
    ) public view returns (uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        _validate(position.collateral > 0, 21);
        return (position.size * BASIS_POINTS_DIVISOR) / position.collateral;
    }

    // for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    // for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) public view returns (uint256) {
        (bool hasProfit, uint256 delta) = getDelta(
            _indexToken,
            _size,
            _averagePrice,
            _isLong,
            _lastIncreasedTime
        );
        uint256 nextSize = _size + _sizeDelta;
        uint256 divisor;
        if (_isLong) {
            divisor = hasProfit ? nextSize + delta : nextSize - delta;
        } else {
            divisor = hasProfit ? nextSize - delta : nextSize + delta;
        }
        return (_nextPrice * nextSize) / divisor;
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
            ? averagePrice - _nextPrice
            : _nextPrice - averagePrice;
        uint256 delta = (size * priceDelta) / averagePrice;
        bool hasProfit = averagePrice > _nextPrice;

        uint256 nextSize = size + _sizeDelta;
        uint256 divisor = hasProfit ? nextSize - delta : nextSize + delta;

        return (_nextPrice * nextSize) / divisor;
    }

    function getNextGlobalLongAveragePrice(
        address _indexToken,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        uint256 size = globalLongSizes[_indexToken];
        uint256 averagePrice = globalLongAveragePrices[_indexToken];
        uint256 priceDelta = averagePrice > _nextPrice
            ? averagePrice - _nextPrice
            : _nextPrice - averagePrice;
        uint256 delta = (size * priceDelta) / averagePrice;
        bool hasProfit = averagePrice < _nextPrice;

        uint256 nextSize = size + _sizeDelta;
        uint256 divisor = hasProfit ? nextSize + delta : nextSize - delta;

        return (_nextPrice * nextSize) / divisor;
    }

    function getGlobalShortDelta(
        uint256 _tokenPrice,
        address _token
    ) external view returns (bool, uint256) {
        uint256 size = globalShortSizes[_token];
        if (size == 0) {
            return (false, 0);
        }

        uint256 nextPrice = _tokenPrice;
        uint256 averagePrice = globalShortAveragePrices[_token];
        uint256 priceDelta = averagePrice > nextPrice
            ? averagePrice - nextPrice
            : nextPrice - averagePrice;
        uint256 delta = (size * priceDelta) / averagePrice;
        bool hasProfit = averagePrice > nextPrice;

        return (hasProfit, delta);
    }

    function getPositionDelta(
        address _account,
        address _indexToken,
        bool _isLong
    ) public view returns (bool, uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position memory position = positions[key];
        return
            getDelta(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                position.lastIncreasedTime
            );
    }

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) public view override returns (bool, uint256) {
        _validate(_averagePrice > 0, 22);
        uint256 price = _isLong
            ? getMinPrice(_indexToken)
            : getMaxPrice(_indexToken);
        uint256 priceDelta = _averagePrice > price
            ? _averagePrice - price
            : price - _averagePrice;
        uint256 delta = (_size * priceDelta) / _averagePrice;

        bool hasProfit = _isLong
            ? price > _averagePrice
            : _averagePrice > price;

        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        uint256 minBps = block.timestamp > _lastIncreasedTime + minProfitTime
            ? 0
            : minProfitBasisPoints[_indexToken];
        if (hasProfit && delta * BASIS_POINTS_DIVISOR <= _size * minBps) {
            delta = 0;
        }

        return (hasProfit, delta);
    }

    function getDeltaAtPrice(
        uint256 _markPrice,
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) public view override returns (bool, uint256) {
        _validate(_averagePrice > 0, 22);
        uint256 price = _markPrice;
        uint256 priceDelta = _averagePrice > price
            ? _averagePrice - price
            : price - _averagePrice;
        uint256 delta = (_size * priceDelta) / _averagePrice;

        bool hasProfit = _isLong
            ? price > _averagePrice
            : _averagePrice > price;

        // if the minProfitTime has passed then there will be no min profit threshold
        // the min profit threshold helps to prevent front-running issues
        uint256 minBps = block.timestamp > _lastIncreasedTime + minProfitTime
            ? 0
            : minProfitBasisPoints[_indexToken];
        if (hasProfit && delta * BASIS_POINTS_DIVISOR <= _size * minBps) {
            delta = 0;
        }

        return (hasProfit, delta);
    }

    function getEntryFundingRate(
        address _indexToken,
        bool _isLong
    ) public view returns (uint256) {
        return cumulativeFundingRates[_indexToken][_isLong];
    }

    function getFundingFee(
        address /* _account */,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) public view returns (uint256) {
        if (_size == 0) {
            return 0;
        }

        uint256 fundingRate = cumulativeFundingRates[_indexToken][_isLong] -
            _entryFundingRate;
        if (fundingRate == 0) {
            return 0;
        }

        return (_size * fundingRate) / FUNDING_RATE_PRECISION;
    }

    function getPositionFee(
        address /* _account */,
        address /* _indexToken */,
        bool /* _isLong */,
        uint256 _sizeDelta
    ) public view returns (uint256) {
        if (_sizeDelta == 0) {
            return 0;
        }
        uint256 afterFeeUsd = (_sizeDelta *
            (BASIS_POINTS_DIVISOR - marginFeeBasisPoints)) /
            BASIS_POINTS_DIVISOR;
        return _sizeDelta - afterFeeUsd;
    }

    function _reduceCollateral(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong
    ) private returns (uint256, uint256) {
        bytes32 key = getPositionKey(_account, _indexToken, _isLong);
        Position storage position = positions[key];

        uint256 fee = _collectMarginFees(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta,
            position.size,
            position.entryFundingRate
        );
        bool hasProfit;
        uint256 adjustedDelta;

        // scope variables to avoid stack too deep errors
        {
            (bool _hasProfit, uint256 delta) = getDelta(
                _indexToken,
                position.size,
                position.averagePrice,
                _isLong,
                position.lastIncreasedTime
            );
            hasProfit = _hasProfit;
            // get the proportional change in pnl
            adjustedDelta = (_sizeDelta * delta) / position.size;
        }

        uint256 usdOut;
        // transfer profits out
        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
            position.realisedPnl = position.realisedPnl + int256(adjustedDelta);

            // pay out realised profits from the pool amount for positions
            uint256 tokenAmount = usdToCollateralTokenMin(adjustedDelta);
            _decreasePoolAmount(tokenAmount);
        }

        if (!hasProfit && adjustedDelta > 0) {
            position.collateral -= adjustedDelta;

            // transfer realised losses to the pool for positions
            // realised losses for long positions are not transferred here as
            // _increasePoolAmount was already called in increasePosition for longs
            uint256 tokenAmount = usdToCollateralTokenMin(adjustedDelta);
            _increasePoolAmount(tokenAmount);

            position.realisedPnl -= int256(adjustedDelta);
        }

        // reduce the position's collateral by _collateralDelta
        // transfer _collateralDelta out
        if (_collateralDelta > 0) {
            usdOut += _collateralDelta;
            position.collateral -= _collateralDelta;
        }

        // if the position will be closed, then transfer the remaining collateral out
        if (position.size == _sizeDelta) {
            usdOut += position.collateral;
            position.collateral = 0;
        }

        // if the usdOut is more than the fee then deduct the fee from the usdOut directly
        // else deduct the fee from the position's collateral
        uint256 usdOutAfterFee = usdOut;
        if (usdOut > fee) {
            usdOutAfterFee = usdOut - fee;
        } else {
            position.collateral -= fee;
        }

        emit UpdatePnl(key, hasProfit, adjustedDelta);

        return (usdOut, usdOutAfterFee);
    }

    function _validatePosition(
        uint256 _size,
        uint256 _collateral
    ) private view {
        if (_size == 0) {
            _validate(_collateral == 0, 23);
            return;
        }
        _validate(_size >= _collateral, 24);
    }

    function _validateRouter(address _account) private view {
        if (msg.sender == _account) {
            return;
        }
        if (msg.sender == router) {
            return;
        }
        _validate(approvedRouters[_account][msg.sender], 25);
    }

    function _validateTokens(address _indexToken, bool isLong) private view {
        _validate(whitelistedTokens[_indexToken], 8);
        _validate(shortableTokens[_indexToken], 27);
        if (!isLong) {
            _validate(!stableTokens[_indexToken], 26);
        }
    }

    function _collectMarginFees(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryFundingRate
    ) private returns (uint256) {
        uint256 feeUsd = getPositionFee(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta
        );

        uint256 fundingFee = getFundingFee(
            _account,
            _indexToken,
            _isLong,
            _size,
            _entryFundingRate
        );
        feeUsd += fundingFee;

        uint256 feeTokens = usdToCollateralTokenMin(feeUsd);
        feeReserve += feeTokens;

        emit CollectMarginFees(feeUsd, feeTokens);
        return feeUsd;
    }

    function _transferIn(address _token) private returns (uint256) {
        uint256 prevBalance = tokenBalances[_token];
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;

        return nextBalance - prevBalance;
    }

    function _transferOut(uint256 _amount, address _receiver) private {
        _validateAddr(_receiver);
        address _token = collateralToken;
        IERC20Upgradeable(_token).safeTransfer(_receiver, _amount);
        tokenBalances[_token] = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
    }

    function _updateTokenBalance(address _token) private {
        uint256 nextBalance = IERC20Upgradeable(_token).balanceOf(
            address(this)
        );
        tokenBalances[_token] = nextBalance;
    }

    function _increasePoolAmount(uint256 _amount) private {
        poolAmount += _amount;
        uint256 balance = IERC20Upgradeable(collateralToken).balanceOf(
            address(this)
        );
        _validate(poolAmount <= balance, 28);
        emit IncreasePoolAmount(_amount);
    }

    function _decreasePoolAmount(uint256 _amount) private {
        require(poolAmount >= _amount, "Vault: poolAmount exceeded");
        poolAmount -= _amount;
        _validate(totalReservedAmount <= poolAmount, 29);
        emit DecreasePoolAmount(_amount);
    }

    function _increaseUsdpAmount(uint256 _amount) private {
        usdpAmount += _amount;
        if (maxUsdpAmount != 0) {
            _validate(usdpAmount <= maxUsdpAmount, 30);
        }
        emit IncreaseUsdpAmount(_amount);
    }

    function _decreaseUsdpAmount(uint256 _amount) private {
        uint256 value = usdpAmount;
        // it is possible for the USDP debt to be less than zero
        // the USDP debt is capped to zero for this case
        if (value <= _amount) {
            usdpAmount = 0;
            emit DecreaseUsdpAmount(value);
            return;
        }
        usdpAmount = value - _amount;
        emit DecreaseUsdpAmount(_amount);
    }

    function _increaseReservedAmount(
        address _token,
        bool _isLong,
        uint256 _amount
    ) private {
        reservedAmounts[_token][_isLong] += _amount;
        totalReservedAmount += _amount;
        _validate(totalReservedAmount <= poolAmount, 29);
        emit IncreaseReservedAmount(_token, _isLong, _amount);
    }

    function _decreaseReservedAmount(
        address _token,
        bool _isLong,
        uint256 _amount
    ) private {
        require(
            reservedAmounts[_token][_isLong] >= _amount,
            "Vault: insufficient reserve"
        );
        totalReservedAmount -= _amount;
        reservedAmounts[_token][_isLong] -= _amount;
        emit DecreaseReservedAmount(_token, _isLong, _amount);
    }

    function _increaseGlobalLongSize(address _token, uint256 _amount) internal {
        globalLongSizes[_token] += _amount;

        uint256 maxSize = maxGlobalLongSizes[_token];
        if (maxSize != 0) {
            require(
                globalLongSizes[_token] <= maxSize,
                "Vault: max longs exceeded"
            );
        }
    }

    function _decreaseGlobalLongSize(address _token, uint256 _amount) private {
        uint256 size = globalLongSizes[_token];
        if (_amount > size) {
            globalLongSizes[_token] = 0;
            return;
        }

        globalLongSizes[_token] = size - _amount;
    }

    function _increaseGlobalShortSize(
        address _token,
        uint256 _amount
    ) internal {
        globalShortSizes[_token] += _amount;

        uint256 maxSize = maxGlobalShortSizes[_token];
        if (maxSize != 0) {
            require(
                globalShortSizes[_token] <= maxSize,
                "Vault: max shorts exceeded"
            );
        }
    }

    function _decreaseGlobalShortSize(address _token, uint256 _amount) private {
        uint256 size = globalShortSizes[_token];
        if (_amount > size) {
            globalShortSizes[_token] = 0;
            return;
        }

        globalShortSizes[_token] = size - _amount;
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateAddr(address addr) private pure {
        require(addr != address(0), "Vault: zero addr");
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validatePlpManager() private view {
        _validate(msg.sender == plpManager, 31);
    }

    // we have this validation as a function instead of a modifier to reduce contract size
    function _validateGasPrice() private view {
        if (maxGasPrice == 0) {
            return;
        }
        _validate(tx.gasprice <= maxGasPrice, 32);
    }

    function _validate(bool _condition, uint256 _errorCode) private view {
        require(_condition, errors[_errorCode]);
    }

    function _adjustForRawDecimals(
        uint256 _amount,
        uint256 _decimalsDiv,
        uint256 _decimalsMul
    ) internal pure returns (uint256) {
        return (_amount * (10 ** _decimalsMul)) / (10 ** _decimalsDiv);
    }

    function setAfterHook(address _afterHook) external {
        _checkOwner();

        afterHook = _afterHook;
    }

    function getMaxLeverage(
        address token
    ) public view override returns (uint256 _maxLeverage) {
        if (maxLeveragePerToken[token] != 0) {
            return maxLeveragePerToken[token];
        }
        return maxLeverage;
    }

    function _handleAfterTrade(address user, uint256 volume) internal {
        if (afterHook != address(0)) {
            IVaultAfterHook(afterHook).afterTrade(user, volume);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../../access/interfaces/IAdmin.sol";

interface IBasePositionManager is IAdmin {
    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(address _token)
        external
        view
        returns (uint256);
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

interface IVaultAfterHook {
    function afterTrade(address user, uint256 volume) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token)
        external
        view
        returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getLatestPrimaryPrice(address _token)
        external
        view
        returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise)
        external
        view
        returns (uint256);

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _stalePriceThreshold
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IVault} from "./IVault.sol";

interface IVaultPyth is IVault {
    function getDeltaAtPrice(
        uint256 _markPrice,
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getMaxLeverage(
        address token
    ) external view returns (uint256 _maxLeverage);

    function setPositionRouter(
        address _positionRouter
    ) external;
}