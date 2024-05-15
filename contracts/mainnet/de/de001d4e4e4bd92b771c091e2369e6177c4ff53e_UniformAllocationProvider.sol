// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IAllocationProvider.sol";
import "../interfaces/IRiskManager.sol";
import "../interfaces/Constants.sol";

contract UniformAllocationProvider is IAllocationProvider {
    function calculateAllocation(AllocationCalculationInput calldata data) external pure returns (uint256[] memory) {
        uint256[] memory allocations = new uint256[](data.strategies.length);
        uint256 allocation = FULL_PERCENT / data.strategies.length;
        for (uint8 i; i < data.strategies.length; ++i) {
            allocations[i] = allocation;
        }

        allocations[0] += (FULL_PERCENT - allocation * data.strategies.length);
        return allocations;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @notice Used when number of provided APYs or risk scores does not match number of provided strategies.
 */
error ApysOrRiskScoresLengthMismatch(uint256, uint256);

/**
 * @notice Input for calculating allocation.
 * @custom:member strategies Strategies to allocate.
 * @custom:member apys APYs for each strategy.
 * @custom:member riskScores Risk scores for each strategy.
 * @custom:member riskTolerance Risk tolerance of the smart vault.
 */
struct AllocationCalculationInput {
    address[] strategies;
    int256[] apys;
    uint8[] riskScores;
    int8 riskTolerance;
}

interface IAllocationProvider {
    /**
     * @notice Calculates allocation between strategies based on input parameters.
     * @param data Input data for allocation calculation.
     * @return allocation Calculated allocation.
     */
    function calculateAllocation(AllocationCalculationInput calldata data)
        external
        view
        returns (uint256[] memory allocation);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../libraries/uint16a16Lib.sol";

error InvalidRiskInputLength();
error RiskScoreValueOutOfBounds(uint8 value);
error RiskToleranceValueOutOfBounds(int8 value);
error CannotSetRiskScoreForGhostStrategy(uint8 riskScore);
error InvalidAllocationSum(uint256 allocationsSum);
error InvalidRiskScores(address riskProvider, address strategy);

interface IRiskManager {
    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Calculates allocation between strategies based on
     * - risk scores of strategies
     * - risk appetite
     * @param smartVault Smart vault address.
     * @param strategies Strategies.
     * @return allocation Calculated allocation.
     */
    function calculateAllocation(address smartVault, address[] calldata strategies)
        external
        view
        returns (uint16a16 allocation);

    /**
     * @notice Gets risk scores for strategies.
     * @param riskProvider Requested risk provider.
     * @param strategy Strategies.
     * @return riskScores Risk scores for strategies.
     */
    function getRiskScores(address riskProvider, address[] memory strategy)
        external
        view
        returns (uint8[] memory riskScores);

    /**
     * @notice Gets configured risk provider for a smart vault.
     * @param smartVault Smart vault.
     * @return riskProvider Risk provider for the smart vault.
     */
    function getRiskProvider(address smartVault) external view returns (address riskProvider);

    /**
     * @notice Gets configured allocation provider for a smart vault.
     * @param smartVault Smart vault.
     * @return allocationProvider Allocation provider for the smart vault.
     */
    function getAllocationProvider(address smartVault) external view returns (address allocationProvider);

    /**
     * @notice Gets configured risk tolerance for a smart vault.
     * @param smartVault Smart vault.
     * @return riskTolerance Risk tolerance for the smart vault.
     */
    function getRiskTolerance(address smartVault) external view returns (int8 riskTolerance);

    /* ========== EXTERNAL MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Sets risk provider for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - risk provider must have role ROLE_RISK_PROVIDER
     * @param smartVault Smart vault.
     * @param riskProvider_ Risk provider to set.
     */
    function setRiskProvider(address smartVault, address riskProvider_) external;

    /**
     * @notice Sets allocation provider for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - allocation provider must have role ROLE_ALLOCATION_PROVIDER
     * @param smartVault Smart vault.
     * @param allocationProvider Allocation provider to set.
     */
    function setAllocationProvider(address smartVault, address allocationProvider) external;

    /**
     * @notice Sets risk scores for strategies.
     * @dev Requirements:
     * - caller must have role ROLE_RISK_PROVIDER
     * @param riskScores Risk scores to set for strategies.
     * @param strategies Strategies for which to set risk scores.
     */
    function setRiskScores(uint8[] calldata riskScores, address[] calldata strategies) external;

    /**
     * @notice Sets risk tolerance for a smart vault.
     * @dev Requirements:
     * - caller must have role ROLE_SMART_VAULT_INTEGRATOR
     * - risk tolerance must be within valid bounds
     * @param smartVault Smart vault.
     * @param riskTolerance Risk tolerance to set.
     */
    function setRiskTolerance(address smartVault, int8 riskTolerance) external;

    /**
     * @notice Risk scores updated
     * @param riskProvider risk provider address
     * @param strategies strategy addresses
     * @param riskScores risk score values
     */
    event RiskScoresUpdated(address indexed riskProvider, address[] strategies, uint8[] riskScores);

    /**
     * @notice Smart vault risk provider set
     * @param smartVault Smart vault address
     * @param riskProvider New risk provider address
     */
    event RiskProviderSet(address indexed smartVault, address indexed riskProvider);

    /**
     * @notice Smart vault allocation provider set
     * @param smartVault Smart vault address
     * @param allocationProvider New allocation provider address
     */
    event AllocationProviderSet(address indexed smartVault, address indexed allocationProvider);

    /**
     * @notice Smart vault risk appetite
     * @param smartVault Smart vault address
     * @param riskTolerance risk appetite value
     */
    event RiskToleranceSet(address indexed smartVault, int8 riskTolerance);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @dev Number of seconds in an average year.
uint256 constant SECONDS_IN_YEAR = 31_556_926;

/// @dev Number of seconds in an average year.
int256 constant SECONDS_IN_YEAR_INT = 31_556_926;

/// @dev Represents 100%.
uint256 constant FULL_PERCENT = 100_00;

/// @dev Represents 100%.
int256 constant FULL_PERCENT_INT = 100_00;

/// @dev Represents 100% for yield.
int256 constant YIELD_FULL_PERCENT_INT = 10 ** 12;

/// @dev Represents 100% for yield.
uint256 constant YIELD_FULL_PERCENT = uint256(YIELD_FULL_PERCENT_INT);

/// @dev Maximal management fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant MANAGEMENT_FEE_MAX = 5_00;

/// @dev Maximal deposit fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant DEPOSIT_FEE_MAX = 5_00;

/// @dev Maximal smart vault performance fee that can be set on a smart vault. Expressed in terms of FULL_PERCENT.
uint256 constant SV_PERFORMANCE_FEE_MAX = 20_00;

/// @dev Maximal ecosystem fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant ECOSYSTEM_FEE_MAX = 20_00;

/// @dev Maximal treasury fee that can be set on the system. Expressed in terms of FULL_PERCENT.
uint256 constant TREASURY_FEE_MAX = 10_00;

/// @dev Maximal risk score a strategy can be assigned.
uint8 constant MAX_RISK_SCORE = 10_0;

/// @dev Minimal risk score a strategy can be assigned.
uint8 constant MIN_RISK_SCORE = 1;

/// @dev Maximal value for risk tolerance a smart vautl can have.
int8 constant MAX_RISK_TOLERANCE = 10;

/// @dev Minimal value for risk tolerance a smart vault can have.
int8 constant MIN_RISK_TOLERANCE = -10;

/// @dev If set as risk provider, system will return fixed risk score values
address constant STATIC_RISK_PROVIDER = address(0xaaa);

/// @dev Fixed values to use if risk provider is set to STATIC_RISK_PROVIDER
uint8 constant STATIC_RISK_SCORE = 1;

/// @dev Maximal value of deposit NFT ID.
uint256 constant MAXIMAL_DEPOSIT_ID = 2 ** 255;

/// @dev Maximal value of withdrawal NFT ID.
uint256 constant MAXIMAL_WITHDRAWAL_ID = 2 ** 256 - 1;

/// @dev How many shares will be minted with a NFT
uint256 constant NFT_MINTED_SHARES = 10 ** 6;

/// @dev Each smart vault can have up to STRATEGY_COUNT_CAP strategies.
uint256 constant STRATEGY_COUNT_CAP = 16;

/// @dev Maximal DHW base yield. Expressed in terms of FULL_PERCENT.
uint256 constant MAX_DHW_BASE_YIELD_LIMIT = 10_00;

/// @dev Smart vault and strategy share multiplier at first deposit.
uint256 constant INITIAL_SHARE_MULTIPLIER = 1000;

/// @dev Strategy initial locked shares. These shares will never be unlocked.
uint256 constant INITIAL_LOCKED_SHARES = 10 ** 12;

/// @dev Strategy initial locked shares address.
address constant INITIAL_LOCKED_SHARES_ADDRESS = address(0xdead);

/// @dev Maximum number of guards a smart vault can be configured with
uint256 constant MAX_GUARD_COUNT = 10;

/// @dev Maximum number of actions a smart vault can be configured with
uint256 constant MAX_ACTION_COUNT = 10;

/// @dev ID of null asset group. Should not be used by any strategy or smart vault.
uint256 constant NULL_ASSET_GROUP_ID = 0;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

type uint16a16 is uint256;

/**
 * @notice This library enables packing of sixteen uint16 elements into one uint256 word.
 */
library uint16a16Lib {
    /// @notice Number of bits per stored element.
    uint256 constant bits = 16;

    /// @notice Maximal number of elements stored.
    uint256 constant elements = 16;

    // must ensure that bits * elements <= 256

    /// @notice Range covered by stored element.
    uint256 constant range = 1 << bits;

    /// @notice Maximal value of stored element.
    uint256 constant max = range - 1;

    /**
     * @notice Gets element from packed array.
     * @param va Packed array.
     * @param index Index of element to get.
     * @return element Element of va stored in index index.
     */
    function get(uint16a16 va, uint256 index) internal pure returns (uint256) {
        require(index < elements);
        return (uint16a16.unwrap(va) >> (bits * index)) & max;
    }

    /**
     * @notice Sets element to packed array.
     * @param va Packed array.
     * @param index Index under which to store the element
     * @param ev Element to store.
     * @return va Packed array with stored element.
     */
    function set(uint16a16 va, uint256 index, uint256 ev) internal pure returns (uint16a16) {
        require(index < elements);
        require(ev < range);
        index *= bits;
        return uint16a16.wrap((uint16a16.unwrap(va) & ~(max << index)) | (ev << index));
    }

    /**
     * @notice Sets elements to packed array.
     * Elements are stored continuously from index 0 onwards.
     * @param va Packed array.
     * @param ev Elements to store.
     * @return va Packed array with stored elements.
     */
    function set(uint16a16 va, uint256[] memory ev) internal pure returns (uint16a16) {
        for (uint256 i; i < ev.length; ++i) {
            va = set(va, i, ev[i]);
        }

        return va;
    }
}