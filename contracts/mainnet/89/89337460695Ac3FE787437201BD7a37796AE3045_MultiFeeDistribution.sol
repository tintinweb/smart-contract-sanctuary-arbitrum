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
pragma solidity 0.8.12;

interface AggregatorInterface {
	function latestAnswer() external view returns (int256);

	function latestTimestamp() external view returns (uint256);

	function latestRound() external view returns (uint256);

	function getAnswer(uint256 roundId) external view returns (int256);

	function getTimestamp(uint256 roundId) external view returns (uint256);

	event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

	event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

	function latestRoundData()
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IBountyManager {
	function quote(address _param) external returns (uint256 bounty);

	function claim(address _param) external returns (uint256 bounty);

	function minDLPBalance() external view returns (uint256 amt);
}

// SPDX-License-Identifier: MIT
// Code from https://github.com/smartcontractkit/chainlink/blob/master/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.12;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface IChainlinkAggregator is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

interface IChefIncentivesController {
	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 **/
	function handleActionBefore(address user) external;

	/**
	 * @dev Called by the corresponding asset on any update that affects the rewards distribution
	 * @param user The address of the user
	 * @param userBalance The balance of the user of the asset in the lending pool
	 * @param totalSupply The total supply of the asset in the lending pool
	 **/
	function handleActionAfter(address user, uint256 userBalance, uint256 totalSupply) external;

	/**
	 * @dev Called by the locking contracts after locking or unlocking happens
	 * @param user The address of the user
	 **/
	function beforeLockUpdate(address user) external;

	/**
	 * @notice Hook for lock update.
	 * @dev Called by the locking contracts after locking or unlocking happens
	 */
	function afterLockUpdate(address _user) external;

	function addPool(address _token, uint256 _allocPoint) external;

	function claim(address _user, address[] calldata _tokens) external;

	function setClaimReceiver(address _user, address _receiver) external;

	function getRegisteredTokens() external view returns (address[] memory);

	function disqualifyUser(address _user, address _hunter) external returns (uint256 bounty);

	function bountyForUser(address _user) external view returns (uint256 bounty);

	function allPendingRewards(address _user) external view returns (uint256 pending);

