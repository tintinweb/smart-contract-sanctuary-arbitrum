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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IGetters} from "../interfaces/IGetters.sol";
import {IZaynVaultV2TakaDao} from "../interfaces/IZaynVaultV2TakaDao.sol";

import {LibTerm} from "../libraries/LibTerm.sol";
import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibFund} from "../libraries/LibFund.sol";
import {LibYieldGeneration} from "../libraries/LibYieldGeneration.sol";

contract GettersFacet is IGetters {
    // TERM GETTERS
    /// @return the current term id
    /// @return the next term id
    function getTermsId() external view returns (uint, uint) {
        LibTerm.TermStorage storage termStorage = LibTerm._termStorage();
        uint lastTermId = termStorage.nextTermId - 1;
        uint nextTermId = termStorage.nextTermId;
        return (lastTermId, nextTermId);
    }

    ///  @notice Gets the remaining registration period for a term
    ///  @param termId the term id
    ///  @return remaining contribution period
    function getRemainingRegistrationTime(uint termId) external view returns (uint) {
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];
        if (block.timestamp >= term.creationTime + term.registrationPeriod) {
            return 0;
        } else {
            return term.creationTime + term.registrationPeriod - block.timestamp;
        }
    }

    /// @param termId the term id
    /// @return the term struct
    function getTermSummary(uint termId) external view returns (LibTerm.Term memory) {
        return (LibTerm._termStorage().terms[termId]);
    }

    /// @param participant the participant address
    /// @return the term ids the participant is part of
    function getAllJoinedTerms(address participant) public view returns (uint[] memory) {
        LibTerm.TermStorage storage termStorage = LibTerm._termStorage();
        uint[] memory participantTermIds = termStorage.participantToTermId[participant];
        return participantTermIds;
    }

    /// @param participant the participant address
    /// @param state the term state
    /// @return the term ids the participant is part of, giving the state of the term
    function getJoinedTermsByState(
        address participant,
        LibTerm.TermStates state
    ) external view returns (uint[] memory) {
        uint[] memory joinedTerms = getAllJoinedTerms(participant);
        uint[] memory userTermsByState;
        uint termscounter;
        uint joinedTermsLength = joinedTerms.length;
        for (uint i; i < joinedTermsLength; ) {
            if (LibTerm._termStorage().terms[joinedTerms[i]].state == state) {
                userTermsByState[termscounter] = i;
                unchecked {
                    ++termscounter;
                }
            }
            unchecked {
                ++i;
            }
        }
        return userTermsByState;
    }

    /// @param participant the participant address
    /// @return the term ids the participant is part of, giving the state of the term
    function getExpelledTerms(address participant) external view returns (uint[] memory) {
        uint[] memory joinedTerms = getAllJoinedTerms(participant);
        uint[] memory termsExpelled;
        uint termscounter;
        uint joinedTermsLength = joinedTerms.length;
        for (uint i; i < joinedTermsLength; ) {
            if (wasExpelled(joinedTerms[i], participant)) {
                termsExpelled[termscounter] = i;
                unchecked {
                    ++termscounter;
                }
            }
            unchecked {
                ++i;
            }
        }
        return termsExpelled;
    }

    /// @param termId the term id
    /// @return remaining time in the current cycle
    function getRemainingCycles(uint termId) external view returns (uint) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];

        return (1 + fund.totalAmountOfCycles - fund.currentCycle);
    }

    /// @param termId the term id
    /// @return remaining time in the current cycle
    function getRemainingCycleTime(uint termId) external view returns (uint) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];
        uint cycleEndTimestamp = term.cycleTime * fund.currentCycle + fund.fundStart;
        if (block.timestamp > cycleEndTimestamp) {
            return 0;
        } else {
            return cycleEndTimestamp - block.timestamp;
        }
    }

    /// @param termId the term id
    /// @return remaining cycles contribution
    function getRemainingCyclesContributionWei(uint termId) external view returns (uint) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];

        uint remainingCycles = 1 + fund.totalAmountOfCycles - fund.currentCycle;
        uint contributionAmountWei = IGetters(address(this)).getToCollateralConversionRate(
            term.contributionAmount * 10 ** 18
        );

        return remainingCycles * contributionAmountWei;
    }

    // COLLATERAL GETTERS

    /// @param depositor the depositor address
    /// @param termId the collateral id
    /// @return isCollateralMember, collateralMembersBank, collateralPaymentBank
    function getDepositorCollateralSummary(
        address depositor,
        uint termId
    ) external view returns (bool, uint, uint, uint) {
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[termId];
        return (
            collateral.isCollateralMember[depositor],
            collateral.collateralMembersBank[depositor],
            collateral.collateralPaymentBank[depositor],
            collateral.collateralDepositByUser[depositor]
        );
    }

    /// @param termId the collateral id
    /// @return collateral: initialized, state, firstDepositTime, counterMembers, depositors, collateralDeposit
    function getCollateralSummary(
        uint termId
    ) external view returns (bool, LibCollateral.CollateralStates, uint, uint, address[] memory) {
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[termId];
        return (
            collateral.initialized,
            collateral.state, // Current state of Collateral
            collateral.firstDepositTime, // Time when the first deposit was made
            collateral.counterMembers, // Current member count
            collateral.depositors // List of depositors
        );
    }

    /// @notice Called to check the minimum collateral amount to deposit in wei
    /// @return amount the minimum collateral amount to deposit in wei
    /// @dev The minimum collateral amount is calculated based on the index on the depositors array
    /// @dev The return value should be the minimum msg.value when calling joinTerm
    /// @dev C = 1.5 Cp (Tp - I) where C = minimum collateral amount, Cp = contribution amount,
    /// Tp = total participants, I = depositor index (starts at 0). 1.5
    function minCollateralToDeposit(
        uint termId,
        uint depositorIndex
    ) external view returns (uint amount) {
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];

        uint contributionAmountInWei = getToCollateralConversionRate(
            term.contributionAmount * 10 ** 18
        );

        amount = (contributionAmountInWei * (term.totalParticipants - depositorIndex) * 150) / 100;
    }

    /// @notice Called to check how much collateral a user can withdraw
    /// @param termId term id
    /// @param user depositor address
    /// @return allowedWithdrawal amount the amount of collateral the depositor can withdraw
    function getWithdrawableUserBalance(
        uint termId,
        address user
    ) external view returns (uint allowedWithdrawal) {
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[termId];
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        uint userCollateral = collateral.collateralMembersBank[user];
        uint availableYield = yield.availableYield[user];

        if (collateral.state == LibCollateral.CollateralStates.ReleasingCollateral) {
            allowedWithdrawal = userCollateral + availableYield;
        } else if (collateral.state == LibCollateral.CollateralStates.CycleOngoing) {
            // Everything above 1.5 X remaining cycles contribution (RCC) can be withdrawn
            uint minRequiredCollateral = (IGetters(address(this)).getRemainingCyclesContributionWei(
                termId
            ) * 15) / 10; // 1.5 X RCC in wei

            // Collateral must be higher than 1.5 X RCC
            if (userCollateral > minRequiredCollateral) {
                allowedWithdrawal = minRequiredCollateral - userCollateral + availableYield; // We allow to withdraw the positive difference
            } else {
                allowedWithdrawal = 0;
            }
        } else {
            allowedWithdrawal = 0;
        }
    }

    // FUND GETTERS

    /// @notice function to get the cycle information in one go
    /// @param termId the fund id
    /// @return initialized, currentState, stableToken, currentCycle, beneficiariesOrder, fundStart, currentCycle, totalAmountOfCycles, fundEnd
    function getFundSummary(
        uint termId
    )
        external
        view
        returns (bool, LibFund.FundStates, IERC20, address[] memory, uint, uint, uint, uint)
    {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        return (
            fund.initialized,
            fund.currentState,
            fund.stableToken,
            fund.beneficiariesOrder,
            fund.fundStart,
            fund.fundEnd,
            fund.currentCycle,
            fund.totalAmountOfCycles
        );
    }

    /// @notice function to get the current beneficiary
    /// @param termId the fund id
    /// @return the current beneficiary
    function getCurrentBeneficiary(uint termId) external view returns (address) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        return fund.beneficiariesOrder[fund.currentCycle - 1];
    }

    /// @notice function to know if a user was expelled before
    /// @param termId the fund id
    /// @param user the user to check
    /// @return true if the user was expelled before
    function wasExpelled(uint termId, address user) public view returns (bool) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[termId];

        if (!fund.isParticipant[user] && !collateral.isCollateralMember[user]) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice function to see if a user is exempted from paying a cycle
    function isExempted(uint termId, uint cycle, address user) external view returns (bool) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        return fund.isExemptedOnCycle[cycle].exempted[user];
    }

    /// @notice function to get cycle information of a specific participant
    /// @param participant the user to get the info from
    /// @param termId the fund id
    /// @return isParticipant, true if is participant
    /// @return isBeneficiary, true if has been beneficiary
    /// @return paidThisCycle, true if has paid the current cycle
    /// @return autoPayEnabled, true if auto pay is enabled
    /// @return beneficiariesPool, the beneficiary pool, 6 decimals
    /// @return beneficiariesFrozenPool, true if the beneficiary pool is frozen
    function getParticipantFundSummary(
        address participant,
        uint termId
    ) external view returns (bool, bool, bool, bool, uint, bool) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        return (
            fund.isParticipant[participant],
            fund.isBeneficiary[participant],
            fund.paidThisCycle[participant],
            fund.autoPayEnabled[participant],
            fund.beneficiariesPool[participant],
            fund.beneficiariesFrozenPool[participant]
        );
    }

    /// @notice returns the time left to contribute for this cycle
    /// @param termId the fund id
    /// @return the time left to contribute
    function getRemainingContributionTime(uint termId) external view returns (uint) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];
        if (fund.currentState != LibFund.FundStates.AcceptingContributions) {
            return 0;
        }

        // Current cycle minus 1 because we use the previous cycle time as start point then add contribution period
        uint contributionEndTimestamp = term.cycleTime *
            (fund.currentCycle - 1) +
            fund.fundStart +
            term.contributionPeriod;
        if (block.timestamp > contributionEndTimestamp) {
            return 0;
        } else {
            return contributionEndTimestamp - block.timestamp;
        }
    }

    // CONVERSION GETTERS

    /// @notice Gets latest ETH / USD price
    /// @return uint latest price in Wei Note: 18 decimals
    function getLatestPrice() public view returns (uint) {
        LibTerm.TermConsts storage termConsts = LibTerm._termConsts();
        (
            ,
            /*uint80 roundID*/ int256 answer,
            uint256 startedAt /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
            ,

        ) = AggregatorV3Interface(termConsts.sequencerUptimeFeedAddress).latestRoundData(); //8 decimals

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        require(answer == 0, "Sequencer down");

        //We must wait at least an hour after the sequencer started up
        require(
            termConsts.sequencerStartupTime <= block.timestamp - startedAt,
            "Sequencer starting up"
        );

        (
            uint80 roundID_ethUSD,
            int256 price_ethUSD,
            ,
            /*uint startedAt*/ uint256 timeStamp_ethUSD,
            uint80 answeredInRound_ethUSD
        ) = AggregatorV3Interface(termConsts.aggregatorsAddresses["ETH/USD"]).latestRoundData(); //8 decimals

        // Check if chainlink data is not stale or incorrect
        require(
            timeStamp_ethUSD != 0 && answeredInRound_ethUSD >= roundID_ethUSD && price_ethUSD > 0,
            "ChainlinkOracle: stale data"
        );

        (
            uint80 roundID_usdUSDC,
            int256 price_usdUSDC,
            ,
            /*uint startedAt*/ uint256 timeStamp_usdUSDC,
            uint80 answeredInRound_usdUSDC
        ) = AggregatorV3Interface(termConsts.aggregatorsAddresses["USDC/USD"]).latestRoundData(); //8 decimals

        require(
            timeStamp_usdUSDC != 0 &&
                answeredInRound_usdUSDC >= roundID_usdUSDC &&
                price_usdUSDC > 0,
            "ChainlinkOracle: stale data"
        );

        int256 ethUSDC = price_ethUSD / price_usdUSDC;

        return uint(ethUSDC * 10 ** 18); //18 decimals
    }

    /// @notice Gets the conversion rate of an amount in USD to ETH
    /// @dev should we always deal with in Wei?
    /// @param USDAmount The amount in USD
    /// @return uint converted amount in wei
    function getToCollateralConversionRate(uint USDAmount) public view returns (uint) {
        uint ethPrice = getLatestPrice();
        uint USDAmountInEth = (USDAmount * 10 ** 18) / ethPrice;
        return USDAmountInEth;
    }

    /// @notice Gets the conversion rate of an amount in ETH to USD
    /// @dev should we always deal with in Wei?
    /// @param ethAmount The amount in ETH
    /// @return uint converted amount in USD correct to 18 decimals
    function getToStableConversionRate(uint ethAmount) external view returns (uint) {
        // NOTE: This will be made internal
        uint ethPrice = getLatestPrice();
        uint ethAmountInUSD = (ethPrice * ethAmount) / 10 ** 18;
        return ethAmountInUSD;
    }

    // YIELD GENERATION GETTERS

    /// @notice This function is used to get a user APY
    /// @param termId The term id for which the APY is being calculated
    /// @param user The user for which the APY is being calculated
    /// @return The APY for the user
    function userAPY(uint termId, address user) external returns (uint256) {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        uint256 elaspedTime = block.timestamp - yield.startTimeStamp;

        return
            (userYieldGenerated(termId, user) / yield.currentTotalDeposit) /
            (elaspedTime * 365 days);
    }

    /// @notice This function is used to get a term APY
    /// @param termId The term id for which the APY is being calculated
    /// @return The APY for the term
    function termAPY(uint termId) external returns (uint256) {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        uint256 elaspedTime = block.timestamp - yield.startTimeStamp;

        return (totalYieldGenerated(termId) / yield.currentTotalDeposit) / (elaspedTime * 365 days);
    }

    /// @notice This function is used to get the yield distribution ratio for a user
    /// @param termId The term id for which the ratio is being calculated
    /// @param user The user for which the ratio is being calculated
    /// @return The yield distribution ratio for the user
    function yieldDistributionRatio(uint termId, address user) public view returns (uint256) {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[termId];

        return collateral.collateralMembersBank[user] / yield.currentTotalDeposit;
    }

    /// @notice This function is used to get the total yield generated for a term
    /// @param termId The term id for which the yield is being calculated
    /// @return The total yield generated for the term
    function totalYieldGenerated(uint termId) public returns (uint) {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        uint totalWithdrawnYield;

        address[] memory arrayToCheck = yield.yieldUsers;
        uint arrayLength = arrayToCheck.length;

        for (uint i; i < arrayLength; ) {
            totalWithdrawnYield += yield.withdrawnYield[arrayToCheck[i]];

            unchecked {
                ++i;
            }
        }

        return
            totalWithdrawnYield +
            (yield.totalDeposit -
                IZaynVaultV2TakaDao(yield.providerAddresses["ZaynVault"]).balanceOf(termId));
    }

    /// @notice This function is used to get the total yield generated for a user
    /// @param termId The term id for which the yield is being calculated
    /// @param user The user for which the yield is being calculated
    /// @return The total yield generated for the user
    function userYieldGenerated(uint termId, address user) public returns (uint) {
        LibYieldGeneration.YieldGeneration storage yield = LibYieldGeneration
            ._yieldStorage()
            .yields[termId];

        return
            yield.withdrawnYield[user] +
            totalYieldGenerated(termId) *
            yieldDistributionRatio(termId, user);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

/// @title Takaturn Collateral Interface
/// @author Aisha EL Allam
/// @notice This is used to allow fund to easily communicate with collateral
/// @dev v2.0 (post-deploy)

import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibTerm} from "../libraries/LibTerm.sol";

