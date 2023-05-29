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

pragma solidity ^0.8.13;

interface IGovFactory {
  event ProjectCreated(address indexed project, uint256 index);

  function owner() external view returns (address);

  function komV() external view returns (address);

  function beacon() external view returns (address);

  function savior() external view returns (address);

  function saleGateway() external view returns (address);

  function operational() external view returns (address);

  function marketing() external view returns (address);

  function treasury() external view returns (address);

  function operationalPercentage_d2() external view returns (uint256);

  function marketingPercentage_d2() external view returns (uint256);

  function treasuryPercentage_d2() external view returns (uint256);

  function allProjectsLength() external view returns (uint256);

  function allPaymentsLength() external view returns (uint256);

  function allChainsStakedLength() external view returns (uint256);

  function allProjects(uint256) external view returns (address);

  function allPayments(uint256) external view returns (address);

  function allChainsStaked(uint256) external view returns (uint256);

  function getPaymentIndex(address) external view returns (uint256);

  function getChainStakedIndex(uint256) external view returns (uint256);

  function isKnown(address) external view returns (bool);

  function setPayment(address _token) external;

  function removePayment(address _token) external;

  function setChainStaked(uint256[] calldata _chainID) external;

  function removeChainStaked(uint256[] calldata _chainID) external;

  function config(
    address _komV,
    address _beacon,
    address _saleGateway,
    address _savior,
    address _operational,
    address _marketing,
    address _treasury
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IGovSaleRemote {
  function init(
    uint128 _start,
    uint128 _duration,
    uint256 _sale,
    uint256 _price,
    uint256[4] memory _fee_d2,
    address _payment,
    string[3] calldata _nameVersionMsg,
    uint128[2] calldata _voteStartEnd,
    uint128 _dstPaymentDecimals,
    address _targetSale
  ) external;

  function finalize(bytes calldata _salePayload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface ISaleGatewayRemote {
  function dstChain() external view returns (uint240 chainID, uint16 lzChainID, address saleGateway);

  function gasForDestinationLzReceive() external view returns (uint256);

  function crossFee_d2() external view returns (uint256);

  function estimateFees(bytes calldata _payload) external view returns (uint256 fees);

  function buyToken(bytes calldata _payload, uint256 _tax) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../interface/IGovFactory.sol';
import '../interface/ISaleGatewayRemote.sol';
import '../interface/IGovSaleRemote.sol';
import '../util/SaleLibrary.sol';

contract GovSaleRemote is
  Initializable,
  IGovSaleRemote,
  PausableUpgradeable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  uint256 public sold;
  uint256 public price; // in payment decimal

  uint128 public dstPaymentDecimals;
  uint128 public srcPaymentDecimals;

  uint256 public sale;
  uint256 public feeMoved;

  uint256 public raised; // sale amount get
  uint256 public revenue; // fee amount get

  uint256 public minFCFSBuy;
  uint256 public maxFCFSBuy;

  uint256 public minComBuy;
  uint256 public maxComBuy;

  uint256 public whitelistTotalAlloc;
  uint256 public voteTotalStaked;

  uint256 internal booster1Achieved;

  address[] public whitelists;
  address[] public stakers; // valid stakers only
  address[] public candidates;
  address[] public users; // valid buyers

  bool public isFinalized;
  address public targetSale;
  ISaleGatewayRemote public saleGateway;
  IGovFactory public factory;
  IERC20MetadataUpgradeable public payment;

  struct Round {
    uint128 start;
    uint128 end;
    uint256 fee_d2; // in percent 2 decimal
  }

  struct Summary {
    uint256 received; // token received
    uint256 bought; // payment given
    uint256 feeGiven;
  }

  mapping(uint128 => Round) public booster;

  mapping(uint240 => uint256) public chainStaked; // staked amount each chain
  mapping(uint240 => mapping(address => uint256)) public candidateChainStaked; // candidate staked amount each chain

  mapping(address => uint256) public stakerIndex; // staker index
  mapping(address => uint256) public whitelist; // whitelist amount

  mapping(address => bool) public isUser;

  mapping(address => string) public recipient;
  mapping(address => Summary) public summaries;
  mapping(address => mapping(uint128 => uint256)) public purchasedPerRound;

  // ========  vote
  bytes32 internal constant FORM_TYPEHASH = keccak256('Form(address from,string content)');

  uint128 public voteStart;
  uint128 public voteEnd;

  bytes32 public DOMAIN_SEPARATOR;
  string public name;
  string public version;
  string public message;

  mapping(address => bool) public isVoteValid;

  struct Form {
    address from;
    string content;
  }
  // ========  vote

  event TokenBought(
    uint128 indexed booster,
    address indexed user,
    uint256 tokenReceived,
    uint256 buyAmount,
    uint256 feeCharged
  );

  event Finalize(uint256 remoteRaised, uint256 remoteRevenue, uint256 remoteSold);

  /**
   * @dev Initialize project for raise fund
   * @param _start Epoch date to start round 1
   * @param _duration Duration per booster (in seconds)
   * @param _sale Amount token project to sell (based on token decimals of project)
   * @param _price Token project price in payment decimal
   * @param _fee_d2 Fee project percent in each rounds in 2 decimal
   * @param _payment Tokens to raise
   * @param _targetSale Tokens to raise
   */
  function init(
    uint128 _start,
    uint128 _duration,
    uint256 _sale,
    uint256 _price,
    uint256[4] memory _fee_d2,
    address _payment,
    string[3] calldata _nameVersionMsg,
    uint128[2] calldata _voteStartEnd,
    uint128 _dstPaymentDecimals,
    address _targetSale
  ) external initializer {
    __Pausable_init();
    __ReentrancyGuard_init();

    sale = _sale;
    price = _price;
    payment = IERC20MetadataUpgradeable(_payment);
    message = _nameVersionMsg[2];
    voteStart = _voteStartEnd[0];
    voteEnd = _voteStartEnd[1];
    dstPaymentDecimals = _dstPaymentDecimals;
    targetSale = _targetSale;

    factory = IGovFactory(_msgSender());
    saleGateway = ISaleGatewayRemote(factory.saleGateway());
    srcPaymentDecimals = payment.decimals();

    _createDomain(_nameVersionMsg[0], _nameVersionMsg[1]);
    _transferOwnership(factory.owner());

    uint128 i = 1;
    do {
      if (i == 1) {
        booster[i].start = _start;
      } else {
        booster[i].start = booster[i - 1].end + 1;
      }
      if (i < 4) booster[i].end = booster[i].start + _duration;
      booster[i].fee_d2 = _fee_d2[i - 1];

      ++i;
    } while (i <= 4);
  }

  // **** VIEW AREA ****

  /**
   * @dev Get all buyers/participants length
   */
  function usersLength() external view virtual returns (uint256) {
    return users.length;
  }

  /**
   * @dev Get all stakers length
   */
  function stakersLength() external view virtual returns (uint256) {
    return stakers.length;
  }

  /**
   * @dev Get all whitelists length
   */
  function whitelistsLength() external view virtual returns (uint256) {
    return whitelists.length;
  }

  /**
   * @dev Get all candidates length
   */
  function candidatesLength() external view virtual returns (uint256) {
    return candidates.length;
  }

  /**
   * @dev Get booster running now, 0 = no booster running
   */
  function boosterProgress() public view virtual returns (uint128 running) {
    for (uint128 i = 1; i <= 4; ++i) {
      if (
        (uint128(block.timestamp) >= booster[i].start && uint128(block.timestamp) <= booster[i].end) ||
        (i == 4 && uint128(block.timestamp) >= booster[i].start)
      ) {
        running = i;
        break;
      }
    }
  }

  /**
   * @dev Get payload
   * @param _amountIn Amount to buy
   * @param _user User address
   */
  function _payload(uint256 _amountIn, address _user) internal view virtual returns (bytes memory payload) {
    // change to 6 decimal
    _amountIn = (_amountIn * (10 ** dstPaymentDecimals)) / 10 ** srcPaymentDecimals;
    payload = abi.encode(uint240(block.chainid), targetSale, _amountIn, _user);
  }

  /**
   * @dev Estimate cross chain fees
   * @param _amountIn Amount to buy
   * @param _user User address
   */
  function estimateCrossFee(uint256 _amountIn, address _user) public view virtual returns (uint256 fees, uint256 tax) {
    fees = saleGateway.estimateFees(_payload(_amountIn, _user));
    tax = SaleLibrary.calcPercent2Decimal(saleGateway.crossFee_d2(), fees);
  }

  /**
   * @dev Get User Total Staked Kom
   * @param _user User address
   */
  function candidateTotalStaked(address _user) public view virtual returns (uint256 userTotalStakedAmount) {
    uint256 chainStakedLength = factory.allChainsStakedLength();
    for (uint256 i = 0; i < chainStakedLength; ++i) {
      userTotalStakedAmount += candidateChainStaked[uint240(factory.allChainsStaked(i))][_user];
    }
  }

  function _formatOrigin(uint256 _amount) internal view virtual returns (uint256 result) {
    result = (_amount * (10 ** srcPaymentDecimals)) / 10 ** dstPaymentDecimals;
  }

  /**
   * @dev Get User Total Staked Allocation
   * @param _user User address
   * @param _boosterRunning Booster progress
   */
  function calcUserAllocation(address _user, uint128 _boosterRunning) public view virtual returns (uint256 userAlloc) {
    uint256 saleAmount = sale;
    uint256 candidateStakedToken = candidateTotalStaked(_user);
    bool isVoter = isVoteValid[_user];

    if (_boosterRunning == 1) {
      if (candidateStakedToken > 0 && isVoter) {
        userAlloc = SaleLibrary.calcAllocFromKom(
          candidateStakedToken,
          voteTotalStaked,
          saleAmount - whitelistTotalAlloc
        );
      }

      uint256 whitelistAmount = whitelist[_user];

      if (whitelistAmount > 0) userAlloc += whitelistAmount;
    } else if (_boosterRunning == 2) {
      if (uint128(block.timestamp) >= booster[2].start && candidateStakedToken > 0 && isVoter) {
        userAlloc = SaleLibrary.calcAllocFromKom(candidateStakedToken, voteTotalStaked, saleAmount - booster1Achieved);
      }
    } else if (_boosterRunning == 3) {
      if ((stakers.length > 0 && stakers[stakerIndex[_user]] == _user) || whitelist[_user] > 0) userAlloc = maxFCFSBuy;
    } else if (_boosterRunning == 4) {
      userAlloc = maxComBuy;
    }
  }

  /**
   * @dev Calculate amount in
   * @param _tokenReceived Token received amount
   * @param _user User address
   * @param _running Booster running
   * @param _boosterPrice Booster running price
   */
  function _amountInCalc(
    uint256 _alloc,
    uint256 _tokenReceived,
    address _user,
    uint128 _running,
    uint256 _boosterPrice
  ) internal view virtual returns (uint256 amountInFinal, uint256 tokenReceivedFinal) {
    uint256 left = sale - sold;

    if (_tokenReceived > left) _tokenReceived = left;

    amountInFinal = SaleLibrary.calcAmountIn(_tokenReceived, _boosterPrice);

    if (_running == 3) {
      require(maxFCFSBuy > 0 && _tokenReceived >= minFCFSBuy, '<min');
    } else if (_running == 4) {
      require(maxComBuy > 0 && _tokenReceived >= minComBuy, '<min');
    }

    uint256 purchaseThisRound = purchasedPerRound[_user][_running];

    if (purchaseThisRound + _tokenReceived > _alloc)
      amountInFinal = SaleLibrary.calcAmountIn(_alloc - purchaseThisRound, _boosterPrice);

    require(purchaseThisRound < _alloc && amountInFinal > 0, 'nope');

    tokenReceivedFinal = SaleLibrary.calcTokenReceived(amountInFinal, _boosterPrice);
  }

  function _isEligible() internal view virtual {
    require((_msgSender() == factory.savior() || _msgSender() == owner()), '??');
  }

  function _isSufficient(uint256 _amount) internal view virtual {
    require(payment.balanceOf(address(this)) >= _amount, 'less');
  }

  function _isNotStarted() internal view virtual {
    require(uint128(block.timestamp) < booster[1].start, 'started');
  }

  // **** MAIN AREA ****

  function _releaseToken(address _target, uint256 _amount) internal virtual {
    payment.safeTransfer(_target, _amount);
  }

  /**
   * @dev Move raised fund to devAddr/project owner
   */
  function moveFund(uint256 _percent_d2, bool _devAddr, address _target) external virtual {
    _isEligible();

    uint256 amount = SaleLibrary.calcPercent2Decimal(raised, _percent_d2);

    _isSufficient(amount);
    require(isFinalized, 'bad');

    if (_devAddr) {
      _releaseToken(factory.operational(), amount);
    } else {
      _releaseToken(_target, amount);
    }
  }

  function forceMoveFund() external virtual {
    _isEligible();

    _releaseToken(factory.operational(), payment.balanceOf(address(this)));
  }

  /**
   * @dev Move fee to devAddr
   */
  function moveFee() external virtual {
    _isEligible();

    uint256 amount = revenue;
    uint256 left = amount - feeMoved;

    _isSufficient(left);

    require(left > 0 && isFinalized, 'bad');

    feeMoved = amount;

    _releaseToken(factory.operational(), SaleLibrary.calcPercent2Decimal(left, factory.operationalPercentage_d2()));
    _releaseToken(factory.marketing(), SaleLibrary.calcPercent2Decimal(left, factory.marketingPercentage_d2()));
    _releaseToken(factory.treasury(), SaleLibrary.calcPercent2Decimal(left, factory.treasuryPercentage_d2()));
  }

  /**
   * @dev Buy token project using token raise
   * @param _amountIn Buy amount
   */
  function buyToken(uint256 _amountIn) external payable virtual whenNotPaused nonReentrant {
    address user = _msgSender();
    uint128 running = boosterProgress();
    require(running > 0, '!booster');

    if (running < 3) require(voteTotalStaked > 0, '!voteStaked');

    uint256 calcAllocation = calcUserAllocation(user, running);
    require(calcAllocation > 0, '!eligible');

    uint256 boosterPrice = price;

    (uint256 amountInFinal, uint256 tokenReceivedFinal) = _amountInCalc(
      calcAllocation,
      SaleLibrary.calcTokenReceived(_amountIn, boosterPrice),
      user,
      running,
      boosterPrice
    );

    (uint256 crossFee, uint256 crossTax) = estimateCrossFee(amountInFinal, user);
    uint256 crossFeeNeeded = crossFee + crossTax;
    uint256 crossFeeIn = msg.value;

    require(crossFeeIn >= crossFeeNeeded, '!crossFee');

    uint256 feeCharged;
    if (whitelist[user] == 0) feeCharged = SaleLibrary.calcPercent2Decimal(amountInFinal, booster[running].fee_d2);

    raised += amountInFinal;
    revenue += feeCharged;
    sold += tokenReceivedFinal;
    if (running == 1) booster1Achieved += tokenReceivedFinal;

    summaries[user].received += tokenReceivedFinal;
    summaries[user].bought += amountInFinal;
    summaries[user].feeGiven += feeCharged;

    if (!isUser[user]) {
      isUser[user] = true;
      users.push(user);
    }

    if (crossFeeIn > crossFeeNeeded) {
      (bool success, ) = payable(user).call{value: crossFeeIn - crossFeeNeeded}('');
      require(success, 'fail');
    }

    payment.safeTransferFrom(user, address(this), amountInFinal + feeCharged);
    saleGateway.buyToken{value: crossFeeNeeded}(_payload(amountInFinal, user), crossTax);

    emit TokenBought(running, user, tokenReceivedFinal, amountInFinal, feeCharged);
  }

  function finalize(bytes memory _salePayload) external virtual whenPaused {
    require(_msgSender() == owner(), '!caller');

    (
      uint240 chainID,
      uint256 remoteRaised,
      uint256 remoteRevenue,
      uint256 remoteSold,
      address[] memory remoteUsers,
      uint256[] memory remoteUsersBought,
      uint256[] memory remoteUsersReceived,
      uint256[] memory remoteUsersFee
    ) = abi.decode(_salePayload, (uint240, uint256, uint256, uint256, address[], uint256[], uint256[], uint256[]));

    require(chainID == uint240(block.chainid), '!chainID');

    raised = _formatOrigin(remoteRaised);
    revenue = _formatOrigin(remoteRevenue);
    sold = remoteSold;

    for (uint256 i = 0; i < remoteUsers.length; ++i) {
      address user = remoteUsers[i];
      uint256 remoteBought = _formatOrigin(remoteUsersBought[i]);
      uint256 remoteFee = _formatOrigin(remoteUsersFee[i]);
      Summary memory summary = summaries[user];

      uint256 payback;
      if (summary.bought > remoteBought) payback = summary.bought - remoteBought;

      uint256 finalFee = remoteFee;
      if (summary.feeGiven > remoteFee) {
        uint256 diff = summary.feeGiven - remoteFee;
        payback += diff;
      } else {
        finalFee = summary.feeGiven;
      }

      summaries[user] = Summary(remoteUsersReceived[i], remoteBought, finalFee);
      if (payback > 0) _releaseToken(user, payback);
    }

    isFinalized = true;

    emit Finalize(raised, revenue, sold);
  }

  /**
   * @dev Set recipient address
   * @param _recipient Recipient address
   */
  function setRecipient(string memory _recipient) external virtual whenNotPaused {
    require(boosterProgress() > 0 && bytes(_recipient).length > 0, 'bad');

    recipient[_msgSender()] = _recipient;
  }

  // **** ADMIN AREA ****

  function setStakers(address[] calldata _users) external virtual onlyOwner {
    _isNotStarted();

    for (uint256 i = 0; i < _users.length; ++i) {
      if (stakers.length > 0 && stakers[stakerIndex[_users[i]]] == _users[i]) continue;

      stakerIndex[_users[i]] = stakers.length;
      stakers.push(_users[i]);
    }
  }

  /**
   * @dev Set user total KOM staked
   * @param _users User address
   */
  function setCandidateChainStaked(
    uint240 _chainID,
    address[] calldata _users,
    uint256[] calldata _stakedAmount
  ) external virtual onlyOwner {
    _isNotStarted();

    uint240 chainID = uint240(factory.allChainsStaked(factory.getChainStakedIndex(_chainID)));

    require(_chainID == chainID && _users.length == _stakedAmount.length, 'bad');

    for (uint256 i = 0; i < _users.length; ++i) {
      if (stakers[stakerIndex[_users[i]]] != _users[i] || candidateChainStaked[_chainID][_users[i]] > 0) continue;

      candidateChainStaked[_chainID][_users[i]] = _stakedAmount[i];
      chainStaked[_chainID] += _stakedAmount[i];
    }
  }

  function resetCandidateChainStaked(uint240 _chainID, address[] calldata _users) external virtual onlyOwner {
    _isNotStarted();

    uint240 chainID = uint240(factory.allChainsStaked(factory.getChainStakedIndex(_chainID)));

    require(_chainID == chainID, '!chainID');

    for (uint256 i = 0; i < _users.length; ++i) {
      if (stakers[stakerIndex[_users[i]]] != _users[i] || candidateChainStaked[_chainID][_users[i]] == 0) continue;

      chainStaked[_chainID] -= candidateChainStaked[_chainID][_users[i]];
      delete candidateChainStaked[_chainID][_users[i]];
    }
  }

  /**
   * @dev Set whitelist allocation token in 6 decimal
   * @param _user User address
   * @param _allocation Token allocation in 6 decimal
   */
  function setWhitelist_d6(address[] calldata _user, uint256[] calldata _allocation) external virtual onlyOwner {
    _isNotStarted();
    require(_user.length == _allocation.length, 'bad');

    uint256 whitelistTotal = whitelistTotalAlloc;
    for (uint256 i = 0; i < _user.length; ++i) {
      if (whitelist[_user[i]] > 0) continue;

      whitelists.push(_user[i]);
      whitelist[_user[i]] = SaleLibrary.calcWhitelist6Decimal(_allocation[i]);
      whitelistTotal += whitelist[_user[i]];
    }

    whitelistTotalAlloc = whitelistTotal;
  }

  /**
   * @dev Update whitelist allocation token in 6 decimal
   * @param _user User address
   * @param _allocation Token allocation in 6 decimal
   */
  function updateWhitelist_d6(address[] calldata _user, uint256[] calldata _allocation) external virtual onlyOwner {
    _isNotStarted();
    require(_user.length == _allocation.length, 'bad');

    uint256 whitelistTotal = whitelistTotalAlloc;
    for (uint256 i = 0; i < _user.length; ++i) {
      if (whitelist[_user[i]] == 0) continue;

      uint256 oldAlloc = whitelist[_user[i]];
      whitelist[_user[i]] = SaleLibrary.calcWhitelist6Decimal(_allocation[i]);
      whitelistTotal = whitelistTotal - oldAlloc + whitelist[_user[i]];
    }

    whitelistTotalAlloc = whitelistTotal;
  }

  function removePurchase(address _user) external virtual onlyOwner {
    require(boosterProgress() == 4 && paused(), 'bad');

    Summary memory summary = summaries[_user];

    delete summaries[_user];

    if (!isFinalized) {
      raised -= summary.bought;
      revenue -= summary.feeGiven;
      sold -= summary.received;
    }

    _releaseToken(_user, summary.bought + summary.feeGiven);
  }

  /**
   * @dev Set Min & Max in FCFS
   * @param _minMaxFCFSBuy Min and max token to buy
   */
  function setMinMaxFCFS(uint256[2] calldata _minMaxFCFSBuy) external virtual onlyOwner {
    if (boosterProgress() < 3) minFCFSBuy = _minMaxFCFSBuy[0];
    maxFCFSBuy = _minMaxFCFSBuy[1];
  }

  /**
   * @dev Set Min & Max in Community Round
   * @param _minMaxComBuy Min and max token to buy
   */
  function setMinMaxCom(uint256[2] calldata _minMaxComBuy) external virtual onlyOwner {
    if (boosterProgress() < 4) minComBuy = _minMaxComBuy[0];
    maxComBuy = _minMaxComBuy[1];
  }

  /**
   * @dev Config sale data
   * @param _sale Amount token project to sell (based on token decimals of project)
   * @param _price Token project price in payment decimal
   * @param _fee_d2 Fee project percent in each rounds in 2 decimal
   * @param _payment Tokens to raise
   */
  function config(
    uint256 _sale,
    uint256 _price,
    uint256[4] memory _fee_d2,
    address _payment,
    uint128 _dstPaymentDecimals
  ) external virtual onlyOwner {
    require(uint128(block.timestamp) < booster[1].start, 'started');

    payment = IERC20MetadataUpgradeable(_payment);
    sale = _sale;
    price = _price;
    dstPaymentDecimals = _dstPaymentDecimals;
    srcPaymentDecimals = payment.decimals();

    uint128 i = 1;
    do {
      booster[i].fee_d2 = _fee_d2[i - 1];

      ++i;
    } while (i <= 4);
  }

  function updateStart(uint128 _start, uint128 _duration) external virtual onlyOwner {
    _isNotStarted();
    uint128 i = 1;
    do {
      if (i == 1) {
        booster[i].start = _start;
      } else {
        booster[i].start = booster[i - 1].end + 1;
      }
      if (i < 4) booster[i].end = booster[i].start + _duration;

      ++i;
    } while (i <= 4);
  }

  function setTargetSale(address _targetSale) external virtual onlyOwner {
    targetSale = _targetSale;
  }

  /**
   * @dev Toggle buyToken pause
   */
  function togglePause() external virtual onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  // ======= vote
  function _createDomain(string memory _name, string memory _version) internal virtual {
    require(bytes(_name).length > 0 && bytes(_version).length > 0, 'bad');

    name = _name;
    version = _version;

    (uint240 chainId, , ) = saleGateway.dstChain();

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
        keccak256(bytes(_name)),
        keccak256(bytes(_version)),
        uint256(chainId),
        targetSale
      )
    );
  }

  function _hash(Form memory form) internal pure virtual returns (bytes32) {
    return keccak256(abi.encode(FORM_TYPEHASH, form.from, keccak256(bytes(form.content))));
  }

  function verify(address _from, bytes memory _signature) public view virtual returns (bool) {
    if (_signature.length != 65) return false;

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(_signature, 0x20))
      s := mload(add(_signature, 0x40))
      v := byte(0, mload(add(_signature, 0x60)))
    }

    Form memory form = Form({from: _from, content: message});

    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, _hash(form)));

    if (v != 27 && v != 28) v += 27;

    return ecrecover(digest, v, r, s) == _from;
  }

  /**
   * @dev Migrate candidates from gov contract
   * @param _users Candidate address
   * param _signatures Candidate's signature
   * param _votedAt Candidate's voted at in unix time
   */
  function migrateCandidates(
    address[] calldata _users,
    bytes[] calldata _signatures,
    uint128[] calldata _votedAt
  ) external virtual onlyOwner {
    _isNotStarted();

    require(
      stakers.length > 0 &&
        _users.length == _signatures.length &&
        _users.length == _votedAt.length &&
        block.timestamp > voteEnd,
      'bad'
    );
    address komV = factory.komV();

    uint256 voteStaked = voteTotalStaked;

    for (uint256 i = 0; i < _users.length; ++i) {
      if (
        isVoteValid[_users[i]] ||
        !verify(_users[i], _signatures[i]) ||
        (komV != address(0) &&
          IERC20Upgradeable(komV).balanceOf(_users[i]) == 0 &&
          stakers[stakerIndex[_users[i]]] != _users[i]) ||
        _votedAt[i] < voteStart ||
        _votedAt[i] > voteEnd
      ) continue;

      voteStaked += candidateTotalStaked(_users[i]);
      isVoteValid[_users[i]] = true;
      candidates.push(_users[i]);
    }
    voteTotalStaked = voteStaked;
  }

  function updateVoteStart(uint128 _voteStart) external virtual onlyOwner {
    require(_voteStart > 0 && _voteStart != voteStart && block.timestamp < voteStart, 'bad');
    voteStart = _voteStart;
  }

  function updateVoteEnd(uint128 _voteEnd) external virtual onlyOwner {
    require(_voteEnd > 0 && _voteEnd != voteEnd && block.timestamp < voteEnd, 'bad');
    voteEnd = _voteEnd;
  }
  // ======= vote
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library SaleLibrary {
  function calcPercent2Decimal(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return (_a * _b) / 1e4;
  }

  function calcAllocFromKom(uint256 _staked, uint256 _totalStaked, uint256 _sale) internal pure returns (uint256) {
    return (((_staked * 1e8) / _totalStaked) * _sale) / 1e8;
  }

  function calcTokenReceived(uint256 _amountIn, uint256 _price) internal pure returns (uint256) {
    return (_amountIn * 1e18) / _price;
  }

  function calcAmountIn(uint256 _received, uint256 _price) internal pure returns (uint256) {
    return (_received * _price) / 1e18;
  }

  function calcWhitelist6Decimal(uint256 _allocation) internal pure returns (uint256) {
    return (_allocation * 1e18) / 1e6;
  }
}