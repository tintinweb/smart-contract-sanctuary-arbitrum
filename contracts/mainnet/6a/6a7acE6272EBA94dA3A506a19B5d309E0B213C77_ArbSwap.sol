// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import './interfaces/IUniV2Strategy.sol';
import './interfaces/IVaultStrategy.sol';
import './interfaces/IUniV3Strategy.sol';
import './interfaces/I1InchStrategy.sol';
import './interfaces/IVault.sol';
import './interfaces/IAggregationExecutor.sol';
import './interfaces/I1InchRouter.sol';
import './WithdrawableUpgradeable.sol';

contract ArbSwap is WithdrawableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    bytes public constant ZERO_BYTES = '';

    IUniV2Strategy public defaultUniV2Strategy;
    mapping(address => IUniV2Strategy) public uniV2Strategies;

    IVaultStrategy public defaultVaultStrategy;
    mapping(address => IVaultStrategy) public vaultStrategies;

    IUniV3Strategy public defaultUniV3Strategy;
    mapping(address => IUniV3Strategy) public uniV3Strategies;

    I1InchStrategy public default1InchStrategy;
    mapping(address => I1InchStrategy) public oneInchStrategies;

    mapping(address => bool) public whitelist;

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], 'ArbSwap: not whitelist');
        _;
    }

    receive() external payable {
        // Required to receive funds
    }

    function initialize() public initializer {
        __Withdrawable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function getUniV2Strategy(address uniV2) public view returns (IUniV2Strategy strategy) {
        IUniV2Strategy _strat = uniV2Strategies[uniV2];
        return _strat != IUniV2Strategy(address(0)) ? _strat : defaultUniV2Strategy;
    }

    function getVaultStrategy(address vault) public view returns (IVaultStrategy strategy) {
        IVaultStrategy _strat = vaultStrategies[vault];
        return _strat != IVaultStrategy(address(0)) ? _strat : defaultVaultStrategy;
    }

    function getUniV3Strategy(address uniV3) public view returns (IUniV3Strategy strategy) {
        IUniV3Strategy _strat = uniV3Strategies[uniV3];
        return _strat != IUniV3Strategy(address(0)) ? _strat : defaultUniV3Strategy;
    }

    function get1InchStrategy(address oneInch) public view returns (I1InchStrategy strategy) {
        I1InchStrategy _strat = oneInchStrategies[oneInch];
        return _strat != I1InchStrategy(address(0)) ? _strat : default1InchStrategy;
    }

    function setDefaultUniV2Strategy(IUniV2Strategy strategy) external onlyOwner {
        defaultUniV2Strategy = strategy;
    }

    function setDefaultVaultStrategy(IVaultStrategy strategy) external onlyOwner {
        defaultVaultStrategy = strategy;
    }

    function setDefaultUniV3Strategy(IUniV3Strategy strategy) external onlyOwner {
        defaultUniV3Strategy = strategy;
    }

    function setDefault1InchStrategy(I1InchStrategy strategy) external onlyOwner {
        default1InchStrategy = strategy;
    }

    function setUniV2Strategy(address uniV2, IUniV2Strategy strategy) external onlyOwner {
        uniV2Strategies[uniV2] = strategy;
    }

    function setVaultStrategy(address vault, IVaultStrategy strategy) external onlyOwner {
        vaultStrategies[vault] = strategy;
    }

    function setUniV3Strategy(address uniV3, IUniV3Strategy strategy) external onlyOwner {
        uniV3Strategies[uniV3] = strategy;
    }

    function set1InchStrategy(address oneInch, I1InchStrategy strategy) external onlyOwner {
        oneInchStrategies[oneInch] = strategy;
    }

    function setWhitelist(address user, bool isWhitelist) external onlyOwner {
        whitelist[user] = isWhitelist;
    }

    function setup(
        IUniV2Strategy uniV2Strategy,
        IVaultStrategy vaultStrategy,
        IUniV3Strategy uniV3Strategy,
        I1InchStrategy oneInchStrategy
    ) external onlyOwner {
        defaultUniV2Strategy = uniV2Strategy;
        defaultVaultStrategy = vaultStrategy;
        defaultUniV3Strategy = uniV3Strategy;
        default1InchStrategy = oneInchStrategy;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function arbFromETH(
        address uniV2Buy,
        address[] calldata pathBuy,
        address uniV2Sell,
        address[] calldata pathSell,
        uint deadline
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        {
            IERC20Upgradeable _token = IERC20Upgradeable(pathBuy[pathBuy.length - 1]);
            IUniV2Strategy _sellStrategy = getUniV2Strategy(uniV2Sell);
            // Buy the tokens
            getUniV2Strategy(uniV2Buy).swapExactETHForTokens{ value: amountIn }(
                uniV2Buy,
                0,
                pathBuy,
                address(_sellStrategy),
                deadline
            );
            // Sell the tokens
            getUniV2Strategy(uniV2Sell).swapExactTokensForETH(
                uniV2Sell,
                _token.balanceOf(address(_sellStrategy)),
                0,
                pathSell,
                address(this),
                deadline
            );
        }
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromTokensWithUniV2(
        uint256 amountIn,
        address uniV2Buy,
        address[] calldata pathBuy,
        address uniV2Sell,
        address[] calldata pathSell,
        uint256 deadline
    ) external nonReentrant whenNotPaused onlyWhitelist {
        IERC20Upgradeable tokenBuyIn = IERC20Upgradeable(pathBuy[0]);
        IERC20Upgradeable tokenBuyOut = IERC20Upgradeable(pathBuy[pathBuy.length - 1]);
        address _sellStrategy = address(getUniV2Strategy(uniV2Sell));
        tokenBuyIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenBuyIn.safeTransfer(_sellStrategy, amountIn);
        // Buy the tokens
        getUniV2Strategy(uniV2Buy).swapExactTokensForTokens(uniV2Buy, amountIn, 0, pathBuy, _sellStrategy, deadline);
        // Sell the tokens
        getUniV2Strategy(uniV2Sell).swapExactTokensForTokens(
            uniV2Sell,
            tokenBuyOut.balanceOf(_sellStrategy),
            0,
            pathSell,
            address(this),
            deadline
        );

        IERC20Upgradeable tokenSellOut = IERC20Upgradeable(pathBuy[pathBuy.length - 1]);
        uint256 actualAmountOut = tokenSellOut.balanceOf(address(this));
        tokenSellOut.safeTransfer(msg.sender, actualAmountOut);
    }

    function arbFromETHWithVault(
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsBuy,
        address[] memory assetsSell,
        int256[] memory limits,
        uint256 deadline
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        {
            IVaultStrategy sellStrategy = getVaultStrategy(vaultSell); //
            IVault.FundManagement memory fundsBuy = IVault.FundManagement({
                sender: address(this),
                fromInternalBalance: false,
                recipient: payable(address(sellStrategy)),
                toInternalBalance: false
            });
            getVaultStrategy(vaultBuy).batchSwap{ value: amountIn }(
                vaultBuy,
                IVault.SwapKind.GIVEN_IN,
                swapsBuy,
                assetsBuy,
                fundsBuy,
                limits,
                deadline
            );
            for (uint256 i = 0; i < swapsSell.length; i++) {
                IVault.BatchSwapStep memory swapStep = swapsSell[i];
                swapsSell[i].amount = IERC20Upgradeable(assetsSell[swapStep.assetInIndex]).balanceOf(
                    address(sellStrategy)
                );
            }
            IVault.FundManagement memory fundsSell = IVault.FundManagement({
                sender: address(sellStrategy),
                fromInternalBalance: false,
                recipient: payable(address(this)),
                toInternalBalance: false
            });
            getVaultStrategy(vaultSell).batchSwap(
                vaultSell,
                IVault.SwapKind.GIVEN_IN,
                swapsSell,
                assetsSell,
                fundsSell,
                limits,
                deadline
            );
        }
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWithVaultAndUniV2(
        address uniV2Router,
        address[] memory path,
        address vaultRouter,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        int256[] memory limits,
        uint256 deadline,
        uint256 selector
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        if (selector == 0) swapUniV2AndVault(uniV2Router, path, vaultRouter, swaps, assets, limits, deadline);
        else swapVaultAndUniV2(uniV2Router, path, vaultRouter, swaps, assets, limits, deadline);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromTokensWithVaultAndUniV2(
        uint256 amountIn,
        address uniV2Router,
        address[] memory path,
        address vaultRouter,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint256 selector
    ) external nonReentrant whenNotPaused onlyWhitelist {
        if (selector == 0) swapTokensUniV2AndVault(amountIn, uniV2Router, path, vaultRouter, swaps, assets, deadline);
        else swapTokensVaultAndUniV2(uniV2Router, path, vaultRouter, swaps, assets, deadline);
    }

    function arbFromETHWithUniV3(
        address uniV3Buy,
        ISwapRouter.ExactInputSingleParams memory paramsBuy,
        address uniV3Sell,
        ISwapRouter.ExactInputSingleParams memory paramsSell
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        IUniV3Strategy sellStrategy = getUniV3Strategy(uniV3Sell);
        getUniV3Strategy(uniV3Buy).exactInputSingle{ value: amountIn }(uniV3Buy, paramsBuy);
        paramsSell.amountIn = IERC20Upgradeable(paramsBuy.tokenOut).balanceOf(address(sellStrategy));
        getUniV3Strategy(uniV3Sell).exactInputSingle(uniV3Sell, paramsSell);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWithUniV3AndUniV2(
        address uniV2,
        address[] calldata path,
        address uniV3,
        ISwapRouter.ExactInputSingleParams memory params,
        uint256 deadline,
        uint256 selector
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        if (selector == 0) swapUniV2AndUniV3(uniV2, path, uniV3, params, deadline);
        else swapUniV3AndUniV2(uniV3, params, uniV2, path, deadline);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWithUniV3AndVault(
        address uniV3,
        ISwapRouter.ExactInputSingleParams memory params,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        int256[] memory limits,
        uint256 deadline,
        uint256 selector
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        if (selector == 0) swapVaultAndUniV3(vault, swaps, assets, limits, uniV3, params, deadline);
        else swapUniV3AndVault(uniV3, params, vault, swaps, assets, limits, deadline);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWith1Inch(
        address oneInchBuy,
        IAggregationExecutor executorBuy,
        I1InchRouter.SwapDescription memory descBuy,
        address oneInchSell,
        IAggregationExecutor executorSell,
        I1InchRouter.SwapDescription memory descSell
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        address sellStrategy = address(get1InchStrategy(oneInchSell));
        get1InchStrategy(oneInchBuy).swap{ value: amountIn }(oneInchBuy, executorBuy, descBuy, ZERO_BYTES, ZERO_BYTES);
        descSell.amount = descBuy.dstToken.balanceOf(sellStrategy);
        get1InchStrategy(oneInchSell).swap(oneInchSell, executorSell, descSell, ZERO_BYTES, ZERO_BYTES);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWith1InchAndUniV2(
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory desc,
        address uniV2,
        address[] memory path,
        uint256 deadline,
        uint256 selector
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        if (selector == 0) swapUniV2And1Inch(oneInch, executor, desc, uniV2, path, deadline);
        else swap1InchAndUniV2(oneInch, executor, desc, uniV2, path, deadline);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWith1InchAndUniV3(
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory desc,
        address uniV3,
        ISwapRouter.ExactInputSingleParams memory params,
        uint256 selector
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        if (selector == 0) swapUniV3And1Inch(oneInch, executor, desc, uniV3, params);
        else swap1InchAndUniV3(oneInch, executor, desc, uniV3, params);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromETHWith1InchAndVault(
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory desc,
        bytes calldata data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint256 selector
    ) external payable nonReentrant whenNotPaused onlyWhitelist returns (uint actualAmountOut) {
        uint amountIn = address(this).balance;
        if (selector == 0) swapVaultAnd1Inch(oneInch, executor, desc, data, vault, swaps, assets, deadline);
        else swap1InchAndVault(oneInch, executor, desc, data, vault, swaps, assets, deadline);
        // Ensure we got a profit
        actualAmountOut = address(this).balance;
        require(actualAmountOut > amountIn, 'No profit');
        // Send the funds
        payable(_msgSender()).sendValue(actualAmountOut);
    }

    function arbFromTokensWith1InchAndVault(
        address oneInch,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription memory desc,
        bytes calldata data,
        address vault,
        IVault.BatchSwapStep[] memory swaps,
        address[] memory assets,
        uint256 deadline,
        uint256 selector
    ) external nonReentrant whenNotPaused onlyWhitelist {
        if (selector == 0) swapTokensVaultAnd1Inch(oneInch, executor, desc, data, vault, swaps, assets, deadline);
        else swapTokens1InchAndVault(oneInch, executor, desc, data, vault, swaps, assets, deadline);
    }

    function getAmountsOut(
        address router,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts) {
        return getUniV2Strategy(router).getAmountsOut(router, amountIn, path);
    }

    function swapUniV2AndVault(
        address uniV2Buy,
        address[] memory pathBuy,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assets,
        int256[] memory limits,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;

        address sellStrategy = address(getVaultStrategy(vaultSell));
        getUniV2Strategy(uniV2Buy).swapExactETHForTokens{ value: amountIn }(
            uniV2Buy,
            0,
            pathBuy,
            sellStrategy,
            deadline
        );
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        for (uint256 i = 0; i < swapsSell.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsSell[i];
            swapsSell[i].amount = IERC20Upgradeable(assets[swapStep.assetInIndex]).balanceOf(address(sellStrategy));
        }
        getVaultStrategy(vaultSell).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assets,
            fundsSell,
            limits,
            deadline
        );
    }

    function swapVaultAndUniV2(
        address uniV2Sell,
        address[] memory pathSell,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assets,
        int256[] memory limits,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;

        address sellStrategy = address(getUniV2Strategy(uniV2Sell));
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        getVaultStrategy(vaultBuy).batchSwap{ value: amountIn }(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assets,
            fundsBuy,
            limits,
            deadline
        );
        IERC20Upgradeable _token = IERC20Upgradeable(assets[swapsBuy[swapsBuy.length - 1].assetOutIndex]);
        getUniV2Strategy(uniV2Sell).swapExactTokensForETH(
            uniV2Sell,
            _token.balanceOf(sellStrategy),
            0,
            pathSell,
            address(this),
            deadline
        );
    }

    function swapTokensUniV2AndVault(
        uint256 amountIn,
        address uniV2Buy,
        address[] memory pathBuy,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsSell,
        uint256 deadline
    ) private {
        IERC20Upgradeable tokenBuyIn = IERC20Upgradeable(pathBuy[0]);
        address buyStrategy = address(getUniV2Strategy(uniV2Buy));
        address sellStrategy = address(getVaultStrategy(vaultSell));
        tokenBuyIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenBuyIn.safeTransfer(buyStrategy, amountIn);
        IUniV2Strategy(buyStrategy).swapExactTokensForTokens(uniV2Buy, amountIn, 0, pathBuy, sellStrategy, deadline);
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(msg.sender),
            toInternalBalance: false
        });
        int256[] memory limitsSell = new int256[](assetsSell.length);
        for (uint256 i = 0; i < assetsSell.length; i++) {
            limitsSell[i] = type(int256).max;
        }
        for (uint256 i = 0; i < swapsSell.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsSell[i];
            swapsSell[i].amount = IERC20Upgradeable(assetsSell[swapStep.assetInIndex]).balanceOf(address(sellStrategy));
        }
        IVaultStrategy(sellStrategy).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assetsSell,
            fundsSell,
            limitsSell,
            deadline
        );
    }

    function swapTokensVaultAndUniV2(
        address uniV2Sell,
        address[] memory pathSell,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assetsBuy,
        uint256 deadline
    ) private {
        address buyStrategy = address(getVaultStrategy(vaultBuy));
        address sellStrategy = address(getUniV2Strategy(uniV2Sell));
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        int256[] memory limitsBuy = new int256[](assetsBuy.length);
        for (uint256 i = 0; i < assetsBuy.length; i++) {
            limitsBuy[i] = type(int256).max;
        }
        for (uint256 i = 0; i < swapsBuy.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsBuy[i];
            IERC20Upgradeable token = IERC20Upgradeable(assetsBuy[swapStep.assetInIndex]);
            token.safeTransferFrom(msg.sender, address(this), swapStep.amount);
            token.safeTransfer(buyStrategy, swapStep.amount);
        }
        IVaultStrategy(buyStrategy).batchSwap(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assetsBuy,
            fundsBuy,
            limitsBuy,
            deadline
        );
        IERC20Upgradeable _token = IERC20Upgradeable(assetsBuy[swapsBuy[swapsBuy.length - 1].assetOutIndex]);
        IUniV2Strategy(sellStrategy).swapExactTokensForTokens(
            uniV2Sell,
            _token.balanceOf(sellStrategy),
            0,
            pathSell,
            address(this),
            deadline
        );
    }

    function swapUniV2AndUniV3(
        address uniV2Buy,
        address[] calldata pathBuy,
        address uniV3Sell,
        ISwapRouter.ExactInputSingleParams memory paramsSell,
        uint deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(getUniV3Strategy(uniV3Sell));

        getUniV2Strategy(uniV2Buy).swapExactETHForTokens{ value: amountIn }(
            uniV2Buy,
            0,
            pathBuy,
            sellStrategy,
            deadline
        );
        IERC20Upgradeable token = IERC20Upgradeable(pathBuy[pathBuy.length - 1]);
        paramsSell.amountIn = token.balanceOf(sellStrategy);
        getUniV3Strategy(uniV3Sell).exactInputSingle(uniV3Sell, paramsSell);
    }

    function swapUniV3AndUniV2(
        address uniV3Buy,
        ISwapRouter.ExactInputSingleParams memory paramsBuy,
        address uniV2Sell,
        address[] calldata pathSell,
        uint deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(getUniV2Strategy(uniV2Sell));

        getUniV3Strategy(uniV3Buy).exactInputSingle{ value: amountIn }(uniV3Buy, paramsBuy);
        IERC20Upgradeable token = IERC20Upgradeable(paramsBuy.tokenOut);
        getUniV2Strategy(uniV2Sell).swapExactTokensForETH(
            uniV2Sell,
            token.balanceOf(sellStrategy),
            0,
            pathSell,
            address(this),
            deadline
        );
    }

    function swapVaultAndUniV3(
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assets,
        int256[] memory limits,
        address uniV3Sell,
        ISwapRouter.ExactInputSingleParams memory paramsSell,
        uint deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(getUniV3Strategy(uniV3Sell));

        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        getVaultStrategy(vaultBuy).batchSwap{ value: amountIn }(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assets,
            fundsBuy,
            limits,
            deadline
        );
        IERC20Upgradeable token = IERC20Upgradeable(assets[swapsBuy[swapsBuy.length - 1].assetOutIndex]);
        paramsSell.amountIn = token.balanceOf(sellStrategy);
        getUniV3Strategy(uniV3Sell).exactInputSingle(uniV3Sell, paramsSell);
    }

    function swapUniV3AndVault(
        address uniV3Buy,
        ISwapRouter.ExactInputSingleParams memory paramsBuy,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assets,
        int256[] memory limits,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;

        address sellStrategy = address(getVaultStrategy(vaultSell));
        getUniV3Strategy(uniV3Buy).exactInputSingle{ value: amountIn }(uniV3Buy, paramsBuy);

        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        for (uint256 i = 0; i < swapsSell.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsSell[i];
            swapsSell[i].amount = IERC20Upgradeable(assets[swapStep.assetInIndex]).balanceOf(address(sellStrategy));
        }
        getVaultStrategy(vaultSell).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assets,
            fundsSell,
            limits,
            deadline
        );
    }

    function swapUniV2And1Inch(
        address oneInchSell,
        IAggregationExecutor executorSell,
        I1InchRouter.SwapDescription memory descSell,
        address uniV2Buy,
        address[] memory pathBuy,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(get1InchStrategy(oneInchSell));
        getUniV2Strategy(uniV2Buy).swapExactETHForTokens{ value: amountIn }(
            uniV2Buy,
            0,
            pathBuy,
            sellStrategy,
            deadline
        );
        descSell.amount = descSell.srcToken.balanceOf(sellStrategy);
        get1InchStrategy(oneInchSell).swap(oneInchSell, executorSell, descSell, ZERO_BYTES, ZERO_BYTES);
    }

    function swap1InchAndUniV2(
        address oneInchBuy,
        IAggregationExecutor executorBuy,
        I1InchRouter.SwapDescription memory descBuy,
        address uniV2Sell,
        address[] memory pathSell,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(getUniV2Strategy(uniV2Sell));
        get1InchStrategy(oneInchBuy).swap{ value: amountIn }(oneInchBuy, executorBuy, descBuy, ZERO_BYTES, ZERO_BYTES);
        getUniV2Strategy(uniV2Sell).swapExactTokensForETH(
            uniV2Sell,
            descBuy.dstToken.balanceOf(sellStrategy),
            0,
            pathSell,
            address(this),
            deadline
        );
    }

    function swapUniV3And1Inch(
        address oneInchSell,
        IAggregationExecutor executorSell,
        I1InchRouter.SwapDescription memory descSell,
        address uniV3Buy,
        ISwapRouter.ExactInputSingleParams memory paramsBuy
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(get1InchStrategy(oneInchSell));
        getUniV3Strategy(uniV3Buy).exactInputSingle{ value: amountIn }(uniV3Buy, paramsBuy);
        descSell.amount = descSell.srcToken.balanceOf(sellStrategy);
        get1InchStrategy(oneInchSell).swap(oneInchSell, executorSell, descSell, ZERO_BYTES, ZERO_BYTES);
    }

    function swap1InchAndUniV3(
        address oneInchBuy,
        IAggregationExecutor executorBuy,
        I1InchRouter.SwapDescription memory descBuy,
        address uniV3Sell,
        ISwapRouter.ExactInputSingleParams memory paramsSell
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(getUniV3Strategy(uniV3Sell));
        get1InchStrategy(oneInchBuy).swap{ value: amountIn }(oneInchBuy, executorBuy, descBuy, ZERO_BYTES, ZERO_BYTES);
        paramsSell.amountIn = descBuy.dstToken.balanceOf(sellStrategy);
        getUniV3Strategy(uniV3Sell).exactInputSingle(uniV3Sell, paramsSell);
    }

    function swapVaultAnd1Inch(
        address oneInchSell,
        IAggregationExecutor executorSell,
        I1InchRouter.SwapDescription memory descSell,
        bytes calldata data,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assetsBuy,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(get1InchStrategy(oneInchSell));
        int256[] memory limitsBuy = new int256[](assetsBuy.length);
        for (uint256 i = 0; i < assetsBuy.length; i++) {
            limitsBuy[i] = type(int256).max;
        }
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        getVaultStrategy(vaultBuy).batchSwap{ value: amountIn }(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assetsBuy,
            fundsBuy,
            limitsBuy,
            deadline
        );
        descSell.amount = descSell.srcToken.balanceOf(sellStrategy);
        get1InchStrategy(oneInchSell).swap(oneInchSell, executorSell, descSell, ZERO_BYTES, data);
    }

    function swap1InchAndVault(
        address oneInchBuy,
        IAggregationExecutor executorBuy,
        I1InchRouter.SwapDescription memory descBuy,
        bytes calldata data,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsSell,
        uint256 deadline
    ) private {
        uint amountIn = address(this).balance;
        address sellStrategy = address(getVaultStrategy(vaultSell));
        get1InchStrategy(oneInchBuy).swap{ value: amountIn }(oneInchBuy, executorBuy, descBuy, ZERO_BYTES, data);
        int256[] memory limitsSell = new int256[](assetsSell.length);
        for (uint256 i = 0; i < assetsSell.length; i++) {
            limitsSell[i] = type(int256).max;
        }
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        for (uint256 i = 0; i < swapsSell.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsSell[i];
            swapsSell[i].amount = IERC20Upgradeable(assetsSell[swapStep.assetInIndex]).balanceOf(address(sellStrategy));
        }
        getVaultStrategy(vaultSell).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assetsSell,
            fundsSell,
            limitsSell,
            deadline
        );
    }

    function swapTokensVaultAnd1Inch(
        address oneInchSell,
        IAggregationExecutor executorSell,
        I1InchRouter.SwapDescription memory descSell,
        bytes calldata data,
        address vaultBuy,
        IVault.BatchSwapStep[] memory swapsBuy,
        address[] memory assetsBuy,
        uint256 deadline
    ) private {
        address buyStrategy = address(getVaultStrategy(vaultBuy));
        address sellStrategy = address(get1InchStrategy(oneInchSell));
        int256[] memory limitsBuy = new int256[](assetsBuy.length);
        for (uint256 i = 0; i < assetsBuy.length; i++) {
            limitsBuy[i] = type(int256).max;
        }
        IVault.FundManagement memory fundsBuy = IVault.FundManagement({
            sender: buyStrategy,
            fromInternalBalance: false,
            recipient: payable(sellStrategy),
            toInternalBalance: false
        });
        for (uint256 i = 0; i < swapsBuy.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsBuy[i];
            IERC20Upgradeable token = IERC20Upgradeable(assetsBuy[swapStep.assetInIndex]);
            token.safeTransferFrom(msg.sender, address(this), swapStep.amount);
            token.safeTransfer(buyStrategy, swapStep.amount);
        }
        IVaultStrategy(buyStrategy).batchSwap(
            vaultBuy,
            IVault.SwapKind.GIVEN_IN,
            swapsBuy,
            assetsBuy,
            fundsBuy,
            limitsBuy,
            deadline
        );
        descSell.amount = descSell.srcToken.balanceOf(sellStrategy);
        I1InchStrategy(sellStrategy).swap(oneInchSell, executorSell, descSell, ZERO_BYTES, data);
    }

    function swapTokens1InchAndVault(
        address oneInchBuy,
        IAggregationExecutor executorBuy,
        I1InchRouter.SwapDescription memory descBuy,
        bytes calldata data,
        address vaultSell,
        IVault.BatchSwapStep[] memory swapsSell,
        address[] memory assetsSell,
        uint256 deadline
    ) private {
        address buyStrategy = address(get1InchStrategy(oneInchBuy));
        address sellStrategy = address(getVaultStrategy(vaultSell));
        IERC20Upgradeable(address(descBuy.srcToken)).safeTransferFrom(msg.sender, address(this), descBuy.amount);
        IERC20Upgradeable(address(descBuy.srcToken)).safeTransfer(buyStrategy, descBuy.amount);
        I1InchStrategy(buyStrategy).swap(oneInchBuy, executorBuy, descBuy, ZERO_BYTES, data);
        int256[] memory limitsSell = new int256[](assetsSell.length);
        for (uint256 i = 0; i < assetsSell.length; i++) {
            limitsSell[i] = type(int256).max;
        }
        IVault.FundManagement memory fundsSell = IVault.FundManagement({
            sender: sellStrategy,
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });
        for (uint256 i = 0; i < swapsSell.length; i++) {
            IVault.BatchSwapStep memory swapStep = swapsSell[i];
            swapsSell[i].amount = IERC20Upgradeable(assetsSell[swapStep.assetInIndex]).balanceOf(address(sellStrategy));
        }
        IVaultStrategy(sellStrategy).batchSwap(
            vaultSell,
            IVault.SwapKind.GIVEN_IN,
            swapsSell,
            assetsSell,
            fundsSell,
            limitsSell,
            deadline
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './IAggregationExecutor.sol';

interface I1InchRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IAggregationExecutor.sol';
import './I1InchRouter.sol';

interface I1InchStrategy {
    function swap(
        address router,
        IAggregationExecutor executor,
        I1InchRouter.SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniV2Strategy {
    function swapExactTokensForTokens(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        address router,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETH(
        address router,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function getAmountsOut(
        address router,
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/ISwapRouter.sol';

interface IUniV3Strategy {
    function exactInputSingle(
        address router,
        ISwapRouter.ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactInput(
        address router,
        ISwapRouter.ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactOutputSingle(
        address router,
        ISwapRouter.ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    function exactOutput(
        address router,
        ISwapRouter.ExactOutputParams calldata params
    ) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVault.sol";

interface IVaultStrategy {
    function batchSwap(
        address vault,
        IVault.SwapKind kind,
        IVault.BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        IVault.FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external payable;

    function swap(
        address vault,
        IVault.SingleSwap calldata singleSwap,
        IVault.FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

abstract contract WithdrawableUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    function __Withdrawable_init() internal initializer {
        __Ownable_init_unchained();
        __Withdrawable_init_unchained();
    }
    function __Withdrawable_init_unchained() internal initializer {
    }

    function withdrawToken(IERC20Upgradeable _token) external onlyOwner {
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }
    function withdrawETH() external onlyOwner {
        payable(_msgSender()).sendValue(address(this).balance);
    }

}