interface ICollateral {
    // Function cannot be called at this time.
    error FunctionInvalidAtThisState();

    function setStateOwner(uint termId, LibCollateral.CollateralStates newState) external;

    /// @notice Called from Fund contract when someone defaults
    /// @dev Check EnumerableMap (openzeppelin) for arrays that are being accessed from Fund contract
    /// @param term the term object
    /// @param defaulters Address that was randomly selected for the current cycle
    function requestContribution(
        LibTerm.Term memory term,
        address[] calldata defaulters
    ) external returns (address[] memory);

    /// @notice Called by each member after the end of the cycle to withraw collateral
    /// @dev This follows the pull-over-push pattern.
    /// @param termId The term id
    function withdrawCollateral(uint termId) external;

    /// @param termId The term id
    /// @param participant The participant address
    function withdrawReimbursement(uint termId, address participant) external;

    /// @param termId The term id
    function releaseCollateral(uint termId) external;

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param termId The term id
    /// @param member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function isUnderCollaterized(uint termId, address member) external view returns (bool);

    /// @notice allow the owner to empty the Collateral after 180 days
    function emptyCollateralAfterEnd(uint termId) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LibTerm} from "../libraries/LibTerm.sol";
import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibFund} from "../libraries/LibFund.sol";

interface IGetters {
    // TERM GETTERS

