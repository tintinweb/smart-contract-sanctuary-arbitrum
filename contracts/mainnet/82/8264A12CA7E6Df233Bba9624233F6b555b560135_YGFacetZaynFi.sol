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

import {IZaynZapV2TakaDAO} from "../interfaces/IZaynZapV2TakaDAO.sol";
import {IZaynVaultV2TakaDao} from "../interfaces/IZaynVaultV2TakaDao.sol";

import {IYGFacetZaynFi} from "../interfaces/IYGFacetZaynFi.sol";

import {LibYieldGenerationStorage} from "../libraries/LibYieldGenerationStorage.sol";
import {LibYieldGeneration} from "../libraries/LibYieldGeneration.sol";
import {LibCollateralStorage} from "../libraries/LibCollateralStorage.sol";
import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import {LibFundStorage} from "../libraries/LibFundStorage.sol";

contract YGFacetZaynFi is IYGFacetZaynFi {
    event OnYGOptInToggled(uint indexed termId, address indexed user, bool indexed optedIn); // Emits when a user succesfully toggles yield generation
    event OnYieldClaimed(
        uint indexed termId,
        address indexed user,
        address receiver,
        uint indexed amount
    ); // Emits when a user claims their yield
    event OnYieldReimbursed(uint indexed termId, address indexed user, uint indexed amount);
    event OnYieldCompensated(uint indexed termId, address indexed user, uint indexed amount);
    event OnWithdrawnBalanceRestored(
        uint indexed termId,
        address indexed user,
        uint indexed amount
    );
    event OnYieldTermUpdated(
        uint indexed termId,
        uint indexed amountRestored,
        uint indexed amountCompensated
    );

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /// @notice This function allows a user to claim the current available yield
    /// @param termId The term id for which the yield is being claimed
    /// @param receiver The address of the user who will receive the yield
    /// @dev for emergency use only, in case the claimed yield is not sent to the user when withdrawing the collateral
    function claimAvailableYield(uint termId, address receiver) external {
        LibFundStorage.Fund storage fund = LibFundStorage._fundStorage().funds[termId];

        address[] memory participants = fund.beneficiariesOrder;
        uint participantsLength = participants.length;
        bool canCall;

        for (uint i; i < participantsLength; ) {
            if (participants[i] == msg.sender) {
                canCall = true;
                break;
            }

            unchecked {
                ++i;
            }
        }

        require(canCall, "The caller must be a participant");

        LibYieldGeneration._claimAvailableYield(termId, msg.sender, receiver);
    }

    /// @notice This function allows a user to toggle their yield generation
    /// @dev only allowed before the term starts
    /// @param termId The term id for which the yield is being claimed
    function toggleOptInYG(uint termId) external {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];
        LibCollateralStorage.Collateral storage collateral = LibCollateralStorage
            ._collateralStorage()
            .collaterals[termId];

        require(
            collateral.state == LibCollateralStorage.CollateralStates.AcceptingCollateral,
            "Too late to change YG opt in"
        );
        require(
            collateral.isCollateralMember[msg.sender],
            "Pay the collateral security deposit first"
        );

        bool optIn = !yield.hasOptedIn[msg.sender];
        yield.hasOptedIn[msg.sender] = optIn;
        emit OnYGOptInToggled(termId, msg.sender, optIn);
    }

    /// @notice This function allows the owner to update the global variable for new yield provider
    /// @param providerString The provider string for which the address is being updated
    /// @param providerAddress The new address of the provider
    function updateYieldProvider(
        string memory providerString,
        address providerAddress
    ) external onlyOwner {
        LibYieldGenerationStorage.YieldProviders storage yieldProvider = LibYieldGenerationStorage
            ._yieldProviders();

        yieldProvider.providerAddresses[providerString] = providerAddress;
    }

    /// @notice This function allows the owner to disable the yield generation feature in case of emergency
    function toggleYieldLock() external onlyOwner returns (bool) {
        bool newYieldLock = !LibYieldGenerationStorage._yieldLock().yieldLock;
        LibYieldGenerationStorage._yieldLock().yieldLock = newYieldLock;

        return LibYieldGenerationStorage._yieldLock().yieldLock;
    }

    /// @notice To be used in case of emergency, when the provider needs to change the zap or the vault
    /// @param termId The term id for which the yield is being claimed
    /// @param providerString The provider string for which the address is being updated
    /// @param providerAddress The new address of the provider
    function updateProviderAddressOnTerms(
        uint termId,
        string memory providerString,
        address providerAddress
    ) external onlyOwner {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[termId];

        require(LibFundStorage._fundExists(termId), "Fund does not exist");
        require(providerAddress != address(0), "Invalid provider address");
        require(
            yield.providerAddresses[providerString] != providerAddress,
            "Same provider address"
        );

        yield.providerAddresses[providerString] = providerAddress;
    }

    /// @notice To be used in case of emergency, when yield got stuck in the vault
    /// @notice The position of each array is used as a set in the calculation
    /// @param termIds The term ids for which the yield is being rescued
    /// @param originalWithdrawals The original ETH withdrawal amounts of each bad transaction
    /// @param originalShares The original calculated shares amounts of each bad transaction
    /// @param users The users to be reimbursed
    function rescueStuckYields(
        uint[] memory termIds,
        uint[] memory originalWithdrawals,
        uint[] memory originalShares,
        address[] memory users
    ) external payable onlyOwner {
        // Start with validating the lengths of the arrays
        uint length = termIds.length;
        require(
            length == originalWithdrawals.length &&
                length == originalShares.length &&
                length == users.length,
            "Arrays don't match"
        );

        uint usedValue = 0; // Used to keep track of the lost ETH stored back into zaynfi

        // Start looping through each combination
        for (uint i; i < length; ) {
            uint termId = termIds[i];
            address user = users[i];

            LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
                ._yieldStorage()
                .yields[termId];

            // Make sure user is part of this term and has enabled yield generation
            require(yield.hasOptedIn[user], "User not part of yield generation");

            // Zaynfi's addresses
            address vaultAddress = yield.providerAddresses["ZaynVault"];
            address zapAddress = yield.providerAddresses["ZaynZap"];

            // Calculate what each user is owed
            int reimbursement = _calculateReimbursement(
                originalWithdrawals[i],
                originalShares[i],
                yield
            );

            if (reimbursement > 0) {
                // Reimbursement is positive, this means the user withdrew less shares than he was supposed to
                uint neededShares = uint(reimbursement);

                // Code copied from _withdrawYG, get the amount of shares back and give it to the user
                uint withdrawnYield = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
                    vaultAddress,
                    neededShares,
                    termId
                );

                yield.withdrawnYield[user] += withdrawnYield;
                yield.availableYield[user] += withdrawnYield;

                // Claim the yield right away and send it to the user
                LibYieldGeneration._claimAvailableYield(termId, user, user);

                emit OnYieldReimbursed(termId, user, withdrawnYield);
            } else if (reimbursement < 0) {
                // When there is a negative reimbursement, we compensate the pool by adding back the exact amount of shares that were lost
                uint neededShares = uint(reimbursement * -1);

                // Calculate the amount of eth we need to deposit to get the desired shares
                uint pricePerShare = IZaynVaultV2TakaDao(vaultAddress).getPricePerFullShare();

                uint neededEth = (15 * neededShares * pricePerShare) / 10 ** 19; // We ask for 150% of the shares we need to compensate for the slippage
                uint sharesBefore = IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId);

                // Make sure we have enough eth
                require(neededEth + usedValue <= msg.value, "Not enough ETH value sent");

                // Deposit the amount of shares we lost
                IZaynZapV2TakaDAO(zapAddress).zapInEth{value: neededEth}(vaultAddress, termId);

                // Increment the used value so far
                usedValue += neededEth;

                // Validate the amount of shares deposited
                uint sharesAfter = IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId);

                // If we deposited more shares than we needed, we withdraw the extra shares and send them back to the caller
                uint withdrawnExtraEth = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
                    vaultAddress,
                    sharesAfter - sharesBefore - neededShares,
                    termId
                );

                uint sharesFinal = IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId);
                require(neededShares == (sharesFinal - sharesBefore), "Final share balance incorrect");

                // Give the extra eth back to msg.sender
                usedValue -= withdrawnExtraEth;

                emit OnYieldCompensated(termId, user, (neededEth - withdrawnExtraEth));
            }

            unchecked {
                ++i;
            }
        }

        // Reimburse the leftover eth that the msg.sender sent
        if (usedValue < msg.value) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - usedValue}("");
            require(success, "Failed to send leftover ETH back");
        }
    }

    
    /// @notice To be used in case of emergency, when there are more shares deposited than expected
    /// @param termIds The term ids for which the yield balance is to be restored
    function reimburseExtraYield(uint[] memory termIds) external payable onlyOwner {
        uint usedValue = 0; // Used to keep track of the lost ETH stored back into zaynfi
        for (uint i; i < termIds.length; ) {
            uint termId = termIds[i];
            LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
                ._yieldStorage()
                .yields[termId];

            if (!yield.initialized) {
                unchecked {
                    ++i;
                }
                continue;
            }

            // Zaynfi's addresses
            address vaultAddress = yield.providerAddresses["ZaynVault"];
            address zapAddress = yield.providerAddresses["ZaynZap"];

            uint neededShares = (yield.currentTotalDeposit * yield.totalShares) /
                yield.totalDeposit;
            uint actualShares = IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId);

            if (actualShares == neededShares) {
                unchecked {
                    ++i;
                }
                continue;
            }

            address[] memory users = yield.yieldUsers;
            uint reimbursed;
            uint withdrawnYield;

            // Super small values are removed
            if ((actualShares - neededShares) < 100000 ) {
                // ZapIn some ETH to withdraw the last few shares
                IZaynZapV2TakaDAO(zapAddress).zapInEth{value: 100000 }(vaultAddress, termId);
                usedValue += 100000;
                withdrawnYield = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
                    vaultAddress,
                    IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId) - neededShares,
                    termId
                );
                // Send back to msg.sender because there is no profit here
                usedValue -= withdrawnYield;
 
                require(neededShares == IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId), "Shares target not reached!");

                unchecked {
                    ++i;
                }
                continue;
            }
            
            for (uint j; j < users.length; ) {
                address user = users[j];

                uint toWithdraw;

                // Prevent rounding errors and make sure everything is withdrawn. This is done at the last user.
                if (j + 1 == users.length) {
                    toWithdraw = actualShares - neededShares - reimbursed;
                } else {
                    // Distribute the extra shares based on the yield distribution ratio
                    toWithdraw = (actualShares - neededShares) * yield.depositedCollateralByUser[user] / yield.totalDeposit;
                    reimbursed += toWithdraw;
                }

                // ZapOut the user's portion
                withdrawnYield = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
                    vaultAddress,
                    toWithdraw,
                    termId
                );

                yield.withdrawnYield[user] += withdrawnYield;
                yield.availableYield[user] += withdrawnYield;

                // Claim the yield right away and send it to the user
                LibYieldGeneration._claimAvailableYield(termId, user, user);
                    
                emit OnYieldCompensated(termId, user, withdrawnYield);
                
                unchecked {
                    ++j;
                }
            }

            require(neededShares == IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId), "Shares target not reached!");
            
            unchecked {
                ++i;
            }
        }
        
        // Reimburse the leftover eth that the msg.sender sent
        if (usedValue < msg.value) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - usedValue}("");
            require(success, "Failed to send leftover ETH back");
        }
    }


    /// @notice To be used in case of emergency, when the user has withdrawn too much eth from yield into the smart contract
    /// @param termIds The term ids for which the yield balance is to be restored
    function restoreYieldBalance(uint[] memory termIds) external payable onlyOwner {
        uint usedValue = 0; // Used to keep track of the lost ETH stored back into zaynfi
        // Start looping through each term id
        for (uint i; i < termIds.length; ) {
            uint termId = termIds[i];
            LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
                ._yieldStorage()
                .yields[termId];

            if (!yield.initialized) {
                unchecked {
                    ++i;
                }
                continue;
            }

            // Zaynfi's addresses
            address vaultAddress = yield.providerAddresses["ZaynVault"];
            address zapAddress = yield.providerAddresses["ZaynZap"];

            // Validate currentTotalDeposit to match the expected shares
            uint neededShares = (yield.currentTotalDeposit * yield.totalShares) /
                yield.totalDeposit;

            require(neededShares == IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId), "currentTotalDeposit does not match needed shares!");

            // Deal with the case where the user has withdrawn too much eth from yield
            // The user did not actually withdraw more ETH to his wallet, just that it was withdrawn back to the smart contract
            // So no ETH was lost
            address[] memory users = yield.yieldUsers;
            uint withdrawnTooMuch;

            for (uint j; j < users.length; ) {
                address user = users[j];

                uint withdraw = yield.withdrawnCollateral[user];
                uint deposit = yield.depositedCollateralByUser[user];

                if (withdraw > deposit) {
                    withdrawnTooMuch += (withdraw - deposit);

                    // Restore the withdrawnCollateral amount of the user to what it's supposed to be
                    yield.withdrawnCollateral[user] = deposit;

                    emit OnWithdrawnBalanceRestored(termId, user, deposit);
                }

                unchecked {
                    ++j;
                }
            }

            // Safety check but most likely the case
            if (withdrawnTooMuch == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            // Restore currentTotalDeposit to what it's supposed to be
            yield.currentTotalDeposit += withdrawnTooMuch;

            // We calculate the current shares we actually need in total for this term
            neededShares = (yield.currentTotalDeposit * yield.totalShares) /
                yield.totalDeposit;

            // withdrawnTooMuch was withdrawn back to the smart contract, we must send it back to the yield vault
            IZaynZapV2TakaDAO(zapAddress).zapInEth{value: withdrawnTooMuch}(vaultAddress, termId);

            // Get the shares after
            uint sharesBalance = IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId);
            if (neededShares > sharesBalance) {
                // If we still need more shares (which is most likely the case), we compensate by putting the missing amount into the vault
                // Calculate the amount of eth we need to deposit to get the desired shares
                uint pricePerShare = IZaynVaultV2TakaDao(vaultAddress).getPricePerFullShare();

                uint neededEth = (15 * (neededShares - sharesBalance) * pricePerShare) / 10 ** 19; // We ask for 150% of the shares we need to compensate for the slippage

                // Make sure we have enough eth
                require(neededEth + usedValue <= msg.value, "Not enough ETH value sent");

                // Deposit the amount of shares we lost
                IZaynZapV2TakaDAO(zapAddress).zapInEth{value: neededEth}(vaultAddress, termId);

                // Increment the used value so far
                usedValue += neededEth;

                // Validate the amount of shares deposited
                sharesBalance = IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId);

                // If we deposited more shares than we needed, we withdraw the extra shares and send them back to the caller
                uint withdrawnExtraEth = IZaynZapV2TakaDAO(zapAddress).zapOutETH(
                    vaultAddress,
                    sharesBalance - neededShares,
                    termId
                );

                require(neededShares == IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId), "Final share balance incorrect");

                // Give the extra eth back to msg.sender
                usedValue -= withdrawnExtraEth;

                emit OnYieldTermUpdated(termId, withdrawnTooMuch, (neededEth - withdrawnExtraEth));
            } else if (sharesBalance > neededShares) {
                // If we deposited more shares than we needed, we withdraw the extra shares and send them back to the caller
                IZaynZapV2TakaDAO(zapAddress).zapOutETH(
                    vaultAddress,
                    sharesBalance - neededShares,
                    termId
                );

                emit OnYieldTermUpdated(termId, withdrawnTooMuch, 0);
            }

            // Some sanity checks
            uint currentTotalDeposit;
            for (uint j; j < users.length; ) {
                address user = users[j];
                uint withdraw = yield.withdrawnCollateral[user];
                uint deposit = yield.depositedCollateralByUser[user];
                require(deposit >= withdraw, "Withdraw greater than deposit");

                currentTotalDeposit += yield.depositedCollateralByUser[user] - yield.withdrawnCollateral[user];

                unchecked {
                    ++j;
                }
            }

            require(yield.currentTotalDeposit == currentTotalDeposit, "currentTotalDeposit invalid");

            uint currentShares = currentTotalDeposit * yield.totalShares / yield.totalDeposit;

            require(currentShares == IZaynVaultV2TakaDao(vaultAddress).balanceOf(termId), "Shares invalid");


            unchecked {
                ++i;
            }
        }

        // Reimburse the leftover eth that the msg.sender sent
        if (usedValue < msg.value) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - usedValue}("");
            require(success, "Failed to send leftover ETH back");
        }
    }

    /// @notice To be used in case of emergency, when yield got stuck in the vault
    /// @notice The position of each array is used as a set in the calculation
    /// @param originalWithdrawal The original ETH withdrawal amount
    /// @param originalShares The original calculated shares amount
    /// @param yield the reference to the yield
    function _calculateReimbursement(
        uint originalWithdrawal,
        uint originalShares,
        LibYieldGenerationStorage.YieldGeneration storage yield
    ) internal view returns (int) {
        uint correctedShares = (originalWithdrawal * yield.totalShares) / yield.totalDeposit;

        if (correctedShares > originalShares) {
            return int(correctedShares - originalShares);
        } else if (correctedShares < originalShares) {
            return int(originalShares - correctedShares) * -1;
        }

        return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;

import {LibTermStorage} from "../libraries/LibTermStorage.sol";

interface IYGFacetZaynFi {
    /// @notice This function allows a user to claim the current available yield
    /// @param termId The term id for which the yield is being claimed
    /// @param receiver The address of the user who will receive the yield
    function claimAvailableYield(uint termId, address receiver) external;

    /// @notice This function allows a user to toggle their yield generation
    /// @dev only allowed before the term starts
    /// @param termId The term id for which the yield is being claimed
    function toggleOptInYG(uint termId) external;

    /// @notice This function allows the owner to update the global variable for new yield provider
    /// @param providerString The provider string for which the address is being updated
    /// @param providerAddress The new address of the provider
    function updateYieldProvider(string memory providerString, address providerAddress) external;

    /// @notice This function allows the owner to disable the yield generation feature in case of emergency
    function toggleYieldLock() external returns (bool);

    /// @notice To be used in case of emergency, when the provider needs to change the zap or the vault
    /// @param termId The term id for which the yield is being claimed
    /// @param providerString The provider string for which the address is being updated
    /// @param providerAddress The new address of the provider
    function updateProviderAddressOnTerms(
        uint termId,
        string memory providerString,
        address providerAddress
    ) external;
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
                    10 ** 18) / yield.totalDeposit;
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

    function _claimAvailableYield(uint _termId, address _user, address _receiver) internal {
        LibYieldGenerationStorage.YieldGeneration storage yield = LibYieldGenerationStorage
            ._yieldStorage()
            .yields[_termId];

        uint availableYield = yield.availableYield[_user];

        require(availableYield > 0, "No yield to withdraw");

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
        uint startTimeStamp;
        uint totalDeposit;
        uint currentTotalDeposit;
        uint totalShares;
        address[] yieldUsers;
        mapping(address => bool) hasOptedIn;
        mapping(address => uint256) withdrawnYield;
        mapping(address => uint256) withdrawnCollateral;
        mapping(address => uint256) availableYield;
        mapping(address => uint256) depositedCollateralByUser;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}