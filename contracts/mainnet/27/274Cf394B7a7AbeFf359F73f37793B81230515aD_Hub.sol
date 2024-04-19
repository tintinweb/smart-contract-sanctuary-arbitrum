// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    /// @custom:storage-location erc7201:openzeppelin.storage.Pausable
    struct PausableStorage {
        bool _paused;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Pausable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableStorageLocation = 0xcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300;

    function _getPausableStorage() private pure returns (PausableStorage storage $) {
        assembly {
            $.slot := PausableStorageLocation
        }
    }

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
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
        PausableStorage storage $ = _getPausableStorage();
        return $._paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage storage $ = _getPausableStorage();
        $._paused = true;
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
        PausableStorage storage $ = _getPausableStorage();
        $._paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
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

    /// @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdatesUnique(
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
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

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/ITokenBridge.sol";
import "./interfaces/CCTPInterfaces/ITokenMessenger.sol";
import "./interfaces/CCTPInterfaces/IMessageTransmitter.sol";

import "./Utils.sol";
import {TokenBase} from "./WormholeRelayerSDK.sol";

library CCTPMessageLib {
    uint8 constant CCTP_KEY_TYPE = 2;

    // encoded using abi.encodePacked(domain, nonce)
    struct CCTPKey {
        uint32 domain;
        uint64 nonce;
    }

    // encoded using abi.encode(message, signature)
    struct CCTPMessage {
        bytes message;
        bytes signature;
    }
}

abstract contract CCTPBase is TokenBase {
    ITokenMessenger public circleTokenMessenger;
    IMessageTransmitter public circleMessageTransmitter;
    address public USDC;

    function __CCTPBase_init(
        address _wormholeRelayer,
        address _tokenBridge,
        address _wormhole,
        address _circleMessageTransmitter,
        address _circleTokenMessenger,
        address _USDC
    ) public {
        require(!_wormholeRelayerInitialized, "WRI");
        TokenBase.__TokenBase_init(_wormholeRelayer, _tokenBridge, _wormhole);
        circleTokenMessenger = ITokenMessenger(_circleTokenMessenger);
        circleMessageTransmitter = IMessageTransmitter(_circleMessageTransmitter);
        USDC = _USDC;
    }

    function getCCTPDomain(uint16 chain) internal pure returns (uint32) {
        if (chain == 2 || chain == 10002) {
            return 0;
        } else if (chain == 6) {
            return 1;
        } else if (chain == 23 || chain == 10003) {
            return 3;
        } else if (chain == 24 || chain == 10005) {
            return 2;
        } else if (chain == 30 || chain == 10004) {
            return 6;
        } else {
            revert("Wrong CCTP Domain");
        }
    }

    function redeemUSDC(bytes memory cctpMessage) internal returns (uint256 amount) {
        (bytes memory message, bytes memory signature) = abi.decode(cctpMessage, (bytes, bytes));
        uint256 beforeBalance = IERC20(USDC).balanceOf(address(this));
        circleMessageTransmitter.receiveMessage(message, signature);
        return IERC20(USDC).balanceOf(address(this)) - beforeBalance;
    }
}

abstract contract CCTPSender is CCTPBase {
    uint8 internal constant CONSISTENCY_LEVEL_FINALIZED = 15;

    using CCTPMessageLib for *;

    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this requires that only the targetAddress can redeem transfers.
     *
     */

    function transferUSDC(uint256 amount, uint16 targetChain, address targetAddress)
        internal
        returns (MessageKey memory)
    {
        SafeERC20.forceApprove(IERC20(USDC), address(circleTokenMessenger), amount);
        uint64 nonce = circleTokenMessenger.depositForBurnWithCaller(
            amount,
            getCCTPDomain(targetChain),
            addressToBytes32CCTP(targetAddress),
            USDC,
            addressToBytes32CCTP(targetAddress)
        );
        return MessageKey(
            CCTPMessageLib.CCTP_KEY_TYPE, abi.encodePacked(getCCTPDomain(wormhole.chainId()), nonce)
        );
    }

    function sendUSDCWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint256 amount,
        uint16 refundChain,
        address refundAddress
    ) internal returns (uint64 sequence) {
        MessageKey[] memory messageKeys = new MessageKey[](1);
        messageKeys[0] = transferUSDC(amount, targetChain, targetAddress);

        address defaultDeliveryProvider = wormholeRelayer.getDefaultDeliveryProvider();

        (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit);

        sequence = wormholeRelayer.sendToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(amount, payload),
            receiverValue,
            0,
            gasLimit,
            refundChain,
            refundAddress,
            defaultDeliveryProvider,
            messageKeys,
            CONSISTENCY_LEVEL_FINALIZED
        );
    }

    function addressToBytes32CCTP(address addr) private pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}

