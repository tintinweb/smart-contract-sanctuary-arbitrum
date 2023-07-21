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
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import "./IAccessControlManagerV8.sol";

/**
 * @title Venus Access Control Contract.
 * @dev The AccessControlledV8 contract is a wrapper around the OpenZeppelin AccessControl contract
 *      It provides a standardized way to control access to methods within the Venus Smart Contract Ecosystem.
 *      The contract allows the owner to set an AccessControlManager contract address.
 *      It can restrict method calls based on the sender's role and the method's signature.
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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/IAccessControl.sol";

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
pragma solidity 0.8.13;

interface OracleInterface {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface ResilientOracleInterface is OracleInterface {
    function updatePrice(address vToken) external;
}

interface TwapInterface is OracleInterface {
    function updateTwap(address vToken) external returns (uint256);
}

interface BoundValidatorInterface {
    function validatePriceWithAnchorPrice(
        address vToken,
        uint256 reporterPrice,
        uint256 anchorPrice
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { ResilientOracleInterface } from "@venusprotocol/oracle/contracts/interfaces/OracleInterface.sol";
import { AccessControlledV8 } from "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";

import { ComptrollerInterface } from "./ComptrollerInterface.sol";
import { ComptrollerStorage } from "./ComptrollerStorage.sol";
import { ExponentialNoError } from "./ExponentialNoError.sol";
import { VToken } from "./VToken.sol";
import { RewardsDistributor } from "./Rewards/RewardsDistributor.sol";
import { MaxLoopsLimitHelper } from "./MaxLoopsLimitHelper.sol";
import { ensureNonzeroAddress } from "./lib/validators.sol";

/**
 * @title Comptroller
 * @author Venus
 * @notice The Comptroller is designed to provide checks for all minting, redeeming, transferring, borrowing, lending, repaying, liquidating,
 * and seizing done by the `vToken` contract. Each pool has one `Comptroller` checking these interactions across markets. When a user interacts
 * with a given market by one of these main actions, a call is made to a corresponding hook in the associated `Comptroller`, which either allows
 * or reverts the transaction. These hooks also update supply and borrow rewards as they are called. The comptroller holds the logic for assessing
 * liquidity snapshots of an account via the collateral factor and liquidation threshold. This check determines the collateral needed for a borrow,
 * as well as how much of a borrow may be liquidated. A user may borrow a portion of their collateral with the maximum amount determined by the
 * markets collateral factor. However, if their borrowed amount exceeds an amount calculated using the market’s corresponding liquidation threshold,
 * the borrow is eligible for liquidation.
 *
 * The `Comptroller` also includes two functions `liquidateAccount()` and `healAccount()`, which are meant to handle accounts that do not exceed
 * the `minLiquidatableCollateral` for the `Comptroller`:
 *
 * - `healAccount()`: This function is called to seize all of a given user’s collateral, requiring the `msg.sender` repay a certain percentage
 * of the debt calculated by `collateral/(borrows*liquidationIncentive)`. The function can only be called if the calculated percentage does not exceed
 * 100%, because otherwise no `badDebt` would be created and `liquidateAccount()` should be used instead. The difference in the actual amount of debt
 * and debt paid off is recorded as `badDebt` for each market, which can then be auctioned off for the risk reserves of the associated pool.
 * - `liquidateAccount()`: This function can only be called if the collateral seized will cover all borrows of an account, as well as the liquidation
 * incentive. Otherwise, the pool will incur bad debt, in which case the function `healAccount()` should be used instead. This function skips the logic
 * verifying that the repay amount does not exceed the close factor.
 */
