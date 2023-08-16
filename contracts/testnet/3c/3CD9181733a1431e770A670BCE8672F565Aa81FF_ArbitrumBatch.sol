// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library AddressAliasHelper {
    uint160 internal constant OFFSET = uint160(0x1111000000000000000000000000000000001111);

    /// @notice Utility function that converts the address in the L1 that submitted a tx to
    /// the inbox to the msg.sender viewed in the L2
    /// @param l1Address the address in the L1 that triggered the tx to L2
    /// @return l2Address L2 address as viewed in msg.sender
    function applyL1ToL2Alias(address l1Address) internal pure returns (address l2Address) {
        unchecked {
            l2Address = address(uint160(l1Address) + OFFSET);
        }
    }

    /// @notice Utility function that converts the msg.sender viewed in the L2 to the
    /// address in the L1 that submitted a tx to the inbox
    /// @param l2Address L2 address as viewed in msg.sender
    /// @return l1Address the address in the L1 that triggered the tx to L2
    function undoL1ToL2Alias(address l2Address) internal pure returns (address l1Address) {
        unchecked {
            l1Address = address(uint160(l2Address) - OFFSET);
        }
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../Error.sol";

contract WhiteListUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private whiteListed;

    event WhiteListAdded(address indexed account);
    event WhiteListRemoved(address indexed account);

    modifier onlyWhiteListed() {
        if (!whiteListed[msg.sender]) revert NotInWhiteList();
        _;
    }

    function __baseInitialize() internal onlyInitializing {
        __Ownable_init();
        whiteListed[msg.sender] = true;
    }

    function addWhiteList(address account) external onlyOwner {
        if (account == address(0)) revert InvalidAddress();
        whiteListed[account] = true;
        emit WhiteListAdded(account);
    }

    function removeWhiteList(address account) external onlyOwner {
        whiteListed[account] = false;
        emit WhiteListRemoved(account);
    }

    function verifyAccount(address account) external view returns (bool) {
        return whiteListed[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library DataTypes {
    enum BatchStatus {
        Pending,
        OnGoing,
        CrossChainHandling,
        Claimable
    }

    enum BatchHandleResult {
        NotHandle,
        Success,
        InvestFailed,
        WithdrawFailed
    }

    struct ArbitrumData {
        uint256 maxSubmissionCost;
        uint256 maxGas;
        uint256 maxGasPrice;
    }

    struct InvestBatchParams {
        uint256 investCoinAmount;
        uint256 totalMinShareAmount;
        uint256 returnShareAmount;
        uint256 failedBackCoinAmount;
    }

    struct WithdrawBatchParams {
        uint256 withdrawShareAmount;
        uint256 totalMinCoinAmount;
        uint256 withdrawCoinAmount;
        uint256 returnCoinAmount;
    }

    struct BatchInfo {
        uint256 startTime;
        uint256 statusUpdateTime;
        BatchStatus status;
        BatchHandleResult handleResult;
    }

    struct UserBasicInfo {
        uint256 shareBalance; // the gvt share balance of user
        uint256 claimableCoinAmount; // the claimable usdc coin amount of user
    }

    struct InvestParams {
        uint256 batchId;
        uint256 investAmount;
        uint256 minShareAmount;
    }

    struct WithdrawParams {
        uint256 batchId;
        uint256 withdrawShareAmount;
        uint256 minCoinAmount;
    }

    struct HelperParams {
        uint256 batchId;
        uint256 withdrawAmount;
        uint256 investAmount;
        uint256 totalMinShareAmount;
        uint256 totalMinCoinAmount;
    }

    struct HelperBatchCheckParams {
        bool investMinShareCheck;
        uint256 investAmount;
        bool withdrawMinCoinCheck;
        uint256 withdrawAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error InvalidAddress();
error InvalidParam();
error InvalidAction();
error InvalidCaller();
error InvalidFromSource();
error InvalidFromChain();
error InsufficientBalance();
error CallerNotExecutor();
error BatchNotReady();
error BatchStatusError();
error MinShareError();
error MinCoinError();
error MinCheckError();
error NotInWhiteList();
error AlreadyHasCrossChainBatch();
error NotExist();
error SendETHFailed();
error UnsupportedToken();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBridgeMessage {
    function bridgeMessage(
        uint256 batchId,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBridgeToken {
    function bridgeToken(address token, address receiver) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IGCrossChainHelper {
    function handleDirectWithdraw(bytes calldata data) external;

    function updateBatchHandleMessage(bytes32 tx, bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IReceiver {
    function transfer(uint256 amount) external;

    function balanceOf() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@arbitrum/nitro-contracts/src/libraries/AddressAliasHelper.sol";
import "../Error.sol";
import "./BatchBase.sol";

contract ArbitrumBatch is BatchBase {
    function initialize(
        address token_,
        address gvtPriceOracle_
    ) public initializer {
        BatchBase.__baseInitialize(token_, gvtPriceOracle_);
    }

    function checkL1SenderSource() internal view override {
        if (msg.sender != AddressAliasHelper.applyL1ToL2Alias(l1Source))
            revert InvalidCaller();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../access/WhiteListUpgradeable.sol";
import "../interfaces/IBridgeToken.sol";
import "../interfaces/IBridgeMessage.sol";
import "../interfaces/IGCrossChainHelper.sol";
import "../interfaces/IReceiver.sol";
import "../DataTypes.sol";
import "../Error.sol";
import "./GVTPriceOracle.sol";

abstract contract BatchBase is WhiteListUpgradeable {
    uint256[] public batchIds;
    mapping(uint256 => DataTypes.BatchInfo) public batchInfos;
    mapping(uint256 => DataTypes.InvestBatchParams) public batchInvestInfos;
    mapping(uint256 => DataTypes.WithdrawBatchParams) public batchWithdrawInfos;

    IERC20 public token;
    GVTPriceOracle public gvtPriceOracle;
    uint256 public gvtTotalSupply;
    uint256 public maxCoinAmount;
    uint256 public slippage; // for token balance check
    address public gCrossChainHelper;
    address public coinReceiver;
    address public tokenBridgeHelper;
    address public messageBridgeHelper;
    address public clientHelper;
    address public l1Source;

    event UpdateGVTPriceOracle(address newPriceOracle);
    event UpdateMaxCoinAmount(uint256 newAmount);
    event UpdateSlippage(uint256 newSlippage);
    event UpdateGCrossChainHelper(address newHelper);
    event UpdateTokenBridgeHelper(address newBridgeHelper);
    event UpdateMessageBridgeHelper(address newBridgeHelper);
    event UpdateClientHelper(address newClientHelper);
    event UpdateCoinReceiver(address newCoinReceiver);
    event UpdateL1Source(address newL1Source);
    event WithdrawCoinBack(uint256 indexed batchId, uint256 amount);
    event InvestCoinBack(uint256 indexed batchId, uint256 amount);
    event CreateNewBatch(
        uint256 indexed batchId,
        uint256 startTime,
        DataTypes.BatchStatus status
    );
    event UpdateBatchStatus(
        uint256 indexed batchId,
        DataTypes.BatchStatus status
    );
    event CrossBatchInfo(
        uint256 indexed batchId,
        uint256 investAmount,
        uint256 withdrawAmount,
        uint256 minShareAmount,
        uint256 minCoinAmount
    );
    event BatchDataBack(
        uint256 indexed batchId,
        bytes32 revertedTxHash,
        uint256 investShareAmount,
        uint256 withdrawCoinAmount,
        uint256 returnBackCoinAmount,
        DataTypes.BatchHandleResult handleResult
    );
    event UpdateBatchToClaimable(
        uint256 indexed batchId,
        DataTypes.BatchHandleResult handleResult
    );

    function checkL1SenderSource() internal virtual;

    modifier onlyClientHelper() {
        if (msg.sender != clientHelper) revert InvalidCaller();
        _;
    }

    function __baseInitialize(
        address token_,
        address gvtPriceOracle_
    ) internal onlyInitializing {
        WhiteListUpgradeable.__baseInitialize();
        token = IERC20(token_);
        gvtPriceOracle = GVTPriceOracle(gvtPriceOracle_);
        maxCoinAmount = 50000 * 10 ** 6; // 50000
        slippage = 100; // 1%
    }

    function updateGVTPriceOracle(address newPriceOracle) external onlyOwner {
        if (newPriceOracle == address(0)) revert InvalidAddress();
        gvtPriceOracle = GVTPriceOracle(newPriceOracle);
        emit UpdateGVTPriceOracle(newPriceOracle);
    }

    function updateMaxCoinAmount(uint256 newMaxCoinAmount) external onlyOwner {
        if (newMaxCoinAmount == 0) revert InvalidParam();
        maxCoinAmount = newMaxCoinAmount;
        emit UpdateMaxCoinAmount(maxCoinAmount);
    }

    function updateGCrossChainHelper(address newHelper) external onlyOwner {
        if (newHelper == address(0)) revert InvalidAddress();
        gCrossChainHelper = newHelper;
        emit UpdateGCrossChainHelper(newHelper);
    }

    function updateTokenBridgeHelper(address helper) external onlyOwner {
        if (helper == address(0)) revert InvalidAddress();
        tokenBridgeHelper = helper;
        emit UpdateTokenBridgeHelper(helper);
    }

    function updateMessageBridgeHelper(address helper) external onlyOwner {
        if (helper == address(0)) revert InvalidAddress();
        messageBridgeHelper = helper;
        emit UpdateMessageBridgeHelper(helper);
    }

    function updateCoinReceiver(address receiver) external onlyOwner {
        if (receiver == address(0)) revert InvalidAddress();
        coinReceiver = receiver;
        emit UpdateCoinReceiver(receiver);
    }

    function updateClientHelper(address helper) external onlyOwner {
        if (helper == address(0)) revert InvalidAddress();
        clientHelper = helper;
        token.approve(clientHelper, type(uint256).max);
        emit UpdateClientHelper(helper);
    }

    function updateL1Source(address newSource) external onlyOwner {
        if (newSource == address(0)) revert InvalidAddress();
        l1Source = newSource;
        emit UpdateL1Source(newSource);
    }

    function updateSlippage(uint256 newSlippage) external onlyOwner {
        if (newSlippage > 10000) revert InvalidParam();
        slippage = newSlippage;
        emit UpdateSlippage(newSlippage);
    }

    function createNewBatch() external onlyWhiteListed {
        DataTypes.BatchStatus lastStatus = batchInfos[batchIds.length].status;
        if (lastStatus == DataTypes.BatchStatus.OnGoing)
            revert BatchStatusError();
        uint256 newBatchId = batchIds.length + 1;
        batchIds.push(newBatchId);

        DataTypes.BatchInfo memory newBatchInfo = DataTypes.BatchInfo({
            startTime: block.timestamp,
            statusUpdateTime: block.timestamp,
            status: DataTypes.BatchStatus.OnGoing,
            handleResult: DataTypes.BatchHandleResult.NotHandle
        });
        batchInfos[newBatchId] = newBatchInfo;

        // init batch invest
        batchInvestInfos[newBatchId] = DataTypes.InvestBatchParams({
            investCoinAmount: 0,
            totalMinShareAmount: 0,
            returnShareAmount: 0,
            failedBackCoinAmount: 0
        });

        // init batch withdraw
        batchWithdrawInfos[newBatchId] = DataTypes.WithdrawBatchParams({
            withdrawShareAmount: 0,
            totalMinCoinAmount: 0,
            withdrawCoinAmount: 0,
            returnCoinAmount: 0
        });

        emit CreateNewBatch(
            newBatchId,
            newBatchInfo.startTime,
            newBatchInfo.status
        );
    }

    function updateBatchInvestAmount(
        uint256 batchId,
        bool isAdd,
        uint256 amount,
        uint256 minShareAmount
    ) external onlyClientHelper {
        if (isAdd) {
            batchInvestInfos[batchId].investCoinAmount += amount;
            batchInvestInfos[batchId].totalMinShareAmount += minShareAmount;
        } else {
            batchInvestInfos[batchId].investCoinAmount -= amount;
            batchInvestInfos[batchId].totalMinShareAmount -= minShareAmount;
        }
    }

    function updateBatchWithdrawAmount(
        uint256 batchId,
        bool isAdd,
        uint256 share,
        uint256 minCoinAmount
    ) external onlyClientHelper {
        if (isAdd) {
            batchWithdrawInfos[batchId].withdrawShareAmount += share;
            batchWithdrawInfos[batchId].totalMinCoinAmount += minCoinAmount;
        } else {
            batchWithdrawInfos[batchId].withdrawShareAmount -= share;
            batchWithdrawInfos[batchId].totalMinCoinAmount -= minCoinAmount;
        }
    }

    function updateGVTTotalSupply(
        bool isAdd,
        uint256 withdrawShare
    ) external onlyClientHelper {
        if (isAdd) {
            gvtTotalSupply += withdrawShare;
        } else {
            gvtTotalSupply -= withdrawShare;
        }
    }

    function bridgeTokenAndMessage() external payable onlyWhiteListed {
        uint256 batchId = batchIds.length;
        DataTypes.InvestBatchParams memory batchInvestInfo = batchInvestInfos[
            batchId
        ];
        DataTypes.WithdrawBatchParams
            memory batchWithdrawInfo = batchWithdrawInfos[batchId];

        if (
            batchInvestInfo.investCoinAmount == 0 &&
            batchWithdrawInfo.withdrawShareAmount == 0
        ) {
            // nobody invest and withdraw
            batchInfos[batchId].status = DataTypes.BatchStatus.Claimable;
            batchInfos[batchId].statusUpdateTime = block.timestamp;
            emit CrossBatchInfo(batchId, 0, 0, 0, 0);
            emit UpdateBatchStatus(batchId, DataTypes.BatchStatus.Claimable);
            return;
        }

        if (batchInvestInfo.investCoinAmount != 0) {
            token.transfer(tokenBridgeHelper, batchInvestInfo.investCoinAmount);
            IBridgeToken(tokenBridgeHelper).bridgeToken(
                address(token),
                gCrossChainHelper
            );
        }

        bytes memory data = abi.encodeWithSelector(
            IGCrossChainHelper.updateBatchHandleMessage.selector,
            batchId,
            batchInvestInfo.investCoinAmount,
            batchWithdrawInfo.withdrawShareAmount,
            batchInvestInfo.totalMinShareAmount,
            batchWithdrawInfo.totalMinCoinAmount
        );
        IBridgeMessage(messageBridgeHelper).bridgeMessage{value: msg.value}(
            batchId,
            data
        );

        batchInfos[batchId].status = DataTypes.BatchStatus.CrossChainHandling;
        batchInfos[batchId].statusUpdateTime = block.timestamp;

        gvtTotalSupply -= batchWithdrawInfo.withdrawShareAmount;

        emit UpdateBatchStatus(
            batchId,
            DataTypes.BatchStatus.CrossChainHandling
        );
        emit CrossBatchInfo(
            batchId,
            batchInvestInfo.investCoinAmount,
            batchWithdrawInfo.withdrawShareAmount,
            batchInvestInfo.totalMinShareAmount,
            batchWithdrawInfo.totalMinCoinAmount
        );
    }

    function setBatchToClaimable() external onlyWhiteListed {
        uint256 batchId = getCrossChainBatchId();
        if (batchId == 0) revert BatchStatusError();

        DataTypes.WithdrawBatchParams
            memory batchWithdrawInfo = batchWithdrawInfos[batchId];
        DataTypes.InvestBatchParams memory batchInvestInfo = batchInvestInfos[
            batchId
        ];
        DataTypes.BatchHandleResult handleResult = batchInfos[batchId]
            .handleResult;

        IReceiver receiver = IReceiver(coinReceiver);
        uint256 balance = receiver.balanceOf();
        if (
            handleResult == DataTypes.BatchHandleResult.Success &&
            batchWithdrawInfo.withdrawShareAmount > 0
        ) {
            if (balance == 0) revert InsufficientBalance();
            if (balance > batchWithdrawInfo.withdrawCoinAmount) {
                batchWithdrawInfos[batchId].returnCoinAmount = batchWithdrawInfo
                    .withdrawCoinAmount;
            } else {
                batchWithdrawInfos[batchId].returnCoinAmount = balance;
            }

            receiver.transfer(batchWithdrawInfos[batchId].returnCoinAmount);
            emit WithdrawCoinBack(
                batchId,
                batchWithdrawInfos[batchId].returnCoinAmount
            );
        } else if (
            handleResult != DataTypes.BatchHandleResult.Success &&
            batchInvestInfo.investCoinAmount > 0
        ) {
            if (balance == 0) revert InsufficientBalance();

            if (balance < batchInvestInfo.failedBackCoinAmount) {
                batchInvestInfos[batchId].failedBackCoinAmount = balance;
            }

            receiver.transfer(batchInvestInfos[batchId].failedBackCoinAmount);
            emit InvestCoinBack(
                batchId,
                batchInvestInfos[batchId].failedBackCoinAmount
            );
        }

        batchInfos[batchId].status = DataTypes.BatchStatus.Claimable;
        batchInfos[batchId].statusUpdateTime = block.timestamp;
        emit UpdateBatchStatus(batchId, DataTypes.BatchStatus.Claimable);
        emit UpdateBatchToClaimable(batchId, handleResult);
    }

    function writeBridgeMessageBack(
        bytes32 revertedTx,
        bytes calldata data
    ) external {
        if (revertedTx == bytes32(0)) {
            checkL1SenderSource();
        } else {
            if (!this.verifyAccount(msg.sender)) revert NotInWhiteList();
        }
        (
            uint256 batchId,
            uint256 investAmount,
            uint256 returnShares,
            uint256 withdrawCoins,
            DataTypes.BatchHandleResult handleResult
        ) = abi.decode(
                data,
                (
                    uint256,
                    uint256,
                    uint256,
                    uint256,
                    DataTypes.BatchHandleResult
                )
            );
        if (
            !checkBatchStatus(batchId, DataTypes.BatchStatus.CrossChainHandling)
        ) revert BatchStatusError();
        batchInfos[batchId].handleResult = handleResult;
        if (handleResult == DataTypes.BatchHandleResult.Success) {
            batchInvestInfos[batchId].returnShareAmount = returnShares;
            batchWithdrawInfos[batchId].withdrawCoinAmount = withdrawCoins;
            gvtTotalSupply += returnShares;
        } else if (batchInvestInfos[batchId].investCoinAmount > 0) {
            batchInvestInfos[batchId].failedBackCoinAmount = investAmount;
        } else if (batchWithdrawInfos[batchId].withdrawShareAmount > 0) {
            gvtTotalSupply += batchWithdrawInfos[batchId].withdrawShareAmount;
        }

        emit BatchDataBack(
            batchId,
            revertedTx,
            returnShares,
            withdrawCoins,
            batchInvestInfos[batchId].failedBackCoinAmount,
            handleResult
        );
    }

    function canCreateNewBatch() external view returns (bool) {
        uint256 batchLength = batchIds.length;
        if (batchLength == 0) return true;
        DataTypes.BatchInfo memory lastBatchInfo = batchInfos[batchLength];
        if (lastBatchInfo.status != DataTypes.BatchStatus.OnGoing) return true;
        return false;
    }

    function canStartBridgeToken() external view returns (bool) {
        uint256 batchId = batchIds.length;
        if (!checkBatchStatus(batchId, DataTypes.BatchStatus.OnGoing))
            return false;
        if (!checkPreviousBatchStatus(batchId, DataTypes.BatchStatus.Claimable))
            return false;
        uint256 investTotal = batchInvestInfos[batchId].investCoinAmount;
        uint256 withdrawEstimateAmount = getWithdrawEstimateCoinAmount(batchId);
        if ((investTotal + withdrawEstimateAmount) >= maxCoinAmount)
            return true;
        return false;
    }

    function canSetBatchToClaimable() external view returns (bool) {
        uint256 batchId = getCrossChainBatchId();
        if (batchId == 0) return false;

        DataTypes.BatchHandleResult handleResult = batchInfos[batchId]
            .handleResult;
        if (handleResult == DataTypes.BatchHandleResult.NotHandle) return false;

        DataTypes.InvestBatchParams memory investInfo = batchInvestInfos[
            batchId
        ];

        DataTypes.WithdrawBatchParams memory withdrawInfo = batchWithdrawInfos[
            batchId
        ];

        uint256 expectedBalance = 0;
        if (handleResult == DataTypes.BatchHandleResult.Success) {
            expectedBalance = withdrawInfo.withdrawCoinAmount;
        } else {
            expectedBalance = investInfo.failedBackCoinAmount;
        }

        uint256 balance = IReceiver(coinReceiver).balanceOf();

        if (expectedBalance > 0 && slippage > 0) {
            uint256 finalExpectBalance = (expectedBalance *
                (10000 - slippage)) / 10000;
            if (balance < finalExpectBalance) return false;
        } else if (expectedBalance != 0 && balance == 0) return false;
        return true;
    }

    function getMaxShare(
        uint256 depositAmount
    ) external view returns (uint256) {
        return gvtPriceOracle.deposit(depositAmount);
    }

    function getMaxCoin(uint256 shareAmount) external view returns (uint256) {
        return gvtPriceOracle.withdraw(shareAmount);
    }

    function getLastBatchId() public view returns (uint256) {
        return batchIds.length;
    }

    function getLastBatchInfo()
        public
        view
        returns (DataTypes.BatchInfo memory batchInfo)
    {
        uint256 batchId = batchIds.length;
        if (batchId == 0) return batchInfo;
        batchInfo = batchInfos[batchId];
    }

    function getBatchStatus(
        uint256 batchId
    ) public view returns (DataTypes.BatchStatus) {
        return batchInfos[batchId].status;
    }

    function checkBatchStatus(
        uint256 batchId,
        DataTypes.BatchStatus status
    ) public view returns (bool) {
        if (batchId == 0) return false;
        DataTypes.BatchInfo memory batchInfo = batchInfos[batchId];
        if (batchInfo.status == status) return true;
        return false;
    }

    function getWithdrawEstimateCoinAmount(
        uint256 batchId
    ) private view returns (uint256) {
        uint256 withdrawShareAmount = batchWithdrawInfos[batchId]
            .withdrawShareAmount;
        if (withdrawShareAmount == 0) return 0;

        return
            (withdrawShareAmount * gvtPriceOracle.gvtPricePerShare()) /
            10 ** 30;
    }

    function getCrossChainBatchId() private view returns (uint256 batchId) {
        batchId = batchIds.length;
        if (batchId == 0) return batchId;
        if (
            batchInfos[batchId].status ==
            DataTypes.BatchStatus.CrossChainHandling
        ) return batchId;
        if (batchId < 2) return 0;
        if (
            batchInfos[batchId - 1].status ==
            DataTypes.BatchStatus.CrossChainHandling
        ) return batchId - 1;
        return 0;
    }

    function checkPreviousBatchStatus(
        uint256 batchId,
        DataTypes.BatchStatus status
    ) private view returns (bool) {
        if (batchId < 2) return true;
        DataTypes.BatchInfo memory lastBatchInfo = batchInfos[batchId - 1];
        if (lastBatchInfo.status == status) return true;
        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Error.sol";

contract GVTPriceOracle is Ownable {
    uint256 public gvtPricePerShare = 100 * 10 ** 18;
    address public updater;

    event UpdateGVTPrice(uint256 gvtPricePerShare);
    event UpdateUpdater(address updater);

    modifier onlyUpdater() {
        if (msg.sender != updater) revert InvalidCaller();
        _;
    }

    constructor() Ownable() {
        updater = msg.sender;
    }

    function updateUpdater(address updater_) external onlyOwner {
        if (updater_ == address(0)) revert InvalidAddress();
        updater = updater_;
        emit UpdateUpdater(updater);
    }

    function updateGVTPricePerShare(
        uint256 gvtPricePerShare_
    ) external onlyUpdater {
        if (gvtPricePerShare_ == 0) revert InvalidParam();
        gvtPricePerShare = gvtPricePerShare_;
        emit UpdateGVTPrice(gvtPricePerShare);
    }

    function deposit(uint256 amount) external view returns (uint256 maxAmount) {
        maxAmount = ((amount * 10 ** 30) / gvtPricePerShare);
    }

    function withdraw(uint256 share) external view returns (uint256 maxAmount) {
        maxAmount = (share * gvtPricePerShare) / 10 ** 30;
    }
}