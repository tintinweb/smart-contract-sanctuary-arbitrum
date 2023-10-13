// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IConeCamelotVaultStorage} from "../../interfaces/algebra/IConeCamelotVaultStorage.sol";
import {IAlgebraPool} from "../../interfaces/algebra/IAlgebraPool.sol";
import {TickMath} from "../../vendor/algebra/TickMath.sol";
import {FullMath, LiquidityAmounts} from "../../vendor/algebra/LiquidityAmounts.sol";
import {IUniswapV3TickSpacing} from "../../interfaces/IUniswapV3TickSpacing.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

library ConeCamelotLibraryV2 {
    using TickMath for int24;
    using SafeCast for uint256;

    // Assuming the declaration of the VaultData struct somewhere in the code as:
    struct VaultData {
        address token0;
        address token1;
        uint256 managerBalance0;
        uint256 managerBalance1;
        uint256 coneBalance0;
        uint256 coneBalance1;
        IAlgebraPool pool;
        int24 lowerTick;
        int24 upperTick;
        address vault;
    }

    struct PoolData {
        uint128 liquidity;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function applyFees(address _vault, uint256 _fee0, uint256 _fee1)
        external
        view
        returns (uint256 coneBalance0, uint256 coneBalance1, uint256 managerBalance0, uint256 managerBalance1, uint256 rawFee0, uint256 rawFee1)
    {
        uint256 coneFeeBPS = IConeCamelotVaultStorage(_vault).coneFeeBPS();
        uint256 managerFeeBPS = IConeCamelotVaultStorage(_vault).managerFeeBPS();

        coneBalance0 = IConeCamelotVaultStorage(_vault).coneBalance0() + (_fee0 * coneFeeBPS) / 10000;
        coneBalance1 = IConeCamelotVaultStorage(_vault).coneBalance1() + (_fee1 * coneFeeBPS) / 10000;
        managerBalance0 = IConeCamelotVaultStorage(_vault).managerBalance0() + (_fee0 * managerFeeBPS) / 10000;
        managerBalance1 = IConeCamelotVaultStorage(_vault).managerBalance1() + (_fee1 * managerFeeBPS) / 10000;
        uint256 deduct0 = (_fee0 * (coneFeeBPS + managerFeeBPS)) / 10000;
        uint256 deduct1 = (_fee1 * (coneFeeBPS + managerFeeBPS)) / 10000;
        rawFee0 = _fee0 - deduct0;
        rawFee1 = _fee1 - deduct1;
    }

    function subtractAdminFees(address _vault, uint256 rawFee0, uint256 rawFee1)
        public
        view
        returns (uint256 fee0, uint256 fee1)
    {
        uint256 coneFeeBPS = IConeCamelotVaultStorage(_vault).coneFeeBPS();
        uint256 managerFeeBPS = IConeCamelotVaultStorage(_vault).managerFeeBPS();
        uint256 deduct0 = (rawFee0 * (coneFeeBPS + managerFeeBPS)) / 10000;
        uint256 deduct1 = (rawFee1 * (coneFeeBPS + managerFeeBPS)) / 10000;
        fee0 = rawFee0 - deduct0;
        fee1 = rawFee1 - deduct1;
    }

    function computeFeesEarned(
        address _pool,
        bool isZero,
        uint256 feeGrowthInsideLast,
        int24 tick,
        uint128 liquidity,
        int24 lowerTick,
        int24 upperTick
    ) public view returns (uint256 fee) {
        IAlgebraPool pool = IAlgebraPool(_pool);

        uint256 feeGrowthOutsideLower;
        uint256 feeGrowthOutsideUpper;
        uint256 feeGrowthGlobal;

        if (isZero) {
            feeGrowthGlobal = pool.totalFeeGrowth0Token();
            (,, feeGrowthOutsideLower,,,,,) = pool.ticks(lowerTick);
            (,, feeGrowthOutsideUpper,,,,,) = pool.ticks(upperTick);
        } else {
            feeGrowthGlobal = pool.totalFeeGrowth1Token();
            (,,, feeGrowthOutsideLower,,,,) = pool.ticks(lowerTick);
            (,,, feeGrowthOutsideUpper,,,,) = pool.ticks(upperTick);
        }

        unchecked {
            // calculate fee growth below
            uint256 feeGrowthBelow;
            if (tick >= lowerTick) {
                feeGrowthBelow = feeGrowthOutsideLower;
            } else {
                feeGrowthBelow = feeGrowthGlobal - feeGrowthOutsideLower;
            }

            // calculate fee growth above
            uint256 feeGrowthAbove;
            if (tick < upperTick) {
                feeGrowthAbove = feeGrowthOutsideUpper;
            } else {
                feeGrowthAbove = feeGrowthGlobal - feeGrowthOutsideUpper;
            }

            uint256 feeGrowthInside = feeGrowthGlobal - feeGrowthBelow - feeGrowthAbove;
            fee = FullMath.mulDiv(liquidity, feeGrowthInside - feeGrowthInsideLast, 0x100000000000000000000000000000000);
        }
    }

    /// @notice compute maximum shares that can be minted from `amount0Max` and `amount1Max`
    /// @param amount0Max The maximum amount of token0 to forward on mint
    /// @param amount0Max The maximum amount of token1 to forward on mint
    /// @return amount0 actual amount of token0 to forward when minting `mintAmount`
    /// @return amount1 actual amount of token1 to forward when minting `mintAmount`
    /// @return mintAmount maximum number of shares mintable
    function getMintAmounts(address _vault, uint256 amount0Max, uint256 amount1Max, uint8 rangeType)
        external
        view
        returns (uint256 amount0, uint256 amount1, uint256 mintAmount)
    {
        uint256 totalSupply = IConeCamelotVaultStorage(_vault).tokensForRange(rangeType);
        if (totalSupply > 0) {
            (amount0, amount1, mintAmount) = computeMintAmounts(_vault, totalSupply, amount0Max, amount1Max, rangeType);
        } else {
            uint160 sqrtRatioX96lower = IConeCamelotVaultStorage(_vault).lowerTicks(rangeType).getSqrtRatioAtTick();
            uint160 sqrtRatioX96upper = IConeCamelotVaultStorage(_vault).upperTicks(rangeType).getSqrtRatioAtTick();
            (uint160 sqrtRatioX96,,,,,,,) = IAlgebraPool(IConeCamelotVaultStorage(_vault).pool()).globalState();
            uint128 newLiquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                sqrtRatioX96lower,
                sqrtRatioX96upper,
                amount0Max,
                amount1Max
            );
            mintAmount = uint256(newLiquidity);
            (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                sqrtRatioX96lower,
                sqrtRatioX96upper,
                newLiquidity
            );
        }
    }

    function getPositionID(address _vault, uint8 _range) public view returns (bytes32 positionID) {
        int24 _lowerTick = IConeCamelotVaultStorage(_vault).lowerTicks(_range);
        int24 _upperTick = IConeCamelotVaultStorage(_vault).upperTicks(_range);

        bytes32 positionKey;
        address This = address(_vault);
        assembly {
            positionKey := or(shl(24, or(shl(24, This), and(_lowerTick, 0xFFFFFF))), and(_upperTick, 0xFFFFFF))
        }
        return positionKey;
    }

    function computeMintAmounts(
        address _vault,
        uint256 totalSupply,
        uint256 amount0Max,
        uint256 amount1Max,
        uint8 rangeType
    ) public view returns (uint256 amount0, uint256 amount1, uint256 mintAmount) {
        (uint256 amount0Current, uint256 amount1Current) = getUnderlyingBalances(_vault, rangeType);

        // compute proportional amount of tokens to mint
        if (amount0Current == 0 && amount1Current > 0) {
            mintAmount = FullMath.mulDiv(amount1Max, totalSupply, amount1Current);
        } else if (amount1Current == 0 && amount0Current > 0) {
            mintAmount = FullMath.mulDiv(amount0Max, totalSupply, amount0Current);
        } else if (amount0Current == 0 && amount1Current == 0) {
            revert("");
        } else {
            // only if both are non-zero
            uint256 amount0Mint = FullMath.mulDiv(amount0Max, totalSupply, amount0Current);
            uint256 amount1Mint = FullMath.mulDiv(amount1Max, totalSupply, amount1Current);
            require(amount0Mint > 0 && amount1Mint > 0, "mint 0");

            mintAmount = amount0Mint < amount1Mint ? amount0Mint : amount1Mint;
        }

        // compute amounts owed to contract
        amount0 = FullMath.mulDivRoundingUp(mintAmount, amount0Current, totalSupply);
        amount1 = FullMath.mulDivRoundingUp(mintAmount, amount1Current, totalSupply);
    }

    /// @notice compute total underlying holdings of the G-UNI token supply
    /// includes current liquidity invested in algebra position, current fees earned
    /// and any uninvested leftover (but does not include manager or external fees accrued)
    /// @return amount0Current current total underlying balance of token0
    /// @return amount1Current current total underlying balance of token1
    function getUnderlyingBalances(address _vault, uint8 _rangeType) public view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, int24 tick,,,,,,) = IAlgebraPool(IConeCamelotVaultStorage(_vault).pool()).globalState();
        return getUnderlyingBalancesAtTick(_vault, sqrtRatioX96, tick, _rangeType);
    }

    function getUnderlyingBalancesAtPrice(address _vault, uint160 sqrtRatioX96, uint8 range)
        public
        view
        returns (uint256, uint256)
    {
        (, int24 tick,,,,,,) = IAlgebraPool(IConeCamelotVaultStorage(_vault).pool()).globalState();
        return getUnderlyingBalancesAtTick(_vault, sqrtRatioX96, tick, range);
    }

    function getUnderlyingBalancesAtTick(address _vault, uint160 sqrtRatioX96, int24 tick, uint8 range)
        public
        view
        returns (uint256 amount0Current, uint256 amount1Current)
    {
        VaultData memory data = getVaultData(_vault, range);

        (uint128 liquidity,,,,,) = data.pool.positions(getPositionID(_vault, range));

        // compute current fees earned
        (uint256 fee0, uint256 fee1) = computeFees(data, tick, range);

        (fee0, fee1) = subtractAdminFees(_vault, fee0, fee1);

        (amount0Current, amount1Current) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96, data.lowerTick.getSqrtRatioAtTick(), data.upperTick.getSqrtRatioAtTick(), liquidity
        );

        // add any leftover in contract to current holdings
        amount0Current += fee0;
        amount1Current += fee1;
    }

    function getVaultData(address _vault, uint8 range) public view returns (VaultData memory) {
        IConeCamelotVaultStorage vaultStorage = IConeCamelotVaultStorage(_vault);

        return VaultData({
            lowerTick: vaultStorage.lowerTicks(range),
            upperTick: vaultStorage.upperTicks(range),
            token0: address(vaultStorage.token0()),
            token1: address(vaultStorage.token1()),
            managerBalance0: vaultStorage.managerBalance0(),
            managerBalance1: vaultStorage.managerBalance1(),
            coneBalance0: vaultStorage.coneBalance0(),
            coneBalance1: vaultStorage.coneBalance1(),
            pool: IAlgebraPool(vaultStorage.pool()),
            vault: _vault
        });
    }

    function getPoolData(address _vault, uint8 _range) public view returns (PoolData memory) {
        IConeCamelotVaultStorage vaultStorage = IConeCamelotVaultStorage(_vault);

        (
            uint256 liquidity,
            ,
            uint256 feeGrowthInside0Last,
            uint256 feeGrowthInside1Last,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = IAlgebraPool(vaultStorage.pool()).positions(getPositionID(_vault, _range));
        return PoolData({
            liquidity: liquidity.toUint128(),
            feeGrowthInside0Last: feeGrowthInside0Last,
            feeGrowthInside1Last: feeGrowthInside1Last,
            tokensOwed0: tokensOwed0,
            tokensOwed1: tokensOwed1
        });
    }

    function computeFees(VaultData memory data, int24 tick, uint8 range)
        public
        view
        returns (uint256 fee0, uint256 fee1)
    {
        PoolData memory poolData = getPoolData(data.vault, range);

        fee0 = computeFeesEarned(
            address(data.pool),
            true,
            poolData.feeGrowthInside0Last,
            tick,
            poolData.liquidity,
            data.lowerTick,
            data.upperTick
        ) + uint256(poolData.tokensOwed0);

        fee1 = computeFeesEarned(
            address(data.pool),
            false,
            poolData.feeGrowthInside1Last,
            tick,
            poolData.liquidity,
            data.lowerTick,
            data.upperTick
        ) + uint256(poolData.tokensOwed1);
    }

    function validateTickSpacing(address uniPool, int24 lowerTick, int24 upperTick) external view returns (bool) {
        int24 spacing = IUniswapV3TickSpacing(uniPool).tickSpacing();
        return lowerTick < upperTick && lowerTick % spacing == 0 && upperTick % spacing == 0;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

interface IUniswapV3TickSpacing {
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./pool/IAlgebraPoolImmutables.sol";
import "./pool/IAlgebraPoolState.sol";
import "./pool/IAlgebraPoolDerivedState.sol";
import "./pool/IAlgebraPoolActions.sol";
import "./pool/IAlgebraPoolPermissionedActions.sol";
import "./pool/IAlgebraPoolEvents.sol";

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPool is
    IAlgebraPoolImmutables,
    IAlgebraPoolState,
    IAlgebraPoolDerivedState,
    IAlgebraPoolActions,
    IAlgebraPoolPermissionedActions,
    IAlgebraPoolEvents
{
// used only for combining interfaces
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import {IAlgebraPool} from "./IAlgebraPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IConeCamelotVaultStorage {
    function initialize(
        string memory _name,
        string memory _symbol,
        address _pool,
        uint16 _managerFeeBPS,
        int24[] calldata _lowerTick,
        int24[] calldata _upperTick,
        address _manager_,
        uint256[] calldata _percentageBIPS
    ) external;

    function pool() external view returns (IAlgebraPool);

    function coneFeeBPS() external view returns (uint256);

    function managerFeeBPS() external view returns (uint256);

    function managerBalance0() external view returns (uint256);

    function managerBalance1() external view returns (uint256);

    function coneBalance0() external view returns (uint256);

    function coneBalance1() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function lowerTicks(uint8) external view returns (int24);

    function upperTicks(uint8) external view returns (int24);

    function getUnderlyingBalances(uint8 _rangeType) external view returns (uint256, uint256);

    function gelatoSlippageInterval() external view returns (uint16);

    function gelatoSlippageBPS() external view returns (uint16);

    function token0() external view returns (IERC20);

    function token1() external view returns (IERC20);

    function tokensForRange(uint8 _rangeType) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

interface IDataStorageOperator {
    /**
     * @notice Returns data belonging to a certain timepoint
     * @param index The index of timepoint in the array
     * @dev There is more convenient function to fetch a timepoint: getTimepoints(). Which requires not an index but seconds
     * @return initialized Whether the timepoint has been initialized and the values are safe to use,
     * blockTimestamp The timestamp of the observation,
     * tickCumulative The tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
     * secondsPerLiquidityCumulative The seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
     * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp,
     * averageTick Time-weighted average tick,
     * volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint88 volatilityCumulative,
            int24 averageTick,
            uint144 volumePerLiquidityCumulative
        );

    /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
    /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
    /// @param tick Initial tick
    function initialize(uint32 time, int24 tick) external;

    /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two timepoints.
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return tickCumulative The cumulative tick since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulative The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    /// @return volatilityCumulative The cumulative volatility value since the pool was first initialized, as of `secondsAgo`
    /// @return volumePerAvgLiquidity The cumulative volume per liquidity value since the pool was first initialized, as of `secondsAgo`
    function getSingleTimepoint(uint32 time, uint32 secondsAgo, int24 tick, uint16 index, uint128 liquidity)
        external
        view
        returns (
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint112 volatilityCumulative,
            uint256 volumePerAvgLiquidity
        );

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest timepoint
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return tickCumulatives The cumulative tick since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
    /// @return volumePerAvgLiquiditys The cumulative volume per liquidity values since the pool was first initialized, as of each `secondsAgo`
    function getTimepoints(uint32 time, uint32[] memory secondsAgos, int24 tick, uint16 index, uint128 liquidity)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    /// @notice Returns average volatility in the range from time-WINDOW to time
    /// @param time The current block.timestamp
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return TWVolatilityAverage The average volatility in the recent range
    /// @return TWVolumePerLiqAverage The average volume per liquidity in the recent range
    function getAverages(uint32 time, int24 tick, uint16 index, uint128 liquidity)
        external
        view
        returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

    /// @notice Writes an dataStorage timepoint to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param blockTimestamp The timestamp of the new timepoint
    /// @param tick The active tick at the time of the new timepoint
    /// @param liquidity The total in-range liquidity at the time of the new timepoint
    /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
    /// @return indexUpdated The new index of the most recently written element in the dataStorage array
    function write(uint16 index, uint32 blockTimestamp, int24 tick, uint128 liquidity, uint128 volumePerLiquidity)
        external
        returns (uint16 indexUpdated);

    /// @notice Calculates gmean(volume/liquidity) for block
    /// @param liquidity The current in-range pool liquidity
    /// @param amount0 Total amount of swapped token0
    /// @param amount1 Total amount of swapped token1
    /// @return volumePerLiquidity gmean(volume/liquidity) capped by 100000 << 64
    function calculateVolumePerLiquidity(uint128 liquidity, int256 amount0, int256 amount1)
        external
        pure
        returns (uint128 volumePerLiquidity);

    /// @return windowLength Length of window used to calculate averages
    function window() external view returns (uint32 windowLength);

    /// @notice Calculates fee based on combination of sigmoids
    /// @param time The current block.timestamp
    /// @param tick The current tick
    /// @param index The index of the timepoint that was most recently written to the timepoints array
    /// @param liquidity The current in-range pool liquidity
    /// @return feeZto The fee for ZtO swaps in hundredths of a bip, i.e. 1e-6
    /// @return feeOtz The fee for OtZ swaps in hundredths of a bip, i.e. 1e-6
    function getFees(uint32 time, int24 tick, uint16 index, uint128 liquidity)
        external
        view
        returns (uint16 feeZto, uint16 feeOtz);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
    /**
     * @notice Sets the initial price for the pool
     * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
     * @param price the initial sqrt price of the pool as a Q64.96
     */
    function initialize(uint160 price) external;

    /**
     * @notice Adds liquidity for the given recipient/bottomTick/topTick position
     * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
     * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
     * on bottomTick, topTick, the amount of liquidity, and the current price.
     * @param sender The address which will receive potential surplus of paid tokens
     * @param recipient The address for which the liquidity will be created
     * @param bottomTick The lower tick of the position in which to add liquidity
     * @param topTick The upper tick of the position in which to add liquidity
     * @param amount The desired amount of liquidity to mint
     * @param data Any data that should be passed through to the callback
     * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
     * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
     * @return liquidityActual The actual minted amount of liquidity
     */
    function mint(
        address sender,
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

    /**
     * @notice Collects tokens owed to a position
     * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
     * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
     * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
     * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
     * @param recipient The address which should receive the fees collected
     * @param bottomTick The lower tick of the position for which to collect fees
     * @param topTick The upper tick of the position for which to collect fees
     * @param amount0Requested How much token0 should be withdrawn from the fees owed
     * @param amount1Requested How much token1 should be withdrawn from the fees owed
     * @return amount0 The amount of fees collected in token0
     * @return amount1 The amount of fees collected in token1
     */
    function collect(
        address recipient,
        int24 bottomTick,
        int24 topTick,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /**
     * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
     * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
     * @dev Fees must be collected separately via a call to #collect
     * @param bottomTick The lower tick of the position for which to burn liquidity
     * @param topTick The upper tick of the position for which to burn liquidity
     * @param amount How much liquidity to burn
     * @return amount0 The amount of token0 sent to the recipient
     * @return amount1 The amount of token1 sent to the recipient
     */
    function burn(int24 bottomTick, int24 topTick, uint128 amount)
        external
        returns (uint256 amount0, uint256 amount1);

    /**
     * @notice Swap token0 for token1, or token1 for token0
     * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
     * @param recipient The address to receive the output of the swap
     * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
     * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     * value after the swap. If one for zero, the price cannot be greater than this value after the swap
     * @param data Any data to be passed through to the callback. If using the Router it should contain
     * SwapRouter#SwapCallbackData
     * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swap(
        address recipient,
        bool zeroToOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     * @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
     * @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
     * @param sender The address called this function (Comes from the Router)
     * @param recipient The address to receive the output of the swap
     * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
     * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
     * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
     * value after the swap. If one for zero, the price cannot be greater than this value after the swap
     * @param data Any data to be passed through to the callback. If using the Router it should contain
     * SwapRouter#SwapCallbackData
     * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
     * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
     */
    function swapSupportingFeeOnInputTokens(
        address sender,
        address recipient,
        bool zeroToOne,
        int256 amountSpecified,
        uint160 limitSqrtPrice,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /**
     * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
     * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
     * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
     * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
     * the donation amount(s) from the callback
     * @param recipient The address which will receive the token0 and token1 amounts
     * @param amount0 The amount of token0 to send
     * @param amount1 The amount of token1 to send
     * @param data Any data to be passed through to the callback
     */
    function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolDerivedState {
    /**
     * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
     * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
     * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
     * you must call it with secondsAgos = [3600, 0].
     * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
     * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
     * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
     * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
     * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
     * from the current block timestamp
     * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
     * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
     */
    function getTimepoints(uint32[] calldata secondsAgos)
        external
        view
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulatives,
            uint112[] memory volatilityCumulatives,
            uint256[] memory volumePerAvgLiquiditys
        );

    /**
     * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
     * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
     * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
     * snapshot is taken and the second snapshot is taken.
     * @param bottomTick The lower tick of the range
     * @param topTick The upper tick of the range
     * @return innerTickCumulative The snapshot of the tick accumulator for the range
     * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
     * @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
     */
    function getInnerCumulatives(int24 bottomTick, int24 topTick)
        external
        view
        returns (int56 innerTickCumulative, uint160 innerSecondsSpentPerLiquidity, uint32 innerSecondsSpent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
    /**
     * @notice Emitted exactly once by a pool when #initialize is first called on the pool
     * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
     * @param price The initial sqrt price of the pool, as a Q64.96
     * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
     */
    event Initialize(uint160 price, int24 tick);

    /**
     * @notice Emitted when liquidity is minted for a given position
     * @param sender The address that minted the liquidity
     * @param owner The owner of the position and recipient of any minted liquidity
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param liquidityAmount The amount of liquidity minted to the position range
     * @param amount0 How much token0 was required for the minted liquidity
     * @param amount1 How much token1 was required for the minted liquidity
     */
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted when fees are collected by the owner of a position
     * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
     * @param owner The owner of the position for which fees are collected
     * @param recipient The address that received fees
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param amount0 The amount of token0 fees collected
     * @param amount1 The amount of token1 fees collected
     */
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 amount0,
        uint128 amount1
    );

    /**
     * @notice Emitted when a position's liquidity is removed
     * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
     * @param owner The owner of the position for which liquidity is removed
     * @param bottomTick The lower tick of the position
     * @param topTick The upper tick of the position
     * @param liquidityAmount The amount of liquidity to remove
     * @param amount0 The amount of token0 withdrawn
     * @param amount1 The amount of token1 withdrawn
     */
    event Burn(
        address indexed owner,
        int24 indexed bottomTick,
        int24 indexed topTick,
        uint128 liquidityAmount,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Emitted by the pool for any swaps between token0 and token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the output of the swap
     * @param amount0 The delta of the token0 balance of the pool
     * @param amount1 The delta of the token1 balance of the pool
     * @param price The sqrt(price) of the pool after the swap, as a Q64.96
     * @param liquidity The liquidity of the pool after the swap
     * @param tick The log base 1.0001 of price of the pool after the swap
     */
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 price,
        uint128 liquidity,
        int24 tick
    );

    /**
     * @notice Emitted by the pool for any flashes of token0/token1
     * @param sender The address that initiated the swap call, and that received the callback
     * @param recipient The address that received the tokens from flash
     * @param amount0 The amount of token0 that was flashed
     * @param amount1 The amount of token1 that was flashed
     * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
     * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
     */
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /**
     * @notice Emitted when the community fee is changed by the pool
     * @param communityFee0New The updated value of the token0 community fee percent
     * @param communityFee1New The updated value of the token1 community fee percent
     */
    event CommunityFee(uint8 communityFee0New, uint8 communityFee1New);

    /**
     * @notice Emitted when the tick spacing changes
     * @param newTickSpacing The updated value of the new tick spacing
     */
    event TickSpacing(int24 newTickSpacing);

    /**
     * @notice Emitted when new activeIncentive is set
     * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
     */
    event Incentive(address indexed virtualPoolAddress);

    /**
     * @notice Emitted when the fee changes
     * @param feeZto The value of the token fee for zto swaps
     * @param feeOtz The value of the token fee for otz swaps
     */
    event Fee(uint16 feeZto, uint16 feeOtz);

    /**
     * @notice Emitted when the LiquidityCooldown changes
     * @param liquidityCooldown The value of locktime for added liquidity
     */
    event LiquidityCooldown(uint32 liquidityCooldown);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "../IDataStorageOperator.sol";

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
    /**
     * @notice The contract that stores all the timepoints and can perform actions with them
     * @return The operator address
     */
    function dataStorageOperator() external view returns (address);

    /**
     * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
     * @return The contract address
     */
    function factory() external view returns (address);

    /**
     * @notice The first of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token0() external view returns (address);

    /**
     * @notice The second of the two tokens of the pool, sorted by address
     * @return The token contract address
     */
    function token1() external view returns (address);

    /**
     * @notice The maximum amount of position liquidity that can use any tick in the range
     * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
     * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
     * @return The max amount of liquidity per tick
     */
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or tokenomics
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolPermissionedActions {
    /**
     * @notice Set the community's % share of the fees. Cannot exceed 25% (250)
     * @param communityFee0 new community fee percent for token0 of the pool in thousandths (1e-3)
     * @param communityFee1 new community fee percent for token1 of the pool in thousandths (1e-3)
     */
    function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

    /// @notice Set the new tick spacing values. Only factory owner
    /// @param newTickSpacing The new tick spacing value
    function setTickSpacing(int24 newTickSpacing) external;

    /**
     * @notice Sets an active incentive
     * @param virtualPoolAddress The address of a virtual pool associated with the incentive
     */
    function setIncentive(address virtualPoolAddress) external;

    /**
     * @notice Sets new lock time for added liquidity
     * @param newLiquidityCooldown The time in seconds
     */
    function setLiquidityCooldown(uint32 newLiquidityCooldown) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
    /**
     * @notice The globalState structure in the pool stores many values but requires only one slot
     * and is exposed as a single method to save gas when accessed externally.
     * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
     * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
     * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
     * boundary;
     * Returns feeZto The last pool fee value for ZtO swaps in hundredths of a bip, i.e. 1e-6;
     * Returns feeOtz The last pool fee value for OtZ swaps in hundredths of a bip, i.e. 1e-6;
     * Returns timepointIndex The index of the last written timepoint;
     * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
     * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
     * Returns unlocked Whether the pool is currently locked to reentrancy;
     */
    function globalState()
        external
        view
        returns (
            uint160 price,
            int24 tick,
            uint16 feeZto,
            uint16 feeOtz,
            uint16 timepointIndex,
            uint8 communityFeeToken0,
            uint8 communityFeeToken1,
            bool unlocked
        );

    /**
     * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth0Token() external view returns (uint256);

    /**
     * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
     * @dev This value can overflow the uint256
     */
    function totalFeeGrowth1Token() external view returns (uint256);

    /**
     * @notice The currently in range liquidity available to the pool
     * @dev This value has no relationship to the total liquidity across all ticks.
     * Returned value cannot exceed type(uint128).max
     */
    function liquidity() external view returns (uint128);

    /**
     * @notice Look up information about a specific tick in the pool
     * @dev This is a public structure, so the `return` natspec tags are omitted.
     * @param tick The tick to look up
     * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
     * tick upper;
     * Returns liquidityDelta how much liquidity changes when the pool price crosses the tick;
     * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
     * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
     * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
     * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
     * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
     * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
     * otherwise equal to false. Outside values can only be used if the tick is initialized.
     * In addition, these values are only relative and must be used only in comparison to previous snapshots for
     * a specific position.
     */
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityTotal,
            int128 liquidityDelta,
            uint256 outerFeeGrowth0Token,
            uint256 outerFeeGrowth1Token,
            int56 outerTickCumulative,
            uint160 outerSecondsPerLiquidity,
            uint32 outerSecondsSpent,
            bool initialized
        );

    /**
     * @notice Returns 256 packed tick initialized boolean values. See TickTable for more information
     */
    function tickTable(int16 wordPosition) external view returns (uint256);

    /**
     * @notice Returns the information about a position by the position's key
     * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
     * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
     * @return liquidityAmount The amount of liquidity in the position;
     * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
     * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
     * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
     * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
     * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
     */
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidityAmount,
            uint32 lastLiquidityAddTimestamp,
            uint256 innerFeeGrowth0Token,
            uint256 innerFeeGrowth1Token,
            uint128 fees0,
            uint128 fees1
        );

    /**
     * @notice Returns data about a specific timepoint index
     * @param index The element of the timepoints array to fetch
     * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
     * ago, rather than at a specific index in the array.
     * This is a public mapping of structures, so the `return` natspec tags are omitted.
     * @return initialized whether the timepoint has been initialized and the values are safe to use;
     * Returns blockTimestamp The timestamp of the timepoint;
     * Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp;
     * Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp;
     * Returns volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp;
     * Returns averageTick Time-weighted average tick;
     * Returns volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp;
     */
    function timepoints(uint256 index)
        external
        view
        returns (
            bool initialized,
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulative,
            uint88 volatilityCumulative,
            int24 averageTick,
            uint144 volumePerLiquidityCumulative
        );

    /**
     * @notice Returns the information about active incentive
     * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
     * @return virtualPool The address of a virtual pool associated with the current active incentive
     */
    function activeIncentive() external view returns (address virtualPool);

    /**
     * @notice Returns the lock time for added liquidity
     */
    function liquidityCooldown() external view returns (uint32 cooldownInSeconds);

    /**
     * @notice The pool tick spacing
     * @dev Ticks can only be used at multiples of this value
     * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
     * This value is an int24 to avoid casting even though it is always positive.
     * @return The tick spacing
     */
    function tickSpacing() external view returns (int24);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.4;

library Constants {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q32 = 1 << 32;
    uint256 internal constant Q48 = 1 << 48;
    uint256 internal constant Q64 = 1 << 64;
    uint256 internal constant Q96 = 1 << 96;
    uint256 internal constant Q128 = 1 << 128;
    uint256 internal constant Q144 = 1 << 144;
    int256 internal constant Q160 = 1 << 160;

    uint16 internal constant BASE_FEE = 0.0001e6; // init minimum fee value in hundredths of a bip (0.01%)
    uint24 internal constant FEE_DENOMINATOR = 1e6;
    int24 internal constant INIT_TICK_SPACING = 60;
    int24 internal constant MAX_TICK_SPACING = 500;

    // Defines the maximum and minimum ticks allowed for limit orders. Corresponds to the range of possible
    // price values ​​in UniswapV2. Due to this limitation, sufficient accuracy is achieved even with the minimum allowable tick
    int24 constant MAX_LIMIT_ORDER_TICK = 776363;

    // the frequency with which the accumulated community fees are sent to the vault
    uint32 internal constant COMMUNITY_FEE_TRANSFER_FREQUENCY = 8 hours;

    // max(uint128) / ( (MAX_TICK - MIN_TICK) )
    uint128 internal constant MAX_LIQUIDITY_PER_TICK = 40564824043007195767232224305152;

    uint8 internal constant MAX_COMMUNITY_FEE = 0.25e3; // 25%
    uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1e3;
    // role that can change communityFee and tickspacing in pools
    bytes32 internal constant POOLS_ADMINISTRATOR_ROLE = keccak256("POOLS_ADMINISTRATOR");
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./FullMath.sol";
import "./Constants.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-periphery
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount0)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, Constants.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint256 amount1)
        internal
        pure
        returns (uint128 liquidity)
    {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, Constants.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 < sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount0)
    {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return FullMath.mulDiv(
                uint256(liquidity) << Constants.RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96
            ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(uint160 sqrtRatioAX96, uint160 sqrtRatioBX96, uint128 liquidity)
        internal
        pure
        returns (uint256 amount1)
    {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, Constants.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 < sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));

        // EDIT: 0.8 compatibility
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) {
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        }
        if (absTick & 0x4 != 0) {
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        }
        if (absTick & 0x8 != 0) {
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        }
        if (absTick & 0x10 != 0) {
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        }
        if (absTick & 0x20 != 0) {
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        }
        if (absTick & 0x40 != 0) {
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        }
        if (absTick & 0x80 != 0) {
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        }
        if (absTick & 0x100 != 0) {
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        }
        if (absTick & 0x200 != 0) {
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        }
        if (absTick & 0x400 != 0) {
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        }
        if (absTick & 0x800 != 0) {
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        }
        if (absTick & 0x1000 != 0) {
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        }
        if (absTick & 0x2000 != 0) {
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        }
        if (absTick & 0x4000 != 0) {
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        }
        if (absTick & 0x8000 != 0) {
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        }
        if (absTick & 0x10000 != 0) {
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        }
        if (absTick & 0x20000 != 0) {
            ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        }
        if (absTick & 0x40000 != 0) {
            ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        }
        if (absTick & 0x80000 != 0) {
            ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;
        }

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}