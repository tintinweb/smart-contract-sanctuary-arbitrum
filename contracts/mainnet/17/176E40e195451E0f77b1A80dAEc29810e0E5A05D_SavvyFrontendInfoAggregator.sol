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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
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
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @notice An error used to indicate that an argument passed to a function is illegal or
///         inappropriate.
///
/// @param message The error message.
error IllegalArgumentWithReason(string message);

/// @notice An error used to indicate that a function has encountered an unrecoverable state.
///
/// @param message The error message.
error IllegalStateWithReason(string message);

/// @notice An error used to indicate that an operation is unsupported.
///
/// @param message The error message.
error UnsupportedOperationWithReason(string message);

/// @notice An error used to indicate that a message sender tried to execute a privileged function.
///
/// @param message The error message.
error UnauthorizedWithReason(string message);

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Burnable
/// @author Savvy DeFi
interface IERC20Burnable is IERC20Minimal {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  IERC20Metadata
/// @author Savvy DeFi
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  IERC20Minimal
/// @author Savvy DeFi
interface IERC20Minimal {
    /// @notice An event which is emitted when tokens are transferred between two parties.
    ///
    /// @param owner     The owner of the tokens from which the tokens were transferred.
    /// @param recipient The recipient of the tokens to which the tokens were transferred.
    /// @param amount    The amount of tokens which were transferred.
    event Transfer(
        address indexed owner,
        address indexed recipient,
        uint256 amount
    );

