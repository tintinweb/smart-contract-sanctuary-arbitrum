// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

// coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
// alpha1 + alpha2 + baseFee must be <= type(uint16).max
struct AlgebraFeeConfiguration {
  uint16 alpha1; // max value of the first sigmoid
  uint16 alpha2; // max value of the second sigmoid
  uint32 beta1; // shift along the x-axis for the first sigmoid
  uint32 beta2; // shift along the x-axis for the second sigmoid
  uint16 gamma1; // horizontal stretch factor for the first sigmoid
  uint16 gamma2; // horizontal stretch factor for the second sigmoid
  uint16 baseFee; // minimum possible fee
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

abstract contract Timestamp {
  /// @dev This function is created for testing by overriding it.
  /// @return A timestamp converted to uint32
  function _blockTimestamp() internal view virtual returns (uint32) {
    return uint32(block.timestamp); // truncation is desired
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './base/common/Timestamp.sol';
import './interfaces/IAlgebraFactory.sol';
import './interfaces/IDataStorageOperator.sol';
import './interfaces/pool/IAlgebraPoolState.sol';

import './libraries/DataStorage.sol';
import './libraries/AdaptiveFee.sol';

/// @title Algebra timepoints data operator
/// @notice This contract stores timepoints and calculates adaptive fee and statistical averages
contract DataStorageOperator is IDataStorageOperator, Timestamp {
  uint256 internal constant UINT16_MODULO = 65536;

  using DataStorage for DataStorage.Timepoint[UINT16_MODULO];

  DataStorage.Timepoint[UINT16_MODULO] public override timepoints;
  AlgebraFeeConfiguration public feeConfigZtO;
  AlgebraFeeConfiguration public feeConfigOtZ;

  /// @dev The role can be granted in AlgebraFactory
  bytes32 public constant FEE_CONFIG_MANAGER = keccak256('FEE_CONFIG_MANAGER');

  address private immutable pool;
  address private immutable factory;

  modifier onlyPool() {
    require(msg.sender == pool, 'only pool can call this');
    _;
  }

  constructor(address _pool) {
    (factory, pool) = (msg.sender, _pool);
  }

  /// @inheritdoc IDataStorageOperator
  function initialize(uint32 time, int24 tick) external override onlyPool {
    return timepoints.initialize(time, tick);
  }

  /// @inheritdoc IDataStorageOperator
  function changeFeeConfiguration(bool zto, AlgebraFeeConfiguration calldata _config) external override {
    require(msg.sender == factory || IAlgebraFactory(factory).hasRoleOrOwner(FEE_CONFIG_MANAGER, msg.sender));
    AdaptiveFee.validateFeeConfiguration(_config);

    if (zto) feeConfigZtO = _config;
    else feeConfigOtZ = _config;
    emit FeeConfiguration(zto, _config);
  }

  /// @inheritdoc IDataStorageOperator
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 lastIndex
  ) external view override returns (int56 tickCumulative, uint112 volatilityCumulative) {
    DataStorage.Timepoint memory result = timepoints.getSingleTimepoint(time, secondsAgo, tick, lastIndex, timepoints.getOldestIndex(lastIndex));
    (tickCumulative, volatilityCumulative) = (result.tickCumulative, result.volatilityCumulative);
  }

  /// @inheritdoc IDataStorageOperator
  function getTimepoints(
    uint32[] memory secondsAgos
  ) external view override returns (int56[] memory tickCumulatives, uint112[] memory volatilityCumulatives) {
    (, int24 tick, , , uint16 index, , ) = IAlgebraPoolState(pool).globalState();
    return timepoints.getTimepoints(_blockTimestamp(), secondsAgos, tick, index);
  }

  /// @inheritdoc IDataStorageOperator
  function write(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick
  ) external override onlyPool returns (uint16 indexUpdated, uint16 newFeeZtO, uint16 newFeeOtZ) {
    uint16 oldestIndex;
    (indexUpdated, oldestIndex) = timepoints.write(index, blockTimestamp, tick);

    if (index != indexUpdated) {
      uint88 volatilityAverage;
      bool hasCalculatedVolatility;
      AlgebraFeeConfiguration memory _feeConfig = feeConfigZtO;
      if (_feeConfig.alpha1 | _feeConfig.alpha2 == 0) {
        newFeeZtO = _feeConfig.baseFee;
      } else {
        uint88 lastVolatilityCumulative = timepoints[indexUpdated].volatilityCumulative;
        volatilityAverage = timepoints.getAverageVolatility(blockTimestamp, tick, indexUpdated, oldestIndex, lastVolatilityCumulative);
        hasCalculatedVolatility = true;
        newFeeZtO = AdaptiveFee.getFee(volatilityAverage, _feeConfig);
      }

      _feeConfig = feeConfigOtZ;
      if (_feeConfig.alpha1 | _feeConfig.alpha2 == 0) {
        newFeeOtZ = _feeConfig.baseFee;
      } else {
        if (!hasCalculatedVolatility) {
          uint88 lastVolatilityCumulative = timepoints[indexUpdated].volatilityCumulative;
          volatilityAverage = timepoints.getAverageVolatility(blockTimestamp, tick, indexUpdated, oldestIndex, lastVolatilityCumulative);
        }
        newFeeOtZ = AdaptiveFee.getFee(volatilityAverage, _feeConfig);
      }
    }
  }

  /// @inheritdoc IDataStorageOperator
  function prepayTimepointsStorageSlots(uint16 startIndex, uint16 amount) external {
    require(!timepoints[startIndex].initialized); // if not initialized, then all subsequent ones too
    require(amount > 0 && type(uint16).max - startIndex >= amount);

    unchecked {
      for (uint256 i = startIndex; i < startIndex + amount; ++i) {
        timepoints[i].blockTimestamp = 1; // will be overwritten
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../base/AlgebraFeeConfiguration.sol';

/// @title The interface for the Algebra Factory
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraFactory {
  /// @notice Emitted when a process of ownership renounce is started
  /// @param timestamp The timestamp of event
  /// @param finishTimestamp The timestamp when ownership renounce will be possible to finish
  event RenounceOwnershipStart(uint256 timestamp, uint256 finishTimestamp);

  /// @notice Emitted when a process of ownership renounce cancelled
  /// @param timestamp The timestamp of event
  event RenounceOwnershipStop(uint256 timestamp);

  /// @notice Emitted when a process of ownership renounce finished
  /// @param timestamp The timestamp of ownership renouncement
  event RenounceOwnershipFinish(uint256 timestamp);

  /// @notice Emitted when a pool is created
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @param pool The address of the created pool
  event Pool(address indexed token0, address indexed token1, address pool);

  /// @notice Emitted when the farming address is changed
  /// @param newFarmingAddress The farming address after the address was changed
  event FarmingAddress(address indexed newFarmingAddress);

  /// @notice Emitted when the default fee configuration is changed
  /// @param newConfig The structure with dynamic fee parameters
  /// @dev See the AdaptiveFee library for more details
  event DefaultFeeConfiguration(AlgebraFeeConfiguration newConfig);

  /// @notice Emitted when the default community fee is changed
  /// @param newDefaultCommunityFee The new default community fee value
  event DefaultCommunityFee(uint8 newDefaultCommunityFee);

  /// @notice role that can change communityFee and tickspacing in pools
  function POOLS_ADMINISTRATOR_ROLE() external view returns (bytes32);

  /// @dev Returns `true` if `account` has been granted `role` or `account` is owner.
  function hasRoleOrOwner(bytes32 role, address account) external view returns (bool);

  /// @notice Returns the current owner of the factory
  /// @dev Can be changed by the current owner via transferOwnership(address newOwner)
  /// @return The address of the factory owner
  function owner() external view returns (address);

  /// @notice Returns the current poolDeployerAddress
  /// @return The address of the poolDeployer
  function poolDeployer() external view returns (address);

  /// @dev Is retrieved from the pools to restrict calling certain functions not by a tokenomics contract
  /// @return The tokenomics contract address
  function farmingAddress() external view returns (address);

  /// @notice Returns the current communityVaultAddress
  /// @return The address to which community fees are transferred
  function communityVault() external view returns (address);

  /// @notice Returns the default community fee
  /// @return Fee which will be set at the creation of the pool
  function defaultCommunityFee() external view returns (uint8);

  /// @notice Returns the pool address for a given pair of tokens, or address 0 if it does not exist
  /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
  /// @param tokenA The contract address of either token0 or token1
  /// @param tokenB The contract address of the other token
  /// @return pool The pool address
  function poolByPair(address tokenA, address tokenB) external view returns (address pool);

  /// @return timestamp The timestamp of the beginning of the renounceOwnership process
  function renounceOwnershipStartTimestamp() external view returns (uint256 timestamp);

  /// @notice Creates a pool for the given two tokens
  /// @param tokenA One of the two tokens in the desired pool
  /// @param tokenB The other of the two tokens in the desired pool
  /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0.
  /// The call will revert if the pool already exists or the token arguments are invalid.
  /// @return pool The address of the newly created pool
  function createPool(address tokenA, address tokenB) external returns (address pool);

  /// @dev updates tokenomics address on the factory
  /// @param newFarmingAddress The new tokenomics contract address
  function setFarmingAddress(address newFarmingAddress) external;

  /// @dev updates default community fee for new pools
  /// @param newDefaultCommunityFee The new community fee, _must_ be <= MAX_COMMUNITY_FEE
  function setDefaultCommunityFee(uint8 newDefaultCommunityFee) external;

  /// @notice Changes initial fee configuration for new pools
  /// @dev changes coefficients for sigmoids: α / (1 + e^( (β-x) / γ))
  /// alpha1 + alpha2 + baseFee (max possible fee) must be <= type(uint16).max and gammas must be > 0
  /// @param newConfig new default fee configuration. See the #AdaptiveFee.sol library for details
  function setDefaultFeeConfiguration(AlgebraFeeConfiguration calldata newConfig) external;

  /// @notice Starts process of renounceOwnership. After that, a certain period
  /// of time must pass before the ownership renounce can be completed.
  function startRenounceOwnership() external;

  /// @notice Stops process of renounceOwnership and removes timer.
  function stopRenounceOwnership() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../base/AlgebraFeeConfiguration.sol';

/// @title The interface for the DataStorageOperator
/// @dev This contract stores timepoints and calculates adaptive fee and statistical averages
interface IDataStorageOperator {
  /// @notice Emitted when the fee configuration is changed
  /// @param zto Direction for new feeConfig (ZtO or OtZ)
  /// @param feeConfig The structure with dynamic fee parameters
  /// @dev See the AdaptiveFee library for more details
  event FeeConfiguration(bool zto, AlgebraFeeConfiguration feeConfig);

  /// @notice Returns data belonging to a certain timepoint
  /// @param index The index of timepoint in the array
  /// @dev There is more convenient function to fetch a timepoint: getTimepoints(). Which requires not an index but seconds
  /// @return initialized Whether the timepoint has been initialized and the values are safe to use
  /// @return blockTimestamp The timestamp of the timepoint
  /// @return tickCumulative The tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp
  /// @return volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp
  /// @return tick The tick at blockTimestamp
  /// @return averageTick Time-weighted average tick
  /// @return windowStartIndex Index of closest timepoint >= WINDOW seconds ago
  function timepoints(
    uint256 index
  )
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint88 volatilityCumulative,
      int24 tick,
      int24 averageTick,
      uint16 windowStartIndex
    );

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(uint32 time, int24 tick) external;

  /// @dev Reverts if a timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return a timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @return tickCumulative The cumulative tick since the pool was first initialized, as of `secondsAgo`
  /// @return volatilityCumulative The cumulative volatility value since the pool was first initialized, as of `secondsAgo`
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index
  ) external view returns (int56 tickCumulative, uint112 volatilityCumulative);

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return a timepoint
  /// @return tickCumulatives The cumulative tick since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(uint32[] memory secondsAgos) external view returns (int56[] memory tickCumulatives, uint112[] memory volatilityCumulatives);

  /// @notice Writes a dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  /// @return newFeeZtO The fee for ZtO swaps in hundredths of a bip, i.e. 1e-6
  /// @return newFeeOtZ The fee for OtZ swaps in hundredths of a bip, i.e. 1e-6
  function write(uint16 index, uint32 blockTimestamp, int24 tick) external returns (uint16 indexUpdated, uint16 newFeeZtO, uint16 newFeeOtZ);

  /// @notice Changes fee configuration for the pool
  function changeFeeConfiguration(bool zto, AlgebraFeeConfiguration calldata feeConfig) external;

  /// @notice Fills uninitialized timepoints with nonzero value
  /// @dev Can be used to reduce the gas cost of future swaps
  /// @param startIndex The start index, must be not initialized
  /// @param amount of slots to fill, startIndex + amount must be <= type(uint16).max
  function prepayTimepointsStorageSlots(uint16 startIndex, uint16 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /// @notice The globalState structure in the pool stores many values but requires only one slot
  /// and is exposed as a single method to save gas when accessed externally.
  /// @return price The current price of the pool as a sqrt(dToken1/dToken0) Q64.96 value;
  /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run;
  /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick boundary;
  /// @return feeZtO The last pool fee value for ZtO swaps in hundredths of a bip, i.e. 1e-6;
  /// @return feeOtZ The last pool fee value for OtZ swaps in hundredths of a bip, i.e. 1e-6;
  /// @return timepointIndex The index of the last written timepoint
  /// @return communityFee The community fee percentage of the swap fee in thousandths (1e-3)
  /// @return unlocked Whether the pool is currently locked to reentrancy
  function globalState()
    external
    view
    returns (uint160 price, int24 tick, uint16 feeZtO, uint16 feeOtZ, uint16 timepointIndex, uint8 communityFee, bool unlocked);

  /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function totalFeeGrowth0Token() external view returns (uint256);

  /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
  /// @dev This value can overflow the uint256
  function totalFeeGrowth1Token() external view returns (uint256);

  /// @notice The currently in range liquidity available to the pool
  /// @dev This value has no relationship to the total liquidity across all ticks.
  /// Returned value cannot exceed type(uint128).max
  function liquidity() external view returns (uint128);

  /// @notice The current tick spacing
  /// @dev Ticks can only be used at multiples of this value
  /// e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The current tick spacing
  function tickSpacing() external view returns (int24);

  /// @notice The current tick spacing for limit orders
  /// @dev Ticks can only be used for limit orders at multiples of this value
  /// This value is an int24 to avoid casting even though it is always positive.
  /// @return The current tick spacing for limit orders
  function tickSpacingLimitOrders() external view returns (int24);

  /// @notice The timestamp of the last sending of tokens to community vault
  function communityFeeLastTimestamp() external view returns (uint32);

  /// @notice The previous active tick
  function prevInitializedTick() external view returns (int24);

  /// @notice The amounts of token0 and token1 that will be sent to the vault
  /// @dev Will be sent COMMUNITY_FEE_TRANSFER_FREQUENCY after communityFeeLastTimestamp
  function getCommunityFeePending() external view returns (uint128 communityFeePending0, uint128 communityFeePending1);

  /// @notice The tracked token0 and token1 reserves of pool
  /// @dev If at any time the real balance is larger, the excess will be transferred to liquidity providers as additional fee.
  /// If the balance exceeds uint128, the excess will be sent to the communityVault.
  function getReserves() external view returns (uint128 reserve0, uint128 reserve1);

  /// @notice The accumulator of seconds per liquidity since the pool was first initialized
  function secondsPerLiquidityCumulative() external view returns (uint160);

  /// @notice Look up information about a specific tick in the pool
  /// @param tick The tick to look up
  /// @return liquidityTotal The total amount of position liquidity that uses the pool either as tick lower or tick upper
  /// @return liquidityDelta How much liquidity changes when the pool price crosses the tick
  /// @return outerFeeGrowth0Token The fee growth on the other side of the tick from the current tick in token0
  /// @return outerFeeGrowth1Token The fee growth on the other side of the tick from the current tick in token1
  /// @return prevTick The previous tick in tick list
  /// @return nextTick The next tick in tick list
  /// @return outerSecondsPerLiquidity The seconds spent per liquidity on the other side of the tick from the current tick
  /// @return outerSecondsSpent The seconds spent on the other side of the tick from the current tick
  /// @return hasLimitOrders Whether there are limit orders on this tick or not
  /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
  /// a specific position.
  function ticks(
    int24 tick
  )
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int24 prevTick,
      int24 nextTick,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool hasLimitOrders
    );

  /// @notice Returns the summary information about a limit orders at tick
  /// @param tick The tick to look up
  /// @return amountToSell The amount of tokens to sell. Has only relative meaning
  /// @return soldAmount The amount of tokens already sold. Has only relative meaning
  /// @return boughtAmount0Cumulative The accumulator of bought tokens0 per amountToSell. Has only relative meaning
  /// @return boughtAmount1Cumulative The accumulator of bought tokens1 per amountToSell. Has only relative meaning
  /// @return initialized Will be true if a limit order was created at least once on this tick
  function limitOrders(
    int24 tick
  )
    external
    view
    returns (uint128 amountToSell, uint128 soldAmount, uint256 boughtAmount0Cumulative, uint256 boughtAmount1Cumulative, bool initialized);

  /// @notice Returns 256 packed tick initialized boolean values. See TickTree for more information
  function tickTable(int16 wordPosition) external view returns (uint256);

  /// @notice Returns the information about a position by the position's key
  /// @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
  /// @return liquidity The amount of liquidity in the position
  /// @return innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke
  /// @return innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke
  /// @return fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke
  /// @return fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
  function positions(
    bytes32 key
  ) external view returns (uint256 liquidity, uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token, uint128 fees0, uint128 fees1);

  /// @notice Returns the information about active incentive
  /// @dev if there is no active incentive at the moment, incentiveAddress would be equal to address(0)
  /// @return incentiveAddress The address associated with the current active incentive
  function activeIncentive() external view returns (address incentiveAddress);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../base/AlgebraFeeConfiguration.sol';
import './Constants.sol';

/// @title AdaptiveFee
/// @notice Calculates fee based on combination of sigmoids
library AdaptiveFee {
  /// @notice Returns default initial fee configuration
  function initialFeeConfiguration() internal pure returns (AlgebraFeeConfiguration memory) {
    return
      AlgebraFeeConfiguration(
        3000 - Constants.BASE_FEE, // alpha1, max value of the first sigmoid in hundredths of a bip, i.e. 1e-6
        15000 - 3000, // alpha2, max value of the second sigmoid in hundredths of a bip, i.e. 1e-6
        360, // beta1, shift along the x-axis (volatility) for the first sigmoid
        60000, // beta2, shift along the x-axis (volatility) for the second sigmoid
        59, // gamma1, horizontal stretch factor for the first sigmoid
        8500, // gamma2, horizontal stretch factor for the second sigmoid
        Constants.BASE_FEE // baseFee in hundredths of a bip, i.e. 1e-6
      );
  }

  /// @notice Validates fee configuration.
  /// @dev Maximum fee value capped by baseFee + alpha1 + alpha2 must be <= type(uint16).max
  /// gammas must be > 0
  function validateFeeConfiguration(AlgebraFeeConfiguration memory _config) internal pure {
    require(uint256(_config.alpha1) + uint256(_config.alpha2) + uint256(_config.baseFee) <= type(uint16).max, 'Max fee exceeded');
    require(_config.gamma1 != 0 && _config.gamma2 != 0, 'Gammas must be > 0');
  }

  /// @notice Calculates fee based on formula:
  /// baseFee + sigmoidVolume(sigmoid1(volatility, volumePerLiquidity) + sigmoid2(volatility, volumePerLiquidity))
  /// maximum value capped by baseFee + alpha1 + alpha2
  function getFee(uint88 volatility, AlgebraFeeConfiguration memory config) internal pure returns (uint16 fee) {
    unchecked {
      volatility /= 15; // normalize for 15 sec interval
      uint256 sumOfSigmoids = sigmoid(volatility, config.gamma1, config.alpha1, config.beta1) +
        sigmoid(volatility, config.gamma2, config.alpha2, config.beta2);

      if (sumOfSigmoids > type(uint16).max) sumOfSigmoids = type(uint16).max; // should be impossible, just in case

      return uint16(config.baseFee + sumOfSigmoids); // safe since alpha1 + alpha2 + baseFee _must_ be <= type(uint16).max
    }
  }

  /// @notice calculates α / (1 + e^( (β-x) / γ))
  /// that is a sigmoid with a maximum value of α, x-shifted by β, and stretched by γ
  /// @dev returns uint256 for fuzzy testing. Guaranteed that the result is not greater than alpha
  function sigmoid(uint256 x, uint16 g, uint16 alpha, uint256 beta) internal pure returns (uint256 res) {
    unchecked {
      if (x > beta) {
        x = x - beta;
        if (x >= 6 * uint256(g)) return alpha; // so x < 19 bits
        uint256 g4 = uint256(g) ** 4; // < 64 bits (4*16)
        uint256 ex = expXg4(x, g, g4); // < 155 bits
        res = (alpha * ex) / (g4 + ex); // in worst case: (16 + 155 bits) / 155 bits
        // so res <= alpha
      } else {
        x = beta - x;
        if (x >= 6 * uint256(g)) return 0; // so x < 19 bits
        uint256 g4 = uint256(g) ** 4; // < 64 bits (4*16)
        uint256 ex = g4 + expXg4(x, g, g4); // < 156 bits
        res = (alpha * g4) / ex; // in worst case: (16 + 128 bits) / 156 bits
        // g8 <= ex, so res <= alpha
      }
    }
  }

  /// @notice calculates e^(x/g) * g^4 in a series, since (around zero):
  /// e^x = 1 + x + x^2/2 + ... + x^n/n! + ...
  /// e^(x/g) = 1 + x/g + x^2/(2*g^2) + ... + x^(n)/(g^n * n!) + ...
  /// @dev has good accuracy only if x/g < 6
  function expXg4(uint256 x, uint16 g, uint256 gHighestDegree) internal pure returns (uint256 res) {
    uint256 closestValue; // nearest 'table' value of e^(x/g), multiplied by 10^20
    assembly {
      let xdg := div(x, g)
      switch xdg
      case 0 {
        closestValue := 100000000000000000000 // 1
      }
      case 1 {
        closestValue := 271828182845904523536 // ~= e
      }
      case 2 {
        closestValue := 738905609893065022723 // ~= e^2
      }
      case 3 {
        closestValue := 2008553692318766774092 // ~= e^3
      }
      case 4 {
        closestValue := 5459815003314423907811 // ~= e^4
      }
      default {
        closestValue := 14841315910257660342111 // ~= e^5
      }

      x := mod(x, g)
    }

    unchecked {
      if (x >= g / 2) {
        // (x - closestValue) >= 0.5, so closestValue := closestValue * e^0.5
        x -= g / 2;
        closestValue = (closestValue * 164872127070012814684) / 1e20;
      }

      // After calculating the closestValue x/g is <= 0.5, so that the series in the neighborhood of zero converges with sufficient speed
      uint256 xLowestDegree = x;
      res = gHighestDegree; // g**4, res < 64 bits

      gHighestDegree /= g; // g**3
      res += xLowestDegree * gHighestDegree; // g**4 + x*g**3, res < 68

      gHighestDegree /= g; // g**2
      xLowestDegree *= x; // x**2
      // g**4 + x * g**3 + (x**2 * g**2) / 2, res < 71
      res += (xLowestDegree * gHighestDegree) / 2;

      gHighestDegree /= g; // g
      xLowestDegree *= x; // x**3
      // g^4 + x * g^3 + (x^2 * g^2)/2 + x^3(g*4 + x)/24, res < 73
      res += (xLowestDegree * g * 4 + xLowestDegree * x) / 24;

      // res = g^4 * (1 + x/g + x^2/(2*g^2) + x^3/(6*g^3) + x^4/(24*g^4)) * closestValue / 10^20, closestValue < 75 bits, res < 155
      res = (res * closestValue) / (1e20);
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.17;

library Constants {
  uint8 internal constant RESOLUTION = 96;
  uint256 internal constant Q64 = 1 << 64;
  uint256 internal constant Q96 = 1 << 96;
  uint256 internal constant Q128 = 1 << 128;
  int256 internal constant Q160 = 1 << 160;

  uint16 internal constant BASE_FEE = 0.0001e6; // init minimum fee value in hundredths of a bip (0.01%)
  uint24 internal constant FEE_DENOMINATOR = 1e6;
  int24 internal constant INIT_TICK_SPACING = 60;
  int24 internal constant MAX_TICK_SPACING = 500;

  // the frequency with which the accumulated community fees are sent to the vault
  uint32 internal constant COMMUNITY_FEE_TRANSFER_FREQUENCY = 8 hours;

  // max(uint128) / ( (MAX_TICK - MIN_TICK) )
  uint128 internal constant MAX_LIQUIDITY_PER_TICK = 40564824043007195767232224305152;

  uint8 internal constant MAX_COMMUNITY_FEE = 0.25e3; // 25%
  uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1e3;
  // role that can change communityFee and tickspacing in pools
  bytes32 internal constant POOLS_ADMINISTRATOR_ROLE = keccak256('POOLS_ADMINISTRATOR');
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

/// @title DataStorage
/// @notice Provides price, liquidity, volatility data useful for a wide variety of system designs
/// @dev Instances of stored dataStorage data, "timepoints", are collected in the dataStorage array
/// Timepoints are overwritten when the full length of the dataStorage array is populated.
/// The most recent timepoint is available by passing 0 to getSingleTimepoint()
library DataStorage {
  /// @notice `target` timestamp is older than oldest timepoint
  error targetIsTooOld();

  uint32 internal constant WINDOW = 1 days;
  uint256 private constant UINT16_MODULO = 65536;

  struct Timepoint {
    bool initialized; // whether or not the timepoint is initialized
    uint32 blockTimestamp; // the block timestamp of the timepoint
    int56 tickCumulative; // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
    uint88 volatilityCumulative; // the volatility accumulator; overflow after ~34800 years is desired :)
    int24 tick; // tick at this blockTimestamp
    int24 averageTick; // average tick at this blockTimestamp (for WINDOW seconds)
    uint16 windowStartIndex; // index of closest timepoint >= WINDOW seconds ago, used to speed up searches
  }

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param self The stored dataStorage array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(Timepoint[UINT16_MODULO] storage self, uint32 time, int24 tick) internal {
    Timepoint storage _zero = self[0];
    require(!_zero.initialized);
    (_zero.initialized, _zero.blockTimestamp, _zero.tick, _zero.averageTick) = (true, time, tick, tick);
  }

  /// @notice Writes a dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param self The stored dataStorage array
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  /// @return oldestIndex The index of the oldest timepoint
  function write(
    Timepoint[UINT16_MODULO] storage self,
    uint16 lastIndex,
    uint32 blockTimestamp,
    int24 tick
  ) internal returns (uint16 indexUpdated, uint16 oldestIndex) {
    Timepoint memory last = self[lastIndex];
    // early return if we've already written a timepoint this block
    if (last.blockTimestamp == blockTimestamp) return (lastIndex, 0);

    // get next index considering overflow
    unchecked {
      indexUpdated = lastIndex + 1;
    }

    // check if we have overflow in the past
    if (self[indexUpdated].initialized) oldestIndex = indexUpdated;

    (int24 avgTick, uint16 windowStartIndex) = _getAverageTickCasted(
      self,
      blockTimestamp,
      tick,
      lastIndex,
      oldestIndex,
      last.blockTimestamp,
      last.tickCumulative
    );
    self[indexUpdated] = _createNewTimepoint(last, blockTimestamp, tick, avgTick, windowStartIndex);
    if (oldestIndex == indexUpdated) oldestIndex++; // previous oldest index has been overwritten
  }

  /// @dev Reverts if a timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param self The stored dataStorage array
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return a timepoint
  /// @param tick The current tick
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @param oldestIndex The index of the oldest timepoint
  /// @return targetTimepoint desired timepoint or it's approximation
  function getSingleTimepoint(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 lastIndex,
    uint16 oldestIndex
  ) internal view returns (Timepoint memory targetTimepoint) {
    unchecked {
      uint32 target = time - secondsAgo;
      (Timepoint storage beforeOrAt, Timepoint storage atOrAfter, bool samePoint, ) = _getTimepointsAt(self, time, target, lastIndex, oldestIndex);

      targetTimepoint = beforeOrAt;
      if (target == targetTimepoint.blockTimestamp) return targetTimepoint; // we're at the left boundary
      if (samePoint) {
        // if target is newer than last timepoint
        (int24 avgTick, uint16 windowStartIndex) = _getAverageTickCasted(
          self,
          time,
          tick,
          lastIndex,
          oldestIndex,
          targetTimepoint.blockTimestamp,
          targetTimepoint.tickCumulative
        );
        return _createNewTimepoint(targetTimepoint, time - secondsAgo, tick, avgTick, windowStartIndex);
      }

      (uint32 timestampAfter, int56 tickCumulativeAfter) = (atOrAfter.blockTimestamp, atOrAfter.tickCumulative);
      if (target == timestampAfter) return atOrAfter; // we're at the right boundary

      // we're in the middle
      (uint32 timepointTimeDelta, uint32 targetDelta) = (timestampAfter - targetTimepoint.blockTimestamp, target - targetTimepoint.blockTimestamp);

      targetTimepoint.tickCumulative +=
        ((tickCumulativeAfter - targetTimepoint.tickCumulative) / int56(uint56(timepointTimeDelta))) *
        int56(uint56(targetDelta));
      targetTimepoint.volatilityCumulative +=
        ((atOrAfter.volatilityCumulative - targetTimepoint.volatilityCumulative) / timepointTimeDelta) *
        targetDelta;
    }
  }

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param self The stored dataStorage array
  /// @param time The current block.timestamp
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return a timepoint
  /// @param tick The current tick
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 lastIndex
  ) internal view returns (int56[] memory tickCumulatives, uint112[] memory volatilityCumulatives) {
    uint256 secondsLength = secondsAgos.length;
    tickCumulatives = new int56[](secondsLength);
    volatilityCumulatives = new uint112[](secondsLength);

    uint16 oldestIndex = getOldestIndex(self, lastIndex);
    Timepoint memory current;
    unchecked {
      for (uint256 i; i < secondsLength; ++i) {
        current = getSingleTimepoint(self, time, secondsAgos[i], tick, lastIndex, oldestIndex);
        (tickCumulatives[i], volatilityCumulatives[i]) = (current.tickCumulative, current.volatilityCumulative);
      }
    }
  }

  /// @notice Returns the index of the oldest timepoint
  /// @param self The stored dataStorage array
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @return oldestIndex The index of the oldest timepoint
  function getOldestIndex(Timepoint[UINT16_MODULO] storage self, uint16 lastIndex) internal view returns (uint16 oldestIndex) {
    unchecked {
      uint16 nextIndex = lastIndex + 1; // considering overflow
      if (self[nextIndex].initialized) oldestIndex = nextIndex; // check if we have overflow in the past
    }
  }

  /// @notice Returns average volatility in the range from time-WINDOW to time
  /// @param self The stored dataStorage array
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @param oldestIndex The index of the oldest timepoint
  /// @return volatilityAverage The average volatility in the recent range
  function getAverageVolatility(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    int24 tick,
    uint16 lastIndex,
    uint16 oldestIndex,
    uint88 lastCumulativeVolatility
  ) internal view returns (uint88 volatilityAverage) {
    unchecked {
      uint32 oldestTimestamp = self[oldestIndex].blockTimestamp;

      if (_lteConsideringOverflow(oldestTimestamp, time - WINDOW, time)) {
        if (self[lastIndex].blockTimestamp == time) {
          // we can simplify the search, because when the timepoint was created, the search was already done
          oldestIndex = self[lastIndex].windowStartIndex;
          oldestTimestamp = self[oldestIndex].blockTimestamp;
          if (lastIndex != oldestIndex) lastIndex = oldestIndex + 1;
        }

        uint88 cumulativeVolatilityAtStart = _getVolatilityCumulativeAt(self, time, WINDOW, tick, lastIndex, oldestIndex);
        return ((lastCumulativeVolatility - cumulativeVolatilityAtStart) / WINDOW); // sample is big enough to ignore bias of variance
      } else if (time != oldestTimestamp) {
        // recorded timepoints are not enough, so we will extrapolate
        uint88 _oldestVolatilityCumulative = self[oldestIndex].volatilityCumulative;
        uint32 unbiasedDenominator = time - oldestTimestamp;
        if (unbiasedDenominator > 1) unbiasedDenominator--; // Bessel's correction for "small" sample
        return ((lastCumulativeVolatility - _oldestVolatilityCumulative) / unbiasedDenominator);
      }
    }
  }

  // ##### further functions are private to the library, but some are made internal for fuzzy testing #####

  /// @notice Transforms a previous timepoint into a new timepoint, given the passage of time and the current tick and liquidity values
  /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
  /// @dev The function changes the structure given to the input, and does not create a new one
  /// @param last The specified timepoint to be used in creation of new timepoint
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param averageTick The average tick at the time of the new timepoint
  /// @param windowStartIndex The index of closest timepoint >= WINDOW seconds ago
  /// @return Timepoint The newly populated timepoint
  function _createNewTimepoint(
    Timepoint memory last,
    uint32 blockTimestamp,
    int24 tick,
    int24 averageTick,
    uint16 windowStartIndex
  ) private pure returns (Timepoint memory) {
    unchecked {
      uint32 delta = blockTimestamp - last.blockTimestamp; // overflow is desired
      // We don't create a new structure in memory to save gas. Therefore, the function changes the old structure
      last.initialized = true;
      last.blockTimestamp = blockTimestamp;
      last.tickCumulative += int56(tick) * int56(uint56(delta));
      last.volatilityCumulative += uint88(_volatilityOnRange(int256(uint256(delta)), last.tick, tick, last.averageTick, averageTick)); // always fits 88 bits
      last.tick = tick;
      last.averageTick = averageTick;
      last.windowStartIndex = windowStartIndex;
      return last;
    }
  }

  /// @notice Calculates volatility between two sequential timepoints with resampling to 1 sec frequency
  /// @param dt Timedelta between timepoints, must be within uint32 range
  /// @param tick0 The tick at the left timepoint, must be within int24 range
  /// @param tick1 The tick at the right timepoint, must be within int24 range
  /// @param avgTick0 The average tick at the left timepoint, must be within int24 range
  /// @param avgTick1 The average tick at the right timepoint, must be within int24 range
  /// @return volatility The volatility between two sequential timepoints
  /// If the requirements for the parameters are met, it always fits 88 bits
  function _volatilityOnRange(int256 dt, int256 tick0, int256 tick1, int256 avgTick0, int256 avgTick1) internal pure returns (uint256 volatility) {
    // On the time interval from the previous timepoint to the current
    // we can represent tick and average tick change as two straight lines:
    // tick = k*t + b, where k and b are some constants
    // avgTick = p*t + q, where p and q are some constants
    // we want to get sum of (tick(t) - avgTick(t))^2 for every t in the interval (0; dt]
    // so: (tick(t) - avgTick(t))^2 = ((k*t + b) - (p*t + q))^2 = (k-p)^2 * t^2 + 2(k-p)(b-q)t + (b-q)^2
    // since everything except t is a constant, we need to use progressions for t and t^2:
    // sum(t) for t from 1 to dt = dt*(dt + 1)/2 = sumOfSequence
    // sum(t^2) for t from 1 to dt = dt*(dt+1)*(2dt + 1)/6 = sumOfSquares
    // so result will be: (k-p)^2 * sumOfSquares + 2(k-p)(b-q)*sumOfSequence + dt*(b-q)^2
    unchecked {
      int256 K = (tick1 - tick0) - (avgTick1 - avgTick0); // (k - p)*dt
      int256 B = (tick0 - avgTick0) * dt; // (b - q)*dt
      int256 sumOfSequence = dt * (dt + 1); // sumOfSequence * 2
      int256 sumOfSquares = sumOfSequence * (2 * dt + 1); // sumOfSquares * 6
      volatility = uint256((K ** 2 * sumOfSquares + 6 * B * K * sumOfSequence + 6 * dt * B ** 2) / (6 * dt ** 2));
    }
  }

  /// @notice Calculates average tick for WINDOW seconds at the moment of `time`
  /// @dev Guaranteed that the result is within the bounds of int24
  /// @return avgTick int256 for fuzzy tests
  /// @return windowStartIndex The index of closest timepoint <= WINDOW seconds ago
  function _getAverageTickCasted(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    int24 tick,
    uint16 lastIndex,
    uint16 oldestIndex,
    uint32 lastTimestamp,
    int56 lastTickCumulative
  ) private view returns (int24 avgTick, uint16 windowStartIndex) {
    (int256 _avgTick, uint256 _windowStartIndex) = _getAverageTick(self, time, tick, lastIndex, oldestIndex, lastTimestamp, lastTickCumulative);
    unchecked {
      (avgTick, windowStartIndex) = (int24(_avgTick), uint16(_windowStartIndex)); // overflow in uint16(_windowStartIndex) is desired
    }
  }

  /// @notice Calculates average tick for WINDOW seconds at the moment of `time`
  /// @dev Guaranteed that the result is within the bounds of int24, but result is not casted
  /// @return avgTick int256 for fuzzy tests
  /// @return windowStartIndex The index of closest timepoint <= WINDOW seconds ago
  function _getAverageTick(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    int24 tick,
    uint16 lastIndex,
    uint16 oldestIndex,
    uint32 lastTimestamp,
    int56 lastTickCumulative
  ) internal view returns (int256 avgTick, uint256 windowStartIndex) {
    (uint32 oldestTimestamp, int56 oldestTickCumulative) = (self[oldestIndex].blockTimestamp, self[oldestIndex].tickCumulative);
    unchecked {
      if (!_lteConsideringOverflow(oldestTimestamp, time - WINDOW, time)) {
        // if oldest is newer than WINDOW ago
        return (
          (lastTimestamp == oldestTimestamp) ? tick : (lastTickCumulative - oldestTickCumulative) / int56(uint56(lastTimestamp - oldestTimestamp)),
          oldestIndex
        );
      }

      if (_lteConsideringOverflow(lastTimestamp, time - WINDOW, time)) {
        Timepoint storage _start = self[lastIndex - 1]; // considering underflow
        (bool initialized, uint32 startTimestamp, int56 startTickCumulative) = (_start.initialized, _start.blockTimestamp, _start.tickCumulative);
        avgTick = initialized ? (lastTickCumulative - startTickCumulative) / int56(uint56(lastTimestamp - startTimestamp)) : tick;
        windowStartIndex = lastIndex;
      } else {
        if (time == lastTimestamp) {
          oldestIndex = self[lastIndex].windowStartIndex;
          lastIndex = oldestIndex + 1;
        }
        int56 tickCumulativeAtStart;
        (tickCumulativeAtStart, windowStartIndex) = _getTickCumulativeAt(self, time, WINDOW, tick, lastIndex, oldestIndex);

        //    current-WINDOW  last   current
        // _________*____________*_______*_
        //           ||||||||||||
        avgTick = (lastTickCumulative - tickCumulativeAtStart) / int56(uint56(lastTimestamp - time + WINDOW));
      }
    }
  }

  /// @notice comparator for 32-bit timestamps
  /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to currentTime
  /// @param a A comparison timestamp from which to determine the relative position of `currentTime`
  /// @param b From which to determine the relative position of `currentTime`
  /// @param currentTime A timestamp truncated to 32 bits
  /// @return res Whether `a` is chronologically <= `b`
  function _lteConsideringOverflow(uint32 a, uint32 b, uint32 currentTime) private pure returns (bool res) {
    res = a > currentTime;
    if (res == b > currentTime) res = a <= b; // if both are on the same side
  }

  /// @notice Calculates cumulative volatility at the moment of `time` - `secondsAgo`
  /// @dev More optimal than via `getSingleTimepoint`
  /// @return volatilityCumulative The cumulative volatility
  function _getVolatilityCumulativeAt(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 lastIndex,
    uint16 oldestIndex
  ) internal view returns (uint88 volatilityCumulative) {
    unchecked {
      uint32 target = time - secondsAgo;
      (Timepoint memory beforeOrAt, Timepoint storage atOrAfter, bool samePoint, ) = _getTimepointsAt(self, time, target, lastIndex, oldestIndex);

      if (target == beforeOrAt.blockTimestamp) return beforeOrAt.volatilityCumulative; // we're at the left boundary
      if (samePoint) {
        // since target != beforeOrAt.blockTimestamp, `samePoint` means that target is newer than last timepoint
        (int24 avgTick, ) = _getAverageTickCasted(self, time, tick, lastIndex, oldestIndex, beforeOrAt.blockTimestamp, beforeOrAt.tickCumulative);
        return (beforeOrAt.volatilityCumulative +
          uint88(_volatilityOnRange(int256(uint256(target - beforeOrAt.blockTimestamp)), beforeOrAt.tick, tick, beforeOrAt.averageTick, avgTick)));
      }

      (uint32 timestampAfter, uint88 volatilityCumulativeAfter) = (atOrAfter.blockTimestamp, atOrAfter.volatilityCumulative);
      if (target == timestampAfter) return volatilityCumulativeAfter; // we're at the right boundary

      // we're in the middle
      (uint32 timepointTimeDelta, uint32 targetDelta) = (timestampAfter - beforeOrAt.blockTimestamp, target - beforeOrAt.blockTimestamp);

      return beforeOrAt.volatilityCumulative + ((volatilityCumulativeAfter - beforeOrAt.volatilityCumulative) / timepointTimeDelta) * targetDelta;
    }
  }

  /// @notice Calculates cumulative tick at the moment of `time` - `secondsAgo`
  /// @dev More optimal than via `getSingleTimepoint`
  /// @return tickCumulative The cumulative tick
  /// @return indexBeforeOrAt The index of closest timepoint before ot at the moment of `time` - `secondsAgo`
  function _getTickCumulativeAt(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 lastIndex,
    uint16 oldestIndex
  ) private view returns (int56 tickCumulative, uint256 indexBeforeOrAt) {
    unchecked {
      uint32 target = time - secondsAgo;
      (Timepoint storage beforeOrAt, Timepoint storage atOrAfter, bool samePoint, uint256 _indexBeforeOrAt) = _getTimepointsAt(
        self,
        time,
        target,
        lastIndex,
        oldestIndex
      );

      (uint32 timestampBefore, int56 tickCumulativeBefore) = (beforeOrAt.blockTimestamp, beforeOrAt.tickCumulative);
      if (target == timestampBefore) return (tickCumulativeBefore, _indexBeforeOrAt); // we're at the left boundary
      // since target != timestampBefore, `samePoint` means that target is newer than last timepoint
      if (samePoint) return ((tickCumulativeBefore + int56(tick) * int56(uint56(target - timestampBefore))), _indexBeforeOrAt); // if target is newer than last timepoint

      (uint32 timestampAfter, int56 tickCumulativeAfter) = (atOrAfter.blockTimestamp, atOrAfter.tickCumulative);
      if (target == timestampAfter) return (tickCumulativeAfter, _indexBeforeOrAt); // we're at the right boundary

      // we're in the middle
      (uint32 timepointTimeDelta, uint32 targetDelta) = (timestampAfter - timestampBefore, target - timestampBefore);
      return (
        tickCumulativeBefore + ((tickCumulativeAfter - tickCumulativeBefore) / int56(uint56(timepointTimeDelta))) * int56(uint56(targetDelta)),
        _indexBeforeOrAt
      );
    }
  }

  /// @notice Returns closest timepoint or timepoints to the moment of `target`
  /// @return beforeOrAt The timepoint recorded before, or at, the target
  /// @return atOrAfter The timepoint recorded at, or after, the target
  /// @return samePoint Are `beforeOrAt` and `atOrAfter` the same or not
  /// @return indexBeforeOrAt The index of closest timepoint before ot at the moment of `target`
  function _getTimepointsAt(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 target,
    uint16 lastIndex,
    uint16 oldestIndex
  ) private view returns (Timepoint storage beforeOrAt, Timepoint storage atOrAfter, bool samePoint, uint256 indexBeforeOrAt) {
    // if target is newer than last timepoint
    if (target == time || _lteConsideringOverflow(self[lastIndex].blockTimestamp, target, time)) {
      return (self[lastIndex], self[lastIndex], true, lastIndex);
    }

    uint32 oldestTimestamp = self[oldestIndex].blockTimestamp;
    if (!_lteConsideringOverflow(oldestTimestamp, target, time)) revert targetIsTooOld();

    if (oldestTimestamp == target) return (self[oldestIndex], self[oldestIndex], true, oldestIndex);

    unchecked {
      if (time - target <= WINDOW) {
        // we can limit the scope of the search
        uint16 windowStartIndex = self[lastIndex].windowStartIndex;
        if (windowStartIndex != oldestIndex) {
          uint32 windowStartTimestamp = self[windowStartIndex].blockTimestamp;
          if (_lteConsideringOverflow(oldestTimestamp, windowStartTimestamp, time)) {
            (oldestIndex, oldestTimestamp) = (windowStartIndex, windowStartTimestamp);
            if (oldestTimestamp == target) return (self[oldestIndex], self[oldestIndex], true, oldestIndex);
          }
        }
      }
      // no need to search if we already know the answer
      if (lastIndex == oldestIndex + 1) return (self[oldestIndex], self[lastIndex], false, oldestIndex);
    }

    (beforeOrAt, atOrAfter, indexBeforeOrAt) = _binarySearch(self, time, target, lastIndex, oldestIndex);
    return (beforeOrAt, atOrAfter, false, indexBeforeOrAt);
  }

  /// @notice Fetches the timepoints beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
  /// The result may be the same timepoint, or adjacent timepoints.
  /// @dev The answer must be contained in the array, used when the target is located within the stored timepoint
  /// boundaries: older than the most recent timepoint and younger, or the same age as, the oldest timepoint
  /// @param self The stored dataStorage array
  /// @param time The current block.timestamp
  /// @param target The timestamp at which the reserved timepoint should be for
  /// @param lastIndex The index of the timepoint that was most recently written to the timepoints array
  /// @param oldestIndex The index of the oldest timepoint in the timepoints array
  /// @return beforeOrAt The timepoint recorded before, or at, the target
  /// @return atOrAfter The timepoint recorded at, or after, the target
  function _binarySearch(
    Timepoint[UINT16_MODULO] storage self,
    uint32 time,
    uint32 target,
    uint16 lastIndex,
    uint16 oldestIndex
  ) private view returns (Timepoint storage beforeOrAt, Timepoint storage atOrAfter, uint256 indexBeforeOrAt) {
    unchecked {
      uint256 left = oldestIndex; // oldest timepoint
      uint256 right = lastIndex < oldestIndex ? lastIndex + UINT16_MODULO : lastIndex; // newest timepoint considering one index overflow
      indexBeforeOrAt = (left + right) >> 1; // "middle" point between the boundaries

      do {
        beforeOrAt = self[uint16(indexBeforeOrAt)]; // checking the "middle" point between the boundaries
        (bool initializedBefore, uint32 timestampBefore) = (beforeOrAt.initialized, beforeOrAt.blockTimestamp);
        if (initializedBefore) {
          if (_lteConsideringOverflow(timestampBefore, target, time)) {
            // is current point before or at `target`?
            atOrAfter = self[uint16(indexBeforeOrAt + 1)]; // checking the next point after "middle"
            (bool initializedAfter, uint32 timestampAfter) = (atOrAfter.initialized, atOrAfter.blockTimestamp);
            if (initializedAfter) {
              if (_lteConsideringOverflow(target, timestampAfter, time)) {
                // is the "next" point after or at `target`?
                return (beforeOrAt, atOrAfter, indexBeforeOrAt); // the only fully correct way to finish
              }
              left = indexBeforeOrAt + 1; // "next" point is before the `target`, so looking in the right half
            } else {
              // beforeOrAt is initialized and <= target, and next timepoint is uninitialized
              // should be impossible if initial boundaries and `target` are correct
              return (beforeOrAt, beforeOrAt, indexBeforeOrAt);
            }
          } else {
            right = indexBeforeOrAt - 1; // current point is after the `target`, so looking in the left half
          }
        } else {
          // we've landed on an uninitialized timepoint, keep searching higher
          // should be impossible if initial boundaries and `target` are correct
          left = indexBeforeOrAt + 1;
        }
        indexBeforeOrAt = (left + right) >> 1; // calculating the new "middle" point index after updating the bounds
      } while (true);

      atOrAfter = beforeOrAt; // code is unreachable, to suppress compiler warning
      assert(false); // code is unreachable, used for fuzzy testing
    }
  }
}