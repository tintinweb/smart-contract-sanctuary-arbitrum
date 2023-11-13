// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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

// SPDX-License-Identifier: MIT

// @dev fixed to specific solidity version for clarity and for more clear
// source code verification purposes.
pragma solidity 0.8.19;

import {ICoreRegistryV1} from "../interfaces/v0.8.x/ICoreRegistryV1.sol";

import {Ownable} from "@openzeppelin-4.7/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin-4.7/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Art Blocks Core Contract Registry, V1.
 * @author Art Blocks Inc.
 * @notice Privileged Roles and Ownership:
 * This contract has a single owner, and is intended to be deployed with a
 * permissioned owner that has elevated privileges on this contract.
 * If in the future multiple deployer addresses are needed to interact with
 * this registry, a new registry version with more complex logic should be
 * implemented and deployed to replace this.
 *
 * This contract builds on the EngineRegistryV0 contract, but encompases more
 * than just Engine contracts. It is updated to be named CoreRegistry, and is
 * V1 because it is the next iteration of the V0 Engine Registry.
 *
 * This contract is intended to be able to act as a registry of all core
 * contracts that are allowed to interact with a specific MinterFilter V2.
 * This includes, but is not limited to:
 * - Flagship contracts
 * - Collaboration contracts
 * - Engine contracts
 * - Engine Flex contracts
 *
 * Note that not all contracts will be registered in this registry, as some
 * contracts may not need to interact with a MinterFilterV2 contract. For
 * example, the original Art Blocks V0 contract does not need to interact with
 * a MinterFilterV2 contract, as it uses a different minting mechanism.
 *
 * A view function is provided to determine if a contract is registered.
 *
 * This contract is designed to be managed by an owner with privileged roles
 * and abilities.
 * ----------------------------------------------------------------------------
 * The following function is restricted to the engine registry owner sending,
 * or the core contract being registered during a transaction originating from
 * the engine registry owner:
 * - registerContract
 * ----------------------------------------------------------------------------
 * The following functions are restricted to the engine registry owner sending:
 * - unregisterContract
 * - registerContracts
 * - unregisterContracts
 * - Ownable: transferOwnership
 * - Ownable: renounceOwnership
 * ----------------------------------------------------------------------------
 * Additional privileged roles may be described on minters, registries, and
 * other contracts that may interact with this contract.
 */
