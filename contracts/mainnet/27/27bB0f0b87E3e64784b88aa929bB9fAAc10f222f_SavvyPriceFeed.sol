// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
pragma solidity ^0.8.17;

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
pragma solidity ^0.8.17;

import "../interfaces/savvy/ISavvyErrors.sol";
import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

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
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transfer.selector,
                recipient,
                amount
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFETRANSFER);
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
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.approve.selector,
                spender,
                value
            )
        );

        require(success, Errors.ERC20CALLFAILED_SAFEAPPROVE);
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
        (bool success, ) = token.call(
            abi.encodeWithSelector(
                IERC20Minimal.transferFrom.selector,
                owner,
                recipient,
                amount
            )
        );
        uint256 balanceAfter = IERC20Minimal(token).balanceOf(recipient);

        require(success, Errors.ERC20CALLFAILED_SAFETRANSFERFROM);

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
pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./libraries/Checker.sol";
import "./libraries/SafeCast.sol";
import "./libraries/TokenUtils.sol";

import "./interfaces/ISavvyPriceFeed.sol";

/// @title  SavvyPriceFeed
/// @author Savvy DeFi
contract SavvyPriceFeed is Ownable2StepUpgradeable, ISavvyPriceFeed {
    mapping(address => address) private priceFeeds;
    address public svyPriceFeed;
    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @inheritdoc ISavvyPriceFeed
    function setPriceFeed(
        address baseToken,
        address priceFeed
    ) external override onlyOwner {
        Checker.checkArgument(
            baseToken != address(0),
            "zero base token address"
        );
        Checker.checkArgument(
            priceFeed != address(0),
            "zero price feed address"
        );
        priceFeeds[baseToken] = priceFeed;
    }

    /// @inheritdoc ISavvyPriceFeed
    function updateSvyPriceFeed(address newFeed) external override onlyOwner {
        Checker.checkArgument(newFeed != address(0), "zero price feed address");
        svyPriceFeed = newFeed;
    }

    /// @inheritdoc ISavvyPriceFeed
    function getBaseTokenPrice(
        address baseToken,
        uint256 amount
    ) external view override returns (uint256) {
        return _convertToUSD(baseToken, amount);
    }

    /// @inheritdoc ISavvyPriceFeed
    function getSavvyTokenPrice() external view override returns (uint256) {
        if (svyPriceFeed == address(0)) {
            return 0;
        }

        return _getChainlinkTokenPrice(svyPriceFeed);
    }

    /// @notice Get token price according to priceFeed.
    /// @param priceFeed_ The address of priceFeed on chainlink.
    /// @return Return token price calculated by 1e18.
    function _getChainlinkTokenPrice(
        address priceFeed_
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeed_);
        (
            uint80 roundID,
            int price,
            ,
            uint256 timestamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(price > 0, "Chainlink price <= 0");
        require(answeredInRound >= roundID, "Stale price");
        require(timestamp != 0, "Round not complete");

        uint256 tokenPrice = uint256(price);
        uint8 decimals = priceFeed.decimals();
        uint8 additionDecimals = 18 - decimals;
        return tokenPrice * 10 ** additionDecimals;
    }

    /// @notice Convert amount of underlyint token to USD.
    /// @param baseToken_ The address of base token.
    /// @param amount_ The amount of base token.
    /// @return Converted amount of USD divided 10**decimals.
    function _convertToUSD(
        address baseToken_,
        uint256 amount_
    ) internal view returns (uint256) {
        address priceFeedAddr = priceFeeds[baseToken_];
        if (priceFeedAddr == address(0)) {
            return 0;
        }

        uint256 tokenPrice = _getChainlinkTokenPrice(priceFeedAddr);
        uint8 baseTokenDecimals = TokenUtils.expectDecimals(baseToken_);
        return (amount_ * tokenPrice) / 10 ** baseTokenDecimals;
    }

    uint256[100] private __gap;
}