	function claimAll(address _user) external;

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function setEligibilityExempt(address _address, bool _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma abicoder v2;

import "./LockedBalance.sol";

interface IFeeDistribution {
	struct RewardData {
		address token;
		uint256 amount;
	}

	function addReward(address rewardsToken) external;

	function lockedBalances(
		address user
	) external view returns (uint256, uint256, uint256, uint256, LockedBalance[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ILockerList {
	function lockersCount() external view returns (uint256);

	function getUsers(uint256 page, uint256 limit) external view returns (address[] memory);

	function addToList(address user) external;

	function removeFromList(address user) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma abicoder v2;

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
pragma abicoder v2;

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

	function zapVestingToLp(address _address) external returns (uint256);

	function withdrawExpiredLocksFor(address _address) external returns (uint256);

	function claimableRewards(address account) external view returns (IFeeDistribution.RewardData[] memory rewards);

	function setDefaultRelockTypeIndex(uint256 _index) external;

	function daoTreasury() external view returns (address);

	function stakingToken() external view returns (address);

	function claimFromConverter(address) external;

	function mint(address user, uint256 amount, bool withPenalty) external;
}

interface IMFDPlus is IMultiFeeDistribution {
	function getLastClaimTime(address _user) external returns (uint256);

	function claimBounty(address _user, bool _execute) external returns (bool issueBaseBounty);

	function claimCompound(address _user, bool _execute) external returns (uint256 bountyAmt);

	function setAutocompound(bool _newVal) external;

	function getAutocompoundEnabled(address _user) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

interface IPriceProvider {
	function getTokenPrice() external view returns (uint256);

	function getTokenPriceUsd() external view returns (uint256);

	function getLpTokenPrice() external view returns (uint256);

	function getLpTokenPriceUsd() external view returns (uint256);

	function decimals() external view returns (uint256);

	function update() external;

	function baseTokenPriceInUsdProxyAggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;
pragma abicoder v2;

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
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../../interfaces/IChefIncentivesController.sol";
import "../../interfaces/IMiddleFeeDistribution.sol";
import "../../interfaces/IBountyManager.sol";
import {IMultiFeeDistribution} from "../../interfaces/IMultiFeeDistribution.sol";
import "../../interfaces/IMintableToken.sol";
import "../../interfaces/ILockerList.sol";
import "../../interfaces/LockedBalance.sol";
import "../../interfaces/IChainlinkAggregator.sol";
import "../../interfaces/IPriceProvider.sol";

/// @title Multi Fee Distribution Contract
/// @author Radiant
/// @dev All function calls are currently implemented without side effects
contract MultiFeeDistribution is IMultiFeeDistribution, Initializable, PausableUpgradeable, OwnableUpgradeable {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for IMintableToken;

	address private _priceProvider;

	/********************** Constants ***********************/

	uint256 public constant QUART = 25000; //  25%
	uint256 public constant HALF = 65000; //  65%
	uint256 public constant WHOLE = 100000; // 100%

	/// @notice Proportion of burn amount
	uint256 public burn;

	/// @notice Duration that rewards are streamed over
	uint256 public rewardsDuration;

	/// @notice Duration that rewards loop back
	uint256 public rewardsLookback;

	/// @notice Multiplier for earnings, fixed to 1
	// uint256 public constant DEFAULT_MUTLIPLIER = 1;

	/// @notice Default lock index
	uint256 public constant DEFAULT_LOCK_INDEX = 1;

	/// @notice Duration of lock/earned penalty period, used for earnings
	uint256 public defaultLockDuration;

	/// @notice Duration of vesting RDNT
	uint256 public vestDuration;

	address public rewardConverter;

	/********************** Contract Addresses ***********************/

	/// @notice Address of Middle Fee Distribution Contract
	IMiddleFeeDistribution public middleFeeDistribution;

	/// @notice Address of CIC contract
	IChefIncentivesController public incentivesController;

	/// @notice Address of RDNT
	IMintableToken public override rdntToken;

	/// @notice Address of LP token
	address public override stakingToken;

	// Address of Lock Zapper
	address internal lockZap;

	/********************** Lock & Earn Info ***********************/

	// Private mappings for balance data
	mapping(address => Balances) private balances;
	mapping(address => LockedBalance[]) internal userLocks;
	mapping(address => LockedBalance[]) private userEarnings;
	mapping(address => bool) public override autocompoundEnabled;
	mapping(address => uint256) public lastAutocompound;

	/// @notice Total locked value
	uint256 public lockedSupply;

	/// @notice Total locked value in multipliers
	uint256 public lockedSupplyWithMultiplier;

	// Time lengths
	uint256[] internal lockPeriod;

	// Multipliers
	uint256[] internal rewardMultipliers;

	/********************** Reward Info ***********************/

	/// @notice Reward tokens being distributed
	address[] public rewardTokens;

	/// @notice Reward data per token
	mapping(address => Reward) public rewardData;

	/// @notice user -> reward token -> rpt; RPT for paid amount
	mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;

	/// @notice user -> reward token -> amount; used to store reward amount
	mapping(address => mapping(address => uint256)) public rewards;

	/********************** Other Info ***********************/

	/// @notice DAO wallet
	address public override daoTreasury;

	/// @notice treasury wallet
	address public startfleetTreasury;

	/// @notice Addresses approved to call mint
	mapping(address => bool) public minters;

	// Addresses to relock
	mapping(address => bool) public override autoRelockDisabled;

	// Default lock index for relock
	mapping(address => uint256) public override defaultLockIndex;

	/// @notice Flag to prevent more minter addings
	bool public mintersAreSet;

	// Users list
	ILockerList public userlist;

	mapping(address => uint256) public lastClaimTime;

	address public bountyManager;

	// to prevent unbounded lock length iteration during withdraw/clean

	/********************** Events ***********************/

	//event RewardAdded(uint256 reward);
	// event Staked(address indexed user, uint256 amount, bool locked);
	event Locked(address indexed user, uint256 amount, uint256 lockedBalance, bool isLP);
	event Withdrawn(
		address indexed user,
		uint256 receivedAmount,
		uint256 lockedBalance,
		uint256 penalty,
		uint256 burn,
		bool isLP
	);
	event RewardPaid(address indexed user, address indexed rewardToken, uint256 reward);
	event IneligibleRewardRemoved(address indexed user, address indexed rewardToken, uint256 reward);
	event RewardsDurationUpdated(address token, uint256 newDuration);
	event Recovered(address token, uint256 amount);
	event Relocked(address indexed user, uint256 amount, uint256 lockIndex);

	/**
	 * @dev Constructor
	 *  First reward MUST be the RDNT token or things will break
	 *  related to the 50% penalty and distribution to locked balances.
	 * @param _rdntToken RDNT token address.
	 * @param _rewardsDuration set reward stream time.
	 * @param _rewardsLookback reward lookback
	 * @param _lockDuration lock duration
	 */
	function initialize(
		address _rdntToken,
		address _lockZap,
		address _dao,
		address _userlist,
		address priceProvider,
		uint256 _rewardsDuration,
		uint256 _rewardsLookback,
		uint256 _lockDuration,
		uint256 _burnRatio,
		uint256 _vestDuration
	) public initializer {
		require(_rdntToken != address(0), "0x0");
		require(_lockZap != address(0), "0x0");
		require(_dao != address(0), "0x0");
		require(_userlist != address(0), "0x0");
		require(priceProvider != address(0), "0x0");
		require(_rewardsDuration != uint256(0), "0x0");
		require(_rewardsLookback != uint256(0), "0x0");
		require(_lockDuration != uint256(0), "0x0");
		require(_vestDuration != uint256(0), "0x0");
		require(_burnRatio <= WHOLE, "invalid burn");
		require(_rewardsLookback <= _rewardsDuration, "invalid lookback");

		__Pausable_init();
		__Ownable_init();

		rdntToken = IMintableToken(_rdntToken);
		lockZap = _lockZap;
		daoTreasury = _dao;
		_priceProvider = priceProvider;
		userlist = ILockerList(_userlist);
		rewardTokens.push(_rdntToken);
		rewardData[_rdntToken].lastUpdateTime = block.timestamp;

		rewardsDuration = _rewardsDuration;
		rewardsLookback = _rewardsLookback;
		defaultLockDuration = _lockDuration;
		burn = _burnRatio;
		vestDuration = _vestDuration;
	}

	/********************** Setters ***********************/

	/**
	 * @notice Set minters
	 * @dev Can be called only once
	 */
	function setMinters(address[] memory _minters) external onlyOwner {
		require(!mintersAreSet, "minters set");
		for (uint256 i; i < _minters.length; i++) {
			require(_minters[i] != address(0), "minter is 0 address");
			minters[_minters[i]] = true;
		}
		mintersAreSet = true;
	}

	function setBountyManager(address _bounty) external onlyOwner {
		require(_bounty != address(0), "bounty is 0 address");
		bountyManager = _bounty;
		minters[_bounty] = true;
	}

	function addRewardConverter(address _rewardConverter) external onlyOwner {
		require(_rewardConverter != address(0), "rewardConverter is 0 address");
		rewardConverter = _rewardConverter;
	}

	/**
	 * @notice Add a new reward token to be distributed to stakers.
	 */
	function setLockTypeInfo(uint256[] memory _lockPeriod, uint256[] memory _rewardMultipliers) external onlyOwner {
		require(_lockPeriod.length == _rewardMultipliers.length, "invalid lock period");
		delete lockPeriod;
		delete rewardMultipliers;
		for (uint256 i = 0; i < _lockPeriod.length; i += 1) {
			lockPeriod.push(_lockPeriod[i]);
			rewardMultipliers.push(_rewardMultipliers[i]);
		}
	}

	/**
	 * @notice Set CIC, MFD and Treasury.
	 */
	function setAddresses(
		IChefIncentivesController _controller,
		IMiddleFeeDistribution _middleFeeDistribution,
		address _treasury
	) external onlyOwner {
		require(address(_controller) != address(0), "controller is 0 address");
		require(address(_middleFeeDistribution) != address(0), "mfd is 0 address");
		incentivesController = _controller;
		middleFeeDistribution = _middleFeeDistribution;
		startfleetTreasury = _treasury;
	}

	/**
	 * @notice Set LP token.
	 */
	function setLPToken(address _stakingToken) external onlyOwner {
		require(_stakingToken != address(0), "_stakingToken is 0 address");
		require(stakingToken == address(0), "already set");
		stakingToken = _stakingToken;
	}

	/**
	 * @notice Add a new reward token to be distributed to stakers.
	 */
	function addReward(address _rewardToken) external override {
		require(_rewardToken != address(0), "rewardToken is 0 address");
		require(minters[msg.sender], "!minter");
		require(rewardData[_rewardToken].lastUpdateTime == 0, "already added");
		rewardTokens.push(_rewardToken);
		rewardData[_rewardToken].lastUpdateTime = block.timestamp;
		rewardData[_rewardToken].periodFinish = block.timestamp;
	}

	/********************** View functions ***********************/

	/**
	 * @notice Set default lock type index for user relock.
	 */
	function setDefaultRelockTypeIndex(uint256 _index) external override {
		require(_index < lockPeriod.length, "invalid type");
		defaultLockIndex[msg.sender] = _index;
	}

	function setAutocompound(bool _status) external {
		autocompoundEnabled[msg.sender] = _status;
	}

	function getLockDurations() external view returns (uint256[] memory) {
		return lockPeriod;
	}

	function getLockMultipliers() external view returns (uint256[] memory) {
		return rewardMultipliers;
	}

	/**
	 * @notice Set relock status
	 */
	function setRelock(bool _status) external virtual {
		autoRelockDisabled[msg.sender] = !_status;
	}

	/**
	 * @notice Returns all locks of a user.
	 */
	function lockInfo(address user) external view override returns (LockedBalance[] memory) {
		return userLocks[user];
	}

	/**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders.
	 */
	function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
		require(rewardData[tokenAddress].lastUpdateTime == 0, "active reward");
		IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}

	/**
	 * @notice Withdraw and restake assets.
	 */
	function relock() external virtual {
		uint256 amount = _withdrawExpiredLocksFor(msg.sender, true, true, userLocks[msg.sender].length);
		_stake(amount, msg.sender, defaultLockIndex[msg.sender], false);
		emit Relocked(msg.sender, amount, defaultLockIndex[msg.sender]);
	}

	/**
	 * @notice Total balance of an account, including unlocked, locked and earned tokens.
	 */
	function totalBalance(address user) external view override returns (uint256 amount) {
		if (stakingToken == address(rdntToken)) {
			return balances[user].total;
		}
		return balances[user].locked;
	}

	/**
	 * @notice Information on a user's lockings
	 * @return total balance of locks
	 * @return unlockable balance
	 * @return locked balance
	 * @return lockedWithMultiplier
	 * @return lockData which is an array of locks
	 */
	function lockedBalances(
		address user
	)
		public
		view
		override
		returns (
			uint256 total,
			uint256 unlockable,
			uint256 locked,
			uint256 lockedWithMultiplier,
			LockedBalance[] memory lockData
		)
	{
		LockedBalance[] storage locks = userLocks[user];
		uint256 idx;
		for (uint256 i = 0; i < locks.length; i++) {
			if (locks[i].unlockTime > block.timestamp) {
				if (idx == 0) {
					lockData = new LockedBalance[](locks.length - i);
				}
				lockData[idx] = locks[i];
				idx++;
				locked = locked.add(locks[i].amount);
				lockedWithMultiplier = lockedWithMultiplier.add(locks[i].amount.mul(locks[i].multiplier));
			} else {
				unlockable = unlockable.add(locks[i].amount);
			}
		}
		return (balances[user].locked, unlockable, locked, lockedWithMultiplier, lockData);
	}

	/**
	 * @notice Earnings which is locked yet
	 * @dev Earned balances may be withdrawn immediately for a 50% penalty.
	 * @return total earnings
	 * @return unlocked earnings
	 * @return earningsData which is an array of all infos
	 */
	function earnedBalances(
		address user
	) public view returns (uint256 total, uint256 unlocked, EarnedBalance[] memory earningsData) {
		unlocked = balances[user].unlocked;
		LockedBalance[] storage earnings = userEarnings[user];
		uint256 idx;
		for (uint256 i = 0; i < earnings.length; i++) {
			if (earnings[i].unlockTime > block.timestamp) {
				if (idx == 0) {
					earningsData = new EarnedBalance[](earnings.length - i);
				}
				(, uint256 penaltyAmount, , ) = ieeWithdrawableBalances(user, earnings[i].unlockTime);
				earningsData[idx].amount = earnings[i].amount;
				earningsData[idx].unlockTime = earnings[i].unlockTime;
				earningsData[idx].penalty = penaltyAmount;
				idx++;
				total = total.add(earnings[i].amount);
			} else {
				unlocked = unlocked.add(earnings[i].amount);
			}
		}
		return (total, unlocked, earningsData);
	}

	/**
	 * @notice Final balance received and penalty balance paid by user upon calling exit.
	 * @dev This is earnings, not locks.
	 */
	function withdrawableBalance(
		address user
	) public view returns (uint256 amount, uint256 penaltyAmount, uint256 burnAmount) {
		uint256 earned = balances[user].earned;
		if (earned > 0) {
			uint256 length = userEarnings[user].length;
			for (uint256 i = 0; i < length; i++) {
				uint256 earnedAmount = userEarnings[user][i].amount;
				if (earnedAmount == 0) continue;
				(, , uint256 newPenaltyAmount, uint256 newBurnAmount) = _penaltyInfo(userEarnings[user][i]);
				penaltyAmount = penaltyAmount.add(newPenaltyAmount);
				burnAmount = burnAmount.add(newBurnAmount);
			}
		}
		amount = balances[user].unlocked.add(earned).sub(penaltyAmount);
		return (amount, penaltyAmount, burnAmount);
	}

	function _penaltyInfo(
		LockedBalance memory earning
	) internal view returns (uint256 amount, uint256 penaltyFactor, uint256 penaltyAmount, uint256 burnAmount) {
		if (earning.unlockTime > block.timestamp) {
			// 90% on day 1, decays to 25% on day 90
			penaltyFactor = earning.unlockTime.sub(block.timestamp).mul(HALF).div(vestDuration).add(QUART); // 25% + timeLeft/vestDuration * 65%
		}
		penaltyAmount = earning.amount.mul(penaltyFactor).div(WHOLE);
		burnAmount = penaltyAmount.mul(burn).div(WHOLE);
		amount = earning.amount.sub(penaltyAmount);
	}

	/********************** Reward functions ***********************/

	/**
	 * @notice Reward amount of the duration.
	 * @param _rewardToken for the reward
	 */
	function getRewardForDuration(address _rewardToken) external view returns (uint256) {
		return rewardData[_rewardToken].rewardPerSecond.mul(rewardsDuration).div(1e12);
	}

	/**
	 * @notice Returns reward applicable timestamp.
	 */
	function lastTimeRewardApplicable(address _rewardToken) public view returns (uint256) {
		uint256 periodFinish = rewardData[_rewardToken].periodFinish;
		return block.timestamp < periodFinish ? block.timestamp : periodFinish;
	}

	/**
	 * @notice Reward amount per token
	 * @dev Reward is distributed only for locks.
	 * @param _rewardToken for reward
	 */
	function rewardPerToken(address _rewardToken) public view returns (uint256 rptStored) {
		rptStored = rewardData[_rewardToken].rewardPerTokenStored;
		if (lockedSupplyWithMultiplier > 0) {
			uint256 newReward = lastTimeRewardApplicable(_rewardToken).sub(rewardData[_rewardToken].lastUpdateTime).mul(
				rewardData[_rewardToken].rewardPerSecond
			);
			rptStored = rptStored.add(newReward.mul(1e18).div(lockedSupplyWithMultiplier));
		}
	}

	/**
	 * @notice Address and claimable amount of all reward tokens for the given account.
	 * @param account for rewards
	 */
	function claimableRewards(
		address account
	) public view override returns (IFeeDistribution.RewardData[] memory rewardsData) {
		rewardsData = new IFeeDistribution.RewardData[](rewardTokens.length);
		for (uint256 i = 0; i < rewardsData.length; i++) {
			rewardsData[i].token = rewardTokens[i];
			rewardsData[i].amount = _earned(
				account,
				rewardsData[i].token,
				balances[account].lockedWithMultiplier,
				rewardPerToken(rewardsData[i].token)
			).div(1e12);
		}
		return rewardsData;
	}

	function claimFromConverter(address onBehalf) external override whenNotPaused {
		require(msg.sender == rewardConverter, "!converter");
		_updateReward(onBehalf);
		middleFeeDistribution.forwardReward(rewardTokens);
		uint256 length = rewardTokens.length;
		for (uint256 i; i < length; i++) {
			address token = rewardTokens[i];
			_notifyUnseenReward(token);
			uint256 reward = rewards[onBehalf][token].div(1e12);
			if (reward > 0) {
				rewards[onBehalf][token] = 0;
				rewardData[token].balance = rewardData[token].balance.sub(reward);

				IERC20(token).safeTransfer(rewardConverter, reward);
				emit RewardPaid(onBehalf, token, reward);
			}
		}
		IPriceProvider(_priceProvider).update();
		lastClaimTime[onBehalf] = block.timestamp;
	}

	/********************** Operate functions ***********************/

	/**
	 * @notice Stake tokens to receive rewards.
	 * @dev Locked tokens cannot be withdrawn for defaultLockDuration and are eligible to receive rewards.
	 */
	function stake(uint256 amount, address onBehalfOf, uint256 typeIndex) external override {
		_stake(amount, onBehalfOf, typeIndex, false);
	}

	function _stake(uint256 amount, address onBehalfOf, uint256 typeIndex, bool isRelock) internal whenNotPaused {
		if (amount == 0) return;
		if (bountyManager != address(0)) {
			require(amount >= IBountyManager(bountyManager).minDLPBalance(), "min stake amt not met");
		}
		require(typeIndex < lockPeriod.length, "invalid index");

		_updateReward(onBehalfOf);

		uint256 transferAmount = amount;
		if (userLocks[onBehalfOf].length != 0) {
			//if user has any locks
			if (userLocks[onBehalfOf][0].unlockTime <= block.timestamp) {
				//if users soonest unlock has already elapsed
				if (onBehalfOf == msg.sender || msg.sender == lockZap) {
					//if the user is msg.sender or the lockzap contract
					uint256 withdrawnAmt;
					if (!autoRelockDisabled[onBehalfOf]) {
						withdrawnAmt = _withdrawExpiredLocksFor(onBehalfOf, true, false, userLocks[onBehalfOf].length);
						amount = amount.add(withdrawnAmt);
					} else {
						_withdrawExpiredLocksFor(onBehalfOf, true, true, userLocks[onBehalfOf].length);
					}
				}
			}
		}
		Balances storage bal = balances[onBehalfOf];
		bal.total = bal.total.add(amount);

		bal.locked = bal.locked.add(amount);
		lockedSupply = lockedSupply.add(amount);

		bal.lockedWithMultiplier = bal.lockedWithMultiplier.add(amount.mul(rewardMultipliers[typeIndex]));
		lockedSupplyWithMultiplier = lockedSupplyWithMultiplier.add(amount.mul(rewardMultipliers[typeIndex]));

		_insertLock(
			onBehalfOf,
			LockedBalance({
				amount: amount,
				unlockTime: block.timestamp.add(lockPeriod[typeIndex]),
				multiplier: rewardMultipliers[typeIndex],
				duration: lockPeriod[typeIndex]
			})
		);

		userlist.addToList(onBehalfOf);

		if (!isRelock) {
			IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), transferAmount);
		}

		incentivesController.afterLockUpdate(onBehalfOf);
		emit Locked(onBehalfOf, amount, balances[onBehalfOf].locked, stakingToken != address(rdntToken));
	}

	function _insertLock(address _user, LockedBalance memory newLock) internal {
		LockedBalance[] storage locks = userLocks[_user];
		uint256 length = locks.length;
		uint256 i;
		while (i < length && locks[i].unlockTime < newLock.unlockTime) {
			i = i + 1;
		}
		locks.push(newLock);
		for (uint256 j = length; j > i; j -= 1) {
			locks[j] = locks[j - 1];
		}
		locks[i] = newLock;
	}

	/**
	 * @notice Add to earnings
	 * @dev Minted tokens receive rewards normally but incur a 50% penalty when
	 *  withdrawn before vestDuration has passed.
	 */
	function mint(address user, uint256 amount, bool withPenalty) external override whenNotPaused {
		require(minters[msg.sender], "!minter");
		if (amount == 0) return;

		if (user == address(this)) {
			// minting to this contract adds the new tokens as incentives for lockers
			_notifyReward(address(rdntToken), amount);
			return;
		}

		Balances storage bal = balances[user];
		bal.total = bal.total.add(amount);
		if (withPenalty) {
			bal.earned = bal.earned.add(amount);
			LockedBalance[] storage earnings = userEarnings[user];
			uint256 unlockTime = block.timestamp.add(vestDuration);
			earnings.push(
				LockedBalance({amount: amount, unlockTime: unlockTime, multiplier: 1, duration: vestDuration})
			);
		} else {
			bal.unlocked = bal.unlocked.add(amount);
		}
		//emit Staked(user, amount, false);
	}

	/**
	 * @notice Withdraw tokens from earnings and unlocked.
	 * @dev First withdraws unlocked tokens, then earned tokens. Withdrawing earned tokens
	 *  incurs a 50% penalty which is distributed based on locked balances.
	 */
	function withdraw(uint256 amount) external {
		address _address = msg.sender;
		require(amount != 0, "amt cannot be 0");

		uint256 penaltyAmount;
		uint256 burnAmount;
		Balances storage bal = balances[_address];

		if (amount <= bal.unlocked) {
			bal.unlocked = bal.unlocked.sub(amount);
		} else {
			uint256 remaining = amount.sub(bal.unlocked);
			require(bal.earned >= remaining, "invalid earned");
			bal.unlocked = 0;
			uint256 sumEarned = bal.earned;
			uint256 i;
			for (i = 0; ; i++) {
				uint256 earnedAmount = userEarnings[_address][i].amount;
				if (earnedAmount == 0) continue;
				(, uint256 penaltyFactor, , ) = _penaltyInfo(userEarnings[_address][i]);

				// Amount required from this lock, taking into account the penalty
				uint256 requiredAmount = remaining.mul(WHOLE).div(WHOLE.sub(penaltyFactor));
				if (requiredAmount >= earnedAmount) {
					requiredAmount = earnedAmount;
					remaining = remaining.sub(earnedAmount.mul(WHOLE.sub(penaltyFactor)).div(WHOLE)); // remaining -= earned * (1 - pentaltyFactor)
					if (remaining == 0) i++;
				} else {
					userEarnings[_address][i].amount = earnedAmount.sub(requiredAmount);
					remaining = 0;
				}
				sumEarned = sumEarned.sub(requiredAmount);

				penaltyAmount = penaltyAmount.add(requiredAmount.mul(penaltyFactor).div(WHOLE)); // penalty += amount * penaltyFactor
				burnAmount = burnAmount.add(penaltyAmount.mul(burn).div(WHOLE)); // burn += penalty * burnFactor

				if (remaining == 0) {
					break;
				} else {
					require(sumEarned != 0, "0 earned");
				}
			}
			if (i > 0) {
				for (uint256 j = i; j < userEarnings[_address].length; j++) {
					userEarnings[_address][j - i] = userEarnings[_address][j];
				}
				for (uint256 j = 0; j < i; j++) {
					userEarnings[_address].pop();
				}
			}
			bal.earned = sumEarned;
		}

		// Update values
		bal.total = bal.total.sub(amount).sub(penaltyAmount);

		_withdrawTokens(_address, amount, penaltyAmount, burnAmount, false);
	}

	function ieeWithdrawableBalances(
		address user,
		uint256 unlockTime
	) internal view returns (uint256 amount, uint256 penaltyAmount, uint256 burnAmount, uint256 index) {
		for (uint256 i = 0; i < userEarnings[user].length; i++) {
			if (userEarnings[user][i].unlockTime == unlockTime) {
				(amount, , penaltyAmount, burnAmount) = _penaltyInfo(userEarnings[user][i]);
				index = i;
				break;
			}
		}
	}

	/**
	 * @notice Withdraw individual unlocked balance and earnings, optionally claim pending rewards.
	 */
	function individualEarlyExit(bool claimRewards, uint256 unlockTime) external {
		address onBehalfOf = msg.sender;
		require(unlockTime > block.timestamp, "!unlockTime");
		(uint256 amount, uint256 penaltyAmount, uint256 burnAmount, uint256 index) = ieeWithdrawableBalances(
			onBehalfOf,
			unlockTime
		);

		if (index >= userEarnings[onBehalfOf].length) {
			return;
		}

		for (uint256 i = index + 1; i < userEarnings[onBehalfOf].length; i++) {
			userEarnings[onBehalfOf][i - 1] = userEarnings[onBehalfOf][i];
		}
		userEarnings[onBehalfOf].pop();

		Balances storage bal = balances[onBehalfOf];
		bal.total = bal.total.sub(amount).sub(penaltyAmount);
		bal.earned = bal.earned.sub(amount).sub(penaltyAmount);

		_withdrawTokens(onBehalfOf, amount, penaltyAmount, burnAmount, claimRewards);
	}

	/**
	 * @notice Withdraw full unlocked balance and earnings, optionally claim pending rewards.
	 */
	function exit(bool claimRewards) external override {
		address onBehalfOf = msg.sender;
		(uint256 amount, uint256 penaltyAmount, uint256 burnAmount) = withdrawableBalance(onBehalfOf);

		delete userEarnings[onBehalfOf];

		Balances storage bal = balances[onBehalfOf];
		bal.total = bal.total.sub(bal.unlocked).sub(bal.earned);
		bal.unlocked = 0;
		bal.earned = 0;

		_withdrawTokens(onBehalfOf, amount, penaltyAmount, burnAmount, claimRewards);
	}

	/**
	 * @notice Claim all pending staking rewards.
	 */
	function getReward(address[] memory _rewardTokens) public {
		_updateReward(msg.sender);
		_getReward(msg.sender, _rewardTokens);
		IPriceProvider(_priceProvider).update();
	}

	/**
	 * @notice Claim all pending staking rewards.
	 */
	function getAllRewards() external {
		return getReward(rewardTokens);
	}

	/**
	 * @notice Calculate earnings.
	 */
	function _earned(
		address _user,
		address _rewardToken,
		uint256 _balance,
		uint256 _currentRewardPerToken
	) internal view returns (uint256 earnings) {
		earnings = rewards[_user][_rewardToken];
		uint256 realRPT = _currentRewardPerToken.sub(userRewardPerTokenPaid[_user][_rewardToken]);
		earnings = earnings.add(_balance.mul(realRPT).div(1e18));
	}

	/**
	 * @notice Update user reward info.
	 */
	function _updateReward(address account) internal {
		uint256 balance = balances[account].lockedWithMultiplier;
		uint256 length = rewardTokens.length;
		for (uint256 i = 0; i < length; i++) {
			address token = rewardTokens[i];
			uint256 rpt = rewardPerToken(token);

			Reward storage r = rewardData[token];
			r.rewardPerTokenStored = rpt;
			r.lastUpdateTime = lastTimeRewardApplicable(token);

			if (account != address(this)) {
				rewards[account][token] = _earned(account, token, balance, rpt);
				userRewardPerTokenPaid[account][token] = rpt;
			}
		}
	}

	/**
	 * @notice Add new reward.
	 * @dev If prev reward period is not done, then it resets `rewardPerSecond` and restarts period
	 */
	function _notifyReward(address _rewardToken, uint256 reward) internal {
		Reward storage r = rewardData[_rewardToken];
		if (block.timestamp >= r.periodFinish) {
			r.rewardPerSecond = reward.mul(1e12).div(rewardsDuration);
		} else {
			uint256 remaining = r.periodFinish.sub(block.timestamp);
			uint256 leftover = remaining.mul(r.rewardPerSecond).div(1e12);
			r.rewardPerSecond = reward.add(leftover).mul(1e12).div(rewardsDuration);
		}

		r.lastUpdateTime = block.timestamp;
		r.periodFinish = block.timestamp.add(rewardsDuration);
		r.balance = r.balance.add(reward);
	}

	/**
	 * @notice Notify unseen rewards.
	 * @dev for rewards other than stakingToken, every 24 hours we check if new
	 *  rewards were sent to the contract or accrued via aToken interest.
	 */
	function _notifyUnseenReward(address token) internal {
		require(token != address(0), "Invalid Token");
		if (token == address(rdntToken)) {
			return;
		}
		Reward storage r = rewardData[token];
		uint256 periodFinish = r.periodFinish;
		require(periodFinish != 0, "invalid period finish");
		if (periodFinish < block.timestamp.add(rewardsDuration - rewardsLookback)) {
			uint256 unseen = IERC20(token).balanceOf(address(this)).sub(r.balance);
			if (unseen > 0) {
				_notifyReward(token, unseen);
			}
		}
	}

	function onUpgrade() public {}

	function setLookback(uint256 _lookback) public onlyOwner {
		rewardsLookback = _lookback;
	}

	/**
	 * @notice User gets reward
	 */
	function _getReward(address _user, address[] memory _rewardTokens) internal whenNotPaused {
		middleFeeDistribution.forwardReward(_rewardTokens);
		uint256 length = _rewardTokens.length;
		for (uint256 i; i < length; i++) {
			address token = _rewardTokens[i];
			_notifyUnseenReward(token);
			uint256 reward = rewards[_user][token].div(1e12);
			if (reward > 0) {
				rewards[_user][token] = 0;
				rewardData[token].balance = rewardData[token].balance.sub(reward);

				IERC20(token).safeTransfer(_user, reward);
				emit RewardPaid(_user, token, reward);
			}
		}
	}

	/**
	 * @notice Withdraw tokens from MFD
	 */
	function _withdrawTokens(
		address onBehalfOf,
		uint256 amount,
		uint256 penaltyAmount,
		uint256 burnAmount,
		bool claimRewards
	) internal {
		require(onBehalfOf == msg.sender, "onBehalfOf != sender");
		_updateReward(onBehalfOf);

		rdntToken.safeTransfer(onBehalfOf, amount);
		if (penaltyAmount > 0) {
			if (burnAmount > 0) {
				rdntToken.safeTransfer(startfleetTreasury, burnAmount);
			}
			rdntToken.safeTransfer(daoTreasury, penaltyAmount.sub(burnAmount));
		}

		if (claimRewards) {
			_getReward(onBehalfOf, rewardTokens);
			lastClaimTime[onBehalfOf] = block.timestamp;
		}

		IPriceProvider(_priceProvider).update();

		emit Withdrawn(
			onBehalfOf,
			amount,
			balances[onBehalfOf].locked,
			penaltyAmount,
			burnAmount,
			stakingToken != address(rdntToken)
		);
	}

	/********************** Eligibility + Disqualification ***********************/

	/**
	 * @notice Withdraw all lockings tokens where the unlock time has passed
	 */
	function _cleanWithdrawableLocks(
		address user,
		uint256 totalLock,
		uint256 totalLockWithMultiplier,
		uint256 limit
	) internal returns (uint256 lockAmount, uint256 lockAmountWithMultiplier) {
		LockedBalance[] storage locks = userLocks[user];

		if (locks.length != 0) {
			uint256 length = locks.length <= limit ? locks.length : limit;
			for (uint256 i = 0; i < length; ) {
				if (locks[i].unlockTime <= block.timestamp) {
					lockAmount = lockAmount.add(locks[i].amount);
					lockAmountWithMultiplier = lockAmountWithMultiplier.add(locks[i].amount.mul(locks[i].multiplier));
					locks[i] = locks[locks.length - 1];
					locks.pop();
					length = length.sub(1);
				} else {
					i = i + 1;
				}
			}
			if (locks.length == 0) {
				lockAmount = totalLock;
				lockAmountWithMultiplier = totalLockWithMultiplier;
				delete userLocks[user];

				userlist.removeFromList(user);
			}
		}
	}

	/**
	 * @notice Withdraw all currently locked tokens where the unlock time has passed.
	 * @param _address of the user.
	 */
	function _withdrawExpiredLocksFor(
		address _address,
		bool isRelockAction,
		bool doTransfer,
		uint256 limit
	) internal whenNotPaused returns (uint256 amount) {
		_updateReward(_address);

		uint256 amountWithMultiplier;
		Balances storage bal = balances[_address];
		(amount, amountWithMultiplier) = _cleanWithdrawableLocks(_address, bal.locked, bal.lockedWithMultiplier, limit);
		bal.locked = bal.locked.sub(amount);
		bal.lockedWithMultiplier = bal.lockedWithMultiplier.sub(amountWithMultiplier);
		bal.total = bal.total.sub(amount);
		lockedSupply = lockedSupply.sub(amount);
		lockedSupplyWithMultiplier = lockedSupplyWithMultiplier.sub(amountWithMultiplier);

		if (!isRelockAction && !autoRelockDisabled[_address]) {
			_stake(amount, _address, defaultLockIndex[_address], true);
		} else {
			if (doTransfer) {
				IERC20(stakingToken).safeTransfer(_address, amount);
				incentivesController.afterLockUpdate(_address);
				emit Withdrawn(_address, amount, balances[_address].locked, 0, 0, stakingToken != address(rdntToken));
			}
		}
		return amount;
	}

	/**
	 * @notice Withdraw all currently locked tokens where the unlock time has passed.
	 */
	function withdrawExpiredLocksFor(address _address) external override returns (uint256) {
		return _withdrawExpiredLocksFor(_address, false, true, userLocks[_address].length);
	}

	function withdrawExpiredLocksForWithOptions(
		address _address,
		uint256 _limit,
		bool _ignoreRelock
	) external returns (uint256) {
		if (_limit == 0) _limit = userLocks[_address].length;

		return _withdrawExpiredLocksFor(_address, _ignoreRelock, true, _limit);
	}

	function zapVestingToLp(address _user) external override returns (uint256 zapped) {
		require(msg.sender == lockZap, "!lockZap");

		_updateReward(_user);

		LockedBalance[] storage earnings = userEarnings[_user];
		for (uint256 i = earnings.length; i > 0; i -= 1) {
			if (earnings[i - 1].unlockTime > block.timestamp) {
				zapped = zapped.add(earnings[i - 1].amount);
				earnings.pop();
			} else {
				break;
			}
		}

		rdntToken.safeTransfer(lockZap, zapped);

		Balances storage bal = balances[_user];
		bal.earned = bal.earned.sub(zapped);
		bal.total = bal.total.sub(zapped);

		IPriceProvider(_priceProvider).update();

		return zapped;
	}

	function getPriceProvider() external view override returns (address) {
		return _priceProvider;
	}

	/**
	 * @notice Claims bounty.
	 * @dev Remove expired locks
	 * @param _user address.
	 */
	function claimBounty(address _user, bool _execute) public whenNotPaused returns (bool issueBaseBounty) {
		require(msg.sender == address(bountyManager), "!bountyManager");

		(, uint256 unlockable, , , ) = lockedBalances(_user);
		if (unlockable == 0) {
			return (false);
		} else {
			issueBaseBounty = true;
		}

		if (!_execute) {
			return (issueBaseBounty);
		}
		// Withdraw the user's expried locks
		_withdrawExpiredLocksFor(_user, false, true, userLocks[_user].length);
	}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	function requalify() external {
		incentivesController.afterLockUpdate(msg.sender);
	}
}