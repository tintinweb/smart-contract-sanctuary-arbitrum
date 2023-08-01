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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
    function getSavvyPositionManagers()
        external
        view
        returns (address[] memory);

    /// @dev The contract to get token price.
    function svyPriceFeed()
        external
        view
        returns (ISavvyPriceFeed svyPriceFeed);

    /// @dev Savvy DeFi's own token.
    function svyToken() external view returns (ISavvyToken svyToken);

    /// @dev SavvyBooster contract handle.
    function svyBooster() external view returns (ISavvyBooster svyBooster);

    /// @dev VeSvy contract handle.
    function veSvy() external view returns (IVeSvy veSvy);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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

/// @title ISavvyAdminInfoAggregator
/// @author Savvy DeFi
///
/// @notice Simplifies the calls required to get protcol and user information.
/// @dev Used by the admin frontend.
interface ISavvyAdminInfoAggregator
{
  struct YieldStrategyMetrics {
    address savvyPositionManager;
    address yieldToken;
    uint256 yieldTokenBalance;
    address baseToken;
    uint256 baseTokenDecimals;
    uint256 expectedValueInBaseToken;
    uint256 maximumExpectedValueInBaseToken;
    bool enabled;
    address adapter;
  }

  /// @notice Set new InfoAggregator contract address.
  /// @dev Only owner can call this function.
  /// @param infoAggregator_ The address of infoAggregator.
  function setInfoAggregator(address infoAggregator_) external;

  /// @notice Get metrics for each yield strategy in Savvy.
  /// @dev iterates over all yield strategies from all the registered SPMs 
  /// in `infoAggregator` and returns metrics for each.
  /// @return metrics List of metrics for each yield strategy in Savvy.
  function getYieldStrategyMetrics() external view returns (YieldStrategyMetrics[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

interface IVeERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IVeERC20.sol";

/**
 * @dev Interface of the VeSvy
 */
interface IVeSvy is IVeERC20 {
    function isUser(address _addr) external view returns (bool);

    function stake(uint256 _amount) external;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
    )
        external
        returns (YieldTokenParams memory yieldTokenParam);

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

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

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import "./interfaces/ISavvyAdminInfoAggregator.sol";
import "./interfaces/IInfoAggregator.sol";
import "./interfaces/ISavvyPositionManager.sol";
import "./interfaces/IYieldStrategyManager.sol";
import "./interfaces/IERC20Metadata.sol";

contract SavvyAdminInfoAggregator is Ownable2StepUpgradeable, ISavvyAdminInfoAggregator
{
    IInfoAggregator public infoAggregator;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IInfoAggregator infoAggregator_
    ) public initializer {
        Checker.checkArgument(
            address(infoAggregator_) != address(0),
            "zero infoAggregator address"
        );
        infoAggregator = infoAggregator_;

        __Ownable2Step_init();
    }

    /// @inheritdoc ISavvyAdminInfoAggregator
    function setInfoAggregator(
        address infoAggregator_
    ) external onlyOwner {
        Checker.checkArgument(
            address(infoAggregator_) != address(0),
            "zero infoAggregator address"
        );
        infoAggregator = IInfoAggregator(infoAggregator_);
    }

    /// @inheritdoc ISavvyAdminInfoAggregator
    function getYieldStrategyMetrics() external view returns (YieldStrategyMetrics[] memory) {
      uint256 yieldTokenLength;
      
      address[] memory savvyPositionManagers = infoAggregator.getSavvyPositionManagers();
      uint256 spmLength = savvyPositionManagers.length;
      for (uint256 i; i < spmLength; ++i) {
        yieldTokenLength += ISavvyPositionManager(savvyPositionManagers[i]).yieldStrategyManager().getSupportedYieldTokens().length;
      }

      YieldStrategyMetrics[] memory metrics = new YieldStrategyMetrics[](yieldTokenLength);

      uint256 metricIdx = 0;
      for (uint256 i; i < spmLength; ++i) {
        address spm = savvyPositionManagers[i];
        IYieldStrategyManager ysm = IYieldStrategyManager(ISavvyPositionManager(spm).yieldStrategyManager());
        address[] memory yieldTokens = ysm.getSupportedYieldTokens();
        yieldTokenLength = yieldTokens.length;
        for (uint256 j; j < yieldTokenLength; ++j) {
          address yieldToken = yieldTokens[j];
          IYieldStrategyManager.YieldTokenParams memory params = ysm.getYieldTokenParams(yieldToken);
          metrics[metricIdx] = YieldStrategyMetrics(
            spm,
            yieldToken,
            params.activeBalance,
            params.baseToken,
            IERC20Metadata(params.baseToken).decimals(),
            params.expectedValue,
            params.maximumExpectedValue,
            params.enabled,
            params.adapter
          );
          ++metricIdx; 
        }
      }

      return metrics;
    }
}