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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Sake.sol";
import "../interfaces/water/IWater.sol";
import "../interfaces/ISake.sol";

/**
 * @author Vaultka Team serving high quality drinks; drink responsibly.
 * Factory and global config params
 */
contract Bartender is OwnableUpgradeable {
    using MathUpgradeable for uint256;
    using MathUpgradeable for uint128;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct DepositInfo {
        // Amount in supply as debt to SAKE
        uint256 amount;
        uint256 totalWithdrawn;
        // store user shares
        uint256 shares;
    }

    struct SakeVaultInfo {
        bool isLiquidated;
        // total amount of USDC use to purchase VLP
        uint256 leverage;
        // record total amount of VLP
        uint256 totalAmountOfVLP;
        uint256 totalAmountOfVLPInUSDC;
        // get all deposited without leverage
        uint256 totalAmountOfUSDCWithoutLeverage;
        // store puchase price of VLP
        uint256 purchasePrice;
        // store all users in array
        address[] users;
        // store time when the sake vault is created
        uint256 startTime;
    }

    struct State {
        IERC20Upgradeable usdcToken;
        address velaMintBurnVault;
        address vlp;
        address velaStakingVault;
        address water;
        address liquor;
        address feeRecipient;
        bool feeEnabled;
        uint128 depositFeeBPS;
        uint128 withdrawFeeBPS;
        uint256 minimumDeposit;
        uint256 maxSakeUsers;
    }

    struct UpdatedDebtRatio {
        uint256 newValue;
        uint256 newDebt;
        uint256 newRatio;
        uint256 lastUpdateTime;
        uint256 previousPrice;
    }

    struct FeeSplitStrategyInfo {
        /**
         * @dev this constant represents the utilization rate at which the vault aims to obtain most competitive borrow rates.
         * Expressed in ray
         **/
        uint128 optimalUtilizationRate;
        // slope 1 used to control the change of reward fee split when reward is inbetween  0-40%
        uint128 maxFeeSplitSlope1;
        // slope 2 used to control the change of reward fee split when reward is inbetween  40%-80%
        uint128 maxFeeSplitSlope2;
        // slope 3 used to control the change of reward fee split when reward is inbetween  80%-100%
        uint128 maxFeeSplitSlope3;
        uint128 utilizationThreshold1;
        uint128 utilizationThreshold2;
        uint128 utilizationThreshold3;
    }

    uint256 private MAX_BPS;
    uint256 private RATE_PRECISION;
    uint256 public COOLDOWN_PERIOD;
    uint256 public currentId;

    State public state;
    FeeSplitStrategyInfo public feeStrategy;
    address public keeper;
    uint256[50] private __gaps;

    mapping(uint256 => address) public sakeVault;
    mapping(uint256 => UpdatedDebtRatio) public updatedDebtRatio;
    mapping(address => mapping(uint256 => DepositInfo)) public depositInfo;
    mapping(uint256 => SakeVaultInfo) public sakeVaultInfo;

    /**
     * @dev Emitted when new `sake` contract is created by the keeper
     * with it `associatedTime`
     */
    event CreateNewSake(address indexed sake, uint256 indexed sakeId);

    /**
     * @dev Emitted when user deposited into the vault
     * `user` is the msg.sender
     * `amountDeposited` is the amount user deposited
     * `associatedTime` the time at which the deposit is made
     * `leverageFromWater` how much leverage was taking by the user from the WATER VAULT
     */
    event BartenderDeposit(
        address indexed user,
        uint256 amountDeposited,
        uint256 indexed sakeId,
        uint256 leverageFromWater
    );
    /**
     * @dev Emitted when user withdraw from the vault
     * `user` is the msg.sender
     * `amount` is the amount user withdraw
     * `sakeId` the id that identify each sake
     * `withdrawableAmountInVLP` how much vlp was taking and been sold for USDC
     */
    event BartenderWithdraw(
        address indexed user,
        uint256 amount,
        uint256 indexed sakeId,
        uint256 withdrawableAmountInVLP
    );
    /* ##################################################################
                                MODIFIERS
    ################################################################## */
    modifier onlyKeeper() {
        require(keeper == msg.sender, "NotKeeper");
        _;
    }

    modifier onlyLiquor() {
        require(state.liquor == msg.sender, "NotLiquor");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _kepper
    )
        external
        // State calldata _params
        initializer
    {
        currentId = 1;
        // state = _params;

        MAX_BPS = 100_000;
        RATE_PRECISION = 1e30;
        COOLDOWN_PERIOD = 2 days;
        keeper = _kepper;
        __Ownable_init();
    }

    function setKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "NO_DEAD_ADDRESS");
        keeper = _keeper;
    }

    /* ##################################################################
                                OWNER FUNCTIONS
    ################################################################## */
    // @notice update every address with a single function
    // @param addresses address to initialized the vault
    function setState(State calldata _params) public onlyOwner {
        // require(
        //     _params.usdcToken != IERC20Upgradeable(address(0)) &&
        //     _params.velaMintBurnVault != address(0) &&
        //     _params.vlp != address(0) &&
        //     _params.velaStakingVault != address(0) &&
        //     _params.water != address(0) &&
        //     _params.liquor != address(0) &&
        //     _params.feeRecipient != address(0) &&
        //     _params.depositFeeBPS >= 0 && _params.depositFeeBPS <= 10000 &&
        //     _params.withdrawFeeBPS >= 0 && _params.withdrawFeeBPS <= 10000 &&
        //     _params.minimumDeposit > 0 &&
        //     _params.maxSakeUsers > 0,
        //     "Invalid state parameters"
        // );

        state = _params;
    }

    /// @notice updates fee split strategy
    /// @notice this determines how eth rewards should be split between WATER Vault and BARTENDER
    /// @notice basis the utilization of WATER Vault
    /// @param _feeStrategy: new fee strategy
    function updateFeeStrategyParams(FeeSplitStrategyInfo calldata _feeStrategy) external onlyOwner {
        require(
            _feeStrategy.optimalUtilizationRate >= 0 &&
                _feeStrategy.optimalUtilizationRate <= 100 * 10 ** 28 &&
                _feeStrategy.maxFeeSplitSlope1 >= 0 &&
                _feeStrategy.maxFeeSplitSlope1 <= 100 * 10 ** 28 &&
                _feeStrategy.maxFeeSplitSlope2 >= _feeStrategy.maxFeeSplitSlope1 &&
                _feeStrategy.maxFeeSplitSlope2 <= 100 * 10 ** 28 &&
                _feeStrategy.maxFeeSplitSlope3 >= _feeStrategy.maxFeeSplitSlope2 &&
                _feeStrategy.maxFeeSplitSlope3 <= 100 * 10 ** 28 &&
                _feeStrategy.utilizationThreshold1 >= 0 &&
                _feeStrategy.utilizationThreshold1 <= _feeStrategy.utilizationThreshold2 &&
                _feeStrategy.utilizationThreshold2 >= _feeStrategy.utilizationThreshold1 &&
                _feeStrategy.utilizationThreshold2 <= _feeStrategy.utilizationThreshold3 &&
                _feeStrategy.utilizationThreshold3 >= _feeStrategy.utilizationThreshold2 &&
                _feeStrategy.utilizationThreshold3 <= 100 * 10 ** 28,
            "Invalid fee strategy parameters"
        );

        feeStrategy = _feeStrategy;
    }

    function withdrawVesting(uint256 id) public onlyOwner {
        ISake(sakeVault[id]).withdrawVesting();
    }

    function setLiquidated(uint256 id) public onlyLiquor returns (address sakeAddress) {
        sakeVaultInfo[id].isLiquidated = true;
        return sakeVault[id];
    }

    /* ##################################################################
                                VIEW FUNCTIONS
    ################################################################## */

    function getSakeVaultInfo(uint256 id) external view returns (SakeVaultInfo memory) {
        return sakeVaultInfo[id];
    }

    function getDepositInfo(uint256 id, address user) external view returns (DepositInfo memory) {
        return depositInfo[user][id];
    }

    function maxWithdraw(uint256 id, uint256 currentShares) public returns (uint256) {
        uint256 updatedDebt;
        uint256 value;
        if (updatedDebtRatio[id].newValue != 0) {
            (updatedDebt, value, ) = updateDebtAndValueAmount(id, true);
        } else {
            updatedDebt = updatedDebtRatio[id].newDebt;
            value = updatedDebtRatio[id].newValue;
        }
        uint256 currentShareDivRate = (value - updatedDebt).mulDiv(currentShares, RATE_PRECISION);
        return currentShareDivRate;
    }

    // preview withdrawal
    function previewWithdraw(uint256 id, address user) public returns (uint256) {
        uint256 shares;
        // uint256 currentId = updatedDebtRatio[id].newValue == 0
        //     ? currentId
        //     : updatedDebtRatio[id].newValue;
        if (updatedDebtRatio[id].newValue == 0) {
            uint256 _totalAmount = sakeVaultInfo[id].totalAmountOfUSDCWithoutLeverage * 3;
            shares = ((depositInfo[user][id].amount * 3).mulDiv(RATE_PRECISION, _totalAmount));
        } else {
            shares = depositInfo[user][id].shares;
        }
        return maxWithdraw(id, shares);
    }

    function getMaxWithdraw(uint256 id, address user) public view returns (uint256 maxWithdrawAmount) {
        uint256 shares = depositInfo[user][id].shares;
        uint256 updatedDebt = updatedDebtRatio[id].newDebt;
        uint256 value = updatedDebtRatio[id].newValue;

        return (value - updatedDebt).mulDiv(shares, RATE_PRECISION);
    }

    /** @dev function for users are liquor to change fee status */
    function getFeeStatus() external view returns (address, bool, uint128, uint128) {
        return (state.feeRecipient, state.feeEnabled, state.depositFeeBPS, state.withdrawFeeBPS);
    }

    function getDebtInfo(uint256 id) external view returns (UpdatedDebtRatio memory) {
        return updatedDebtRatio[id];
    }

    function getSakeUsers(uint256 id) external view returns (uint256 totalVLP, address[] memory users) {
        totalVLP = sakeVaultInfo[id].totalAmountOfVLP;
        uint256 usersLength = sakeVaultInfo[id].users.length;
        users = new address[](usersLength);
        for (uint256 i = 0; i < usersLength; i++) {
            users[i] = sakeVaultInfo[id].users[i];
        }
    }

    function isValidUpdate(uint256 id) public view returns (bool isValid) {
        // if last deposit / withdraw is 8 hours before
        uint256 currentVLPPrice = getVLPPrice();
        uint256 previousVLPPrice = updatedDebtRatio[id].previousPrice;

        uint256 priceChange = currentVLPPrice > previousVLPPrice
            ? currentVLPPrice - previousVLPPrice
            : previousVLPPrice - currentVLPPrice;
        //28800 is 8 hours in seconds
        uint256 onePercent = 1000;
        if (
            block.timestamp - updatedDebtRatio[id].lastUpdateTime > 28800 ||
            priceChange.mulDiv(RATE_PRECISION, previousVLPPrice) > onePercent.mulDiv(RATE_PRECISION, MAX_BPS)
        ) {
            return true;
        } else {
            return false;
        }
    }

    function convertVLPToUSDC(uint256 _amount) public view returns (uint256) {
        uint256 _vlpPrice = getVLPPrice();
        return _amount.mulDiv(_vlpPrice * 10, (10 ** 18));
    }

    function getVLPPrice() public view returns (uint256) {
        return IVault(state.velaMintBurnVault).getVLPPrice();
    }

    /**
     * @notice Calculates the maximum deposit amount (`MaxDeposit`) allowed based on the current debt (`Debt`)
     * and water balance (`WaterBalance`) in USDC.
     *
     * Formula: MaxDeposit = (Debt + 2 * MaxDeposit) / (Debt + WaterBalance)
     */
    function _getMaxDeposit(uint256 totalDebt, uint256 waterBalance) internal view returns (uint256) {
        uint256 y = waterBalance.mulDiv(40000, MAX_BPS) - totalDebt.mulDiv(10000, MAX_BPS);
        return y;
    }

    function checkMaximumDeposit(uint256 amount) public view returns (bool status) {
        uint256 totalDebt = IWater(state.water).getTotalDebt();
        uint256 WaterUSDCBalance = state.usdcToken.balanceOf(state.water);

        uint256 maxDeposit = _getMaxDeposit(totalDebt, WaterUSDCBalance);

        if (amount > maxDeposit) {
            status = true;
        }
        return status;
    }

    /* ##################################################################
                                KEEPER FUNCTIONS
    ################################################################## */
    /// @notice Create new SAKE Vault
    function createSake() external onlyKeeper {
        uint256 lCurrentId = currentId;
        // compute the amount deposited with the last known time
        uint256 _amount = sakeVaultInfo[lCurrentId].totalAmountOfUSDCWithoutLeverage * 3;
        // revert if no deposit occure
        require(_amount != 0, "Current Deposit Is Zero");
        // create new SAKE
        Sake newSake = new Sake(
            address(state.usdcToken),
            address(this),
            state.velaMintBurnVault,
            state.velaStakingVault,
            state.vlp,
            state.liquor
        );

        sakeVault[lCurrentId] = address(newSake);
        // safeTransfer _token into the newly created SAKE
        state.usdcToken.safeTransfer(address(newSake), _amount);
        (bool _status, uint256 totalVLP) = newSake.executeMintAndStake();
        require(_status, "Sake Creation failed");

        sakeVaultInfo[lCurrentId].totalAmountOfVLP = totalVLP;
        sakeVaultInfo[lCurrentId].totalAmountOfVLPInUSDC = convertVLPToUSDC(totalVLP);
        sakeVaultInfo[lCurrentId].startTime = block.timestamp;
        sakeVaultInfo[lCurrentId].purchasePrice = getVLPPrice();
        initializedAllSakeUsersShares(lCurrentId);
        storeDebtRatio(lCurrentId, 0);
        currentId++;
        emit CreateNewSake(address(newSake), lCurrentId);
    }

    function computeTotalDebtValueAndUpdateWaterDebt(
        bool _state,
        uint256 _amount,
        uint256 initialDebt,
        uint256 feeSplit,
        uint256 previousValue,
        uint256 previousDebt
    ) internal returns (uint256, uint256) {
        uint256 amountInUSDC = _amount;

        uint256 profitDifferences;
        // profit difference should be with previous value
        // uint256 getPreviousValue = State.newValue;
        // check if there is profit
        // i.e the total amount of VLP in USDC is greater than the current amount with leverage
        // and when there is not profit the debt remains.
        if (amountInUSDC > previousValue) {
            profitDifferences = amountInUSDC - previousValue;
        }
        // calculate the fee split rateand reward split to water when there is profit
        // rewardSplitToWater returns 0 when there is no profit

        uint256 rewardSplitToWater = profitDifferences.mulDiv(feeSplit, RATE_PRECISION);
        // uint256 previousDebt = State.newDebt;
        uint256 previousDebtAddRewardSplit = previousDebt + rewardSplitToWater;
        uint256 totalDebt;
        if (_state) {
            if (previousDebt == 0) {
                totalDebt = initialDebt;
            } else {
                totalDebt = previousDebtAddRewardSplit;
                IWater(state.water).updateTotalDebt(rewardSplitToWater);
            }
        }
        if (!_state) {
            uint256 getPreviousDVTRatio = previousDebtAddRewardSplit.mulDiv(RATE_PRECISION, amountInUSDC);
            totalDebt = amountInUSDC.mulDiv(getPreviousDVTRatio, RATE_PRECISION);
            IWater(state.water).updateTotalDebt(rewardSplitToWater);
        }
        return (totalDebt, amountInUSDC);
    }

    /* ##################################################################
                                USER FUNCTIONS
    ################################################################## */
    /** @dev See {IBartender-deposit}. */
    function deposit(uint256 _amount) external {
        require(_amount >= state.minimumDeposit, "Minimum Deposit not reached");
        uint256 lCurrentId = currentId;
        SakeVaultInfo storage svi = sakeVaultInfo[lCurrentId];
        require(!checkMaximumDeposit(_amount), "Throw Max Deposit Exceeded");
        require(svi.users.length < state.maxSakeUsers, "Max Sake Users Reached");

        state.usdcToken.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 fees = _amount.mulDiv(state.depositFeeBPS, MAX_BPS);
        uint256 amount = _amount - (fees);
        uint256 initialDeposit = depositInfo[msg.sender][currentId].amount;

        if (fees > 0) {
            (state.usdcToken).safeTransfer(state.feeRecipient, fees);
        }

        // locally store 2X leverage to avoid computing mload everytime
        uint256 leverage = amount * 2;
        IWater(state.water).leverageVault(leverage);

        // take leverage from WATER VAULT
        // update total amount without borrowed amount
        svi.totalAmountOfUSDCWithoutLeverage = svi.totalAmountOfUSDCWithoutLeverage + amount;
        // update amount stake on current time interval
        svi.leverage = svi.leverage + leverage;
        // update user state values
        depositInfo[msg.sender][lCurrentId].amount += amount;
        // push users into list
        if (initialDeposit == 0) {
            svi.users.push(msg.sender);
        }
        emit BartenderDeposit(msg.sender, _amount, lCurrentId, leverage);
    }

    /** @dev See {IBartender-withdraw}. */
    function withdraw(uint256 _amount, uint256 id) external {
        require(!sakeVaultInfo[id].isLiquidated, "Sake Vault Liquidated");

        require(_amount != 0, "Zero Amount");

        //    require(block.timestamp >= sakeVaultInfo[id].startTime + COOLDOWN_PERIOD, "Time Lock On");

        require(_amount <= previewWithdraw(id, msg.sender), "Invalid Amount");

        uint256 withdrawableAmountInVLP = _calculateVlpToBeSold(_amount, id, msg.sender);
        address _sake = sakeVault[id];
        (bool status, uint256 _withdrawnAmountinUSDC) = Sake(_sake).withdraw(address(this), withdrawableAmountInVLP);
        require(status, "SakeWithdrawal");
        state.usdcToken.approve(state.water, _withdrawnAmountinUSDC);

        uint256 loan = (_withdrawnAmountinUSDC - _amount);
        // repay loan to WATER VAULT
        IWater(state.water).repayDebt(loan);
        // take protocol fee
        uint256 fees = _amount.mulDiv(state.withdrawFeeBPS, MAX_BPS);
        uint256 amount = _amount - fees;
        if (fees > 0) {
            (state.usdcToken).safeTransfer(state.feeRecipient, fees);
        }
        (state.usdcToken).safeTransfer(msg.sender, amount);

        emit BartenderWithdraw(msg.sender, _amount, id, withdrawableAmountInVLP);
    }

    /* ##################################################################
                                INTERNAL FUNCTIONS
    ################################################################## */

    function _calculateVlpToBeSold(uint256 withdrawableAmount, uint256 id, address sender) internal returns (uint256) {
        uint256 updatedDebt;
        uint256 value;
        // when new value is 0, then it shows the SAKE vault is been created, get the current debt and value
        // else get the previous debt and value
        (updatedDebt, value, ) = updateDebtAndValueAmount(id, true);
        // get the difference between the current value and the updated debt
        // use the difference to and the withdrawable amount * value / difference.
        uint256 subDebtFromValue = value - updatedDebt;
        uint256 withdrawableAmountMulValue = withdrawableAmount.mulDiv(value, subDebtFromValue);
        // the previous debt and value is used to calculate the shares, using the withdrawable amount.
        (uint256 previousValue, uint256 previousDebt) = storeDebtRatio(id, withdrawableAmountMulValue);
        _updateShares(id, sender, withdrawableAmount, previousValue, previousDebt);
        // the amount of VLP to be sold is the withdrawable amount / the current VLP price
        uint256 requireAMountOfVLPToBeSold = withdrawableAmountMulValue.mulDiv(10 ** 18, getVLPPrice() * 10);
        // // update the total amount of VLP in the SAKE vault
        sakeVaultInfo[id].totalAmountOfVLP -= requireAMountOfVLPToBeSold;
        // // return the amount of VLP to be sold
        return requireAMountOfVLPToBeSold;
    }

    function initializedAllSakeUsersShares(uint256 id) private {
        uint256 totalUsers = sakeVaultInfo[id].users.length;
        uint256 amountWithoutLeverage = sakeVaultInfo[id].totalAmountOfUSDCWithoutLeverage;
        for (uint256 i = 0; i < totalUsers; ) {
            address user = sakeVaultInfo[id].users[i];
            uint256 _amountDepositedAndLeverage = depositInfo[user][id].amount;
            depositInfo[user][id].shares = (_amountDepositedAndLeverage.mulDiv(RATE_PRECISION, amountWithoutLeverage));
            unchecked {
                i++;
            }
        }
    }

    function storeDebtRatio(
        uint256 id,
        uint256 requireToBeSold
    ) private returns (uint256 previousValue, uint256 previousDebt) {
        uint256 updatedDebt;
        uint256 value;
        uint256 dvtRatio;

        previousValue = updatedDebtRatio[id].newValue;
        previousDebt = updatedDebtRatio[id].newDebt;
        if (requireToBeSold == 0) {
            (updatedDebt, value, dvtRatio) = updateDebtAndValueAmount(id, true);
        } else {
            (updatedDebt, value, dvtRatio) = updateDebtAndValueAmount(id, false);
            value = value - requireToBeSold;
            updatedDebt = value.mulDiv(dvtRatio, RATE_PRECISION);
        }
        updatedDebtRatio[id].newDebt = updatedDebt;
        updatedDebtRatio[id].newValue = value;
        updatedDebtRatio[id].newRatio = dvtRatio;
    }

    function _updateShares(
        uint256 id,
        address sender,
        uint256 withdrawableAmount,
        uint256 previousValue,
        uint256 previousDebt
    ) private {
        uint256 newDebt = updatedDebtRatio[id].newDebt;
        uint256 newValue = updatedDebtRatio[id].newValue;
        // get the total number of users in the SAKE vault
        uint256 totalUsers = sakeVaultInfo[id].users.length;
        for (uint256 i = 0; i < totalUsers; ) {
            // load the user address into memory
            address user = sakeVaultInfo[id].users[i];
            if (user == sender) {
                uint256 subAmountFromMaxWithdrawal = beforeWithdrawal(id, previousValue, previousDebt, user) -
                    withdrawableAmount;

                uint256 _newShare = subAmountFromMaxWithdrawal.mulDiv(RATE_PRECISION, (newValue - newDebt));
                depositInfo[sender][id].shares = _newShare;
                depositInfo[sender][id].totalWithdrawn = subAmountFromMaxWithdrawal;
            } else {
                uint256 subAmountFromMaxWithdrawal = beforeWithdrawal(id, previousValue, previousDebt, user);

                uint256 share = subAmountFromMaxWithdrawal.mulDiv(RATE_PRECISION, ((newValue - newDebt)));
                depositInfo[user][id].shares = share;
            }
            unchecked {
                i++;
            }
        }
    }

    function updateDebtAndValueAmount(
        uint256 id,
        bool _state
    ) public returns (uint256 totalDebt, uint256 amountInUSDC, uint256 dvtRatio) {
        (uint256 feeSplit, ) = calculateFeeSplitRate();

        (totalDebt, amountInUSDC) = computeTotalDebtValueAndUpdateWaterDebt(
            _state,
            convertVLPToUSDC(sakeVaultInfo[id].totalAmountOfVLP),
            sakeVaultInfo[id].totalAmountOfUSDCWithoutLeverage * 2,
            feeSplit,
            updatedDebtRatio[id].newValue,
            updatedDebtRatio[id].newDebt
        );

        UpdatedDebtRatio memory _updatedDebtRatio = UpdatedDebtRatio({
            newValue: amountInUSDC,
            newDebt: totalDebt,
            newRatio: totalDebt.mulDiv(RATE_PRECISION, amountInUSDC),
            lastUpdateTime: block.timestamp,
            previousPrice: getVLPPrice()
        });
        updatedDebtRatio[id] = _updatedDebtRatio;

        // DVT Ratio is the total amount of new debt / total amount of VLP in USDC
        // return the new debt, amount in USDC which is the total amount of VLP in USDC and the DVT Ratio
        return (totalDebt, amountInUSDC, totalDebt.mulDiv(RATE_PRECISION, amountInUSDC));
    }

    //change to public for testing purpose
    function calculateFeeSplitRate() public view returns (uint256 feeSplitRate, uint256 utilizationRatio) {
        (, bytes memory _totalAssets) = address(state.water).staticcall(abi.encodeWithSignature("totalAssets()"));
        (, bytes memory _totalDebt) = address(state.water).staticcall(abi.encodeWithSignature("getTotalDebt()"));

        uint256 totalAssets = abi.decode(_totalAssets, (uint256));
        uint256 totalDebt = abi.decode(_totalDebt, (uint256));

        (feeSplitRate, utilizationRatio) = calculateFeeSplit((totalAssets - totalDebt), totalDebt);

        return (feeSplitRate, utilizationRatio);
    }

    function beforeWithdrawal(
        uint256 id,
        uint256 previousValue,
        uint256 previousDebt,
        address user
    ) public view returns (uint256 max) {
        // convert total amount of VLP to USDC
        uint256 amountInUSDC = convertVLPToUSDC(sakeVaultInfo[id].totalAmountOfVLP);
        uint256 profitDifferences;
        // profit difference should be with previous value
        // uint256 getPreviousValue = updatedDebtRatio[id].newValue;
        // check if there is profit
        // i.e the total amount of VLP in USDC is greater than the current amount with leverage
        // and when there is not profit the debt remains.
        if (amountInUSDC > previousValue) {
            profitDifferences = amountInUSDC - previousValue;
        }
        // // calculate the fee split rateand reward split to water when there is profit
        (uint256 feeSplit, ) = calculateFeeSplitRate();
        uint256 rewardSplitToWater = (profitDifferences.mulDiv(feeSplit, RATE_PRECISION));
        uint256 previousDebtAddRewardSplit = previousDebt + rewardSplitToWater;
        uint256 currentShares = depositInfo[user][id].shares;

        return (amountInUSDC - previousDebtAddRewardSplit).mulDiv(currentShares, RATE_PRECISION);
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
     * New protocol implementation uses the new calculateInterestRates() interface
     * @param totalDebtInUSDC The liquidity available in the corresponding aToken
     * @param waterBalanceInUSDC The total borrowed from the reserve at a variable rate
     **/
    function calculateFeeSplit(
        uint256 waterBalanceInUSDC,
        uint256 totalDebtInUSDC
    ) internal view returns (uint256 feeSplitRate, uint256 ur) {
        uint256 utilizationRate = getUtilizationRate(waterBalanceInUSDC, totalDebtInUSDC);
        // uint256 utilizationRate = _ratio.mulDiv(_maxBPS, RATE_PRECISION);
        if (utilizationRate <= feeStrategy.utilizationThreshold1) {
            /* Slope 1
            rewardFee_{slope2} =  
                {maxFeeSplitSlope1 *  {(utilization Ratio / URThreshold1)}}
            */
            feeSplitRate = (feeStrategy.maxFeeSplitSlope1).mulDiv(utilizationRate, feeStrategy.utilizationThreshold1);
        } else if (
            utilizationRate > feeStrategy.utilizationThreshold1 && utilizationRate < feeStrategy.utilizationThreshold2
        ) {
            /* Slope 2
            rewardFee_{slope2} =  
                maxFeeSplitSlope1 + 
                {(utilization Ratio - URThreshold1) / 
                (1 - UR Threshold1 - (UR Threshold3 - URThreshold2)}
                * (maxFeeSplitSlope2 -maxFeeSplitSlope1) 
            */
            uint256 subThreshold1FromUtilizationRate = utilizationRate - feeStrategy.utilizationThreshold1;
            uint256 maxBpsSubThreshold1 = RATE_PRECISION - feeStrategy.utilizationThreshold1;
            uint256 threshold3SubThreshold2 = feeStrategy.utilizationThreshold3 - feeStrategy.utilizationThreshold2;
            uint256 mSlope2SubMSlope1 = feeStrategy.maxFeeSplitSlope2 - feeStrategy.maxFeeSplitSlope1;
            uint256 feeSlpope = maxBpsSubThreshold1 - threshold3SubThreshold2;
            uint256 split = subThreshold1FromUtilizationRate.mulDiv(RATE_PRECISION, feeSlpope);
            feeSplitRate = mSlope2SubMSlope1.mulDiv(split, RATE_PRECISION);
            feeSplitRate = feeSplitRate + (feeStrategy.maxFeeSplitSlope1);
        } else if (
            utilizationRate > feeStrategy.utilizationThreshold2 && utilizationRate < feeStrategy.utilizationThreshold3
        ) {
            /* Slope 3
            rewardFee_{slope3} =  
                maxFeeSplitSlope2 + {(utilization Ratio - URThreshold2) / 
                (1 - UR Threshold2}
                * (maxFeeSplitSlope3 -maxFeeSplitSlope2) 
            */
            uint256 subThreshold2FromUtilirationRatio = utilizationRate - feeStrategy.utilizationThreshold2;
            uint256 maxBpsSubThreshold2 = RATE_PRECISION - feeStrategy.utilizationThreshold2;
            uint256 mSlope3SubMSlope2 = feeStrategy.maxFeeSplitSlope3 - feeStrategy.maxFeeSplitSlope2;
            uint256 split = subThreshold2FromUtilirationRatio.mulDiv(RATE_PRECISION, maxBpsSubThreshold2);

            feeSplitRate = (split.mulDiv(mSlope3SubMSlope2, RATE_PRECISION)) + (feeStrategy.maxFeeSplitSlope2);
        }
        return (feeSplitRate, utilizationRate);
    }

    function getUtilizationRate(uint256 waterBalanceInUSDC, uint256 totalDebtInUSDC) internal view returns (uint256) {
        return totalDebtInUSDC == 0 ? 0 : totalDebtInUSDC.mulDiv(RATE_PRECISION, waterBalanceInUSDC + totalDebtInUSDC);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IVault} from "../interfaces/vela-exchange/IVault.sol";
import {ITokenFarm} from "../interfaces/vela-exchange/ITokenFarm.sol";

contract Sake {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //@note keep as immutable so that bartender can change these variables when creating new Sake
    IERC20Upgradeable public usdcToken;
    address public bartender;
    uint256 public totalAmountOfVLP;
    address public liquor;

    //vela exchange contracts

    IVault public velaMintBurnVault;
    ITokenFarm public velaStakingVault;
    IERC20Upgradeable public vlp;

    modifier onlyBartenderOrLiquor() {
        require(
            msg.sender == address(bartender) || msg.sender == address(liquor),
            string(abi.encodePacked("PermissionDenied: admin=", address(bartender), ", sender=", msg.sender))
        );
        _;
    }

    constructor(
        address _usdcToken,
        address _bartender,
        address _velaMintBurnVault,
        address _velaStakingVault,
        address _vlp,
        address _liquor
    ) {
        usdcToken = IERC20Upgradeable(_usdcToken);
        bartender = _bartender;
        velaMintBurnVault = IVault(_velaMintBurnVault);
        velaStakingVault = ITokenFarm(_velaStakingVault);
        vlp = IERC20Upgradeable(_vlp);
        liquor = _liquor;
    }

    /// @notice allows bartender to mint and stake vlp into the sake contract
    /// @return status status is true if the function executed sucessfully, vice versa
    function executeMintAndStake() external onlyBartenderOrLiquor returns (bool status, uint256 totalVLP) {
        uint256 usdcBalance = usdcToken.balanceOf(address(this));
        usdcToken.approve(address(velaMintBurnVault), usdcBalance);
        //mint the whole batch of USDC to VLP, sake doesn't handle the accounting, so balanceOf will be sufficient.
        // @notice there is no need for reentrancy guard Bartender will handle that
        // REFERENCE: 01
        // @todo a struct/variables to store or return this values so that bartender can store them to calculate user share during withdrawal
        // vlp recieved,
        // amount used to purchase the vlp, (can be excluded since it amount transferred by bartender to sake)
        // price at which vlp was bought
        velaMintBurnVault.stake(address(this), address(usdcToken), usdcBalance);
        totalVLP = vlp.balanceOf(address(this));
        // vlp approve staking vault with uint256 max
        vlp.approve(address(velaStakingVault), totalVLP);
        // get the total amount of VLP bought
        totalAmountOfVLP = totalVLP;
        velaStakingVault.deposit(0, totalVLP);

        return (true, totalVLP);
    }

    /// @notice allows bartender to withdraw a specific amount from the sake contract
    /// @param _to user reciving the redeemed USDC
    /// @param amountToWithdrawInVLP amount to withdraw in VLP
    /// @return status received in exchange of token
    function withdraw(
        address _to,
        uint256 amountToWithdrawInVLP
    ) external onlyBartenderOrLiquor returns (bool status, uint256 usdcAmount) {
        vlp.approve(address(velaStakingVault), amountToWithdrawInVLP);
        velaStakingVault.withdraw(0, amountToWithdrawInVLP);
        velaMintBurnVault.unstake(address(usdcToken), amountToWithdrawInVLP, address(this));
        uint256 withdrawAmount = usdcToken.balanceOf(address(this));

        //sake will send the USDC back to the user directly
        usdcToken.safeTransfer(_to, withdrawAmount);
        totalAmountOfVLP -= amountToWithdrawInVLP;
        return (true, withdrawAmount);
    }

    // create a function to output sake balance in vlp
    function getSakeBalanceInVLP() external view returns (uint256 vlpBalance) {
        return totalAmountOfVLP;
    }

    function getClaimable() public view returns (uint256) {
        return velaStakingVault.claimable(address(this));
    }

    function withdrawVesting() external onlyBartenderOrLiquor {
        velaStakingVault.withdrawVesting();
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface ISake {

    function withdraw(
        address _to,
        uint256 amountToWithdrawInVLP
    ) external returns (bool status, uint256 usdcAmount);

    function withdrawVesting() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @dev Interface of the VeDxp
 */
interface ITokenFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function claimable(address _account) external view returns (uint256);

    function withdrawVesting() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

//@note this interface is actually for minting and burning, the function name is confusing
interface IVault {
    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _vlpAmount, address _receiver) external;

    function getVLPPrice() external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

/**
 * @author Chef Photons, Vaultka Team serving high quality drinks; drink responsibly.
 * Responsible for our customers not getting intoxicated
 * @notice provided interface for `Water.sol`
 */
interface IWater {
        /// @notice supply USDC to the vault
    /// @param _amount to be leveraged to Bartender (6 decimals)
    function leverageVault(uint256 _amount) external;

    /// @notice collect debt from Bartender
    /// @param _amount to be collected from Bartender (6 decimals)
    function repayDebt(uint256 _amount) external;

    function getTotalDebt() external view returns (uint256);

    function updateTotalDebt(uint256 profit) external returns (uint256);
}