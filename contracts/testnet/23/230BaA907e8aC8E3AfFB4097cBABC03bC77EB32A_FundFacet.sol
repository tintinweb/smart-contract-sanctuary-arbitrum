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
import {IFund} from "../interfaces/IFund.sol";
import {ICollateral} from "../interfaces/ICollateral.sol";
import {IGetters} from "../interfaces/IGetters.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibCollateral} from "../libraries/LibCollateral.sol";
import {LibFund} from "../libraries/LibFund.sol";
import {LibTerm} from "../libraries/LibTerm.sol";
import {LibTermOwnership} from "../libraries/LibTermOwnership.sol";

/// @title Takaturn Fund
/// @author Mohammed Haddouti
/// @notice This is used to operate the Takaturn fund
/// @dev v3.0 (Diamond)
contract FundFacet is IFund {
    using EnumerableSet for EnumerableSet.AddressSet;

    uint public constant FUND_VERSION = 2; // The version of the contract

    event OnTermStart(uint indexed termId); // Emits when a new term starts, this also marks the start of the first cycle
    event OnFundStateChanged(
        uint indexed termId,
        uint indexed currentCycle,
        LibFund.FundStates indexed newState
    ); // Emits when state has updated
    event OnPaidContribution(uint indexed termId, address indexed payer, uint indexed currentCycle); // Emits when participant pays the contribution
    event OnBeneficiaryAwarded(uint indexed termId, address indexed beneficiary); // Emits when beneficiary is selected for this cycle
    event OnFundWithdrawn(uint indexed termId, address indexed claimant, uint indexed amount); // Emits when a chosen beneficiary claims their fund
    event OnParticipantDefaulted(
        uint indexed termId,
        uint indexed currentCycle,
        address indexed defaulter
    ); // Emits when a participant didn't pay this cycle's contribution
    event OnDefaulterExpelled(
        uint indexed termId,
        uint indexed currentCycle,
        address indexed expellant
    ); // Emits when a defaulter can't compensate with the collateral
    event OnAutoPayToggled(uint indexed termId, address indexed participant, bool indexed enabled); // Emits when a participant succesfully toggles autopay

    modifier onlyTermOwner(uint termId) {
        LibTermOwnership._ensureTermOwner(termId);
        _;
    }

    /// Insufficient balance for transfer. Needed `required` but only
    /// `available` available.
    /// @param available balance available.
    /// @param required requested amount to transfer.
    error InsufficientBalance(uint available, uint required);

    /// @notice called by the term to init the fund
    /// @param termId the id of the term
    function initFund(uint termId) external {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        uint participantsArrayLength = fund.beneficiariesOrder.length;
        // Set and track participants
        for (uint i; i < participantsArrayLength; ) {
            EnumerableSet.add(fund._participants, fund.beneficiariesOrder[i]);
            fund.isParticipant[fund.beneficiariesOrder[i]] = true;
            unchecked {
                ++i;
            }
        }

        // Starts the first cycle
        _startNewCycle(termId);

        // Set timestamp of deployment, which will be used to determine cycle times
        // We do this after starting the first cycle to make sure the first cycle starts smoothly
        fund.fundStart = block.timestamp;
        //emit LibFund.OnTermStart(termId);
        emit OnTermStart(termId);
    }

    /// @notice starts a new cycle manually called by the owner. Only the first cycle starts automatically upon deploy
    /// @param termId the id of the term
    function startNewCycle(uint termId) external {
        _startNewCycle(termId);
    }

    /// @notice Must be called at the end of the contribution period after the time has passed by the owner
    /// @param termId the id of the term
    function closeFundingPeriod(uint termId) external {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];
        // Current cycle minus 1 because we use the previous cycle time as start point then  add contribution period
        require(
            block.timestamp >
                term.cycleTime * (fund.currentCycle - 1) + fund.fundStart + term.contributionPeriod,
            "Still time to contribute"
        );
        require(fund.currentState == LibFund.FundStates.AcceptingContributions, "Wrong state");

        address currentBeneficiary = IGetters(address(this)).getCurrentBeneficiary(termId);

        // We attempt to make the autopayers pay their contribution right away
        _autoPay(termId);

        // Only then award the beneficiary
        _setState(termId, LibFund.FundStates.AwardingBeneficiary);

        // We must check who hasn't paid and default them, check all participants based on beneficiariesOrder
        address[] memory participants = fund.beneficiariesOrder;

        uint participantsLength = participants.length;
        uint currentCycle = fund.currentCycle;
        for (uint i; i < participantsLength; ) {
            address p = participants[i];

            // The current beneficiary or someone who is exempt doesn't pay neither gets defaulted
            if (p == currentBeneficiary || fund.isExemptedOnCycle[currentCycle].exempted[p]) {
                unchecked {
                    ++i;
                }
                continue;
            }

            if (fund.paidThisCycle[p]) {
                // check where to restore the defaulter to, participants or beneficiaries
                if (fund.isBeneficiary[p]) {
                    EnumerableSet.add(fund._beneficiaries, p);
                } else {
                    EnumerableSet.add(fund._participants, p);
                }

                EnumerableSet.remove(fund._defaulters, p);
            } else if (!EnumerableSet.contains(fund._defaulters, p)) {
                // And we make sure that existing defaulters are ignored
                // If the current beneficiary is an expelled participant, only check previous beneficiaries
                if (IGetters(address(this)).wasExpelled(termId, currentBeneficiary)) {
                    if (fund.isBeneficiary[p]) {
                        _defaultParticipant(termId, p);
                    }
                } else {
                    _defaultParticipant(termId, p);
                }
            }
            unchecked {
                ++i;
            }
        }

        // Once we decided who defaulted and who paid, we can award the beneficiary for this cycle
        _awardBeneficiary(fund, term);
        if (!(fund.currentCycle < fund.totalAmountOfCycles)) {
            // If all cycles have passed, and the last cycle's time has passed, close the fund
            _closeFund(termId);
            return;
        }
    }

    /// @notice Fallback function, if the internal call fails somehow and the state gets stuck, allow owner to call the function again manually
    /// @dev This shouldn't happen, but is here in case there's an edge-case we didn't take into account, can possibly be removed in the future
    /// @param termId the id of the term
    function awardBeneficiary(uint termId) external onlyTermOwner(termId) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        require(fund.currentState == LibFund.FundStates.AwardingBeneficiary, "Wrong state");
        LibTerm.Term storage term = LibTerm._termStorage().terms[termId];

        _awardBeneficiary(fund, term);
    }

    /// @notice called by the owner to close the fund for emergency reasons.
    /// @param termId the id of the term
    function closeFund(uint termId) external onlyTermOwner(termId) {
        //require (!(currentCycle < totalAmountOfCycles), "Not all cycles have happened yet");
        _closeFund(termId);
    }

    /// @notice allow the owner to empty the fund if there's any excess fund left after 180 days,
    ///         this with the assumption that beneficiaries can't claim it themselves due to losing their keys for example,
    ///         and prevent the fund to be stuck in limbo
    /// @param termId the id of the term
    function emptyFundAfterEnd(uint termId) external onlyTermOwner(termId) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        require(
            fund.currentState == LibFund.FundStates.FundClosed &&
                block.timestamp > fund.fundEnd + 180 days,
            "Can't empty yet"
        );

        uint balance = fund.stableToken.balanceOf(address(this));
        if (balance > 0) {
            bool success = fund.stableToken.transfer(msg.sender, balance);
            require(success, "Transfer failed");
        }
    }

    /// @notice function to enable/disable autopay
    /// @param termId the id of the term
    function toggleAutoPay(uint termId) external {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        require(fund.isParticipant[msg.sender], "Not a participant");
        bool enabled = !fund.autoPayEnabled[msg.sender];
        fund.autoPayEnabled[msg.sender] = enabled;

        emit OnAutoPayToggled(termId, msg.sender, enabled);
    }

    /// @notice This is the function participants call to pay the contribution
    /// @param termId the id of the term
    function payContribution(uint termId) external {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];

        // Get the beneficiary for this cycle
        address currentBeneficiary = IGetters(address(this)).getCurrentBeneficiary(termId);

        require(fund.currentState == LibFund.FundStates.AcceptingContributions, "Wrong state");
        require(fund.isParticipant[msg.sender], "Not a participant");
        require(currentBeneficiary != msg.sender, "Beneficiary doesn't pay");
        require(!fund.paidThisCycle[msg.sender], "Already paid for cycle");
        require(
            !fund.isExemptedOnCycle[fund.currentCycle].exempted[msg.sender],
            "Participant is exempted this cycle"
        );

        _payContribution(termId, msg.sender, msg.sender);
    }

    /// @notice This function is here to give the possibility to pay using a different wallet
    /// @param termId the id of the term
    /// @param participant the address the msg.sender is paying for, the address must be part of the fund
    function payContributionOnBehalfOf(uint termId, address participant) external {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];

        address currentBeneficiary = IGetters(address(this)).getCurrentBeneficiary(termId);

        require(fund.currentState == LibFund.FundStates.AcceptingContributions, "Wrong state");
        require(fund.isParticipant[participant], "Not a participant");
        require(currentBeneficiary != participant, "Beneficiary doesn't pay");
        require(!fund.paidThisCycle[participant], "Already paid for cycle");
        require(
            !fund.isExemptedOnCycle[fund.currentCycle].exempted[participant],
            "Participant is exempted this cycle"
        );

        _payContribution(termId, msg.sender, participant);
    }

    /// @notice Called by the beneficiary to withdraw the fund
    /// @dev This follows the pull-over-push pattern.
    /// @param termId the id of the term
    function withdrawFund(uint termId) external {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[termId];
        // To withdraw the fund, the fund must be closed or the participant must be a beneficiary on
        // any of the past cycles.

        require(
            fund.currentState == LibFund.FundStates.FundClosed || fund.isBeneficiary[msg.sender],
            "You must be a beneficiary"
        );

        bool hasFundPool = fund.beneficiariesPool[msg.sender] > 0;
        bool hasFrozenPool = fund.beneficiariesFrozenPool[msg.sender];
        bool hasCollateralPool = collateral.collateralPaymentBank[msg.sender] > 0;

        require(hasFundPool || hasFrozenPool || hasCollateralPool, "Nothing to withdraw");

        if (hasFundPool) {
            _transferPoolToBeneficiary(termId, msg.sender);
        }

        if (hasCollateralPool) {
            ICollateral(address(this)).withdrawReimbursement(termId, msg.sender);
        }

        if (hasFrozenPool) {
            bool freeze = _freezePot(LibTerm._termStorage().terms[termId], fund, msg.sender);

            require(!freeze, "Need at least 1.1RCC collateral to unfreeze your fund");

            _transferPoolToBeneficiary(termId, msg.sender);
        }
    }

    /// @param termId the id of the term
    /// @param beneficiary the address of the participant to check
    /// @return true if the participant is a beneficiary
    function isBeneficiary(uint termId, address beneficiary) external view returns (bool) {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[termId];
        return fund.isBeneficiary[beneficiary];
    }

    /// @notice updates the state according to the input and makes sure the state can't be changed if the fund is closed. Also emits an event that this happened
    /// @param _termId The id of the term
    /// @param _newState The new state of the fund
    function _setState(uint _termId, LibFund.FundStates _newState) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];
        require(fund.currentState != LibFund.FundStates.FundClosed, "Fund closed");
        fund.currentState = _newState;
        emit OnFundStateChanged(_termId, fund.currentCycle, _newState);
    }

    /// @notice This starts the new cycle and can only be called internally. Used upon deploy
    /// @param _termId The id of the term
    function _startNewCycle(uint _termId) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[_termId];
        // currentCycle is 0 when this is called for the first time
        require(
            block.timestamp > term.cycleTime * fund.currentCycle + fund.fundStart,
            "Too early to start new cycle"
        );
        require(
            fund.currentState == LibFund.FundStates.InitializingFund ||
                fund.currentState == LibFund.FundStates.CycleOngoing,
            "Wrong state"
        );

        ++fund.currentCycle;
        uint length = fund.beneficiariesOrder.length;
        for (uint i; i < length; ) {
            fund.paidThisCycle[fund.beneficiariesOrder[i]] = false;
            unchecked {
                ++i;
            }
        }

        _setState(_termId, LibFund.FundStates.AcceptingContributions);

        // We attempt to make the autopayers pay their contribution right away
        _autoPay(_termId);
    }

    /// @notice function to attempt to make autopayers pay their contribution
    /// @param _termId the id of the term
    function _autoPay(uint _termId) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];

        // Get the beneficiary for this cycle
        address currentBeneficiary = IGetters(address(this)).getCurrentBeneficiary(_termId);

        address[] memory autoPayers = fund.beneficiariesOrder; // use beneficiariesOrder because it is a single array with all participants
        uint autoPayersArray = autoPayers.length;

        for (uint i; i < autoPayersArray; ) {
            address autoPayer = autoPayers[i];
            // The beneficiary doesn't pay
            if (currentBeneficiary == autoPayer) {
                unchecked {
                    ++i;
                }
                continue;
            }

            if (
                fund.autoPayEnabled[autoPayer] &&
                !fund.paidThisCycle[autoPayer] &&
                !fund.isExemptedOnCycle[fund.currentCycle].exempted[autoPayer]
            ) {
                _payContributionSafe(_termId, autoPayer, autoPayer);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice function to pay the actual contribution for the cycle, used for autopay to prevent reverts
    /// @param _termId the id of the term
    /// @param _payer the address that's paying
    /// @param _participant the (participant) address that's being paid for
    function _payContributionSafe(uint _termId, address _payer, address _participant) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[_termId];

        // Get the amount and do the actual transfer
        // This will only succeed if the sender approved this contract address beforehand
        uint amount = term.contributionAmount * 10 ** 6; // Deducted from user's wallet, six decimals
        try fund.stableToken.transferFrom(_payer, address(this), amount) returns (bool success) {
            if (success) {
                // Finish up, set that the participant paid for this cycle and emit an event that it's been done
                fund.paidThisCycle[_participant] = true;
                emit OnPaidContribution(_termId, _participant, fund.currentCycle);
            }
        } catch {}
    }

    /// @notice function to pay the actual contribution for the cycle
    /// @param _termId the id of the term
    /// @param _payer the address that's paying
    /// @param _participant the (participant) address that's being paid for
    function _payContribution(uint _termId, address _payer, address _participant) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[_termId];

        // Get the amount and do the actual transfer
        // This will only succeed if the sender approved this contract address beforehand
        uint amount = term.contributionAmount * 10 ** 6; // Deducted from user's wallet, six decimals

        bool success = fund.stableToken.transferFrom(_payer, address(this), amount);
        require(success, "Contribution failed, did you approve stable token?");

        // Finish up, set that the participant paid for this cycle and emit an event that it's been done
        fund.paidThisCycle[_participant] = true;
        emit OnPaidContribution(_termId, _participant, fund.currentCycle);
    }

    /// @notice Default the participant/beneficiary by checking the mapping first, then remove them from the appropriate array
    /// @param _termId The id of the term
    /// @param _defaulter The participant to default
    function _defaultParticipant(uint _termId, address _defaulter) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];
        // Try removing from participants first
        bool success = EnumerableSet.remove(fund._participants, _defaulter);

        // If that fails, we try removing from beneficiaries
        if (!success) {
            success = EnumerableSet.remove(fund._beneficiaries, _defaulter);
        }

        require(success, "Can't remove defaulter");
        EnumerableSet.add(fund._defaulters, _defaulter);

        emit OnParticipantDefaulted(_termId, fund.currentCycle, _defaulter);
    }

    /// @notice The beneficiary will be awarded here based on the beneficiariesOrder array.
    /// @notice It will loop through the array and choose the first in line to be eligible to be beneficiary.
    function _awardBeneficiary(LibFund.Fund storage _fund, LibTerm.Term storage _term) internal {
        address beneficiary = IGetters(address(this)).getCurrentBeneficiary(_term.termId);

        // Request contribution from the collateral for those who have to pay this cycle and haven't paid
        if (EnumerableSet.length(_fund._defaulters) > 0) {
            address[] memory expellants = ICollateral(address(this)).requestContribution(
                _term,
                EnumerableSet.values(_fund._defaulters)
            );

            uint expellantsLength = expellants.length;
            for (uint i; i < expellantsLength; ) {
                if (expellants[i] == address(0)) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
                _expelDefaulter(_fund, _term, expellants[i]);
                unchecked {
                    ++i;
                }
            }
        }

        // Remove participant from participants set..
        if (EnumerableSet.remove(_fund._participants, beneficiary)) {
            // ..Then add them to the benificiaries set
            EnumerableSet.add(_fund._beneficiaries, beneficiary);
        } // If this if-statement fails, this means we're dealing with a graced defaulter

        // Update the mapping to track who's been beneficiary
        _fund.isBeneficiary[beneficiary] = true;

        // Get the amount of participants that paid this cycle, and add that amount to the beneficiary's pool
        uint paidCount;
        address[] memory participants = _fund.beneficiariesOrder; // Use beneficiariesOrder here because it contains all active participants in a single array
        uint participantsLength = participants.length;
        for (uint i; i < participantsLength; ) {
            if (_fund.paidThisCycle[participants[i]]) {
                paidCount++;
            }
            unchecked {
                ++i;
            }
        }

        // Award the beneficiary with the pool or freeze the pot
        _freezePot(_term, _fund, beneficiary);

        _fund.beneficiariesPool[beneficiary] += _term.contributionAmount * paidCount * 10 ** 6; // Six decimals

        emit OnBeneficiaryAwarded(_term.termId, beneficiary);
        _setState(_term.termId, LibFund.FundStates.CycleOngoing);
    }

    /// @notice called internally to expel a participant. It should not be possible to expel non-defaulters, so those arrays are not checked.
    /// @param _expellant The address of the defaulter that will be expelled
    function _expelDefaulter(
        LibFund.Fund storage _fund,
        LibTerm.Term storage _term,
        address _expellant
    ) internal {
        // Expellants should only be in the defauters set so no need to touch the other sets
        require(
            _fund.isParticipant[_expellant] && EnumerableSet.remove(_fund._defaulters, _expellant),
            "Expellant not found"
        );

        _fund.isParticipant[_expellant] = false;

        // Lastly, lower the amount of participants
        --_term.totalParticipants;
        // collateral.isCollateralMember[_expellant] = false; // todo: needed? it is set also on whoExpelled
        ++_fund.expelledParticipants;

        emit OnDefaulterExpelled(_term.termId, _fund.currentCycle, _expellant);
    }

    /// @notice Internal function for close fund which is used by _startNewCycle & _chooseBeneficiary to cover some edge-cases
    /// @param _termId The id of the term
    function _closeFund(uint _termId) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];
        LibTerm.Term storage term = LibTerm._termStorage().terms[_termId];
        fund.fundEnd = block.timestamp;
        term.state = LibTerm.TermStates.ClosedTerm;
        _setState(_termId, LibFund.FundStates.FundClosed);
        ICollateral(address(this)).releaseCollateral(_termId);
    }

    /// @notice Internal function to transfer the pool to the beneficiary
    /// @param _termId The id of the term
    /// @param _beneficiary The address of the beneficiary
    function _transferPoolToBeneficiary(uint _termId, address _beneficiary) internal {
        LibFund.Fund storage fund = LibFund._fundStorage().funds[_termId];

        // Get the amount this beneficiary can withdraw
        uint transferAmount = fund.beneficiariesPool[msg.sender];
        uint contractBalance = fund.stableToken.balanceOf(address(this));
        if (contractBalance < transferAmount) {
            revert InsufficientBalance({available: contractBalance, required: transferAmount});
        } else {
            fund.beneficiariesPool[msg.sender] = 0;
            bool success = fund.stableToken.transfer(msg.sender, transferAmount);
            require(success, "Transfer failed");
        }
        emit OnFundWithdrawn(_termId, _beneficiary, transferAmount);
    }

    /// @notice Internal function to freeze the pot for the beneficiary
    function _freezePot(
        LibTerm.Term memory _term,
        LibFund.Fund storage _fund,
        address _user
    ) internal returns (bool) {
        LibCollateral.Collateral storage collateral = LibCollateral
            ._collateralStorage()
            .collaterals[_term.termId];

        uint remainingCyclesContribution = IGetters(address(this))
            .getRemainingCyclesContributionWei(_term.termId);

        uint neededCollateral = (110 * remainingCyclesContribution) / 100; // 1.1 x RCC

        if (collateral.collateralMembersBank[_user] < neededCollateral) {
            _fund.beneficiariesFrozenPool[_user] = true;
        } else {
            _fund.beneficiariesFrozenPool[_user] = false;
        }

        return _fund.beneficiariesFrozenPool[_user];
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

/// @title Takaturn Fund Interface
/// @author Mohammed Haddouti
/// @notice This is used to allow collateral to easily communicate with fund
/// @dev v2.0 (post-deploy)

import {LibFund} from "../libraries/LibFund.sol";

interface IFund {
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

import {LibTerm} from "../libraries/LibTerm.sol";

library LibTermOwnership {
    bytes32 constant TERM_OWNER_HELPER = keccak256("diamond.standard.term.owner.helper");

    /**
     * @dev Throws if the sender is not the term owner.
     * @dev Used for internal calls
     */
    function _ensureTermOwner(uint termId) internal view {
        require(
            LibTerm._termStorage().terms[termId].termOwner == msg.sender,
            "TermOwnable: caller is not the owner"
        );
    }
}