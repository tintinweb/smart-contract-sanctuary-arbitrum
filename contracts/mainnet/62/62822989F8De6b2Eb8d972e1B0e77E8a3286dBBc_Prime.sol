// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import "./IAccessControlManagerV8.sol";

/**
 * @title AccessControlledV8
 * @author Venus
 * @notice This contract is helper between access control manager and actual contract. This contract further inherited by other contract (using solidity 0.8.13)
 * to integrate access controlled mechanism. It provides initialise methods and verifying access methods.
 */
abstract contract AccessControlledV8 is Initializable, Ownable2StepUpgradeable {
    /// @notice Access control manager contract
    IAccessControlManagerV8 private _accessControlManager;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Emitted when access control manager contract address is changed
    event NewAccessControlManager(address oldAccessControlManager, address newAccessControlManager);

    /// @notice Thrown when the action is prohibited by AccessControlManager
    error Unauthorized(address sender, address calledContract, string methodSignature);

    function __AccessControlled_init(address accessControlManager_) internal onlyInitializing {
        __Ownable2Step_init();
        __AccessControlled_init_unchained(accessControlManager_);
    }

    function __AccessControlled_init_unchained(address accessControlManager_) internal onlyInitializing {
        _setAccessControlManager(accessControlManager_);
    }

    /**
     * @notice Sets the address of AccessControlManager
     * @dev Admin function to set address of AccessControlManager
     * @param accessControlManager_ The new address of the AccessControlManager
     * @custom:event Emits NewAccessControlManager event
     * @custom:access Only Governance
     */
    function setAccessControlManager(address accessControlManager_) external onlyOwner {
        _setAccessControlManager(accessControlManager_);
    }

    /**
     * @notice Returns the address of the access control manager contract
     */
    function accessControlManager() external view returns (IAccessControlManagerV8) {
        return _accessControlManager;
    }

    /**
     * @dev Internal function to set address of AccessControlManager
     * @param accessControlManager_ The new address of the AccessControlManager
     */
    function _setAccessControlManager(address accessControlManager_) internal {
        require(address(accessControlManager_) != address(0), "invalid acess control manager address");
        address oldAccessControlManager = address(_accessControlManager);
        _accessControlManager = IAccessControlManagerV8(accessControlManager_);
        emit NewAccessControlManager(oldAccessControlManager, accessControlManager_);
    }

    /**
     * @notice Reverts if the call is not allowed by AccessControlManager
     * @param signature Method signature
     */
    function _checkAccessAllowed(string memory signature) internal view {
        bool isAllowedToCall = _accessControlManager.isAllowedToCall(msg.sender, signature);

        if (!isAllowedToCall) {
            revert Unauthorized(msg.sender, address(this), signature);
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title IAccessControlManagerV8
 * @author Venus
 * @notice Interface implemented by the `AccessControlManagerV8` contract.
 */
interface IAccessControlManagerV8 is IAccessControl {
    function giveCallPermission(address contractAddress, string calldata functionSig, address accountToPermit) external;

    function revokeCallPermission(
        address contractAddress,
        string calldata functionSig,
        address accountToRevoke
    ) external;

    function isAllowedToCall(address account, string calldata functionSig) external view returns (bool);

    function hasPermission(
        address account,
        address contractAddress,
        string calldata functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

interface OracleInterface {
    function getPrice(address asset) external view returns (uint256);
}

interface ResilientOracleInterface is OracleInterface {
    function updatePrice(address vToken) external;

    function updateAssetPrice(address asset) external;

    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface TwapInterface is OracleInterface {
    function updateTwap(address asset) external returns (uint256);
}

interface BoundValidatorInterface {
    function validatePriceWithAnchorPrice(
        address asset,
        uint256 reporterPrice,
        uint256 anchorPrice
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

/// @dev Base unit for computations, usually used in scaling (multiplications, divisions)
uint256 constant EXP_SCALE = 1e18;

/// @dev A unit (literal one) in EXP_SCALE, usually used in additions/subtractions
uint256 constant MANTISSA_ONE = EXP_SCALE;

/// @dev The approximate number of seconds per year
uint256 constant SECONDS_PER_YEAR = 31_536_000;

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

/**
 * @title MaxLoopsLimitHelper
 * @author Venus
 * @notice Abstract contract used to avoid collection with too many items that would generate gas errors and DoS.
 */
abstract contract MaxLoopsLimitHelper {
    // Limit for the loops to avoid the DOS
    uint256 public maxLoopsLimit;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /// @notice Emitted when max loops limit is set
    event MaxLoopsLimitUpdated(uint256 oldMaxLoopsLimit, uint256 newmaxLoopsLimit);

    /// @notice Thrown an error on maxLoopsLimit exceeds for any loop
    error MaxLoopsLimitExceeded(uint256 loopsLimit, uint256 requiredLoops);

    /**
     * @notice Set the limit for the loops can iterate to avoid the DOS
     * @param limit Limit for the max loops can execute at a time
     */
    function _setMaxLoopsLimit(uint256 limit) internal {
        require(limit > maxLoopsLimit, "Comptroller: Invalid maxLoopsLimit");

        uint256 oldMaxLoopsLimit = maxLoopsLimit;
        maxLoopsLimit = limit;

        emit MaxLoopsLimitUpdated(oldMaxLoopsLimit, limit);
    }

    /**
     * @notice Compare the maxLoopsLimit with number of the times loop iterate
     * @param len Length of the loops iterate
     * @custom:error MaxLoopsLimitExceeded error is thrown when loops length exceeds maxLoopsLimit
     */
    function _ensureMaxLoops(uint256 len) internal view {
        if (len > maxLoopsLimit) {
            revert MaxLoopsLimitExceeded(maxLoopsLimit, len);
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import { SECONDS_PER_YEAR } from "./constants.sol";

abstract contract TimeManagerV8 {
    /// @notice Stores blocksPerYear if isTimeBased is true else secondsPerYear is stored
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable blocksOrSecondsPerYear;

    /// @notice Acknowledges if a contract is time based or not
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bool public immutable isTimeBased;

    /// @notice Stores the current block timestamp or block number depending on isTimeBased
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    function() view returns (uint256) private immutable _getCurrentSlot;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    /// @notice Thrown when blocks per year is invalid
    error InvalidBlocksPerYear();

    /// @notice Thrown when time based but blocks per year is provided
    error InvalidTimeBasedConfiguration();

    /**
     * @param timeBased_ A boolean indicating whether the contract is based on time or block
     * If timeBased is true than blocksPerYear_ param is ignored as blocksOrSecondsPerYear is set to SECONDS_PER_YEAR
     * @param blocksPerYear_ The number of blocks per year
     * @custom:error InvalidBlocksPerYear is thrown if blocksPerYear entered is zero and timeBased is false
     * @custom:error InvalidTimeBasedConfiguration is thrown if blocksPerYear entered is non zero and timeBased is true
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor(bool timeBased_, uint256 blocksPerYear_) {
        if (!timeBased_ && blocksPerYear_ == 0) {
            revert InvalidBlocksPerYear();
        }

        if (timeBased_ && blocksPerYear_ != 0) {
            revert InvalidTimeBasedConfiguration();
        }

        isTimeBased = timeBased_;
        blocksOrSecondsPerYear = timeBased_ ? SECONDS_PER_YEAR : blocksPerYear_;
        _getCurrentSlot = timeBased_ ? _getBlockTimestamp : _getBlockNumber;
    }

    /**
     * @dev Function to simply retrieve block number or block timestamp
     * @return Current block number or block timestamp
     */
    function getBlockNumberOrTimestamp() public view virtual returns (uint256) {
        return _getCurrentSlot();
    }

    /**
     * @dev Returns the current timestamp in seconds
     * @return The current timestamp
     */
    function _getBlockTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns the current block number
     * @return The current block number
     */
    function _getBlockNumber() private view returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.25;

interface InterfaceComptroller {
    function markets(address) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

/**
 * @title PoolRegistryInterface
 * @author Venus
 * @notice Interface implemented by `PoolRegistry`.
 */
interface PoolRegistryInterface {
    /**
     * @notice Struct for a Venus interest rate pool.
     */
    struct VenusPool {
        string name;
        address creator;
        address comptroller;
        uint256 blockPosted;
        uint256 timestampPosted;
    }

    /// @notice Get a pool by comptroller address
    function getPoolByComptroller(address comptroller) external view returns (VenusPool memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

import { PrimeStorageV1 } from "../PrimeStorage.sol";

/**
 * @title IPrime
 * @author Venus
 * @notice Interface for Prime Token
 */
interface IPrime {
    struct APRInfo {
        // supply APR of the user in BPS
        uint256 supplyAPR;
        // borrow APR of the user in BPS
        uint256 borrowAPR;
        // total score of the market
        uint256 totalScore;
        // score of the user
        uint256 userScore;
        // capped XVS balance of the user
        uint256 xvsBalanceForScore;
        // capital of the user
        uint256 capital;
        // capped supply of the user
        uint256 cappedSupply;
        // capped borrow of the user
        uint256 cappedBorrow;
        // capped supply of user in USD
        uint256 supplyCapUSD;
        // capped borrow of user in USD
        uint256 borrowCapUSD;
    }

    struct Capital {
        // capital of the user
        uint256 capital;
        // capped supply of the user
        uint256 cappedSupply;
        // capped borrow of the user
        uint256 cappedBorrow;
        // capped supply of user in USD
        uint256 supplyCapUSD;
        // capped borrow of user in USD
        uint256 borrowCapUSD;
    }

    /**
     * @notice Returns boosted pending interest accrued for a user for all markets
     * @param user the account for which to get the accrued interests
     * @return pendingRewards the number of underlying tokens accrued by the user for all markets
     */
    function getPendingRewards(address user) external returns (PrimeStorageV1.PendingReward[] memory pendingRewards);

    /**
     * @notice Update total score of multiple users and market
     * @param users accounts for which we need to update score
     */
    function updateScores(address[] memory users) external;

    /**
     * @notice Update value of alpha
     * @param _alphaNumerator numerator of alpha. If alpha is 0.5 then numerator is 1
     * @param _alphaDenominator denominator of alpha. If alpha is 0.5 then denominator is 2
     */
    function updateAlpha(uint128 _alphaNumerator, uint128 _alphaDenominator) external;

    /**
     * @notice Update multipliers for a market
     * @param market address of the market vToken
     * @param supplyMultiplier new supply multiplier for the market, scaled by 1e18
     * @param borrowMultiplier new borrow multiplier for the market, scaled by 1e18
     */
    function updateMultipliers(address market, uint256 supplyMultiplier, uint256 borrowMultiplier) external;

    /**
     * @notice Add a market to prime program
     * @param comptroller address of the comptroller
     * @param market address of the market vToken
     * @param supplyMultiplier the multiplier for supply cap. It should be converted to 1e18
     * @param borrowMultiplier the multiplier for borrow cap. It should be converted to 1e18
     */
    function addMarket(
        address comptroller,
        address market,
        uint256 supplyMultiplier,
        uint256 borrowMultiplier
    ) external;

    /**
     * @notice Set limits for total tokens that can be minted
     * @param _irrevocableLimit total number of irrevocable tokens that can be minted
     * @param _revocableLimit total number of revocable tokens that can be minted
     */
    function setLimit(uint256 _irrevocableLimit, uint256 _revocableLimit) external;

    /**
     * @notice Directly issue prime tokens to users
     * @param isIrrevocable are the tokens being issued
     * @param users list of address to issue tokens to
     */
    function issue(bool isIrrevocable, address[] calldata users) external;

    /**
     * @notice Executed by XVSVault whenever user's XVSVault balance changes
     * @param user the account address whose balance was updated
     */
    function xvsUpdated(address user) external;

    /**
     * @notice accrues interest and updates score for an user for a specific market
     * @param user the account address for which to accrue interest and update score
     * @param market the market for which to accrue interest and update score
     */
    function accrueInterestAndUpdateScore(address user, address market) external;

    /**
     * @notice For claiming prime token when staking period is completed
     */
    function claim() external;

    /**
     * @notice For burning any prime token
     * @param user the account address for which the prime token will be burned
     */
    function burn(address user) external;

    /**
     * @notice To pause or unpause claiming of interest
     */
    function togglePause() external;

    /**
     * @notice For user to claim boosted yield
     * @param vToken the market for which claim the accrued interest
     * @return amount the amount of tokens transferred to the user
     */
    function claimInterest(address vToken) external returns (uint256);

    /**
     * @notice For user to claim boosted yield
     * @param vToken the market for which claim the accrued interest
     * @param user the user for which to claim the accrued interest
     * @return amount the amount of tokens transferred to the user
     */
    function claimInterest(address vToken, address user) external returns (uint256);

    /**
     * @notice Distributes income from market since last distribution
     * @param vToken the market for which to distribute the income
     */
    function accrueInterest(address vToken) external;

    /**
     * @notice Returns boosted interest accrued for a user
     * @param vToken the market for which to fetch the accrued interest
     * @param user the account for which to get the accrued interest
     * @return interestAccrued the number of underlying tokens accrued by the user since the last accrual
     */
    function getInterestAccrued(address vToken, address user) external returns (uint256);

    /**
     * @notice Retrieves an array of all available markets
     * @return an array of addresses representing all available markets
     */
    function getAllMarkets() external view returns (address[] memory);

    /**
     * @notice fetch the numbers of seconds remaining for staking period to complete
     * @param user the account address for which we are checking the remaining time
     * @return timeRemaining the number of seconds the user needs to wait to claim prime token
     */
    function claimTimeRemaining(address user) external view returns (uint256);

    /**
     * @notice Returns supply and borrow APR for user for a given market
     * @param market the market for which to fetch the APR
     * @param user the account for which to get the APR
     * @return aprInfo APR information for the user for the given market
     */
    function calculateAPR(address market, address user) external view returns (APRInfo memory aprInfo);

    /**
     * @notice Returns supply and borrow APR for estimated supply, borrow and XVS staked
     * @param market the market for which to fetch the APR
     * @param user the account for which to get the APR
     * @param borrow hypothetical borrow amount
     * @param supply hypothetical supply amount
     * @param xvsStaked hypothetical staked XVS amount
     * @return aprInfo APR information for the user for the given market
     */
    function estimateAPR(
        address market,
        address user,
        uint256 borrow,
        uint256 supply,
        uint256 xvsStaked
    ) external view returns (APRInfo memory aprInfo);

    /**
     * @notice the total income that's going to be distributed in a year to prime token holders
     * @param vToken the market for which to fetch the total income that's going to distributed in a year
     * @return amount the total income
     */
    function incomeDistributionYearly(address vToken) external view returns (uint256 amount);

    /**
     * @notice Returns if user is a prime holder
     * @return isPrimeHolder true if user is a prime holder
     */
    function isUserPrimeHolder(address user) external view returns (bool);

    /**
     * @notice Set the limit for the loops can iterate to avoid the DOS
     * @param loopsLimit Number of loops limit
     */
    function setMaxLoopsLimit(uint256 loopsLimit) external;

    /**
     * @notice Update staked at timestamp for multiple users
     * @param users accounts for which we need to update staked at timestamp
     * @param timestamps new staked at timestamp for the users
     */
    function setStakedAt(address[] calldata users, uint256[] calldata timestamps) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title IPrimeLiquidityProvider
 * @author Venus
 * @notice Interface for PrimeLiquidityProvider
 */
interface IPrimeLiquidityProvider {
    /**
     * @notice Initialize the distribution of the token
     * @param tokens_ Array of addresses of the tokens to be intialized
     */
    function initializeTokens(address[] calldata tokens_) external;

    /**
     * @notice Pause fund transfer of tokens to Prime contract
     */
    function pauseFundsTransfer() external;

    /**
     * @notice Resume fund transfer of tokens to Prime contract
     */
    function resumeFundsTransfer() external;

    /**
     * @notice Set distribution speed (amount of token distribute per block or second)
     * @param tokens_ Array of addresses of the tokens
     * @param distributionSpeeds_ New distribution speeds for tokens
     */
    function setTokensDistributionSpeed(address[] calldata tokens_, uint256[] calldata distributionSpeeds_) external;

    /**
     * @notice Set max distribution speed for token (amount of maximum token distribute per block or second)
     * @param tokens_ Array of addresses of the tokens
     * @param maxDistributionSpeeds_ New distribution speeds for tokens
     */
    function setMaxTokensDistributionSpeed(
        address[] calldata tokens_,
        uint256[] calldata maxDistributionSpeeds_
    ) external;

    /**
     * @notice Set the prime token contract address
     * @param prime_ The new address of the prime token contract
     */
    function setPrimeToken(address prime_) external;

    /**
     * @notice Claim all the token accrued till last block or second
     * @param token_ The token to release to the Prime contract
     */
    function releaseFunds(address token_) external;

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to user
     * @param token_ The address of the ERC-20 token to sweep
     * @param to_ The address of the recipient
     * @param amount_ The amount of tokens needs to transfer
     */
    function sweepToken(IERC20Upgradeable token_, address to_, uint256 amount_) external;

    /**
     * @notice Accrue token by updating the distribution state
     * @param token_ Address of the token
     */
    function accrueTokens(address token_) external;

    /**
     * @notice Set the limit for the loops can iterate to avoid the DOS
     * @param loopsLimit Limit for the max loops can execute at a time
     */
    function setMaxLoopsLimit(uint256 loopsLimit) external;

    /**
     * @notice Get rewards per block or second for token
     * @param token_ Address of the token
     * @return speed returns the per block or second reward
     */
    function getEffectiveDistributionSpeed(address token_) external view returns (uint256);

    /**
     * @notice Get the amount of tokens accrued
     * @param token_ Address of the token
     * @return Amount of tokens that are accrued
     */
    function tokenAmountAccrued(address token_) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

interface IVToken {
    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function underlying() external view returns (address);

    function totalBorrows() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

interface IXVSVault {
    function getUserInfo(
        address _rewardToken,
        uint256 _pid,
        address _user
    ) external view returns (uint256 amount, uint256 rewardDebt, uint256 pendingWithdrawals);

    function xvsAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
// solhint-disable var-name-mixedcase

pragma solidity 0.8.25;

import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import { FixedMath0x } from "./FixedMath0x.sol";

using SafeCastUpgradeable for uint256;

error InvalidFixedPoint();

/**
 * @title FixedMath
 * @author Venus
 * @notice FixedMath library is used for complex mathematical operations
 */
library FixedMath {
    error InvalidFraction(uint256 n, uint256 d);

    /**
     * @notice Convert some uint256 fraction `n` numerator / `d` denominator to a fixed-point number `f`.
     * @param n numerator
     * @param d denominator
     * @return fixed-point number
     */
    function _toFixed(uint256 n, uint256 d) internal pure returns (int256) {
        if (d.toInt256() < n.toInt256()) revert InvalidFraction(n, d);

        return (n.toInt256() * FixedMath0x.FIXED_1) / int256(d.toInt256());
    }

    /**
     * @notice Divide some unsigned int `u` by a fixed point number `f`
     * @param u unsigned dividend
     * @param f fixed point divisor, in FIXED_1 units
     * @return unsigned int quotient
     */
    function _uintDiv(uint256 u, int256 f) internal pure returns (uint256) {
        if (f < 0) revert InvalidFixedPoint();
        // multiply `u` by FIXED_1 to cancel out the built-in FIXED_1 in f
        return uint256((u.toInt256() * FixedMath0x.FIXED_1) / f);
    }

    /**
     * @notice Multiply some unsigned int `u` by a fixed point number `f`
     * @param u unsigned multiplicand
     * @param f fixed point multiplier, in FIXED_1 units
     * @return unsigned int product
     */
    function _uintMul(uint256 u, int256 f) internal pure returns (uint256) {
        if (f < 0) revert InvalidFixedPoint();
        // divide the product by FIXED_1 to cancel out the built-in FIXED_1 in f
        return uint256((u.toInt256() * f) / FixedMath0x.FIXED_1);
    }

    /// @notice see FixedMath0x
    function _ln(int256 x) internal pure returns (int256) {
        return FixedMath0x._ln(x);
    }

    /// @notice see FixedMath0x
    function _exp(int256 x) internal pure returns (int256) {
        return FixedMath0x._exp(x);
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable max-line-length

pragma solidity 0.8.25;

// Below is code from 0x's LibFixedMath.sol. Changes:
// - addition of 0.8-style errors
// - removal of unused functions
// - added comments for clarity
// https://github.com/0xProject/exchange-v3/blob/aae46bef841bfd1cc31028f41793db4fe7197084/contracts/staking/contracts/src/libs/LibFixedMath.sol

/*

  Copyright 2017 Bprotocol Foundation, 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/
/// Thrown when the natural log function is given too large of an argument
error LnTooLarge(int256 x);
/// Thrown when the natural log would have returned a number outside of ℝ
error LnNonRealResult(int256 x);
/// Thrown when exp is given too large of an argument
error ExpTooLarge(int256 x);
/// Thrown when an unsigned value is too large to be converted to a signed value
error UnsignedValueTooLarge(uint256 x);

/**
 * @title FixedMath0x
 * @notice Signed, fixed-point, 127-bit precision math library
 */
library FixedMath0x {
    // Base for the fixed point numbers (this is our 1)
    int256 internal constant FIXED_1 = int256(0x0000000000000000000000000000000080000000000000000000000000000000);
    // Maximum ln argument (1)
    int256 private constant LN_MAX_VAL = FIXED_1;
    // Minimum ln argument. Notice this is related to EXP_MIN_VAL (e ^ -63.875)
    int256 private constant LN_MIN_VAL = int256(0x0000000000000000000000000000000000000000000000000000000733048c5a);
    // Maximum exp argument (0)
    int256 private constant EXP_MAX_VAL = 0;
    // Minimum exp argument. Notice this is related to LN_MIN_VAL (-63.875)
    int256 private constant EXP_MIN_VAL = -int256(0x0000000000000000000000000000001ff0000000000000000000000000000000);

    /// @dev Get the natural logarithm of a fixed-point number 0 < `x` <= LN_MAX_VAL
    function _ln(int256 x) internal pure returns (int256 r) {
        if (x > LN_MAX_VAL) {
            revert LnTooLarge(x);
        }
        if (x <= 0) {
            revert LnNonRealResult(x);
        }
        if (x == FIXED_1) {
            return 0;
        }
        if (x <= LN_MIN_VAL) {
            return EXP_MIN_VAL;
        }

        int256 y;
        int256 z;
        int256 w;

        // Rewrite the input as a quotient of negative natural exponents and a single residual q, such that 1 < q < 2
        // For example: log(0.3) = log(e^-1 * e^-0.25 * 1.0471028872385522)
        //              = 1 - 0.25 - log(1 + 0.0471028872385522)
        // e ^ -32
        if (x <= int256(0x00000000000000000000000000000000000000000001c8464f76164760000000)) {
            r -= int256(0x0000000000000000000000000000001000000000000000000000000000000000); // - 32
            x = (x * FIXED_1) / int256(0x00000000000000000000000000000000000000000001c8464f76164760000000); // / e ^ -32
        }
        // e ^ -16
        if (x <= int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000)) {
            r -= int256(0x0000000000000000000000000000000800000000000000000000000000000000); // - 16
            x = (x * FIXED_1) / int256(0x00000000000000000000000000000000000000f1aaddd7742e90000000000000); // / e ^ -16
        }
        // e ^ -8
        if (x <= int256(0x00000000000000000000000000000000000afe10820813d78000000000000000)) {
            r -= int256(0x0000000000000000000000000000000400000000000000000000000000000000); // - 8
            x = (x * FIXED_1) / int256(0x00000000000000000000000000000000000afe10820813d78000000000000000); // / e ^ -8
        }
        // e ^ -4
        if (x <= int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000)) {
            r -= int256(0x0000000000000000000000000000000200000000000000000000000000000000); // - 4
            x = (x * FIXED_1) / int256(0x0000000000000000000000000000000002582ab704279ec00000000000000000); // / e ^ -4
        }
        // e ^ -2
        if (x <= int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000100000000000000000000000000000000); // - 2
            x = (x * FIXED_1) / int256(0x000000000000000000000000000000001152aaa3bf81cc000000000000000000); // / e ^ -2
        }
        // e ^ -1
        if (x <= int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000080000000000000000000000000000000); // - 1
            x = (x * FIXED_1) / int256(0x000000000000000000000000000000002f16ac6c59de70000000000000000000); // / e ^ -1
        }
        // e ^ -0.5
        if (x <= int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000040000000000000000000000000000000); // - 0.5
            x = (x * FIXED_1) / int256(0x000000000000000000000000000000004da2cbf1be5828000000000000000000); // / e ^ -0.5
        }
        // e ^ -0.25
        if (x <= int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000)) {
            r -= int256(0x0000000000000000000000000000000020000000000000000000000000000000); // - 0.25
            x = (x * FIXED_1) / int256(0x0000000000000000000000000000000063afbe7ab2082c000000000000000000); // / e ^ -0.25
        }
        // e ^ -0.125
        if (x <= int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) {
            r -= int256(0x0000000000000000000000000000000010000000000000000000000000000000); // - 0.125
            x = (x * FIXED_1) / int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d); // / e ^ -0.125
        }
        // `x` is now our residual in the range of 1 <= x <= 2 (or close enough).

        // Add the taylor series for log(1 + z), where z = x - 1
        z = y = x - FIXED_1;
        w = (y * y) / FIXED_1;
        r += (z * (0x100000000000000000000000000000000 - y)) / 0x100000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^01 / 01 - y^02 / 02
        r += (z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y)) / 0x200000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^03 / 03 - y^04 / 04
        r += (z * (0x099999999999999999999999999999999 - y)) / 0x300000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^05 / 05 - y^06 / 06
        r += (z * (0x092492492492492492492492492492492 - y)) / 0x400000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^07 / 07 - y^08 / 08
        r += (z * (0x08e38e38e38e38e38e38e38e38e38e38e - y)) / 0x500000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^09 / 09 - y^10 / 10
        r += (z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y)) / 0x600000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^11 / 11 - y^12 / 12
        r += (z * (0x089d89d89d89d89d89d89d89d89d89d89 - y)) / 0x700000000000000000000000000000000;
        z = (z * w) / FIXED_1; // add y^13 / 13 - y^14 / 14
        r += (z * (0x088888888888888888888888888888888 - y)) / 0x800000000000000000000000000000000; // add y^15 / 15 - y^16 / 16
    }

    /// @dev Compute the natural exponent for a fixed-point number EXP_MIN_VAL <= `x` <= 1
    function _exp(int256 x) internal pure returns (int256 r) {
        if (x < EXP_MIN_VAL) {
            // Saturate to zero below EXP_MIN_VAL.
            return 0;
        }
        if (x == 0) {
            return FIXED_1;
        }
        if (x > EXP_MAX_VAL) {
            revert ExpTooLarge(x);
        }

        // Rewrite the input as a product of natural exponents and a
        // single residual q, where q is a number of small magnitude.
        // For example: e^-34.419 = e^(-32 - 2 - 0.25 - 0.125 - 0.044)
        //              = e^-32 * e^-2 * e^-0.25 * e^-0.125 * e^-0.044
        //              -> q = -0.044

        // Multiply with the taylor series for e^q
        int256 y;
        int256 z;
        // q = x % 0.125 (the residual)
        z = y = x % 0x0000000000000000000000000000000010000000000000000000000000000000;
        z = (z * y) / FIXED_1;
        r += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = (z * y) / FIXED_1;
        r += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = (z * y) / FIXED_1;
        r += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = (z * y) / FIXED_1;
        r += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = (z * y) / FIXED_1;
        r += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = (z * y) / FIXED_1;
        r += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = (z * y) / FIXED_1;
        r += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = (z * y) / FIXED_1;
        r += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = (z * y) / FIXED_1;
        r += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = (z * y) / FIXED_1;
        r += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = (z * y) / FIXED_1;
        r += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        r = r / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        // Multiply with the non-residual terms.
        x = -x;
        // e ^ -32
        if ((x & int256(0x0000000000000000000000000000001000000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000000000f1aaddd7742e56d32fb9f99744)) /
                int256(0x0000000000000000000000000043cbaf42a000812488fc5c220ad7b97bf6e99e); // * e ^ -32
        }
        // e ^ -16
        if ((x & int256(0x0000000000000000000000000000000800000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000000afe10820813d65dfe6a33c07f738f)) /
                int256(0x000000000000000000000000000005d27a9f51c31b7c2f8038212a0574779991); // * e ^ -16
        }
        // e ^ -8
        if ((x & int256(0x0000000000000000000000000000000400000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000002582ab704279e8efd15e0265855c47a)) /
                int256(0x0000000000000000000000000000001b4c902e273a58678d6d3bfdb93db96d02); // * e ^ -8
        }
        // e ^ -4
        if ((x & int256(0x0000000000000000000000000000000200000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000001152aaa3bf81cb9fdb76eae12d029571)) /
                int256(0x00000000000000000000000000000003b1cc971a9bb5b9867477440d6d157750); // * e ^ -4
        }
        // e ^ -2
        if ((x & int256(0x0000000000000000000000000000000100000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000002f16ac6c59de6f8d5d6f63c1482a7c86)) /
                int256(0x000000000000000000000000000000015bf0a8b1457695355fb8ac404e7a79e3); // * e ^ -2
        }
        // e ^ -1
        if ((x & int256(0x0000000000000000000000000000000080000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x000000000000000000000000000000004da2cbf1be5827f9eb3ad1aa9866ebb3)) /
                int256(0x00000000000000000000000000000000d3094c70f034de4b96ff7d5b6f99fcd8); // * e ^ -1
        }
        // e ^ -0.5
        if ((x & int256(0x0000000000000000000000000000000040000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000063afbe7ab2082ba1a0ae5e4eb1b479dc)) /
                int256(0x00000000000000000000000000000000a45af1e1f40c333b3de1db4dd55f29a7); // * e ^ -0.5
        }
        // e ^ -0.25
        if ((x & int256(0x0000000000000000000000000000000020000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x0000000000000000000000000000000070f5a893b608861e1f58934f97aea57d)) /
                int256(0x00000000000000000000000000000000910b022db7ae67ce76b441c27035c6a1); // * e ^ -0.25
        }
        // e ^ -0.125
        if ((x & int256(0x0000000000000000000000000000000010000000000000000000000000000000)) != 0) {
            r =
                (r * int256(0x00000000000000000000000000000000783eafef1c0a8f3978c7f81824d62ebf)) /
                int256(0x0000000000000000000000000000000088415abbe9a76bead8d00cf112e4d4a8); // * e ^ -0.125
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { SafeCastUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import { FixedMath } from "./FixedMath.sol";

using SafeCastUpgradeable for uint256;

/**
 * @title Scores
 * @author Venus
 * @notice Scores library is used to calculate score of users
 */
library Scores {
    /**
     * @notice Calculate a membership score given some amount of `xvs` and `capital`, along
     *  with some 𝝰 = `alphaNumerator` / `alphaDenominator`.
     * @param xvs amount of xvs (xvs, 1e18 decimal places)
     * @param capital amount of capital (1e18 decimal places)
     * @param alphaNumerator alpha param numerator
     * @param alphaDenominator alpha param denominator
     * @return membership score with 1e18 decimal places
     *
     * @dev 𝝰 must be in the range [0, 1]
     */
    function _calculateScore(
        uint256 xvs,
        uint256 capital,
        uint256 alphaNumerator,
        uint256 alphaDenominator
    ) internal pure returns (uint256) {
        // Score function is:
        // xvs^𝝰 * capital^(1-𝝰)
        //    = capital * capital^(-𝝰) * xvs^𝝰
        //    = capital * (xvs / capital)^𝝰
        //    = capital * (e ^ (ln(xvs / capital))) ^ 𝝰
        //    = capital * e ^ (𝝰 * ln(xvs / capital))     (1)
        // or
        //    = capital / ( 1 / e ^ (𝝰 * ln(xvs / capital)))
        //    = capital / (e ^ (𝝰 * ln(xvs / capital)) ^ -1)
        //    = capital / e ^ (𝝰 * -1 * ln(xvs / capital))
        //    = capital / e ^ (𝝰 * ln(capital / xvs))     (2)
        //
        // To avoid overflows, use (1) when xvs < capital and
        // use (2) when capital < xvs

        // If any side is 0, exit early
        if (xvs == 0 || capital == 0) return 0;

        // If both sides are equal, we have:
        // xvs^𝝰 * capital^(1-𝝰)
        //    = xvs^𝝰 * xvs^(1-𝝰)
        //    = xvs^(𝝰 + 1 - 𝝰)     = xvs
        if (xvs == capital) return xvs;

        bool lessxvsThanCapital = xvs < capital;

        // (xvs / capital) or (capital / xvs), always in range (0, 1)
        int256 ratio = lessxvsThanCapital ? FixedMath._toFixed(xvs, capital) : FixedMath._toFixed(capital, xvs);

        // e ^ ( ln(ratio) * 𝝰 )
        int256 exponentiation = FixedMath._exp(
            (FixedMath._ln(ratio) * alphaNumerator.toInt256()) / alphaDenominator.toInt256()
        );

        if (lessxvsThanCapital) {
            // capital * e ^ (𝝰 * ln(xvs / capital))
            return FixedMath._uintMul(capital, exponentiation);
        }

        // capital / e ^ (𝝰 * ln(capital / xvs))
        return FixedMath._uintDiv(capital, exponentiation);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AccessControlledV8 } from "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";
import { ResilientOracleInterface } from "@venusprotocol/oracle/contracts/interfaces/OracleInterface.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { MaxLoopsLimitHelper } from "@venusprotocol/solidity-utilities/contracts/MaxLoopsLimitHelper.sol";
import { TimeManagerV8 } from "@venusprotocol/solidity-utilities/contracts/TimeManagerV8.sol";

import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import { PrimeStorageV1 } from "./PrimeStorage.sol";
import { Scores } from "./libs/Scores.sol";

import { IPrimeLiquidityProvider } from "./Interfaces/IPrimeLiquidityProvider.sol";
import { IPrime } from "./Interfaces/IPrime.sol";
import { IXVSVault } from "./Interfaces/IXVSVault.sol";
import { IVToken } from "./Interfaces/IVToken.sol";
import { InterfaceComptroller } from "./Interfaces/InterfaceComptroller.sol";
import { PoolRegistryInterface } from "./Interfaces/IPoolRegistry.sol";

/**
 * @title Prime
 * @author Venus
 * @notice Prime Token is used to provide extra rewards to the users who have staked a minimum of `MINIMUM_STAKED_XVS` XVS in the XVSVault for `STAKING_PERIOD` days
 * @custom:security-contact https://github.com/VenusProtocol/venus-protocol
 */
contract Prime is IPrime, AccessControlledV8, PausableUpgradeable, MaxLoopsLimitHelper, PrimeStorageV1, TimeManagerV8 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice address of wrapped native token contract
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable WRAPPED_NATIVE_TOKEN;

    /// @notice address of native market contract
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable NATIVE_MARKET;

    /// @notice minimum amount of XVS user needs to stake to become a prime member
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable MINIMUM_STAKED_XVS;

    /// @notice maximum XVS taken in account when calculating user score
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable MAXIMUM_XVS_CAP;

    /// @notice number of days user need to stake to claim prime token
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint256 public immutable STAKING_PERIOD;

    /// @notice Emitted when prime token is minted
    event Mint(address indexed user, bool isIrrevocable);

    /// @notice Emitted when prime token is burned
    event Burn(address indexed user);

    /// @notice Emitted when a market is added to prime program
    event MarketAdded(
        address indexed comptroller,
        address indexed market,
        uint256 supplyMultiplier,
        uint256 borrowMultiplier
    );

    /// @notice Emitted when mint limits are updated
    event MintLimitsUpdated(
        uint256 indexed oldIrrevocableLimit,
        uint256 indexed oldRevocableLimit,
        uint256 indexed newIrrevocableLimit,
        uint256 newRevocableLimit
    );

    /// @notice Emitted when user score is updated
    event UserScoreUpdated(address indexed user);

    /// @notice Emitted when alpha is updated
    event AlphaUpdated(
        uint128 indexed oldNumerator,
        uint128 indexed oldDenominator,
        uint128 indexed newNumerator,
        uint128 newDenominator
    );

    /// @notice Emitted when multiplier is updated
    event MultiplierUpdated(
        address indexed market,
        uint256 indexed oldSupplyMultiplier,
        uint256 indexed oldBorrowMultiplier,
        uint256 newSupplyMultiplier,
        uint256 newBorrowMultiplier
    );

    /// @notice Emitted when interest is claimed
    event InterestClaimed(address indexed user, address indexed market, uint256 amount);

    /// @notice Emitted when revocable token is upgraded to irrevocable token
    event TokenUpgraded(address indexed user);

    /// @notice Emitted when stakedAt is updated
    event StakedAtUpdated(address indexed user, uint256 timestamp);

    /// @notice Error thrown when market is not supported
    error MarketNotSupported();

    /// @notice Error thrown when mint limit is reached
    error InvalidLimit();

    /// @notice Error thrown when user is not eligible to claim prime token
    error IneligibleToClaim();

    /// @notice Error thrown when user needs to wait more time to claim prime token
    error WaitMoreTime();

    /// @notice Error thrown when user has no prime token
    error UserHasNoPrimeToken();

    /// @notice Error thrown when no score updates are required
    error NoScoreUpdatesRequired();

    /// @notice Error thrown when market already exists
    error MarketAlreadyExists();

    /// @notice Error thrown when asset already exists
    error AssetAlreadyExists();

    /// @notice Error thrown when invalid address is passed
    error InvalidAddress();

    /// @notice Error thrown when invalid alpha arguments are passed
    error InvalidAlphaArguments();

    /// @notice Error thrown when invalid vToken is passed
    error InvalidVToken();

    /// @notice Error thrown when invalid length is passed
    error InvalidLength();

    /// @notice Error thrown when timestamp is invalid
    error InvalidTimestamp();

    /// @notice Error thrown when invalid comptroller is passed
    error InvalidComptroller();

    /**
     * @notice Prime constructor
     * @param _wrappedNativeToken Address of wrapped native token
     * @param _nativeMarket Address of native market
     * @param _blocksPerYear total blocks per year
     * @param _stakingPeriod total number of seconds for which user needs to stake to claim prime token
     * @param _minimumStakedXVS minimum amount of XVS user needs to stake to become a prime member (scaled by 1e18)
     * @param _maximumXVSCap maximum XVS taken in account when calculating user score (scaled by 1e18)
     * @param _timeBased A boolean indicating whether the contract is based on time or block.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _wrappedNativeToken,
        address _nativeMarket,
        uint256 _blocksPerYear,
        uint256 _stakingPeriod,
        uint256 _minimumStakedXVS,
        uint256 _maximumXVSCap,
        bool _timeBased
    ) TimeManagerV8(_timeBased, _blocksPerYear) {
        WRAPPED_NATIVE_TOKEN = _wrappedNativeToken;
        NATIVE_MARKET = _nativeMarket;
        STAKING_PERIOD = _stakingPeriod;
        MINIMUM_STAKED_XVS = _minimumStakedXVS;
        MAXIMUM_XVS_CAP = _maximumXVSCap;

        // Note that the contract is upgradeable. Use initialize() or reinitializers
        // to set the state variables.
        _disableInitializers();
    }

    /**
     * @notice Prime initializer
     * @param xvsVault_ Address of XVSVault
     * @param xvsVaultRewardToken_ Address of XVSVault reward token
     * @param xvsVaultPoolId_ Pool id of XVSVault
     * @param alphaNumerator_ numerator of alpha. If alpha is 0.5 then numerator is 1.
              alphaDenominator_ must be greater than alphaNumerator_, alphaDenominator_ cannot be zero and alphaNumerator_ cannot be zero
     * @param alphaDenominator_ denominator of alpha. If alpha is 0.5 then denominator is 2.
              alpha is alphaNumerator_/alphaDenominator_. So, 0 < alpha < 1
     * @param accessControlManager_ Address of AccessControlManager
     * @param primeLiquidityProvider_ Address of PrimeLiquidityProvider
     * @param comptroller_ Address of core pool comptroller
     * @param oracle_ Address of Oracle
     * @param loopsLimit_ Maximum number of loops allowed in a single transaction
     * @custom:error Throw InvalidAddress if any of the address is invalid
     */
    function initialize(
        address xvsVault_,
        address xvsVaultRewardToken_,
        uint256 xvsVaultPoolId_,
        uint128 alphaNumerator_,
        uint128 alphaDenominator_,
        address accessControlManager_,
        address primeLiquidityProvider_,
        address comptroller_,
        address oracle_,
        uint256 loopsLimit_
    ) external initializer {
        if (xvsVault_ == address(0)) revert InvalidAddress();
        if (xvsVaultRewardToken_ == address(0)) revert InvalidAddress();
        if (oracle_ == address(0)) revert InvalidAddress();
        if (primeLiquidityProvider_ == address(0)) revert InvalidAddress();

        _checkAlphaArguments(alphaNumerator_, alphaDenominator_);

        alphaNumerator = alphaNumerator_;
        alphaDenominator = alphaDenominator_;
        xvsVaultRewardToken = xvsVaultRewardToken_;
        xvsVaultPoolId = xvsVaultPoolId_;
        xvsVault = xvsVault_;
        nextScoreUpdateRoundId = 0;
        primeLiquidityProvider = primeLiquidityProvider_;
        corePoolComptroller = comptroller_;
        oracle = ResilientOracleInterface(oracle_);

        __AccessControlled_init(accessControlManager_);
        __Pausable_init();
        _setMaxLoopsLimit(loopsLimit_);

        _pause();
    }

    /**
     * @notice Prime initializer V2 for initializing pool registry
     * @param poolRegistry_ Address of IL pool registry
     */
    function initializeV2(address poolRegistry_) external reinitializer(2) {
        poolRegistry = poolRegistry_;
    }

    /**
     * @notice Returns boosted pending interest accrued for a user for all markets
     * @param user the account for which to get the accrued interests
     * @return pendingRewards the number of underlying tokens accrued by the user for all markets
     */
    function getPendingRewards(address user) external returns (PendingReward[] memory pendingRewards) {
        address[] storage allMarkets = _allMarkets;
        uint256 marketsLength = allMarkets.length;

        pendingRewards = new PendingReward[](marketsLength);
        for (uint256 i; i < marketsLength; ) {
            address market = allMarkets[i];
            uint256 interestAccrued = getInterestAccrued(market, user);
            uint256 accrued = interests[market][user].accrued;

            pendingRewards[i] = PendingReward({
                vToken: market,
                rewardToken: _getUnderlying(market),
                amount: interestAccrued + accrued
            });

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Update total score of multiple users and market
     * @param users accounts for which we need to update score
     * @custom:error Throw NoScoreUpdatesRequired if no score updates are required
     * @custom:error Throw UserHasNoPrimeToken if user has no prime token
     * @custom:event Emits UserScoreUpdated event
     */
    function updateScores(address[] calldata users) external {
        if (pendingScoreUpdates == 0) revert NoScoreUpdatesRequired();
        if (nextScoreUpdateRoundId == 0) revert NoScoreUpdatesRequired();

        for (uint256 i; i < users.length; ) {
            address user = users[i];

            if (!tokens[user].exists) revert UserHasNoPrimeToken();
            if (isScoreUpdated[nextScoreUpdateRoundId][user]) {
                unchecked {
                    ++i;
                }
                continue;
            }

            address[] storage allMarkets = _allMarkets;
            uint256 marketsLength = allMarkets.length;

            for (uint256 j; j < marketsLength; ) {
                address market = allMarkets[j];
                _executeBoost(user, market);
                _updateScore(user, market);

                unchecked {
                    ++j;
                }
            }

            --pendingScoreUpdates;
            isScoreUpdated[nextScoreUpdateRoundId][user] = true;

            unchecked {
                ++i;
            }

            emit UserScoreUpdated(user);
        }
    }

    /**
     * @notice Update value of alpha
     * @param _alphaNumerator numerator of alpha. If alpha is 0.5 then numerator is 1
     * @param _alphaDenominator denominator of alpha. If alpha is 0.5 then denominator is 2
     * @custom:event Emits AlphaUpdated event
     * @custom:access Controlled by ACM
     */
    function updateAlpha(uint128 _alphaNumerator, uint128 _alphaDenominator) external {
        _checkAccessAllowed("updateAlpha(uint128,uint128)");
        _checkAlphaArguments(_alphaNumerator, _alphaDenominator);

        emit AlphaUpdated(alphaNumerator, alphaDenominator, _alphaNumerator, _alphaDenominator);

        alphaNumerator = _alphaNumerator;
        alphaDenominator = _alphaDenominator;

        uint256 marketslength = _allMarkets.length;

        for (uint256 i; i < marketslength; ) {
            accrueInterest(_allMarkets[i]);

            unchecked {
                ++i;
            }
        }

        _startScoreUpdateRound();
    }

    /**
     * @notice Update multipliers for a market
     * @param market address of the market vToken
     * @param supplyMultiplier new supply multiplier for the market, scaled by 1e18
     * @param borrowMultiplier new borrow multiplier for the market, scaled by 1e18
     * @custom:error Throw MarketNotSupported if market is not supported
     * @custom:event Emits MultiplierUpdated event
     * @custom:access Controlled by ACM
     */
    function updateMultipliers(address market, uint256 supplyMultiplier, uint256 borrowMultiplier) external {
        _checkAccessAllowed("updateMultipliers(address,uint256,uint256)");

        Market storage _market = markets[market];
        if (!_market.exists) revert MarketNotSupported();

        accrueInterest(market);

        emit MultiplierUpdated(
            market,
            _market.supplyMultiplier,
            _market.borrowMultiplier,
            supplyMultiplier,
            borrowMultiplier
        );
        _market.supplyMultiplier = supplyMultiplier;
        _market.borrowMultiplier = borrowMultiplier;

        _startScoreUpdateRound();
    }

    /**
     * @notice Update staked at timestamp for multiple users
     * @param users accounts for which we need to update staked at timestamp
     * @param timestamps new staked at timestamp for the users
     * @custom:error Throw InvalidLength if users and timestamps length are not equal
     * @custom:event Emits StakedAtUpdated event for each user
     * @custom:access Controlled by ACM
     */
    function setStakedAt(address[] calldata users, uint256[] calldata timestamps) external {
        _checkAccessAllowed("setStakedAt(address[],uint256[])");
        if (users.length != timestamps.length) revert InvalidLength();

        for (uint256 i; i < users.length; ) {
            if (timestamps[i] > block.timestamp) revert InvalidTimestamp();

            stakedAt[users[i]] = timestamps[i];
            emit StakedAtUpdated(users[i], timestamps[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Add a market to prime program
     * @param comptroller address of the comptroller
     * @param market address of the market vToken
     * @param supplyMultiplier the multiplier for supply cap. It should be converted to 1e18
     * @param borrowMultiplier the multiplier for borrow cap. It should be converted to 1e18
     * @custom:error Throw MarketAlreadyExists if market already exists
     * @custom:error Throw InvalidVToken if market is not valid
     * @custom:event Emits MarketAdded event
     * @custom:access Controlled by ACM
     */
    function addMarket(
        address comptroller,
        address market,
        uint256 supplyMultiplier,
        uint256 borrowMultiplier
    ) external {
        _checkAccessAllowed("addMarket(address,address,uint256,uint256)");

        if (comptroller == address(0)) revert InvalidComptroller();

        if (
            comptroller != corePoolComptroller &&
            PoolRegistryInterface(poolRegistry).getPoolByComptroller(comptroller).comptroller != comptroller
        ) revert InvalidComptroller();

        Market storage _market = markets[market];
        if (_market.exists) revert MarketAlreadyExists();

        bool isMarketExist = InterfaceComptroller(comptroller).markets(market);
        if (!isMarketExist) revert InvalidVToken();

        delete _market.rewardIndex;
        _market.supplyMultiplier = supplyMultiplier;
        _market.borrowMultiplier = borrowMultiplier;
        delete _market.sumOfMembersScore;
        _market.exists = true;

        address underlying = _getUnderlying(market);

        if (vTokenForAsset[underlying] != address(0)) revert AssetAlreadyExists();
        vTokenForAsset[underlying] = market;

        _allMarkets.push(market);
        _startScoreUpdateRound();

        _ensureMaxLoops(_allMarkets.length);

        emit MarketAdded(comptroller, market, supplyMultiplier, borrowMultiplier);
    }

    /**
     * @notice Set limits for total tokens that can be minted
     * @param _irrevocableLimit total number of irrevocable tokens that can be minted
     * @param _revocableLimit total number of revocable tokens that can be minted
     * @custom:error Throw InvalidLimit if any of the limit is less than total tokens minted
     * @custom:event Emits MintLimitsUpdated event
     * @custom:access Controlled by ACM
     */
    function setLimit(uint256 _irrevocableLimit, uint256 _revocableLimit) external {
        _checkAccessAllowed("setLimit(uint256,uint256)");
        if (_irrevocableLimit < totalIrrevocable || _revocableLimit < totalRevocable) revert InvalidLimit();

        emit MintLimitsUpdated(irrevocableLimit, revocableLimit, _irrevocableLimit, _revocableLimit);

        revocableLimit = _revocableLimit;
        irrevocableLimit = _irrevocableLimit;
    }

    /**
     * @notice Set the limit for the loops can iterate to avoid the DOS
     * @param loopsLimit Number of loops limit
     * @custom:event Emits MaxLoopsLimitUpdated event on success
     * @custom:access Controlled by ACM
     */
    function setMaxLoopsLimit(uint256 loopsLimit) external {
        _checkAccessAllowed("setMaxLoopsLimit(uint256)");
        _setMaxLoopsLimit(loopsLimit);
    }

    /**
     * @notice Directly issue prime tokens to users
     * @param isIrrevocable are the tokens being issued
     * @param users list of address to issue tokens to
     * @custom:access Controlled by ACM
     */
    function issue(bool isIrrevocable, address[] calldata users) external {
        _checkAccessAllowed("issue(bool,address[])");

        if (isIrrevocable) {
            for (uint256 i; i < users.length; ) {
                Token storage userToken = tokens[users[i]];
                if (userToken.exists && !userToken.isIrrevocable) {
                    _upgrade(users[i]);
                } else {
                    _mint(true, users[i]);
                    _initializeMarkets(users[i]);
                }

                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i; i < users.length; ) {
                _mint(false, users[i]);
                _initializeMarkets(users[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Executed by XVSVault whenever user's XVSVault balance changes
     * @param user the account address whose balance was updated
     */
    function xvsUpdated(address user) external {
        uint256 totalStaked = _xvsBalanceOfUser(user);
        bool isAccountEligible = _isEligible(totalStaked);

        uint256 userStakedAt = stakedAt[user];
        Token memory token = tokens[user];

        if (token.exists && !isAccountEligible) {
            delete stakedAt[user];
            emit StakedAtUpdated(user, 0);

            if (token.isIrrevocable) {
                _accrueInterestAndUpdateScore(user);
            } else {
                _burn(user);
            }
        } else if (!isAccountEligible && !token.exists && userStakedAt != 0) {
            delete stakedAt[user];
            emit StakedAtUpdated(user, 0);
        } else if (userStakedAt == 0 && isAccountEligible && !token.exists) {
            stakedAt[user] = block.timestamp;
            emit StakedAtUpdated(user, block.timestamp);
        } else if (token.exists && isAccountEligible) {
            _accrueInterestAndUpdateScore(user);

            if (stakedAt[user] == 0) {
                stakedAt[user] = block.timestamp;
                emit StakedAtUpdated(user, block.timestamp);
            }
        }
    }

    /**
     * @notice accrues interes and updates score for an user for a specific market
     * @param user the account address for which to accrue interest and update score
     * @param market the market for which to accrue interest and update score
     */
    function accrueInterestAndUpdateScore(address user, address market) external {
        _executeBoost(user, market);
        _updateScore(user, market);
    }

    /**
     * @notice For claiming prime token when staking period is completed
     */
    function claim() external {
        uint256 userStakedAt = stakedAt[msg.sender];
        if (userStakedAt == 0) revert IneligibleToClaim();
        if (block.timestamp - userStakedAt < STAKING_PERIOD) revert WaitMoreTime();

        _mint(false, msg.sender);
        _initializeMarkets(msg.sender);
    }

    /**
     * @notice For burning any prime token
     * @param user the account address for which the prime token will be burned
     * @custom:access Controlled by ACM
     */
    function burn(address user) external {
        _checkAccessAllowed("burn(address)");
        _burn(user);
    }

    /**
     * @notice To pause or unpause claiming of interest
     * @custom:access Controlled by ACM
     */
    function togglePause() external {
        _checkAccessAllowed("togglePause()");
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @notice For user to claim boosted yield
     * @param vToken the market for which claim the accrued interest
     * @return amount the amount of tokens transferred to the msg.sender
     */
    function claimInterest(address vToken) external whenNotPaused returns (uint256) {
        return _claimInterest(vToken, msg.sender);
    }

    /**
     * @notice For user to claim boosted yield
     * @param vToken the market for which claim the accrued interest
     * @param user the user for which to claim the accrued interest
     * @return amount the amount of tokens transferred to the user
     */
    function claimInterest(address vToken, address user) external whenNotPaused returns (uint256) {
        return _claimInterest(vToken, user);
    }

    /**
     * @notice Retrieves an array of all available markets
     * @return an array of addresses representing all available markets
     */
    function getAllMarkets() external view returns (address[] memory) {
        return _allMarkets;
    }

    /**
     * @notice Retrieves the core pool comptroller address
     * @return the core pool comptroller address
     */
    function comptroller() external view returns (address) {
        return corePoolComptroller;
    }

    /**
     * @notice fetch the numbers of seconds remaining for staking period to complete
     * @param user the account address for which we are checking the remaining time
     * @return timeRemaining the number of seconds the user needs to wait to claim prime token
     */
    function claimTimeRemaining(address user) external view returns (uint256) {
        uint256 userStakedAt = stakedAt[user];
        if (userStakedAt == 0) return STAKING_PERIOD;

        uint256 totalTimeStaked;
        unchecked {
            totalTimeStaked = block.timestamp - userStakedAt;
        }

        if (totalTimeStaked < STAKING_PERIOD) {
            unchecked {
                return STAKING_PERIOD - totalTimeStaked;
            }
        }
        return 0;
    }

    /**
     * @notice Returns if user is a prime holder
     * @return isPrimeHolder true if user is a prime holder
     */
    function isUserPrimeHolder(address user) external view returns (bool) {
        return tokens[user].exists;
    }

    /**
     * @notice Returns supply and borrow APR for user for a given market
     * @param market the market for which to fetch the APR
     * @param user the account for which to get the APR
     * @return aprInfo APR information for the user for the given market
     */
    function calculateAPR(address market, address user) external view returns (APRInfo memory aprInfo) {
        IVToken vToken = IVToken(market);
        uint256 borrow = vToken.borrowBalanceStored(user);
        uint256 exchangeRate = vToken.exchangeRateStored();
        uint256 balanceOfAccount = vToken.balanceOf(user);
        uint256 supply = (exchangeRate * balanceOfAccount) / EXP_SCALE;

        aprInfo.userScore = interests[market][user].score;
        aprInfo.totalScore = markets[market].sumOfMembersScore;

        aprInfo.xvsBalanceForScore = _xvsBalanceForScore(_xvsBalanceOfUser(user));
        Capital memory capital = _capitalForScore(aprInfo.xvsBalanceForScore, borrow, supply, address(vToken));

        aprInfo.capital = capital.capital;
        aprInfo.cappedSupply = capital.cappedSupply;
        aprInfo.cappedBorrow = capital.cappedBorrow;
        aprInfo.supplyCapUSD = capital.supplyCapUSD;
        aprInfo.borrowCapUSD = capital.borrowCapUSD;

        (aprInfo.supplyAPR, aprInfo.borrowAPR) = _calculateUserAPR(
            market,
            supply,
            borrow,
            aprInfo.cappedSupply,
            aprInfo.cappedBorrow,
            aprInfo.userScore,
            aprInfo.totalScore
        );
    }

    /**
     * @notice Returns supply and borrow APR for estimated supply, borrow and XVS staked
     * @param market the market for which to fetch the APR
     * @param user the account for which to get the APR
     * @return aprInfo APR information for the user for the given market
     */
    function estimateAPR(
        address market,
        address user,
        uint256 borrow,
        uint256 supply,
        uint256 xvsStaked
    ) external view returns (APRInfo memory aprInfo) {
        aprInfo.totalScore = markets[market].sumOfMembersScore - interests[market][user].score;

        aprInfo.xvsBalanceForScore = _xvsBalanceForScore(xvsStaked);
        Capital memory capital = _capitalForScore(aprInfo.xvsBalanceForScore, borrow, supply, market);

        aprInfo.capital = capital.capital;
        aprInfo.cappedSupply = capital.cappedSupply;
        aprInfo.cappedBorrow = capital.cappedBorrow;
        aprInfo.supplyCapUSD = capital.supplyCapUSD;
        aprInfo.borrowCapUSD = capital.borrowCapUSD;

        uint256 decimals = IERC20MetadataUpgradeable(_getUnderlying(market)).decimals();
        aprInfo.capital = aprInfo.capital * (10 ** (18 - decimals));

        aprInfo.userScore = Scores._calculateScore(
            aprInfo.xvsBalanceForScore,
            aprInfo.capital,
            alphaNumerator,
            alphaDenominator
        );

        aprInfo.totalScore = aprInfo.totalScore + aprInfo.userScore;

        (aprInfo.supplyAPR, aprInfo.borrowAPR) = _calculateUserAPR(
            market,
            supply,
            borrow,
            aprInfo.cappedSupply,
            aprInfo.cappedBorrow,
            aprInfo.userScore,
            aprInfo.totalScore
        );
    }

    /**
     * @notice Distributes income from market since last distribution
     * @param vToken the market for which to distribute the income
     * @custom:error Throw MarketNotSupported if market is not supported
     */
    function accrueInterest(address vToken) public {
        Market storage market = markets[vToken];

        if (!market.exists) revert MarketNotSupported();

        address underlying = _getUnderlying(vToken);

        IPrimeLiquidityProvider _primeLiquidityProvider = IPrimeLiquidityProvider(primeLiquidityProvider);
        _primeLiquidityProvider.accrueTokens(underlying);
        uint256 totalAccruedInPLP = _primeLiquidityProvider.tokenAmountAccrued(underlying);
        uint256 unreleasedPLPAccruedInterest = totalAccruedInPLP - unreleasedPLPIncome[underlying];
        uint256 distributionIncome = unreleasedPLPAccruedInterest;

        if (distributionIncome == 0) {
            return;
        }

        unreleasedPLPIncome[underlying] = totalAccruedInPLP;

        uint256 delta;
        if (market.sumOfMembersScore != 0) {
            delta = ((distributionIncome * EXP_SCALE) / market.sumOfMembersScore);
        }

        market.rewardIndex += delta;
    }

    /**
     * @notice Returns boosted interest accrued for a user
     * @param vToken the market for which to fetch the accrued interest
     * @param user the account for which to get the accrued interest
     * @return interestAccrued the number of underlying tokens accrued by the user since the last accrual
     */
    function getInterestAccrued(address vToken, address user) public returns (uint256) {
        accrueInterest(vToken);

        return _interestAccrued(vToken, user);
    }

    /**
     * @notice accrues interest and updates score of all markets for an user
     * @param user the account address for which to accrue interest and update score
     */
    function _accrueInterestAndUpdateScore(address user) internal {
        address[] storage allMarkets = _allMarkets;
        uint256 marketsLength = allMarkets.length;

        for (uint256 i; i < marketsLength; ) {
            address market = allMarkets[i];
            _executeBoost(user, market);
            _updateScore(user, market);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Initializes all the markets for the user when a prime token is minted
     * @param account the account address for which markets needs to be initialized
     */
    function _initializeMarkets(address account) internal {
        address[] storage allMarkets = _allMarkets;
        uint256 marketsLength = allMarkets.length;

        for (uint256 i; i < marketsLength; ) {
            address market = allMarkets[i];
            accrueInterest(market);

            interests[market][account].rewardIndex = markets[market].rewardIndex;

            uint256 score = _calculateScore(market, account);
            interests[market][account].score = score;
            markets[market].sumOfMembersScore = markets[market].sumOfMembersScore + score;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice calculate the current score of user
     * @param market the market for which to calculate the score
     * @param user the account for which to calculate the score
     * @return score the score of the user
     */
    function _calculateScore(address market, address user) internal returns (uint256) {
        uint256 xvsBalanceForScore = _xvsBalanceForScore(_xvsBalanceOfUser(user));

        IVToken vToken = IVToken(market);
        uint256 borrow = vToken.borrowBalanceStored(user);
        uint256 exchangeRate = vToken.exchangeRateStored();
        uint256 balanceOfAccount = vToken.balanceOf(user);
        uint256 supply = (exchangeRate * balanceOfAccount) / EXP_SCALE;

        address xvsToken = IXVSVault(xvsVault).xvsAddress();
        oracle.updateAssetPrice(xvsToken);
        oracle.updatePrice(market);

        Capital memory capital = _capitalForScore(xvsBalanceForScore, borrow, supply, market);

        uint256 decimals = IERC20MetadataUpgradeable(_getUnderlying(market)).decimals();

        capital.capital = capital.capital * (10 ** (18 - decimals));

        return Scores._calculateScore(xvsBalanceForScore, capital.capital, alphaNumerator, alphaDenominator);
    }

    /**
     * @notice To transfer the accrued interest to user
     * @param vToken the market for which to claim
     * @param user the account for which to get the accrued interest
     * @return amount the amount of tokens transferred to the user
     * @custom:event Emits InterestClaimed event
     */
    function _claimInterest(address vToken, address user) internal returns (uint256) {
        uint256 amount = getInterestAccrued(vToken, user);
        amount += interests[vToken][user].accrued;

        interests[vToken][user].rewardIndex = markets[vToken].rewardIndex;
        delete interests[vToken][user].accrued;

        address underlying = _getUnderlying(vToken);
        IERC20Upgradeable asset = IERC20Upgradeable(underlying);

        if (amount > asset.balanceOf(address(this))) {
            delete unreleasedPLPIncome[underlying];
            IPrimeLiquidityProvider(primeLiquidityProvider).releaseFunds(address(asset));
        }

        asset.safeTransfer(user, amount);

        emit InterestClaimed(user, vToken, amount);

        return amount;
    }

    /**
     * @notice Used to mint a new prime token
     * @param isIrrevocable is the tokens being issued is irrevocable
     * @param user token owner
     * @custom:error Throw IneligibleToClaim if user is not eligible to claim prime token
     * @custom:event Emits Mint event
     */
    function _mint(bool isIrrevocable, address user) internal {
        Token storage token = tokens[user];
        if (token.exists) revert IneligibleToClaim();

        token.exists = true;
        token.isIrrevocable = isIrrevocable;

        if (isIrrevocable) {
            ++totalIrrevocable;
        } else {
            ++totalRevocable;
        }

        if (totalIrrevocable > irrevocableLimit || totalRevocable > revocableLimit) revert InvalidLimit();
        _updateRoundAfterTokenMinted(user);

        emit Mint(user, isIrrevocable);
    }

    /**
     * @notice Used to burn a new prime token
     * @param user owner whose prime token to burn
     * @custom:error Throw UserHasNoPrimeToken if user has no prime token
     * @custom:event Emits Burn event
     */
    function _burn(address user) internal {
        Token memory token = tokens[user];
        if (!token.exists) revert UserHasNoPrimeToken();

        address[] storage allMarkets = _allMarkets;
        uint256 marketsLength = allMarkets.length;

        for (uint256 i; i < marketsLength; ) {
            address market = allMarkets[i];
            _executeBoost(user, market);
            markets[market].sumOfMembersScore = markets[market].sumOfMembersScore - interests[market][user].score;

            delete interests[market][user].score;
            delete interests[market][user].rewardIndex;

            unchecked {
                ++i;
            }
        }

        if (token.isIrrevocable) {
            --totalIrrevocable;
        } else {
            --totalRevocable;
        }

        delete tokens[user].exists;
        delete tokens[user].isIrrevocable;

        _updateRoundAfterTokenBurned(user);

        emit Burn(user);
    }

    /**
     * @notice Used to upgrade an token
     * @param user owner whose prime token to upgrade
     * @custom:error Throw InvalidLimit if total irrevocable tokens exceeds the limit
     * @custom:event Emits TokenUpgraded event
     */
    function _upgrade(address user) internal {
        Token storage userToken = tokens[user];

        userToken.isIrrevocable = true;
        ++totalIrrevocable;
        --totalRevocable;

        if (totalIrrevocable > irrevocableLimit) revert InvalidLimit();

        emit TokenUpgraded(user);
    }

    /**
     * @notice Accrue rewards for the user. Must be called before updating score
     * @param user account for which we need to accrue rewards
     * @param vToken the market for which we need to accrue rewards
     */
    function _executeBoost(address user, address vToken) internal {
        if (!markets[vToken].exists || !tokens[user].exists) {
            return;
        }

        accrueInterest(vToken);
        interests[vToken][user].accrued += _interestAccrued(vToken, user);
        interests[vToken][user].rewardIndex = markets[vToken].rewardIndex;
    }

    /**
     * @notice Update total score of user and market. Must be called after changing account's borrow or supply balance.
     * @param user account for which we need to update score
     * @param market the market for which we need to score
     */
    function _updateScore(address user, address market) internal {
        Market storage _market = markets[market];
        if (!_market.exists || !tokens[user].exists) {
            return;
        }

        uint256 score = _calculateScore(market, user);
        _market.sumOfMembersScore = _market.sumOfMembersScore - interests[market][user].score + score;

        interests[market][user].score = score;
    }

    /**
     * @notice Verify new alpha arguments
     * @param _alphaNumerator numerator of alpha. If alpha is 0.5 then numerator is 1
     * @param _alphaDenominator denominator of alpha. If alpha is 0.5 then denominator is 2
     * @custom:error Throw InvalidAlphaArguments if alpha is invalid
     */
    function _checkAlphaArguments(uint128 _alphaNumerator, uint128 _alphaDenominator) internal pure {
        if (_alphaNumerator >= _alphaDenominator || _alphaNumerator == 0) {
            revert InvalidAlphaArguments();
        }
    }

    /**
     * @notice starts round to update scores of a particular or all markets
     */
    function _startScoreUpdateRound() internal {
        nextScoreUpdateRoundId++;
        totalScoreUpdatesRequired = totalIrrevocable + totalRevocable;
        pendingScoreUpdates = totalScoreUpdatesRequired;
    }

    /**
     * @notice update the required score updates when token is burned before round is completed
     */
    function _updateRoundAfterTokenBurned(address user) internal {
        if (totalScoreUpdatesRequired != 0) --totalScoreUpdatesRequired;

        if (pendingScoreUpdates != 0 && !isScoreUpdated[nextScoreUpdateRoundId][user]) {
            --pendingScoreUpdates;
        }
    }

    /**
     * @notice update the required score updates when token is minted before round is completed
     */
    function _updateRoundAfterTokenMinted(address user) internal {
        if (totalScoreUpdatesRequired != 0) isScoreUpdated[nextScoreUpdateRoundId][user] = true;
    }

    /**
     * @notice fetch the current XVS balance of user in the XVSVault
     * @param user the account address
     * @return xvsBalance the XVS balance of user
     */
    function _xvsBalanceOfUser(address user) internal view returns (uint256) {
        (uint256 xvs, , uint256 pendingWithdrawals) = IXVSVault(xvsVault).getUserInfo(
            xvsVaultRewardToken,
            xvsVaultPoolId,
            user
        );
        return (xvs - pendingWithdrawals);
    }

    /**
     * @notice calculate the current XVS balance that will be used in calculation of score
     * @param xvs the actual XVS balance of user
     * @return xvsBalanceForScore the XVS balance to use in score
     */
    function _xvsBalanceForScore(uint256 xvs) internal view returns (uint256) {
        if (xvs > MAXIMUM_XVS_CAP) {
            return MAXIMUM_XVS_CAP;
        }
        return xvs;
    }

    /**
     * @notice calculate the capital for calculation of score
     * @param xvs the actual XVS balance of user
     * @param borrow the borrow balance of user
     * @param supply the supply balance of user
     * @param market the market vToken address
     * @return capital the capital to use in calculation of score
     */
    function _capitalForScore(
        uint256 xvs,
        uint256 borrow,
        uint256 supply,
        address market
    ) internal view returns (Capital memory capital) {
        address xvsToken = IXVSVault(xvsVault).xvsAddress();

        uint256 xvsPrice = oracle.getPrice(xvsToken);
        capital.borrowCapUSD = (xvsPrice * ((xvs * markets[market].borrowMultiplier) / EXP_SCALE)) / EXP_SCALE;
        capital.supplyCapUSD = (xvsPrice * ((xvs * markets[market].supplyMultiplier) / EXP_SCALE)) / EXP_SCALE;

        uint256 tokenPrice = oracle.getUnderlyingPrice(market);
        uint256 supplyUSD = (tokenPrice * supply) / EXP_SCALE;
        uint256 borrowUSD = (tokenPrice * borrow) / EXP_SCALE;

        if (supplyUSD >= capital.supplyCapUSD) {
            supply = supplyUSD != 0 ? (supply * capital.supplyCapUSD) / supplyUSD : 0;
        }

        if (borrowUSD >= capital.borrowCapUSD) {
            borrow = borrowUSD != 0 ? (borrow * capital.borrowCapUSD) / borrowUSD : 0;
        }

        capital.capital = supply + borrow;
        capital.cappedSupply = supply;
        capital.cappedBorrow = borrow;
    }

    /**
     * @notice Used to get if the XVS balance is eligible for prime token
     * @param amount amount of XVS
     * @return isEligible true if the staked XVS amount is enough to consider the associated user eligible for a Prime token, false otherwise
     */
    function _isEligible(uint256 amount) internal view returns (bool) {
        if (amount >= MINIMUM_STAKED_XVS) {
            return true;
        }

        return false;
    }

    /**
     * @notice Calculate the interests accrued by the user in the market, since the last accrual
     * @param vToken the market for which to calculate the accrued interest
     * @param user the user for which to calculate the accrued interest
     * @return interestAccrued the number of underlying tokens accrued by the user since the last accrual
     */
    function _interestAccrued(address vToken, address user) internal view returns (uint256) {
        Interest memory interest = interests[vToken][user];
        uint256 index = markets[vToken].rewardIndex - interest.rewardIndex;

        uint256 score = interest.score;

        return (index * score) / EXP_SCALE;
    }

    /**
     * @notice Returns the underlying token associated with the VToken, or wrapped native token if the market is native market
     * @param vToken the market whose underlying token will be returned
     * @return underlying The address of the underlying token associated with the VToken, or the address of the WRAPPED_NATIVE_TOKEN token if the market is NATIVE_MARKET
     */
    function _getUnderlying(address vToken) internal view returns (address) {
        if (vToken == NATIVE_MARKET) {
            return WRAPPED_NATIVE_TOKEN;
        }
        return IVToken(vToken).underlying();
    }

    //////////////////////////////////////////////////
    //////////////// APR Calculation ////////////////
    ////////////////////////////////////////////////

    /**
     * @notice the total income that's going to be distributed in a year to prime token holders
     * @param vToken the market for which to fetch the total income that's going to distributed in a year
     * @return amount the total income
     */
    function incomeDistributionYearly(address vToken) public view returns (uint256 amount) {
        uint256 totalIncomePerBlockOrSecondFromPLP = IPrimeLiquidityProvider(primeLiquidityProvider)
            .getEffectiveDistributionSpeed(_getUnderlying(vToken));
        amount = blocksOrSecondsPerYear * totalIncomePerBlockOrSecondFromPLP;
    }

    /**
     * @notice used to calculate the supply and borrow APR of the user
     * @param vToken the market for which to fetch the APR
     * @param totalSupply the total token supply of the user
     * @param totalBorrow the total tokens borrowed by the user
     * @param totalCappedSupply the total token capped supply of the user
     * @param totalCappedBorrow the total capped tokens borrowed by the user
     * @param userScore the score of the user
     * @param totalScore the total market score
     * @return supplyAPR the supply APR of the user
     * @return borrowAPR the borrow APR of the user
     */
    function _calculateUserAPR(
        address vToken,
        uint256 totalSupply,
        uint256 totalBorrow,
        uint256 totalCappedSupply,
        uint256 totalCappedBorrow,
        uint256 userScore,
        uint256 totalScore
    ) internal view returns (uint256 supplyAPR, uint256 borrowAPR) {
        if (totalScore == 0) return (0, 0);

        uint256 userYearlyIncome = (userScore * incomeDistributionYearly(vToken)) / totalScore;

        uint256 totalCappedValue = totalCappedSupply + totalCappedBorrow;

        if (totalCappedValue == 0) return (0, 0);

        uint256 maximumBps = MAXIMUM_BPS;
        uint256 userSupplyIncomeYearly;
        uint256 userBorrowIncomeYearly;
        userSupplyIncomeYearly = (userYearlyIncome * totalCappedSupply) / totalCappedValue;
        userBorrowIncomeYearly = (userYearlyIncome * totalCappedBorrow) / totalCappedValue;
        supplyAPR = totalSupply == 0 ? 0 : ((userSupplyIncomeYearly * maximumBps) / totalSupply);
        borrowAPR = totalBorrow == 0 ? 0 : ((userBorrowIncomeYearly * maximumBps) / totalBorrow);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import { ResilientOracleInterface } from "@venusprotocol/oracle/contracts/interfaces/OracleInterface.sol";

/**
 * @title PrimeStorageV1
 * @author Venus
 * @notice Storage for Prime Token
 */
contract PrimeStorageV1 {
    struct Token {
        bool exists;
        bool isIrrevocable;
    }

    struct Market {
        uint256 supplyMultiplier;
        uint256 borrowMultiplier;
        uint256 rewardIndex;
        uint256 sumOfMembersScore;
        bool exists;
    }

    struct Interest {
        uint256 accrued;
        uint256 score;
        uint256 rewardIndex;
    }

    struct PendingReward {
        address vToken;
        address rewardToken;
        uint256 amount;
    }

    /// @notice Base unit for computations, usually used in scaling (multiplications, divisions)
    uint256 internal constant EXP_SCALE = 1e18;

    /// @notice maximum BPS = 100%
    uint256 internal constant MAXIMUM_BPS = 1e4;

    /// @notice Mapping to get prime token's metadata
    mapping(address => Token) public tokens;

    /// @notice  Tracks total irrevocable tokens minted
    uint256 public totalIrrevocable;

    /// @notice  Tracks total revocable tokens minted
    uint256 public totalRevocable;

    /// @notice  Indicates maximum revocable tokens that can be minted
    uint256 public revocableLimit;

    /// @notice  Indicates maximum irrevocable tokens that can be minted
    uint256 public irrevocableLimit;

    /// @notice Tracks when prime token eligible users started staking for claiming prime token
    mapping(address => uint256) public stakedAt;

    /// @notice vToken to market configuration
    mapping(address => Market) public markets;

    /// @notice vToken to user to user index
    mapping(address => mapping(address => Interest)) public interests;

    /// @notice A list of boosted markets
    address[] internal _allMarkets;

    /// @notice numerator of alpha. Ex: if alpha is 0.5 then this will be 1
    uint128 public alphaNumerator;

    /// @notice denominator of alpha. Ex: if alpha is 0.5 then this will be 2
    uint128 public alphaDenominator;

    /// @notice address of XVS vault
    address public xvsVault;

    /// @notice address of XVS vault reward token
    address public xvsVaultRewardToken;

    /// @notice address of XVS vault pool id
    uint256 public xvsVaultPoolId;

    /// @notice mapping to check if a account's score was updated in the round
    mapping(uint256 => mapping(address => bool)) public isScoreUpdated;

    /// @notice unique id for next round
    uint256 public nextScoreUpdateRoundId;

    /// @notice total number of accounts whose score needs to be updated
    uint256 public totalScoreUpdatesRequired;

    /// @notice total number of accounts whose score is yet to be updated
    uint256 public pendingScoreUpdates;

    /// @notice mapping used to find if an asset is part of prime markets
    mapping(address => address) public vTokenForAsset;

    /// @notice Address of core pool comptroller contract
    address internal corePoolComptroller;

    /// @notice unreleased income from PLP that's already distributed to prime holders
    /// @dev mapping of asset address => amount
    mapping(address => uint256) public unreleasedPLPIncome;

    /// @notice The address of PLP contract
    address public primeLiquidityProvider;

    /// @notice The address of ResilientOracle contract
    ResilientOracleInterface public oracle;

    /// @notice The address of PoolRegistry contract
    address public poolRegistry;

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    uint256[26] private __gap;
}