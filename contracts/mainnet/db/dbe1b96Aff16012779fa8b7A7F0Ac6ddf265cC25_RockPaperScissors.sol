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

// SPDX-License-Identifier: UNLICENSED

/**
 * This is free and unencumbered software released into the public domain.
 * Anyone is free to copy, modify, publish, use, compile, sell, or
 * distribute this software, either in source code form or as a compiled
 * binary, for any purpose, commercial or non-commercial, and by any
 * means.
 * In jurisdictions that recognize copyright laws, the author or authors
 * of this software dedicate any and all copyright interest in the
 * software to the public domain. We make this dedication for the benefit
 * of the public at large and to the detriment of our heirs and
 * successors. We intend this dedication to be an overt act of
 * relinquishment in perpetuity of all present and future rights to this
 * software under copyright law.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 *
 * IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 * OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 *
 * BY USING THIS SOFTWARE, YOU ACKNOWLEDGE YOUR SOLE RESPONSIBILITY
 * TO COMPLY WITH ALL APPLICABLE LAWS REGARDING MONEY TRANSMISSION,
 * AND OTHER LEGAL REGULATIONS, AS NO THIRD PARTY INTERMEDIATION
 * EXISTS IN BLOCKCHAIN TRANSACTIONS. WHILE YOU ARE FREE TO UTILIZE THIS CODE
 * IN ANY MANNER, IT IS YOUR OBLIGATION TO ENSURE THAT YOUR USAGE ADHERES
 * TO THE LEGAL STANDARDS OF YOUR JURISDICTION.
 * For more information, please refer to <http://unlicense.org/>
 */

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

pragma solidity 0.8.25;

