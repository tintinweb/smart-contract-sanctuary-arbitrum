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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Wrapped ETH.
interface IWETH {
    /// @dev Deposit ETH into WETH
    function deposit() external payable;

    /// @dev Transfer WETH to receiver
    /// @param to address of WETH receiver
    /// @param value amount of WETH to transfer
    /// @return get true when succeed, else false
    function transfer(address to, uint256 value) external returns (bool);

    /// @dev Withdraw WETH to ETH
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/// @title Woo private pool for swap.
/// @notice Use this contract to directly interfact with woo's synthetic proactive
///         marketing making pool.
/// @author woo.network
interface IWooPPV2 {
    /* ----- Events ----- */

    event Deposit(address indexed token, address indexed sender, uint256 amount);
    event Withdraw(address indexed token, address indexed receiver, uint256 amount);
    event Migrate(address indexed token, address indexed receiver, uint256 amount);
    event AdminUpdated(address indexed addr, bool flag);
    event FeeAddrUpdated(address indexed newFeeAddr);
    event WooracleUpdated(address indexed newWooracle);
    event WooSwap(
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address from,
        address indexed to,
        address rebateTo,
        uint256 swapVol,
        uint256 swapFee
    );

    /* ----- External Functions ----- */

    /// @notice The quote token address (immutable).
    /// @return address of quote token
    function quoteToken() external view returns (address);

    /// @notice Gets the pool size of the specified token (swap liquidity).
    /// @param token the token address
    /// @return the pool size
    function poolSize(address token) external view returns (uint256);

    /// @notice Query the amount to swap `fromToken` to `toToken`, without checking the pool reserve balance.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @return toAmount the swapped amount of `toToken`
    function tryQuery(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice Query the amount to swap `fromToken` to `toToken`, with checking the pool reserve balance.
    /// @dev tx reverts when 'toToken' balance is insufficient.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @return toAmount the swapped amount of `toToken`
    function query(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be address ZERO)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address to,
        address rebateTo
    ) external returns (uint256 realToAmount);

