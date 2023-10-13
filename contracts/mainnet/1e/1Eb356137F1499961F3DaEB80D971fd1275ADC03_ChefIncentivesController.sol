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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IEligibilityDataProvider {
	function refresh(address user) external returns (bool currentEligibility);

	function updatePrice() external;

	function requiredEthValue(address user) external view returns (uint256 required);

	function isEligibleForRewards(address _user) external view returns (bool isEligible);

	function lastEligibleTime(address user) external view returns (uint256 lastEligibleTimestamp);

	function lockedUsdValue(address user) external view returns (uint256);

	function requiredUsdValue(address user) external view returns (uint256 required);

	function lastEligibleStatus(address user) external view returns (bool);

	function rewardEligibleAmount(address token) external view returns (uint256);

	function setDqTime(address _user, uint256 _time) external;

	function getDqTime(address _user) external view returns (uint256);

	function autoprune() external returns (uint256 processed);

	function requiredDepositRatio() external view returns (uint256);

	function RATIO_DIVISOR() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function removeReward(address _rewardToken) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface ILeverager {
	function wethToZap(address user) external view returns (uint256);

	function zapWETHWithBorrow(uint256 amount, address borrower) external returns (uint256 liquidity);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import {IFeeDistribution} from "./IMultiFeeDistribution.sol";

interface IMiddleFeeDistribution is IFeeDistribution {
	function forwardReward(address[] memory _rewardTokens) external;

	function getRdntTokenAddress() external view returns (address);

	function getMultiFeeDistributionAddress() external view returns (address);

	function operationExpenseRatio() external view returns (uint256);

	function operationExpenses() external view returns (address);

	function isRewardToken(address) external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableToken is IERC20 {
	function mint(address _receiver, uint256 _amount) external returns (bool);

	function burn(uint256 _amount) external returns (bool);

	function setMinter(address _minter) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./LockedBalance.sol";
import "./IFeeDistribution.sol";
import "./IMintableToken.sol";

interface IMultiFeeDistribution is IFeeDistribution {
	function exit(bool claimRewards) external;

	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external;

	function rdntToken() external view returns (IMintableToken);

	function getPriceProvider() external view returns (address);

	function lockInfo(address user) external view returns (LockedBalance[] memory);

	function autocompoundEnabled(address user) external view returns (bool);

	function defaultLockIndex(address _user) external view returns (uint256);

	function autoRelockDisabled(address user) external view returns (bool);

	function totalBalance(address user) external view returns (uint256);

	function lockedBalance(address user) external view returns (uint256);

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);

	function getBalances(address _user) external view returns (Balances memory);

	function zapVestingToLp(address _address) external returns (uint256);

	function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

	function setDefaultRelockTypeIndex(uint256 _index) external;

	function daoTreasury() external view returns (address);

	function stakingToken() external view returns (address);

	function userSlippage(address) external view returns (uint256);

	function claimFromConverter(address) external;

	function vestTokens(address user, uint256 amount, bool withPenalty) external;
}

interface IMFDPlus is IMultiFeeDistribution {
	function getLastClaimTime(address _user) external returns (uint256);

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function claimCompound(address _user, bool _execute, uint256 _slippage) external returns (uint256 bountyAmt);

	function setAutocompound(bool _newVal) external;

	function setUserSlippage(uint256 slippage) external;

	function toggleAutocompound() external;

	function getAutocompoundEnabled(address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IOnwardIncentivesController {
	function handleAction(address _token, address _user, uint256 _balance, uint256 _totalSupply) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

struct LockedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 multiplier;
	uint256 duration;
}

struct EarnedBalance {
	uint256 amount;
	uint256 unlockTime;
	uint256 penalty;
}

struct Reward {
	uint256 periodFinish;
	uint256 rewardPerSecond;
	uint256 lastUpdateTime;
	uint256 rewardPerTokenStored;
	// tracks already-added balances to handle accrued interest in aToken rewards
	// for the stakingToken this value is unused and will always be 0
	uint256 balance;
}

struct Balances {
	uint256 total; // sum of earnings and lockings; no use when LP and RDNT is different
	uint256 unlocked; // RDNT token
	uint256 locked; // LP token or RDNT token
	uint256 lockedWithMultiplier; // Multiplied locked amount
	uint256 earned; // RDNT token
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title RecoverERC20 contract
/// @author Radiant Devs
/// @dev All function calls are currently implemented without side effects
contract RecoverERC20 {
	using SafeERC20 for IERC20;

	/// @notice Emitted when ERC20 token is recovered
	event Recovered(address indexed token, uint256 amount);

	/**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
	 */
	function _recoverERC20(address tokenAddress, uint256 tokenAmount) internal {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import {RecoverERC20} from "../libraries/RecoverERC20.sol";
import {IMultiFeeDistribution} from "../../interfaces/IMultiFeeDistribution.sol";
import {IEligibilityDataProvider} from "../../interfaces/IEligibilityDataProvider.sol";
import {IOnwardIncentivesController} from "../../interfaces/IOnwardIncentivesController.sol";
import {IMiddleFeeDistribution} from "../../interfaces/IMiddleFeeDistribution.sol";
import {ILeverager} from "../../interfaces/ILeverager.sol";

/// @title ChefIncentivesController Contract
/// @author Radiant
/// based on the Sushi MasterChef
///	https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
contract ChefIncentivesController is Initializable, PausableUpgradeable, OwnableUpgradeable, RecoverERC20 {
	using SafeERC20 for IERC20;

	// Info of each user.
	// reward = user.`amount` * pool.`accRewardPerShare` - `rewardDebt`
	struct UserInfo {
		uint256 amount;
		uint256 rewardDebt;
		uint256 enterTime; // legacy value, kept to retain storage structure of userInfo array.
		uint256 lastClaimTime;
	}

	// Info of each pool.
	struct PoolInfo {
		uint256 totalSupply;
		uint256 allocPoint; // How many allocation points assigned to this pool.
		uint256 lastRewardTime; // Last second that reward distribution occurs.
		uint256 accRewardPerShare; // Accumulated rewards per share, times ACC_REWARD_PRECISION. See below.
		IOnwardIncentivesController onwardIncentives;
	}

	// Info about token emissions for a given time period.
	struct EmissionPoint {
		uint128 startTimeOffset;
		uint128 rewardsPerSecond;
	}

	// Info about ending time of reward emissions
	struct EndingTime {
		uint256 estimatedTime;
		uint256 lastUpdatedTime;
		uint256 updateCadence;
	}

	/********************** Events ***********************/
	// Emitted when rewardPerSecond is updated
	event RewardsPerSecondUpdated(uint256 indexed rewardsPerSecond, bool persist);

	event BalanceUpdated(address indexed token, address indexed user, uint256 balance, uint256 totalSupply);

	event EmissionScheduleAppended(uint256[] startTimeOffsets, uint256[] rewardsPerSeconds);

	event ChefReserveLow(uint256 indexed _balance);

	event Disqualified(address indexed user);

	event OnwardIncentivesUpdated(address indexed _token, IOnwardIncentivesController _incentives);

	event BountyManagerUpdated(address indexed _bountyManager);

	event EligibilityEnabledUpdated(bool indexed _newVal);

	event BatchAllocPointsUpdated(address[] _tokens, uint256[] _allocPoints);

	event AuthorizedContractUpdated(address _contract, bool _authorized);

	event EndingTimeUpdateCadence(uint256 indexed _lapse);

	event RewardDeposit(uint256 indexed _amount);

	/********************** Errors ***********************/
	error AddressZero();

	error UnknownPool();

	error PoolExists();

	error AlreadyStarted();

	error NotAllowed();

	error ArrayLengthMismatch();

	error NotAscending();

	error ExceedsMaxInt();

	error InvalidStart();

	error InvalidRToken();

	error InsufficientPermission();

	error AuthorizationAlreadySet();

	error NotMFD();

	error BountyOnly();

	error NotEligible();

	error CadenceTooLong();

	error NotRTokenOrMfd();

	error OutOfRewards();

	error NothingToVest();

	error DuplicateSchedule();

	// multiplier for reward calc
	uint256 private constant ACC_REWARD_PRECISION = 1e12;

	// Data about the future reward rates. emissionSchedule stored in chronological order,
	// whenever the duration since the start timestamp exceeds the next timestamp offset a new
	// reward rate is applied.
	EmissionPoint[] public emissionSchedule;

	// If true, keep this new reward rate indefinitely
	// If false, keep this reward rate until the next scheduled block offset, then return to the schedule.
	bool public persistRewardsPerSecond;

	/********************** Emission Info ***********************/

	// Array of tokens for reward
	address[] public registeredTokens;

	// Current reward per second
	uint256 public rewardsPerSecond;

	// last RPS, used during refill after reserve empty
	uint256 public lastRPS;

	// Index in emission schedule which the last rewardsPerSeconds was used
	// only used for scheduled rewards
	uint256 public emissionScheduleIndex;

	// Info of each pool.
	mapping(address => PoolInfo) public poolInfo;
	mapping(address => bool) private validRTokens;

	// Total allocation points. Must be the sum of all allocation points in all pools.
	uint256 public totalAllocPoint;

	// token => user => Info of each user that stakes LP tokens.
	mapping(address => mapping(address => UserInfo)) public userInfo;

	// user => base claimable balance
	mapping(address => uint256) public userBaseClaimable;

	// MFD, bounties, AC, middlefee
	mapping(address => bool) public eligibilityExempt;

	// The block number when reward mining starts.
	uint256 public startTime;

	// Option for eligibility
	bool public eligibilityEnabled;

	// Address for PoolConfigurator
	address public poolConfigurator;

	// Amount of deposited rewards
	uint256 public depositedRewards;

	// Amount of accumulated rewards
	uint256 public accountedRewards;

	// Timestamp when all pools updated
	uint256 public lastAllPoolUpdate;

	// Middle Fee Distribution contract
	IMiddleFeeDistribution public rewardMinter;

	// Eligiblity Data Provider contract
	IEligibilityDataProvider public eligibleDataProvider;

	// Bounty Manager contract
	address public bountyManager;

	// Info of reward emission end time
	EndingTime public endingTime;

	// Contracts that are authorized to handle r/vdToken actions without triggering elgiibility checks
	mapping(address => bool) public authorizedContracts;

	/**
	 * @notice Initializer
	 * @param _poolConfigurator Pool configurator address
	 * @param _eligibleDataProvider Eligibility Data provider address
	 * @param _rewardMinter Middle fee distribution contract
	 * @param _rewardsPerSecond RPS
	 */
	function initialize(
		address _poolConfigurator,
		IEligibilityDataProvider _eligibleDataProvider,
		IMiddleFeeDistribution _rewardMinter,
		uint256 _rewardsPerSecond
	) public initializer {
		if (_poolConfigurator == address(0)) revert AddressZero();
		if (address(_eligibleDataProvider) == address(0)) revert AddressZero();
		if (address(_rewardMinter) == address(0)) revert AddressZero();

		__Ownable_init();
		__Pausable_init();

		poolConfigurator = _poolConfigurator;
		eligibleDataProvider = _eligibleDataProvider;
		rewardMinter = _rewardMinter;
		rewardsPerSecond = _rewardsPerSecond;
		persistRewardsPerSecond = true;

		eligibilityEnabled = true;
	}

	/**
	 * @dev Returns length of reward pools.
	 */
	function poolLength() public view returns (uint256) {
		return registeredTokens.length;
	}

	/**
	 * @dev Returns address of MFD.
	 * @return mfd contract address
	 */
	function _getMfd() internal view returns (IMultiFeeDistribution mfd) {
		address multiFeeDistribution = rewardMinter.getMultiFeeDistributionAddress();
		mfd = IMultiFeeDistribution(multiFeeDistribution);
	}

	/**
	 * @notice Sets incentive controllers for custom token.
	 * @param _token for reward pool
	 * @param _incentives incentives contract address
	 */
	function setOnwardIncentives(address _token, IOnwardIncentivesController _incentives) external onlyOwner {
		PoolInfo storage pool = poolInfo[_token];
		if (pool.lastRewardTime == 0) revert UnknownPool();
		pool.onwardIncentives = _incentives;
		emit OnwardIncentivesUpdated(_token, _incentives);
	}

	/**
	 * @dev Updates bounty manager contract.
	 * @param _bountyManager Bounty Manager contract.
	 */
	function setBountyManager(address _bountyManager) external onlyOwner {
		bountyManager = _bountyManager;
		emit BountyManagerUpdated(_bountyManager);
	}

	/**
	 * @dev Enable/Disable eligibility
	 * @param _newVal New value.
	 */
	function setEligibilityEnabled(bool _newVal) external onlyOwner {
		eligibilityEnabled = _newVal;
		emit EligibilityEnabledUpdated(_newVal);
	}

	/********************** Pool Setup + Admin ***********************/

	/**
	 * @dev Starts RDNT emission.
	 */
	function start() public onlyOwner {
		if (startTime != 0) revert AlreadyStarted();
		startTime = block.timestamp;
	}

	/**
	 * @dev Add a new lp to the pool. Can only be called by the poolConfigurator.
	 * @param _token for reward pool
	 * @param _allocPoint allocation point of the pool
	 */
	function addPool(address _token, uint256 _allocPoint) external {
		if (msg.sender != poolConfigurator) revert NotAllowed();
		if (poolInfo[_token].lastRewardTime != 0) revert PoolExists();
		_updateEmissions();
		totalAllocPoint = totalAllocPoint + _allocPoint;
		registeredTokens.push(_token);
		PoolInfo storage pool = poolInfo[_token];
		pool.allocPoint = _allocPoint;
		pool.lastRewardTime = block.timestamp;
		pool.onwardIncentives = IOnwardIncentivesController(address(0));
		validRTokens[_token] = true;
	}

	/**
	 * @dev Update the given pool's allocation point. Can only be called by the owner.
	 * @param _tokens for reward pools
	 * @param _allocPoints allocation points of the pools
	 */
	function batchUpdateAllocPoint(address[] calldata _tokens, uint256[] calldata _allocPoints) external onlyOwner {
		if (_tokens.length != _allocPoints.length) revert ArrayLengthMismatch();
		_massUpdatePools();
		uint256 _totalAllocPoint = totalAllocPoint;
		uint256 length = _tokens.length;
		for (uint256 i; i < length; ) {
			PoolInfo storage pool = poolInfo[_tokens[i]];
			if (pool.lastRewardTime == 0) revert UnknownPool();
			_totalAllocPoint = _totalAllocPoint - pool.allocPoint + _allocPoints[i];
			pool.allocPoint = _allocPoints[i];
			unchecked {
				i++;
			}
		}
		totalAllocPoint = _totalAllocPoint;
		emit BatchAllocPointsUpdated(_tokens, _allocPoints);
	}

	/**
	 * @notice Sets the reward per second to be distributed. Can only be called by the owner.
	 * @dev Its decimals count is ACC_REWARD_PRECISION
	 * @param _rewardsPerSecond The amount of reward to be distributed per second.
	 * @param _persist true if RPS is fixed, otherwise RPS is by emission schedule.
	 */
	function setRewardsPerSecond(uint256 _rewardsPerSecond, bool _persist) external onlyOwner {
		_massUpdatePools();
		rewardsPerSecond = _rewardsPerSecond;
		persistRewardsPerSecond = _persist;
		emit RewardsPerSecondUpdated(_rewardsPerSecond, _persist);
	}

	/**
	 * @dev Updates RPS.
	 */
	function setScheduledRewardsPerSecond() internal {
		if (!persistRewardsPerSecond) {
			uint256 length = emissionSchedule.length;
			uint256 i = emissionScheduleIndex;
			uint128 offset = uint128(block.timestamp - startTime);
			for (; i < length && offset >= emissionSchedule[i].startTimeOffset; ) {
				unchecked {
					i++;
				}
			}
			if (i > emissionScheduleIndex) {
				emissionScheduleIndex = i;
				_massUpdatePools();
				rewardsPerSecond = uint256(emissionSchedule[i - 1].rewardsPerSecond);
			}
		}
	}

	/**
	 * @notice Ensure that the specified time offset hasn't been registered already.
	 * @param _startTimeOffset time offset
	 * @return true if the specified time offset is already registered
	 */
	function _checkDuplicateSchedule(uint256 _startTimeOffset) internal view returns (bool) {
		uint256 length = emissionSchedule.length;
		for (uint256 i = 0; i < length; ) {
			if (emissionSchedule[i].startTimeOffset == _startTimeOffset) {
				return true;
			}
			unchecked {
				i++;
			}
		}
		return false;
	}

	/**
	 * @notice Updates RDNT emission schedule.
	 * @dev This appends the new offsets and RPS.
	 * @param _startTimeOffsets Offsets array.
	 * @param _rewardsPerSecond RPS array.
	 */
	function setEmissionSchedule(
		uint256[] calldata _startTimeOffsets,
		uint256[] calldata _rewardsPerSecond
	) external onlyOwner {
		uint256 length = _startTimeOffsets.length;
		if (length <= 0 || length != _rewardsPerSecond.length) revert ArrayLengthMismatch();

		for (uint256 i = 0; i < length; ) {
			if (i > 0) {
				if (_startTimeOffsets[i - 1] > _startTimeOffsets[i]) revert NotAscending();
			}
			if (_startTimeOffsets[i] > type(uint128).max) revert ExceedsMaxInt();
			if (_rewardsPerSecond[i] > type(uint128).max) revert ExceedsMaxInt();
			if (_checkDuplicateSchedule(_startTimeOffsets[i])) revert DuplicateSchedule();

			if (startTime > 0) {
				if (_startTimeOffsets[i] < block.timestamp - startTime) revert InvalidStart();
			}
			emissionSchedule.push(
				EmissionPoint({
					startTimeOffset: uint128(_startTimeOffsets[i]),
					rewardsPerSecond: uint128(_rewardsPerSecond[i])
				})
			);
			unchecked {
				i++;
			}
		}
		emit EmissionScheduleAppended(_startTimeOffsets, _rewardsPerSecond);
	}

	/**
	 * @notice Recover tokens in this contract. Callable by owner.
	 * @param tokenAddress Token address for recover
	 * @param tokenAmount Amount to recover
	 */
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		_recoverERC20(tokenAddress, tokenAmount);
	}

	/********************** Pool State Changers ***********************/

	/**
	 * @dev Update emission params of CIC.
	 */
	function _updateEmissions() internal {
		if (block.timestamp > endRewardTime()) {
			_massUpdatePools();
			lastRPS = rewardsPerSecond;
			rewardsPerSecond = 0;
			return;
		}
		setScheduledRewardsPerSecond();
	}

	/**
	 * @dev Update reward variables for all pools.
	 */
	function _massUpdatePools() internal {
		uint256 totalAP = totalAllocPoint;
		uint256 length = poolLength();
		for (uint256 i; i < length; ) {
			_updatePool(poolInfo[registeredTokens[i]], totalAP);
			unchecked {
				i++;
			}
		}
		lastAllPoolUpdate = block.timestamp;
	}

	/**
	 * @dev Update reward variables of the given pool to be up-to-date.
	 * @param pool pool info
	 * @param _totalAllocPoint allocation point of the pool
	 */
	function _updatePool(PoolInfo storage pool, uint256 _totalAllocPoint) internal {
		uint256 timestamp = block.timestamp;
		uint256 endReward = endRewardTime();
		if (endReward <= timestamp) {
			timestamp = endReward;
		}
		if (timestamp <= pool.lastRewardTime) {
			return;
		}

		(uint256 reward, uint256 newAccRewardPerShare) = _newRewards(pool, _totalAllocPoint);
		accountedRewards = accountedRewards + reward;
		pool.accRewardPerShare = pool.accRewardPerShare + newAccRewardPerShare;
		pool.lastRewardTime = timestamp;
	}

	/********************** Emission Calc + Transfer ***********************/

	/**
	 * @notice Pending rewards of a user.
	 * @param _user address for claim
	 * @param _tokens array of reward-bearing tokens
	 * @return claimable rewards array
	 */
	function pendingRewards(address _user, address[] memory _tokens) public view returns (uint256[] memory) {
		uint256[] memory claimable = new uint256[](_tokens.length);
		uint256 length = _tokens.length;
		for (uint256 i; i < length; ) {
			address token = _tokens[i];
			PoolInfo storage pool = poolInfo[token];
			UserInfo storage user = userInfo[token][_user];
			uint256 accRewardPerShare = pool.accRewardPerShare;
			if (block.timestamp > pool.lastRewardTime) {
				(, uint256 newAccRewardPerShare) = _newRewards(pool, totalAllocPoint);
				accRewardPerShare = accRewardPerShare + newAccRewardPerShare;
			}
			claimable[i] = (user.amount * accRewardPerShare) / ACC_REWARD_PRECISION - user.rewardDebt;
			unchecked {
				i++;
			}
		}
		return claimable;
	}

	/**
	 * @notice Claim rewards. They are vested into MFD.
	 * @param _user address for claim
	 * @param _tokens array of reward-bearing tokens
	 */
	function claim(address _user, address[] memory _tokens) public whenNotPaused {
		if (eligibilityEnabled) {
			checkAndProcessEligibility(_user, true, true);
		}

		_updateEmissions();

		uint256 currentTimestamp = block.timestamp;

		uint256 pending = userBaseClaimable[_user];
		userBaseClaimable[_user] = 0;
		uint256 _totalAllocPoint = totalAllocPoint;
		uint256 length = _tokens.length;
		for (uint256 i; i < length; ) {
			if (!validRTokens[_tokens[i]]) revert InvalidRToken();
			PoolInfo storage pool = poolInfo[_tokens[i]];
			if (pool.lastRewardTime == 0) revert UnknownPool();
			_updatePool(pool, _totalAllocPoint);
			UserInfo storage user = userInfo[_tokens[i]][_user];
			uint256 rewardDebt = (user.amount * pool.accRewardPerShare) / ACC_REWARD_PRECISION;
			pending = pending + rewardDebt - user.rewardDebt;
			user.rewardDebt = rewardDebt;
			user.lastClaimTime = currentTimestamp;
			unchecked {
				i++;
			}
		}

		_vestTokens(_user, pending);

		eligibleDataProvider.updatePrice();

		if (endRewardTime() < currentTimestamp + 5 days) {
			address rdntToken = rewardMinter.getRdntTokenAddress();
			emit ChefReserveLow(IERC20(rdntToken).balanceOf(address(this)));
		}
	}

	/**
	 * @notice Vest tokens to MFD.
	 * @param _user address to receive
	 * @param _amount to vest
	 */
	function _vestTokens(address _user, uint256 _amount) internal {
		if (_amount == 0) revert NothingToVest();
		IMultiFeeDistribution mfd = _getMfd();
		_sendRadiant(address(mfd), _amount);
		mfd.vestTokens(_user, _amount, true);
	}

	/**
	 * @notice Exempt a contract from eligibility check.
	 * @dev Can be called by owner or authorized contracts
	 * @param _contract address to exempt
	 * @param _value flag for exempt
	 */
	function setEligibilityExempt(address _contract, bool _value) public {
		if (msg.sender != owner() && !authorizedContracts[msg.sender]) revert InsufficientPermission();
		eligibilityExempt[_contract] = _value;
	}

	/**
	 * @notice Updates whether the provided address is authorized to call setEligibilityExempt(), only callable by owner.
	 * @param _address address of the user or contract whose authorization level is being changed
	 */
	function setContractAuthorization(address _address, bool _authorize) external onlyOwner {
		if (authorizedContracts[_address] == _authorize) revert AuthorizationAlreadySet();
		authorizedContracts[_address] = _authorize;
		emit AuthorizedContractUpdated(_address, _authorize);
	}

	/********************** Eligibility + Disqualification ***********************/

	/**
	 * @notice `after` Hook for deposit and borrow update.
	 * @dev important! eligible status can be updated here
	 * @param _user address
	 * @param _balance balance of token
	 * @param _totalSupply total supply of the token
	 */
	function handleActionAfter(address _user, uint256 _balance, uint256 _totalSupply) external {
		if (!validRTokens[msg.sender] && msg.sender != address(_getMfd())) revert NotRTokenOrMfd();

		if (_user == address(rewardMinter) || _user == address(_getMfd()) || eligibilityExempt[_user]) {
			return;
		}
		if (eligibilityEnabled) {
			bool lastEligibleStatus = eligibleDataProvider.lastEligibleStatus(_user);
			bool isCurrentlyEligible = eligibleDataProvider.refresh(_user);
			if (isCurrentlyEligible) {
				if (lastEligibleStatus) {
					_handleActionAfterForToken(msg.sender, _user, _balance, _totalSupply);
				} else {
					_updateRegisteredBalance(_user);
				}
			} else {
				_processEligibility(_user, isCurrentlyEligible, true);
			}
		} else {
			_handleActionAfterForToken(msg.sender, _user, _balance, _totalSupply);
		}
	}

	/**
	 * @notice `after` Hook for deposit and borrow update.
	 * @dev important! eligible status can be updated here
	 * @param _token address
	 * @param _user address
	 * @param _balance new amount
	 * @param _totalSupply total supply of the token
	 */
	function _handleActionAfterForToken(
		address _token,
		address _user,
		uint256 _balance,
		uint256 _totalSupply
	) internal {
		PoolInfo storage pool = poolInfo[_token];
		if (pool.lastRewardTime == 0) revert UnknownPool();
		// Although we would want the pools to be as up to date as possible when users
		// transfer rTokens or dTokens, updating all pools on every r-/d-Token interaction would be too gas intensive.
		// _updateEmissions();
		_updatePool(pool, totalAllocPoint);
		UserInfo storage user = userInfo[_token][_user];
		uint256 amount = user.amount;
		uint256 accRewardPerShare = pool.accRewardPerShare;
		if (amount != 0) {
			uint256 pending = (amount * accRewardPerShare) / ACC_REWARD_PRECISION - user.rewardDebt;
			if (pending != 0) {
				userBaseClaimable[_user] = userBaseClaimable[_user] + pending;
			}
		}
		pool.totalSupply = pool.totalSupply - user.amount;
		user.amount = _balance;
		user.rewardDebt = (_balance * accRewardPerShare) / ACC_REWARD_PRECISION;
		pool.totalSupply = pool.totalSupply + _balance;
		if (pool.onwardIncentives != IOnwardIncentivesController(address(0))) {
			pool.onwardIncentives.handleAction(_token, _user, _balance, _totalSupply);
		}

		emit BalanceUpdated(_token, _user, _balance, _totalSupply);
	}

	/**
	 * @notice `before` Hook for deposit and borrow update.
	 * @param _user address
	 */
	function handleActionBefore(address _user) external {}

	/**
	 * @notice Hook for lock update.
	 * @dev Called by the locking contracts before locking or unlocking happens
	 * @param _user address
	 */
	function beforeLockUpdate(address _user) external {}

	/**
	 * @notice Hook for lock update.
	 * @dev Called by the locking contracts after locking or unlocking happens
	 * @param _user address
	 */
	function afterLockUpdate(address _user) external {
		if (msg.sender != address(_getMfd())) revert NotMFD();
		if (eligibilityEnabled) {
			bool isCurrentlyEligible = eligibleDataProvider.refresh(_user);
			if (isCurrentlyEligible) {
				_updateRegisteredBalance(_user);
			} else {
				_processEligibility(_user, isCurrentlyEligible, true);
			}
		}
	}

	/**
	 * @notice Update balance if there are any unregistered.
	 * @param _user address of the user whose balances will be updated
	 */
	function _updateRegisteredBalance(address _user) internal {
		uint256 length = poolLength();
		for (uint256 i; i < length; ) {
			uint256 newBal = IERC20(registeredTokens[i]).balanceOf(_user);
			uint256 registeredBal = userInfo[registeredTokens[i]][_user].amount;
			if (newBal != 0 && newBal != registeredBal) {
				_handleActionAfterForToken(
					registeredTokens[i],
					_user,
					newBal,
					poolInfo[registeredTokens[i]].totalSupply + newBal - registeredBal
				);
			}
			unchecked {
				i++;
			}
		}
	}

	/********************** Eligibility + Disqualification ***********************/

	/**
	 * @dev Returns true if `_user` has some reward eligible tokens.
	 * @param _user address of recipient
	 */
	function hasEligibleDeposits(address _user) internal view returns (bool hasDeposits) {
		uint256 length = poolLength();
		for (uint256 i; i < length; ) {
			if (userInfo[registeredTokens[i]][_user].amount != 0) {
				hasDeposits = true;
				break;
			}
			unchecked {
				i++;
			}
		}
	}

	/**
	 * @dev Stop emissions if there's any new DQ.
	 * @param _user address of recipient
	 * @param _isEligible user's eligible status
	 * @param _execute true if it's actual execution
	 * @return issueBaseBounty true for base bounty
	 */
	function _processEligibility(
		address _user,
		bool _isEligible,
		bool _execute
	) internal returns (bool issueBaseBounty) {
		bool hasEligDeposits = hasEligibleDeposits(_user);
		uint256 lastDqTime = eligibleDataProvider.getDqTime(_user);
		bool alreadyDqd = lastDqTime != 0;

		if (!_isEligible && hasEligDeposits && !alreadyDqd) {
			issueBaseBounty = true;
		}
		if (_execute && issueBaseBounty) {
			stopEmissionsFor(_user);
			emit Disqualified(_user);
		}
	}

	/**
	 * @notice Check eligibility of the user
	 * @dev Stop emissions if there's any DQ.
	 * @param _user address of recipient
	 * @param _execute true if it's actual execution
	 * @param _refresh true if needs to refresh user's eligible status
	 * @return issueBaseBounty true for base bounty
	 */
	function checkAndProcessEligibility(
		address _user,
		bool _execute,
		bool _refresh
	) internal returns (bool issueBaseBounty) {
		bool isEligible;
		if (_refresh && _execute) {
			isEligible = eligibleDataProvider.refresh(_user);
		} else {
			isEligible = eligibleDataProvider.isEligibleForRewards(_user);
		}
		issueBaseBounty = _processEligibility(_user, isEligible, _execute);
	}

	/**
	 * @notice Claim bounty
	 * @param _user address of recipient
	 * @param _execute true if it's actual execution
	 * @return issueBaseBounty true for base bounty
	 */
	function claimBounty(address _user, bool _execute) public returns (bool issueBaseBounty) {
		if (msg.sender != address(bountyManager)) revert BountyOnly();
		issueBaseBounty = checkAndProcessEligibility(_user, _execute, true);
	}

	/**
	 * @dev Stop RDNT emissions for specific users
	 * @param _user address of recipient
	 */
	function stopEmissionsFor(address _user) internal {
		if (!eligibilityEnabled) revert NotEligible();
		// lastEligibleStatus will be fresh from refresh before this call
		uint256 length = poolLength();
		for (uint256 i; i < length; ) {
			address token = registeredTokens[i];
			PoolInfo storage pool = poolInfo[token];
			UserInfo storage user = userInfo[token][_user];

			if (user.amount != 0) {
				_handleActionAfterForToken(token, _user, 0, pool.totalSupply - user.amount);
			}
			unchecked {
				i++;
			}
		}
		eligibleDataProvider.setDqTime(_user, block.timestamp);
	}

	/**
	 * @dev Send RNDT rewards to user.
	 * @param _user address of recipient
	 * @param _amount of RDNT
	 */
	function _sendRadiant(address _user, uint256 _amount) internal {
		if (_amount == 0) {
			return;
		}

		address rdntToken = rewardMinter.getRdntTokenAddress();
		uint256 chefReserve = IERC20(rdntToken).balanceOf(address(this));
		if (_amount > chefReserve) {
			revert OutOfRewards();
		} else {
			IERC20(rdntToken).safeTransfer(_user, _amount);
		}
	}

	/********************** RDNT Reserve Management ***********************/

	/**
	 * @notice Ending reward distribution time.
	 */
	function endRewardTime() public returns (uint256) {
		uint256 unclaimedRewards = availableRewards();
		uint256 extra = 0;
		uint256 length = poolLength();
		for (uint256 i; i < length; ) {
			PoolInfo storage pool = poolInfo[registeredTokens[i]];

			if (pool.lastRewardTime > lastAllPoolUpdate) {
				extra +=
					((pool.lastRewardTime - lastAllPoolUpdate) * pool.allocPoint * rewardsPerSecond) /
					totalAllocPoint;
			}
			unchecked {
				i++;
			}
		}
		endingTime.lastUpdatedTime = block.timestamp;

		if (rewardsPerSecond == 0) {
			endingTime.estimatedTime = type(uint256).max;
		} else {
			endingTime.estimatedTime = (unclaimedRewards + extra) / rewardsPerSecond + lastAllPoolUpdate;
		}
		return endingTime.estimatedTime;
	}

	/**
	 * @notice Updates cadence duration of ending time.
	 * @dev Only callable by owner.
	 * @param _lapse new cadence
	 */
	function setEndingTimeUpdateCadence(uint256 _lapse) external onlyOwner {
		if (_lapse > 1 weeks) revert CadenceTooLong();
		endingTime.updateCadence = _lapse;
		emit EndingTimeUpdateCadence(_lapse);
	}

	/**
	 * @notice Add new rewards.
	 * @dev Only callable by owner.
	 * @param _amount new deposit amount
	 */
	function registerRewardDeposit(uint256 _amount) external onlyOwner {
		depositedRewards = depositedRewards + _amount;
		_massUpdatePools();
		if (rewardsPerSecond == 0 && lastRPS > 0) {
			rewardsPerSecond = lastRPS;
		}
		emit RewardDeposit(_amount);
	}

	/**
	 * @notice Available reward amount for future distribution.
	 * @dev This value is equal to `depositedRewards` - `accountedRewards`.
	 * @return amount available
	 */
	function availableRewards() internal view returns (uint256 amount) {
		return depositedRewards - accountedRewards;
	}

	/**
	 * @notice Claim rewards entitled to all registered tokens.
	 * @param _user address of the user
	 */
	function claimAll(address _user) external {
		claim(_user, registeredTokens);
	}

	/**
	 * @notice Sum of all pending RDNT rewards.
	 * @param _user address of the user
	 * @return pending reward amount
	 */
	function allPendingRewards(address _user) public view returns (uint256 pending) {
		pending = userBaseClaimable[_user];
		uint256[] memory claimable = pendingRewards(_user, registeredTokens);
		uint256 length = claimable.length;
		for (uint256 i; i < length; ) {
			pending += claimable[i];
			unchecked {
				i++;
			}
		}
	}

	/**
	 * @notice Pause the claim operations.
	 */
	function pause() external onlyOwner {
		_pause();
	}

	/**
	 * @notice Unpause the claim operations.
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/**
	 * @dev Returns new rewards since last reward time.
	 * @param pool pool info
	 * @param _totalAllocPoint allocation point of the pool
	 */
	function _newRewards(
		PoolInfo memory pool,
		uint256 _totalAllocPoint
	) internal view returns (uint256 newReward, uint256 newAccRewardPerShare) {
		uint256 lpSupply = pool.totalSupply;
		if (lpSupply > 0) {
			uint256 duration = block.timestamp - pool.lastRewardTime;
			uint256 rawReward = duration * rewardsPerSecond;

			uint256 rewards = availableRewards();
			if (rewards < rawReward) {
				rawReward = rewards;
			}
			newReward = (rawReward * pool.allocPoint) / _totalAllocPoint;
			newAccRewardPerShare = (newReward * ACC_REWARD_PRECISION) / lpSupply;
		}
	}
}