contract RockPaperScissors is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant MIN_WINS = 1;
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;
    uint16 public constant MAX_ROUND = 65535;

    enum Closer {
        None,
        PlayerA,
        PlayerB
    }

    enum RoomStatus {
        None,
        Open,
        ReadyForGame,
        ReadyForReveal,
        Closed
    }

    enum WinnerStatus {
        None,
        WinnerPlayerA,
        WinnerPlayerB,
        PlayerAExitRoom,
        UnusedRoomClosed,
        TechnicalWinnerA,
        TechnicalWinnerB
    }

    enum GameStages {
        None,
        WaitForOpponent,
        WaitForReveal,
        DoneWithWinner,
        DoneWithDraw
    }

    enum RoundStages {
        None,
        InitGame,
        AddMove,
        RevealMove,
        BothRevealed,
        Done
    }

    enum Moves {
        None,
        Rock,
        Scissors,
        Paper
    }

    enum RoundWinnerOutcomes {
        None,
        PlayerA,
        PlayerB,
        Draw
    }

    struct UniqRoomData {
        uint256 roomId;
        address playerA;
        address playerB;
        uint8 wins;
        address token;
        uint256 bet;
    }

    struct PlayerWinCounter {
        uint8 winsPlayerA;
        uint8 winsPlayerB;
    }

    struct RoomInfo {
        UniqRoomData data;
        uint256 pot;
        uint16 roundCounter;
        PlayerWinCounter winsCounter;
        Closer closer;
        uint64 deadline;
        RoomStatus status;
        WinnerStatus winnerStatus;
    }

    struct GameRoomInfo {
        Moves moveA;
        Moves moveB;
        bytes32 encrMoveA;
        bytes32 encrMoveB;
        RoundWinnerOutcomes winner;
        GameStages stage;
        RoundStages roundStage;
    }

    uint256 public roomIdCounter;
    uint256 public activeRoomCounter;

    address public feeReceiver;
    uint256 public fee;
    uint256 public referrerFee;

    uint256 public minBetAmount;

    uint64 public closeRoomDeadline;

    mapping(uint256 => RoomInfo) public rooms;
    mapping(uint256 => mapping(uint256 => GameRoomInfo)) public rounds;
    mapping(address => address) public referrers;

    event PlayerExit(uint256 indexed roomId, address indexed entrant);
    event FeePercentageSet(uint256 indexed feePercentage);
    event MinimalBetAmountSet(uint256 indexed minBetAmount);
    event MoveAdded(uint256 indexed roomId, uint256 indexed gameId, address indexed entrant);
    event RoomJoined(uint256 indexed roomId, address indexed entrant);
    event OwnerCloseUnusedRoom(uint256 indexed roomId, address indexed potReceiver);
    event UnusedRoomClosed(uint256 indexed roomId, address indexed potReceiver);
    event ReferrerFeeSet(uint256 indexed feeValue);
    event ReferrerConnected(address indexed referralAddr, address indexed referrerAddr);
    event RoomCloseDeadlineSet(uint64 indexed deadlineToCloseRoom);
    event FeeReceiverSet(address feeReceiver);
    event CurrencySent(address indexed receiver);
    event RoomGameHasDraw(
        uint256 indexed roomId,
        uint256 indexed gameId,
        RoundWinnerOutcomes winner
    );
    event PrivateRoomInitialized(
        uint256 indexed roomId,
        address indexed entrantA,
        address indexed entrantB
    );
    event PlayerRevealedMove(
        uint256 indexed roomId,
        uint256 indexed gameId,
        address indexed entrant
    );
    event RoomClosed(
        uint256 indexed roomId,
        address indexed receiver,
        address indexed receiverAddr,
        uint256 pot
    );
    event RoomGameStarted(
        uint256 indexed roomId,
        uint256 indexed gameId,
        address indexed sender,
        address opponent
    );
    event WinsCounterUpdated(
        uint256 indexed roomId,
        uint256 indexed winsEntrantA,
        uint256 indexed winsEntrantB,
        address entrantA,
        address entrantB
    );
    event RoomCreated(
        uint256 indexed roomId,
        address indexed entrantA,
        address indexed entrantB,
        address currency,
        uint256 betAmount
    );

    error LowValue();
    error WrongRoomStatus();
    error InvalidBetAmount();
    error InvalidTimeDuration();
    error LowBetAmount();
    error UnknownCaller();
    error SelfPlayProhibited();
    error ZeroAddress();
    error InvalidFeeValue();
    error NonexistentRoom();
    error EarlyCallForCloseRoom();
    error ReachedCloseRoomDeadline();
    error AlreadyRevealed();
    error InvalidData(bytes32, bytes32);
    error InvalidMove();
    error InvalidRound(uint16 round, uint16 roundCounter);
    error HiddedMoveAlreadySet();
    error WithdrawFailed();

    modifier isRoomExist(uint256 roomId) {
        if (roomId > roomIdCounter) revert NonexistentRoom();
        _;
    }
    modifier onlyRoomPlayer(uint256 roomId) {
        if (rooms[roomId].data.playerA != msg.sender && rooms[roomId].data.playerB != msg.sender)
            revert UnknownCaller();
        _;
    }

    function initialize(
        uint64 closeRoomDeadline_,
        uint256 fee_,
        uint256 minBetAmount_,
        address feeReceiver_,
        uint256 referrerFee_
    ) public initializer {
        __Ownable_init();

        setFeeReceiver(feeReceiver_);
        setFeePercentage(fee_);
        setMinimalBetAmount(minBetAmount_);
        setReferrerFee(referrerFee_);
        setRoomCloseDeadline(closeRoomDeadline_);
    }

    function initRoom(
        uint8 wins,
        address currency,
        uint256 betAmount,
        address playerB,
        address referrer
    ) external returns (uint256) {
        if (wins < MIN_WINS) revert LowValue();
        if (betAmount < minBetAmount) revert LowBetAmount();
        if (currency == address(0)) revert ZeroAddress();
        if (msg.sender == playerB) revert SelfPlayProhibited();

        uint256 roomId = ++roomIdCounter;
        activeRoomCounter++;

        RoomInfo storage room = rooms[roomId];

        room.data.roomId = roomId;
        room.data.playerA = msg.sender;
        room.data.wins = wins;
        room.data.token = currency;
        room.data.bet = betAmount;
        room.status = RoomStatus.Open;

        if (playerB != address(0)) {
            room.data.playerB = playerB;
            emit PrivateRoomInitialized(roomId, room.data.playerA, playerB);
        }

        _connectReferrer(msg.sender, referrer);
        _setCloser(roomId);

        IERC20Upgradeable(currency).safeTransferFrom(msg.sender, address(this), betAmount);

        emit RoomCreated(roomId, msg.sender, playerB, currency, betAmount);

        return roomId;
    }

    function joinRoom(uint256 roomId, address referrer) external isRoomExist(roomId) {
        RoomInfo storage room = rooms[roomId];

        if (room.status != RoomStatus.Open) revert WrongRoomStatus();
        if (msg.sender == room.data.playerA) revert SelfPlayProhibited();
        if (room.data.playerB == msg.sender && room.data.playerB == address(0))
            revert UnknownCaller();

        room.data.playerB = msg.sender;
        room.status = RoomStatus.ReadyForGame;
        room.pot = room.data.bet + room.data.bet;
        room.roundCounter++;

        rounds[roomId][room.roundCounter].roundStage = RoundStages.InitGame;

        _connectReferrer(msg.sender, referrer);
        _setCloser(roomId);

        IERC20Upgradeable(room.data.token).safeTransferFrom(
            msg.sender,
            address(this),
            room.data.bet
        );

        emit RoomJoined(roomId, msg.sender);
    }

    function playRoomGame(
        uint256 roomId,
        uint16 round,
        bytes32 hiddenMove
    ) external isRoomExist(roomId) onlyRoomPlayer(roomId) {
        RoomInfo storage room = rooms[roomId];

        if (block.timestamp > room.deadline) revert ReachedCloseRoomDeadline();
        if (room.status != RoomStatus.ReadyForGame) revert WrongRoomStatus();
        if (round != room.roundCounter) revert InvalidRound(round, room.roundCounter);

        GameRoomInfo storage roundInfo = rounds[roomId][round];

        if (roundInfo.roundStage == RoundStages.InitGame) {
            _setHiddenMove(roomId, round, hiddenMove);

            roundInfo.roundStage = RoundStages.AddMove;

            emit RoomGameStarted(roomId, round, room.data.playerA, room.data.playerB);
        } else {
            _setHiddenMove(roomId, round, hiddenMove);

            roundInfo.roundStage = RoundStages.RevealMove;
            room.status = RoomStatus.ReadyForReveal;

            emit MoveAdded(roomId, round, msg.sender);
        }

        _setCloser(roomId);
    }

    function reveal(
        uint256 roomId,
        uint16 round,
        Moves move,
        string memory salt
    ) external isRoomExist(roomId) onlyRoomPlayer(roomId) {
        RoomInfo storage room = rooms[roomId];
        if (block.timestamp > room.deadline) revert ReachedCloseRoomDeadline();
        if (
            round != room.roundCounter &&
            rounds[roomId][room.roundCounter].roundStage != RoundStages.RevealMove
        ) revert InvalidRound(round, room.roundCounter);
        if (room.status != RoomStatus.ReadyForReveal) revert WrongRoomStatus();

        GameRoomInfo storage roundInfo = rounds[roomId][round];

        _revealPlayerMove(roomId, round, move, salt);

        if (roundInfo.roundStage == RoundStages.BothRevealed) {
            roundInfo.roundStage = RoundStages.Done;

            _calcRoundWinnerOutcomes(roomId, round);

            if (
                room.data.wins == room.winsCounter.winsPlayerA ||
                room.data.wins == room.winsCounter.winsPlayerB
            ) {
                room.winsCounter.winsPlayerA > room.winsCounter.winsPlayerB
                    ? room.winnerStatus = WinnerStatus.WinnerPlayerA
                    : room.winnerStatus = WinnerStatus.WinnerPlayerB;

                _closeRoomAndPayWinPot(roomId);
            } else {
                room.roundCounter++;

                if (room.roundCounter == MAX_ROUND) {
                    room.winnerStatus = WinnerStatus.UnusedRoomClosed;
                    _closeRoomAndPayWinPot(roomId);
                }

                room.status = RoomStatus.ReadyForGame;
                rounds[roomId][room.roundCounter].roundStage = RoundStages.InitGame;
            }
        }

        _setCloser(roomId);
    }

    function exitRoom(uint256 roomId) external isRoomExist(roomId) {
        RoomInfo storage room = rooms[roomId];
        // check if room has status === open
        if (room.status != RoomStatus.Open) revert WrongRoomStatus();
        // if sender is creator of room
        if (msg.sender != room.data.playerA) revert UnknownCaller();

        room.winnerStatus = WinnerStatus.PlayerAExitRoom;

        _closeRoomAndPayWinPot(roomId);

        emit PlayerExit(roomId, msg.sender);
    }

    function closeRoom(uint256 roomId) external isRoomExist(roomId) onlyRoomPlayer(roomId) {
        _closeUnusedRoom(roomId);
        RoomInfo memory room = rooms[roomId];
        emit UnusedRoomClosed(
            roomId,
            room.closer == Closer.PlayerA ? room.data.playerA : room.data.playerB
        );
    }

    function ownerCloseRooms(uint256[] memory roomIds) external onlyOwner {
        for (uint256 i = 0; i < roomIds.length; i++) {
            _closeUnusedRoom(roomIds[i]);

            RoomInfo memory room = rooms[roomIds[i]];

            emit OwnerCloseUnusedRoom(
                roomIds[i],
                room.closer == Closer.PlayerA ? room.data.playerA : room.data.playerB
            );
        }
    }

    function setMinimalBetAmount(uint256 minBetAmount_) public onlyOwner {
        if (minBetAmount_ == 0 wei) revert InvalidBetAmount();

        minBetAmount = minBetAmount_;

        emit MinimalBetAmountSet(minBetAmount_);
    }

    function setFeePercentage(uint256 fee_) public onlyOwner {
        if (fee_ > ONE_HUNDRED_PERCENT || fee_ == 0) revert InvalidFeeValue();
        fee = fee_;

        emit FeePercentageSet(fee_);
    }

    function setReferrerFee(uint256 referrerFee_) public onlyOwner {
        if (referrerFee_ > fee) revert InvalidFeeValue();
        referrerFee = referrerFee_;

        emit ReferrerFeeSet(referrerFee_);
    }

    function setRoomCloseDeadline(uint64 closeRoomDeadline_) public onlyOwner {
        if (closeRoomDeadline_ == 0) revert InvalidTimeDuration();
        closeRoomDeadline = closeRoomDeadline_;

        emit RoomCloseDeadlineSet(closeRoomDeadline);
    }

    function setFeeReceiver(address feeReceiver_) public onlyOwner {
        if (feeReceiver_ == address(0)) revert ZeroAddress();
        feeReceiver = feeReceiver_;

        emit FeeReceiverSet(feeReceiver_);
    }

    function getCurrentRoomRound(uint256 roomId) external view returns (uint256) {
        return rooms[roomId].roundCounter;
    }

    function getCloserAddress(uint256 roomId) external view returns (address) {
        return
            rooms[roomId].closer == Closer.PlayerA
                ? rooms[roomId].data.playerA
                : rooms[roomId].data.playerB;
    }

    function getRoomCloser(uint256 roomId) external view returns (Closer, uint64 deadline) {
        return (rooms[roomId].closer, rooms[roomId].deadline);
    }

    function getAllRoomRounds(uint256 roomId) external view returns (GameRoomInfo[] memory) {
        if (rooms[roomId].roundCounter == 0) {
            return new GameRoomInfo[](0);
        }

        uint256 length = rooms[roomId].roundCounter;
        GameRoomInfo[] memory roundsInfo = new GameRoomInfo[](length);

        for (uint256 i = 1; i <= length; i++) {
            roundsInfo[i - 1] = rounds[roomId][i];
        }

        return roundsInfo;
    }

    function getRoomsInfo(
        uint256 indexFrom,
        uint256 indexTo
    ) external view returns (RoomInfo[] memory) {
        uint256 length = indexTo - indexFrom;
        RoomInfo[] memory roomsInfo = new RoomInfo[](length + 1);
        uint256 counter = 0;

        for (uint256 i = indexFrom; i <= indexTo; i++) {
            roomsInfo[counter] = rooms[i];
            ++counter;
        }
        return roomsInfo;
    }

    function _setCloser(uint256 _roomId) private {
        rooms[_roomId].closer = msg.sender == rooms[_roomId].data.playerA
            ? Closer.PlayerA
            : Closer.PlayerB;
        rooms[_roomId].deadline = uint64(block.timestamp + closeRoomDeadline);
    }

    function _setHiddenMove(uint256 _roomId, uint256 _round, bytes32 _hiddenMove) private {
        GameRoomInfo storage roundInfo = rounds[_roomId][_round];
        if (msg.sender == rooms[_roomId].data.playerA) {
            if (roundInfo.encrMoveA != bytes32(0)) revert HiddedMoveAlreadySet();
            roundInfo.encrMoveA = _hiddenMove;
        } else {
            if (roundInfo.encrMoveB != bytes32(0)) revert HiddedMoveAlreadySet();
            roundInfo.encrMoveB = _hiddenMove;
        }
    }

    function _revealPlayerMove(
        uint256 _roomId,
        uint256 _round,
        Moves _move,
        string memory _salt
    ) private {
        if (_move != Moves.Rock && _move != Moves.Paper && _move != Moves.Scissors)
            revert InvalidMove();
        bytes32 encrMove = keccak256(abi.encodePacked(_salt, _move, msg.sender));

        GameRoomInfo storage roundInfo = rounds[_roomId][_round];

        if (msg.sender == rooms[_roomId].data.playerA) {
            if (roundInfo.moveA != Moves.None) revert AlreadyRevealed();
            if (encrMove != roundInfo.encrMoveA) revert InvalidData(encrMove, roundInfo.encrMoveA);

            roundInfo.moveA = _move;
        } else {
            if (roundInfo.moveB != Moves.None) revert AlreadyRevealed();
            if (encrMove != roundInfo.encrMoveB) revert InvalidData(encrMove, roundInfo.encrMoveB);

            roundInfo.moveB = _move;
        }

        if (roundInfo.moveA != Moves.None && roundInfo.moveB != Moves.None) {
            roundInfo.roundStage = RoundStages.BothRevealed;
        }

        emit PlayerRevealedMove(_roomId, _roomId, msg.sender);
    }

    function _calcRoundWinnerOutcomes(uint256 _roomId, uint256 _round) private {
        RoomInfo storage room = rooms[_roomId];
        GameRoomInfo storage roundInfo = rounds[_roomId][_round];

        Moves _movePlayerA = roundInfo.moveA;
        Moves _movePlayerB = roundInfo.moveB;

        if (_movePlayerA == _movePlayerB) {
            roundInfo.winner = RoundWinnerOutcomes.Draw;

            emit RoomGameHasDraw(_roomId, _round, RoundWinnerOutcomes.Draw);
        } else if (
            (_movePlayerA == Moves.Rock && _movePlayerB == Moves.Scissors) ||
            (_movePlayerA == Moves.Paper && _movePlayerB == Moves.Rock) ||
            (_movePlayerA == Moves.Scissors && _movePlayerB == Moves.Paper)
        ) {
            roundInfo.winner = RoundWinnerOutcomes.PlayerA;
            room.winsCounter.winsPlayerA++;
        } else {
            roundInfo.winner = RoundWinnerOutcomes.PlayerB;
            room.winsCounter.winsPlayerB++;
        }

        emit WinsCounterUpdated(
            _roomId,
            room.winsCounter.winsPlayerA,
            room.winsCounter.winsPlayerB,
            room.data.playerA,
            room.data.playerB
        );
    }

    function _closeRoomAndPayWinPot(uint256 _roomId) private {
        RoomInfo storage room = rooms[_roomId];

        address token = room.data.token;
        uint256 roomBalance = room.pot;
        room.pot = 0;
        room.status = RoomStatus.Closed;
        activeRoomCounter--;

        uint256 winPot;
        if (
            room.winnerStatus == WinnerStatus.WinnerPlayerA ||
            room.winnerStatus == WinnerStatus.WinnerPlayerB ||
            room.winnerStatus == WinnerStatus.TechnicalWinnerA ||
            room.winnerStatus == WinnerStatus.TechnicalWinnerB
        ) {
            address winner = room.winnerStatus == WinnerStatus.WinnerPlayerA ||
                room.winnerStatus == WinnerStatus.TechnicalWinnerA
                ? room.data.playerA
                : room.data.playerB;

            uint256 serviceFee = (roomBalance * fee) / ONE_HUNDRED_PERCENT;
            uint256 referrerFeeAmount = (serviceFee * referrerFee) / ONE_HUNDRED_PERCENT;
            winPot = roomBalance - serviceFee;
            serviceFee -= referrerFeeAmount;

            IERC20Upgradeable(token).safeTransfer(winner, winPot);
            IERC20Upgradeable(token).safeTransfer(feeReceiver, serviceFee);
            IERC20Upgradeable(token).safeTransfer(referrers[winner], referrerFeeAmount);

            emit RoomClosed(_roomId, room.data.playerA, room.data.playerB, winPot);
        } else if (room.winnerStatus == WinnerStatus.PlayerAExitRoom) {
            uint256 amount = room.data.bet;
            IERC20Upgradeable(token).safeTransfer(room.data.playerA, amount);

            emit RoomClosed(_roomId, room.data.playerA, address(0), amount);
        } else if (room.winnerStatus == WinnerStatus.UnusedRoomClosed) {
            winPot = roomBalance / 2;

            IERC20Upgradeable(token).safeTransfer(room.data.playerA, winPot);
            IERC20Upgradeable(token).safeTransfer(room.data.playerB, winPot);

            emit RoomClosed(_roomId, room.data.playerA, room.data.playerB, roomBalance);
        }
    }

    function _closeUnusedRoom(uint256 _roomId) private {
        if (rooms[_roomId].status == RoomStatus.Closed) revert WrongRoomStatus();
        if (block.timestamp < rooms[_roomId].deadline) revert EarlyCallForCloseRoom();

        RoomInfo storage room = rooms[_roomId];

        if (
            room.roundCounter == 1 &&
            rounds[_roomId][room.roundCounter].roundStage == RoundStages.InitGame
        ) {
            room.winnerStatus = WinnerStatus.UnusedRoomClosed;
        } else {
            room.winnerStatus = room.closer == Closer.PlayerA
                ? WinnerStatus.TechnicalWinnerA
                : WinnerStatus.TechnicalWinnerB;
        }

        _closeRoomAndPayWinPot(_roomId);
    }

    function _connectReferrer(address _entrant, address _referrer) private {
        if (referrers[_entrant] == address(0)) {
            referrers[_entrant] = _referrer == address(0) ? feeReceiver : _referrer;

            emit ReferrerConnected(_entrant, referrers[_entrant]);
        }
    }

    receive() external payable {
        _withdrawBalance();
    }

    function _withdrawBalance() private {
        payable(feeReceiver).transfer(address(this).balance);

        emit CurrencySent(feeReceiver);
    }
}