abstract contract CCTPReceiver is CCTPBase {
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalMessages,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external virtual payable {
        _receiveWormholeMessagesWithCCTP(payload, additionalMessages, sourceAddress, sourceChain, deliveryHash);
    }

    function _receiveWormholeMessagesWithCCTP(
        bytes memory payload,
        bytes[] memory additionalMessages,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal {
        require(additionalMessages.length <= 1, "CCTP: At most one Message is supported");

        uint256 amountUSDCReceived;
        if (additionalMessages.length == 1) {
            amountUSDCReceived = redeemUSDC(additionalMessages[0]);
        }

        (uint256 amount, bytes memory userPayload) = abi.decode(payload, (uint256, bytes));

        // Check that the correct amount was received
        // It is important to verify that the 'USDC' received is
        require(amount == amountUSDCReceived, "Wrong amount received");

        receivePayloadAndUSDC(userPayload, amountUSDCReceived, sourceAddress, sourceChain, deliveryHash);
    }

    function receivePayloadAndUSDC(
        bytes memory payload,
        uint256 amountUSDCReceived,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}
}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

import "./IRelayer.sol";
import "./IReceiver.sol";

/**
 * @title IMessageTransmitter
 * @notice Interface for message transmitters, which both relay and receive messages.
 */
interface IMessageTransmitter is IRelayer, IReceiver {

}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

/**
 * @title IReceiver
 * @notice Receives messages on destination chain and forwards them to IMessageDestinationHandler
 */
interface IReceiver {
    /**
     * @notice Receives an incoming message, validating the header and passing
     * the body to application-specific handler.
     * @param message The message raw bytes
     * @param signature The message signature
     * @return success bool, true if successful
     */
    function receiveMessage(bytes calldata message, bytes calldata signature)
        external
        returns (bool success);
}

/*
 * Copyright (c) 2022, Circle Internet Financial Limited.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

/**
 * @title IRelayer
 * @notice Sends messages from source domain to destination domain
 */
interface IRelayer {
    /**
     * @notice Sends an outgoing message from the source domain.
     * @dev Increment nonce, format the message, and emit `MessageSent` event with message information.
     * @param destinationDomain Domain of destination chain
     * @param recipient Address of message recipient on destination domain as bytes32
     * @param messageBody Raw bytes content of message
     * @return nonce reserved by message
     */
    function sendMessage(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata messageBody
    ) external returns (uint64);

    /**
     * @notice Sends an outgoing message from the source domain, with a specified caller on the
     * destination domain.
     * @dev Increment nonce, format the message, and emit `MessageSent` event with message information.
     * WARNING: if the `destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * sendMessage() should be preferred for use cases where a specific destination caller is not required.
     * @param destinationDomain Domain of destination chain
     * @param recipient Address of message recipient on destination domain as bytes32
     * @param destinationCaller caller on the destination domain, as bytes32
     * @param messageBody Raw bytes content of message
     * @return nonce reserved by message
     */
    function sendMessageWithCaller(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes32 destinationCaller,
        bytes calldata messageBody
    ) external returns (uint64);

    /**
     * @notice Replace a message with a new message body and/or destination caller.
     * @dev The `originalAttestation` must be a valid attestation of `originalMessage`.
     * @param originalMessage original message to replace
     * @param originalAttestation attestation of `originalMessage`
     * @param newMessageBody new message body of replaced message
     * @param newDestinationCaller the new destination caller
     */
    function replaceMessage(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes calldata newMessageBody,
        bytes32 newDestinationCaller
    ) external;
}

pragma solidity ^0.8.0;

interface ITokenMessenger {
   /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `destinationCaller`.
     * WARNING: if the `destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no TokenMessenger registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param amount amount of tokens to burn
     * @param destinationDomain destination domain
     * @param mintRecipient address of mint recipient on destination domain
     * @param burnToken address of contract to burn deposited tokens, on local domain
     * @param destinationCaller caller on the destination domain, as bytes32
     * @return nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 amount,
        uint32 destinationDomain,
        bytes32 mintRecipient,
        address burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 nonce);
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./IWETH.sol";
import "./IWormhole.sol";

interface ITokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

    struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    function _parseTransferCommon(bytes memory encoded) external pure returns (Transfer memory transfer);

    function attestToken(address tokenAddress, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce)
        external
        payable
        returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload)
        external
        payable
        returns (uint64 sequence);

    function transferTokens(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint256 arbiterFee,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    function updateWrapped(bytes memory encodedVm) external returns (address token);

    function createWrapped(bytes memory encodedVm) external returns (address token);

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(AssetMeta memory meta) external pure returns (bytes memory encoded);

    function encodeTransfer(Transfer memory transfer) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(TransferWithPayload memory transfer)
        external
        pure
        returns (bytes memory encoded);

    function parsePayloadID(bytes memory encoded) external pure returns (uint8 payloadID);

    function parseAssetMeta(bytes memory encoded) external pure returns (AssetMeta memory meta);

    function parseTransfer(bytes memory encoded) external pure returns (Transfer memory transfer);

    function parseTransferWithPayload(bytes memory encoded)
        external
        pure
        returns (TransferWithPayload memory transfer);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function evmChainId() external view returns (uint256);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function bridgeContracts(uint16 chainId_) external view returns (bytes32);

    function tokenImplementation() external view returns (address);

    function WETH() external view returns (IWETH);

    function outstandingBridged(address token) external view returns (uint256);

    function isWrappedAsset(address token) external view returns (bool);

    function finality() external view returns (uint8);

    function implementation() external view returns (address);

    function initialize() external;

    function registerChain(bytes memory encodedVM) external;

    function upgrade(bytes memory encodedVM) external;

    function submitRecoverChainId(bytes memory encodedVM) external;

    function parseRegisterChain(bytes memory encoded) external pure returns (RegisterChain memory chain);

    function parseUpgrade(bytes memory encoded) external pure returns (UpgradeContract memory chain);

    function parseRecoverChainId(bytes memory encodedRecoverChainId)
        external
        pure
        returns (RecoverChainId memory rci);
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;
        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;
        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(
        address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel
    );
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel)
        external
        payable
        returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet)
        external
        pure
        returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint256 numGuardians) external pure returns (uint256 numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade)
        external
        pure
        returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId)
        external
        pure
        returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @notice Interface for a contract which can receive Wormhole messages.
 */
interface IWormholeReceiver {
    /**
     * @notice When a `send` is performed with this contract as the target, this function will be
     *     invoked by the WormholeRelayer contract
     *
     * NOTE: This function should be restricted such that only the Wormhole Relayer contract can call it.
     *
     * We also recommend that this function:
     *   - Stores all received `deliveryHash`s in a mapping `(bytes32 => bool)`, and
     *       on every call, checks that deliveryHash has not already been stored in the
     *       map (This is to prevent other users maliciously trying to relay the same message)
     *   - Checks that `sourceChain` and `sourceAddress` are indeed who
     *       you expect to have requested the calling of `send` on the source chain
     *
     * The invocation of this function corresponding to the `send` request will have msg.value equal
     *   to the receiverValue specified in the send request.
     *
     * If the invocation of this function reverts or exceeds the gas limit
     *   specified by the send requester, this delivery will result in a `ReceiverFailure`.
     *
     * @param payload - an arbitrary message which was included in the delivery by the
     *     requester.
     * @param additionalVaas - Additional VAAs which were requested to be included in this delivery.
     *   They are guaranteed to all be included and in the same order as was specified in the
     *     delivery request.
     * @param sourceAddress - the (wormhole format) address on the sending chain which requested
     *     this delivery.
     * @param sourceChain - the wormhole chain ID where this delivery was requested.
     * @param deliveryHash - the VAA hash of the deliveryVAA.
     *
     * NOTE: These signedVaas are NOT verified by the Wormhole core contract prior to being provided
     *     to this call. Always make sure `parseAndVerify()` is called on the Wormhole core contract
     *     before trusting the content of a raw VAA, otherwise the VAA may be invalid or malicious.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

/**
 * @title WormholeRelayer
 * @author
 * @notice This project allows developers to build cross-chain applications powered by Wormhole without needing to
 * write and run their own relaying infrastructure
 *
 * We implement the IWormholeRelayer interface that allows users to request a delivery provider to relay a payload (and/or additional VAAs)
 * to a chain and address of their choice.
 */

/**
 * @notice VaaKey identifies a wormhole message
 *
 * @custom:member chainId Wormhole chain ID of the chain where this VAA was emitted from
 * @custom:member emitterAddress Address of the emitter of the VAA, in Wormhole bytes32 format
 * @custom:member sequence Sequence number of the VAA
 */
struct VaaKey {
    uint16 chainId;
    bytes32 emitterAddress;
    uint64 sequence;
}

// 0-127 are reserved for standardized KeyTypes, 128-255 are for custom use
uint8 constant VAA_KEY_TYPE = 1;

struct MessageKey {
    uint8 keyType; // 0-127 are reserved for standardized KeyTypes, 128-255 are for custom use
    bytes encodedKey;
}


interface IWormholeRelayerBase {
    event SendEvent(
        uint64 indexed sequence, uint256 deliveryQuote, uint256 paymentForExtraReceiverValue
    );

    function getRegisteredWormholeRelayerContract(uint16 chainId) external view returns (bytes32);

    /**
     * @notice Returns true if a delivery has been attempted for the given deliveryHash
     * Note: invalid deliveries where the tx reverts are not considered attempted
     */
    function deliveryAttempted(bytes32 deliveryHash) external view returns (bool attempted);

    /**
     * @notice block number at which a delivery was successfully executed
     */
    function deliverySuccessBlock(bytes32 deliveryHash) external view returns (uint256 blockNumber);

    /**
     * @notice block number of the latest attempt to execute a delivery that failed
     */
    function deliveryFailureBlock(bytes32 deliveryHash) external view returns (uint256 blockNumber);
}

/**
 * @title IWormholeRelayerSend
 * @notice The interface to request deliveries
 */
interface IWormholeRelayerSend is IWormholeRelayerBase {

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendPayloadToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * Any refunds (from leftover gas) will be paid to the delivery provider. In order to receive the refunds, use the `sendVaasToEvm` function
     * with `refundChain` and `refundAddress` as parameters
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the default delivery provider
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to `receiverValue`
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to `quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit)`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendVaasToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        VaaKey[] memory vaaKeys,
        uint16 refundChain,
        address refundAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and external messages specified by `messageKeys` to the address `targetAddress` on chain `targetChain`
     * with gas limit `gasLimit` and `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * MessageKeys can specify wormhole messages (VaaKeys) or other types of messages (ex. USDC CCTP attestations). Ensure the selected
     * Note: DeliveryProvider supports all the MessageKey.keyType values specified or it will not be delivered!
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver)
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param gasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param messageKeys Additional messagess to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        MessageKey[] memory messageKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param vaaKeys Additional VAAs to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Publishes an instruction for the delivery provider at `deliveryProviderAddress`
     * to relay a payload and VAAs specified by `vaaKeys` to the address `targetAddress` on chain `targetChain`
     * with `msg.value` equal to
     * receiverValue + (arbitrary amount that is paid for by paymentForExtraReceiverValue of this chain's wei) in targetChain wei.
     *
     * Any refunds (from leftover gas) will be sent to `refundAddress` on chain `refundChain`
     * `targetAddress` must implement the IWormholeReceiver interface
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, receiverValue, encodedExecutionParameters, deliveryProviderAddress) + paymentForExtraReceiverValue
     *
     * MessageKeys can specify wormhole messages (VaaKeys) or other types of messages (ex. USDC CCTP attestations). Ensure the selected
     * Note: DeliveryProvider supports all the MessageKey.keyType values specified or it will not be delivered!
     *
     * @param targetChain in Wormhole Chain ID format
     * @param targetAddress address to call on targetChain (that implements IWormholeReceiver), in Wormhole bytes32 format
     * @param payload arbitrary bytes to pass in as parameter in call to `targetAddress`
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param paymentForExtraReceiverValue amount (in current chain currency units) to spend on extra receiverValue
     *        (in addition to the `receiverValue` specified)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param refundChain The chain to deliver any refund to, in Wormhole Chain ID format
     * @param refundAddress The address on `refundChain` to deliver any refund to, in Wormhole bytes32 format
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @param messageKeys Additional messagess to pass in as parameter in call to `targetAddress`
     * @param consistencyLevel Consistency level with which to publish the delivery instructions - see
     *        https://book.wormhole.com/wormhole/3_coreLayerContracts.html?highlight=consistency#consistency-levels
     * @return sequence sequence number of published VAA containing delivery instructions
     */
    function send(
        uint16 targetChain,
        bytes32 targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        bytes memory encodedExecutionParameters,
        uint16 refundChain,
        bytes32 refundAddress,
        address deliveryProviderAddress,
        MessageKey[] memory messageKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     * (e.g. with a different delivery provider)
     *
     * This function must be called with `msg.value` equal to
     * quoteEVMDeliveryPrice(targetChain, newReceiverValue, newGasLimit, newDeliveryProviderAddress)
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newGasLimit gas limit with which to call `targetAddress`. Any units of gas unused will be refunded according to the
     *        `targetChainRefundPerGasUnused` rate quoted by the delivery provider, to the refund chain and address specified in the original request
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     * @notice *** This will only be able to succeed if the following is true **
     *         - newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resendToEvm(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Requests a previously published delivery instruction to be redelivered
     *
     *
     * This function must be called with `msg.value` equal to
     * quoteDeliveryPrice(targetChain, newReceiverValue, newEncodedExecutionParameters, newDeliveryProviderAddress)
     *
     * @param deliveryVaaKey VaaKey identifying the wormhole message containing the
     *        previously published delivery instructions
     * @param targetChain The target chain that the original delivery targeted. Must match targetChain from original delivery instructions
     * @param newReceiverValue new msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param newEncodedExecutionParameters new encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param newDeliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return sequence sequence number of published VAA containing redelivery instructions
     *
     *  @notice *** This will only be able to succeed if the following is true **
     *         - (For EVM_V1) newGasLimit >= gas limit of the old instruction
     *         - newReceiverValue >= receiver value of the old instruction
     *         - (For EVM_V1) newDeliveryProvider's `targetChainRefundPerGasUnused` >= old relay provider's `targetChainRefundPerGasUnused`
     */
    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        bytes memory newEncodedExecutionParameters,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using the default delivery provider
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param gasLimit gas limit with which to call `targetAddress`.
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return targetChainRefundPerGasUnused amount of target chain currency that will be refunded per unit of gas unused,
     *         if a refundAddress is specified
     */
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        uint256 gasLimit,
        address deliveryProviderAddress
    ) external view returns (uint256 nativePriceQuote, uint256 targetChainRefundPerGasUnused);

    /**
     * @notice Returns the price to request a relay to chain `targetChain`, using delivery provider `deliveryProviderAddress`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param receiverValue msg.value that delivery provider should pass in for call to `targetAddress` (in targetChain currency units)
     * @param encodedExecutionParameters encoded information on how to execute delivery that may impact pricing
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` with which to call `targetAddress`
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return nativePriceQuote Price, in units of current chain currency, that the delivery provider charges to perform the relay
     * @return encodedExecutionInfo encoded information on how the delivery will be executed
     *        e.g. for version EVM_V1, this is a struct that encodes the `gasLimit` and `targetChainRefundPerGasUnused`
     *             (which is the amount of target chain currency that will be refunded per unit of gas unused,
     *              if a refundAddress is specified)
     */
    function quoteDeliveryPrice(
        uint16 targetChain,
        uint256 receiverValue,
        bytes memory encodedExecutionParameters,
        address deliveryProviderAddress
    ) external view returns (uint256 nativePriceQuote, bytes memory encodedExecutionInfo);

    /**
     * @notice Returns the (extra) amount of target chain currency that `targetAddress`
     * will be called with, if the `paymentForExtraReceiverValue` field is set to `currentChainAmount`
     *
     * @param targetChain in Wormhole Chain ID format
     * @param currentChainAmount The value that `paymentForExtraReceiverValue` will be set to
     * @param deliveryProviderAddress The address of the desired delivery provider's implementation of IDeliveryProvider
     * @return targetChainAmount The amount such that if `targetAddress` will be called with `msg.value` equal to
     *         receiverValue + targetChainAmount
     */
    function quoteNativeForChain(
        uint16 targetChain,
        uint256 currentChainAmount,
        address deliveryProviderAddress
    ) external view returns (uint256 targetChainAmount);

    /**
     * @notice Returns the address of the current default delivery provider
     * @return deliveryProvider The address of (the default delivery provider)'s contract on this source
     *   chain. This must be a contract that implements IDeliveryProvider.
     */
    function getDefaultDeliveryProvider() external view returns (address deliveryProvider);
}

/**
 * @title IWormholeRelayerDelivery
 * @notice The interface to execute deliveries. Only relevant for Delivery Providers
 */
interface IWormholeRelayerDelivery is IWormholeRelayerBase {
    enum DeliveryStatus {
        SUCCESS,
        RECEIVER_FAILURE
    }

    enum RefundStatus {
        REFUND_SENT,
        REFUND_FAIL,
        CROSS_CHAIN_REFUND_SENT,
        CROSS_CHAIN_REFUND_FAIL_PROVIDER_NOT_SUPPORTED,
        CROSS_CHAIN_REFUND_FAIL_NOT_ENOUGH
    }

