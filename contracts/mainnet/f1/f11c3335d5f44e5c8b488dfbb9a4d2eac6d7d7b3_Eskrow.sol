/**
 *Submitted for verification at Arbiscan.io on 2023-10-01
*/

// SPDX-License-Identifier: GD
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
    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
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
    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
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
    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
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
    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
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
    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
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
    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
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
    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
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
    function values(
        AddressSet storage set
    ) internal view returns (address[] memory) {
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
    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
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
    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
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
    function values(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: contracts\EskrowHelpers\EskrowStructs.sol

pragma solidity ^0.8.19;

abstract contract EskrowStructs {
    struct Escrow {
        bytes32 escrowId;
        address payable party1;
        address payable party2;
        address token1;
        address token2;
        uint256 token1RequiredQty;
        uint256 token1DepositedQty;
        uint256 token2RequiredQty;
        uint256 token2DepositedQty;
        uint expiryEpoch;
        uint settleFromEpoch;
        uint16 feeInPpt;
        bool isParty1LockRefund;
        bool isParty2LockRefund;
        bool hasParty1Withdrawn;
        bool hasParty2Withdrawn;
        string description;
    }

    struct EscrowExt {
        // struct Escrow
        bytes32 escrowId;
        address payable party1;
        address payable party2;
        address token1;
        address token2;
        uint256 token1RequiredQty;
        uint256 token1DepositedQty;
        uint256 token2RequiredQty;
        uint256 token2DepositedQty;
        uint expiryEpoch;
        uint settleFromEpoch;
        uint16 feeInPpt;
        bool isParty1LockRefund;
        bool isParty2LockRefund;
        bool hasParty1Withdrawn;
        bool hasParty2Withdrawn;
        string description;
        // -----
        // Extension
        uint256 token1FeeInQty;
        uint256 token2FeeInQty;
        bool isReadyToSettle;
        bool isExpired;
        bool isFullyWithdrawn;
    }
}

// File: contracts\EskrowHelpers\EskrowEvents.sol

pragma solidity ^0.8.19;

abstract contract EskrowEvents {
    // ==============================
    // // EVENTS
    // event Checkpoint( string message );
    // event Checkpoint( uint256 value );
    // event Checkpoint( address value );

    event EscrowCreated(
        bytes32 indexed _escrowId,
        address indexed _party1,
        address indexed _party2
    );
    event EscrowRemoved(bytes32 indexed _escrowId, address _party);
    event EscrowFunded(
        bytes32 indexed _escrowId,
        address indexed _party,
        address indexed _token,
        uint256 _qty
    );
    event EscrowRefunded(
        bytes32 indexed _escrowId,
        address indexed _party,
        address indexed _token,
        uint256 _quantity
    );
    event EscrowSettled(
        bytes32 indexed _escrowId,
        address indexed _party,
        address _token,
        uint256 _quantity
    );

    event EscrowIsFullyFunded(
        bytes32 indexed _escrowId,
        address indexed _party1,
        address indexed _party2
    );

    event EscrowError(
        address indexed _origin,
        bytes32 indexed _escrowId,
        string indexed _method,
        uint32 _code
    );
}

// File: contracts\EskrowHelpers\IEskrowSub.sol

pragma solidity ^0.8.19;

/**
 * @dev Interface of the EskroSub contract.
 */
interface IEskrowSub {
    function toEscrowExt(
        EskrowStructs.Escrow memory _escrowId,
        uint256 _blockTime
    ) external pure returns (EskrowStructs.EscrowExt memory);

    function create(
        EskrowStructs.Escrow memory _escrowId,
        address _msgSender
    ) external returns (EskrowStructs.Escrow memory);

    function validateRemove(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrowId
    ) external returns (bool success);

    function validateDeposit(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrowId,
        address _token,
        uint256 _quantity
    )
        external
        returns (
            uint32 code,
            uint256 token1Qty,
            uint256 token2Qty,
            bool isFullyDeposited
        );

    function validateRefund(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrowId,
        bool _isByForce
    ) external returns (uint32 code, address token, address bene, uint256 qty);

    function validateSettle(
        address _msgInitiator,
        EskrowStructs.Escrow memory _escrowId
    ) external returns (uint32 code, address token, address bene, uint256 qty);
}

// File: contracts\Eskrow.sol

pragma solidity ^0.8.19;

contract Eskrow is EskrowEvents, Ownable {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // ==============================
    // STATE VARIABLES
    //
    string contractName;
    mapping(address => uint256) internal treasuryByToken;
    EnumerableSet.Bytes32Set internal escrowIds;
    mapping(bytes32 => EskrowStructs.Escrow) internal escrows;
    mapping(address => EnumerableSet.Bytes32Set) internal escrowIdsByParty;
    IEskrowSub internal eskrowSub;
    bool internal configIsPaused;
    address public configFeeAddress;
    uint16 public configFeeInPptPct;

    // ==============================
    // FUNCTIONS

    // Initializations
    constructor() {
        contractName = "Eskrow v1.5.3";

        configIsPaused = false;
        configFeeAddress = address(0x0);
        configFeeInPptPct = 0; // 1 ppt == (1/1000 of 1%)
        eskrowSub = IEskrowSub(payable(address(0x0)));
    }

    // Note: Users should NEVER send ETHER (or ANY token) to contract.
    receive() external payable virtual {}

    //----------
    function _breakOnSystemPause() internal view {
        require(
            !configIsPaused,
            "===> HARD EXIT. Contract paused. Please refer to community."
        );

        require(
            address(eskrowSub) != address(0x0),
            "===> Please set EskrowSub adress."
        );
    }

    function _breakOnInvalidEscrowId(bytes32 _escrowId) internal view {
        require(escrowIds.contains(_escrowId), "==> Invalid EscrowId.");
    }

    // ===================
    // ADMIN CONFIG SETTINGS !!! OWNER ONLY
    function setConfigIsPaused(bool _isPause) external onlyOwner {
        configIsPaused = _isPause;
    }

    function setConfigFeeAddress(address _wallet) external onlyOwner {
        configFeeAddress = _wallet;
    }

    function setConfigFeeInPptPct(uint16 _feeInPptPct) external onlyOwner {
        configFeeInPptPct = _feeInPptPct;
    }

    function setEskrowSub(address payable _implementation) external onlyOwner {
        if (_implementation != address(0)) {
            eskrowSub = IEskrowSub(_implementation);
        }
    }

    // ==============================
    // ==============================
    // Function Group: Create Escrow
    function create(
        address payable _party1,
        address payable _party2,
        address _token1,
        uint256 _token1RequiredQty,
        address _token2,
        uint256 _token2RequiredQty,
        bool _isParty1LockRefund,
        bool _isParty2LockRefund,
        uint _expiryEpoch,
        uint _settleFromEpoch,
        string memory _description
    ) external virtual returns (EskrowStructs.Escrow memory escrow) {
        _breakOnSystemPause();

        escrow = EskrowStructs.Escrow({
            escrowId: 0, // Set by eskrowSub.create()
            party1: _party1,
            party2: _party2,
            token1: _token1,
            token2: _token2,
            token1RequiredQty: _token1RequiredQty,
            token1DepositedQty: 0,
            token2RequiredQty: _token2RequiredQty,
            token2DepositedQty: 0,
            feeInPpt: configFeeInPptPct,
            expiryEpoch: _expiryEpoch,
            settleFromEpoch: _settleFromEpoch,
            isParty1LockRefund: _isParty1LockRefund,
            isParty2LockRefund: _isParty2LockRefund,
            hasParty1Withdrawn: false,
            hasParty2Withdrawn: false,
            description: _description
        });

        escrow = eskrowSub.create(escrow, _msgSender());
        if ((escrow.escrowId != 0) && !escrowIds.contains(escrow.escrowId)) {
            // Add the new escrow into storage
            escrows[escrow.escrowId] = escrow;
            escrowIds.add(escrow.escrowId);
            escrowIdsByParty[_party1].add(escrow.escrowId);
            escrowIdsByParty[_party2].add(escrow.escrowId);

            emit EscrowCreated(escrow.escrowId, _party1, _party2);
        }
        return escrow;
    }

    // ==============================
    // Function Group: Deposit ERC20 tokens
    function depositErc20(
        bytes32 _escrowId,
        address _token,
        uint256 _quantity
    ) external virtual returns (uint32 _code) {
        _breakOnSystemPause();
        _breakOnInvalidEscrowId(_escrowId);

        (
            uint32 code,
            uint256 token1Qty,
            uint256 token2Qty,
            bool isFullyDeposited
        ) = eskrowSub.validateDeposit(
                _msgSender(),
                escrows[_escrowId],
                _token,
                _quantity
            );

        if (code == 0) {
            if (
                IERC20(_token).transferFrom(
                    _msgSender(),
                    address(this),
                    _quantity
                )
            ) {
                escrows[_escrowId].token1DepositedQty = token1Qty;
                escrows[_escrowId].token2DepositedQty = token2Qty;
                treasuryByToken[_token] += _quantity;

                emit EscrowFunded(_escrowId, _msgSender(), _token, _quantity);

                // Emit event if isFullyDeposited (is not the same as isReadyForSettle)
                if (isFullyDeposited) {
                    emit EscrowIsFullyFunded(
                        _escrowId,
                        escrows[_escrowId].party1,
                        escrows[_escrowId].party2
                    );
                }

                return 0;
            }
            return 1;
        }
        return code;
    }

    // ==============================
    // Function Group: Refund escrow
    function refund(bytes32 _escrowId) external virtual returns (uint32 _code) {
        _breakOnSystemPause();
        _breakOnInvalidEscrowId(_escrowId);

        (uint32 code, address token, address bene, uint256 qty) = eskrowSub
            .validateRefund(_msgSender(), escrows[_escrowId], false);

        if (code == 0) {
            if (IERC20(token).transfer(bene, qty)) {
                if (bene == escrows[_escrowId].party1) {
                    treasuryByToken[token] -= escrows[_escrowId]
                        .token1DepositedQty;
                    escrows[_escrowId].token1DepositedQty = 0;
                }

                if (bene == escrows[_escrowId].party2) {
                    treasuryByToken[token] -= escrows[_escrowId]
                        .token2DepositedQty;
                    escrows[_escrowId].token2DepositedQty = 0;
                }

                emit EscrowRefunded(_escrowId, bene, token, qty);
                return 0;
            } else {
                return 1;
            }
        }
        return code;
    }

    // ==============================
    // Function Group: Settle
    function settle(bytes32 _escrowId) external virtual returns (uint32 _code) {
        _breakOnSystemPause();
        _breakOnInvalidEscrowId(_escrowId);

        (uint32 code, address token, address bene, uint256 qty) = eskrowSub
            .validateSettle(_msgSender(), escrows[_escrowId]);

        if (code == 0) {
            if (IERC20(token).transfer(bene, qty)) {
                if (bene == escrows[_escrowId].party1) {
                    escrows[_escrowId].hasParty1Withdrawn = true;
                    treasuryByToken[token] -= escrows[_escrowId]
                        .token2DepositedQty;
                }
                if (bene == escrows[_escrowId].party2) {
                    escrows[_escrowId].hasParty2Withdrawn = true;
                    treasuryByToken[token] -= escrows[_escrowId]
                        .token1DepositedQty;
                }

                emit EscrowSettled(_escrowId, bene, token, qty);

                return 0;
            } else {
                return 1;
            }
        }
        return code;
    }

    // ==============================
    // Function Group: Remove Escrow
    function remove(bytes32 _escrowId) external virtual returns (bool success) {
        _breakOnSystemPause();
        _breakOnInvalidEscrowId(_escrowId);

        if (eskrowSub.validateRemove(_msgSender(), escrows[_escrowId])) {
            address party1 = escrows[_escrowId].party1;
            address party2 = escrows[_escrowId].party2;

            escrowIds.remove(_escrowId);
            delete escrows[_escrowId];

            _removeBaseEscrowIdsByParty(_escrowId, party1);
            _removeBaseEscrowIdsByParty(_escrowId, party2);

            emit EscrowRemoved(_escrowId, party1);
            emit EscrowRemoved(_escrowId, party2);
            return true;
        }
        return false;
    }

    function _removeBaseEscrowIdsByParty(
        bytes32 _escrowId,
        address _party
    ) private {
        escrowIdsByParty[_party].remove(_escrowId);
        if (escrowIdsByParty[_party].length() == 0) {
            delete escrowIdsByParty[_party];
        }
    }

    // ==============================
    // ADMIN FUNCTION: Withdraw earned fees (and expired escrows)
    function adminWithdrawAccumulatedFees(
        address _token
    ) external virtual onlyOwner returns (uint256 fees) {
        require(configFeeAddress != address(0), "===> Invalid Fee Address");

        fees =
            IERC20(_token).balanceOf(address(this)) -
            treasuryByToken[_token];
        if (IERC20(_token).transfer(configFeeAddress, fees)) {
            return fees;
        }
        return 0;
    }

    // Do NOT send Ether to contract. Escrow Funding is via the DepositErc20().
    // But, just in case, this allow admin to withdraw any ETH accidentally sent here.
    function adminWithdrawEther(uint256 _gwei) external virtual onlyOwner {
        require(
            configFeeAddress != address(0),
            "===> Invalid Withdrawal Address"
        );
        payable(configFeeAddress).transfer(_gwei);
    }

    // ==============================
    // Function Group: Getters
    //
    //
    function getVersion()
        external
        view
        virtual
        returns (string memory version)
    {
        return contractName;
    }

    //
    function getEscrowExt(
        bytes32 _escrowId
    ) external view virtual returns (EskrowStructs.EscrowExt memory) {
        return eskrowSub.toEscrowExt(escrows[_escrowId], block.timestamp);
    }

    //
    function getEscrowIdsByParty(
        address _party
    ) external view virtual returns (bytes32[] memory) {
        return escrowIdsByParty[_party].values();
    }

    //
    function getAccumulatedFees(
        address _token
    ) external virtual returns (uint256 fees) {
        fees =
            IERC20(_token).balanceOf(address(this)) -
            treasuryByToken[_token];
        return fees;
    }
}