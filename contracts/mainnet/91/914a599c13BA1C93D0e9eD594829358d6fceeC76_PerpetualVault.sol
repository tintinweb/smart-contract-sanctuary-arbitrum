// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

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
    function acceptOwnership() external {
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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
 * ```
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

interface IDataStore {
  function getUint(bytes32 key) external view returns (uint256);
  function getBool(bytes32 key) external view returns (bool);
  function getAddress(bytes32 key) external view returns (address);
  function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./StructData.sol";

interface IExchangeRouter {
  function sendWnt(address receiver, uint256 amount) external payable;
  function sendTokens(address token, address receiver, uint256 amount) external payable;
  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);
  function cancelOrder(bytes32 key) external payable;
  function claimFundingFees(address[] memory markets, address[] memory tokens, address receiver) external returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./IDataStore.sol";
import "./StructData.sol";
import "../../libraries/Position.sol";
import "../../libraries/Order.sol";

interface IReader {
  function getMarket(address dataStore, address key) external view returns (MarketProps memory);
  // function getMarkets(IDataStore dataStore, uint256 start, uint256 end) external view returns (MarketProps[] memory);
  function getPosition(address dataStore, bytes32 key) external view returns (Position.Props memory);
  function getAccountOrders(
    address dataStore,
    address account,
    uint256 start,
    uint256 end
  ) external view returns (Order.Props[] memory);
  function getPositionInfo(
    address dataStore,
    address referralStorage,
    bytes32 positionKey,
    MarketPrices memory prices,
    uint256 sizeDeltaUsd,
    address uiFeeReceiver,
    bool usePositionSizeAsSizeDeltaUsd
  ) external view returns (PositionInfo memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "../../libraries/Position.sol";
import "../../libraries/Order.sol";

struct MarketProps {
  address marketToken;
  address indexToken;
  address longToken;
  address shortToken;
}

struct PriceProps {
  uint256 min;
  uint256 max;
}

struct MarketPrices {
  PriceProps indexTokenPrice;
  PriceProps longTokenPrice;
  PriceProps shortTokenPrice;
}

struct PositionFees {
  PositionReferralFees referral;
  PositionFundingFees funding;
  PositionBorrowingFees borrowing;
  PositionUiFees ui;
  PriceProps collateralTokenPrice;
  uint256 positionFeeFactor;
  uint256 protocolFeeAmount;
  uint256 positionFeeReceiverFactor;
  uint256 feeReceiverAmount;
  uint256 feeAmountForPool;
  uint256 positionFeeAmountForPool;
  uint256 positionFeeAmount;
  uint256 totalCostAmountExcludingFunding;
  uint256 totalCostAmount;
}

// @param affiliate the referral affiliate of the trader
// @param traderDiscountAmount the discount amount for the trader
// @param affiliateRewardAmount the affiliate reward amount
struct PositionReferralFees {
  bytes32 referralCode;
  address affiliate;
  address trader;
  uint256 totalRebateFactor;
  uint256 traderDiscountFactor;
  uint256 totalRebateAmount;
  uint256 traderDiscountAmount;
  uint256 affiliateRewardAmount;
}

struct PositionBorrowingFees {
  uint256 borrowingFeeUsd;
  uint256 borrowingFeeAmount;
  uint256 borrowingFeeReceiverFactor;
  uint256 borrowingFeeAmountForFeeReceiver;
}

// @param fundingFeeAmount the position's funding fee amount
// @param claimableLongTokenAmount the negative funding fee in long token that is claimable
// @param claimableShortTokenAmount the negative funding fee in short token that is claimable
// @param latestLongTokenFundingAmountPerSize the latest long token funding
// amount per size for the market
// @param latestShortTokenFundingAmountPerSize the latest short token funding
// amount per size for the market
struct PositionFundingFees {
  uint256 fundingFeeAmount;
  uint256 claimableLongTokenAmount;
  uint256 claimableShortTokenAmount;
  uint256 latestFundingFeeAmountPerSize;
  uint256 latestLongTokenClaimableFundingAmountPerSize;
  uint256 latestShortTokenClaimableFundingAmountPerSize;
}

struct PositionUiFees {
  address uiFeeReceiver;
  uint256 uiFeeReceiverFactor;
  uint256 uiFeeAmount;
}

struct ExecutionPriceResult {
  int256 priceImpactUsd;
  uint256 priceImpactDiffUsd;
  uint256 executionPrice;
}

struct PositionInfo {
  Position.Props position;
  PositionFees fees;
  ExecutionPriceResult executionPriceResult;
  int256 basePnlUsd;
  int256 uncappedBasePnlUsd;
  int256 pnlAfterPriceImpactUsd;
}

// @param addresses address values
// @param numbers number values
// @param orderType for order.orderType
// @param decreasePositionSwapType for order.decreasePositionSwapType
// @param isLong for order.isLong
// @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
struct CreateOrderParams {
  CreateOrderParamsAddresses addresses;
  CreateOrderParamsNumbers numbers;
  Order.OrderType orderType;
  Order.DecreasePositionSwapType decreasePositionSwapType;
  bool isLong;
  bool shouldUnwrapNativeToken;
  bytes32 referralCode;
}

// @param receiver for order.receiver
// @param callbackContract for order.callbackContract
// @param market for order.market
// @param initialCollateralToken for order.initialCollateralToken
// @param swapPath for order.swapPath
struct CreateOrderParamsAddresses {
  address receiver;
  address callbackContract;
  address uiFeeReceiver;
  address market;
  address initialCollateralToken;
  address[] swapPath;
}

// @param sizeDeltaUsd for order.sizeDeltaUsd
// @param triggerPrice for order.triggerPrice
// @param acceptablePrice for order.acceptablePrice
// @param executionFee for order.executionFee
// @param callbackGasLimit for order.callbackGasLimit
// @param minOutputAmount for order.minOutputAmount
struct CreateOrderParamsNumbers {
  uint256 sizeDeltaUsd;
  uint256 initialCollateralDeltaAmount;
  uint256 triggerPrice;
  uint256 acceptablePrice;
  uint256 executionFee;
  uint256 callbackGasLimit;
  uint256 minOutputAmount;
}

enum PROTOCOL {
  UNISWAP,
  GMX
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "../interfaces/gmx/IReader.sol";

interface IGmxUtils {
  struct PositionData {
    uint256 sizeInUsd;
    uint256 sizeInTokens;
    uint256 collateralAmount;
    uint256 netValue;
    bool isLong;
  }

  struct OrderData {
    address market;
    address indexToken;
    address initialCollateralToken;
    address[] swapPath;
    bool isLong;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 amountIn;
    uint256 callbackGasLimit;
  }

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }
  function getPositionInfo(bytes32 key, MarketPrices memory prices) external view returns (PositionData memory);
  function getPositionSizeInUsd(bytes32 key) external view returns (uint256 sizeInUsd);
  function getExecutionGasLimit(OrderType orderType, uint256 callbackGasLimit) external view returns (uint256 executionGasLimit);
  function setPerpVault(address perpVault) external;
  function createOrder(OrderType orderType, OrderData memory orderData, MarketPrices memory prices) external returns (bytes32);
  function createDecreaseOrder(bytes32 key, address market, bool isLong, uint256 sl, uint256 tp, uint256 callbackGaslimit, MarketPrices memory prices) external;
  function cancelOrder(bytes32[] memory orderKeys) external;
  function withdrawEth() external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

// @title Order
// @dev Struct for orders
library Order {
  using Order for Props;

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  // to help further differentiate orders
  enum SecondaryOrderType {
    None,
    Adl
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the account of the order
  // @param receiver the receiver for any token transfers
  // this field is meant to allow the output of an order to be
  // received by an address that is different from the creator of the
  // order whether this is for swaps or whether the account is the owner
  // of a position
  // for funding fees and claimable collateral, the funds are still
  // credited to the owner of the position indicated by order.account
  // @param callbackContract the contract to call for callbacks
  // @param uiFeeReceiver the ui fee receiver
  // @param market the trading market
  // @param initialCollateralToken for increase orders, initialCollateralToken
  // is the token sent in by the user, the token will be swapped through the
  // specified swapPath, before being deposited into the position as collateral
  // for decrease orders, initialCollateralToken is the collateral token of the position
  // withdrawn collateral from the decrease of the position will be swapped
  // through the specified swapPath
  // for swaps, initialCollateralToken is the initial token sent for the swap
  // @param swapPath an array of market addresses to swap through
  struct Addresses {
    address account;
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialCollateralToken;
    address[] swapPath;
  }

  // @param sizeDeltaUsd the requested change in position size
  // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
  // is the amount of the initialCollateralToken sent in by the user
  // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
  // collateralToken to withdraw
  // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
  // in for the swap
  // @param orderType the order type
  // @param triggerPrice the trigger price for non-market orders
  // @param acceptablePrice the acceptable execution price for increase / decrease orders
  // @param executionFee the execution fee for keepers
  // @param callbackGasLimit the gas limit for the callbackContract
  // @param minOutputAmount the minimum output amount for decrease orders and swaps
  // note that for decrease orders, multiple tokens could be received, for this reason, the
  // minOutputAmount value is treated as a USD value for validation in decrease orders
  // @param updatedAtBlock the block at which the order was last updated
  struct Numbers {
    OrderType orderType;
    DecreasePositionSwapType decreasePositionSwapType;
    uint256 sizeDeltaUsd;
    uint256 initialCollateralDeltaAmount;
    uint256 triggerPrice;
    uint256 acceptablePrice;
    uint256 executionFee;
    uint256 callbackGasLimit;
    uint256 minOutputAmount;
    uint256 updatedAtBlock;
  }

  // @param isLong whether the order is for a long or short
  // @param shouldUnwrapNativeToken whether to unwrap native tokens before
  // transferring to the user
  // @param isFrozen whether the order is frozen
  struct Flags {
    bool isLong;
    bool shouldUnwrapNativeToken;
    bool isFrozen;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

// @title Position
// @dev Stuct for positions
//
// borrowing fees for position require only a borrowingFactor to track
// an example on how this works is if the global cumulativeBorrowingFactor is 10020%
// a position would be opened with borrowingFactor as 10020%
// after some time, if the cumulativeBorrowingFactor is updated to 10025% the position would
// owe 5% of the position size as borrowing fees
// the total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs
// when a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
// collateral and transferred into the LP pool
//
// the same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees
// based on the fiat value of the position sizes
//
// for example, if the price of the longToken is $2000 and a long position owes $200 in funding fees, the opposing short position
// claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would
// only owe 0.05 longToken ($200)
// this would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts
// to be deducted and to be paid out need to be tracked instead
//
// for funding fees, there are four values to consider:
// 1. long positions with market.longToken as collateral
// 2. long positions with market.shortToken as collateral
// 3. short positions with market.longToken as collateral
// 4. short positions with market.shortToken as collateral
library Position {
  // @dev there is a limit on the number of fields a struct can have when being passed
  // or returned as a memory variable which can cause "Stack too deep" errors
  // use sub-structs to avoid this issue
  // @param addresses address values
  // @param numbers number values
  // @param flags boolean values
  struct Props {
    Addresses addresses;
    Numbers numbers;
    Flags flags;
  }

  // @param account the position's account
  // @param market the position's market
  // @param collateralToken the position's collateralToken
  struct Addresses {
    address account;
    address market;
    address collateralToken;
  }

  // @param sizeInUsd the position's size in USD
  // @param sizeInTokens the position's size in tokens
  // @param collateralAmount the amount of collateralToken for collateral
  // @param borrowingFactor the position's borrowing factor
  // @param fundingFeeAmountPerSize the position's funding fee per size
  // @param longTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
  // for the market.longToken
  // @param shortTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
  // for the market.shortToken
  // @param increasedAtBlock the block at which the position was last increased
  // @param decreasedAtBlock the block at which the position was last decreased
  struct Numbers {
    uint256 sizeInUsd;
    uint256 sizeInTokens;
    uint256 collateralAmount;
    uint256 borrowingFactor;
    uint256 fundingFeeAmountPerSize;
    uint256 longTokenClaimableFundingAmountPerSize;
    uint256 shortTokenClaimableFundingAmountPerSize;
    uint256 increasedAtBlock;
    uint256 decreasedAtBlock;
  }

  // @param isLong whether the position is a long or short
  struct Flags {
    bool isLong;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/gmx/IDataStore.sol";
import "./interfaces/gmx/IReader.sol";
import "./interfaces/gmx/IExchangeRouter.sol";
import "./interfaces/IGmxUtils.sol";

/**
 * @notice
 *  contract that manages GMX position
 */
contract PerpetualVault is Initializable, Ownable2StepUpgradeable {
  using SafeERC20 for IERC20;

  struct PositionRequestQueue {
    bytes32 requestKey;                 //  requestKey generated by PositionRouter contract of GMX
    bool isLong;
  }

  enum NextActionSelector {
    NO_ACTION,
    DEPOSIT_ACTION,
    INCREASE_ACTION,
    DECREASE_WITHDRAW_ACTION,
    CREATE_DECREASE_ORDER,
    WITHDRAW_ACTION,
    INCREASE_ACTION_ON_IDLE
  }

  struct Action {
    NextActionSelector selector;
    bytes data;
  }

  struct DepositInfo {
    uint256 amount;
    uint256 shares;
    address owner;
  }

  string public name;
  bytes32 private _referralCode;

  // Vault variables
  uint256 public constant PRECISION = 1e30;
  uint256 public constant BASIS_POINTS_DIVISOR = 10_000;

  uint256 public totalShares;
  uint256 public counter;
  mapping (uint256 => DepositInfo) public depositInfo;
  mapping (address => EnumerableSet.UintSet) userDeposits;

  address public market;
  address public indexToken;
  IERC20 public collateralToken;
  IReader public gReader;
  IGmxUtils public gmxUtils;
  address public gDataStore;
  
  address public keeper;
  address public _strategy;
  address public treasury;
  bytes32 public curPositionKey;      //  current open positionKey
  uint256 public minFund;             // 30 decimals
  uint256 public minCollateralUsd;    // 30 decimals
  uint256 public minEth;
  uint256 public governanceFee;
  uint256 public callbackGasLimit;
  PositionRequestQueue public queue;  // store position request info for confirming in callback function
  
  //  if balance is not enough when withdrawing, `withdraw` function open partial close request.
  //   so withdrawing action can't be done in one transaction. 
  //   register withdraw amount and address to this variable to reference in the callback function
  //   of execute position action called by GMX keeper 
  Action public nextAction;
  bool public beenLong;               // long / short of current open position
  bool public closed;                 // true if there's no open position
  bool _isLock;                       // status value
  bool _entered;                      // status value
  
  uint256 _slippage;
  uint256 _leverage;
  uint256 _gasBufferFactor;
  bytes[] swapData;
  MarketPrices marketPrices;


  event GmxPositionCallbackCalled(
    bytes32 requestKey,
    bool isIncrease
  );

  modifier onlyKeeper() {
    require(msg.sender == keeper, "!keeper");
    _;
  }

  // we will lock the contract from the moment we create position to the moment we get the callback from GMX keeper
  modifier gmxLock() {
    require(_isLock == false, "gmx action lock");
    _;
  }

  // we prevent calling functions while previous action is still being processed.
  modifier nonReentrant() {
    require(_entered == false, "reentrant call");
    _entered = true;
    _;
  }

  /**
   * @notice
   *  `collateralToken` can be ETH, WETH, BTC, LINK, UNI, USDC, USDT, DAI, FRAX.
   *  if we want another token, need to use external DEX to swap.
   * @param _keeper keeper address
   */
  function initialize(
    string memory _name,
    address _market,
    address _collateralToken,
    address _keeper,
    address _treasury,
    address _gmxUtils,
    bytes32 _refCode
  ) external initializer {
    __Ownable2Step_init();
    name = _name;
    require(_market != address(0), "zero address");
    require(_collateralToken != address(0), "zero address");
    require(_gmxUtils != address(0), "zero address");
    market = _market;
    collateralToken = IERC20(_collateralToken);
    gReader = IReader(0xf60becbba223EEA9495Da3f606753867eC10d139);
    gDataStore = address(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
    IGmxUtils(_gmxUtils).setPerpVault(address(this));
    gmxUtils = IGmxUtils(_gmxUtils);
    MarketProps memory marketInfo = gReader.getMarket(gDataStore, market);
    indexToken = marketInfo.indexToken;
    require(_keeper != address(0), "zero address");
    require(_treasury != address(0), "zero address");
    keeper = _keeper;
    treasury = _treasury;
    _referralCode = _refCode;
    governanceFee = 500;  // 5%
    _slippage = 30;   // 0.3%
    _gasBufferFactor = 12_000;
    minCollateralUsd = 10 * PRECISION;
    minEth = 0.002 ether;
    callbackGasLimit = 2_000_000;
    closed = true;
    
    // approve `collateralToken` and `indexToken` on `SwapRouter02` contract of uniswap v3
    address swapRouter02 = address(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    collateralToken.safeApprove(swapRouter02, type(uint256).max);
    IERC20(indexToken).safeApprove(swapRouter02, type(uint256).max);
  }

  //  need payable to receive ETH when opening position
  receive() external payable {}

  /**
   * @notice
   *  deposit collateral token
   * @param amount amount of collateral token
   */
  function deposit(uint256 amount) external nonReentrant {
    require(amount > 0, "zero amount");
    collateralToken.safeTransferFrom(msg.sender, address(this), amount);
    // // // check redeposit with initialDeposit to apply fee
    // // initialDeposit[msg.sender] = amount;
    depositInfo[counter] = DepositInfo(amount, 0, msg.sender);
    EnumerableSet.add(userDeposits[msg.sender], counter);
    // mint share token in the NextAction to involve off-chain price data and improve security
    nextAction.selector = NextActionSelector.DEPOSIT_ACTION;
    nextAction.data = abi.encode(counter);
    counter++;
  }

  /**
   * @notice
   *  withdraw token, 
   *   create a position request to withdraw collateral token from gmx position and real withdraw action is
   *    done by `runNextAction` function in the following block.
   * @param recipient address to receive tokens
   * @param depositId deposit ID of collateral token to withdraw
   */
  function withdraw(address recipient, uint256 depositId) public nonReentrant {
    require(address(gmxUtils).balance > minEth, "low than minium eth balance");
    require(recipient != address(0), "zero address");
    require(EnumerableSet.contains(userDeposits[msg.sender], depositId), "not a valid user");
    nextAction.selector = NextActionSelector.WITHDRAW_ACTION;
    nextAction.data = abi.encode(recipient, depositId, false, 0);
  }

  /**
   * 
   * @param isOpen if true, open a position, if false, close a current position
   * @param isLong if true, open a long position, if false, open a short position
   * @param sl stop loss value. its decimals is 30
   * @param tp take profit value. its decimals is 30
   * @param leverage leverage value in gmx protocol
   * @param prices gmx price data of market tokens that is from gmx api call
   * @param _swapData swap tx data. generated by external script
   */
  function run(bool isOpen, bool isLong, uint256 sl, uint256 tp, uint256 leverage, MarketPrices memory prices, bytes[] memory _swapData) external nonReentrant onlyKeeper {
    require(address(gmxUtils).balance > minEth, "low than minium eth balance");
    marketPrices = prices;
    swapData = _swapData;
    // _leverage = leverage;

    if (isOpen) {
      if (closed == true) {
        require(_isFundIdle(prices) == true, "no enough balance to open position");
        _leverage = leverage;
        _createIncreasePosition(0, 0, isLong, sl, tp);
      } else {
        if (beenLong == isLong) {
          _createDecreaseOrder(sl, tp, false);
        } else {
          nextAction.selector = NextActionSelector.INCREASE_ACTION;
          bytes memory sltp = abi.encode(sl, tp);
          nextAction.data = abi.encode(uint256(0), uint256(0), isLong, sltp, leverage);
          _createDecreasePosition(0, 0, beenLong);
        }
      }
    } else {
      if (closed == false) {
        if (beenLong == false) {
          nextAction.selector = NextActionSelector.CREATE_DECREASE_ORDER;
          nextAction.data = abi.encode(0, 0);
        }
        _createDecreasePosition(0, 0, beenLong);
      } else {
        revert("no action needed");
      }
    }
  }

  function runNextAction(MarketPrices memory prices, bytes[] memory _swapData) external gmxLock onlyKeeper {
    marketPrices = prices;
    swapData = _swapData;
    if (nextAction.selector == NextActionSelector.DEPOSIT_ACTION) {
      (uint256 depositId) = abi.decode(nextAction.data, (uint256));
      _issueShares(depositId, true);
      if (closed == false) {
        (uint256 sl, uint256 tp) = _cancelPendingOrders();
        _createIncreasePosition(0, 0, beenLong, sl, tp);
      } else {
        _entered = false;
        delete nextAction;
      }
    } else if (nextAction.selector == NextActionSelector.INCREASE_ACTION) {
      (
        uint256 amountIn,
        uint256 sizeDelta,
        bool _isLong,
        bytes memory sltp,
        uint256 leverage
      ) = abi.decode(nextAction.data, (uint256, uint256, bool, bytes, uint256));
      delete nextAction;
      (uint256 sl, uint256 tp) = abi.decode(sltp, (uint256, uint256));
      _leverage = leverage;
      _createIncreasePosition(amountIn, sizeDelta, _isLong, sl, tp);
    } else if (nextAction.selector == NextActionSelector.DECREASE_WITHDRAW_ACTION) {
      (
        uint256 collateralDeltaAmount,
        uint256 sizeDeltaInUsd,
        bool _isLong,
        bytes memory withdrawData
      ) = abi.decode(nextAction.data, (uint256, uint256, bool, bytes));
      nextAction.selector = NextActionSelector.WITHDRAW_ACTION;
      nextAction.data = withdrawData;
      _createDecreasePosition(collateralDeltaAmount, sizeDeltaInUsd, _isLong);
    } else if (nextAction.selector == NextActionSelector.CREATE_DECREASE_ORDER) {
      (uint256 sl, uint256 tp) = abi.decode(nextAction.data, (uint256, uint256));
      _createDecreaseOrder(sl, tp, false);
      delete nextAction;
    } else if (nextAction.selector == NextActionSelector.WITHDRAW_ACTION) {
      (
        address recipient,
        uint256 depositId,
        bool forced,
        uint256 amount
      ) = abi.decode(nextAction.data, (address, uint256, bool, uint256));
      _withdraw(recipient, depositId, forced, amount);
      _createDecreaseOrder(0, 0, true);
      delete nextAction;
    } else if (closed == false && _isFundIdle(prices)) {
      _entered = true;
      (uint256 sl, uint256 tp) = _cancelPendingOrders();
      _createIncreasePosition(0, 0, beenLong, sl, tp);
    } else {
      revert("no next action");
    }
  }

  /**
   * callback function that is from order execution of GMX. is called only when order executed successfully
   * @param key requestKey of executed order
   * @param orderType order type of executed order
   * @param isLong long or short of executed order
   * @param positionKey position key
   */
  function afterOrderExecution(bytes32 key, IGmxUtils.OrderType orderType, bool isLong, bytes32 positionKey) external {
    require(msg.sender == address(gmxUtils), "invalid caller");
    
    _isLock = false;
    if (orderType == IGmxUtils.OrderType.MarketIncrease) {
      curPositionKey = positionKey;
      beenLong = isLong;
      closed = false;
    } else if(orderType == IGmxUtils.OrderType.MarketDecrease) {
      uint256 sizeInUsd = gmxUtils.getPositionSizeInUsd(curPositionKey);
      if (sizeInUsd == 0) {
        closed = true;      // need to check if `closed` should be false even though no position.
        curPositionKey = bytes32(0);
      }
    } else if (orderType == IGmxUtils.OrderType.MarketSwap) {
      beenLong = queue.isLong;
      if (beenLong) {
        closed = false;
      } else {
        closed = true;
      }
    } else if (orderType == IGmxUtils.OrderType.LimitDecrease || orderType == IGmxUtils.OrderType.StopLossDecrease) {
      curPositionKey = bytes32(0);
      closed = true;
      nextAction.selector = NextActionSelector.CREATE_DECREASE_ORDER;
      nextAction.data = abi.encode(0, 0);
    }
    delete queue;
    if (nextAction.selector == NextActionSelector.NO_ACTION) {
      _entered = false;
    }
    emit GmxPositionCallbackCalled(key, true);
  }

  function afterOrderCancellation(bytes32 key, IGmxUtils.OrderType, bool, bytes32) external {
    require(msg.sender == address(gmxUtils), "invalid caller");
    _isLock = false;
    delete nextAction;
    emit GmxPositionCallbackCalled(key, false);
  }

  function afterOrderFrozen(bytes32 key, IGmxUtils.OrderType, bool, bytes32) external {}

  //////////////////////////////
  ////    View Functions    ////
  //////////////////////////////

  /**
   * @notice
   *  return the amount of a collateral token
   */
  function totalAmount(MarketPrices memory prices) external view returns (uint256) {
    return _totalAmount(prices);
  }

  function getPositionInfo() external view returns (address, address, uint256, uint256,uint256, uint256, bool) {
    IGmxUtils.PositionData memory positionData = gmxUtils.getPositionInfo(curPositionKey, marketPrices);
    return (
      market,
      address(collateralToken),
      positionData.sizeInUsd,
      positionData.sizeInTokens,
      positionData.collateralAmount,
      positionData.netValue,
      positionData.isLong
    );
  }

  function getUserDeposits(address user) external view returns (uint256[] memory depositIds) {
    for (uint8 i = 0; i < EnumerableSet.length(userDeposits[user]); i++) {
      depositIds[i] = EnumerableSet.at(userDeposits[user], i);
    }
  }

  function isNextAction(MarketPrices memory prices) external view returns (NextActionSelector) {
    if (_isLock == true ) {
      return NextActionSelector.NO_ACTION;
    } else if (nextAction.selector != NextActionSelector.NO_ACTION) {
      return nextAction.selector;
    } else if (closed == false && _isFundIdle(prices)) {
      return NextActionSelector.INCREASE_ACTION_ON_IDLE;
    } else {
      return NextActionSelector.NO_ACTION;
    }
  }

  function isBusy() external view returns (bool) {
    return _entered;
  }

  function curLeverage() external view returns (uint256) {
    return _leverage;
  }

  function referralCode() external view returns (bytes32) {
    return _referralCode;
  }

  function isLock() external view returns (bool) {
    return _isLock;
  }

  function slippage() external view returns (uint256) {
    return _slippage;
  }

  function strategy() external view returns (address) {
    return _strategy;
  }

  function setKeeper(address _keeper) external onlyOwner {
    require(_keeper != address(0), "zero address");
    keeper = _keeper;
  }

  function setTreasury(address _treasury) external onlyOwner {
    require(_treasury != address(0), "zero address");
    treasury = _treasury;
  }

  function setLock(bool locked) external onlyOwner {
    _isLock = locked;
  }

  // this is just for development
  function setEntered() external onlyOwner {
    _entered = false;
  }

  function setSlippage(uint256 val) external onlyOwner {
    _slippage = val;
  }

  function setMinFund(uint256 _minFund) external onlyOwner {
    uint256 min = IDataStore(gDataStore).getUint(keccak256(abi.encode("MIN_COLLATERAL_USD")));
    require(_minFund >= min, "minimum");
    minFund = _minFund;
  }

  function setMinCollateralUsd(uint256 _minCollateralUsd) external onlyOwner {
    uint256 min = IDataStore(gDataStore).getUint(keccak256(abi.encode("MIN_COLLATERAL_USD")));
    require(_minCollateralUsd > min, "minimum");
    minCollateralUsd = _minCollateralUsd;
  }

  function setMinEth(uint256 _minEth) external onlyOwner {
    require(_minEth > 0, "minimum");
    minEth = _minEth;
  }

  function setCallbackGasLimit(uint256 _callbackGasLimit) external onlyOwner {
    require(_callbackGasLimit > 0, "zero value");
    callbackGasLimit = _callbackGasLimit;
  }
  
  //////////////////////////////
  ////  Internal Functions  ////
  //////////////////////////////

  function _issueShares(uint256 depositId, bool isMint) internal {
    if (isMint) {
      uint256 _shares;
      if (totalShares > 0) {
        uint256 _totalAmountBefore = _totalAmount(marketPrices) - depositInfo[depositId].amount;
        _shares = depositInfo[depositId].amount * totalShares / _totalAmountBefore;
      } else {
        _shares = depositInfo[depositId].amount;
      }

      depositInfo[depositId].shares = _shares;
      totalShares = totalShares + _shares;
    } else {
      EnumerableSet.remove(userDeposits[depositInfo[depositId].owner], depositId);
      totalShares = totalShares - depositInfo[depositId].shares;
    }
  }

  function _totalAmount(MarketPrices memory prices) internal view returns (uint256) {
    if (closed == true) {
      return collateralToken.balanceOf(address(this));
    } else if (curPositionKey == bytes32(0)) {
      uint256 amount = IERC20(indexToken).balanceOf(address(this)) * prices.longTokenPrice.min / prices.shortTokenPrice.max
        + collateralToken.balanceOf(address(this));
      return amount;
    } else {
      IGmxUtils.PositionData memory positionData = gmxUtils.getPositionInfo(curPositionKey, prices);
      uint256 amount = positionData.netValue / prices.shortTokenPrice.max + collateralToken.balanceOf(address(this));
      return amount;
    }
  }

  function _isFundIdle(MarketPrices memory prices) internal view returns (bool) {
    uint256 balance = collateralToken.balanceOf(address(this));
    if (prices.shortTokenPrice.min * balance > minFund) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @notice
   *  create increase position
   *  we can't interact directly with GMX vault contract because leverage was disabled by default and 
   *   can be set only by TimeLock(governance) and registered contracts. So we need to use their 
   *   peripheral contracts to do perp.
   *  this function doesn't open position actually, just register position information. Actual position
   *   opening/closing is done by a keeper of GMX vault.
   * @param amountIn: the amount of tokenIn you want to deposit as collateral
   * @param sizeDelta: the USD value of the change in position size. decimals is 30
   * @param _isLong: if long, true or false
   * @param sl: stop-loss value. 30 decimals
   * @param tp: take-profit value. 30 decimals
   */
  function _createIncreasePosition(
    uint256 amountIn,
    uint256 sizeDelta,
    bool _isLong,
    uint256 sl,
    uint256 tp
  ) private gmxLock {
    // check available amounts to open positions
    if (amountIn == 0) {
      amountIn = collateralToken.balanceOf(address(this));
    }
    IGmxUtils.OrderType orderType;
    if (_leverage == BASIS_POINTS_DIVISOR && _isLong) {
      require(swapData.length > 0, "swap data missing");
      for (uint8 i = 0; i < swapData.length; i++) {
        (PROTOCOL _protocol, bytes memory data) = abi.decode(swapData[i], (PROTOCOL, bytes));
        if (_protocol == PROTOCOL.UNISWAP) {
          (address to, bytes memory callData) = abi.decode(
            data,
            (address, bytes)
          );
          (bool success, ) = to.call(callData);
          require(success, "uniswap call reverted");
          beenLong = true;
          closed = false;
          if (nextAction.selector == NextActionSelector.NO_ACTION) {
            _entered = false;
          }
        } else {
          (address[] memory gPath) = abi.decode(data, (address[]));
          orderType = IGmxUtils.OrderType.MarketSwap;
          amountIn = collateralToken.balanceOf(address(this));
          collateralToken.safeTransfer(address(gmxUtils), amountIn);
          IGmxUtils.OrderData memory orderData = IGmxUtils.OrderData({
            market: address(0),
            indexToken: address(0),
            initialCollateralToken: address(collateralToken),
            swapPath: gPath,
            isLong: _isLong,
            sizeDeltaUsd: 0,
            initialCollateralDeltaAmount: 0,
            amountIn: amountIn,
            callbackGasLimit: callbackGasLimit
          });
          _isLock = true;
          queue.requestKey = gmxUtils.createOrder(orderType, orderData, marketPrices);
          queue.isLong = _isLong;
        }
      }
      delete swapData;
    } else {
      nextAction.selector = NextActionSelector.CREATE_DECREASE_ORDER;
      nextAction.data = abi.encode(sl, tp);

      address[] memory swapPath;
      orderType = IGmxUtils.OrderType.MarketIncrease;
      collateralToken.safeTransfer(address(gmxUtils), amountIn);
      if (sizeDelta == 0) {
        sizeDelta = marketPrices.shortTokenPrice.max * amountIn * _leverage / BASIS_POINTS_DIVISOR;
      }
      IGmxUtils.OrderData memory orderData = IGmxUtils.OrderData({
        market: market,
        indexToken: indexToken,
        initialCollateralToken: address(collateralToken),
        swapPath: swapPath,
        isLong: _isLong,
        sizeDeltaUsd: sizeDelta,
        initialCollateralDeltaAmount: 0,
        amountIn: amountIn,
        callbackGasLimit: callbackGasLimit 
      });
      _isLock = true;
      queue.requestKey = gmxUtils.createOrder(orderType, orderData, marketPrices);
    }
  }

  /**
   * @notice
   *  create decrease position
   *  we can't interact directly with GMX vault contract because leverage was disabled by default and 
   *   can be set only by TimeLock(governance) and registered contracts. So we need to use their 
   *   peripheral contracts to do perp.
   *  this function doesn't close position actually, just register position information. Actual position
   *   opening/closing is done by a keeper of GMX vault.
   * @param collateralDeltaAmount: the token amount of collateral to withdraw
   * @param sizeDeltaInUsd: the USD value of the change in position size. decimals is 30
   * @param _isLong: if long, true or false
   */
  function _createDecreasePosition(
    uint256 collateralDeltaAmount,
    uint256 sizeDeltaInUsd,
    bool _isLong
  ) private gmxLock {
    address[] memory swapPath;
    IGmxUtils.OrderType orderType;
    if (_leverage == BASIS_POINTS_DIVISOR && _isLong) {
      require(swapData.length > 0, "swap data missing");
      for (uint8 i = 0; i < swapData.length; i++) {
        (PROTOCOL _protocol, bytes memory data) = abi.decode(swapData[i], (PROTOCOL, bytes));
        if (_protocol == PROTOCOL.UNISWAP) {
          (address to, bytes memory callData) = abi.decode(
            data,
            (address, bytes)
          );
          (bool success, ) = to.call(callData);
          require(success, "uniswap call reverted");
          closed = true;
          if (nextAction.selector == NextActionSelector.NO_ACTION) {
            _entered = false;
          }
        } else {
          (address[] memory gPath, uint256 amountIn) = abi.decode(data, (address[], uint256));
          orderType = IGmxUtils.OrderType.MarketSwap;
          IERC20(indexToken).safeTransfer(address(gmxUtils), amountIn);
          IGmxUtils.OrderData memory orderData = IGmxUtils.OrderData({
            market: address(0),
            indexToken: address(0),
            initialCollateralToken: indexToken,
            swapPath: gPath,
            isLong: _isLong,
            sizeDeltaUsd: 0,
            initialCollateralDeltaAmount: 0,
            amountIn: amountIn,
            callbackGasLimit: callbackGasLimit 
          });
          _isLock = true;
          queue.requestKey = gmxUtils.createOrder(orderType, orderData, marketPrices);
          queue.isLong = _isLong;
        }
      }
      delete swapData;
    } else {
      orderType = IGmxUtils.OrderType.MarketDecrease;
      uint256 sizeInUsd = gmxUtils.getPositionSizeInUsd(curPositionKey);
      if (
        sizeDeltaInUsd == 0 ||
        (sizeInUsd - sizeDeltaInUsd) * BASIS_POINTS_DIVISOR / _leverage < minCollateralUsd
      ) {
        sizeDeltaInUsd = sizeInUsd;
      }
      IGmxUtils.OrderData memory orderData = IGmxUtils.OrderData({
        market: market,
        indexToken: indexToken,
        initialCollateralToken: address(collateralToken),
        swapPath: swapPath,
        isLong: _isLong,
        sizeDeltaUsd: sizeDeltaInUsd,
        initialCollateralDeltaAmount: collateralDeltaAmount,
        amountIn: 0,
        callbackGasLimit: callbackGasLimit
      });
      _isLock = true;
      queue.requestKey = gmxUtils.createOrder(orderType, orderData, marketPrices);
    }
  }

  function _createDecreaseOrder(uint256 sl, uint256 tp, bool useOld) internal {
    (uint256 _sl, uint256 _tp) = _cancelPendingOrders();
    if (useOld) {
      sl = _sl;
      tp = _tp;
    }
    if (curPositionKey != bytes32(0) && sl + tp > 0) {
      gmxUtils.createDecreaseOrder(curPositionKey, market, beenLong, sl, tp, callbackGasLimit, marketPrices);
    }
    _entered = false;
  }

  // cancel all orders when switching positions
  function _cancelPendingOrders() internal returns (uint256 sl, uint256 tp) {
    Order.Props[] memory orders = gReader.getAccountOrders(gDataStore, address(gmxUtils), 0, 10);
    if (orders.length == 0) return (sl, tp);
    for (uint8 i = 0; i < orders.length; ) {
      if (orders[i].numbers.triggerPrice > marketPrices.indexTokenPrice.min) {
        tp = orders[i].numbers.triggerPrice;
      } else {
        sl = orders[i].numbers.triggerPrice;
      }
      unchecked {
        i = i + 1;
      }
    }
    if (!beenLong) {
      uint256 temp = sl;
      sl = tp;
      tp = temp;
    }
    
    bytes32 accountOrderListKey = keccak256(abi.encode(keccak256(abi.encode("ACCOUNT_ORDER_LIST")), address(gmxUtils)));
    bytes32[] memory orderKeys = IDataStore(gDataStore).getBytes32ValuesAt(accountOrderListKey, 0, 10);
    gmxUtils.cancelOrder(orderKeys);
    return (sl, tp);
  }

  function _withdraw(address recipient, uint256 depositId, bool forced, uint256 amount) internal returns (bool) {
    // get amount to withdraw from the estimated total collateralTokenAmount(balance + GMX liquidity)
    if (forced == false) {
      amount = _totalAmount(marketPrices) * depositInfo[depositId].shares / totalShares;
    }
    uint256 balance = collateralToken.balanceOf(address(this));
    if (forced || balance >= amount ) {
      if (amount > depositInfo[depositId].amount) {
        uint256 fee = (amount - depositInfo[depositId].amount) * governanceFee / BASIS_POINTS_DIVISOR;
        collateralToken.safeTransfer(treasury, fee);
        collateralToken.safeTransfer(recipient, amount - fee);
      } else {
        collateralToken.safeTransfer(recipient, amount);
      }
      
      _issueShares(depositId, false);
      return true;
    }

    // if we don't have enough balance, need to withdraw from GMX
    //  when decreasing position, we can't indicate amount of collateral token to withdraw using collateralDelta
    //   because `swapFee` and `closeFee` would be deducted from `amountOut`. it may need to multiply 1.01. should check exact multiplier value via testing
    uint256 want = amount - balance;
    IGmxUtils.PositionData memory positionData = gmxUtils.getPositionInfo(curPositionKey, marketPrices);
    uint256 sizeDeltaInUsd;
    uint256 collateralDeltaAmount;
    if (want * marketPrices.shortTokenPrice.min >= positionData.netValue) {
      sizeDeltaInUsd = positionData.sizeInUsd;
      collateralDeltaAmount = 0;
    } else {
      //  may need to consider fee deduction
      sizeDeltaInUsd = want * marketPrices.shortTokenPrice.min * _leverage / BASIS_POINTS_DIVISOR;
      collateralDeltaAmount = want;
    }

    nextAction.selector = NextActionSelector.DECREASE_WITHDRAW_ACTION;
    bytes memory withdrawActionData = abi.encode(recipient, depositId, true, amount);
    nextAction.data = abi.encode(collateralDeltaAmount, sizeDeltaInUsd, beenLong, withdrawActionData);
    return false;
  }

  /**
   * @notice
   *  check available liquidity before create positions
   */
  // function _checkPool(bool _isLong, address _indexToken, address _tokenIn, uint256 sizeDelta) internal view {}
}