    /// @notice Gets the current and next term id
    /// @return current termID
    /// @return next termID
    function getTermsId() external view returns (uint, uint);

    /// @notice Must return 0 before starting the fund
    /// @param termId the id of the term
    /// @return remaining registration time in seconds
    function getRemainingRegistrationTime(uint termId) external view returns (uint);

    /// @notice Get current information of a term
    /// @param termId the id of the term
    /// @return Term Struct, see LibTerm.sol
    function getTermSummary(uint termId) external view returns (LibTerm.Term memory);

    /// @notice Gets all terms a user has previously joined
    /// @param participant address
    /// @return List of termIDs
    function getAllJoinedTerms(address participant) external view returns (uint[] memory);

    /// @notice Gets all terms a user has previously joined based on the specefied term state
    /// @param participant address
    /// @param state, can be InitializingTerm, ActiveTerm, ExpiredTerm, ClosedTerm
    /// @return List of termIDs
    function getJoinedTermsByState(
        address participant,
        LibTerm.TermStates state
    ) external view returns (uint[] memory);

    /// @notice Gets all terms a user was previously expelled from
    /// @param participant address
    /// @return List of termIDs
    function getExpelledTerms(address participant) external view returns (uint[] memory);

    /// @notice Gets all remaining cycles of a term
    /// @param termId the id of the term
    /// @return remaining cycles
    function getRemainingCycles(uint termId) external view returns (uint);

