/**
 *Submitted for verification at Arbiscan on 2023-02-26
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/structs/[email protected]

// License-Identifier: MIT
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


// File ethereum/contracts/Fund.sol

// License-Identifier: GPL-3.0        

pragma solidity ^0.8.9;
//import "./Collateral.sol";

/// @title Takaturn Fund
/// @author Mohammed Haddouti
/// @notice This is used to operate the Takaturn fund
/// @dev v1.3 (pretest phase 3)
/// @custom:experimental This is still in testing phase.
contract Fund is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum States {
        InitializingFund, // Time before the first cycle has started
        AcceptingContributions, // Triggers at the start of a cycle
        ChoosingBeneficiary, // Contributions are closed, beneficiary is chosen, people default etc.
        CycleOngoing, // Time after beneficiary is chosen, up till the start of the next cycle
        FundClosed // Triggers at the end of the last contribution period, no state changes after this
    }

    /// Insufficient balance for transfer. Needed `required` but only
    /// `available` available.
    /// @param available balance available.
    /// @param required requested amount to transfer.
    error InsufficientBalance(uint256 available, uint256 required);

    event OnContractDeployed(); // Emits when contract is deployed
    event OnStateChanged(States newState); // Emits when state has updated
    event OnPaidContribution(address indexed payer, uint indexed currentCycle, uint indexed amount); // Emits when participant pays the contribution
    event OnBeneficiarySelected(address indexed beneficiary); // Emits when beneficiary is selected for this cycle
    event OnFundWithdrawn(address indexed claimant, uint indexed amount); // Emits when a chosen beneficiary claims their fund
    event OnParticipantDefaulted(address indexed defaulter); // Emits when a participant didn't pay this cycle's contribution
    event OnParticipantUndefaulted(address indexed undefaulter); // Emits when a participant was a defaulter before but started paying on time again for this cycle
    event OnDefaulterExpelled(address indexed expellant); // Emits when a defaulter can't compensate with the collateral
    event OnTotalParticipantsUpdated(uint indexed newLength); // Emits when the total participants lengths has changed from its initial value

    uint public version; // The version of the contract

    Collateral immutable public collateral; // Instance of the collateral
    //address immutable public collateralAddress; // The address of the collateral
    IERC20 immutable public stableToken; // Instance of the stable token

    States public currentState = States.InitializingFund; // Variable to keep track of the different States

    uint public totalAmountOfCycles; // Amount of cycles that this fund will have
    uint public totalParticipants; // Total amount of starting participants
    uint immutable public cycleTime;// = 2592000; // time for a single cycle in seconds, default is 30 days
    uint immutable public contributionAmount;// = 100; // amount in stable token currency, 6 decimals
    uint immutable public contributionPeriod;// = 259200; // time for participants to contribute this cycle

    mapping(address => bool) public participantsTracker; // Mapping to keep track of who's a participant or not
    mapping(address => bool) public beneficiariesTracker; // Mapping to keep track of who's a beneficiary or not
    mapping(address => bool) public paidThisCycle; // Mapping to keep track of who paid for this cycle
    mapping(address => bool) public autoPayEnabled; // Wheter to attempt to automate payments at the end of the contribution period
    mapping(address => uint) public beneficiariesPool; // Mapping to keep track on how much each beneficiary can claim
    EnumerableSet.AddressSet private participants; // Those who have not been beneficiaries yet and have not defaulted this cycle
    EnumerableSet.AddressSet private beneficiaries; // Those who have been beneficiaries and have not defaulted this cycle
    EnumerableSet.AddressSet private defaulters; // Both participants and beneficiaries who have defaulted this cycle

    //address[] public participants; // those who have not been beneficiaries yet and have not defaulted this cycle
    //address[] public beneficiaries; // those who have been beneficiaries and have not defaulted this cycle
    //address[] public defaulters; // both participants and beneficiaries who have defaulted this cycle
    address[] public beneficiariesOrder; // The correct order of who gets to be next beneficiary, determined by collateral contract
    uint public expelledParticipants; // Total amount of participants that have been expelled so far

    uint public currentCycle = 0; // Index of current cycle
    uint public fundStart = 0; // Timestamp of the start of the fund
    uint public fundEnd = 0; // Timestamp of the end of the fund
    //uint public contributionEnd; // Timestamp of the end of the contribution period

    address public lastBeneficiary; // The last selected beneficiary, updates with every cycle

    /// @notice Constructor Function
    /// @dev Network is Arbitrum and Stable Token is USDC
    /// @param _stableTokenAddress Address of the stable token contract
    /// @param _participants An array of all participants
    /// @param _cycleTime The time it takes to finish 1 cycle
    /// @param _contributionAmount The amount participants need to pay per cycle, amount in whole dollars
    /// @param _contributionPeriod The amount of time participants have to pay the contribution of a cycle, must be less than cycle time
    constructor(
        //address _collateralAddress, 
        address _stableTokenAddress,
        //address _ownerAddress,
        address[] memory _participants,
        uint _cycleTime, 
        uint _contributionAmount, 
        uint _contributionPeriod//,
        //uint _randomNumber
    ) {
        /*require(_collateralAddress != address(0), "Collateral is zero address");
        require(_stableTokenAddress != address(0), "StableToken is zero address");
        require(_contributionPeriod < _cycleTime, "Contribution period is less than cycle time");
        require(_contributionAmount > 0, "Contribution amount is zero");*/
        collateral = Collateral(msg.sender);
        stableToken = IERC20(_stableTokenAddress);

        transferOwnership(collateral.owner());
        
        // Set and track participants
        for (uint i = 0; i < _participants.length; i++) {
            EnumerableSet.add(participants, _participants[i]);
            participantsTracker[_participants[i]] = true;
        }
        beneficiariesOrder = _participants;

        // Sets some cycle-related parameters
        totalParticipants = _participants.length;
        totalAmountOfCycles = _participants.length;
        cycleTime = _cycleTime;
        contributionAmount = _contributionAmount * 10 ** 6; // Convert to 6 decimals
        contributionPeriod = _contributionPeriod;

        // Sets the version of the contract
        version = 1;

        emit OnContractDeployed();

        // Starts the first cycle
        _startNewCycle();
        
        // Set timestamp of deployment, which will be used to determine cycle times
        // We do this after starting the first cycle to make sure the first cycle starts smoothly
        fundStart = block.timestamp;
    }

    /// @notice returns the beneficiaries order as an array
    function getBeneficiariesOrder() view external returns (address[] memory) {
        return beneficiariesOrder;
    }

    /// @notice function to enable/disable autopay
    function toggleAutoPay() external {
        require(participantsTracker[msg.sender]);
        autoPayEnabled[msg.sender] = !autoPayEnabled[msg.sender];
    }

    /// @notice updates the state according to the input and makes sure the state can't be changed if the fund is closed. Also emits an event that this happened
    /// @param newState The new state of the fund
    function _setState(States newState) internal {
        require (currentState != States.FundClosed, "Fund's closed");
        currentState = newState;
        emit OnStateChanged(newState);
    }

    /// @notice Called internally to move a defaulter in the beneficiariesOrder to the end, so that people who have paid get chosen first as beneficiary
    /// @param _beneficiary The defaulter that could have been beneficiary
    function _removeBeneficiaryFromOrder(address _beneficiary) internal {
        address[] memory arrayToCheck = beneficiariesOrder;
        address[] memory newArray = new address[](arrayToCheck.length - 1);
        uint j = 0;
        for (uint i = 0; i < arrayToCheck.length; i++) {
            address b = arrayToCheck[i];
            if (b != _beneficiary) {
                newArray[j] = b;
                j++;
            }
        }

        beneficiariesOrder = newArray;
    }

    /// @notice starts a new cycle manually called by the owner. Only the first cycle starts automatically upon deploy
    function startNewCycle() external onlyOwner {
        _startNewCycle();
    }

    /// @notice This starts the new cycle and can only be called internally. Used upon deploy
    function _startNewCycle() internal {
        // currentCycle is 0 when this is called for the first time
        require(block.timestamp > cycleTime * currentCycle + fundStart, "Too early to start new cycle");
        require(currentState == States.InitializingFund || currentState == States.CycleOngoing, "Wrong state");
        
        currentCycle++;
        uint length = beneficiariesOrder.length;
        for (uint i = 0; i < length; i++) {
            paidThisCycle[beneficiariesOrder[i]] = false;
        }

        _setState(States.AcceptingContributions);
    }

    /// @notice called by the owner to close the fund for emergency reasons.
    function closeFund() external onlyOwner {
        //require (!(currentCycle < totalAmountOfCycles), "Not all cycles have happened yet");
        _closeFund();
    }

    /// @notice Internal function for close fund which is used by _startNewCycle & _chooseBeneficiary to cover some edge-cases
    function _closeFund() internal {
        fundEnd = block.timestamp;
        _setState(States.FundClosed);
        collateral.releaseCollateral();
    }

    /// @notice Must be called at the end of the contribution period after the time has passed by the owner
    function closeFundingPeriod() external onlyOwner {
        // Current cycle minus 1 because currentCycle is the cycle no. Not the cycle index
        require(block.timestamp > cycleTime * (currentCycle - 1) + fundStart + contributionPeriod, "There's still time to contribute");
        require(currentState == States.AcceptingContributions);

        // Before closing, we attempt to make the autopayers pay
        address[] memory autoPayers = beneficiariesOrder;
        uint amount = contributionAmount;
        for (uint i = 0; i < autoPayers.length; i++) {
            if (autoPayEnabled[autoPayers[i]] && 
                !paidThisCycle[autoPayers[i]] &&
                amount <= stableToken.allowance(autoPayers[i], address(this)) &&
                amount <= stableToken.balanceOf(autoPayers[i])) {
                _payContribution(autoPayers[i], autoPayers[i]);
            }
        }

        // Only then start choosing beneficiary
        _setState(States.ChoosingBeneficiary);

        // We must check who hasn't paid and default them, check all participants based on beneficiariesOrder
        // To maintain the order and to properly push defaulters to the back based on that same order
        // And we make sure that existing defaulters are ignored
        address[] memory currentParticipants = beneficiariesOrder;
        for (uint i = 0; i < currentParticipants.length; i++) {
            address p = currentParticipants[i];
            if (paidThisCycle[p]) {
                // check where to restore the defaulter to, participants or beneficiaries
                if (beneficiariesTracker[p]) {
                    EnumerableSet.add(beneficiaries, p);
                }
                else {
                    EnumerableSet.add(participants, p);
                }

                if (EnumerableSet.remove(defaulters, p)) {
                    emit OnParticipantUndefaulted(p);
                }
            }
            else if (!EnumerableSet.contains(defaulters, p)){
                _defaultParticipant(p);
            }
        }

        // Once we decided who defaulted and who paid, we can select the beneficiary for this cycle
        _selectBeneficiary();

        if (!(currentCycle < totalAmountOfCycles)) { // If all cycles have passed, and the last cycle's time has passed, close the fund
            _closeFund();
            return;
        }
    }

    /// @notice Default the participant/beneficiary by checking the mapping first, then remove them from the appropriate array
    /// @param defaulter The participant to default
    function _defaultParticipant(address defaulter) internal {
        // Try removing from participants first
        bool success = EnumerableSet.remove(participants, defaulter);

        // If that fails, we try removing from beneficiaries
        if (!success) {
            success = EnumerableSet.remove(beneficiaries, defaulter);
        }

        require (success, "Could not remove defaulter");
        EnumerableSet.add(defaulters, defaulter);

        emit OnParticipantDefaulted(defaulter);
    }

    /// @notice This is the function participants call to pay the contribution
    function payContribution() external {
        require(currentState == States.AcceptingContributions);
        require(participantsTracker[msg.sender], "not a participant");
        require(!paidThisCycle[msg.sender], "Already paid for this cycle");
        _payContribution(msg.sender, msg.sender);
    }

    /// @notice This function is here to give the possibility to pay using a different wallet
    /// @param participant the address the msg.sender is paying for, the address must be part of the fund
    function payContributionOnBehalfOf(address participant) external {
        require(currentState == States.AcceptingContributions);
        require(participantsTracker[participant], "not a participant");
        require(!paidThisCycle[participant], "Already paid for this cycle");
        _payContribution(msg.sender, participant);
    }

    /// Function to pay the actual contribution for the cycle
    /// @param payer the address that's paying
    /// @param participant the (participant) address that's being paid for
    function _payContribution(address payer, address participant) internal {
        // Get the amount and do the actual transfer, this will only succeed if the sender approved this contract address beforehand
        uint amount = contributionAmount;
        
        bool success = stableToken.transferFrom(payer, address(this), amount);
        require(success, "Contribution failed, did you approve stable token contract?");

        // Finish up, set that the participant paid for this cycle and emit an event that it's been done
        paidThisCycle[participant] = true;
        emit OnPaidContribution(participant, currentCycle, amount);
    }

    /// @notice Fallback function, if the internal call fails somehow and the state gets stuck, allow owner to call the function again manually
    /// @dev This shouldn't happen, but is here in case there's an edge-case we didn't take into account
    function selectBeneficiary() external onlyOwner {
        require(currentState == States.ChoosingBeneficiary);
        _selectBeneficiary();
    }

    /// @notice The beneficiary will be selected here based on the beneficiariesOrder array.
    /// @notice It will loop through the array and choose the first in line to be eligible to be beneficiary.
    function _selectBeneficiary() internal {
        // check if there are any participants left, else use the defaulters
        address selectedBeneficiary = address(0);
        address[] memory arrayToCheck = beneficiariesOrder;
        uint beneficiaryIndex = 0;
        for (uint i = 0; i < arrayToCheck.length; i++) { 
            address b = arrayToCheck[i];
            if (!beneficiariesTracker[b]) {
                selectedBeneficiary = b;
                beneficiaryIndex = i;
                break;
            }
        }

        // If the defaulter didn't pay this cycle, we move the first elligible beneficiary forward and everyone in between forward
        if (!paidThisCycle[selectedBeneficiary]) {
            // Find the index of the beneficiary to move to the end
            for (uint i = beneficiaryIndex; i < arrayToCheck.length; i++) {
                address b = arrayToCheck[i];
                // Find the first eligible beneficiary
                if (paidThisCycle[b]) {
                    selectedBeneficiary = b;
                    address[] memory newOrder = beneficiariesOrder;
                    // Move each defaulter between current beneficiary and new beneficiary 1 position forward
                    for (uint j = beneficiaryIndex; j < i; j++) {
                        newOrder[j + 1] = arrayToCheck[j];
                    }
                    // Move new beneficiary to original beneficiary's position
                    newOrder[beneficiaryIndex] = selectedBeneficiary;
                    beneficiariesOrder = newOrder;
                    break;
                }
            }
        }

        // Request contribution from the collateral for those who haven't paid this cycle
        if (EnumerableSet.length(defaulters) > 0) {

            
            address[] memory expellants = collateral.requestContribution(selectedBeneficiary, EnumerableSet.values(defaulters));
            //require(success, "Could not request defaulters contribution");

            for (uint i = 0; i < expellants.length; i++) {
                if (expellants[i] == address(0)) {
                    continue;
                }
                _expelDefaulter(expellants[i]);
            }
            //require(success, "Could not request defaulters contribution");
        }
        
        // Remove participant from participants set..
        if (EnumerableSet.remove(participants, selectedBeneficiary)) {
            // ..Then add them to the benificiaries set
            EnumerableSet.add(beneficiaries, selectedBeneficiary);
        } // If this if-statement fails, this means we're dealing with a graced defaulter

        // Update the mapping to track who's been beneficiary
        beneficiariesTracker[selectedBeneficiary] = true;

        // Get the amount of participants that paid this cycle, and add that amount to the beneficiary's pool
        uint paidCount = 0;
        address[] memory allParticipants = beneficiariesOrder; // Use beneficiariesOrder here because it contains all active participants in a single array
        for (uint i = 0; i < allParticipants.length; i++) {
            if (paidThisCycle[allParticipants[i]]) {
                paidCount++;
            }
        }
 
        // Award the beneficiary with the pool and update the lastBeneficiary
        beneficiariesPool[selectedBeneficiary] = contributionAmount * paidCount;
        lastBeneficiary = selectedBeneficiary;
        
        emit OnBeneficiarySelected(selectedBeneficiary);
        _setState(States.CycleOngoing);
    }

    /// @notice Called by the beneficiary to withdraw the fund
    /// @dev This follows the pull-over-push pattern.
    function withdrawFund() external {
        //require(beneficiariesPool[msg.sender] > 0, "No funds to withdraw");
        require(currentState == States.FundClosed || 
                paidThisCycle[msg.sender], "You must pay your cycle before withdrawing");

        if (beneficiariesPool[msg.sender] > 0) {
            // Get the amount this beneficiary can withdraw
            uint transferAmount = beneficiariesPool[msg.sender];
            uint contractBalance = stableToken.balanceOf(address(this));
            if (contractBalance < transferAmount) {
                revert InsufficientBalance({
                    available: contractBalance,
                    required: transferAmount
                });
            }
            else {
                beneficiariesPool[msg.sender] = 0;
                stableToken.transfer(msg.sender, transferAmount); // Untrusted
            }
            emit OnFundWithdrawn(msg.sender, transferAmount);
        }

        try collateral.withdrawReimbursement(msg.sender) {} catch {}
    }

    /// @notice called internally to expel a participant. It should not be possible to expel non-defaulters, so those arrays are not checked.
    /// @param expellant The address of the defaulter that will be expelled
    function _expelDefaulter(address expellant) internal {
        //require(msg.sender == address(collateral), "Caller is not collateral");
        require (participantsTracker[expellant], "Expellant not part of fund");
  
          // Expellants should only be in the defauters set so no need to touch the other sets
        require(EnumerableSet.remove(defaulters, expellant), "Expellant not found");

        // Remove expellant from beneficiaries order
        // Remove expellants from participants tracker and emit that they've been expelled
        // Update the defaulters array
        _removeBeneficiaryFromOrder(expellant);

        participantsTracker[expellant] = false;
        emit OnDefaulterExpelled(expellant);

        // If the participant is expelled before becoming beneficiary, we lose a cycle, the one which this expellant is becoming beneficiary
        if (!beneficiariesTracker[expellant]) {
            totalAmountOfCycles--;
        }

        // Lastly, lower the amount of participants with the amount expelled
        uint newLength = totalParticipants - 1;
        totalParticipants = newLength;
        expelledParticipants++;
        
        emit OnTotalParticipantsUpdated(newLength);
    }

    // @notice allow the owner to empty the fund if there's any excess fund left after 180 days,
    //         this with the assumption that beneficiaries can't claim it themselves due to losing their keys for example,
    //         and prevent the fund to be stuck in limbo
    function emptyFundAfterEnd() external onlyOwner {
        require(currentState == States.FundClosed /*&& block.timestamp + 180 days TODO: uncomment this when done testing > fundEnd */, "Can't empty yet");

        uint balance = stableToken.balanceOf(address(this));
        if (balance > 0) {
            stableToken.transfer(msg.sender, balance);
        }
        
        // TODO: add colllateral function here to call
    }

    // @notice function to get the cycle information in one go
    function getFundSummary() external view returns (States, uint, address) {
        return (currentState, currentCycle, lastBeneficiary);
    }

    // @notice function to get cycle information of a specific participant
    // @param user the user to get the info from
    function getParticipantSummary(address participant) external view returns (uint, bool, bool, bool) {
        return (beneficiariesPool[participant], beneficiariesTracker[participant], paidThisCycle[participant], autoPayEnabled[participant]);
    }

}


