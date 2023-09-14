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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.7;

/**
 * @notice An extension of OpenZeppelin's `Ownable.sol` contract that requires
 * an address to be nominated, and then accept that nomination, before
 * ownership is transferred.
 */
interface ISafeOwnable {
  /**
   * @dev Emitted via `transferOwnership()`.
   * @param previousNominee The previous nominee
   * @param newNominee The new nominee
   */
  event NomineeUpdate(
    address indexed previousNominee,
    address indexed newNominee
  );

  /**
   * @notice Nominates an address to be owner of the contract.
   * @dev Only callable by `owner()`.
   * @param nominee The address that will be nominated
   */
  function transferOwnership(address nominee) external;

  /**
   * @notice Renounces ownership of contract and leaves the contract
   * without any owner.
   * @dev Only callable by `owner()`.
   * Sets nominee back to zero address.
   * It will not be possible to call `onlyOwner` functions anymore.
   */
  function renounceOwnership() external;

  /**
   * @notice Accepts ownership nomination.
   * @dev Only callable by the current nominee. Sets nominee back to zero
   * address.
   */
  function acceptOwnership() external;

  /// @return The current nominee
  function getNominee() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.7;

import {ISafeOwnable} from "./interfaces/ISafeOwnable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract SafeOwnableUpgradeable is ISafeOwnable, OwnableUpgradeable {
  address private _nominee;

  modifier onlyNominee() {
    require(_msgSender() == _nominee, "msg.sender != nominee");
    _;
  }

  function transferOwnership(
    address nominee
  ) public virtual override(ISafeOwnable, OwnableUpgradeable) onlyOwner {
    _setNominee(nominee);
  }

  function acceptOwnership() public virtual override onlyNominee {
    _transferOwnership(_nominee);
    _setNominee(address(0));
  }

  function renounceOwnership()
    public
    virtual
    override(ISafeOwnable, OwnableUpgradeable)
    onlyOwner
  {
    super.renounceOwnership();
    _setNominee(address(0));
  }

  function getNominee() public view virtual override returns (address) {
    return _nominee;
  }