    /**
     * @custom:member recipientContract - The target contract address
     * @custom:member sourceChain - The chain which this delivery was requested from (in wormhole
     *     ChainID format)
     * @custom:member sequence - The wormhole sequence number of the delivery VAA on the source chain
     *     corresponding to this delivery request
     * @custom:member deliveryVaaHash - The hash of the delivery VAA corresponding to this delivery
     *     request
     * @custom:member gasUsed - The amount of gas that was used to call your target contract
     * @custom:member status:
     *   - RECEIVER_FAILURE, if the target contract reverts
     *   - SUCCESS, if the target contract doesn't revert
     * @custom:member additionalStatusInfo:
     *   - If status is SUCCESS, then this is empty.
     *   - If status is RECEIVER_FAILURE, this is `RETURNDATA_TRUNCATION_THRESHOLD` bytes of the
     *       return data (i.e. potentially truncated revert reason information).
     * @custom:member refundStatus - Result of the refund. REFUND_SUCCESS or REFUND_FAIL are for
     *     refunds where targetChain=refundChain; the others are for targetChain!=refundChain,
     *     where a cross chain refund is necessary
     * @custom:member overridesInfo:
     *   - If not an override: empty bytes array
     *   - Otherwise: An encoded `DeliveryOverride`
     */
    event Delivery(
        address indexed recipientContract,
        uint16 indexed sourceChain,
        uint64 indexed sequence,
        bytes32 deliveryVaaHash,
        DeliveryStatus status,
        uint256 gasUsed,
        RefundStatus refundStatus,
        bytes additionalStatusInfo,
        bytes overridesInfo
    );

    /**
     * @notice The delivery provider calls `deliver` to relay messages as described by one delivery instruction
     *
     * The delivery provider must pass in the specified (by VaaKeys[]) signed wormhole messages (VAAs) from the source chain
     * as well as the signed wormhole message with the delivery instructions (the delivery VAA)
     *
     * The messages will be relayed to the target address (with the specified gas limit and receiver value) iff the following checks are met:
     * - the delivery VAA has a valid signature
     * - the delivery VAA's emitter is one of these WormholeRelayer contracts
     * - the delivery provider passed in at least enough of this chain's currency as msg.value (enough meaning the maximum possible refund)
     * - the instruction's target chain is this chain
     * - the relayed signed VAAs match the descriptions in container.messages (the VAA hashes match, or the emitter address, sequence number pair matches, depending on the description given)
     *
     * @param encodedVMs - An array of signed wormhole messages (all from the same source chain
     *     transaction)
     * @param encodedDeliveryVAA - Signed wormhole message from the source chain's WormholeRelayer
     *     contract with payload being the encoded delivery instruction container
     * @param relayerRefundAddress - The address to which any refunds to the delivery provider
     *     should be sent
     * @param deliveryOverrides - Optional overrides field which must be either an empty bytes array or
     *     an encoded DeliveryOverride struct
     */
    function deliver(
        bytes[] memory encodedVMs,
        bytes memory encodedDeliveryVAA,
        address payable relayerRefundAddress,
        bytes memory deliveryOverrides
    ) external payable;
}

interface IWormholeRelayer is IWormholeRelayerDelivery, IWormholeRelayerSend {}

/*
 *  Errors thrown by IWormholeRelayer contract
 */

// Bound chosen by the following formula: `memoryWord * 4 + selectorSize`.
// This means that an error identifier plus four fixed size arguments should be available to developers.
// In the case of a `require` revert with error message, this should provide 2 memory word's worth of data.
uint256 constant RETURNDATA_TRUNCATION_THRESHOLD = 132;

//When msg.value was not equal to `delivery provider's quoted delivery price` + `paymentForExtraReceiverValue`
error InvalidMsgValue(uint256 msgValue, uint256 totalFee);

error RequestedGasLimitTooLow();

error DeliveryProviderDoesNotSupportTargetChain(address relayer, uint16 chainId);
error DeliveryProviderCannotReceivePayment();
error DeliveryProviderDoesNotSupportMessageKeyType(uint8 keyType);

//When calling `delivery()` a second time even though a delivery is already in progress
error ReentrantDelivery(address msgSender, address lockedBy);

error InvalidPayloadId(uint8 parsed, uint8 expected);
error InvalidPayloadLength(uint256 received, uint256 expected);
error InvalidVaaKeyType(uint8 parsed);
error TooManyMessageKeys(uint256 numMessageKeys);

error InvalidDeliveryVaa(string reason);
//When the delivery VAA (signed wormhole message with delivery instructions) was not emitted by the
//  registered WormholeRelayer contract
error InvalidEmitter(bytes32 emitter, bytes32 registered, uint16 chainId);
error MessageKeysLengthDoesNotMatchMessagesLength(uint256 keys, uint256 vaas);
error VaaKeysDoNotMatchVaas(uint8 index);
//When someone tries to call an external function of the WormholeRelayer that is only intended to be
//  called by the WormholeRelayer itself (to allow retroactive reverts for atomicity)
error RequesterNotWormholeRelayer();

//When trying to relay a `DeliveryInstruction` to any other chain but the one it was specified for
error TargetChainIsNotThisChain(uint16 targetChain);
//When a `DeliveryOverride` contains a gas limit that's less than the original
error InvalidOverrideGasLimit();
//When a `DeliveryOverride` contains a receiver value that's less than the original
error InvalidOverrideReceiverValue();
//When a `DeliveryOverride` contains a 'refund per unit of gas unused' that's less than the original
error InvalidOverrideRefundPerGasUnused();

//When the delivery provider doesn't pass in sufficient funds (i.e. msg.value does not cover the
// maximum possible refund to the user)
error InsufficientRelayerFunds(uint256 msgValue, uint256 minimum);

//When a bytes32 field can't be converted into a 20 byte EVM address, because the 12 padding bytes
//  are non-zero (duplicated from Utils.sol)
error NotAnEvmAddress(bytes32);

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IWormholeRelayer.sol";

function toWormholeFormat(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

function fromWormholeFormat(bytes32 whFormatAddress) pure returns (address) {
    if (uint256(whFormatAddress) >> 160 != 0) {
        revert NotAnEvmAddress(whFormatAddress);
    }
    return address(uint160(uint256(whFormatAddress)));
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWormholeReceiver.sol";
import "./interfaces/IWormholeRelayer.sol";
import "./interfaces/ITokenBridge.sol";

import "./Utils.sol";

abstract contract Base {
    IWormholeRelayer public wormholeRelayer;
    IWormhole public wormhole;

    mapping(bytes32 => bool) public seenDeliveryVaaHashes;

    address registrationOwner;
    mapping(uint16 => bytes32) registeredSenders;

    bool internal _wormholeRelayerInitialized;

    function __Base_init(address _wormholeRelayer, address _wormhole) public {
        require(!_wormholeRelayerInitialized, "WRI");
        _wormholeRelayerInitialized = true;
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        wormhole = IWormhole(_wormhole);
        registrationOwner = msg.sender;
    }

    modifier onlyWormholeRelayer() {
        require(msg.sender == address(wormholeRelayer), "Msg.sender is not Wormhole Relayer");
        _;
    }

    modifier replayProtect(bytes32 deliveryHash) {
        require(!seenDeliveryVaaHashes[deliveryHash], "Message already processed");
        seenDeliveryVaaHashes[deliveryHash] = true;
        _;
    }

    modifier isRegisteredSender(uint16 sourceChain, bytes32 sourceAddress) {
        require(registeredSenders[sourceChain] == sourceAddress, "Not registered sender");
        _;
    }

    /**
     * Sets the registered address for 'sourceChain' to 'sourceAddress'
     * So that for messages from 'sourceChain', only ones from 'sourceAddress' are valid
     *
     * Assumes only one sender per chain is valid
     * Sender is the address that called 'send' on the Wormhole Relayer contract on the source chain)
     */
    function setRegisteredSender(uint16 sourceChain, bytes32 sourceAddress) public {
        require(msg.sender == registrationOwner, "Not allowed to set registered sender");
        registeredSenders[sourceChain] = sourceAddress;
    }
}

abstract contract TokenBase is Base {
    ITokenBridge public tokenBridge;

    function __TokenBase_init(address _wormholeRelayer, address _tokenBridge, address _wormhole) public {
        require(!_wormholeRelayerInitialized, "WRI");
        Base.__Base_init(_wormholeRelayer, _wormhole);
        tokenBridge = ITokenBridge(_tokenBridge);
    }

    function getDecimals(address tokenAddress) internal view returns (uint8 decimals) {
        // query decimals
        (, bytes memory queriedDecimals) = address(tokenAddress).staticcall(abi.encodeWithSignature("decimals()"));
        decimals = abi.decode(queriedDecimals, (uint8));
    }

    function getTokenAddressOnThisChain(uint16 tokenHomeChain, bytes32 tokenHomeAddress)
        internal
        view
        returns (address tokenAddressOnThisChain)
    {
        return tokenHomeChain == wormhole.chainId()
            ? fromWormholeFormat(tokenHomeAddress)
            : tokenBridge.wrappedAsset(tokenHomeChain, tokenHomeAddress);
    }
}

abstract contract TokenSender is TokenBase {
    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     *
     */
    function transferTokens(address token, uint256 amount, uint16 targetChain, address targetAddress)
        internal
        returns (VaaKey memory)
    {
        return transferTokens(token, amount, targetChain, targetAddress, bytes(""));
    }

    /**
     * transferTokens wraps common boilerplate for sending tokens to another chain using IWormholeRelayer.
     * A payload can be included in the transfer vaa. By including a payload here instead of the deliveryVaa,
     * fewer trust assumptions are placed on the WormholeRelayer contract.
     *
     * - approves tokenBridge to spend 'amount' of 'token'
     * - emits token transfer VAA
     * - returns VAA key for inclusion in WormholeRelayer `additionalVaas` argument
     *
     * Note: this function uses transferTokensWithPayload instead of transferTokens since the former requires that only the targetAddress
     *       can redeem transfers. Otherwise it's possible for another address to redeem the transfer before the targetContract is invoked by
     *       the offchain relayer and the target contract would have to be hardened against this.
     */
    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress,
        bytes memory payload
    ) internal returns (VaaKey memory) {
        SafeERC20.forceApprove(IERC20(token), address(tokenBridge), amount);
        uint64 sequence = tokenBridge.transferTokensWithPayload{value: wormhole.messageFee()}(
            token, amount, targetChain, toWormholeFormat(targetAddress), 0, payload
        );
        return VaaKey({
            emitterAddress: toWormholeFormat(address(tokenBridge)),
            chainId: wormhole.chainId(),
            sequence: sequence
        });
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit);
        return wormholeRelayer.sendVaasToEvm{value: cost}(
            targetChain, targetAddress, payload, receiverValue, gasLimit, vaaKeys
        );
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount,
        uint16 refundChain,
        address refundAddress
    ) internal returns (uint64) {
        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit);
        return wormholeRelayer.sendVaasToEvm{value: cost}(
            targetChain, targetAddress, payload, receiverValue, gasLimit, vaaKeys, refundChain, refundAddress
        );
    }
}

