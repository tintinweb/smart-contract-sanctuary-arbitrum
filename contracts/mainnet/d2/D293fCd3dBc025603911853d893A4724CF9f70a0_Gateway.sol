// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
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
import {Initializable} from "../proxy/utils/Initializable.sol";

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
import {Initializable} from "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import {GatewaySettingManager} from './GatewaySettingManager.sol';
import {IGateway, IERC20} from './interfaces/IGateway.sol';
import {SharedStructs} from './libraries/SharedStructs.sol';

/**
 * @title Gateway
 * @notice This contract serves as a gateway for creating orders and managing settlements.
 */
contract Gateway is IGateway, GatewaySettingManager, PausableUpgradeable {
	struct fee {
		uint256 protocolFee;
		uint256 liquidityProviderAmount;
	}

	mapping(bytes32 => Order) private order;
	mapping(address => uint256) private _nonce;
	uint256[50] private __gap;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	/**
	 * @dev Initialize function.
	 */
	function initialize() external initializer {
		MAX_BPS = 100_000;
		__Ownable2Step_init();
		__Pausable_init();
	}

	/**
	 * @dev Modifier that allows only the aggregator to call a function.
	 */
	modifier onlyAggregator() {
		require(msg.sender == _aggregatorAddress, 'OnlyAggregator');
		_;
	}

	/* ##################################################################
                                OWNER FUNCTIONS
    ################################################################## */
	/**
	 * @dev Pause the contract.
	 */
	function pause() external onlyOwner {
		_pause();
	}

	/**
	 * @dev Unpause the contract.
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/* ##################################################################
                                USER CALLS
    ################################################################## */
	/** @dev See {createOrder-IGateway}. */
	function createOrder(
		address _token,
		uint256 _amount,
		bytes32 _institutionCode,
		uint96 _rate,
		address _senderFeeRecipient,
		uint256 _senderFee,
		address _refundAddress,
		string calldata messageHash
	) external whenNotPaused returns (bytes32 orderId) {
		// checks that are required
		_handler(
			_token,
			_amount,
			_refundAddress,
			_senderFeeRecipient,
			_senderFee,
			_institutionCode
		);

		// validate messageHash
		require(bytes(messageHash).length != 0, 'InvalidMessageHash');

		// transfer token from msg.sender to contract
		IERC20(_token).transferFrom(msg.sender, address(this), _amount + _senderFee);

		// increase users nonce to avoid replay attacks
		_nonce[msg.sender]++;

		// generate transaction id for the transaction
		orderId = keccak256(abi.encode(msg.sender, _nonce[msg.sender]));

		// update transaction
		uint256 _protocolFee = (_amount * protocolFeePercent) / MAX_BPS;
		order[orderId] = Order({
			sender: msg.sender,
			token: _token,
			senderFeeRecipient: _senderFeeRecipient,
			senderFee: _senderFee,
			protocolFee: _protocolFee,
			isFulfilled: false,
			isRefunded: false,
			refundAddress: _refundAddress,
			currentBPS: uint64(MAX_BPS),
			amount: _amount - _protocolFee
		});

		// emit order created event
		emit OrderCreated(
			order[orderId].sender,
			_token,
			order[orderId].amount,
			_protocolFee,
			orderId,
			_rate,
			_institutionCode,
			messageHash
		);
	}

	/**
	 * @dev Internal function to handle order creation.
	 * @param _token The address of the token being traded.
	 * @param _amount The amount of tokens being traded.
	 * @param _refundAddress The address to refund the tokens in case of cancellation.
	 * @param _senderFeeRecipient The address of the recipient for the sender fee.
	 * @param _senderFee The amount of the sender fee.
	 * @param _institutionCode The code of the institution associated with the order.
	 */
	function _handler(
		address _token,
		uint256 _amount,
		address _refundAddress,
		address _senderFeeRecipient,
		uint256 _senderFee,
		bytes32 _institutionCode
	) internal view {
		require(_isTokenSupported[_token] == 1, 'TokenNotSupported');
		require(_amount != 0, 'AmountIsZero');
		require(_refundAddress != address(0), 'ThrowZeroAddress');
		require(
			supportedInstitutionsByCode[_institutionCode].name != bytes32(0),
			'InvalidInstitutionCode'
		);

		if (_senderFee != 0) {
			require(_senderFeeRecipient != address(0), 'InvalidSenderFeeRecipient');
		}
	}

	/* ##################################################################
                                AGGREGATOR FUNCTIONS
    ################################################################## */
	/** @dev See {settle-IGateway}. */
	function settle(
		bytes32 _splitOrderId,
		bytes32 _orderId,
		address _liquidityProvider,
		uint64 _settlePercent
	) external onlyAggregator returns (bool) {
		// ensure the transaction has not been fulfilled
		require(!order[_orderId].isFulfilled, 'OrderFulfilled');
		require(!order[_orderId].isRefunded, 'OrderRefunded');

		// load the token into memory
		address token = order[_orderId].token;

		// subtract sum of amount based on the input _settlePercent
		order[_orderId].currentBPS -= _settlePercent;

		if (order[_orderId].currentBPS == 0) {
			// update the transaction to be fulfilled
			order[_orderId].isFulfilled = true;

			if (order[_orderId].senderFee != 0) {
				// transfer sender fee
				IERC20(order[_orderId].token).transfer(
					order[_orderId].senderFeeRecipient,
					order[_orderId].senderFee
				);

				// emit event
				emit SenderFeeTransferred(
					order[_orderId].senderFeeRecipient,
					order[_orderId].senderFee
				);
			}

			if (order[_orderId].protocolFee != 0) {
				// transfer protocol fee
				IERC20(token).transfer(treasuryAddress, order[_orderId].protocolFee);
			}
		}

		// transfer to liquidity provider
		uint256 liquidityProviderAmount = (order[_orderId].amount * _settlePercent) / MAX_BPS;
		order[_orderId].amount -= liquidityProviderAmount;
		IERC20(token).transfer(_liquidityProvider, liquidityProviderAmount);

		// emit settled event
		emit OrderSettled(_splitOrderId, _orderId, _liquidityProvider, _settlePercent);

		return true;
	}

	/** @dev See {refund-IGateway}. */
	function refund(uint256 _fee, bytes32 _orderId) external onlyAggregator returns (bool) {
		// ensure the transaction has not been fulfilled
		require(!order[_orderId].isFulfilled, 'OrderFulfilled');
		require(!order[_orderId].isRefunded, 'OrderRefunded');
		require(order[_orderId].protocolFee >= _fee, 'FeeExceedsProtocolFee');

		// transfer refund fee to the treasury
		IERC20(order[_orderId].token).transfer(treasuryAddress, _fee);

		// reset state values
		order[_orderId].isRefunded = true;
		order[_orderId].currentBPS = 0;

		// deduct fee from order amount
		uint256 refundAmount = order[_orderId].amount + order[_orderId].protocolFee - _fee;

		// transfer refund amount and sender fee to the refund address
		IERC20(order[_orderId].token).transfer(
			order[_orderId].refundAddress,
			refundAmount + order[_orderId].senderFee
		);

		// emit refunded event
		emit OrderRefunded(_fee, _orderId);

		return true;
	}

	/* ##################################################################
                                VIEW CALLS
    ################################################################## */
	/** @dev See {getOrderInfo-IGateway}. */
	function getOrderInfo(bytes32 _orderId) external view returns (Order memory) {
		return order[_orderId];
	}

	/** @dev See {isTokenSupported-IGateway}. */
	function isTokenSupported(address _token) external view returns (bool) {
		if (_isTokenSupported[_token] == 1) return true;
		return false;
	}

	/** @dev See {getSupportedInstitutionByCode-IGateway}. */
	function getSupportedInstitutionByCode(
		bytes32 _code
	) external view returns (SharedStructs.InstitutionByCode memory) {
		return supportedInstitutionsByCode[_code];
	}

	/** @dev See {getSupportedInstitutions-IGateway}. */
	function getSupportedInstitutions(
		bytes32 _currency
	) external view returns (SharedStructs.Institution[] memory) {
		return supportedInstitutions[_currency];
	}

	/** @dev See {getFeeDetails-IGateway}. */
	function getFeeDetails() external view returns (uint64, uint256) {
		return (protocolFeePercent, MAX_BPS);
	}
}

