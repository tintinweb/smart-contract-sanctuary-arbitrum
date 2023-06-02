// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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

pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/IVesselManager.sol";
import "./Interfaces/IDebtToken.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Interfaces/ISortedVessels.sol";
import "./Interfaces/IFeeCollector.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Dependencies/PreonBase.sol";
import "./Dependencies/SafetyTransfer.sol";

contract BorrowerOperations is PreonBase, IBorrowerOperations {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    string public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    IVesselManager public vesselManager;
    IStabilityPool public stabilityPool;
    address public gasPoolAddress;
    ICollSurplusPool public collSurplusPool;
    IFeeCollector public feeCollector;
    IDebtToken public debtToken;
    ISortedVessels public sortedVessels; // double-linked list, sorted by their collateral ratios

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

    struct LocalVariables_adjustVessel {
        address asset;
        uint256 price;
        uint256 collChange;
        uint256 netDebtChange;
        bool isCollIncrease;
        uint256 debt;
        uint256 coll;
        uint256 oldICR;
        uint256 newICR;
        uint256 newTCR;
        uint256 debtTokenFee;
        uint256 newDebt;
        uint256 newColl;
        uint256 stake;
    }

    struct LocalVariables_openVessel {
        address asset;
        uint256 price;
        uint256 debtTokenFee;
        uint256 netDebt;
        uint256 compositeDebt;
        uint256 ICR;
        uint256 NICR;
        uint256 stake;
        uint256 arrayIndex;
    }

    struct ContractsCache {
        IAdminContract adminContract;
        IVesselManager vesselManager;
        IActivePool activePool;
        IDebtToken debtToken;
    }

    enum BorrowerOperation {
        openVessel,
        closeVessel,
        adjustVessel
    }

    event VesselUpdated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 stake,
        BorrowerOperation operation
    );

    // --- Dependency setters ---

    function setAddresses(
        address _vesselManagerAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _sortedVesselsAddress,
        address _debtTokenAddress,
        address _feeCollectorAddress,
        address _adminContractAddress
    ) external initializer {
        __Ownable_init();
        vesselManager = IVesselManager(_vesselManagerAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        sortedVessels = ISortedVessels(_sortedVesselsAddress);
        debtToken = IDebtToken(_debtTokenAddress);
        feeCollector = IFeeCollector(_feeCollectorAddress);
        adminContract = IAdminContract(_adminContractAddress);
    }

    // --- Borrower Vessel Operations ---

    function openVessel(
        address _asset,
        uint256 _assetAmount,
        uint256 _debtTokenAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        ContractsCache memory contractsCache = ContractsCache({
            adminContract: adminContract,
            vesselManager: vesselManager,
            activePool: adminContract.activePool(),
            debtToken: debtToken
        });
        require(
            contractsCache.adminContract.getIsActive(_asset),
            "BorrowerOps: Asset is not active"
        );
        LocalVariables_openVessel memory vars;
        vars.asset = _asset;

        vars.price = contractsCache.adminContract.priceFeed().fetchPrice(
            vars.asset
        );
        bool isRecoveryMode = _checkRecoveryMode(vars.asset, vars.price);

        _requireVesselIsNotActive(
            vars.asset,
            contractsCache.vesselManager,
            msg.sender
        );

        vars.netDebt = _debtTokenAmount;

        if (!isRecoveryMode) {
            vars.debtTokenFee = _triggerBorrowingFee(
                vars.asset,
                contractsCache.vesselManager,
                contractsCache.debtToken,
                _debtTokenAmount
            );
            vars.netDebt = vars.netDebt + vars.debtTokenFee;
        }
        _requireAtLeastMinNetDebt(vars.asset, vars.netDebt);

        // ICR is based on the composite debt, i.e. the requested debt token amount + borrowing fee + gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.asset, vars.netDebt);
        assert(vars.compositeDebt > 0);

        vars.ICR = PreonMath._computeCR(
            _assetAmount,
            vars.compositeDebt,
            vars.price
        );
        vars.NICR = PreonMath._computeNominalCR(
            _assetAmount,
            vars.compositeDebt
        );

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.asset, vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.asset, vars.ICR);
            uint256 newTCR = _getNewTCRFromVesselChange(
                vars.asset,
                _assetAmount,
                true,
                vars.compositeDebt,
                true,
                vars.price
            ); // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(vars.asset, newTCR);
        }

        // Set the vessel struct's properties
        contractsCache.vesselManager.setVesselStatus(vars.asset, msg.sender, 1); // Vessel Status 1 = Active
        contractsCache.vesselManager.increaseVesselColl(
            vars.asset,
            msg.sender,
            _assetAmount
        );
        contractsCache.vesselManager.increaseVesselDebt(
            vars.asset,
            msg.sender,
            vars.compositeDebt
        );

        contractsCache.vesselManager.updateVesselRewardSnapshots(
            vars.asset,
            msg.sender
        );
        vars.stake = contractsCache.vesselManager.updateStakeAndTotalStakes(
            vars.asset,
            msg.sender
        );

        sortedVessels.insert(
            vars.asset,
            msg.sender,
            vars.NICR,
            _upperHint,
            _lowerHint
        );
        vars.arrayIndex = contractsCache.vesselManager.addVesselOwnerToArray(
            vars.asset,
            msg.sender
        );
        emit VesselCreated(vars.asset, msg.sender, vars.arrayIndex);

        // Move the asset to the Active Pool, and mint the debtToken amount to the borrower
        _activePoolAddColl(vars.asset, contractsCache.activePool, _assetAmount);
        _withdrawDebtTokens(
            vars.asset,
            contractsCache.activePool,
            contractsCache.debtToken,
            msg.sender,
            _debtTokenAmount,
            vars.netDebt
        );
        // Move the debtToken gas compensation to the Gas Pool
        _withdrawDebtTokens(
            vars.asset,
            contractsCache.activePool,
            contractsCache.debtToken,
            gasPoolAddress,
            contractsCache.adminContract.getDebtTokenGasCompensation(
                vars.asset
            ),
            contractsCache.adminContract.getDebtTokenGasCompensation(vars.asset)
        );

        emit VesselUpdated(
            vars.asset,
            msg.sender,
            vars.compositeDebt,
            _assetAmount,
            vars.stake,
            BorrowerOperation.openVessel
        );
        emit BorrowingFeePaid(vars.asset, msg.sender, vars.debtTokenFee);
    }

    // Send collateral to a vessel
    function addColl(
        address _asset,
        uint256 _assetSent,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustVessel(
            _asset,
            _assetSent,
            msg.sender,
            0,
            0,
            false,
            _upperHint,
            _lowerHint
        );
    }

    // Withdraw collateral from a vessel
    function withdrawColl(
        address _asset,
        uint256 _collWithdrawal,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustVessel(
            _asset,
            0,
            msg.sender,
            _collWithdrawal,
            0,
            false,
            _upperHint,
            _lowerHint
        );
    }

    // Withdraw debt tokens from a vessel: mint new debt tokens to the owner, and increase the vessel's debt accordingly
    function withdrawDebtTokens(
        address _asset,
        uint256 _debtTokenAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustVessel(
            _asset,
            0,
            msg.sender,
            0,
            _debtTokenAmount,
            true,
            _upperHint,
            _lowerHint
        );
    }

    // Repay debt tokens to a Vessel: Burn the repaid debt tokens, and reduce the vessel's debt accordingly
    function repayDebtTokens(
        address _asset,
        uint256 _debtTokenAmount,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustVessel(
            _asset,
            0,
            msg.sender,
            0,
            _debtTokenAmount,
            false,
            _upperHint,
            _lowerHint
        );
    }

    function adjustVessel(
        address _asset,
        uint256 _assetSent,
        uint256 _collWithdrawal,
        uint256 _debtTokenChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external override {
        _adjustVessel(
            _asset,
            _assetSent,
            msg.sender,
            _collWithdrawal,
            _debtTokenChange,
            _isDebtIncrease,
            _upperHint,
            _lowerHint
        );
    }

    /*
     * _adjustVessel(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal.
     */
    function _adjustVessel(
        address _asset,
        uint256 _assetSent,
        address _borrower,
        uint256 _collWithdrawal,
        uint256 _debtTokenChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) internal {
        ContractsCache memory contractsCache = ContractsCache({
            adminContract: adminContract,
            vesselManager: vesselManager,
            activePool: adminContract.activePool(),
            debtToken: debtToken
        });
        LocalVariables_adjustVessel memory vars;
        vars.asset = _asset;
        vars.price = contractsCache.adminContract.priceFeed().fetchPrice(
            vars.asset
        );
        bool isRecoveryMode = _checkRecoveryMode(vars.asset, vars.price);

        if (_isDebtIncrease) {
            _requireNonZeroDebtChange(_debtTokenChange);
        }
        _requireSingularCollChange(_collWithdrawal, _assetSent);
        _requireNonZeroAdjustment(
            _collWithdrawal,
            _debtTokenChange,
            _assetSent
        );
        _requireVesselIsActive(
            vars.asset,
            contractsCache.vesselManager,
            _borrower
        );

        // Confirm the operation is either a borrower adjusting their own vessel, or a pure asset transfer from the Stability Pool to a vessel
        assert(
            msg.sender == _borrower ||
                (address(stabilityPool) == msg.sender &&
                    _assetSent > 0 &&
                    _debtTokenChange == 0)
        );

        contractsCache.vesselManager.applyPendingRewards(vars.asset, _borrower);

        // Get the collChange based on whether or not asset was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(
            _assetSent,
            _collWithdrawal
        );

        vars.netDebtChange = _debtTokenChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) {
            vars.debtTokenFee = _triggerBorrowingFee(
                vars.asset,
                contractsCache.vesselManager,
                contractsCache.debtToken,
                _debtTokenChange
            );
            vars.netDebtChange = vars.netDebtChange + vars.debtTokenFee; // The raw debt change includes the fee
        }

        vars.debt = contractsCache.vesselManager.getVesselDebt(
            vars.asset,
            _borrower
        );
        vars.coll = contractsCache.vesselManager.getVesselColl(
            vars.asset,
            _borrower
        );

        // Get the vessel's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = PreonMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromVesselChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease,
            vars.price
        );
        require(
            _collWithdrawal <= vars.coll,
            "BorrowerOps: Trying to remove more than the vessel holds"
        );

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(
            vars.asset,
            isRecoveryMode,
            _collWithdrawal,
            _isDebtIncrease,
            vars
        );

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough debt tokens
        if (!_isDebtIncrease && _debtTokenChange > 0) {
            _requireAtLeastMinNetDebt(
                vars.asset,
                _getNetDebt(vars.asset, vars.debt) - vars.netDebtChange
            );
            _requireValidDebtTokenRepayment(
                vars.asset,
                vars.debt,
                vars.netDebtChange
            );
            _requireSufficientDebtTokenBalance(
                contractsCache.debtToken,
                _borrower,
                vars.netDebtChange
            );
        }

        (vars.newColl, vars.newDebt) = _updateVesselFromAdjustment(
            vars.asset,
            contractsCache.vesselManager,
            _borrower,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );
        vars.stake = contractsCache.vesselManager.updateStakeAndTotalStakes(
            vars.asset,
            _borrower
        );

        // Re-insert vessel in to the sorted list
        uint256 newNICR = _getNewNominalICRFromVesselChange(
            vars.coll,
            vars.debt,
            vars.collChange,
            vars.isCollIncrease,
            vars.netDebtChange,
            _isDebtIncrease
        );
        sortedVessels.reInsert(
            vars.asset,
            _borrower,
            newNICR,
            _upperHint,
            _lowerHint
        );

        emit VesselUpdated(
            vars.asset,
            _borrower,
            vars.newDebt,
            vars.newColl,
            vars.stake,
            BorrowerOperation.adjustVessel
        );
        emit BorrowingFeePaid(vars.asset, msg.sender, vars.debtTokenFee);

        // Use the unmodified _debtTokenChange here, as we don't send the fee to the user
        _moveTokensFromAdjustment(
            vars.asset,
            contractsCache.activePool,
            contractsCache.debtToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _debtTokenChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeVessel(address _asset) external override {
        IVesselManager vesselManagerCached = vesselManager;
        IAdminContract adminContractCached = adminContract;
        IActivePool activePoolCached = adminContractCached.activePool();
        IDebtToken debtTokenCached = debtToken;

        _requireVesselIsActive(_asset, vesselManagerCached, msg.sender);
        uint256 price = adminContractCached.priceFeed().fetchPrice(_asset);
        _requireNotInRecoveryMode(_asset, price);

        vesselManagerCached.applyPendingRewards(_asset, msg.sender);

        uint256 coll = vesselManagerCached.getVesselColl(_asset, msg.sender);
        uint256 debt = vesselManagerCached.getVesselDebt(_asset, msg.sender);

        _requireSufficientDebtTokenBalance(
            debtTokenCached,
            msg.sender,
            debt - adminContractCached.getDebtTokenGasCompensation(_asset)
        );

        uint256 newTCR = _getNewTCRFromVesselChange(
            _asset,
            coll,
            false,
            debt,
            false,
            price
        );
        _requireNewTCRisAboveCCR(_asset, newTCR);

        vesselManagerCached.removeStake(_asset, msg.sender);
        vesselManagerCached.closeVessel(_asset, msg.sender);

        emit VesselUpdated(
            _asset,
            msg.sender,
            0,
            0,
            0,
            BorrowerOperation.closeVessel
        );
        uint256 gasCompensation = adminContractCached
            .getDebtTokenGasCompensation(_asset);
        // Burn the repaid debt tokens from the user's balance and the gas compensation from the Gas Pool
        _repayDebtTokens(
            _asset,
            activePoolCached,
            debtTokenCached,
            msg.sender,
            debt - gasCompensation
        );
        _repayDebtTokens(
            _asset,
            activePoolCached,
            debtTokenCached,
            gasPoolAddress,
            gasCompensation
        );

        // Signal to the fee collector that debt has been paid in full
        feeCollector.closeDebt(msg.sender, _asset);

        // Send the collateral back to the user
        activePoolCached.sendAsset(_asset, msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral(address _asset) external override {
        // send asset from CollSurplusPool to owner
        collSurplusPool.claimColl(_asset, msg.sender);
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(
        address _asset,
        IVesselManager _vesselManager,
        IDebtToken _debtToken,
        uint256 _debtTokenAmount
    ) internal returns (uint256) {
        uint256 debtTokenFee = _vesselManager.getBorrowingFee(
            _asset,
            _debtTokenAmount
        );
        _debtToken.mint(_asset, address(feeCollector), debtTokenFee);
        feeCollector.increaseDebt(msg.sender, _asset, debtTokenFee);
        return debtTokenFee;
    }

    function _getUSDValue(
        uint256 _coll,
        uint256 _price
    ) internal pure returns (uint256) {
        return (_price * _coll) / DECIMAL_PRECISION;
    }

    function _getCollChange(
        uint256 _collReceived,
        uint256 _requestedCollWithdrawal
    ) internal pure returns (uint256 collChange, bool isCollIncrease) {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update vessel's coll and debt based on whether they increase or decrease
    function _updateVesselFromAdjustment(
        address _asset,
        IVesselManager _vesselManager,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal returns (uint256, uint256) {
        uint256 newColl = (_isCollIncrease)
            ? _vesselManager.increaseVesselColl(_asset, _borrower, _collChange)
            : _vesselManager.decreaseVesselColl(_asset, _borrower, _collChange);
        uint256 newDebt = (_isDebtIncrease)
            ? _vesselManager.increaseVesselDebt(_asset, _borrower, _debtChange)
            : _vesselManager.decreaseVesselDebt(_asset, _borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensFromAdjustment(
        address _asset,
        IActivePool _activePool,
        IDebtToken _debtToken,
        address _borrower,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtTokenChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    ) internal {
        if (_isDebtIncrease) {
            _withdrawDebtTokens(
                _asset,
                _activePool,
                _debtToken,
                _borrower,
                _debtTokenChange,
                _netDebtChange
            );
        } else {
            _repayDebtTokens(
                _asset,
                _activePool,
                _debtToken,
                _borrower,
                _debtTokenChange
            );
        }
        if (_isCollIncrease) {
            _activePoolAddColl(_asset, _activePool, _collChange);
        } else {
            _activePool.sendAsset(_asset, _borrower, _collChange);
        }
    }

    // Send asset to Active Pool and increase its recorded asset balance
    function _activePoolAddColl(
        address _asset,
        IActivePool _activePool,
        uint256 _amount
    ) internal {
        _activePool.receivedERC20(_asset, _amount);
        IERC20Upgradeable(_asset).safeTransferFrom(
            msg.sender,
            address(_activePool),
            SafetyTransfer.decimalsCorrection(_asset, _amount)
        );
    }

    // Issue the specified amount of debt tokens to _account and increases the total active debt (_netDebtIncrease potentially includes a debtTokenFee)
    function _withdrawDebtTokens(
        address _asset,
        IActivePool _activePool,
        IDebtToken _debtToken,
        address _account,
        uint256 _debtTokenAmount,
        uint256 _netDebtIncrease
    ) internal {
        uint256 newTotalAssetDebt = _activePool.getDebtTokenBalance(_asset) +
            adminContract.defaultPool().getDebtTokenBalance(_asset) +
            _netDebtIncrease;
        require(
            newTotalAssetDebt <= adminContract.getMintCap(_asset),
            "BorrowerOperations: Exceeds mint cap"
        );
        _activePool.increaseDebt(_asset, _netDebtIncrease);
        _debtToken.mint(_asset, _account, _debtTokenAmount);
    }

    // Burn the specified amount of debt tokens from _account and decreases the total active debt
    function _repayDebtTokens(
        address _asset,
        IActivePool _activePool,
        IDebtToken _debtToken,
        address _account,
        uint256 _debtTokenAmount
    ) internal {
        _activePool.decreaseDebt(_asset, _debtTokenAmount);
        _debtToken.burn(_account, _debtTokenAmount);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(
        uint256 _collWithdrawal,
        uint256 _amountSent
    ) internal pure {
        require(
            _collWithdrawal == 0 || _amountSent == 0,
            "BorrowerOperations: Cannot withdraw and add coll"
        );
    }

    function _requireNonZeroAdjustment(
        uint256 _collWithdrawal,
        uint256 _debtTokenChange,
        uint256 _assetSent
    ) internal pure {
        require(
            _collWithdrawal != 0 || _debtTokenChange != 0 || _assetSent != 0,
            "BorrowerOps: There must be either a collateral change or a debt change"
        );
    }

    function _requireVesselIsActive(
        address _asset,
        IVesselManager _vesselManager,
        address _borrower
    ) internal view {
        uint256 status = _vesselManager.getVesselStatus(_asset, _borrower);
        require(status == 1, "BorrowerOps: Vessel does not exist or is closed");
    }

    function _requireVesselIsNotActive(
        address _asset,
        IVesselManager _vesselManager,
        address _borrower
    ) internal view {
        uint256 status = _vesselManager.getVesselStatus(_asset, _borrower);
        require(status != 1, "BorrowerOps: Vessel is active");
    }

    function _requireNonZeroDebtChange(uint256 _debtTokenChange) internal pure {
        require(
            _debtTokenChange > 0,
            "BorrowerOps: Debt increase requires non-zero debtChange"
        );
    }

    function _requireNotInRecoveryMode(
        address _asset,
        uint256 _price
    ) internal view {
        require(
            !_checkRecoveryMode(_asset, _price),
            "BorrowerOps: Operation not permitted during Recovery Mode"
        );
    }

    function _requireNoCollWithdrawal(uint256 _collWithdrawal) internal pure {
        require(
            _collWithdrawal == 0,
            "BorrowerOps: Collateral withdrawal not permitted Recovery Mode"
        );
    }

    function _requireValidAdjustmentInCurrentMode(
        address _asset,
        bool _isRecoveryMode,
        uint256 _collWithdrawal,
        bool _isDebtIncrease,
        LocalVariables_adjustVessel memory _vars
    ) internal view {
        /*
         * In Recovery Mode, only allow:
         *
         * - Pure collateral top-up
         * - Pure debt repayment
         * - Collateral top-up with debt repayment
         * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
         *
         * In Normal Mode, ensure:
         *
         * - The new ICR is above MCR
         * - The adjustment won't pull the TCR below CCR
         */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_asset, _vars.newICR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }
        } else {
            // if Normal Mode
            _requireICRisAboveMCR(_asset, _vars.newICR);
            _vars.newTCR = _getNewTCRFromVesselChange(
                _asset,
                _vars.collChange,
                _vars.isCollIncrease,
                _vars.netDebtChange,
                _isDebtIncrease,
                _vars.price
            );
            _requireNewTCRisAboveCCR(_asset, _vars.newTCR);
        }
    }

    function _requireICRisAboveMCR(
        address _asset,
        uint256 _newICR
    ) internal view {
        require(
            _newICR >= adminContract.getMcr(_asset),
            "BorrowerOps: An operation that would result in ICR < MCR is not permitted"
        );
    }

    function _requireICRisAboveCCR(
        address _asset,
        uint256 _newICR
    ) internal view {
        require(
            _newICR >= adminContract.getCcr(_asset),
            "BorrowerOps: Operation must leave vessel with ICR >= CCR"
        );
    }

    function _requireNewICRisAboveOldICR(
        uint256 _newICR,
        uint256 _oldICR
    ) internal pure {
        require(
            _newICR >= _oldICR,
            "BorrowerOps: Cannot decrease your Vessel's ICR in Recovery Mode"
        );
    }

    function _requireNewTCRisAboveCCR(
        address _asset,
        uint256 _newTCR
    ) internal view {
        require(
            _newTCR >= adminContract.getCcr(_asset),
            "BorrowerOps: An operation that would result in TCR < CCR is not permitted"
        );
    }

    function _requireAtLeastMinNetDebt(
        address _asset,
        uint256 _netDebt
    ) internal view {
        require(
            _netDebt >= adminContract.getMinNetDebt(_asset),
            "BorrowerOps: Vessel's net debt must be greater than minimum"
        );
    }

    function _requireValidDebtTokenRepayment(
        address _asset,
        uint256 _currentDebt,
        uint256 _debtRepayment
    ) internal view {
        require(
            _debtRepayment <=
                _currentDebt -
                    adminContract.getDebtTokenGasCompensation(_asset),
            "BorrowerOps: Amount repaid must not be larger than the Vessel's debt"
        );
    }

    function _requireSufficientDebtTokenBalance(
        IDebtToken _debtToken,
        address _borrower,
        uint256 _debtRepayment
    ) internal view {
        require(
            _debtToken.balanceOf(_borrower) >= _debtRepayment,
            "BorrowerOps: Caller doesnt have enough debt tokens to make repayment"
        );
    }

    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromVesselChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewVesselAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint256 newNICR = PreonMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromVesselChange(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal pure returns (uint256) {
        (uint256 newColl, uint256 newDebt) = _getNewVesselAmounts(
            _coll,
            _debt,
            _collChange,
            _isCollIncrease,
            _debtChange,
            _isDebtIncrease
        );

        uint256 newICR = PreonMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewVesselAmounts(
        uint256 _coll,
        uint256 _debt,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease
    ) internal pure returns (uint256, uint256) {
        uint256 newColl = _coll;
        uint256 newDebt = _debt;

        newColl = _isCollIncrease ? _coll + _collChange : _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }

    function _getNewTCRFromVesselChange(
        address _asset,
        uint256 _collChange,
        bool _isCollIncrease,
        uint256 _debtChange,
        bool _isDebtIncrease,
        uint256 _price
    ) internal view returns (uint256) {
        uint256 totalColl = getEntireSystemColl(_asset);
        uint256 totalDebt = getEntireSystemDebt(_asset);

        totalColl = _isCollIncrease
            ? totalColl + _collChange
            : totalColl - _collChange;
        totalDebt = _isDebtIncrease
            ? totalDebt + _debtChange
            : totalDebt - _debtChange;

        uint256 newTCR = PreonMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }

    function getCompositeDebt(
        address _asset,
        uint256 _debt
    ) external view override returns (uint256) {
        return _getCompositeDebt(_asset, _debt);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract BaseMath {
    uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./BaseMath.sol";
import "./PreonMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPreonBase.sol";
import "../Interfaces/IAdminContract.sol";

/*
 * Base contract for VesselManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
abstract contract PreonBase is IPreonBase, BaseMath, OwnableUpgradeable {
    IAdminContract public adminContract;
    IActivePool public activePool;
    IDefaultPool internal defaultPool;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;

    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vessel, for the purpose of ICR calculation
    function _getCompositeDebt(
        address _asset,
        uint256 _debt
    ) internal view returns (uint256) {
        return _debt + adminContract.getDebtTokenGasCompensation(_asset);
    }

    function _getNetDebt(
        address _asset,
        uint256 _debt
    ) internal view returns (uint256) {
        return _debt - adminContract.getDebtTokenGasCompensation(_asset);
    }

    // Return the amount of ETH to be drawn from a vessel's collateral and sent as gas compensation.
    function _getCollGasCompensation(
        address _asset,
        uint256 _entireColl
    ) internal view returns (uint256) {
        return _entireColl / adminContract.getPercentDivisor(_asset);
    }

    function getEntireSystemColl(
        address _asset
    ) public view returns (uint256 entireSystemColl) {
        uint256 activeColl = adminContract.activePool().getAssetBalance(_asset);
        uint256 liquidatedColl = adminContract.defaultPool().getAssetBalance(
            _asset
        );
        return activeColl + liquidatedColl;
    }

    function getEntireSystemDebt(
        address _asset
    ) public view returns (uint256 entireSystemDebt) {
        uint256 activeDebt = adminContract.activePool().getDebtTokenBalance(
            _asset
        );
        uint256 closedDebt = adminContract.defaultPool().getDebtTokenBalance(
            _asset
        );
        return activeDebt + closedDebt;
    }

    function _getTCR(
        address _asset,
        uint256 _price
    ) internal view returns (uint256 TCR) {
        uint256 entireSystemColl = getEntireSystemColl(_asset);
        uint256 entireSystemDebt = getEntireSystemDebt(_asset);
        TCR = PreonMath._computeCR(entireSystemColl, entireSystemDebt, _price);
    }

    function _checkRecoveryMode(
        address _asset,
        uint256 _price
    ) internal view returns (bool) {
        uint256 TCR = _getTCR(_asset, _price);
        return TCR < adminContract.getCcr(_asset);
    }

    function _requireUserAcceptsFee(
        uint256 _fee,
        uint256 _amount,
        uint256 _maxFeePercentage
    ) internal view {
        uint256 feePercentage = (_fee * adminContract.DECIMAL_PRECISION()) /
            _amount;
        require(
            feePercentage <= _maxFeePercentage,
            "Fee exceeded provided maximum"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library PreonMath {
    uint256 internal constant DECIMAL_PRECISION = 1 ether;

    uint256 internal constant EXPONENT_CAP = 525_600_000;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
     * Multiply two decimal numbers and use normal rounding rules:
     * -round product up if 19'th mantissa digit >= 5
     * -round product down if 19'th mantissa digit < 5
     *
     * Used only inside the exponentiation, _decPow().
     */
    function decMul(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x * y;

        decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
    }

    /*
     * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
     *
     * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
     *
     * Called by two functions that represent time in units of minutes:
     * 1) VesselManager._calcDecayedBaseRate
     * 2) CommunityIssuance._getCumulativeIssuanceFraction
     *
     * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
     * "minutes in 1000 years": 60 * 24 * 365 * 1000
     *
     * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
     * negligibly different from just passing the cap, since:
     *
     * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
     * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
     */
    function _decPow(
        uint256 _base,
        uint256 _minutes
    ) internal pure returns (uint256) {
        if (_minutes > EXPONENT_CAP) {
            _minutes = EXPONENT_CAP;
        } // cap to avoid overflow

        if (_minutes == 0) {
            return DECIMAL_PRECISION;
        }

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else {
                // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
    }

    function _getAbsoluteDifference(
        uint256 _a,
        uint256 _b
    ) internal pure returns (uint256) {
        return (_a >= _b) ? _a - _b : _b - _a;
    }

    function _computeNominalCR(
        uint256 _coll,
        uint256 _debt
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            return (_coll * NICR_PRECISION) / _debt;
        }
        // Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }

    function _computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) internal pure returns (uint256) {
        if (_debt > 0) {
            uint256 newCollRatio = (_coll * _price) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
        else {
            // if (_debt == 0)
            return type(uint256).max;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "../Interfaces/IERC20Decimals.sol";

library SafetyTransfer {
    error EthUnsupportedError();
    error InvalidAmountError();

    //_amount is in ether (1e18) and we want to convert it to the token decimal
    function decimalsCorrection(
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        if (_token == address(0)) {
            revert EthUnsupportedError();
        }
        if (_amount == 0) {
            return 0;
        }
        uint8 decimals = IERC20Decimals(_token).decimals();
        if (decimals < 18) {
            uint256 divisor = 10 ** (18 - decimals);
            if (_amount % divisor != 0) {
                revert InvalidAmountError();
            }
            return _amount / divisor;
        } else if (decimals > 18) {
            uint256 multiplier = 10 ** (decimals - 18);
            return _amount * multiplier;
        }
        return _amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---

    event ActivePoolDebtUpdated(address _asset, uint256 _debtTokenAmount);
    event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

    // --- Functions ---

    function sendAsset(
        address _asset,
        address _account,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";

interface IAdminContract {
    // Structs ----------------------------------------------------------------------------------------------------------

    struct CollateralParams {
        uint256 decimals;
        uint256 index; //Maps to token address in validCollateral[]
        bool active;
        bool isWrapped;
        uint256 mcr;
        uint256 ccr;
        uint256 debtTokenGasCompensation; // Amount of debtToken to be locked in gas pool on opening vessels
        uint256 minNetDebt; // Minimum amount of net debtToken a vessel must have
        uint256 percentDivisor; // dividing by 200 yields 0.5%
        uint256 borrowingFee;
        uint256 redemptionFeeFloor;
        uint256 redemptionBlockTimestamp;
        uint256 mintCap;
    }

    // Custom Errors ----------------------------------------------------------------------------------------------------

    error SafeCheckError(
        string parameter,
        uint256 valueEntered,
        uint256 minValue,
        uint256 maxValue
    );
    error AdminContract__ShortTimelockOnly();
    error AdminContract__LongTimelockOnly();
    error AdminContract__OnlyOwner();
    error AdminContract__CollateralAlreadyInitialized();

    // Events -----------------------------------------------------------------------------------------------------------

    event CollateralAdded(address _collateral);
    event MCRChanged(uint256 oldMCR, uint256 newMCR);
    event CCRChanged(uint256 oldCCR, uint256 newCCR);
    event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
    event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
    event BorrowingFeeChanged(uint256 oldBorrowingFee, uint256 newBorrowingFee);
    event RedemptionFeeFloorChanged(
        uint256 oldRedemptionFeeFloor,
        uint256 newRedemptionFeeFloor
    );
    event MintCapChanged(uint256 oldMintCap, uint256 newMintCap);
    event RedemptionBlockTimestampChanged(
        address _collateral,
        uint256 _blockTimestamp
    );

    // Functions --------------------------------------------------------------------------------------------------------

    function DECIMAL_PRECISION() external view returns (uint256);

    function _100pct() external view returns (uint256);

    function activePool() external view returns (IActivePool);

    function treasury() external view returns (address);

    function defaultPool() external view returns (IDefaultPool);

    function priceFeed() external view returns (IPriceFeed);

    function addNewCollateral(
        address _collateral,
        uint256 _debtTokenGasCompensation,
        uint256 _decimals,
        bool _isWrapped
    ) external;

    function setMCR(address _collateral, uint256 newMCR) external;

    function setCCR(address _collateral, uint256 newCCR) external;

    function setMinNetDebt(address _collateral, uint256 minNetDebt) external;

    function setPercentDivisor(
        address _collateral,
        uint256 precentDivisor
    ) external;

    function setBorrowingFee(
        address _collateral,
        uint256 borrowingFee
    ) external;

    function setRedemptionFeeFloor(
        address _collateral,
        uint256 redemptionFeeFloor
    ) external;

    function setMintCap(address _collateral, uint256 mintCap) external;

    function setRedemptionBlockTimestamp(
        address _collateral,
        uint256 _blockTimestamp
    ) external;

    function getIndex(address _collateral) external view returns (uint256);

    function getIsActive(address _collateral) external view returns (bool);

    function getValidCollateral() external view returns (address[] memory);

    function getMcr(address _collateral) external view returns (uint256);

    function getCcr(address _collateral) external view returns (uint256);

    function getDebtTokenGasCompensation(
        address _collateral
    ) external view returns (uint256);

    function getMinNetDebt(address _collateral) external view returns (uint256);

    function getPercentDivisor(
        address _collateral
    ) external view returns (uint256);

    function getBorrowingFee(
        address _collateral
    ) external view returns (uint256);

    function getRedemptionFeeFloor(
        address _collateral
    ) external view returns (uint256);

    function getRedemptionBlockTimestamp(
        address _collateral
    ) external view returns (uint256);

    function getMintCap(address _collateral) external view returns (uint256);

    function getTotalAssetDebt(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IBorrowerOperations {
    // --- Events ---

    event VesselCreated(
        address indexed _asset,
        address indexed _borrower,
        uint256 arrayIndex
    );
    event VesselUpdated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 stake,
        uint8 operation
    );
    event BorrowingFeePaid(
        address indexed _asset,
        address indexed _borrower,
        uint256 _feeAmount
    );

    // --- Functions ---

    function openVessel(
        address _asset,
        uint256 _assetAmount,
        uint256 _debtTokenAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function addColl(
        address _asset,
        uint256 _assetSent,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawColl(
        address _asset,
        uint256 _assetAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function withdrawDebtTokens(
        address _asset,
        uint256 _debtTokenAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function repayDebtTokens(
        address _asset,
        uint256 _debtTokenAmount,
        address _upperHint,
        address _lowerHint
    ) external;

    function closeVessel(address _asset) external;

    function adjustVessel(
        address _asset,
        uint256 _assetSent,
        uint256 _collWithdrawal,
        uint256 _debtChange,
        bool isDebtIncrease,
        address _upperHint,
        address _lowerHint
    ) external;

    function claimCollateral(address _asset) external;

    function getCompositeDebt(
        address _asset,
        uint256 _debt
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {
    // --- Events ---

    event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
    event AssetSent(address _to, uint256 _amount);

    // --- Functions ---

    function getAssetBalance(address _asset) external view returns (uint256);

    function getCollateral(
        address _asset,
        address _account
    ) external view returns (uint256);

    function accountSurplus(
        address _asset,
        address _account,
        uint256 _amount
    ) external;

    function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStabilityPool.sol";

interface IDebtToken is IERC20 {
    // --- Events ---

    event TokenBalanceUpdated(address _user, uint256 _amount);
    event EmergencyStopMintingCollateral(address _asset, bool state);
    event WhitelistChanged(address _whitelisted, bool whitelisted);

    function emergencyStopMinting(address _asset, bool status) external;

    function mint(address _asset, address _account, uint256 _amount) external;

    function mintFromWhitelistedContract(uint256 _amount) external;

    function burnFromWhitelistedContract(uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(
        address _sender,
        address poolAddress,
        uint256 _amount
    ) external;

    function returnFromPool(
        address poolAddress,
        address user,
        uint256 _amount
    ) external;

    function addWhitelist(address _address) external;

    function removeWhitelist(address _address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolDebtUpdated(address _asset, uint256 _debt);
    event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

    // --- Functions ---
    function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDeposit {
    function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFeeCollector {
    // Events -----------------------------------------------------------------------------------------------------------

    event FeeRecordUpdated(
        address borrower,
        address asset,
        uint256 from,
        uint256 to,
        uint256 amount
    );
    event FeeCollected(
        address borrower,
        address asset,
        address collector,
        uint256 amount
    );
    event FeeRefunded(address borrower, address asset, uint256 amount);
    event FeeDistributorAddressChanged(address newAddress);
    event RedemptionFeeCollected(address asset, uint256 amount);
    event RouteToFeeDistributorChanged(bool routeToPREONStaking);

    // Structs ----------------------------------------------------------------------------------------------------------

    struct FeeRecord {
        uint256 from; // timestamp in seconds
        uint256 to; // timestamp in seconds
        uint256 amount; // refundable fee amount
    }

    // Custom Errors ----------------------------------------------------------------------------------------------------

    error FeeCollector__ArrayMismatch();
    error FeeCollector__BorrowerOperationsOnly(
        address sender,
        address expected
    );
    error FeeCollector__BorrowerOperationsOrVesselManagerOnly(
        address sender,
        address expected1,
        address expected2
    );
    error FeeCollector__InvalidFeeDistributorAddress();
    error FeeCollector__VesselManagerOnly(address sender, address expected);

    // Functions --------------------------------------------------------------------------------------------------------

    function setFeeDistributorAddress(address _feeDistributorAddress) external;

    function setRouteToFeeDistributor(bool _routeToFeeDistributor) external;

    function increaseDebt(
        address _borrower,
        address _asset,
        uint256 _feeAmount
    ) external;

    function decreaseDebt(
        address _borrower,
        address _asset,
        uint256 _paybackFraction
    ) external;

    function closeDebt(address _borrower, address _asset) external;

    function liquidateDebt(address _borrower, address _asset) external;

    function simulateRefund(
        address _borrower,
        address _asset,
        uint256 _paybackFraction
    ) external returns (uint256);

    function collectFees(
        address[] calldata _borrowers,
        address[] calldata _assets
    ) external;

    function handleRedemptionFee(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IDeposit.sol";

interface IPool is IDeposit {
    // --- Events ---

    event AssetSent(address _to, address indexed _asset, uint256 _amount);

    // --- Functions ---

    function getAssetBalance(address _asset) external view returns (uint256);

    function getDebtTokenBalance(
        address _asset
    ) external view returns (uint256);

    function increaseDebt(address _asset, uint256 _amount) external;

    function decreaseDebt(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IAdminContract.sol";

interface IPreonBase {
    struct Colls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    function adminContract() external view returns (IAdminContract);
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.17;

interface IPriceFeed {
    // Structs --------------------------------------------------------------------------------------------------------

    struct OracleRecord {
        AggregatorV3Interface chainLinkOracle;
        // Maximum price deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
        uint256 maxDeviationBetweenRounds;
        bool exists;
        bool isFeedWorking;
        bool isEthIndexed;
    }

    struct PriceRecord {
        uint256 scaledPrice;
        uint256 timestamp;
    }

    struct FeedResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
    }

    // Custom Errors --------------------------------------------------------------------------------------------------

    error PriceFeed__InvalidFeedResponseError(address token);
    error PriceFeed__InvalidPriceDeviationParamError();
    error PriceFeed__FeedFrozenError(address token);
    error PriceFeed__PriceDeviationError(address token);
    error PriceFeed__UnknownFeedError(address token);
    error PriceFeed__TimelockOnly();

    // Events ---------------------------------------------------------------------------------------------------------

    event NewOracleRegistered(
        address token,
        address chainlinkAggregator,
        bool isEthIndexed
    );
    event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
    event PriceRecordUpdated(address indexed token, uint256 _price);

    // Functions ------------------------------------------------------------------------------------------------------

    function setOracle(
        address _token,
        address _chainlinkOracle,
        uint256 _maxPriceDeviationFromPreviousRound,
        bool _isEthIndexed
    ) external;

    function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISortedVessels {
    // --- Events ---

    event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
    event NodeRemoved(address indexed _asset, address _id);

    // --- Functions ---

    function insert(
        address _asset,
        address _id,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external;

    function remove(address _asset, address _id) external;

    function reInsert(
        address _asset,
        address _id,
        uint256 _newICR,
        address _prevId,
        address _nextId
    ) external;

    function contains(address _asset, address _id) external view returns (bool);

    function isEmpty(address _asset) external view returns (bool);

    function getSize(address _asset) external view returns (uint256);

    function getFirst(address _asset) external view returns (address);

    function getLast(address _asset) external view returns (address);

    function getNext(
        address _asset,
        address _id
    ) external view returns (address);

    function getPrev(
        address _asset,
        address _id
    ) external view returns (address);

    function validInsertPosition(
        address _asset,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (bool);

    function findInsertPosition(
        address _asset,
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
    // --- Structs ---

    struct Snapshots {
        mapping(address => uint256) S;
        uint256 P;
        uint256 G;
        uint128 scale;
        uint128 epoch;
    }

    // --- Events ---

    event DepositSnapshotUpdated(
        address indexed _depositor,
        uint256 _P,
        uint256 _G
    );
    event SystemSnapshotUpdated(uint256 _P, uint256 _G);

    event AssetSent(address _asset, address _to, uint256 _amount);
    event GainsWithdrawn(
        address indexed _depositor,
        address[] _collaterals,
        uint256[] _amounts,
        uint256 _debtTokenLoss
    );
    event PREONPaidToDepositor(address indexed _depositor, uint256 _PREON);
    event StabilityPoolAssetBalanceUpdated(address _asset, uint256 _newBalance);
    event StabilityPoolDebtTokenBalanceUpdated(uint256 _newBalance);
    event StakeChanged(uint256 _newSystemStake, address _depositor);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

    event P_Updated(uint256 _P);
    event S_Updated(address _asset, uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    // --- Functions ---

    function addCollateralType(address _collateral) external;

    /*
     * Initial checks:
     * - _amount is not zero
     * ---
     * - Triggers a PREON issuance, based on time passed since the last issuance. The PREON issuance is shared between *all* depositors.
     * - Sends depositor's accumulated gains (PREON, assets) to depositor
     */
    function provideToSP(uint256 _amount) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized vessels left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a PREON issuance, based on time passed since the last issuance. The PREON issuance is shared between *all* depositors.
     * - Sends all depositor's accumulated gains (PREON, assets) to depositor
     * - Decreases deposit's stake, and takes new snapshots.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint256 _amount) external;

    /*
	Initial checks:
	 * - Caller is VesselManager
	 * ---
	 * Cancels out the specified debt against the debt token contained in the Stability Pool (as far as possible)
	 * and transfers the Vessel's collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the VesselManager.
	 */
    function offset(uint256 _debt, address _asset, uint256 _coll) external;

    /*
     * Returns debt tokens held in the pool. Changes when users deposit/withdraw, and when Vessel debt is offset.
     */
    function getTotalDebtTokenDeposits() external view returns (uint256);

    /*
     * Calculates the asset gains earned by the deposit since its last snapshots were taken.
     */
    function getDepositorGains(
        address _depositor
    ) external view returns (address[] memory, uint256[] memory);

    /*
     * Calculate the PREON gain earned by a deposit since its last snapshots were taken.
     */
    function getDepositorPREONGain(
        address _depositor
    ) external view returns (uint256);

    /*
     * Return the user's compounded deposits.
     */
    function getCompoundedDebtTokenDeposits(
        address _depositor
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IActivePool.sol";
import "./ICollSurplusPool.sol";
import "./IDebtToken.sol";
import "./IDefaultPool.sol";
import "./IPreonBase.sol";
import "./ISortedVessels.sol";
import "./IStabilityPool.sol";

interface IVesselManager is IPreonBase {
    // Enums ------------------------------------------------------------------------------------------------------------

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    enum VesselManagerOperation {
        applyPendingRewards,
        liquidateInNormalMode,
        liquidateInRecoveryMode,
        redeemCollateral
    }

    // Events -----------------------------------------------------------------------------------------------------------

    event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
    event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
    event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(
        address indexed _asset,
        uint256 _totalStakesSnapshot,
        uint256 _totalCollateralSnapshot
    );
    event LTermsUpdated(
        address indexed _asset,
        uint256 _L_Coll,
        uint256 _L_Debt
    );
    event VesselSnapshotsUpdated(
        address indexed _asset,
        uint256 _L_Coll,
        uint256 _L_Debt
    );
    event VesselIndexUpdated(
        address indexed _asset,
        address _borrower,
        uint256 _newIndex
    );

    event VesselUpdated(
        address indexed _asset,
        address indexed _borrower,
        uint256 _debt,
        uint256 _coll,
        uint256 _stake,
        VesselManagerOperation _operation
    );

    // Custom Errors ----------------------------------------------------------------------------------------------------

    error VesselManager__FeeBiggerThanAssetDraw();
    error VesselManager__OnlyOneVessel();

    error VesselManager__OnlyVesselManagerOperations();
    error VesselManager__OnlyBorrowerOperations();
    error VesselManager__OnlyVesselManagerOperationsOrBorrowerOperations();

    // Structs ----------------------------------------------------------------------------------------------------------

    struct Vessel {
        uint256 debt;
        uint256 coll;
        uint256 stake;
        Status status;
        uint128 arrayIndex;
    }

    // Functions --------------------------------------------------------------------------------------------------------

    function stabilityPool() external returns (IStabilityPool);

    function debtToken() external returns (IDebtToken);

    function executeFullRedemption(
        address _asset,
        address _borrower,
        uint256 _newColl
    ) external;

    function executePartialRedemption(
        address _asset,
        address _borrower,
        uint256 _newDebt,
        uint256 _newColl,
        uint256 _newNICR,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint
    ) external;

    function getVesselOwnersCount(
        address _asset
    ) external view returns (uint256);

    function getVesselFromVesselOwnersArray(
        address _asset,
        uint256 _index
    ) external view returns (address);

    function getNominalICR(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getCurrentICR(
        address _asset,
        address _borrower,
        uint256 _price
    ) external view returns (uint256);

    function updateStakeAndTotalStakes(
        address _asset,
        address _borrower
    ) external returns (uint256);

    function updateVesselRewardSnapshots(
        address _asset,
        address _borrower
    ) external;

    function addVesselOwnerToArray(
        address _asset,
        address _borrower
    ) external returns (uint256 index);

    function applyPendingRewards(address _asset, address _borrower) external;

    function getPendingAssetReward(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getPendingDebtTokenReward(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function hasPendingRewards(
        address _asset,
        address _borrower
    ) external view returns (bool);

    function getEntireDebtAndColl(
        address _asset,
        address _borrower
    )
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 pendingDebtTokenReward,
            uint256 pendingAssetReward
        );

    function closeVessel(address _asset, address _borrower) external;

    function closeVesselLiquidation(address _asset, address _borrower) external;

    function removeStake(address _asset, address _borrower) external;

    function getRedemptionRate(address _asset) external view returns (uint256);

    function getRedemptionRateWithDecay(
        address _asset
    ) external view returns (uint256);

    function getRedemptionFeeWithDecay(
        address _asset,
        uint256 _assetDraw
    ) external view returns (uint256);

    function getBorrowingRate(address _asset) external view returns (uint256);

    function getBorrowingFee(
        address _asset,
        uint256 _debtTokenAmount
    ) external view returns (uint256);

    function getVesselStatus(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getVesselStake(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getVesselDebt(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function getVesselColl(
        address _asset,
        address _borrower
    ) external view returns (uint256);

    function setVesselStatus(
        address _asset,
        address _borrower,
        uint256 num
    ) external;

    function increaseVesselColl(
        address _asset,
        address _borrower,
        uint256 _collIncrease
    ) external returns (uint256);

    function decreaseVesselColl(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external returns (uint256);

    function increaseVesselDebt(
        address _asset,
        address _borrower,
        uint256 _debtIncrease
    ) external returns (uint256);

    function decreaseVesselDebt(
        address _asset,
        address _borrower,
        uint256 _collDecrease
    ) external returns (uint256);

    function getTCR(
        address _asset,
        uint256 _price
    ) external view returns (uint256);

    function checkRecoveryMode(
        address _asset,
        uint256 _price
    ) external returns (bool);

    function sortedVessels() external returns (ISortedVessels);

    function isValidFirstRedemptionHint(
        address _asset,
        address _firstRedemptionHint,
        uint256 _price
    ) external returns (bool);

    function updateBaseRateFromRedemption(
        address _asset,
        uint256 _assetDrawn,
        uint256 _price,
        uint256 _totalDebtTokenSupply
    ) external returns (uint256);

    function getRedemptionFee(
        address _asset,
        uint256 _assetDraw
    ) external view returns (uint256);

    function finalizeRedemption(
        address _asset,
        address _receiver,
        uint256 _debtToRedeem,
        uint256 _fee,
        uint256 _totalRedemptionRewards
    ) external;

    function redistributeDebtAndColl(
        address _asset,
        uint256 _debt,
        uint256 _coll,
        uint256 _debtToOffset,
        uint256 _collToSendToStabilityPool
    ) external;

    function updateSystemSnapshots_excludeCollRemainder(
        address _asset,
        uint256 _collRemainder
    ) external;

    function movePendingVesselRewardsToActivePool(
        address _asset,
        uint256 _debtTokenAmount,
        uint256 _assetAmount
    ) external;

    function isVesselActive(
        address _asset,
        address _borrower
    ) external view returns (bool);

    function sendGasCompensation(
        address _asset,
        address _liquidator,
        uint256 _debtTokenAmount,
        uint256 _assetAmount
    ) external;
}