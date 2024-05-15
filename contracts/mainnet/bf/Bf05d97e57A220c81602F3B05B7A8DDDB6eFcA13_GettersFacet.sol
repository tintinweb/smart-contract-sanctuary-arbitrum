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

import {LibTermStorage} from "../libraries/LibTermStorage.sol";
import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibCollateralStorage} from "../libraries/LibCollateralStorage.sol";
import {LibFundStorage} from "../libraries/LibFundStorage.sol";
import {LibYieldGenerationStorage} from "../libraries/LibYieldGenerationStorage.sol";
import {LibYieldGeneration} from "../libraries/LibYieldGeneration.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibGettersHelpers} from "../libraries/LibGettersHelpers.sol";

/// @title Takaturn Getters Facet
/// @author Maikel Ordaz
/// @notice Getters for Takaturn protocol
/// @dev v3.0 (Diamond)
contract GettersFacet is IGetters {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice This function is used as a helper for front-end implementation
    /// @param termId The term id for which the summary is being requested
    /// @return term The term object
    /// @return collateralState The current state of the collateral
    /// @return fundState The current state of the fund
    /// @return nonUserRelated A helper struct with the following values:
    ///                        available positions, security deposits corresponding to each position,
    ///                        remaining registration time, remaining contribution time,
    ///                        remaining cycle time, remaining cycles, remaining cycles
    ///                        contribution in wei, latest price from Chainlink, collateral
    ///                        first deposit time in seconds, collateral counter members,
    ///                        fund start time in seconds, fund end time in seconds, current
    ///                        cycle, expelled participants, total amount of cycles, yield
    ///                        start time in seconds, total deposit in wei, current total
    ///                        deposit in wei, total shares, users opted in for yield
    function getTermRelatedSummary(
        uint termId
    )
        external
        view
        returns (
            LibTermStorage.Term memory term,
            LibCollateralStorage.CollateralStates collateralState,
            LibFundStorage.FundStates fundState,
            LibGettersHelpers.NonUserRelated memory nonUserRelated
        )
    {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        term = LibTermStorage._termStorage().terms[termId];
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        (
            uint[] memory joinPositions,
            uint[] memory joinAmounts
        ) = getAvailablePositionsAndSecurityAmount(termId);

        collateralState = collateral.state;
        fundState = fund.currentState;

        nonUserRelated = LibGettersHelpers.NonUserRelated({
            availablePositions: joinPositions,
            securityDeposits: joinAmounts,
            remainingRegistrationTime: getRemainingRegistrationTime(termId),
            remainingContributionTime: getRemainingContributionTime(termId),
            remainingCycleTime: getRemainingCycleTime(termId),
            remainingCycles: getRemainingCycles(termId),
            rcc: getRemainingCyclesContributionWei(termId),
            latestPrice: getLatestPrice(),
            collateralInitialized: collateral.initialized,
            collateralFirstDepositTime: collateral.firstDepositTime,
            collateralCounterMembers: collateral.counterMembers,
            fundInitialized: fund.initialized,
            fundStartTime: fund.fundStart,
            fundEndTime: fund.fundEnd,
            fundCurrentCycle: fund.currentCycle,
            fundExpellantsCount: fund.expelledParticipants,
            fundTotalCycles: fund.totalAmountOfCycles,
            fundBeneficiariesOrder: fund.beneficiariesOrder,
            yieldInitialized: yield.initialized,
            yieldStartTime: yield.startTimeStamp,
            yieldTotalDeposit: yield.totalDeposit,
            yieldCurrentTotalDeposit: yield.currentTotalDeposit,
            yieldTotalShares: yield.totalShares,
            yieldUsers: yield.yieldUsers
        });
    }

    /// @notice This function is used as a helper for front-end implementation
    /// @param user the depositor address
    /// @param termId the collateral id
    /// @return userRelated an object that contains the following values:
    ///                     user is collateral member, user is undercollaterized,
    ///                     current collateral balance, received collateral from defaults,
    ///                     initial deposited collateral, collateral expulsion limit,
    ///                     currently withdrawable balance, is fund member, is or was beneficiary,
    ///                     user paid current cycle, user paid next cycle in advance,
    ///                     user enabled autopay, user's money pot is frozen, user is exempted this
    ///                     cycle, the money pot pool the user can withdraw, the cycle the user got
    ///                     expelled (if applicable), is yield member, amount of collateral deposited
    ///                     in yield pool, amount of collateral withdrawn from yield pool, available
    ///                     yield to withdraw, amount of yield withdrawn, yield to be distributed
    function getUserRelatedSummary(
        address user,
        uint termId
    ) external view returns (LibGettersHelpers.UserRelated memory userRelated) {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        bool beneficiary = fund.isBeneficiary[user]; // true if user has been beneficiary

        userRelated.collateralMember = collateral.isCollateralMember[user]; // true if member
        userRelated.isUnderCollaterized = LibCollateral._isUnderCollaterized(termId, user); // checks if user is undercollaterized
        userRelated.membersBank = collateral.collateralMembersBank[user];
        userRelated.paymentBank = collateral.collateralPaymentBank[user];
        userRelated.deposited = collateral.collateralDepositByUser[user];
        userRelated.fundMember = fund.isParticipant[user]; // true if participant
        userRelated.beneficiary = beneficiary; // true if user has been beneficiary
        userRelated.currentCyclePaid = fund.paidThisCycle[user]; // true if has paid current cycle
        userRelated.nextCyclePaid = fund.paidNextCycle[user]; // true if has paid next cycle
        userRelated.autoPayer = fund.autoPayEnabled[user]; // true if enabled auto pay
        userRelated.moneyPotFrozen = _checkFrozenMoneyPot(user, termId); // true if money pot is frozen
        userRelated.exemptedThisCycle = fund.isExemptedOnCycle[fund.currentCycle].exempted[user];
        userRelated.yieldMember = yield.hasOptedIn[user]; // true if deposit on yield
        userRelated.withdrawableBalance = getWithdrawableUserBalance(termId, user); // Gets the amount of collateral the user can withdraw right now

        if (collateral.state != LibCollateralStorage.CollateralStates.AcceptingCollateral) {
            uint limit;
            if (beneficiary) {
                // limit is determined by whether the user is beneficiary or not
                limit = getRemainingCyclesContributionWei(termId);
            } else {
                limit = getToCollateralConversionRate(term.contributionAmount * 10 ** 18);
            }

            userRelated.expulsonLimit = limit;
            userRelated.pool = fund.beneficiariesPool[user];
            userRelated.cycleExpelled = fund.cycleOfExpulsion[user];

            if (yield.hasOptedIn[user]) {
                userRelated.collateralDepositedInYield = yield.depositedCollateralByUser[user];
                userRelated.collateralWithdrawnFromYield = yield.withdrawnCollateral[user];
                userRelated.yieldAvailable = yield.availableYield[user];
                userRelated.yieldWithdrawn = yield.withdrawnYield[user];
                userRelated.distributedYield = LibYieldGeneration._unwithdrawnUserYieldGenerated(
                    termId,
                    user
                );
            }
        }
    }

    /// @notice This function return the current constant values for oracles and yield providers
    /// @param firstAggregator The name of the first aggregator. Example: "ETH/USD"
    /// @param secondAggregator The name of the second aggregator. Example: "USDC/USD"
    /// @param zapAddress The name of the zap address. Example: "ZaynZap"
    /// @param vaultAddress The name of the vault address. Example: "ZaynVault"
    /// @return The addresses of the oracles and yield providers
    function getConstants(
        string memory firstAggregator,
        string memory secondAggregator,
        string memory zapAddress,
        string memory vaultAddress
    ) external view returns (address, address, address, address) {
        LibTermStorage.TermConsts storage termConsts = LibTermStorage._termConsts();
        LibYieldGenerationStorage.YieldProviders storage yieldProvider = LibYieldGenerationStorage
            ._yieldProviders();

        return (
            termConsts.aggregatorsAddresses[firstAggregator],
            termConsts.aggregatorsAddresses[secondAggregator],
            yieldProvider.providerAddresses[zapAddress],
            yieldProvider.providerAddresses[vaultAddress]
        );
    }

    /// @notice This function is used to get the current state of the yield lock
    /// @return The current state of the yield lock
    function getYieldLockState() external view returns (bool) {
        return LibYieldGenerationStorage._yieldLock().yieldLock;
    }

    /// @return the current term id
    /// @return the next term id
    function getTermsId() external view returns (uint, uint) {
        LibTermStorage.TermStorage storage termStorage = LibTermStorage._termStorage();
        uint lastTermId = termStorage.nextTermId - 1;
        uint nextTermId = termStorage.nextTermId;
        return (lastTermId, nextTermId);
    }

    /// @notice Gets the term object
    /// @param termId the term id
    /// @return the term object
    function getTermSummary(uint termId) external view returns (LibTermStorage.Term memory) {
        return (LibTermStorage._termStorage().terms[termId]);
    }

    /// @notice function to get the collateral object
    /// @param termId the collateral id
    /// @return if collateral initialized
    /// @return current collateral state
    /// @return time of first deposit
    /// @return current members count
    /// @return list of depositors
    function getCollateralSummary(
        uint termId
    )
        external
        view
        returns (bool, LibCollateralStorage.CollateralStates, uint, uint, address[] memory)
    {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
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

    /// @notice function to get the cycle information in one go
    /// @param termId the fund id
    /// @return if fund initialized
    /// @return current fund state
    /// @return stable token address used
    /// @return list of beneficiaries order
    /// @return when the fund starts in seconds
    /// @return when the fund ended, 0 if not ended
    /// @return current cycle number
    /// @return total amount of cycles
    function getFundSummary(
        uint termId
    )
        external
        view
        returns (bool, LibFundStorage.FundStates, IERC20, address[] memory, uint, uint, uint, uint)
    {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
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

    /// @notice Gets the yield object
    /// @param termId the collateral id
    /// @return if the yield is initialized
    /// @return start time stamp for yield deposit
    /// @return total deposit
    /// @return current amount in yield
    /// @return amount of total shares
    /// @return list of yield users
    /// @return address of vault
    /// @return address of zap
    function getYieldSummary(
        uint termId
    ) external view returns (bool, uint, uint, uint, uint, address[] memory, address, address) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];
        return (
            yield.initialized,
            yield.startTimeStamp,
            yield.totalDeposit,
            yield.currentTotalDeposit,
            yield.totalShares,
            yield.yieldUsers,
            yield.providerAddresses["ZaynVault"],
            yield.providerAddresses["ZaynZap"]
        );
    }

    /// @notice This function is used to get a term APY
    /// @param termId The term id for which the APY is being calculated
    /// @return The APY for the term
    function termAPY(uint termId) external view returns (uint256) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        uint256 elaspedTime = block.timestamp - yield.startTimeStamp;

        return
            (((totalYieldGenerated(termId) * 10 ** 18) / yield.currentTotalDeposit) * 365 days) /
            elaspedTime;
    }

    /// @notice a function to get the needed allowance for every active term the user is part of
    /// @param user the user address
    /// @return the needed allowance
    function getNeededAllowance(address user) external view returns (uint) {
        uint neededAllowance;

        uint[] memory activeTerms = getJoinedTermsByState(
            user,
            LibTermStorage.TermStates.ActiveTerm
        );
        uint[] memory initializedTerms = getJoinedTermsByState(
            user,
            LibTermStorage.TermStates.InitializingTerm
        );

        uint activeTermsLength = activeTerms.length;
        uint initializedTermsLength = initializedTerms.length;

        for (uint i; i < activeTermsLength; ) {
            LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[activeTerms[i]];
            uint remainingPayments = term.contributionAmount *
                getRemainingCycles(activeTerms[i]) *
                10 ** 6;
            neededAllowance += remainingPayments;

            /// @custom:unchecked-block without risk, i can't be higher than activeTerms length
            unchecked {
                ++i;
            }
        }

        for (uint i; i < initializedTermsLength; ) {
            LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[
                initializedTerms[i]
            ];
            uint totalPayments = term.contributionAmount * term.totalParticipants * 10 ** 6;
            neededAllowance += totalPayments;

            /// @custom:unchecked-block without risk, i can't be higher than initializedTerms length
            unchecked {
                ++i;
            }
        }

        return neededAllowance;
    }

    /// @notice function to get the beneficiary from the current cycle
    /// @param termId the fund id
    /// @return the current beneficiary
    function getCurrentBeneficiary(uint termId) external view returns (address) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        return fund.beneficiariesOrder[fund.currentCycle - 1];
    }

    /// @notice function to get the beneficiary from the next cycle
    /// @param termId the fund id
    /// @return the next beneficiary
    function getNextBeneficiary(uint termId) external view returns (address) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        return fund.beneficiariesOrder[fund.currentCycle];
    }

    /// @notice function to get the depositor collateral summary
    /// @param depositor the depositor address
    /// @param termId the collateral id
    /// @return if the user is a true member of the term
    /// @return current users locked collateral balance in wei
    /// @return current users unlocked collateral balance in wei
    /// @return initial users deposit in wei
    /// @return expulsion limit
    function getDepositorCollateralSummary(
        address depositor,
        uint termId
    ) external view returns (bool, uint, uint, uint, uint) {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];

        uint limit;
        if (!fund.isBeneficiary[depositor]) {
            limit = getToCollateralConversionRate(term.contributionAmount * 10 ** 18);
        } else {
            limit = getRemainingCyclesContributionWei(termId);
        }

        return (
            collateral.isCollateralMember[depositor],
            collateral.collateralMembersBank[depositor],
            collateral.collateralPaymentBank[depositor],
            collateral.collateralDepositByUser[depositor],
            limit
        );
    }

    /// @notice function to get fund information of a specific participant
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
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];

        bool isMoneyPotFrozen = _checkFrozenMoneyPot(participant, termId);

        return (
            fund.isParticipant[participant],
            fund.isBeneficiary[participant],
            fund.paidThisCycle[participant],
            fund.autoPayEnabled[participant],
            fund.beneficiariesPool[participant],
            isMoneyPotFrozen
        );
    }

    /// @notice Gets the user yield summary
    /// @param user the depositor address
    /// @param termId the collateral id
    /// @return if the user opted in for yield
    /// @return amount withdrawn from yield
    /// @return amount withdrawn from collateral
    /// @return amount available in yield
    /// @return amount deposited by user in yield
    /// @return amount of yield distributed
    function getUserYieldSummary(
        address user,
        uint termId
    ) external view returns (bool, uint, uint, uint, uint, uint) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        uint yieldDistributed = LibYieldGeneration._unwithdrawnUserYieldGenerated(termId, user);

        return (
            yield.hasOptedIn[user],
            yield.withdrawnYield[user],
            yield.withdrawnCollateral[user],
            yield.availableYield[user],
            yield.depositedCollateralByUser[user],
            yieldDistributed
        );
    }

    /// @notice function to get cycle information of a specific participant
    /// @param participant the user to get the info from
    /// @param termId the fund id
    /// @return on participant set
    /// @return on beneficiary set
    /// @return on defaulter set
    function getUserSet(address participant, uint termId) external view returns (bool, bool, bool) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        bool onParticipantSet = EnumerableSet.contains(fund._participants, participant);
        bool onBeneficiarySet = EnumerableSet.contains(fund._beneficiaries, participant);
        bool onDefaulterSet = EnumerableSet.contains(fund._defaulters, participant);
        return (onParticipantSet, onBeneficiarySet, onDefaulterSet);
    }

    /// @notice Called to check how much collateral a user can withdraw
    /// @param termId term id
    /// @param user depositor address
    /// @return allowedWithdrawal amount the amount of collateral the depositor can withdraw
    function getWithdrawableUserBalance(
        uint termId,
        address user
    ) public view returns (uint allowedWithdrawal) {
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        uint userCollateral = collateral.collateralMembersBank[user];
        uint availableYield = yield.availableYield[user];
        bool expelledBeforeBeingBeneficiary = fund.expelledBeforeBeneficiary[user];

        if (
            collateral.state == LibCollateralStorage.CollateralStates.ReleasingCollateral ||
            expelledBeforeBeingBeneficiary
        ) {
            allowedWithdrawal = userCollateral + availableYield;
        } else if (collateral.state == LibCollateralStorage.CollateralStates.CycleOngoing) {
            uint minRequiredCollateral;

            // Check if the user has paid this cycle or the next
            if (!fund.paidThisCycle[user] && !fund.paidNextCycle[user]) {
                // If none have been paid
                // Everything above 1.5 X remaining cycles contribution (RCC) can be withdrawn
                minRequiredCollateral = (getRemainingCyclesContributionWei(termId) * 15) / 10; // 1.5 X RCC in wei
            }

            // If the user has paid only one of the cycles, current or next
            if (
                (fund.paidThisCycle[user] && !fund.paidNextCycle[user]) ||
                (fund.paidNextCycle[user] && !fund.paidThisCycle[user])
            ) {
                // We need to check his remaining cycles and get the contribution amount for those
                uint remainingCycles = fund.totalAmountOfCycles - fund.currentCycle;
                uint contributionAmountWei = getToCollateralConversionRate(
                    term.contributionAmount * 10 ** 18
                );

                minRequiredCollateral = (remainingCycles * contributionAmountWei * 15) / 10; // 1.5 times of what the user needs to pay for the remaining cycles
            }

            // If the user has paid both cycles, current and next
            if (fund.paidThisCycle[user] && fund.paidNextCycle[user]) {
                // We need to check his remaining cycles and get the contribution amount for those
                uint remainingCycles = fund.totalAmountOfCycles - fund.currentCycle - 1;
                uint contributionAmountWei = getToCollateralConversionRate(
                    term.contributionAmount * 10 ** 18
                );

                minRequiredCollateral = (remainingCycles * contributionAmountWei * 15) / 10; // 1.5 times of what the user needs to pay for the remaining cycles
            }

            // Collateral must be higher than 1.5 X RCC
            if (userCollateral > minRequiredCollateral) {
                allowedWithdrawal = userCollateral - minRequiredCollateral + availableYield; // We allow to withdraw the positive difference
            } else {
                allowedWithdrawal = 0;
            }
        } else {
            allowedWithdrawal = 0;
        }
    }

    /// @notice Get all the terms a participant was expelled from
    /// @param participant the participant address
    /// @return an array the term ids on which the participant was expelled
    function getExpelledTerms(address participant) external view returns (uint[] memory) {
        uint[] memory joinedTerms = getAllJoinedTerms(participant);
        uint[] memory temporaryArray = new uint[](joinedTerms.length);
        uint termsCounter;
        uint joinedTermsLength = joinedTerms.length;

        for (uint i; i < joinedTermsLength; ) {
            if (wasExpelled(joinedTerms[i], participant)) {
                temporaryArray[termsCounter] = joinedTerms[i];

                /// @custom:unchecked-block without risk, termsCounter can't be higher than joinedTerms length
                unchecked {
                    ++termsCounter;
                }
            }

            /// @custom:unchecked-block without risk, i can't be higher than joinedTerms length
            unchecked {
                ++i;
            }
        }

        uint[] memory termsExpelled = new uint[](termsCounter);

        for (uint i; i < termsCounter; ) {
            termsExpelled[i] = temporaryArray[i];

            /// @custom:unchecked-block without risk, i can't be higher than termsCounter
            unchecked {
                ++i;
            }
        }

        return termsExpelled;
    }

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param termId The term id
    /// @param member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function isUnderCollaterized(uint termId, address member) external view returns (bool) {
        return LibCollateral._isUnderCollaterized(termId, member);
    }

    /// @notice function to see if a user is exempted from paying a cycle
    /// @param termId the fund id
    /// @param cycle the cycle to check
    /// @param user the user to check
    /// @return true if the user is exempted
    function isExempted(uint termId, uint cycle, address user) external view returns (bool) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        return fund.isExemptedOnCycle[cycle].exempted[user];
    }

    /// @notice This function is used to check if a user has opted in for yield generation
    /// @param termId The term id for which the check is being made
    /// @param user The user for which the check is being made
    /// @return True if the user has opted in
    function userHasoptedInYG(uint termId, address user) external view returns (bool) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        return yield.hasOptedIn[user];
    }

    /// @notice This function is used to get a user APY
    /// @param termId The term id for which the APY is being calculated
    /// @param user The user for which the APY is being calculated
    /// @return The APY for the user
    function userAPY(uint termId, address user) external view returns (uint256) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];

        uint256 elaspedTime = block.timestamp - yield.startTimeStamp;

        uint userYieldGenerated = yield.withdrawnYield[user] +
            LibYieldGeneration._unwithdrawnUserYieldGenerated(termId, user);

        return
            (((userYieldGenerated * 10 ** 18) / collateral.collateralMembersBank[user]) *
                365 days) / elaspedTime;
    }

    /// @notice function to get fund information of a specific participant
    /// @param participant the user to get the info from
    /// @param termId the fund id
    /// @return paidThisCycle, true if has paid the current cycle
    /// @return paidNextCycle, true if has paid the next cycle
    function currentOrNextCyclePaid(
        address participant,
        uint termId
    ) external view returns (bool, bool) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];

        return (fund.paidThisCycle[participant], fund.paidNextCycle[participant]);
    }

    /// @notice checks if a participant have been a beneficiary
    /// @param termId the id of the term
    /// @param beneficiary the address of the participant to check
    /// @return true if the participant is a beneficiary
    function isBeneficiary(uint termId, address beneficiary) external view returns (bool) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        return fund.isBeneficiary[beneficiary];
    }

    /// @notice function to know if a user was expelled before
    /// @param termId the fund id
    /// @param user the user to check
    /// @return true if the user was expelled before
    function wasExpelled(uint termId, address user) public view returns (bool) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];

        if (!fund.isParticipant[user] && !collateral.isCollateralMember[user]) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice checks if a participant have been expelled before being a beneficiary
    /// @param termId the id of the term
    /// @param user the address of the participant to check
    /// @return true if the participant is expelled before being a beneficiary
    function expelledBeforeBeneficiary(uint termId, address user) external view returns (bool) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        return fund.expelledBeforeBeneficiary[user];
    }

    /// @notice Gets the conversion rate of an amount in ETH to USD
    /// @param ethAmount The amount in ETH
    /// @return uint converted amount in USD correct to 18 decimals
    function getToStableConversionRate(uint ethAmount) external view returns (uint) {
        // NOTE: This will be made internal
        uint ethPrice = getLatestPrice();
        uint ethAmountInUSD = (ethPrice * ethAmount) / 10 ** 18;
        return ethAmountInUSD;
    }

    /// @notice Get the term's remaining cycles
    /// @param termId the term id
    /// @return remaining cycles
    function getRemainingCycles(uint termId) public view returns (uint) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];

        return (1 + fund.totalAmountOfCycles - fund.currentCycle);
    }

    /// @notice Get the term's remaining contribution amount converted from USDC to wei
    /// @param termId the term id
    /// @return remaining cycles contribution in wei
    function getRemainingCyclesContributionWei(uint termId) public view returns (uint) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];

        uint remainingCycles;

        if (fund.currentState == LibFundStorage.FundStates.InitializingFund) {
            remainingCycles = term.totalParticipants;
        } else if (
            fund.currentState == LibFundStorage.FundStates.AcceptingContributions ||
            fund.currentState == LibFundStorage.FundStates.AwardingBeneficiary
        ) {
            remainingCycles = getRemainingCycles(termId);
        } else if (fund.currentState == LibFundStorage.FundStates.CycleOngoing) {
            remainingCycles = getRemainingCycles(termId) - 1;
        } else if (fund.currentState == LibFundStorage.FundStates.FundClosed) {
            remainingCycles = 0;
        }

        uint contributionAmountWei = getToCollateralConversionRate(
            term.contributionAmount * 10 ** 18
        );

        return remainingCycles * contributionAmountWei;
    }

    /// @notice Called to check the minimum collateral amount to deposit in wei
    /// @param termId term id
    /// @param depositorIndex the index the depositor wants to join
    /// @return amount the minimum collateral amount to deposit in wei
    /// @dev The minimum collateral amount is calculated based on the index on the depositors array
    /// @dev The return value should be the minimum msg.value when calling joinTerm
    /// @dev C = 1.5 Cp (Tp - I) where C = minimum collateral amount, Cp = contribution amount,
    ///      Tp = total participants, I = depositor index (starts at 0). 1.5
    function minCollateralToDeposit(
        uint termId,
        uint depositorIndex
    ) public view returns (uint amount) {
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];

        require(depositorIndex < term.totalParticipants, "TT-GF-01");

        uint contributionAmountInWei = getToCollateralConversionRate(
            term.contributionAmount * 10 ** 18
        );

        amount = (contributionAmountInWei * (term.totalParticipants - depositorIndex) * 150) / 100;
    }

    /// @notice Gets latest ETH / USD price
    /// @dev Revert if there is problem with chainlink data
    /// @return uint latest price in Wei Note: 18 decimals
    function getLatestPrice() public view returns (uint) {
        LibTermStorage.TermConsts storage termConsts = LibTermStorage._termConsts();

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
            "TT-GF-02"
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
            "TT-GF-02"
        );

        int256 ethUSDC = price_ethUSD / price_usdUSDC;

        return uint(ethUSDC * 10 ** 18); //18 decimals
    }

    /// @notice Gets the conversion rate of an amount in USD to ETH
    /// @param USDAmount The amount in USD with 18 decimals
    /// @return uint converted amount in wei
    function getToCollateralConversionRate(uint USDAmount) public view returns (uint) {
        uint ethPrice = getLatestPrice();
        uint USDAmountInEth = (USDAmount * 10 ** 18) / ethPrice;
        return USDAmountInEth;
    }

    /// @notice This function is used to get the total yield generated for a term
    /// @param termId The term id for which the yield is being calculated
    /// @return The total yield generated for the term
    function totalYieldGenerated(uint termId) public view returns (uint) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        uint totalWithdrawnYield;

        address[] memory arrayToCheck = yield.yieldUsers;
        uint arrayLength = arrayToCheck.length;

        for (uint i; i < arrayLength; ) {
            totalWithdrawnYield += yield.withdrawnYield[arrayToCheck[i]];

            /// @custom:unchecked-block without risk, i can't be higher than arrayLength
            unchecked {
                ++i;
            }
        }

        uint sharesInEth = LibYieldGeneration._sharesToEth(termId, yield);

        if (sharesInEth > yield.currentTotalDeposit) {
            return totalWithdrawnYield + sharesInEth - yield.currentTotalDeposit;
        } else {
            return totalWithdrawnYield;
        }
    }

    /// @notice Get all the terms a participant is part of
    /// @param participant the participant address
    /// @return an array with the term ids the participant is part of
    function getAllJoinedTerms(address participant) public view returns (uint[] memory) {
        LibTermStorage.TermStorage storage termStorage = LibTermStorage._termStorage();
        uint[] memory participantTermIds = termStorage.participantToTermId[participant];
        return participantTermIds;
    }

    /// @notice Get all the terms a participant is part of by a given state
    /// @param participant the participant address
    /// @param state the term state
    /// @return an array with the term ids the participant is part of, giving the state of the term
    function getJoinedTermsByState(
        address participant,
        LibTermStorage.TermStates state
    ) public view returns (uint[] memory) {
        uint[] memory joinedTerms = getAllJoinedTerms(participant);
        uint[] memory temporaryArray = new uint[](joinedTerms.length);
        uint termsCounter;
        uint joinedTermsLength = joinedTerms.length;

        for (uint i; i < joinedTermsLength; ) {
            if (LibTermStorage._termStorage().terms[joinedTerms[i]].state == state) {
                temporaryArray[termsCounter] = joinedTerms[i];

                /// @custom:unchecked-block without risk, termsCounter can't be higher than joinedTerms length
                unchecked {
                    ++termsCounter;
                }
            }

            /// @custom:unchecked-block without risk, i can't be higher than joinedTerms length
            unchecked {
                ++i;
            }
        }

        uint[] memory userTermsByState = new uint[](termsCounter);

        for (uint i; i < termsCounter; ) {
            userTermsByState[i] = temporaryArray[i];
            unchecked {
                ++i;
            }
        }

        return userTermsByState;
    }

    /// @notice Gets the remaining positions in a term and the corresponding security amount
    /// @param termId the term id
    /// @dev Available positions starts at 0
    /// @return availablePositions an array with the available positions
    /// @return securityAmount an array with the security amount for each available position
    function getAvailablePositionsAndSecurityAmount(
        uint termId
    ) public view returns (uint[] memory, uint[] memory) {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];

        if (collateral.state != LibCollateralStorage.CollateralStates.AcceptingCollateral) {
            return (new uint[](0), new uint[](0));
        }

        uint depositorsLength = collateral.depositors.length;
        uint[] memory availablePositions = new uint[](depositorsLength);

        uint availablePositionsCounter;

        // Loop through the depositors array and get the available positions
        for (uint i; i < depositorsLength; ) {
            // The position is available if the depositor is address zero
            if (collateral.depositors[i] == address(0)) {
                // Add the position to the available positions array
                availablePositions[availablePositionsCounter] = i;

                // And increment the available positions counter
                unchecked {
                    ++availablePositionsCounter;
                }
            }

            /// @custom:unchecked-block without risk, i can't be higher than depositors length
            unchecked {
                ++i;
            }
        }

        // Create the arrays to return
        // The available positions array will have the length of the available positions counter
        // The security amount array will have the same length
        uint[] memory availablePositionsArray = new uint[](availablePositionsCounter);
        uint[] memory securityAmountArray = new uint[](availablePositionsCounter);

        // Loop through the available positions counter and fill the arrays
        for (uint i; i < availablePositionsCounter; ) {
            availablePositionsArray[i] = availablePositions[i];
            // Get the security amount for the position
            securityAmountArray[i] = minCollateralToDeposit(termId, availablePositions[i]);
            unchecked {
                ++i;
            }
        }

        // Return the arrays, the available positions array and the security amount array are coupled
        // availablePositionsArray[0] will have the securityAmountArray[0] and so on
        return (availablePositionsArray, securityAmountArray);
    }

    /// @notice Gets the remaining registration period for a term
    /// @dev Revert if nobody has deposited
    /// @param termId the term id
    /// @return remaining contribution period
    function getRemainingRegistrationTime(uint termId) public view returns (uint) {
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];
        if (
            collateral.firstDepositTime == 0 ||
            block.timestamp >= collateral.firstDepositTime + term.registrationPeriod
        ) {
            return 0;
        } else {
            return collateral.firstDepositTime + term.registrationPeriod - block.timestamp;
        }
    }

    /// @notice returns the time left to contribute for this cycle
    /// @param termId the fund id
    /// @return the time left to contribute
    function getRemainingContributionTime(uint termId) public view returns (uint) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];
        if (fund.currentState != LibFundStorage.FundStates.AcceptingContributions) {
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

    /// @notice Get the term's remaining time in the current cycle
    /// @param termId the term id
    /// @return remaining time in the current cycle
    function getRemainingCycleTime(uint termId) public view returns (uint) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];
        LibTermStorage.Term storage term = LibTermStorage._termStorage().terms[termId];
        uint cycleEndTimestamp = term.cycleTime * fund.currentCycle + fund.fundStart;
        if (block.timestamp > cycleEndTimestamp) {
            return 0;
        } else {
            return cycleEndTimestamp - block.timestamp;
        }
    }

    /// @notice checks if the money pot is frozen for a participant
    /// @param _participant the user to check
    /// @param _termId the fund id
    /// @return _isMoneyPotFrozen true if the money pot is frozen
    function _checkFrozenMoneyPot(
        address _participant,
        uint _termId
    ) internal view returns (bool _isMoneyPotFrozen) {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[_termId];
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];

        if (fund.expelledBeforeBeneficiary[_participant]) {
            _isMoneyPotFrozen = false;
        } else {
            uint neededCollateral = (110 * getRemainingCyclesContributionWei(_termId)) / 100; // 1.1 x RCC

            if (collateral.collateralMembersBank[_participant] < neededCollateral) {
                _isMoneyPotFrozen = true;
            } else {
                _isMoneyPotFrozen = false;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LibTermStorage} from "../libraries/LibTermStorage.sol";
import {LibCollateralStorage} from "../libraries/LibCollateralStorage.sol";
import {LibFundStorage} from "../libraries/LibFundStorage.sol";
import {LibGettersHelpers} from "../libraries/LibGettersHelpers.sol";

interface IGetters {
    /// @notice This function is used as a helper for front-end implementation
    /// @param termId The term id for which the summary is being requested
    /// @return term The term object
    /// @return collateralState The current state of the collateral
    /// @return fundState The current state of the fund
    /// @return nonUserRelated A helper struct with the following values:
    ///                        available positions, security deposits corresponding to each position,
    ///                        remaining registration time, remaining contribution time,
    ///                        remaining cycle time, remaining cycles, remaining cycles
    ///                        contribution in wei, latest price from Chainlink, collateral
    ///                        first deposit time in seconds, collateral counter members,
    ///                        fund start time in seconds, fund end time in seconds, current
    ///                        cycle, expelled participants, total amount of cycles, yield
    ///                        start time in seconds, total deposit in wei, current total
    ///                        deposit in wei, total shares
    function getTermRelatedSummary(
        uint termId
    )
        external
        view
        returns (
            LibTermStorage.Term memory term,
            LibCollateralStorage.CollateralStates collateralState,
            LibFundStorage.FundStates fundState,
            LibGettersHelpers.NonUserRelated memory nonUserRelated
        );

    /// @notice This function is used as a helper for front-end implementation
    /// @param user the depositor address
    /// @param termId the collateral id
    /// @return userRelated an object that contains the following values:
    ///                     user is collateral member, user is undercollaterized,
    ///                     current collateral balance, received collateral from defaults,
    ///                     initial deposited collateral, collateral expulsion limit,
    ///                     currently withdrawable balance, is fund member, is or was beneficiary,
    ///                     user paid current cycle, user paid next cycle in advance,
    ///                     user enabled autopay, user's money pot is frozen, user is exempted this
    ///                     cycle, the money pot pool the user can withdraw, the cycle the user got
    ///                     expelled (if applicable), is yield member, amount of collateral deposited
    ///                     in yield pool, amount of collateral withdrawn from yield pool, available
    ///                     yield to withdraw, amount of yield withdrawn, yield to be distributed
    function getUserRelatedSummary(
        address user,
        uint termId
    ) external view returns (LibGettersHelpers.UserRelated memory userRelated);

    /// @notice This function return the current constant values for oracles and yield providers
    /// @param firstAggregator The name of the first aggregator. Example: "ETH/USD"
    /// @param secondAggregator The name of the second aggregator. Example: "USDC/USD"
    /// @param zapAddress The name of the zap address. Example: "ZaynZap"
    /// @param vaultAddress The name of the vault address. Example: "ZaynVault"
    /// @return The addresses of the oracles and yield providers
    function getConstants(
        string memory firstAggregator,
        string memory secondAggregator,
        string memory zapAddress,
        string memory vaultAddress
    ) external view returns (address, address, address, address);

    /// @notice This function is used to get the current state of the yield lock
    /// @return The current state of the yield lock
    function getYieldLockState() external view returns (bool);

    /// @return the current term id
    /// @return the next term id
    function getTermsId() external view returns (uint, uint);

    /// @notice Gets the term object
    /// @param termId the term id
    /// @return the term object
    function getTermSummary(uint termId) external view returns (LibTermStorage.Term memory);

    /// @notice Gets the collateral summary of a term
    /// @param termId the id of the term
    /// @return if collateral is initialized
    /// @return current state of the collateral, see States struct in LibCollateralStorage.sol
    /// @return time of first deposit in seconds, 0 if no deposit occured yet
    /// @return current member count
    /// @return list of depositors
    function getCollateralSummary(
        uint termId
    )
        external
        view
        returns (bool, LibCollateralStorage.CollateralStates, uint, uint, address[] memory);

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
        returns (bool, LibFundStorage.FundStates, IERC20, address[] memory, uint, uint, uint, uint);

    /// @notice Gets the yield object
    /// @param termId the collateral id
    /// @return if the yield is initialized
    /// @return start time stamp for yield deposit
    /// @return total deposit
    /// @return current amount in yield
    /// @return amount of total shares
    /// @return list of yield users
    /// @return address of vault
    /// @return address of zap
    function getYieldSummary(
        uint termId
    ) external view returns (bool, uint, uint, uint, uint, address[] memory, address, address);

    /// @notice This function is used to get a term APY
    /// @param termId The term id for which the APY is being calculated
    /// @return The APY for the term
    function termAPY(uint termId) external view returns (uint256);

    /// @notice a function to get the needed allowance
    /// @param user the user address
    /// @return the needed allowance
    function getNeededAllowance(address user) external view returns (uint);

    /// @notice function to get the beneficiary from the current cycle
    /// @param termId the fund id
    /// @return the current beneficiary
    function getCurrentBeneficiary(uint termId) external view returns (address);

    /// @notice Gets the next beneficiary of a term
    /// @param termId the id of the term
    /// @return user address
    function getNextBeneficiary(uint termId) external view returns (address);

    /// @notice Gets a users collateral summary
    /// @param depositor address
    /// @param termId the id of the term
    /// @return if the user is a true member of the term
    /// @return current users locked collateral balance in wei
    /// @return current users unlocked collateral balance in wei
    /// @return initial users deposit in wei
    /// @return expulsion limit
    function getDepositorCollateralSummary(
        address depositor,
        uint termId
    ) external view returns (bool, uint, uint, uint, uint);

    /// @notice function to get fund information of a specific participant
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
    ) external view returns (bool, bool, bool, bool, uint, bool);

    /// @notice Gets the user yield summary
    /// @param user the depositor address
    /// @param termId the collateral id
    /// @return if the user opted in for yield
    /// @return amount withdrawn from yield
    /// @return amount withdrawn from collateral
    /// @return amount available in yield
    /// @return amount deposited by user in yield
    /// @return amount of yield distributed
    function getUserYieldSummary(
        address user,
        uint termId
    ) external view returns (bool, uint, uint, uint, uint, uint);

    /// @notice function to get cycle information of a specific participant
    /// @param participant the user to get the info from
    /// @param termId the fund id
    /// @return on participant set
    /// @return on beneficiary set
    /// @return on defaulter set
    function getUserSet(address participant, uint termId) external view returns (bool, bool, bool);

    /// @notice Called to check how much collateral a user can withdraw
    /// @param termId term id
    /// @param user depositor address
    /// @return allowedWithdrawal amount the amount of collateral the depositor can withdraw
    function getWithdrawableUserBalance(
        uint termId,
        address user
    ) external view returns (uint allowedWithdrawal);

    /// @notice Get all the terms a participant was expelled from
    /// @param participant the participant address
    /// @return an array the term ids on which the participant was expelled
    function getExpelledTerms(address participant) external view returns (uint[] memory);

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param termId The term id
    /// @param member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function isUnderCollaterized(uint termId, address member) external view returns (bool);

    /// @notice Gets if a user is exempted from paying for a specefic cycle
    /// @param termId the id of the term
    /// @param cycle number
    /// @param user address
    /// @return true or false
    function isExempted(uint termId, uint cycle, address user) external view returns (bool);

    /// @notice This function is used to check if a user has opted in for yield generation
    /// @param termId The term id for which the check is being made
    /// @param user The user for which the check is being made
    /// @return True if the user has opted in
    function userHasoptedInYG(uint termId, address user) external view returns (bool);

    /// @notice This function is used to get a user APY
    /// @param termId The term id for which the APY is being calculated
    /// @param user The user for which the APY is being calculated
    /// @return The APY for the user
    function userAPY(uint termId, address user) external view returns (uint256);

    /// @notice function to get fund information of a specific participant
    /// @param participant the user to get the info from
    /// @param termId the fund id
    /// @return paidThisCycle, true if has paid the current cycle
    /// @return paidNextCycle, true if has paid the next cycle
    function currentOrNextCyclePaid(
        address participant,
        uint termId
    ) external view returns (bool, bool);

    /// @param termId the id of the term
    /// @param beneficiary the address of the participant to check
    /// @return true if the participant is a beneficiary
    function isBeneficiary(uint termId, address beneficiary) external view returns (bool);

    /// @notice Gets if a user is expelled from a specefic term
    /// @param termId the id of the term
    /// @param user address
    /// @return true or false
    function wasExpelled(uint termId, address user) external view returns (bool);

    /// @notice checks if a participant have been expelled before being a beneficiary
    /// @param termId the id of the term
    /// @param user the address of the participant to check
    /// @return true if the participant is expelled before being a beneficiary
    function expelledBeforeBeneficiary(uint termId, address user) external view returns (bool);

    /// @notice Gets the conversion rate of an amount in ETH to USD
    /// @param ethAmount The amount in ETH
    /// @return uint converted amount in USD correct to 18 decimals
    function getToStableConversionRate(uint ethAmount) external view returns (uint);

    /// @notice Gets all remaining cycles of a term
    /// @param termId the id of the term
    /// @return remaining cycles
    function getRemainingCycles(uint termId) external view returns (uint);

    /// @notice Gets the expected remaining contribution amount for users in a term
    /// @param termId the id of the term
    /// @return total remaining contribution in wei
    function getRemainingCyclesContributionWei(uint termId) external view returns (uint);

    /// @notice Called to check the minimum collateral amount to deposit in wei
    /// @param termId term id
    /// @param depositorIndex the index the depositor wants to join
    /// @return amount the minimum collateral amount to deposit in wei
    /// @dev The minimum collateral amount is calculated based on the index on the depositors array
    /// @dev The return value should be the minimum msg.value when calling joinTerm
    /// @dev C = 1.5 Cp (Tp - I) where C = minimum collateral amount, Cp = contribution amount,
    ///      Tp = total participants, I = depositor index (starts at 0). 1.5
    function minCollateralToDeposit(uint termId, uint depositorIndex) external view returns (uint);

    /// @notice Gets latest ETH / USD price
    /// @dev Revert if there is problem with chainlink data
    /// @return uint latest price in Wei Note: 18 decimals
    function getLatestPrice() external view returns (uint);

    /// @notice Gets the conversion rate of an amount in USD to ETH
    /// @param USDAmount The amount in USD with 18 decimals
    /// @return uint converted amount in wei
    function getToCollateralConversionRate(uint USDAmount) external view returns (uint);

    /// @notice This function is used to get the total yield generated for a term
    /// @param termId The term id for which the yield is being calculated
    /// @return The total yield generated for the term
    function totalYieldGenerated(uint termId) external view returns (uint);

    /// @notice Get all the terms a participant is part of
    /// @param participant the participant address
    /// @return an array with the term ids the participant is part of
    function getAllJoinedTerms(address participant) external view returns (uint[] memory);

    /// @notice Get all the terms a participant is part of by a given state
    /// @param participant the participant address
    /// @param state the term state
    /// @return an array with the term ids the participant is part of, giving the state of the term
    function getJoinedTermsByState(
        address participant,
        LibTermStorage.TermStates state
    ) external view returns (uint[] memory);

    /// @notice Gets the remaining positions in a term and the corresponding security amount
    /// @param termId the term id
    /// @dev Available positions starts at 0
    /// @return availablePositions an array with the available positions
    /// @return securityAmount an array with the security amount for each available position
    function getAvailablePositionsAndSecurityAmount(
        uint termId
    ) external view returns (uint[] memory, uint[] memory);

    /// @notice Gets the remaining registration period for a term
    /// @dev Revert if nobody have deposited
    /// @param termId the term id
    /// @return remaining contribution period
    function getRemainingRegistrationTime(uint termId) external view returns (uint);

    /// @notice Must return 0 before closing a contribution period
    /// @param termId the id of the term
    /// @return remaining contribution time in seconds
    function getRemainingContributionTime(uint termId) external view returns (uint);

    /// @notice Must be 0 before starting a new cycle
    /// @param termId the id of the term
    /// @return remaining cycle time in seconds
    function getRemainingCycleTime(uint termId) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynVaultV2TakaDao {
    function totalSupply() external view returns (uint256);

    function depositZap(uint256 _amount, uint256 _term) external;

    function withdrawZap(uint256 _shares, uint256 _term) external;

    function want() external view returns (address);

    function balance() external view returns (uint256);

    function strategy() external view returns (address);

    function balanceOf(uint256 term) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

interface IZaynZapV2TakaDAO {
    function zapInEth(address vault, uint256 termID) external payable;

    function zapOutETH(address vault, uint256 _shares, uint256 termID) external returns (uint);

    function toggleTrustedSender(address _trustedSender, bool _allow) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IGetters} from "../interfaces/IGetters.sol";

import {LibCollateralStorage} from "./LibCollateralStorage.sol";
import {LibFundStorage} from "./LibFundStorage.sol";

library LibCollateral {
    event OnCollateralStateChanged(
        uint indexed termId,
        LibCollateralStorage.CollateralStates indexed oldState,
        LibCollateralStorage.CollateralStates indexed newState
    ); // Emits when the state of the collateral changes
    event OnReimbursementWithdrawn(
        uint indexed termId,
        address indexed participant,
        address receiver,
        uint indexed amount
    ); // Emits when a participant withdraws their reimbursement

    /// @notice Sets the state of the collateral
    /// @param _termId term id
    /// @param _newState collateral state
    function _setState(uint _termId, LibCollateralStorage.CollateralStates _newState) internal {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];
        LibCollateralStorage.CollateralStates oldState = collateral.state;
        collateral.state = _newState;
        emit OnCollateralStateChanged(_termId, oldState, _newState);
    }

    /// @notice Allow a user to withdraw their reimbursement
    /// @dev Reverts if the fund does not exists or if the user has nothing to claim
    /// @param _termId term id
    /// @param _participant Address of the depositor
    /// @param _receiver Address of the receiver
    function _withdrawReimbursement(
        uint _termId,
        address _participant,
        address _receiver
    ) internal {
        require(LibFundStorage._fundExists(_termId), "TT-LC-01");
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];

        uint amount = collateral.collateralPaymentBank[_participant];
        require(amount > 0, "TT-LC-02");
        collateral.collateralPaymentBank[_participant] = 0;

        (bool success, ) = payable(_receiver).call{value: amount}("");
        require(success);

        emit OnReimbursementWithdrawn(_termId, _participant, _receiver, amount);
    }

    /// @notice Checks if a user has a collateral below 1.0x of total contribution amount
    /// @dev This will revert if called during ReleasingCollateral or after
    /// @param _termId The fund id
    /// @param _member The user to check for
    /// @return Bool check if member is below 1.0x of collateralDeposit
    function _isUnderCollaterized(uint _termId, address _member) internal view returns (bool) {
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[_termId];

        uint collateralLimit;
        uint memberCollateral = collateral.collateralMembersBank[_member];

        if (!LibFundStorage._fundExists(_termId)) {
            // Only check here when starting the term
            (, , , , collateralLimit) = IGetters(address(this)).getDepositorCollateralSummary(
                _member,
                _termId
            );
        } else {
            collateralLimit = IGetters(address(this)).getRemainingCyclesContributionWei(_termId);
        }

        return (memberCollateral < collateralLimit);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibCollateralStorage {
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
        uint firstDepositTime; // Time when the first deposit was made in seconds
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

library LibFundStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

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
        mapping(address => bool) expelledBeforeBeneficiary; // Mapping to keep track of who has been expelled before being a beneficiary
        mapping(address => bool) paidNextCycle; // Mapping to keep track of who has paid for the next cycle
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

library LibGettersHelpers {
    struct NonUserRelated {
        // Positions and security deposits related
        uint[] availablePositions;
        uint[] securityDeposits;
        // Times and contributions related
        uint remainingRegistrationTime; // In seconds
        uint remainingContributionTime; // In seconds
        uint remainingCycleTime; // In seconds
        uint remainingCycles;
        uint rcc; // Remaining Contribution Cycles in wei
        uint latestPrice; // From Chainlink
        // Collateral related
        bool collateralInitialized;
        uint collateralFirstDepositTime; // In seconds
        uint collateralCounterMembers; // Member count
        // Fund related
        bool fundInitialized;
        uint fundStartTime; // In seconds
        uint fundEndTime; // In seconds
        uint fundCurrentCycle;
        uint fundExpellantsCount;
        uint fundTotalCycles;
        address[] fundBeneficiariesOrder;
        // Yield related
        bool yieldInitialized;
        uint yieldStartTime; // In seconds
        uint yieldTotalDeposit; // In wei
        uint yieldCurrentTotalDeposit; // In wei
        uint yieldTotalShares;
        address[] yieldUsers;
    }

    struct UserRelated {
        // Collateral related
        bool collateralMember;
        bool isUnderCollaterized;
        uint membersBank;
        uint paymentBank;
        uint deposited;
        uint expulsonLimit;
        uint withdrawableBalance;
        // Fund related
        bool fundMember;
        bool beneficiary;
        bool currentCyclePaid;
        bool nextCyclePaid;
        bool autoPayer;
        bool moneyPotFrozen;
        bool exemptedThisCycle;
        uint pool;
        uint cycleExpelled;
        // Yield related
        bool yieldMember;
        uint collateralDepositedInYield;
        uint collateralWithdrawnFromYield;
        uint yieldAvailable;
        uint yieldWithdrawn;
        uint distributedYield;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibTermStorage {
    bytes32 constant TERM_CONSTS_POSITION = keccak256("diamond.standard.term.consts");
    bytes32 constant TERM_STORAGE_POSITION = keccak256("diamond.standard.term.storage");

    enum TermStates {
        InitializingTerm,
        ActiveTerm,
        ExpiredTerm,
        ClosedTerm
    }

    struct TermConsts {
        mapping(string => address) aggregatorsAddresses; // "ETH/USD" => address , "USDC/USD" => address
    }

    struct Term {
        bool initialized;
        TermStates state;
        address termOwner;
        uint creationTime; // In seconds
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

import {IZaynZapV2TakaDAO} from "../interfaces/IZaynZapV2TakaDAO.sol";
import {IZaynVaultV2TakaDao} from "../interfaces/IZaynVaultV2TakaDao.sol";

import {LibYieldGenerationStorage} from "../libraries/LibYieldGenerationStorage.sol";

library LibYieldGeneration {
    event OnYieldClaimed(
        uint indexed termId,
        address indexed user,
        address receiver,
        uint indexed amount
    ); // Emits when a user claims their yield

    /// @notice This function is used to deposit collateral for yield generation
    /// @param _termId The term id for which the collateral is being deposited
    /// @param _ethAmount The amount of collateral being deposited
    function _depositYG(uint _termId, uint _ethAmount) internal {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        yield.totalDeposit = _ethAmount;
        yield.currentTotalDeposit = _ethAmount;

        address vaultAddress = yield.providerAddresses["ZaynVault"];

        IZaynZapV2TakaDAO(yield.providerAddresses["ZaynZap"]).zapInEth{value: _ethAmount}(
            vaultAddress,
            _termId
        );

        yield.totalShares = IZaynVaultV2TakaDao(vaultAddress).balanceOf(_termId);
    }

    /// @notice This function is used to withdraw collateral from the yield generation protocol
    /// @param _termId The term id for which the collateral is being withdrawn
    /// @param _collateralAmount The amount of collateral being withdrawn
    /// @param _user The user address that is withdrawing the collateral
    /// @return The amount of yield withdrawn
    function _withdrawYG(
        uint _termId,
        uint256 _collateralAmount,
        address _user
    ) internal returns (uint) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint neededShares = _neededShares(_collateralAmount, yield.totalShares, yield.totalDeposit);

        yield.withdrawnCollateral[_user] += _collateralAmount;
        yield.currentTotalDeposit -= _collateralAmount;

        address zapAddress = yield.providerAddresses["ZaynZap"];
        address vaultAddress = yield.providerAddresses["ZaynVault"];

        uint sharesBalance = IZaynVaultV2TakaDao(vaultAddress).balanceOf(_termId);

        // Prevent rounding errors
        if (neededShares > sharesBalance) {
            if (neededShares - sharesBalance < 10000) {
                neededShares = sharesBalance;
            }
        } else {
            if (sharesBalance - neededShares < 10000) {
                neededShares = sharesBalance;
            }
        }

        uint withdrawnAmount = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
            vaultAddress,
            neededShares,
            _termId
        );

        if (withdrawnAmount < _collateralAmount) {
            return 0;
        } else {
            uint withdrawnYield = withdrawnAmount - _collateralAmount;
            yield.withdrawnYield[_user] += withdrawnYield;
            yield.availableYield[_user] += withdrawnYield;

            return withdrawnYield;
        }
    }

    /// @notice Conversion from shares to eth
    /// @param _termId The term id
    /// @param _yield The yield generation struct
    /// @return Wei equivalent of the shares
    function _sharesToEth(
        uint _termId,
        LibYieldGenerationStorage.YieldGeneration storage _yield
    ) internal view returns (uint) {
        uint termBalance = IZaynVaultV2TakaDao(_yield.providerAddresses["ZaynVault"]).balanceOf(
            _termId
        );

        uint pricePerShare = IZaynVaultV2TakaDao(_yield.providerAddresses["ZaynVault"])
            .getPricePerFullShare();

        return (termBalance * pricePerShare) / 10 ** 18;
    }

    /// @notice Conversion from eth to shares
    /// @param _collateralAmount The amount of collateral to withdraw
    /// @param _totalShares The total shares in the yield from the term
    /// @param _totalDeposit The total deposit in the yield from the term
    /// @return The amount of shares equivalent to a collateral amount
    function _neededShares(
        uint _collateralAmount,
        uint _totalShares,
        uint _totalDeposit
    ) internal pure returns (uint) {
        if (_totalDeposit == 0) return 0;
        return ((_collateralAmount * _totalShares) / _totalDeposit);
    }

    /// @notice This function is used to get the current total yield generated for a term
    /// @param _termId The term id for which the yield is being calculated
    /// @return The total yield generated for the term
    function _currentYieldGenerated(uint _termId) internal view returns (uint) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint termBalance = IZaynVaultV2TakaDao(yield.providerAddresses["ZaynVault"]).balanceOf(
            _termId
        );
        uint pricePerShare = IZaynVaultV2TakaDao(yield.providerAddresses["ZaynVault"])
            .getPricePerFullShare();

        uint sharesInEth = (termBalance * pricePerShare) / 10 ** 18;
        if (sharesInEth > yield.currentTotalDeposit) {
            return sharesInEth - yield.currentTotalDeposit;
        } else {
            return 0;
        }
    }

    /// @notice This function is used to get the yield distribution ratio for a user
    /// @param _termId The term id for which the ratio is being calculated
    /// @param _user The user for which the ratio is being calculated
    /// @return The yield distribution ratio for the user
    function _yieldDistributionRatio(uint _termId, address _user) internal view returns (uint256) {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        if (yield.currentTotalDeposit == 0) {
            return 0;
        } else {
            return
                ((yield.depositedCollateralByUser[_user] - yield.withdrawnCollateral[_user]) *
                    10 ** 18) / yield.currentTotalDeposit;
        }
    }

    /// @notice This function is used to get the total yield generated for a user
    /// @param termId The term id for which the yield is being calculated
    /// @param user The user for which the yield is being calculated
    /// @return The total yield generated for the user
    function _unwithdrawnUserYieldGenerated(
        uint termId,
        address user
    ) internal view returns (uint) {
        uint yieldDistributed = (_currentYieldGenerated(termId) *
            _yieldDistributionRatio(termId, user)) / 10 ** 18;

        return yieldDistributed;
    }

    /// @notice This function is used to claim the available yield for a user
    /// @param _termId The term id for which the yield is being claimed
    /// @param _user The user for which the yield is being claimed
    /// @param _receiver The receiver of the yield
    function _claimAvailableYield(uint _termId, address _user, address _receiver) internal {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint availableYield = yield.availableYield[_user];

        require(availableYield > 0, "TT-LYG-01");

        yield.availableYield[_user] = 0;
        (bool success, ) = payable(_receiver).call{value: availableYield}("");
        require(success);

        emit OnYieldClaimed(_termId, _user, _receiver, availableYield);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library LibYieldGenerationStorage {
    bytes32 constant YIELD_PROVIDERS_POSITION = keccak256("diamond.standard.yield.providers");
    bytes32 constant YIELD_STORAGE_POSITION = keccak256("diamond.standard.yield.storage");
    bytes32 constant YIELD_LOCK_POSITION = keccak256("diamond.standard.yield.lock");

    enum YGProviders {
        InHouse,
        ZaynFi
    }

    struct YieldLock {
        bool yieldLock;
    }

    // Both index 0 are reserved for ZaynFi
    struct YieldProviders {
        mapping(string => address) providerAddresses;
    }

    struct YieldGeneration {
        bool initialized;
        YGProviders provider;
        mapping(string => address) providerAddresses;
        uint startTimeStamp; // In seconds
        uint totalDeposit; // In wei
        uint currentTotalDeposit; // In wei
        uint totalShares;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield; // In wei
        mapping(address => uint256) withdrawnCollateral; // In wei
        mapping(address => uint256) availableYield; // In wei
        mapping(address => uint256) depositedCollateralByUser; // In wei
    }

    struct YieldStorage {
        mapping(uint => YieldGeneration) yields; // termId => YieldGeneration struct
    }

    function _yieldExists(uint termId) internal view returns (bool) {
        return _yieldStorage().yields[termId].initialized;
    }

    function _yieldLock() internal pure returns (YieldLock storage yieldLock) {
        bytes32 position = YIELD_LOCK_POSITION;
        assembly {
            yieldLock.slot := position
        }
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