contract Comptroller is
    Ownable2StepUpgradeable,
    AccessControlledV8,
    ComptrollerStorage,
    ComptrollerInterface,
    ExponentialNoError,
    MaxLoopsLimitHelper
{
    // PoolRegistry, immutable to save on gas
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable poolRegistry;

    /// @notice Emitted when an account enters a market
    event MarketEntered(VToken indexed vToken, address indexed account);

    /// @notice Emitted when an account exits a market
    event MarketExited(VToken indexed vToken, address indexed account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(VToken vToken, uint256 oldCollateralFactorMantissa, uint256 newCollateralFactorMantissa);

    /// @notice Emitted when liquidation threshold is changed by admin
    event NewLiquidationThreshold(
        VToken vToken,
        uint256 oldLiquidationThresholdMantissa,
        uint256 newLiquidationThresholdMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint256 oldLiquidationIncentiveMantissa, uint256 newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(ResilientOracleInterface oldPriceOracle, ResilientOracleInterface newPriceOracle);

    /// @notice Emitted when an action is paused on a market
    event ActionPausedMarket(VToken vToken, Action action, bool pauseState);

    /// @notice Emitted when borrow cap for a vToken is changed
    event NewBorrowCap(VToken indexed vToken, uint256 newBorrowCap);

    /// @notice Emitted when the collateral threshold (in USD) for non-batch liquidations is changed
    event NewMinLiquidatableCollateral(uint256 oldMinLiquidatableCollateral, uint256 newMinLiquidatableCollateral);

    /// @notice Emitted when supply cap for a vToken is changed
    event NewSupplyCap(VToken indexed vToken, uint256 newSupplyCap);

    /// @notice Emitted when a rewards distributor is added
    event NewRewardsDistributor(address indexed rewardsDistributor);

    /// @notice Emitted when a market is supported
    event MarketSupported(VToken vToken);

    /// @notice Thrown when collateral factor exceeds the upper bound
    error InvalidCollateralFactor();

    /// @notice Thrown when liquidation threshold exceeds the collateral factor
    error InvalidLiquidationThreshold();

    /// @notice Thrown when the action is only available to specific sender, but the real sender was different
    error UnexpectedSender(address expectedSender, address actualSender);

    /// @notice Thrown when the oracle returns an invalid price for some asset
    error PriceError(address vToken);

    /// @notice Thrown if VToken unexpectedly returned a nonzero error code while trying to get account snapshot
    error SnapshotError(address vToken, address user);

    /// @notice Thrown when the market is not listed
    error MarketNotListed(address market);

    /// @notice Thrown when a market has an unexpected comptroller
    error ComptrollerMismatch();

    /// @notice Thrown when user is not member of market
    error MarketNotCollateral(address vToken, address user);

    /**
     * @notice Thrown during the liquidation if user's total collateral amount is lower than
     *   a predefined threshold. In this case only batch liquidations (either liquidateAccount
     *   or healAccount) are available.
     */
    error MinimalCollateralViolated(uint256 expectedGreaterThan, uint256 actual);
    error CollateralExceedsThreshold(uint256 expectedLessThanOrEqualTo, uint256 actual);
    error InsufficientCollateral(uint256 collateralToSeize, uint256 availableCollateral);

    /// @notice Thrown when the account doesn't have enough liquidity to redeem or borrow
    error InsufficientLiquidity();

    /// @notice Thrown when trying to liquidate a healthy account
    error InsufficientShortfall();

    /// @notice Thrown when trying to repay more than allowed by close factor
    error TooMuchRepay();

    /// @notice Thrown if the user is trying to exit a market in which they have an outstanding debt
    error NonzeroBorrowBalance();

    /// @notice Thrown when trying to perform an action that is paused
    error ActionPaused(address market, Action action);

    /// @notice Thrown when trying to add a market that is already listed
    error MarketAlreadyListed(address market);

    /// @notice Thrown if the supply cap is exceeded
    error SupplyCapExceeded(address market, uint256 cap);

    /// @notice Thrown if the borrow cap is exceeded
    error BorrowCapExceeded(address market, uint256 cap);

    /// @param poolRegistry_ Pool registry address
    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @custom:error ZeroAddressNotAllowed is thrown when pool registry address is zero
    constructor(address poolRegistry_) {
        ensureNonzeroAddress(poolRegistry_);

        poolRegistry = poolRegistry_;
        _disableInitializers();
    }

    /**
     * @param loopLimit Limit for the loops can iterate to avoid the DOS
     * @param accessControlManager Access control manager contract address
     */
    function initialize(uint256 loopLimit, address accessControlManager) external initializer {
        __Ownable2Step_init();
        __AccessControlled_init_unchained(accessControlManager);

        _setMaxLoopsLimit(loopLimit);
    }

    /**
     * @notice Add assets to be included in account liquidity calculation; enabling them to be used as collateral
     * @param vTokens The list of addresses of the vToken markets to be enabled
     * @return errors An array of NO_ERROR for compatibility with Venus core tooling
     * @custom:event MarketEntered is emitted for each market on success
     * @custom:error ActionPaused error is thrown if entering any of the markets is paused
     * @custom:error MarketNotListed error is thrown if any of the markets is not listed
     * @custom:access Not restricted
     */
    function enterMarkets(address[] memory vTokens) external override returns (uint256[] memory) {
        uint256 len = vTokens.length;

        uint256[] memory results = new uint256[](len);
        for (uint256 i; i < len; ++i) {
            VToken vToken = VToken(vTokens[i]);

            _addToMarket(vToken, msg.sender);
            results[i] = NO_ERROR;
        }

        return results;
    }

    function removeMarket(address vToken) external {
        _checkAccessAllowed("removeMarket(address)");
        // Check if the market is listed.
        Market storage market = markets[address(vToken)];
        if (!market.isListed) {
            revert MarketNotListed(vToken);
        }

        // Remove the market from the list of all markets.
        uint256 marketsCount = allMarkets.length;
        for (uint256 i = 0; i < marketsCount; ++i) {
            if (allMarkets[i] == VToken(vToken)) {
                allMarkets[i] = allMarkets[marketsCount - 1];
                break;
            }
        }
        allMarkets.pop();
        // Delete the market struct from memory.
        delete markets[address(vToken)];
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation; disabling them as collateral
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param vTokenAddress The address of the asset to be removed
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event MarketExited is emitted on success
     * @custom:error ActionPaused error is thrown if exiting the market is paused
     * @custom:error NonzeroBorrowBalance error is thrown if the user has an outstanding borrow in this market
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:error InsufficientLiquidity error is thrown if exiting the market would lead to user's insolvency
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     * @custom:access Not restricted
     */
    function exitMarket(address vTokenAddress) external override returns (uint256) {
        _checkActionPauseState(vTokenAddress, Action.EXIT_MARKET);
        VToken vToken = VToken(vTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the vToken */
        (uint256 tokensHeld, uint256 amountOwed, ) = _safeGetAccountSnapshot(vToken, msg.sender);

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            revert NonzeroBorrowBalance();
        }

        /* Fail if the sender is not permitted to redeem all of their tokens */
        _checkRedeemAllowed(vTokenAddress, msg.sender, tokensHeld);

        Market storage marketToExit = markets[address(vToken)];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return NO_ERROR;
        }

        /* Set vToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete vToken from the account’s list of assets */
        // load into memory for faster iteration
        VToken[] memory userAssetList = accountAssets[msg.sender];
        uint256 len = userAssetList.length;

        uint256 assetIndex = len;
        for (uint256 i; i < len; ++i) {
            if (userAssetList[i] == vToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        VToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketExited(vToken, msg.sender);

        return NO_ERROR;
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param vToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @custom:error ActionPaused error is thrown if supplying to this market is paused
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:error SupplyCapExceeded error is thrown if the total supply exceeds the cap after minting
     * @custom:access Not restricted
     */
    function preMintHook(address vToken, address minter, uint256 mintAmount) external override {
        _checkActionPauseState(vToken, Action.MINT);

        if (!markets[vToken].isListed) {
            revert MarketNotListed(address(vToken));
        }

        uint256 supplyCap = supplyCaps[vToken];
        // Skipping the cap check for uncapped coins to save some gas
        if (supplyCap != type(uint256).max) {
            uint256 vTokenSupply = VToken(vToken).totalSupply();
            Exp memory exchangeRate = Exp({ mantissa: VToken(vToken).exchangeRateStored() });
            uint256 nextTotalSupply = mul_ScalarTruncateAddUInt(exchangeRate, vTokenSupply, mintAmount);
            if (nextTotalSupply > supplyCap) {
                revert SupplyCapExceeded(vToken, supplyCap);
            }
        }

        // Keep the flywheel moving
        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            rewardsDistributor.updateRewardTokenSupplyIndex(vToken);
            rewardsDistributor.distributeSupplierRewardToken(vToken, minter);
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param vToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of vTokens to exchange for the underlying asset in the market
     * @custom:error ActionPaused error is thrown if withdrawals are paused in this market
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:error InsufficientLiquidity error is thrown if the withdrawal would lead to user's insolvency
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     * @custom:access Not restricted
     */
    function preRedeemHook(address vToken, address redeemer, uint256 redeemTokens) external override {
        _checkActionPauseState(vToken, Action.REDEEM);

        _checkRedeemAllowed(vToken, redeemer, redeemTokens);

        // Keep the flywheel moving
        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            rewardsDistributor.updateRewardTokenSupplyIndex(vToken);
            rewardsDistributor.distributeSupplierRewardToken(vToken, redeemer);
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param vToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @custom:error ActionPaused error is thrown if borrowing is paused in this market
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:error InsufficientLiquidity error is thrown if there is not enough collateral to borrow
     * @custom:error BorrowCapExceeded is thrown if the borrow cap will be exceeded should this borrow succeed
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     * @custom:access Not restricted if vToken is enabled as collateral, otherwise only vToken
     */
    /// disable-eslint
    function preBorrowHook(address vToken, address borrower, uint256 borrowAmount) external override {
        _checkActionPauseState(vToken, Action.BORROW);

        if (!markets[vToken].isListed) {
            revert MarketNotListed(address(vToken));
        }

        if (!markets[vToken].accountMembership[borrower]) {
            // only vTokens may call borrowAllowed if borrower not in market
            _checkSenderIs(vToken);

            // attempt to add borrower to the market or revert
            _addToMarket(VToken(msg.sender), borrower);
        }

        // Update the prices of tokens
        updatePrices(borrower);

        if (oracle.getUnderlyingPrice(vToken) == 0) {
            revert PriceError(address(vToken));
        }

        uint256 borrowCap = borrowCaps[vToken];
        // Skipping the cap check for uncapped coins to save some gas
        if (borrowCap != type(uint256).max) {
            uint256 totalBorrows = VToken(vToken).totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            if (nextTotalBorrows > borrowCap) {
                revert BorrowCapExceeded(vToken, borrowCap);
            }
        }

        AccountLiquiditySnapshot memory snapshot = _getHypotheticalLiquiditySnapshot(
            borrower,
            VToken(vToken),
            0,
            borrowAmount,
            _getCollateralFactor
        );

        if (snapshot.shortfall > 0) {
            revert InsufficientLiquidity();
        }

        Exp memory borrowIndex = Exp({ mantissa: VToken(vToken).borrowIndex() });

        // Keep the flywheel moving
        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            rewardsDistributor.updateRewardTokenBorrowIndex(vToken, borrowIndex);
            rewardsDistributor.distributeBorrowerRewardToken(vToken, borrower, borrowIndex);
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param vToken The market to verify the repay against
     * @param borrower The account which would borrowed the asset
     * @custom:error ActionPaused error is thrown if repayments are paused in this market
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:access Not restricted
     */
    function preRepayHook(address vToken, address borrower) external override {
        _checkActionPauseState(vToken, Action.REPAY);

        oracle.updatePrice(vToken);

        if (!markets[vToken].isListed) {
            revert MarketNotListed(address(vToken));
        }

        // Keep the flywheel moving
        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            Exp memory borrowIndex = Exp({ mantissa: VToken(vToken).borrowIndex() });
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            rewardsDistributor.updateRewardTokenBorrowIndex(vToken, borrowIndex);
            rewardsDistributor.distributeBorrowerRewardToken(vToken, borrower, borrowIndex);
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param vTokenBorrowed Asset which was borrowed by the borrower
     * @param vTokenCollateral Asset which was used as collateral and will be seized
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     * @param skipLiquidityCheck Allows the borrow to be liquidated regardless of the account liquidity
     * @custom:error ActionPaused error is thrown if liquidations are paused in this market
     * @custom:error MarketNotListed error is thrown if either collateral or borrowed token is not listed
     * @custom:error TooMuchRepay error is thrown if the liquidator is trying to repay more than allowed by close factor
     * @custom:error MinimalCollateralViolated is thrown if the users' total collateral is lower than the threshold for non-batch liquidations
     * @custom:error InsufficientShortfall is thrown when trying to liquidate a healthy account
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     */
    function preLiquidateHook(
        address vTokenBorrowed,
        address vTokenCollateral,
        address borrower,
        uint256 repayAmount,
        bool skipLiquidityCheck
    ) external override {
        // Pause Action.LIQUIDATE on BORROWED TOKEN to prevent liquidating it.
        // If we want to pause liquidating to vTokenCollateral, we should pause
        // Action.SEIZE on it
        _checkActionPauseState(vTokenBorrowed, Action.LIQUIDATE);

        // Update the prices of tokens
        updatePrices(borrower);

        if (!markets[vTokenBorrowed].isListed) {
            revert MarketNotListed(address(vTokenBorrowed));
        }
        if (!markets[vTokenCollateral].isListed) {
            revert MarketNotListed(address(vTokenCollateral));
        }

        uint256 borrowBalance = VToken(vTokenBorrowed).borrowBalanceStored(borrower);

        /* Allow accounts to be liquidated if the market is deprecated or it is a forced liquidation */
        if (skipLiquidityCheck || isDeprecated(VToken(vTokenBorrowed))) {
            if (repayAmount > borrowBalance) {
                revert TooMuchRepay();
            }
            return;
        }

        /* The borrower must have shortfall and collateral > threshold in order to be liquidatable */
        AccountLiquiditySnapshot memory snapshot = _getCurrentLiquiditySnapshot(borrower, _getLiquidationThreshold);

        if (snapshot.totalCollateral <= minLiquidatableCollateral) {
            /* The liquidator should use either liquidateAccount or healAccount */
            revert MinimalCollateralViolated(minLiquidatableCollateral, snapshot.totalCollateral);
        }

        if (snapshot.shortfall == 0) {
            revert InsufficientShortfall();
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint256 maxClose = mul_ScalarTruncate(Exp({ mantissa: closeFactorMantissa }), borrowBalance);
        if (repayAmount > maxClose) {
            revert TooMuchRepay();
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param vTokenCollateral Asset which was used as collateral and will be seized
     * @param seizerContract Contract that tries to seize the asset (either borrowed vToken or Comptroller)
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @custom:error ActionPaused error is thrown if seizing this type of collateral is paused
     * @custom:error MarketNotListed error is thrown if either collateral or borrowed token is not listed
     * @custom:error ComptrollerMismatch error is when seizer contract or seized asset belong to different pools
     * @custom:access Not restricted
     */
    function preSeizeHook(
        address vTokenCollateral,
        address seizerContract,
        address liquidator,
        address borrower
    ) external override {
        // Pause Action.SEIZE on COLLATERAL to prevent seizing it.
        // If we want to pause liquidating vTokenBorrowed, we should pause
        // Action.LIQUIDATE on it
        _checkActionPauseState(vTokenCollateral, Action.SEIZE);

        Market storage market = markets[vTokenCollateral];

        if (!market.isListed) {
            revert MarketNotListed(vTokenCollateral);
        }

        if (seizerContract == address(this)) {
            // If Comptroller is the seizer, just check if collateral's comptroller
            // is equal to the current address
            if (address(VToken(vTokenCollateral).comptroller()) != address(this)) {
                revert ComptrollerMismatch();
            }
        } else {
            // If the seizer is not the Comptroller, check that the seizer is a
            // listed market, and that the markets' comptrollers match
            if (!markets[seizerContract].isListed) {
                revert MarketNotListed(seizerContract);
            }
            if (VToken(vTokenCollateral).comptroller() != VToken(seizerContract).comptroller()) {
                revert ComptrollerMismatch();
            }
        }

        if (!market.accountMembership[borrower]) {
            revert MarketNotCollateral(vTokenCollateral, borrower);
        }

        // Keep the flywheel moving
        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            rewardsDistributor.updateRewardTokenSupplyIndex(vTokenCollateral);
            rewardsDistributor.distributeSupplierRewardToken(vTokenCollateral, borrower);
            rewardsDistributor.distributeSupplierRewardToken(vTokenCollateral, liquidator);
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param vToken The market to verify the transfer against
     * @param src The account which sources the tokens
     * @param dst The account which receives the tokens
     * @param transferTokens The number of vTokens to transfer
     * @custom:error ActionPaused error is thrown if withdrawals are paused in this market
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:error InsufficientLiquidity error is thrown if the withdrawal would lead to user's insolvency
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     * @custom:access Not restricted
     */
    function preTransferHook(address vToken, address src, address dst, uint256 transferTokens) external override {
        _checkActionPauseState(vToken, Action.TRANSFER);

        // Currently the only consideration is whether or not
        //  the src is allowed to redeem this many tokens
        _checkRedeemAllowed(vToken, src, transferTokens);

        // Keep the flywheel moving
        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            rewardsDistributor.updateRewardTokenSupplyIndex(vToken);
            rewardsDistributor.distributeSupplierRewardToken(vToken, src);
            rewardsDistributor.distributeSupplierRewardToken(vToken, dst);
        }
    }

    /*** Pool-level operations ***/

    /**
     * @notice Seizes all the remaining collateral, makes msg.sender repay the existing
     *   borrows, and treats the rest of the debt as bad debt (for each market).
     *   The sender has to repay a certain percentage of the debt, computed as
     *   collateral / (borrows * liquidationIncentive).
     * @param user account to heal
     * @custom:error CollateralExceedsThreshold error is thrown when the collateral is too big for healing
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     * @custom:access Not restricted
     */
    function healAccount(address user) external {
        VToken[] memory userAssets = accountAssets[user];
        uint256 userAssetsCount = userAssets.length;

        address liquidator = msg.sender;
        {
            ResilientOracleInterface oracle_ = oracle;
            // We need all user's markets to be fresh for the computations to be correct
            for (uint256 i; i < userAssetsCount; ++i) {
                userAssets[i].accrueInterest();
                oracle_.updatePrice(address(userAssets[i]));
            }
        }

        AccountLiquiditySnapshot memory snapshot = _getCurrentLiquiditySnapshot(user, _getLiquidationThreshold);

        if (snapshot.totalCollateral > minLiquidatableCollateral) {
            revert CollateralExceedsThreshold(minLiquidatableCollateral, snapshot.totalCollateral);
        }

        if (snapshot.shortfall == 0) {
            revert InsufficientShortfall();
        }

        // percentage = collateral / (borrows * liquidation incentive)
        Exp memory collateral = Exp({ mantissa: snapshot.totalCollateral });
        Exp memory scaledBorrows = mul_(
            Exp({ mantissa: snapshot.borrows }),
            Exp({ mantissa: liquidationIncentiveMantissa })
        );

        Exp memory percentage = div_(collateral, scaledBorrows);
        if (lessThanExp(Exp({ mantissa: MANTISSA_ONE }), percentage)) {
            revert CollateralExceedsThreshold(scaledBorrows.mantissa, collateral.mantissa);
        }

        for (uint256 i; i < userAssetsCount; ++i) {
            VToken market = userAssets[i];

            (uint256 tokens, uint256 borrowBalance, ) = _safeGetAccountSnapshot(market, user);
            uint256 repaymentAmount = mul_ScalarTruncate(percentage, borrowBalance);

            // Seize the entire collateral
            if (tokens != 0) {
                market.seize(liquidator, user, tokens);
            }
            // Repay a certain percentage of the borrow, forgive the rest
            if (borrowBalance != 0) {
                market.healBorrow(liquidator, user, repaymentAmount);
            }
        }
    }

    /**
     * @notice Liquidates all borrows of the borrower. Callable only if the collateral is less than
     *   a predefined threshold, and the account collateral can be seized to cover all borrows. If
     *   the collateral is higher than the threshold, use regular liquidations. If the collateral is
     *   below the threshold, and the account is insolvent, use healAccount.
     * @param borrower the borrower address
     * @param orders an array of liquidation orders
     * @custom:error CollateralExceedsThreshold error is thrown when the collateral is too big for a batch liquidation
     * @custom:error InsufficientCollateral error is thrown when there is not enough collateral to cover the debt
     * @custom:error SnapshotError is thrown if some vToken fails to return the account's supply and borrows
     * @custom:error PriceError is thrown if the oracle returns an incorrect price for some asset
     * @custom:access Not restricted
     */
    function liquidateAccount(address borrower, LiquidationOrder[] calldata orders) external {
        // We will accrue interest and update the oracle prices later during the liquidation

        AccountLiquiditySnapshot memory snapshot = _getCurrentLiquiditySnapshot(borrower, _getLiquidationThreshold);

        if (snapshot.totalCollateral > minLiquidatableCollateral) {
            // You should use the regular vToken.liquidateBorrow(...) call
            revert CollateralExceedsThreshold(minLiquidatableCollateral, snapshot.totalCollateral);
        }

        uint256 collateralToSeize = mul_ScalarTruncate(
            Exp({ mantissa: liquidationIncentiveMantissa }),
            snapshot.borrows
        );
        if (collateralToSeize >= snapshot.totalCollateral) {
            // There is not enough collateral to seize. Use healBorrow to repay some part of the borrow
            // and record bad debt.
            revert InsufficientCollateral(collateralToSeize, snapshot.totalCollateral);
        }

        if (snapshot.shortfall == 0) {
            revert InsufficientShortfall();
        }

        uint256 ordersCount = orders.length;

        _ensureMaxLoops(ordersCount / 2);

        for (uint256 i; i < ordersCount; ++i) {
            if (!markets[address(orders[i].vTokenBorrowed)].isListed) {
                revert MarketNotListed(address(orders[i].vTokenBorrowed));
            }
            if (!markets[address(orders[i].vTokenCollateral)].isListed) {
                revert MarketNotListed(address(orders[i].vTokenCollateral));
            }

            LiquidationOrder calldata order = orders[i];
            order.vTokenBorrowed.forceLiquidateBorrow(
                msg.sender,
                borrower,
                order.repayAmount,
                order.vTokenCollateral,
                true
            );
        }

        VToken[] memory borrowMarkets = accountAssets[borrower];
        uint256 marketsCount = borrowMarkets.length;

        for (uint256 i; i < marketsCount; ++i) {
            (, uint256 borrowBalance, ) = _safeGetAccountSnapshot(borrowMarkets[i], borrower);
            require(borrowBalance == 0, "Nonzero borrow balance after liquidation");
        }
    }

    /**
     * @notice Sets the closeFactor to use when liquidating borrows
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     * @custom:event Emits NewCloseFactor on success
     * @custom:access Controlled by AccessControlManager
     */
    function setCloseFactor(uint256 newCloseFactorMantissa) external {
        _checkAccessAllowed("setCloseFactor(uint256)");
        require(MAX_CLOSE_FACTOR_MANTISSA >= newCloseFactorMantissa, "Close factor greater than maximum close factor");
        require(MIN_CLOSE_FACTOR_MANTISSA <= newCloseFactorMantissa, "Close factor smaller than minimum close factor");

        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, newCloseFactorMantissa);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev This function is restricted by the AccessControlManager
     * @param vToken The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     * @param newLiquidationThresholdMantissa The new liquidation threshold, scaled by 1e18
     * @custom:event Emits NewCollateralFactor when collateral factor is updated
     *    and NewLiquidationThreshold when liquidation threshold is updated
     * @custom:error MarketNotListed error is thrown when the market is not listed
     * @custom:error InvalidCollateralFactor error is thrown when collateral factor is too high
     * @custom:error InvalidLiquidationThreshold error is thrown when liquidation threshold is lower than collateral factor
     * @custom:error PriceError is thrown when the oracle returns an invalid price for the asset
     * @custom:access Controlled by AccessControlManager
     */
    function setCollateralFactor(
        VToken vToken,
        uint256 newCollateralFactorMantissa,
        uint256 newLiquidationThresholdMantissa
    ) external {
        _checkAccessAllowed("setCollateralFactor(address,uint256,uint256)");

        // Verify market is listed
        Market storage market = markets[address(vToken)];
        if (!market.isListed) {
            revert MarketNotListed(address(vToken));
        }

        // Check collateral factor <= 0.9
        if (newCollateralFactorMantissa > MAX_COLLATERAL_FACTOR_MANTISSA) {
            revert InvalidCollateralFactor();
        }

        // Ensure that liquidation threshold <= 1
        if (newLiquidationThresholdMantissa > MANTISSA_ONE) {
            revert InvalidLiquidationThreshold();
        }

        // Ensure that liquidation threshold >= CF
        if (newLiquidationThresholdMantissa < newCollateralFactorMantissa) {
            revert InvalidLiquidationThreshold();
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(address(vToken)) == 0) {
            revert PriceError(address(vToken));
        }

        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        if (newCollateralFactorMantissa != oldCollateralFactorMantissa) {
            market.collateralFactorMantissa = newCollateralFactorMantissa;
            emit NewCollateralFactor(vToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);
        }

        uint256 oldLiquidationThresholdMantissa = market.liquidationThresholdMantissa;
        if (newLiquidationThresholdMantissa != oldLiquidationThresholdMantissa) {
            market.liquidationThresholdMantissa = newLiquidationThresholdMantissa;
            emit NewLiquidationThreshold(vToken, oldLiquidationThresholdMantissa, newLiquidationThresholdMantissa);
        }
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev This function is restricted by the AccessControlManager
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @custom:event Emits NewLiquidationIncentive on success
     * @custom:access Controlled by AccessControlManager
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external {
        require(newLiquidationIncentiveMantissa >= MANTISSA_ONE, "liquidation incentive should be greater than 1e18");

        _checkAccessAllowed("setLiquidationIncentive(uint256)");

        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Only callable by the PoolRegistry
     * @param vToken The address of the market (token) to list
     * @custom:error MarketAlreadyListed is thrown if the market is already listed in this pool
     * @custom:access Only PoolRegistry
     */
    function supportMarket(VToken vToken) external {
        _checkSenderIs(poolRegistry);

        if (markets[address(vToken)].isListed) {
            revert MarketAlreadyListed(address(vToken));
        }

        require(vToken.isVToken(), "Comptroller: Invalid vToken"); // Sanity check to make sure its really a VToken

        Market storage newMarket = markets[address(vToken)];
        newMarket.isListed = true;
        newMarket.collateralFactorMantissa = 0;
        newMarket.liquidationThresholdMantissa = 0;

        _addMarket(address(vToken));

        uint256 rewardDistributorsCount = rewardsDistributors.length;

        for (uint256 i; i < rewardDistributorsCount; ++i) {
            rewardsDistributors[i].initializeMarket(address(vToken));
        }

        emit MarketSupported(vToken);
    }

    /**
     * @notice Set the given borrow caps for the given vToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev This function is restricted by the AccessControlManager
     * @dev A borrow cap of type(uint256).max corresponds to unlimited borrowing.
     * @dev Borrow caps smaller than the current total borrows are accepted. This way, new borrows will not be allowed
            until the total borrows amount goes below the new borrow cap
     * @param vTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of type(uint256).max corresponds to unlimited borrowing.
     * @custom:access Controlled by AccessControlManager
     */
    function setMarketBorrowCaps(VToken[] calldata vTokens, uint256[] calldata newBorrowCaps) external {
        _checkAccessAllowed("setMarketBorrowCaps(address[],uint256[])");

        uint256 numMarkets = vTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        _ensureMaxLoops(numMarkets);

        for (uint256 i; i < numMarkets; ++i) {
            borrowCaps[address(vTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(vTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Set the given supply caps for the given vToken markets. Supply that brings total Supply to or above supply cap will revert.
     * @dev This function is restricted by the AccessControlManager
     * @dev A supply cap of type(uint256).max corresponds to unlimited supply.
     * @dev Supply caps smaller than the current total supplies are accepted. This way, new supplies will not be allowed
            until the total supplies amount goes below the new supply cap
     * @param vTokens The addresses of the markets (tokens) to change the supply caps for
     * @param newSupplyCaps The new supply cap values in underlying to be set. A value of type(uint256).max corresponds to unlimited supply.
     * @custom:access Controlled by AccessControlManager
     */
    function setMarketSupplyCaps(VToken[] calldata vTokens, uint256[] calldata newSupplyCaps) external {
        _checkAccessAllowed("setMarketSupplyCaps(address[],uint256[])");
        uint256 vTokensCount = vTokens.length;

        require(vTokensCount != 0, "invalid number of markets");
        require(vTokensCount == newSupplyCaps.length, "invalid number of markets");

        _ensureMaxLoops(vTokensCount);

        for (uint256 i; i < vTokensCount; ++i) {
            supplyCaps[address(vTokens[i])] = newSupplyCaps[i];
            emit NewSupplyCap(vTokens[i], newSupplyCaps[i]);
        }
    }

    /**
     * @notice Pause/unpause specified actions
     * @dev This function is restricted by the AccessControlManager
     * @param marketsList Markets to pause/unpause the actions on
     * @param actionsList List of action ids to pause/unpause
     * @param paused The new paused state (true=paused, false=unpaused)
     * @custom:access Controlled by AccessControlManager
     */
    function setActionsPaused(VToken[] calldata marketsList, Action[] calldata actionsList, bool paused) external {
        _checkAccessAllowed("setActionsPaused(address[],uint256[],bool)");

        uint256 marketsCount = marketsList.length;
        uint256 actionsCount = actionsList.length;

        _ensureMaxLoops(marketsCount * actionsCount);

        for (uint256 marketIdx; marketIdx < marketsCount; ++marketIdx) {
            for (uint256 actionIdx; actionIdx < actionsCount; ++actionIdx) {
                _setActionPaused(address(marketsList[marketIdx]), actionsList[actionIdx], paused);
            }
        }
    }

    /**
     * @notice Set the given collateral threshold for non-batch liquidations. Regular liquidations
     *   will fail if the collateral amount is less than this threshold. Liquidators should use batch
     *   operations like liquidateAccount or healAccount.
     * @dev This function is restricted by the AccessControlManager
     * @param newMinLiquidatableCollateral The new min liquidatable collateral (in USD).
     * @custom:access Controlled by AccessControlManager
     */
    function setMinLiquidatableCollateral(uint256 newMinLiquidatableCollateral) external {
        _checkAccessAllowed("setMinLiquidatableCollateral(uint256)");

        uint256 oldMinLiquidatableCollateral = minLiquidatableCollateral;
        minLiquidatableCollateral = newMinLiquidatableCollateral;
        emit NewMinLiquidatableCollateral(oldMinLiquidatableCollateral, newMinLiquidatableCollateral);
    }

    /**
     * @notice Add a new RewardsDistributor and initialize it with all markets
     * @dev Only callable by the admin
     * @param _rewardsDistributor Address of the RewardDistributor contract to add
     * @custom:access Only Governance
     * @custom:event Emits NewRewardsDistributor with distributor address
     */
    function addRewardsDistributor(RewardsDistributor _rewardsDistributor) external onlyOwner {
        require(!rewardsDistributorExists[address(_rewardsDistributor)], "already exists");

        uint256 rewardsDistributorsLength = rewardsDistributors.length;

        for (uint256 i; i < rewardsDistributorsLength; ++i) {
            address rewardToken = address(rewardsDistributors[i].rewardToken());
            require(
                rewardToken != address(_rewardsDistributor.rewardToken()),
                "distributor already exists with this reward"
            );
        }

        uint256 rewardsDistributorsLen = rewardsDistributors.length;
        _ensureMaxLoops(rewardsDistributorsLen + 1);

        rewardsDistributors.push(_rewardsDistributor);
        rewardsDistributorExists[address(_rewardsDistributor)] = true;

        uint256 marketsCount = allMarkets.length;

        for (uint256 i; i < marketsCount; ++i) {
            _rewardsDistributor.initializeMarket(address(allMarkets[i]));
        }

        emit NewRewardsDistributor(address(_rewardsDistributor));
    }

    /**
     * @notice Sets a new price oracle for the Comptroller
     * @dev Only callable by the admin
     * @param newOracle Address of the new price oracle to set
     * @custom:event Emits NewPriceOracle on success
     * @custom:error ZeroAddressNotAllowed is thrown when the new oracle address is zero
     */
    function setPriceOracle(ResilientOracleInterface newOracle) external onlyOwner {
        ensureNonzeroAddress(address(newOracle));

        ResilientOracleInterface oldOracle = oracle;
        oracle = newOracle;
        emit NewPriceOracle(oldOracle, newOracle);
    }

    /**
     * @notice Set the for loop iteration limit to avoid DOS
     * @param limit Limit for the max loops can execute at a time
     */
    function setMaxLoopsLimit(uint256 limit) external onlyOwner {
        _setMaxLoopsLimit(limit);
    }

    /**
     * @notice Determine the current account liquidity with respect to liquidation threshold requirements
     * @dev The interface of this function is intentionally kept compatible with Compound and Venus Core
     * @param account The account get liquidity for
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @return liquidity Account liquidity in excess of liquidation threshold requirements,
     * @return shortfall Account shortfall below liquidation threshold requirements
     */
    function getAccountLiquidity(
        address account
    ) external view returns (uint256 error, uint256 liquidity, uint256 shortfall) {
        AccountLiquiditySnapshot memory snapshot = _getCurrentLiquiditySnapshot(account, _getLiquidationThreshold);
        return (NO_ERROR, snapshot.liquidity, snapshot.shortfall);
    }

    /**
     * @notice Determine the current account liquidity with respect to collateral requirements
     * @dev The interface of this function is intentionally kept compatible with Compound and Venus Core
     * @param account The account get liquidity for
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @return liquidity Account liquidity in excess of collateral requirements,
     * @return shortfall Account shortfall below collateral requirements
     */
    function getBorrowingPower(
        address account
    ) external view returns (uint256 error, uint256 liquidity, uint256 shortfall) {
        AccountLiquiditySnapshot memory snapshot = _getCurrentLiquiditySnapshot(account, _getCollateralFactor);
        return (NO_ERROR, snapshot.liquidity, snapshot.shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @dev The interface of this function is intentionally kept compatible with Compound and Venus Core
     * @param vTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @return liquidity Hypothetical account liquidity in excess of collateral requirements,
     * @return shortfall Hypothetical account shortfall below collateral requirements
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) external view returns (uint256 error, uint256 liquidity, uint256 shortfall) {
        AccountLiquiditySnapshot memory snapshot = _getHypotheticalLiquiditySnapshot(
            account,
            VToken(vTokenModify),
            redeemTokens,
            borrowAmount,
            _getCollateralFactor
        );
        return (NO_ERROR, snapshot.liquidity, snapshot.shortfall);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return markets The list of market addresses
     */
    function getAllMarkets() external view override returns (VToken[] memory) {
        return allMarkets;
    }

    /**
     * @notice Check if a market is marked as listed (active)
     * @param vToken vToken Address for the market to check
     * @return listed True if listed otherwise false
     */
    function isMarketListed(VToken vToken) external view returns (bool) {
        return markets[address(vToken)].isListed;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (VToken[] memory) {
        VToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in a given market
     * @param account The address of the account to check
     * @param vToken The vToken to check
     * @return True if the account is in the market specified, otherwise false.
     */
    function checkMembership(address account, VToken vToken) external view returns (bool) {
        return markets[address(vToken)].accountMembership[account];
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in vToken.liquidateBorrowFresh)
     * @param vTokenBorrowed The address of the borrowed vToken
     * @param vTokenCollateral The address of the collateral vToken
     * @param actualRepayAmount The amount of vTokenBorrowed underlying to convert into vTokenCollateral tokens
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @return tokensToSeize Number of vTokenCollateral tokens to be seized in a liquidation
     * @custom:error PriceError if the oracle returns an invalid price
     */
    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint256 actualRepayAmount
    ) external view override returns (uint256 error, uint256 tokensToSeize) {
        /* Read oracle prices for borrowed and collateral markets */
        uint256 priceBorrowedMantissa = _safeGetUnderlyingPrice(VToken(vTokenBorrowed));
        uint256 priceCollateralMantissa = _safeGetUnderlyingPrice(VToken(vTokenCollateral));

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint256 exchangeRateMantissa = VToken(vTokenCollateral).exchangeRateStored(); // Note: reverts on error
        uint256 seizeTokens;
        Exp memory numerator;
        Exp memory denominator;
        Exp memory ratio;

        numerator = mul_(Exp({ mantissa: liquidationIncentiveMantissa }), Exp({ mantissa: priceBorrowedMantissa }));
        denominator = mul_(Exp({ mantissa: priceCollateralMantissa }), Exp({ mantissa: exchangeRateMantissa }));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);

        return (NO_ERROR, seizeTokens);
    }

    /**
     * @notice Returns reward speed given a vToken
     * @param vToken The vToken to get the reward speeds for
     * @return rewardSpeeds Array of total supply and borrow speeds and reward token for all reward distributors
     */
    function getRewardsByMarket(address vToken) external view returns (RewardSpeeds[] memory rewardSpeeds) {
        uint256 rewardsDistributorsLength = rewardsDistributors.length;
        rewardSpeeds = new RewardSpeeds[](rewardsDistributorsLength);
        for (uint256 i; i < rewardsDistributorsLength; ++i) {
            RewardsDistributor rewardsDistributor = rewardsDistributors[i];
            address rewardToken = address(rewardsDistributor.rewardToken());
            rewardSpeeds[i] = RewardSpeeds({
                rewardToken: rewardToken,
                supplySpeed: rewardsDistributor.rewardTokenSupplySpeeds(vToken),
                borrowSpeed: rewardsDistributor.rewardTokenBorrowSpeeds(vToken)
            });
        }
        return rewardSpeeds;
    }

    /**
     * @notice Return all reward distributors for this pool
     * @return Array of RewardDistributor addresses
     */
    function getRewardDistributors() external view returns (RewardsDistributor[] memory) {
        return rewardsDistributors;
    }

    /**
     * @notice A marker method that returns true for a valid Comptroller contract
     * @return Always true
     */
    function isComptroller() external pure override returns (bool) {
        return true;
    }

    /**
     * @notice Update the prices of all the tokens associated with the provided account
     * @param account Address of the account to get associated tokens with
     */
    function updatePrices(address account) public {
        VToken[] memory vTokens = accountAssets[account];
        uint256 vTokensCount = vTokens.length;

        ResilientOracleInterface oracle_ = oracle;

        for (uint256 i; i < vTokensCount; ++i) {
            oracle_.updatePrice(address(vTokens[i]));
        }
    }

    /**
     * @notice Checks if a certain action is paused on a market
     * @param market vToken address
     * @param action Action to check
     * @return paused True if the action is paused otherwise false
     */
    function actionPaused(address market, Action action) public view returns (bool) {
        return _actionPaused[market][action];
    }

    /**
     * @notice Check if a vToken market has been deprecated
     * @dev All borrows in a deprecated vToken market can be immediately liquidated
     * @param vToken The market to check if deprecated
     * @return deprecated True if the given vToken market has been deprecated
     */
    function isDeprecated(VToken vToken) public view returns (bool) {
        return
            markets[address(vToken)].collateralFactorMantissa == 0 &&
            actionPaused(address(vToken), Action.BORROW) &&
            vToken.reserveFactorMantissa() == MANTISSA_ONE;
    }

    /**
     * @notice Add the market to the borrower's "assets in" for liquidity calculations
     * @param vToken The market to enter
     * @param borrower The address of the account to modify
     */
    function _addToMarket(VToken vToken, address borrower) internal {
        _checkActionPauseState(address(vToken), Action.ENTER_MARKET);
        Market storage marketToJoin = markets[address(vToken)];

        if (!marketToJoin.isListed) {
            revert MarketNotListed(address(vToken));
        }

        if (marketToJoin.accountMembership[borrower]) {
            // already joined
            return;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[borrower] = true;
        accountAssets[borrower].push(vToken);

        emit MarketEntered(vToken, borrower);
    }

    /**
     * @notice Internal function to validate that a market hasn't already been added
     * and if it hasn't adds it
     * @param vToken The market to support
     */
    function _addMarket(address vToken) internal {
        uint256 marketsCount = allMarkets.length;

        for (uint256 i; i < marketsCount; ++i) {
            if (allMarkets[i] == VToken(vToken)) {
                revert MarketAlreadyListed(vToken);
            }
        }
        allMarkets.push(VToken(vToken));
        marketsCount = allMarkets.length;
        _ensureMaxLoops(marketsCount);
    }

    /**
     * @dev Pause/unpause an action on a market
     * @param market Market to pause/unpause the action on
     * @param action Action id to pause/unpause
     * @param paused The new paused state (true=paused, false=unpaused)
     */
    function _setActionPaused(address market, Action action, bool paused) internal {
        require(markets[market].isListed, "cannot pause a market that is not listed");
        _actionPaused[market][action] = paused;
        emit ActionPausedMarket(VToken(market), action, paused);
    }

    /**
     * @dev Internal function to check that vTokens can be safely redeemed for the underlying asset.
     * @param vToken Address of the vTokens to redeem
     * @param redeemer Account redeeming the tokens
     * @param redeemTokens The number of tokens to redeem
     */
    function _checkRedeemAllowed(address vToken, address redeemer, uint256 redeemTokens) internal {
        Market storage market = markets[vToken];

        if (!market.isListed) {
            revert MarketNotListed(address(vToken));
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!market.accountMembership[redeemer]) {
            return;
        }

        // Update the prices of tokens
        updatePrices(redeemer);

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        AccountLiquiditySnapshot memory snapshot = _getHypotheticalLiquiditySnapshot(
            redeemer,
            VToken(vToken),
            redeemTokens,
            0,
            _getCollateralFactor
        );
        if (snapshot.shortfall > 0) {
            revert InsufficientLiquidity();
        }
    }

    /**
     * @notice Get the total collateral, weighted collateral, borrow balance, liquidity, shortfall
     * @param account The account to get the snapshot for
     * @param weight The function to compute the weight of the collateral – either collateral factor or
     *  liquidation threshold. Accepts the address of the vToken and returns the weight as Exp.
     * @dev Note that we calculate the exchangeRateStored for each collateral vToken using stored data,
     *  without calculating accumulated interest.
     * @return snapshot Account liquidity snapshot
     */
    function _getCurrentLiquiditySnapshot(
        address account,
        function(VToken) internal view returns (Exp memory) weight
    ) internal view returns (AccountLiquiditySnapshot memory snapshot) {
        return _getHypotheticalLiquiditySnapshot(account, VToken(address(0)), 0, 0, weight);
    }

    /**
     * @notice Determine what the supply/borrow balances would be if the given amounts were redeemed/borrowed
     * @param vTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @param weight The function to compute the weight of the collateral – either collateral factor or
         liquidation threshold. Accepts the address of the VToken and returns the weight
     * @dev Note that we calculate the exchangeRateStored for each collateral vToken using stored data,
     *  without calculating accumulated interest.
     * @return snapshot Account liquidity snapshot
     */
    function _getHypotheticalLiquiditySnapshot(
        address account,
        VToken vTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount,
        function(VToken) internal view returns (Exp memory) weight
    ) internal view returns (AccountLiquiditySnapshot memory snapshot) {
        // For each asset the account is in
        VToken[] memory assets = accountAssets[account];
        uint256 assetsCount = assets.length;

        for (uint256 i; i < assetsCount; ++i) {
            VToken asset = assets[i];

            // Read the balances and exchange rate from the vToken
            (uint256 vTokenBalance, uint256 borrowBalance, uint256 exchangeRateMantissa) = _safeGetAccountSnapshot(
                asset,
                account
            );

            // Get the normalized price of the asset
            Exp memory oraclePrice = Exp({ mantissa: _safeGetUnderlyingPrice(asset) });

            // Pre-compute conversion factors from vTokens -> usd
            Exp memory vTokenPrice = mul_(Exp({ mantissa: exchangeRateMantissa }), oraclePrice);
            Exp memory weightedVTokenPrice = mul_(weight(asset), vTokenPrice);

            // weightedCollateral += weightedVTokenPrice * vTokenBalance
            snapshot.weightedCollateral = mul_ScalarTruncateAddUInt(
                weightedVTokenPrice,
                vTokenBalance,
                snapshot.weightedCollateral
            );

            // totalCollateral += vTokenPrice * vTokenBalance
            snapshot.totalCollateral = mul_ScalarTruncateAddUInt(vTokenPrice, vTokenBalance, snapshot.totalCollateral);

            // borrows += oraclePrice * borrowBalance
            snapshot.borrows = mul_ScalarTruncateAddUInt(oraclePrice, borrowBalance, snapshot.borrows);

            // Calculate effects of interacting with vTokenModify
            if (asset == vTokenModify) {
                // redeem effect
                // effects += tokensToDenom * redeemTokens
                snapshot.effects = mul_ScalarTruncateAddUInt(weightedVTokenPrice, redeemTokens, snapshot.effects);

                // borrow effect
                // effects += oraclePrice * borrowAmount
                snapshot.effects = mul_ScalarTruncateAddUInt(oraclePrice, borrowAmount, snapshot.effects);
            }
        }

        uint256 borrowPlusEffects = snapshot.borrows + snapshot.effects;
        // These are safe, as the underflow condition is checked first
        unchecked {
            if (snapshot.weightedCollateral > borrowPlusEffects) {
                snapshot.liquidity = snapshot.weightedCollateral - borrowPlusEffects;
                snapshot.shortfall = 0;
            } else {
                snapshot.liquidity = 0;
                snapshot.shortfall = borrowPlusEffects - snapshot.weightedCollateral;
            }
        }

        return snapshot;
    }

    /**
     * @dev Retrieves price from oracle for an asset and checks it is nonzero
     * @param asset Address for asset to query price
     * @return Underlying price
     */
    function _safeGetUnderlyingPrice(VToken asset) internal view returns (uint256) {
        uint256 oraclePriceMantissa = oracle.getUnderlyingPrice(address(asset));
        if (oraclePriceMantissa == 0) {
            revert PriceError(address(asset));
        }
        return oraclePriceMantissa;
    }

    /**
     * @dev Return collateral factor for a market
     * @param asset Address for asset
     * @return Collateral factor as exponential
     */
    function _getCollateralFactor(VToken asset) internal view returns (Exp memory) {
        return Exp({ mantissa: markets[address(asset)].collateralFactorMantissa });
    }

    /**
     * @dev Retrieves liquidation threshold for a market as an exponential
     * @param asset Address for asset to liquidation threshold
     * @return Liquidation threshold as exponential
     */
    function _getLiquidationThreshold(VToken asset) internal view returns (Exp memory) {
        return Exp({ mantissa: markets[address(asset)].liquidationThresholdMantissa });
    }

    /**
     * @dev Returns supply and borrow balances of user in vToken, reverts on failure
     * @param vToken Market to query
     * @param user Account address
     * @return vTokenBalance Balance of vTokens, the same as vToken.balanceOf(user)
     * @return borrowBalance Borrowed amount, including the interest
     * @return exchangeRateMantissa Stored exchange rate
     */
    function _safeGetAccountSnapshot(
        VToken vToken,
        address user
    ) internal view returns (uint256 vTokenBalance, uint256 borrowBalance, uint256 exchangeRateMantissa) {
        uint256 err;
        (err, vTokenBalance, borrowBalance, exchangeRateMantissa) = vToken.getAccountSnapshot(user);
        if (err != 0) {
            revert SnapshotError(address(vToken), user);
        }
        return (vTokenBalance, borrowBalance, exchangeRateMantissa);
    }

    /// @notice Reverts if the call is not from expectedSender
    /// @param expectedSender Expected transaction sender
    function _checkSenderIs(address expectedSender) internal view {
        if (msg.sender != expectedSender) {
            revert UnexpectedSender(expectedSender, msg.sender);
        }
    }

    /// @notice Reverts if a certain action is paused on a market
    /// @param market Market to check
    /// @param action Action to check
    function _checkActionPauseState(address market, Action action) private view {
        if (actionPaused(market, action)) {
            revert ActionPaused(market, action);
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { ResilientOracleInterface } from "@venusprotocol/oracle/contracts/interfaces/OracleInterface.sol";

import { VToken } from "./VToken.sol";
import { RewardsDistributor } from "./Rewards/RewardsDistributor.sol";

/**
 * @title ComptrollerInterface
 * @author Venus
 * @notice Interface implemented by the `Comptroller` contract.
 */
interface ComptrollerInterface {
    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata vTokens) external returns (uint256[] memory);

    function exitMarket(address vToken) external returns (uint256);

    /*** Policy Hooks ***/

    function preMintHook(
        address vToken,
        address minter,
        uint256 mintAmount
    ) external;

    function preRedeemHook(
        address vToken,
        address redeemer,
        uint256 redeemTokens
    ) external;

    function preBorrowHook(
        address vToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function preRepayHook(address vToken, address borrower) external;

    function preLiquidateHook(
        address vTokenBorrowed,
        address vTokenCollateral,
        address borrower,
        uint256 repayAmount,
        bool skipLiquidityCheck
    ) external;

    function preSeizeHook(
        address vTokenCollateral,
        address vTokenBorrowed,
        address liquidator,
        address borrower
    ) external;

    function preTransferHook(
        address vToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    function isComptroller() external view returns (bool);

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address vTokenBorrowed,
        address vTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAllMarkets() external view returns (VToken[] memory);
}

/**
 * @title ComptrollerViewInterface
 * @author Venus
 * @notice Interface implemented by the `Comptroller` contract, including only some util view functions.
 */
interface ComptrollerViewInterface {
    function markets(address) external view returns (bool, uint256);

    function oracle() external view returns (ResilientOracleInterface);

    function getAssetsIn(address) external view returns (VToken[] memory);

    function closeFactorMantissa() external view returns (uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function minLiquidatableCollateral() external view returns (uint256);

    function getRewardDistributors() external view returns (RewardsDistributor[] memory);

    function getAllMarkets() external view returns (VToken[] memory);

    function borrowCaps(address) external view returns (uint256);

    function supplyCaps(address) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { ResilientOracleInterface } from "@venusprotocol/oracle/contracts/interfaces/OracleInterface.sol";

import { VToken } from "./VToken.sol";
import { RewardsDistributor } from "./Rewards/RewardsDistributor.sol";

/**
 * @title ComptrollerStorage
 * @author Venus
 * @notice Storage layout for the `Comptroller` contract.
 */
contract ComptrollerStorage {
    struct LiquidationOrder {
        VToken vTokenCollateral;
        VToken vTokenBorrowed;
        uint256 repayAmount;
    }

    struct AccountLiquiditySnapshot {
        uint256 totalCollateral;
        uint256 weightedCollateral;
        uint256 borrows;
        uint256 effects;
        uint256 liquidity;
        uint256 shortfall;
    }

    struct RewardSpeeds {
        address rewardToken;
        uint256 supplySpeed;
        uint256 borrowSpeed;
    }

    struct Market {
        // Whether or not this market is listed
        bool isListed;
        //  Multiplier representing the most one can borrow against their collateral in this market.
        //  For instance, 0.9 to allow borrowing 90% of collateral value.
        //  Must be between 0 and 1, and stored as a mantissa.
        uint256 collateralFactorMantissa;
        //  Multiplier representing the collateralization after which the borrow is eligible
        //  for liquidation. For instance, 0.8 liquidate when the borrow is 80% of collateral
        //  value. Must be between 0 and collateral factor, stored as a mantissa.
        uint256 liquidationThresholdMantissa;
        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
    }

    enum Action {
        MINT,
        REDEEM,
        BORROW,
        REPAY,
        SEIZE,
        LIQUIDATE,
        TRANSFER,
        ENTER_MARKET,
        EXIT_MARKET
    }

    /**
     * @notice Oracle which gives the price of any given asset
     */
    ResilientOracleInterface public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint256 public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint256 public liquidationIncentiveMantissa;

    /**
     * @notice Per-account mapping of "assets you are in"
     */
    mapping(address => VToken[]) public accountAssets;

    /**
     * @notice Official mapping of vTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;

    /// @notice A list of all markets
    VToken[] public allMarkets;

    /// @notice Borrow caps enforced by borrowAllowed for each vToken address. Defaults to zero which restricts borrowing.
    mapping(address => uint256) public borrowCaps;

    /// @notice Minimal collateral required for regular (non-batch) liquidations
    uint256 public minLiquidatableCollateral;

    /// @notice Supply caps enforced by mintAllowed for each vToken address. Defaults to zero which corresponds to minting not allowed
    mapping(address => uint256) public supplyCaps;

    /// @notice True if a certain action is paused on a certain market
    mapping(address => mapping(Action => bool)) internal _actionPaused;

    // List of Reward Distributors added
    RewardsDistributor[] internal rewardsDistributors;

    // Used to check if rewards distributor is added
    mapping(address => bool) internal rewardsDistributorExists;

    uint256 internal constant NO_ERROR = 0;

    // closeFactorMantissa must be strictly greater than this value
    uint256 internal constant MIN_CLOSE_FACTOR_MANTISSA = 0.05e18; // 0.05

    // closeFactorMantissa must not exceed this value
    uint256 internal constant MAX_CLOSE_FACTOR_MANTISSA = 0.9e18; // 0.9

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant MAX_COLLATERAL_FACTOR_MANTISSA = 0.9e18; // 0.9

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/**
 * @title TokenErrorReporter
 * @author Venus
 * @notice Errors that can be thrown by the `VToken` contract.
 */
contract TokenErrorReporter {
    uint256 public constant NO_ERROR = 0; // support legacy return codes

    error TransferNotAllowed();

    error MintFreshnessCheck();

    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();

    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowFreshnessCheck();

    error HealBorrowUnauthorized();
    error ForceLiquidateBorrowUnauthorized();

    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();

    error LiquidateSeizeLiquidatorIsBorrower();

    error ProtocolSeizeShareTooBig();

    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { EXP_SCALE as EXP_SCALE_, MANTISSA_ONE as MANTISSA_ONE_ } from "./lib/constants.sol";

/**
 * @title Exponential module for storing fixed-precision decimals
 * @author Compound
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    struct Exp {
        uint256 mantissa;
    }

    struct Double {
        uint256 mantissa;
    }

    uint256 internal constant EXP_SCALE = EXP_SCALE_;
    uint256 internal constant DOUBLE_SCALE = 1e36;
    uint256 internal constant HALF_EXP_SCALE = EXP_SCALE / 2;
    uint256 internal constant MANTISSA_ONE = MANTISSA_ONE_;

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * EXP_SCALE}) = 15
     */
    function truncate(Exp memory exp) internal pure returns (uint256) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / EXP_SCALE;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    // solhint-disable-next-line func-name-mixedcase
    function mul_ScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    // solhint-disable-next-line func-name-mixedcase
    function mul_ScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }

    function safe224(uint256 n, string memory errorMessage) internal pure returns (uint224) {
        require(n <= type(uint224).max, errorMessage);
        return uint224(n);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n <= type(uint32).max, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: add_(a.mantissa, b.mantissa) });
    }

    function add_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: add_(a.mantissa, b.mantissa) });
    }

    function add_(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: sub_(a.mantissa, b.mantissa) });
    }

    function sub_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: sub_(a.mantissa, b.mantissa) });
    }

    function sub_(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: mul_(a.mantissa, b.mantissa) / EXP_SCALE });
    }

    function mul_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({ mantissa: mul_(a.mantissa, b) });
    }

    function mul_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / EXP_SCALE;
    }

    function mul_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: mul_(a.mantissa, b.mantissa) / DOUBLE_SCALE });
    }

    function mul_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({ mantissa: mul_(a.mantissa, b) });
    }

    function mul_(uint256 a, Double memory b) internal pure returns (uint256) {
        return mul_(a, b.mantissa) / DOUBLE_SCALE;
    }

    function mul_(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div_(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: div_(mul_(a.mantissa, EXP_SCALE), b.mantissa) });
    }

    function div_(Exp memory a, uint256 b) internal pure returns (Exp memory) {
        return Exp({ mantissa: div_(a.mantissa, b) });
    }

    function div_(uint256 a, Exp memory b) internal pure returns (uint256) {
        return div_(mul_(a, EXP_SCALE), b.mantissa);
    }

    function div_(Double memory a, Double memory b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(mul_(a.mantissa, DOUBLE_SCALE), b.mantissa) });
    }

    function div_(Double memory a, uint256 b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(a.mantissa, b) });
    }

    function div_(uint256 a, Double memory b) internal pure returns (uint256) {
        return div_(mul_(a, DOUBLE_SCALE), b.mantissa);
    }

    function div_(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function fraction(uint256 a, uint256 b) internal pure returns (Double memory) {
        return Double({ mantissa: div_(mul_(a, DOUBLE_SCALE), b) });
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
abstract contract InterestRateModel {
    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param badDebt The amount of badDebt in the market
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 badDebt
    ) external view virtual returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @param badDebt The amount of badDebt in the market
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa,
        uint256 badDebt
    ) external view virtual returns (uint256);

    /**
     * @notice Indicator that this is an InterestRateModel contract (for inspection)
     * @return Always true
     */
    function isInterestRateModel() external pure virtual returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/// @dev The approximate number of blocks per year that is assumed by the interest rate model
uint256 constant BLOCKS_PER_YEAR = 10_512_000;

/// @dev Base unit for computations, usually used in scaling (multiplications, divisions)
uint256 constant EXP_SCALE = 1e18;

/// @dev A unit (literal one) in EXP_SCALE, usually used in additions/subtractions
uint256 constant MANTISSA_ONE = EXP_SCALE;

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/// @notice Thrown if the supplied address is a zero address where it is not allowed
error ZeroAddressNotAllowed();

/// @notice Checks if the provided address is nonzero, reverts otherwise
/// @param address_ Address to check
/// @custom:error ZeroAddressNotAllowed is thrown if the provided address is a zero address
function ensureNonzeroAddress(address address_) pure {
    if (address_ == address(0)) {
        revert ZeroAddressNotAllowed();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

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
pragma solidity 0.8.13;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { AccessControlledV8 } from "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";

import { PoolRegistryInterface } from "./PoolRegistryInterface.sol";
import { Comptroller } from "../Comptroller.sol";
import { VToken } from "../VToken.sol";
import { ensureNonzeroAddress } from "../lib/validators.sol";
import "hardhat/console.sol";

/**
 * @title PoolRegistry
 * @author Venus
 * @notice The Isolated Pools architecture centers around the `PoolRegistry` contract. The `PoolRegistry` maintains a directory of isolated lending
 * pools and can perform actions like creating and registering new pools, adding new markets to existing pools, setting and updating the pool's required
 * metadata, and providing the getter methods to get information on the pools.
 *
 * Isolated lending has three main components: PoolRegistry, pools, and markets. The PoolRegistry is responsible for managing pools.
 * It can create new pools, update pool metadata and manage markets within pools. PoolRegistry contains getter methods to get the details of
 * any existing pool like `getVTokenForAsset` and `getPoolsSupportedByAsset`. It also contains methods for updating pool metadata (`updatePoolMetadata`)
 * and setting pool name (`setPoolName`).
 *
 * The directory of pools is managed through two mappings: `_poolByComptroller` which is a hashmap with the comptroller address as the key and `VenusPool` as
 * the value and `_poolsByID` which is an array of comptroller addresses. Individual pools can be accessed by calling `getPoolByComptroller` with the pool's
 * comptroller address. `_poolsByID` is used to iterate through all of the pools.
 *
 * PoolRegistry also contains a map of asset addresses called `_supportedPools` that maps to an array of assets suppored by each pool. This array of pools by
 * asset is retrieved by calling `getPoolsSupportedByAsset`.
 *
 * PoolRegistry registers new isolated pools in the directory with the `createRegistryPool` method. Isolated pools are composed of independent markets with
 * specific assets and custom risk management configurations according to their markets.
 */
contract PoolRegistry is Ownable2StepUpgradeable, AccessControlledV8, PoolRegistryInterface {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct AddMarketInput {
        VToken vToken;
        uint256 collateralFactor;
        uint256 liquidationThreshold;
        uint256 initialSupply;
        address vTokenReceiver;
        uint256 supplyCap;
        uint256 borrowCap;
    }

    uint256 internal constant MAX_POOL_NAME_LENGTH = 100;

    /**
     * @notice Maps pool's comptroller address to metadata.
     */
    mapping(address => VenusPoolMetaData) public metadata;

    /**
     * @dev Maps pool ID to pool's comptroller address
     */
    mapping(uint256 => address) private _poolsByID;

    /**
     * @dev Total number of pools created.
     */
    uint256 private _numberOfPools;

    /**
     * @dev Maps comptroller address to Venus pool Index.
     */
    mapping(address => VenusPool) private _poolByComptroller;

    /**
     * @dev Maps pool's comptroller address to asset to vToken.
     */
    mapping(address => mapping(address => address)) private _vTokens;

    /**
     * @dev Maps asset to list of supported pools.
     */
    mapping(address => address[]) private _supportedPools;

    /**
     * @notice Emitted when a new Venus pool is added to the directory.
     */
    event PoolRegistered(address indexed comptroller, VenusPool pool);

    /**
     * @notice Emitted when a pool name is set.
     */
    event PoolNameSet(address indexed comptroller, string oldName, string newName);

    /**
     * @notice Emitted when a pool metadata is updated.
     */
    event PoolMetadataUpdated(
        address indexed comptroller,
        VenusPoolMetaData oldMetadata,
        VenusPoolMetaData newMetadata
    );

    /**
     * @notice Emitted when a Market is added to the pool.
     */
    event MarketAdded(address indexed comptroller, address indexed vTokenAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // Note that the contract is upgradeable. Use initialize() or reinitializers
        // to set the state variables.
        _disableInitializers();
    }

    /**
     * @notice Initializes the deployer to owner
     * @param accessControlManager_ AccessControlManager contract address
     */
    function initialize(address accessControlManager_) external initializer {
        __Ownable2Step_init();
        __AccessControlled_init_unchained(accessControlManager_);
    }

    /**
     * @notice Adds a new Venus pool to the directory
     * @dev Price oracle must be configured before adding a pool
     * @param name The name of the pool
     * @param comptroller Pool's Comptroller contract
     * @param closeFactor The pool's close factor (scaled by 1e18)
     * @param liquidationIncentive The pool's liquidation incentive (scaled by 1e18)
     * @param minLiquidatableCollateral Minimal collateral for regular (non-batch) liquidations flow
     * @return index The index of the registered Venus pool
     * @custom:error ZeroAddressNotAllowed is thrown when Comptroller address is zero
     * @custom:error ZeroAddressNotAllowed is thrown when price oracle address is zero
     */
    function addPool(
        string calldata name,
        Comptroller comptroller,
        uint256 closeFactor,
        uint256 liquidationIncentive,
        uint256 minLiquidatableCollateral
    ) external virtual returns (uint256 index) {
        _checkAccessAllowed("addPool(string,address,uint256,uint256,uint256)");
        // Input validation
        ensureNonzeroAddress(address(comptroller));
        ensureNonzeroAddress(address(comptroller.oracle()));

        uint256 poolId = _registerPool(name, address(comptroller));

        // Set Venus pool parameters
        comptroller.setCloseFactor(closeFactor);
        comptroller.setLiquidationIncentive(liquidationIncentive);
        comptroller.setMinLiquidatableCollateral(minLiquidatableCollateral);

        return poolId;
    }

    /**
     * @notice Add a market to an existing pool and then mint to provide initial supply
     * @param input The structure describing the parameters for adding a market to a pool
     * @custom:error ZeroAddressNotAllowed is thrown when vToken address is zero
     * @custom:error ZeroAddressNotAllowed is thrown when vTokenReceiver address is zero
     */
    function addMarket(AddMarketInput memory input) external {
        _checkAccessAllowed("addMarket(AddMarketInput)");
        ensureNonzeroAddress(address(input.vToken));
        ensureNonzeroAddress(input.vTokenReceiver);
        require(input.initialSupply > 0, "PoolRegistry: initialSupply is zero");

        VToken vToken = input.vToken;
        address vTokenAddress = address(vToken);
        address comptrollerAddress = address(vToken.comptroller());
        Comptroller comptroller = Comptroller(comptrollerAddress);
        address underlyingAddress = vToken.underlying();
        IERC20Upgradeable underlying = IERC20Upgradeable(underlyingAddress);

        require(_poolByComptroller[comptrollerAddress].creator != address(0), "PoolRegistry: Pool not registered");
        // solhint-disable-next-line reason-string
        require(
            _vTokens[comptrollerAddress][underlyingAddress] == address(0),
            "PoolRegistry: Market already added for asset comptroller combination"
        );

        comptroller.supportMarket(vToken);
        comptroller.setCollateralFactor(vToken, input.collateralFactor, input.liquidationThreshold);

        uint256[] memory newSupplyCaps = new uint256[](1);
        uint256[] memory newBorrowCaps = new uint256[](1);
        VToken[] memory vTokens = new VToken[](1);

        newSupplyCaps[0] = input.supplyCap;
        newBorrowCaps[0] = input.borrowCap;
        vTokens[0] = vToken;

        comptroller.setMarketSupplyCaps(vTokens, newSupplyCaps);
        comptroller.setMarketBorrowCaps(vTokens, newBorrowCaps);

        _vTokens[comptrollerAddress][underlyingAddress] = vTokenAddress;
        _supportedPools[underlyingAddress].push(comptrollerAddress);

        uint256 amountToSupply = _transferIn(underlying, msg.sender, input.initialSupply);
        underlying.approve(vTokenAddress, 0);
        underlying.approve(vTokenAddress, amountToSupply);
        vToken.mintBehalf(input.vTokenReceiver, amountToSupply);

        emit MarketAdded(comptrollerAddress, vTokenAddress);
    }

    /**
     * @notice Modify existing Venus pool name
     * @param comptroller Pool's Comptroller
     * @param name New pool name
     */
    function setPoolName(address comptroller, string calldata name) external {
        _checkAccessAllowed("setPoolName(address,string)");
        _ensureValidName(name);
        VenusPool storage pool = _poolByComptroller[comptroller];
        string memory oldName = pool.name;
        pool.name = name;
        emit PoolNameSet(comptroller, oldName, name);
    }

    /**
     * @notice Update metadata of an existing pool
     * @param comptroller Pool's Comptroller
     * @param metadata_ New pool metadata
     */
    function updatePoolMetadata(address comptroller, VenusPoolMetaData calldata metadata_) external {
        _checkAccessAllowed("updatePoolMetadata(address,VenusPoolMetaData)");
        VenusPoolMetaData memory oldMetadata = metadata[comptroller];
        metadata[comptroller] = metadata_;
        emit PoolMetadataUpdated(comptroller, oldMetadata, metadata_);
    }

    /**
     * @notice Returns arrays of all Venus pools' data
     * @dev This function is not designed to be called in a transaction: it is too gas-intensive
     * @return A list of all pools within PoolRegistry, with details for each pool
     */
    function getAllPools() external view override returns (VenusPool[] memory) {
        console.log("1");
        uint256 numberOfPools_ = _numberOfPools; // storage load to save gas
        VenusPool[] memory _pools = new VenusPool[](numberOfPools_);
        for (uint256 i = 1; i <= numberOfPools_; ++i) {
            address comptroller = _poolsByID[i];
            _pools[i - 1] = (_poolByComptroller[comptroller]);
        }
        return _pools;
    }

    /**
     * @param comptroller The comptroller proxy address associated to the pool
     * @return  Returns Venus pool
     */
    function getPoolByComptroller(address comptroller) external view override returns (VenusPool memory) {
        return _poolByComptroller[comptroller];
    }

    /**
     * @param comptroller comptroller of Venus pool
     * @return Returns Metadata of Venus pool
     */
    function getVenusPoolMetadata(address comptroller) external view override returns (VenusPoolMetaData memory) {
        return metadata[comptroller];
    }

    function getVTokenForAsset(address comptroller, address asset) external view override returns (address) {
        return _vTokens[comptroller][asset];
    }

    function getPoolsSupportedByAsset(address asset) external view override returns (address[] memory) {
        return _supportedPools[asset];
    }

    /**
     * @dev Adds a new Venus pool to the directory (without checking msg.sender).
     * @param name The name of the pool
     * @param comptroller The pool's Comptroller proxy contract address
     * @return The index of the registered Venus pool
     */
    function _registerPool(string calldata name, address comptroller) internal returns (uint256) {
        VenusPool storage storedPool = _poolByComptroller[comptroller];

        require(storedPool.creator == address(0), "PoolRegistry: Pool already exists in the directory.");
        _ensureValidName(name);

        ++_numberOfPools;
        uint256 numberOfPools_ = _numberOfPools; // cache on stack to save storage read gas

        VenusPool memory pool = VenusPool(name, msg.sender, comptroller, block.number, block.timestamp);

        _poolsByID[numberOfPools_] = comptroller;
        _poolByComptroller[comptroller] = pool;

        emit PoolRegistered(comptroller, pool);
        return numberOfPools_;
    }

    function _transferIn(
        IERC20Upgradeable token,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }

    function _ensureValidName(string calldata name) internal pure {
        require(bytes(name).length <= MAX_POOL_NAME_LENGTH, "Pool's name is too large");
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

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

    /**
     * @notice Struct for a Venus interest rate pool metadata.
     */
    struct VenusPoolMetaData {
        string category;
        string logoURL;
        string description;
    }

    /// @notice Get all pools in PoolRegistry
    function getAllPools() external view returns (VenusPool[] memory);

    /// @notice Get a pool by comptroller address
    function getPoolByComptroller(address comptroller) external view returns (VenusPool memory);

    /// @notice Get the address of the VToken contract in the Pool where the underlying token is the provided asset
    function getVTokenForAsset(address comptroller, address asset) external view returns (address);

    /// @notice Get the addresss of the Pools supported that include a market for the provided asset
    function getPoolsSupportedByAsset(address asset) external view returns (address[] memory);

    /// @notice Get the metadata of a Pool by comptroller address
    function getVenusPoolMetadata(address comptroller) external view returns (VenusPoolMetaData memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AccessControlledV8 } from "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";

import { ExponentialNoError } from "../ExponentialNoError.sol";
import { VToken } from "../VToken.sol";
import { Comptroller } from "../Comptroller.sol";
import { MaxLoopsLimitHelper } from "../MaxLoopsLimitHelper.sol";

/**
 * @title `RewardsDistributor`
 * @author Venus
 * @notice Contract used to configure, track and distribute rewards to users based on their actions (borrows and supplies) in the protocol.
 * Users can receive additional rewards through a `RewardsDistributor`. Each `RewardsDistributor` proxy is initialized with a specific reward
 * token and `Comptroller`, which can then distribute the reward token to users that supply or borrow in the associated pool.
 * Authorized users can set the reward token borrow and supply speeds for each market in the pool. This sets a fixed amount of reward
 * token to be released each block for borrowers and suppliers, which is distributed based on a user’s percentage of the borrows or supplies
 * respectively. The owner can also set up reward distributions to contributor addresses (distinct from suppliers and borrowers) by setting
 * their contributor reward token speed, which similarly allocates a fixed amount of reward token per block.
 *
 * The owner has the ability to transfer any amount of reward tokens held by the contract to any other address. Rewards are not distributed
 * automatically and must be claimed by a user calling `claimRewardToken()`. Users should be aware that it is up to the owner and other centralized
 * entities to ensure that the `RewardsDistributor` holds enough tokens to distribute the accumulated rewards of users and contributors.
 */
contract RewardsDistributor is ExponentialNoError, Ownable2StepUpgradeable, AccessControlledV8, MaxLoopsLimitHelper {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct RewardToken {
        // The market's last updated rewardTokenBorrowIndex or rewardTokenSupplyIndex
        uint224 index;
        // The block number the index was last updated at
        uint32 block;
    }

    /// @notice The initial REWARD TOKEN index for a market
    uint224 public constant INITIAL_INDEX = 1e36;


    /// @notice The REWARD TOKEN market supply state for each market
    mapping(address => RewardToken) public rewardTokenSupplyState;

    /// @notice The REWARD TOKEN borrow index for each market for each supplier as of the last time they accrued REWARD TOKEN
    mapping(address => mapping(address => uint256)) public rewardTokenSupplierIndex;

    /// @notice The REWARD TOKEN accrued but not yet transferred to each user
    mapping(address => uint256) public rewardTokenAccrued;

    /// @notice The rate at which rewardToken is distributed to the corresponding borrow market (per block)
    mapping(address => uint256) public rewardTokenBorrowSpeeds;

    /// @notice The rate at which rewardToken is distributed to the corresponding supply market (per block)
    mapping(address => uint256) public rewardTokenSupplySpeeds;

    /// @notice The REWARD TOKEN market borrow state for each market
    mapping(address => RewardToken) public rewardTokenBorrowState;

    /// @notice The portion of REWARD TOKEN that each contributor receives per block
    mapping(address => uint256) public rewardTokenContributorSpeeds;

    /// @notice Last block at which a contributor's REWARD TOKEN rewards have been allocated
    mapping(address => uint256) public lastContributorBlock;

    /// @notice The REWARD TOKEN borrow index for each market for each borrower as of the last time they accrued REWARD TOKEN
    mapping(address => mapping(address => uint256)) public rewardTokenBorrowerIndex;

    Comptroller private comptroller;

    IERC20Upgradeable public rewardToken;

    /// @notice Emitted when REWARD TOKEN is distributed to a supplier
    event DistributedSupplierRewardToken(
        VToken indexed vToken,
        address indexed supplier,
        uint256 rewardTokenDelta,
        uint256 rewardTokenTotal,
        uint256 rewardTokenSupplyIndex
    );

    /// @notice Emitted when REWARD TOKEN is distributed to a borrower
    event DistributedBorrowerRewardToken(
        VToken indexed vToken,
        address indexed borrower,
        uint256 rewardTokenDelta,
        uint256 rewardTokenTotal,
        uint256 rewardTokenBorrowIndex
    );

    /// @notice Emitted when a new supply-side REWARD TOKEN speed is calculated for a market
    event RewardTokenSupplySpeedUpdated(VToken indexed vToken, uint256 newSpeed);

    /// @notice Emitted when a new borrow-side REWARD TOKEN speed is calculated for a market
    event RewardTokenBorrowSpeedUpdated(VToken indexed vToken, uint256 newSpeed);

    /// @notice Emitted when REWARD TOKEN is granted by admin
    event RewardTokenGranted(address indexed recipient, uint256 amount);

    /// @notice Emitted when a new REWARD TOKEN speed is set for a contributor
    event ContributorRewardTokenSpeedUpdated(address indexed contributor, uint256 newSpeed);

    /// @notice Emitted when a market is initialized
    event MarketInitialized(address indexed vToken);

    /// @notice Emitted when a reward token supply index is updated
    event RewardTokenSupplyIndexUpdated(address indexed vToken);

    /// @notice Emitted when a reward token borrow index is updated
    event RewardTokenBorrowIndexUpdated(address indexed vToken, Exp marketBorrowIndex);

    /// @notice Emitted when a reward for contributor is updated
    event ContributorRewardsUpdated(address indexed contributor, uint256 rewardAccrued);

    modifier onlyComptroller() {
        require(address(comptroller) == msg.sender, "Only comptroller can call this function");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice RewardsDistributor initializer
     * @dev Initializes the deployer to owner
     * @param comptroller_ Comptroller to attach the reward distributor to
     * @param rewardToken_ Reward token to distribute
     * @param loopsLimit_ Maximum number of iterations for the loops in this contract
     * @param accessControlManager_ AccessControlManager contract address
     */
    function initialize(
        Comptroller comptroller_,
        IERC20Upgradeable rewardToken_,
        uint256 loopsLimit_,
        address accessControlManager_
    ) external initializer {
        comptroller = comptroller_;
        rewardToken = rewardToken_;
        __Ownable2Step_init();
        __AccessControlled_init_unchained(accessControlManager_);

        _setMaxLoopsLimit(loopsLimit_);
    }

    function initializeMarket(address vToken) external onlyComptroller {
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");

        RewardToken storage supplyState = rewardTokenSupplyState[vToken];
        RewardToken storage borrowState = rewardTokenBorrowState[vToken];

        /*
         * Update market state indices
         */
        if (supplyState.index == 0) {
            // Initialize supply state index with default value
            supplyState.index = INITIAL_INDEX;
        }

        if (borrowState.index == 0) {
            // Initialize borrow state index with default value
            borrowState.index = INITIAL_INDEX;
        }

        /*
         * Update market state block numbers
         */
        supplyState.block = borrowState.block = blockNumber;

        emit MarketInitialized(vToken);
    }

    /*** Reward Token Distribution ***/

    /**
     * @notice Calculate reward token accrued by a borrower and possibly transfer it to them
     *         Borrowers will begin to accrue after the first interaction with the protocol.
     * @dev This function should only be called when the user has a borrow position in the market
     *      (e.g. Comptroller.preBorrowHook, and Comptroller.preRepayHook)
     *      We avoid an external call to check if they are in the market to save gas because this function is called in many places
     * @param vToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute REWARD TOKEN to
     * @param marketBorrowIndex The current global borrow index of vToken
     */
    function distributeBorrowerRewardToken(
        address vToken,
        address borrower,
        Exp memory marketBorrowIndex
    ) external onlyComptroller {
        _distributeBorrowerRewardToken(vToken, borrower, marketBorrowIndex);
    }

    function updateRewardTokenSupplyIndex(address vToken) external onlyComptroller {
        _updateRewardTokenSupplyIndex(vToken);
    }

    /**
     * @notice Transfer REWARD TOKEN to the recipient
     * @dev Note: If there is not enough REWARD TOKEN, we do not perform the transfer all
     * @param recipient The address of the recipient to transfer REWARD TOKEN to
     * @param amount The amount of REWARD TOKEN to (possibly) transfer
     */
    function grantRewardToken(address recipient, uint256 amount) external onlyOwner {
        uint256 amountLeft = _grantRewardToken(recipient, amount);
        require(amountLeft == 0, "insufficient rewardToken for grant");
        emit RewardTokenGranted(recipient, amount);
    }

    function updateRewardTokenBorrowIndex(address vToken, Exp memory marketBorrowIndex) external onlyComptroller {
        _updateRewardTokenBorrowIndex(vToken, marketBorrowIndex);
    }

    /**
     * @notice Set REWARD TOKEN borrow and supply speeds for the specified markets
     * @param vTokens The markets whose REWARD TOKEN speed to update
     * @param supplySpeeds New supply-side REWARD TOKEN speed for the corresponding market
     * @param borrowSpeeds New borrow-side REWARD TOKEN speed for the corresponding market
     */
    function setRewardTokenSpeeds(
        VToken[] memory vTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external {
        _checkAccessAllowed("setRewardTokenSpeeds(address[],uint256[],uint256[])");
        uint256 numTokens = vTokens.length;
        require(
            numTokens == supplySpeeds.length && numTokens == borrowSpeeds.length,
            "RewardsDistributor::setRewardTokenSpeeds invalid input"
        );

        for (uint256 i; i < numTokens; ++i) {
            _setRewardTokenSpeed(vTokens[i], supplySpeeds[i], borrowSpeeds[i]);
        }
    }

    /**
     * @notice Set REWARD TOKEN speed for a single contributor
     * @param contributor The contributor whose REWARD TOKEN speed to update
     * @param rewardTokenSpeed New REWARD TOKEN speed for contributor
     */
    function setContributorRewardTokenSpeed(address contributor, uint256 rewardTokenSpeed) external onlyOwner {
        // note that REWARD TOKEN speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (rewardTokenSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        rewardTokenContributorSpeeds[contributor] = rewardTokenSpeed;

        emit ContributorRewardTokenSpeedUpdated(contributor, rewardTokenSpeed);
    }

    function distributeSupplierRewardToken(address vToken, address supplier) external onlyComptroller {
        _distributeSupplierRewardToken(vToken, supplier);
    }

    /**
     * @notice Claim all the rewardToken accrued by holder in all markets
     * @param holder The address to claim REWARD TOKEN for
     */
    function claimRewardToken(address holder) external {
        return claimRewardToken(holder, comptroller.getAllMarkets());
    }

    /**
     * @notice Set the limit for the loops can iterate to avoid the DOS
     * @param limit Limit for the max loops can execute at a time
     */
    function setMaxLoopsLimit(uint256 limit) external onlyOwner {
        _setMaxLoopsLimit(limit);
    }

    /**
     * @notice Calculate additional accrued REWARD TOKEN for a contributor since last accrual
     * @param contributor The address to calculate contributor rewards for
     */
    function updateContributorRewards(address contributor) public {
        uint256 rewardTokenSpeed = rewardTokenContributorSpeeds[contributor];
        uint256 blockNumber = getBlockNumber();
        uint256 deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && rewardTokenSpeed > 0) {
            uint256 newAccrued = mul_(deltaBlocks, rewardTokenSpeed);
            uint256 contributorAccrued = add_(rewardTokenAccrued[contributor], newAccrued);

            rewardTokenAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;

            emit ContributorRewardsUpdated(contributor, rewardTokenAccrued[contributor]);
        }
    }

    /**
     * @notice Claim all the rewardToken accrued by holder in the specified markets
     * @param holder The address to claim REWARD TOKEN for
     * @param vTokens The list of markets to claim REWARD TOKEN in
     */
    function claimRewardToken(address holder, VToken[] memory vTokens) public {
        uint256 vTokensCount = vTokens.length;

        _ensureMaxLoops(vTokensCount);

        for (uint256 i; i < vTokensCount; ++i) {
            VToken vToken = vTokens[i];
            require(comptroller.isMarketListed(vToken), "market must be listed");
            Exp memory borrowIndex = Exp({ mantissa: vToken.borrowIndex() });
            _updateRewardTokenBorrowIndex(address(vToken), borrowIndex);
            _distributeBorrowerRewardToken(address(vToken), holder, borrowIndex);
            _updateRewardTokenSupplyIndex(address(vToken));
            _distributeSupplierRewardToken(address(vToken), holder);
        }
        rewardTokenAccrued[holder] = _grantRewardToken(holder, rewardTokenAccrued[holder]);
    }

    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Set REWARD TOKEN speed for a single market.
     * @param vToken market's whose reward token rate to be updated
     * @param supplySpeed New supply-side REWARD TOKEN speed for market
     * @param borrowSpeed New borrow-side REWARD TOKEN speed for market
     */
    function _setRewardTokenSpeed(
        VToken vToken,
        uint256 supplySpeed,
        uint256 borrowSpeed
    ) internal {
        require(comptroller.isMarketListed(vToken), "rewardToken market is not listed");

        if (rewardTokenSupplySpeeds[address(vToken)] != supplySpeed) {
            // Supply speed updated so let's update supply state to ensure that
            //  1. REWARD TOKEN accrued properly for the old speed, and
            //  2. REWARD TOKEN accrued at the new speed starts after this block.
            _updateRewardTokenSupplyIndex(address(vToken));

            // Update speed and emit event
            rewardTokenSupplySpeeds[address(vToken)] = supplySpeed;
            emit RewardTokenSupplySpeedUpdated(vToken, supplySpeed);
        }

        if (rewardTokenBorrowSpeeds[address(vToken)] != borrowSpeed) {
            // Borrow speed updated so let's update borrow state to ensure that
            //  1. REWARD TOKEN accrued properly for the old speed, and
            //  2. REWARD TOKEN accrued at the new speed starts after this block.
            Exp memory borrowIndex = Exp({ mantissa: vToken.borrowIndex() });
            _updateRewardTokenBorrowIndex(address(vToken), borrowIndex);

            // Update speed and emit event
            rewardTokenBorrowSpeeds[address(vToken)] = borrowSpeed;
            emit RewardTokenBorrowSpeedUpdated(vToken, borrowSpeed);
        }
    }

    /**
     * @notice Calculate REWARD TOKEN accrued by a supplier and possibly transfer it to them.
     * @param vToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute REWARD TOKEN to
     */
    function _distributeSupplierRewardToken(address vToken, address supplier) internal {
        RewardToken storage supplyState = rewardTokenSupplyState[vToken];
        uint256 supplyIndex = supplyState.index;
        uint256 supplierIndex = rewardTokenSupplierIndex[vToken][supplier];

        // Update supplier's index to the current index since we are distributing accrued REWARD TOKEN
        rewardTokenSupplierIndex[vToken][supplier] = supplyIndex;

        if (supplierIndex == 0 && supplyIndex >= INITIAL_INDEX) {
            // Covers the case where users supplied tokens before the market's supply state index was set.
            // Rewards the user with REWARD TOKEN accrued from the start of when supplier rewards were first
            // set for the market.
            supplierIndex = INITIAL_INDEX;
        }

        // Calculate change in the cumulative sum of the REWARD TOKEN per vToken accrued
        Double memory deltaIndex = Double({ mantissa: sub_(supplyIndex, supplierIndex) });

        uint256 supplierTokens = VToken(vToken).balanceOf(supplier);

        // Calculate REWARD TOKEN accrued: vTokenAmount * accruedPerVToken
        uint256 supplierDelta = mul_(supplierTokens, deltaIndex);

        uint256 supplierAccrued = add_(rewardTokenAccrued[supplier], supplierDelta);
        rewardTokenAccrued[supplier] = supplierAccrued;

        emit DistributedSupplierRewardToken(VToken(vToken), supplier, supplierDelta, supplierAccrued, supplyIndex);
    }

    /**
     * @notice Calculate reward token accrued by a borrower and possibly transfer it to them.
     * @param vToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute REWARD TOKEN to
     * @param marketBorrowIndex The current global borrow index of vToken
     */
    function _distributeBorrowerRewardToken(
        address vToken,
        address borrower,
        Exp memory marketBorrowIndex
    ) internal {
        RewardToken storage borrowState = rewardTokenBorrowState[vToken];
        uint256 borrowIndex = borrowState.index;
        uint256 borrowerIndex = rewardTokenBorrowerIndex[vToken][borrower];

        // Update borrowers's index to the current index since we are distributing accrued REWARD TOKEN
        rewardTokenBorrowerIndex[vToken][borrower] = borrowIndex;

        if (borrowerIndex == 0 && borrowIndex >= INITIAL_INDEX) {
            // Covers the case where users borrowed tokens before the market's borrow state index was set.
            // Rewards the user with REWARD TOKEN accrued from the start of when borrower rewards were first
            // set for the market.
            borrowerIndex = INITIAL_INDEX;
        }

        // Calculate change in the cumulative sum of the REWARD TOKEN per borrowed unit accrued
        Double memory deltaIndex = Double({ mantissa: sub_(borrowIndex, borrowerIndex) });

        uint256 borrowerAmount = div_(VToken(vToken).borrowBalanceStored(borrower), marketBorrowIndex);

        // Calculate REWARD TOKEN accrued: vTokenAmount * accruedPerBorrowedUnit
        if (borrowerAmount != 0) {
            uint256 borrowerDelta = mul_(borrowerAmount, deltaIndex);

            uint256 borrowerAccrued = add_(rewardTokenAccrued[borrower], borrowerDelta);
            rewardTokenAccrued[borrower] = borrowerAccrued;

            emit DistributedBorrowerRewardToken(VToken(vToken), borrower, borrowerDelta, borrowerAccrued, borrowIndex);
        }
    }

    /**
     * @notice Transfer REWARD TOKEN to the user.
     * @dev Note: If there is not enough REWARD TOKEN, we do not perform the transfer all.
     * @param user The address of the user to transfer REWARD TOKEN to
     * @param amount The amount of REWARD TOKEN to (possibly) transfer
     * @return The amount of REWARD TOKEN which was NOT transferred to the user
     */
    function _grantRewardToken(address user, uint256 amount) internal returns (uint256) {
        uint256 rewardTokenRemaining = rewardToken.balanceOf(address(this));
        if (amount > 0 && amount <= rewardTokenRemaining) {
            rewardToken.safeTransfer(user, amount);
            return 0;
        }
        return amount;
    }

    /**
     * @notice Accrue REWARD TOKEN to the market by updating the supply index
     * @param vToken The market whose supply index to update
     * @dev Index is a cumulative sum of the REWARD TOKEN per vToken accrued
     */
    function _updateRewardTokenSupplyIndex(address vToken) internal {
        RewardToken storage supplyState = rewardTokenSupplyState[vToken];
        uint256 supplySpeed = rewardTokenSupplySpeeds[vToken];
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        uint256 deltaBlocks = sub_(uint256(blockNumber), uint256(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            uint256 supplyTokens = VToken(vToken).totalSupply();
            uint256 accruedSinceUpdate = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0
                ? fraction(accruedSinceUpdate, supplyTokens)
                : Double({ mantissa: 0 });
            supplyState.index = safe224(
                add_(Double({ mantissa: supplyState.index }), ratio).mantissa,
                "new index exceeds 224 bits"
            );
            supplyState.block = blockNumber;
        } else if (deltaBlocks > 0) {
            supplyState.block = blockNumber;
        }

        emit RewardTokenSupplyIndexUpdated(vToken);
    }

    /**
     * @notice Accrue REWARD TOKEN to the market by updating the borrow index
     * @param vToken The market whose borrow index to update
     * @param marketBorrowIndex The current global borrow index of vToken
     * @dev Index is a cumulative sum of the REWARD TOKEN per vToken accrued
     */
    function _updateRewardTokenBorrowIndex(address vToken, Exp memory marketBorrowIndex) internal {
        RewardToken storage borrowState = rewardTokenBorrowState[vToken];
        uint256 borrowSpeed = rewardTokenBorrowSpeeds[vToken];
        uint32 blockNumber = safe32(getBlockNumber(), "block number exceeds 32 bits");
        uint256 deltaBlocks = sub_(uint256(blockNumber), uint256(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            uint256 borrowAmount = div_(VToken(vToken).totalBorrows(), marketBorrowIndex);
            uint256 accruedSinceUpdate = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0
                ? fraction(accruedSinceUpdate, borrowAmount)
                : Double({ mantissa: 0 });
            borrowState.index = safe224(
                add_(Double({ mantissa: borrowState.index }), ratio).mantissa,
                "new index exceeds 224 bits"
            );
            borrowState.block = blockNumber;
        } else if (deltaBlocks > 0) {
            borrowState.block = blockNumber;
        }

        emit RewardTokenBorrowIndexUpdated(vToken, marketBorrowIndex);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

/**
 * @title IProtocolShareReserve
 * @author Venus
 * @notice Interface implemented by `ProtocolShareReserve`.
 */
interface IProtocolShareReserve {
    function updateAssetsState(address comptroller, address asset) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { Ownable2StepUpgradeable } from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AccessControlledV8 } from "@venusprotocol/governance-contracts/contracts/Governance/AccessControlledV8.sol";

import { VTokenInterface } from "./VTokenInterfaces.sol";
import { ComptrollerInterface, ComptrollerViewInterface } from "./ComptrollerInterface.sol";
import { TokenErrorReporter } from "./ErrorReporter.sol";
import { InterestRateModel } from "./InterestRateModel.sol";
import { ExponentialNoError } from "./ExponentialNoError.sol";
import { IProtocolShareReserve } from "./RiskFund/IProtocolShareReserve.sol";
import { ensureNonzeroAddress } from "./lib/validators.sol";

/**
 * @title VToken
 * @author Venus
 * @notice Each asset that is supported by a pool is integrated through an instance of the `VToken` contract. As outlined in the protocol overview,
 * each isolated pool creates its own `vToken` corresponding to an asset. Within a given pool, each included `vToken` is referred to as a market of
 * the pool. The main actions a user regularly interacts with in a market are:

- mint/redeem of vTokens;
- transfer of vTokens;
- borrow/repay a loan on an underlying asset;
- liquidate a borrow or liquidate/heal an account.

 * A user supplies the underlying asset to a pool by minting `vTokens`, where the corresponding `vToken` amount is determined by the `exchangeRate`.
 * The `exchangeRate` will change over time, dependent on a number of factors, some of which accrue interest. Additionally, once users have minted
 * `vToken` in a pool, they can borrow any asset in the isolated pool by using their `vToken` as collateral. In order to borrow an asset or use a `vToken`
 * as collateral, the user must be entered into each corresponding market (else, the `vToken` will not be considered collateral for a borrow). Note that
 * a user may borrow up to a portion of their collateral determined by the market’s collateral factor. However, if their borrowed amount exceeds an amount
 * calculated using the market’s corresponding liquidation threshold, the borrow is eligible for liquidation. When a user repays a borrow, they must also
 * pay off interest accrued on the borrow.
 * 
 * The Venus protocol includes unique mechanisms for healing an account and liquidating an account. These actions are performed in the `Comptroller`
 * and consider all borrows and collateral for which a given account is entered within a market. These functions may only be called on an account with a
 * total collateral amount that is no larger than a universal `minLiquidatableCollateral` value, which is used for all markets within a `Comptroller`.
 * Both functions settle all of an account’s borrows, but `healAccount()` may add `badDebt` to a vToken. For more detail, see the description of
 * `healAccount()` and `liquidateAccount()` in the `Comptroller` summary section below.
 */
contract VToken is
    Ownable2StepUpgradeable,
    AccessControlledV8,
    VTokenInterface,
    ExponentialNoError,
    TokenErrorReporter
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 internal constant DEFAULT_PROTOCOL_SEIZE_SHARE_MANTISSA = 5e16; // 5%

    /*** Reentrancy Guard ***/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     */
    modifier nonReentrant() {
        require(_notEntered, "re-entered");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // Note that the contract is upgradeable. Use initialize() or reinitializers
        // to set the state variables.
        _disableInitializers();
    }

    /**
     * @notice Construct a new money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     * @param accessControlManager_ AccessControlManager contract address
     * @param riskManagement Addresses of risk & income related contracts
     * @param reserveFactorMantissa_ Percentage of borrow interest that goes to reserves (from 0 to 1e18)
     * @custom:error ZeroAddressNotAllowed is thrown when admin address is zero
     * @custom:error ZeroAddressNotAllowed is thrown when shortfall contract address is zero
     * @custom:error ZeroAddressNotAllowed is thrown when protocol share reserve address is zero
     */
    function initialize(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address admin_,
        address accessControlManager_,
        RiskManagementInit memory riskManagement,
        uint256 reserveFactorMantissa_
    ) external initializer {
        ensureNonzeroAddress(admin_);

        // Initialize the market
        _initialize(
            underlying_,
            comptroller_,
            interestRateModel_,
            initialExchangeRateMantissa_,
            name_,
            symbol_,
            decimals_,
            admin_,
            accessControlManager_,
            riskManagement,
            reserveFactorMantissa_
        );
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success True if the transfer succeeded, reverts otherwise
     * @custom:event Emits Transfer event on success
     * @custom:error TransferNotAllowed is thrown if trying to transfer to self
     * @custom:access Not restricted
     */
    function transfer(address dst, uint256 amount) external override nonReentrant returns (bool) {
        _transferTokens(msg.sender, msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success True if the transfer succeeded, reverts otherwise
     * @custom:event Emits Transfer event on success
     * @custom:error TransferNotAllowed is thrown if trying to transfer to self
     * @custom:access Not restricted
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        _transferTokens(msg.sender, src, dst, amount);
        return true;
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (uint256.max means infinite)
     * @return success Whether or not the approval succeeded
     * @custom:event Emits Approval event
     * @custom:access Not restricted
     * @custom:error ZeroAddressNotAllowed is thrown when spender address is zero
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        ensureNonzeroAddress(spender);

        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

    /**
     * @notice Increase approval for `spender`
     * @param spender The address of the account which may transfer tokens
     * @param addedValue The number of additional tokens spender can transfer
     * @return success Whether or not the approval succeeded
     * @custom:event Emits Approval event
     * @custom:access Not restricted
     * @custom:error ZeroAddressNotAllowed is thrown when spender address is zero
     */
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        ensureNonzeroAddress(spender);

        address src = msg.sender;
        uint256 newAllowance = transferAllowances[src][spender];
        newAllowance += addedValue;
        transferAllowances[src][spender] = newAllowance;

        emit Approval(src, spender, newAllowance);
        return true;
    }

    /**
     * @notice Decreases approval for `spender`
     * @param spender The address of the account which may transfer tokens
     * @param subtractedValue The number of tokens to remove from total approval
     * @return success Whether or not the approval succeeded
     * @custom:event Emits Approval event
     * @custom:access Not restricted
     * @custom:error ZeroAddressNotAllowed is thrown when spender address is zero
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        ensureNonzeroAddress(spender);

        address src = msg.sender;
        uint256 currentAllowance = transferAllowances[src][spender];
        require(currentAllowance >= subtractedValue, "decreased allowance below zero");
        unchecked {
            currentAllowance -= subtractedValue;
        }

        transferAllowances[src][spender] = currentAllowance;

        emit Approval(src, spender, currentAllowance);
        return true;
    }

    /**
     * @notice Get the underlying balance of the `owner`
     * @dev This also accrues interest in a transaction
     * @param owner The address of the account to query
     * @return amount The amount of underlying owned by `owner`
     */
    function balanceOfUnderlying(address owner) external override returns (uint256) {
        Exp memory exchangeRate = Exp({ mantissa: exchangeRateCurrent() });
        return mul_ScalarTruncate(exchangeRate, accountTokens[owner]);
    }

    /**
     * @notice Returns the current total borrows plus accrued interest
     * @return totalBorrows The total borrows with interest
     */
    function totalBorrowsCurrent() external override nonReentrant returns (uint256) {
        accrueInterest();
        return totalBorrows;
    }

    /**
     * @notice Accrue interest to updated borrowIndex and then calculate account's borrow balance using the updated borrowIndex
     * @param account The address whose balance should be calculated after updating borrowIndex
     * @return borrowBalance The calculated balance
     */
    function borrowBalanceCurrent(address account) external override nonReentrant returns (uint256) {
        accrueInterest();
        return _borrowBalanceStored(account);
    }

    /**
     * @notice Sender supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits Mint and Transfer events; may emit AccrueInterest
     * @custom:access Not restricted
     */
    function mint(uint256 mintAmount) external override nonReentrant returns (uint256) {
        accrueInterest();
        // _mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        _mintFresh(msg.sender, msg.sender, mintAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender calls on-behalf of minter. minter supplies assets into the market and receives vTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param minter User whom the supply will be attributed to
     * @param mintAmount The amount of the underlying asset to supply
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits Mint and Transfer events; may emit AccrueInterest
     * @custom:access Not restricted
     * @custom:error ZeroAddressNotAllowed is thrown when minter address is zero
     */
    function mintBehalf(address minter, uint256 mintAmount) external override nonReentrant returns (uint256) {
        ensureNonzeroAddress(minter);

        accrueInterest();
        // _mintFresh emits the actual Mint event if successful and logs on errors, so we don't need to
        _mintFresh(msg.sender, minter, mintAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems vTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of vTokens to redeem into underlying
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits Redeem and Transfer events; may emit AccrueInterest
     * @custom:error RedeemTransferOutNotPossible is thrown when the protocol has insufficient cash
     * @custom:access Not restricted
     */
    function redeem(uint256 redeemTokens) external override nonReentrant returns (uint256) {
        accrueInterest();
        // _redeemFresh emits redeem-specific logs on errors, so we don't need to
        _redeemFresh(msg.sender, redeemTokens, 0);
        return NO_ERROR;
    }

    /**
     * @notice Sender redeems vTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to receive from redeeming vTokens
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     */
    function redeemUnderlying(uint256 redeemAmount) external override nonReentrant returns (uint256) {
        accrueInterest();
        // _redeemFresh emits redeem-specific logs on errors, so we don't need to
        _redeemFresh(msg.sender, 0, redeemAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender borrows assets from the protocol to their own address
     * @param borrowAmount The amount of the underlying asset to borrow
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits Borrow event; may emit AccrueInterest
     * @custom:error BorrowCashNotAvailable is thrown when the protocol has insufficient cash
     * @custom:access Not restricted
     */
    function borrow(uint256 borrowAmount) external override nonReentrant returns (uint256) {
        accrueInterest();
        // borrowFresh emits borrow-specific logs on errors, so we don't need to
        _borrowFresh(msg.sender, borrowAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay, or type(uint256).max for the full outstanding amount
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits RepayBorrow event; may emit AccrueInterest
     * @custom:access Not restricted
     */
    function repayBorrow(uint256 repayAmount) external override nonReentrant returns (uint256) {
        accrueInterest();
        // _repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        _repayBorrowFresh(msg.sender, msg.sender, repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay, or type(uint256).max for the full outstanding amount
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits RepayBorrow event; may emit AccrueInterest
     * @custom:access Not restricted
     */
    function repayBorrowBehalf(address borrower, uint256 repayAmount) external override nonReentrant returns (uint256) {
        accrueInterest();
        // _repayBorrowFresh emits repay-borrow-specific logs on errors, so we don't need to
        _repayBorrowFresh(msg.sender, borrower, repayAmount);
        return NO_ERROR;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this vToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @custom:event Emits LiquidateBorrow event; may emit AccrueInterest
     * @custom:error LiquidateAccrueCollateralInterestFailed is thrown when it is not possible to accrue interest on the collateral vToken
     * @custom:error LiquidateCollateralFreshnessCheck is thrown when interest has not been accrued on the collateral vToken
     * @custom:error LiquidateLiquidatorIsBorrower is thrown when trying to liquidate self
     * @custom:error LiquidateCloseAmountIsZero is thrown when repayment amount is zero
     * @custom:error LiquidateCloseAmountIsUintMax is thrown when repayment amount is UINT_MAX
     * @custom:access Not restricted
     */
    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external override returns (uint256) {
        _liquidateBorrow(msg.sender, borrower, repayAmount, vTokenCollateral, false);
        return NO_ERROR;
    }

    /**
     * @notice sets protocol share accumulated from liquidations
     * @dev must be equal or less than liquidation incentive - 1
     * @param newProtocolSeizeShareMantissa_ new protocol share mantissa
     * @custom:event Emits NewProtocolSeizeShare event on success
     * @custom:error Unauthorized error is thrown when the call is not authorized by AccessControlManager
     * @custom:error ProtocolSeizeShareTooBig is thrown when the new seize share is too high
     * @custom:access Controlled by AccessControlManager
     */
    function setProtocolSeizeShare(uint256 newProtocolSeizeShareMantissa_) external {
        _checkAccessAllowed("setProtocolSeizeShare(uint256)");
        uint256 liquidationIncentive = ComptrollerViewInterface(address(comptroller)).liquidationIncentiveMantissa();
        if (newProtocolSeizeShareMantissa_ + MANTISSA_ONE > liquidationIncentive) {
            revert ProtocolSeizeShareTooBig();
        }

        uint256 oldProtocolSeizeShareMantissa = protocolSeizeShareMantissa;
        protocolSeizeShareMantissa = newProtocolSeizeShareMantissa_;
        emit NewProtocolSeizeShare(oldProtocolSeizeShareMantissa, newProtocolSeizeShareMantissa_);
    }

    /**
     * @notice accrues interest and sets a new reserve factor for the protocol using _setReserveFactorFresh
     * @dev Admin function to accrue interest and set a new reserve factor
     * @param newReserveFactorMantissa New reserve factor (from 0 to 1e18)
     * @custom:event Emits NewReserveFactor event; may emit AccrueInterest
     * @custom:error Unauthorized error is thrown when the call is not authorized by AccessControlManager
     * @custom:error SetReserveFactorBoundsCheck is thrown when the new reserve factor is too high
     * @custom:access Controlled by AccessControlManager
     */
    function setReserveFactor(uint256 newReserveFactorMantissa) external override nonReentrant {
        _checkAccessAllowed("setReserveFactor(uint256)");

        accrueInterest();
        _setReserveFactorFresh(newReserveFactorMantissa);
    }

    /**
     * @notice Accrues interest and reduces reserves by transferring to the protocol reserve contract
     * @param reduceAmount Amount of reduction to reserves
     * @custom:event Emits ReservesReduced event; may emit AccrueInterest
     * @custom:error ReduceReservesCashNotAvailable is thrown when the vToken does not have sufficient cash
     * @custom:error ReduceReservesCashValidation is thrown when trying to withdraw more cash than the reserves have
     * @custom:access Not restricted
     */
    function reduceReserves(uint256 reduceAmount) external override nonReentrant {
        accrueInterest();
        _reduceReservesFresh(reduceAmount);
    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount of underlying token to add as reserves
     * @custom:event Emits ReservesAdded event; may emit AccrueInterest
     * @custom:access Not restricted
     */
    function addReserves(uint256 addAmount) external override nonReentrant {
        accrueInterest();
        _addReservesFresh(addAmount);
    }

    /**
     * @notice accrues interest and updates the interest rate model using _setInterestRateModelFresh
     * @dev Admin function to accrue interest and update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     * @custom:event Emits NewMarketInterestRateModel event; may emit AccrueInterest
     * @custom:error Unauthorized error is thrown when the call is not authorized by AccessControlManager
     * @custom:access Controlled by AccessControlManager
     */
    function setInterestRateModel(InterestRateModel newInterestRateModel) external override {
        _checkAccessAllowed("setInterestRateModel(address)");

        accrueInterest();
        _setInterestRateModelFresh(newInterestRateModel);
    }

    /**
     * @notice Repays a certain amount of debt, treats the rest of the borrow as bad debt, essentially
     *   "forgiving" the borrower. Healing is a situation that should rarely happen. However, some pools
     *   may list risky assets or be configured improperly – we want to still handle such cases gracefully.
     *   We assume that Comptroller does the seizing, so this function is only available to Comptroller.
     * @dev This function does not call any Comptroller hooks (like "healAllowed"), because we assume
     *   the Comptroller does all the necessary checks before calling this function.
     * @param payer account who repays the debt
     * @param borrower account to heal
     * @param repayAmount amount to repay
     * @custom:event Emits RepayBorrow, BadDebtIncreased events; may emit AccrueInterest
     * @custom:error HealBorrowUnauthorized is thrown when the request does not come from Comptroller
     * @custom:access Only Comptroller
     */
    function healBorrow(
        address payer,
        address borrower,
        uint256 repayAmount
    ) external override nonReentrant {
        if (repayAmount != 0) {
            comptroller.preRepayHook(address(this), borrower);
        }

        if (msg.sender != address(comptroller)) {
            revert HealBorrowUnauthorized();
        }

        uint256 accountBorrowsPrev = _borrowBalanceStored(borrower);
        uint256 totalBorrowsNew = totalBorrows;

        uint256 actualRepayAmount;
        if (repayAmount != 0) {
            // _doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
            // We violate checks-effects-interactions here to account for tokens that take transfer fees
            actualRepayAmount = _doTransferIn(payer, repayAmount);
            totalBorrowsNew = totalBorrowsNew - actualRepayAmount;
            emit RepayBorrow(
                payer,
                borrower,
                actualRepayAmount,
                accountBorrowsPrev - actualRepayAmount,
                totalBorrowsNew
            );
        }

        // The transaction will fail if trying to repay too much
        uint256 badDebtDelta = accountBorrowsPrev - actualRepayAmount;
        if (badDebtDelta != 0) {
            uint256 badDebtOld = badDebt;
            uint256 badDebtNew = badDebtOld + badDebtDelta;
            totalBorrowsNew = totalBorrowsNew - badDebtDelta;
            badDebt = badDebtNew;

            // We treat healing as "repayment", where vToken is the payer
            emit RepayBorrow(address(this), borrower, badDebtDelta, 0, totalBorrowsNew);
            emit BadDebtIncreased(borrower, badDebtDelta, badDebtOld, badDebtNew);
        }

        accountBorrows[borrower].principal = 0;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        emit HealBorrow(payer, borrower, repayAmount);
    }

    /**
     * @notice The extended version of liquidations, callable only by Comptroller. May skip
     *  the close factor check. The collateral seized is transferred to the liquidator.
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param borrower The borrower of this vToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param skipLiquidityCheck If set to true, allows to liquidate up to 100% of the borrow
     *   regardless of the account liquidity
     * @custom:event Emits LiquidateBorrow event; may emit AccrueInterest
     * @custom:error ForceLiquidateBorrowUnauthorized is thrown when the request does not come from Comptroller
     * @custom:error LiquidateAccrueCollateralInterestFailed is thrown when it is not possible to accrue interest on the collateral vToken
     * @custom:error LiquidateCollateralFreshnessCheck is thrown when interest has not been accrued on the collateral vToken
     * @custom:error LiquidateLiquidatorIsBorrower is thrown when trying to liquidate self
     * @custom:error LiquidateCloseAmountIsZero is thrown when repayment amount is zero
     * @custom:error LiquidateCloseAmountIsUintMax is thrown when repayment amount is UINT_MAX
     * @custom:access Only Comptroller
     */
    function forceLiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral,
        bool skipLiquidityCheck
    ) external override {
        if (msg.sender != address(comptroller)) {
            revert ForceLiquidateBorrowUnauthorized();
        }
        _liquidateBorrow(liquidator, borrower, repayAmount, vTokenCollateral, skipLiquidityCheck);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Will fail unless called by another vToken during the process of liquidation.
     *  It's absolutely critical to use msg.sender as the borrowed vToken and not a parameter.
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of vTokens to seize
     * @custom:event Emits Transfer, ReservesAdded events
     * @custom:error LiquidateSeizeLiquidatorIsBorrower is thrown when trying to liquidate self
     * @custom:access Not restricted
     */
    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external override nonReentrant {
        _seize(msg.sender, liquidator, borrower, seizeTokens);
    }

    /**
     * @notice Updates bad debt
     * @dev Called only when bad debt is recovered from auction
     * @param recoveredAmount_ The amount of bad debt recovered
     * @custom:event Emits BadDebtRecovered event
     * @custom:access Only Shortfall contract
     */
    function badDebtRecovered(uint256 recoveredAmount_) external {
        require(msg.sender == shortfall, "only shortfall contract can update bad debt");
        require(recoveredAmount_ <= badDebt, "more than bad debt recovered from auction");

        uint256 badDebtOld = badDebt;
        uint256 badDebtNew = badDebtOld - recoveredAmount_;
        badDebt = badDebtNew;

        emit BadDebtRecovered(badDebtOld, badDebtNew);
    }

    /**
     * @notice Sets protocol share reserve contract address
     * @param protocolShareReserve_ The address of the protocol share reserve contract
     * @custom:error ZeroAddressNotAllowed is thrown when protocol share reserve address is zero
     * @custom:access Only Governance
     */
    function setProtocolShareReserve(address payable protocolShareReserve_) external onlyOwner {
        _setProtocolShareReserve(protocolShareReserve_);
    }

    /**
     * @notice Sets shortfall contract address
     * @param shortfall_ The address of the shortfall contract
     * @custom:error ZeroAddressNotAllowed is thrown when shortfall contract address is zero
     * @custom:access Only Governance
     */
    function setShortfallContract(address shortfall_) external onlyOwner {
        _setShortfallContract(shortfall_);
    }

    /**
     * @notice A public function to sweep accidental ERC-20 transfers to this contract. Tokens are sent to admin (timelock)
     * @param token The address of the ERC-20 token to sweep
     * @custom:access Only Governance
     */
    function sweepToken(IERC20Upgradeable token) external override {
        require(msg.sender == owner(), "VToken::sweepToken: only admin can sweep tokens");
        require(address(token) != underlying, "VToken::sweepToken: can not sweep underlying token");
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(owner(), balance);

        emit SweepToken(address(token));
    }

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return amount The number of tokens allowed to be spent (type(uint256).max means infinite)
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return transferAllowances[owner][spender];
    }

    /**
     * @notice Get the token balance of the `owner`
     * @param owner The address of the account to query
     * @return amount The number of tokens owned by `owner`
     */
    function balanceOf(address owner) external view override returns (uint256) {
        return accountTokens[owner];
    }

    /**
     * @notice Get a snapshot of the account's balances, and the cached exchange rate
     * @dev This is used by comptroller to more efficiently perform liquidity checks.
     * @param account Address of the account to snapshot
     * @return error Always NO_ERROR for compatibility with Venus core tooling
     * @return vTokenBalance User's balance of vTokens
     * @return borrowBalance Amount owed in terms of underlying
     * @return exchangeRate Stored exchange rate
     */
    function getAccountSnapshot(address account)
        external
        view
        override
        returns (
            uint256 error,
            uint256 vTokenBalance,
            uint256 borrowBalance,
            uint256 exchangeRate
        )
    {
        return (NO_ERROR, accountTokens[account], _borrowBalanceStored(account), _exchangeRateStored());
    }

    /**
     * @notice Get cash balance of this vToken in the underlying asset
     * @return cash The quantity of underlying asset owned by this contract
     */
    function getCash() external view override returns (uint256) {
        return _getCashPrior();
    }

    /**
     * @notice Returns the current per-block borrow interest rate for this vToken
     * @return rate The borrow interest rate per block, scaled by 1e18
     */
    function borrowRatePerBlock() external view override returns (uint256) {
        return interestRateModel.getBorrowRate(_getCashPrior(), totalBorrows, totalReserves, badDebt);
    }

    /**
     * @notice Returns the current per-block supply interest rate for this v
     * @return rate The supply interest rate per block, scaled by 1e18
     */
    function supplyRatePerBlock() external view override returns (uint256) {
        return
            interestRateModel.getSupplyRate(
                _getCashPrior(),
                totalBorrows,
                totalReserves,
                reserveFactorMantissa,
                badDebt
            );
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return borrowBalance The calculated balance
     */
    function borrowBalanceStored(address account) external view override returns (uint256) {
        return _borrowBalanceStored(account);
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the VToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return exchangeRate Calculated exchange rate scaled by 1e18
     */
    function exchangeRateStored() external view override returns (uint256) {
        return _exchangeRateStored();
    }

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return exchangeRate Calculated exchange rate scaled by 1e18
     */
    function exchangeRateCurrent() public override nonReentrant returns (uint256) {
        accrueInterest();
        return _exchangeRateStored();
    }

    /**
     * @notice Applies accrued interest to total borrows and reserves
     * @dev This calculates interest accrued from the last checkpointed block
     *   up to the current block and writes new checkpoint to storage.
     * @return Always NO_ERROR
     * @custom:event Emits AccrueInterest event on success
     * @custom:access Not restricted
     */
    function accrueInterest() public virtual override returns (uint256) {
        /* Remember the initial block number */
        uint256 currentBlockNumber = _getBlockNumber();
        uint256 accrualBlockNumberPrior = accrualBlockNumber;

        /* Short-circuit accumulating 0 interest */
        if (accrualBlockNumberPrior == currentBlockNumber) {
            return NO_ERROR;
        }

        /* Read the previous values out of storage */
        uint256 cashPrior = _getCashPrior();
        uint256 borrowsPrior = totalBorrows;
        uint256 reservesPrior = totalReserves;
        uint256 borrowIndexPrior = borrowIndex;

        /* Calculate the current borrow interest rate */
        uint256 borrowRateMantissa = interestRateModel.getBorrowRate(cashPrior, borrowsPrior, reservesPrior, badDebt);
        require(borrowRateMantissa <= MAX_BORROW_RATE_MANTISSA, "borrow rate is absurdly high");

        /* Calculate the number of blocks elapsed since the last accrual */
        uint256 blockDelta = currentBlockNumber - accrualBlockNumberPrior;

        /*
         * Calculate the interest accumulated into borrows and reserves and the new index:
         *  simpleInterestFactor = borrowRate * blockDelta
         *  interestAccumulated = simpleInterestFactor * totalBorrows
         *  totalBorrowsNew = interestAccumulated + totalBorrows
         *  totalReservesNew = interestAccumulated * reserveFactor + totalReserves
         *  borrowIndexNew = simpleInterestFactor * borrowIndex + borrowIndex
         */

        Exp memory simpleInterestFactor = mul_(Exp({ mantissa: borrowRateMantissa }), blockDelta);
        uint256 interestAccumulated = mul_ScalarTruncate(simpleInterestFactor, borrowsPrior);
        uint256 totalBorrowsNew = interestAccumulated + borrowsPrior;
        uint256 totalReservesNew = mul_ScalarTruncateAddUInt(
            Exp({ mantissa: reserveFactorMantissa }),
            interestAccumulated,
            reservesPrior
        );
        uint256 borrowIndexNew = mul_ScalarTruncateAddUInt(simpleInterestFactor, borrowIndexPrior, borrowIndexPrior);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the previously calculated values into storage */
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        /* We emit an AccrueInterest event */
        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew);

        return NO_ERROR;
    }

    /**
     * @notice User supplies assets into the market and receives vTokens in exchange
     * @dev Assumes interest has already been accrued up to the current block
     * @param payer The address of the account which is sending the assets for supply
     * @param minter The address of the account which is supplying the assets
     * @param mintAmount The amount of the underlying asset to supply
     */
    function _mintFresh(
        address payer,
        address minter,
        uint256 mintAmount
    ) internal {
        /* Fail if mint not allowed */
        comptroller.preMintHook(address(this), minter, mintAmount);

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != _getBlockNumber()) {
            revert MintFreshnessCheck();
        }

        Exp memory exchangeRate = Exp({ mantissa: _exchangeRateStored() });

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         *  We call `_doTransferIn` for the minter and the mintAmount.
         *  `_doTransferIn` reverts if anything goes wrong, since we can't be sure if
         *  side-effects occurred. The function returns the amount actually transferred,
         *  in case of a fee. On success, the vToken holds an additional `actualMintAmount`
         *  of cash.
         */
        uint256 actualMintAmount = _doTransferIn(payer, mintAmount);

        /*
         * We get the current exchange rate and calculate the number of vTokens to be minted:
         *  mintTokens = actualMintAmount / exchangeRate
         */

        uint256 mintTokens = div_(actualMintAmount, exchangeRate);

        /*
         * We calculate the new total supply of vTokens and minter token balance, checking for overflow:
         *  totalSupplyNew = totalSupply + mintTokens
         *  accountTokensNew = accountTokens[minter] + mintTokens
         * And write them into storage
         */
        totalSupply = totalSupply + mintTokens;
        uint256 balanceAfter = accountTokens[minter] + mintTokens;
        accountTokens[minter] = balanceAfter;

        /* We emit a Mint event, and a Transfer event */
        emit Mint(minter, actualMintAmount, mintTokens, balanceAfter);
        emit Transfer(address(0), minter, mintTokens);
    }

    /**
     * @notice User redeems vTokens in exchange for the underlying asset
     * @dev Assumes interest has already been accrued up to the current block
     * @param redeemer The address of the account which is redeeming the tokens
     * @param redeemTokensIn The number of vTokens to redeem into underlying (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     * @param redeemAmountIn The number of underlying tokens to receive from redeeming vTokens (only one of redeemTokensIn or redeemAmountIn may be non-zero)
     */
    function _redeemFresh(
        address redeemer,
        uint256 redeemTokensIn,
        uint256 redeemAmountIn
    ) internal {
        require(redeemTokensIn == 0 || redeemAmountIn == 0, "one of redeemTokensIn or redeemAmountIn must be zero");

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != _getBlockNumber()) {
            revert RedeemFreshnessCheck();
        }

        /* exchangeRate = invoke Exchange Rate Stored() */
        Exp memory exchangeRate = Exp({ mantissa: _exchangeRateStored() });

        uint256 redeemTokens;
        uint256 redeemAmount;

        /* If redeemTokensIn > 0: */
        if (redeemTokensIn > 0) {
            /*
             * We calculate the exchange rate and the amount of underlying to be redeemed:
             *  redeemTokens = redeemTokensIn
             */
            redeemTokens = redeemTokensIn;
        } else {
            /*
             * We get the current exchange rate and calculate the amount to be redeemed:
             *  redeemTokens = redeemAmountIn / exchangeRate
             */
            redeemTokens = div_(redeemAmountIn, exchangeRate);

            uint256 _redeemAmount = mul_(redeemTokens, exchangeRate);
            if (_redeemAmount != 0 && _redeemAmount != redeemAmountIn) redeemTokens++; // round up
        }

        // redeemAmount = exchangeRate * redeemTokens
        redeemAmount = mul_ScalarTruncate(exchangeRate, redeemTokens);

        // Revert if amount is zero
        if (redeemAmount == 0) {
            revert("redeemAmount is zero");
        }

        /* Fail if redeem not allowed */
        comptroller.preRedeemHook(address(this), redeemer, redeemTokens);

        /* Fail gracefully if protocol has insufficient cash */
        if (_getCashPrior() - totalReserves < redeemAmount) {
            revert RedeemTransferOutNotPossible();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing reduced supply before external transfer.
         */
        totalSupply = totalSupply - redeemTokens;
        uint256 balanceAfter = accountTokens[redeemer] - redeemTokens;
        accountTokens[redeemer] = balanceAfter;

        /*
         * We invoke _doTransferOut for the redeemer and the redeemAmount.
         *  On success, the vToken has redeemAmount less of cash.
         *  _doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        _doTransferOut(redeemer, redeemAmount);

        /* We emit a Transfer event, and a Redeem event */
        emit Transfer(redeemer, address(this), redeemTokens);
        emit Redeem(redeemer, redeemAmount, redeemTokens, balanceAfter);
    }

    /**
     * @notice Users borrow assets from the protocol to their own address
     * @param borrower User who borrows the assets
     * @param borrowAmount The amount of the underlying asset to borrow
     */
    function _borrowFresh(address borrower, uint256 borrowAmount) internal {
        /* Fail if borrow not allowed */
        comptroller.preBorrowHook(address(this), borrower, borrowAmount);

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != _getBlockNumber()) {
            revert BorrowFreshnessCheck();
        }

        /* Fail gracefully if protocol has insufficient underlying cash */
        if (_getCashPrior() - totalReserves < borrowAmount) {
            revert BorrowCashNotAvailable();
        }

        /*
         * We calculate the new borrower and total borrow balances, failing on overflow:
         *  accountBorrowNew = accountBorrow + borrowAmount
         *  totalBorrowsNew = totalBorrows + borrowAmount
         */
        uint256 accountBorrowsPrev = _borrowBalanceStored(borrower);
        uint256 accountBorrowsNew = accountBorrowsPrev + borrowAmount;
        uint256 totalBorrowsNew = totalBorrows + borrowAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We write the previously calculated values into storage.
         *  Note: Avoid token reentrancy attacks by writing increased borrow before external transfer.
        `*/
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /*
         * We invoke _doTransferOut for the borrower and the borrowAmount.
         *  On success, the vToken borrowAmount less of cash.
         *  _doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
         */
        _doTransferOut(borrower, borrowAmount);

        /* We emit a Borrow event */
        emit Borrow(borrower, borrowAmount, accountBorrowsNew, totalBorrowsNew);
    }

    /**
     * @notice Borrows are repaid by another user (possibly the borrower).
     * @param payer the account paying off the borrow
     * @param borrower the account with the debt being payed off
     * @param repayAmount the amount of underlying tokens being returned, or type(uint256).max for the full outstanding amount
     * @return (uint) the actual repayment amount.
     */
    function _repayBorrowFresh(
        address payer,
        address borrower,
        uint256 repayAmount
    ) internal returns (uint256) {
        /* Fail if repayBorrow not allowed */
        comptroller.preRepayHook(address(this), borrower);

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != _getBlockNumber()) {
            revert RepayBorrowFreshnessCheck();
        }

        /* We fetch the amount the borrower owes, with accumulated interest */
        uint256 accountBorrowsPrev = _borrowBalanceStored(borrower);

        uint256 repayAmountFinal = repayAmount >= accountBorrowsPrev ? accountBorrowsPrev : repayAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /*
         * We call _doTransferIn for the payer and the repayAmount
         *  On success, the vToken holds an additional repayAmount of cash.
         *  _doTransferIn reverts if anything goes wrong, since we can't be sure if side effects occurred.
         *   it returns the amount actually transferred, in case of a fee.
         */
        uint256 actualRepayAmount = _doTransferIn(payer, repayAmountFinal);

        /*
         * We calculate the new borrower and total borrow balances, failing on underflow:
         *  accountBorrowsNew = accountBorrows - actualRepayAmount
         *  totalBorrowsNew = totalBorrows - actualRepayAmount
         */
        uint256 accountBorrowsNew = accountBorrowsPrev - actualRepayAmount;
        uint256 totalBorrowsNew = totalBorrows - actualRepayAmount;

        /* We write the previously calculated values into storage */
        accountBorrows[borrower].principal = accountBorrowsNew;
        accountBorrows[borrower].interestIndex = borrowIndex;
        totalBorrows = totalBorrowsNew;

        /* We emit a RepayBorrow event */
        emit RepayBorrow(payer, borrower, actualRepayAmount, accountBorrowsNew, totalBorrowsNew);

        return actualRepayAmount;
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param skipLiquidityCheck If set to true, allows to liquidate up to 100% of the borrow
     *   regardless of the account liquidity
     */
    function _liquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral,
        bool skipLiquidityCheck
    ) internal nonReentrant {
        accrueInterest();

        uint256 error = vTokenCollateral.accrueInterest();
        if (error != NO_ERROR) {
            // accrueInterest emits logs on errors, but we still want to log the fact that an attempted liquidation failed
            revert LiquidateAccrueCollateralInterestFailed(error);
        }

        // _liquidateBorrowFresh emits borrow-specific logs on errors, so we don't need to
        _liquidateBorrowFresh(liquidator, borrower, repayAmount, vTokenCollateral, skipLiquidityCheck);
    }

    /**
     * @notice The liquidator liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param liquidator The address repaying the borrow and seizing collateral
     * @param borrower The borrower of this vToken to be liquidated
     * @param vTokenCollateral The market in which to seize collateral from the borrower
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param skipLiquidityCheck If set to true, allows to liquidate up to 100% of the borrow
     *   regardless of the account liquidity
     */
    function _liquidateBorrowFresh(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral,
        bool skipLiquidityCheck
    ) internal {
        /* Fail if liquidate not allowed */
        comptroller.preLiquidateHook(
            address(this),
            address(vTokenCollateral),
            borrower,
            repayAmount,
            skipLiquidityCheck
        );

        /* Verify market's block number equals current block number */
        if (accrualBlockNumber != _getBlockNumber()) {
            revert LiquidateFreshnessCheck();
        }

        /* Verify vTokenCollateral market's block number equals current block number */
        if (vTokenCollateral.accrualBlockNumber() != _getBlockNumber()) {
            revert LiquidateCollateralFreshnessCheck();
        }

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            revert LiquidateLiquidatorIsBorrower();
        }

        /* Fail if repayAmount = 0 */
        if (repayAmount == 0) {
            revert LiquidateCloseAmountIsZero();
        }

        /* Fail if repayAmount = type(uint256).max */
        if (repayAmount == type(uint256).max) {
            revert LiquidateCloseAmountIsUintMax();
        }

        /* Fail if repayBorrow fails */
        uint256 actualRepayAmount = _repayBorrowFresh(liquidator, borrower, repayAmount);

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We calculate the number of collateral tokens that will be seized */
        (uint256 amountSeizeError, uint256 seizeTokens) = comptroller.liquidateCalculateSeizeTokens(
            address(this),
            address(vTokenCollateral),
            actualRepayAmount
        );
        require(amountSeizeError == NO_ERROR, "LIQUIDATE_COMPTROLLER_CALCULATE_AMOUNT_SEIZE_FAILED");

        /* Revert if borrower collateral token balance < seizeTokens */
        require(vTokenCollateral.balanceOf(borrower) >= seizeTokens, "LIQUIDATE_SEIZE_TOO_MUCH");

        // If this is also the collateral, call _seize internally to avoid re-entrancy, otherwise make an external call
        if (address(vTokenCollateral) == address(this)) {
            _seize(address(this), liquidator, borrower, seizeTokens);
        } else {
            vTokenCollateral.seize(liquidator, borrower, seizeTokens);
        }

        /* We emit a LiquidateBorrow event */
        emit LiquidateBorrow(liquidator, borrower, actualRepayAmount, address(vTokenCollateral), seizeTokens);
    }

    /**
     * @notice Transfers collateral tokens (this market) to the liquidator.
     * @dev Called only during an in-kind liquidation, or by liquidateBorrow during the liquidation of another VToken.
     *  It's absolutely critical to use msg.sender as the seizer vToken and not a parameter.
     * @param seizerContract The contract seizing the collateral (either borrowed vToken or Comptroller)
     * @param liquidator The account receiving seized collateral
     * @param borrower The account having collateral seized
     * @param seizeTokens The number of vTokens to seize
     */
    function _seize(
        address seizerContract,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) internal {
        /* Fail if seize not allowed */
        comptroller.preSeizeHook(address(this), seizerContract, liquidator, borrower);

        /* Fail if borrower = liquidator */
        if (borrower == liquidator) {
            revert LiquidateSeizeLiquidatorIsBorrower();
        }

        /*
         * We calculate the new borrower and liquidator token balances, failing on underflow/overflow:
         *  borrowerTokensNew = accountTokens[borrower] - seizeTokens
         *  liquidatorTokensNew = accountTokens[liquidator] + seizeTokens
         */
        uint256 liquidationIncentiveMantissa = ComptrollerViewInterface(address(comptroller))
        .liquidationIncentiveMantissa();
        uint256 numerator = mul_(seizeTokens, Exp({ mantissa: protocolSeizeShareMantissa }));
        uint256 protocolSeizeTokens = div_(numerator, Exp({ mantissa: liquidationIncentiveMantissa }));
        uint256 liquidatorSeizeTokens = seizeTokens - protocolSeizeTokens;
        Exp memory exchangeRate = Exp({ mantissa: _exchangeRateStored() });
        uint256 protocolSeizeAmount = mul_ScalarTruncate(exchangeRate, protocolSeizeTokens);
        uint256 totalReservesNew = totalReserves + protocolSeizeAmount;

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* We write the calculated values into storage */
        totalReserves = totalReservesNew;
        totalSupply = totalSupply - protocolSeizeTokens;
        accountTokens[borrower] = accountTokens[borrower] - seizeTokens;
        accountTokens[liquidator] = accountTokens[liquidator] + liquidatorSeizeTokens;

        /* Emit a Transfer event */
        emit Transfer(borrower, liquidator, liquidatorSeizeTokens);
        emit Transfer(borrower, address(this), protocolSeizeTokens);
        emit ReservesAdded(address(this), protocolSeizeAmount, totalReservesNew);
    }

    function _setComptroller(ComptrollerInterface newComptroller) internal {
        ComptrollerInterface oldComptroller = comptroller;
        // Ensure invoke comptroller.isComptroller() returns true
        require(newComptroller.isComptroller(), "marker method returned false");

        // Set market's comptroller to newComptroller
        comptroller = newComptroller;

        // Emit NewComptroller(oldComptroller, newComptroller)
        emit NewComptroller(oldComptroller, newComptroller);
    }

    /**
     * @notice Sets a new reserve factor for the protocol (*requires fresh interest accrual)
     * @dev Admin function to set a new reserve factor
     * @param newReserveFactorMantissa New reserve factor (from 0 to 1e18)
     */
    function _setReserveFactorFresh(uint256 newReserveFactorMantissa) internal {
        // Verify market's block number equals current block number
        if (accrualBlockNumber != _getBlockNumber()) {
            revert SetReserveFactorFreshCheck();
        }

        // Check newReserveFactor ≤ maxReserveFactor
        if (newReserveFactorMantissa > MAX_RESERVE_FACTOR_MANTISSA) {
            revert SetReserveFactorBoundsCheck();
        }

        uint256 oldReserveFactorMantissa = reserveFactorMantissa;
        reserveFactorMantissa = newReserveFactorMantissa;

        emit NewReserveFactor(oldReserveFactorMantissa, newReserveFactorMantissa);
    }

    /**
     * @notice Add reserves by transferring from caller
     * @dev Requires fresh interest accrual
     * @param addAmount Amount of addition to reserves
     * @return actualAddAmount The actual amount added, excluding the potential token fees
     */
    function _addReservesFresh(uint256 addAmount) internal returns (uint256) {
        // totalReserves + actualAddAmount
        uint256 totalReservesNew;
        uint256 actualAddAmount;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != _getBlockNumber()) {
            revert AddReservesFactorFreshCheck(actualAddAmount);
        }

        actualAddAmount = _doTransferIn(msg.sender, addAmount);
        totalReservesNew = totalReserves + actualAddAmount;
        totalReserves = totalReservesNew;
        emit ReservesAdded(msg.sender, actualAddAmount, totalReservesNew);

        return actualAddAmount;
    }

    /**
     * @notice Reduces reserves by transferring to the protocol reserve contract
     * @dev Requires fresh interest accrual
     * @param reduceAmount Amount of reduction to reserves
     */
    function _reduceReservesFresh(uint256 reduceAmount) internal {
        // totalReserves - reduceAmount
        uint256 totalReservesNew;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != _getBlockNumber()) {
            revert ReduceReservesFreshCheck();
        }

        // Fail gracefully if protocol has insufficient underlying cash
        if (_getCashPrior() < reduceAmount) {
            revert ReduceReservesCashNotAvailable();
        }

        // Check reduceAmount ≤ reserves[n] (totalReserves)
        if (reduceAmount > totalReserves) {
            revert ReduceReservesCashValidation();
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        totalReservesNew = totalReserves - reduceAmount;

        // Store reserves[n+1] = reserves[n] - reduceAmount
        totalReserves = totalReservesNew;

        // _doTransferOut reverts if anything goes wrong, since we can't be sure if side effects occurred.
        // Transferring an underlying asset to the protocolShareReserve contract to channel the funds for different use.
        _doTransferOut(protocolShareReserve, reduceAmount);

        // Update the pool asset's state in the protocol share reserve for the above transfer.
        IProtocolShareReserve(protocolShareReserve).updateAssetsState(address(comptroller), underlying);

        emit ReservesReduced(protocolShareReserve, reduceAmount, totalReservesNew);
    }

    /**
     * @notice updates the interest rate model (*requires fresh interest accrual)
     * @dev Admin function to update the interest rate model
     * @param newInterestRateModel the new interest rate model to use
     */
    function _setInterestRateModelFresh(InterestRateModel newInterestRateModel) internal {
        // Used to store old model for use in the event that is emitted on success
        InterestRateModel oldInterestRateModel;

        // We fail gracefully unless market's block number equals current block number
        if (accrualBlockNumber != _getBlockNumber()) {
            revert SetInterestRateModelFreshCheck();
        }

        // Track the market's current interest rate model
        oldInterestRateModel = interestRateModel;

        // Ensure invoke newInterestRateModel.isInterestRateModel() returns true
        require(newInterestRateModel.isInterestRateModel(), "marker method returned false");

        // Set the interest rate model to newInterestRateModel
        interestRateModel = newInterestRateModel;

        // Emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel)
        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    /*** Safe Token ***/

    /**
     * @dev Similar to ERC-20 transfer, but handles tokens that have transfer fees.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     * @param from Sender of the underlying tokens
     * @param amount Amount of underlying to transfer
     * @return Actual amount received
     */
    function _doTransferIn(address from, uint256 amount) internal virtual returns (uint256) {
        IERC20Upgradeable token = IERC20Upgradeable(underlying);
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        uint256 balanceAfter = token.balanceOf(address(this));
        // Return the amount that was *actually* transferred
        return balanceAfter - balanceBefore;
    }

    /**
     * @dev Just a regular ERC-20 transfer, reverts on failure
     * @param to Receiver of the underlying tokens
     * @param amount Amount of underlying to transfer
     */
    function _doTransferOut(address to, uint256 amount) internal virtual {
        IERC20Upgradeable token = IERC20Upgradeable(underlying);
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Transfer `tokens` tokens from `src` to `dst` by `spender`
     * @dev Called by both `transfer` and `transferFrom` internally
     * @param spender The address of the account performing the transfer
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param tokens The number of tokens to transfer
     */
    function _transferTokens(
        address spender,
        address src,
        address dst,
        uint256 tokens
    ) internal {
        /* Fail if transfer not allowed */
        comptroller.preTransferHook(address(this), src, dst, tokens);

        /* Do not allow self-transfers */
        if (src == dst) {
            revert TransferNotAllowed();
        }

        /* Get the allowance, infinite for the account owner */
        uint256 startingAllowance;
        if (spender == src) {
            startingAllowance = type(uint256).max;
        } else {
            startingAllowance = transferAllowances[src][spender];
        }

        /* Do the calculations, checking for {under,over}flow */
        uint256 allowanceNew = startingAllowance - tokens;
        uint256 srcTokensNew = accountTokens[src] - tokens;
        uint256 dstTokensNew = accountTokens[dst] + tokens;

        /////////////////////////
        // EFFECTS & INTERACTIONS

        accountTokens[src] = srcTokensNew;
        accountTokens[dst] = dstTokensNew;

        /* Eat some of the allowance (if necessary) */
        if (startingAllowance != type(uint256).max) {
            transferAllowances[src][spender] = allowanceNew;
        }

        /* We emit a Transfer event */
        emit Transfer(src, dst, tokens);
    }

    /**
     * @notice Initialize the money market
     * @param underlying_ The address of the underlying asset
     * @param comptroller_ The address of the Comptroller
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param decimals_ ERC-20 decimal precision of this token
     * @param admin_ Address of the administrator of this token
     * @param accessControlManager_ AccessControlManager contract address
     * @param riskManagement Addresses of risk & income related contracts
     * @param reserveFactorMantissa_ Percentage of borrow interest that goes to reserves (from 0 to 1e18)
     */
    function _initialize(
        address underlying_,
        ComptrollerInterface comptroller_,
        InterestRateModel interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address admin_,
        address accessControlManager_,
        RiskManagementInit memory riskManagement,
        uint256 reserveFactorMantissa_
    ) internal onlyInitializing {
        __Ownable2Step_init();
        __AccessControlled_init_unchained(accessControlManager_);
        require(accrualBlockNumber == 0 && borrowIndex == 0, "market may only be initialized once");

        // Set initial exchange rate
        initialExchangeRateMantissa = initialExchangeRateMantissa_;
        require(initialExchangeRateMantissa > 0, "initial exchange rate must be greater than zero.");

        _setComptroller(comptroller_);

        // Initialize block number and borrow index (block number mocks depend on comptroller being set)
        accrualBlockNumber = _getBlockNumber();
        borrowIndex = MANTISSA_ONE;

        // Set the interest rate model (depends on block number / borrow index)
        _setInterestRateModelFresh(interestRateModel_);

        _setReserveFactorFresh(reserveFactorMantissa_);

        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _setShortfallContract(riskManagement.shortfall);
        _setProtocolShareReserve(riskManagement.protocolShareReserve);
        protocolSeizeShareMantissa = DEFAULT_PROTOCOL_SEIZE_SHARE_MANTISSA;

        // Set underlying and sanity check it
        underlying = underlying_;
        IERC20Upgradeable(underlying).totalSupply();

        // The counter starts true to prevent changing it from zero to non-zero (i.e. smaller cost/refund)
        _notEntered = true;
        _transferOwnership(admin_);
    }

    function _setShortfallContract(address shortfall_) internal {
        ensureNonzeroAddress(shortfall_);
        address oldShortfall = shortfall;
        shortfall = shortfall_;
        emit NewShortfallContract(oldShortfall, shortfall_);
    }

    function _setProtocolShareReserve(address payable protocolShareReserve_) internal {
        ensureNonzeroAddress(protocolShareReserve_);
        address oldProtocolShareReserve = address(protocolShareReserve);
        protocolShareReserve = protocolShareReserve_;
        emit NewProtocolShareReserve(oldProtocolShareReserve, address(protocolShareReserve_));
    }

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function _getCashPrior() internal view virtual returns (uint256) {
        IERC20Upgradeable token = IERC20Upgradeable(underlying);
        return token.balanceOf(address(this));
    }

    /**
     * @dev Function to simply retrieve block number
     *  This exists mainly for inheriting test contracts to stub this result.
     * @return Current block number
     */
    function _getBlockNumber() internal view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @notice Return the borrow balance of account based on stored data
     * @param account The address whose balance should be calculated
     * @return borrowBalance the calculated balance
     */
    function _borrowBalanceStored(address account) internal view returns (uint256) {
        /* Get borrowBalance and borrowIndex */
        BorrowSnapshot memory borrowSnapshot = accountBorrows[account];

        /* If borrowBalance = 0 then borrowIndex is likely also 0.
         * Rather than failing the calculation with a division by 0, we immediately return 0 in this case.
         */
        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        /* Calculate new borrow balance using the interest index:
         *  recentBorrowBalance = borrower.borrowBalance * market.borrowIndex / borrower.borrowIndex
         */
        uint256 principalTimesIndex = borrowSnapshot.principal * borrowIndex;

        return principalTimesIndex / borrowSnapshot.interestIndex;
    }

    /**
     * @notice Calculates the exchange rate from the underlying to the VToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return exchangeRate Calculated exchange rate scaled by 1e18
     */
    function _exchangeRateStored() internal view virtual returns (uint256) {
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            /*
             * If there are no tokens minted:
             *  exchangeRate = initialExchangeRate
             */
            return initialExchangeRateMantissa;
        }
        /*
         * Otherwise:
         *  exchangeRate = (totalCash + totalBorrows + badDebt - totalReserves) / totalSupply
         */
        uint256 totalCash = _getCashPrior();
        uint256 cashPlusBorrowsMinusReserves = totalCash + totalBorrows + badDebt - totalReserves;
        uint256 exchangeRate = (cashPlusBorrowsMinusReserves * EXP_SCALE) / _totalSupply;

        return exchangeRate;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ResilientOracleInterface } from "@venusprotocol/oracle/contracts/interfaces/OracleInterface.sol";

import { ComptrollerInterface } from "./ComptrollerInterface.sol";
import { InterestRateModel } from "./InterestRateModel.sol";

/**
 * @title VTokenStorage
 * @author Venus
 * @notice Storage layout used by the `VToken` contract
 */
// solhint-disable-next-line max-states-count
contract VTokenStorage {
    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice Underlying asset for this VToken
     */
    address public underlying;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    /**
     * @notice Protocol share Reserve contract address
     */
    address payable public protocolShareReserve;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint256 internal constant MAX_BORROW_RATE_MANTISSA = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint256 internal constant MAX_RESERVE_FACTOR_MANTISSA = 1e18;

    /**
     * @notice Contract which oversees inter-vToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first VTokens (used when totalSupply = 0)
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    /**
     * @notice Total bad debt of the market
     */
    uint256 public badDebt;

    // Official record of token balances for each account
    mapping(address => uint256) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint256 public protocolSeizeShareMantissa;

    /**
     * @notice Storage of Shortfall contract address
     */
    address public shortfall;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/**
 * @title VTokenInterface
 * @author Venus
 * @notice Interface implemented by the `VToken` contract
 */
abstract contract VTokenInterface is VTokenStorage {
    struct RiskManagementInit {
        address shortfall;
        address payable protocolShareReserve;
    }

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address indexed minter, uint256 mintAmount, uint256 mintTokens, uint256 accountBalance);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens, uint256 accountBalance);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address indexed borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(
        address indexed payer,
        address indexed borrower,
        uint256 repayAmount,
        uint256 accountBorrows,
        uint256 totalBorrows
    );

    /**
     * @notice Event emitted when bad debt is accumulated on a market
     * @param borrower borrower to "forgive"
     * @param badDebtDelta amount of new bad debt recorded
     * @param badDebtOld previous bad debt value
     * @param badDebtNew new bad debt value
     */
    event BadDebtIncreased(address indexed borrower, uint256 badDebtDelta, uint256 badDebtOld, uint256 badDebtNew);

    /**
     * @notice Event emitted when bad debt is recovered via an auction
     * @param badDebtOld previous bad debt value
     * @param badDebtNew new bad debt value
     */
    event BadDebtRecovered(uint256 badDebtOld, uint256 badDebtNew);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(
        address indexed liquidator,
        address indexed borrower,
        uint256 repayAmount,
        address indexed vTokenCollateral,
        uint256 seizeTokens
    );

    /*** Admin Events ***/

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface indexed oldComptroller, ComptrollerInterface indexed newComptroller);

    /**
     * @notice Event emitted when shortfall contract address is changed
     */
    event NewShortfallContract(address indexed oldShortfall, address indexed newShortfall);

    /**
     * @notice Event emitted when protocol share reserve contract address is changed
     */
    event NewProtocolShareReserve(address indexed oldProtocolShareReserve, address indexed newProtocolShareReserve);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(
        InterestRateModel indexed oldInterestRateModel,
        InterestRateModel indexed newInterestRateModel
    );

    /**
     * @notice Event emitted when protocol seize share is changed
     */
    event NewProtocolSeizeShare(uint256 oldProtocolSeizeShareMantissa, uint256 newProtocolSeizeShareMantissa);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address indexed benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address indexed admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Event emitted when healing the borrow
     */
    event HealBorrow(address indexed payer, address indexed borrower, uint256 repayAmount);

    /**
     * @notice Event emitted when tokens are swept
     */
    event SweepToken(address indexed token);

    /*** User Interface ***/

    function mint(uint256 mintAmount) external virtual returns (uint256);

    function mintBehalf(address minter, uint256 mintAllowed) external virtual returns (uint256);

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);

    function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral
    ) external virtual returns (uint256);

    function healBorrow(
        address payer,
        address borrower,
        uint256 repayAmount
    ) external virtual;

    function forceLiquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        VTokenInterface vTokenCollateral,
        bool skipCloseFactorCheck
    ) external virtual;

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual;

    function transfer(address dst, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function accrueInterest() external virtual returns (uint256);

    function sweepToken(IERC20Upgradeable token) external virtual;

    /*** Admin Functions ***/

    function setReserveFactor(uint256 newReserveFactorMantissa) external virtual;

    function reduceReserves(uint256 reduceAmount) external virtual;

    function exchangeRateCurrent() external virtual returns (uint256);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function setInterestRateModel(InterestRateModel newInterestRateModel) external virtual;

    function addReserves(uint256 addAmount) external virtual;

    function totalBorrowsCurrent() external virtual returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool);

    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view virtual returns (uint256);

    function supplyRatePerBlock() external view virtual returns (uint256);

    function borrowBalanceStored(address account) external view virtual returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function getCash() external view virtual returns (uint256);

    /**
     * @notice Indicator that this is a VToken contract (for inspection)
     * @return Always true
     */
    function isVToken() external pure virtual returns (bool) {
        return true;
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