// SPDX-License-Identifier: UNLICENSED

/**
 * @title GatewaySettingManager
 * @dev This contract manages the settings and configurations for the Gateway protocol.
 */
pragma solidity ^0.8.18;

import '@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol';

import {SharedStructs} from './libraries/SharedStructs.sol';

contract GatewaySettingManager is Ownable2StepUpgradeable {
	uint256 internal MAX_BPS;
	uint64 internal protocolFeePercent;
	address internal treasuryAddress;
	address internal _aggregatorAddress;

	// this should decrease if more slots are needed on this contract to avoid collisions with base contract
	uint256[50] private __gap;

	mapping(address => uint256) internal _isTokenSupported;

	mapping(bytes32 => SharedStructs.Institution[]) internal supportedInstitutions;
	mapping(bytes32 => SharedStructs.InstitutionByCode) internal supportedInstitutionsByCode;

	event SettingManagerBool(bytes32 indexed what, address indexed value, uint256 status);
	event SupportedInstitutionsUpdated(
		bytes32 indexed currency,
		SharedStructs.Institution[] institutions
	);
	event ProtocolFeeUpdated(uint64 protocolFee);
	event ProtocolAddressUpdated(bytes32 indexed what, address indexed treasuryAddress);
	event SetFeeRecipient(address indexed treasuryAddress);

	/* ##################################################################
                                OWNER FUNCTIONS
    ################################################################## */

	/**
	 * @dev Sets the boolean value for a specific setting.
	 * @param what The setting to be updated.
	 * @param value The address or value associated with the setting.
	 * @param status The boolean value to be set.
	 * Requirements:
	 * - The value must not be a zero address.
	 */
	function settingManagerBool(bytes32 what, address value, uint256 status) external onlyOwner {
		require(value != address(0), 'Gateway: zero address');
		require(status == 1 || status == 2, 'Gateway: invalid status');
		if (what == 'token') {
			_isTokenSupported[value] = status;
			emit SettingManagerBool(what, value, status);
		}
	}

	/**
	 * @dev Sets the supported institutions for a specific currency.
	 * @param currency The currency for which the institutions are being set.
	 * @param institutions The array of institutions to be set.
	 */
	function setSupportedInstitutions(
		bytes32 currency,
		SharedStructs.Institution[] memory institutions
	) external onlyOwner {
		delete supportedInstitutions[currency];
		for (uint i; i < institutions.length; ) {
			supportedInstitutions[currency].push(institutions[i]);
			supportedInstitutionsByCode[institutions[i].code] = SharedStructs.InstitutionByCode({
				name: institutions[i].name,
				currency: currency
			});
			unchecked {
				++i;
			}
		}
		emit SupportedInstitutionsUpdated(currency, supportedInstitutions[currency]);
	}

	/**
	 * @dev Updates the protocol fee percentage.
	 * @param _protocolFeePercent The new protocol fee percentage to be set.
	 */
	function updateProtocolFee(uint64 _protocolFeePercent) external onlyOwner {
		protocolFeePercent = _protocolFeePercent;
		emit ProtocolFeeUpdated(_protocolFeePercent);
	}

	/**
	 * @dev Updates a protocol address.
	 * @param what The address type to be updated (treasury or aggregator).
	 * @param value The new address to be set.
	 * Requirements:
	 * - The value must not be a zero address.
	 */
	function updateProtocolAddress(bytes32 what, address value) external onlyOwner {
		require(value != address(0), 'Gateway: zero address');
		bool updated;
		if (what == 'treasury') {
			require(treasuryAddress != value, 'Gateway: treasury address already set');
			treasuryAddress = value;
			updated = true;
		} else if (what == 'aggregator') {
			require(_aggregatorAddress != value, 'Gateway: aggregator address already set');
			_aggregatorAddress = value;
			updated = true;
		}
		if (updated) {
			emit ProtocolAddressUpdated(what, value);
		}
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {SharedStructs} from '../libraries/SharedStructs.sol';

/**
 * @title IGateway
 * @notice Interface for the Gateway contract.
 */
interface IGateway {
	/* ##################################################################
                                EVENTS
    ################################################################## */
	/**
	 * @dev Emitted when a deposit is made.
	 * @param sender The address of the sender.
	 * @param token The address of the deposited token.
	 * @param amount The amount of the deposit.
	 * @param orderId The ID of the order.
	 * @param rate The rate at which the deposit is made.
	 * @param institutionCode The code of the institution.
	 * @param messageHash The hash of the message.
	 */
	event OrderCreated(
		address indexed sender,
		address indexed token,
		uint256 indexed amount,
		uint256 protocolFee,
		bytes32 orderId,
		uint256 rate,
		bytes32 institutionCode,
		string messageHash
	);

	/**
	 * @dev Emitted when an aggregator settles a transaction.
	 * @param splitOrderId The ID of the split order.
	 * @param orderId The ID of the order.
	 * @param liquidityProvider The address of the liquidity provider.
	 * @param settlePercent The percentage at which the transaction is settled.
	 */
	event OrderSettled(
		bytes32 splitOrderId,
		bytes32 indexed orderId,
		address indexed liquidityProvider,
		uint96 settlePercent
	);

	/**
	 * @dev Emitted when an aggregator refunds a transaction.
	 * @param fee The fee deducted from the refund amount.
	 * @param orderId The ID of the order.
	 */
	event OrderRefunded(uint256 fee, bytes32 indexed orderId);

	/**
	 * @dev Emitted when the sender's fee is transferred.
	 * @param sender The address of the sender.
	 * @param amount The amount of the fee transferred.
	 */
	event SenderFeeTransferred(address indexed sender, uint256 indexed amount);

	/* ##################################################################
                                STRUCTS
    ################################################################## */
	/**
	 * @dev Struct representing transaction metadata.
	 * @param identifier The identifier of the transaction.
	 * @param institution The institution of the transaction.
	 * @param name The name of the transaction.
	 * @param currency The currency of the transaction.
	 * @param liquidityProviderID The ID of the liquidity provider.
	 */
	struct TransactionMetadata {
		bytes8 identifier;
		bytes8 institution;
		bytes8 name;
		bytes8 currency;
		uint256 liquidityProviderID;
	}

	/**
	 * @dev Struct representing an order.
	 * @param sender The address of the sender.
	 * @param token The address of the token.
	 * @param senderFeeRecipient The address of the sender fee recipient.
	 * @param senderFee The fee to be paid to the sender fee recipient.
	 * @param protocolFee The protocol fee to be paid.
	 * @param isFulfilled Whether the order is fulfilled.
	 * @param isRefunded Whether the order is refunded.
	 * @param refundAddress The address to which the refund is made.
	 * @param currentBPS The current basis points.
	 * @param amount The amount of the order.
	 */
	struct Order {
		address sender;
		address token;
		address senderFeeRecipient;
		uint256 senderFee;
		uint256 protocolFee;
		bool isFulfilled;
		bool isRefunded;
		address refundAddress;
		uint96 currentBPS;
		uint256 amount;
	}

	/* ##################################################################
                                EXTERNAL CALLS
    ################################################################## */
	/**
	 * @notice Locks the sender's amount of token into Gateway.
	 * @dev Requirements:
	 * - `msg.sender` must approve Gateway contract on `_token` of at least `amount` before function call.
	 * - `_token` must be an acceptable token. See {isTokenSupported}.
	 * - `amount` must be greater than minimum.
	 * - `_refundAddress` refund address must not be zero address.
	 * @param _token The address of the token.
	 * @param _amount The amount in the decimal of `_token` to be locked.
	 * @param _institutionCode The institution code of the sender.
	 * @param _rate The rate at which the sender intends to sell `_amount` of `_token`.
	 * @param _senderFeeRecipient The address that will receive `_senderFee` in `_token`.
	 * @param _senderFee The amount in the decimal of `_token` that will be paid to `_senderFeeRecipient`.
	 * @param _refundAddress The address that will receive `_amount` in `_token` when there is a need to refund.
	 * @param messageHash The hash of the message.
	 * @return _orderId The ID of the order.
	 */
	function createOrder(
		address _token,
		uint256 _amount,
		bytes32 _institutionCode,
		uint96 _rate,
		address _senderFeeRecipient,
		uint256 _senderFee,
		address _refundAddress,
		string calldata messageHash
	) external returns (bytes32 _orderId);

	/**
	 * @notice Settles a transaction and distributes rewards accordingly.
	 * @param _splitOrderId The ID of the split order.
	 * @param _orderId The ID of the transaction.
	 * @param _liquidityProvider The address of the liquidity provider.
	 * @param _settlePercent The rate at which the transaction is settled.
	 * @return bool the settlement is successful.
	 */
	function settle(
		bytes32 _splitOrderId,
		bytes32 _orderId,
		address _liquidityProvider,
		uint64 _settlePercent
	) external returns (bool);

	/**
	 * @notice Refunds to the specified refundable address.
	 * @dev Requirements:
	 * - Only aggregators can call this function.
	 * @param _fee The amount to be deducted from the amount to be refunded.
	 * @param _orderId The ID of the transaction.
	 * @return bool the refund is successful.
	 */
	function refund(uint256 _fee, bytes32 _orderId) external returns (bool);

	/**
	 * @notice Checks if a token is supported by Gateway.
	 * @param _token The address of the token to check.
	 * @return bool the token is supported.
	 */
	function isTokenSupported(address _token) external view returns (bool);

	/**
	 * @notice Gets the details of an order.
	 * @param _orderId The ID of the order.
	 * @return Order The order details.
	 */
	function getOrderInfo(bytes32 _orderId) external view returns (Order memory);

	/**
	 * @notice Gets the fee details of Gateway.
	 * @return protocolReward The protocol reward amount.
	 * @return max_bps The maximum basis points.
	 */
	function getFeeDetails() external view returns (uint64 protocolReward, uint256 max_bps);

	/**
	 * @notice Gets the details of a supported institution by code.
	 * @param _code The institution code.
	 * @return InstitutionByCode The institution details.
	 */
	function getSupportedInstitutionByCode(
		bytes32 _code
	) external view returns (SharedStructs.InstitutionByCode memory);

	/**
	 * @notice Gets the details of supported institutions by currency.
	 * @param _currency The currency code.
	 * @return Institutions An array of institutions.
	 */
	function getSupportedInstitutions(
		bytes32 _currency
	) external view returns (SharedStructs.Institution[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library SharedStructs {
    /**
     * @dev Struct representing an institution.
     * @param code The code of the institution.
     * @param name The name of the institution.
     */
    struct Institution {
        bytes32 code;
        bytes32 name;
    }

    /**
     * @dev Struct representing an institution by code.
     * @param name The name of the institution.
     * @param currency The currency of the institution.
     */
    struct InstitutionByCode {
        bytes32 name;
        bytes32 currency;
    }
}