// File ethereum/contracts/Collateral.sol

// License-Identifier: GPL-3.0

pragma solidity ^0.8.9;
//import "hardhat/console.sol";

/// @title Takaturn Collateral
/// @author Aisha EL Allam
/// @notice This is used to operate the Takaturn fund
/// @dev v1.4 (prebeta)
/// @custom:experimental This is still in testing phase.
contract CollateralFactory {
    address payable[] public deployedCollaterals;

    function createCollateral(
        uint totalParticipants,
        uint cycleTime,
        uint contributionAmount,
        uint contributionPeriod,
        uint collateralAmount,
        uint fixedCollateralEth,
        address stableCoinAddress,
        address aggregatorAddress
    ) public returns (address) {
        address newCollateral = address(
            new Collateral(
                totalParticipants,
                cycleTime,
                contributionAmount,
                contributionPeriod,
                collateralAmount,
                fixedCollateralEth,
                address(stableCoinAddress),
                address(aggregatorAddress),
                msg.sender
            )
        );
        deployedCollaterals.push(payable(newCollateral));

        return newCollateral;
    }

    function getDeployedCollaterals()
        public
        view
        returns (address payable[] memory)
    {
        return deployedCollaterals;
    }
}

//TODO:
//Revise Type casting between uint and int
//create events to listen to calls (for front-end)
contract Collateral is Ownable {
    //NOTE: This was originally inside the reqCon function
    //It was moved out due to stack too deep error
    //Another solution is to call parameter from Fund contract directly
    Fund private fundInstance;

    AggregatorV3Interface internal priceFeed;

    uint public version = 2;

    uint public totalParticipants;
    uint public collateralDeposit;
    uint public firstDepositTime;
    uint public cycleTime;
    uint public contributionAmount;
    uint public contributionPeriod;
    uint public counterMembers = 0;
    uint public fixedCollateralEth;

    mapping(address => bool) public isCollateralMember; //Determines if a participant is a valid user
    mapping(address => uint) public collateralMembersBank; //Main user balance
    mapping(address => uint) public collateralPaymentBank; //User reimbursement balance

    address[] public participants;
    address public fundContract;
    address public stableCoinAddress;

    enum States {
        AcceptingCollateral, //Initial state where collateral are deposited
        CycleOngoing, //Triggered when a fund instance is created, no collateral can be accepted
        ReleasingCollateral, //Triggered when the fund closes
        Closed //Triggers when all participants withdraw their collaterals
    }

    event OnContractDeployed(address indexed newContract);
    event OnFundContractDeployed(
        address indexed fund,
        address indexed collateral
    );
    event OnStateChanged(States indexed oldState, States indexed newState);
    event OnCollateralDeposited(address indexed user, uint indexed amount); //AISHA: SEND NEW HASH TO NAV
    event OnCollateralWithdrawn(address indexed user, uint indexed amount);
    event OnCollateralLiquidated(address indexed user);

    //Function cannot be called at this time.
    error FunctionInvalidAtThisState();

    //Current state.
    States public state = States.AcceptingCollateral;
    uint public creationTime = block.timestamp;
    modifier atState(States state_) {
        if (state != state_) revert FunctionInvalidAtThisState();
        _;
    }

    function setStateOwner(States state_) public onlyOwner {
        setState(state_);
    }

    function setState(States state_) internal {
        state = state_;
        emit OnStateChanged(state, state_);
    }

    /// @notice Constructor Function
    /// @dev Network is Polygon Testnet and Aggregator is ETH/USD
    /// @param _totalParticipants Max number of participants
    /// @param _cycleTime Time for single cycle (seconds)
    /// @param _contributionAmount Amount user must pay per cycle (USD)
    /// @param _contributionPeriod The portion of cycle user must make payment
    /// @param _collateralAmount Total value of collateral in USD (1.5x of total fund)
    /// @param _creator owner of contract
    constructor(
        uint _totalParticipants,
        uint _cycleTime,
        uint _contributionAmount,
        uint _contributionPeriod,
        uint _collateralAmount,
        uint _fixedCollateralEth,
        address _stableCoinAddress,
        address _aggregatorAddress,
        address _creator
    ) {
        transferOwnership(_creator);

        totalParticipants = _totalParticipants;
        cycleTime = _cycleTime;
        contributionAmount = _contributionAmount; //TODO: convert to wei as well
        contributionPeriod = _contributionPeriod;
        collateralDeposit = _collateralAmount * 10 ** 18; //convert to Wei
        fixedCollateralEth = _fixedCollateralEth;
        stableCoinAddress = _stableCoinAddress;
        priceFeed = AggregatorV3Interface(_aggregatorAddress);

        emit OnContractDeployed(address(this));
    }

    /// @notice Calls the Fund constructor to start he fund
    /// @dev The inputs must be revised / add try catch (see: https://solidity-by-example.org/try-catch/)
    /// @param _participants Max number of participants
    /// @param _cycleTime Duration of a complete cycle in seconds?
    /// @param _contributionAmount Value participant must contribute for each cycle
    /// @param _contributionPeriod Duration of funding period in seconds?
    function _createFund(
        address _stableTokenAddress,
        address[] memory _participants,
        uint _cycleTime,
        uint _contributionAmount,
        uint _contributionPeriod
    ) internal {
        fundContract = address(
            new Fund(
                //address(this),
                _stableTokenAddress,
                //owner(),
                _participants,
                _cycleTime,
                _contributionAmount,
                _contributionPeriod
            )
        );

        //TODO: check for success before initiating instance
        fundInstance = Fund(address(fundContract)); //newly added
        setState(States.CycleOngoing);
        emit OnFundContractDeployed(address(fundContract), address(this));
    }

    /// @notice Called by each member to enter the Fund
    /// @dev needs to call the fund creation function
    function depositCollateral()
        external
        payable
        atState(States.AcceptingCollateral)
    {
        address sender = msg.sender;
        require(counterMembers < totalParticipants);
        require(isCollateralMember[sender] == false);
        require(msg.value >= fixedCollateralEth, "You need to pay up...");

        collateralMembersBank[sender] += msg.value;
        isCollateralMember[sender] = true;
        participants.push(address(sender));
        counterMembers++; //maybe replace this with array len

        emit OnCollateralDeposited(address(sender), msg.value);

        if (participants.length == 1) {
            firstDepositTime = block.timestamp;
        }
    }

    /// @notice Called by the manager when the cons job goes off
    /// @dev consider making the duration a variable
    function initiateFundContract()
        public
        onlyOwner
        atState(States.AcceptingCollateral)
    {
        require(fundContract == address(0));
        require(counterMembers == totalParticipants);
        //If one user is under collaterized, then all are too.
        require(
            isUnderCollaterized(participants[0]) == false,
            "Cannot start fund: Eth prices dropped"
        ); //TODO: how will backend behave here?

        _createFund(
            stableCoinAddress,
            participants,
            cycleTime,
            contributionAmount,
            contributionPeriod
        );
    }

    /// @notice Called from Fund contract when someone defaults
    /// @dev Check EnumerableMap (openzeppelin) for arrays that are being accessed from Fund contract
    /// @param beneficiary Address that was randomly selected for the current cycle
    /// @param defaulters Address that was randomly selected for the current cycle
    function requestContribution(
        address beneficiary,
        address[] calldata defaulters
    ) external atState(States.CycleOngoing) returns (address[] memory) {
        require(fundContract == address(msg.sender), "wrong caller");
        require(defaulters.length != 0, "defaulters array is empty!");
        //fundInstance = Fund(address(fundContract));

        address ben = beneficiary; //to solve stack too deep

        bool wasBeneficiary = false;
        address currentDefaulter;
        address currentParticipant;
        address[] memory nonBeneficiaries = new address[](participants.length);
        address[] memory expellants = new address[](defaulters.length);

        uint totalExpellants = 0;
        uint nonBeneficiaryCounter = 0;
        uint share = 0;

        uint contributionAmountWei = uint(
            getToEthConversionRate(int(contributionAmount * 10 ** 18))
        );

        //Determine who will be expelled and who will just pay the contribution
        //from their collateral.
        for (uint i = 0; i < defaulters.length; i++) {
            currentDefaulter = defaulters[i];
            wasBeneficiary = fundInstance.beneficiariesTracker(
                currentDefaulter
            );

            if (currentDefaulter == ben) continue; //avoid expelling graced defaulter

            if (
                (wasBeneficiary && isUnderCollaterized(currentDefaulter)) ||
                (collateralMembersBank[currentDefaulter] <
                    contributionAmountWei)
            ) {
                isCollateralMember[currentDefaulter] = false; //expelled!
                expellants[i] = currentDefaulter;
                share += collateralMembersBank[currentDefaulter];
                collateralMembersBank[currentDefaulter] = 0;
                totalExpellants++;
                counterMembers--;

                emit OnCollateralLiquidated(address(currentDefaulter));
            } else {
                //subtract contribution from defaulter and add to beneficiary.
                collateralMembersBank[
                    currentDefaulter
                ] -= contributionAmountWei;
                collateralPaymentBank[ben] += contributionAmountWei;
            }
        }

        totalParticipants = totalParticipants - totalExpellants;
        //Note: It would be nice to remove currentDefaulter from participants list here

        //Divide and Liquidate
        for (uint i = 0; i < participants.length; i++) {
            currentParticipant = participants[i];
            if (
                !fundInstance.beneficiariesTracker(currentParticipant) &&
                isCollateralMember[currentParticipant]
            ) {
                nonBeneficiaries[nonBeneficiaryCounter] = currentParticipant;
                nonBeneficiaryCounter++;
            }
        }

        //Finally, divide the share equally among non-beneficiaries
        if (nonBeneficiaryCounter > 0) {
            //this case can only happen when what?
            share = share / nonBeneficiaryCounter;
            for (uint i = 0; i < nonBeneficiaryCounter; i++) {
                collateralPaymentBank[nonBeneficiaries[i]] += share;
            }
        }
        //TODO: emit event here event when collateral is liquidated with current Eth
        //think of the case when 2 users remain to be ben and both default
        //think of the case when 1 user remains and he defaults in last cycle when its his turn
        //for a graced defaulter, should we put them inside the defaulters array? mutually exclusive

        return (expellants); //returning true here doesnt make sense because no where else am i returning false.
    }

    /// @notice Called by each member after the end of the cycle to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    function withdrawCollateral() external atState(States.ReleasingCollateral) {
        address sender = msg.sender;
        uint total = collateralMembersBank[sender] +
            collateralPaymentBank[sender];
        require(total > 0, "No collateral to claim");

        collateralMembersBank[sender] = 0;
        collateralPaymentBank[sender] = 0;
        payable(sender).transfer(total);

        emit OnCollateralWithdrawn(address(sender), total);

        counterMembers--;
        //if last person withdraws, then change state to EOL
        if (counterMembers == 0) {
            setState(States.Closed);
        }
    }

    function withdrawReimbursement(address participant) external {
        require(address(fundContract) == address(msg.sender), "wrong caller");
        uint amount = collateralPaymentBank[participant];
        require(amount > 0, "No reimbursement to claim");
        collateralPaymentBank[participant] = 0;
        payable(participant).transfer(amount);
    }

    function releaseCollateral() external {
        require(address(fundContract) == address(msg.sender), "wrong caller"); //Attention! Temp comment out for testing
        setState(States.ReleasingCollateral);
    }

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This calculates the total contribution amount each time to take note of user expulsion
    /// @param member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function isUnderCollaterized(address member) public view returns (bool) {
        //AISHA: this will revert if called after users are withdrawing their collateral
        uint collateralLimit;
        int memberCollateralUSD;
        if (fundContract == address(0)) {
            collateralLimit = totalParticipants * contributionAmount * 10 ** 18;
        } else {
            uint remainingCycles = counterMembers -
                fundInstance.currentCycle() +
                1; //TODO: Can counter members be equal or less that current cycle?
            collateralLimit = remainingCycles * contributionAmount * 10 ** 18; //convert to Wei
        }

        memberCollateralUSD = getToUSDConversionRate(
            int(collateralMembersBank[member])
        );

        return (memberCollateralUSD < int(collateralLimit));
    }

    /// @notice Gets latest ETH / USD price using the Polygon Testnet
    /// @dev Address is 0x0715A7794a1dc8e42615F059dD6e406A6594651A
    /// @return int latest price in Wei
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData(); //8 decimals
        return int(price * 10 ** 10); //18 decimals
    }

    /** TO-DO: need to fix conversion
     * usdAmount: Amount in USD to convert to ETH (Wei)
     * Returns converted amount in eth
     */
    function getToEthConversionRate(int USDAmount) public view returns (int) {
        //NOTE: make internal
        int ethPrice = getLatestPrice();
        //console.log("Eth price is", uint(ethPrice));
        int USDAmountInEth = (USDAmount * 10 ** 18) / ethPrice; //* 10 ** 18;
        //console.log("Converted amount inside function", uint(USDAmountInEth));
        return USDAmountInEth;
    }

    /// @notice Gets the conversion rate of an amount in ETH to USD
    /// @dev should we always deal with in Wei?
    /// @return int converted amount in USD correct to 18 decimals
    function getToUSDConversionRate(int ethAmount) public view returns (int) {
        //NOTE: make internal
        int ethPrice = getLatestPrice();
        int ethAmountInUSD = (ethPrice * ethAmount) / 10 ** 18;
        return ethAmountInUSD;
    }

    function drainCollateralAfterEnd()
        external
        onlyOwner
        atState(States.ReleasingCollateral)
    {
        require(
            block.timestamp >= (cycleTime * totalParticipants) + 180 days,
            "Can't empty yet"
        );

        payable(msg.sender).transfer(address(this).balance);
    }

    function getCollateralSummary()
        public
        view
        returns (States, uint, uint, uint, uint, uint, uint, uint)
    {
        return (
            state, //current state of Collateral
            cycleTime, //cycle duration
            totalParticipants, //total no. of participants
            collateralDeposit, //collateral
            contributionAmount, //Required contribution per cycle
            contributionPeriod, //time to contribute
            counterMembers, //current member count
            fixedCollateralEth //fixed ether to deposit
        );
    }

    function drainBalanceTesting() external onlyOwner {
        //AISHA: REMOVE BEFORE LIVE DEPLOYMENT
        payable(msg.sender).transfer(address(this).balance);
    }
}

//get from fund contract
//fund state
//current cycle
//current ben