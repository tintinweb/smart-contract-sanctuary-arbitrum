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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICore.sol";
import "./interfaces/IOptionsFlashCallback.sol";
import "./interfaces/IOracleTemplate.sol";

contract Core is ICore, Ownable, ReentrancyGuard {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant DIVIDER = 1 ether;
    uint256 public constant MAX_PROTOCOL_FEE = 0.2 ether;
    uint256 public constant MAX_FLASHLOAN_FEE = 0.2 ether;

    NFTDiscountLevel private _discount;
    FeeConfiguration private _feeConfiguration;
    GlobalsConfiguration private _globalsConfiguration;
    ImmutableConfiguration private _immutableConfiguration;
    LimitsConfiguration private _limitsConfiguration;

    EnumerableSet.AddressSet private _oracles;
    EnumerableSet.AddressSet private _oraclesWhitelist;

    mapping(uint256 => EnumerableSet.AddressSet) private _accountsAutomation;
    mapping(uint256 => mapping(address => Automation)) private _automations;
    mapping(uint256 => Position) private _positions;

    mapping(address => uint256) public oracleTimes;
    mapping(uint256 => uint256) public unacceptedBalances;
    mapping(address => mapping(uint256 => bool)) public positionsExist;

    function affiliationUserData(address user) public view returns (AffiliationUserData memory output) {
        output.activeId = _immutableConfiguration.affiliation.usersActiveID(user);
        output.team = _immutableConfiguration.affiliation.usersTeam(user);
        output.nftData = _immutableConfiguration.affiliation.data(output.activeId);
        IFoxifyAffiliationFull.Level level = output.nftData.level;
        if (level == IFoxifyAffiliation.Level.BRONZE) {
            output.discount = _discount.bronze;
        } else if (level == IFoxifyAffiliation.Level.SILVER) {
            output.discount = _discount.silver;
        } else if (level == IFoxifyAffiliation.Level.GOLD) {
            output.discount = _discount.gold;
        }
    }

    function accountsAutomationCount(uint256 positionId) external view returns (uint256) {
        return _accountsAutomation[positionId].length();
    }

    function accountsAutomationContains(uint256 positionId, address wallet) external view returns (bool) {
        return _accountsAutomation[positionId].contains(wallet);
    }

    function accountsAutomationList(
        uint256 positionId,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory output) {
        uint256 automationsLength = _accountsAutomation[positionId].length();
        if (offset >= automationsLength) return new address[](0);
        uint256 to = offset + limit;
        if (automationsLength < to) to = automationsLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _accountsAutomation[positionId].at(offset + i);
    }

    function automations(uint256 positionId, address wallet) external view returns (Automation memory) {
        return _automations[positionId][wallet];
    }

    function calculateStableFee(address user, uint256 amount, uint256 fee) external view returns (uint256) {
        AffiliationUserData memory affiliationUserData_ = affiliationUserData(user);
        return _calculateStableFee(affiliationUserData_, amount, fee);
    }

    function discount() external view returns (NFTDiscountLevel memory) {
        return _discount;
    }

    function feeConfiguration() external view returns (FeeConfiguration memory) {
        return _feeConfiguration;
    }

    function globalsConfiguration() external view returns (GlobalsConfiguration memory) {
        return _globalsConfiguration;
    }

    function immutableConfiguration() external view returns (ImmutableConfiguration memory) {
        return _immutableConfiguration;
    }

    function limitsConfiguration() external view returns (LimitsConfiguration memory) {
        return _limitsConfiguration;
    }

    function oraclesCount() external view returns (uint256) {
        return _oracles.length();
    }

    function oraclesContains(address oracle) external view returns (bool) {
        return _oracles.contains(oracle);
    }

    function oraclesList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 oraclesLength = _oracles.length();
        if (offset >= oraclesLength) return new address[](0);
        uint256 to = offset + limit;
        if (oraclesLength < to) to = oraclesLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _oracles.at(offset + i);
    }

    function oraclesWhitelistCount() external view returns (uint256) {
        return _oraclesWhitelist.length();
    }

    function oraclesWhitelistContains(address oracle) external view returns (bool) {
        return _oraclesWhitelist.contains(oracle);
    }

    function oraclesWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 oraclesWhitelistLength = _oraclesWhitelist.length();
        if (offset >= oraclesWhitelistLength) return new address[](0);
        uint256 to = offset + limit;
        if (oraclesWhitelistLength < to) to = oraclesWhitelistLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _oraclesWhitelist.at(offset + i);
    }

    function positions(uint256 positionId) external view returns (Position memory) {
        return _positions[positionId];
    }

    constructor(ImmutableConfiguration memory config_) {
        require(address(config_.stable) != address(0), "Core: Stable is zero address");
        require(address(config_.positionTokenCreator) != address(0), "Core: Position token Creator is zero address");
        require(address(config_.positionTokenAccepter) != address(0), "Core: Position token Accepter is zero address");
        require(address(config_.affiliation) != address(0), "Core: Affiliation is zero address");
        require(address(config_.blacklist) != address(0), "Core: Blacklist is zero address");
        require(address(config_.oracleAggregator) != address(0), "Core: Oracle Aggregator is zero address");
        _immutableConfiguration = config_;
    }

    function accept(
        uint256 positionId,
        uint256 ratesCount,
        bool autoResolve_
    ) external payable notBlacklisted(msg.sender) returns (bool) {
        _accept(positionId, ratesCount, autoResolve_, msg.sender);
        return true;
    }

    function acceptWithPermit(
        uint256 positionId,
        uint256 ratesCount,
        bool autoResolve_,
        Permit memory permit
    ) external payable notBlacklisted(msg.sender) returns (bool) {
        _immutableConfiguration.stable.permit(
            msg.sender,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        _accept(positionId, ratesCount, autoResolve_, msg.sender);
        return true;
    }

    function addOracles(address[] memory oracles_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < oracles_.length; i++) {
            require(
                IOracleTemplate(oracles_[i]).oracleAggregator() == _immutableConfiguration.oracleAggregator,
                "Core: Invalid oracle"
            );
            _oracles.add(oracles_[i]);
            _oraclesWhitelist.add(oracles_[i]);
        }
        emit OraclesAdded(oracles_);
        return true;
    }

    function autoResolve(AutoResolve[] memory data) external nonReentrant onlyKeeper returns (bool) {
        for (uint256 i = 0; i < data.length; i++) {
            _autoResolve(data[i]);
        }
        return true;
    }

    function autoResolveAndRepeat(uint256[] memory positionIds) external nonReentrant onlyKeeper returns (bool) {
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 positionId = positionIds[i];
            require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
            Position memory position_ = _positions[positionId];
            Automation storage automation_ = _automations[positionId][position_.creator];
            AffiliationUserData memory affiliationUserData_ = affiliationUserData(position_.creator);
            uint256 balanceOfCreator = _immutableConfiguration.positionTokenCreator.balanceOf(
                position_.creator,
                positionId
            );
            uint256 price = _immutableConfiguration.oracleAggregator.getData(
                position_.data.oracle,
                position_.data.endTime
            );
            bool returnRepeatsFee;
            if (
                balanceOfCreator > 0 &&
                automation_.repeatsCount > 0 &&
                _immutableConfiguration.oracleAggregator.hasData(position_.data.oracle, position_.data.endTime) &&
                ((price > position_.data.strike && position_.data.position == PositionType.UP) ||
                    (price < position_.data.strike && position_.data.position == PositionType.DOWN))
            ) {
                automation_.repeatsCount--;
                _automations[positionId + 1][position_.creator] = automation_;
                uint256 totalStableToWithdraw = _execute(positionId, position_.creator, balanceOfCreator, true);
                uint256 amount = balanceOfCreator * position_.minPositionAmountCreator;
                uint256 amountWithFee = amount + _calculateStableFee(affiliationUserData_, amount, position_.fee);
                if (totalStableToWithdraw >= amountWithFee) {
                    _immutableConfiguration.stable.transfer(position_.creator, totalStableToWithdraw - amountWithFee);
                    position_.data.endTime += (position_.timeslotsAmount * position_.oraclePeriod);
                    position_.data.ratesCount = balanceOfCreator;
                    _create(position_.data, false, true, 0, position_.creator);
                } else {
                    returnRepeatsFee = true;
                    _immutableConfiguration.stable.transfer(position_.creator, totalStableToWithdraw);
                }
                payable(msg.sender).transfer(automation_.fee);
                delete _automations[positionId][position_.creator];
                _accountsAutomation[positionId].remove(position_.creator);
            } else {
                returnRepeatsFee = true;
                address[] memory creator = new address[](1);
                creator[0] = position_.creator;
                _autoResolve(AutoResolve(positionId, creator));
            }
            if (automation_.repeatsCount > 0 && returnRepeatsFee) {
                uint256 returnAmount = automation_.repeatsCount * automation_.fee;
                payable(position_.creator).transfer(returnAmount);
            }
        }
        emit AutoResolveAndRepeated(positionIds);
        return true;
    }

    function cancel(uint256[] memory positionIds) external nonReentrant returns (bool) {
        for (uint256 i = 0; i < positionIds.length; i++) {
            _cancel(
                positionIds[i],
                msg.sender,
                _immutableConfiguration.positionTokenAccepter.balanceOf(msg.sender, positionIds[i])
            );
        }
        return true;
    }

    function claimFee(uint256 amount) external onlyOwner returns (bool) {
        require(
            amount <= _immutableConfiguration.stable.balanceOf(address(this)) - _globalsConfiguration.totalStableAmount,
            "Core: Amount gt available"
        );
        _immutableConfiguration.stable.transfer(_feeConfiguration.feeRecipient, amount);
        emit FeeClaimed(amount);
        return true;
    }

    function create(
        CreateInputData memory data,
        bool autoResolve_,
        uint256 repeats
    ) external payable nonReentrant notBlacklisted(msg.sender) returns (uint256) {
        return _create(data, autoResolve_, false, repeats, msg.sender);
    }

    function createWithPermit(
        CreateInputData memory data,
        bool autoResolve_,
        uint256 repeats,
        Permit memory permit
    ) external payable nonReentrant notBlacklisted(msg.sender) returns (uint256) {
        _immutableConfiguration.stable.permit(
            msg.sender,
            address(this),
            permit.value,
            permit.deadline,
            permit.v,
            permit.r,
            permit.s
        );
        return _create(data, autoResolve_, false, repeats, msg.sender);
    }

    function execute(uint256[] memory positionIds) external nonReentrant returns (bool) {
        for (uint256 i = 0; i < positionIds.length; i++) {
            _execute(
                positionIds[i],
                msg.sender,
                _immutableConfiguration.positionTokenAccepter.balanceOf(msg.sender, positionIds[i]),
                false
            );
        }
        return true;
    }

    function flashloan(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant notBlacklisted(msg.sender) returns (bool) {
        uint256 balanceBefore = _immutableConfiguration.stable.balanceOf(address(this));
        require(amount > 0 && amount <= balanceBefore, "Core: Invalid amount");
        AffiliationUserData memory affiliationUserData_ = affiliationUserData(msg.sender);
        uint256 fee = _calculateStableFee(affiliationUserData_, amount, _feeConfiguration.flashloanFee);
        _immutableConfiguration.stable.transfer(recipient, amount);
        IOptionsFlashCallback(msg.sender).optionsFlashCallback(recipient, amount, fee, data);
        uint256 balanceAfter = _immutableConfiguration.stable.balanceOf(address(this));
        require(balanceBefore + fee <= balanceAfter, "Core: Invalid stable balance");
        emit Flashloan(msg.sender, affiliationUserData_, recipient, amount, balanceAfter - balanceBefore);
        return true;
    }

    function redeem(uint256 positionId, uint256 ratesCount) external nonReentrant returns (bool) {
        require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
        Position storage position_ = _positions[positionId];
        require(position_.data.endTime > block.timestamp, "Core: Position ended");
        require(
            _immutableConfiguration.positionTokenCreator.balanceOf(msg.sender, positionId) >= ratesCount &&
                _immutableConfiguration.positionTokenAccepter.balanceOf(msg.sender, positionId) >= ratesCount,
            "Core: Not enough position tokens"
        );
        uint256 totalStableToWithdraw = (ratesCount * position_.minPositionAmountCreator) +
            (ratesCount * position_.minPositionAmountAccepter);
        position_.minted -= ratesCount;
        _globalsConfiguration.totalStableAmount -= totalStableToWithdraw;
        _immutableConfiguration.positionTokenCreator.burn(msg.sender, positionId, ratesCount);
        _immutableConfiguration.positionTokenAccepter.burn(msg.sender, positionId, ratesCount);
        _immutableConfiguration.stable.transfer(msg.sender, totalStableToWithdraw);
        emit Redeemed(msg.sender, positionId, ratesCount, totalStableToWithdraw);
        return true;
    }

    function redeemWithFlashloan(
        uint256 positionId,
        uint256 ratesCount
    ) external nonReentrant notBlacklisted(msg.sender) returns (bool) {
        require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
        Position storage position_ = _positions[positionId];
        AffiliationUserData memory affiliationUserData_ = affiliationUserData(msg.sender);
        require(position_.data.endTime > block.timestamp, "Core: Position ended");
        require(
            _immutableConfiguration.positionTokenCreator.balanceOf(msg.sender, positionId) >= ratesCount &&
                unacceptedBalances[positionId] >= ratesCount,
            "Core: Not enough position tokens"
        );
        uint256 totalStableToWithdraw = ratesCount * position_.minPositionAmountCreator;
        uint256 protocolFee_ = _calculateStableFee(affiliationUserData_, totalStableToWithdraw, position_.fee);
        uint256 flashloanFee_ = _calculateStableFee(
            affiliationUserData_,
            totalStableToWithdraw + protocolFee_,
            _feeConfiguration.flashloanFee
        );
        uint256 fee = protocolFee_ + flashloanFee_;
        require(fee <= totalStableToWithdraw, "Core: Fee gt withdraw value");
        totalStableToWithdraw -= fee;
        position_.minted -= ratesCount;
        _globalsConfiguration.totalStableAmount -= totalStableToWithdraw;
        unacceptedBalances[positionId] -= ratesCount;
        _immutableConfiguration.positionTokenCreator.burn(msg.sender, positionId, ratesCount);
        _immutableConfiguration.positionTokenAccepter.burn(address(this), positionId, ratesCount);
        _immutableConfiguration.stable.transfer(msg.sender, totalStableToWithdraw);
        emit RedeemedWithFlashloan(
            msg.sender,
            positionId,
            affiliationUserData_,
            ratesCount,
            totalStableToWithdraw,
            fee
        );
        return true;
    }

    function removeOracles(address[] memory oracles_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < oracles_.length; i++) {
            _oracles.remove(oracles_[i]);
        }
        emit OraclesRemoved(oracles_);
        return true;
    }

    function removeOraclesWhitelist(address[] memory oracles_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < oracles_.length; i++) {
            _oraclesWhitelist.remove(oracles_[i]);
        }
        emit OraclesWhitelistRemoved(oracles_);
        return true;
    }

    function updateDiscount(NFTDiscountLevel memory discount_) external onlyOwner returns (bool) {
        require(
            discount_.bronze <= DIVIDER && discount_.silver <= DIVIDER && discount_.gold <= DIVIDER,
            "Core: Invalid discount value"
        );
        _discount = discount_;
        emit DiscountUpdated(discount_);
        return true;
    }

    function updateLimitsConfiguration(LimitsConfiguration memory config) external onlyOwner returns (bool) {
        require(config.minPositionAmount > 0, "Core: MinPosition is not positive");
        require(config.minPositionRate > 0, "Core: MinRate is not positive");
        require(config.maxPositionRate >= config.minPositionRate, "Core: Max rate lt min");
        _limitsConfiguration = config;
        emit LimitsConfigurationUpdated(config);
        return true;
    }

    function updateFeeConfiguration(FeeConfiguration memory config) external onlyOwner returns (bool) {
        require(config.feeRecipient != address(0), "Core: Recipient is zero address");
        require(config.protocolFee <= MAX_PROTOCOL_FEE, "Core: Protocol fee gt max");
        require(config.flashloanFee <= MAX_FLASHLOAN_FEE, "Core: Flashloan fee gt max");
        _feeConfiguration = config;
        emit FeeConfigurationUpdated(config);
        return true;
    }

    function _calculateStableFee(
        AffiliationUserData memory affiliationUserData_,
        uint256 amount,
        uint256 fee
    ) private pure returns (uint256) {
        uint256 stableFee = (amount * fee) / DIVIDER;
        uint256 discount_ = (affiliationUserData_.discount * stableFee) / DIVIDER;
        return stableFee - discount_;
    }

    function _accept(uint256 positionId, uint256 ratesCount, bool autoResolve_, address account) private nonReentrant {
        require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
        require(ratesCount > 0, "Core: RatesCount is not positive");
        Position storage position_ = _positions[positionId];
        Automation storage automation_ = _automations[positionId][account];
        AffiliationUserData memory affiliationUserData_ = affiliationUserData(account);
        require(position_.data.endTime > block.timestamp, "Core: Position ended");
        if (autoResolve_) {
            require(!_accountsAutomation[positionId].contains(account), "Core: Automation is active");
            require(msg.value >= _feeConfiguration.resolveFee, "Core: Insufficient ETH value");
            automation_.fee = _feeConfiguration.resolveFee;
            automation_.resolve = true;
            _accountsAutomation[positionId].add(account);
        }
        uint256 amount = ratesCount * position_.minPositionAmountAccepter;
        uint256 amountWithFee = amount + _calculateStableFee(affiliationUserData_, amount, position_.fee);
        _immutableConfiguration.stable.transferFrom(account, address(this), amountWithFee);
        _immutableConfiguration.positionTokenAccepter.safeTransferFrom(
            address(this),
            account,
            positionId,
            ratesCount,
            new bytes(0)
        );
        unacceptedBalances[positionId] -= ratesCount;
        _globalsConfiguration.totalStableAmount += amount;
        emit Accepted(
            account,
            positionId,
            position_,
            automation_,
            affiliationUserData_,
            ratesCount,
            amountWithFee,
            msg.value
        );
    }

    function _autoResolve(AutoResolve memory data) private {
        uint256 positionId = data.positionId;
        require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
        Position storage position_ = _positions[positionId];
        require(position_.data.endTime < block.timestamp, "Core: Position is active");
        for (uint256 i = 0; i < data.accounts.length; i++) {
            address account = data.accounts[i];
            Automation storage automation_ = _automations[positionId][account];
            require(automation_.resolve || automation_.fee > 0, "Core: Automation is not active");
            uint256 balanceOfAccepter = _immutableConfiguration.positionTokenAccepter.balanceOf(account, positionId);
            if (account == address(this)) balanceOfAccepter -= unacceptedBalances[positionId];
            if (
                !_immutableConfiguration.oracleAggregator.hasData(position_.data.oracle, position_.data.endTime) &&
                position_.data.endTime + _immutableConfiguration.oracleAggregator.CANCELATION_PERIOD() < block.timestamp
            ) {
                _cancel(positionId, account, balanceOfAccepter);
            } else {
                _execute(positionId, account, balanceOfAccepter, false);
            }
            payable(msg.sender).transfer(automation_.fee);
            delete _automations[positionId][account];
            _accountsAutomation[positionId].remove(account);
        }
        emit AutoResolved(data);
    }

    function _cancel(uint256 positionId, address account, uint256 balanceOfAccepter) private {
        require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
        Position storage position_ = _positions[positionId];
        require(
            !_immutableConfiguration.oracleAggregator.hasData(position_.data.oracle, position_.data.endTime) &&
                position_.data.endTime + _immutableConfiguration.oracleAggregator.CANCELATION_PERIOD() <
                block.timestamp,
            "Core: Position is active"
        );
        uint256 balanceOfCreator = _immutableConfiguration.positionTokenCreator.balanceOf(account, positionId);
        uint256 totalStableBalance = (balanceOfCreator * position_.minPositionAmountCreator) +
            (balanceOfAccepter * position_.minPositionAmountAccepter);
        _globalsConfiguration.totalStableAmount -= totalStableBalance;
        if (balanceOfCreator > 0)
            _immutableConfiguration.positionTokenCreator.burn(account, positionId, balanceOfCreator);
        if (balanceOfAccepter > 0)
            _immutableConfiguration.positionTokenAccepter.burn(account, positionId, balanceOfAccepter);
        if (totalStableBalance > 0) _immutableConfiguration.stable.transfer(account, totalStableBalance);
        emit Canceled(account, positionId, totalStableBalance);
    }

    function _create(
        CreateInputData memory data,
        bool autoResolve_,
        bool repeat,
        uint256 repeats,
        address account
    ) private returns (uint256) {
        require(data.ratesCount > 0, "Core: RatesCount is not positive");
        require(
            data.positionRate >= _limitsConfiguration.minPositionRate &&
                data.positionRate <= _limitsConfiguration.maxPositionRate,
            "Core: Position rate is invalid"
        );
        require(_oraclesWhitelist.contains(data.oracle), "Core: Oracle is not supported");
        IOracleTemplate oracle = IOracleTemplate(data.oracle);
        require(
            oracle.validateTimestamp(data.endTime) && data.endTime > block.timestamp,
            "Core: End timestamp is invalid"
        );
        _globalsConfiguration.positionsCount++;
        uint256 positionId = _globalsConfiguration.positionsCount;
        Position storage position_ = _positions[positionId];
        Automation storage automation_ = _automations[positionId][account];
        AffiliationUserData memory affiliationUserData_ = affiliationUserData(account);
        uint256 amount = data.ratesCount * _limitsConfiguration.minPositionAmount;
        position_.data = data;
        position_.creator = account;
        position_.fee = _feeConfiguration.protocolFee;
        position_.oraclePeriod = oracle.period();
        position_.minPositionAmountCreator = _limitsConfiguration.minPositionAmount;
        position_.minPositionAmountAccepter = (_limitsConfiguration.minPositionAmount * DIVIDER) / data.positionRate;
        position_.minted = data.ratesCount;
        _globalsConfiguration.totalStableAmount += amount;
        unacceptedBalances[positionId] = position_.minted;
        if (data.endTime > oracleTimes[data.oracle]) oracleTimes[data.oracle] = data.endTime;
        positionsExist[data.oracle][data.endTime] = true;
        uint256 amountWithFee = amount + _calculateStableFee(affiliationUserData_, amount, position_.fee);
        if (autoResolve_) {
            require(repeats == 0, "Core: Auto execute enabled");
            require(msg.value >= _feeConfiguration.resolveFee, "Core: Insufficient ETH value");
            automation_.fee = _feeConfiguration.resolveFee;
            automation_.resolve = true;
            _accountsAutomation[positionId].add(account);
        }
        if (repeats > 0) {
            require(repeats <= _limitsConfiguration.maxRepeats, "Core: Repeats value gt max");
            require(msg.value >= _feeConfiguration.repeatFee * (repeats + 1), "Core: Insufficient ETH value");
            position_.timeslotsAmount = (data.endTime - block.timestamp) / position_.oraclePeriod;
            if (position_.timeslotsAmount == 0) position_.timeslotsAmount = 1;
            automation_.fee = _feeConfiguration.repeatFee;
            automation_.repeatsCount = repeats;
            _accountsAutomation[positionId].add(account);
        }
        if (!repeat) _immutableConfiguration.stable.transferFrom(account, address(this), amountWithFee);
        _immutableConfiguration.positionTokenCreator.mint(account, positionId, position_.minted, new bytes(0));
        _immutableConfiguration.positionTokenAccepter.mint(address(this), positionId, position_.minted, new bytes(0));
        emit Created(account, positionId, position_, automation_, affiliationUserData_, amountWithFee, msg.value);
        return positionId;
    }

    function _execute(
        uint256 positionId,
        address account,
        uint256 balanceOfAccepter,
        bool repeat
    ) private returns (uint256) {
        require(positionId > 0 && positionId <= _globalsConfiguration.positionsCount, "Core: Invalid position id");
        Position storage position_ = _positions[positionId];
        require(position_.data.endTime <= block.timestamp, "Core: Position is active");
        require(
            _immutableConfiguration.oracleAggregator.hasData(position_.data.oracle, position_.data.endTime),
            "Core: Oracle data not found"
        );
        uint256 price = _immutableConfiguration.oracleAggregator.getData(position_.data.oracle, position_.data.endTime);
        uint256 balanceOfCreator = _immutableConfiguration.positionTokenCreator.balanceOf(account, positionId);
        uint256 minRateRemainingCreator = (unacceptedBalances[positionId] * position_.minPositionAmountCreator) /
            position_.minted;
        uint256 minRateRedeemedAccepter = ((position_.minted - unacceptedBalances[positionId]) *
            position_.minPositionAmountAccepter) / position_.minted;
        uint256 totalStableToWithdraw;
        if (price == position_.data.strike) {
            totalStableToWithdraw +=
                (balanceOfCreator * position_.minPositionAmountCreator) +
                (balanceOfAccepter * position_.minPositionAmountAccepter);
        } else if (
            (price > position_.data.strike && position_.data.position == PositionType.UP) ||
            (price < position_.data.strike && position_.data.position == PositionType.DOWN)
        ) {
            totalStableToWithdraw += (balanceOfCreator *
                (position_.minPositionAmountCreator + minRateRedeemedAccepter));
        } else {
            totalStableToWithdraw +=
                (balanceOfCreator * minRateRemainingCreator) +
                (balanceOfAccepter * (position_.minPositionAmountCreator + position_.minPositionAmountAccepter));
        }
        _globalsConfiguration.totalStableAmount -= totalStableToWithdraw;
        if (balanceOfCreator > 0)
            _immutableConfiguration.positionTokenCreator.burn(account, positionId, balanceOfCreator);
        if (balanceOfAccepter > 0)
            _immutableConfiguration.positionTokenAccepter.burn(account, positionId, balanceOfAccepter);
        if (totalStableToWithdraw > 0 && !repeat)
            _immutableConfiguration.stable.transfer(account, totalStableToWithdraw);
        emit Executed(account, positionId, _globalsConfiguration.totalStableAmount);
        return totalStableToWithdraw;
    }

    modifier notBlacklisted(address user) {
        require(!_immutableConfiguration.blacklist.blacklistContains(user), "Core: Address blacklisted");
        _;
    }

    modifier onlyKeeper() {
        require(_immutableConfiguration.oracleAggregator.keepersContains(msg.sender), "Core: Caller is not keeper");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IERC20Stable.sol";
import "./IPositionToken.sol";
import "./IFoxifyAffiliationFull.sol";
import "./IFoxifyBlacklist.sol";
import "./IOracleAggregator.sol";

interface ICore {
    enum PositionType {
        UP,
        DOWN
    }

    struct AffiliationUserData {
        uint256 activeId;
        uint256 team;
        uint256 discount;
        IFoxifyAffiliationFull.NFTData nftData;
    }

    struct Automation {
        uint256 fee;
        bool resolve;
        uint256 repeatsCount;
    }

    struct AutoResolve {
        uint256 positionId;
        address[] accounts;
    }

    struct CreateInputData {
        uint256 ratesCount;
        PositionType position;
        uint256 positionRate;
        address oracle;
        uint256 strike;
        uint256 endTime;
    }

    struct FeeConfiguration {
        address feeRecipient;
        uint256 resolveFee;
        uint256 repeatFee;
        uint256 protocolFee;
        uint256 flashloanFee;
    }

    struct GlobalsConfiguration {
        uint256 positionsCount;
        uint256 totalStableAmount;
    }

    struct ImmutableConfiguration {
        IFoxifyBlacklist blacklist;
        IFoxifyAffiliationFull affiliation;
        IPositionToken positionTokenCreator;
        IPositionToken positionTokenAccepter;
        IERC20Stable stable;
        IOracleAggregator oracleAggregator;
    }

    struct LimitsConfiguration {
        uint256 minPositionAmount;
        uint256 minPositionRate;
        uint256 maxPositionRate;
        uint256 maxRepeats;
    }

    struct NFTDiscountLevel {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
    }

    struct Position {
        CreateInputData data;
        address creator;
        uint256 oraclePeriod;
        uint256 timeslotsAmount;
        uint256 fee;
        uint256 minPositionAmountCreator;
        uint256 minPositionAmountAccepter;
        uint256 minted;
    }

    struct Permit {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function accountsAutomationCount(uint256 positionId) external view returns (uint256);
    function accountsAutomationContains(uint256 positionId, address wallet) external view returns (bool);
    function accountsAutomationList(
        uint256 positionId,
        uint256 offset,
        uint256 limit
    ) external view returns (address[] memory output);
    function affiliationUserData(address user) external view returns (AffiliationUserData memory output);
    function automations(uint256 positionId, address wallet) external view returns (Automation memory);
    function calculateStableFee(address user, uint256 amount, uint256 fee) external view returns (uint256);
    function discount() external view returns (NFTDiscountLevel memory);
    function DIVIDER() external view returns (uint256);
    function feeConfiguration() external view returns (FeeConfiguration memory);
    function globalsConfiguration() external view returns (GlobalsConfiguration memory);
    function immutableConfiguration() external view returns (ImmutableConfiguration memory);
    function limitsConfiguration() external view returns (LimitsConfiguration memory);
    function MAX_PROTOCOL_FEE() external view returns (uint256);
    function MAX_FLASHLOAN_FEE() external view returns (uint256);
    function oraclesCount() external view returns (uint256);
    function oraclesContains(address oracle) external view returns (bool);
    function oraclesList(uint256 offset, uint256 limit) external view returns (address[] memory output);
    function oraclesWhitelistCount() external view returns (uint256);
    function oraclesWhitelistContains(address oracle) external view returns (bool);
    function oraclesWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output);
    function oracleTimes(address) external view returns (uint256);
    function positionsExist(address, uint256) external view returns (bool);
    function positions(uint256 positionId) external view returns (Position memory);
    function unacceptedBalances(uint256) external view returns (uint256);

    event Accepted(
        address indexed accepter,
        uint256 indexed positionId,
        Position position,
        Automation automation,
        AffiliationUserData affiliation,
        uint256 ratesCount,
        uint256 stableAmount,
        uint256 ethAmount
    );
    event AutoResolved(AutoResolve data);
    event AutoResolveAndRepeated(uint256[] positionId);
    event Canceled(address indexed user, uint256 indexed positionId, uint256 amount);
    event Created(
        address indexed creator,
        uint256 indexed positionId,
        Position position,
        Automation automation,
        AffiliationUserData affiliation,
        uint256 stableAmount,
        uint256 ethAmount
    );
    event DiscountUpdated(NFTDiscountLevel discount_);
    event Executed(address indexed user, uint256 indexed positionId, uint256 amount);
    event FeeClaimed(uint256 amount);
    event FeeConfigurationUpdated(FeeConfiguration config);
    event Flashloan(
        address indexed caller,
        AffiliationUserData affiliation,
        address indexed receiver,
        uint256 amount,
        uint256 fee
    );
    event LimitsConfigurationUpdated(LimitsConfiguration config);
    event OraclesAdded(address[] oracles);
    event OraclesRemoved(address[] oracles);
    event OraclesWhitelistRemoved(address[] oracles);
    event Redeemed(address indexed user, uint256 indexed positionId, uint256 ratesCount, uint256 amount);
    event RedeemedWithFlashloan(
        address indexed user,
        uint256 indexed positionId,
        AffiliationUserData affiliation,
        uint256 ratesCount,
        uint256 amount,
        uint256 fee
    );

    function accept(uint256 positionId, uint256 ratesCount, bool autoResolve_) external payable returns (bool);
    function acceptWithPermit(
        uint256 positionId,
        uint256 ratesCount,
        bool autoResolve_,
        Permit memory permit
    ) external payable returns (bool);
    function autoResolve(AutoResolve[] memory data) external returns (bool);
    function autoResolveAndRepeat(uint256[] memory positionIds) external returns (bool);
    function cancel(uint256[] memory positionIds) external returns (bool);
    function claimFee(uint256 amount) external returns (bool);
    function create(
        CreateInputData memory data,
        bool autoResolve_,
        uint256 repeats
    ) external payable returns (uint256);
    function createWithPermit(
        CreateInputData memory data,
        bool autoResolve_,
        uint256 repeats,
        Permit memory permit
    ) external payable returns (uint256);
    function execute(uint256[] memory positionIds) external returns (bool);
    function flashloan(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
    function redeem(uint256 positionId, uint256 ratesCount) external returns (bool);
    function redeemWithFlashloan(
        uint256 positionId,
        uint256 ratesCount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC20Stable is IERC20, IERC20Permit {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyAffiliation {
    enum Level {
        UNKNOWN,
        BRONZE,
        SILVER,
        GOLD
    }

    struct BatchParams {
        address from;
        address to;
        uint256 id;
    }

    struct LevelsDistribution {
        uint256 bronze;
        uint256 silver;
        uint256 gold;
    }

    struct MergeLevelRates {
        uint256 bronzeToSilver;
        uint256 silverToGold;
    }

    struct MergeLevelPermissions {
        bool bronzeToSilver;
        bool silverToGold;
    }

    struct NFTData {
        Level level;
        bytes32 randomValue;
        uint256 timestamp;
    }

    struct Wave {
        bytes32 root;
        uint256 start;
        uint256 end;
        LevelsDistribution distribution;
    }

    function claimed(uint256, address) external view returns (bool);
    function currentWave() external view returns (uint256 id, Wave memory output);
    function dataList(uint256 offset, uint256 limit) external view returns (NFTData[] memory output);
    function exists(uint256 tokenId) external view returns (bool);
    function teamUsers(uint256 team, uint256 index) external view returns (address);
    function teamUsersContains(uint256 team, address user) external view returns (bool);
    function teamUsersLength(uint256 team) external view returns (uint256);
    function teamUsersList(uint256 offset, uint256 limit, uint256 team) external view returns (address[] memory output);
    function tokensCount() external view returns (uint256);
    function TOTAL_SHARE() external view returns (uint256);
    function teamsCount() external view returns (uint256);
    function usersActiveID(address) external view returns (uint256);
    function usersTeam(address) external view returns (uint256);
    function usersIDs(address user, uint256 index) external view returns (uint256);
    function usersIDsContains(address user, uint256 id) external view returns (bool);
    function usersIDsLength(address user) external view returns (uint256);
    function usersIDsList(address user, uint256 offset, uint256 limit) external view returns (uint256[] memory output);
    function usersTeamList(address[] memory users) external view returns (uint256[] memory output);
    function wavesList(uint256 offset, uint256 limit) external view returns (Wave[] memory output);

    event BaseURIUpdated(string uri);
    event Merged(uint256 indexed tokenId, uint256[] ids, Level from, Level to);
    event MergeLevelRatesUpdated(MergeLevelRates rates);
    event Migrated(address indexed migrator, uint256[] tokenIds);
    event MergeLevelPermissionsUpdated(MergeLevelPermissions permissions);
    event Minted(address indexed recipient, uint256 tokenId, NFTData data);
    event TeamsCountUpdated(uint256 count);
    event TeamSwitched(address indexed user, uint256 teamId);
    event UserActiveIDUpdated(address indexed user, uint256 indexed tokenId);
    event WaveScheduled(uint256 index, Wave wave);
    event WaveUnscheduled(Wave wave);

    function batchTransferFrom(BatchParams[] memory params) external returns (bool);
    function merge(uint256[] memory ids, Level from) external returns (bool);
    function mintRequest(bytes32[] calldata merkleProof, uint256 team) external returns (bool);
    function preMint(LevelsDistribution memory shares) external returns (bool);
    function scheduleWave(Wave memory wave) external returns (bool);
    function switchTeam(uint256 team) external returns (bool);
    function unscheduleWave(uint256 index) external returns (bool);
    function updateBaseURI(string memory uri) external returns (bool);
    function updateMergeLevelRates(MergeLevelRates memory rates) external returns (bool);
    function updateMergeLevelPermissions(MergeLevelPermissions memory permissions) external returns (bool);
    function updateTeamsCount(uint256 count) external returns (bool);
    function updateUserActiveID(uint256 tokenId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IFoxifyAffiliation.sol";

interface IFoxifyAffiliationFull is IFoxifyAffiliation {
    function data(uint256) external view returns (NFTData memory);
    function mergeLevelRates() external view returns (MergeLevelRates memory);
    function mergeLevelPermissions() external view returns (MergeLevelPermissions memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function waves(uint256) external view returns (Wave memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFoxifyBlacklist {
    function blacklist(uint256 index) external view returns (address);
    function blacklistCount() external view returns (uint256);
    function blacklistContains(address wallet) external view returns (bool);
    function blacklistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    event Blacklisted(address[] wallets);
    event Unblacklisted(address[] wallets);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IOptionsFlashCallback {
    function optionsFlashCallback(address account, uint256 amount, uint256 fee, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOracleAggregator {
    function CANCELATION_PERIOD() external view returns (uint256);
    function getData(address oracleId, uint256 timestamp) external view returns (uint256);
    function hasData(address oracleId, uint256 timestamp) external view returns (bool);
    function keepers(uint256 index) external view returns (address);
    function keepersCount() external view returns (uint256);
    function keepersContains(address keeper) external view returns (bool);
    function keepersList(uint256 offset, uint256 limit) external view returns (address[] memory output);
    function updater() external view returns (address);

    event KeepersAdded(address[] keepers);
    event KeepersRemoved(address[] keepers);
    event LogDataProvided(address indexed oracleId, uint256 indexed timestamp, uint256 data);
    event UpdaterUpdated(address indexed updater);

    function __callback(uint256 timestamp, uint256 data) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IOracleAggregator.sol";

interface IOracleTemplate {
    function decimals() external view returns (uint256);
    function oracleAggregator() external view returns (IOracleAggregator);
    function name() external view returns (string memory);
    function period() external view returns (uint256);
    function START() external view returns (uint256);
    function validateTimestamp(uint256 timestamp) external view returns (bool);

    event LogDataProvided(uint256 indexed _timestamp, uint256 indexed _data);

    function __callback(uint256 timestamp) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IPositionToken is IERC1155 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function burn(address account, uint256 id, uint256 amount) external;
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}