    /// @notice Must be 0 before starting a new cycle
    /// @param termId the id of the term
    /// @return remaining cycle time in seconds
    function getRemainingCycleTime(uint termId) external view returns (uint);

    /// @notice Gets the expected remaining contribution amount for users in a term
    /// @param termId the id of the term
    /// @return total remaining contribution in wei
    function getRemainingCyclesContributionWei(uint termId) external view returns (uint);

    // COLLATERAL GETTERS

    /// @notice Gets a users collateral summary
    /// @param depositor address
    /// @param termId the id of the term
    /// @return if the user is a true member of the term
    /// @return current users locked collateral balance in wei
    /// @return current users unlocked collateral balance in wei
    /// @return initial users deposit in wei
    function getDepositorCollateralSummary(
        address depositor,
        uint termId
    ) external view returns (bool, uint, uint, uint);

    /// @notice Gets the collateral summary of a term
    /// @param termId the id of the term
    /// @return if collateral is initialized
    /// @return current state of the collateral, see States struct in LibCollateral.sol
    /// @return time of first deposit in seconds, 0 if no deposit occured yet
    /// @return current member count
    /// @return list of depositors
    function getCollateralSummary(
        uint termId
    ) external view returns (bool, LibCollateral.CollateralStates, uint, uint, address[] memory);