  function _setNominee(address nominee) internal virtual {
    emit NomineeUpdate(_nominee, nominee);
    _nominee = nominee;
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILostMyGlasses {
  struct Permit {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Listing {
    address seller;
    uint256 pointsForSale;
    uint256 saleWethPerPoint;
    uint256 collateralWethPerPoint;
    string messageFromSeller;
  }

  error AlreadyRedeemed();
  error CollateralRatioTooLow();
  error InsufficientWethAllowance();
  error InsufficientWethBalance();
  error ListingCancelled();
  error SaleWethValueExceeded();
  error SaleWethValueBelowMin();
  error MaxListingsExceeded();
  error MsgSenderIsNotSeller();
  error WethPerPointAlreadySet();
  error WethPerPointNotSet();

  function createListing(
    uint256 pointsForSale,
    uint256 saleWethPerPoint,
    uint256 collateralWethPerPoint,
    string calldata messageFromSeller,
    string calldata contactUrl,
    string calldata verificationUrl,
    Permit calldata permit
  ) external payable;

  function cancelListing(uint256 id) external;

  function setContactUrl(string calldata url) external;

  function setVerificationUrl(string calldata url) external;

  function addCollateral(
    uint256 id,
    uint256 wethAmount,
    Permit calldata permit
  ) external payable;

  function reclaimCollateral(uint256[] calldata ids) external;

  function buy(
    uint256 id,
    uint256 wethAmount,
    Permit calldata permit
  ) external payable;

  function redeem(uint256 id) external;

  function setMinSaleWethValue(uint256 wethValue) external;

  function setMinCollateralRatio(uint256 ratio) external;

  function setMaxListingsPerSeller(uint256 count) external;

  function setSettlementWethPerPoint(uint256 settlementWethPerPoint) external;

  function getListing(uint256 id) external view returns (Listing memory);

  function isListingCancelled(uint256 id) external view returns (bool);

  function getHighestListingId() external view returns (uint256);

  function getMinSaleWethValue() external view returns (uint256);

  function getCollateralRatio(uint256 id) external view returns (uint256);

  function getMinCollateralRatio() external view returns (uint256);

  function getListingCount(address seller) external view returns (uint256);

  function getContactUrl(address seller) external view returns (string memory);

  function getVerificationUrl(
    address seller
  ) external view returns (string memory);

  function getMaxListingsPerSeller() external view returns (uint256);

  function getWethSpent() external view returns (uint256);

  function getWethSpent(uint256 id) external view returns (uint256);

  function getWethSpent(
    uint256 id,
    address buyer
  ) external view returns (uint256);

  function getWethDebt(uint256 id) external view returns (uint256);

  function getWethRedeemed(uint256 id) external view returns (uint256);

  function getSettlementWethPerPoint() external view returns (uint256);

  function getSettlementWethPerPointSetTime() external view returns (uint256);

  function getSaleWethValue(uint256 id) external view returns (uint256);

  function getCollateralWethValue(uint256 id) external view returns (uint256);

  function getRedeemableWeth(
    uint256 id,
    address buyer
  ) external view returns (uint256);

  function getReclaimableCollateralWethValue(
    uint256 id
  ) external view returns (uint256);

  function getLockedCollateralWethValue(
    uint256 id
  ) external view returns (uint256);

  function getMaxSpendableWeth(uint256 id) external view returns (uint256);

  function getAdditionalBalanceNeeded(
    uint256 id
  ) external view returns (uint256);

  function getAdditionalAllowanceNeeded(
    uint256 id
  ) external view returns (uint256);

  function HUNDRED_PERCENT() external view returns (uint256);

  function WETH() external view returns (IERC20);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.7;

interface IWETH9 {
  function deposit() external payable;

  function withdraw(uint256 _amount) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.7;

import {IERC20, ILostMyGlasses} from "./interfaces/ILostMyGlasses.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {SafeOwnableUpgradeable} from "@prepo-shared-contracts/contracts/SafeOwnableUpgradeable.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract LostMyGlasses is
  ILostMyGlasses,
  ReentrancyGuardUpgradeable,
  SafeOwnableUpgradeable
{
  uint256 private _nextListingId;
  uint256 private _minSaleWethValue;
  uint256 private _minCollateralRatio;
  uint256 private _maxListingsPerSeller;
  uint256 private _globalWethSpent;
  uint256 private _settlementWethPerPointSetTime;
  uint256 private _settlementWethPerPoint;

  mapping(uint256 => Listing) private _idToListing;
  mapping(uint256 => bool) private _idToCancelled;
  mapping(uint256 => uint256) private _idToWethSpent;
  mapping(uint256 => uint256) private _idToWethDebt;
  mapping(uint256 => uint256) private _idToWethRedeemed;
  mapping(uint256 => mapping(address => uint256))
    private _idToAccountToWethSpent;
  mapping(uint256 => mapping(address => bool)) _idToAccountToRedeemed;
  mapping(address => uint256) private _sellerToListingCount;
  mapping(address => string) private _sellerToContactUrl;
  mapping(address => string) private _sellerToVerificationUrl;

  uint256 public constant override HUNDRED_PERCENT = 1_000_000;
  IERC20 public constant override WETH =
    IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

  function initialize() public initializer {
    __ReentrancyGuard_init();
    __Ownable_init();
  }

  function createListing(
    uint256 pointsForSale,
    uint256 saleWethPerPoint,
    uint256 collateralWethPerPoint,
    string calldata messageFromSeller,
    string calldata contactUrl,
    string calldata verificationUrl,
    Permit calldata permit
  ) external payable override nonReentrant {
    if (_settlementWethPerPointSetTime > 0) revert WethPerPointAlreadySet();
    if (bytes(contactUrl).length > 0)
      _sellerToContactUrl[msg.sender] = contactUrl;
    if (bytes(verificationUrl).length > 0)
      _sellerToVerificationUrl[msg.sender] = verificationUrl;
    uint256 saleWethValue = (pointsForSale * saleWethPerPoint) / 1e18;
    if (saleWethValue < _minSaleWethValue) revert SaleWethValueBelowMin();
    if (
      (collateralWethPerPoint * HUNDRED_PERCENT) / saleWethPerPoint <
      _minCollateralRatio
    ) revert CollateralRatioTooLow();
    if (++_sellerToListingCount[msg.sender] > _maxListingsPerSeller)
      revert MaxListingsExceeded();
    _idToListing[_nextListingId++] = Listing(
      msg.sender,
      pointsForSale,
      saleWethPerPoint,
      collateralWethPerPoint,
      messageFromSeller
    );
    uint256 collateralWethValue = (pointsForSale * collateralWethPerPoint) /
      1e18;
    _processWethPermit(msg.sender, address(this), collateralWethValue, permit);
    if (WETH.allowance(msg.sender, address(this)) < collateralWethValue)
      revert InsufficientWethAllowance();
    if (msg.value > 0) {
      IWETH9(address(WETH)).deposit{value: msg.value}();
      WETH.transfer(msg.sender, msg.value);
    }
    if (collateralWethValue > saleWethValue) {
      uint256 collateralNeeded = collateralWethValue - saleWethValue;
      if (WETH.balanceOf(msg.sender) < collateralNeeded)
        revert InsufficientWethBalance();
    }
  }

  function cancelListing(uint256 id) external override nonReentrant {
    if (_settlementWethPerPointSetTime > 0) revert WethPerPointAlreadySet();
    if (msg.sender != _idToListing[id].seller) revert MsgSenderIsNotSeller();
    _idToCancelled[id] = true;
    _sellerToListingCount[msg.sender]--;
  }

  function setContactUrl(string calldata url) external override nonReentrant {
    _sellerToContactUrl[msg.sender] = url;
  }

  function setVerificationUrl(
    string calldata url
  ) external override nonReentrant {
    _sellerToVerificationUrl[msg.sender] = url;
  }

  function addCollateral(
    uint256 id,
    uint256 wethAmount,
    Permit calldata permit
  ) external payable override nonReentrant {
    if (msg.value > 0) IWETH9(address(WETH)).deposit{value: msg.value}();
    if (wethAmount > 0) {
      _processWethPermit(msg.sender, address(this), wethAmount, permit);
      WETH.transferFrom(msg.sender, address(this), wethAmount);
    }
    uint256 totalWethAmount = msg.value + wethAmount;
    _idToListing[id].collateralWethPerPoint =
      ((getLockedCollateralWethValue(id) + totalWethAmount) * 1e18) /
      _idToWethDebt[id];
  }

  function reclaimCollateral(
    uint256[] calldata ids
  ) external override nonReentrant {
    if (_settlementWethPerPointSetTime == 0) revert WethPerPointNotSet();
    for (uint256 i; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 reclaimableWethForListing = getReclaimableCollateralWethValue(
        id
      );
      if (reclaimableWethForListing > 0) {
        _idToListing[id].collateralWethPerPoint = _settlementWethPerPoint;
        WETH.transfer(_idToListing[id].seller, reclaimableWethForListing);
      }
    }
  }

  function buy(
    uint256 id,
    uint256 wethAmount,
    Permit calldata permit
  ) external payable override nonReentrant {
    if (_settlementWethPerPointSetTime > 0) revert WethPerPointAlreadySet();
    if (_idToCancelled[id]) revert ListingCancelled();
    uint256 wethSpent = _idToWethSpent[id];
    uint256 totalWethToSpend = msg.value + wethAmount;
    if (wethSpent + totalWethToSpend > getSaleWethValue(id))
      revert SaleWethValueExceeded();
    if (msg.value > 0) IWETH9(address(WETH)).deposit{value: msg.value}();
    if (wethAmount > 0) {
      _processWethPermit(msg.sender, address(this), wethAmount, permit);
      WETH.transferFrom(msg.sender, address(this), wethAmount);
    }
    _globalWethSpent += totalWethToSpend;
    _idToWethSpent[id] += totalWethToSpend;
    _idToWethDebt[id] += totalWethToSpend;
    _idToAccountToWethSpent[id][msg.sender] += totalWethToSpend;
    Listing memory listing = _idToListing[id];
    WETH.transfer(listing.seller, totalWethToSpend);
    uint256 collateralNeeded = (totalWethToSpend *
      listing.collateralWethPerPoint) / listing.saleWethPerPoint;
    WETH.transferFrom(listing.seller, address(this), collateralNeeded);
  }

  function redeem(uint256 id) external override nonReentrant {
    if (_settlementWethPerPointSetTime == 0) revert WethPerPointNotSet();
    if (_idToAccountToRedeemed[id][msg.sender]) revert AlreadyRedeemed();
    uint256 redeemableWeth = getRedeemableWeth(id, msg.sender);
    _idToAccountToRedeemed[id][msg.sender] = true;
    _idToWethDebt[id] -= _idToAccountToWethSpent[id][msg.sender];
    _idToWethRedeemed[id] += redeemableWeth;
    WETH.transfer(msg.sender, redeemableWeth);
  }

  function setMinSaleWethValue(uint256 wethValue) external override onlyOwner {
    _minSaleWethValue = wethValue;
  }

  function setMinCollateralRatio(uint256 ratio) external override onlyOwner {
    _minCollateralRatio = ratio;
  }

  function setMaxListingsPerSeller(
    uint256 maxListingsPerSeller
  ) external override onlyOwner {
    _maxListingsPerSeller = maxListingsPerSeller;
  }

  function setSettlementWethPerPoint(
    uint256 settlementWethPerPoint
  ) external override onlyOwner {
    if (_settlementWethPerPointSetTime > 0) revert WethPerPointAlreadySet();
    _settlementWethPerPointSetTime = block.timestamp;
    _settlementWethPerPoint = settlementWethPerPoint;
  }

  function getListing(
    uint256 id
  ) external view override returns (Listing memory) {
    return _idToListing[id];
  }

  function isListingCancelled(
    uint256 id
  ) external view override returns (bool) {
    return _idToCancelled[id];
  }

  function getHighestListingId() external view override returns (uint256) {
    return (_nextListingId == 0) ? 0 : _nextListingId - 1;
  }

  function getMinSaleWethValue() external view override returns (uint256) {
    return _minSaleWethValue;
  }

  function getSaleWethValue(
    uint256 id
  ) public view override returns (uint256) {
    Listing memory listing = _idToListing[id];
    return (listing.pointsForSale * listing.saleWethPerPoint) / 1e18;
  }

  function getCollateralWethValue(
    uint256 id
  ) public view override returns (uint256) {
    Listing memory listing = _idToListing[id];
    return (listing.pointsForSale * listing.collateralWethPerPoint) / 1e18;
  }

  function getCollateralRatio(
    uint256 id
  ) external view override returns (uint256) {
    return
      (getCollateralWethValue(id) * HUNDRED_PERCENT) / getSaleWethValue(id);
  }

  function getMinCollateralRatio() external view override returns (uint256) {
    return _minCollateralRatio;
  }

  function getListingCount(
    address seller
  ) external view override returns (uint256) {
    return _sellerToListingCount[seller];
  }

  function getContactUrl(
    address seller
  ) external view override returns (string memory) {
    return _sellerToContactUrl[seller];
  }

  function getVerificationUrl(
    address seller
  ) external view override returns (string memory) {
    return _sellerToVerificationUrl[seller];
  }

  function getMaxListingsPerSeller() external view override returns (uint256) {
    return _maxListingsPerSeller;
  }

  function getWethSpent() external view override returns (uint256) {
    return _globalWethSpent;
  }

  function getWethSpent(uint256 id) external view override returns (uint256) {
    return _idToWethSpent[id];
  }

  function getWethSpent(
    uint256 id,
    address buyer
  ) external view override returns (uint256) {
    return _idToAccountToWethSpent[id][buyer];
  }

  function getWethDebt(uint256 id) external view override returns (uint256) {
    return _idToWethDebt[id];
  }

  function getWethRedeemed(
    uint256 id
  ) external view override returns (uint256) {
    return _idToWethRedeemed[id];
  }

  function getSettlementWethPerPoint()
    external
    view
    override
    returns (uint256)
  {
    if (_settlementWethPerPointSetTime == 0) revert WethPerPointNotSet();
    return _settlementWethPerPoint;
  }

  function getSettlementWethPerPointSetTime()
    public
    view
    override
    returns (uint256)
  {
    return
      (_settlementWethPerPointSetTime == 0)
        ? type(uint256).max
        : _settlementWethPerPointSetTime;
  }

  function getRedeemableWeth(
    uint256 id,
    address buyer
  ) public view override returns (uint256) {
    Listing memory listing = _idToListing[id];
    uint256 wethSpent = _idToAccountToWethSpent[id][buyer];
    uint256 collateralWethValue = (wethSpent *
      listing.collateralWethPerPoint) / listing.saleWethPerPoint;
    uint256 settlementWethValue = (wethSpent * _settlementWethPerPoint) /
      listing.saleWethPerPoint;
    return _min(collateralWethValue, settlementWethValue);
  }

  function getReclaimableCollateralWethValue(
    uint256 id
  ) public view override returns (uint256) {
    Listing memory listing = _idToListing[id];
    uint256 wethDebt = _idToWethDebt[id];
    uint256 settlementWethValue = (wethDebt * _settlementWethPerPoint) /
      listing.saleWethPerPoint;
    uint256 lockedCollateralWethValue = getLockedCollateralWethValue(id);
    return
      (lockedCollateralWethValue > settlementWethValue)
        ? lockedCollateralWethValue - settlementWethValue
        : 0;
  }

  function getLockedCollateralWethValue(
    uint256 id
  ) public view override returns (uint256) {
    Listing memory listing = _idToListing[id];
    return
      (_idToWethDebt[id] * listing.collateralWethPerPoint) /
      listing.saleWethPerPoint;
  }

  function getMaxSpendableWeth(
    uint256 id
  ) external view override returns (uint256) {
    Listing memory listing = _idToListing[id];
    uint256 remainingSaleWethValue = getSaleWethValue(id) - _idToWethSpent[id];
    uint256 remainingCollateralWethValue = getCollateralWethValue(id) -
      getLockedCollateralWethValue(id);
    uint256 balanceNeededForRemainingCollateral = (remainingCollateralWethValue >
        remainingSaleWethValue)
        ? remainingCollateralWethValue - remainingSaleWethValue
        : 0;
    uint256 maxCollateralWethValueFromBalance = _min(
      WETH.balanceOf(msg.sender),
      balanceNeededForRemainingCollateral
    );
    uint256 maxCollateralWethValueFromAllowance = _min(
      WETH.allowance(listing.seller, address(this)),
      remainingCollateralWethValue
    );
    uint256 maxSaleWethValueFromBalance = (maxCollateralWethValueFromBalance *
      listing.saleWethPerPoint) / listing.collateralWethPerPoint;
    uint256 maxSaleWethValueFromAllowance = (maxCollateralWethValueFromAllowance *
        listing.saleWethPerPoint) / listing.collateralWethPerPoint;
    return _min(maxSaleWethValueFromBalance, maxSaleWethValueFromAllowance);
  }

  function getAdditionalBalanceNeeded(
    uint256 id
  ) external view override returns (uint256) {
    uint256 remainingSaleWethValue = getSaleWethValue(id) - _idToWethSpent[id];
    uint256 remainingCollateralWethValue = getCollateralWethValue(id) -
      getLockedCollateralWethValue(id);
    uint256 collateralNeeded = (remainingSaleWethValue >=
      remainingCollateralWethValue)
      ? 0
      : remainingCollateralWethValue - remainingSaleWethValue;
    uint256 sellersBalance = WETH.balanceOf(_idToListing[id].seller);
    return (
      sellersBalance >= collateralNeeded
        ? 0
        : collateralNeeded - sellersBalance
    );
  }

  function getAdditionalAllowanceNeeded(
    uint256 id
  ) external view override returns (uint256) {
    uint256 remainingCollateralWethValue = getCollateralWethValue(id) -
      getLockedCollateralWethValue(id);
    uint256 sellersAllowance = WETH.allowance(
      _idToListing[id].seller,
      address(this)
    );
    return (
      sellersAllowance >= remainingCollateralWethValue
        ? 0
        : remainingCollateralWethValue - sellersAllowance
    );
  }

  function _processWethPermit(
    address owner,
    address spender,
    uint256 amount,
    Permit calldata permit
  ) internal {
    if (WETH.allowance(owner, spender) >= amount) return;
    if (permit.deadline > 0)
      IERC20Permit(address(WETH)).permit(
        owner,
        spender,
        amount,
        permit.deadline,
        permit.v,
        permit.r,
        permit.s
      );
  }

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}