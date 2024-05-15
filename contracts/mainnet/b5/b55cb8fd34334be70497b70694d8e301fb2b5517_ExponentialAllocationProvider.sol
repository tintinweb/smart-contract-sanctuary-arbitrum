// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/IAllocationProvider.sol";
import "../interfaces/IRiskManager.sol";
import "../interfaces/Constants.sol";

contract ExponentialAllocationProvider is IAllocationProvider {
    /// @notice APY threshold to assign allocation, 0.1%.
    /// @dev If the threshold is not met, strategy will have 0 allocation.
    int256 public constant APY_ALLOCATION_THRESHOLD = YIELD_FULL_PERCENT_INT / 1000;

    /// @notice Minimum value signed 64.64-bit fixed point number may have.
    int256 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /// @notice Maximum value signed 64.64-bit fixed point number may have.
    int256 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @notice APY normalization factor.
    int256 private immutable _normalizationFactor;

    constructor() {
        _normalizationFactor = fromInt(8);
    }

    function calculateAllocation(AllocationCalculationInput calldata data) external view returns (uint256[] memory) {
        if (data.apys.length != data.riskScores.length) {
            revert ApysOrRiskScoresLengthMismatch(data.apys.length, data.riskScores.length);
        }

        uint256[] memory allocations = new uint256[](data.apys.length);

        if (allocations.length == 1) {
            // if there is only one strategy, it should get full allocation
            allocations[0] = FULL_PERCENT;
            return allocations;
        }

        int256 riskToleranceFactor = _calculateRiskToleranceFactor(data.riskTolerance);

        // sum APY over all strategies for normalization
        int256 apySum;
        for (uint256 i; i < data.apys.length; ++i) {
            if (data.apys[i] < APY_ALLOCATION_THRESHOLD) {
                continue;
            }

            apySum += data.apys[i];
        }
        int256 partApySum = fromInt(apySum);

        // calculate allocation for each strategy
        uint256 allocationSum;
        for (uint256 i; i < data.apys.length; ++i) {
            if (data.apys[i] < APY_ALLOCATION_THRESHOLD) {
                continue;
            }

            int256 allocation = div(mul(fromInt(data.apys[i]), _normalizationFactor), partApySum);
            allocation = exp_2(exp_2(mul(riskToleranceFactor, log_2(allocation))));
            allocations[i] = uint256(div(allocation, fromUint(data.riskScores[i])));

            allocationSum += allocations[i];
        }

        if (allocationSum <= 0) {
            for (uint256 i; i < allocations.length; ++i) {
                allocations[i] = 1;
            }

            allocationSum = allocations.length;
        }

        // normalize allocation to FULL_PERCENT
        uint256 residual = FULL_PERCENT;
        for (uint256 i; i < allocations.length; ++i) {
            allocations[i] = FULL_PERCENT * allocations[i] / allocationSum;
            residual -= allocations[i];
        }

        if (residual > 0) {
            for (uint256 i; i < allocations.length; ++i) {
                if (allocations[i] > 0) {
                    allocations[i] += residual;
                    break;
                }
            }
        }

        return allocations;
    }

    function _calculateRiskToleranceFactor(int8 riskTolerance) private pure returns (int256) {
        // NOTE: minimum data.riskTolerance value is -10
        uint256 positiveRiskTolerance = uint8(riskTolerance + 10); // from 0 to 20
        unchecked {
            return div(fromUint(10 + positiveRiskTolerance * 9), fromInt(100));
        }
    }

    function fromInt(int256 x) internal pure returns (int256) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int256(x << 64);
        }
    }

    function toInt(int256 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    function log_2(int256 x) internal pure returns (int256) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = msb - 64 << 64;
            uint256 ux = uint256(x) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return result;
        }
    }

    function exp_2(int256 x) internal pure returns (int256) {
        unchecked {
            require(x < 0x400000000000000000, "Overflow"); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) {
                result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
            }
            if (x & 0x4000000000000000 > 0) {
                result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
            }
            if (x & 0x2000000000000000 > 0) {
                result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
            }
            if (x & 0x1000000000000000 > 0) {
                result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
            }
            if (x & 0x800000000000000 > 0) {
                result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
            }
            if (x & 0x400000000000000 > 0) {
                result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
            }
            if (x & 0x200000000000000 > 0) {
                result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
            }
            if (x & 0x100000000000000 > 0) {
                result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
            }
            if (x & 0x80000000000000 > 0) {
                result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
            }
            if (x & 0x40000000000000 > 0) {
                result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
            }
            if (x & 0x20000000000000 > 0) {
                result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
            }
            if (x & 0x10000000000000 > 0) {
                result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
            }
            if (x & 0x8000000000000 > 0) {
                result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
            }
            if (x & 0x4000000000000 > 0) {
                result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
            }
            if (x & 0x2000000000000 > 0) {
                result = result * 0x1000162E525EE054754457D5995292026 >> 128;
            }
            if (x & 0x1000000000000 > 0) {
                result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
            }
            if (x & 0x800000000000 > 0) {
                result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
            }
            if (x & 0x400000000000 > 0) {
                result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
            }
            if (x & 0x200000000000 > 0) {
                result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
            }
            if (x & 0x100000000000 > 0) {
                result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
            }
            if (x & 0x80000000000 > 0) {
                result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
            }
            if (x & 0x40000000000 > 0) {
                result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
            }
            if (x & 0x20000000000 > 0) {
                result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
            }
            if (x & 0x10000000000 > 0) {
                result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
            }
            if (x & 0x8000000000 > 0) {
                result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
            }
            if (x & 0x4000000000 > 0) {
                result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
            }
            if (x & 0x2000000000 > 0) {
                result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
            }
            if (x & 0x1000000000 > 0) {
                result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
            }
            if (x & 0x800000000 > 0) {
                result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
            }
            if (x & 0x400000000 > 0) {
                result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
            }
            if (x & 0x200000000 > 0) {
                result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
            }
            if (x & 0x100000000 > 0) {
                result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
            }
            if (x & 0x80000000 > 0) {
                result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
            }
            if (x & 0x40000000 > 0) {
                result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
            }
            if (x & 0x20000000 > 0) {
                result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
            }
            if (x & 0x10000000 > 0) {
                result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
            }
            if (x & 0x8000000 > 0) {
                result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
            }
            if (x & 0x4000000 > 0) {
                result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
            }
            if (x & 0x2000000 > 0) {
                result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
            }
            if (x & 0x1000000 > 0) {
                result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
            }
            if (x & 0x800000 > 0) {
                result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
            }
            if (x & 0x400000 > 0) {
                result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
            }
            if (x & 0x200000 > 0) {
                result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
            }
            if (x & 0x100000 > 0) {
                result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
            }
            if (x & 0x80000 > 0) {
                result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
            }
            if (x & 0x40000 > 0) {
                result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
            }
            if (x & 0x20000 > 0) {
                result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
            }
            if (x & 0x10000 > 0) {
                result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
            }
            if (x & 0x8000 > 0) {
                result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
            }
            if (x & 0x4000 > 0) {
                result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
            }
            if (x & 0x2000 > 0) {
                result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
            }
            if (x & 0x1000 > 0) {
                result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
            }
            if (x & 0x800 > 0) {
                result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
            }
            if (x & 0x400 > 0) {
                result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
            }
            if (x & 0x200 > 0) {
                result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
            }
            if (x & 0x100 > 0) {
                result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
            }
            if (x & 0x80 > 0) {
                result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
            }
            if (x & 0x40 > 0) {
                result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
            }
            if (x & 0x20 > 0) {
                result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
            }
            if (x & 0x10 > 0) {
                result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
            }
            if (x & 0x8 > 0) {
                result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
            }
            if (x & 0x4 > 0) {
                result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
            }
            if (x & 0x2 > 0) {
                result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
            }
            if (x & 0x1 > 0) {
                result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;
            }

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int256(int256(result));
        }
    }

    function div(int256 x, int256 y) internal pure returns (int256) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int256(result);
        }
    }

    function fromUint(uint256 x) internal pure returns (int256) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int256(int256(x << 64));
        }
    }

    function mul(int256 x, int256 y) internal pure returns (int256) {
        unchecked {
            int256 result = int256(x) * y >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int256(result);
        }
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