    /// @notice Gets the required minimum collateral deposit based on the position
    /// @param termId the term id
    /// @param depositorIndex the index of the depositor
    /// @return required minimum in wei
    function minCollateralToDeposit(uint termId, uint depositorIndex) external view returns (uint);

    /// @notice Called to check how much collateral a user can withdraw
    /// @param termId term id
    /// @param user depositor address
    /// @return allowedWithdrawal amount the amount of collateral the depositor can withdraw
    function getWithdrawableUserBalance(
        uint termId,
        address user
    ) external view returns (uint allowedWithdrawal);

    // FUND GETTERS
    /// @notice Gets the fund summary of a term
    /// @param termId the id of the term
    /// @return if fund is initialized
    /// @return current state of the fund, see States struct in LibFund.sol
    /// @return stablecoin address used
    /// @return list for order of beneficiaries
    /// @return when the fund started in seconds
    /// @return when the fund ended in seconds, 0 otherwise
    /// @return current cycle of fund
    /// @return total amount of cycles in this fund/term
    function getFundSummary(
        uint termId
    )
        external
        view
        returns (bool, LibFund.FundStates, IERC20, address[] memory, uint, uint, uint, uint);

    /// @notice Gets the current beneficiary of a term
    /// @param termId the id of the term
    /// @return user address
    function getCurrentBeneficiary(uint termId) external view returns (address);