abstract contract TokenReceiver is TokenBase {
    struct TokenReceived {
        bytes32 tokenHomeAddress;
        uint16 tokenHomeChain;
        address tokenAddress; // wrapped address if tokenHomeChain !== this chain, else tokenHomeAddress (in evm address format)
        uint256 amount;
        uint256 amountNormalized; // if decimals > 8, normalized to 8 decimal places
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external virtual payable {
        _receiveWormholeMessages(payload, additionalVaas, sourceAddress, sourceChain, deliveryHash);
    }

    function _receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal {
        TokenReceived[] memory receivedTokens = new TokenReceived[](additionalVaas.length);

        for (uint256 i = 0; i < additionalVaas.length; ++i) {
            IWormhole.VM memory parsed = wormhole.parseVM(additionalVaas[i]);
            require(
                parsed.emitterAddress == tokenBridge.bridgeContracts(parsed.emitterChainId), "Not a Token Bridge VAA"
            );
            ITokenBridge.TransferWithPayload memory transfer = tokenBridge.parseTransferWithPayload(parsed.payload);
            require(
                transfer.to == toWormholeFormat(address(this)) && transfer.toChain == wormhole.chainId(),
                "Token was not sent to this address"
            );

            tokenBridge.completeTransferWithPayload(additionalVaas[i]);

            address thisChainTokenAddress = getTokenAddressOnThisChain(transfer.tokenChain, transfer.tokenAddress);
            uint8 decimals = getDecimals(thisChainTokenAddress);
            uint256 denormalizedAmount = transfer.amount;
            if (decimals > 8) denormalizedAmount *= uint256(10) ** (decimals - 8);

            receivedTokens[i] = TokenReceived({
                tokenHomeAddress: transfer.tokenAddress,
                tokenHomeChain: transfer.tokenChain,
                tokenAddress: thisChainTokenAddress,
                amount: denormalizedAmount,
                amountNormalized: transfer.amount
            });
        }

        // call into overriden method
        receivePayloadAndTokens(payload, receivedTokens, sourceAddress, sourceChain, deliveryHash);
    }

    function receivePayloadAndTokens(
        bytes memory payload,
        TokenReceived[] memory receivedTokens,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/ILiquidationCalculator.sol";

/**
 * @title HubSpokeEvents
 * @notice Events emitted by the Hub and Spoke contracts
 */
contract HubSpokeEvents {
    event Liquidation(address indexed liquidator, address indexed vault, ILiquidationCalculator.DenormalizedLiquidationAsset[] liquidationAssets);
    event Deposit(address indexed vault, address indexed asset, uint256 amount, uint256 vaultTotalDeposited);
    event Withdraw(address indexed vault, address indexed asset, uint256 amount, uint256 vaultTotalDeposited);
    event Borrow(address indexed vault, address indexed asset, uint256 amount, uint256 vaultTotalBorrowed);
    event Repay(address indexed vault, address indexed asset, uint256 amount, uint256 vaultTotalBorrowed);
    event ReservesWithdrawn(address indexed asset, uint256 amount, address destination);
    event LogError(bytes32 sourceAddress, uint16 sourceChain, bytes32 deliveryHash, string error);
    event SpokeRegistered(uint16 chainId, address spoke);
    event AssetRegistered(
        address asset,
        uint256 collateralizationRatioDeposit,
        uint256 collateralizationRatioBorrow,
        uint256 borrowLimit,
        uint256 supplyLimit,
        address interestRateCalculator,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus
    );
    event SetAssetParams(
        address asset,
        uint256 borrowLimit,
        uint256 supplyLimit,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus,
        address interestRateCalculator
    );
    event CollateralizationRatiosChanged(
        address asset,
        uint256 collateralizationRatioDeposit,
        uint256 collateralizationRatioBorrow
    );
    event SetLiquidationFee(uint256 value, uint256 precision);
    event AssetPythIdChanged(address asset, bytes32 oldPythId, bytes32 newPythId);
    event AccrualIndexUpdated(address indexed asset, uint256 deposit, uint256 borrow, uint256 timestamp);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILiquidationCalculator} from "../interfaces/ILiquidationCalculator.sol";
import {IHubPriceUtilities} from "../interfaces/IHubPriceUtilities.sol";
import {IAssetRegistry} from "../interfaces/IAssetRegistry.sol";

/**
 * @title HubSpokeStructs
 * @notice A set of structs and enums used in the Hub and Spoke contracts
 */
library HubSpokeStructs {
    /**
     * @param wormhole: Address of the Wormhole contract
     * @param tokenBridge: Address of the TokenBridge contract
     * @param wormholeRelayer: Address of the WormholeRelayer contract
     * @param consistencyLevel: Desired level of finality the Wormhole guardians will reach before signing the messages
     * NOTE: consistencyLevel = 200 will result in an instant message, while all other values will wait for finality
     * Recommended finality levels can be found here: https://book.wormhole.com/reference/contracts.html
     * @param pythAddress: Address of the Pyth oracle on the Hub chain
     * @param priceStandardDeviations: priceStandardDeviations = (psd * priceStandardDeviationsPrecision), where psd is
     * the number of standard deviations that we use for our price intervals in calculations relating to allowing
     * withdraws, borrows, or liquidations
     * @param priceStandardDeviationsPrecision: A precision number that allows us to represent our desired noninteger
     * price standard deviation as an integer (psd = priceStandardDeviations/priceStandardDeviationsPrecision)
     * @param maxLiquidationPortionPrecision: A precision number that allows us to represent our desired noninteger
     * max liquidation portion mlp as an integer (mlp = maxLiquidationPortion/maxLiquidationPortionPrecision)
     * @param interestAccrualIndexPrecision: A precision number that allows us to represent our noninteger interest
     * accrual indices as integers; we store each index as its true value multiplied by interestAccrualIndexPrecision
     * @param collateralizationRatioPrecision: A precision number that allows us to represent our noninteger
     * collateralization ratios as integers; we store each ratio as its true value multiplied by
     * collateralizationRatioPrecision
     * @param liquidationFee: The fee taken by the protocol on liquidation
     * @param _circleMessageTransmitter: Cicle Message Transmitter contract (cctp)
     * @param _circleTokenMessenger: Cicle Token Messenger contract (cctp)
     * @param _USDC: USDC token contract (cctp)
     */
    struct ConstructorArgs {
        /* Wormhole Information */
        address wormhole;
        address tokenBridge;
        address wormholeRelayer;
        uint8 consistencyLevel;
        /* Liquidation Information */
        uint256 interestAccrualIndexPrecision;
        uint256 liquidationFee;
        uint256 liquidationFeePrecision;
        /* CCTP Information */
        address circleMessageTransmitter;
        address circleTokenMessenger;
        address USDC;
    }

    struct StoredVaultAmount {
        DenormalizedVaultAmount amounts;
        AccrualIndices accrualIndices;
    }

    struct DenormalizedVaultAmount {
        uint256 deposited;
        uint256 borrowed;
    }

    struct NotionalVaultAmount {
        uint256 deposited;
        uint256 borrowed;
    }

    struct AccrualIndices {
        uint256 deposited;
        uint256 borrowed;
    }

    /**
     * @dev Struct to hold the decoded data from a Wormhole payload
     * @param action The action to be performed (e.g., Deposit, Borrow, Withdraw, Repay)
     * @param sender The address of the sender initiating the action
     * @param wrappedAsset The address of the wrapped asset involved in the action
     * @param amount The amount of the wrapped asset involved in the action
     * @param unwrap A boolean indicating whether to unwrap the asset or not for native withdraws and borrows
     */
    struct PayloadData {
        Action action;
        address sender;
        address wrappedAsset;
        uint256 amount;
        bool unwrap;
    }

    struct CrossChainTarget {
        bytes32 addressWhFormat;
        uint16 chainId;
        bytes32 deliveryHash;
    }

    enum Action {
        Deposit,
        Borrow,
        Withdraw,
        Repay,
        DepositNative,
        RepayNative
    }

    struct HubState {
        // number of confirmations for wormhole messages
        uint8 consistencyLevel;
        // vault for lending
        mapping(address => mapping(address => HubSpokeStructs.StoredVaultAmount)) vault;
        // total asset amounts (tokenAddress => (uint256, uint256))
        mapping(address => HubSpokeStructs.StoredVaultAmount) totalAssets;
        // interest accrual indices
        mapping(address => HubSpokeStructs.AccrualIndices) indices;
        // last timestamp for update
        mapping(address => uint256) lastActivityBlockTimestamps;
        // interest accrual rate precision level
        uint256 interestAccrualIndexPrecision;
        // calculator for liquidation amounts
        ILiquidationCalculator liquidationCalculator;
        // price utilities for getting prices
        IHubPriceUtilities priceUtilities;
        // asset registry for getting asset info
        IAssetRegistry assetRegistry;
        // protocol fee taken on liquidation
        uint256 liquidationFee;
        // for wormhole relay quotes
        uint256 defaultGasLimit;
        // for refunding of returnCost amount
        uint256 refundGasLimit;
        // toggle for using CCTP for asset => USDC
        bool isUsingCCTP;
        // the precision of the liquidation fee
        uint256 liquidationFeePrecision;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenSender, TokenReceiver, IWormholeRelayerSend, IWormhole, ITokenBridge} from "@wormhole-upgradeable/WormholeRelayerSDK.sol";
import {CCTPSender, CCTPReceiver, CCTPBase} from "@wormhole-upgradeable/CCTPBase.sol";
import {IWETH} from "@wormhole-upgradeable/interfaces/IWETH.sol";
import "@wormhole-upgradeable/Utils.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./HubInterestUtilities.sol";
import "../HubSpokeEvents.sol";
import "../wormhole/TokenReceiverWithCCTP.sol";
import "../wormhole/TokenBridgeUtilities.sol";

/**
 * @title Hub
 * @notice The Hub contract maintains state and liquidity for the protocol. It receives cross-chain payloads and tokens
 * using Wormhole, with user interactions happening on Spokes deployed on different chains. Spokes must be registered
 * on the Hub before we can receive messages. Assets must also be registered.
 */

contract Hub is
    Initializable,
    TokenSender,
    CCTPSender,
    PausableUpgradeable,
    HubInterestUtilities
{
    using SafeERC20 for IERC20;

    string private constant ERROR_UNREGISTERED_ASSET = "UnregisteredAsset";
    string private constant ERROR_VAULT_INSUFFICIENT_ASSETS = "VaultInsufficientAssets";
    string private constant ERROR_GLOBAL_INSUFFICIENT_ASSETS = "GlobalInsufficientAssets";
    string private constant ERROR_PAUSED = "HubPaused";
    string private constant ERROR_MSG_VALUE = "InsufficientMsgValue";

    error TransferFailed();
    error MustSendEther();
    error RenounceOwnershipDisabled();
    error ZeroAddress();
    error InvalidAction();
    error UnusedParameterMustBeZero();
    error InsufficientMsgValue();
    error InvalidPayloadOrVaa();

    /**
     * @notice Hub constructor; prevent initialize() from being invoked on the implementation contract
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Hub initializer - Initializes a new hub with given parameters
     *
     * @param args struct with constructor arguments
     */
    function initialize(HubSpokeStructs.ConstructorArgs memory args) public initializer {
        OwnableUpgradeable.__Ownable_init(msg.sender);
        PausableUpgradeable.__Pausable_init();
        CCTPBase.__CCTPBase_init(
            args.wormholeRelayer,
            args.tokenBridge,
            args.wormhole,
            args.circleMessageTransmitter,
            args.circleTokenMessenger,
            args.USDC
        );

        if (args.interestAccrualIndexPrecision < 1e18) {
            revert InvalidPrecision();
        }

        _state.interestAccrualIndexPrecision = args.interestAccrualIndexPrecision;
        _state.defaultGasLimit = 300_000;
        _state.refundGasLimit = 60_000;
        setLiquidationFee(args.liquidationFee, args.liquidationFeePrecision);
        _state.isUsingCCTP = args.circleMessageTransmitter != address(0); // zero address would indicate not using
    }

    function getVaultAmounts(address vaultOwner, address assetAddress) public view returns (HubSpokeStructs.DenormalizedVaultAmount memory) {
        return applyInterest(assetAddress, _state.vault[vaultOwner][assetAddress]);
    }

    function setVaultAmounts(address vaultOwner, address assetAddress, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) internal {
        _state.vault[vaultOwner][assetAddress].amounts = vaultAmount;
        _state.vault[vaultOwner][assetAddress].accrualIndices = getCurrentAccrualIndices(assetAddress);
    }

    function getGlobalAmounts(address assetAddress) public view returns (HubSpokeStructs.DenormalizedVaultAmount memory) {
        return applyInterest(assetAddress, _state.totalAssets[assetAddress]);
    }

    function setGlobalAmounts(address assetAddress, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) internal {
        _state.totalAssets[assetAddress].amounts = vaultAmount;
        _state.totalAssets[assetAddress].accrualIndices = getCurrentAccrualIndices(assetAddress);
    }

    /**
     * @notice Registers a spoke contract. Only wormhole messages from registered spoke contracts are allowed.
     *
     * @param chainId - The chain id which the spoke is deployed on
     * @param spokeContractAddress - The address of the spoke contract on its chain
     */
    function registerSpoke(uint16 chainId, address spokeContractAddress) external onlyOwner {
        setRegisteredSender(chainId, toWormholeFormat(spokeContractAddress));

        emit SpokeRegistered(chainId, spokeContractAddress);
    }

    /**
     * @notice Liquidates a vault. The sender of this transaction pays, for each i, assetRepayAmount[i] of the asset
     * assetRepayAddresses[i] and receives, for each i, assetReceiptAmount[i] of the asset at assetReceiptAddresses[i]
     * A check is made to see if this liquidation attempt should be allowed
     *
     * @param input: The LiquidationInput struct containing the liquidation details, input amounts should be denormalized (real amounts)
     */
    // todo kc change accrual indices in tests to > 1, make some time elapse as well
    function liquidation(ILiquidationCalculator.LiquidationInput memory input) public whenNotPaused {
        // check if inputs are valid
        _state.liquidationCalculator.checkLiquidationInputsValid(input);

        // update all accrual indices
        for (uint256 i = 0; i < input.assets.length;) {
            updateAccrualIndices(input.assets[i].assetAddress);
            unchecked {
                i++;
            }
        }

        // check if intended liquidation is valid
        _state.liquidationCalculator.checkAllowedToLiquidate(input);

        (uint256 liquidationFee, uint256 precision) = getLiquidationFeeAndPrecision();

        for (uint256 i = 0; i < input.assets.length;) {
            ILiquidationCalculator.DenormalizedLiquidationAsset memory asset = input.assets[i];
            IERC20 assetToken = IERC20(asset.assetAddress);

            // update vault amounts
            if (asset.repaidAmount > 0) {
                _updateVaultAmounts(HubSpokeStructs.Action.Repay, input.vault, asset.assetAddress, asset.repaidAmount);
                // send repay tokens from liquidator to contract
                assetToken.safeTransferFrom(msg.sender, address(this), asset.repaidAmount);
            }

            if (asset.receivedAmount > 0) {
                _updateVaultAmounts(HubSpokeStructs.Action.Withdraw, input.vault, asset.assetAddress, asset.receivedAmount);
                // reward liquidator
                uint256 feePortion = (asset.receivedAmount * liquidationFee) / precision;
                uint256 amountToTransfer = asset.receivedAmount - feePortion;
                if (asset.depositTakeover) {
                    _updateVaultAmounts(HubSpokeStructs.Action.Deposit, msg.sender, asset.assetAddress, amountToTransfer);
                } else {
                    assetToken.safeTransfer(msg.sender, amountToTransfer);
                }
            }

            unchecked {
                i++;
            }
        }

        emit Liquidation(msg.sender, input.vault, input.assets);
    }

    /**
     * @notice Returns the calculated return delivery cost on the given `spokeChainId`
     * @param spokeChainId: The spoke's chainId to forward tokens to
     * @return The calculated return delivery cost
     */
    function getCostForReturnDelivery(uint16 spokeChainId) public view returns (uint256) {
        return getDeliveryCost(spokeChainId, _state.defaultGasLimit);
    }

    function getCostForRefundDelivery(uint16 spokeChainId) public view returns (uint256) {
        return getDeliveryCost(spokeChainId, _state.refundGasLimit);
    }

    function getDeliveryCost(uint16 spokeChainId, uint256 gasLimit) internal view returns (uint256) {
        (uint256 deliveryCost,) = wormholeRelayer.quoteEVMDeliveryPrice(spokeChainId, 0, gasLimit);
        return deliveryCost + tokenBridge.wormhole().messageFee();
    }

    /**
     * @dev Overriding the superclasses' function to choose whether to use CCTP or not, based on the implemented
     * `isUsingCCTP` function
     * @param payload - the payload received
     * @param additionalVaas - any wormhole VAAs received
     * @param sourceAddress - the source address of the tokens
     * @param sourceChain - the source chain of the tokens
     * @param deliveryHash - the delivery hash of the tokens
     */
    function receiveWormholeMessages(
          bytes memory payload,
          bytes[] memory additionalVaas,
          bytes32 sourceAddress,
          uint16 sourceChain,
          bytes32 deliveryHash
    )
    external
    payable
    onlyWormholeRelayer
    isRegisteredSender(sourceChain, sourceAddress)
    replayProtect(deliveryHash)
    {
        HubSpokeStructs.PayloadData memory data;
        bool withCCTP;
        {
            bytes memory userPayload;
            bool sendingCCTP;
            bool receivingCCTP;
            (data.amount, userPayload) = abi.decode(payload, (uint256, bytes));
            (data.action, data.sender, data.wrappedAsset, data.unwrap, sendingCCTP, receivingCCTP) =
                abi.decode(userPayload, (HubSpokeStructs.Action, address, address, bool, bool, bool));
            withCCTP = sendingCCTP || receivingCCTP;
        }

        if (sendingTokens(data.action)) {
            if (additionalVaas.length > 0) {
                revert InvalidPayloadOrVaa();
            }
            data.wrappedAsset = withCCTP && _state.isUsingCCTP
                ? USDC
                : tokenBridge.wrappedAsset(sourceChain, toWormholeFormat(data.wrappedAsset));
        } else {
            if (additionalVaas.length != 1) {
                revert InvalidPayloadOrVaa();
            }

            if (withCCTP) {
                if (data.amount != redeemUSDC(additionalVaas[0])) {
                    revert InvalidPayloadOrVaa();
                }
                data.wrappedAsset = USDC;
            } else {
                IWormhole.VM memory parsed = wormhole.parseVM(additionalVaas[0]);
                if (parsed.emitterAddress != tokenBridge.bridgeContracts(parsed.emitterChainId)) {
                    revert InvalidPayloadOrVaa();
                }
                ITokenBridge.TransferWithPayload memory transfer = tokenBridge.parseTransferWithPayload(parsed.payload);
                if (transfer.to != toWormholeFormat(address(this)) || transfer.toChain != wormhole.chainId()) {
                    revert InvalidPayloadOrVaa();
                }

                tokenBridge.completeTransferWithPayload(additionalVaas[0]);

                data.wrappedAsset = getTokenAddressOnThisChain(transfer.tokenChain, transfer.tokenAddress);

                if (data.amount != TokenBridgeUtilities.denormalizeAmount(transfer.amount, getDecimals(data.wrappedAsset))) {
                    revert InvalidPayloadOrVaa();
                }
            }
        }

        handlePayload(
            data,
            HubSpokeStructs.CrossChainTarget(sourceAddress, sourceChain, deliveryHash),
            false
        );
    }

    function hubInitiatedAction(HubSpokeStructs.Action action, address asset, uint256 amount, uint16 targetChain, bool unwrap) external payable whenNotPaused {
        bytes32 spokeAddress = registeredSenders[targetChain];
        if (spokeAddress == bytes32(0)) {
            revert ZeroAddress();
        }

        if (action != HubSpokeStructs.Action.Withdraw && action != HubSpokeStructs.Action.Borrow) {
            revert InvalidAction();
        }

        TokenBridgeUtilities.requireAssetAmountValidForTokenBridge(asset, amount);

        HubSpokeStructs.PayloadData memory data = HubSpokeStructs.PayloadData(action, msg.sender, asset, amount, unwrap);
        HubSpokeStructs.CrossChainTarget memory target = HubSpokeStructs.CrossChainTarget(spokeAddress, targetChain, bytes32(0));

        handlePayload(data, target, true);
    }

    // ============ Same Chain User Functions ============
    /**
     * @notice allows users to perform actions on the vault from the same chain as the vault (ERC20 only)
     * @param action - the action (either Deposit, Borrow, Withdraw, or Repay)
     * @param asset - the address of the wrapped asset
     * @param amount - the amount of the wrapped asset
     */
    function userActions(HubSpokeStructs.Action action, address asset, uint256 amount) public payable whenNotPaused {
        if (action == HubSpokeStructs.Action.RepayNative || action == HubSpokeStructs.Action.DepositNative) {
            if (msg.value == 0) revert MustSendEther();
            if (asset != address(0)) revert UnusedParameterMustBeZero();
            if (amount != 0) revert UnusedParameterMustBeZero();

            IWETH weth = _state.assetRegistry.WETH();
            asset = address(weth);
            amount = msg.value;
            weth.deposit{value: msg.value}();
        }

        checkValidAsset(asset, true);
        updateAccrualIndices(asset);

        bool transferTokensToSender;

        if (action == HubSpokeStructs.Action.Withdraw) {
            _state.priceUtilities.checkAllowedToWithdraw(msg.sender, asset, amount, true);
            transferTokensToSender = true;
        } else if (action == HubSpokeStructs.Action.Borrow) {
            _state.priceUtilities.checkAllowedToBorrow(msg.sender, asset, amount, true);
            transferTokensToSender = true;
        } else if (action == HubSpokeStructs.Action.Repay || action == HubSpokeStructs.Action.RepayNative) {
            _state.priceUtilities.checkAllowedToRepay(msg.sender, asset, amount, true);
            if (action == HubSpokeStructs.Action.Repay) {
                IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
            }
        } else if (action == HubSpokeStructs.Action.Deposit || action == HubSpokeStructs.Action.DepositNative) {
            _state.priceUtilities.checkAllowedToDeposit(asset, amount, true);
            if (action == HubSpokeStructs.Action.Deposit) {
                IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
            }
        }

        _updateVaultAmounts(action, msg.sender, asset, amount);

        if (transferTokensToSender) {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @notice Allows users to borrow or withdraw in native currency
     * @param action - the action (either Borrow or Withdraw)
     * @param amount - The amount in native currency
     * @param unwrap - A boolean indicating whether to unwrap the asset or not
     */
    function borrowOrWithdrawNative(HubSpokeStructs.Action action, uint256 amount, bool unwrap) external whenNotPaused {
        IWETH weth = _state.assetRegistry.WETH();
        address asset = address(weth);
        updateAccrualIndices(asset);

        if (action == HubSpokeStructs.Action.Withdraw) {
            _state.priceUtilities.checkAllowedToWithdraw(msg.sender, asset, amount, true);
        } else if (action == HubSpokeStructs.Action.Borrow) {
            _state.priceUtilities.checkAllowedToBorrow(msg.sender, asset, amount, true);
        } else {
            revert InvalidAction();
        }

        _updateVaultAmounts(action, msg.sender, asset, amount);

        if (unwrap) {
            _sendNative(amount, weth);
        } else {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }
    }

    /**
     * @dev Checks if deposit after interest is greater than the amount that is to be withdrawn
     *
     * @param vault - the address of the vault to be checked
     * @param assetAddress - the address of the relevant asset
     * @param amount - the denormalized amount of the asset that is to be withdrawn
     * @param shouldRevert - Whether we should revert or simply log the error
     * @return success - Whether the vault has assets
     * @return error - The error message if the vault has insufficient assets
     */
    function checkVaultHasAssets(address vault, address assetAddress, uint256 amount, bool shouldRevert)
        public
        view
        returns (bool success, string memory error)
    {
        HubSpokeStructs.DenormalizedVaultAmount memory amounts = getVaultAmounts(vault, assetAddress);
        bool hasAssets = amounts.deposited >= amount;

        if (shouldRevert) {
            require(hasAssets, ERROR_VAULT_INSUFFICIENT_ASSETS);
        }

        return (hasAssets, ERROR_VAULT_INSUFFICIENT_ASSETS);
    }

    function checkProtocolGloballyHasAssets(
        address assetAddress,
        uint256 amount,
        bool shouldRevert
    ) public view returns (bool success, string memory error) {
        return checkProtocolGloballyHasAssets(assetAddress, amount, shouldRevert, type(uint256).max);
    }

    /**
     * @dev Checks if the protocol globally has an amount of asset greater than or equal to withdrawn or borrowed amount
     * This check protects protocol reserves, because it requires:
     * 1. denormalizedDeposited >= denormalizedBorrowed + amount
     * 2. baseDeposited + depositInterest >= baseBorrowed + borrowInterest + amount
     * 3. baseDeposited + depositInterest - baseBorrowed - borrowInterest >= amount
     * 4. baseDeposited - baseBorrowed + depositInterest - borrowInterest >= amount
     * 5. baseDeposited - baseBorrowed + depositInterest - borrowInterest >= amount
     * 6. baseDeposited - baseBorrowed - (borrowInterest - depositInterest) >= amount
     * 7. baseDeposited - baseBorrowed - reserve >= amount
     *
     * @param assetAddress - the address of the relevant asset
     * @param amount - the denormalized amount of asset that is to be withdrawn or borrowed
     * @param shouldRevert - Whether we should revert or simply log the error
     * @param borrowLimit - The borrow limit of the asset. Pass type(uint256).max for no limit
     * @return success - Whether the protocol globally has assets
     * @return error - The error message if the protocol has insufficient assets
     */
    function checkProtocolGloballyHasAssets(
        address assetAddress,
        uint256 amount,
        bool shouldRevert,
        uint256 borrowLimit
    ) public view returns (bool success, string memory error) {
        HubSpokeStructs.DenormalizedVaultAmount memory globalAmounts = getGlobalAmounts(assetAddress);
        bool globalHasAssets = globalAmounts.deposited >= globalAmounts.borrowed + amount;
        if (borrowLimit < type(uint256).max) {
            globalHasAssets = borrowLimit >= globalAmounts.borrowed + amount;
        }

        if (shouldRevert) {
            require(globalHasAssets, ERROR_GLOBAL_INSUFFICIENT_ASSETS);
        }

        return (globalHasAssets, ERROR_GLOBAL_INSUFFICIENT_ASSETS);
    }

    /**
     * @dev Check if an address has been registered on the Hub; throws an error or logs the error
     * @param assetAddress - The address to be checked
     * @param shouldRevert - Whether we should revert or simply log the error
     * @return Whether the asset is valid
     * @return The error message if the asset is invalid
     */
    function checkValidAsset(address assetAddress, bool shouldRevert) internal view returns (bool, string memory) {
        bool isValid = getAssetInfo(assetAddress).exists;

        if (shouldRevert) {
            require(isValid, ERROR_UNREGISTERED_ASSET);
        }

        return (isValid, ERROR_UNREGISTERED_ASSET);
    }

    // ============ Internal Functions ============

    function handlePayload(
        HubSpokeStructs.PayloadData memory data,
        HubSpokeStructs.CrossChainTarget memory target,
        bool revertOnInvalid
    ) internal {
        (bool valid, string memory err) = checkValidAsset(data.wrappedAsset, false);

        if (paused()) {
            valid = false;
            err = ERROR_PAUSED;
        }

        if (valid) {
            (valid, err) = _checkMsgValueForReturnDelivery(data.action, target.chainId);
        }

        if (valid) {
            updateAccrualIndices(data.wrappedAsset);
            if (data.action == HubSpokeStructs.Action.Withdraw) {
                (valid, err) = _state.priceUtilities.checkAllowedToWithdraw(data.sender, data.wrappedAsset, data.amount, false);
            } else if (data.action == HubSpokeStructs.Action.Borrow) {
                (valid, err) = _state.priceUtilities.checkAllowedToBorrow(data.sender, data.wrappedAsset, data.amount, false);
            } else if (data.action == HubSpokeStructs.Action.Repay || data.action == HubSpokeStructs.Action.RepayNative) {
                (valid, err) = _state.priceUtilities.checkAllowedToRepay(data.sender, data.wrappedAsset, data.amount, false);
            } else if (data.action == HubSpokeStructs.Action.Deposit || data.action == HubSpokeStructs.Action.DepositNative) {
                (valid, err) = _state.priceUtilities.checkAllowedToDeposit(data.wrappedAsset, data.amount, false);
            }
        }

        if (valid) {
            _updateVaultAmounts(data.action, data.sender, data.wrappedAsset, data.amount);
        } else {
            emit LogError(target.addressWhFormat, target.chainId, target.deliveryHash, err);
        }

        if (revertOnInvalid && !valid) {
            revert(err);
        }

        handleTokenTransfer(valid, data, target.chainId, target.addressWhFormat);
    }

    function encodeUserPayload(HubSpokeStructs.PayloadData memory data, bool withCCTP) internal pure returns (bytes memory) {
        return abi.encode(data.sender, data.unwrap, withCCTP);
    }

    function sendingTokens(HubSpokeStructs.Action action) private pure returns (bool) {
        return action == HubSpokeStructs.Action.Withdraw || action == HubSpokeStructs.Action.Borrow;
    }

    /**
     * @dev Handles the transfer of tokens based on the validity of the action and the type of action. If we are to
     * use CCTP, use the appropriate function to send.
     * @param valid - A boolean indicating the validity of the action.
     * @param data - A struct containing the payload data.
     * @param sourceChain - The source chain from where the payload and tokens were sent.
     * @param sourceAddress - The address from which the payload and tokens were sent.
     */
    function handleTokenTransfer(bool valid, HubSpokeStructs.PayloadData memory data, uint16 sourceChain, bytes32 sourceAddress)
        internal
    {
        bool tokensOut = sendingTokens(data.action);

        if ((valid && tokensOut) || (!valid && !tokensOut)) {
            if (msg.value < getCostForReturnDelivery(sourceChain)) {
                revert InsufficientMsgValue();
            }

            if (data.wrappedAsset == USDC && _state.isUsingCCTP) {
                sendUSDCWithPayloadToEvm(
                    sourceChain,
                    fromWormholeFormat(sourceAddress),
                    encodeUserPayload(data, true),
                    0,
                    _state.defaultGasLimit,
                    data.amount,
                    sourceChain, // refundChain
                    data.sender // refundAddress
                );
            } else {
                sendTokenWithPayloadToEvm(
                    sourceChain,
                    fromWormholeFormat(sourceAddress),
                    abi.encode(uint256(0), encodeUserPayload(data, false)), // encoding again so it's the same format as cctp messages
                    0,
                    _state.defaultGasLimit,
                    data.wrappedAsset,
                    data.amount,
                    sourceChain, // refundChain
                    data.sender // refundAddress
                );
            }
        } else if (msg.value > getCostForRefundDelivery(sourceChain)) {
            // not transferring any tokens and not refunding a failed deposit or repay
            // we need to return the roundtrip cost to the sender
            wormholeRelayer.sendToEvm{value: msg.value}(
                sourceChain,
                fromWormholeFormat(sourceAddress),
                abi.encode(uint256(0), encodeUserPayload(data, false)), // encoding again so it's the same format as cctp messages
                0, // receiverValue in Spoke chain native currency
                msg.value - getCostForRefundDelivery(sourceChain), // additional value sent in Hub chain native currency
                _state.refundGasLimit, // refund gas limit,
                sourceChain,
                data.sender,
                wormholeRelayer.getDefaultDeliveryProvider(),
                new VaaKey[](0),
                CONSISTENCY_LEVEL_FINALIZED
            );
        }
    }

    /**
     * @dev This function allows users to perform actions on the vault from the same chain as the vault using the native asset.
     * It checks if the action is allowed, updates the vault amounts, and if the action is Borrow or Withdraw, it sends the native asset to the user.
     * @param amount - The amount of the native asset.
     * @param weth - IWETH interface
     */
    function _sendNative(uint256 amount, IWETH weth) internal {
        weth.withdraw(amount);
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    /**
     * @dev Updates the vault's state to log either a deposit, borrow, withdraw, or repay
     *
     * @param action - the action (either Deposit, Borrow, Withdraw, or Repay)
     * @param vault - the address of the vault
     * @param assetAddress - the address of the relevant asset being logged
     * @param amount - the amount of the asset assetAddress being logged
     */
    function _updateVaultAmounts(HubSpokeStructs.Action action, address vault, address assetAddress, uint256 amount) internal {
        HubSpokeStructs.DenormalizedVaultAmount memory vaultAmounts = getVaultAmounts(vault, assetAddress);
        HubSpokeStructs.DenormalizedVaultAmount memory globalAmounts = getGlobalAmounts(assetAddress);

        if (action == HubSpokeStructs.Action.Deposit || action == HubSpokeStructs.Action.DepositNative) {
            vaultAmounts.deposited += amount;
            globalAmounts.deposited += amount;

            emit Deposit(vault, assetAddress, amount, vaultAmounts.deposited);
        } else if (action == HubSpokeStructs.Action.Withdraw) {
            vaultAmounts.deposited -= amount;
            globalAmounts.deposited -= amount;

            emit Withdraw(vault, assetAddress, amount, vaultAmounts.deposited);
        } else if (action == HubSpokeStructs.Action.Borrow) {
            vaultAmounts.borrowed += amount;
            globalAmounts.borrowed += amount;

            emit Borrow(vault, assetAddress, amount, vaultAmounts.borrowed);
        } else if (action == HubSpokeStructs.Action.Repay || action == HubSpokeStructs.Action.RepayNative) {
            if (amount > vaultAmounts.borrowed) {
                amount = vaultAmounts.borrowed;
            }
            vaultAmounts.borrowed -= amount;
            globalAmounts.borrowed -= amount;

            emit Repay(vault, assetAddress, amount, vaultAmounts.borrowed);
        }

        setVaultAmounts(vault, assetAddress, vaultAmounts);
        setGlobalAmounts(assetAddress, globalAmounts);
    }

    /**
     * @dev Validates whether the `msg.value` is sufficient to cover the quoted cost for return delivery
     * @param action The relayed action; we only validate `msg.value` when it's a borrow or withdraw
     * @param sourceChain The chain from which the payload and tokens were sent
     */
    function _checkMsgValueForReturnDelivery(HubSpokeStructs.Action action, uint16 sourceChain)
        internal
        view
        returns (bool valid, string memory error)
    {
        if (action != HubSpokeStructs.Action.Borrow && action != HubSpokeStructs.Action.Withdraw) return (true, "");

        valid = msg.value >= getCostForReturnDelivery(sourceChain);

        return (valid, ERROR_MSG_VALUE);
    }

    // ============ Admin Functions ============

    /**
     * @notice Allows the contract deployer to toggle whether we are using CCTP for USDC
     * NOTE: If `_circleMessageTransmitter` is the null address, it indicates CCTP is not supported on this chain, thus
     * we don't do anything.
     *
     * @param value: the new value for `isUsingCCTP`
     */
    function setIsUsingCCTP(bool value) external onlyOwner {
        if (address(circleMessageTransmitter) == address(0)) return; // zero address would indicate not using/supported

        _state.isUsingCCTP = value;
    }

    /**
     * @notice Withdraws reserves from the contract. If the amount is greater than the reserve balance, then
     * the entire reserve balance is withdrawn.
     * @param wrappedAsset: The address of the wrapped asset. Pass address(0) for native asset.
     * @param destination: The address to send the reserves to
     * @param amount: The amount of the wrapped asset to withdraw
     */
    function withdrawReserves(address wrappedAsset, address destination, uint256 amount) external onlyOwner {
        if (destination == address(0)) {
            revert ZeroAddress();
        }

        uint256 reserveBalance = wrappedAsset == address(0) ? address(this).balance : getReserveAmount(wrappedAsset);

        // can't withdraw more than reserve balance
        if (amount > reserveBalance) {
            amount = reserveBalance;
        }

        if (wrappedAsset == address(0)) {
            (bool success,) = payable(destination).call{value: amount}("");
            if (!success) revert TransferFailed();
        } else {
            // transfer reserve balance to destination
            IERC20(wrappedAsset).safeTransfer(destination, amount);
        }

        emit ReservesWithdrawn(wrappedAsset, amount, destination);
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        // this already checks for zero address
        OwnableUpgradeable.transferOwnership(newOwner);
        // also update registrationOwner defined in abstract contract Base in evm/lib/upgradeable-wormhole-solidity-sdk/src/WormholeRelayerSDK.sol
        // this is required to be able to register new WH message senders (Spokes)
        registrationOwner = newOwner;
    }

    function renounceOwnership() public view override onlyOwner {
        revert RenounceOwnershipDisabled();
    }

    /**
     * @notice Get the protocol's global reserve amount in an asset
     *
     * @param asset - the address of the asset
     * @return uint256 The amount of the asset in the protocol's reserve
     */
    function getReserveAmount(address asset) public view returns (uint256) {
        if (asset == address(0)) {
            revert ZeroAddress();
        }
        HubSpokeStructs.DenormalizedVaultAmount memory globalAmounts = getGlobalAmounts(asset);
        return IERC20(asset).balanceOf(address(this)) + globalAmounts.borrowed - globalAmounts.deposited;
    }

    function getSpokeAddress(uint256 chainId) public view returns (address) {
        return fromWormholeFormat(registeredSenders[uint16(chainId)]);
    }

    /**
     * @notice Pauses the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice fallback function to receive unwrapped native asset
     */
    fallback() external payable {}

    receive() external payable {}

    // OVERRIDES
    function _msgSender() internal view override(ContextUpgradeable) returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure override(ContextUpgradeable) returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../HubSpokeStructs.sol";
import "./HubState.sol";
import "../../interfaces/IInterestRateCalculator.sol";

/**
 * @title HubInterestUtilities
 * @notice Contract defining interest-related utility functions for the Hub contract
 */
contract HubInterestUtilities is HubState {

    /**
     * @dev Assets accrue interest over time, so at any given point in time the value of an asset is (amount of asset on day 1) * (the amount of interest that has accrued).
     * This function updates both the deposit and borrow interest accrual indices of the asset.
     *
     * @param assetAddress - The asset to update the interest accrual indices of
     */
    function updateAccrualIndices(address assetAddress) public {
        HubSpokeStructs.AccrualIndices memory accrualIndices = getCurrentAccrualIndices(assetAddress);
        setInterestAccrualIndices(assetAddress, accrualIndices);
        setLastActivityBlockTimestamp(assetAddress, block.timestamp);
        emit AccrualIndexUpdated(assetAddress, accrualIndices.deposited, accrualIndices.borrowed, block.timestamp);
    }

    /**
     * @dev Calculates the current accrual indices for a given asset.
     * It calculates the seconds elapsed since the last activity, the total assets deposited,
     * and the current interest accrual indices. If seconds elapsed and deposited are not zero,
     * it calculates the total assets borrowed, normalizes the deposited and borrowed amounts,
     * gets the asset info, and computes the interest factor, reserve factor, and reserve precision.
     * It then updates the borrowed and deposited accrual indices accordingly.
     * @param assetAddress The address of the asset for which to calculate the accrual indices.
     * @return AccrualIndices The current accrual indices for the given asset.
     */
    function getCurrentAccrualIndices(address assetAddress) public view returns (HubSpokeStructs.AccrualIndices memory) {
        uint256 secondsElapsed = block.timestamp - getLastActivityBlockTimestamp(assetAddress);
        HubSpokeStructs.StoredVaultAmount memory globalAssetAmounts = _state.totalAssets[assetAddress];
        HubSpokeStructs.AccrualIndices memory accrualIndices = getInterestAccrualIndices(assetAddress);
        if (secondsElapsed != 0 && globalAssetAmounts.amounts.borrowed != 0 && globalAssetAmounts.amounts.deposited != 0) {
            IAssetRegistry.AssetInfo memory assetInfo = getAssetInfo(assetAddress);
            IInterestRateCalculator assetCalculator = IInterestRateCalculator(assetInfo.interestRateCalculator);
            uint256 interestAccrualPrecision = getInterestAccrualIndexPrecision();
            (uint256 depositInterestFactor, uint256 borrowInterestFactor, uint256 precision) = assetCalculator
                .computeSourceInterestFactor(
                    secondsElapsed,
                    applyInterest(globalAssetAmounts, accrualIndices),
                    interestAccrualPrecision
                );

            accrualIndices.borrowed = accrualIndices.borrowed * borrowInterestFactor / precision;
            accrualIndices.deposited = accrualIndices.deposited * depositInterestFactor / precision;
        }
        return accrualIndices;
    }

    function applyInterest(address asset, HubSpokeStructs.StoredVaultAmount memory vaultAmount) internal view returns (HubSpokeStructs.DenormalizedVaultAmount memory) {
        return applyInterest(vaultAmount, getCurrentAccrualIndices(asset));
    }

    function applyInterest(HubSpokeStructs.StoredVaultAmount memory vaultAmount, HubSpokeStructs.AccrualIndices memory indices) internal pure returns (HubSpokeStructs.DenormalizedVaultAmount memory) {
        // no need to check the deposit index
        // if the borrow index didn't change then the deposit index didn't either
        if (indices.borrowed == vaultAmount.accrualIndices.borrowed) {
            // the amounts are already up to date
            // no need to recompute
            return vaultAmount.amounts;
        }

        return HubSpokeStructs.DenormalizedVaultAmount({
            deposited: vaultAmount.amounts.deposited == 0 ? 0 : vaultAmount.amounts.deposited * indices.deposited / vaultAmount.accrualIndices.deposited,
            borrowed: vaultAmount.amounts.borrowed == 0 ? 0 : vaultAmount.amounts.borrowed * indices.borrowed / vaultAmount.accrualIndices.borrowed
        });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../interfaces/ILiquidationCalculator.sol";
import "../../interfaces/IHubPriceUtilities.sol";
import "../../interfaces/IAssetRegistry.sol";
import "../HubSpokeStructs.sol";
import "../HubSpokeEvents.sol";

/**
 * @title HubState
 * @notice Contract holding state variable for the Hub contract
 */
abstract contract HubState is OwnableUpgradeable, HubSpokeEvents {

    error InvalidPrecision();

    HubSpokeStructs.HubState _state;

    function getAssetInfo(address assetAddress) internal view virtual returns (IAssetRegistry.AssetInfo memory) {
        return _state.assetRegistry.getAssetInfo(assetAddress);
    }

    function consistencyLevel() public view returns (uint8) {
        return _state.consistencyLevel;
    }

    function getLiquidationCalculator() public view returns (ILiquidationCalculator) {
        return _state.liquidationCalculator;
    }

    function getPriceUtilities() public view returns (IHubPriceUtilities) {
        return _state.priceUtilities;
    }

    function getAssetRegistry() public view returns (IAssetRegistry) {
        return _state.assetRegistry;
    }

    function getLiquidationFeeAndPrecision() public view returns (uint256, uint256) {
        return (_state.liquidationFee, _state.liquidationFeePrecision);
    }

    function getIsUsingCCTP() public view returns (bool) {
        return _state.isUsingCCTP;
    }

    function getLastActivityBlockTimestamp(address assetAddress) public view returns (uint256) {
        return _state.lastActivityBlockTimestamps[assetAddress];
    }

    function getInterestAccrualIndices(address assetAddress) public view returns (HubSpokeStructs.AccrualIndices memory) {
        if (_state.indices[assetAddress].deposited == 0 || _state.indices[assetAddress].borrowed == 0) {
            // seed with precision if not set
            return HubSpokeStructs.AccrualIndices({deposited: getInterestAccrualIndexPrecision(), borrowed: getInterestAccrualIndexPrecision()});
        }

        return _state.indices[assetAddress];
    }

    function getInterestAccrualIndexPrecision() public view returns (uint256) {
        return _state.interestAccrualIndexPrecision;
    }

    function setLastActivityBlockTimestamp(address assetAddress, uint256 blockTimestamp) internal {
        _state.lastActivityBlockTimestamps[assetAddress] = blockTimestamp;
    }

    function setInterestAccrualIndices(address assetAddress, HubSpokeStructs.AccrualIndices memory indices) internal {
        _state.indices[assetAddress] = indices;
    }

    /**
     * @notice Sets the default gas limit used for wormhole relay quotes
     * @param value: The new value for `defaultGasLimit`
     */
    function setDefaultGasLimit(uint256 value) public onlyOwner {
        _state.defaultGasLimit = value;
    }

    /**
     * @dev Sets the gas limit used for refunding of returnCost amount
     * @param value: The new value for `refundGasLimit`
     */
    function setRefundGasLimit(uint256 value) public onlyOwner {
        _state.refundGasLimit = value;
    }

    /**
     * @notice Updates the liquidation fee
     * @param _liquidationFee: The new liquidation fee
     */
    function setLiquidationFee(uint256 _liquidationFee, uint256 _precision) public onlyOwner {
        if (_liquidationFee > _precision) {
            revert InvalidPrecision();
        }
        _state.liquidationFee = _liquidationFee;
        _state.liquidationFeePrecision = _precision;
        emit SetLiquidationFee(_liquidationFee, _precision);
    }

    /**
     * @notice Sets the liquidation calculator
     * @param _calculator: The address of the liquidation calculator
     */
    function setLiquidationCalculator(address _calculator) external onlyOwner {
        _state.liquidationCalculator = ILiquidationCalculator(_calculator);
    }

    function setPriceUtilities(address _priceUtilities) external onlyOwner {
        _state.priceUtilities = IHubPriceUtilities(_priceUtilities);
    }

    function setAssetRegistry(address _assetRegistry) external onlyOwner {
        _state.assetRegistry = IAssetRegistry(_assetRegistry);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/IERC20decimals.sol";

/**
 * @title TokenBridgeUtilities
 * @notice A set of internal utility functions
 */
library TokenBridgeUtilities {
    error TooManyDecimalPlaces();

    uint8 public constant MAX_DECIMALS = 8;

    /**
     * @dev This function checks if the asset amount is valid for the token bridge
     * @param assetAddress The address of the asset
     * @param assetAmount The amount of the asset
     */
    function requireAssetAmountValidForTokenBridge(address assetAddress, uint256 assetAmount) public view {
        uint8 decimals;
        if (assetAddress == address(0)) {
            // native ETH
            decimals = 18;
        } else {
            decimals = IERC20decimals(assetAddress).decimals();
        }

        if (decimals > MAX_DECIMALS && trimDust(assetAmount, decimals) != assetAmount) {
            revert TooManyDecimalPlaces();
        }
    }

    function trimDust(uint256 amount, uint8 decimals) public pure returns (uint256) {
        return denormalizeAmount(normalizeAmount(amount, decimals), decimals);
    }

    /**
     * @dev This function normalizes the amount based on the decimals
     * @param amount The amount to be normalized
     * @param decimals The number of decimals
     * @return The normalized amount
     */
    function normalizeAmount(uint256 amount, uint8 decimals) public pure returns (uint256) {
        if (decimals > MAX_DECIMALS) {
            amount /= uint256(10) ** (decimals - MAX_DECIMALS);
        }

        return amount;
    }

    /**
     * @dev This function normalizes the amount based on the decimals
     * @param amount The amount to be normalized
     * @param decimals The number of decimals
     * @return The normalized amount
     */
    function denormalizeAmount(uint256 amount, uint8 decimals) public pure returns (uint256) {
        if (decimals > MAX_DECIMALS) {
            amount *= uint256(10) ** (decimals - MAX_DECIMALS);
        }

        return amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {TokenReceiver} from "@wormhole-upgradeable/WormholeRelayerSDK.sol";
import {CCTPReceiver} from "@wormhole-upgradeable/CCTPBase.sol";

abstract contract TokenReceiverWithCCTP is CCTPReceiver, TokenReceiver {
    /**
     * @dev Overriding the superclasses' function to choose whether to use CCTP or not, based on the implemented
     * `isUsingCCTP` function
     * @param payload - the payload received
     * @param additionalVaas - any wormhole VAAs received
     * @param sourceAddress - the source address of the tokens
     * @param sourceChain - the source chain of the tokens
     * @param deliveryHash - the delivery hash of the tokens
     */
    function receiveWormholeMessages(
          bytes memory payload,
          bytes[] memory additionalVaas,
          bytes32 sourceAddress,
          uint16 sourceChain,
          bytes32 deliveryHash
    ) public virtual override(TokenReceiver, CCTPReceiver) payable {
        if (messageWithCCTP(payload)) {
            _receiveWormholeMessagesWithCCTP(payload, additionalVaas, sourceAddress, sourceChain, deliveryHash);
        } else {
            _receiveWormholeMessages(payload, additionalVaas, sourceAddress, sourceChain, deliveryHash);
        }
    }

    /**
     * @dev Virtual function to decode `payload` and determine if using CCTP or not
     * @param payload - the payload received
     */
    function messageWithCCTP(bytes memory payload) internal view virtual returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "@wormhole-upgradeable/interfaces/IWETH.sol";
import "../contracts/HubSpokeStructs.sol";

interface IAssetRegistry {
    struct AssetInfo {
        uint256 collateralizationRatioDeposit;
        uint256 collateralizationRatioBorrow;
        uint8 decimals;
        address interestRateCalculator;
        bool exists;
        uint256 borrowLimit;
        uint256 supplyLimit;
        uint256 maxLiquidationPortion;
        uint256 maxLiquidationBonus; // 1e6 precision; 130e4 = 130% = 1.3; the liquidator gets 30% over what he repays
    }

    function registerAsset(
        address assetAddress,
        uint256 collateralizationRatioDeposit,
        uint256 collateralizationRatioBorrow,
        address interestRateCalculator,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus
    ) external;

    function getAssetInfo(address assetAddress) external view returns (AssetInfo memory);

    function setAssetParams(
        address assetAddress,
        uint256 borrowLimit,
        uint256 supplyLimit,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus,
        address interestRateCalculatorAddress
    ) external;

    function setCollateralizationRatios(address _asset, uint256 _deposit, uint256 _borrow) external;

    function getRegisteredAssets() external view returns (address[] memory);

    function getCollateralizationRatioPrecision() external view returns (uint256);

    function getMaxLiquidationPortionPrecision() external view returns (uint256);

    function WETH() external view returns (IWETH);

    function getMaxDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20decimals is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../contracts/HubSpokeStructs.sol";
import "./ILiquidationCalculator.sol";
import "./IHubPriceUtilities.sol";
import "./IAssetRegistry.sol";

/**
 * @notice interface for external contracts that need to access Hub state
 */
interface IHub {
    function checkVaultHasAssets(address vault, address assetAddress, uint256 normalizedAmount, bool shouldRevert)
        external
        view
        returns (bool success, string memory error);

    function checkProtocolGloballyHasAssets(
        address assetAddress,
        uint256 normalizedAmount,
        bool shouldRevert
    ) external view returns (bool success, string memory error);

    function checkProtocolGloballyHasAssets(
        address assetAddress,
        uint256 normalizedAmount,
        bool shouldRevert,
        uint256 borrowLimit
    ) external view returns (bool success, string memory error);

    function getInterestAccrualIndices(address assetAddress)
        external
        view
        returns (HubSpokeStructs.AccrualIndices memory);

    function getInterestAccrualIndexPrecision() external view returns (uint256);

    function getVaultAmounts(address vaultOwner, address assetAddress)
        external
        view
        returns (HubSpokeStructs.DenormalizedVaultAmount memory);

    function getCurrentAccrualIndices(address assetAddress)
        external
        view
        returns (HubSpokeStructs.AccrualIndices memory);

    function updateAccrualIndices(address assetAddress) external;

    function getLastActivityBlockTimestamp(address assetAddress) external view returns (uint256);

    function getGlobalAmounts(address assetAddress) external view returns (HubSpokeStructs.DenormalizedVaultAmount memory);

    function getReserveAmount(address assetAddress) external view returns (uint256);

    function getLiquidationCalculator() external view returns (ILiquidationCalculator);

    function getPriceUtilities() external view returns (IHubPriceUtilities);

    function getAssetRegistry() external view returns (IAssetRegistry);

    function getLiquidationFeeAndPrecision() external view returns (uint256, uint256);

    function liquidation(ILiquidationCalculator.LiquidationInput memory input) external;

    function userActions(HubSpokeStructs.Action action, address asset, uint256 amount) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "./IHub.sol";
import "./IAssetRegistry.sol";
import "./ISynonymPriceOracle.sol";
import "../contracts/HubSpokeStructs.sol";

interface IHubPriceUtilities {
    function getAssetRegistry() external view returns (IAssetRegistry);
    function getPrices(address assetAddress) external view returns (uint256, uint256, uint256, uint256);
    function getVaultEffectiveNotionals(address vaultOwner, bool collateralizationRatios) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function calculateNotionals(address asset, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function calculateEffectiveNotionals(address asset, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function invertNotionals(address asset, HubSpokeStructs.NotionalVaultAmount memory realValues) external view returns (HubSpokeStructs.DenormalizedVaultAmount memory);
    function applyCollateralizationRatios(address asset, HubSpokeStructs.NotionalVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function removeCollateralizationRatios(address asset, HubSpokeStructs.NotionalVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function checkAllowedToDeposit(address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function checkAllowedToWithdraw(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function checkAllowedToBorrow(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function checkAllowedToRepay(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function getHub() external view returns (IHub);
    function setHub(IHub _hub) external;
    function getPriceOracle() external view returns (ISynonymPriceOracle);
    function setPriceOracle(ISynonymPriceOracle _priceOracle) external;
    function getPriceStandardDeviations() external view returns (uint256, uint256);
    function setPriceStandardDeviations(uint256 _priceStandardDeviations, uint256 _precision) external;
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../contracts/HubSpokeStructs.sol";

interface IInterestRateCalculator {
    struct InterestRates {
        uint256 depositRate;
        uint256 borrowRate;
        uint256 precision;
    }

    struct InterestRateBase {
        uint256 interestRate;
        uint256 precision;
    }

    /**
     * @notice Computes the source interest factor
     * @param secondsElapsed The number of seconds elapsed
     * @param globalAssetAmount The global denormalized asset amounts
     * @param interestAccrualIndexPrecision The precision of the interest accrual index
     * @return depositInterestFactor interest factor for deposits
     * @return borrowInterestFactor interest factor for borrows
     * @return precision precision
     */
    function computeSourceInterestFactor(
        uint256 secondsElapsed,
        HubSpokeStructs.DenormalizedVaultAmount memory globalAssetAmount,
        uint256 interestAccrualIndexPrecision
    ) external view returns (uint256 depositInterestFactor, uint256 borrowInterestFactor, uint256 precision);

    /**
     * @notice utility function to return current APY for an asset
     * @param globalAssetAmount The global denormalized amounts of the asset
     * @return interestRates rate * model.ratePrecision
     */
    function currentInterestRate(HubSpokeStructs.DenormalizedVaultAmount memory globalAssetAmount)
        external
        view
        returns (InterestRates memory);

    function getReserveFactorAndPrecision() external view returns (uint256 reserveFactor, uint256 reservePrecision);

    function getInterestRateFromPoolUtilization(HubSpokeStructs.DenormalizedVaultAmount memory globalAssetAmount) view external returns (InterestRateBase memory);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../contracts/HubSpokeStructs.sol";

interface ILiquidationCalculator {
    /**
     * @param assetAddress - The address of the repaid/received asset
     * @param repaidAmount - The amount of the asset that is being repaid (can be zero)
     * @param receivedAmount - The amount of the asset that is being received (can be zero)
     * @param depositTakeover - A flag if the liquidator will take the deposit of the debtor instead of collateral tokens
     */
    struct DenormalizedLiquidationAsset {
        address assetAddress;
        uint256 repaidAmount;
        uint256 receivedAmount;
        bool depositTakeover;
    }

    /**
     * @param vault - the address of the vault that is being liquidated
     */
    struct LiquidationInput {
        address vault;
        DenormalizedLiquidationAsset[] assets;
    }

    function checkLiquidationInputsValid(LiquidationInput memory input) external view;
    function checkAllowedToLiquidate(LiquidationInput memory input) external view;
    function getMaxHealthFactor() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ISynonymPriceSource} from "./ISynonymPriceSource.sol";

interface ISynonymPriceOracle is ISynonymPriceSource {
    struct PriceSource {
        ISynonymPriceSource priceSource;
        uint256 maxPriceAge;
    }

    function getPrice(address _asset) external view returns (Price memory price);
    function setPriceSource(address _asset, PriceSource memory _priceSource) external;
    function removePriceSource(address _asset) external;
    function getPriceSource(address _asset) external view returns (PriceSource memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISynonymPriceSource {
    error NoPriceForAsset();
    error StalePrice();

    struct Price {
        uint256 price;
        uint256 confidence;
        uint256 precision;
        uint256 updatedAt;
    }

    function getPrice(address _asset, uint256 _maxAge) external view returns (Price memory price);
    function priceAvailable(address _asset) external view returns (bool);
    function outputAsset() external view returns (string memory);
}