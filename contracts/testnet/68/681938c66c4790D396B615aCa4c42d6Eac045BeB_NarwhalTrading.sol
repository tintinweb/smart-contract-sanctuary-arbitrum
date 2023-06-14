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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPyth.sol";
import "./PythErrors.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
    function queryPriceFeed(
        bytes32 id
    ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(
        bytes32 id
    ) public view virtual returns (bool exists);

    function getValidTimePeriod()
        public
        view
        virtual
        override
        returns (uint validTimePeriod);

    function getPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function getEmaPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    // Access modifier is overridden to public to be able to call it locally.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable virtual override;

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable virtual override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; i++) {
            if (
                !priceFeedExists(priceIds[i]) ||
                queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "../libraries/Chainlink.sol";
import "../interfaces/ENSInterface.sol";
import "../interfaces/LinkTokenInterface.sol";
import "../interfaces/OperatorInterface.sol";
import "../interfaces/PointerInterface.sol";

abstract contract ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 internal constant LINK_DIVISIBILITY = 10 ** 18;
    uint256 private constant AMOUNT_OVERRIDE = 0;
    address private constant SENDER_OVERRIDE = address(0);
    uint256 private constant ORACLE_ARGS_VERSION = 1;
    uint256 private constant OPERATOR_ARGS_VERSION = 2;
    bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
    bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
    address private constant LINK_TOKEN_POINTER =
        0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

    ENSInterface private s_ens;
    bytes32 private s_ensNode;
    LinkTokenInterface private s_link;
    OperatorInterface private s_oracle;
    uint256 private s_requestCount = 1;
    mapping(bytes32 => address) private s_pendingRequests;

    event ChainlinkRequested(bytes32 indexed id);
    event ChainlinkFulfilled(bytes32 indexed id);
    event ChainlinkCancelled(bytes32 indexed id);

    /**
     * @notice Creates a request that can hold additional parameters
     * @param specId The Job Specification ID that the request will be created for
     * @param callbackAddr address to operate the callback on
     * @param callbackFunctionSignature function signature to use for the callback
     * @return A Chainlink Request struct in memory
     */
    function buildChainlinkRequest(
        bytes32 specId,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) internal pure returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return req.initialize(specId, callbackAddr, callbackFunctionSignature);
    }

    /**
     * @notice Creates a request that can hold additional parameters
     * @param specId The Job Specification ID that the request will be created for
     * @param callbackFunctionSignature function signature to use for the callback
     * @return A Chainlink Request struct in memory
     */
    function buildOperatorRequest(
        bytes32 specId,
        bytes4 callbackFunctionSignature
    ) internal view returns (Chainlink.Request memory) {
        Chainlink.Request memory req;
        return req.initialize(specId, address(this), callbackFunctionSignature);
    }

    /**
     * @notice Creates a Chainlink request to the stored oracle address
     * @dev Calls `chainlinkRequestTo` with the stored oracle address
     * @param req The initialized Chainlink Request
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendChainlinkRequest(
        Chainlink.Request memory req,
        uint256 payment
    ) internal returns (bytes32) {
        return sendChainlinkRequestTo(address(s_oracle), req, payment);
    }

    /**
     * @notice Creates a Chainlink request to the specified oracle address
     * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
     * send LINK which creates a request on the target oracle contract.
     * Emits ChainlinkRequested event.
     * @param oracleAddress The address of the oracle for the request
     * @param req The initialized Chainlink Request
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendChainlinkRequestTo(
        address oracleAddress,
        Chainlink.Request memory req,
        uint256 payment
    ) internal returns (bytes32 requestId) {
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            ChainlinkRequestInterface.oracleRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            req.id,
            address(this),
            req.callbackFunctionId,
            nonce,
            ORACLE_ARGS_VERSION,
            req.buf.buf
        );
        return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
    }

    /**
     * @notice Creates a Chainlink request to the stored oracle address
     * @dev This function supports multi-word response
     * @dev Calls `sendOperatorRequestTo` with the stored oracle address
     * @param req The initialized Chainlink Request
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendOperatorRequest(
        Chainlink.Request memory req,
        uint256 payment
    ) internal returns (bytes32) {
        return sendOperatorRequestTo(address(s_oracle), req, payment);
    }

    /**
     * @notice Creates a Chainlink request to the specified oracle address
     * @dev This function supports multi-word response
     * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
     * send LINK which creates a request on the target oracle contract.
     * Emits ChainlinkRequested event.
     * @param oracleAddress The address of the oracle for the request
     * @param req The initialized Chainlink Request
     * @param payment The amount of LINK to send for the request
     * @return requestId The request ID
     */
    function sendOperatorRequestTo(
        address oracleAddress,
        Chainlink.Request memory req,
        uint256 payment
    ) internal returns (bytes32 requestId) {
        uint256 nonce = s_requestCount;
        s_requestCount = nonce + 1;
        bytes memory encodedRequest = abi.encodeWithSelector(
            OperatorInterface.operatorRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            req.id,
            req.callbackFunctionId,
            nonce,
            OPERATOR_ARGS_VERSION,
            req.buf.buf
        );
        return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
    }

    /**
     * @notice Make a request to an oracle
     * @param oracleAddress The address of the oracle for the request
     * @param nonce used to generate the request ID
     * @param payment The amount of LINK to send for the request
     * @param encodedRequest data encoded for request type specific format
     * @return requestId The request ID
     */
    function _rawRequest(
        address oracleAddress,
        uint256 nonce,
        uint256 payment,
        bytes memory encodedRequest
    ) private returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(this, nonce));
        s_pendingRequests[requestId] = oracleAddress;
        emit ChainlinkRequested(requestId);
        require(
            s_link.transferAndCall(oracleAddress, payment, encodedRequest),
            "unable to transferAndCall to oracle"
        );
    }

    /**
     * @notice Allows a request to be cancelled if it has not been fulfilled
     * @dev Requires keeping track of the expiration value emitted from the oracle contract.
     * Deletes the request from the `pendingRequests` mapping.
     * Emits ChainlinkCancelled event.
     * @param requestId The request ID
     * @param payment The amount of LINK sent for the request
     * @param callbackFunc The callback function specified for the request
     * @param expiration The time of the expiration for the request
     */
    function cancelChainlinkRequest(
        bytes32 requestId,
        uint256 payment,
        bytes4 callbackFunc,
        uint256 expiration
    ) internal {
        OperatorInterface requested = OperatorInterface(
            s_pendingRequests[requestId]
        );
        delete s_pendingRequests[requestId];
        emit ChainlinkCancelled(requestId);
        requested.cancelOracleRequest(
            requestId,
            payment,
            callbackFunc,
            expiration
        );
    }

    /**
     * @notice the next request count to be used in generating a nonce
     * @dev starts at 1 in order to ensure consistent gas cost
     * @return returns the next request count to be used in a nonce
     */
    function getNextRequestCount() internal view returns (uint256) {
        return s_requestCount;
    }

    /**
     * @notice Sets the stored oracle address
     * @param oracleAddress The address of the oracle contract
     */
    function setChainlinkOracle(address oracleAddress) internal {
        s_oracle = OperatorInterface(oracleAddress);
    }

    /**
     * @notice Sets the LINK token address
     * @param linkAddress The address of the LINK token contract
     */
    function setChainlinkToken(address linkAddress) internal {
        s_link = LinkTokenInterface(linkAddress);
    }

    /**
     * @notice Sets the Chainlink token address for the public
     * network as given by the Pointer contract
     */
    function setPublicChainlinkToken() internal {
        setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
    }

    /**
     * @notice Retrieves the stored address of the LINK token
     * @return The address of the LINK token
     */
    function chainlinkTokenAddress() internal view returns (address) {
        return address(s_link);
    }

    /**
     * @notice Retrieves the stored address of the oracle contract
     * @return The address of the oracle contract
     */
    function chainlinkOracleAddress() internal view returns (address) {
        return address(s_oracle);
    }

    /**
     * @notice Allows for a request which was created on another contract to be fulfilled
     * on this contract
     * @param oracleAddress The address of the oracle contract that will fulfill the request
     * @param requestId The request ID used for the response
     */
    function addChainlinkExternalRequest(
        address oracleAddress,
        bytes32 requestId
    ) internal notPendingRequest(requestId) {
        s_pendingRequests[requestId] = oracleAddress;
    }

    /**
     * @notice Ensures that the fulfillment is valid for this contract
     * @dev Use if the contract developer prefers methods instead of modifiers for validation
     * @param requestId The request ID for fulfillment
     */
    function validateChainlinkCallback(
        bytes32 requestId
    )
        internal
        recordChainlinkFulfillment(requestId)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /**
     * @dev Reverts if the sender is not the oracle of the request.
     * Emits ChainlinkFulfilled event.
     * @param requestId The request ID for fulfillment
     */
    modifier recordChainlinkFulfillment(bytes32 requestId) {
        require(
            msg.sender == s_pendingRequests[requestId],
            "Source must be the oracle of the request"
        );
        delete s_pendingRequests[requestId];
        emit ChainlinkFulfilled(requestId);
        _;
    }

    /**
     * @dev Reverts if the request is already pending
     * @param requestId The request ID for fulfillment
     */
    modifier notPendingRequest(bytes32 requestId) {
        require(
            s_pendingRequests[requestId] == address(0),
            "Request is already pending"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract Delegatable {
    mapping(address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }

    function delegatedAction(
        address trader,
        bytes calldata call_data
    ) external returns (bytes memory) {
        require(delegations[trader] == msg.sender, "DELEGATE_NOT_APPROVED");

        senderOverride = trader;
        (bool success, bytes memory result) = address(this).delegatecall(
            call_data
        );
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577 (return the original revert reason)
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        senderOverride = address(0);

        return result;
    }

    function _msgSender() public view returns (address) {
        if (senderOverride == address(0)) {
            return msg.sender;
        } else {
            return senderOverride;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract ENSResolver {
    function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface AggregatorInterface {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    function getPrice(
        uint,
        OrderType,
        uint,
        bytes[] calldata
    ) external returns (uint);

    function tokenPriceUSDT() external view returns (uint);

    function pairMinOpenLimitSlippageP(uint) external view returns (uint);

    function closeFeeP(uint) external view returns (uint);

    function linkFee(uint, uint) external view returns (uint);

    function openFeeP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function pairsCount() external view returns (uint);

    function tokenUSDTReservesLp() external view returns (uint, uint);

    function referralP(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./PairsStorageInterface.sol";
import "./StorageInterface.sol";
import "./CallbacksInterface.sol";

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function beforeGetPriceLimit(
        StorageInterface.Trade memory t
    ) external returns (uint256);

    function getPrice(
        OrderType,
        bytes[] calldata,
        StorageInterface.Trade memory
    ) external returns (uint, uint256);

    function fulfill(uint256 orderId, uint256 price) external;

    function pairsStorage() external view returns (PairsStorageInterface);

    function tokenPriceUSDT() external returns (uint);

    function updatePriceFeed(uint256 pairIndex,bytes[] calldata updateData) external returns (uint256);

    function linkFee(uint, uint) external view returns (uint);

    function orders(uint) external view returns (uint, OrderType, uint, bool);

    function tokenUSDTReservesLp() external view returns (uint, uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    function getPairForIndex(
        uint256 _pairIndex
    ) external view returns (string memory, string memory);

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface CallbacksInterface {
    struct AggregatorAnswer {
        uint orderId;
        uint256 price;
        uint spreadP;
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeOpenOrderCallback(AggregatorAnswer memory) external;

    function executeCloseOrderCallback(AggregatorAnswer memory) external;

    function updateSlCallback(AggregatorAnswer memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ChainlinkFeedInterfaceV5 {
    function latestRoundData()
        external
        view
        returns (uint80, int, uint, uint, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ENSInterface {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external;

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IBaseToken {
    function totalStaked() external view returns (uint256);

    function stakedBalance(address _account) external view returns (uint256);

    function removeAdmin(address _account) external;

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracle {
    function getUnderlyingPrice(
        string memory _pair
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IPoolRewards {
    function cumulativeRewards(
        address _account
    ) external view returns (uint256);

    function getUserInfo(
        address _account
    ) external view returns (uint256, uint256, uint256);

    function averageStakedAmounts(
        address _account
    ) external view returns (uint256);

    function _unLockNAR(address _account, uint256 _amount) external;

    function _lockNAR(address _account, uint256 _amount) external;

    function getUserTokenBalance(
        address _account
    ) external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function getReservedAmount(
        address _account
    ) external view returns (uint256);
}

pragma solidity 0.8.15;

interface IStakingRewards {
    // Views

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardsDistribution() external view returns (address);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    // Mutative

    function exit() external;

    function getReward() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUniswapPairOracle {
    function update() external;

    function consult(
        address token,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function canUpdate() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IVester {
    function claimForAccount(
        address _account,
        address _receiver
    ) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(
        address _account
    ) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

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

    function depositForAccount(
        address _creditor,
        address _sender,
        uint256 _amount
    ) external returns (uint256);

    function setTransferredAverageStakedAmounts(
        address _account,
        uint256 _amount
    ) external;

    function setTransferredcumulativeRewards(
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IYieldTracker {
    function claim(
        address _account,
        address _receiver
    ) external returns (uint256);

    function updateRewards(address _account) external;

    function getTokensPerInterval() external view returns (uint256);

    function claimable(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface LimitOrdersInterface {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterface.LimitOrder order;
    }
    //MOMENTUM = STOP
    //REVERSAL = LIMIT
    //LEGACY = MARKET
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function openLimitOrderTypes(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(
        address,
        uint,
        uint,
        OpenLimitOrderType
    ) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface LinkTokenInterface {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256 remaining);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(
        address spender,
        uint256 addedValue
    ) external returns (bool success);

    function increaseApproval(
        address spender,
        uint256 subtractedValue
    ) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(
        address to,
        uint256 value
    ) external returns (bool success);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface LpInterfaceV5 {
    function getReserves() external view returns (uint112, uint112, uint32);

    function token0() external view returns (address);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint256) external;

    function totalSupply() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function approve(address, uint256) external returns (bool);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface NarwhalReferralInterface {
    struct ReferrerDetails {
        address[] userReferralList;
        uint volumeReferredUSDT; // 1e18
        uint pendingRewards; // 1e18
        uint totalRewards; // 1e18
        bool registered;
        uint256 referralLink;
        bool canChangeReferralLink;
        address userReferredFrom;
        bool isWhitelisted;
        uint256 discount;
        uint256 rebate;
        uint256 tier;
    }

    function getReferralDiscountAndRebate(
        address _user
    ) external view returns (uint256, uint256);

    function signUp(address trader, address referral) external;

    function incrementTier2Tier3(
        address _tier2,
        uint256 _rewardTier2,
        uint256 _rewardTier3,
        uint256 _tradeSize
    ) external;

    function getReferralDetails(
        address _user
    ) external view returns (ReferrerDetails memory);

    function getReferral(address _user) external view returns (address);

    function isTier3KOL(address _user) external view returns (bool);

    function tier3tier2RebateBonus() external view returns (uint256);

    function incrementRewards(address _user, uint256 _rewards,uint256 _tradeSize) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./LimitOrdersInterface.sol";

interface NarwhalTradingInterface {
    function openTrade(
        StorageInterface.Trade memory t,
        LimitOrdersInterface.OpenLimitOrderType orderType, // LEGACY => market
        uint spreadReductionId,
        uint slippageP, // for market orders only
        address referrer
    ) external;

    function setAllowedToInteract(address _contract, bool _status) external;

    function closeTradeMarket(uint pairIndex, uint index) external;

    function cancelOpenLimitOrder(uint pairIndex, uint index) external;

    function updateTp(uint pairIndex, uint index, uint newTp) external;

    function updateSl(uint pairIndex, uint index, uint newSl) external;

    function updateOpenLimitOrder(
        uint pairIndex,
        uint index,
        uint price, // PRECISION
        uint tp,
        uint sl
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./OracleInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
    function operatorRequest(
        address sender,
        uint256 payment,
        bytes32 specId,
        bytes4 callbackFunctionId,
        uint256 nonce,
        uint256 dataVersion,
        bytes calldata data
    ) external;

    function fulfillOracleRequest2(
        bytes32 requestId,
        uint256 payment,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 expiration,
        bytes calldata data
    ) external returns (bool);

    function ownerTransferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool success);

    function distributeFunds(
        address payable[] calldata receivers,
        uint256[] calldata amounts
    ) external payable;

    function getAuthorizedSenders() external returns (address[] memory);

    function setAuthorizedSenders(address[] calldata senders) external;

    function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ChainlinkRequestInterface {
    function oracleRequest(
        address sender,
        uint256 requestPrice,
        bytes32 serviceAgreementID,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 nonce,
        uint256 dataVersion,
        bytes calldata data
    ) external;

    function cancelOracleRequest(
        bytes32 requestId,
        uint256 payment,
        bytes4 callbackFunctionId,
        uint256 expiration
    ) external;
}

interface OracleInterface {
    function fulfillOracleRequest(
        bytes32 requestId,
        uint256 payment,
        address callbackAddress,
        bytes4 callbackFunctionId,
        uint256 expiration,
        bytes32 data
    ) external returns (bool);

    function isAuthorizedSender(address node) external view returns (bool);

    function withdraw(address recipient, uint256 amount) external;

    function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairInfoInterface {
    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (USDT)
    ) external returns (uint); // 1e18 (USDT)

    function getAccFundingFeesLong(uint pairIndex) external view returns (int);

    function getAccFundingFeesShort(uint pairIndex) external view returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairsStorageInterface {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        bytes32 feed1;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairSpreadP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupMaxCollateral(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUSDT(uint) external view returns (uint);

    function pairLimitOrderFeeP(
        uint _pairIndex
    ) external view returns (uint);

    function incr() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PausableInterface {
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PointerInterface {
    function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PoolInterface {
    function increaseAccTokens(uint) external;
}

// SPDX-License-Identifier: MITUSDT
pragma solidity 0.8.15;
import "./TokenInterface.sol";
import "./AggregatorInterfaceV6_2.sol";
import "./UniswapRouterInterfaceV5.sol";
import "./VaultInterface.sol";
import "./PoolInterface.sol";

interface StorageInterface {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trader {
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal; // 1e18
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUSDT; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUSDT; // PRECISION
        uint openInterestUSDT; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (USDT or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }

    struct PendingLimitOrder {
        address limitHolder;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function getNetOI(uint256 _pairIndex, bool _long) external view returns (uint256);
    
    function gov() external view returns (address);

    function dev() external view returns (address);

    function USDT() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function linkErc677() external view returns (TokenInterface);

    function tokenUSDTRouter() external view returns (UniswapRouterInterfaceV5);

    function tempTradeStatus(address _trader,uint256 _pairIndex,uint256 _index) external view returns (bool);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (VaultInterface);

    function pool() external view returns (PoolInterface);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUSDT(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint,
        bool
    ) external;

    function storeReferral(address, address) external;

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

    function openTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function tradeTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function openTradesInfo(
        address,
        uint,
        uint
    ) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function positionSizeTokenDynamic(uint, uint) external view returns (uint);

    function maxSlP() external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingLimitOrder(PendingLimitOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function currentPercentProfit(
        uint,
        uint,
        bool,
        uint
    ) external view returns (int);

    function reqID_pendingLimitOrder(
        uint
    ) external view returns (PendingLimitOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingLimitOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function getReferral(address) external view returns (address);

    function increaseReferralRewards(address, uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function setLeverageUnlocked(address, uint) external;

    function getLeverageUnlocked(address) external view returns (uint);

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function maxOpenLimitOrdersPerPair() external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function maxTradesPerBlock() external view returns (uint);

    function tradesPerBlock(uint) external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function maxGainP() external view returns (uint);

    function defaultLeverageUnlocked() external view returns (uint);

    function openInterestUSDT(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function traders(address) external view returns (Trader memory);

    function keeperForOrder(uint256) external view returns (address);

    function accPerOiOpen(
        address,
        uint,
        uint
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface TokenInterface {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface TokenInterfaceV5 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint256) external;

    function totalSupply() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function approve(address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface UniswapRouterInterfaceV5 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface VaultInterface {
    function sendUSDTToTrader(address, uint) external;

    function receiveUSDTFromTrader(address, uint, uint, bool) external;

    function currentBalanceUSDT() external view returns (uint);

    function distributeRewardUSDT(uint, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library BufferChainlink {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(
        buffer memory buf,
        uint256 capacity
    ) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     *      Changes to the buffer may mutate the original value.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint256 capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Sets buffer length to 0.
     * @param buf The buffer to truncate.
     * @return The original buffer, for chaining..
     */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
     * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The start offset to write to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function write(
        buffer memory buf,
        uint256 off,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
     * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write the byte at.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function writeUint8(
        buffer memory buf,
        uint256 off,
        uint8 data
    ) internal pure returns (buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendUint8(
        buffer memory buf,
        uint8 data
    ) internal pure returns (buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
     * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @param len The number of bytes to write (left-aligned).
     * @return The original buffer, for chaining.
     */
    function write(
        buffer memory buf,
        uint256 off,
        bytes32 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        unchecked {
            uint256 mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + off + len
                let dest := add(add(bufptr, off), len)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(add(off, len), mload(bufptr)) {
                    mstore(bufptr, add(off, len))
                }
            }
        }
        return buf;
    }

    /**
     * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function writeBytes20(
        buffer memory buf,
        uint256 off,
        bytes20 data
    ) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chhaining.
     */
    function appendBytes20(
        buffer memory buf,
        bytes20 data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendBytes32(
        buffer memory buf,
        bytes32 data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
     * @dev Writes an integer to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer, for chaining.
     */
    function writeInt(
        buffer memory buf,
        uint256 off,
        uint256 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint256 mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(
        buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library BufferChainlink {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(
        buffer memory buf,
        uint256 capacity
    ) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     *      Changes to the buffer may mutate the original value.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint256 capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Sets buffer length to 0.
     * @param buf The buffer to truncate.
     * @return The original buffer, for chaining..
     */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
     * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The start offset to write to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function write(
        buffer memory buf,
        uint256 off,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
     * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write the byte at.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function writeUint8(
        buffer memory buf,
        uint256 off,
        uint8 data
    ) internal pure returns (buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendUint8(
        buffer memory buf,
        uint8 data
    ) internal pure returns (buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
     * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @param len The number of bytes to write (left-aligned).
     * @return The original buffer, for chaining.
     */
    function write(
        buffer memory buf,
        uint256 off,
        bytes32 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        unchecked {
            uint256 mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + off + len
                let dest := add(add(bufptr, off), len)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(add(off, len), mload(bufptr)) {
                    mstore(bufptr, add(off, len))
                }
            }
        }
        return buf;
    }

    /**
     * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function writeBytes20(
        buffer memory buf,
        uint256 off,
        bytes20 data
    ) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chhaining.
     */
    function appendBytes20(
        buffer memory buf,
        bytes20 data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendBytes32(
        buffer memory buf,
        bytes32 data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
     * @dev Writes an integer to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer, for chaining.
     */
    function writeInt(
        buffer memory buf,
        uint256 off,
        uint256 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint256 mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(
        buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

library CBORChainlink {
    using BufferChainlink for BufferChainlink.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    function encodeFixedNumeric(
        BufferChainlink.buffer memory buf,
        uint8 major,
        uint64 value
    ) private pure {
        if (value <= 23) {
            buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.appendUint8(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.appendUint8(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else {
            buf.appendUint8(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(
        BufferChainlink.buffer memory buf,
        uint8 major
    ) private pure {
        buf.appendUint8(uint8((major << 5) | 31));
    }

    function encodeUInt(
        BufferChainlink.buffer memory buf,
        uint value
    ) internal pure {
        if (value > 0xFFFFFFFFFFFFFFFF) {
            encodeBigNum(buf, value);
        } else {
            encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
        }
    }

    function encodeInt(
        BufferChainlink.buffer memory buf,
        int value
    ) internal pure {
        if (value < -0x10000000000000000) {
            encodeSignedBigNum(buf, value);
        } else if (value > 0xFFFFFFFFFFFFFFFF) {
            encodeBigNum(buf, uint(value));
        } else if (value >= 0) {
            encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
        } else {
            encodeFixedNumeric(
                buf,
                MAJOR_TYPE_NEGATIVE_INT,
                uint64(uint256(-1 - value))
            );
        }
    }

    function encodeBytes(
        BufferChainlink.buffer memory buf,
        bytes memory value
    ) internal pure {
        encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
        buf.append(value);
    }

    function encodeBigNum(
        BufferChainlink.buffer memory buf,
        uint value
    ) internal pure {
        buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
        encodeBytes(buf, abi.encode(value));
    }

    function encodeSignedBigNum(
        BufferChainlink.buffer memory buf,
        int input
    ) internal pure {
        buf.appendUint8(
            uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM)
        );
        encodeBytes(buf, abi.encode(uint256(-1 - input)));
    }

    function encodeString(
        BufferChainlink.buffer memory buf,
        string memory value
    ) internal pure {
        encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        buf.append(bytes(value));
    }

    function startArray(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library BufferChainlink {
    /**
     * @dev Represents a mutable buffer. Buffers have a current value (buf) and
     *      a capacity. The capacity may be longer than the current value, in
     *      which case it can be extended without the need to allocate more memory.
     */
    struct buffer {
        bytes buf;
        uint256 capacity;
    }

    /**
     * @dev Initializes a buffer with an initial capacity.
     * @param buf The buffer to initialize.
     * @param capacity The number of bytes of space to allocate the buffer.
     * @return The buffer, for chaining.
     */
    function init(
        buffer memory buf,
        uint256 capacity
    ) internal pure returns (buffer memory) {
        if (capacity % 32 != 0) {
            capacity += 32 - (capacity % 32);
        }
        // Allocate space for the buffer data
        buf.capacity = capacity;
        assembly {
            let ptr := mload(0x40)
            mstore(buf, ptr)
            mstore(ptr, 0)
            mstore(0x40, add(32, add(ptr, capacity)))
        }
        return buf;
    }

    /**
     * @dev Initializes a new buffer from an existing bytes object.
     *      Changes to the buffer may mutate the original value.
     * @param b The bytes object to initialize the buffer with.
     * @return A new buffer.
     */
    function fromBytes(bytes memory b) internal pure returns (buffer memory) {
        buffer memory buf;
        buf.buf = b;
        buf.capacity = b.length;
        return buf;
    }

    function resize(buffer memory buf, uint256 capacity) private pure {
        bytes memory oldbuf = buf.buf;
        init(buf, capacity);
        append(buf, oldbuf);
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }

    /**
     * @dev Sets buffer length to 0.
     * @param buf The buffer to truncate.
     * @return The original buffer, for chaining..
     */
    function truncate(buffer memory buf) internal pure returns (buffer memory) {
        assembly {
            let bufptr := mload(buf)
            mstore(bufptr, 0)
        }
        return buf;
    }

    /**
     * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The start offset to write to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function write(
        buffer memory buf,
        uint256 off,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        require(len <= data.length);

        if (off + len > buf.capacity) {
            resize(buf, max(buf.capacity, len + off) * 2);
        }

        uint256 dest;
        uint256 src;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Start address = buffer address + offset + sizeof(buffer length)
            dest := add(add(bufptr, 32), off)
            // Update buffer length if we're extending it
            if gt(add(len, off), buflen) {
                mstore(bufptr, add(len, off))
            }
            src := add(data, 32)
        }

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        unchecked {
            uint256 mask = (256 ** (32 - len)) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask))
                let destpart := and(mload(dest), mask)
                mstore(dest, or(destpart, srcpart))
            }
        }

        return buf;
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @param len The number of bytes to copy.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, len);
    }

    /**
     * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function append(
        buffer memory buf,
        bytes memory data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, data.length);
    }

    /**
     * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write the byte at.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function writeUint8(
        buffer memory buf,
        uint256 off,
        uint8 data
    ) internal pure returns (buffer memory) {
        if (off >= buf.capacity) {
            resize(buf, buf.capacity * 2);
        }

        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Length of existing buffer data
            let buflen := mload(bufptr)
            // Address = buffer address + sizeof(buffer length) + off
            let dest := add(add(bufptr, off), 32)
            mstore8(dest, data)
            // Update buffer length if we extended it
            if eq(off, buflen) {
                mstore(bufptr, add(buflen, 1))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendUint8(
        buffer memory buf,
        uint8 data
    ) internal pure returns (buffer memory) {
        return writeUint8(buf, buf.buf.length, data);
    }

    /**
     * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
     *      exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @param len The number of bytes to write (left-aligned).
     * @return The original buffer, for chaining.
     */
    function write(
        buffer memory buf,
        uint256 off,
        bytes32 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        unchecked {
            uint256 mask = (256 ** len) - 1;
            // Right-align data
            data = data >> (8 * (32 - len));
            assembly {
                // Memory address of the buffer data
                let bufptr := mload(buf)
                // Address = buffer address + sizeof(buffer length) + off + len
                let dest := add(add(bufptr, off), len)
                mstore(dest, or(and(mload(dest), not(mask)), data))
                // Update buffer length if we extended it
                if gt(add(off, len), mload(bufptr)) {
                    mstore(bufptr, add(off, len))
                }
            }
        }
        return buf;
    }

    /**
     * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
     *      capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function writeBytes20(
        buffer memory buf,
        uint256 off,
        bytes20 data
    ) internal pure returns (buffer memory) {
        return write(buf, off, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chhaining.
     */
    function appendBytes20(
        buffer memory buf,
        bytes20 data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, bytes32(data), 20);
    }

    /**
     * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer, for chaining.
     */
    function appendBytes32(
        buffer memory buf,
        bytes32 data
    ) internal pure returns (buffer memory) {
        return write(buf, buf.buf.length, data, 32);
    }

    /**
     * @dev Writes an integer to the buffer. Resizes if doing so would exceed
     *      the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param off The offset to write at.
     * @param data The data to append.
     * @param len The number of bytes to write (right-aligned).
     * @return The original buffer, for chaining.
     */
    function writeInt(
        buffer memory buf,
        uint256 off,
        uint256 data,
        uint256 len
    ) private pure returns (buffer memory) {
        if (len + off > buf.capacity) {
            resize(buf, (len + off) * 2);
        }

        uint256 mask = (256 ** len) - 1;
        assembly {
            // Memory address of the buffer data
            let bufptr := mload(buf)
            // Address = buffer address + off + sizeof(buffer length) + len
            let dest := add(add(bufptr, off), len)
            mstore(dest, or(and(mload(dest), not(mask)), data))
            // Update buffer length if we extended it
            if gt(add(off, len), mload(bufptr)) {
                mstore(bufptr, add(off, len))
            }
        }
        return buf;
    }

    /**
     * @dev Appends a byte to the end of the buffer. Resizes if doing so would
     * exceed the capacity of the buffer.
     * @param buf The buffer to append to.
     * @param data The data to append.
     * @return The original buffer.
     */
    function appendInt(
        buffer memory buf,
        uint256 data,
        uint256 len
    ) internal pure returns (buffer memory) {
        return writeInt(buf, buf.buf.length, data, len);
    }
}

library CBORChainlink {
    using BufferChainlink for BufferChainlink.buffer;

    uint8 private constant MAJOR_TYPE_INT = 0;
    uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
    uint8 private constant MAJOR_TYPE_BYTES = 2;
    uint8 private constant MAJOR_TYPE_STRING = 3;
    uint8 private constant MAJOR_TYPE_ARRAY = 4;
    uint8 private constant MAJOR_TYPE_MAP = 5;
    uint8 private constant MAJOR_TYPE_TAG = 6;
    uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

    uint8 private constant TAG_TYPE_BIGNUM = 2;
    uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

    function encodeFixedNumeric(
        BufferChainlink.buffer memory buf,
        uint8 major,
        uint64 value
    ) private pure {
        if (value <= 23) {
            buf.appendUint8(uint8((major << 5) | value));
        } else if (value <= 0xFF) {
            buf.appendUint8(uint8((major << 5) | 24));
            buf.appendInt(value, 1);
        } else if (value <= 0xFFFF) {
            buf.appendUint8(uint8((major << 5) | 25));
            buf.appendInt(value, 2);
        } else if (value <= 0xFFFFFFFF) {
            buf.appendUint8(uint8((major << 5) | 26));
            buf.appendInt(value, 4);
        } else {
            buf.appendUint8(uint8((major << 5) | 27));
            buf.appendInt(value, 8);
        }
    }

    function encodeIndefiniteLengthType(
        BufferChainlink.buffer memory buf,
        uint8 major
    ) private pure {
        buf.appendUint8(uint8((major << 5) | 31));
    }

    function encodeUInt(
        BufferChainlink.buffer memory buf,
        uint value
    ) internal pure {
        if (value > 0xFFFFFFFFFFFFFFFF) {
            encodeBigNum(buf, value);
        } else {
            encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
        }
    }

    function encodeInt(
        BufferChainlink.buffer memory buf,
        int value
    ) internal pure {
        if (value < -0x10000000000000000) {
            encodeSignedBigNum(buf, value);
        } else if (value > 0xFFFFFFFFFFFFFFFF) {
            encodeBigNum(buf, uint(value));
        } else if (value >= 0) {
            encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
        } else {
            encodeFixedNumeric(
                buf,
                MAJOR_TYPE_NEGATIVE_INT,
                uint64(uint256(-1 - value))
            );
        }
    }

    function encodeBytes(
        BufferChainlink.buffer memory buf,
        bytes memory value
    ) internal pure {
        encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
        buf.append(value);
    }

    function encodeBigNum(
        BufferChainlink.buffer memory buf,
        uint value
    ) internal pure {
        buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
        encodeBytes(buf, abi.encode(value));
    }

    function encodeSignedBigNum(
        BufferChainlink.buffer memory buf,
        int input
    ) internal pure {
        buf.appendUint8(
            uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM)
        );
        encodeBytes(buf, abi.encode(uint256(-1 - input)));
    }

    function encodeString(
        BufferChainlink.buffer memory buf,
        string memory value
    ) internal pure {
        encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
        buf.append(bytes(value));
    }

    function startArray(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    }

    function startMap(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    }

    function endSequence(BufferChainlink.buffer memory buf) internal pure {
        encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    }
}

library Chainlink {
    uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

    using CBORChainlink for BufferChainlink.buffer;

    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunctionId;
        uint256 nonce;
        BufferChainlink.buffer buf;
    }

    /**
     * @notice Initializes a Chainlink request
     * @dev Sets the ID, callback address, and callback function signature on the request
     * @param self The uninitialized request
     * @param jobId The Job Specification ID
     * @param callbackAddr The callback address
     * @param callbackFunc The callback function signature
     * @return The initialized request
     */
    function initialize(
        Request memory self,
        bytes32 jobId,
        address callbackAddr,
        bytes4 callbackFunc
    ) internal pure returns (Chainlink.Request memory) {
        BufferChainlink.init(self.buf, defaultBufferSize);
        self.id = jobId;
        self.callbackAddress = callbackAddr;
        self.callbackFunctionId = callbackFunc;
        return self;
    }

    /**
     * @notice Sets the data for the buffer without encoding CBOR on-chain
     * @dev CBOR can be closed with curly-brackets {} or they can be left off
     * @param self The initialized request
     * @param data The CBOR data
     */
    function setBuffer(Request memory self, bytes memory data) internal pure {
        BufferChainlink.init(self.buf, data.length);
        BufferChainlink.append(self.buf, data);
    }

    /**
     * @notice Adds a string value to the request with a given key name
     * @param self The initialized request
     * @param key The name of the key
     * @param value The string value to add
     */
    function add(
        Request memory self,
        string memory key,
        string memory value
    ) internal pure {
        self.buf.encodeString(key);
        self.buf.encodeString(value);
    }

    /**
     * @notice Adds a bytes value to the request with a given key name
     * @param self The initialized request
     * @param key The name of the key
     * @param value The bytes value to add
     */
    function addBytes(
        Request memory self,
        string memory key,
        bytes memory value
    ) internal pure {
        self.buf.encodeString(key);
        self.buf.encodeBytes(value);
    }

    /**
     * @notice Adds a int256 value to the request with a given key name
     * @param self The initialized request
     * @param key The name of the key
     * @param value The int256 value to add
     */
    function addInt(
        Request memory self,
        string memory key,
        int256 value
    ) internal pure {
        self.buf.encodeString(key);
        self.buf.encodeInt(value);
    }

    /**
     * @notice Adds a uint256 value to the request with a given key name
     * @param self The initialized request
     * @param key The name of the key
     * @param value The uint256 value to add
     */
    function addUint(
        Request memory self,
        string memory key,
        uint256 value
    ) internal pure {
        self.buf.encodeString(key);
        self.buf.encodeUInt(value);
    }

    /**
     * @notice Adds an array of strings to the request with a given key name
     * @param self The initialized request
     * @param key The name of the key
     * @param values The array of string values to add
     */
    function addStringArray(
        Request memory self,
        string memory key,
        string[] memory values
    ) internal pure {
        self.buf.encodeString(key);
        self.buf.startArray();
        for (uint256 i = 0; i < values.length; i++) {
            self.buf.encodeString(values[i]);
        }
        self.buf.endSequence();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 =
        0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(
        uq112x112 memory self,
        uint256 y
    ) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(
            y == 0 || (z = self._x * y) / y == self._x,
            "FixedPoint::mul: overflow"
        );
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(
        uq112x112 memory self,
        int256 y
    ) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2 ** 255, "FixedPoint::muli: overflow");
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(
        uq112x112 memory self,
        uq112x112 memory other
    ) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(
            upper <= type(uint112).max,
            "FixedPoint::muluq: upper overflow"
        );

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) +
            uppers_lowero +
            uppero_lowers +
            (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, "FixedPoint::muluq: sum overflow");

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(
        uq112x112 memory self,
        uq112x112 memory other
    ) internal pure returns (uq112x112 memory) {
        require(other._x > 0, "FixedPoint::divuq: division by zero");
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, "FixedPoint::divuq: overflow");
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, "FixedPoint::divuq: overflow");
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(
                result <= type(uint224).max,
                "FixedPoint::fraction: overflow"
            );
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(
                result <= type(uint224).max,
                "FixedPoint::fraction: overflow"
            );
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(
        uq112x112 memory self
    ) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint::reciprocal: reciprocal of zero");
        require(self._x != 1, "FixedPoint::reciprocal: overflow");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(
        uq112x112 memory self
    ) internal pure returns (uq112x112 memory) {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return
            uq112x112(
                uint224(
                    Babylonian.sqrt(uint256(self._x) << safeShiftBits) <<
                        ((112 - safeShiftBits) / 2)
                )
            );
    }
}

library FullMath {
    function fullMul(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (~d + 1);
        d /= pow2;
        l /= pow2;
        l += h * ((~pow2 + 1) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, "FullMath: FULLDIV_OVERFLOW");
        return fullDiv(l, h, d);
    }
}

pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT

import "./interfaces/TokenInterface.sol";
import "./interfaces/AggregatorInterface.sol";
import "./interfaces/PoolInterface.sol";
import "./interfaces/PausableInterface.sol";
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract LimitOrdersStorage {
    // Contracts (constant)
    StorageInterface public immutable storageT;

    // Params (adjustable)
    uint public triggerTimeout = 5; // blocks
    uint public sameBlockLimit = 10; // bots

    uint public firstP = 40; // %
    uint public sameBlockP = 20; // %
    uint public poolP = 40; // %

    // Custom data types
    struct TriggeredLimit {
        address first;
        address[] sameBlock;
        uint block;
    }
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterface.LimitOrder order;
    }

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    mapping(address => mapping(uint => mapping(uint => mapping(StorageInterface.LimitOrder => TriggeredLimit))))
        public triggeredLimits; // limits being triggered

    mapping(address => mapping(uint => mapping(uint => OpenLimitOrderType)))
        public openLimitOrderTypes;
    
    mapping(address => bool) public allowedToInteract;


    // Events
    event NumberUpdated(string name, uint value);
    event PercentagesUpdated(uint firstP, uint sameBlockP, uint poolP);

    event TriggeredFirst(TriggeredLimitId id, address bot);
    event TriggeredSameBlock(TriggeredLimitId id, address bot);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(
        TriggeredLimitId id,
        address first,
        uint sameBlockCount,
        uint reward
    );

    constructor(StorageInterface _storageT) {
        require(address(_storageT) != address(0), "ZERO_ADDRESS");
        storageT = _storageT;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyTrading() {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    function setAllowedToInteract(address _sender, bool _status) public onlyGov {
        allowedToInteract[_sender] = _status;
    }

    // Manage params
    function updateTriggerTimeout(uint _triggerTimeout) external onlyGov {
        require(_triggerTimeout >= 5, "LESS_THAN_5");
        triggerTimeout = _triggerTimeout;
        emit NumberUpdated("triggerTimeout", _triggerTimeout);
    }

    function updateSameBlockLimit(uint _sameBlockLimit) external onlyGov {
        require(_sameBlockLimit >= 5, "LESS_THAN_5");
        sameBlockLimit = _sameBlockLimit;
        emit NumberUpdated("sameBlockLimit", _sameBlockLimit);
    }

    function updatePercentages(
        uint _firstP,
        uint _sameBlockP,
        uint _poolP
    ) external onlyGov {
        require(_firstP + _sameBlockP + _poolP == 100, "SUM_NOT_100");

        firstP = _firstP;
        sameBlockP = _sameBlockP;
        poolP = _poolP;

        emit PercentagesUpdated(_firstP, _sameBlockP, _poolP);
    }

    // Triggers
    function storeFirstToTrigger(
        TriggeredLimitId calldata _id,
        address _bot
    ) external onlyTrading {
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];

        t.first = _bot;
        delete t.sameBlock;
        t.block = block.number;

        emit TriggeredFirst(_id, _bot);
    }

    function storeTriggerSameBlock(
        TriggeredLimitId calldata _id,
        address _bot
    ) external onlyTrading {
        TriggeredLimit storage t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];

        require(t.block == block.number, "TOO_LATE");
        require(t.sameBlock.length < sameBlockLimit, "SAME_BLOCK_LIMIT");

        t.sameBlock.push(_bot);

        emit TriggeredSameBlock(_id, _bot);
    }

    function unregisterTrigger(
        TriggeredLimitId calldata _id
    ) external onlyCallbacks {
        delete triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];
        emit TriggerUnregistered(_id);
    }

    // Manage open limit order types
    function setOpenLimitOrderType(
        address _trader,
        uint _pairIndex,
        uint _index,
        OpenLimitOrderType _type
    ) external onlyTrading {
        openLimitOrderTypes[_trader][_pairIndex][_index] = _type;
    }

    // Getters
    function triggered(
        TriggeredLimitId calldata _id
    ) external view returns (bool) {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];
        return t.block > 0;
    }

    function timedOut(
        TriggeredLimitId calldata _id
    ) external view returns (bool) {
        TriggeredLimit memory t = triggeredLimits[_id.trader][_id.pairIndex][
            _id.index
        ][_id.order];
        return t.block > 0 && block.number - t.block >= triggerTimeout;
    }

    function sameBlockTriggers(
        TriggeredLimitId calldata _id
    ) external view returns (address[] memory) {
        return
            triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order]
                .sameBlock;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "./PythStructs.sol";
import "./IPyth.sol";
import "./PythErrors.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
    function queryPriceFeed(
        bytes32 id
    ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(
        bytes32 id
    ) public view virtual returns (bool exists);

    function getValidTimePeriod()
        public
        view
        virtual
        override
        returns (uint validTimePeriod);

    function getPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function getEmaPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    // Access modifier is overridden to public to be able to call it locally.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable virtual override;

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable virtual override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; i++) {
            if (
                !priceFeedExists(priceIds[i]) ||
                queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);

    function queryPriceFeed(
        bytes32 id
    ) external view returns (PythStructs.PriceFeed memory priceFeed);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract MockBUSD is ERC20Burnable {
    address public owner;
    mapping(address => bool) public claimed;
    uint256 public uniqueClaimAmount = 10000e18;

    constructor() ERC20("MockBUSD", "BUSD") {
        owner = msg.sender;
        _mint(msg.sender, 100000000000e18);
    }

    function mintMockTokens() public {
        require(
            claimed[msg.sender] == false,
            "Already claimed, get rekted ser"
        );
        claimed[msg.sender] = true;
        _mint(msg.sender, uniqueClaimAmount);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract MockLINK is ERC20Burnable {
    address public owner;

    constructor() ERC20("MockLINK", "LINK") {
        owner = msg.sender;
        _mint(msg.sender, 100000000e18);
    }

    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}

pragma solidity 0.8.15;

interface IDIA {
    function getValue(
        string calldata key
    ) external view returns (uint128, uint128);
}

contract MockOracle {
    address public governance;
    address public DIA;

    mapping(string => bool) public collatExcludedAddresses;
    mapping(string => uint256) public excludedPrice;

    modifier onlyGovernance() {
        require(msg.sender == governance, "Governance required.");
        _;
    }

    constructor() {
        governance = msg.sender;
    }

    function isCollatExcludedAddresses(
        string memory _pair
    ) public view returns (bool isIndeed) {
        return collatExcludedAddresses[_pair];
    }

    function setPrice(
        string memory _pair,
        uint256 _price
    ) public onlyGovernance {
        excludedPrice[_pair] = _price;
    }

    function getUnderlyingPrice(
        string memory _pair
    ) external view returns (uint256) {
        uint256 converted;

        if (isCollatExcludedAddresses(_pair) == true) {
            converted = excludedPrice[_pair];
        } else {
            (uint256 DIAPrice, ) = IDIA(DIA).getValue(_pair);
            converted = (DIAPrice * (1e18) * (1e10)) / (1e18);
        }

        return converted;
    }

    function transferGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0), "New governance is zero address");
        governance = newGovernance;
    }

    function addExcluded(
        string memory _pair
    ) public onlyGovernance returns (bool) {
        collatExcludedAddresses[_pair] = true;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract EACAggregatorProxy {
    int256 public mockAnswer;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function setMockAnswer(int256 _mockAnswer) public {
        require(msg.sender == owner, "Get rekt");
        mockAnswer = _mockAnswer;
    }

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, mockAnswer, 0, 0, 0);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "./AbstractPyth.sol";
import "./PythStructs.sol";
import "./PythErrors.sol";
import "hardhat/console.sol";

contract MockPyth is AbstractPyth {
    mapping(bytes32 => PythStructs.PriceFeed) priceFeeds;
    uint64 sequenceNumber;

    uint singleUpdateFeeInWei;
    uint validTimePeriod;

    constructor(uint _validTimePeriod, uint _singleUpdateFeeInWei) {
        singleUpdateFeeInWei = _singleUpdateFeeInWei;
        validTimePeriod = _validTimePeriod;
    }

    function queryPriceFeed(
        bytes32 id
    ) public view override returns (PythStructs.PriceFeed memory priceFeed) {
        if (priceFeeds[id].id == 0) revert PythErrors.PriceFeedNotFound();
        return priceFeeds[id];
    }

    function priceFeedExists(bytes32 id) public view override returns (bool) {
        return (true);
    }

    function getValidTimePeriod() public view override returns (uint) {
        return validTimePeriod;
    }

    // Takes an array of encoded price feeds and stores them.
    // You can create this data either by calling createPriceFeedData or
    // by using web3.js or ethers abi utilities.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable override {
        uint requiredFee = getUpdateFee(updateData);
        if (msg.value < requiredFee) revert PythErrors.InsufficientFee();
        console.log("Passed fee paid");
        // Chain ID is id of the source chain that the price update comes from. Since it is just a mock contract
        // We set it to 1.
        uint16 chainId = 1;

        for (uint i = 0; i < updateData.length; i++) {
            console.log("Attempting decode");
            PythStructs.PriceFeed memory priceFeed = abi.decode(
                updateData[i],
                (PythStructs.PriceFeed)
            );
            console.log("Passed decode");
            uint lastPublishTime = priceFeeds[priceFeed.id].price.publishTime;

            //if (lastPublishTime < priceFeed.price.publishTime) {
            // Price information is more recent than the existing price information.
            priceFeeds[priceFeed.id] = priceFeed;
            uint256 convertedNumber = uint256(uint64(priceFeed.price.price));
            console.log("priceFeed.price.price", convertedNumber);
            emit PriceFeedUpdate(
                priceFeed.id,
                uint64(lastPublishTime),
                priceFeed.price.price,
                priceFeed.price.conf
            );
            //}
        }

        // In the real contract, the input of this function contains multiple batches that each contain multiple prices.
        // This event is emitted when a batch is processed. In this mock contract we consider there is only one batch of prices.
        // Each batch has (chainId, sequenceNumber) as it's unique identifier. Here chainId is set to 1 and an increasing sequence number is used.
        emit BatchPriceFeedUpdate(chainId, sequenceNumber);
        sequenceNumber += 1;
    }

    function getUpdateFee(
        bytes[] calldata updateData
    ) public view override returns (uint feeAmount) {
        return singleUpdateFeeInWei * updateData.length;
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable override returns (PythStructs.PriceFeed[] memory feeds) {
        uint requiredFee = getUpdateFee(updateData);
        if (msg.value < requiredFee) revert PythErrors.InsufficientFee();

        feeds = new PythStructs.PriceFeed[](priceIds.length);

        for (uint i = 0; i < priceIds.length; i++) {
            for (uint j = 0; j < updateData.length; j++) {
                feeds[i] = abi.decode(updateData[j], (PythStructs.PriceFeed));

                if (feeds[i].id == priceIds[i]) {
                    uint publishTime = feeds[i].price.publishTime;
                    if (
                        minPublishTime <= publishTime &&
                        publishTime <= maxPublishTime
                    ) {
                        break;
                    } else {
                        feeds[i].id = 0;
                    }
                }
            }

            if (feeds[i].id != priceIds[i])
                revert PythErrors.PriceFeedNotFoundWithinRange();
        }
    }

    function createPriceFeedUpdateData(
        bytes32 id,
        int64 price,
        uint64 conf,
        int32 expo,
        int64 emaPrice,
        uint64 emaConf,
        uint64 publishTime
    ) public pure returns (bytes memory priceFeedData) {
        PythStructs.PriceFeed memory priceFeed;

        priceFeed.id = id;

        priceFeed.price.price = price;
        priceFeed.price.conf = conf;
        priceFeed.price.expo = expo;
        priceFeed.price.publishTime = publishTime;

        priceFeed.emaPrice.price = emaPrice;
        priceFeed.emaPrice.conf = emaConf;
        priceFeed.emaPrice.expo = expo;
        priceFeed.emaPrice.publishTime = publishTime;

        priceFeedData = abi.encode(priceFeed);
    }

    function mockPrices(
        bytes32 id,
        int64 price,
        uint64 conf,
        int32 expo,
        int64 emaPrice,
        uint64 emaConf,
        uint64 publishTime
    ) public view returns (bytes memory priceFeedData) {
        PythStructs.PriceFeed memory priceFeed;

        priceFeed.id = id;

        priceFeed.price.price = price;
        priceFeed.price.conf = conf;
        priceFeed.price.expo = expo;
        priceFeed.price.publishTime = publishTime;

        priceFeed.emaPrice.price = emaPrice;
        priceFeed.emaPrice.conf = emaConf;
        priceFeed.emaPrice.expo = expo;
        priceFeed.emaPrice.publishTime = publishTime;

        priceFeedData = abi.encode(priceFeed);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract MockUSDT is ERC20Burnable {
    address public owner;
    mapping(address => bool) public claimed;
    uint256 public uniqueClaimAmount = 10000e6;

    constructor() ERC20("MockUSDT", "USDT") {
        owner = msg.sender;
        _mint(msg.sender, 100000000000e18);
    }

    function mintMockTokens() public {
        require(
            claimed[msg.sender] == false,
            "Already claimed"
        );
        claimed[msg.sender] = true;
        _mint(msg.sender, uniqueClaimAmount);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract MockUSDT18 is ERC20Burnable {
    address public owner;
    mapping(address => bool) public claimed;
    uint256 public uniqueClaimAmount = 10000e6;

    constructor() ERC20("MockUSDT", "USDT") {
        owner = msg.sender;
        _mint(msg.sender, 100000000000e18);
    }

    function mintMockTokens() public {
        require(
            claimed[msg.sender] == false,
            "Already claimed"
        );
        claimed[msg.sender] = true;
        _mint(msg.sender, uniqueClaimAmount);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract MockXX is ERC20Burnable {
    address public owner;

    constructor() ERC20("MockXX", "XX") {
        owner = msg.sender;
        _mint(msg.sender, 1000000000000000000e18);
    }

    function mint(uint256 _amount) public {
        _mint(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity 0.8.15;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@pythnetwork/pyth-sdk-solidity/AbstractPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

interface IPythTestnet {
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    function queryPriceFeed(
        bytes32 id
    ) external view returns (PythStructs.PriceFeed memory priceFeed);
    
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);
}

contract SimplePriceUpdate {

    uint256 public price;
    uint256 public publishTime;
    address public PythOracle = 0x939C0e902FF5B3F7BA666Cc8F6aC75EE76d3f900;

    function getPrice(
        bytes[] calldata updateData,
        bytes32 _id
    ) public payable {


        IPythTestnet(PythOracle).updatePriceFeeds{
            value: IPythTestnet(PythOracle).getUpdateFee(updateData)
        }(updateData);

        PythStructs.PriceFeed memory priceFeed = IPythTestnet(PythOracle)
            .queryPriceFeed(_id);

        PythStructs.Price memory priceP = IPythTestnet(PythOracle)
            .getPriceNoOlderThan(_id,60);

        price = uint256(uint64(priceP.price));
        publishTime = priceFeed.price.publishTime;
    }
}

pragma solidity 0.8.15;
/**
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Hegic
 * Copyright (C) 2020 Hegic
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract WETHMock is IWETH, ERC20, Ownable {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
    mapping(address => bool) public used;
    uint256 public toMint;

    constructor() ERC20("Wrapped Ether", "WETH") {
        _mint(msg.sender, 100000000000000000000000000000e18);
    }

    fallback() external payable {
        deposit();
    }

    function setToMint(uint256 _toMint) public onlyOwner {
        toMint = _toMint;
    }

    function faucet() public {
        require(used[msg.sender] == false, "Already used, get rekted");
        used[msg.sender] = true;
        _mint(msg.sender, toMint);
    }

    receive() external payable {}

    function deposit() public payable override {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public override {
        _burn(msg.sender, wad);

        (bool success, ) = msg.sender.call{value: wad}("");
        require(success, "Withdraw failed");

        emit Withdrawal(msg.sender, wad);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";
import "./interfaces/IVester.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ITradingVault {
    function deposit(uint _amount, address _user) external;
}

contract NarwhalPool is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contracts & Addresses
    StorageInterface public immutable storageT;
    address public USDT;
    address public narToken;
    address public esToken;
    address public govFund;
    address public Vester;
    address public TradingVault;
    uint256 public MAX_INT = 2 ** 256 - 1;

    address public pendingGovFund;
    // Pool variables for NAR
    uint256 public accTokensPernarToken;
    uint256 public accUSDTPernarToken;
    uint256 public totalDeposited;
    uint256 public totalUSDTRewardsIncrement;

    // Mappings
    mapping(address => UserNwxRecords) public usernarrecords;
    mapping(address => bool) public allowedContracts;
    mapping(address => uint256) public cumulativeRewards;
    mapping(address => uint256) public averageStakedAmounts;
    mapping(address => mapping(address => uint256)) public depositBalances;
    mapping(address => uint256) public stakedAmounts;
    mapping(address => bool) public isTokenWhitelisted;
    mapping(address => uint256) public totalDepositedForToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 365 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    //Change back to 72 hours !!
    uint public withdrawTimelock = 1 minutes; // time
    bool public withdrawTimelockEnabled = false;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    struct UserNwxRecords {
        uint256 narDebtUSDT;
        uint256 amountInLockup;
        uint256 narLocked;
        uint256 esnarLocked;
        uint256 depositTimestamp;
    }

    // Pool stats
    uint256 public rewardsToken; // 1e18
    uint256 public rewardsUSDT; // usdtDecimals

    // Events
    event AddressUpdated(string name, address a);
    event ContractAllowed(address a, bool allowed);
    event RewardsDurationSet(uint256 rewardsDuration);
    event RewardsSet(uint256 rewards);

    constructor(address _tradingStorage, StorageInterface _storageT) {
        require(_tradingStorage != address(0), "ADDRESS_0");
        allowedContracts[_tradingStorage] = true;
        govFund = msg.sender;
        storageT = _storageT;
    }

    // GOV => UPDATE VARIABLES & MANAGE PAIRS

    // 0. Modifiers
    modifier onlyGov() {
        require(msg.sender == govFund, "GOV_ONLY");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // ONLY FOR DECIMAL 18 tokens
    function setTokenWhitelisted(address _token, bool _status) external onlyGov {
        require(_token == narToken || _token == esToken, "Invalid token");
        isTokenWhitelisted[_token] = _status;
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyGov {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        require(_rewardsDuration >= 183 days && _rewardsDuration <= 730 days, "Out of range");
        rewardsDuration = _rewardsDuration;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsDurationSet(_rewardsDuration);
    }

    function notifyRewardAmount(uint256 reward) external onlyGov updateReward(address(0)) {
        
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }
        IERC20(address(esToken)).safeTransferFrom(msg.sender, address(this), reward);
        uint balance = IERC20(address(esToken)).balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsSet(reward);
    }

    // Set addresses
    function setPendingGovFund(address _govFund) external onlyGov {
        require(_govFund != address(0), "ADDRESS_0");
        pendingGovFund = _govFund;
    }

    function confirmGovFund() external onlyGov {
        govFund = pendingGovFund;
        emit AddressUpdated("govFund", govFund);
    }

    function setVester(address _vester) external onlyGov {
        require(_vester != address(0), "ADDRESS_0");
        Vester = _vester;
        emit AddressUpdated("Vester", _vester);
    }

    function setEsToken(address _esToken) external onlyGov {
        require(address(_esToken) != address(0), "ADDRESS_0");
        esToken = _esToken;
        emit AddressUpdated("estoken", address(_esToken));
    }

    function setNARToken(address _narToken) external onlyGov {
        require(address(_narToken) != address(0), "ADDRESS_0");
        narToken = _narToken;
        emit AddressUpdated("nextoken", address(_narToken));
    }

    function setUSDT(address _USDT) external onlyGov {
        require(_USDT != address(0), "ADDRESS_0");
        USDT = _USDT;
        emit AddressUpdated("token", _USDT);
    }

    function setWithdrawTimelock(uint _withdrawTimelock) external onlyGov {
        require(_withdrawTimelock > 1 days, "Should be above 1 day");
        withdrawTimelock = _withdrawTimelock;
    }
    
    function setWithdrawTimelockEnabled() external onlyGov {
        withdrawTimelockEnabled = !withdrawTimelockEnabled;
    }

    function setTradingVault(address _tradingVault) external onlyGov {
        require(address(_tradingVault) != address(0), "ADDRESS_0");
        TradingVault = _tradingVault;
        emit AddressUpdated("token", address(_tradingVault));
    }

    function addAllowedContract(address c) external onlyGov {
        require(c != address(0), "ADDRESS_0");
        allowedContracts[c] = true;
        emit ContractAllowed(c, true);
    }

    function removeAllowedContract(address c) external onlyGov {
        require(c != address(0), "ADDRESS_0");
        allowedContracts[c] = false;
        emit ContractAllowed(c, false);
    }

    function increaseAccTokens(uint256 _amount) external {
        require(allowedContracts[msg.sender], "ONLY_ALLOWED_CONTRACTS");
        IERC20(USDT).safeTransferFrom(msg.sender, address(this), _amount);

        if (totalDeposited > 0) {
            accUSDTPernarToken += (_amount * 1e18) / totalDeposited;
            totalUSDTRewardsIncrement += _amount;
        }
    }

    function totalSupply() external view returns (uint256) {
        return totalDeposited;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint256 stakedToken = userTotalBalance(account);
        return stakedToken;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalDeposited == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalDeposited)
            );
    }

    function earned(address account) public view returns (uint256) {
        uint256 stakedToken = userTotalBalance(account);
        return stakedToken.mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function getUserTokenBalance(
        address _account
    ) external view returns (uint256) {
        return (stakedAmounts[_account]);
    }

    function getReservedAmount(address _account) external view returns (uint256) {
        UserNwxRecords storage unar = usernarrecords[_account];
        return (unar.amountInLockup);
    }

    function pendingRewardUSDTNARStake(
        address _account
    ) public view returns (uint) {
        if (totalDeposited == 0) {
            return 0;
        }
        UserNwxRecords storage unar = usernarrecords[_account];
        uint256 stakedToken = userTotalBalance(_account);
        uint256 pendings = (stakedToken * accUSDTPernarToken) /
            1e18 -
            unar.narDebtUSDT;
        return (pendings);
    }

    function getUserNARInfo(
        address _account
    ) external view returns (uint256, uint256) {
        UserNwxRecords storage unar = usernarrecords[_account];
        uint256 totalUserDeposited = stakedAmounts[_account];
        return (totalUserDeposited, unar.narDebtUSDT);
    }

    function _lockNAR(address _account, uint256 _amount) external {
        require(msg.sender == Vester, "Not the vesting contract");
        UserNwxRecords storage unar = usernarrecords[_account];
        stakedAmounts[_account] = stakedAmounts[_account].sub(_amount);
        unar.amountInLockup = unar.amountInLockup.add(_amount);

        uint256 amountDiv2 = _amount.div(2);
        uint256 narStaked = depositBalances[_account][address(narToken)];
        uint256 esnarStaked = depositBalances[_account][address(esToken)];

        if (amountDiv2 <= narStaked && amountDiv2 <= esnarStaked) {
            unar.narLocked += amountDiv2;
            unar.esnarLocked += amountDiv2;
        } else if (
            amountDiv2 <= narStaked &&
            amountDiv2 > esnarStaked &&
            _amount <= narStaked
        ) {
            unar.narLocked += _amount;
        } else if (
            amountDiv2 > narStaked &&
            amountDiv2 <= esnarStaked &&
            _amount <= esnarStaked
        ) {
            unar.esnarLocked += _amount;
        } else if (narStaked > esnarStaked && esnarStaked != 0) {
            unar.esnarLocked += _amount.sub(narStaked);
            unar.narLocked += _amount.sub(unar.esnarLocked);
        } else if (esnarStaked > narStaked && narStaked != 0) {
            unar.narLocked += _amount.sub(esnarStaked);
            unar.esnarLocked += _amount.sub(unar.narLocked);
        } else {
            revert("Adjust your staking balance");
        }
    }

    function _unLockNAR(address _account, uint256 _amount) external {
        require(msg.sender == Vester, "Not the vesting contract");
        UserNwxRecords storage unar = usernarrecords[_account];
        unar.amountInLockup = unar.amountInLockup.sub(_amount);
        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
        unar.narLocked = 0;
        unar.esnarLocked = 0;
    }

    // Harvest rewards
    function harvest(bool _compound) public updateReward(msg.sender) {
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        uint256 narRewards;
        uint256 USDTRewardsNAR;

        if (totalDeposited > 0) {
            (narRewards, USDTRewardsNAR) = _harvest();
        }

        uint256 pendingTokens = narRewards;
        uint256 pendingUSDTTotal = USDTRewardsNAR;

        if (pendingTokens > 0) {
            rewards[msg.sender] = 0;
            uint256 nextCumulativeReward = cumulativeRewards[msg.sender].add(
                pendingTokens
            );
            averageStakedAmounts[msg.sender] = averageStakedAmounts[msg.sender]
                .mul(cumulativeRewards[msg.sender])
                .div(nextCumulativeReward)
                .add(stakedAmounts[msg.sender].add(unar.amountInLockup))
                .mul((pendingTokens))
                .div(nextCumulativeReward);
            cumulativeRewards[msg.sender] = nextCumulativeReward;

            if (!_compound) {
                IERC20(esToken).safeTransfer(msg.sender, pendingTokens);
            } else {
                stakedAmounts[msg.sender] += pendingTokens;
                totalDeposited += pendingTokens;
                totalDepositedForToken[address(esToken)] += pendingTokens;

                uint256 stakedToken = userTotalBalance(msg.sender);
                unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;
                if (withdrawTimelockEnabled) {
                    unar.depositTimestamp = block.timestamp;
                }
                depositBalances[msg.sender][address(esToken)] += pendingTokens;
            }

        }

        if (pendingUSDTTotal > 0) {
            if (_compound) {
                IERC20(USDT).approve(TradingVault, pendingUSDTTotal);
                ITradingVault(TradingVault).deposit(
                    pendingUSDTTotal,
                    msg.sender
                );
            } else {
                IERC20(USDT).safeTransfer(msg.sender, pendingUSDTTotal);
            }
        }
    }

    function _harvest() internal returns (uint256, uint256) {
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        uint pendingES = rewards[msg.sender];
        uint pendingUSDT = pendingRewardUSDTNARStake(msg.sender);

        uint256 stakedToken = userTotalBalance(msg.sender);
        unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;
        rewardsUSDT += pendingUSDT;
        rewardsToken += pendingES;

        return (pendingES, pendingUSDT);
    }

    /**@notice Stakes the specified amount of tokens
    @param amount The amount of tokens to be staked
    @param _tokenAddress The address of the token being staked
    @dev Only users with whitelisted tokens can stake ONLY FOR DECIMAL 18 TOKENS
    /** */
    function stake(uint amount, address _tokenAddress) external nonReentrant updateReward(msg.sender) {
        require(isTokenWhitelisted[_tokenAddress], "Token not whitelisted");
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        harvest(false);
        IERC20(address(_tokenAddress)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        totalDeposited += amount;
        totalDepositedForToken[_tokenAddress] += amount;
        stakedAmounts[msg.sender] += amount;

        uint256 stakedToken = userTotalBalance(msg.sender);
        unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;
        if (withdrawTimelockEnabled) {
            unar.depositTimestamp = block.timestamp;
        }

        depositBalances[msg.sender][_tokenAddress] += amount;
    }

    /**

    @notice Unstake amount of _tokenAddress
    @param amount The amount of tokens to be unstaked
    @param _tokenAddress The address of the tokens to be unstaked
    @dev This function allows a user to unstake their tokens
    */
    function unstake(uint amount, address _tokenAddress) external nonReentrant updateReward(msg.sender) {
        require(isTokenWhitelisted[_tokenAddress], "Token not whitelisted");
        require(
            amount <= depositBalances[msg.sender][_tokenAddress],
            "AMOUNT_TOO_BIG"
        );
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        
        if (withdrawTimelockEnabled) {
            require(block.timestamp >= unar.depositTimestamp + withdrawTimelock,"TOO_EARLY");
        }

        harvest(false);
        uint256 am;
        uint256 availToWithdraw;
        bool lockup = false;
        if (unar.amountInLockup > 0) {
            (availToWithdraw, lockup) = userAvailToWithdraw(
                msg.sender,
                _tokenAddress
            );
        } else {
            availToWithdraw = depositBalances[msg.sender][_tokenAddress];
        }
        if (lockup) {
            require(amount <= availToWithdraw, "Amount too high");
            require(availToWithdraw != 0, "Nothing to withdraw");
            am = amount;
        } else {
            require(
                amount <= depositBalances[msg.sender][_tokenAddress],
                "Amount too high"
            );
            require(availToWithdraw != 0, "Nothing to withdraw");
            am = amount;
        }

        totalDeposited -= am;
        totalDepositedForToken[_tokenAddress] -= am;
        stakedAmounts[msg.sender] -= am;

        uint256 stakedToken = userTotalBalance(msg.sender);
        unar.narDebtUSDT = (stakedToken * accUSDTPernarToken) / 1e18;

        depositBalances[msg.sender][_tokenAddress] -= am;

        IERC20(_tokenAddress).safeTransfer(msg.sender, am);
    }

    /**
    @notice Check the available amount that a user can withdraw
    @param _user The address of the user
    @param _tokenAddress The address of the narToken to check
    @return The amount of tokens available to withdraw and a boolean indicating if the amount is locked up
    @dev This function checks if a user has any nar/es/Tokens locked up, and if so, how many are available to withdraw
    */
    function userAvailToWithdraw(
        address _user,
        address _tokenAddress
    ) public view returns (uint256, bool) {
        UserNwxRecords storage unar = usernarrecords[_user];

        uint256 narStaked = depositBalances[_user][address(narToken)];
        uint256 esnarStaked = depositBalances[_user][address(esToken)];

        uint256 availToWithdraw;
        if (stakedAmounts[_user] == 0) {
            availToWithdraw = 0;
        } else if (
            unar.narLocked > 0 && _tokenAddress == address(narToken)
        ) {
            availToWithdraw = narStaked.sub(unar.narLocked);
        } else if (
            unar.esnarLocked > 0 && _tokenAddress == address(esToken)
        ) {
            availToWithdraw = esnarStaked.sub(unar.esnarLocked);
        }

        return (availToWithdraw, true);
    }

    /**
    @notice Check the total balance of a user's staked nar/es/Tokens
    @param _user The address of the user
    @return The total amount of nar/es/Tokens staked by the user
    @dev This function returns the total amount of nar/es/Tokens staked by the user, including any locked up tokens
    */
    function userTotalBalance(address _user) public view returns (uint256) {
        UserNwxRecords storage unar = usernarrecords[msg.sender];
        uint256 staked;
        if (unar.amountInLockup > 0) {
            staked = unar.amountInLockup.add(stakedAmounts[_user]);
        } else {
            staked = stakedAmounts[_user];
        }
        return staked;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/CallbacksInterface.sol";
import "./interfaces/LpInterfaceV5.sol";
import "./libraries/FullMath.sol";

import "@pythnetwork/pyth-sdk-solidity/AbstractPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface INarwhal {
    function tempSlippage() external view returns (uint256);

    function tempSpreadReduction() external view returns (uint256);

    function tempSL() external view returns (uint256);

    function isLimitOrder() external view returns (bool);

    function tempOrderId() external view returns (uint256);
}

interface IPythTestnet {
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    function queryPriceFeed(
        bytes32 id
    ) external view returns (PythStructs.PriceFeed memory priceFeed);
    
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    function priceFeedExists(
        bytes32 id
    ) external view returns (bool);
    
}

interface IUniswapOracle {
    function consult(
        address token,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}

contract NarwhalPriceAggregator {
    using FixedPoint for *;
    using SafeMath for uint256;

    // Contracts (constant)
    StorageInterface public immutable storageT;
    address public PythOracle;
    address public NarwhalTrading;
    // Contracts (adjustable)
    address public pairsStorage;
    bytes32 public USDTFeed;

    // Params (constant)
    uint256 constant PRECISION = 1e10;
    uint256 public age = 60; //seconds price confidence

    // Custom data types
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    struct Order {
        uint pairIndex;
        OrderType orderType;
        uint pythFeePerNode;
        bool initiated;
    }

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }

    struct PendingMarket {
        uint block;
        uint wantedPrice;
        uint slippageP;
        uint spreadReductionP;
        uint tokenId;
    }

    mapping(uint => Order) public orders;
    mapping(uint => uint[]) public ordersAnswers;
    mapping(uint => PendingSl) public pendingSlOrders;

    // Events
    event PairsStorageUpdated(address value);
    event USDTFeedSet(bytes32 indexed feed);
    event OracleSet(address indexed oracle);
    event AgeSet(uint256 age);
    event NarwhalTradingSet(address indexed NarwhalTrading);

    constructor(
        StorageInterface _storageT,
        address _pairsStorage,
        address _PythOracle,
        bytes32 _usdtFeed
    ) {
        require(
            address(_storageT) != address(0) &&
                address(_pairsStorage) != address(0) &&
                address(_PythOracle) != address(0),
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        PythOracle = _PythOracle;
        pairsStorage = _pairsStorage;
        USDTFeed = _usdtFeed;
        require(IPythTestnet(PythOracle).priceFeedExists(USDTFeed),"INCORRECT_PRICE_FEED");
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyTrading() {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Manage contracts
    function updatePairsStorage(address value) external onlyGov {
        require(address(value) != address(0), "VALUE_0");

        pairsStorage = value;

        emit PairsStorageUpdated(address(value));
    }

    function setUSDTFeed(bytes32 _feed) public onlyGov {
        require(IPythTestnet(PythOracle).priceFeedExists(_feed),"INCORRECT_PRICE_FEED");
        USDTFeed = _feed;
        emit USDTFeedSet(_feed);
    }

    function setOracle(address _oracle) public onlyGov {
        require(_oracle != address(0), "ZERO_ADDRESS");
        PythOracle = _oracle;
        emit OracleSet(_oracle);
    }

    function setAge(uint256 _age) public onlyGov {
        require(_age <= 60, "Too much");
        age = _age;
        emit AgeSet(_age);
    }

    function setNarwhalTrading(address _NarwhalTrading) public onlyGov {
        require(_NarwhalTrading != address(0), "ZERO_ADDRESS");
        NarwhalTrading = _NarwhalTrading;
        emit NarwhalTradingSet(_NarwhalTrading);
    }
    
    function tokenPriceUSDT() public view returns (uint256) {
        //testnet
        PythStructs.Price memory priceP = IPythTestnet(PythOracle)
           .getPriceUnsafe(USDTFeed);
        //mainnet
        // PythStructs.Price memory priceP = IPythTestnet(PythOracle)
        //      .getPriceNoOlderThan(USDTFeed,age);

        uint256 price = uint256(uint64(priceP.price));
        require(price != 0, "PRICE_FEED_ERROR");
        uint256 convertedNumber = price * 1e10;
        return convertedNumber;
    }

    function beforeGetPriceLimit(
        StorageInterface.Trade memory t
    ) public onlyTrading returns (uint256) {
        (, , uint orderId) = PairsStorageInterface(pairsStorage).pairJob(
            t.pairIndex
        );
        return (orderId);
    }

    function updatePriceFeed(uint256 pairIndex,bytes[] calldata updateData) public payable onlyTrading returns (uint256) {
        PairsStorageInterface.Feed memory f = PairsStorageInterface(
            pairsStorage
        ).pairFeed(pairIndex);

        IPythTestnet(PythOracle).updatePriceFeeds{
            value: getPythFee(updateData)
        }(updateData);

        // //mainnet
        // PythStructs.Price memory priceP = IPythTestnet(PythOracle)
        //      .getPriceNoOlderThan(f.feed1,age);

        //testnet
        PythStructs.Price memory priceP = IPythTestnet(PythOracle)
           .getPriceUnsafe(f.feed1);

        uint256 convertedNumber = uint256(uint64(priceP.price));
        int32 expRefactor = priceP.expo + 18;
        uint256 factor;
        if (expRefactor > 0) {
            factor = tenPow(expRefactor);
        } else {
            revert("Check the feed decimals");
        }
        uint256 precisionPrice = convertedNumber * (factor);
        return (precisionPrice);
    }

    // On-demand price request to oracles network
    function getPrice(
        OrderType orderType,
        bytes[] calldata updateData,
        StorageInterface.Trade memory t
    ) public onlyTrading returns (uint, uint256) {
        uint orderId;
        if (INarwhal(NarwhalTrading).isLimitOrder()) {
            orderId = INarwhal(NarwhalTrading).tempOrderId();
        } else {
            orderId = beforeGetPriceLimit(t);
        }

        orders[orderId] = Order(
            t.pairIndex,
            orderType,
            getPythFee(updateData),
            true
        );

        uint256 precisionPrice = updatePriceFeed(t.pairIndex,updateData);

        if (orderType == OrderType.MARKET_CLOSE) {
            storageT.storePendingMarketOrder(
                StorageInterface.PendingMarketOrder(
                    StorageInterface.Trade(
                        t.trader,
                        t.pairIndex,
                        t.index,
                        0,
                        0,
                        0,
                        false,
                        0,
                        0,
                        0
                    ),
                    0,
                    0,
                    0,
                    0,
                    0
                ),
                orderId,
                false
            );
        } else if (orderType == OrderType.MARKET_OPEN) {
            storageT.storePendingMarketOrder(
                StorageInterface.PendingMarketOrder(
                    StorageInterface.Trade(
                        t.trader,
                        t.pairIndex,
                        0,
                        0,
                        t.positionSizeUSDT,
                        0,
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    INarwhal(NarwhalTrading).tempSlippage(),
                    INarwhal(NarwhalTrading).tempSpreadReduction(),
                    0
                ),
                orderId,
                true
            );
        } else {
            storePendingSlOrder(
                orderId,
                PendingSl(
                    t.trader,
                    t.pairIndex,
                    t.index,
                    t.openPrice,
                    t.buy,
                    INarwhal(NarwhalTrading).tempSL()
                )
            );
        }

        
        fulfill(orderId, precisionPrice);
        return (orderId, precisionPrice);
    }

    function tenPow(int32 exp) internal pure returns (uint256) {
        uint256 result = 1;
        for (int32 i = 0; i < exp; i++) {
            result = result.mul(10);
        }
        return result;
    }

    // Fulfill on-demand price requests
    function fulfill(uint256 orderId, uint256 price) internal {

        Order memory r = orders[orderId];
        if (!r.initiated) {
            return;
        }

        uint[] storage answers = ordersAnswers[orderId];
        answers.push(price);

        CallbacksInterface.AggregatorAnswer memory a;
        a.orderId = orderId;
        a.price = price;
        a.spreadP = PairsStorageInterface(pairsStorage).pairSpreadP(
            r.pairIndex
        );

        CallbacksInterface c = CallbacksInterface(storageT.callbacks());
        if (r.orderType == OrderType.MARKET_OPEN) {
            c.openTradeMarketCallback(a);
        } else if (r.orderType == OrderType.MARKET_CLOSE) {
            c.closeTradeMarketCallback(a);
        } else if (r.orderType == OrderType.LIMIT_OPEN) {
            c.executeOpenOrderCallback(a);
        } else if (r.orderType == OrderType.LIMIT_CLOSE) {
            c.executeCloseOrderCallback(a);
        } else {
            c.updateSlCallback(a);
        }

        delete orders[orderId];
        delete ordersAnswers[orderId];
    }

    function getPythFee(
        bytes[] calldata updateData
    ) public view returns (uint) {
        uint256 feeAmount = IPythTestnet(PythOracle).getUpdateFee(updateData);
        return feeAmount;
    }

    // Manage pending SL orders
    function storePendingSlOrder(uint orderId, PendingSl memory p) internal {
        pendingSlOrders[orderId] = p;
    }

    function unregisterPendingSlOrder(uint orderId) external {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");

        delete pendingSlOrders[orderId];
    }

    // Median function
    function swap(uint[] memory array, uint i, uint j) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function sort(uint[] memory array, uint begin, uint end) private pure {
        if (begin >= end) {
            return;
        }

        uint j = begin;
        uint pivot = array[j];

        for (uint i = begin + 1; i < end; ++i) {
            if (array[i] < pivot) {
                swap(array, i, ++j);
            }
        }

        swap(array, begin, j);
        sort(array, begin, j);
        sort(array, j + 1, end);
    }

    function median(uint[] memory array) private pure returns (uint) {
        sort(array, 0, array.length);

        return
            array.length % 2 == 0
                ? (array[array.length / 2 - 1] + array[array.length / 2]) / 2
                : array[array.length / 2];
    }

    // Storage v5 compatibility
    function openFeeP(uint pairIndex) external view returns (uint) {
        return PairsStorageInterface(pairsStorage).pairOpenFeeP(pairIndex);
    }

    function withdrawETH(address payable recipient) external onlyGov {
        require(recipient != address(0), "Invalid address");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";


interface ITradingVault {
    function deposit(uint _amount, address _user) external;
}

contract NarwhalReferrals is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // CONSTANTS
    StorageInterface public storageT;

    // ADJUSTABLE PARAMETERS
    uint256 public baseReferralDiscount; //% in 1000 precision, 100 = 10 %
    uint256 public baseReferralRebate; //%
    uint256 public tier3tier2RebateBonus; //%
    address public USDT;
    address public TradingVault;
    CountersUpgradeable.Counter public nonce;

    struct ReferrerDetails {
        address[] userReferralList;
        uint volumeReferredUSDT; // 1e18
        uint pendingRewards; // 1e18
        uint totalRewards; // 1e18
        bool registered;
        uint256 referralLink;
        bool canChangeReferralLink;
        address userReferredFrom;
        bool isWhitelisted;
        uint256 discount;
        uint256 rebate;
        uint256 tier;
    }

    // STATE (MAPPINGS)
    mapping(address => ReferrerDetails) public referrerDetails;
    mapping(address => bool) public isTier3Referred;
    mapping(address => address) public referral;
    mapping(address => address[]) public tier3RefList;
    mapping(address => address) public tier2ReferredTier3;
    mapping(address => mapping(address => uint256)) public tier2tier3TotalComissions;
    mapping(uint256 => address) public refLinkToUser;
    mapping(address => bool) public allowedToInteract;

    // Events
    event TradingStorageSet(address indexed storageT);
    event AllowedToInteractSet(address indexed sender, bool status);
    event BaseRebatesAndDiscountsSet(uint256 discount, uint256 rebate);
    event Tier3Tier2RebateBonusSet(uint256 tier3tier2RebateBonus);
    event TradingVaultSet(address indexed tradingVault);
    event WhitelistedAddressSet(address indexed toWhitelist, bool status, uint256 rebate, uint256 discount, uint256 tier);
    event RewardsClaimed(address indexed user, uint256 amount, bool compounded);
    event ReferralLinkChanged(address indexed user, uint256 newReferralLink);
    event UserSignedUp(address indexed user, address indexed referral);
    event ReferredKOLUnder(address indexed tier3, address indexed tier2);
    event IncrementedTier2Tier3(address indexed tier2, address indexed tier3,uint256 rewardTier2,uint256 rewardTier3,uint256 tradeSize);
    event RewardsIncremented(address user,uint256 rewards,uint256 tradeSize);

    function initialize(StorageInterface _storageT, address _tradingVault) public initializer {
        require(address(_storageT) != address(0), "ADDRESS_0");
        storageT = _storageT;
        USDT = address(storageT.USDT());
        TradingVault = _tradingVault;

        baseReferralDiscount = 100; //% in 1000 precision, 100 = 10 %
        baseReferralRebate = 100; //%
        tier3tier2RebateBonus = 100; //%
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // MODIFIERS
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyTrading() {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    function getReferralDetails(
        address _user
    ) public view returns (ReferrerDetails memory) {
        ReferrerDetails memory ref = referrerDetails[_user];
        return (ref);
    }

    function getReferralDiscountAndRebate(
        address _user
    ) public view returns (uint256, uint256) {
        ReferrerDetails memory ref = referrerDetails[_user];
        return (ref.discount, ref.rebate);
    }

    function isTier3KOL(address _user) public view returns (bool) {
        return (isTier3Referred[_user]);
    }

    function getReferral(address _user) public view returns (address) {
        return (referral[_user]);
    }

    function setTradingStorage(StorageInterface _storageT) public onlyOwner {
        require(address(_storageT) != address(0), "ADDRESS_0");
        storageT = _storageT;
        emit TradingStorageSet(address(_storageT));
    }
    
    function setAllowedToInteract(address _sender, bool _status) public onlyOwner {
        allowedToInteract[_sender] = _status;
        emit AllowedToInteractSet(_sender, _status);
    }

    function setBaseRebatesAndDiscounts(
        uint256 _discount,
        uint256 _rebate
    ) public onlyOwner {
        baseReferralDiscount = _discount;
        baseReferralRebate = _rebate;
        emit BaseRebatesAndDiscountsSet(_discount, _rebate);
    }

    function setTier3Tier2RebateBonus(
        uint256 _tier3tier2RebateBonus
    ) public onlyOwner {
        tier3tier2RebateBonus = _tier3tier2RebateBonus;
        emit Tier3Tier2RebateBonusSet(_tier3tier2RebateBonus);
    }

    function setTradingVault(address _tradingVault) external onlyOwner {
        require(address(_tradingVault) != address(0), "ADDRESS_0");
        TradingVault = _tradingVault;
        emit TradingVaultSet(_tradingVault);
    }

    function setWhitelistedAddress(
        address _toWhitelist,
        bool _status,
        uint256 _rebate,
        uint256 _discount,
        uint256 _tier
    ) public onlyOwner {
        require(_toWhitelist != address(0), "No 0 addresses ser");
        ReferrerDetails storage ref = referrerDetails[_toWhitelist];
        require(ref.registered == true, "Ask the user to register first");
        require(_tier == 2 || _tier == 3, "Wrong tier");

        ref.isWhitelisted = _status;
        ref.discount = _discount;
        ref.rebate = _rebate;
        ref.tier = _tier;
        emit WhitelistedAddressSet(_toWhitelist, _status, _rebate, _discount, _tier);
    }

    function referKOLUnder(address _tier3, address _tier2) public onlyOwner {
        require(
            _tier3 != address(0) && _tier2 != address(0),
            "No 0 addresses ser"
        );
        require(_tier3 != _tier2, "No identical addresses");
        ReferrerDetails memory ref = referrerDetails[_tier3];
        ReferrerDetails memory ref2 = referrerDetails[_tier2];
        require(
            ref2.registered == true && ref.registered == true,
            "Ask the user to register first"
        );
        tier3RefList[_tier3].push(_tier2);
        tier2ReferredTier3[_tier2] = _tier3;
        isTier3Referred[_tier2] = true;
        emit ReferredKOLUnder(_tier3,_tier2);
    }

    function incrementTier2Tier3(
        address _tier2,
        uint256 _rewardTier2,
        uint256 _rewardTier3,
        uint256 _tradeSize
    ) public onlyCallbacks {
        address tier3 = tier2ReferredTier3[_tier2];
        ReferrerDetails storage refTier2 = referrerDetails[_tier2];
        ReferrerDetails storage refTier3 = referrerDetails[tier3];
        refTier2.pendingRewards += _rewardTier2;
        refTier3.pendingRewards += _rewardTier3;
        refTier2.volumeReferredUSDT += _tradeSize;
        refTier3.volumeReferredUSDT += _tradeSize;
        tier2tier3TotalComissions[_tier2][tier3] += (
            _rewardTier2.add(_rewardTier3)
        );
        emit IncrementedTier2Tier3(_tier2, tier3, _rewardTier2, _rewardTier3, _tradeSize);
    }

    function incrementRewards(
        address _user,
        uint256 _rewards,
        uint256 _tradeSize
    ) public onlyCallbacks {
        ReferrerDetails storage ref = referrerDetails[_user];
        ref.pendingRewards += _rewards;
        ref.volumeReferredUSDT += _tradeSize;
        emit RewardsIncremented(_user,_rewards,_tradeSize);
    }

    function claimRewards(bool _compound) public nonReentrant {
        ReferrerDetails storage ref = referrerDetails[msg.sender];
        require(ref.registered == true, "You are not registered");
        uint256 pendings = ref.pendingRewards;
        if (pendings > 0) {
            ref.pendingRewards = 0;
            ref.totalRewards += pendings;
            if (_compound) {
                require(IERC20Upgradeable(USDT).approve(TradingVault, pendings), "Approval failed");
                ITradingVault(TradingVault).deposit(pendings, msg.sender);
            } else {
                IERC20Upgradeable(USDT).safeTransfer(msg.sender, pendings);
            }
            emit RewardsClaimed(msg.sender, pendings, _compound);
        }
    }

    //Core functions.
    function changeReferralLink(uint256 _referralLink) public nonReentrant {
        address user = msg.sender;
        ReferrerDetails storage ref = referrerDetails[user];
        address referrer = refLinkToUser[_referralLink];
        require(
            ref.canChangeReferralLink == true && ref.registered == true,
            "You are already signed up with a link or changed it once"
        );
        require(
            referrer != address(0) && referrer != msg.sender,
            "Incorrect ref link"
        );

        ref.userReferredFrom = referrer;
        ref.canChangeReferralLink = false;

        ReferrerDetails storage refFrom = referrerDetails[referrer];
        refFrom.userReferralList.push(user);
        emit ReferralLinkChanged(msg.sender, _referralLink);
    }

    //This just signs up the user with admin ref link
    function signUp(address _user, address _referral) public nonReentrant {
        require(_user != _referral, "No identical addresses");
        require(_user != address(0), "No 0 addresses ser");
        address user;
        if (msg.sender == address(storageT)) {
            user = _user;
        } else {
            user = msg.sender;
        }

        ReferrerDetails storage ref = referrerDetails[user];

        require(ref.registered == false, "You are already registered");
        require(
            refLinkToUser[nonce.current()] == address(0),
            "Referral Link already taken"
        );

        ref.referralLink = nonce.current();
        refLinkToUser[nonce.current()] = user;
        ref.registered = true;
        nonce.increment();

        if (_referral == address(0)) {
            ref.userReferredFrom = address(0);
            referral[user] = address(0);
            ref.canChangeReferralLink = true;
            ref.discount = baseReferralDiscount;
            ref.rebate = baseReferralRebate;
        } else {
            ReferrerDetails storage refFrom = referrerDetails[_referral];
            require(refFrom.registered == true, "Referrer not registered");
            ref.userReferredFrom = _referral;
            referral[user] = _referral;

            ref.canChangeReferralLink = false;
            refFrom.userReferralList.push(user);
            ref.discount = refFrom.discount;
            ref.rebate = baseReferralRebate;
        }
        ref.tier = 1;
        emit UserSignedUp(user, _referral);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";
import "./interfaces/CallbacksInterface.sol";

contract NarwhalTrading is Initializable, ReentrancyGuardUpgradeable {

    StorageInterface public storageT;
    PairInfoInterface public pairInfos;
    LimitOrdersInterface public limitOrders;

    uint public PRECISION;
    uint public MAX_SL_P;
    uint public MAX_GAIN_P;

    address public VaultFactory;

    uint public maxPosUSDT; // usdtDecimals (eg. 75000 * usdtDecimals)
    uint public limitOrdersTimelock; // block (eg. 30)
    uint public marketOrdersTimeout; // block (eg. 30)
    uint256 public timeLimit; //block

    bool public isDone;
    mapping(address => uint256) public orderExecutionTimeLimit;
    mapping(address => bool) public allowedToInteract;
    uint256 public tempSlippage;
    uint256 public tempSpreadReduction;
    uint256 public tempSL;
    bool public isLimitOrder;
    uint256 public tempOrderId;

    // Events
    event Done(bool done);

    event NumberUpdated(string name, uint value);

    event OrderExecutionData(
        address trader,
        uint pairIndex,
        uint positionSizeUSDT,
        uint openPrice,
        uint currentPrice,
        bool buy,
        uint leverage,
        uint256 openTime,
        uint256 closeTime);

    event OpenLimitPlaced(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );
    event OpenLimitUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newPrice,
        uint newTp,
        uint newSl
    );
    event OpenLimitCanceled(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event TpUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newTp
    );
    event SlUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );
    event SlUpdateInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );

    event CouldNotCloseTrade(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event AllowedToInteractSet(address indexed sender, bool status);

    function initialize(
        StorageInterface _storageT,
        LimitOrdersInterface _limitOrders,
        PairInfoInterface _pairInfos,
        uint _maxPosUSDT,
        uint _limitOrdersTimelock,
        uint _marketOrdersTimeout
    ) public initializer {
        require(
            address(_storageT) != address(0) &&
                address(_pairInfos) != address(0) &&
                _maxPosUSDT > 0 &&
                _limitOrdersTimelock > 0 &&
                _marketOrdersTimeout > 0,
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        pairInfos = _pairInfos;
        limitOrders = _limitOrders;

        PRECISION = 1e10;
        MAX_SL_P = 90; // -90% PNL
        MAX_GAIN_P = 900;
        timeLimit = 1;

        maxPosUSDT = _maxPosUSDT;
        limitOrdersTimelock = _limitOrdersTimelock;
        marketOrdersTimeout = _marketOrdersTimeout;
        __ReentrancyGuard_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier notContract() {
        if (allowedToInteract[msg.sender]) {} else {
            require(tx.origin == msg.sender);
        }

        _;
    }
    modifier notDone() {
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setMaxPosUSDT(uint value) external onlyGov {
        require(value > 0, "VALUE_0");
        maxPosUSDT = value;

        emit NumberUpdated("maxPosUSDT", value);
    }

    function setLimitOrdersTimelock(uint value) external onlyGov {
        require(value > 0, "VALUE_0");
        limitOrdersTimelock = value;

        emit NumberUpdated("limitOrdersTimelock", value);
    }

    function setTimeLimit(uint256 _timeLimit) public onlyGov{
        require(_timeLimit < 5, "Time limit too high");
        timeLimit = _timeLimit;
    }

    function setAllowedToInteract(address _contract, bool _status) public {
        require(msg.sender == VaultFactory, "Not vault factory");
        allowedToInteract[_contract] = _status;
        emit AllowedToInteractSet(_contract, _status);
    }

    function setVaultFactory(address _VaultFactory) public onlyGov {
        require(_VaultFactory != address(0), "No dead address");
        VaultFactory = _VaultFactory;
    }

    function setMarketOrdersTimeout(uint value) external onlyGov {
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;

        emit NumberUpdated("marketOrdersTimeout", value);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // Execute limit order
    function executeLimitOrder(
        StorageInterface.LimitOrder orderType,
        address trader,
        uint pairIndex,
        uint index,
        bytes[] calldata updateData
    ) external notContract notDone nonReentrant {
        address sender = msg.sender;
        uint256 openTimestamp;
        uint256 price;
        StorageInterface.Trade memory t;
        require(block.number > orderExecutionTimeLimit[trader] + (timeLimit),"Wait a bit more");
        if (orderType == StorageInterface.LimitOrder.OPEN) {
            require(
                storageT.hasOpenLimitOrder(trader, pairIndex, index),
                "NO_LIMIT"
            );
        } else {
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");
            
            if (orderType == StorageInterface.LimitOrder.LIQ) {
                uint liqPrice = getTradeLiquidationPrice(t);

                require(
                    t.sl == 0 || (t.buy ? liqPrice > t.sl : liqPrice < t.sl),
                    "HAS_SL"
                );
            } else {
                require(
                    orderType != StorageInterface.LimitOrder.SL || t.sl > 0,
                    "NO_SL"
                );
                require(
                    orderType != StorageInterface.LimitOrder.TP || t.tp > 0,
                    "NO_TP"
                );
            }
        }
        
        LimitOrdersInterface.TriggeredLimitId
            memory triggeredLimitId = LimitOrdersInterface.TriggeredLimitId(
                trader,
                pairIndex,
                index,
                orderType
            );

        if (
            !limitOrders.triggered(triggeredLimitId) ||
            limitOrders.timedOut(triggeredLimitId)
        ) {
            uint leveragedPosUSDT;

            if (orderType == StorageInterface.LimitOrder.OPEN) {
                StorageInterface.OpenLimitOrder memory l = storageT
                    .getOpenLimitOrder(trader, pairIndex, index);

                leveragedPosUSDT = l.positionSize * l.leverage;

                (uint priceImpactP, ) = pairInfos.getTradePriceImpact(
                    0,
                    l.pairIndex,
                    l.buy,
                    leveragedPosUSDT
                );

                require(
                    priceImpactP * l.leverage <=
                        pairInfos.maxNegativePnlOnOpenP(),
                    "PRICE_IMPACT_TOO_HIGH"
                );
            } else {
                leveragedPosUSDT =
                    (t.initialPosToken *
                        storageT
                            .openTradesInfo(trader, pairIndex, index)
                            .tokenPriceUSDT *
                        t.leverage) /
                    PRECISION;
            }

            isLimitOrder = true;
            tempOrderId = storageT.priceAggregator().beforeGetPriceLimit(t);
            storageT.storePendingLimitOrder(
                StorageInterface.PendingLimitOrder(
                    sender,
                    trader,
                    pairIndex,
                    index,
                    orderType
                ),
                tempOrderId
            );

            openTimestamp = storageT.openTimestamp(trader, pairIndex, index);
            (,price) = storageT.priceAggregator().getPrice(
                orderType == StorageInterface.LimitOrder.OPEN
                    ? AggregatorInterfaceV6_2.OrderType.LIMIT_OPEN
                    : AggregatorInterfaceV6_2.OrderType.LIMIT_CLOSE,
                updateData,
                t
            );

            isLimitOrder = false;
            delete tempOrderId;

            limitOrders.storeFirstToTrigger(triggeredLimitId, sender);
        } else {
            limitOrders.storeTriggerSameBlock(triggeredLimitId, sender);
        }

        bool closeSuccessful = storageT.tempTradeStatus(trader,pairIndex,index);
        if (closeSuccessful) {
            emit OrderExecutionData(t.trader,t.pairIndex,t.positionSizeUSDT, t.openPrice,price,t.buy,t.leverage,openTimestamp,block.timestamp);
        }

    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        StorageInterface.Trade memory t,
        LimitOrdersInterface.OpenLimitOrderType orderType, // LEGACY => market
        uint spreadReductionId,
        uint slippageP, // for market orders only
        bytes[] calldata updateData
    ) external notContract notDone nonReentrant {
        PairsStorageInterface pairsStored = storageT
            .priceAggregator()
            .pairsStorage();

        require(block.number > orderExecutionTimeLimit[msg.sender] + (timeLimit),"Wait a bit more");
        require(
            storageT.openTradesCount(t.trader, t.pairIndex) +
                storageT.pendingMarketOpenCount(t.trader, t.pairIndex) +
                storageT.openLimitOrdersCount(t.trader, t.pairIndex) <
                storageT.maxTradesPerPair(),
            "MAX_TRADES_PER_PAIR"
        );

        require(
            storageT.pendingOrderIdsCount(t.trader) <
                storageT.maxPendingMarketOrders(),
            "MAX_PENDING_ORDERS"
        );

        require(t.positionSizeUSDT <= maxPosUSDT, "ABOVE_MAX_POS");
        require(
            t.positionSizeUSDT * t.leverage >=
                pairsStored.pairMinLevPosUSDT(t.pairIndex),
            "BELOW_MIN_POS"
        );

        require(
            t.leverage > 0 &&
                t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) &&
                t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex),
            "LEVERAGE_INCORRECT"
        );

        require(
            t.tp == 0 || (t.buy ? t.tp > t.openPrice : t.tp < t.openPrice),
            "WRONG_TP"
        );

        require(
            t.sl == 0 || (t.buy ? t.sl < t.openPrice : t.sl > t.openPrice),
            "WRONG_SL"
        );

        (uint priceImpactP, ) = pairInfos.getTradePriceImpact(
            0,
            t.pairIndex,
            t.buy,
            t.positionSizeUSDT * t.leverage
        );

        require(
            priceImpactP * t.leverage <= pairInfos.maxNegativePnlOnOpenP(),
            "PRICE_IMPACT_TOO_HIGH"
        );

        storageT.transferUSDT(
            msg.sender,
            address(storageT),
            t.positionSizeUSDT
        );

        if (orderType != LimitOrdersInterface.OpenLimitOrderType.LEGACY) {
            uint index = storageT.firstEmptyOpenLimitIndex(
                t.trader,
                t.pairIndex
            );

            storageT.storeOpenLimitOrder(
                StorageInterface.OpenLimitOrder(
                    t.trader,
                    t.pairIndex,
                    index,
                    t.positionSizeUSDT,
                    spreadReductionId > 0
                        ? storageT.spreadReductionsP(spreadReductionId - 1)
                        : 0,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    0
                )
            );

            limitOrders.setOpenLimitOrderType(
                t.trader,
                t.pairIndex,
                index,
                orderType
            );
            emit OpenLimitPlaced(t.trader, t.pairIndex, index);
        } else {
            tempSlippage = slippageP;
            tempSpreadReduction = spreadReductionId > 0
                ? storageT.spreadReductionsP(spreadReductionId - 1)
                : 0;

            storageT.priceAggregator().getPrice(
                AggregatorInterfaceV6_2.OrderType.MARKET_OPEN,
                updateData,
                t
            );
            tempSlippage = 0;
            tempSpreadReduction = 0;
        }
        orderExecutionTimeLimit[msg.sender] = block.number;
    }

    // Close trade (MARKET)
    function closeTradeMarket(
        uint pairIndex,
        uint index,
        bytes[] calldata updateData
    ) external notContract notDone nonReentrant {
        address sender = msg.sender;
        require(block.number > orderExecutionTimeLimit[sender] + (timeLimit),"Wait a bit more");
        StorageInterface.Trade memory t = storageT.openTrades(
            sender,
            pairIndex,
            index
        );

        StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
            sender,
            pairIndex,
            index
        );

        require(
            storageT.pendingOrderIdsCount(sender) <
                storageT.maxPendingMarketOrders(),
            "MAX_PENDING_ORDERS"
        );

        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");
        uint256 openTime = storageT.openTimestamp(t.trader,t.pairIndex,t.index);
        (uint orderId,uint256 price) = storageT.priceAggregator().getPrice(
            AggregatorInterfaceV6_2.OrderType.MARKET_CLOSE,
            updateData,
            t
        );
        orderExecutionTimeLimit[msg.sender] = block.number;
        emit OrderExecutionData(t.trader,t.pairIndex,t.positionSizeUSDT, t.openPrice,price,t.buy,t.leverage,openTime,block.timestamp);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex,
        uint index,
        uint price, // PRECISION
        uint tp,
        uint sl
    ) external notContract notDone {
        address sender = msg.sender;

        require(
            storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT"
        );

        require(block.number > orderExecutionTimeLimit[sender] + (timeLimit),"Wait a bit more");

        StorageInterface.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender,
            pairIndex,
            index
        );

        require(
            block.number - o.block >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        require(tp == 0 || (o.buy ? tp > price : tp < price), "WRONG_TP");

        require(sl == 0 || (o.buy ? sl < price : sl > price), "WRONG_SL");

        o.minPrice = price;
        o.maxPrice = price;

        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);
        orderExecutionTimeLimit[sender] = block.number;
        emit OpenLimitUpdated(sender, pairIndex, index, price, tp, sl);
    }

    function cancelOpenLimitOrder(
        uint pairIndex,
        uint index
    ) external notContract notDone {
        address sender = msg.sender;

        require(
            storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT"
        );

        StorageInterface.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender,
            pairIndex,
            index
        );

        require(
            block.number - o.block >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferUSDT(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(sender, pairIndex, index);
    }

    // Manage limit order (TP/SL)
    function updateTp(
        uint pairIndex,
        uint index,
        uint newTp,
        bytes[] calldata updateData
    ) external notContract notDone {
        address sender = msg.sender;
        
        StorageInterface.Trade memory t = storageT.openTrades(
            sender,
            pairIndex,
            index
        );
        require(t.leverage > 0, "NO_TRADE");
        StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
            sender,
            pairIndex,
            index
        );
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        uint256 price = aggregator.updatePriceFeed(
            t.pairIndex,
            updateData
        );
        uint256 maxtp = maxTP(t.openPrice, t.leverage, t.buy);

        // Ensure newTp is between the current price and the maximum take profit.
        require(
            t.buy ? price <= newTp && newTp <= maxtp : maxtp <= newTp && newTp <= price,
            "WRONG_TP"
        );
        
        require(
            block.number - i.tpLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        storageT.updateTp(sender, pairIndex, index, newTp);
        emit TpUpdated(sender, pairIndex, index, newTp);
    }

    function maxTP(
        uint openPrice,
        uint leverage,
        bool buy) public view returns (uint256) {

        uint tpDiff = (openPrice * MAX_GAIN_P) / leverage / 100;

        return buy ? openPrice + tpDiff : tpDiff <= openPrice ? openPrice - tpDiff : 0;
    }

    function updateSl(
        uint pairIndex,
        uint index,
        uint newSl,
        bytes[] calldata updateData
    ) external notContract notDone {
        address sender = msg.sender;
        StorageInterface.Trade memory t = storageT.openTrades(
            sender,
            pairIndex,
            index
        );

        StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
            sender,
            pairIndex,
            index
        );

        require(t.leverage > 0, "NO_TRADE");

        uint maxSlDist = (t.openPrice * MAX_SL_P) / 100 / t.leverage;
        require(
            newSl == 0 ||
                (
                    t.buy
                        ? newSl >= t.openPrice - maxSlDist
                        : newSl <= t.openPrice + maxSlDist
                ),
            "SL_TOO_BIG"
        );

        require(
            block.number - i.slLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK"
        );

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if (
            newSl == 0 ||
            !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)
        ) {
            storageT.updateSl(sender, pairIndex, index, newSl);

            emit SlUpdated(sender, pairIndex, index, newSl);
        } else {
            tempSL = newSl;
            (uint orderId, ) = aggregator.getPrice(
                AggregatorInterfaceV6_2.OrderType.UPDATE_SL,
                updateData,
                t
            );
            delete tempSL;

            emit SlUpdateInitiated(orderId, sender, pairIndex, index, newSl);
        }
    }

    // Avoid stack too deep error in executeLimitOrder
    function getTradeLiquidationPrice(
        StorageInterface.Trade memory t
    ) private view returns (uint) {
        return
            pairInfos.getTradeLiquidationPrice(
                t.trader,
                t.pairIndex,
                t.index,
                t.openPrice,
                t.buy,
                (t.initialPosToken *
                    storageT
                        .openTradesInfo(t.trader, t.pairIndex, t.index)
                        .tokenPriceUSDT) / PRECISION,
                t.leverage
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract NarwhalTradingCallbacks is Initializable, PausableUpgradeable {

    StorageInterface public storageT;
    LimitOrdersInterface public limitOrders;
    PairInfoInterface public pairInfos;
    NarwhalReferralInterface public referrals;

    address public Treasury;
    address public MarketingFund;

    // Params
    uint public PRECISION; // 10 decimals
    uint public MAX_SL_P; // -90% PNL
    uint public MAX_GAIN_P; // 900% PnL (10x)

    // Params (adjustable)
    uint public USDTVaultFeeP; // % of closing fee going to USDT vault (eg. 40)
    uint public lpFeeP; // % of closing fee going to NWX/USDT LPs (eg. 20)
    uint public projectFeeP; // % of closing fee going to treasury (eg. 40)
    uint public marketingFeeP; // % of closing fee going to marketing fund


    // Custom data types
    struct AggregatorAnswer {
        uint orderId;
        uint price;
        uint spreadP;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint posUSDT;
        uint levPosUSDT;
        uint tokenPriceUSDT;
        int profitP;
        uint price;
        uint liqPrice;
        uint USDTSentToTrader;
        uint reward1;
        uint reward2;
        uint reward3;
        uint reward4;
        uint reward5;
        uint leftoverFees;
        uint totalFees;
    }

    function initialize (
        StorageInterface _storageT,
        LimitOrdersInterface _limitOrders,
        PairInfoInterface _pairInfos,
        NarwhalReferralInterface _referrals,
        uint _USDTVaultFeeP,
        uint _lpFeeP,
        uint _projectFeeP,
        uint256 _marketingFeeP
    ) public initializer {
        storageT = _storageT;
        limitOrders = _limitOrders;
        pairInfos = _pairInfos;
        referrals = _referrals;

        require(_USDTVaultFeeP + _lpFeeP + _projectFeeP + _marketingFeeP == 100, "SUM_NOT_100");
        require(address(_storageT) != address(0) &&
            address(_limitOrders) != address(0) &&
            address(_pairInfos) != address(0) &&
            address(_referrals) != address(0), "ZERO_ADDRESS");

        USDTVaultFeeP = _USDTVaultFeeP;
        lpFeeP = _lpFeeP;
        projectFeeP = _projectFeeP;
        marketingFeeP = _marketingFeeP;

        PRECISION = 1e10; // 10 decimals
        MAX_SL_P = 90; // -90% PNL
        MAX_GAIN_P = 900; // 900% PnL (10x)
        
        Treasury = msg.sender;
        MarketingFund = msg.sender;
        __Pausable_init();
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setCoreSettings(
        StorageInterface _storageT,
        LimitOrdersInterface _limitOrders,
        PairInfoInterface _pairInfos,
        NarwhalReferralInterface _referrals,
        uint _USDTVaultFeeP,
        uint _lpFeeP,
        uint _projectFeeP,
        uint256 _marketingFeeP) public onlyGov {
        storageT = _storageT;
        limitOrders = _limitOrders;
        pairInfos = _pairInfos;
        referrals = _referrals;

        require(_USDTVaultFeeP + _lpFeeP + _projectFeeP + _marketingFeeP == 100, "SUM_NOT_100");
        require(address(_storageT) != address(0) &&
            address(_limitOrders) != address(0) &&
            address(_pairInfos) != address(0) &&
            address(_referrals) != address(0), "ZERO_ADDRESS");

        USDTVaultFeeP = _USDTVaultFeeP;
        lpFeeP = _lpFeeP;
        projectFeeP = _projectFeeP;
        marketingFeeP = _marketingFeeP;
    }

    function giveAllowance() public onlyGov {
        storageT.USDT().approve(address(storageT.vault()), type(uint256).max);
        storageT.USDT().approve(address(storageT.pool()), type(uint256).max);
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyPriceAggregator() {
        require(
            msg.sender == address(storageT.priceAggregator()),
            "AGGREGATOR_ONLY"
        );
        _;
    }

    function openTradeMarketCallback(
        AggregatorAnswer memory a
    ) external whenNotPaused onlyPriceAggregator {
        StorageInterface.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        StorageInterface.Trade memory t = o.trade;

        (uint priceImpactP, uint priceAfterImpact) = pairInfos
            .getTradePriceImpact(
                marketExecutionPrice(
                    a.price,
                    a.spreadP,
                    o.spreadReductionP,
                    t.buy
                ),
                t.pairIndex,
                t.buy,
                t.positionSizeUSDT * t.leverage
            );

        t.openPrice = priceAfterImpact;
        uint maxSlippage = (o.wantedPrice * o.slippageP) / 100 / PRECISION;

        if (a.price == 0 ||
            (
                t.buy
                    ? t.openPrice > o.wantedPrice + maxSlippage
                    : t.openPrice < o.wantedPrice - maxSlippage
            ) ||
            (t.tp > 0 && (t.buy ? t.openPrice >= t.tp : t.openPrice <= t.tp)) ||
            (t.sl > 0 && (t.buy ? t.openPrice <= t.sl : t.openPrice >= t.sl)) ||
            !withinExposureLimits(
                t.pairIndex,
                t.buy,
                t.positionSizeUSDT,
                t.leverage
            ) ||
            priceImpactP * t.leverage > pairInfos.maxNegativePnlOnOpenP()
        ) {
            storageT.transferUSDT(
                address(storageT),
                t.trader,
                t.positionSizeUSDT
            );

        } else {
            registerTrade(t, a.orderId, false);
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator {
        StorageInterface.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        StorageInterface.Trade memory t = storageT.openTrades(
            o.trade.trader,
            o.trade.pairIndex,
            o.trade.index
        );

        if (t.leverage > 0) {
            StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
                t.trader,
                t.pairIndex,
                t.index
            );

            AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
            PairsStorageInterface pairsStorage = aggregator.pairsStorage();

            Values memory v;

            v.levPosUSDT =
                (t.initialPosToken * i.tokenPriceUSDT * t.leverage) / PRECISION / 1e8;
            if (a.price == 0) {
                t.initialPosToken -= (v.reward1 * PRECISION) / i.tokenPriceUSDT;
                storageT.updateTrade(t);

            } else {
                v.profitP = currentPercentProfit(
                    t.openPrice,
                    a.price,
                    t.buy,
                    t.leverage
                );
                v.posUSDT = v.levPosUSDT / t.leverage;
                v.USDTSentToTrader = unregisterTrade(
                    t,
                    v.profitP,
                    v.posUSDT,
                    i.openInterestUSDT / t.leverage,
                    (v.levPosUSDT * pairsStorage.pairCloseFeeP(t.pairIndex)) /
                        100000,
                    0
                );
            }
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }

    function executeOpenOrderCallback(
        AggregatorAnswer memory a
    ) external whenNotPaused onlyPriceAggregator {
        StorageInterface.PendingLimitOrder memory n = storageT
            .reqID_pendingLimitOrder(a.orderId);
        require(n.trader != address(0), "INVALID_ORDER");

        if (a.price > 0 &&
            storageT.hasOpenLimitOrder(n.trader, n.pairIndex, n.index)
        ) {

            StorageInterface.OpenLimitOrder memory o = storageT
                .getOpenLimitOrder(n.trader, n.pairIndex, n.index);

            LimitOrdersInterface.OpenLimitOrderType t = limitOrders
                .openLimitOrderTypes(n.trader, n.pairIndex, n.index);

            (uint priceImpactP, uint priceAfterImpact) = pairInfos
                .getTradePriceImpact(
                    marketExecutionPrice(
                        a.price,
                        a.spreadP,
                        o.spreadReductionP,
                        o.buy
                    ),
                    o.pairIndex,
                    o.buy,
                    o.positionSize * o.leverage
                );

            a.price = priceAfterImpact;
            if (
                (
                    t == LimitOrdersInterface.OpenLimitOrderType.LEGACY
                        ? (a.price >= o.minPrice && a.price <= o.maxPrice)
                        : t == LimitOrdersInterface.OpenLimitOrderType.REVERSAL
                        ? (
                            o.buy
                                ? a.price <= o.maxPrice
                                : a.price >= o.minPrice
                        )
                        : (
                            o.buy
                                ? a.price >= o.minPrice
                                : a.price <= o.maxPrice
                        )
                ) &&
                withinExposureLimits(
                    o.pairIndex,
                    o.buy,
                    o.positionSize,
                    o.leverage
                ) &&
                priceImpactP * o.leverage <= pairInfos.maxNegativePnlOnOpenP()
            ) {
 
                registerTrade(
                        StorageInterface.Trade(
                            o.trader,
                            o.pairIndex,
                            0,
                            0,
                            o.positionSize,
                            t ==
                                LimitOrdersInterface.OpenLimitOrderType.REVERSAL
                                ? o.maxPrice
                                : a.price,
                            o.buy,
                            o.leverage,
                            o.tp,
                            o.sl
                        ),
                        a.orderId,
                        true
                    );

                storageT.unregisterOpenLimitOrder(
                    o.trader,
                    o.pairIndex,
                    o.index
                );
            }
        }

        limitOrders.unregisterTrigger(
            LimitOrdersInterface.TriggeredLimitId(
                n.trader,
                n.pairIndex,
                n.index,
                n.orderType
            )
        );

        storageT.unregisterPendingLimitOrder(a.orderId);
    }

    function executeCloseOrderCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator {
        StorageInterface.PendingLimitOrder memory o = storageT
            .reqID_pendingLimitOrder(a.orderId);
        StorageInterface.Trade memory t = storageT.openTrades(
            o.trader,
            o.pairIndex,
            o.index
        );

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if (a.price > 0 && t.leverage > 0) {
            StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
                t.trader,
                t.pairIndex,
                t.index
            );

            PairsStorageInterface pairsStored = aggregator.pairsStorage();

            Values memory v;

            v.price = pairsStored.guaranteedSlEnabled(t.pairIndex)
                ? o.orderType == StorageInterface.LimitOrder.TP
                    ? t.tp
                    : o.orderType == StorageInterface.LimitOrder.SL
                    ? t.sl
                    : a.price
                : a.price;

            v.profitP = currentPercentProfit(
                t.openPrice,
                v.price,
                t.buy,
                t.leverage
            );
            v.levPosUSDT =
                (t.initialPosToken * i.tokenPriceUSDT * t.leverage) /
                PRECISION /
                1e8;
            
            v.posUSDT = v.levPosUSDT / t.leverage;

            if (o.orderType == StorageInterface.LimitOrder.LIQ) {
                v.liqPrice = pairInfos.getTradeLiquidationPrice(
                    t.trader,
                    t.pairIndex,
                    t.index,
                    t.openPrice,
                    t.buy,
                    v.posUSDT,
                    t.leverage
                );
                v.reward1 = (
                    t.buy ? a.price <= v.liqPrice : a.price >= v.liqPrice
                )
                    ? (v.posUSDT * 5) / 100
                    : 0;
            } else {
                v.reward1 = ((o.orderType == StorageInterface.LimitOrder.TP &&
                    t.tp > 0 &&
                    (t.buy ? a.price >= t.tp : a.price <= t.tp)) ||
                    (o.orderType == StorageInterface.LimitOrder.SL &&
                        t.sl > 0 &&
                        (t.buy ? a.price <= t.sl : a.price >= t.sl)))
                    ? ((v.levPosUSDT * pairsStored.pairCloseFeeP(t.pairIndex)) /
                        100000) * 5 / 100 : 0;
                
            }

            if (v.reward1 > 0) {
                storageT.transferUSDT(
                    address(storageT),
                    storageT.keeperForOrder(a.orderId),
                    v.reward1
                );
                
                unregisterTrade(
                    t,
                    v.profitP,
                    v.posUSDT - v.reward1,
                    i.openInterestUSDT / t.leverage,
                    (v.levPosUSDT * pairsStored.pairCloseFeeP(t.pairIndex)) /
                        100000 - v.reward1,
                    v.reward1
                );

            }
        }

        limitOrders.unregisterTrigger(
            LimitOrdersInterface.TriggeredLimitId(
                o.trader,
                o.pairIndex,
                o.index,
                o.orderType
            )
        );

        storageT.unregisterPendingLimitOrder(a.orderId);
    }

    function updateSlCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        AggregatorInterfaceV6_2.PendingSl memory o = aggregator.pendingSlOrders(
            a.orderId
        );

        StorageInterface.Trade memory t = storageT.openTrades(
            o.trader,
            o.pairIndex,
            o.index
        );
        if (t.leverage > 0) {
            StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
                o.trader,
                o.pairIndex,
                o.index
            );

            Values memory v;

            v.tokenPriceUSDT = aggregator.tokenPriceUSDT();
            v.levPosUSDT =
                (t.initialPosToken * i.tokenPriceUSDT * t.leverage) /
                PRECISION /
                1e8 /
                2;

            t.initialPosToken -= (v.reward1 * PRECISION) / i.tokenPriceUSDT;
            storageT.updateTrade(t);

            if (
                a.price > 0 &&
                t.buy == o.buy &&
                t.openPrice == o.openPrice &&
                (t.buy ? o.newSl <= a.price : o.newSl >= a.price)
            ) {
                storageT.updateSl(o.trader, o.pairIndex, o.index, o.newSl);
            }
        }

        aggregator.unregisterPendingSlOrder(a.orderId);
    }

    function registerTrade(
        StorageInterface.Trade memory trade,
        uint256 _orderId,
        bool _limit
    ) private returns (StorageInterface.Trade memory, uint) {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        PairsStorageInterface pairsStored = aggregator.pairsStorage();
        Values memory v;

        v.levPosUSDT = trade.positionSizeUSDT * trade.leverage;
        v.tokenPriceUSDT = aggregator.tokenPriceUSDT();
        v.totalFees =
            (v.levPosUSDT *
                (pairsStored.pairOpenFeeP(trade.pairIndex))) /
            100000;
        trade.positionSizeUSDT -= v.totalFees;
        address ref = referrals.getReferral(trade.trader);
        if (ref != address(0)) {
            (uint256 discount, uint256 rebate) = referrals
                .getReferralDiscountAndRebate(trade.trader);
            v.reward2 = (v.totalFees * discount) / 1000;

            storageT.transferUSDT(address(storageT), trade.trader, v.reward2);

            if (referrals.isTier3KOL(ref)) {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementTier2Tier3(
                    ref,
                    v.reward1,
                    (v.totalFees * referrals.tier3tier2RebateBonus()) / 1000,
                    v.levPosUSDT
                );
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000)
                );
                v.leftoverFees =
                    v.totalFees -
                    (v.reward1 +
                        v.reward2 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000));
            } else {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementRewards(ref, v.reward1,v.levPosUSDT);
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1
                );
                v.leftoverFees = v.totalFees - (v.reward1 + v.reward2);
            }
        } else {
            v.leftoverFees = v.totalFees;
        }

        if (_limit) {
            v.reward3 =
                (v.leftoverFees *
                    pairsStored.pairLimitOrderFeeP(trade.pairIndex)) /
                1000;
            storageT.transferUSDT(
                address(storageT),
                storageT.keeperForOrder(_orderId),
                v.reward3
            );
            storageT.transferUSDT(
                address(storageT),
                Treasury,
                (v.leftoverFees * projectFeeP) / 100
            );
        } else {
            storageT.transferUSDT(
                address(storageT),
                Treasury,
                (v.leftoverFees * projectFeeP) / 100
            );
            storageT.transferUSDT(
                address(storageT),
                MarketingFund,
                (v.leftoverFees * marketingFeeP) / 100
            );
        }

        v.reward4 = (v.leftoverFees * USDTVaultFeeP) / 100;
        storageT.transferUSDT(address(storageT), address(this), v.reward4);
        storageT.vault().distributeRewardUSDT(v.reward4, true);

        v.reward5 = (v.leftoverFees * lpFeeP) / 100;
        storageT.distributeLpRewards(v.reward5);

        trade.index = storageT.firstEmptyTradeIndex(
            trade.trader,
            trade.pairIndex
        );
        trade.initialPosToken = trade.positionSizeUSDT * 1e18 / v.tokenPriceUSDT;

        trade.tp = correctTp(
            trade.openPrice,
            trade.leverage,
            trade.tp,
            trade.buy
        );
        trade.sl = correctSl(
            trade.openPrice,
            trade.leverage,
            trade.sl,
            trade.buy
        );

        pairInfos.storeTradeInitialAccFees(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy
        );
        pairsStored.updateGroupCollateral(
            trade.pairIndex,
            trade.positionSizeUSDT,
            trade.buy,
            true
        );

        storageT.storeTrade(
            trade,
            StorageInterface.TradeInfo(
                0,
                v.tokenPriceUSDT,
                trade.positionSizeUSDT * trade.leverage,
                0,
                0,
                false
            )
        );

        return (trade, v.tokenPriceUSDT);
    }

    function unregisterTrade(
        StorageInterface.Trade memory trade,
        int percentProfit, // PRECISION
        uint currentUSDTPos, // usdtDecimals
        uint initialUSDTPos, // usdtDecimals
        uint closingFeeUSDT, // usdtDecimals
        uint limitFeeUSDT
    ) internal returns (uint USDTSentToTrader) {
        USDTSentToTrader = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentUSDTPos,
            trade.leverage,
            percentProfit,
            closingFeeUSDT + limitFeeUSDT
        );
        Values memory v;
        v.totalFees = closingFeeUSDT;
        if (referrals.getReferral(trade.trader) != address(0)) {

            (uint256 discount, uint256 rebate) = referrals
                .getReferralDiscountAndRebate(trade.trader);
            v.reward2 = (v.totalFees * discount) / 1000;
            storageT.transferUSDT(address(storageT), trade.trader, v.reward2);

            if (referrals.isTier3KOL(referrals.getReferral(trade.trader))) {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementTier2Tier3(
                    referrals.getReferral(trade.trader),
                    v.reward1,
                    (v.totalFees * referrals.tier3tier2RebateBonus()) / 1000,
                    trade.positionSizeUSDT * trade.leverage
                );
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000)
                );
                v.leftoverFees =
                    v.totalFees -
                    (v.reward1 +
                        v.reward2 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000));
            } else {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementRewards(referrals.getReferral(trade.trader), v.reward1,trade.positionSizeUSDT * trade.leverage);
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1
                );
                v.leftoverFees = v.totalFees - (v.reward1 + v.reward2);
            }
        } else {
            v.leftoverFees = v.totalFees;
        }

        if (trade.positionSizeUSDT > 0) {
            storageT.transferUSDT(
                address(storageT),
                Treasury,
                (v.leftoverFees * projectFeeP) / 100
            );
            storageT.transferUSDT(
                address(storageT),
                MarketingFund,
                (v.leftoverFees * marketingFeeP) / 100
            );

            v.reward4 = (v.leftoverFees * USDTVaultFeeP) / 100;
            storageT.transferUSDT(address(storageT), address(this), v.reward4);
            storageT.vault().distributeRewardUSDT(v.reward4, true);

            v.reward5 = (v.leftoverFees * lpFeeP) / 100;
            storageT.distributeLpRewards(v.reward5);

            uint USDTLeftInStorage = currentUSDTPos - v.totalFees;
            if (USDTSentToTrader > USDTLeftInStorage) {
                storageT.vault().sendUSDTToTrader(
                    trade.trader,
                    USDTSentToTrader - USDTLeftInStorage
                );
                storageT.transferUSDT(
                    address(storageT),
                    trade.trader,
                    USDTLeftInStorage
                );
            } else {
                storageT.vault().receiveUSDTFromTrader(
                    trade.trader,
                    USDTLeftInStorage - USDTSentToTrader,
                    0,
                    false
                );
                storageT.transferUSDT(
                    address(storageT),
                    trade.trader,
                    USDTSentToTrader
                );
            }

        } else {
            storageT.vault().sendUSDTToTrader(trade.trader, USDTSentToTrader);
        }

        storageT.priceAggregator().pairsStorage().updateGroupCollateral(
            trade.pairIndex,
            initialUSDTPos,
            trade.buy,
            false
        );

        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);
    }

    function withinExposureLimits(
        uint pairIndex,
        bool buy,
        uint positionSizeUSDT,
        uint leverage
    ) internal view returns (bool) {
        PairsStorageInterface pairsStored = storageT
            .priceAggregator()
            .pairsStorage();

        uint256 posLev = positionSizeUSDT * leverage;
        uint256 OILimit = storageT.openInterestUSDT(pairIndex, buy ? 0 : 1) + posLev;
        uint256 netOI = storageT.getNetOI(pairIndex, buy);

        return
            OILimit <= storageT.openInterestUSDT(pairIndex, 2) && 
            netOI + posLev <= storageT.openInterestUSDT(pairIndex, buy ? 3 : 4) &&
            pairsStored.groupCollateral(pairIndex, buy) + positionSizeUSDT <=
            pairsStored.groupMaxCollateral(pairIndex);
    }

    function currentPercentProfit(
        uint openPrice,
        uint currentPrice,
        bool buy,
        uint leverage
    ) internal view returns (int p) {
        int maxPnlP = int(MAX_GAIN_P) * int(PRECISION);

        p =
            ((
                buy
                    ? int(currentPrice) - int(openPrice)
                    : int(openPrice) - int(currentPrice)
            ) *
                100 *
                int(PRECISION) *
                int(leverage)) /
            int(openPrice);

        p = p > maxPnlP ? maxPnlP : p;
    }

    function correctTp(
        uint openPrice,
        uint leverage,
        uint tp,
        bool buy
    ) internal view returns (uint) {
        if (
            tp == 0 ||
            currentPercentProfit(openPrice, tp, buy, leverage) ==
            int(MAX_GAIN_P) * int(PRECISION)
        ) {
            uint tpDiff = (openPrice * MAX_GAIN_P) / leverage / 100;

            return
                buy ? openPrice + tpDiff : tpDiff <= openPrice
                    ? openPrice - tpDiff
                    : 0;
        }

        return tp;
    }

    function correctSl(
        uint openPrice,
        uint leverage,
        uint sl,
        bool buy
    ) internal view returns (uint) {
        if (
            sl > 0 &&
            currentPercentProfit(openPrice, sl, buy, leverage) <
            int(MAX_SL_P) * int(PRECISION) * -1
        ) {
            uint slDiff = (openPrice * MAX_SL_P) / leverage / 100;

            return buy ? openPrice - slDiff : openPrice + slDiff;
        }

        return sl;
    }

    function marketExecutionPrice(
        uint price,
        uint spreadP,
        uint spreadReductionP,
        bool long
    ) internal view returns (uint) {
        uint priceDiff = (price *
            (spreadP - (spreadP * spreadReductionP) / 100)) /
            100 /
            PRECISION;

        return long ? price + priceDiff : price - priceDiff;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {FixedPoint} from "../utils/math/FixedPoint.sol";
import {IUniswapPairOracle} from "../interfaces/IUniswapPairOracle.sol";
import {UniswapV2Library} from "../Uniswap/UniswapV2Library.sol";
import {IUniswapV2Pair} from "../Uniswap/Interfaces/IUniswapV2Pair.sol";
import {UniswapV2OracleLibrary} from "../Uniswap/UniswapV2OracleLibrary.sol";
import {IUniswapV2Factory} from "../Uniswap/Interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @dev Fixed window oracle that recomputes the average price for the entire period once every period
///  Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract OracleBase is IUniswapPairOracle, Ownable {
    using FixedPoint for *;

    IUniswapV2Pair public immutable pair;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    uint32 public blockTimestampLast;
    uint256 public PERIOD = 0; // 1 hour TWAP (time-weighted average price)
    uint256 public CONSULT_LENIENCY = 120; // Used for being able to consult past the period end
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    mapping(address => bool) public updateAllowed;

    address public immutable token0;
    address public immutable token1;

    constructor(address factory, address tokenA, address tokenB) {
        IUniswapV2Pair _pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(factory, tokenA, tokenB)
        );
        pair = _pair;
        token0 = _pair.token0();
        token1 = _pair.token1();
        price0CumulativeLast = _pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0)
        price1CumulativeLast = _pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1)
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = _pair.getReserves();
        require(
            reserve0 != 0 && reserve1 != 0,
            "UniswapPairOracle: NO_RESERVES"
        ); // Ensure that there's liquidity in the pair
        setUpdateAllowed(msg.sender, true);
    }

    /**
     * External.
     */

    function setUpdateAllowed(address _allowed, bool _choice) public onlyOwner {
        updateAllowed[_allowed] = _choice;
    }

    function isUpdateAllowed(address _sender) public view returns (bool) {
        bool check = updateAllowed[_sender];
        return check;
    }

    function setPeriod(uint256 _period) external onlyOwner {
        PERIOD = _period;
    }

    function setConsultLeniency(uint256 _consult_leniency) external onlyOwner {
        CONSULT_LENIENCY = _consult_leniency;
    }

    function update() external override {
        require(
            isUpdateAllowed(msg.sender),
            "Not allowed to update the Oracle"
        );
        (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired

        // Overflow is desired, casting never truncates
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        price0Average = FixedPoint.uq112x112(
            uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)
        );
        price1Average = FixedPoint.uq112x112(
            uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)
        );

        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
    }

    // Note this will always return 0 before update has been called successfully for the first time.
    function consult(
        address token,
        uint256 amountIn
    ) external view override returns (uint256 amountOut) {

        if (token == token0) {
            amountOut = price0Average.mul(amountIn).decode144();
        } else {
            require(token == token1, "UniswapPairOracle: INVALID_TOKEN");
            amountOut = price1Average.mul(amountIn).decode144();
        }
    }

    /**
     * Public.
     */

    // Check if update() can be called instead of wasting gas calling it
    function canUpdate() public view override returns (bool) {
        uint32 blockTimestamp = UniswapV2OracleLibrary.currentBlockTimestamp();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired
        return (timeElapsed >= PERIOD);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./OracleBase.sol";

// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract UniswapPairOracle is OracleBase {
    constructor(
        address factory,
        address tokenA,
        address tokenB
    ) OracleBase(factory, tokenA, tokenB) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract PairInfos {
    // Addresses
    StorageInterface immutable storageT;
    address public manager;

    // Constant parameters
    uint constant PRECISION = 1e10; // 10 decimals
    uint constant LIQ_THRESHOLD_P = 90; // -90% (of collateral)
    uint256 public usdtDecimals;

    // Adjustable parameters
    uint public maxNegativePnlOnOpenP = 40 * PRECISION; // PRECISION (%)

    // Pair parameters
    struct PairParams {
        uint onePercentDepthAbove; // USDT
        uint onePercentDepthBelow; // USDT
        uint rolloverFeePerBlockP; // PRECISION (%)
        uint fundingFeePerBlockP; // PRECISION (%)
    }

    mapping(uint => PairParams) public pairParams;

    // Pair acc funding fees
    struct PairFundingFees {
        int accPerOiLong; // usdtDecimals (USDT)
        int accPerOiShort; // usdtDecimals (USDT)
        uint lastUpdateBlock;
    }

    mapping(uint => PairFundingFees) public pairFundingFees;

    // Pair acc rollover fees
    struct PairRolloverFees {
        uint accPerCollateral; // usdtDecimals (USDT)
        uint lastUpdateBlock;
    }

    mapping(uint => PairRolloverFees) public pairRolloverFees;

    // Trade initial acc fees
    struct TradeInitialAccFees {
        uint rollover; // usdtDecimals (USDT)
        int funding; // usdtDecimals (USDT)
        bool openedAfterUpdate;
    }

    mapping(address => mapping(uint => mapping(uint => TradeInitialAccFees)))
        public tradeInitialAccFees;
    
    mapping(address => bool) public allowedToInteract;

    // Events
    event ManagerUpdated(address value);
    event MaxNegativePnlOnOpenPUpdated(uint value);

    event PairParamsUpdated(uint pairIndex, PairParams value);
    event OnePercentDepthUpdated(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    );
    event RolloverFeePerBlockPUpdated(uint pairIndex, uint value);
    event FundingFeePerBlockPUpdated(uint pairIndex, uint value);

    event TradeInitialAccFeesStored(
        address trader,
        uint pairIndex,
        uint index,
        uint rollover,
        int funding
    );

    event AccFundingFeesStored(uint pairIndex, int valueLong, int valueShort);
    event AccRolloverFeesStored(uint pairIndex, uint value);

    event FeesCharged(
        uint pairIndex,
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint rolloverFees, // usdtDecimals (USDT)
        int fundingFees // usdtDecimals (USDT)
    );

    constructor(
        StorageInterface _storageT,
        uint256 _usdtDecimals) {
        storageT = _storageT;
        usdtDecimals = _usdtDecimals;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyManager() {
        require(msg.sender == manager, "MANAGER_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    function setAllowedToInteract(address _sender, bool _status) public onlyGov {
        allowedToInteract[_sender] = _status;
    }


    // Set manager address
    function setManager(address _manager) external onlyGov {
        require(_manager != address(0), "ZERO_ADDRESS");
        manager = _manager;
        emit ManagerUpdated(_manager);
    }

    // Set max negative PnL % on trade opening
    function setMaxNegativePnlOnOpenP(uint value) external onlyManager {
        require(value != 0, "ZERO_VALUE");
        maxNegativePnlOnOpenP = value;
        emit MaxNegativePnlOnOpenPUpdated(value);
    }

    // Set parameters for pair
    function setPairParams(
        uint pairIndex,
        PairParams memory value
    ) public onlyManager {
        storeAccRolloverFees(pairIndex);
        storeAccFundingFees(pairIndex);

        pairParams[pairIndex] = value;

        emit PairParamsUpdated(pairIndex, value);
    }

    function setPairParamsArray(
        uint[] memory indices,
        PairParams[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint i = 0; i < indices.length; i++) {
            setPairParams(indices[i], values[i]);
        }
    }

    // Set one percent depth for pair
    function setOnePercentDepth(
        uint pairIndex,
        uint valueAbove,
        uint valueBelow
    ) public onlyManager {
        PairParams storage p = pairParams[pairIndex];

        p.onePercentDepthAbove = valueAbove;
        p.onePercentDepthBelow = valueBelow;

        emit OnePercentDepthUpdated(pairIndex, valueAbove, valueBelow);
    }

    function setOnePercentDepthArray(
        uint[] memory indices,
        uint[] memory valuesAbove,
        uint[] memory valuesBelow
    ) external onlyManager {
        require(
            indices.length == valuesAbove.length &&
                indices.length == valuesBelow.length,
            "WRONG_LENGTH"
        );

        for (uint i = 0; i < indices.length; i++) {
            setOnePercentDepth(indices[i], valuesAbove[i], valuesBelow[i]);
        }
    }

    // Set rollover fee for pair
    function setRolloverFeePerBlockP(
        uint pairIndex,
        uint value
    ) public onlyManager {
        require(value <= 25000000, "TOO_HIGH"); // ≈ 100% per day

        storeAccRolloverFees(pairIndex);

        pairParams[pairIndex].rolloverFeePerBlockP = value;

        emit RolloverFeePerBlockPUpdated(pairIndex, value);
    }

    function setRolloverFeePerBlockPArray(
        uint[] memory indices,
        uint[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint i = 0; i < indices.length; i++) {
            setRolloverFeePerBlockP(indices[i], values[i]);
        }
    }

    // Set funding fee for pair
    function setFundingFeePerBlockP(
        uint pairIndex,
        uint value
    ) public onlyManager {
        require(value <= 10000000, "TOO_HIGH"); // ≈ 40% per day

        storeAccFundingFees(pairIndex);

        pairParams[pairIndex].fundingFeePerBlockP = value;

        emit FundingFeePerBlockPUpdated(pairIndex, value);
    }

    function setFundingFeePerBlockPArray(
        uint[] memory indices,
        uint[] memory values
    ) external onlyManager {
        require(indices.length == values.length, "WRONG_LENGTH");

        for (uint i = 0; i < indices.length; i++) {
            setFundingFeePerBlockP(indices[i], values[i]);
        }
    }

    // Store trade details when opened (acc fee values)
    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external onlyCallbacks {
        storeAccFundingFees(pairIndex);

        TradeInitialAccFees storage t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        t.rollover = getPendingAccRolloverFees(pairIndex);

        t.funding = long
            ? pairFundingFees[pairIndex].accPerOiLong
            : pairFundingFees[pairIndex].accPerOiShort;

        t.openedAfterUpdate = true;

        emit TradeInitialAccFeesStored(
            trader,
            pairIndex,
            index,
            t.rollover,
            t.funding
        );
    }

    // Acc rollover fees (store right before fee % update)
    function storeAccRolloverFees(uint pairIndex) private {
        PairRolloverFees storage r = pairRolloverFees[pairIndex];

        r.accPerCollateral = getPendingAccRolloverFees(pairIndex);
        r.lastUpdateBlock = block.number;

        emit AccRolloverFeesStored(pairIndex, r.accPerCollateral);
    }

    function getPendingAccRolloverFees(
        uint pairIndex
    ) public view returns (uint) {
        // usdtDecimals (USDT)
        PairRolloverFees storage r = pairRolloverFees[pairIndex];
        uint _usdtDecimals = usdtDecimals;
        return
            r.accPerCollateral +
            ((block.number - r.lastUpdateBlock) *
                pairParams[pairIndex].rolloverFeePerBlockP *
                _usdtDecimals) /
            PRECISION /
            100;
    }

    // Acc funding fees (store right before trades opened / closed and fee % update)
    function storeAccFundingFees(uint pairIndex) private {
        PairFundingFees storage f = pairFundingFees[pairIndex];

        (f.accPerOiLong, f.accPerOiShort) = getPendingAccFundingFees(pairIndex);
        f.lastUpdateBlock = block.number;

        emit AccFundingFeesStored(pairIndex, f.accPerOiLong, f.accPerOiShort);
    }

    function getPendingAccFundingFees(
        uint pairIndex
    ) public view returns (int valueLong, int valueShort) {
        PairFundingFees storage f = pairFundingFees[pairIndex];
        int256 _usdtDecimals = int256(usdtDecimals);

        valueLong = f.accPerOiLong;
        valueShort = f.accPerOiShort;

        int openInterestUSDTLong = int(storageT.openInterestUSDT(pairIndex, 0));
        int openInterestUSDTShort = int(
            storageT.openInterestUSDT(pairIndex, 1)
        );

        int fundingFeesPaidByLongs = ((openInterestUSDTLong -
            openInterestUSDTShort) *
            int(block.number - f.lastUpdateBlock) *
            int(pairParams[pairIndex].fundingFeePerBlockP)) /
            int(PRECISION) /
            100;

        if (openInterestUSDTLong > 0) {
            valueLong += (fundingFeesPaidByLongs * _usdtDecimals) / openInterestUSDTLong;
        }

        if (openInterestUSDTShort > 0) {
            valueShort +=
                (fundingFeesPaidByLongs * _usdtDecimals * (-1)) /
                openInterestUSDTShort;
        }
    }

    // Dynamic price impact value on trade opening
    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint tradeOpenInterest // usdtDecimals (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        )
    {
        (priceImpactP, priceAfterImpact) = getTradePriceImpactPure(
            openPrice,
            long,
            storageT.openInterestUSDT(pairIndex, long ? 0 : 1),
            tradeOpenInterest,
            long
                ? pairParams[pairIndex].onePercentDepthAbove
                : pairParams[pairIndex].onePercentDepthBelow
        );
    }

    function getTradePriceImpactPure(
        uint openPrice, // PRECISION
        bool long,
        uint startOpenInterest, // usdtDecimals (USDT)
        uint tradeOpenInterest, // usdtDecimals (USDT)
        uint onePercentDepth
    )
        public
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        )
    {
        if (onePercentDepth == 0) {
            return (0, openPrice);
        }

        priceImpactP =
            ((startOpenInterest + tradeOpenInterest / 2) * PRECISION) /
            usdtDecimals /
            onePercentDepth;

        uint priceImpact = (priceImpactP * openPrice) / PRECISION / 100;

        priceAfterImpact = long
            ? openPrice + priceImpact
            : openPrice - priceImpact;
    }

    // Rollover fee value
    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // usdtDecimals (USDT)
    ) public view returns (uint) {
        // usdtDecimals (USDT)
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        return
            getTradeRolloverFeePure(
                t.rollover,
                getPendingAccRolloverFees(pairIndex),
                collateral
            );
    }

    function getTradeRolloverFeePure(
        uint accRolloverFeesPerCollateral,
        uint endAccRolloverFeesPerCollateral,
        uint collateral // usdtDecimals (USDT)
    ) public view returns (uint) {
        // usdtDecimals (USDT)
        return
            ((endAccRolloverFeesPerCollateral - accRolloverFeesPerCollateral) *
                collateral) / usdtDecimals;
    }

    // Funding fee value
    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage
    )
        public
        view
        returns (
            int // usdtDecimals (USDT) | Positive => Fee, Negative => Reward
        )
    {
        TradeInitialAccFees memory t = tradeInitialAccFees[trader][pairIndex][
            index
        ];

        if (!t.openedAfterUpdate) {
            return 0;
        }

        (int pendingLong, int pendingShort) = getPendingAccFundingFees(
            pairIndex
        );

        return
            getTradeFundingFeePure(
                t.funding,
                long ? pendingLong : pendingShort,
                collateral,
                leverage
            );
    }

    function getTradeFundingFeePure(
        int accFundingFeesPerOi,
        int endAccFundingFeesPerOi,
        uint collateral, // usdtDecimals (USDT)
        uint leverage
    )
        public
        view
        returns (
            int // usdtDecimals (USDT) | Positive => Fee, Negative => Reward
        )
    {
        return
            ((endAccFundingFeesPerOi - accFundingFeesPerOi) *
                int(collateral) *
                int(leverage)) / int(usdtDecimals);
    }

    // Liquidation price value after rollover and funding fees
    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage
    ) external view returns (uint) {
        // PRECISION
        return
            getTradeLiquidationPricePure(
                openPrice,
                long,
                collateral,
                leverage,
                getTradeRolloverFee(trader, pairIndex, index, collateral),
                getTradeFundingFee(
                    trader,
                    pairIndex,
                    index,
                    long,
                    collateral,
                    leverage
                )
            );
    }

    function getTradeLiquidationPricePure(
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage,
        uint rolloverFee, // usdtDecimals (USDT)
        int fundingFee // usdtDecimals (USDT)
    ) public pure returns (uint) {
        // PRECISION
        int liqPriceDistance = (int(openPrice) *
            (int((collateral * LIQ_THRESHOLD_P) / 100) -
                int(rolloverFee) -
                fundingFee)) /
            int(collateral) /
            int(leverage);

        int liqPrice = long
            ? int(openPrice) - liqPriceDistance
            : int(openPrice) + liqPriceDistance;

        return liqPrice > 0 ? uint(liqPrice) : 0;
    }

    // USDT sent to trader after PnL and fees
    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // usdtDecimals (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // usdtDecimals (USDT)
    ) external onlyCallbacks returns (uint amount) {
        // usdtDecimals (USDT)
        storeAccFundingFees(pairIndex);

        uint r = getTradeRolloverFee(trader, pairIndex, index, collateral);
        int f = getTradeFundingFee(
            trader,
            pairIndex,
            index,
            long,
            collateral,
            leverage
        );
        amount = getTradeValuePure(collateral, percentProfit, r, f, closingFee);
        emit FeesCharged(
            pairIndex,
            long,
            collateral,
            leverage,
            percentProfit,
            r,
            f
        );
    }

    function getTradeValuePure(
        uint collateral, // usdtDecimals (USDT)
        int percentProfit, // PRECISION (%)
        uint rolloverFee, // usdtDecimals (USDT)
        int fundingFee, // usdtDecimals (USDT)
        uint closingFee // usdtDecimals (USDT)
    ) public pure returns (uint) {
        // usdtDecimals (USDT)
        int value = int(collateral) +
            (int(collateral) * percentProfit) /
            int(PRECISION) /
            100 -
            int(rolloverFee) -
            fundingFee;

        if (value <= (int(collateral) * int(100 - LIQ_THRESHOLD_P)) / 100) {
            return 0;
        }
        
        
        value -= int(closingFee);

        return value > 0 ? uint(value) : 0;
    }

    // Useful getters
    function getPairInfos(
        uint[] memory indices
    )
        external
        view
        returns (
            PairParams[] memory,
            PairRolloverFees[] memory,
            PairFundingFees[] memory
        )
    {
        PairParams[] memory params = new PairParams[](indices.length);
        PairRolloverFees[] memory rolloverFees = new PairRolloverFees[](
            indices.length
        );
        PairFundingFees[] memory fundingFees = new PairFundingFees[](
            indices.length
        );

        for (uint i = 0; i < indices.length; i++) {
            uint index = indices[i];

            params[i] = pairParams[index];
            rolloverFees[i] = pairRolloverFees[index];
            fundingFees[i] = pairFundingFees[index];
        }

        return (params, rolloverFees, fundingFees);
    }

    function getOnePercentDepthAbove(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].onePercentDepthAbove;
    }

    function getOnePercentDepthBelow(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].onePercentDepthBelow;
    }

    function getRolloverFeePerBlockP(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].rolloverFeePerBlockP;
    }

    function getFundingFeePerBlockP(
        uint pairIndex
    ) external view returns (uint) {
        return pairParams[pairIndex].fundingFeePerBlockP;
    }

    function getAccRolloverFees(uint pairIndex) external view returns (uint) {
        return pairRolloverFees[pairIndex].accPerCollateral;
    }

    function getAccRolloverFeesUpdateBlock(
        uint pairIndex
    ) external view returns (uint) {
        return pairRolloverFees[pairIndex].lastUpdateBlock;
    }

    function getAccFundingFeesLong(uint pairIndex) external view returns (int) {
        return pairFundingFees[pairIndex].accPerOiLong;
    }

    function getAccFundingFeesShort(
        uint pairIndex
    ) external view returns (int) {
        return pairFundingFees[pairIndex].accPerOiShort;
    }

    function getAccFundingFeesUpdateBlock(
        uint pairIndex
    ) external view returns (uint) {
        return pairFundingFees[pairIndex].lastUpdateBlock;
    }

    function getTradeInitialAccRolloverFeesPerCollateral(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (uint) {
        return tradeInitialAccFees[trader][pairIndex][index].rollover;
    }

    function getTradeInitialAccFundingFeesPerOi(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (int) {
        return tradeInitialAccFees[trader][pairIndex][index].funding;
    }

    function getTradeOpenedAfterUpdate(
        address trader,
        uint pairIndex,
        uint index
    ) external view returns (bool) {
        return tradeInitialAccFees[trader][pairIndex][index].openedAfterUpdate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract PairsStorage {
    // Contracts (constant)
    StorageInterface public storageT;

    // Params (constant)
    uint constant MIN_LEVERAGE = 1;
    uint constant MAX_LEVERAGE = 1000;
    // Custom data types
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }
    struct Feed {
        bytes32 feed1;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    }

    struct Pair {
        string from;
        string to;
        Feed feed;
        uint spreadP; // PRECISION
        uint groupIndex;
        uint feeIndex;
    }
    struct Group {
        string name;
        uint minLeverage;
        uint maxLeverage;
        uint maxCollateralP; // % (of USDT vault current balance)
    }
    struct Fee {
        string name;
        uint openFeeP; // PRECISION (% of leveraged pos)
        uint closeFeeP; // PRECISION (% of leveraged pos)
        uint oracleFeeP; // PRECISION (% of leveraged pos)
        uint LimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint referralFeeP; // PRECISION (% of leveraged pos)
        uint minLevPosUSDT; // usdtDecimals (collateral x leverage, useful for min fee)
    }

    // State
    uint public currentOrderId;
    uint public pairsCount;
    uint public groupsCount;
    uint public feesCount;

    mapping(uint => Pair) public pairs;
    mapping(uint => Group) public groups;
    mapping(uint => Fee) public fees;

    mapping(string => mapping(string => bool)) public isPairListed;
    mapping(address => bool) public allowedToInteract;

    mapping(uint => uint[2]) public groupsCollaterals; // (long, short)

    // Events
    event PairAdded(uint index, string from, string to);
    event PairUpdated(uint index);

    event GroupAdded(uint index, string name);
    event GroupUpdated(uint index);

    event FeeAdded(uint index, string name);
    event FeeUpdated(uint index);

    constructor(uint _currentOrderId,address _storage) {
        require(_currentOrderId > 0, "ORDER_ID_0");
        currentOrderId = _currentOrderId;
        storageT = StorageInterface(_storage);
    }

    // Modifiers
    modifier onlyGov() {
        require(
            msg.sender == storageT.gov(),
            "GOV_ONLY"
        );
        _;
    }

    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    modifier groupListed(uint _groupIndex) {
        require(groups[_groupIndex].minLeverage > 0, "GROUP_NOT_LISTED");
        _;
    }
    modifier feeListed(uint _feeIndex) {
        require(fees[_feeIndex].openFeeP > 0, "FEE_NOT_LISTED");
        _;
    }

    modifier feedOk(Feed calldata _feed) {
        require(_feed.maxDeviationP > 0);
        require(
            _feed.feedCalculation != FeedCalculation.COMBINE,
            "WRONG_FEED_CALCULATION"
        );
        _;
    }
    modifier groupOk(Group calldata _group) {
        require(
            _group.minLeverage >= MIN_LEVERAGE &&
                _group.maxLeverage <= MAX_LEVERAGE &&
                _group.minLeverage < _group.maxLeverage,
            "WRONG_LEVERAGES"
        );
        _;
    }
    modifier feeOk(Fee calldata _fee) {
        require(
            _fee.openFeeP > 0 &&
                _fee.closeFeeP > 0 &&
                _fee.oracleFeeP > 0 &&
                _fee.LimitOrderFeeP > 0 &&
                _fee.referralFeeP > 0 &&
                _fee.minLevPosUSDT > 0,
            "WRONG_FEES"
        );
        _;
    }

    function setAllowedToInteract(address _sender, bool _status) public onlyGov {
        allowedToInteract[_sender] = _status;
    }

    function changeStorageInterface(address _storage) public onlyGov {
        require(_storage != address(0), "ZERO_ADDRESS");
        storageT = StorageInterface(_storage);
    }

    // Manage pairs
    function addPair(
        Pair calldata _pair
    )
        public
        onlyGov
        feedOk(_pair.feed)
        groupListed(_pair.groupIndex)
        feeListed(_pair.feeIndex)
    {
        require(!isPairListed[_pair.from][_pair.to], "PAIR_ALREADY_LISTED");

        pairs[pairsCount] = _pair;
        isPairListed[_pair.from][_pair.to] = true;

        emit PairAdded(pairsCount++, _pair.from, _pair.to);
    }

    function addPairs(Pair[] calldata _pairs) external {
        for (uint i = 0; i < _pairs.length; i++) {
            addPair(_pairs[i]);
        }
    }

    function updatePair(
        uint _pairIndex,
        Pair calldata _pair
    ) external onlyGov feedOk(_pair.feed) feeListed(_pair.feeIndex) {
        Pair storage p = pairs[_pairIndex];
        require(isPairListed[p.from][p.to], "PAIR_NOT_LISTED");

        p.feed = _pair.feed;
        p.spreadP = _pair.spreadP;
        p.feeIndex = _pair.feeIndex;

        emit PairUpdated(_pairIndex);
    }

    // Manage groups
    function addGroup(Group calldata _group) external onlyGov groupOk(_group) {
        groups[groupsCount] = _group;
        emit GroupAdded(groupsCount++, _group.name);
    }

    function updateGroup(
        uint _id,
        Group calldata _group
    ) external onlyGov groupListed(_id) groupOk(_group) {
        groups[_id] = _group;
        emit GroupUpdated(_id);
    }

    // Manage fees
    function addFee(Fee calldata _fee) external onlyGov feeOk(_fee) {
        fees[feesCount] = _fee;
        emit FeeAdded(feesCount++, _fee.name);
    }

    function updateFee(
        uint _id,
        Fee calldata _fee
    ) external onlyGov feeListed(_id) feeOk(_fee) {
        fees[_id] = _fee;
        emit FeeUpdated(_id);
    }

    // Update collateral open exposure for a group (callbacks)
    function updateGroupCollateral(
        uint _pairIndex,
        uint _amount,
        bool _long,
        bool _increase
    ) external onlyCallbacks {

        uint[2] storage collateralOpen = groupsCollaterals[
            pairs[_pairIndex].groupIndex
        ];
        uint index = _long ? 0 : 1;

        if (_increase) {
            collateralOpen[index] += _amount;
        } else {
            collateralOpen[index] = collateralOpen[index] > _amount
                ? collateralOpen[index] - _amount
                : 0;
        }
    }

    // Fetch relevant info for order (aggregator)
    function pairJob(
        uint _pairIndex
    ) external returns (string memory, string memory, uint) {
        require(
            msg.sender == address(storageT.priceAggregator()),
            "AGGREGATOR_ONLY"
        );
        Pair memory p = pairs[_pairIndex];
        require(isPairListed[p.from][p.to], "PAIR_NOT_LISTED");
        return (p.from, p.to, currentOrderId++);
    }

    // Getters (pairs & groups)
    function pairFeed(uint _pairIndex) external view returns (Feed memory) {
        return pairs[_pairIndex].feed;
    }

    function pairSpreadP(uint _pairIndex) external view returns (uint) {
        return pairs[_pairIndex].spreadP;
    }

    function pairMinLeverage(uint _pairIndex) external view returns (uint) {
        return groups[pairs[_pairIndex].groupIndex].minLeverage;
    }

    function pairMaxLeverage(uint _pairIndex) external view returns (uint) {
        return groups[pairs[_pairIndex].groupIndex].maxLeverage;
    }

    function groupMaxCollateral(uint _pairIndex) external view returns (uint) {
        return
            (groups[pairs[_pairIndex].groupIndex].maxCollateralP *
                storageT.vault().currentBalanceUSDT()) / 100;
    }

    function groupCollateral(
        uint _pairIndex,
        bool _long
    ) external view returns (uint) {
        return groupsCollaterals[pairs[_pairIndex].groupIndex][_long ? 0 : 1];
    }

    function guaranteedSlEnabled(uint _pairIndex) external view returns (bool) {
        return pairs[_pairIndex].groupIndex == 0; // crypto only
    }

    // Getters (fees)
    function pairOpenFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].openFeeP;
    }

    function pairCloseFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].closeFeeP;
    }

    function pairOracleFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].oracleFeeP;
    }

    function pairLimitOrderFeeP(
        uint _pairIndex
    ) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].LimitOrderFeeP;
    }

    function pairReferralFeeP(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].referralFeeP;
    }

    function pairMinLevPosUSDT(uint _pairIndex) external view returns (uint) {
        return fees[pairs[_pairIndex].feeIndex].minLevPosUSDT;
    }

    // Getters (backend)
    function pairsBackend(
        uint _index
    ) external view returns (Pair memory, Group memory, Fee memory) {
        Pair memory p = pairs[_index];
        return (p, groups[p.groupIndex], fees[p.feeIndex]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IBaseToken.sol";

contract BaseToken is IERC20, IBaseToken {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    uint256 public override totalSupply;
    uint256 public nonStakingSupply;

    address public gov;
    address public pendingGov;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    mapping(address => bool) public nonStakingAccounts;
    mapping(address => bool) public admins;

    bool public inPrivateTransferMode = true;
    mapping(address => bool) public isRecipientAllowed;
    
    event AddressUpdated(string name, address a);

    modifier onlyGov() {
        require(msg.sender == gov, "BaseToken: forbidden");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "BaseToken: forbidden");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) {
        name = _name;
        symbol = _symbol;
        gov = msg.sender;
        _mint(msg.sender, _initialSupply);
    }

    // Set addresses
    function setPendingGovFund(address _gov) external onlyGov {
        require(_gov != address(0), "ADDRESS_0");
        pendingGov = _gov;
    }

    function confirmGovFund() external onlyGov {
        gov = pendingGov;
        emit AddressUpdated("govFund", gov);
    }

    function addAdmin(address _account) external onlyGov {
        admins[_account] = true;
    }

    function removeAdmin(address _account) external override onlyGov {
        admins[_account] = false;
    }

    function setInPrivateTransferMode(
        bool _inPrivateTransferMode
    ) external override onlyGov {
        inPrivateTransferMode = _inPrivateTransferMode;
    }

    function setRecipientAllowed(address _handler, bool _status) external onlyGov {
        isRecipientAllowed[_handler] = _status;
    }

    function addNonStakingAccount(address _account) external onlyAdmin {
        require(
            !nonStakingAccounts[_account],
            "BaseToken: _account already marked"
        );
        nonStakingAccounts[_account] = true;
        nonStakingSupply = nonStakingSupply.add(balances[_account]);
    }

    function removeNonStakingAccount(address _account) external onlyAdmin {
        require(nonStakingAccounts[_account], "BaseToken: _account not marked");
        nonStakingAccounts[_account] = false;
        nonStakingSupply = nonStakingSupply.sub(balances[_account]);
    }

    function totalStaked() external view override returns (uint256) {
        return totalSupply.sub(nonStakingSupply);
    }

    function balanceOf(
        address _account
    ) external view override returns (uint256) {
        return balances[_account];
    }

    function stakedBalance(
        address _account
    ) external view override returns (uint256) {
        if (nonStakingAccounts[_account]) {
            return 0;
        }
        return balances[_account];
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(
        address _owner,
        address _spender
    ) external view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(
        address _spender,
        uint256 _amount
    ) external override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(
            _amount,
            "BaseToken: transfer amount exceeds allowance"
        );
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        require(_account != address(0), "BaseToken: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal {
        require(
            _account != address(0),
            "BaseToken: burn from the zero address"
        );

        balances[_account] = balances[_account].sub(
            _amount,
            "BaseToken: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(_amount);

        if (nonStakingAccounts[_account]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }

        emit Transfer(_account, address(0), _amount);
    }

    function _transfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        require(
            _sender != address(0),
            "BaseToken: transfer from the zero address"
        );
        require(
            _recipient != address(0),
            "BaseToken: transfer to the zero address"
        );

        if (inPrivateTransferMode) {
            require(isRecipientAllowed[_recipient] || isRecipientAllowed[_sender],"BaseToken: _recipient not whitelisted");
        }
        
        balances[_sender] = balances[_sender].sub(
            _amount,
            "BaseToken: transfer amount exceeds balance"
        );
        balances[_recipient] = balances[_recipient].add(_amount);

        if (nonStakingAccounts[_sender]) {
            nonStakingSupply = nonStakingSupply.sub(_amount);
        }
        if (nonStakingAccounts[_recipient]) {
            nonStakingSupply = nonStakingSupply.add(_amount);
        }

        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) private {
        require(
            _owner != address(0),
            "BaseToken: approve from the zero address"
        );
        require(
            _spender != address(0),
            "BaseToken: approve to the zero address"
        );

        allowances[_owner][_spender] = _amount;

        emit Approval(_owner, _spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "../interfaces/IMintable.sol";
import "./BaseToken.sol";

contract MintableBaseToken is BaseToken, IMintable {
    mapping(address => bool) public override isMinter;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply
    ) BaseToken(_name, _symbol, _initialSupply) {}

    modifier onlyMinter() {
        require(isMinter[msg.sender], "MintableBaseToken: forbidden");
        _;
    }

    function setMinter(
        address _minter,
        bool _isActive
    ) external override onlyGov {
        isMinter[_minter] = _isActive;
    }

    function mint(
        address _account,
        uint256 _amount
    ) external override onlyMinter {
        _mint(_account, _amount);
    }

    function burn(
        address _account,
        uint256 _amount
    ) external override onlyMinter {
        _burn(_account, _amount);
    }
}

contract esNAR is MintableBaseToken {
    constructor()
        MintableBaseToken("Escrowed NAR", "esNAR", 80000000e18)
    {}

    function id() external pure returns (string memory _name) {
        return "esNAR";
    }
}

pragma solidity 0.8.15;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NarwhalToken is ERC20 {
    constructor() ERC20("NAR", "NAR") {
        _mint(msg.sender, 100000000e18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPoolRewards.sol";
import "../Uniswap/Interfaces/IUniswapV2Pair.sol";

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

contract Governable {
    address public gov;
    address public pendingGov;

    constructor() {
        gov = msg.sender;
    }

    event AddressUpdated(string name, address a);
    
    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    // Set addresses
    function setPendingGovFund(address _gov) external onlyGov {
        require(_gov != address(0), "ADDRESS_0");
        pendingGov = _gov;
    }

    function confirmGovFund() external onlyGov {
        gov = pendingGov;
        emit AddressUpdated("govFund", gov);
    }
}

contract Vester is IERC20, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public vestingDuration;

    address public esToken;
    address public claimableToken;
    address public NarwhalPool;
    uint256 public totalSupply;

    bool public hasMaxVestableAmount;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public cumulativeClaimAmounts;
    mapping(address => uint256) public claimedAmounts;
    mapping(address => uint256) public lastVestingTimes;

    mapping(address => uint256) public pairAmounts;

    mapping(address => uint256) public transferredAverageStakedAmounts;
    mapping(address => uint256) public transferredCumulativeRewards;
    mapping(address => uint256) public cumulativeRewardDeductions;

    mapping(address => bool) public isHandler;
    uint256 public pairSupply;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);
    event HandlerSet(address indexed handler, bool isActive);
    event NarwhalPoolSet(address indexed narwhalpool);
    event MaxVestableAmountSet(bool hasMaxVestableAmount);
    event TransferredAverageStakedAmountsSet(address indexed account, uint256 amount);
    event TransferredCumulativeRewardsSet(address indexed account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _vestingDuration,
        address _esToken,
        address _claimableToken
    ) {
        name = _name;
        symbol = _symbol;

        vestingDuration = _vestingDuration;

        esToken = _esToken;
        claimableToken = _claimableToken;
        hasMaxVestableAmount = true;
    }


    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit HandlerSet(_handler, _isActive);
    }

    function setNarwhalPool(address _narwhalPool) external onlyGov {
        NarwhalPool = _narwhalPool;
        emit NarwhalPoolSet(_narwhalPool);
    }

    function setHasMaxVestableAmount(
        bool _hasMaxVestableAmount
    ) external onlyGov {
        hasMaxVestableAmount = _hasMaxVestableAmount;
        emit MaxVestableAmountSet(_hasMaxVestableAmount);
    }

    function setTransferredAverageStakedAmounts(
        address _account,
        uint256 _amount
    ) external {
        _validateHandler();
        transferredAverageStakedAmounts[_account] = _amount;
        emit TransferredAverageStakedAmountsSet(_account, _amount);
    }

    function settransferredCumulativeRewards(
        address _account,
        uint256 _amount
    ) external {
        _validateHandler();
        transferredCumulativeRewards[_account] = _amount;
        emit TransferredCumulativeRewardsSet(_account, _amount);
    }

    function claimable(address _account) public view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account].sub(
            claimedAmounts[_account]
        );
        uint256 nextClaimable = _getNextClaimableAmount(_account);
        return amount.add(nextClaimable);
    }

    function getMaxVestableAmount(
        address _account
    ) public view returns (uint256) {
        uint256 transferredCumulativeReward = transferredCumulativeRewards[
            _account
        ];
        uint256 cumulativeReward = IPoolRewards(NarwhalPool).cumulativeRewards(
            _account
        );

        uint256 maxVestableAmount = cumulativeReward.add(
            transferredCumulativeReward
        );
        uint256 cumulativeRewardDeduction = cumulativeRewardDeductions[
            _account
        ];

        if (maxVestableAmount < cumulativeRewardDeduction) {
            return 0;
        }

        return maxVestableAmount.sub(cumulativeRewardDeduction);
    }

    function getPairAmount(
        uint256 _esAmount,
        address _account
    ) public view returns (uint256) {
        uint256 combinedAverageStakedAmount = getCombinedAverageStakedAmount(
            _account
        );

        if (combinedAverageStakedAmount == 0) {
            return 0;
        }

        uint256 maxVestableAmount = getMaxVestableAmount(_account);

        if (maxVestableAmount == 0) {
            return 0;
        }

        return
            _esAmount.mul(combinedAverageStakedAmount).div(maxVestableAmount);
    }

    function getCombinedAverageStakedAmount(
        address _account
    ) public view returns (uint256) {
        uint256 cumulativeReward = IPoolRewards(NarwhalPool).cumulativeRewards(
            _account
        );

        uint256 transferredCumulativeReward = transferredCumulativeRewards[
            _account
        ];
        uint256 totalCumulativeReward = cumulativeReward.add(
            transferredCumulativeReward
        );
        if (totalCumulativeReward == 0) {
            return 0;
        }

        uint256 averageStakedAmount = IPoolRewards(NarwhalPool)
            .averageStakedAmounts(_account);

        uint256 transferredAverageStakedAmount = transferredAverageStakedAmounts[
                _account
            ];

        return
            averageStakedAmount
                .mul(cumulativeReward)
                .div(totalCumulativeReward)
                .add(
                    transferredAverageStakedAmount
                        .mul(transferredCumulativeReward)
                        .div(totalCumulativeReward)
                );
    }

    function getTotalVested(address _account) public view returns (uint256) {
        return balances[_account].add(cumulativeClaimAmounts[_account]);
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    // empty implementation, tokens are non-transferrable
    function transfer(
        address /* recipient */,
        uint256 /* amount */
    ) public pure returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function allowance(
        address /* owner */,
        address /* spender */
    ) public view virtual returns (uint256) {
        return 0;
    }

    // empty implementation, tokens are non-transferrable
    function approve(
        address /* spender */,
        uint256 /* amount */
    ) public virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function transferFrom(
        address /* sender */,
        address /* recipient */,
        uint256 /* amount */
    ) public virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    function deposit(uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function depositForAccount(
        address _account,
        uint256 _amount
    ) external nonReentrant {
        _validateHandler();
        _deposit(_account, _amount);
    }

    function _deposit(
        address _account,
        uint256 _amount
    ) private returns (uint256) {
        require(_amount > 0, "Vester: invalid _amount");

        _updateVesting(_account);

        IERC20(esToken).safeTransferFrom(_account, address(this), _amount);
        _mint(_account, _amount);
        uint256 pairAmountDiff;

        uint256 pairAmount = pairAmounts[_account];
        uint256 nextPairAmount = getPairAmount(balances[_account], _account);

        if (nextPairAmount > pairAmount) {
            pairAmountDiff = nextPairAmount.sub(pairAmount);

            uint256 totalStaked = IPoolRewards(NarwhalPool).getUserTokenBalance(
                _account
            );

            require(
                totalStaked >= pairAmountDiff,
                "Not enough balance locked up in pool"
            );
            IPoolRewards(NarwhalPool)._lockNAR(_account, pairAmountDiff);
            _mintPair(_account, pairAmountDiff);
        }

        if (hasMaxVestableAmount) {
            uint256 maxAmount = getMaxVestableAmount(_account);
            require(
                getTotalVested(_account) <= maxAmount,
                "Vester: max vestable amount exceeded"
            );
        }
        emit Deposit(_account, _amount);
        return (pairAmountDiff);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        require(_token != esToken, "Vester: invalid token");
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function withdraw() external nonReentrant {
        address account = msg.sender;
        address _receiver = account;
        _claim(account, _receiver);

        uint256 claimedAmount = cumulativeClaimAmounts[account];
        uint256 balance = balances[account];
        uint256 totalVested = balance.add(claimedAmount);
        require(totalVested > 0, "Vester: vested amount is zero");

        uint256 pairAmount = pairAmounts[account];
        _burnPair(account, pairAmount);

        if (pairAmount > 0) {
            IPoolRewards(NarwhalPool)._unLockNAR(msg.sender, pairAmount);
        }

        IERC20(esToken).safeTransfer(_receiver, balance);
        _burn(account, balance);

        delete cumulativeClaimAmounts[account];
        delete claimedAmounts[account];
        delete lastVestingTimes[account];

        emit Withdraw(account, claimedAmount, balance);
    }

    function claim() external nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    function claimForAccount(
        address _account,
        address _receiver
    ) external nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    function _claim(
        address _account,
        address _receiver
    ) private returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        claimedAmounts[_account] = claimedAmounts[_account].add(amount);
        cumulativeRewardDeductions[_account] += amount;
        IERC20(claimableToken).safeTransfer(_receiver, amount);
        
        emit Claim(_account, amount);
        return amount;
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account].sub(
            _amount,
            "Vester: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _mintPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        pairSupply = pairSupply.add(_amount);
        pairAmounts[_account] = pairAmounts[_account].add(_amount);
    }

    function _burnPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        pairAmounts[_account] = pairAmounts[_account].sub(
            _amount,
            "Vester: burn amount exceeds balance"
        );
        pairSupply = pairSupply.sub(_amount);
    }

    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);
        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        // transfer claimableAmount from balances to cumulativeClaimAmounts
        _burn(_account, amount);
        cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account].add(
            amount
        );

        IMintable(esToken).burn(address(this), amount);
    }

    function _getNextClaimableAmount(
        address _account
    ) private view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastVestingTimes[_account]);

        uint256 balance = balances[_account];
        if (balance == 0) {
            return 0;
        }

        uint256 vestedAmount = getTotalVested(_account);
        uint256 claimableAmount = vestedAmount.mul(timeDiff).div(
            vestingDuration
        );

        if (claimableAmount < balance) {
            return claimableAmount;
        }

        return balance;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPoolRewards.sol";
import "../Uniswap/Interfaces/IUniswapV2Pair.sol";

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

contract Governable {
    address public gov;
    address public pendingGov;

    constructor() {
        gov = msg.sender;
    }

    event AddressUpdated(string name, address a);
    
    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    // Set addresses
    function setPendingGovFund(address _gov) external onlyGov {
        require(_gov != address(0), "ADDRESS_0");
        pendingGov = _gov;
    }

    function confirmGovFund() external onlyGov {
        gov = pendingGov;
        emit AddressUpdated("govFund", gov);
    }
}

contract VesterNLP is IERC20, ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    uint8 public decimals = 18;

    uint256 public vestingDuration;

    address public esToken;
    address public claimableToken;
    address public TradingVault;
    uint256 public totalSupply;

    bool public hasMaxVestableAmount;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public cumulativeClaimAmounts;
    mapping(address => uint256) public claimedAmounts;
    mapping(address => uint256) public lastVestingTimes;

    mapping(address => uint256) public pairAmounts;

    mapping(address => uint256) public transferredAverageStakedAmounts;
    mapping(address => uint256) public transferredCumulativeRewards;
    mapping(address => uint256) public cumulativeRewardDeductions;

    mapping(address => bool) public isHandler;
    uint256 public pairSupply;

    event Claim(address receiver, uint256 amount);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 claimedAmount, uint256 balance);
    event HandlerSet(address indexed handler, bool isActive);
    event TradingVaultSet(address indexed tradingVault);
    event MaxVestableAmountSet(bool hasMaxVestableAmount);
    event TransferredAverageStakedAmountsSet(address indexed account, uint256 amount);
    event TransferredCumulativeRewardsSet(address indexed account, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _vestingDuration,
        address _esToken,
        address _claimableToken
    ) {
        name = _name;
        symbol = _symbol;

        vestingDuration = _vestingDuration;

        esToken = _esToken;
        claimableToken = _claimableToken;
        hasMaxVestableAmount = true;
    }

    
    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit HandlerSet(_handler, _isActive);
    }

    function setTradingVault(address _TradingVault) external onlyGov {
        TradingVault = _TradingVault;
        emit TradingVaultSet(_TradingVault);
    }

    function setHasMaxVestableAmount(
        bool _hasMaxVestableAmount
    ) external onlyGov {
        hasMaxVestableAmount = _hasMaxVestableAmount;
        emit MaxVestableAmountSet(_hasMaxVestableAmount);
    }

    function setTransferredAverageStakedAmounts(
        address _account,
        uint256 _amount
    ) external {
        _validateHandler();
        transferredAverageStakedAmounts[_account] = _amount;
        emit TransferredAverageStakedAmountsSet(_account, _amount);
    }

    function settransferredCumulativeRewards(
        address _account,
        uint256 _amount
    ) external {
        _validateHandler();
        transferredCumulativeRewards[_account] = _amount;
        emit TransferredCumulativeRewardsSet(_account, _amount);
    }

    function claimable(address _account) public view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account].sub(
            claimedAmounts[_account]
        );
        uint256 nextClaimable = _getNextClaimableAmount(_account);
        return amount.add(nextClaimable);
    }

    function getMaxVestableAmount(
        address _account
    ) public view returns (uint256) {
        uint256 transferredCumulativeReward = transferredCumulativeRewards[
            _account
        ];
        uint256 cumulativeReward = IPoolRewards(TradingVault).cumulativeRewards(
            _account
        );

        uint256 maxVestableAmount = cumulativeReward.add(
            transferredCumulativeReward
        );
        uint256 cumulativeRewardDeduction = cumulativeRewardDeductions[
            _account
        ];

        if (maxVestableAmount < cumulativeRewardDeduction) {
            return 0;
        }

        return maxVestableAmount.sub(cumulativeRewardDeduction);
    }

    function getPairAmount(
        uint256 _esAmount,
        address _account
    ) public view returns (uint256) {
        uint256 combinedAverageStakedAmount = getCombinedAverageStakedAmount(
            _account
        );

        if (combinedAverageStakedAmount == 0) {
            return 0;
        }

        uint256 maxVestableAmount = getMaxVestableAmount(_account);

        if (maxVestableAmount == 0) {
            return 0;
        }

        return
            _esAmount.mul(combinedAverageStakedAmount).div(maxVestableAmount);
    }

    function getCombinedAverageStakedAmount(
        address _account
    ) public view returns (uint256) {
        uint256 cumulativeReward = IPoolRewards(TradingVault).cumulativeRewards(
            _account
        );

        uint256 transferredCumulativeReward = transferredCumulativeRewards[
            _account
        ];
        uint256 totalCumulativeReward = cumulativeReward.add(
            transferredCumulativeReward
        );
        if (totalCumulativeReward == 0) {
            return 0;
        }

        uint256 averageStakedAmount = IPoolRewards(TradingVault)
            .averageStakedAmounts(_account);

        uint256 transferredAverageStakedAmount = transferredAverageStakedAmounts[
                _account
            ];

        return
            averageStakedAmount
                .mul(cumulativeReward)
                .div(totalCumulativeReward)
                .add(
                    transferredAverageStakedAmount
                        .mul(transferredCumulativeReward)
                        .div(totalCumulativeReward)
                );
    }

    function getTotalVested(address _account) public view returns (uint256) {
        return balances[_account].add(cumulativeClaimAmounts[_account]);
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    // empty implementation, tokens are non-transferrable
    function transfer(
        address /* recipient */,
        uint256 /* amount */
    ) public pure returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function allowance(
        address /* owner */,
        address /* spender */
    ) public view virtual returns (uint256) {
        return 0;
    }

    // empty implementation, tokens are non-transferrable
    function approve(
        address /* spender */,
        uint256 /* amount */
    ) public virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function transferFrom(
        address /* sender */,
        address /* recipient */,
        uint256 /* amount */
    ) public virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    function deposit(uint256 _amount) external nonReentrant {
        _deposit(msg.sender, _amount);
    }

    function depositForAccount(
        address _account,
        uint256 _amount
    ) external nonReentrant {
        _validateHandler();
        _deposit(_account, _amount);
    }

    function _deposit(
        address _account,
        uint256 _amount
    ) private returns (uint256) {
        require(_amount > 0, "Vester: invalid _amount");

        _updateVesting(_account);

        IERC20(esToken).safeTransferFrom(_account, address(this), _amount);
        _mint(_account, _amount);
        uint256 pairAmountDiff;

        uint256 pairAmount = pairAmounts[_account];
        uint256 nextPairAmount = getPairAmount(balances[_account], _account);

        if (nextPairAmount > pairAmount) {
            pairAmountDiff = nextPairAmount.sub(pairAmount);

            uint256 totalStaked = IPoolRewards(TradingVault)
                .getUserTokenBalance(_account);

            require(
                totalStaked >= pairAmountDiff,
                "Not enough balance locked up in pool"
            );
            IPoolRewards(TradingVault)._lockNAR(_account, pairAmountDiff);
            _mintPair(_account, pairAmountDiff);
        }

        if (hasMaxVestableAmount) {
            uint256 maxAmount = getMaxVestableAmount(_account);

            require(
                getTotalVested(_account) <= maxAmount,
                "Vester: max vestable amount exceeded"
            );
        }
        
        emit Deposit(_account, _amount);
        return (pairAmountDiff);
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyGov {
        require(_token != esToken, "Vester: invalid token");
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function withdraw() external nonReentrant {
        address account = msg.sender;
        address _receiver = account;
        _claim(account, _receiver);

        uint256 claimedAmount = cumulativeClaimAmounts[account];
        uint256 balance = balances[account];
        uint256 totalVested = balance.add(claimedAmount);
        require(totalVested > 0, "Vester: vested amount is zero");

        uint256 pairAmount = pairAmounts[account];
        _burnPair(account, pairAmount);

        if (pairAmount > 0) {
            IPoolRewards(TradingVault)._unLockNAR(msg.sender, pairAmount);
        }

        IERC20(esToken).safeTransfer(_receiver, balance);
        _burn(account, balance);

        delete cumulativeClaimAmounts[account];
        delete claimedAmounts[account];
        delete lastVestingTimes[account];

        emit Withdraw(account, claimedAmount, balance);
    }

    function claim() external nonReentrant returns (uint256) {
        return _claim(msg.sender, msg.sender);
    }

    function claimForAccount(
        address _account,
        address _receiver
    ) external nonReentrant returns (uint256) {
        _validateHandler();
        return _claim(_account, _receiver);
    }

    function _claim(
        address _account,
        address _receiver
    ) private returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        claimedAmounts[_account] = claimedAmounts[_account].add(amount);
        cumulativeRewardDeductions[_account] += amount;
        IERC20(claimableToken).safeTransfer(_receiver, amount);
        emit Claim(_account, amount);
        return amount;
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account].sub(
            _amount,
            "Vester: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _mintPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        pairSupply = pairSupply.add(_amount);
        pairAmounts[_account] = pairAmounts[_account].add(_amount);
    }

    function _burnPair(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        pairAmounts[_account] = pairAmounts[_account].sub(
            _amount,
            "Vester: burn amount exceeds balance"
        );
        pairSupply = pairSupply.sub(_amount);
    }

    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);
        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        // transfer claimableAmount from balances to cumulativeClaimAmounts
        _burn(_account, amount);
        cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account].add(
            amount
        );

        IMintable(esToken).burn(address(this), amount);
    }

    function _getNextClaimableAmount(
        address _account
    ) private view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastVestingTimes[_account]);

        uint256 balance = balances[_account];
        if (balance == 0) {
            return 0;
        }

        uint256 vestedAmount = getTotalVested(_account);
        uint256 claimableAmount = vestedAmount.mul(timeDiff).div(
            vestingDuration
        );

        if (claimableAmount < balance) {
            return claimableAmount;
        }

        return balance;
    }

    function _validateHandler() private view {
        require(isHandler[msg.sender], "Vester: forbidden");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPoolRewards.sol";
import "../Uniswap/Interfaces/IUniswapV2Pair.sol";

contract VestingSchedule is IERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public name;
    string public symbol;
    
    //0 uint256 public privateRoundCLiff = 0; 30 months
    //1 uint256 public ifoCLiff = 0; 3 months
    //2 uint256 public treasuryCLiff = 0; 5 years
    //3 uint256 public teamCLiff = 182 days; 30 months
    //4 uint256 public wombatCLiff = 60 days; 3 years
    //5 uint256 public advisoryCLiff = 182 days; 30 months
    //6 uint256 public marketingCLiff = 7 days; 1 year

    address public narToken;
    address public NarwhalPool;
    uint256 public totalSupply;
    uint256 public startTime;
    bool public amountsAdded = false;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public cumulativeClaimAmounts;
    mapping(address => uint256) public claimedAmounts;
    mapping(address => uint256) public lastVestingTimes;

    mapping(address => uint256) public addressGroup;
    mapping(uint256 => uint256) public groupCliff;
    mapping(uint256 => bool) public groupCliffSet;
    mapping(uint256 => uint256) public groupVestingDuration;
    mapping(address => bool) public allowedClaimers;


    event Claim(address receiver, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _narToken,
        uint256[] memory _cliffs,
        uint256[] memory _vestingDurations
    ) {
        name = _name;
        symbol = _symbol;
        narToken = _narToken;
        
        require(_cliffs.length == _vestingDurations.length,"Wrong arrays length");

        for (uint256 i = 0; i < _cliffs.length; i++) {
            addGroupCliff(i,_cliffs[i],_vestingDurations[i]);
        }
    }

    function start() external onlyOwner {
        require(startTime == 0, "Already started");
        require(amountsAdded == true,"Add amounts first");
        startTime = block.timestamp;
    }

    function changeClaimerStatus(address _claimer, bool _status) external onlyOwner {
        allowedClaimers[_claimer] = _status;
    }

    function addGroupCliff(uint256 _group, uint256 _cliff,uint256 _vestingDuration) public onlyOwner {
        require(groupCliffSet[_group] == false, "Cannot change cliff, already set");
        groupCliff[_group] = _cliff;
        groupVestingDuration[_group] = _vestingDuration;
        groupCliffSet[_group] = true;
    }

    function transferAnyERC20(address _token) external onlyOwner {
        IERC20(_token).safeTransfer(owner(),IERC20(_token).balanceOf(address(this)));
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balances[_account];
    }

    function addAmountToInvestors(
        address[] memory _accounts,
        uint256[] memory _amounts,
        uint256[] memory _group
    ) public onlyOwner {
        require(amountsAdded == false, "Already added");
        require(
            _accounts.length == _amounts.length &&
            _amounts.length == _group.length,
            "Wrong arrays length"
        );

        uint256 acc = _accounts.length;
        for (uint256 i = 0; i < acc; i++) {
            _updateVesting(_accounts[i]);
            _mint(_accounts[i], _amounts[i]);
            addressGroup[_accounts[i]] = _group[i];
            lastVestingTimes[_accounts[i]] = block.timestamp.add(groupCliff[addressGroup[_accounts[i]]]);
            allowedClaimers[_accounts[i]] = true;
        }
        amountsAdded = true;
    }

    function claimable(address _account) public view returns (uint256) {
        uint256 amount = cumulativeClaimAmounts[_account].sub(
            claimedAmounts[_account]
        );
        uint256 nextClaimable = _getNextClaimableAmount(_account);

        return amount.add(nextClaimable);
    }

    function claim() external nonReentrant returns (uint256) {
        uint256 timeCheck = startTime.add(groupCliff[addressGroup[msg.sender]]);
        require(block.timestamp >= timeCheck,"Not time to claim yet");
        require(startTime != 0, "Not started");
        require(allowedClaimers[msg.sender] == true, "Not allowed to claim");
        return _claim(msg.sender, msg.sender);
    }

    function _claim(
        address _account,
        address _receiver
    ) private returns (uint256) {
        _updateVesting(_account);
        uint256 amount = claimable(_account);
        require(amount != 0, "No amounts to claim");
        claimedAmounts[_account] = claimedAmounts[_account].add(amount);

        IERC20(narToken).safeTransfer(_receiver, amount);

        emit Claim(_account, amount);
        return amount;
    }

    function _mint(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: mint to the zero address");

        totalSupply = totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);

        emit Transfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "Vester: burn from the zero address");

        balances[_account] = balances[_account].sub(
            _amount,
            "Vester: burn amount exceeds balance"
        );
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);
    }

    function _updateVesting(address _account) private {
        uint256 amount = _getNextClaimableAmount(_account);
        lastVestingTimes[_account] = block.timestamp;

        if (amount == 0) {
            return;
        }

        _burn(_account, amount);
        cumulativeClaimAmounts[_account] = cumulativeClaimAmounts[_account].add(
            amount
        );
    }

    function getTotalVested(address _account) public view returns (uint256) {
        return balances[_account].add(cumulativeClaimAmounts[_account]);
    }

    function _getNextClaimableAmount(
        address _account
    ) private view returns (uint256) {
        uint256 timeDiff = block.timestamp.sub(lastVestingTimes[_account]);

        uint256 balance = balances[_account];
        if (balance == 0) {
            return 0;
        }
        uint256 vestedAmount = getTotalVested(_account);
        uint256 claimableAmount = vestedAmount.mul(timeDiff).div(
            groupVestingDuration[addressGroup[_account]]
        );

        if (claimableAmount < balance) {
            return claimableAmount;
        } else {
            return balance;
        }
    }

    // empty implementation, tokens are non-transferrable
    function transfer(
        address /* recipient */,
        uint256 /* amount */
    ) public pure returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function allowance(
        address /* owner */,
        address /* spender */
    ) public view virtual returns (uint256) {
        return 0;
    }

    // empty implementation, tokens are non-transferrable
    function approve(
        address /* spender */,
        uint256 /* amount */
    ) public virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

    // empty implementation, tokens are non-transferrable
    function transferFrom(
        address /* sender */,
        address /* recipient */,
        uint256 /* amount */
    ) public virtual returns (bool) {
        revert("Vester: non-transferrable");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/AggregatorInterface.sol";
import "./interfaces/PoolInterface.sol";
import "./interfaces/PausableInterface.sol";
import "./interfaces/PairInfoInterface.sol";

contract TradingStorage is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.UintSet;

    // Constants
    uint public PRECISION;
    address public USDT;

    // Contracts (updatable)
    AggregatorInterface public priceAggregator;
    PairInfoInterface public pairInfos;
    PoolInterface public pool;
    address public trading;
    address public callbacks;

    address public vault;
    // Trading variables
    uint public maxTradesPerPair;
    uint public maxPendingMarketOrders;
    uint[5] public spreadReductionsP; // %

    // Gov (updatable)
    address public gov;
    address public pendingGov;

    mapping(uint256 => address) public keeperForOrder;

    // Enums
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    
    // Events
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // usdtDecimals
        uint positionSizeUSDT; // usdtDecimals
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl;
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUSDT; // PRECISION
        uint openInterestUSDT; // usdtDecimals
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // usdtDecimals
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId;
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;
    }

    struct PendingLimitOrder {
        address limitHolder;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    // Trades mappings
    mapping(address => mapping(uint => mapping(uint => Trade)))
        public openTrades;
    mapping(address => mapping(uint => mapping(uint => bool)))
        public tempTradeStatus;
    mapping(address => mapping(uint => mapping(uint => uint256)))
        public openTimestamp;
    mapping(address => mapping(uint => mapping(uint => int256)))
        public accPerOiOpen;
    mapping(address => mapping(uint => mapping(uint => TradeInfo)))
        public openTradesInfo;
    mapping(address => mapping(uint => uint)) public openTradesCount;
    mapping(uint => PendingLimitOrder) public reqID_pendingLimitOrder;

    // Limit orders mappings
    mapping(address => mapping(uint => mapping(uint => uint)))
        public openLimitOrderIds;
    mapping(address => mapping(uint => uint)) public openLimitOrdersCount;
    OpenLimitOrder[] public openLimitOrders;

    // Pending orders mappings
    mapping(uint => PendingMarketOrder) public reqID_pendingMarketOrder;
    mapping(address => EnumerableSet.UintSet) private pendingOrderIds;
    mapping(address => mapping(uint => uint)) public pendingMarketOpenCount;
    mapping(address => mapping(uint => uint)) public pendingMarketCloseCount;

    // List of open trades & limit orders
    mapping(uint => address[]) public pairTraders;
    mapping(address => mapping(uint => uint)) public pairTradersId;

    // Current and max open interests for each pair
    mapping(uint => uint[5]) public openInterestUSDT; // usdtDecimals [long,short,max OI,max netOI, min netOI]
    

    // Restrictions & Timelocks
    mapping(uint => uint) public tradesPerBlock;

    // List of allowed contracts => can update storage + mint/burn tokens
    mapping(address => bool) public isTradingContract;

    // Events
    event SupportedTokenAdded(address a);
    event TradingContractAdded(address a);
    event TradingContractRemoved(address a);
    event AddressUpdated(string name, address a);
    event NumberUpdated(string name, uint value);
    event NumberUpdatedPair(string name, uint pairIndex, uint value);
    event SpreadReductionsUpdated(uint[5]);

    function initialize(
        address _USDT
        ) public initializer {
        gov = msg.sender;
        maxTradesPerPair = 3;
        maxPendingMarketOrders = 5;
        spreadReductionsP = [15, 20, 25, 30, 35]; // %
        PRECISION = 1e10;
        require(address(_USDT) != address(0), "ADDRESS_0");
        USDT = _USDT;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == gov, "Not gov");
        _;
    }
    modifier onlyTrading() {
        require(isTradingContract[msg.sender], "Not allowed");
        _;
    }

    // Set addresses
    function setPendingGovFund(address _gov) external onlyGov {
        require(_gov != address(0), "ADDRESS_0");
        pendingGov = _gov;
    }

    function confirmGovFund() external onlyGov {
        gov = pendingGov;
        emit AddressUpdated("govFund", gov);
    }

    // Trading + callbacks contracts
    function addTradingContract(address _trading) external onlyGov {
        require(_trading != address(0),"ADDRESS_0");
        isTradingContract[_trading] = true;
        emit TradingContractAdded(_trading);
    }

    function removeTradingContract(address _trading) external onlyGov {
        require(_trading != address(0),"ADDRESS_0");
        require(isTradingContract[_trading],"Not a trading contract");
        isTradingContract[_trading] = false;
        emit TradingContractRemoved(_trading);
    }

    function setPriceAggregator(address _aggregator) external onlyGov {
        require(_aggregator != address(0),"ADDRESS_0");
        priceAggregator = AggregatorInterface(_aggregator);
        emit AddressUpdated("priceAggregator", _aggregator);
    }

    function setPairInfos(PairInfoInterface _pairInfos) external onlyGov {
        require(address(_pairInfos) != address(0),"ADDRESS_0");
        pairInfos = _pairInfos;
        emit AddressUpdated("_pairInfos", address(_pairInfos));
    }

    function setPool(address _pool) external onlyGov {
        require(_pool != address(0),"ADDRESS_0");
        pool = PoolInterface(_pool);
        IERC20Upgradeable(USDT).approve(address(pool), type(uint256).max);
        emit AddressUpdated("pool", _pool);
    }

    function setVault(address _vault) external onlyGov {
        require(_vault != address(0),"ADDRESS_0");
        vault = _vault;
        emit AddressUpdated("vault", _vault);
    }

    function setTrading(address _trading) external onlyGov {
        require(_trading != address(0),"ADDRESS_0");
        trading = _trading;
        emit AddressUpdated("trading", _trading);
    }

    function setCallbacks(address _callbacks) external onlyGov {
        require(_callbacks != address(0),"ADDRESS_0");
        callbacks = _callbacks;
        emit AddressUpdated("callbacks", _callbacks);
    }

    function setMaxTradesPerPair(uint _maxTradesPerPair) external onlyGov {
        require(_maxTradesPerPair > 0,"MUST_ABOVE_0");
        maxTradesPerPair = _maxTradesPerPair;
        emit NumberUpdated("maxTradesPerPair", _maxTradesPerPair);
    }

    function setMaxPendingMarketOrders(
        uint _maxPendingMarketOrders
    ) external onlyGov {
        require(_maxPendingMarketOrders > 0,"MAX_PENDING_MARKET_ORDERS");
        maxPendingMarketOrders = _maxPendingMarketOrders;
        emit NumberUpdated("maxPendingMarketOrders", _maxPendingMarketOrders);
    }

    function setSpreadReductionsP(uint[5] calldata _r) external onlyGov {
        require(
            _r[0] > 0 &&
                _r[1] > _r[0] &&
                _r[2] > _r[1] &&
                _r[3] > _r[2] &&
                _r[4] > _r[3]
        ,"WRONG_SPREAD");
        spreadReductionsP = _r;
        emit SpreadReductionsUpdated(_r);
    }

    function setMaxOpenInterestUSDT(
        uint _pairIndex,
        uint _newMaxOpenInterest,
        uint _newMaxNetOpenInterest,
        uint _newMinNetOpenInterest
    ) external onlyGov {
        // Can set max open interest to 0 to pause trading on this pair only
        openInterestUSDT[_pairIndex][2] = _newMaxOpenInterest;
        openInterestUSDT[_pairIndex][3] = _newMaxNetOpenInterest;
        openInterestUSDT[_pairIndex][4] = _newMinNetOpenInterest;
        emit NumberUpdatedPair(
            "maxOpenInterestUSDT",
            _pairIndex,
            _newMaxOpenInterest
        );
    }

    function storePendingLimitOrder(
        PendingLimitOrder memory _limitOrder,
        uint _orderId
    ) external onlyTrading {
        reqID_pendingLimitOrder[_orderId] = _limitOrder;
        keeperForOrder[_orderId] = _limitOrder.limitHolder;
    }

    function unregisterPendingLimitOrder(uint _order) external onlyTrading {
        delete reqID_pendingLimitOrder[_order];
        keeperForOrder[_order] = address(0);
    }

    // Manage stored trades
    function storeTrade(
        Trade memory _trade,
        TradeInfo memory _tradeInfo
    ) external onlyTrading {
        require(_trade.index == firstEmptyTradeIndex(_trade.trader, _trade.pairIndex), "Wrong index");
        openTrades[_trade.trader][_trade.pairIndex][_trade.index] = _trade;
        openTimestamp[_trade.trader][_trade.pairIndex][_trade.index] = block.timestamp;
        if (_trade.buy) {
            accPerOiOpen[_trade.trader][_trade.pairIndex][_trade.index] = pairInfos.getAccFundingFeesLong(_trade.pairIndex);
        } else {
            accPerOiOpen[_trade.trader][_trade.pairIndex][_trade.index] = pairInfos.getAccFundingFeesShort(_trade.pairIndex);
        }
        openTradesCount[_trade.trader][_trade.pairIndex]++;
        tradesPerBlock[block.number]++;

        if (openTradesCount[_trade.trader][_trade.pairIndex] == 1) {
            pairTradersId[_trade.trader][_trade.pairIndex] = pairTraders[
                _trade.pairIndex
            ].length;
            pairTraders[_trade.pairIndex].push(_trade.trader);
        }

        _tradeInfo.beingMarketClosed = false;
        openTradesInfo[_trade.trader][_trade.pairIndex][
            _trade.index
        ] = _tradeInfo;

        updateOpenInterestUSDT(
            _trade.pairIndex,
            _tradeInfo.openInterestUSDT,
            true,
            _trade.buy
        );

        //Pre registering value to false to get a true at close
        tempTradeStatus[_trade.trader][_trade.pairIndex][_trade.index] = false;
    }

    function unregisterTrade(
        address trader,
        uint pairIndex,
        uint index
    ) external onlyTrading {
        Trade storage t = openTrades[trader][pairIndex][index];
        TradeInfo storage i = openTradesInfo[trader][pairIndex][index];
        if (t.leverage == 0) {
            return;
        }

        updateOpenInterestUSDT(pairIndex, i.openInterestUSDT, false, t.buy);

        if (openTradesCount[trader][pairIndex] == 1) {
            uint _pairTradersId = pairTradersId[trader][pairIndex];
            address[] storage p = pairTraders[pairIndex];

            p[_pairTradersId] = p[p.length - 1];
            pairTradersId[p[_pairTradersId]][pairIndex] = _pairTradersId;

            delete pairTradersId[trader][pairIndex];
            p.pop();
        }
        uint256 openTime = openTimestamp[trader][pairIndex][index];
        delete openTrades[trader][pairIndex][index];
        delete openTimestamp[trader][pairIndex][index];
        delete openTradesInfo[trader][pairIndex][index];
        delete accPerOiOpen[t.trader][t.pairIndex][t.index];
        tempTradeStatus[trader][pairIndex][index] = true;

        openTradesCount[trader][pairIndex]--;
        tradesPerBlock[block.number]++;
    }

    // Manage pending market orders
    function storePendingMarketOrder(
        PendingMarketOrder memory _order,
        uint _id,
        bool _open
    ) external onlyTrading {
        pendingOrderIds[_order.trade.trader].add(_id);
        reqID_pendingMarketOrder[_id] = _order;
        reqID_pendingMarketOrder[_id].block = block.number;

        if (_open) {
            pendingMarketOpenCount[_order.trade.trader][
                _order.trade.pairIndex
            ]++;
        } else {
            pendingMarketCloseCount[_order.trade.trader][
                _order.trade.pairIndex
            ]++;
            openTradesInfo[_order.trade.trader][_order.trade.pairIndex][
                _order.trade.index
            ].beingMarketClosed = true;
        }
    }

    function unregisterPendingMarketOrder(
        uint _id,
        bool _open
    ) external onlyTrading {
        PendingMarketOrder memory _order = reqID_pendingMarketOrder[_id];
        bool removed = pendingOrderIds[_order.trade.trader].remove(_id);

        if (removed) {
            if (_open) {
                pendingMarketOpenCount[_order.trade.trader][
                    _order.trade.pairIndex
                ]--;
            } else {
                pendingMarketCloseCount[_order.trade.trader][
                    _order.trade.pairIndex
                ]--;
                openTradesInfo[_order.trade.trader][_order.trade.pairIndex][
                    _order.trade.index
                ].beingMarketClosed = false;
            }
            delete reqID_pendingMarketOrder[_id];
        }
    }

    // Manage open interest
    function updateOpenInterestUSDT(
        uint _pairIndex,
        uint _leveragedPosUSDT,
        bool _open,
        bool _long
    ) private {
        uint index = _long ? 0 : 1;
        uint[5] storage o = openInterestUSDT[_pairIndex];
        o[index] = _open
            ? o[index] + _leveragedPosUSDT
            : o[index] - _leveragedPosUSDT;
    }

    // Manage open limit orders
    function storeOpenLimitOrder(OpenLimitOrder memory o) external onlyTrading {
        o.index = firstEmptyOpenLimitIndex(o.trader, o.pairIndex);
        o.block = block.number;
        openLimitOrders.push(o);
        openLimitOrderIds[o.trader][o.pairIndex][o.index] =
            openLimitOrders.length -
            1;
        openLimitOrdersCount[o.trader][o.pairIndex]++;
    }

    function updateOpenLimitOrder(
        OpenLimitOrder calldata _o
    ) external onlyTrading {
        if (!hasOpenLimitOrder(_o.trader, _o.pairIndex, _o.index)) {
            return;
        }
        OpenLimitOrder storage o = openLimitOrders[
            openLimitOrderIds[_o.trader][_o.pairIndex][_o.index]
        ];
        o.positionSize = _o.positionSize;
        o.buy = _o.buy;
        o.leverage = _o.leverage;
        o.tp = _o.tp;
        o.sl = _o.sl;
        o.minPrice = _o.minPrice;
        o.maxPrice = _o.maxPrice;
        o.block = block.number;
    }

    function unregisterOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external onlyTrading {
        if (!hasOpenLimitOrder(_trader, _pairIndex, _index)) {
            return;
        }

        // Copy last order to deleted order => update id of this limit order
        uint id = openLimitOrderIds[_trader][_pairIndex][_index];
        openLimitOrders[id] = openLimitOrders[openLimitOrders.length - 1];
        openLimitOrderIds[openLimitOrders[id].trader][
            openLimitOrders[id].pairIndex
        ][openLimitOrders[id].index] = id;

        // Remove
        delete openLimitOrderIds[_trader][_pairIndex][_index];
        openLimitOrders.pop();

        openLimitOrdersCount[_trader][_pairIndex]--;
    }

    // Manage open trade
    function updateSl(
        address _trader,
        uint _pairIndex,
        uint _index,
        uint _newSl
    ) external onlyTrading {
        Trade storage t = openTrades[_trader][_pairIndex][_index];
        TradeInfo storage i = openTradesInfo[_trader][_pairIndex][_index];
        if (t.leverage == 0) {
            return;
        }
        t.sl = _newSl;
        i.slLastUpdated = block.number;
    }

    function updateTp(
        address _trader,
        uint _pairIndex,
        uint _index,
        uint _newTp
    ) external onlyTrading {
        Trade storage t = openTrades[_trader][_pairIndex][_index];
        TradeInfo storage i = openTradesInfo[_trader][_pairIndex][_index];
        if (t.leverage == 0) {
            return;
        }
        t.tp = _newTp;
        i.tpLastUpdated = block.number;
    }

    function updateTrade(Trade memory _t) external onlyTrading {
        // useful when partial adding/closing
        Trade storage t = openTrades[_t.trader][_t.pairIndex][_t.index];
        if (t.leverage == 0) {
            return;
        }
        t.initialPosToken = _t.initialPosToken;
        t.positionSizeUSDT = _t.positionSizeUSDT;
        t.openPrice = _t.openPrice;
        t.leverage = _t.leverage;
    }

    // Manage rewards
    function distributeLpRewards(uint _amount) external onlyTrading {
        pool.increaseAccTokens(_amount);
    }

    function transferUSDT(
        address _from,
        address _to,
        uint _amount
    ) external onlyTrading {
        if (_from == address(this)) {
            IERC20Upgradeable(USDT).safeTransfer(_to, _amount);
            
        } else {
            IERC20Upgradeable(USDT).safeTransferFrom(_from, _to, _amount);
        }
    }

    function getNetOI(uint256 _pairIndex, bool _long) external view returns (uint256) {
        int256 longOI = int256(openInterestUSDT[_pairIndex][0]);
        int256 shortOI = int256(openInterestUSDT[_pairIndex][1]);

        int256 netOI;
        if (_long) {
            netOI = longOI - shortOI;
        } else {
            netOI = shortOI - longOI;
        }
        
        return abs(netOI);
    }

    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    // View utils functions
    function firstEmptyTradeIndex(
        address trader,
        uint pairIndex
    ) public view returns (uint index) {
        bool allOccupied = true;

        for (uint i = 0; i < maxTradesPerPair; i++) {
            if (openTrades[trader][pairIndex][i].leverage == 0) {
                index = i;
                allOccupied = false;
                break;
            }
        }

        require(!allOccupied, "All open limit slots are full");
        return index;
    }

    function firstEmptyOpenLimitIndex(
        address trader,
        uint pairIndex
    ) public view returns (uint index) {
        bool allOccupied = true;
        for (uint i = 0; i < maxTradesPerPair; i++) {
            if (!hasOpenLimitOrder(trader, pairIndex, i)) {
                index = i;
                allOccupied = false;
                break;
            }
        }
        
        require(!allOccupied, "All open limit slots are full");
        return index;
    }

    function hasOpenLimitOrder(
        address trader,
        uint pairIndex,
        uint index
    ) public view returns (bool) {
        if (openLimitOrders.length == 0) {
            return false;
        }
        OpenLimitOrder storage o = openLimitOrders[
            openLimitOrderIds[trader][pairIndex][index]
        ];
        return
            o.trader == trader && o.pairIndex == pairIndex && o.index == index;
    }

    function pairTradersArray(
        uint _pairIndex
    ) external view returns (address[] memory) {
        return pairTraders[_pairIndex];
    }


    function getPendingOrderIds(
        address _trader
    ) external view returns (uint[] memory) {
        EnumerableSet.UintSet storage idsSet = pendingOrderIds[_trader];
        uint256 length = idsSet.length();
        uint[] memory idsArray = new uint[](length);

        for (uint256 i = 0; i < length; i++) {
            idsArray[i] = idsSet.at(i);
        }

        return idsArray;
    }

    function pendingOrderIdsCount(
        address _trader
    ) external view returns (uint) {
        return pendingOrderIds[_trader].length();
    }

    function getOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external view returns (OpenLimitOrder memory) {
        require(hasOpenLimitOrder(_trader, _pairIndex, _index),"MUST_HAVE_OPEN_LIMIT");
        return openLimitOrders[openLimitOrderIds[_trader][_pairIndex][_index]];
    }

    function getOpenLimitOrders()
        external
        view
        returns (OpenLimitOrder[] memory)
    {
        return openLimitOrders;
    }

    function getSpreadReductionsArray() external view returns (uint[5] memory) {
        return spreadReductionsP;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract NarwhalTradingVault is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public esnar;
    StorageInterface public immutable storageT;
    uint256 public rewardsToken; // 1e6
    address public Vester;
    address public USDT;

    // 3. Staking
    //Change back to 72 hours !!
    uint public withdrawTimelock = 1 minutes; // time

    // STATE
    // 1. USDT balance
    uint256 public currentBalanceUSDT; // 1e6

    // 2. USDT staking rewards
    uint public totalRewardsDistributed; // 1e6

    // 4. Mappings
    struct User {
        uint256 depositTimestamp;
        uint256 debtToken;
        uint256 amountInLockup;
    }
    mapping(address => User) public users;
    mapping(address => uint) public USDTToClaim;
    mapping(address => uint256) public cumulativeRewards;
    mapping(address => uint256) public averageStakedAmounts;
    mapping(address => uint256) public stakedAmounts;
    mapping(address => bool) public allowed;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration = 365 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => bool) public allowedToInteract;

    // EVENTS
    event Deposited(
        address caller,
        uint amount,
        uint newCurrentBalanceUSDT,
        uint shares
    );
    event Withdrawn(
        address caller,
        uint amount,
        uint newCurrentBalanceUSDT,
        uint shares
    );
    event Sent(
        address caller,
        address trader,
        uint amount,
        uint newCurrentBalanceUSDT
    );
    event ToClaim(
        address caller,
        address trader,
        uint amount,
        uint currentBalanceUSDT
    );
    event Claimed(address trader, uint amount, uint newCurrentBalanceUSDT);

    event ReceivedFromTrader(
        address caller,
        address trader,
        uint USDTAmount,
        uint vaultFeeUSDT,
        uint newCurrentBalanceUSDT
    );
    event NumberUpdated(string name, uint value);
    event AllowedToInteractSet(address indexed sender, bool status);
    event RewardsDurationSet(uint256 rewardsDuration);
    event RewardTokenSet(address indexed esnar);
    event VesterSet(address indexed vester);
    event UsdtSet(address indexed usdt);
    event RewardsSet(uint256 rewards);

    constructor(
        StorageInterface _storageT,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(address(_storageT) != address(0), "ADDRESS_0");
        storageT = _storageT;
    }

    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks() || allowedToInteract[msg.sender], "NOT_ALLOWED");
        _;
    }

    function setAllowedToInteract(address _sender, bool _status) public onlyGov {
        allowedToInteract[_sender] = _status;
        emit AllowedToInteractSet(_sender, _status);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyGov {
        require(
            block.timestamp > periodFinish,
            "Must complete previous rewards period"
        );
        require(_rewardsDuration >= 183 days && _rewardsDuration <= 730 days, "Out of range");
        rewardsDuration = _rewardsDuration;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsDurationSet(_rewardsDuration);
    }

    function setRewardToken(address _esnar) external onlyGov {
        require(address(_esnar) != address(0), "ADDRESS_0");
        require(address(esnar) == address(0), "ALREADY_SET");
        esnar = _esnar;
        emit RewardTokenSet(_esnar);
    }

    function setVester(address _vester) external onlyGov {
        require(_vester != address(0), "ADDRESS_0");
        Vester = _vester;
        emit VesterSet(_vester);
    }

    function setUSDT(address _usdt) public onlyGov {
        require(address(_usdt) != address(0), "ADDRESS_0");
        require(address(USDT) == address(0), "ALREADY_SET");
        USDT = _usdt;
        emit UsdtSet(_usdt);
    }

    function setWithdrawTimelock(uint _withdrawTimelock) external onlyGov {
        require(_withdrawTimelock > 1 days, "Should be above 1 day");
        withdrawTimelock = _withdrawTimelock;
        emit NumberUpdated("withdrawTimelock", _withdrawTimelock);
    }

    function setAllowed(address _sender, bool _status) public onlyOwner {
        allowed[_sender] = _status;
        emit AllowedToInteractSet(_sender, _status);
    }

    function updateReward(address account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    function notifyRewardAmount(uint256 reward) external onlyGov  {
        updateReward(address(0));
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }
        IERC20(address(esnar)).safeTransferFrom(msg.sender, address(this), reward);
        uint currBalance = IERC20(address(esnar)).balanceOf(address(this));
        require(rewardRate <= currBalance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardsSet(reward);
    }

    function balance() public view returns (uint256) {
        uint256 totalVaultBalance = currentBalanceUSDT;
        return (totalVaultBalance);
    }

    function getUserTokenBalance(
        address _account
    ) public view returns (uint256) {
        User storage u = users[_account];
        uint256 stakedToken;
        if (u.amountInLockup > 0) {
            stakedToken = u.amountInLockup.add(stakedAmounts[_account]);
        } else {
            stakedToken = stakedAmounts[_account];
        }
        return (stakedToken);
    }

    function getPricePerFullShare() public view returns (uint256) {
        return
            totalSupply() == 0 ? 10**storageT.USDT().decimals() : balance().mul(1e18).div(totalSupply());
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e6).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        uint256 stakedToken = userTotalBalance(account);
        return stakedToken.mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e6).add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function _lockNAR(address _account, uint256 _amount) public {
        require(msg.sender == Vester, "Not the vesting contract");
        User storage u = users[_account];
        stakedAmounts[_account] = stakedAmounts[_account].sub(_amount);
        u.amountInLockup = u.amountInLockup.add(_amount);
    }

    function _unLockNAR(address _account, uint256 _amount) public {
        require(msg.sender == Vester, "Not the vesting contract");
        User storage u = users[_account];
        u.amountInLockup = u.amountInLockup.sub(_amount);
        stakedAmounts[_account] = stakedAmounts[_account].add(_amount);
    }

    // Harvest rewards
    function harvest(address _user) public {
        if (balance() == 0) {
            return;
        }

        address user;
        if (allowed[msg.sender]) {
            user = _user;
        } else {
            user = msg.sender;
        }
        updateReward(user);

        User storage u = users[user];

        uint pendingTokens = rewards[user];

        if (pendingTokens > 0) {
            rewards[user] = 0;
            uint256 nextCumulativeReward = cumulativeRewards[user].add(
                pendingTokens
            );
            averageStakedAmounts[user] = averageStakedAmounts[user]
                .mul(cumulativeRewards[user])
                .div(nextCumulativeReward)
                .add(stakedAmounts[user].add(u.amountInLockup))
                .mul((pendingTokens))
                .div(nextCumulativeReward);
            cumulativeRewards[user] = nextCumulativeReward;
            rewardsToken += pendingTokens;
            IERC20(esnar).safeTransfer(user, pendingTokens);
        }
    }

    function depositAll(address _user) external {
        deposit(IERC20(USDT).balanceOf(msg.sender), _user);
    }

    function deposit(uint _amount, address _user) public nonReentrant {
        require(_amount > 0, "AMOUNT_0");
        address user;
        if (allowed[msg.sender]) {
            user = _user;
        } else {
            user = msg.sender;
        }

        User storage u = users[user];

        require(storageT.USDT().transferFrom(msg.sender, address(this), _amount));
        harvest(user);

        uint256 shares = 0;
        uint256 SCALE = 10 ** decimals() / 10 ** storageT.USDT().decimals();
        if (totalSupply() == 0) {
            require(_amount > 1000,"Not Enough Shares for first mint");
            shares = (_amount-1000) * SCALE;
            _mint(address(this),1000 * SCALE);
        } else {
            shares = (_amount.mul(totalSupply())).div(currentBalanceUSDT);
        }
        require(shares != 0, "Zero shares minted");
        
        currentBalanceUSDT += _amount;

        _mint(user, shares);
        stakedAmounts[user] = stakedAmounts[user].add(shares);
        u.depositTimestamp = block.timestamp;

        emit Deposited(user, _amount, currentBalanceUSDT, shares);
    }

    function withdrawAll() external {
        withdraw(balanceOf(msg.sender));
    }

    function withdraw(uint _shares) public nonReentrant {
        require(_shares > 0, "AMOUNT_0");
        require(
            _shares <= stakedAmounts[msg.sender],
            "Cant withdraw more than your balance"
        );

        User storage u = users[msg.sender];
        harvest(msg.sender);
        uint256 userAsset;
        userAsset = (balance().mul(_shares)).div(totalSupply());

        require(
            block.timestamp >= u.depositTimestamp + withdrawTimelock,
            "TOO_EARLY"
        );
        _burn(msg.sender, _shares);
        currentBalanceUSDT -= userAsset;
        stakedAmounts[msg.sender] = stakedAmounts[msg.sender].sub(_shares);
        IERC20(USDT).safeTransfer(msg.sender, userAsset);

        emit Withdrawn(msg.sender, userAsset, currentBalanceUSDT, _shares);
    }

    function userTotalBalance(address _user) public view returns (uint256) {
        User storage u = users[_user];
        uint256 staked;
        if (u.amountInLockup > 0) {
            staked = u.amountInLockup.add(stakedAmounts[_user]);
        } else {
            staked = stakedAmounts[_user];
        }
        return staked;
    }

    // USDT incentives
    function distributeRewardUSDT(
        uint _amount,
        bool _send
    ) public onlyCallbacks {
        currentBalanceUSDT = currentBalanceUSDT.add(_amount);
        totalRewardsDistributed += _amount;
        if (_send) {
            IERC20(USDT).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }

    // Handle traders USDT when a trade is closed
    function sendUSDTToTrader(
        address _trader,
        uint _amount
    ) external onlyCallbacks {
        if (_amount < currentBalanceUSDT) {
            currentBalanceUSDT = currentBalanceUSDT.sub(_amount);
            IERC20(USDT).safeTransfer(_trader, _amount);
            emit Sent(msg.sender, _trader, _amount, currentBalanceUSDT);
        } else {
            USDTToClaim[_trader] += _amount;
            emit ToClaim(msg.sender, _trader, _amount, currentBalanceUSDT);
        }
    }

    function claimUSDT() external {
        uint amount = USDTToClaim[msg.sender];
        require(amount > 0, "NOTHING_TO_CLAIM");
        require(currentBalanceUSDT > amount, "BALANCE_TOO_LOW");

        unchecked {
            currentBalanceUSDT -= amount;
        }
        USDTToClaim[msg.sender] = 0;
        IERC20(USDT).safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount, currentBalanceUSDT);
    }

    // Handle USDT from opened trades
    function receiveUSDTFromTrader(
        address _trader,
        uint _amount,
        uint _vaultFee,
        bool _send
    ) external onlyCallbacks {
        currentBalanceUSDT += _amount;
        storageT.transferUSDT(address(storageT), address(this), _amount);
        distributeRewardUSDT(_vaultFee, _send);
        emit ReceivedFromTrader(
            msg.sender,
            _trader,
            _amount,
            _vaultFee,
            currentBalanceUSDT
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUniswapV2ERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IUniswapV2Router01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./TransferHelper.sol";
import "../utils/math/Babylonian.sol";
import "./UniswapV2Library.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Interfaces/IUniswapV2Router01.sol";

contract SwapToPrice {
    using SafeMath for uint256;

    IUniswapV2Router01 public immutable router;
    address public immutable factory;

    constructor(address factory_, IUniswapV2Router01 router_) {
        factory = factory_;
        router = router_;
    }

    /// @dev Computes the direction and magnitude of the profit-maximizing trade
    function computeProfitMaximizingTrade(
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 reserveA,
        uint256 reserveB
    ) public pure returns (bool aToB, uint256 amountIn) {
        aToB = reserveA.mul(truePriceTokenB) / reserveB < truePriceTokenA;

        uint256 invariant = reserveA.mul(reserveB);

        uint256 leftSide = Babylonian.sqrt(
            invariant.mul(aToB ? truePriceTokenA : truePriceTokenB).mul(1000) /
                uint256(aToB ? truePriceTokenB : truePriceTokenA).mul(997)
        );
        uint256 rightSide = (aToB ? reserveA.mul(1000) : reserveB.mul(1000)) /
            997;

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide.sub(rightSide);
    }

    /** @dev Swaps an amount of either token such that the trade is profit-maximizing, given an external true price
     * true price is expressed in the ratio of token A to token B
     * caller must approve this contract to spend whichever token is intended to be swapped
     */
    function swapToPrice(
        address tokenA,
        address tokenB,
        uint256 truePriceTokenA,
        uint256 truePriceTokenB,
        uint256 maxSpendTokenA,
        uint256 maxSpendTokenB,
        address to,
        uint256 deadline
    ) public {
        // true price is expressed as a ratio, so both values must be non-zero
        require(
            truePriceTokenA != 0 && truePriceTokenB != 0,
            "ExampleSwapToPrice: ZERO_PRICE"
        );
        // caller can specify 0 for either if they wish to swap in only one direction, but not both
        require(
            maxSpendTokenA != 0 || maxSpendTokenB != 0,
            "ExampleSwapToPrice: ZERO_SPEND"
        );

        bool aToB;
        uint256 amountIn;
        {
            (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
                factory,
                tokenA,
                tokenB
            );
            (aToB, amountIn) = computeProfitMaximizingTrade(
                truePriceTokenA,
                truePriceTokenB,
                reserveA,
                reserveB
            );
        }

        // spend up to the allowance of the token in
        uint256 maxSpend = aToB ? maxSpendTokenA : maxSpendTokenB;
        if (amountIn > maxSpend) {
            amountIn = maxSpend;
        }

        address tokenIn = aToB ? tokenA : tokenB;
        address tokenOut = aToB ? tokenB : tokenA;
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(tokenIn, address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        router.swapExactTokensForTokens(
            amountIn,
            0, // amountOutMin: we can skip computing this number because the math is tested
            path,
            to,
            deadline
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev A helper methods for interacting with ERC20 tokens and
    sending ETH that do not consistently return true/false.
 */
library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/IUniswapV2ERC20.sol";

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint256;

    string public constant override name = "Uniswap V2";
    string public constant override symbol = "UNI-V2";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(
        address spender,
        uint256 value
    ) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(
        address to,
        uint256 value
    ) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(int256(-1))) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "UniswapV2: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./UniswapV2Pair.sol";
import "./Interfaces/IUniswapV2Factory.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external override returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(
            getPair[token0][token1] == address(0),
            "UniswapV2: PAIR_EXISTS"
        ); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));

        // This creates a new contract
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Interfaces/IUniswapV2Factory.sol";

library UniswapV2Library {
    using SafeMath for uint256;

    /// @dev Returns sorted token addresses, used to handle return values from
    /// pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    /// @dev Less efficient than the CREATE2 method below
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = IUniswapV2Factory(factory).getPair(token0, token1);
    }

    /// @dev Calculates the CREATE2 address for a pair without making any external calls
    function pairForCreate2(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        ); // this matches the CREATE2 in UniswapV2Factory.createPair
    }

    /// @dev Fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    /// @dev Given some amount of an asset and pair reserves, returns an equivalent
    /// amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /// @dev Given an input amount of an asset and pair reserves, returns the
    /// maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /// @dev Given an output amount of an asset and pair reserves, returns a required
    /// input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    /// @dev Performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    /// @dev Performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../utils/math/FixedPoint.sol";
import "../Uniswap/Interfaces/IUniswapV2Pair.sol";

/// @dev Library with helper methods for oracles that are concerned
/// with computing average prices.
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    /// @dev Helper function that returns the current block timestamp
    /// within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    /// @dev Produces the cumulative price using counterfactuals to save gas
    /// and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    )
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        ) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative +=
                uint256(FixedPoint.fraction(reserve1, reserve0)._x) *
                timeElapsed;
            // counterfactual
            price1Cumulative +=
                uint256(FixedPoint.fraction(reserve0, reserve1)._x) *
                timeElapsed;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/math/Math.sol";
import "./UniswapV2ERC20.sol";
import "../utils/math/UQ112x112.sol";
import "./Interfaces/IUniswapV2Pair.sol";
import "./Interfaces/IUniswapV2Callee.sol";
import "./Interfaces/IUniswapV2Factory.sol";

contract UniswapV2Pair is IUniswapV2Pair {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    string public constant override name = "Uniswap V2";
    string public constant override symbol = "UNI-V2";
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public constant override MINIMUM_LIQUIDITY = 10 ** 3;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    address public override factory;
    address public override token0;
    address public override token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;
    uint256 public override kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves()
        public
        view
        override
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    constructor() {
        factory = msg.sender;
    }

    /// @dev Called once by the factory at time of deployment.
    function initialize(address _token0, address _token1) external override {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    /// @dev Update reserves and, on the first call per block, price accumulators.
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            balance0 <= uint112(int112(-1)) && balance1 <= uint112(int112(-1)),
            "UniswapV2: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /// @dev If fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k).
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0).mul(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint256 denominator = rootK.mul(5).add(rootKLast);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    /// @dev This low-level function should be called from a contract which performs
    /// important safety checks.
    function mint(
        address to
    ) external override lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0.sub(_reserve0);
        uint256 amount1 = balance1.sub(_reserve1);
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                amount0.mul(_totalSupply) / _reserve0,
                amount1.mul(_totalSupply) / _reserve1
            );
        }

        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    /// @dev This low-level function should be called from a contract which performs important safety checks.
    function burn(
        address to
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    /// @dev This low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external override lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UniswapV2: INSUFFICIENT_LIQUIDITY"
        );

        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0)
                IUniswapV2Callee(to).uniswapV2Call(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint256 balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >=
                    uint256(_reserve0).mul(_reserve1).mul(1000 ** 2),
                "UniswapV2: K"
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    /// @dev Force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)).sub(reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)).sub(reserve1)
        );
    }

    /// @dev Force reserves to match balances
    function sync() external override lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    // Migrated over from UniswapV2ERC20. Needed for ^0.6.0
    // ===============================================

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(
        address spender,
        uint256 value
    ) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(
        address to,
        uint256 value
    ) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != uint256(int256(-1))) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "UniswapV2: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/IWETH.sol";
import "./TransferHelper.sol";
import "./UniswapV2Library.sol";
import "./Interfaces/IUniswapV2Factory.sol";
import "./Interfaces/IUniswapV2Router02.sol";

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint256;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "UniswapV2Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity)
    {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(
            amountA >= amountAMin,
            "UniswapV2Router: INSUFFICIENT_A_AMOUNT"
        );
        require(
            amountB >= amountBMin,
            "UniswapV2Router: INSUFFICIENT_B_AMOUNT"
        );
    }

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        override
        ensure(deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountA, uint256 amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        uint256 value = approveMax ? uint256(int256(-1)) : liquidity;
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        virtual
        override
        returns (uint256 amountToken, uint256 amountETH)
    {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(int256(-1)) : liquidity;
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountToken, amountETH) = removeLiquidityETH(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public virtual override ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(
            token,
            to,
            IERC20(token).balanceOf(address(this))
        );
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (uint256 amountETH) {
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        uint256 value = approveMax ? uint256(int256(-1)) : liquidity;
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token,
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }

    // **** SWAP ****
    /// @dev Requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (uint256[] memory amounts)
    {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= msg.value,
            "UniswapV2Router: EXCESSIVE_INPUT_AMOUNT"
        );
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amounts[0]
            )
        );
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0])
            TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    /// @dev Requires the initial amount to have already been sent to the first pair.
    function _swapSupportingFeeOnTransferTokens(
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output)
            );
            uint256 amountInput;
            uint256 amountOutput;
            {
                // scope to avoid stack too deep errors
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                (uint256 reserveInput, uint256 reserveOutput) = input == token0
                    ? (reserve0, reserve1)
                    : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(
                    reserveInput
                );
                amountOutput = UniswapV2Library.getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput
                );
            }
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amountIn
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >=
                amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        require(path[0] == WETH, "UniswapV2Router: INVALID_PATH");
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(
            IWETH(WETH).transfer(
                UniswapV2Library.pairFor(factory, path[0], path[1]),
                amountIn
            )
        );
        uint256 balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >=
                amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        require(path[path.length - 1] == WETH, "UniswapV2Router: INVALID_PATH");
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            UniswapV2Library.pairFor(factory, path[0], path[1]),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(
            amountOut >= amountOutMin,
            "UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountOut) {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual override returns (uint256 amountIn) {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint256 amountOut,
        address[] memory path
    ) public view virtual override returns (uint256[] memory amounts) {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// @dev computes square roots using the babylonian method
/// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./Babylonian.sol";

/// @dev A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(
        uq112x112 memory self,
        uint112 x
    ) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(
        uq112x112 memory self,
        uint256 y
    ) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(
            y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x),
            "FixedPoint: MULTIPLICATION_OVERFLOW"
        );
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(
        uint112 numerator,
        uint112 denominator
    ) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(
        uq112x112 memory self
    ) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(
        uq112x112 memory self
    ) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

// https://ethereum.stackexchange.com/a/69590
library MagnitudesAndPowers {
    function magnitude(uint256 x) public pure returns (uint256) {
        require(x > 0);

        uint256 a = 0;
        uint256 b = 77;

        while (b > a) {
            uint256 m = (a + b + 1) >> 1;
            if (x >= pow10(m)) a = m;
            else b = m - 1;
        }

        return a;
    }

    function pow10(uint256 x) private pure returns (uint256) {
        uint256 result = 1;
        uint256 y = 10;
        while (x > 0) {
            if (x % 2 == 1) {
                result *= y;
                x -= 1;
            } else {
                y *= y;
                x >>= 1;
            }
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2 ** 64, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2 ** 32, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2 ** 16, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2 ** 8, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= -2 ** 127 && value < 2 ** 127,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= -2 ** 63 && value < 2 ** 63,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= -2 ** 31 && value < 2 ** 31,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= -2 ** 15 && value < 2 ** 15,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= -2 ** 7 && value < 2 ** 7,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2 ** 255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10 ** uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10 ** uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10 ** uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(
        uint256 i
    ) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(
        uint256 i
    ) internal pure returns (uint256) {
        uint256 quotientTimesTen = i /
            (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// A library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
/// range: [0, 2**112 - 1]
/// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}