    /// @notice Gets if a user is expelled from a specefic term
    /// @param termId the id of the term
    /// @param user address
    /// @return true or false
    function wasExpelled(uint termId, address user) external view returns (bool);

    /// @notice Gets if a user is exempted from paying for a specefic cycle
    /// @param termId the id of the term
    /// @param cycle number
    /// @param user address
    /// @return true or false
    function isExempted(uint termId, uint cycle, address user) external view returns (bool);

    /// @notice Gets a user information of in a fund
    /// @param participant address
    /// @param termId the id of the term
    /// @return if the user is a true member of the fund/term
    /// @return if the user was beneficiary in the past
    /// @return if the user paid for the current cycle
    /// @return if the user has autopay enabled
    /// @return users money pot balance
    function getParticipantFundSummary(
        address participant,
        uint termId
    ) external view returns (bool, bool, bool, bool, uint, bool);

    /// @notice Must return 0 before closing a contribution period
    /// @param termId the id of the term
    /// @return remaining contribution time in seconds
    function getRemainingContributionTime(uint termId) external view returns (uint);

    // CONVERSION GETTERS

    function getToCollateralConversionRate(uint USDAmount) external view returns (uint);

    function getToStableConversionRate(uint ethAmount) external view returns (uint);

    // YIELD GENERATION GETTERS

    function userAPY(uint termId, address user) external returns (uint256);

    function termAPY(uint termId) external returns (uint256);

    function yieldDistributionRatio(uint termId, address user) external view returns (uint256);

    function totalYieldGenerated(uint termId) external returns (uint);

    function userYieldGenerated(uint termId, address user) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynVaultV2TakaDao {
    function totalSupply() external view returns (uint256);

    function depositZap(uint256 _amount, uint256 _term) external;

    function withdrawZap(uint256 _shares, uint256 _term) external;

    function want() external pure returns (address);

    function balance() external pure returns (uint256);

    function strategy() external pure returns (address);

    function balanceOf(uint256 term) external returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibCollateral {
    uint public constant COLLATERAL_VERSION = 1;
    bytes32 constant COLLATERAL_STORAGE_POSITION = keccak256("diamond.standard.collateral.storage");

    enum CollateralStates {
        AcceptingCollateral, // Initial state where collateral are deposited
        CycleOngoing, // Triggered when a fund instance is created, no collateral can be accepted
        ReleasingCollateral, // Triggered when the fund closes
        Closed // Triggered when all depositors withdraw their collaterals
    }

    struct DefaulterState {
        bool payWithCollateral;
        bool payWithFrozenPool;
        bool gettingExpelled;
        bool isBeneficiary;
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

import {ICollateral} from "../interfaces/ICollateral.sol";

library LibFund {
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

    struct PayExemption {
        mapping(address => bool) exempted; // Mapping to keep track of if someone is exempted from paying
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
        mapping(address => uint) beneficiariesPool; // Mapping to keep track on how much each beneficiary can claim. Six decimals
        mapping(address => bool) beneficiariesFrozenPool; // Frozen pool by beneficiaries, it can claim when his collateral is at least 1.1 X RCC
        mapping(address => uint) cycleOfExpulsion; // Mapping to keep track on which cycle a user was expelled
        mapping(uint => PayExemption) isExemptedOnCycle; // Mapping to keep track of if someone is exempted from paying this cycle
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

library LibTerm {
    uint public constant TERM_VERSION = 2;
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    enum TermStates {
        InitializingTerm,
        ActiveTerm,
        ExpiredTerm,
        ClosedTerm
    }

    struct TermConsts {
        uint sequencerStartupTime;
        address sequencerUptimeFeedAddress;
        mapping(string => address) aggregatorsAddresses; // "ETH/USD" => address , "USDC/USD" => address
    }

    struct Term {
        bool initialized;
        TermStates state;
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
        mapping(string => address) providerAddresses;
    }

    struct YieldGeneration {
        bool initialized;
        YGProviders provider;
        mapping(string => address) providerAddresses;
        uint startTimeStamp;
        uint totalDeposit;
        uint currentTotalDeposit;
        uint totalShares;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield;
        mapping(address => uint256) withdrawnCollateral;
        mapping(address => uint256) availableYield;
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