    /// @notice Deposit the specified token into the liquidity pool of WooPPV2.
    /// @param token the token to deposit
    /// @param amount the deposit amount
    function deposit(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

/*

░██╗░░░░░░░██╗░█████╗░░█████╗░░░░░░░███████╗██╗
░██║░░██╗░░██║██╔══██╗██╔══██╗░░░░░░██╔════╝██║
░╚██╗████╗██╔╝██║░░██║██║░░██║█████╗█████╗░░██║
░░████╔═████║░██║░░██║██║░░██║╚════╝██╔══╝░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝╚█████╔╝░░░░░░██║░░░░░██║
░░░╚═╝░░░╚═╝░░░╚════╝░░╚════╝░░░░░░░╚═╝░░░░░╚═╝

*
* MIT License
* ===========
*
* Copyright (c) 2020 WooTrade
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "../interfaces/IWooPPV2.sol";

/// @title Woo router interface (version 2)
/// @notice functions to interface with WooFi swap
interface IWooRouterV2 {
    /* ----- Type declarations ----- */

    enum SwapType {
        WooSwap,
        DodoSwap
    }

    /* ----- Events ----- */

    event WooRouterSwap(
        SwapType swapType,
        address indexed fromToken,
        address indexed toToken,
        uint256 fromAmount,
        uint256 toAmount,
        address from,
        address indexed to,
        address rebateTo
    );

    event WooPoolChanged(address newPool);

    /* ----- Router properties ----- */

    function WETH() external view returns (address);

    function wooPool() external view returns (IWooPPV2);

    /* ----- Main query & swap APIs ----- */

    /// @notice query the amount to swap fromToken -> toToken
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of fromToken to swap
    /// @return toAmount the predicted amount to receive
    function querySwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice query the amount to swap fromToken -> toToken,
    ///     WITHOUT checking the reserve balance; so it
    ///     always returns the quoted amount (for reference).
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of fromToken to swap
    /// @return toAmount the predicted amount to receive
    function tryQuerySwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    /// @notice Swap `fromToken` to `toToken`.
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of `fromToken` to swap
    /// @param minToAmount the minimum amount of `toToken` to receive
    /// @param to the destination address
    /// @param rebateTo the rebate address (optional, can be 0)
    /// @return realToAmount the amount of toToken to receive
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external payable returns (uint256 realToAmount);

    /* ----- 3rd party DEX swap ----- */

    /// @notice swap fromToken -> toToken via an external 3rd swap
    /// @param approveTarget the contract address for token transfer approval
    /// @param swapTarget the contract address for swap
    /// @param fromToken the from token
    /// @param toToken the to token
    /// @param fromAmount the amount of fromToken to swap
    /// @param minToAmount the min amount of swapped toToken
    /// @param to the destination address
    /// @param data call data for external call
    function externalSwap(
        address approveTarget,
        address swapTarget,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        bytes calldata data
    ) external payable returns (uint256 realToAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStargateEthVault {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface INonceCounter {
    /* ----- Events ----- */

    event CrossChainRouterUpdated(address crossChainRouter, bool flag);

    /* ----- Functions ----- */

    function outboundNonce(uint16 dstChainId) external view returns (uint256 nonce);

    function increment(uint16 dstChainId) external returns (uint256 nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IWOOFiDexCrossChainRouter {
    /* ----- Structs ----- */

    struct SrcInfos {
        address fromToken;
        uint256 fromAmount;
        address bridgeToken;
        uint256 minBridgeAmount;
    }

    struct DstInfos {
        uint16 chainId;
        address bridgedToken;
        address toToken;
        uint256 minToAmount;
        uint256 airdropNativeAmount;
    }

    struct DstVaultDeposit {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
    }

    struct PoolIds {
        uint256 src;
        uint256 dst;
    }

    /* ----- Events ----- */

    event WOOFiDexCrossSwapOnSrcChain(
        uint16 dstChainId,
        uint256 indexed nonce,
        address indexed sender,
        address indexed to,
        address fromToken,
        uint256 fromAmount,
        address bridgeToken,
        uint256 minBridgeAmount,
        uint256 bridgeAmount
    );

    event WOOFiDexCrossSwapOnDstChain(
        uint16 srcChainId,
        uint256 indexed nonce,
        address indexed sender,
        address indexed to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        uint256 minToAmount,
        address realToToken,
        uint256 realToAmount,
        bytes32 accountId,
        bytes32 brokerHash,
        bytes32 tokenHash,
        uint128 tokenAmount
    );

    /* ----- State Variables ----- */

    function weth() external view returns (address);

    function bridgeSlippage() external view returns (uint256);

    function dstGasForSwapCall() external view returns (uint256);

    function dstGasForNoSwapCall() external view returns (uint256);

    function sgChainIdLocal() external view returns (uint16);

    function woofiDexCrossChainRouters(uint16 chainId) external view returns (address wooCrossChainRouter);

    function woofiDexVaults(uint16 chainId, address token) external view returns (address woofiDexVault);

    function sgETHs(uint16 chainId) external view returns (address sgETH);

    function sgPoolIds(uint16 chainId, address token) external view returns (uint256 poolId);

    /* ----- Functions ----- */

    function crossSwap(
        address payable to,
        SrcInfos calldata srcInfos,
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external payable;

    function sgReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint256 nonce,
        address bridgedToken,
        uint256 amountLD,
        bytes memory payload
    ) external;

    function quoteLayerZeroFee(
        address to,
        SrcInfos memory srcInfos,
        DstInfos memory dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external view returns (uint256 nativeAmount, uint256 zroAmount);

    function allDirectBridgeTokens() external view returns (address[] memory tokens);

    function allDirectBridgeTokensLength() external view returns (uint256 length);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

interface IWOOFiDexVault {
    struct VaultDepositFE {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
    }

    function depositTo(address receiver, VaultDepositFE calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.14;

// OpenZeppelin Contracts
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Uniswap Periphery
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

// Local Contracts
import {IStargateEthVault} from "../interfaces/Stargate/IStargateEthVault.sol";
import {IStargateRouter} from "../interfaces/Stargate/IStargateRouter.sol";
import {INonceCounter} from "../interfaces/WOOFiDex/INonceCounter.sol";
import {IWOOFiDexCrossChainRouter} from "../interfaces/WOOFiDex/IWOOFiDexCrossChainRouter.sol";
import {IWOOFiDexVault} from "../interfaces/WOOFiDex/IWOOFiDexVault.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IWooRouterV2} from "../interfaces/IWooRouterV2.sol";

/// @title WOOFi Dex Router for Cross Chain and Same Chain Swap to Deposit
/// @custom:stargate-contracts https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses
contract WOOFiDexCrossChainRouter is IWOOFiDexCrossChainRouter, Ownable, Pausable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ----- Constants ----- */

    address public constant NATIVE_PLACEHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MAX_BRIDGE_SLIPPAGE = 10000;

    /* ----- Variables ----- */

    INonceCounter public nonceCounter;
    IWooRouterV2 public wooRouter;
    IStargateRouter public stargateRouter;

    address public immutable weth;
    uint256 public bridgeSlippage; // default 0.2%
    uint256 public dstGasForSwapCall;
    uint256 public dstGasForNoSwapCall;

    uint16 public sgChainIdLocal; // stargate chainId on local chain

    mapping(uint16 => address) public woofiDexCrossChainRouters; // chainId => WOOFiDexCrossChainRouter address
    mapping(uint16 => mapping(address => address)) public woofiDexVaults; // chainId => token address => WOOFiDexVault address
    mapping(uint16 => address) public sgETHs; // chainId => SGETH token address
    mapping(uint16 => mapping(address => uint256)) public sgPoolIds; // chainId => token address => Stargate poolId

    EnumerableSet.AddressSet private directBridgeTokens;

    receive() external payable {}

    constructor(
        address _weth,
        address _nonceCounter,
        address _wooRouter,
        address _stargateRouter,
        uint16 _sgChainIdLocal
    ) {
        nonceCounter = INonceCounter(_nonceCounter);
        wooRouter = IWooRouterV2(_wooRouter);
        stargateRouter = IStargateRouter(_stargateRouter);

        weth = _weth;
        bridgeSlippage = 20;
        dstGasForSwapCall = 750000;
        dstGasForNoSwapCall = 450000;

        sgChainIdLocal = _sgChainIdLocal;

        _initSgETHs();
        _initSgPoolIds();
    }

    /* ----- Functions ----- */

    function crossSwap(
        address payable to,
        SrcInfos calldata srcInfos,
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external payable whenNotPaused nonReentrant {
        require(to != address(0), "WOOFiDexCrossChainRouter: to not allow");
        require(srcInfos.fromToken != address(0), "WOOFiDexCrossChainRouter: srcInfos.fromToken not allow");
        require(
            dstInfos.toToken != address(0) && dstInfos.toToken != sgETHs[dstInfos.chainId],
            "WOOFiDexCrossChainRouter: dstInfos.toToken not allow"
        );
        require(
            woofiDexVaults[dstInfos.chainId][dstInfos.toToken] != address(0),
            "WOOFiDexCrossChainRouter: dstInfos.chainId not allow"
        );

        address sender = _msgSender();
        uint256 nativeAmount = msg.value;
        uint256 bridgeAmount;

        {
            address srcFromToken = srcInfos.fromToken;
            if (srcFromToken == NATIVE_PLACEHOLDER) {
                require(srcInfos.fromAmount <= nativeAmount, "WOOFiDexCrossChainRouter: nativeAmount not enough");
                srcFromToken = weth;
                IWETH(weth).deposit{value: srcInfos.fromAmount}();
                nativeAmount -= srcInfos.fromAmount;
            } else {
                TransferHelper.safeTransferFrom(srcFromToken, sender, address(this), srcInfos.fromAmount);
            }

            if (!directBridgeTokens.contains(srcFromToken) && srcFromToken != srcInfos.bridgeToken) {
                TransferHelper.safeApprove(srcFromToken, address(wooRouter), srcInfos.fromAmount);
                bridgeAmount = wooRouter.swap(
                    srcFromToken,
                    srcInfos.bridgeToken,
                    srcInfos.fromAmount,
                    srcInfos.minBridgeAmount,
                    payable(address(this)),
                    to
                );
            } else {
                require(
                    srcInfos.fromAmount == srcInfos.minBridgeAmount,
                    "WOOFiDexCrossChainRouter: srcInfos.minBridgeAmount incorrect"
                );
                bridgeAmount = srcInfos.fromAmount;
            }

            require(
                bridgeAmount <= IERC20(srcInfos.bridgeToken).balanceOf(address(this)),
                "WOOFiDexCrossChainRouter: bridgeAmount exceed balance"
            );
        }

        uint256 nonce = nonceCounter.increment(dstInfos.chainId);
        {
            uint256 dstMinBridgedAmount = (bridgeAmount * (MAX_BRIDGE_SLIPPAGE - bridgeSlippage)) / MAX_BRIDGE_SLIPPAGE;
            bytes memory payload = _getEncodePayload(nonce, to, dstInfos, dstVaultDeposit);
            _bridgeByStargate(to, nativeAmount, bridgeAmount, dstMinBridgedAmount, payload, srcInfos, dstInfos);
        }

        emit WOOFiDexCrossSwapOnSrcChain(
            dstInfos.chainId,
            nonce,
            sender,
            to,
            srcInfos.fromToken,
            srcInfos.fromAmount,
            srcInfos.bridgeToken,
            srcInfos.minBridgeAmount,
            bridgeAmount
        );
    }

    function sgReceive(
        uint16 srcChainId,
        bytes memory, // srcAddress
        uint256, // nonce
        address bridgedToken,
        uint256 bridgedAmount,
        bytes memory payload
    ) external {
        address sender = _msgSender();
        require(sender == address(stargateRouter), "WOOFiDexCrossChainRouter: invalid sender");

        (
            uint256 nonce,
            address to,
            address toToken,
            uint256 minToAmount,
            DstVaultDeposit memory dstVaultDeposit
        ) = _getDecodePayload(payload);
        address woofiDexVault = woofiDexVaults[sgChainIdLocal][toToken];

        _handleERC20Received(
            srcChainId,
            nonce,
            sender,
            to,
            bridgedToken,
            bridgedAmount,
            toToken,
            minToAmount,
            woofiDexVault,
            dstVaultDeposit
        );
    }

    function quoteLayerZeroFee(
        address to,
        SrcInfos calldata, // srcInfos
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) external view returns (uint256 nativeAmount, uint256 zroAmount) {
        uint256 nonce = nonceCounter.outboundNonce(dstInfos.chainId) + 1;
        bytes memory payload = _getEncodePayload(nonce, payable(to), dstInfos, dstVaultDeposit);

        // only bridge via Stargate
        IStargateRouter.lzTxObj memory obj = _getLzTxObj(to, dstInfos);

        return
            stargateRouter.quoteLayerZeroFee(
                dstInfos.chainId,
                1, // https://stargateprotocol.gitbook.io/stargate/developers/function-types
                obj.dstNativeAddr,
                payload,
                obj
            );
    }

    function allDirectBridgeTokens() external view returns (address[] memory) {
        uint256 length = directBridgeTokens.length();
        address[] memory tokens = new address[](length);
        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                tokens[i] = directBridgeTokens.at(i);
            }
        }
        return tokens;
    }

    function allDirectBridgeTokensLength() external view returns (uint256) {
        return directBridgeTokens.length();
    }

    function _initSgETHs() internal {
        sgETHs[101] = 0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c; // Ethereum
        sgETHs[110] = 0x82CbeCF39bEe528B5476FE6d1550af59a9dB6Fc0; // Arbitrum
        sgETHs[111] = 0xb69c8CBCD90A39D8D3d3ccf0a3E968511C3856A0; // Optimism
        sgETHs[183] = 0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03; // Linea
        sgETHs[184] = 0x224D8Fd7aB6AD4c6eb4611Ce56EF35Dec2277F03; // Base
    }

    function _initSgPoolIds() internal {
        // poolId > 0 means able to be bridge token
        // Ethereum
        sgPoolIds[101][0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 1; // USDC
        sgPoolIds[101][0xdAC17F958D2ee523a2206206994597C13D831ec7] = 2; // USDT
        sgPoolIds[101][0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2] = 13; // WETH
        sgPoolIds[101][0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = 20; // WOO
        // BNB Chain
        sgPoolIds[102][0x55d398326f99059fF775485246999027B3197955] = 2; // USDT
        sgPoolIds[102][0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56] = 5; // BUSD
        sgPoolIds[102][0x4691937a7508860F876c9c0a2a617E7d9E945D4B] = 20; // WOO
        // Avalanche
        sgPoolIds[106][0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E] = 1; // USDC
        sgPoolIds[106][0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7] = 2; // USDT
        sgPoolIds[106][0xaBC9547B534519fF73921b1FBA6E672b5f58D083] = 20; // WOO
        // Polygon
        sgPoolIds[109][0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174] = 1; // USDC
        sgPoolIds[109][0xc2132D05D31c914a87C6611C10748AEb04B58e8F] = 2; // USDT
        sgPoolIds[109][0x1B815d120B3eF02039Ee11dC2d33DE7aA4a8C603] = 20; // WOO
        // Arbitrum
        sgPoolIds[110][0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = 1; // USDC
        sgPoolIds[110][0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9] = 2; // USDT
        sgPoolIds[110][0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 13; // WETH
        sgPoolIds[110][0xcAFcD85D8ca7Ad1e1C6F82F651fA15E33AEfD07b] = 20; // WOO
        // Optimism
        sgPoolIds[111][0x7F5c764cBc14f9669B88837ca1490cCa17c31607] = 1; // USDC
        sgPoolIds[111][0x4200000000000000000000000000000000000006] = 13; // WETH
        sgPoolIds[111][0x871f2F2ff935FD1eD867842FF2a7bfD051A5E527] = 20; // WOO
        // Fantom
        sgPoolIds[112][0x04068DA6C83AFCFA0e13ba15A6696662335D5B75] = 1; // USDC
        sgPoolIds[112][0x6626c47c00F1D87902fc13EECfaC3ed06D5E8D8a] = 20; // WOO
        // Linea
        sgPoolIds[183][0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f] = 13; // WETH
        // Base
        sgPoolIds[184][0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA] = 1; // USDC
        sgPoolIds[184][0x4200000000000000000000000000000000000006] = 13; // WETH
    }

    function _getDstGasForCall(DstInfos memory dstInfos) internal view returns (uint256) {
        return (dstInfos.toToken == dstInfos.bridgedToken) ? dstGasForNoSwapCall : dstGasForSwapCall;
    }

    function _getLzTxObj(address to, DstInfos memory dstInfos) internal view returns (IStargateRouter.lzTxObj memory) {
        uint256 dstGasForCall = _getDstGasForCall(dstInfos);

        return IStargateRouter.lzTxObj(dstGasForCall, dstInfos.airdropNativeAmount, abi.encodePacked(to));
    }

    function _getEncodePayload(
        uint256 nonce,
        address payable to,
        DstInfos calldata dstInfos,
        DstVaultDeposit calldata dstVaultDeposit
    ) internal pure returns (bytes memory) {
        return abi.encode(nonce, to, dstInfos.toToken, dstInfos.minToAmount, dstVaultDeposit);
    }

    function _getDecodePayload(bytes memory payload)
        internal
        pure
        returns (
            uint256,
            address,
            address,
            uint256,
            DstVaultDeposit memory
        )
    {
        (uint256 nonce, address to, address toToken, uint256 minToAmount, DstVaultDeposit memory dstVaultDeposit) = abi
            .decode(payload, (uint256, address, address, uint256, DstVaultDeposit));

        return (nonce, to, toToken, minToAmount, dstVaultDeposit);
    }

    function _bridgeByStargate(
        address payable to,
        uint256 nativeAmount,
        uint256 bridgeAmount,
        uint256 dstMinBridgedAmount,
        bytes memory payload,
        SrcInfos calldata srcInfos,
        DstInfos calldata dstInfos
    ) internal {
        // avoid stack too deep
        PoolIds memory poolIds;
        {
            poolIds = PoolIds(
                sgPoolIds[sgChainIdLocal][srcInfos.bridgeToken],
                sgPoolIds[dstInfos.chainId][dstInfos.bridgedToken]
            );
        }
        require(poolIds.src > 0, "WOOFiDexCrossChainRouter: poolIds.src not exist");
        require(poolIds.dst > 0, "WOOFiDexCrossChainRouter: poolIds.dst not exist");

        if (srcInfos.bridgeToken == weth) {
            IWETH(weth).withdraw(bridgeAmount);
            address sgETH = sgETHs[sgChainIdLocal];
            IStargateEthVault(sgETH).deposit{value: bridgeAmount}(); // logic from Stargate RouterETH.sol
            TransferHelper.safeApprove(sgETH, address(stargateRouter), bridgeAmount);
        } else {
            TransferHelper.safeApprove(srcInfos.bridgeToken, address(stargateRouter), bridgeAmount);
        }

        IStargateRouter.lzTxObj memory obj = _getLzTxObj(to, dstInfos);
        stargateRouter.swap{value: nativeAmount}(
            dstInfos.chainId, // dst chain id
            poolIds.src, // bridge token's pool id on src chain
            poolIds.dst, // bridge token's pool id on dst chain
            payable(_msgSender()), // rebate address
            bridgeAmount, // swap amount on src chain
            dstMinBridgedAmount, // min received amount on dst chain
            obj, // config: dstGasForCall, dstNativeAmount, dstNativeAddr
            abi.encodePacked(woofiDexCrossChainRouters[dstInfos.chainId]), // smart contract to call on dst chain
            payload // payload to piggyback
        );
    }

    function _handleERC20Received(
        uint16 srcChainId,
        uint256 nonce,
        address sender,
        address to,
        address bridgedToken,
        uint256 bridgedAmount,
        address toToken,
        uint256 minToAmount,
        address woofiDexVault,
        DstVaultDeposit memory dstVaultDeposit
    ) internal {
        if (toToken == bridgedToken) {
            IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = IWOOFiDexVault.VaultDepositFE(
                dstVaultDeposit.accountId,
                dstVaultDeposit.brokerHash,
                dstVaultDeposit.tokenHash,
                uint128(bridgedAmount)
            );
            TransferHelper.safeApprove(toToken, woofiDexVault, bridgedAmount);
            IWOOFiDexVault(woofiDexVault).depositTo(to, vaultDepositFE);
            emit WOOFiDexCrossSwapOnDstChain(
                srcChainId,
                nonce,
                sender,
                to,
                bridgedToken,
                bridgedAmount,
                toToken,
                minToAmount,
                toToken,
                bridgedAmount,
                vaultDepositFE.accountId,
                vaultDepositFE.brokerHash,
                vaultDepositFE.tokenHash,
                vaultDepositFE.tokenAmount
            );
        } else {
            TransferHelper.safeApprove(bridgedToken, address(wooRouter), bridgedAmount);
            try wooRouter.swap(bridgedToken, toToken, bridgedAmount, minToAmount, payable(address(this)), to) returns (
                uint256 realToAmount
            ) {
                IWOOFiDexVault.VaultDepositFE memory vaultDepositFE = IWOOFiDexVault.VaultDepositFE(
                    dstVaultDeposit.accountId,
                    dstVaultDeposit.brokerHash,
                    dstVaultDeposit.tokenHash,
                    uint128(realToAmount)
                );
                TransferHelper.safeApprove(toToken, woofiDexVault, realToAmount);
                IWOOFiDexVault(woofiDexVault).depositTo(to, vaultDepositFE);
                emit WOOFiDexCrossSwapOnDstChain(
                    srcChainId,
                    nonce,
                    sender,
                    to,
                    bridgedToken,
                    bridgedAmount,
                    toToken,
                    minToAmount,
                    toToken,
                    realToAmount,
                    vaultDepositFE.accountId,
                    vaultDepositFE.brokerHash,
                    vaultDepositFE.tokenHash,
                    vaultDepositFE.tokenAmount
                );
            } catch {
                TransferHelper.safeTransfer(bridgedToken, to, bridgedAmount);
                emit WOOFiDexCrossSwapOnDstChain(
                    srcChainId,
                    nonce,
                    sender,
                    to,
                    bridgedToken,
                    bridgedAmount,
                    toToken,
                    minToAmount,
                    bridgedToken,
                    bridgedAmount,
                    bytes32(0),
                    bytes32(0),
                    bytes32(0),
                    0
                );
            }
        }
    }

    /* ----- Owner & Admin Functions ----- */

    function setWooRouter(address _wooRouter) external onlyOwner {
        require(_wooRouter != address(0), "WOOFiDexCrossChainRouter: _wooRouter cant be zero");
        wooRouter = IWooRouterV2(_wooRouter);
    }

    function setStargateRouter(address _stargateRouter) external onlyOwner {
        require(_stargateRouter != address(0), "WOOFiDexCrossChainRouter: _stargateRouter cant be zero");
        stargateRouter = IStargateRouter(_stargateRouter);
    }

    function setBridgeSlippage(uint256 _bridgeSlippage) external onlyOwner {
        require(_bridgeSlippage <= MAX_BRIDGE_SLIPPAGE, "WOOFiDexCrossChainRouter: _bridgeSlippage exceed max");
        bridgeSlippage = _bridgeSlippage;
    }

    function setDstGasForSwapCall(uint256 _dstGasForSwapCall) external onlyOwner {
        dstGasForSwapCall = _dstGasForSwapCall;
    }

    function setDstGasForNoSwapCall(uint256 _dstGasForNoSwapCall) external onlyOwner {
        dstGasForNoSwapCall = _dstGasForNoSwapCall;
    }

    function setSgChainIdLocal(uint16 _sgChainIdLocal) external onlyOwner {
        sgChainIdLocal = _sgChainIdLocal;
    }

    function setWOOFiDexCrossChainRouter(uint16 chainId, address woofiDexCrossChainRouter) external onlyOwner {
        require(
            woofiDexCrossChainRouter != address(0),
            "WOOFiDexCrossChainRouter: woofiDexCrossChainRouter cant be zero"
        );
        woofiDexCrossChainRouters[chainId] = woofiDexCrossChainRouter;
    }

    function setWOOFiDexVault(
        uint16 chainId,
        address token,
        address woofiDexVault
    ) external onlyOwner {
        require(woofiDexVault != address(0), "WOOFiDexCrossChainRouter: woofiDexVault cant be zero");
        woofiDexVaults[chainId][token] = woofiDexVault;
    }

    function setSgETH(uint16 chainId, address token) external onlyOwner {
        require(token != address(0), "WOOFiDexCrossChainRouter: token cant be zero");
        sgETHs[chainId] = token;
    }

    function setSgPoolId(
        uint16 chainId,
        address token,
        uint256 poolId
    ) external onlyOwner {
        sgPoolIds[chainId][token] = poolId;
    }

    function addDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.add(token);
        require(success, "WOOFiDexCrossChainRouter: token exist");
    }

    function removeDirectBridgeToken(address token) external onlyOwner {
        bool success = directBridgeTokens.remove(token);
        require(success, "WOOFiDexCrossChainRouter: token not exist");
    }

    function inCaseTokenGotStuck(address stuckToken) external onlyOwner {
        address sender = _msgSender();
        if (stuckToken == NATIVE_PLACEHOLDER) {
            TransferHelper.safeTransferETH(sender, address(this).balance);
        } else {
            uint256 amount = IERC20(stuckToken).balanceOf(address(this));
            TransferHelper.safeTransfer(stuckToken, sender, amount);
        }
    }
}