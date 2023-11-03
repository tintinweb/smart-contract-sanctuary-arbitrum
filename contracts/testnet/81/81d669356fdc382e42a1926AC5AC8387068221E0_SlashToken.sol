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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../handshake-drop-libs/TokenTransferer.sol";
import "../handshake-drop-types/interfaces/SlashTokenEvents.sol";
import "../handshake-drop-libs/NativeTransferer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "hardhat/console.sol";
import "../handshake-drop-libs/SubscriptionRegistry.sol";
/// @author 0xCocomastoras
/// @custom:version 1.0
/// @title SlashToken
/// @notice SlashToken is a simple, yet powerful tool to airdrop tokens and NFTs.

contract SlashToken is TokenTransferer, NativeTransferer, SlashTokenEvents, SubscriptionRegistry, ReentrancyGuard {

    constructor() ReentrancyGuard(){}

    /**
        @notice ERC-20 token airdrop with same, equal amount to all recipients
        @param recipients A list of addresses of the recipients
        @param amount Amount of tokens each recipient will be airdropped
        @param token Address of the token
    */
    function erc20AirdropEqualAmount(address[] calldata recipients, uint256 amount, address token) external payable nonReentrant {
        require(frozen == 0, "CF");
        require(denylist[msg.sender] == 0, 'UD');
        uint256 value = _getBaseFeeForWallet(); //Check if wallet is whitelisted with different value
        uint256 purchasedTxns = _getAvailableTxnsForWallet();
        uint recipientsLength = recipients.length;
        value = value == 0 ? baseFee : value;
        if (purchasedTxns == 0) {
            require(msg.value == value, "NVV");
        } else {
            _updateAvailableTxnsForWallet();
        }
        require(isInitialized != 0, 'NIY');
        require(recipientsLength <= 500, 'NVL');
        uint recipientsOffset;
        assembly {
            recipientsOffset := recipients.offset
        }
        _performMultiERC20Transfer(token, recipientsOffset, recipientsLength, amount);
        emit Erc20AirdropEqualAmount(msg.sender, token, recipientsLength, recipientsLength*amount);
    }

    /**
        @notice ERC-20 token airdrop with custom amount for each recipient
        @param recipients A list of addresses of the recipients
        @param amount A list of amounts of the tokens each recipient will be airdropped
        @param token Address of the token
        @param totalAmount The sum of all tokens to be airdropped
    */
    function erc20AirdropCustomAmount(address[] calldata recipients, uint256[] calldata amount, address token, uint256 totalAmount) external payable nonReentrant {
        require(frozen == 0, "CF");
        require(denylist[msg.sender] == 0, 'UD');
        uint256 value = _getBaseFeeForWallet(); //Check if wallet is whitelisted with different value
        uint256 purchasedTxns = _getAvailableTxnsForWallet();
        uint recipientsLength = recipients.length;
        value = value == 0 ? baseFee : value;
        if (purchasedTxns == 0) {
            require(msg.value == value, "NVV");
        } else {
            _updateAvailableTxnsForWallet();
        }
        require(isInitialized != 0, 'NIY');
        require(recipientsLength <= 500 && recipientsLength == amount.length, 'NVL');
        uint recipientsOffset;
        uint amountsOffset;

        assembly {
            recipientsOffset := recipients.offset
            amountsOffset := amount.offset
        }
        _performMultiERC20TransferCustom(token, recipientsOffset, recipientsLength, amountsOffset, totalAmount);
        emit Erc20AirdropCustomAmount(msg.sender, token, recipientsLength, totalAmount);
    }

    /**
        @notice Native currency airdrop with same, equal amount to all recipients
        @param recipients A list of addresses of the recipients
        @param amount Amount of tokens each recipient will be airdropped
    */
    function nativeAirdropEqualAmount(address[] calldata recipients, uint256 amount) external payable nonReentrant {
        require(frozen == 0, "CF");
        require(isInitialized != 0, 'NIY');
        require(denylist[msg.sender] == 0, 'UD');
        uint recipientsOffset;
        uint recipientsLength = recipients.length;
        uint256 value = _getBaseFeeForWallet();  //Check if wallet is whitelisted with different value
        uint256 purchasedTxns = _getAvailableTxnsForWallet();
        uint256 recipientsValue = amount * recipientsLength;
        value = value == 0 ? (baseFee + recipientsValue) : (value + recipientsValue);
        if (purchasedTxns == 0) {
            require(msg.value == value, "NVV");
        } else {
            require(msg.value == recipientsValue, 'NVV');
            _updateAvailableTxnsForWallet();
        }
        require(recipientsLength <= 500, 'NVL');
        assembly {
            recipientsOffset := recipients.offset
        }
        _performMultiNativeTransfer(recipientsOffset, recipientsLength, amount);
        emit NativeAirdropEqualAmount(msg.sender, recipientsLength, recipientsValue);
    }

    /**
        @notice Native currency airdrop with custom amount for each recipient
        @param recipients A list of addresses of the recipients
        @param amounts A list of amounts that each recipient will be airdropped
    */
    function nativeAirdropCustomAmount(address[] calldata recipients, uint256[] calldata amounts) external payable nonReentrant {
        require(frozen == 0, "CF");
        require(isInitialized != 0, 'NIY');
        require(denylist[msg.sender] == 0, 'UD');
        uint256 value = _getBaseFeeForWallet(); //Check if wallet is whitelisted with different value
        uint256 purchasedTxns = _getAvailableTxnsForWallet();
        uint recipientsOffset;
        uint amountsOffset;
        uint recipientsLength = recipients.length;
        require(recipientsLength <= 500 && recipientsLength == amounts.length, 'NVL');
        assembly {
            recipientsOffset := recipients.offset
            amountsOffset := amounts.offset
        }
        uint totalAmount = _performMultiNativeTransferCustom(recipientsOffset, recipientsLength, amountsOffset);
        value = value == 0 ? (baseFee + totalAmount) : (value + totalAmount);
        if (purchasedTxns == 0) {
            require(msg.value == value, "NVV");
        } else {
            require(msg.value == totalAmount, 'NVV');
            _updateAvailableTxnsForWallet();
        }
        emit NativeAirdropCustomAmount(msg.sender, recipientsLength, totalAmount);
    }

    /**
        @notice Basic Airdrop of Erc721 tokens without bundle
        @param recipients A list of addresses of the recipients
        @param ids A list of ids of the token each recipient will be airdropped
        @param token The address of the token
    */
    function erc721Airdrop(address[] calldata recipients, uint256[] calldata ids, address token) external payable nonReentrant {
        require(permitErc721 != 0, 'NEY');
        require(frozen == 0, "CF");
        require(isInitialized != 0, 'NIY');
        require(denylist[msg.sender] == 0, 'UD');
        uint256 value = _getBaseFeeForWallet();
        value = value == 0 ? baseFee : value;
        uint256 purchasedTxns = _getAvailableTxnsForWallet();
        uint recipientsLength = recipients.length;
        if (purchasedTxns == 0) {
            require(msg.value == value, "NVV");
        } else {
            _updateAvailableTxnsForWallet();
        }
        require(recipientsLength <= 500 && recipientsLength == ids.length, 'NVL');
        uint recipientsOffset;
        uint idsOffset;
        assembly {
            recipientsOffset := recipients.offset
            idsOffset := ids.offset
        }
        _performMultiERC721Transfer(token, msg.sender, recipientsOffset, recipientsLength, idsOffset);
        emit Erc721Airdrop(msg.sender, token, recipientsLength);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


contract ManagerActions{
    constructor(){}
    address owner;
    address feeSink;
    uint256 public frozen;
    uint256 public permitErc721 = 0;

    mapping(address => uint256) denylist;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet deniedAddresses;

    /**
        @notice Admin freezes / unfreezes contracts
        @param value_ 0 = unfreeze, any other value = freeze
    */
    function freezeContract(uint256 value_) external {
        require(msg.sender == owner, 'NVS');
        frozen = value_;
    }

    /**
        @notice Admin permits/freezes erv721Airdrops
        @param value_ 0 = freeze, any other value = permit
    */
    function handleErc721Flag(uint256 value_) external {
        require(msg.sender == owner, 'NVS');
        permitErc721 = value_;
    }

    /**
        @notice Admin updates fee sink address
        @param feeSink_ The new fee sink address
    */
    function updateFeeSink(address feeSink_) external {
        require(msg.sender == owner, 'NVS');
        feeSink = feeSink_;
    }

    /**
        @notice Admin claims contract fees
    */
    function claimFees() external {
        address owner_ = owner;
        assembly {
            if iszero(eq(caller(), owner_)) {
                revert(0,0)
            }
            if iszero(call(gas(), sload(feeSink.slot), selfbalance(), 0, 0, 0, 0)) {
                revert(0,0)
            }
        }
    }

    function addToDenylist(address[] memory list) external {
        require(msg.sender == owner, 'NVS');
        uint len = list.length;
        for(uint i = 0; i < len;) {
            if (!deniedAddresses.contains(list[i])) {
                deniedAddresses.add(list[i]);
            }
            unchecked {
                denylist[list[i]] = 1;
                i++;
            }
        }
    }

    function removeFromDenylist(address[] memory list) external {
        require(msg.sender == owner, 'NVS');
        uint len = list.length;
        for(uint i = 0; i < len;) {
            if (deniedAddresses.contains(list[i])) {
                deniedAddresses.remove(list[i]);
            }
            unchecked {
                denylist[list[i]] = 0;
                i++;
            }
        }
    }

    function getDenylist() external view returns (address[] memory) {
        require(msg.sender == owner, 'NVS');
        return deniedAddresses.values();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract NativeTransferer {
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /**
     * @dev Internal function to transfer native tokens from a given originator
     *      to a multiple recipients
     *
     * @param offset     Calldata offset of the recipients of the transfer.
     * @param length     Calldata length of the recipients of the transfer.
     * @param amount     The amount to transfer.
     */
    function _performMultiNativeTransfer(uint256 offset, uint256 length, uint256 amount) internal {
        assembly {
             for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                 let to := calldataload(add(offset, mul(i, 0x20)))
                 if iszero( call(
                    GAS_STIPEND_NO_STORAGE_WRITES,
                    to,
                    amount,
                    0,
                    0,
                    0,
                    0
                 )) {
                     revert(0,0)
                 }
             }
        }
    }

    /**
     * @dev Internal function to transfer native tokens from a given originator
     *      to a multiple recipients
     *
     * @param recipientsOffset            Calldata offset of the recipients of the transfer.
     * @param length            Calldata length of the recipients of the transfer.
     * @param amountsOffset     Calldata offset of the amounts to transfer
     */
    function _performMultiNativeTransferCustom(uint256 recipientsOffset, uint256 length, uint256 amountsOffset) internal returns (uint256 totalAmount){
        assembly {
             for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                 let to := calldataload(add(recipientsOffset, mul(i, 0x20)))
                 let amount := calldataload(add(amountsOffset, mul(i, 0x20)))
                 totalAmount := add(totalAmount, amount)
                 if iszero( call(
                    GAS_STIPEND_NO_STORAGE_WRITES,
                    to,
                    amount,
                    0,
                    0,
                    0,
                    0
                 )) {
                     revert(0,0)
                 }
             }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../handshake-drop-types/interfaces/SlashTokenRegistryEvents.sol";
import "../handshake-drop-types/interfaces/PremiumSubscriptionRegistryEvents.sol";
import "./ManagerActions.sol";


contract SubscriptionRegistry is SlashTokenRegistryEvents, PremiumSubscriptionRegistryEvents, ManagerActions {
    // @dev user's adddress to custom base fee for no bundle purchases
    mapping (address => uint256) baseFeeWhitelisted;
    // @dev user address to total available txns to use
    mapping(address => uint256) public userToTxns;

    uint256[] availableTxnsBundles;
    uint256[] txnsBundlesToPrice;

    uint256 isInitialized;
    uint256 public baseFee;
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet bundleUsers;


    function initialize(address admin_, address feeSink_, uint256 baseFeeCostInWei, uint256[] memory availableTxnsBundles_, uint256[] memory txnsBundlesToPrice_ ) external {
        require(isInitialized == 0, 'AI');
        require(availableTxnsBundles_.length == txnsBundlesToPrice_.length, 'NVD');
        owner = admin_;
        feeSink = feeSink_;
        availableTxnsBundles = availableTxnsBundles_;
        txnsBundlesToPrice = txnsBundlesToPrice_;
        isInitialized = 1;
        baseFee = baseFeeCostInWei;
    }

    constructor(){}

    /**
        @notice User buys a bundle of txns
        @param bundleIndex The index of the bundle array
        @param quantity The number of bundles that the user wants to buy
    */
    function buyTxnsBundle(uint256 bundleIndex, uint256 quantity) external payable {
        require(frozen == 0, "CF");
        require(msg.value == txnsBundlesToPrice[bundleIndex] * quantity, 'NVV');
        require(denylist[msg.sender] == 0, 'UD');
        require(quantity != 0, 'NVA');
        if(!bundleUsers.contains(msg.sender)) {
            bundleUsers.add(msg.sender);
        }
        uint256 total;
        unchecked {
            total = availableTxnsBundles[bundleIndex] * quantity;
            userToTxns[msg.sender] += total;
        }
        emit TxnsBundleBought(msg.sender, msg.value, total);
    }

    /**
        @notice Admin sets promo fee for wallet instead of default base fee
        @param wallet User's wallet address
        @param amountInWei New cost per txns
    */
    function setBaseFeeForWallet(address wallet, uint256 amountInWei) external {
        require(amountInWei < baseFee, "NVV");
        require(msg.sender == owner, 'NVS');
        baseFeeWhitelisted[wallet] = amountInWei;
        emit WalletBaseFeeSet(wallet, amountInWei);
    }

    /**
        @notice Admin resets promo fee for wallet. Default base fee applies
        @param wallet User's wallet address
    */
    function resetBaseFeeForWallet(address wallet) external {
        require(msg.sender == owner, 'NVS');
        delete baseFeeWhitelisted[wallet];
        emit WalletBaseFeeReset(wallet);
    }

    /**
        @notice Admin adds txns to a user
        @param wallets A list of user's wallet address
        @param txns A list of txns to be added
    */
    function addTxnsToWallets(address[] memory wallets, uint256[] memory txns) external {
        require(msg.sender == owner, 'NVS');
        require(wallets.length == txns.length, "NVL");
        uint len = wallets.length;
        for(uint i =0; i<len;){
            unchecked {
                userToTxns[wallets[i]] += txns[i];
                i++;
            }
        }
        emit TxnsAdded(wallets, txns);
    }

    /**
        @notice Admin sets the new base fee for all txns
        @param baseFee_ New base fee
    */
    function setNewBaseFee(uint256 baseFee_) external {
        require(msg.sender == owner, 'NVS');
        baseFee = baseFee_;
    }

    /**
        @notice Admin sets the new available txnsBundles and prices
        @param availableTxnsBundles_ New available bundles
        @param txnsBundlesToPrice_ New price per bundles
    */
    function updateBundles(uint256[] memory availableTxnsBundles_, uint256[] memory txnsBundlesToPrice_ ) external {
        require(msg.sender == owner, 'NVS');
        require(availableTxnsBundles_.length == txnsBundlesToPrice_.length, 'NVD');
        availableTxnsBundles = availableTxnsBundles_;
        txnsBundlesToPrice = txnsBundlesToPrice_;
        emit BundlesUpdated(msg.sender, availableTxnsBundles_, txnsBundlesToPrice_);
    }

    /**
        @notice External view function that returns active bundle offers
    */
    function getBundles() external view returns (uint256[] memory AvailableBundles, uint256[] memory BundlesPrices) {
        AvailableBundles = availableTxnsBundles;
        BundlesPrices = txnsBundlesToPrice;
    }

    /**
        @notice External view function that returns the custom base fee for wallet
    */
    function getBaseFeeForWallet() external view returns (uint256) {
        return baseFeeWhitelisted[msg.sender];
    }

    /**
        @notice External view function that returns the available txns for wallet
    */
    function getAvailableTxnsForWallet() external view returns (uint256) {
        return userToTxns[msg.sender];
    }

    /**
        @notice External view function that returns all the users that have bought a bundle
    */
    function getUsersThatBoughtBundles() external view returns (address[] memory Users) {
        require(msg.sender == owner, 'NVS');
        Users = bundleUsers.values();
    }

    /**
        @notice Internal view function that returns the custom base fee for wallet
    */
    function _getBaseFeeForWallet() internal view returns (uint256) {
        return baseFeeWhitelisted[msg.sender];
    }

    /**
        @notice Internal view function that returns the available txns for wallet
    */
    function _updateAvailableTxnsForWallet() internal {
        unchecked {
            --userToTxns[msg.sender];
        }
    }

    /**
        @notice Internal view function that returns the available txns for wallet
    */
    function _getAvailableTxnsForWallet() internal view returns (uint256) {
        return userToTxns[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Safe ERC20 ,ERC721 multi transfer library that gracefully handles missing return values.
/// @author Cocomastoras
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ERC20s and ERC721s, this implementation won't check that a token has code,
/// responsibility is delegated to the caller.

contract TokenTransferer {
    error TransferFromFailed();

    /**
     * @dev Internal function to transfer ERC20 tokens from a given originator
     *      to a multiple recipients. Sufficient approvals must be set on the
     *      contract performing the transfer.
     *
     * @param token                The ERC20 token to transfer.
     * @param recipientsOffset     Calldata offset of the recipients of the transfer.
     * @param length               Calldata length of the recipients of the transfer.
     * @param amount               The amount to transfer.
     */
    function _performMultiERC20Transfer(address token, uint256 recipientsOffset, uint256 length, uint256 amount) internal{
        /// @solidity memory-safe-assembly
        assembly {
            let total := mul(amount, length)
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, total) // Store the `amount` argument.
            mstore(0x40, address()) // Store the `to` argument.
            mstore(0x2c, shl(96, caller())) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(
                        eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                    )
                )
            {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, amount) // Store the `amount` argument.
            for { let i := 0 } lt(i, length) { i := add(i, 1) } {
                let to := calldataload(add(recipientsOffset, mul(i, 0x20)))
                mstore(0x2c, shl(96, to)) // Store the `to` argument.
                mstore(0x0c, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
                // Perform the transfer, reverting upon failure.
                if iszero(
                    and( // The arguments of `and` are evaluated from right to left.
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /**
        * @dev Internal function to transfer ERC20 tokens from a given originator
        *      to multiple recipients. Sufficient approvals must be set on the
        *      contract performing the transfer.
        * @param token            The ERC20 token to transfer.
        * @param recipientsOffset Offset of the recipients of the transfer.
        * @param recipientsLength Length of the recipients of the transfer.
        * @param amountsOffset    Offset of the amounts to transfer.
        * @param totalAmount      The totalAmount to transfer
    */
    function _performMultiERC20TransferCustom(address token, uint256 recipientsOffset, uint256 recipientsLength, uint256 amountsOffset, uint256 totalAmount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, totalAmount) // Store the `amount` argument.
            mstore(0x40, address()) // Store the `to` argument.
            mstore(0x2c, shl(96, caller())) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000)
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(
                        eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                    )
                )
            {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            let sumAmount := 0
            for { let i := 0 } lt(i, recipientsLength) { i := add(i, 1) } {
                let to := calldataload(add(recipientsOffset, mul(i, 0x20)))
                let amount := calldataload(add(amountsOffset, mul(i, 0x20)))
                sumAmount := add(sumAmount, amount)
                mstore(0x40, amount) // Store the `amount` argument.
                mstore(0x2c, shl(96, to)) // Store the `to` argument.
                mstore(0x0c, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
                // Perform the transfer, reverting upon failure.
                if iszero(
                    and( // The arguments of `and` are evaluated from right to left.
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            if iszero(eq(totalAmount, sumAmount)) {
                revert(0,0)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /**
     * @dev Internal function to transfer batch of ERC721 tokens from a given
     *      originator to multiple recipients. Sufficient approvals must be set on
     *      the contract performing the transfer. Note that this function does
     *      not check whether the receiver can accept the ERC721 token (i.e. it
     *      does not use `safeTransferFrom`).
     *
     * @param token             The ERC721 token to transfer.
     * @param from              The originator of the transfer.
     * @param recipientsOffset  The offset of recipients of the transfer.
     * @param recipientsLength  The length of tokens to transfer.
     * @param idsOffset         The offset of tokenIds to transfer.
     */
    function _performMultiERC721Transfer(
        address token,
        address from,
        uint256 recipientsOffset,
        uint256 recipientsLength,
        uint256 idsOffset
    ) internal {
        // Utilize assembly to perform an optimized ERC721 token transfer.
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            for { let i := 0 } lt(i, recipientsLength) { i := add(i, 1) } {
                let to := calldataload(add(recipientsOffset, mul(i, 0x20)))
                let identifier := calldataload(add(idsOffset, mul(i, 0x20)))
                mstore(0x60, identifier) // Store the `identifier` argument.
                mstore(0x40, to) // Store the `to` argument.
                mstore(0x2c, shl(96, from)) // Store the `from` argument.
                mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
                // Perform the transfer, reverting upon failure.
                if iszero(
                    and( // The arguments of `and` are evaluated from right to left.
                        iszero(returndatasize()), // Returned error.
                        call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x00)
                    )
                ) {
                    mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface PremiumSubscriptionRegistryEvents {
    event WalletBaseFeeSet(address indexed Wallet, uint256 BaseFeeInWei);
    event WalletBaseFeeReset(address indexed Wallet);
    event TxnsAdded(address[] Wallet, uint256[] Txns);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface SlashTokenEvents {
    event Erc20AirdropEqualAmount(address indexed From, address indexed Token,uint256 RecipientsLength, uint256 TotalAmount);
    event Erc20AirdropCustomAmount(address indexed From, address indexed Token, uint256 RecipientsLength, uint256 TotalAmount);
    event NativeAirdropEqualAmount(address indexed From,uint256 RecipientsLength, uint256 TotalAmount);
    event NativeAirdropCustomAmount(address indexed From, uint256 RecipientsLength, uint256 TotalAmount);
    event Erc721Airdrop(address indexed From, address indexed Token, uint256 RecipientsLength);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface SlashTokenRegistryEvents {
    event TxnsBundleBought(address indexed Buyer, uint256 Amount, uint256 Txns);
    event BundlesUpdated(address indexed Operator, uint256[] BundlesAmounts, uint256[] BundlesPrices);
}