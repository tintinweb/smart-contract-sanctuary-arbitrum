// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

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
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
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
            set._positions[value] = set._values.length;
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
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
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
pragma solidity ^0.8.4;

library Client {
  struct EVMTokenAmount {
    address token; // token address on the local chain
    uint256 amount;
  }  

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source
    uint64 sourceChainSelector;
    bytes sender; // abi.decode(sender) if coming from an EVM chain
    bytes data; // payload sent in original message
    EVMTokenAmount[] tokenAmounts;
  }

  // If extraArgs is empty bytes, the default is 
  // 200k gas limit and strict = false. 
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload 
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // extraArgs will evolve to support new features
  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit; // ATTENTION!!! MAX GAS LIMIT 4M FOR ALPHA TESTING
    bool strict; // See strict sequencing details below. 
  }
  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Client} from "./Client.sol";

/// @notice Application contracts that intend to receive messages from
/// the router should implement this interface.
interface IAny2EVMMessageReceiver {

  /// @notice Router calls this to deliver a message.
  /// If this reverts, any token transfers also revert. The message
  /// will move to a FAILED state and become available for manual execution
  /// as a retry. Fees already paid are NOT currently refunded (may change). 
  /// @param message CCIP Message
  /// @dev Note ensure you check the msg.sender is the router
  function ccipReceive(Client.Any2EVMMessage calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Client library above
import {Client} from "./Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destinationChainSelector);
  /// @dev Sender is not whitelisted
  error SenderNotAllowed(address sender);
  error InsufficientFeeTokenAmount();
  /// @dev Sent msg.value with a non-empty feeToken
  error InvalidMsgValue();

  /// @notice Checks if the given chain selector is supported for sending/receiving.
  /// @param chainSelector The chain to check
  /// @return supported is true if it is supported, false if not
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain selector.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chain selector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns execution fee for the specified message
  /// delivery to destination chain
  /// @dev returns 0 fee on invalid message.
  function getFee(uint64 destinationChainSelector, Client.EVM2AnyMessage memory message)
  external
  view
  returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain selector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  function ccipSend(uint64 destinationChainSelector, Client.EVM2AnyMessage calldata message)
  external
  payable
  returns (bytes32 messageId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./IAny2EVMMessageReceiver.sol";
import "./IRouterClient.sol";
import "./Proxy.sol";
import "./NFTBridgeData.sol";



contract NFTBridge is NFTBridgeData {

    
    error   TokenAlreadyBridged();
    error   TokenNotBridged();
    error   TokenNotOwned();
    error   InvalidRouter();
    error   InvalidSender();
    error   NoBaseURI();
    error   FeeNotEnough();

 
    fallback(bytes calldata b) external returns (bytes memory) {
        address dest = ds().bridge_admin;
        (bool success, bytes memory returnedData) = dest.delegatecall(b);
        if (!success) {
            assembly {
                revert(add(returnedData,32),mload(returnedData))
            }
        }
        return returnedData;
    }

    constructor(
        address _router,
        uint256 _creationGasLimit,
        uint256 _transferGasLimit,
        address _goldenIndividual,
        address _goldenBaseUri,
        address _bridge_admin
    )  {
        ds().ccip_router            = IRouterClient(_router);
        ds().creationGasLimit       = _creationGasLimit;
        ds().transferGasLimit       = _transferGasLimit;
        ds().goldenIndividualNFT    = _goldenIndividual;
        ds().goldenBaseUriNFT       = _goldenBaseUri;
        ds().bridge_admin           = _bridge_admin;
        ds().owner                  = msg.sender;
    }

    // Home Chain Functions

    function createBaseURIToken(
        address _nft, 
        string memory _baseURI,
        string memory _suffix,
        uint256 _offset,
        bool _baseZero,
        uint256 destinationChain
    ) external payable returns (bytes32 messageId){
        if(ds().localTokenInfo[_nft].owner != address(0)) revert TokenAlreadyBridged();
        if (msg.sender != Ownable(_nft).owner())
            revert TokenNotOwned();
        if(bytes(_baseURI).length == 0) revert NoBaseURI();
        (
            uint64 destinationChainSelector,
            Client.EVM2AnyMessage memory message,
            uint256 fee,
            TokenStorageData memory td
        ) = _ecBaseURI(_nft,destinationChain,_baseURI,_suffix, _offset, _baseZero);
        require(msg.value >= fee,"NFTBridge : Insufficient value sent");
        ds().localTokenInfo[_nft] = td;
        ds().tokenInfo[block.chainid][_nft] = td;
        messageId = ds().ccip_router.ccipSend{value: fee}(destinationChainSelector, message);
    }

    function createIndividualURIBasedToken(address _nft, uint256 destinationChain) external payable returns (bytes32 messageId){
        require(ds().localTokenInfo[_nft].owner == address(0),"NFTBridge : token already exists");
        require(msg.sender == Ownable(_nft).owner(),"NFTBridge : you do not own this token");
        (
            uint64 destinationChainSelector,
            Client.EVM2AnyMessage memory message,
            uint256 fee,
            TokenStorageData memory td
        ) =  _ecIndividualURI(_nft,destinationChain);
        require(msg.value >= fee,"NFTBridge : Insufficient value sent");        
        ds().localTokenInfo[_nft] = td;
        ds().tokenInfo[block.chainid][_nft] = td;
        messageId = ds().ccip_router.ccipSend{value: fee}(destinationChainSelector, message);
    }

    function transferMyToken(address _nft, uint256 tokenId, uint256 destinationChain) external payable returns (bytes32 messageId){
        Client.EVM2AnyMessage memory message;
        uint256 fee;
        uint64 destinationChainSelector;
        if(IERC721(_nft).ownerOf(tokenId) != msg.sender) revert TokenNotOwned();
        TokenStorageData memory tsd = ds().localTokenInfo[_nft];
        if(tsd.owner == address(0)) revert TokenNotBridged();
        if (tsd.homeChain == block.chainid) {
            IERC721(_nft).transferFrom(msg.sender,address(this),tokenId);
        } else {
            NamedNFT(_nft).burn(tokenId);
        }
        (destinationChainSelector,message,fee) = _ecTT(_nft,tokenId,destinationChain);
        if(msg.value < fee) revert FeeNotEnough();
        messageId = ds().ccip_router.ccipSend{value: fee}(destinationChainSelector, message);
    }

    function estimateCostForCreateBaseURIToken(address _nft,uint256 destinationChain, string memory _baseURI, string memory _suffix, uint256 _offset, bool _baseZero) external  view returns (uint256 cost) {
        (,,cost,) = _ecBaseURI(_nft,destinationChain,_baseURI, _suffix, _offset, _baseZero);
    }

    function estimateCostForCreateIndividualURIBasedToken(address _nft, uint256  _destinationChain) external view returns (uint256 cost) {
        (,,cost,) = _ecIndividualURI(_nft, _destinationChain);
    }
    function estimateCostForTransferMyToken(address _nft, uint256 tokenId, uint256 destinationChain) external view returns (uint256 cost) {
       (,,cost) = _ecTT(_nft,tokenId,destinationChain);
    }

    // internals

    function _ecTT(
        address _nft, 
        uint256 tokenId, 
        uint256 destinationChain
    ) internal view returns (
        uint64 destinationChainSelector, 
        Client.EVM2AnyMessage memory message,
        uint256 fee
    ) {
        TokenStorageData memory td = ds().localTokenInfo[_nft];
        if(td.owner == address(0)) revert TokenNotBridged();
        if (!td.usesBaseURI) {
            message = _getTokenIdDataWithURI(_nft,td.nft,tokenId, td.homeChain);
        } else {
            message = _getTokenIdDataWithoutURI(td.nft,tokenId, td.homeChain);
        }
        destinationChainSelector = ds().chainToSelector[destinationChain];
        fee = ds().ccip_router.getFee(destinationChainSelector, message);
    }

    function _ecIndividualURI(
        address _nft, 
        uint256 destinationChain
    ) internal view returns (
        uint64 destinationChainSelector, 
        Client.EVM2AnyMessage memory message,
        uint256 fee,
        TokenStorageData memory td
    ) {
        td = TokenStorageData(
            1,
            Ownable(_nft).owner(),
            _nft,
            NamedNFT(_nft).name(),
            NamedNFT(_nft).symbol(),
            false,
            0,
            false,
            0,
            "",
            "",
            block.chainid,
            _nft
        );
        message = _getCreationData(td);
        destinationChainSelector = ds().chainToSelector[destinationChain];
        fee = ds().ccip_router.getFee(destinationChainSelector, message);
    }

    function _ecBaseURI(
        address _nft, 
        uint256 destinationChain,
        string memory _baseURI,
        string memory _suffix,
        uint256 _offset,
        bool _baseZero

    )internal view returns (
        uint64 destinationChainSelector, 
        Client.EVM2AnyMessage memory message,
        uint256 fee,
        TokenStorageData memory td
    ) {
        td = TokenStorageData(
            2,
            Ownable(_nft).owner(),
            _nft,
            NamedNFT(_nft).name(),
            NamedNFT(_nft).symbol(),
            true,
            _offset,
            _baseZero,
            NamedNFT(_nft).totalSupply(),
            _baseURI,
            _suffix,
            block.chainid,
            _nft
        );
        message = _getCreationData(td);
        destinationChainSelector = ds().chainToSelector[destinationChain];
        fee = ds().ccip_router.getFee(destinationChainSelector, message);
    }

    // utility

    function _getTokenIdDataWithURI(address _nft,address homeNFT, uint256 tokenId, uint256 _homeChain) internal view returns (Client.EVM2AnyMessage memory message) {
        bytes memory data = abi.encode(TokenDataWithURI(
            3,
            homeNFT,
            msg.sender,
            tokenId,
            _homeChain,
            NamedNFT(_nft).tokenURI(tokenId)
        ));
        return craftMessage(
            abi.encode(address(this)),
            data,
            ds().transferGasLimit,
            address(0)
        );

    }

    function _getTokenIdDataWithoutURI(address _nft,uint256 tokenId, uint256 _homeChain) internal view returns (Client.EVM2AnyMessage memory message) {
        bytes memory data = abi.encode(TokenData(
            4,
            _nft,
            msg.sender,
            tokenId,
            _homeChain
        ));
        return craftMessage(
            abi.encode(address(this)),
            data,
            ds().transferGasLimit,
            address(0)
        );
    }


    function _getCreationData(TokenStorageData memory td) internal view returns (Client.EVM2AnyMessage memory message) {
        bytes memory data = abi.encode(td);
        return craftMessage(
            abi.encode(address(this)),
            data,
            ds().creationGasLimit,
            address(0)
        );
    }

    function craftMessage(
        bytes memory receiver,
        bytes memory data,
        uint256 _gasLimit,
        address feeToken
    ) internal pure returns (Client.EVM2AnyMessage memory message) {
        Client.EVMExtraArgsV1 memory _data = Client.EVMExtraArgsV1(_gasLimit,false); // not strict
        bytes memory gas = Client._argsToBytes(_data);
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](0);
        message = Client.EVM2AnyMessage({
            receiver: receiver,
            data: data,
            tokenAmounts: tokenAmounts,
            extraArgs: gas,
            feeToken: feeToken
        });
    }

    // Receiving Chain Functions

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external {
        if (msg.sender != address(ds().ccip_router)) revert InvalidRouter();
        address sender = abi.decode(message.sender,(address));
        if (sender != address(this)) revert InvalidSender();
        uint256 modeswitch = uint256(bytes32(message.data[0:32]));
        if       ( (modeswitch == 1) || (modeswitch == 2)){
            TokenStorageData memory td = abi.decode(message.data,(TokenStorageData));
            if (block.chainid != td.homeChain) return;
            if (ds().tokenInfo[td.homeChain][td.nft].nft != address(0)) return;
            if  (modeswitch == 1) {
                td.localNFT = address(new Proxy(ds().goldenIndividualNFT));
            } else {
                td.localNFT = address(new Proxy(ds().goldenBaseUriNFT));
            }
            NamedNFT(td.localNFT).init(td);
            ds().tokenInfo[td.homeChain][td.nft] = td;
            ds().localTokenInfo[td.localNFT] = td;
        } else if (modeswitch == 3) {
            TokenDataWithURI memory td = abi.decode(message.data,(TokenDataWithURI));
            TokenStorageData memory tsd = ds().tokenInfo[td.homeChain][td.nft]; 
            if (block.chainid != td.homeChain) {                 
                if (tsd.nft == address(0)) return;
                NamedNFT n = NamedNFT(tsd.localNFT);
                n.mintWithURI(td.owner,td.TokenId,td.URI);
            } else {
                IERC721(tsd.nft).transferFrom(address(this),td.owner,td.TokenId);
            }
        } else if (modeswitch == 4) { // transfer tokenID only
            TokenData memory td = abi.decode(message.data,(TokenData));
            TokenStorageData memory tsd = ds().tokenInfo[td.homeChain][td.nft]; 
            if (block.chainid != td.homeChain) {
                if (ds().tokenInfo[td.homeChain][td.nft].nft == address(0)) return;
                NamedNFT n = NamedNFT(tsd.localNFT);
                n.mint(td.owner,td.TokenId);
            } else {
                IERC721(tsd.nft).transferFrom(address(this),td.owner,td.TokenId);
            }
        }
    }


    // Admin

    function supportsInterface(
        bytes4 interfaceId)
    public pure   returns (bool) {
        return 
                interfaceId == type(IAny2EVMMessageReceiver).interfaceId || 
                interfaceId == type(IERC165).interfaceId;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IRouterClient.sol";


struct BaseURIData {
    address     owner;
    address     nft;
    string      name;
    string      symbol;
    string      baseURI;
    uint256     offset;
    string      postFix;
    uint256     homeChain;
} 

struct TokenURIData {
    address     owner;
    address     nft;
    string      name;
    string      symbol;
    uint256     homeChain;
} 

struct TokenStorageData {
    uint256     recordType; // 1 (uri) / 2 (baseURI)
    address     owner;
    address     nft;
    string      name;
    string      symbol;
    bool        usesBaseURI;
    uint256     offset;
    bool        baseZero;
    uint256     max;
    string      baseURI;
    string      postFix;
    uint256     homeChain;
    address     localNFT;
}

struct TokenData {
    uint256     recordType; // 4
    address     nft;
    address     owner;
    uint256     TokenId;
    uint256     homeChain;
}

struct TokenDataWithURI {
    uint256     recordType; // 3
    address     nft;
    address     owner;
    uint256     TokenId;
    uint256     homeChain;
    string      URI;
}

interface NamedNFT {
    function init(TokenStorageData calldata) external;
    function name() external view returns (string memory);
    function symbol()  external view returns (string memory);
    function tokenURI(uint256) external view returns (string memory);
    function mint(address owner, uint256 tokenId) external;
    function mintWithURI(address owner, uint256 tokenId, string calldata uri) external;
    function burn(uint256) external;
    function totalSupply() external view returns (uint256);
}

struct NFTBridgeDataInstance {
    IRouterClient           ccip_router;
    uint256                 creationGasLimit;
    uint256                 transferGasLimit;

    address                 goldenIndividualNFT;
    address                 goldenBaseUriNFT;

    address                 owner;
    address                 bridge_admin;

    mapping(uint256 =>
        mapping (address    => TokenStorageData))   tokenInfo;
    mapping(address         => TokenStorageData)    localTokenInfo;
    mapping(uint256         => uint64)              chainToSelector;

    EnumerableSet.AddressSet                        localTokens;                  

}

contract NFTBridgeData {

    bytes32 constant DATA_STORAGE_POSITION = keccak256("DATA_STORAGE_POSITION");

    function ds() internal pure returns (NFTBridgeDataInstance storage dss) {
        bytes32 position = DATA_STORAGE_POSITION;
        assembly {
            dss.slot := position
        }
    }

 

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Proxy {

    event ContractInitialised(address);

    address immutable public destination;

    constructor(address _destination) {
        // console.log("TheProxy constructor");
        
        destination  = _destination;
        // console.log("proxy installed: dest/ctr_name/lookup", dest, contract_name, lookup);
        emit ContractInitialised(_destination);
    }

    // fallback(bytes calldata b) external  returns (bytes memory)  {           // For debugging when we want to access "lookup"
    fallback(bytes calldata b) external payable returns (bytes memory)  {
        // console.log("proxy start sender/lookup:", msg.sender, lookup);
        
        // console.log("proxy delegate:", dest);
        (bool success, bytes memory returnedData) = destination.delegatecall(b);
        if (!success) {
            assembly {
                revert(add(returnedData,32),mload(returnedData))
            }
        }
        return returnedData; 
    }
  
}