    /// @notice An event which is emitted when an approval is made.
    ///
    /// @param owner   The address which made the approval.
    /// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Gets the current total supply of tokens.
    ///
    /// @return The total supply.
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of tokens that an account holds.
    ///
    /// @param account The account address.
    ///
    /// @return The balance of the account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the allowance that an owner has allotted for a spender.
    ///
    /// @param owner   The owner address.
    /// @param spender The spender address.
    ///
    /// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    ///
    /// @notice Emits a {Transfer} event.
    ///
    /// @param recipient The address which will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    ///
    /// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    ///
    /// @return If the approval was successful.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    /// @notice Emits a {Transfer} event.
    ///
    /// @param owner     The address to transfer tokens from.
    /// @param recipient The address that will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./IERC20Minimal.sol";

/// @title  IERC20Mintable
/// @author Savvy DeFi
interface IERC20Mintable is IERC20Minimal {
    /// @notice Mints `amount` tokens to `recipient`.
    ///
    /// @param recipient The address which will receive the minted tokens.
    /// @param amount    The amount of tokens to mint.
    ///
    /// @return If minting the tokens was successful.
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./infoaggregator/ISavvyOverview.sol";
import "./infoaggregator/ISavvyUserPortfolio.sol";
import "./infoaggregator/ISavvyUserBalance.sol";
import "./infoaggregator/ISavvyPositions.sol";
import "./infoaggregator/ISavvyPool.sol";
import "./infoaggregator/ISavvyFrontend.sol";
import "./IVeSvy.sol";
import "./ISavvyBooster.sol";
import "./ISavvyToken.sol";
import "./ISavvyPriceFeed.sol";

/// @title IInfoAggregator
/// @author Savvy DeFi
///
/// @notice Simplifies the calls required to get protcol and user information.
/// @dev Used by the frontend.
interface IInfoAggregator is
  ISavvyOverview,
  ISavvyUserPortfolio,
  ISavvyUserBalance,
  ISavvyPositions,
  ISavvyPool
{
  /// @notice Add new SavvyPositionManagers.
  /// @dev Only owner can call this function. If not, return IllegalArgument().
  /// @param savvyPositionManagers_ List of SavvyPositionManager addresses.
  function addSavvyPositionManager(
    address[] memory savvyPositionManagers_
  ) external;

  /// @notice Add support tokens to infoAggregator.
  /// @param _supportTokens The informations of savvy supports
  function addSupportTokens(
    SupportTokenInfo[] calldata _supportTokens
  ) external;

  /// @notice Get all registered SavvyPositionManager addresses.
  function getSavvyPositionManagers() external view returns (address[] memory);

  /// @notice Check if addr is valid SavvyPositionManager address
  function isSavvyPositionManager(address) external view returns (bool);

  /// @dev The contract to get token price.
  function svyPriceFeed() external view returns (ISavvyPriceFeed svyPriceFeed);

  /// @dev Savvy DeFi's own token.
  function svyToken() external view returns (ISavvyToken svyToken);

  /// @dev SavvyBooster contract handle.
  function svyBooster() external view returns (ISavvyBooster svyBooster);

  /// @dev VeSvy contract handle.
  function veSvy() external view returns (IVeSvy veSvy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./ISavvyInfoAggregatorStructs.sol";

/// @title ISavvyFrontend
/// @author Savvy DeFi
///
/// @notice Get the necessary information for the Savvy DeFi frontend from a single call.
interface ISavvyFrontend is ISavvyInfoAggregatorStructs {
    /// @notice Add new SavvySwap.
    /// @dev Only owner can call this function. If not, return IllegalArgument().
    /// @param savvySwaps_ List of SavvySwap addresses.
    function setSavvySwap(
        address[] memory savvySwaps_,
        bool[] memory shouldAdd_
    ) external;

    /// @notice A simplified way to get all the information for the Dashboard
    /// page on the frontend.
    ///
    /// @notice `account_` must be a non-zero address or this call will revert with a {IllegalArgument} error.
    ///
    /// @param account_ The specific wallet to get information for.
    /// @return dashboardPageInfo The Dashboard information for an account.
    function getDashboardPageInfo(
        address account_
    ) external view returns (DashboardPageInfo memory);

    /// @notice A simplified way to get all the information for the Pools
    /// page on the frontend.
    ///
    /// @notice `account_` must be a non-zero address or this call will revert with a {IllegalArgument} error.
    ///
    /// @param account_ The specific wallet to get information for.
    /// @return poolsPageInfo The Pools information for an account.
    function getPoolsPageInfo(
        address account_
    ) external view returns (PoolsPageInfo memory);

    /// @notice A simplified way to get all the information for the MySVY
    /// page on the frontend.
    ///
    /// @notice `account_` must be a non-zero address or this call will revert with a {IllegalArgument} error.
    ///
    /// @param account_ The specific wallet to get information for.
    /// @return MySVYPageInfo The MySVY information for an account.
    function getMySVYPageInfo(
        address account_
    ) external view returns (MySVYPageInfo memory);

    /// @notice Set new InfoAggregator contract address.
    /// @dev Only owner can call this function.
    /// @param infoAggregator_ The address of infoAggregator.
    function setInfoAggregator(address infoAggregator_) external;

    /// @notice A simplified way to get all the information for the Swap
    /// page on the frontend.
    ///
    /// @notice `account_` must be a non-zero address or this call will revert with a {IllegalArgument} error.
    ///
    /// @param account_ The specific wallet to get information for.
    /// @return MySVYPageInfo The Swap information for an account.
    function getSwapPageInfo(
        address account_
    ) external view returns (SwapPageInfo memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISavvyInfoAggregatorStructs {
    struct FullSavvyPosition {
        address token;
        uint256 amount;
        uint256 valueUSD;
    }

    struct FullDebtInfo {
        address savvyPositionManager;
        int256 amount;
        int256 valueUSD;
    }

    struct FullPoolInfo {
        address savvyPositionManager;
        address poolAddress;
        address baseTokenAddress;
        uint256 userDepositedAmount;
        uint256 userDepositedValueUSD;
        uint256 userHarvestedYield;
        uint256 poolDepositedAmount;
        uint256 poolDepositedValueUSD;
        uint256 maxPoolDepositedAmount;
        uint256 maxPoolDepositedValueUSD;
        uint256 maxWithdrawableShares;
        uint256 maxWithdrawableAmount;
    }

    struct SavvyPosition {
        address baseToken;
        uint256 amount;
    }

    struct SavvyWithdrawInfo {
        address savvyPositionManager;
        address yieldToken;
        uint256 amount;
        uint256 shares;
    }

    struct SupportTokenInfo {
        address baseToken;
        address yieldToken;
    }

    struct DebtInfo {
        address savvyPositionManager;
        int256 amount;
    }

    struct TokenPriceData {
        address tokenAddress;
        uint256 priceUSD;
    }

    /// @notice All the information required by the Dashboard page.
    struct DashboardPageInfo {
        // The balance and value for debt tokens in the account's
        // wallet (e.g. svUSD, svAVAX, etc).
        FullSavvyPosition[] debtTokens;
        // The balance and value of each token the account deposited
        // into Savvy (e.g. USDC, WAVAX, WETH.e, etc).
        FullSavvyPosition[] depositedTokens;
        // The balance and value of each token that a wallet can deposit into Savvy.
        // @dev This is different than `depositedTokens`. `depositedTokens` are
        // tokens already deposited into Savvy where as `availableDeposit` is
        // the balance of depositable tokens in an account's wallet.
        FullSavvyPosition[] availableDeposit;
        // The balance and value of the available credit for each debt token.
        FullSavvyPosition[] availableCredit;
        // The balance and value of the outstanding debt for an account.
        // @dev This is different than `debtTokens`. This is how
        // much an account owes SavvyPositionManager. The debt token
        // is an arbitrary ERC20 that has no bearing on outstanding debt.
        FullDebtInfo[] outstandingDebt;
    }

    /// @notice All the information required by the Pools page.
    struct PoolsPageInfo {
        // Info for all the Savvy pools.
        FullPoolInfo[] pools;
        // The balance and value for debt tokens in the account's
        // wallet (e.g. svUSD, svAVAX, etc).
        FullSavvyPosition[] debtTokens;
        // The balance and value of each token that a wallet can deposit into Savvy.
        // @dev This is different than `depositedTokens`. `depositedTokens` are
        // tokens already deposited into Savvy where as `availableDeposit` is
        // the balance of depositable tokens in an account's wallet.
        FullSavvyPosition[] availableDeposit;
        // The balance and value of the available credit for each debt token.
        FullSavvyPosition[] availableCredit;
        // The balance and value of the outstanding debt for an account.
        // @dev This is different than `debtTokens`. This is how
        // much an account owes SavvyPositionManager. The debt token
        // is an arbitrary ERC20 that has no bearing on outstanding debt.
        FullDebtInfo[] outstandingDebt;
    }

    /// @notice All the information required by the MySVY page.
    struct MySVYPageInfo {
        // Balance of SVY.
        uint256 svyBalance;
        // Balance of staked SVY.
        uint256 stakedSVYBalance;
        // Amount of claimable SVY.
        uint256 claimableSVY;
        // The per second earn rate of SVY.
        uint256 svyEarnRatePerSec;
        // Balance of veSVY.
        uint256 veSVYBalance;
        // Amount of claimable veSVY.
        uint256 claimableVeSVY;
        // The per second earn rate of veSVY.
        uint256 veSVYEarnRatePerSec;
        // The maximum earnable veSVY.
        uint256 maxVeSvyEarnable;
    }

    /// @notice Information for a single savvy swap.
    struct SwapInfo {
        // Address of the SavvySwap.
        address savvySwap;
        // Address of the deposit token.
        address depositToken;
        // Address of the token that is generated by the swap.
        address swapTargetToken;
        // The amount of tokens you can deposit into SavvySwap.
        uint256 availableDepositAmount;
        // The amount of DepositToken you've deposited into SavvySwap.
        uint256 depositedAmount;
        // The amount of SwapTargetToken that has been swapps and can be claimed.
        uint256 claimableAmount;
    }

    /// @notice All the information required by the MySVY page.
    struct SwapPageInfo {
        SwapInfo[] swapInfos;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./ISavvyInfoAggregatorStructs.sol";

interface ISavvyOverview {
    /// @notice Return total debt amount calculated in USD.
    /// @return Total debt amount calculated in USD.
    function getTotalDebtAmount() external view returns (int256);

    /// @notice Return total deposited amount calculated in USD.
    /// @return Total deposited amount calculated in USD.
    function getTotalDepositedAmount() external view returns (uint256);

    /// @notice Return total value locked (TVL) calculated in USD.
    /// @return Total total deposited amount plus SVY staked in veSVY in USD.
    function getTotalValueLocked() external view returns (uint256);

    /// @notice Get total SVY staked in veSVY.
    /// @return Total amount of SVY staked in veSVY.
    function getTotalSVYStaked() external view returns (uint256);

    /// @notice Get total SVY staked in veSVY in USD.
    /// @return The USD value of SVY staked in veSVY.
    function getTotalSVYStakedUSD() external view returns (uint256);

    /// @notice Get total available credit.
    /// @return Total amount of available credit calculated in USD.
    function getAvailableCredit() external view returns (int256);

    /// @notice Get all token price that added to Savvy DeFi
    /// @return Token price informations.
    function getAllTokenPrice()
        external
        view
        returns (ISavvyInfoAggregatorStructs.TokenPriceData[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISavvyPool {
    /// @notice Get user’s deposit in a pool.
    /// @param user The address of a user.
    /// @param poolAddr The address of beefy a pool.
    /// @return Returns deposited amount in a pool.
    function getPoolDeposited(
        address user,
        address poolAddr
    ) external view returns (uint256);

    /// @notice Get total deposited by Savvy in pool vs total capped amount for pool
    /// @param poolAddr The address of beefy a pool.
    /// @param savvyPositionManager The address of SavvyPositionManager.
    /// @return total deposited by Savvy in pool, total capped amount for pool
    function getPoolUtilization(
        address poolAddr,
        address savvyPositionManager
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./ISavvyInfoAggregatorStructs.sol";

interface ISavvyPositions is ISavvyInfoAggregatorStructs {
    /// @notice Total balance of each token type in user’s wallet
    /// @param user_ The address of a user.
    /// @return Infos for each pool, each token.
    function getAvailableDepositTokenAmount(
        address user_
    ) external view returns (SavvyPosition[] memory);

    /// @notice Total deposited into each pool of each token type for user.
    /// @param user_ The address of a user.
    /// @return Infos for each pool, each token.
    function getTotalDepositedTokenAmount(
        address user_
    ) external view returns (SavvyPosition[] memory);

    /// @notice Total debt borrowed of each pool of each token type for user.
    /// @param user_ The address of a user.
    /// @return Infos for each pool, each token.
    function getTotalDebtTokenAmount(
        address user_
    ) external view returns (DebtInfo[] memory);

    /// @notice Up to 50% of deposit available to borrow as debt is reduced
    /// @notice  over time of each pool of each token type for user.
    /// @param user_ The address of a user.
    /// @return Infos for each pool, each token.
    function getAvailableCreditToken(
        address user_
    ) external view returns (DebtInfo[] memory);

    /// @notice Get the borrowable amount per SavvyPositionManager.
    /// @param user_ The address of a user.
    /// @return borrowableAmounts The borrowable amounts per SavvyPositionManager.
    function getBorrowableAmount(
        address user_
    ) external view returns (SavvyPosition[] memory);

    /// @notice Get the withdrawable amount per SavvyPositionManager.
    /// @param user_ The address of a user.
    /// @return The withdrawable amounts per SavvyPositionManager per YieldToken.
    function getWithdrawableAmount(
        address user_
    ) external view returns (SavvyWithdrawInfo[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISavvyUserBalance {
    /// @notice User’s SVY amount in wallet.
    /// @param user_ The address of a user.
    /// @return Amount of user's SVY balance.
    function getUserSVYBalance(address user_) external view returns (uint256);

    /// @notice User’s SVY amount staked in veSVY contract.
    /// @param user_ The address of a user.
    /// @return Amount of user staked in veSVY.
    function getUserStakedSVYAmount(
        address user_
    ) external view returns (uint256);

    /// @notice User’s veSVY amount in wallet.
    /// @param user_ The address of a user.
    /// @return Amount of user's veSVY balance.
    function getUserVeSVYBalance(address user_) external view returns (uint256);

    /// @notice User’s claimable veSVY amount in the veSVY contract.
    /// @param user_ The address of a user.
    /// @return Amount of user's claimable veSVY.
    function getUserClaimableVeSVYAmount(
        address user_
    ) external view returns (uint256);

    /// @notice User’s claimable SVY amount in the SavvyBooster contract.
    /// @param user_ The address of a user.
    /// @return Amount of user's claimable SVY.
    function getUserClaimableSVYAmount(
        address user_
    ) external view returns (uint256);

    /// @notice SVY USD price.
    /// @dev This function returns token price calculated by 1e18.
    /// @return SVY USD price.
    function getSVYPrice() external view returns (uint256);

    /// @notice User’s SVY earn rate in USD / user’s total deposit in USD
    /// @param user_ The address of a user.
    /// @return Amount of svy earn rate.
    function getSVYEarnRate(address user_) external view returns (uint256);

    /// @notice User’s SVY earn rate in USD / user’s total deposit.
    /// @param user_ The address of a user.
    /// @return User’s SVY earn rate in USD / user’s total deposit.
    function getSVYAPY(address user_) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISavvyUserPortfolio {
    /// @notice Return total amount of user deposited calculated by USD.
    /// @param user_ The address of user to get total deposited amount.
    /// @return The amount of total deposited calculated by USD.
    function getUserDepositedAmount(
        address user_
    ) external view returns (uint256);

    /// @notice Get total available credit of a specific user.
    /// @dev Calculated as [total deposit] / [minimumCollateralization] - [current balance]
    /// @return Total amount of available credit of a specific user, calculated by USD.
    function getUserAvailableCredit(
        address user_
    ) external view returns (int256);

    /// @notice Return total debt amount calculated by USD.
    /// @param user_ The address of user to get total deposited amount.
    /// @return Total debt amount calculated by USD.
    function getUserDebtAmount(address user_) external view returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./ISavvyPositionManager.sol";

/// @title  ISavvyBooster
/// @author Savvy DeFi
interface ISavvyBooster {
    /// @dev The struct to show each pool Info.
    /// @dev Pool Info represents each emission supply pool.
    struct PoolInfo {
        /// @dev The amount of svy emissions remaining for this pool.
        uint256 remainingEmissions;
        /// @dev [emission supply amount] / [emission supplying duration].
        uint256 emissionRatio;
        /// @dev Duration timestamp between (this supplied time) - (last supplied time).
        uint256 duration;
        /// @dev Supplied timestamp.
        uint256 startTime;
        /// @dev total debt in Savvy protocol.
        uint256 totalDebtBalance;
        /// @dev total veSVY in Savvy protocol.
        uint256 totalVeSvyBalance;
    }

    /// @dev The struct to represent user info.
    struct UserInfo {
        /// @dev Amount that you can claim.
        /// @dev It's real * 1e18.
        uint256 pendingRewards;
        /// @dev The timestamp that a msterSavvy updated lastly.
        uint256 lastUpdateTime;
        /// @dev The last pool when the user info was updated.
        uint256 lastUpdatePool;
        /// @dev User's last debt bablance.
        uint256 debtBalance;
        /// @dev User's last veSVY balance.
        uint256 veSvyBalance;
    }

    /// @notice Set savvyPositionManager address.
    /// @dev Only owner can call this function.
    /// @param savvyPositionManagers The address list of new savvyPositionManager.
    function addSavvyPositionManagers(
        ISavvyPositionManager[] calldata savvyPositionManagers
    ) external;

    /// @notice Add new pool to deposit svy emissions.
    /// @dev Only owner can call this function.
    /// @param amount Amount of svy emissions.
    /// @param duration Duration of emission deposit.
    function addPool(uint256 amount, uint256 duration) external;

    /// @notice Remove a future queued pool and withdraw svy emissions.
    /// @dev Only owner can call this function.
    /// @dev This function can be called only when the pool is not started yet.
    /// @param period The period of pool to remove.
    function removePool(uint256 period) external;

    /// @notice User claims boosted SVY rewards.
    /// @return Amount of rewards claimed.
    function claimSvyRewards() external returns (uint256);

    /// @notice Update pending rewards when user's debt balance changes.
    /// @dev Only savvyPositionManager calls this function when user's debt balance changes.
    /// @param user The address of user that wants to get rewards.
    /// @param userDebtSavvy User's debt balance in USD of savvyPositionManager.
    /// @param totalDebtSavvy Total debt balance in USD of savvyPositionManager.
    function updatePendingRewardsWithDebt(
        address user,
        uint256 userDebtSavvy,
        uint256 totalDebtSavvy
    ) external;

    /// @notice Update pending rewards when user's veSvy balance changes.
    /// @dev VeSvy contract call this function when user's veSvy balance is updated.
    /// @param user The address of a user.
    /// @param userVeSvyBalance User's veSVY balance.
    /// @param totalVeSvyBalance Total veSVY balance.
    function updatePendingRewardsWithVeSvy(
        address user,
        uint256 userVeSvyBalance,
        uint256 totalVeSvyBalance
    ) external;

    /// @notice Get the claimable rewards amount accrued for user.
    /// @param user The address of a user.
    /// @return pending rewards amount of a user.
    function getClaimableRewards(address user) external view returns (uint256);

    /// @notice Get current svy earning rate of a user.
    /// @param user The address of a user.
    /// @return amount of current svy earning reate.
    function getSvyEarnRate(address user) external view returns (uint256);

    /// @notice withdraw svyToken to owner.
    function withdraw() external;

    /// @notice deposit svyToken into new pool.
    event Deposit(uint256 amount, uint256 poolId);

    /// @notice withdraw svyToken to owner.
    event Withdraw(uint256 amount);

    /// @notice claim svyToken rewards.
    /// @dev If pendingAmount is greater than 0, this is a warning concern.
    event Claim(
        address indexed user,
        uint256 rewardAmount,
        uint256 pendingAmount
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./savvy/ISavvyActions.sol";
import "./savvy/ISavvyAdminActions.sol";
import "./savvy/ISavvyErrors.sol";
import "./savvy/ISavvyImmutables.sol";
import "./savvy/ISavvyEvents.sol";
import "./savvy/ISavvyState.sol";

/// @title  ISavvyPositionManager
/// @author Savvy DeFi
interface ISavvyPositionManager is
    ISavvyActions,
    ISavvyAdminActions,
    ISavvyErrors,
    ISavvyImmutables,
    ISavvyEvents,
    ISavvyState
{

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISavvyPriceFeed {
    /// @notice Add priceFee by baseToken.
    /// @dev Only owner can call this function.
    /// @param baseToken The address of base token.
    /// @param priceFeed The address of priceFeed of base token.
    function setPriceFeed(address baseToken, address priceFeed) external;

    /// @notice Set priceFeed for SVY/AVAX
    /// @param newFeed The address of new priceFeed.
    function updateSvyPriceFeed(address newFeed) external;

    /// @notice Get token price from chainlink
    /// @param baseToken The address of base token.
    /// @param amount The amount of base token.
    /// @return USD amount of the base token.
    function getBaseTokenPrice(
        address baseToken,
        uint256 amount
    ) external view returns (uint256);

    /// @notice Get USD price for SVY/AVAX
    /// @dev Explain to a developer any extra details
    /// @return Return USD price for SVY/AVAX
    function getSavvyTokenPrice() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title  ISavvyToken
/// @author Savvy DeFi
interface ISavvyToken is IERC20 {
    /// @notice Gets the total amount of minted tokens for an account.
    ///
    /// @param account The address of the account.
    ///
    /// @return The total minted.
    function hasMinted(address account) external view returns (uint256);

    /// @notice Lowers the number of tokens which the `msg.sender` has minted.
    ///
    /// This reverts if the `msg.sender` is not allowlisted.
    ///
    /// @param amount The amount to lower the minted amount by.
    function lowerHasMinted(uint256 amount) external;

    /// @notice Sets the mint allowance for a given account'
    ///
    /// This reverts if the `msg.sender` is not admin
    ///
    /// @param toSetCeiling The account whos allowance to update
    /// @param ceiling      The amount of tokens allowed to mint
    function setCeiling(address toSetCeiling, uint256 ceiling) external;

    /// @notice Updates the state of an address in the allowlist map
    ///
    /// This reverts if msg.sender is not admin
    ///
    /// @param toAllowlist the address whos state is being updated
    /// @param state the boolean state of the allowlist
    function setAllowlist(address toAllowlist, bool state) external;

    function mint(address recipient, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ITokenAdapter
/// @author Savvy DeFi
interface ITokenAdapter {

    event AllowlistUpdated(address[] allowlistAddresses, bool status);

    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the base token that the yield token wraps.
    ///
    /// @return The address of the base token.
    function baseToken() external view returns (address);

    /// @notice Gets the number of base tokens that a single whole yield token is redeemable for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` base tokens into the yield token.
    ///
    /// @param amount           The amount of the base token to wrap.
    /// @param recipient        The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(
        uint256 amount,
        address recipient
    ) external returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the base token.
    ///
    /// @param amount           The amount of yield-tokens to redeem.
    /// @param recipient        The recipient of the resulting base tokens.
    ///
    /// @return amountBaseTokens The amount of base tokens unwrapped to `recipient`.
    function unwrap(
        uint256 amount,
        address recipient
    ) external returns (uint256 amountBaseTokens);

    /// @notice Add address of SavvyPositionManager to allowlist
    /// @dev Only owner can call this function/
    /// @param allowlistAddresses The addresses of SavvyPositionManager/YieldStrategyManager.
    /// @param status Status for allowlist. true/false = on/off.
    function addAllowlist(
        address[] memory allowlistAddresses,
        bool status
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IVeERC20.sol";

/**
 * @dev Interface of the VeSvy
 */
interface IVeSvy is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function stake(uint256 _amount) external;

    function stakeFor(address _recipient, uint256 _amount) external;

    function claimable(address _addr) external view returns (uint256);

    function claim() external;

    function unstake(uint256 _amount) external;

    function getStakedSvy(address _addr) external view returns (uint256);

    function getVotes(address _account) external view returns (uint256);

    function getVeSVYEarnRatePerSec(
        address _addr
    ) external view returns (uint256);

    function getMaxVeSVYEarnable(address _addr) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./savvy/ISavvyTokenParams.sol";
import "./savvy/ISavvyErrors.sol";
import "./savvy/ISavvyEvents.sol";
import "./savvy/ISavvyAdminActions.sol";
import "./savvy/IYieldStrategyManagerStates.sol";
import "./savvy/IYieldStrategyManagerActions.sol";
import "../libraries/Limiters.sol";

/// @title  IYieldStrategyManager
/// @author Savvy DeFi
interface IYieldStrategyManager is
    ISavvyTokenParams,
    ISavvyErrors,
    ISavvyEvents,
    IYieldStrategyManagerStates,
    IYieldStrategyManagerActions
{

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ISavvyActions
/// @author Savvy DeFi
///
/// @notice Specifies user actions.
interface ISavvyActions {
    /// @notice Approve `spender` to borrow `amount` debt tokens.
    ///
    /// **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @param spender The address that will be approved to borrow.
    /// @param amount  The amount of tokens that `spender` will be allowed to borrow.
    function approveBorrow(address spender, uint256 amount) external;

    /// @notice Approve `spender` to withdraw `amount` shares of `yieldToken`.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @param spender    The address that will be approved to withdraw.
    /// @param yieldToken The address of the yield token that `spender` will be allowed to withdraw.
    /// @param shares     The amount of shares that `spender` will be allowed to withdraw.
    function approveWithdraw(
        address spender,
        address yieldToken,
        uint256 shares
    ) external;

    /// @notice Synchronizes the state of the account owned by `owner`.
    ///
    /// @param owner The owner of the account to synchronize.
    function syncAccount(address owner) external;

    /// @notice Deposit an base token into the account of `recipient` as `yieldToken`.
    ///
    /// @notice An approval must be set for the base token of `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** When depositing, the `SavvyPositionManager` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **baseToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amount = 50000;
    /// @notice SavvyPositionManager(savvyAddress).depositBaseToken(mooAaveDAI, amount, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to wrap the base tokens into.
    /// @param amount           The amount of the base token to deposit.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be deposited to `recipient`.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositBaseToken(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesIssued);

    /// @notice Deposit a yield token into a user's account.
    ///
    /// @notice An approval must be set for `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` base token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **_NOTE:_** When depositing, the `SavvyPositionManager` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **yieldToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amount = 50000;
    /// @notice IERC20(mooAaveDAI).approve(savvyAddress, amount);
    /// @notice SavvyPositionManager(savvyAddress).depositYieldToken(mooAaveDAI, amount, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The yield-token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The owner of the account that will receive the resulting shares.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositYieldToken(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 sharesIssued);

    /// @notice Withdraw amount yield tokens to recipient The number of yield tokens withdrawn to `recipient` will depend on the value of shares for that yield token at the time of the call.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getYieldTokensPerShare(mooAaveDAI);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice SavvyPositionManager(savvyAddress).withdrawYieldToken(mooAaveDAI, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawYieldToken(
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares from the account of `owner`
    ///
    /// @notice `owner` must have an withdrawal allowance which is greater than `amount` for this call to succeed.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getYieldTokensPerShare(mooAaveDAI);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice SavvyPositionManager(savvyAddress).withdrawFrom(msg.sender, mooAaveDAI, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param owner      The address of the account owner to withdraw from.
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawYieldTokenFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw base tokens to `recipient` by burning `share` shares and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** The caller of `withdrawYieldTokenFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getBaseTokensPerShare(mooAaveDAI);
    /// @notice uint256 amountBaseTokens = 5000;
    /// @notice SavvyPositionManager(savvyAddress).withdrawUnderlying(mooAaveDAI, amountBaseTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of base tokens that were withdrawn to `recipient`.
    function withdrawBaseToken(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw base tokens to `recipient` by burning `share` shares from the account of `owner` and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** The caller of `withdrawYieldTokenFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 pps = SavvyPositionManager(savvyAddress).getBaseTokensPerShare(mooAaveDAI);
    /// @notice uint256 amtBaseTokens = 5000 * 10**mooAaveDAI.decimals();
    /// @notice SavvyPositionManager(savvyAddress).withdrawUnderlying(msg.sender, mooAaveDAI, amtBaseTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param owner            The address of the account owner to withdraw from.
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of base tokens that were withdrawn to `recipient`.
    function withdrawBaseTokenFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice borrow `amount` debt tokens to recipient.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Borrow} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice SavvyPositionManager(savvyAddress).borrowCredit(amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to borrow.
    /// @param recipient The address of the recipient.
    function borrowCredit(uint256 amount, address recipient) external;

    /// @notice Borrow `amount` debt tokens from the account owned by `owner` to `recipient`.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Borrow} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    /// @notice **_NOTE:_** The caller of `borrowFrom()` must have **borrowAllowance()** to borrow debt from the `Account` controlled by **owner** for at least the amount of **yieldTokens** that **shares** will be converted to.  This can be done via the `approveBorrow()` or `permitBorrow()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice SavvyPositionManager(savvyAddress).borrowFrom(msg.sender, amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param owner     The address of the owner of the account to borrow from.
    /// @param amount    The amount of tokens to borrow.
    /// @param recipient The address of the recipient.
    function borrowCreditFrom(
        address owner,
        uint256 amount,
        address recipient
    ) external;

    /// @notice Burn `amount` debt tokens to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must have non-zero debt or this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Burn} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtBurn = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithDebtToken(amtBurn, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to burn.
    /// @param recipient The address of the recipient.
    ///
    /// @return amountBurned The amount of tokens that were burned.
    function repayWithDebtToken(
        uint256 amount,
        address recipient
    ) external returns (uint256 amountBurned);

    /// @notice Repay `amount` debt using `baseToken` to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `baseToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `amount` must be less than or equal to the current available repay limit or this call will revert with a {ReplayLimitExceeded} error.
    ///
    /// @notice Emits a {Repay} event.
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address dai = 0x6b175474e89094c44da98b954eedeac495271d0f;
    /// @notice uint256 amtRepay = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithBaseToken(dai, amtRepay, msg.sender);
    /// @notice ```
    ///
    /// @param baseToken The address of the base token to repay.
    /// @param amount          The amount of the base token to repay.
    /// @param recipient       The address of the recipient which will receive credit.
    ///
    /// @return amountRepaid The amount of tokens that were repaid.
    function repayWithBaseToken(
        address baseToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 amountRepaid);

    /// @notice
    ///
    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    ///
    /// @notice `shares` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` base token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    /// @notice `amount` must be less than or equal to the current available repayWithCollateral limit or this call will revert with a {RepayWithCollateralLimitExceeded} error.
    ///
    /// @notice Emits a {RepayWithCollateral} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000 * 10**mooAaveDAI.decimals();
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(mooAaveDAI, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to repayWithCollateral.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be repaidWithCollateral.
    ///
    /// @return sharesRepaidWithCollateral The amount of shares that were repaidWithCollateral.
    function repayWithCollateral(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesRepaidWithCollateral);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(dai, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    function donate(address yieldToken, uint256 amount) external;

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    function harvest(address yieldToken, uint256 minimumAmountOut) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ISavvyAdminActions
/// @author Savvy DeFi
///
/// @notice Specifies admin and/or sentinel actions.
/// @notice Used by SavvyPositionManager
interface ISavvyAdminActions {
    /// @notice Contract initialization parameters.
    struct InitializationParams {
        // The initial admin account.
        address admin;
        // The ERC20 token used to represent debt.
        address debtToken;
        // The initial savvySage or savvySage buffer.
        address savvySage;
        // The address of giving rewards to users.
        address svyBooster;
        // The address of SavvyPriceFeed contract.
        address svyPriceFeed;
        // The redlist is active.
        bool redlistActive;
        // The address of Redlist contract.
        address savvyRedlist;
        // The address of YieldStrategyManager contract.
        address yieldStrategyManager;
        // The minimum collateralization ratio that an account must maintain.
        uint256 minimumCollateralization;
        // The percentage fee taken from each harvest measured in units of basis points.
        uint256 protocolFee;
        // The address that receives protocol fees.
        address protocolFeeReceiver;
        // A limit used to prevent administrators from making borrowing functionality inoperable.
        uint256 borrowingLimitMinimum;
        // The maximum number of tokens that can be borrowed per period of time.
        uint256 borrowingLimitMaximum;
        // The number of blocks that it takes for the borrowing limit to be refreshed.
        uint256 borrowingLimitBlocks;
        // The address of the allowlist.
        address allowlist;
        // Base base token to calculate token price.
        address baseToken;
        /// The address of WrapTokenGateway contract.
        address wrapTokenGateway;
    }

    /// @notice Configuration parameters for an base token.
    struct BaseTokenConfig {
        // A limit used to prevent administrators from making repayment functionality inoperable.
        uint256 repayLimitMinimum;
        // The maximum number of base tokens that can be repaid per period of time.
        uint256 repayLimitMaximum;
        // The number of blocks that it takes for the repayment limit to be refreshed.
        uint256 repayLimitBlocks;
        // A limit used to prevent administrators from making repayWithCollateral functionality inoperable.
        uint256 repayWithCollateralLimitMinimum;
        // The maximum number of base tokens that can be repaidWithCollateral per period of time.
        uint256 repayWithCollateralLimitMaximum;
        // The number of blocks that it takes for the repayWithCollateral limit to be refreshed.
        uint256 repayWithCollateralLimitBlocks;
    }

    /// @notice Configuration parameters of a yield token.
    struct YieldTokenConfig {
        // The adapter used by the system to interop with the token.
        address adapter;
        // The maximum percent loss in expected value that can occur before certain actions are disabled.
        // Measured in units of basis points.
        uint256 maximumLoss;
        // The maximum value that can be held by the system before certain actions are disabled.
        //  measured in the base token.
        uint256 maximumExpectedValue;
        // The number of blocks that credit will be distributed over to depositors.
        uint256 creditUnlockBlocks;
    }

    /// @notice Initialize the contract.
    ///
    /// @notice `params.protocolFee` must be in range or this call will with an {IllegalArgument} error.
    /// @notice The borrowing growth limiter parameters must be valid or this will revert with an {IllegalArgument} error. For more information, see the {Limiters} library.
    ///
    /// @notice Emits an {AdminUpdated} event.
    /// @notice Emits a {SavvySageUpdated} event.
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    /// @notice Emits a {ProtocolFeeUpdated} event.
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param params The contract initialization parameters.
    function initialize(InitializationParams calldata params) external;

    /// @notice Sets the pending administrator.
    ///
    /// @notice `msg.sender` must be the pending admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {PendingAdminUpdated} event.
    ///
    /// @dev This is the first step in the two-step process of setting a new administrator. After this function is called, the pending administrator will then need to call {acceptAdmin} to complete the process.
    ///
    /// @param value the address to set the pending admin to.
    function setPendingAdmin(address value) external;

    /// @notice Allows for `msg.sender` to accepts the role of administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice The current pending administrator must be non-zero or this call will revert with an {IllegalState} error.
    ///
    /// @dev This is the second step in the two-step process of setting a new administrator. After this function is successfully called, this pending administrator will be reset and the new administrator will be set.
    ///
    /// @notice Emits a {AdminUpdated} event.
    /// @notice Emits a {PendingAdminUpdated} event.
    function acceptAdmin() external;

    /// @notice Sets an address as a sentinel.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param sentinel The address to set or unset as a sentinel.
    /// @param flag     A flag indicating of the address should be set or unset as a sentinel.
    function setSentinel(address sentinel, bool flag) external;

    /// @notice Sets an address as a keeper.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param keeper The address to set or unset as a keeper.
    /// @param flag   A flag indicating of the address should be set or unset as a keeper.
    function setKeeper(address keeper, bool flag) external;

    /// @notice Adds an base token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param baseToken The address of the base token to add.
    /// @param config          The initial base token configuration.
    function addBaseToken(
        address baseToken,
        BaseTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {AddYieldToken} event.
    /// @notice Emits a {TokenAdapterUpdated} event.
    /// @notice Emits a {MaximumLossUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(
        address yieldToken,
        YieldTokenConfig calldata config
    ) external;

    /// @notice Sets an base token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits an {BaseTokenEnabled} event.
    ///
    /// @param baseToken The address of the base token to enable or disable.
    /// @param enabled         If the base token should be enabled or disabled.
    function setBaseTokenEnabled(address baseToken, bool enabled) external;

    /// @notice Sets a yield token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {YieldTokenEnabled} event.
    ///
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the base token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Configures the the repay limit of `baseToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {ReplayLimitUpdated} event.
    ///
    /// @param baseToken The address of the base token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the repayWithCollateral limiter of `baseToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `baseToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {RepayWithCollateralLimitUpdated} event.
    ///
    /// @param baseToken The address of the base token to configure the repayWithCollateral limit of.
    /// @param maximum         The maximum repayWithCollateral limit.
    /// @param blocks          The number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Set the address of the savvySage.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {SavvySageUpdated} event.
    ///
    /// @param savvySage The address of the savvySage.
    function setSavvySage(address savvySage) external;

    /// @notice Set the minimum collateralization ratio.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    ///
    /// @param value The new minimum collateralization ratio.
    function setMinimumCollateralization(uint256 value) external;

    /// @notice Sets the fee that the protocol will take from harvests.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be in range or this call will with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeUpdated} event.
    ///
    /// @param value The value to set the protocol fee to measured in basis points.
    function setProtocolFee(uint256 value) external;

    /// @notice Sets the address which will receive protocol fees.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    ///
    /// @param value The address to set the protocol fee receiver to.
    function setProtocolFeeReceiver(address value) external;

    /// @notice Configures the borrowing limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param maximum The maximum borrowing limit.
    /// @param blocks  The number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    function configureBorrowingLimit(uint256 maximum, uint256 blocks) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    ///
    /// @notice Emits a {CreditUnlockRateUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external;

    /// @notice Sets the token adapter of a yield token.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The token that `adapter` supports must be `yieldToken` or this call will revert with a {IllegalState} error.
    ///
    /// @notice Emits a {TokenAdapterUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its base token.
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev There are two types of loss of value for yield bearing tokens: temporary or permanent. The system will automatically restrict actions which are sensitive to both forms of loss when detected. For example, deposits must be restricted when an excessive loss is encountered to prevent users from having their collateral harvested from them. While the user would receive credit, which then could be exchanged for value equal to the collateral that was harvested from them, it is seen as a negative user experience because the value of their collateral should have been higher than what was originally recorded when they made their deposit.
    ///
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of base tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external;

    /// @notice Sweep all of 'rewardtoken' from the savvy into the admin.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `rewardToken` must not be a yield or base token or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param rewardToken The address of the reward token to snap.
    /// @param amount The amount of 'rewardToken' to sweep to the admin.
    function sweepTokens(address rewardToken, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ISavvyErrors
/// @author Savvy DeFi
///
/// @notice Specifies errors.
interface ISavvyErrors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the base token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the base token.
    error ExpectedValueExceeded(
        address yieldToken,
        uint256 expectedValue,
        uint256 maximumExpectedValue
    );

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a borrowing operation failed because the borrowing limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be borrowed.
    /// @param available The amount of debt tokens which are available to borrow.
    error BorrowingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaid.
    /// @param available       The amount of base tokens that are available to be repaid.
    error RepayLimitExceeded(
        address baseToken,
        uint256 amount,
        uint256 available
    );

    /// @notice An error which is used to indicate that an repay operation failed because the repayWithCollateral limit for an base token has been exceeded.
    ///
    /// @param baseToken The address of the base token.
    /// @param amount          The amount of base tokens that were requested to be repaidWithCollateral.
    /// @param available       The amount of base tokens that are available to be repaidWithCollateral.
    error RepayWithCollateralLimitExceeded(
        address baseToken,
        uint256 amount,
        uint256 available
    );

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);
}

library Errors {
    // TokenUtils
    string internal constant ERC20CALLFAILED_EXPECTDECIMALS = "SVY101";
    string internal constant ERC20CALLFAILED_SAFEBALANCEOF = "SVY102";
    string internal constant ERC20CALLFAILED_SAFETRANSFER = "SVY103";
    string internal constant ERC20CALLFAILED_SAFEAPPROVE = "SVY104";
    string internal constant ERC20CALLFAILED_SAFETRANSFERFROM = "SVY105";
    string internal constant ERC20CALLFAILED_SAFEMINT = "SVY106";
    string internal constant ERC20CALLFAILED_SAFEBURN = "SVY107";
    string internal constant ERC20CALLFAILED_SAFEBURNFROM = "SVY108";

    // SavvyPositionManager
    string internal constant SPM_FEE_EXCEEDS_BPS = "SVY201"; // protocol fee exceeds BPS
    string internal constant SPM_ZERO_ADMIN_ADDRESS = "SVY202"; // zero pending admin address
    string internal constant SPM_UNAUTHORIZED_PENDING_ADMIN = "SVY203"; // Unauthorized pending admin
    string internal constant SPM_ZERO_SAVVY_SAGE_ADDRESS = "SVY204"; // zero savvy sage address
    string internal constant SPM_ZERO_PROTOCOL_FEE_RECEIVER_ADDRESS = "SVY205"; // zero protocol fee receiver address
    string internal constant SPM_ZERO_RECIPIENT_ADDRESS = "SVY206"; // zero recipient address
    string internal constant SPM_ZERO_TOKEN_AMOUNT = "SVY207"; // zero token amount
    string internal constant SPM_INVALID_DEBT_AMOUNT = "SVY208"; // invalid debt amount
    string internal constant SPM_ZERO_COLLATERAL_AMOUNT = "SVY209"; // zero collateral amount
    string internal constant SPM_INVALID_UNREALIZED_DEBT_AMOUNT = "SVY210"; // invalid unrealized debt amount
    string internal constant SPM_UNAUTHORIZED_ADMIN = "SVY211"; // Unauthorized admin
    string internal constant SPM_UNAUTHORIZED_REDLIST = "SVY212"; // Unauthorized redlist
    string internal constant SPM_UNAUTHORIZED_SENTINEL_OR_ADMIN = "SVY213"; // Unauthorized sentinel or admin
    string internal constant SPM_UNAUTHORIZED_KEEPER = "SVY214"; // Unauthorized keeper
    string internal constant SPM_BORROWING_LIMIT_EXCEEDED = "SVY215"; // Borrowing limit exceeded
    string internal constant SPM_INVALID_TOKEN_AMOUNT = "SVY216"; // invalid token amount
    string internal constant SPM_EXPECTED_VALUE_EXCEEDED = "SVY217"; // Expected Value exceeded
    string internal constant SPM_SLIPPAGE_EXCEEDED = "SVY218"; // Slippage exceeded
    string internal constant SPM_UNDERCOLLATERALIZED = "SVY219"; // Undercollateralized
    string internal constant SPM_UNAUTHORIZED_NOT_ALLOWLISTED = "SVY220"; // Unathorized, not allowlisted
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ISavvyEvents
/// @author Savvy DeFi
interface ISavvyEvents {
    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The address of the pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the administrator is updated.
    ///
    /// @param admin The address of the administrator.
    event AdminUpdated(address admin);

    /// @notice Emitted when an address is set or unset as a sentinel.
    ///
    /// @param sentinel The address of the sentinel.
    /// @param flag     A flag indicating if `sentinel` was set or unset as a sentinel.
    event SentinelSet(address sentinel, bool flag);

    /// @notice Emitted when an address is set or unset as a keeper.
    ///
    /// @param sentinel The address of the keeper.
    /// @param flag     A flag indicating if `keeper` was set or unset as a sentinel.
    event KeeperSet(address sentinel, bool flag);

    /// @notice Emitted when an base token is added.
    ///
    /// @param baseToken The address of the base token that was added.
    event AddBaseToken(address indexed baseToken);

    /// @notice Emitted when a yield token is added.
    ///
    /// @param yieldToken The address of the yield token that was added.
    event AddYieldToken(address indexed yieldToken);

    /// @notice Emitted when an base token is enabled or disabled.
    ///
    /// @param baseToken The address of the base token that was enabled or disabled.
    /// @param enabled         A flag indicating if the base token was enabled or disabled.
    event BaseTokenEnabled(address indexed baseToken, bool enabled);

    /// @notice Emitted when an yield token is enabled or disabled.
    ///
    /// @param yieldToken The address of the yield token that was enabled or disabled.
    /// @param enabled    A flag indicating if the yield token was enabled or disabled.
    event YieldTokenEnabled(address indexed yieldToken, bool enabled);

    /// @notice Emitted when the repay limit of an base token is updated.
    ///
    /// @param baseToken The address of the base token.
    /// @param maximum         The updated maximum repay limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    event RepayLimitUpdated(
        address indexed baseToken,
        uint256 maximum,
        uint256 blocks
    );

    /// @notice Emitted when the repayWithCollateral limit of an base token is updated.
    ///
    /// @param baseToken The address of the base token.
    /// @param maximum         The updated maximum repayWithCollateral limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    event RepayWithCollateralLimitUpdated(
        address indexed baseToken,
        uint256 maximum,
        uint256 blocks
    );

    /// @notice Emitted when the savvySage is updated.
    ///
    /// @param savvySage The updated address of the savvySage.
    event SavvySageUpdated(address savvySage);

    /// @notice Emitted when the minimum collateralization is updated.
    ///
    /// @param minimumCollateralization The updated minimum collateralization.
    event MinimumCollateralizationUpdated(uint256 minimumCollateralization);

    /// @notice Emitted when the protocol fee is updated.
    ///
    /// @param protocolFee The updated protocol fee.
    event ProtocolFeeUpdated(uint256 protocolFee);

    /// @notice Emitted when the protocol fee receiver is updated.
    ///
    /// @param protocolFeeReceiver The updated address of the protocol fee receiver.
    event ProtocolFeeReceiverUpdated(address protocolFeeReceiver);

    /// @notice Emitted when the borrowing limit is updated.
    ///
    /// @param maximum The updated maximum borrowing limit.
    /// @param blocks  The updated number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    event BorrowingLimitUpdated(uint256 maximum, uint256 blocks);

    /// @notice Emitted when the credit unlock rate is updated.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param blocks     The number of blocks that distributed credit will unlock over.
    event CreditUnlockRateUpdated(address yieldToken, uint256 blocks);

    /// @notice Emitted when the adapter of a yield token is updated.
    ///
    /// @param yieldToken   The address of the yield token.
    /// @param tokenAdapter The updated address of the token adapter.
    event TokenAdapterUpdated(address yieldToken, address tokenAdapter);

    /// @notice Emitted when the maximum expected value of a yield token is updated.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param maximumExpectedValue The updated maximum expected value.
    event MaximumExpectedValueUpdated(
        address indexed yieldToken,
        uint256 maximumExpectedValue
    );

    /// @notice Emitted when the maximum loss of a yield token is updated.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param maximumLoss The updated maximum loss.
    event MaximumLossUpdated(address indexed yieldToken, uint256 maximumLoss);

    /// @notice Emitted when the expected value of a yield token is snapped to its current value.
    ///
    /// @param yieldToken    The address of the yield token.
    /// @param expectedValue The updated expected value measured in the yield token's base token.
    event Snap(address indexed yieldToken, uint256 expectedValue);

    /// @notice Emitted when a the admin sweeps all of one reward token from the Savvy
    ///
    /// @param rewardToken The address of the reward token.
    /// @param amount      The amount of 'rewardToken' swept into the admin.
    event SweepTokens(address indexed rewardToken, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to borrow debt tokens on its behalf.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address which is being permitted to borrow tokens on the behalf of `owner`.
    /// @param amount  The amount of debt tokens that `spender` is allowed to borrow.
    event ApproveBorrow(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when `owner` grants `spender` the ability to withdraw `yieldToken` from its account.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address which is being permitted to borrow tokens on the behalf of `owner`.
    /// @param yieldToken The address of the yield token that `spender` is allowed to withdraw.
    /// @param amount     The amount of shares of `yieldToken` that `spender` is allowed to withdraw.
    event ApproveWithdraw(
        address indexed owner,
        address indexed spender,
        address indexed yieldToken,
        uint256 amount
    );

    /// @notice Emitted when a user deposits `amount of `yieldToken` to `recipient`.
    ///
    /// @notice This event does not imply that `sender` directly deposited yield tokens. It is possible that the
    ///         base tokens were wrapped.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param yieldToken   The address of the yield token that was deposited.
    /// @param amount       The amount of yield tokens that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event DepositYieldToken(
        address indexed sender,
        address indexed yieldToken,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when `shares` shares of `yieldToken` are burned to withdraw `yieldToken` from the account owned
    ///         by `owner` to `recipient`.
    ///
    /// @notice This event does not imply that `recipient` received yield tokens. It is possible that the yield tokens
    ///         were unwrapped.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token that was withdrawn.
    /// @param shares     The amount of shares that were burned.
    /// @param recipient  The address that received the withdrawn funds.
    event WithdrawYieldToken(
        address indexed owner,
        address indexed yieldToken,
        uint256 shares,
        address recipient
    );

    /// @notice Emitted when `amount` debt tokens are borrowed to `recipient` using the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount of tokens that were borrowed.
    /// @param recipient The recipient of the borrowed tokens.
    event Borrow(address indexed owner, uint256 amount, address recipient);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to `recipient`.
    ///
    /// @param sender    The address which is burning tokens.
    /// @param amount    The amount of tokens that were burned.
    /// @param recipient The address that received credit for the burned tokens.
    event RepayWithDebtToken(
        address indexed sender,
        uint256 amount,
        address recipient
    );

    /// @notice Emitted when `amount` of `baseToken` are repaid to grant credit to `recipient`.
    ///
    /// @param sender          The address which is repaying tokens.
    /// @param baseToken The address of the base token that was used to repay debt.
    /// @param amount          The amount of the base token that was used to repay debt.
    /// @param recipient       The address that received credit for the repaid tokens.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event RepayWithBaseToken(
        address indexed sender,
        address indexed baseToken,
        uint256 amount,
        address recipient,
        uint256 credit
    );

    /// @notice Emitted when `sender` repayWithCollateral `share` shares of `yieldToken`.
    ///
    /// @param owner           The address of the account owner repaying with collateral.
    /// @param yieldToken      The address of the yield token.
    /// @param baseToken The address of the base token.
    /// @param shares          The amount of the shares of `yieldToken` that were repaidWithCollateral.
    /// @param credit          The amount of debt that was paid-off to the account owned by owner.
    event RepayWithCollateral(
        address indexed owner,
        address indexed yieldToken,
        address indexed baseToken,
        uint256 shares,
        uint256 credit
    );

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to users who have deposited `yieldToken`.
    ///
    /// @param sender     The address which burned debt tokens.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of debt tokens which were burned.
    event Donate(
        address indexed sender,
        address indexed yieldToken,
        uint256 amount
    );

    /// @notice Emitted when `yieldToken` is harvested.
    ///
    /// @param yieldToken     The address of the yield token that was harvested.
    /// @param minimumAmountOut    The maximum amount of loss that is acceptable when unwrapping the base tokens into yield tokens, measured in basis points.
    /// @param totalHarvested The total amount of base tokens harvested.
    /// @param credit           The total amount of debt repaid to depositors of `yieldToken`.
    event Harvest(
        address indexed yieldToken,
        uint256 minimumAmountOut,
        uint256 totalHarvested,
        uint256 credit
    );

    /// @notice Emitted when the offset as baseToken exceeds to limit.
    ///
    /// @param yieldToken      The address of the yield token that was harvested.
    /// @param currentValue    Current value as baseToken.
    /// @param expectedValue   Limit offset value.
    event HarvestExceedsOffset(
        address indexed yieldToken,
        uint256 currentValue,
        uint256 expectedValue
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ISavvyImmutables
/// @author Savvy DeFi
interface ISavvyImmutables {
    /// @notice Returns the version of the savvy.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Returns the address of the debt token used by the system.
    ///
    /// @return The address of the debt token.
    function debtToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./ISavvyTokenParams.sol";
import "../IYieldStrategyManager.sol";
import "../../libraries/Sets.sol";

/// @title  ISavvyState
/// @author Savvy DeFi
interface ISavvyState is ISavvyTokenParams {
    /// @notice A user account.
    struct Account {
        // A signed value which represents the current amount of debt or credit that the account has accrued.
        // Positive values indicate debt, negative values indicate credit.
        int256 debt;
        // The share balances for each yield token.
        mapping(address => uint256) balances;
        // The last values recorded for accrued weights for each yield token.
        mapping(address => uint256) lastAccruedWeights;
        // The set of yield tokens that the account has deposited into the system.
        Sets.AddressSet depositedTokens;
        // The allowances for borrows.
        mapping(address => uint256) borrowAllowances;
        // The allowances for withdrawals.
        mapping(address => mapping(address => uint256)) withdrawAllowances;
        // The harvested base token amount per yield token.
        mapping(address => uint256) harvestedYield;
    }

    /// @notice Gets the address of the admin.
    ///
    /// @return admin The admin address.
    function admin() external view returns (address admin);

    /// @notice The total number of debt token.
    /// @return totalDebt Total debt amount.
    function totalDebt() external view returns (int256 totalDebt);

    /// @notice Gets the address of the pending administrator.
    ///
    /// @return pendingAdmin The pending administrator address.
    function pendingAdmin() external view returns (address pendingAdmin);

    /// @notice Gets if an address is a sentinel.
    ///
    /// @param sentinel The address to check.
    ///
    /// @return isSentinel If the address is a sentinel.
    function sentinels(
        address sentinel
    ) external view returns (bool isSentinel);

    /// @notice Gets if an address is a keeper.
    ///
    /// @param keeper The address to check.
    ///
    /// @return isKeeper If the address is a keeper
    function keepers(address keeper) external view returns (bool isKeeper);

    /// @notice Gets the address of the savvySage.
    ///
    /// @return savvySage The savvySage address.
    function savvySage() external view returns (address savvySage);

    /// @notice Gets the address of the svyBooster.
    ///
    /// @return svyBooster The svyBooster address.
    function svyBooster() external view returns (address svyBooster);

    /// @notice Gets the minimum collateralization.
    ///
    /// @notice Collateralization is determined by taking the total value of collateral that a user has deposited into their account and dividing it their debt.
    ///
    /// @dev The value returned is a 18 decimal fixed point integer.
    ///
    /// @return minimumCollateralization The minimum collateralization.
    function minimumCollateralization()
        external
        view
        returns (uint256 minimumCollateralization);

    /// @notice Gets the protocol fee.
    ///
    /// @return protocolFee The protocol fee.
    function protocolFee() external view returns (uint256 protocolFee);

    /// @notice Gets the protocol fee receiver.
    ///
    /// @return protocolFeeReceiver The protocol fee receiver.
    function protocolFeeReceiver()
        external
        view
        returns (address protocolFeeReceiver);

    /// @notice Gets the address of the allowlist contract.
    ///
    /// @return allowlist The address of the allowlist contract.
    function allowlist() external view returns (address allowlist);

    /// @notice Gets value to present redlist is active or not.
    ///
    /// @return redlistActive The redlist is active.
    function redlistActive() external view returns (bool redlistActive);

    /// @notice Gets value to present protocolTokenRequire is active or not.
    ///
    /// @return protocolTokenRequired The protocolTokenRequired is active.
    function protocolTokenRequired()
        external
        view
        returns (bool protocolTokenRequired);

    /// @notice The address of WrapTokenGateway contract.
    ///
    /// @return wrapTokenGateway The address of WrapTokenGateway contract.
    function wrapTokenGateway()
        external
        view
        returns (address wrapTokenGateway);

    /// @notice Gets information about the account owned by `owner`.
    ///
    /// @param owner The address that owns the account.
    ///
    /// @return debt            The unrealized amount of debt that the account had incurred.
    /// @return depositedTokens The yield tokens that the owner has deposited.
    function accounts(
        address owner
    ) external view returns (int256 debt, address[] memory depositedTokens);

    /// @notice Gets information about a yield token position for the account owned by `owner`.
    ///
    /// @param owner      The address that owns the account.
    /// @param yieldToken The address of the yield token to get the position of.
    ///
    /// @return shares            The amount of shares of that `owner` owns of the yield token.
    /// @return harvestedYield    The amount of harvested yield.
    /// @return lastAccruedWeight The last recorded accrued weight of the yield token.
    function positions(
        address owner,
        address yieldToken
    )
        external
        view
        returns (
            uint256 shares,
            uint256 harvestedYield,
            uint256 lastAccruedWeight
        );

    /// @notice Gets the amount of debt tokens `spender` is allowed to borrow on behalf of `owner`.
    ///
    /// @param owner   The owner of the account.
    /// @param spender The address which is allowed to borrow on behalf of `owner`.
    ///
    /// @return allowance The amount of debt tokens that `spender` can borrow on behalf of `owner`.
    function borrowAllowance(
        address owner,
        address spender
    ) external view returns (uint256 allowance);

    /// @notice Gets the amount of shares of `yieldToken` that `spender` is allowed to withdraw on behalf of `owner`.
    ///
    /// @param owner      The owner of the account.
    /// @param spender    The address which is allowed to withdraw on behalf of `owner`.
    /// @param yieldToken The address of the yield token.
    ///
    /// @return allowance The amount of shares that `spender` can withdraw on behalf of `owner`.
    function withdrawAllowance(
        address owner,
        address spender,
        address yieldToken
    ) external view returns (uint256 allowance);

    /// @notice Get YieldStrategyManager contract handle.
    /// @return returns YieldStrategyManager contract handle.
    function yieldStrategyManager()
        external
        view
        returns (IYieldStrategyManager);

    /// @notice Check interfaceId is supported by SavvyPositionManager.
    /// @param interfaceId The Id of interface to check.
    /// @return SavvyPositionMananger supports this interfaceId or not. true/false.
    function supportInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  ISavvyTokenParams
/// @author Savvy DeFi
interface ISavvyTokenParams {
    /// @notice Defines base token parameters.
    struct BaseTokenParams {
        // A coefficient used to normalize the token to a value comparable to the debt token. For example, if the
        // base token is 8 decimals and the debt token is 18 decimals then the conversion factor will be
        // 10^10. One unit of the base token will be comparably equal to one unit of the debt token.
        uint256 conversionFactor;
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Defines yield token parameters.
    struct YieldTokenParams {
        // The maximum percentage loss that is acceptable before disabling certain actions.
        uint256 maximumLoss;
        // The maximum value of yield tokens that the system can hold, measured in units of the base token.
        uint256 maximumExpectedValue;
        // The percent of credit that will be unlocked per block. The representation of this value is a 18  decimal
        // fixed point integer.
        uint256 creditUnlockRate;
        // The current balance of yield tokens which are held by users.
        uint256 activeBalance;
        // The current balance of yield tokens which are earmarked to be harvested by the system at a later time.
        uint256 harvestableBalance;
        // The total number of shares that have been borrowed for this token.
        uint256 totalShares;
        // The expected value of the tokens measured in base tokens. This value controls how much of the token
        // can be harvested. When users deposit yield tokens, it increases the expected value by how much the tokens
        // are exchangeable for in the base token. When users withdraw yield tokens, it decreases the expected
        // value by how much the tokens are exchangeable for in the base token.
        uint256 expectedValue;
        // The current amount of credit which is will be distributed over time to depositors.
        uint256 pendingCredit;
        // The amount of the pending credit that has been distributed.
        uint256 distributedCredit;
        // The block number which the last credit distribution occurred.
        uint256 lastDistributionBlock;
        // The total accrued weight. This is used to calculate how much credit a user has been granted over time. The
        // representation of this value is a 18 decimal fixed point integer.
        uint256 accruedWeight;
        // The associated base token that can be redeemed for the yield-token.
        address baseToken;
        // The adapter used by the system to wrap, unwrap, and lookup the conversion rate of this token into its
        // base token.
        address adapter;
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../../libraries/Limiters.sol";
import "./ISavvyAdminActions.sol";
import "./ISavvyTokenParams.sol";

/// @title  IYieldStrategyManagerActions
/// @author Savvy DeFi
interface IYieldStrategyManagerActions is ISavvyTokenParams {
    /// @dev Unwraps `amount` of `yieldToken` into its base token.
    ///
    /// @param yieldToken       The address of the yield token to unwrap.
    /// @param amount           The amount of the yield token to wrap.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be received from the
    ///                         operation.
    ///
    /// @return The amount of base tokens that resulted from the operation.
    function unwrap(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is ALLOWLISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address mooAaveDAI = 0xAf9f33df60CA764307B17E62dde86e9F7090426c;
    /// @notice uint256 amtRepayWithCollateral = 5000;
    /// @notice SavvyPositionManager(savvyAddress).repayWithCollateral(dai, amtRepayWithCollateral, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    /// @param shares     The amount of share left in savvy.
    function donate(
        address yieldToken,
        uint256 amount,
        uint256 shares
    ) external returns (uint256);

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be withdrawn to `recipient`.
    /// @param protocolFee      The rate of protocol fee.
    /// @return baseToken           The address of base token.
    /// @return amountBaseTokens    The amount of base token.
    /// @return feeAmount           The amount of protocol fee.
    /// @return distributeAmount    The amount of distribute
    /// @return credit              The amount of debt.
    function harvest(
        address yieldToken,
        uint256 minimumAmountOut,
        uint256 protocolFee
    )
        external
        returns (
            address baseToken,
            uint256 amountBaseTokens,
            uint256 feeAmount,
            uint256 distributeAmount,
            uint256 credit
        );

    /// @notice Synchronizes the active balance and expected value of `yieldToken`.
    /// @param yieldToken       The address of yield token.
    /// @param amount           The amount to add or subtract from the debt.
    /// @param addOperation     Present for add or sub.
    /// @return                 The config of yield token.
    function syncYieldToken(
        address yieldToken,
        uint256 amount,
        bool addOperation
    ) external returns (YieldTokenParams memory);

    /// @dev Burns `share` shares of `yieldToken` from the account owned by `owner`.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares to burn.
    function burnShares(address yieldToken, uint256 shares) external;

    /// @dev Issues shares of `yieldToken` for `amount` of its base token to `recipient`.
    ///
    /// IMPORTANT: `amount` must never be 0.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield token.
    /// @return shares    The amount of shars.
    function issueSharesForAmount(
        address yieldToken,
        uint256 amount
    ) external returns (uint256 shares);

    /// @notice Update repay limiters and returns debt amount and actual amount of base token.
    /// @param baseToken The address of base token.
    /// @return Return debt amount same worth as `amount` of base token.
    /// @return Return actual amount of base token for repay debt.
    function repayWithBaseToken(
        address baseToken,
        uint256 amount,
        int256 debt
    ) external view returns (uint256, uint256);

    /// @notice Check if had condition to do repayWithCollateral.
    /// @notice checkSupportedYieldToken(), checkTokenEnabled(), checkLoss()
    /// @param yieldToken The address of yield token.
    /// @return baseToken The address of base token.
    function repayWithCollateralCheck(
        address yieldToken
    ) external view returns (address baseToken);

    /// @dev Distributes unlocked credit of `yieldToken` to all depositors.
    ///
    /// @param yieldToken The address of the yield token to distribute unlocked credit for.
    function distributeUnlockedCredit(address yieldToken) external;

    /// @dev Preemptively harvests `yieldToken`.
    ///
    /// @dev This will earmark yield tokens to be harvested at a future time when the current value of the token is
    ///      greater than the expected value. The purpose of this function is to synchronize the balance of the yield
    ///      token which is held by users versus tokens which will be seized by the protocol.
    ///
    /// @param yieldToken The address of the yield token to preemptively harvest.
    function preemptivelyHarvest(address yieldToken) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of base tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external returns (uint256);

    /// @notice Do pre actions for deposit.
    /// @notice checkTokenEnabled(), checkLoss(), preemptivelyHarvest()
    /// @param yieldToken The address of yield token.
    /// @return yieldTokenParam The config of yield token.
    function depositPrepare(
        address yieldToken
    ) external returns (YieldTokenParams memory yieldTokenParam);

    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    /// @dev Explain to a developer any extra details
    /// @param yieldToken       The address of the yield token to repayWithCollateral.
    /// @param recipient        The address of user that will derease debt.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of base tokens that are expected to be repaidWithCollateral.
    /// @param unrealizedDebt   The amount of the debt unrealized.
    /// @return The amount of base token.
    /// @return The amount of yield token.
    /// @return The amount of shares that used actually to decrease debt.
    function repayWithCollateral(
        address yieldToken,
        address recipient,
        uint256 shares,
        uint256 minimumAmountOut,
        int256 unrealizedDebt
    ) external returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../../libraries/Limiters.sol";
import "./ISavvyAdminActions.sol";
import "./ISavvyTokenParams.sol";

/// @title  IYieldStrategyManagerState
/// @author Savvy DeFi
interface IYieldStrategyManagerStates is ISavvyTokenParams {
    /// @notice Configures the the repay limit of `baseToken`.
    /// @param baseToken The address of the base token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the repayWithCollateral limiter of `baseToken`.
    /// @param baseToken The address of the base token to configure the repayWithCollateral limit of.
    /// @param maximum         The maximum repayWithCollateral limit.
    /// @param blocks          The number of blocks it will take for the maximum repayWithCollateral limit to be replenished when it is completely exhausted.
    function configureRepayWithCollateralLimit(
        address baseToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configures the borrowing limiter.
    ///
    /// @param maximum The maximum borrowing limit.
    /// @param rate  The number of blocks it will take for the maximum borrowing limit to be replenished when it is completely exhausted.
    function configureBorrowingLimit(uint256 maximum, uint256 rate) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(
        address yieldToken,
        uint256 blocks
    ) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its base token.
    function setMaximumExpectedValue(
        address yieldToken,
        uint256 value
    ) external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Sets the token adapter of a yield token.
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Set the borrowing limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {BorrowingLimitUpdated} event.
    ///
    /// @param borrowingLimiter Limit information for borrowing.
    function setBorrowingLimiter(
        Limiters.LinearGrowthLimiter calldata borrowingLimiter
    ) external;

    /// @notice Set savvyPositionManager address.
    /// @dev Only owner can call this function.
    /// @param savvyPositionManager The address of savvyPositionManager.
    function setSavvyPositionManager(address savvyPositionManager) external;

    /// @notice Gets the conversion rate of base tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of base tokens per share.
    function getBaseTokensPerShare(
        address yieldToken
    ) external view returns (uint256 rate);

    /// @notice Gets the conversion rate of yield tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of yield tokens per share.
    function getYieldTokensPerShare(
        address yieldToken
    ) external view returns (uint256 rate);

    /// @notice Gets the supported base tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported base tokens.
    function getSupportedBaseTokens()
        external
        view
        returns (address[] memory tokens);

    /// @notice Gets the supported yield tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported yield tokens.
    function getSupportedYieldTokens()
        external
        view
        returns (address[] memory tokens);

    /// @notice Gets if an base token is supported.
    ///
    /// @param baseToken The address of the base token to check.
    ///
    /// @return isSupported If the base token is supported.
    function isSupportedBaseToken(
        address baseToken
    ) external view returns (bool isSupported);

    /// @notice Gets if a yield token is supported.
    ///
    /// @param yieldToken The address of the yield token to check.
    ///
    /// @return isSupported If the yield token is supported.
    function isSupportedYieldToken(
        address yieldToken
    ) external view returns (bool isSupported);

    /// @notice Gets the parameters of an base token.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return params The base token parameters.
    function getBaseTokenParameters(
        address baseToken
    ) external view returns (BaseTokenParams memory params);

    /// @notice Get the parameters and state of a yield-token.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return params The yield token parameters.
    function getYieldTokenParameters(
        address yieldToken
    ) external view returns (YieldTokenParams memory params);

    /// @notice Gets current limit, maximum, and rate of the borrowing limiter.
    ///
    /// @return currentLimit The current amount of debt tokens that can be borrowed.
    /// @return rate         The maximum possible amount of tokens that can be repaidWithCollateral at a time.
    /// @return maximum      The highest possible maximum amount of debt tokens that can be borrowed at a time.
    function getBorrowLimitInfo()
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @notice Gets current limit, maximum, and rate of a repay limiter for `baseToken`.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return currentLimit The current amount of base tokens that can be repaid.
    /// @return rate         The rate at which the the current limit increases back to its maximum in tokens per block.
    /// @return maximum      The maximum possible amount of tokens that can be repaid at a time.
    function getRepayLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @notice Gets current limit, maximum, and rate of the repayWithCollateral limiter for `baseToken`.
    ///
    /// @param baseToken The address of the base token.
    ///
    /// @return currentLimit The current amount of base tokens that can be repaid with Collateral.
    /// @return rate         The rate at which the function increases back to its maximum limit (tokens / block).
    /// @return maximum      The highest possible maximum amount of debt tokens that can be repaidWithCollateral at a time.
    function getRepayWithCollateralLimitInfo(
        address baseToken
    )
        external
        view
        returns (uint256 currentLimit, uint256 rate, uint256 maximum);

    /// @dev Gets the amount of shares that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The number of shares.
    function convertYieldTokensToShares(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of shares of `yieldToken` that `amount` of its base token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of base tokens.
    ///
    /// @return The amount of shares.
    function convertBaseTokensToShares(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of yield tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return The amount of yield tokens.
    function convertSharesToYieldTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (uint256);

    /// @dev Gets the amount of an base token that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The amount of base tokens.
    function convertYieldTokensToBaseToken(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of `yieldToken` that `amount` of its base token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of base tokens.
    ///
    /// @return The amount of yield tokens.
    function convertBaseTokensToYieldToken(
        address yieldToken,
        uint256 amount
    ) external view returns (uint256);

    /// @dev Gets the amount of base tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return baseToken           The address of base token.
    /// @return amountBaseTokens    The amount of base tokens.
    function convertSharesToBaseTokens(
        address yieldToken,
        uint256 shares
    ) external view returns (address baseToken, uint256 amountBaseTokens);

    /// @dev Calculates the amount of unlocked credit for `yieldToken` that is available for distribution.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return currentAccruedWeight The current total accrued weight.
    /// @return unlockedCredit The amount of unlocked credit available.
    function calculateUnlockedCredit(
        address yieldToken
    )
        external
        view
        returns (uint256 currentAccruedWeight, uint256 unlockedCredit);

    /// @dev Gets the virtual active balance of `yieldToken`.
    ///
    /// @dev The virtual active balance is the active balance minus any harvestable tokens which have yet to be realized.
    ///
    /// @param yieldToken The address of the yield token to get the virtual active balance of.
    ///
    /// @return The virtual active balance.
    function calculateUnrealizedActiveBalance(
        address yieldToken
    ) external view returns (uint256);

    /// @notice Check token is supported by Savvy.
    /// @dev The token should not be yield token or base token that savvy contains.
    /// @dev If token is yield token or base token, reverts UnsupportedToken.
    /// @param rewardToken The address of token to check.
    function checkSupportTokens(address rewardToken) external view;

    /// @dev Checks if an address is a supported yield token.
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    /// @param yieldToken The address to check.
    function checkSupportedYieldToken(address yieldToken) external view;

    /// @dev Checks if an address is a supported base token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param baseToken The address to check.
    function checkSupportedBaseToken(address baseToken) external view;

    /// @notice Get repay limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Repay limit information of baseToken.
    function repayLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Get currnet borrow limit information.
    /// @return Current borrowing limit information.
    function currentBorrowingLimiter() external view returns (uint256);

    /// @notice Get current repay limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Current repay limit information of baseToken.
    function currentRepayWithBaseTokenLimit(
        address baseToken
    ) external view returns (uint256);

    /// @notice Get current repayWithCollateral limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return Current repayWithCollateral limit information of baseToken.
    function currentRepayWithCollateralLimit(
        address baseToken
    ) external view returns (uint256);

    /// @notice Get repayWithCollateral limit information of baseToken.
    /// @param baseToken The address of base token.
    /// @return RepayWithCollateral limit information of baseToken.
    function repayWithCollateralLimiters(
        address baseToken
    ) external view returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Get yield token parameter of yield token.
    /// @param yieldToken The address of yield token.
    /// @return The parameter of yield token.
    function getYieldTokenParams(
        address yieldToken
    ) external view returns (YieldTokenParams memory);

    /// @notice Check yield token loss is exceeds max loss.
    /// @dev If it's exceeds to max loss, revert `LossExceed(yieldToken, currentLoss, maximumLoss)`.
    /// @param yieldToken The address of yield token.
    function checkLoss(address yieldToken) external view;

    /// @notice Adds an base token to the system.
    /// @param debtToken The address of debt Token.
    /// @param baseToken The address of the base token to add.
    /// @param config          The initial base token configuration.
    function addBaseToken(
        address debtToken,
        address baseToken,
        ISavvyAdminActions.BaseTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(
        address yieldToken,
        ISavvyAdminActions.YieldTokenConfig calldata config
    ) external;

    /// @notice Sets an base token as either enabled or disabled.
    /// @param baseToken The address of the base token to enable or disable.
    /// @param enabled         If the base token should be enabled or disabled.
    function setBaseTokenEnabled(address baseToken, bool enabled) external;

    /// @notice Sets a yield token as either enabled or disabled.
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the base token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Get base token parameter of base token.
    /// @param baseToken The address of base token.
    /// @return The parameter of base token.
    function getBaseTokenParams(
        address baseToken
    ) external view returns (BaseTokenParams memory);

    /// @notice Get borrow limit information.
    /// @return Borrowing limit information.
    function borrowingLimiter()
        external
        view
        returns (Limiters.LinearGrowthLimiter memory);

    /// @notice Decrease borrowing limiter.
    /// @param amount The amount of borrowing to decrease.
    function decreaseBorrowingLimiter(uint256 amount) external;

    /// @notice Increase borrowing limiter.
    /// @param amount The amount of borrowing to increase.
    function increaseBorrowingLimiter(uint256 amount) external;

    /// @notice Decrease repayWithCollateral limiter.
    /// @param amount The amount of repayWithCollateral to decrease.
    function decreaseRepayWithCollateralLimiter(
        address baseToken,
        uint256 amount
    ) external;

    /// @notice Decrease base token repay limiter.
    /// @param amount The amount of base token repay to decrease.
    function decreaseRepayWithBaseTokenLimiter(
        address baseToken,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title ISavvySwap
/// @author Savvy DeFi
interface ISavvySwap {
    /// @notice Emitted when the admin address is updated.
    ///
    /// @param admin The new admin address.
    event AdminUpdated(address admin);

    /// @notice Emitted when the pending admin address is updated.
    ///
    /// @param pendingAdmin The new pending admin address.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the system is paused or unpaused.
    ///
    /// @param flag `true` if the system has been paused, `false` otherwise.
    event Paused(bool flag);

    /// @dev Emitted when a deposit is performed.
    ///
    /// @param sender The address of the depositor.
    /// @param owner  The address of the account that received the deposit.
    /// @param amount The amount of tokens deposited.
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 amount
    );

    /// @dev Emitted when a withdraw is performed.
    ///
    /// @param sender    The address of the `msg.sender` executing the withdraw.
    /// @param recipient The address of the account that received the withdrawn tokens.
    /// @param amount    The amount of tokens withdrawn.
    event Withdraw(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Emitted when a claim is performed.
    ///
    /// @param sender    The address of the claimer / account owner.
    /// @param recipient The address of the account that received the claimed tokens.
    /// @param amount    The amount of tokens claimed.
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    /// @dev Emitted when an swap is performed.
    ///
    /// @param sender The address that called `swap()`.
    /// @param amount The amount of tokens swapped.
    event Swap(address indexed sender, uint256 amount);

    /// @notice Gets the version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @dev Gets the synthetic token.
    ///
    /// @return The synthetic token.
    function syntheticToken() external view returns (address);

    /// @dev Gets the supported base token.
    ///
    /// @return The base token.
    function baseToken() external view returns (address);

    /// @notice Gets the address of the allowlist contract.
    ///
    /// @return allowlist The address of the allowlist contract.
    function allowlist() external view returns (address allowlist);

    /// @dev Gets the unswapped balance of an account.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The unswapped balance.
    function getUnswappedBalance(address owner) external view returns (uint256);

    /// @dev Gets the swapped balance of an account, in units of `debtToken`.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The swapped balance.
    function getSwappedBalance(address owner) external view returns (uint256);

    /// @dev Gets the claimable balance of an account, in units of `baseToken`.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The claimable balance.
    function getClaimableBalance(address owner) external view returns (uint256);

    /// @dev The conversion factor used to convert between base token amounts and debt token amounts.
    ///
    /// @return The coversion factor.
    function conversionFactor() external view returns (uint256);

    /// @dev Deposits tokens to be swapped into an account.
    ///
    /// @param amount The amount of tokens to deposit.
    /// @param owner  The owner of the account to deposit the tokens into.
    function deposit(uint256 amount, address owner) external;

    /// @dev Withdraws tokens from the caller's account that were previously deposited to be swapped.
    ///
    /// @param amount    The amount of tokens to withdraw.
    /// @param recipient The address which will receive the withdrawn tokens.
    function withdraw(uint256 amount, address recipient) external;

    /// @dev Claims swapped tokens.
    ///
    /// @param amount    The amount of tokens to claim.
    /// @param recipient The address which will receive the claimed tokens.
    function claim(uint256 amount, address recipient) external;

    /// @dev Swap `amount` base tokens for `amount` synthetic tokens staked in the system.
    ///
    /// @param amount The amount of tokens to swap.
    function swap(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../base/ErrorMessages.sol";

// a library for validating conditions.

library Checker {
    /// @dev Checks an expression and reverts with an {IllegalArgument} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkArgument(
        bool expression,
        string memory message
    ) internal pure {
        require(expression, message);
    }

    /// @dev Checks an expression and reverts with an {IllegalState} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    /// @param message The error message to display if the check fails.
    function checkState(bool expression, string memory message) internal pure {
        require(expression, message);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISavvyPositionManager.sol";
import "../interfaces/ISavvyPriceFeed.sol";
import "../interfaces/infoaggregator/ISavvyInfoAggregatorStructs.sol";
import "../interfaces/ITokenAdapter.sol";
import "./SafeCast.sol";
import "./TokenUtils.sol";
import "./Math.sol";

/**
 * @notice A library which implements fixed point decimal math.
 */
library InfoAggregatorUtils {
  uint256 public constant FIXED_POINT_SCALAR = 1e18;
  uint256 private constant OFFSET_RANGE = 100;

  function _convertDebtToUSD(
    int256 totalDebt,
    ISavvyPriceFeed svyPriceFeed_,
    ISavvyPositionManager savvyPositionManager_
  ) internal view returns (uint256) {
    uint256 actualDebt = SafeCast.toUint256(totalDebt);
    IYieldStrategyManager yieldStrategyManager = savvyPositionManager_
      .yieldStrategyManager();
    address[] memory yieldTokens = yieldStrategyManager
      .getSupportedYieldTokens();

    if (yieldTokens.length == 0) {
      return 0;
    }

    address yieldToken = yieldTokens[0];
    ISavvyState.YieldTokenParams memory yieldTokenParams = yieldStrategyManager
      .getYieldTokenParameters(yieldToken);
    address baseToken = yieldTokenParams.baseToken;

    uint256 baseTokenAmount = _normalizeBaseTokensToDebt(
      savvyPositionManager_,
      baseToken,
      actualDebt
    );

    return _getBaseTokenPrice(svyPriceFeed_, baseToken, baseTokenAmount);
  }

  /// @dev Normalize `amount` of `baseToken` to a value which is comparable to units of the debt token.
  ///
  /// @param baseToken_ The address of the base token.
  /// @param amount_          The amount of the debt token.
  ///
  /// @return The normalized amount.
  function _normalizeBaseTokensToDebt(
    ISavvyPositionManager savvyPositionManager_,
    address baseToken_,
    uint256 amount_
  ) internal view returns (uint256) {
    IYieldStrategyManager yieldStrategyManager = savvyPositionManager_
      .yieldStrategyManager();
    ISavvyState.BaseTokenParams memory baseTokenParams = yieldStrategyManager
      .getBaseTokenParameters(baseToken_);
    return amount_ / baseTokenParams.conversionFactor;
  }

  /// @notice Get token price.
  /// @param baseToken_ The address of base token.
  /// @param amount_ The base token amount.
  /// @return Return token price as 1e18
  function _getBaseTokenPrice(
    ISavvyPriceFeed svyPriceFeed_,
    address baseToken_,
    uint256 amount_
  ) internal view returns (uint256) {
    return svyPriceFeed_.getBaseTokenPrice(baseToken_, amount_);
  }

  /// @dev The struct to resolve stack too deep issue
  /// @dev It is only used in `_getPoolsInfo` function
  struct GetPoolsInfoState {
    uint256 numOfSavvyPositionManagers;
    uint256 numOfYieldTokens;
    uint256 poolsInfoIdx;
    uint256 userHarvestedYield;
  }

  /// @notice Gets information for all Savvy pools.
  ///
  /// @notice `account_` must be a non-zero address
  /// or this call will revert with a {IllegalArgument} error.
  ///
  /// @param account_ The specific wallet to get information for.
  /// @return poolsInfo Information for all Savvy pools.
  function _getPoolsInfo(
    ISavvyPriceFeed svyPriceFeed,
    address[] memory savvyPositionManagers,
    address account_
  ) internal view returns (ISavvyInfoAggregatorStructs.FullPoolInfo[] memory) {
    Checker.checkArgument(account_ != address(0), "zero account address");

    GetPoolsInfoState memory state;
    state.poolsInfoIdx = 0;
    state.numOfSavvyPositionManagers = savvyPositionManagers.length;
    state.numOfYieldTokens = 0;

    for (uint256 i = 0; i < state.numOfSavvyPositionManagers; i++) {
      ISavvyPositionManager savvyPositionManager = ISavvyPositionManager(
        savvyPositionManagers[i]
      );
      IYieldStrategyManager yieldStrategyManager = IYieldStrategyManager(
        savvyPositionManager.yieldStrategyManager()
      );
      address[] memory yieldTokens = yieldStrategyManager
        .getSupportedYieldTokens();
      state.numOfYieldTokens += yieldTokens.length;
    }

    ISavvyInfoAggregatorStructs.FullPoolInfo[]
      memory poolsInfo = new ISavvyInfoAggregatorStructs.FullPoolInfo[](
        state.numOfYieldTokens
      );
    state.poolsInfoIdx = 0;

    for (uint256 i = 0; i < state.numOfSavvyPositionManagers; i++) {
      ISavvyPositionManager savvyPositionManager = ISavvyPositionManager(
        savvyPositionManagers[i]
      );
      IYieldStrategyManager yieldStrategyManager = IYieldStrategyManager(
        savvyPositionManager.yieldStrategyManager()
      );
      address[] memory supportedYieldTokens = yieldStrategyManager
        .getSupportedYieldTokens();
      ISavvyPriceFeed priceFeed = svyPriceFeed;
      for (uint256 j = 0; j < supportedYieldTokens.length; j++) {
        address yieldToken = supportedYieldTokens[j];
        ISavvyState.YieldTokenParams
          memory yieldTokenParams = yieldStrategyManager
            .getYieldTokenParameters(yieldToken);

        ISavvyInfoAggregatorStructs.FullSavvyPosition
          memory poolDepositedInfo = _getFullDepositedTokenPosition(
            account_,
            yieldToken,
            savvyPositionManager,
            yieldStrategyManager,
            priceFeed
          );
        ISavvyState.BaseTokenParams
          memory baseTokenParams = yieldStrategyManager.getBaseTokenParameters(
            poolDepositedInfo.token
          );

        (, state.userHarvestedYield, ) = savvyPositionManager.positions(
          account_,
          yieldToken
        );
        poolsInfo[state.poolsInfoIdx] = ISavvyInfoAggregatorStructs
          .FullPoolInfo(
            address(savvyPositionManager), // savvyPositionManager
            yieldToken, // poolAddress
            poolDepositedInfo.token, // baseTokenAddress
            poolDepositedInfo.amount, // userDepositedAmount
            poolDepositedInfo.valueUSD, // userDepositedValueUSD
            state.userHarvestedYield, // userHarvestedYield
            yieldTokenParams.expectedValue * baseTokenParams.conversionFactor, // poolDepositedAmount
            _getBaseTokenPrice(
              priceFeed,
              poolDepositedInfo.token,
              yieldTokenParams.expectedValue
            ), // poolDepositedValueUSD
            yieldTokenParams.maximumExpectedValue *
              baseTokenParams.conversionFactor, // maxPoolDepositedAmount
            _getBaseTokenPrice(
              priceFeed,
              poolDepositedInfo.token,
              yieldTokenParams.maximumExpectedValue
            ), // maxPoolDepositedValueUSD,
            0, // maxWithdrawableShares
            0 // maxWithdrawableAmount
          );
        state.poolsInfoIdx++;
      }
    }

    state.poolsInfoIdx = 0;
    for (uint256 i = 0; i < state.numOfSavvyPositionManagers; i++) {
      ISavvyPositionManager savvyPositionManager = ISavvyPositionManager(
        savvyPositionManagers[i]
      );
      IYieldStrategyManager yieldStrategyManager = IYieldStrategyManager(
        savvyPositionManager.yieldStrategyManager()
      );

      ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[]
        memory withdrawableShares = _getWithdrawableAmount(
          account_,
          savvyPositionManager
        );
      address[] memory supportedYieldTokens = yieldStrategyManager
        .getSupportedYieldTokens();
      for (uint256 j = 0; j < supportedYieldTokens.length; j++) {
        address yieldToken = supportedYieldTokens[j];
        if (!yieldStrategyManager.getYieldTokenParameters(yieldToken).enabled) {
          continue;
        }
        ISavvyInfoAggregatorStructs.SavvyWithdrawInfo
          memory savvyWithdrawInfo = _findWithdrawSharesForYieldToken(
            yieldToken,
            withdrawableShares
          );

        poolsInfo[state.poolsInfoIdx].maxWithdrawableAmount = savvyWithdrawInfo
          .amount;
        poolsInfo[state.poolsInfoIdx].maxWithdrawableShares = savvyWithdrawInfo
          .shares;
        state.poolsInfoIdx++;
      }
    }

    return poolsInfo;
  }

  function _findWithdrawSharesForYieldToken(
    address yieldToken,
    ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[] memory withdrawableShares
  )
    internal
    pure
    returns (ISavvyInfoAggregatorStructs.SavvyWithdrawInfo memory)
  {
    uint256 length = withdrawableShares.length;
    for (uint256 i = 0; i < length; i++) {
      if (yieldToken == withdrawableShares[i].yieldToken) {
        return withdrawableShares[i];
      }
    }

    return
      ISavvyInfoAggregatorStructs.SavvyWithdrawInfo(
        address(0),
        address(0),
        0,
        0
      );
  }

  /// @notice Get the FullSavvyPosition for the deposited
  /// token for an `account_`. For example, if a user
  /// used Savvy to deposit 1000 DAI into a beefy/curve
  /// strategy, the balance of the deposited token for the
  /// av3CRV `yieldToken_` would be 1000.
  ///
  /// @notice `yieldToken_` must be a valid yield token for the
  /// provided `savvyPositionManager_` or this call will revert
  /// with a {IllegalArgument} error.
  ///
  /// @param account_ The account's wallet to check.
  /// @param yieldToken_ The address of the yield token.
  /// @param savvyPositionManager_ The SavvyPositionManager
  /// that manages the deposits.
  /// @param yieldStrategyManager_ The YieldStrategyManager associtated
  /// with `savvyPositionManager_`.
  /// @return fullDepositedTokenPosition The balance and value of
  /// the base token deposited in Savvy.
  function _getFullDepositedTokenPosition(
    address account_,
    address yieldToken_,
    ISavvyPositionManager savvyPositionManager_,
    IYieldStrategyManager yieldStrategyManager_,
    ISavvyPriceFeed savvyPriceFeed_
  )
    internal
    view
    returns (ISavvyInfoAggregatorStructs.FullSavvyPosition memory)
  {
    Checker.checkArgument(
      yieldStrategyManager_.isSupportedYieldToken(yieldToken_),
      "unsupported yield token"
    );

    (uint256 shares, , ) = savvyPositionManager_.positions(
      account_,
      yieldToken_
    );

    (address baseToken, uint256 baseTokenAmount) = yieldStrategyManager_
      .convertSharesToBaseTokens(yieldToken_, shares);
    uint256 valueUSD = _getBaseTokenPrice(
      savvyPriceFeed_,
      baseToken,
      baseTokenAmount
    );

    ISavvyState.BaseTokenParams memory baseTokenParams = yieldStrategyManager_
      .getBaseTokenParams(baseToken);
    uint256 normalizedBaseTokenAmount = baseTokenAmount *
      baseTokenParams.conversionFactor;

    return
      ISavvyInfoAggregatorStructs.FullSavvyPosition(
        baseToken,
        normalizedBaseTokenAmount,
        valueUSD
      );
  }

  /// @notice Get the total deposited amount for `account_` across
  /// all suported tokens in `savvyPositionManager_`.
  /// @param account_ The account's wallet to check.
  /// @param savvyPositionManager_ The SavvyPositionManager
  /// that manages the deposits.
  /// @param yieldStrategyManager_ The YieldStrategyManager associtated
  /// with `savvyPositionManager_`.
  /// @return totalDepositedAmount The total amount of deposits
  /// across all supported tokens.
  function _getDepositedAmountForAccount(
    address account_,
    ISavvyPositionManager savvyPositionManager_,
    IYieldStrategyManager yieldStrategyManager_
  ) internal view returns (uint256) {
    address[] memory yieldTokens = yieldStrategyManager_
      .getSupportedYieldTokens();

    uint256 totalDepositedAmount = 0;
    for (uint256 i = 0; i < yieldTokens.length; i++) {
      address yieldToken = yieldTokens[i];
      (uint256 shares, , ) = savvyPositionManager_.positions(
        account_,
        yieldToken
      );

      ISavvyState.YieldTokenParams
        memory yieldTokenParams = yieldStrategyManager_.getYieldTokenParameters(
          yieldToken
        );
      uint256 pricePerShare = ITokenAdapter(yieldTokenParams.adapter).price();

      uint8 yieldTokenDecimals = TokenUtils.expectDecimals(yieldToken);
      uint256 baseTokenAmount = ((pricePerShare * shares) /
        10 ** yieldTokenDecimals);
      totalDepositedAmount += baseTokenAmount;
    }

    return totalDepositedAmount;
  }

  /// @notice Get the FullSavvyPosition for the outstanding
  /// debt for an `account_`. For example, if a user
  /// deposited 1000 DAI and borrowed 400 svUSD the user's
  /// outstanding debt would be the 400 svUSD. It is important
  /// to note that the balance of svUSD in a user's wallet
  /// has no bearing on the outstanding debt. If the user swaps
  /// the 400 svUSD for some stable token, they still owe 400 svUSD,
  /// or eligible repayment, token to Savvy.
  /// @param account_ The account's wallet to check.
  /// @param savvyPositionManager_ The SavvyPositionManager
  /// that manages the debt.
  /// @return fullOutstandingDebtInfo The balance and value of
  /// the outstanding debt.
  function _getFullOutstandingDebtInfo(
    address account_,
    ISavvyPriceFeed savvyPriceFeed_,
    ISavvyPositionManager savvyPositionManager_
  ) internal view returns (ISavvyInfoAggregatorStructs.FullDebtInfo memory) {
    (int256 debtAmount, ) = savvyPositionManager_.accounts(account_);
    return
      ISavvyInfoAggregatorStructs.FullDebtInfo(
        address(savvyPositionManager_),
        debtAmount,
        _getUserDebtValueUSD(savvyPriceFeed_, savvyPositionManager_, account_)
      );
  }

  /// @notice Return total amount of user borrowed with specific SavvyPositionManager.
  /// @param savvyPositionManager_ Handle of SavvyPositionManager.
  /// @param user_ The address of user to get total deposited amount.
  /// @return The amount of total deposited calculated by USD.
  function _getUserDebtValueUSD(
    ISavvyPriceFeed savvyPriceFeed_,
    ISavvyPositionManager savvyPositionManager_,
    address user_
  ) internal view returns (int256) {
    (int256 debt, ) = savvyPositionManager_.accounts(user_);
    int256 debtAmount = 0;

    if (debt > 0) {
      debtAmount += SafeCast.toInt256(
        _convertDebtToUSD(debt, savvyPriceFeed_, savvyPositionManager_)
      );
    }

    return debtAmount;
  }

  /// @notice Get the FullSavvyPosition for a debt token
  /// in an `account_`'s wallet. For example, the balance
  /// of svUSD in the `account_`'s wallet. This is not the
  /// same as the debt the `account_` owes to Savvy.
  /// @dev TODO(2022-12-15, ramsey) The USD value of the debt
  /// token is approximated from the price of the a base
  /// token. Since the debt token is soft pegged to the base
  /// token, this proxy value should be close enough.
  /// @param account_ The account's wallet to check.
  /// @param savvyPositionManager_ The SavvyPositionManager
  /// that manages the debt token.
  /// @return fullDebtTokenPosition The balance and value of
  /// the debt token in the `account_`'s wallet.
  function _getFullDebtTokenPosition(
    address account_,
    ISavvyPriceFeed svyPriceFeed_,
    ISavvyPositionManager savvyPositionManager_
  )
    internal
    view
    returns (ISavvyInfoAggregatorStructs.FullSavvyPosition memory)
  {
    address addressOfDebtToken = savvyPositionManager_.debtToken();
    uint256 balanceOfDebtToken = IERC20(addressOfDebtToken).balanceOf(account_);
    uint256 valueOfDebtTokenUSD = _convertDebtToUSD(
      SafeCast.toInt256(balanceOfDebtToken),
      svyPriceFeed_,
      savvyPositionManager_
    );

    return
      ISavvyInfoAggregatorStructs.FullSavvyPosition(
        addressOfDebtToken,
        balanceOfDebtToken,
        valueOfDebtTokenUSD
      );
  }

  /// @notice Get the FullSavvyPosition for the available
  /// credit for an `account_`. For example, if a user
  /// deposited 1000 DAI, they can borrow up to 500 svUSD.
  /// Assume the user goes on to borrow 200 svUSD, the
  /// available credit of svUSD is 300.
  /// @param account_ The account's wallet to check.
  /// @param savvyPositionManager_ The SavvyPositionManager
  /// that manages the credit line.
  /// @return fullAvailableCreditPosition The balance and value of
  /// the available credit.
  function _getFullAvailableCreditPosition(
    address account_,
    ISavvyPositionManager savvyPositionManager_,
    ISavvyPriceFeed savvyPriceFeed_
  )
    internal
    view
    returns (ISavvyInfoAggregatorStructs.FullSavvyPosition memory)
  {
    uint256 availableCreditAmount = _getBorrowableAmount(
      account_,
      savvyPositionManager_
    );
    uint256 availableCreditUSD = _convertDebtToUSD(
      SafeCast.toInt256(availableCreditAmount),
      savvyPriceFeed_,
      savvyPositionManager_
    );

    return
      ISavvyInfoAggregatorStructs.FullSavvyPosition(
        savvyPositionManager_.debtToken(),
        availableCreditAmount,
        availableCreditUSD
      );
  }

  /// @notice Return total amount of user deposited with specific SavvyPositionManager.
  /// @param savvyPositionManager_ Handle of SavvyPositionManager.
  /// @param user_ The address of user to get total deposited amount.
  /// @return The amount of total deposited calculated by USD.
  function _getUserDepositedAmount(
    ISavvyPositionManager savvyPositionManager_,
    ISavvyPriceFeed savvyPriceFeed_,
    address user_
  ) internal view returns (uint256) {
    (, address[] memory depositedTokens) = savvyPositionManager_.accounts(
      user_
    );

    uint256 length = depositedTokens.length;
    uint256 totalAmount = 0;
    IYieldStrategyManager yieldStrategyManager = savvyPositionManager_
      .yieldStrategyManager();

    ISavvyPriceFeed priceFeed = savvyPriceFeed_;
    for (uint256 i = 0; i < length; i++) {
      address yieldToken = depositedTokens[i];
      (uint256 shares, , ) = savvyPositionManager_.positions(user_, yieldToken);
      (address baseToken, uint256 baseTokenAmount) = yieldStrategyManager
        .convertSharesToBaseTokens(yieldToken, shares);
      uint256 price = _getBaseTokenPrice(priceFeed, baseToken, baseTokenAmount);

      totalAmount += price;
    }

    return totalAmount;
  }

  /// @notice Get total available credit of a specific user.
  /// @dev Calculated as [total deposit] / [minimumCollateralization] - [current balance]
  /// @param savvyPositionManager_ Handle of SavvyPositionManager.
  /// @param user_ The address of user to get total deposited amount.
  /// @return Total amount of available credit of a specific user, calculated by USD.
  function _getUserAvailableCreditUSD(
    ISavvyPositionManager savvyPositionManager_,
    ISavvyPriceFeed savvyPriceFeed_,
    address user_
  ) internal view returns (int256) {
    uint256 minCollateralization = savvyPositionManager_
      .minimumCollateralization();
    uint256 totalDepositedAmount = _getUserDepositedAmount(
      savvyPositionManager_,
      savvyPriceFeed_,
      user_
    );
    int256 currentBalance = _getUserDebtValueUSD(
      savvyPriceFeed_,
      savvyPositionManager_,
      user_
    );

    int256 creditAmount = SafeCast.toInt256(
      (totalDepositedAmount * FIXED_POINT_SCALAR) / minCollateralization
    );

    return creditAmount - currentBalance;
  }

  /// @notice Get total debt amount of specific savvyPositionManager.
  /// @param savvyPositionManager_ Handl of the savvyPositionManager.
  /// @return Total debt amount of specific savvyPositionManager.
  function _getTotalDebtAmount(
    ISavvyPositionManager savvyPositionManager_,
    ISavvyPriceFeed svyPriceFeed_
  ) internal view returns (int256) {
    int256 totalDebt = savvyPositionManager_.totalDebt();
    int256 debtAmount = 0;

    if (totalDebt > 0) {
      debtAmount += SafeCast.toInt256(
        _convertDebtToUSD(totalDebt, svyPriceFeed_, savvyPositionManager_)
      );
    }

    return debtAmount;
  }

  /// @notice Get total deposited amount of specific savvyPositionManager.
  /// @param savvyPositionManager_ Handle of the savvyPositionManager.
  /// @return Total deposited amount of specific savvyPositionManager.
  function _getTotalDepositedAmount(
    ISavvyPositionManager savvyPositionManager_,
    ISavvyPriceFeed svyPriceFeed_
  ) internal view returns (uint256) {
    IYieldStrategyManager yieldStrategyManager = savvyPositionManager_
      .yieldStrategyManager();
    address[] memory yieldTokens = yieldStrategyManager
      .getSupportedYieldTokens();

    uint256 length = yieldTokens.length;
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < length; i++) {
      uint256 price = _getDepositedTokenPrice(
        yieldTokens[i],
        address(savvyPositionManager_),
        svyPriceFeed_
      );
      totalAmount += price;
    }

    return totalAmount;
  }

  /// @notice Get total available credit of a specific user.
  /// @dev Calculated as [total deposit] / [minimumCollateralization] - [current balance]
  /// @param savvyPositionManager_ Handle of SavvyPositionManager.
  /// @return Total amount of available credit of a specific user, calculated by USD.
  function _getAvailableCreditUSD(
    ISavvyPositionManager savvyPositionManager_,
    ISavvyPriceFeed svyPriceFeed_
  ) internal view returns (int256) {
    uint256 minCollateralization = savvyPositionManager_
      .minimumCollateralization();
    uint256 totalDepositedAmount = _getTotalDepositedAmount(
      savvyPositionManager_,
      svyPriceFeed_
    );
    int256 currentBalance = _getTotalDebtAmount(
      savvyPositionManager_,
      svyPriceFeed_
    );

    int256 creditAmount = SafeCast.toInt256(
      (totalDepositedAmount * FIXED_POINT_SCALAR) / minCollateralization
    );

    return creditAmount - currentBalance;
  }

  /// @notice Get usd amount deposited with the base token by the user.
  /// @param user_ The address of an user.
  /// @param yieldToken_ The address of an yield token.
  /// @param savvyPositionManager_ The address of a savvyPositionManager.
  /// @return USD amount.
  function _getUserDepositedTokenPrice(
    address user_,
    address yieldToken_,
    address savvyPositionManager_,
    ISavvyPriceFeed svyPriceFeed_
  ) internal view returns (uint256) {
    IYieldStrategyManager yieldStrategyManager = ISavvyPositionManager(
      savvyPositionManager_
    ).yieldStrategyManager();
    if (!yieldStrategyManager.isSupportedYieldToken(yieldToken_)) {
      return 0;
    }

    (uint256 shares, , ) = ISavvyPositionManager(savvyPositionManager_)
      .positions(user_, yieldToken_);

    ISavvyState.YieldTokenParams memory yieldTokenParams = yieldStrategyManager
      .getYieldTokenParameters(yieldToken_);
    uint256 pricePerShare = ITokenAdapter(yieldTokenParams.adapter).price();

    uint8 yieldTokenDecimals = TokenUtils.expectDecimals(yieldToken_);
    uint256 baseTokenAmount = ((pricePerShare * shares) /
      10 ** yieldTokenDecimals);
    address baseToken = yieldTokenParams.baseToken;
    uint256 price = _getBaseTokenPrice(
      svyPriceFeed_,
      baseToken,
      baseTokenAmount
    );

    return price;
  }

  /// @notice Get usd amount deposited with the base token by all users.
  /// @param yieldToken_ The address of an yield token.
  /// @param savvyPositionManager_ The address of a savvyPositionManager.
  /// @return USD amount.
  function _getDepositedTokenPrice(
    address yieldToken_,
    address savvyPositionManager_,
    ISavvyPriceFeed svyPriceFeed_
  ) internal view returns (uint256) {
    IYieldStrategyManager yieldStrategyManager = ISavvyPositionManager(
      savvyPositionManager_
    ).yieldStrategyManager();

    ISavvyState.YieldTokenParams memory yieldTokenParams = yieldStrategyManager
      .getYieldTokenParameters(yieldToken_);
    uint256 shares = yieldTokenParams.totalShares;
    uint256 pricePerShare = ITokenAdapter(yieldTokenParams.adapter).price();

    uint8 yieldTokenDecimals = TokenUtils.expectDecimals(yieldToken_);
    uint256 baseTokenAmount = ((pricePerShare * shares) /
      10 ** yieldTokenDecimals);
    address baseToken = yieldTokenParams.baseToken;
    uint256 price = _getBaseTokenPrice(
      svyPriceFeed_,
      baseToken,
      baseTokenAmount
    );

    return price;
  }

  /// @notice Check that yieldToken is added to support tokens before.
  /// @param yieldTokenAddress_ The address of a yield token.
  /// @return return bool if already added, if not, return false.
  function _checkSupportTokenExist(
    ISavvyInfoAggregatorStructs.SupportTokenInfo[] memory supportTokens,
    address yieldTokenAddress_
  ) internal pure returns (bool) {
    uint256 length = supportTokens.length;

    for (uint256 i = 0; i < length; i++) {
      if (supportTokens[i].yieldToken == yieldTokenAddress_) {
        return true;
      }
    }

    return false;
  }

  function _getWithdrawableAmount(
    address owner_,
    ISavvyPositionManager savvyPositionManager_
  )
    internal
    view
    returns (ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[] memory)
  {
    address account = owner_;
    ISavvyPositionManager positionManager = savvyPositionManager_;
    IYieldStrategyManager strategyManager = positionManager
      .yieldStrategyManager();
    (int256 debt, address[] memory depositedTokens) = positionManager.accounts(
      account
    );
    uint256 length = depositedTokens.length;

    if (length == 0) {
      return new ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[](0);
    }

    uint256 totalValue = _getTotalValue(
      account,
      depositedTokens,
      positionManager,
      strategyManager
    );
    uint256 minCollateralization = positionManager.minimumCollateralization();
    uint256 virtualDebt = debt <= 0 ? 0 : uint256(debt);

    bool withdrawable = true;
    if (virtualDebt > 0) {
      uint256 collateralization = (totalValue * FIXED_POINT_SCALAR) /
        virtualDebt;
      if (collateralization < minCollateralization) {
        withdrawable = false;
      }
    }

    uint256 withdrawableValue = !withdrawable
      ? 0
      : (totalValue -
        (minCollateralization * virtualDebt) /
        FIXED_POINT_SCALAR);
    if (withdrawableValue <= OFFSET_RANGE) {
      withdrawable = false;
    }

    withdrawableValue = !withdrawable ? 0 : withdrawableValue;

    return
      _getWithdrawableShares(
        length,
        withdrawableValue,
        account,
        depositedTokens,
        positionManager
      );
  }

  function _getWithdrawableShares(
    uint256 _length,
    uint256 _withdrawableValue,
    address _account,
    address[] memory _depositedTokens,
    ISavvyPositionManager _positionManager
  )
    internal
    view
    returns (ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[] memory)
  {
    ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[]
      memory withdrawInfos = new ISavvyInfoAggregatorStructs.SavvyWithdrawInfo[](
        _length
      );
    IYieldStrategyManager strategyManager = _positionManager
      .yieldStrategyManager();
    uint256 availableValue = _withdrawableValue;
    for (uint256 i = 0; i < _length; i++) {
      address yieldToken = _depositedTokens[i];
      withdrawInfos[i] = ISavvyInfoAggregatorStructs.SavvyWithdrawInfo(
        address(_positionManager),
        yieldToken,
        0,
        0
      );

      if (availableValue > 0) {
        ISavvyTokenParams.YieldTokenParams
          memory yieldTokenParams = strategyManager.getYieldTokenParams(
            yieldToken
          );
        address baseToken = yieldTokenParams.baseToken;
        (uint256 shares, , ) = _positionManager.positions(_account, yieldToken);
        (, uint256 amountBaseTokens) = strategyManager
          .convertSharesToBaseTokens(yieldToken, shares);
        ISavvyTokenParams.BaseTokenParams memory _baseToken = strategyManager
          .getBaseTokenParams(baseToken);
        uint256 value = amountBaseTokens * _baseToken.conversionFactor;
        uint256 withdrawableShares = Math.min(
          (availableValue / _baseToken.conversionFactor) *
            _baseToken.conversionFactor, // truncate extra decimals that cannot be represented by the token
          value
        );
        withdrawInfos[i].amount = withdrawableShares;
        withdrawableShares = strategyManager.convertBaseTokensToShares(
          yieldToken,
          withdrawableShares / _baseToken.conversionFactor
        );
        withdrawInfos[i].shares = withdrawableShares;
      }
    }

    return withdrawInfos;
  }

  function _getTotalValue(
    address account_,
    address[] memory depositedTokens_,
    ISavvyPositionManager savvyPositionManager_,
    IYieldStrategyManager strategyManager_
  ) internal view returns (uint256 totalValue) {
    totalValue = 0;
    uint256 length = depositedTokens_.length;
    for (uint256 i = 0; i < length; i++) {
      address yieldToken = depositedTokens_[i];
      ISavvyTokenParams.YieldTokenParams
        memory yieldTokenParams = strategyManager_.getYieldTokenParams(
          yieldToken
        );
      address baseToken = yieldTokenParams.baseToken;
      (uint256 shares, , ) = savvyPositionManager_.positions(
        account_,
        yieldToken
      );
      (, uint256 amountBaseTokens) = strategyManager_.convertSharesToBaseTokens(
        yieldToken,
        shares
      );

      ISavvyTokenParams.BaseTokenParams memory _baseToken = strategyManager_
        .getBaseTokenParams(baseToken);
      totalValue += amountBaseTokens * _baseToken.conversionFactor;
    }
  }

  /// @notice Get the synthetic credit line for a SavvyPositionManager.
  /// @param owner_ The account to query the synthetic credit line for.
  /// @param savvyPositionManager_ SavvyPositionManager to borrow against.
  /// @return The amount of synthetic that a user can borrow.
  function _getBorrowableAmount(
    address owner_,
    ISavvyPositionManager savvyPositionManager_
  ) internal view returns (uint256) {
    IYieldStrategyManager strategyManager = savvyPositionManager_
      .yieldStrategyManager();
    uint256 borrowLimit = strategyManager.currentBorrowingLimiter();
    address account = owner_;
    (int256 debt, address[] memory depositedTokens) = savvyPositionManager_
      .accounts(account);
    if (depositedTokens.length == 0 || borrowLimit == 0) {
      return 0;
    }

    uint256 totalValue = _getTotalValue(
      account,
      depositedTokens,
      savvyPositionManager_,
      strategyManager
    );
    uint256 minCollateralization = savvyPositionManager_
      .minimumCollateralization();
    uint256 virtualDebt = debt <= 0 ? 0 : uint256(debt);

    if (virtualDebt > 0) {
      uint256 collateralization = (totalValue * FIXED_POINT_SCALAR) /
        virtualDebt;
      if (collateralization < minCollateralization) {
        return 0;
      }
    }

    uint256 borrowableAmount = ((totalValue -
      (minCollateralization * virtualDebt) /
      FIXED_POINT_SCALAR) * FIXED_POINT_SCALAR) / minCollateralization;
    borrowableAmount = debt < 0
      ? borrowableAmount + uint256(-1 * debt)
      : borrowableAmount;
    if (borrowableAmount <= OFFSET_RANGE) {
      return 0;
    }

    return Math.min(borrowableAmount, borrowLimit);
  }

  /// @notice Gets information for the Dashboard page.
  ///
  /// @notice `account_` must be a non-zero address
  /// or this call will revert with a {IllegalArgument} error.
  ///
  /// @param account_ The specific wallet to get information for.
  /// @return poolsInfo Information for the Dashboard page.
  function _getDashboardPageInfo(
    address[] memory savvyPositionManagers,
    address account_,
    ISavvyPriceFeed svyPriceFeed_
  )
    internal
    view
    returns (ISavvyInfoAggregatorStructs.DashboardPageInfo memory)
  {
    Checker.checkArgument(account_ != address(0), "zero account address");

    // [prework] find number of supported base tokens and initialize arrays for DashboardPageInfo.
    uint256 numOfSavvyPositionManagers = savvyPositionManagers.length;

    uint256 numOfBaseTokens = 0;
    for (uint256 i = 0; i < numOfSavvyPositionManagers; i++) {
      ISavvyPositionManager savvyPositionManager = ISavvyPositionManager(
        savvyPositionManagers[i]
      );
      IYieldStrategyManager yieldStrategyManager = IYieldStrategyManager(
        savvyPositionManager.yieldStrategyManager()
      );
      address[] memory supportedTokens = yieldStrategyManager
        .getSupportedBaseTokens();
      for (uint256 j = 0; j < supportedTokens.length; j++) {
        if (
          yieldStrategyManager
            .getBaseTokenParameters(supportedTokens[j])
            .enabled
        ) {
          numOfBaseTokens++;
        }
      }
    }

    ISavvyInfoAggregatorStructs.FullSavvyPosition[]
      memory debtTokens = new ISavvyInfoAggregatorStructs.FullSavvyPosition[](
        numOfSavvyPositionManagers
      );
    ISavvyInfoAggregatorStructs.FullSavvyPosition[]
      memory depositedTokens = new ISavvyInfoAggregatorStructs.FullSavvyPosition[](
        numOfBaseTokens
      );
    ISavvyInfoAggregatorStructs.FullSavvyPosition[]
      memory availableDeposit = new ISavvyInfoAggregatorStructs.FullSavvyPosition[](
        numOfBaseTokens
      );
    ISavvyInfoAggregatorStructs.FullSavvyPosition[]
      memory availableCredit = new ISavvyInfoAggregatorStructs.FullSavvyPosition[](
        numOfSavvyPositionManagers
      );
    ISavvyInfoAggregatorStructs.FullDebtInfo[]
      memory outstandingDebt = new ISavvyInfoAggregatorStructs.FullDebtInfo[](
        numOfSavvyPositionManagers
      );

    // [work] populate arrays for DashboardPageInfo.
    for (uint256 i = 0; i < numOfSavvyPositionManagers; i++) {
      ISavvyPositionManager savvyPositionManager = ISavvyPositionManager(
        savvyPositionManagers[i]
      );
      IYieldStrategyManager yieldStrategyManager = IYieldStrategyManager(
        savvyPositionManager.yieldStrategyManager()
      );

      debtTokens[i] = _getFullDebtTokenPosition(
        account_,
        svyPriceFeed_,
        savvyPositionManager
      );
      availableCredit[i] = _getFullAvailableCreditPosition(
        account_,
        savvyPositionManager,
        svyPriceFeed_
      );
      outstandingDebt[i] = _getFullOutstandingDebtInfo(
        account_,
        svyPriceFeed_,
        savvyPositionManager
      );

      address[] memory supportedYieldTokens = yieldStrategyManager
        .getSupportedYieldTokens();
      address account = account_;
      ISavvyPriceFeed priceFeed = svyPriceFeed_;
      for (uint256 j = 0; j < supportedYieldTokens.length; j++) {
        if (
          !yieldStrategyManager
            .getYieldTokenParameters(supportedYieldTokens[j])
            .enabled
        ) {
          continue;
        }
        ISavvyInfoAggregatorStructs.FullSavvyPosition
          memory depositedTokenPosition = _getFullDepositedTokenPosition(
            account,
            supportedYieldTokens[j],
            savvyPositionManager,
            yieldStrategyManager,
            priceFeed
          );

        address baseTokenAddress = depositedTokenPosition.token;
        if (
          !yieldStrategyManager.getBaseTokenParameters(baseTokenAddress).enabled
        ) {
          continue;
        }

        uint256 idx = _findIndexFromFullSavvyPositionArray(
          depositedTokens,
          baseTokenAddress
        );
        depositedTokens[idx].token = baseTokenAddress;
        depositedTokens[idx].amount += depositedTokenPosition.amount;
        depositedTokens[idx].valueUSD += depositedTokenPosition.valueUSD;
      }
    }

    // (2022-12-15) moved into its own for loop to resolve stack too deep error.
    for (uint256 i = 0; i < numOfBaseTokens; i++) {
      address baseTokenAddress = depositedTokens[i].token;
      uint256 availableDepositAmount = IERC20(baseTokenAddress).balanceOf(
        account_
      );
      uint8 baseTokenDecimals = TokenUtils.expectDecimals(baseTokenAddress);
      uint256 conversionFactor = (10 ** (18 - baseTokenDecimals));
      availableDeposit[i].token = baseTokenAddress;
      availableDeposit[i].amount = availableDepositAmount * conversionFactor;
      availableDeposit[i].valueUSD = _getBaseTokenPrice(
        svyPriceFeed_,
        baseTokenAddress,
        availableDepositAmount
      );
    }
    // [format] create DashboardPageInfo.
    return
      ISavvyInfoAggregatorStructs.DashboardPageInfo(
        debtTokens,
        depositedTokens,
        availableDeposit,
        availableCredit,
        outstandingDebt
      );
  }

  /// @notice Finds the index of a token's address
  /// in a FullSavvyPosition array. If the token is not
  /// found, the function will return the first empty
  /// index in the array.
  /// @param arr The array to traverse.
  /// @param token The token address to look for.
  /// @return idx The index of the token or the first
  /// available index.
  function _findIndexFromFullSavvyPositionArray(
    ISavvyInfoAggregatorStructs.FullSavvyPosition[] memory arr,
    address token
  ) internal pure returns (uint256) {
    for (uint256 i = 0; i < arr.length; i++) {
      if (arr[i].token == token || arr[i].token == address(0)) {
        return i;
      }
    }
    return arr.length - 1;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IllegalArgument} from "../base/Errors.sol";
import "./Checker.sol";

/// @title  Functions
/// @author Savvy DeFi
library Limiters {
    using Limiters for LinearGrowthLimiter;

    /// @dev A maximum cooldown to avoid malicious governance bricking the contract.
    /// @dev 1 day @ 12 sec / block
    uint256 public constant MAX_COOLDOWN_BLOCKS = 7200;

    /// @dev The scalar used to convert integral types to fixed point numbers.
    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    /// @dev The configuration and state of a linear growth function (LGF).
    struct LinearGrowthLimiter {
        uint256 maximum; /// The maximum limit of the function.
        uint256 rate; /// The rate at which the function increases back to its maximum.
        uint256 lastValue; /// The most recently saved value of the function.
        uint256 lastBlock; /// The block that `lastValue` was recorded.
        uint256 minLimit; /// A minimum limit to avoid malicious governance bricking the contract
    }

    /// @dev Instantiates a new linear growth function.
    ///
    /// @param maximum The maximum value for the LGF.
    /// @param blocks  The number of blocks that determins the rate of the LGF.
    ///
    /// @return The LGF struct.
    function createLinearGrowthLimiter(
        uint256 maximum,
        uint256 blocks,
        uint256 _minLimit
    ) internal view returns (LinearGrowthLimiter memory) {
        Checker.checkArgument(blocks <= MAX_COOLDOWN_BLOCKS, "invalid blocks");
        Checker.checkArgument(maximum >= _minLimit, "invalid minLimit");

        return
            LinearGrowthLimiter({
                maximum: maximum,
                rate: (maximum * FIXED_POINT_SCALAR) / blocks,
                lastValue: maximum,
                lastBlock: block.number,
                minLimit: _minLimit
            });
    }

    /// @dev Configure an LGF.
    ///
    /// @param self    The LGF to configure.
    /// @param maximum The maximum value of the LFG.
    /// @param blocks  The number of recovery blocks of the LGF.
    function configure(
        LinearGrowthLimiter storage self,
        uint256 maximum,
        uint256 blocks
    ) internal {
        Checker.checkArgument(blocks <= MAX_COOLDOWN_BLOCKS, "invalid blocks");
        Checker.checkArgument(maximum >= self.minLimit, "invalid minLimit");

        if (self.lastValue > maximum) {
            self.lastValue = maximum;
        }

        self.maximum = maximum;
        self.rate = (maximum * FIXED_POINT_SCALAR) / blocks;
    }

    /// @dev Updates the state of an LGF by updating `lastValue` and `lastBlock`.
    ///
    /// @param self the LGF to update.
    function update(LinearGrowthLimiter storage self) internal {
        self.lastValue = self.get();
        self.lastBlock = block.number;
    }

    /// @dev Increase the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function increase(
        LinearGrowthLimiter storage self,
        uint256 amount
    ) internal {
        uint256 value = self.get();
        self.lastValue = value + amount;
        self.lastBlock = block.number;
    }

    /// @dev Decrease the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function decrease(
        LinearGrowthLimiter storage self,
        uint256 amount
    ) internal {
        uint256 value = self.get();
        self.lastValue = value - amount;
        self.lastBlock = block.number;
    }

    /// @dev Get the current value of the linear growth limiter.
    ///
    /// @return The current value.
    function get(
        LinearGrowthLimiter storage self
    ) internal view returns (uint256) {
        uint256 elapsed = block.number - self.lastBlock;
        if (elapsed == 0) {
            return self.lastValue;
        }
        uint256 delta = (elapsed * self.rate) / FIXED_POINT_SCALAR;
        uint256 value = self.lastValue + delta;
        return value > self.maximum ? self.maximum : value;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// a library for performing various math operations

library Math {
    uint256 public constant WAD = 1e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y >> (1 + 1);
            while (x < z) {
                z = x;
                x = (y / x + x) >> 1;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD >> 1)) / WAD;
    }

    function uoperation(
        uint256 x,
        uint256 y,
        bool addOperation
    ) internal pure returns (uint256 z) {
        if (addOperation) {
            return uadd(x, y);
        } else {
            return usub(x, y);
        }
    }

    /// @dev Subtracts two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z the result.
    function usub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x < y) {
            return 0;
        }
        z = x - y;
    }

    /// @dev Adds two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z The result.
    function uadd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    /// @notice Return minimum uint256 value.
    /// @param x The first operand.
    /// @param y The second operand.
    /// @return z The result
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? y : x;
    }

    /// @notice Return maximum uint256 value.
    /// @param x The first operand.
    /// @param y The second operand.
    /// @return z The result
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        if (a > (type(uint256).max - halfRAY) / b) {
            return 0;
        }

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            return 0;
        }
        uint256 halfB = b / 2;

        if (a > (type(uint256).max - halfB) / RAY) {
            return 0;
        }

        return (a * RAY + halfB) / b;
    }

    /// @notice utility function to find weighted averages without any underflows or zero division problems.
    /// @dev use x to determine weights, with y being the values you're weighting
    /// @param valueToAdd new allotment amount
    /// @param currentValue current allotment amount
    /// @param weightToAdd new amount of y being added to weighted average
    /// @param currentWeight current weighted average of y
    /// @return Update duration
    function findWeightedAverage(
        uint256 valueToAdd,
        uint256 currentValue,
        uint256 weightToAdd,
        uint256 currentWeight
    ) internal pure returns (uint256) {
        uint256 totalWeight = weightToAdd + currentWeight;
        if (totalWeight == 0) {
            return 0;
        }
        uint256 totalValue = (valueToAdd * weightToAdd) +
            (currentValue * currentWeight);
        return totalValue / totalWeight;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IllegalArgument} from "../base/Errors.sol";

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < (1 << 255), "IllegalArgument");
        z = int256(y);
    }

    /// @notice Cast a int256 to a uint256, revert on underflow
    /// @param y The int256 to be casted
    /// @return z The casted integer, now type uint256
    function toUint256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, "IllegalArgument");
        z = uint256(y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/// @title  Sets
/// @author Savvy DeFi
library Sets {
    using Sets for AddressSet;

    /// @notice A data structure holding an array of values with an index mapping for O(1) lookup.
    struct AddressSet {
        address[] values;
        mapping(address => uint256) indexes;
    }

    /// @dev Add a value to a Set
    ///
    /// @param self  The Set.
    /// @param value The value to add.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value is already contained in the Set)
    function add(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        if (self.contains(value)) {
            return false;
        }
        self.values.push(value);
        self.indexes[value] = self.values.length;
        return true;
    }

    /// @dev Remove a value from a Set
    ///
    /// @param self  The Set.
    /// @param value The value to remove.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value was not contained in the Set)
    function remove(
        AddressSet storage self,
        address value
    ) internal returns (bool) {
        uint256 index = self.indexes[value];
        if (index == 0) {
            return false;
        }

        // Normalize the index since we know that the element is in the set.
        index--;

        uint256 lastIndex = self.values.length - 1;

        if (index != lastIndex) {
            address lastValue = self.values[lastIndex];
            self.values[index] = lastValue;
            self.indexes[lastValue] = index + 1;
        }

        self.values.pop();

        delete self.indexes[value];

        return true;
    }

    /// @dev Returns true if the value exists in the Set
    ///
    /// @param self  The Set.
    /// @param value The value to check.
    ///
    /// @return True if the value is contained in the Set, False if it is not.
    function contains(
        AddressSet storage self,
        address value
    ) internal view returns (bool) {
        return self.indexes[value] != 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "../interfaces/savvy/ISavvyErrors.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title  TokenUtils
/// @author Savvy DeFi
library TokenUtils {
    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        require(success, Errors.ERC20CALLFAILED_EXPECTDECIMALS);

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(
        address token,
        address account
    ) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
        );
        require(success, Errors.ERC20CALLFAILED_SAFEBALANCEOF);

        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        SafeERC20.safeTransfer(IERC20(token), recipient, amount);
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(
        address token,
        address spender,
        uint256 value
    ) internal {
        SafeERC20.safeIncreaseAllowance(IERC20(token), spender, value);
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(
        address token,
        address owner,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 balanceBefore = IERC20Minimal(token).balanceOf(recipient);
        SafeERC20.safeTransferFrom(IERC20(token), owner, recipient, amount);
        uint256 balanceAfter = IERC20Minimal(token).balanceOf(recipient);

        return (balanceAfter - balanceBefore);
    }

    /// @dev Mints tokens to an address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
    ///
    /// @param token     The token to mint.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to mint.
    function safeMint(
        address token,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Mintable.mint.selector,
                recipient,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEMINT);
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        require(success, Errors.ERC20CALLFAILED_SAFEBURN);
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(
        address token,
        address owner,
        uint256 amount
    ) internal {
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Burnable.burnFrom.selector,
                owner,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEBURNFROM);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IInfoAggregator.sol";
import "./interfaces/ISavvyPriceFeed.sol";
import "./interfaces/IVeSvy.sol";
import "./interfaces/ISavvyToken.sol";
import "./interfaces/ISavvyBooster.sol";
import "./interfaces/savvySwap/ISavvySwap.sol";

import "./libraries/Checker.sol";
import {InfoAggregatorUtils} from "./libraries/InfoAggregatorUtils.sol";

contract SavvyFrontendInfoAggregator is
    Ownable2StepUpgradeable,
    ISavvyFrontend
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Address of InfoAggregator.
    IInfoAggregator public infoAggregator;

    /// @dev Addresses of SavvySwap.
    EnumerableSet.AddressSet private savvySwaps;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IInfoAggregator infoAggregator_,
        address[] memory savvySwaps_
    ) public initializer {
        Checker.checkArgument(
            address(infoAggregator_) != address(0),
            "zero infoAggregator address"
        );
        infoAggregator = infoAggregator_;
        uint256 length = savvySwaps_.length;
        for (uint256 i = 0; i < length; i++) {
            address savvySwap_ = savvySwaps_[i];
            Checker.checkArgument(
                savvySwap_ != address(0),
                "SavvySwap address cannot be zero"
            );
            Checker.checkArgument(
                !savvySwaps.contains(savvySwap_),
                "SavvySwap already exists"
            );
            savvySwaps.add(savvySwap_);
        }
        __Ownable_init();
    }

    /// @inheritdoc ISavvyFrontend
    function setInfoAggregator(
        address infoAggregator_
    ) external override onlyOwner {
        Checker.checkArgument(
            address(infoAggregator_) != address(0),
            "zero infoAggregator address"
        );
        infoAggregator = IInfoAggregator(infoAggregator_);
    }

    /// @inheritdoc	ISavvyFrontend
    function setSavvySwap(
        address[] memory savvySwaps_,
        bool[] memory shouldAdd_
    ) external override onlyOwner {
        Checker.checkArgument(
            savvySwaps_.length == shouldAdd_.length,
            "SavvySwaps and ShouldAdd need to have the same length."
        );
        uint256 length = savvySwaps_.length;
        Checker.checkArgument(length > 0, "empty SavvySwaps array");

        for (uint256 i = 0; i < length; i++) {
            address savvySwap = savvySwaps_[i];
            Checker.checkArgument(
                savvySwap != address(0),
                "zero SavvySwaps address"
            );
            if (shouldAdd_[i]) {
                Checker.checkArgument(
                    savvySwaps.contains(savvySwap) == false,
                    "SavvySwap already exists"
                );
                savvySwaps.add(savvySwap);
            } else {
                savvySwaps.remove(savvySwap);
            }
        }
    }

    function getSavvySwaps()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return savvySwaps.values();
    }

    /// @inheritdoc ISavvyFrontend
    function getDashboardPageInfo(
        address account_
    ) external view override returns (DashboardPageInfo memory) {
        return
            InfoAggregatorUtils._getDashboardPageInfo(
                infoAggregator.getSavvyPositionManagers(),
                account_,
                infoAggregator.svyPriceFeed()
            );
    }

    /// @inheritdoc ISavvyFrontend
    function getPoolsPageInfo(
        address account_
    ) external view override returns (PoolsPageInfo memory) {
        Checker.checkArgument(account_ != address(0), "zero account address");

        address[] memory savvyPositionManagers = infoAggregator
            .getSavvyPositionManagers();
        ISavvyPriceFeed svyPriceFeed = infoAggregator.svyPriceFeed();
        FullPoolInfo[] memory poolsInfo = InfoAggregatorUtils._getPoolsInfo(
            svyPriceFeed,
            savvyPositionManagers,
            account_
        );
        DashboardPageInfo memory dashboardPageInfo = InfoAggregatorUtils
            ._getDashboardPageInfo(
                savvyPositionManagers,
                account_,
                svyPriceFeed
            );
        return
            PoolsPageInfo(
                poolsInfo,
                dashboardPageInfo.debtTokens,
                dashboardPageInfo.availableDeposit,
                dashboardPageInfo.availableCredit,
                dashboardPageInfo.outstandingDebt
            );
    }

    /// @inheritdoc ISavvyFrontend
    function getMySVYPageInfo(
        address account_
    ) external view override returns (MySVYPageInfo memory) {
        Checker.checkArgument(account_ != address(0), "zero account address");

        ISavvyToken svyToken = infoAggregator.svyToken();
        IVeSvy veSvy = infoAggregator.veSvy();
        ISavvyBooster svyBooster = infoAggregator.svyBooster();
        return
            MySVYPageInfo(
                svyToken.balanceOf(account_), //svyBalance
                veSvy.getStakedSvy(account_), //stakedSVYBalance
                svyBooster.getClaimableRewards(account_), //claimableSVY
                svyBooster.getSvyEarnRate(account_), //svyEarnRatePerSec
                veSvy.balanceOf(account_), //veSVYBalance
                veSvy.claimable(account_), //claimableVeSVY
                veSvy.getVeSVYEarnRatePerSec(account_), //veSVYEarnRatePerSec
                veSvy.getMaxVeSVYEarnable(account_) //maxSvyEarnable
            );
    }

    /// @inheritdoc ISavvyFrontend
    function getSwapPageInfo(
        address account_
    ) external view override returns (SwapPageInfo memory) {
        Checker.checkArgument(account_ != address(0), "zero account address");

        uint256 length = savvySwaps.length();
        SwapInfo[] memory swapInfos = new SwapInfo[](length);

        for (uint256 i = 0; i < length; i++) {
            ISavvySwap savvySwap = ISavvySwap(savvySwaps.at(i));
            IERC20 depositToken = IERC20(savvySwap.syntheticToken());
            swapInfos[i] = SwapInfo(
                address(savvySwap), // savvySwap
                address(depositToken), // depositToken
                savvySwap.baseToken(), // swapTargetToken
                depositToken.balanceOf(account_), // availableDepositAmount
                savvySwap.getUnswappedBalance(account_), // depositedAmount
                savvySwap.getClaimableBalance(account_) *
                    savvySwap.conversionFactor() // claimableAmount
            );
        }

        return SwapPageInfo(swapInfos);
    }
}