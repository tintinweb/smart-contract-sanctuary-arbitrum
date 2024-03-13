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

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IShortsTracker.sol";
import "./interfaces/IOrderBook.sol";
import "./interfaces/IBasePositionManager.sol";
import "../peripherals/interfaces/ITimelock.sol";
import "../referrals/interfaces/IReferralStorage.sol";

contract BasePositionManager is
    IBasePositionManager,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    address public admin;

    address public vault;
    address public shortsTracker;
    address public router;
    address public collateralToken;

    // to prevent using the deposit and withdrawal of collateral as a zero fee swap,
    // there is a small depositFee charged if a collateral deposit results in the decrease
    // of leverage for an existing position
    // increasePositionBufferBps allows for a small amount of decrease of leverage
    uint256 public depositFee;
    uint256 public increasePositionBufferBps;

    address public referralStorage;

    uint256 public feeReserve;

    mapping(address => uint256) public override maxGlobalLongSizes;
    mapping(address => uint256) public override maxGlobalShortSizes;
    mapping(address => bool) public isHandler;

    event SetHandler(address indexed handler, bool isHandler);
    event SetDepositFee(uint256 depositFee);
    event SetIncreasePositionBufferBps(uint256 increasePositionBufferBps);
    event SetReferralStorage(address referralStorage);
    event SetAdmin(address admin);
    event WithdrawFees(address indexed receiver, uint256 amount);

    event SetMaxGlobalSizes(
        address[] tokens,
        uint256[] longSizes,
        uint256[] shortSizes
    );

    event IncreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );

    event DecreasePositionReferral(
        address account,
        uint256 sizeDelta,
        uint256 marginFeeBasisPoints,
        bytes32 referralCode,
        address referrer
    );

    modifier onlyAdmin() {
        require(msg.sender == admin, "BasePositionManager: forbidden");
        _;
    }

    modifier onlyHandlerAndAbove() {
        require(
            msg.sender == admin || isHandler[msg.sender],
            "BasePositionManager: forbidden"
        );
        _;
    }

    function __BasePositionManager_init(
        address _vault,
        address _router,
        address _shortsTracker,
        address _collateralToken,
        uint256 _depositFee
    ) internal onlyInitializing {
        __ReentrancyGuard_init();
        __Ownable_init();

        vault = _vault;
        router = _router;
        require(
            _depositFee < BASIS_POINTS_DIVISOR,
            "BasePositionManager: invalid deposit fee"
        );
        depositFee = _depositFee;
        shortsTracker = _shortsTracker;
        collateralToken = _collateralToken;
        admin = msg.sender;

        increasePositionBufferBps = 100;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function setDepositFee(uint256 _depositFee) external onlyAdmin {
        require(
            _depositFee < BASIS_POINTS_DIVISOR,
            "BasePositionManager: invalid deposit fee"
        );
        depositFee = _depositFee;
        emit SetDepositFee(_depositFee);
    }

    function setHandler(address _account, bool _isActive) external onlyAdmin {
        isHandler[_account] = _isActive;
        emit SetHandler(_account, _isActive);
    }

    function setIncreasePositionBufferBps(uint256 _increasePositionBufferBps)
        external
        onlyAdmin
    {
        increasePositionBufferBps = _increasePositionBufferBps;
        emit SetIncreasePositionBufferBps(_increasePositionBufferBps);
    }

    function setReferralStorage(address _referralStorage) external onlyAdmin {
        referralStorage = _referralStorage;
        emit SetReferralStorage(_referralStorage);
    }

    function setMaxGlobalSizes(
        address[] memory _tokens,
        uint256[] memory _longSizes,
        uint256[] memory _shortSizes
    ) external onlyHandlerAndAbove {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            maxGlobalLongSizes[token] = _longSizes[i];
            maxGlobalShortSizes[token] = _shortSizes[i];
        }

        emit SetMaxGlobalSizes(_tokens, _longSizes, _shortSizes);
    }

    function withdrawFees(address _receiver) external onlyHandlerAndAbove {
        uint256 amount = feeReserve;
        if (amount == 0) {
            return;
        }

        feeReserve = 0;
        IERC20Upgradeable(collateralToken).safeTransfer(_receiver, amount);

        emit WithdrawFees(_receiver, amount);
    }

    function approve(
        address _token,
        address _spender,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).approve(_spender, _amount);
    }

    function sendValue(address payable _receiver, uint256 _amount)
        external
        onlyOwner
    {
        _receiver.sendValue(_amount);
    }

    function _validateMaxGlobalSize(
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) internal view {
        if (_sizeDelta == 0) {
            return;
        }

        if (_isLong) {
            uint256 maxGlobalLongSize = maxGlobalLongSizes[_indexToken];
            if (
                maxGlobalLongSize > 0 &&
                IVault(vault).globalLongSizes(_indexToken) + _sizeDelta >
                maxGlobalLongSize
            ) {
                revert("BasePositionManager: max global longs exceeded");
            }
        } else {
            uint256 maxGlobalShortSize = maxGlobalShortSizes[_indexToken];
            if (
                maxGlobalShortSize > 0 &&
                IVault(vault).globalShortSizes(_indexToken) + _sizeDelta >
                maxGlobalShortSize
            ) {
                revert("BasePositionManager: max global shorts exceeded");
            }
        }
    }

    function _increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) internal {
        address _vault = vault;

        uint256 markPrice = _isLong
            ? IVault(_vault).getMaxPrice(_indexToken)
            : IVault(_vault).getMinPrice(_indexToken);
        if (_isLong) {
            require(
                markPrice <= _price,
                "BasePositionManager: mark price higher than limit"
            );
        } else {
            require(
                markPrice >= _price,
                "BasePositionManager: mark price lower than limit"
            );
        }

        _validateMaxGlobalSize(_indexToken, _isLong, _sizeDelta);

        address timelock = OwnableUpgradeable(_vault).owner();

        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta,
            markPrice,
            true
        );

        ITimelock(timelock).enableLeverage(_vault);
        IRouter(router).pluginIncreasePosition(
            _account,
            _indexToken,
            _sizeDelta,
            _isLong
        );
        ITimelock(timelock).disableLeverage(_vault);

        _emitIncreasePositionReferral(_account, _sizeDelta);
    }

    function _decreasePosition(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) internal returns (uint256) {
        address _vault = vault;

        uint256 markPrice = _isLong
            ? IVault(_vault).getMinPrice(_indexToken)
            : IVault(_vault).getMaxPrice(_indexToken);
        if (_isLong) {
            require(
                markPrice >= _price,
                "BasePositionManager: mark price lower than limit"
            );
        } else {
            require(
                markPrice <= _price,
                "BasePositionManager: mark price higher than limit"
            );
        }

        address timelock = OwnableUpgradeable(_vault).owner();

        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(
            _account,
            _indexToken,
            _isLong,
            _sizeDelta,
            markPrice,
            false
        );

        ITimelock(timelock).enableLeverage(_vault);
        uint256 amountOut = IRouter(router).pluginDecreasePosition(
            _account,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver
        );
        ITimelock(timelock).disableLeverage(_vault);

        _emitDecreasePositionReferral(_account, _sizeDelta);

        return amountOut;
    }

    function _emitIncreasePositionReferral(address _account, uint256 _sizeDelta)
        internal
    {
        address _referralStorage = referralStorage;
        if (_referralStorage == address(0)) {
            return;
        }

        (bytes32 referralCode, address referrer) = IReferralStorage(
            _referralStorage
        ).getTraderReferralInfo(_account);
        emit IncreasePositionReferral(
            _account,
            _sizeDelta,
            IVault(vault).marginFeeBasisPoints(),
            referralCode,
            referrer
        );
    }

    function _emitDecreasePositionReferral(address _account, uint256 _sizeDelta)
        internal
    {
        address _referralStorage = referralStorage;
        if (_referralStorage == address(0)) {
            return;
        }

        (bytes32 referralCode, address referrer) = IReferralStorage(
            _referralStorage
        ).getTraderReferralInfo(_account);

        if (referralCode == bytes32(0)) {
            return;
        }

        emit DecreasePositionReferral(
            _account,
            _sizeDelta,
            IVault(vault).marginFeeBasisPoints(),
            referralCode,
            referrer
        );
    }

    function _transferOutETH(uint256 _amountOut, address payable _receiver)
        internal
    {
        (bool success, ) = _receiver.call{value: _amountOut}("");
        require(success, "BasePositionManager: eth transfer failed");
    }

    function _collectFees(
        address _account,
        uint256 _amountIn,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) internal returns (uint256) {
        bool shouldDeductFee = _shouldDeductFee(
            _account,
            _amountIn,
            _indexToken,
            _isLong,
            _sizeDelta
        );

        if (shouldDeductFee) {
            uint256 afterFeeAmount = (_amountIn *
                (BASIS_POINTS_DIVISOR - depositFee)) / BASIS_POINTS_DIVISOR;
            uint256 feeAmount = _amountIn - afterFeeAmount;
            feeReserve = feeReserve + feeAmount;
            return afterFeeAmount;
        }

        return _amountIn;
    }

    function _shouldDeductFee(
        address _account,
        uint256 _amountIn,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) internal view returns (bool) {
        // if the position is a short, do not charge a fee
        if (!_isLong) {
            return false;
        }

        // if the position size is not increasing, this is a collateral deposit
        if (_sizeDelta == 0) {
            return true;
        }

        IVault _vault = IVault(vault);
        (uint256 size, uint256 collateral, , , , , , ) = _vault.getPosition(
            _account,
            _indexToken,
            _isLong
        );

        // if there is no existing position, do not charge a fee
        if (size == 0) {
            return false;
        }

        uint256 nextSize = size + _sizeDelta;
        uint256 collateralDelta = _vault.tokenToUsdMin(
            collateralToken,
            _amountIn
        );
        uint256 nextCollateral = collateral + collateralDelta;

        uint256 prevLeverage = (size * BASIS_POINTS_DIVISOR) / collateral;
        uint256 nextLeverage = (nextSize *
            (BASIS_POINTS_DIVISOR + increasePositionBufferBps)) /
            nextCollateral;

        // deduct a fee if the leverage is decreased
        return nextLeverage < prevLeverage;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IRouter.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderBook.sol";
import "../oracle/interfaces/IPythPriceFeed.sol";
import "../peripherals/interfaces/ITimelock.sol";
import "./BasePositionManager.sol";

contract PositionManager is BasePositionManager {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public orderBook;
    bool public inLegacyMode;

    bool public shouldValidateIncreaseOrder;

    mapping(address => bool) public isOrderKeeper;
    mapping(address => bool) public isPartner;
    mapping(address => bool) public isLiquidator;
    IPythPriceFeed public pythPriceFeed;

    event SetOrderKeeper(address indexed account, bool isActive);
    event SetLiquidator(address indexed account, bool isActive);
    event SetPartner(address account, bool isActive);
    event SetInLegacyMode(bool inLegacyMode);
    event SetShouldValidateIncreaseOrder(bool shouldValidateIncreaseOrder);
    event SetPythPriceFeed(address pythPriceFeed);

    modifier onlyOrderKeeper() {
        require(isOrderKeeper[msg.sender], "PositionManager: forbidden");
        _;
    }

    modifier onlyLiquidator() {
        require(isLiquidator[msg.sender], "PositionManager: forbidden");
        _;
    }

    modifier onlyPartnersOrLegacyMode() {
        require(
            isPartner[msg.sender] || inLegacyMode,
            "PositionManager: forbidden"
        );
        _;
    }

    function initialize(
        address _vault,
        address _router,
        address _shortsTracker,
        address _collateralToken,
        uint256 _depositFee,
        address _orderBook,
        bool _shouldValidateIncreaseOrder
    ) external initializer {
        __BasePositionManager_init(
            _vault,
            _router,
            _shortsTracker,
            _collateralToken,
            _depositFee
        );

        orderBook = _orderBook;
        shouldValidateIncreaseOrder = _shouldValidateIncreaseOrder;
    }

    function setOrderKeeper(
        address _account,
        bool _isActive
    ) external onlyAdmin {
        isOrderKeeper[_account] = _isActive;
        emit SetOrderKeeper(_account, _isActive);
    }

    function setLiquidator(
        address _account,
        bool _isActive
    ) external onlyAdmin {
        isLiquidator[_account] = _isActive;
        emit SetLiquidator(_account, _isActive);
    }

    function setPartner(address _account, bool _isActive) external onlyAdmin {
        isPartner[_account] = _isActive;
        emit SetPartner(_account, _isActive);
    }

    function setInLegacyMode(bool _inLegacyMode) external onlyAdmin {
        inLegacyMode = _inLegacyMode;
        emit SetInLegacyMode(_inLegacyMode);
    }

    function setShouldValidateIncreaseOrder(
        bool _shouldValidateIncreaseOrder
    ) external onlyAdmin {
        shouldValidateIncreaseOrder = _shouldValidateIncreaseOrder;
        emit SetShouldValidateIncreaseOrder(_shouldValidateIncreaseOrder);
    }

    function setPythPriceFeed(address _pythPriceFeed) external onlyAdmin {
        pythPriceFeed = IPythPriceFeed(_pythPriceFeed);
        emit SetPythPriceFeed(_pythPriceFeed);
    }

    function increasePosition(
        address _indexToken,
        uint256 _amountIn,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        if (_amountIn > 0) {
            IRouter(router).pluginTransfer(
                collateralToken,
                msg.sender,
                address(this),
                _amountIn
            );

            uint256 afterFeeAmount = _collectFees(
                msg.sender,
                _amountIn,
                _indexToken,
                _isLong,
                _sizeDelta
            );
            IERC20Upgradeable(collateralToken).safeTransfer(
                vault,
                afterFeeAmount
            );
        }

        _increasePosition(msg.sender, _indexToken, _sizeDelta, _isLong, _price);
    }

    function decreasePosition(
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external nonReentrant onlyPartnersOrLegacyMode {
        _decreasePosition(
            msg.sender,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _price
        );
    }

    function liquidatePosition(
        bytes[] calldata priceUpdateData,
        address _account,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external payable nonReentrant onlyLiquidator {
        pythPriceFeed.updatePriceFeeds{value: msg.value}(
            priceUpdateData,
            msg.sender
        );

        address _vault = vault;
        address timelock = OwnableUpgradeable(_vault).owner();
        (uint256 size, , , , , , , ) = IVault(vault).getPosition(
            _account,
            _indexToken,
            _isLong
        );

        uint256 markPrice = _isLong
            ? IVault(_vault).getMinPrice(_indexToken)
            : IVault(_vault).getMaxPrice(_indexToken);
        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(
            _account,
            _indexToken,
            _isLong,
            size,
            markPrice,
            false
        );

        ITimelock(timelock).enableLeverage(_vault);
        IVault(_vault).liquidatePosition(
            _account,
            _indexToken,
            _isLong,
            _feeReceiver
        );
        ITimelock(timelock).disableLeverage(_vault);
    }

    function executeIncreaseOrder(
        bytes[] calldata priceUpdateData,
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external payable onlyOrderKeeper {
        pythPriceFeed.updatePriceFeeds{value: msg.value}(
            priceUpdateData,
            msg.sender
        );

        _validateIncreaseOrder(_account, _orderIndex);

        address _vault = vault;
        address timelock = OwnableUpgradeable(_vault).owner();

        (
            ,
            ,
            address indexToken,
            uint256 sizeDelta,
            bool isLong /*uint256 triggerPrice*/ /*bool triggerAboveThreshold*/ /*uint256 executionFee*/,
            ,
            ,

        ) = IOrderBook(orderBook).getIncreaseOrder(_account, _orderIndex);

        uint256 markPrice = isLong
            ? IVault(_vault).getMaxPrice(indexToken)
            : IVault(_vault).getMinPrice(indexToken);
        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(
            _account,
            indexToken,
            isLong,
            sizeDelta,
            markPrice,
            true
        );

        ITimelock(timelock).enableLeverage(_vault);
        IOrderBook(orderBook).executeIncreaseOrder(
            _account,
            _orderIndex,
            _feeReceiver
        );
        ITimelock(timelock).disableLeverage(_vault);

        _emitIncreasePositionReferral(_account, sizeDelta);
    }

    function executeDecreaseOrder(
        bytes[] calldata priceUpdateData,
        address _account,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external payable onlyOrderKeeper {
        pythPriceFeed.updatePriceFeeds{value: msg.value}(
            priceUpdateData,
            msg.sender
        );

        address _vault = vault;
        address timelock = OwnableUpgradeable(_vault).owner();

        (
            ,
            ,
            /*uint256 collateralDelta*/
            address indexToken,
            uint256 sizeDelta,
            bool isLong /*uint256 triggerPrice*/ /*bool triggerAboveThreshold*/ /*uint256 executionFee*/,
            ,
            ,

        ) = IOrderBook(orderBook).getDecreaseOrder(_account, _orderIndex);

        uint256 markPrice = isLong
            ? IVault(_vault).getMinPrice(indexToken)
            : IVault(_vault).getMaxPrice(indexToken);
        // should be called strictly before position is updated in Vault
        IShortsTracker(shortsTracker).updateGlobalShortData(
            _account,
            indexToken,
            isLong,
            sizeDelta,
            markPrice,
            false
        );

        ITimelock(timelock).enableLeverage(_vault);
        IOrderBook(orderBook).executeDecreaseOrder(
            _account,
            _orderIndex,
            _feeReceiver
        );
        ITimelock(timelock).disableLeverage(_vault);

        _emitDecreasePositionReferral(_account, sizeDelta);
    }

    function _validateIncreaseOrder(
        address _account,
        uint256 _orderIndex
    ) internal view {
        (
            uint256 _tokenAmount,
            address _collateralToken,
            address _indexToken,
            uint256 _sizeDelta,
            bool _isLong, // triggerPrice // triggerAboveThreshold // executionFee
            ,
            ,

        ) = IOrderBook(orderBook).getIncreaseOrder(_account, _orderIndex);

        _validateMaxGlobalSize(_indexToken, _isLong, _sizeDelta);

        if (!shouldValidateIncreaseOrder) {
            return;
        }

        // shorts are okay
        if (!_isLong) {
            return;
        }

        // if the position size is not increasing, this is a collateral deposit
        require(_sizeDelta > 0, "PositionManager: long deposit");

        IVault _vault = IVault(vault);
        (uint256 size, uint256 collateral, , , , , , ) = _vault.getPosition(
            _account,
            _indexToken,
            _isLong
        );

        // if there is no existing position, do not charge a fee
        if (size == 0) {
            return;
        }

        uint256 nextSize = size + _sizeDelta;
        uint256 collateralDelta = _vault.tokenToUsdMin(
            _collateralToken,
            _tokenAmount
        );
        uint256 nextCollateral = collateral + collateralDelta;

        uint256 prevLeverage = (size * BASIS_POINTS_DIVISOR) / collateral;
        // allow for a maximum of a increasePositionBufferBps decrease since there might be some swap fees taken from the collateral
        uint256 nextLeverageWithBuffer = (nextSize *
            (BASIS_POINTS_DIVISOR + increasePositionBufferBps)) /
            nextCollateral;

        require(
            nextLeverageWithBuffer >= prevLeverage,
            "PositionManager: long leverage decrease"
        );
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

interface IOrderBook {
    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            uint256 tokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeDecreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function executeIncreaseOrder(
        address,
        uint256,
        address payable
    ) external;

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) external view returns (uint256, bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IRouter {
    function addPlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint256 _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);
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

import "../../access/interfaces/IAdmin.sol";

interface ITimelock is IAdmin {
    function marginFeeBasisPoints() external view returns (uint256);

    function enableLeverage(address _vault) external;

    function disableLeverage(address _vault) external;

    function setIsLeverageEnabled(address _vault, bool _isLeverageEnabled)
        external;

    function signalSetGov(address _target, address _gov) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IReferralStorage {
    function codeOwners(bytes32 _code) external view returns (address);

    function traderReferralCodes(address _account)
        external
        view
        returns (bytes32);

    function referrerDiscountShares(address _account)
        external
        view
        returns (uint256);

    function referrerTiers(address _account) external view returns (uint256);

    function getTraderReferralInfo(address _account)
        external
        view
        returns (bytes32, address);

    function setTraderReferralCode(address _account, bytes32 _code) external;

    function setTier(
        uint256 _tierId,
        uint256 _totalRebate,
        uint256 _discountShare
    ) external;

    function setReferrerTier(address _referrer, uint256 _tierId) external;

    function govSetCodeOwner(bytes32 _code, address _newAccount) external;
}