contract CoreRegistryV1 is Ownable, ICoreRegistryV1 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// private enumerable set of registered contracts
    EnumerableSet.AddressSet private _registeredContracts;

    /// private mapping of registered contract addresses to
    EnumerableSet.AddressSet
        private _registeredMinterFilterV2CompatibleContracts;

    constructor() Ownable() {}

    /**
     * @notice Register a contract and emit a `ContractRegistered` event with
     * the provided information. Only callable by the owner or the contract
     * being registered, and only if tx.origin == owner.
     * Reverts if authorization fails, or if the contract is already
     * registered.
     */
    function registerContract(
        address contractAddress,
        bytes32 coreVersion,
        bytes32 coreType
    ) external {
        // CHECKS
        // revert if not called by owner
        Ownable._checkOwner();
        // EFFECTS
        _registerContract({
            contractAddress: contractAddress,
            coreVersion: coreVersion,
            coreType: coreType
        });
    }

    /**
     * @notice Unregister a contract and emit a `ContractUnregistered` event.
     * Only callable by the owner of this registry contract.
     * Reverts if authorization fails, or if the contract is not already
     * registered.
     */
    function unregisterContract(address contractAddress) external {
        // CHECKS
        // revert if not called by owner
        Ownable._checkOwner();
        // EFFECTS
        _unregisterContract(contractAddress);
    }

    /**
     * @notice Register multiple contracts at once.
     * Only callable by the owner.
     * Reverts if any contract is already registered.
     * @dev This should primarily be used for backfilling the registry with
     * existing contracts shortly after deployment.
     * @param contractAddresses Array of contract addresses to register.
     * @param coreVersions Array of core versions for each contract (aligned).
     * @param coreTypes Array of core types for each contract (aligned).
     */
    function registerContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external {
        // CHECKS
        // revert if not called by owner
        Ownable._checkOwner();
        // validate same length arrays
        uint256 numContracts = contractAddresses.length;
        require(
            numContracts == coreVersions.length &&
                numContracts == coreTypes.length,
            "Mismatched array lengths"
        );
        // EFFECTS
        for (uint256 i = 0; i < numContracts; ) {
            _registerContract({
                contractAddress: contractAddresses[i],
                coreVersion: coreVersions[i],
                coreType: coreTypes[i]
            });
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Unregister multiple contracts at once.
     * Only callable by the owner.
     * Reverts if any contract is not already registered.
     * @param contractAddresses Array of contract addresses to unregister.
     */
    function unregisterContracts(
        address[] calldata contractAddresses
    ) external {
        // CHECKS
        // revert if not called by owner
        Ownable._checkOwner();
        // EFFECTS
        uint256 numContracts = contractAddresses.length;
        for (uint256 i = 0; i < numContracts; ) {
            _unregisterContract(contractAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get the number of registered contracts.
     * @return The number of registered contracts.
     */
    function getNumRegisteredContracts() external view returns (uint256) {
        return _registeredContracts.length();
    }

    /**
     * @notice Get the address of a registered contract by index.
     * @param index The index of the contract to get.
     * @return The address of the contract at the given index.
     */
    function getRegisteredContractAt(
        uint256 index
    ) external view returns (address) {
        return _registeredContracts.at(index);
    }

    /**
     * @notice Gets an array of all registered contract addresses.
     * Warning: Unbounded gas limit. This function is gas intensive and should
     * only be used for off-chain analysis. Please use
     * `getNumRegisteredContracts` and `getRegisteredContractAt` for bounded
     * gas usage.
     */
    function getAllRegisteredContracts()
        external
        view
        returns (address[] memory)
    {
        return _registeredContracts.values();
    }

    /**
     * @notice Returns boolean representing if contract is registered on this
     * registry.
     * @param contractAddress The address of the contract to check.
     * @return isRegistered True if the contract is registered.
     */
    function isRegisteredContract(
        address contractAddress
    ) external view returns (bool isRegistered) {
        return _registeredContracts.contains(contractAddress);
    }

    /**
     * @notice Internal function to register a contract.
     * Reverts if the contract is already registered.
     */
    function _registerContract(
        address contractAddress,
        bytes32 coreVersion,
        bytes32 coreType
    ) internal {
        // @dev add returns true only if not already registered
        require(
            _registeredContracts.add(contractAddress),
            "Contract already registered"
        );
        emit ContractRegistered({
            _contractAddress: contractAddress,
            _coreVersion: coreVersion,
            _coreType: coreType
        });
    }

    /**
     * @notice Internal function to unregister a contract.
     * Reverts if the contract is not already registered.
     */
    function _unregisterContract(address contractAddress) internal {
        // @dev remove returns true only if already in set
        require(
            _registeredContracts.remove(contractAddress),
            "Only registered contracts"
        );
        emit ContractUnregistered({_contractAddress: contractAddress});
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

import "./IEngineRegistryV0.sol";

interface ICoreRegistryV1 is IEngineRegistryV0 {
    function registerContracts(
        address[] calldata contractAddresses,
        bytes32[] calldata coreVersions,
        bytes32[] calldata coreTypes
    ) external;

    function unregisterContracts(address[] calldata contractAddresses) external;

    function getNumRegisteredContracts() external view returns (uint256);

    function getRegisteredContractAt(
        uint256 index
    ) external view returns (address);

    function isRegisteredContract(
        address contractAddress
    ) external view returns (bool isRegistered);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.
pragma solidity ^0.8.0;

interface IEngineRegistryV0 {
    /// ADDRESS
    /**
     * @notice contract has been registered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractRegistered(
        address indexed _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    );

    /// ADDRESS
    /**
     * @notice contract has been unregistered as a contract that is powered by the Art Blocks Engine.
     */
    event ContractUnregistered(address indexed _contractAddress);

    /**
     * @notice Emits a `ContractRegistered` event with the provided information.
     * @dev this function should be gated to only deployer addresses.
     */
    function registerContract(
        address _contractAddress,
        bytes32 _coreVersion,
        bytes32 _coreType
    ) external;

    /**
     * @notice Emits a `ContractUnregistered` event with the provided information, validating that the provided
     *         address was indeed previously registered.
     * @dev this function should be gated to only deployer addresses.
     */
    function unregisterContract(address _contractAddress) external;
}