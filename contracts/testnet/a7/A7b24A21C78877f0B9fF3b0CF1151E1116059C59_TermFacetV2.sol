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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {IFundV2} from "../interfaces/IFundV2.sol";
import {ICollateralV2} from "../interfaces/ICollateralV2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ITermV2} from "../interfaces/ITermV2.sol";
import {IGettersV2} from "../interfaces/IGettersV2.sol";
import {IYGFacetZaynFi} from "../interfaces/IYGFacetZaynFi.sol";

import {LibFundV2} from "../libraries/LibFundV2.sol";
import {LibTermV2} from "../libraries/LibTermV2.sol";
import {LibCollateralV2} from "../libraries/LibCollateralV2.sol";
import {LibYieldGeneration} from "../libraries/LibYieldGeneration.sol";

/// @title Takaturn Term
/// @author Mohammed Haddouti
/// @notice This is used to deploy the collateral & fund contracts
/// @dev v3.0 (Diamond)
contract TermFacetV2 is ITermV2 {
    uint public constant TERM_VERSION = 2;

    event OnTermCreated(uint indexed termId, address indexed termOwner);
    event OnCollateralDeposited(uint indexed termId, address indexed user, uint amount);
    event OnTermFilled(uint indexed termId);
    event OnTermExpired(uint indexed termId);

    function createTerm(
        uint totalParticipants,
        uint registrationPeriod,
        uint cycleTime,
        uint contributionAmount,
        uint contributionPeriod,
        address stableTokenAddress
    ) external returns (uint) {
        return
            _createTerm(
                totalParticipants,
                registrationPeriod,
                cycleTime,
                contributionAmount,
                contributionPeriod,
                stableTokenAddress
            );
    }

    function joinTerm(uint termId) external payable {
        _joinTerm(termId);
    }

    function startTerm(uint termId) external {
        _startTerm(termId);
    }

    function expireTerm(uint termId) external {
        _expireTerm(termId);
    }

    function _createTerm(
        uint _totalParticipants,
        uint _registrationPeriod,
        uint _cycleTime,
        uint _contributionAmount,
        uint _contributionPeriod,
        address _stableTokenAddress
    ) internal returns (uint) {
        require(
            _cycleTime != 0 &&
                _contributionAmount != 0 &&
                _contributionPeriod != 0 &&
                _totalParticipants != 0 &&
                _registrationPeriod != 0 &&
                _contributionPeriod < _cycleTime &&
                _stableTokenAddress != address(0),
            "Invalid inputs"
        );

        LibTermV2.TermStorage storage termStorage = LibTermV2._termStorage();
        uint termId = termStorage.nextTermId;

        //require(!termStorage.terms[termId].initialized, "Term already exists");

        LibTermV2.Term memory newTerm;

        newTerm.termId = termId;
        newTerm.totalParticipants = _totalParticipants;
        newTerm.registrationPeriod = _registrationPeriod;
        newTerm.cycleTime = _cycleTime;
        newTerm.contributionAmount = _contributionAmount;
        newTerm.contributionPeriod = _contributionPeriod;
        newTerm.stableTokenAddress = _stableTokenAddress;
        newTerm.termOwner = msg.sender;
        newTerm.creationTime = block.timestamp;
        newTerm.initialized = true;

        termStorage.terms[termId] = newTerm;
        termStorage.nextTermId++;

        _createCollateral(termId, _totalParticipants);

        emit OnTermCreated(termId, msg.sender);

        return termId;
    }

    function _joinTerm(uint _termId) internal {
        LibTermV2.TermStorage storage termStorage = LibTermV2._termStorage();
        LibTermV2.Term memory term = termStorage.terms[_termId];
        LibCollateralV2.Collateral storage collateral = LibCollateralV2
            ._collateralStorage()
            .collaterals[_termId];

        require(LibTermV2._termExists(_termId) && LibCollateralV2._collateralExists(_termId));

        require(collateral.state == LibCollateralV2.CollateralStates.AcceptingCollateral, "Closed");

        require(collateral.counterMembers < term.totalParticipants, "No space");

        require(
            block.timestamp <= term.creationTime + term.registrationPeriod,
            "Registration period ended"
        );

        require(!collateral.isCollateralMember[msg.sender], "Reentry");

        uint ethSended = msg.value;

        uint depositorsLength = collateral.depositors.length;
        for (uint i; i < depositorsLength; ) {
            if (collateral.depositors[i] == address(0)) {
                uint amount = IGettersV2(address(this)).minCollateralToDeposit(term, i);

                require(ethSended >= amount, "Eth payment too low");

                collateral.collateralMembersBank[msg.sender] += ethSended;
                collateral.isCollateralMember[msg.sender] = true;
                collateral.depositors[i] = msg.sender;
                collateral.counterMembers++;
                collateral.collateralDepositByUser[msg.sender] += ethSended;

                termStorage.participantToTermId[msg.sender].push(_termId);

                emit OnCollateralDeposited(_termId, msg.sender, ethSended);

                break;
            }

            unchecked {
                ++i;
            }
        }

        if (collateral.counterMembers == 1) {
            collateral.firstDepositTime = block.timestamp;
        }

        // If all the spots are filled, change the collateral
        if (collateral.counterMembers == term.totalParticipants) {
            emit OnTermFilled(_termId);
        }
    }

    function _startTerm(uint _termId) internal {
        LibTermV2.Term memory term = LibTermV2._termStorage().terms[_termId];
        LibCollateralV2.Collateral storage collateral = LibCollateralV2
            ._collateralStorage()
            .collaterals[_termId];
        address[] memory depositors = collateral.depositors;

        uint depositorsArrayLength = depositors.length;

        require(
            block.timestamp > term.creationTime + term.registrationPeriod,
            "Term not ready to start"
        );

        require(collateral.counterMembers == term.totalParticipants, "All spots are not filled");

        // Need to check each user because they can have different collateral amounts
        for (uint i; i < depositorsArrayLength; ) {
            require(
                !ICollateralV2(address(this)).isUnderCollaterized(term.termId, depositors[i]),
                "Eth prices dropped"
            );

            unchecked {
                ++i;
            }
        }

        // Actually create and initialize the fund
        _createFund(term, collateral);

        _createYieldGenerator(term, collateral);

        // Tell the collateral that the term has started
        ICollateralV2(address(this)).setStateOwner(
            term.termId,
            LibCollateralV2.CollateralStates.CycleOngoing
        );
    }

    function _createCollateral(uint _termId, uint _totalParticipants) internal {
        //require(!LibCollateralV2._collateralExists(termId), "Collateral already exists");
        LibCollateralV2.Collateral storage newCollateral = LibCollateralV2
            ._collateralStorage()
            .collaterals[_termId];

        newCollateral.initialized = true;
        newCollateral.state = LibCollateralV2.CollateralStates.AcceptingCollateral;
        newCollateral.depositors = new address[](_totalParticipants);
    }

    function _createFund(
        LibTermV2.Term memory _term,
        LibCollateralV2.Collateral storage _collateral
    ) internal {
        require(!LibFundV2._fundExists(_term.termId), "Fund already exists");
        LibFundV2.Fund storage newFund = LibFundV2._fundStorage().funds[_term.termId];

        newFund.stableToken = IERC20(_term.stableTokenAddress);
        newFund.beneficiariesOrder = _collateral.depositors;
        newFund.initialized = true;
        newFund.totalAmountOfCycles = newFund.beneficiariesOrder.length;
        newFund.currentState = LibFundV2.FundStates.InitializingFund;

        IFundV2(address(this)).initFund(_term.termId);
    }

    function _expireTerm(uint _termId) internal {
        LibTermV2.Term storage term = LibTermV2._termStorage().terms[_termId];
        LibCollateralV2.Collateral storage collateral = LibCollateralV2
            ._collateralStorage()
            .collaterals[_termId];

        require(LibTermV2._termExists(_termId) && LibCollateralV2._collateralExists(_termId));

        require(
            block.timestamp > term.creationTime + term.registrationPeriod,
            "Registration period not ended"
        );

        require(
            collateral.counterMembers < term.totalParticipants,
            "All spots are filled, can't expire"
        );

        require(!term.expired, "Term already expired");

        uint depositorsArrayLength = collateral.depositors.length;

        for (uint i; i < depositorsArrayLength; ) {
            address depositor = collateral.depositors[i];

            if (depositor != address(0)) {
                uint amount = collateral.collateralMembersBank[depositor];

                collateral.collateralPaymentBank[depositor] += amount;
                collateral.collateralMembersBank[depositor] = 0;
                collateral.isCollateralMember[depositor] = false;
                collateral.depositors[i] = address(0);
                --collateral.counterMembers;
            }

            unchecked {
                ++i;
            }
        }

        term.expired = true;
        collateral.initialized = false;
        collateral.state = LibCollateralV2.CollateralStates.Closed;

        emit OnTermExpired(_termId);
    }

    function _createYieldGenerator(
        LibTermV2.Term memory _term,
        LibCollateralV2.Collateral storage _collateral
    ) internal {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[_term.termId];

        uint amountDeposited;

        address[] memory depositors = _collateral.depositors;
        uint depositorsArrayLength = depositors.length;

        for (uint i; i < depositorsArrayLength; ) {
            if (yield.hasOptedIn[depositors[i]]) {
                yield.yieldUsers.push(depositors[i]);
                amountDeposited += _collateral.collateralMembersBank[depositors[i]];
            }

            unchecked {
                ++i;
            }
        }

        yield.startTimeStamp = block.timestamp;
        yield.initialized = true;

        IYGFacetZaynFi(address(this)).depositYG(_term.termId, amountDeposited);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

/// @title Takaturn Collateral Interface
/// @author Aisha EL Allam
/// @notice This is used to allow fund to easily communicate with collateral
/// @dev v2.0 (post-deploy)

import {LibCollateralV2} from "../libraries/LibCollateralV2.sol";
import {LibTermV2} from "../libraries/LibTermV2.sol";

interface ICollateralV2 {
    // Function cannot be called at this time.
    error FunctionInvalidAtThisState();

    function setStateOwner(uint termId, LibCollateralV2.CollateralStates newState) external;

    /// @notice Called from Fund contract when someone defaults
    /// @dev Check EnumerableMap (openzeppelin) for arrays that are being accessed from Fund contract
    /// @param defaulters Address that was randomly selected for the current cycle
    function requestContribution(
        LibTermV2.Term memory term,
        address[] calldata defaulters
    ) external returns (address[] memory);

    /// @notice Called by each member after the end of the cycle to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    function withdrawCollateral(uint termId) external;

    function withdrawReimbursement(uint termId, address participant) external;

    function releaseCollateral(uint termId) external;

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function isUnderCollaterized(uint termId, address member) external view returns (bool);

    /// @notice allow the owner to empty the Collateral after 180 days
    function emptyCollateralAfterEnd(uint termId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

/// @title Takaturn Fund Interface
/// @author Mohammed Haddouti
/// @notice This is used to allow collateral to easily communicate with fund
/// @dev v2.0 (post-deploy)

import {LibFundV2} from "../libraries/LibFundV2.sol";

interface IFundV2 {
    function initFund(uint termId) external;

    /// @notice starts a new cycle manually called by the owner. Only the first cycle starts automatically upon deploy
    function startNewCycle(uint termId) external;

    /// @notice Must be called at the end of the contribution period after the time has passed by the owner
    function closeFundingPeriod(uint termId) external;

    /// @notice Fallback function, if the internal call fails somehow and the state gets stuck, allow owner to call the function again manually
    /// @dev This shouldn't happen, but is here in case there's an edge-case we didn't take into account, can possibly be removed in the future
    function awardBeneficiary(uint termId) external;

    /// @notice called by the owner to close the fund for emergency reasons.
    function closeFund(uint termId) external;

    // @notice allow the owner to empty the fund if there's any excess fund left after 180 days,
    //         this with the assumption that beneficiaries can't claim it themselves due to losing their keys for example,
    //         and prevent the fund to be stuck in limbo
    function emptyFundAfterEnd(uint termId) external;

    /// @notice function to enable/disable autopay
    function toggleAutoPay(uint termId) external;

    /// @notice This is the function participants call to pay the contribution
    function payContribution(uint termId) external;

    /// @notice This function is here to give the possibility to pay using a different wallet
    /// @param participant the address the msg.sender is paying for, the address must be part of the fund
    function payContributionOnBehalfOf(uint termId, address participant) external;

    /// @notice Called by the beneficiary to withdraw the fund
    /// @dev This follows the pull-over-push pattern.
    function withdrawFund(uint termId) external;

    function isBeneficiary(uint termId, address beneficiary) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LibTermV2} from "../libraries/LibTermV2.sol";
import {LibCollateralV2} from "../libraries/LibCollateralV2.sol";
import {LibFundV2} from "../libraries/LibFundV2.sol";

interface IGettersV2 {
    // TERM GETTERS

    function getTermsId() external view returns (uint, uint);

    function getRemainingContributionPeriod(uint termId) external view returns (uint);

    function getTermSummary(uint termId) external view returns (LibTermV2.Term memory);

    function getParticipantTerms(address participant) external view returns (uint[] memory);

    function getRemainingCycles(uint termId) external view returns (uint);

    function getRemainingCycleTime(uint termId) external view returns (uint);

    function getRemainingCyclesContributionWei(uint termId) external view returns (uint);

    // COLLATERAL GETTERS

    function getDepositorCollateralSummary(
        address depositor,
        uint termId
    ) external view returns (bool, uint, uint, uint);

    function getCollateralSummary(
        uint termId
    ) external view returns (bool, LibCollateralV2.CollateralStates, uint, uint, address[] memory);

    function minCollateralToDeposit(
        LibTermV2.Term memory term,
        uint depositorIndex
    ) external view returns (uint);

    // FUND GETTERS

    function getFundSummary(
        uint termId
    )
        external
        view
        returns (bool, LibFundV2.FundStates, IERC20, address[] memory, uint, uint, uint, uint);

    function getCurrentBeneficiary(uint termId) external view returns (address);

    function wasExpelled(uint termId, address user) external view returns (bool);

    function getParticipantFundSummary(
        address participant,
        uint termId
    ) external view returns (bool, bool, bool, bool, uint);

    function getRemainingContributionTime(uint termId) external view returns (uint);

    // CONVERSION GETTERS

    function getToEthConversionRate(uint USDAmount) external view returns (uint);

    function getToUSDConversionRate(uint ethAmount) external view returns (uint);

    // YIELD GENERATION GETTERS

    function userAPR(uint termId, address user) external view returns (uint256);

    function termAPR(uint termId) external view returns (uint256);

    function yieldDistributionRatio(uint termId, address user) external view returns (uint256);

    function totalYieldGenerated(uint termId) external view returns (uint);

    function userYieldGenerated(uint termId, address user) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

interface ITermV2 {
    function createTerm(
        uint totalParticipants,
        uint registrationPeriod,
        uint cycleTime,
        uint contributionAmount,
        uint contributionPeriod,
        address stableTokenAddress
    ) external returns (uint);

    function joinTerm(uint termId) external payable;

    function startTerm(uint termId) external;

    function expireTerm(uint termId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {LibTermV2} from "../libraries/LibTermV2.sol";

interface IYGFacetZaynFi {
    function depositYG(uint termId, uint amount) external;

    function withdrawYG(uint termId, address user, uint256 ethAmount) external;

    function toggleOptInYG(uint termId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibCollateralV2 {
    uint public constant COLLATERAL_VERSION = 1;
    bytes32 constant COLLATERAL_STORAGE_POSITION = keccak256("diamond.standard.collateral.storage");

    enum CollateralStates {
        AcceptingCollateral, // Initial state where collateral are deposited
        CycleOngoing, // Triggered when a fund instance is created, no collateral can be accepted
        ReleasingCollateral, // Triggered when the fund closes
        Closed // Triggered when all depositors withdraw their collaterals
    }

    struct Collateral {
        bool initialized;
        CollateralStates state;
        uint firstDepositTime;
        uint counterMembers;
        address[] depositors;
        mapping(address => bool) isCollateralMember; // Determines if a depositor is a valid user
        mapping(address => uint) collateralMembersBank; // Users main balance
        mapping(address => uint) collateralPaymentBank; // Users reimbursement balance after someone defaults
        mapping(address => uint) collateralDepositByUser; // Depends on the depositors index
    }

    struct CollateralStorage {
        mapping(uint => Collateral) collaterals; // termId => Collateral struct
    }

    function _collateralExists(uint termId) internal view returns (bool) {
        return _collateralStorage().collaterals[termId].initialized;
    }

    function _collateralStorage()
        internal
        pure
        returns (CollateralStorage storage collateralStorage)
    {
        bytes32 position = COLLATERAL_STORAGE_POSITION;
        assembly {
            collateralStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ICollateralV2} from "../interfaces/ICollateralV2.sol";

library LibFundV2 {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint public constant FUND_VERSION = 1;
    bytes32 constant FUND_POSITION = keccak256("diamond.standard.fund");
    bytes32 constant FUND_STORAGE_POSITION = keccak256("diamond.standard.fund.storage");

    enum FundStates {
        InitializingFund, // Time before the first cycle has started
        AcceptingContributions, // Triggers at the start of a cycle
        AwardingBeneficiary, // Contributions are closed, beneficiary is chosen, people default etc.
        CycleOngoing, // Time after beneficiary is chosen, up till the start of the next cycle
        FundClosed // Triggers at the end of the last contribution period, no state changes after this
    }

    struct Fund {
        bool initialized;
        FundStates currentState; // Variable to keep track of the different FundStates
        IERC20 stableToken; // Instance of the stable token
        address[] beneficiariesOrder; // The correct order of who gets to be next beneficiary, determined by collateral contract
        uint fundStart; // Timestamp of the start of the fund
        uint fundEnd; // Timestamp of the end of the fund
        uint currentCycle; // Index of current cycle
        mapping(address => bool) isParticipant; // Mapping to keep track of who's a participant or not
        mapping(address => bool) isBeneficiary; // Mapping to keep track of who's a beneficiary or not
        mapping(address => bool) paidThisCycle; // Mapping to keep track of who paid for this cycle
        mapping(address => bool) autoPayEnabled; // Wheter to attempt to automate payments at the end of the contribution period
        mapping(address => uint) beneficiariesPool; // Mapping to keep track on how much each beneficiary can claim
        // todo: add another one to freeze collateral?
        mapping(address => bool) beneficiariesFrozenPool; // Frozen pool by beneficiaries, it can claim when his collateral is at least 1.5RCC
        EnumerableSet.AddressSet _participants; // Those who have not been beneficiaries yet and have not defaulted this cycle
        EnumerableSet.AddressSet _beneficiaries; // Those who have been beneficiaries and have not defaulted this cycle
        EnumerableSet.AddressSet _defaulters; // Both participants and beneficiaries who have defaulted this cycle
        uint expelledParticipants; // Total amount of participants that have been expelled so far
        uint totalAmountOfCycles;
    }

    struct FundStorage {
        mapping(uint => Fund) funds; // termId => Fund struct
    }

    function _fundExists(uint termId) internal view returns (bool) {
        return _fundStorage().funds[termId].initialized;
    }

    function _fundStorage() internal pure returns (FundStorage storage fundStorage) {
        bytes32 position = FUND_STORAGE_POSITION;
        assembly {
            fundStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibTermV2 {
    uint public constant TERM_VERSION = 2;
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    struct TermConsts {
        uint sequencerStartupTime;
        address sequencerUptimeFeedAddress;
        mapping(string => address) aggregatorsAddresses; // "ETH/USD" => address , "USD/USDC" => address
    }

    struct Term {
        bool initialized;
        bool expired;
        address termOwner;
        uint creationTime;
        uint termId;
        uint registrationPeriod; // Time for registration (seconds)
        uint totalParticipants; // Max number of participants
        uint cycleTime; // Time for single cycle (seconds)
        uint contributionAmount; // Amount user must pay per cycle (USD)
        uint contributionPeriod; // The portion of cycle user must make payment
        address stableTokenAddress;
    }

    struct TermStorage {
        uint nextTermId;
        mapping(uint => Term) terms; // termId => Term struct
        mapping(address => uint[]) participantToTermId; // userAddress => [termId1, termId2, ...]
    }

    function _termExists(uint termId) internal view returns (bool) {
        return _termStorage().terms[termId].initialized;
    }

    function _termConsts() internal pure returns (TermConsts storage termConsts) {
        bytes32 position = TERM_CONSTS_POSITION;
        assembly {
            termConsts.slot := position
        }
    }

    function _termStorage() internal pure returns (TermStorage storage termStorage) {
        bytes32 position = TERM_STORAGE_POSITION;
        assembly {
            termStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibYieldGeneration {
    uint public constant YIELD_GENERATION_VERSION = 1;
    bytes32 constant YIELD_PROVIDERS_POSITION = keccak256("diamond.standard.yield.providers");
    bytes32 constant YIELD_STORAGE_POSITION = keccak256("diamond.standard.yield.storage");

    enum YGProviders {
        InHouse,
        ZaynFi
    }

    // Both index 0 are reserved for ZaynFi
    struct YieldProviders {
        address[] zaps;
        address[] vaults;
    }

    struct YieldGeneration {
        bool initialized;
        YGProviders provider;
        uint startTimeStamp;
        uint totalDeposit;
        uint currentTotalDeposit;
        address zap;
        address vault;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield;
        mapping(address => uint256) withdrawnCollateral;
    }

    struct YieldStorage {
        mapping(uint => YieldGeneration) yields; // termId => YieldGeneration struct
    }

    function _yieldExists(uint termId) internal view returns (bool) {
        return _yieldStorage().yields[termId].initialized;
    }

    function _yieldProviders() internal pure returns (YieldProviders storage yieldProviders) {
        bytes32 position = YIELD_PROVIDERS_POSITION;
        assembly {
            yieldProviders.slot := position
        }
    }

    function _yieldStorage() internal pure returns (YieldStorage storage yieldStorage) {
        bytes32 position = YIELD_STORAGE_POSITION;
        assembly {
            yieldStorage.slot := position
        }
    }
}