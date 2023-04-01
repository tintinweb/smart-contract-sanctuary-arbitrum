// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;
pragma abicoder v1;

import './interfaces/IDataStorageOperator.sol';

import './base/AlgebraPoolBase.sol';
import './base/DerivedState.sol';
import './base/ReentrancyGuard.sol';
import './base/Positions.sol';
import './base/LimitOrderPositions.sol';
import './base/SwapCalculation.sol';
import './base/ReservesManager.sol';
import './base/TickStructure.sol';

import './libraries/FullMath.sol';
import './libraries/Constants.sol';
import './libraries/SafeTransfer.sol';
import './libraries/SafeCast.sol';
import './libraries/TickMath.sol';
import './libraries/LiquidityMath.sol';

import './interfaces/IAlgebraFactory.sol';
import './interfaces/callback/IAlgebraMintCallback.sol';
import './interfaces/callback/IAlgebraFlashCallback.sol';

/// @title Algebra concentrated liquidity pool
/// @notice This contract is responsible for liquidity positions, swaps and flashloans
contract AlgebraPool is
  AlgebraPoolBase,
  DerivedState,
  ReentrancyGuard,
  Positions,
  LimitOrderPositions,
  SwapCalculation,
  ReservesManager,
  TickStructure
{
  using SafeCast for uint256;

  /// @inheritdoc IAlgebraPoolActions
  function initialize(uint160 initialPrice) external override {
    if (globalState.price != 0) revert alreadyInitialized(); // after initialization, the price can never become zero
    int24 tick = TickMath.getTickAtSqrtRatio(initialPrice); // getTickAtSqrtRatio checks validity of initialPrice inside
    IDataStorageOperator(dataStorageOperator).initialize(_blockTimestamp(), tick);
    lastTimepointTimestamp = _blockTimestamp();

    globalState.price = initialPrice;
    globalState.communityFee = IAlgebraFactory(factory).defaultCommunityFee();
    globalState.unlocked = true;
    globalState.tick = tick;

    emit Initialize(initialPrice, tick);
  }

  /// @inheritdoc IAlgebraPoolActions
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 liquidityDesired,
    bytes calldata data
  ) external override nonReentrant onlyValidTicks(bottomTick, topTick) returns (uint256 amount0, uint256 amount1, uint128 liquidityActual) {
    if (liquidityDesired == 0) revert zeroLiquidityDesired();
    unchecked {
      int24 _tickSpacing = bottomTick == topTick ? tickSpacingLimitOrders : tickSpacing;
      if (bottomTick % _tickSpacing | topTick % _tickSpacing != 0) revert tickIsNotSpaced();
    }
    if (bottomTick == topTick) {
      (amount0, amount1) = bottomTick > globalState.tick ? (uint256(liquidityDesired), uint256(0)) : (uint256(0), uint256(liquidityDesired));
    } else {
      (amount0, amount1, ) = LiquidityMath.getAmountsForLiquidity(bottomTick, topTick, int128(liquidityDesired), globalState.tick, globalState.price);
    }

    (uint256 receivedAmount0, uint256 receivedAmount1) = _updateReserves();
    IAlgebraMintCallback(msg.sender).algebraMintCallback(amount0, amount1, data);

    receivedAmount0 = amount0 == 0 ? 0 : _balanceToken0() - receivedAmount0;
    receivedAmount1 = amount1 == 0 ? 0 : _balanceToken1() - receivedAmount1;

    // scope to prevent "stack too deep"
    {
      Position storage _position = getOrCreatePosition(recipient, bottomTick, topTick);
      if (bottomTick == topTick) {
        liquidityActual = receivedAmount0 > 0 ? uint128(receivedAmount0) : uint128(receivedAmount1);
        if (liquidityActual == 0) revert insufficientInputAmount();
        _updateLimitOrderPosition(_position, bottomTick, int128(liquidityActual));
      } else {
        if (receivedAmount0 < amount0) {
          liquidityActual = uint128(FullMath.mulDiv(uint256(liquidityDesired), receivedAmount0, amount0));
        } else {
          liquidityActual = liquidityDesired;
        }
        if (receivedAmount1 < amount1) {
          uint128 liquidityForRA1 = uint128(FullMath.mulDiv(uint256(liquidityDesired), receivedAmount1, amount1));
          if (liquidityForRA1 < liquidityActual) liquidityActual = liquidityForRA1;
        }
        if (liquidityActual == 0) revert zeroLiquidityActual();

        (amount0, amount1) = _updatePositionTicksAndFees(_position, bottomTick, topTick, int128(liquidityActual));
      }
    }

    unchecked {
      if (amount0 > 0) {
        if (receivedAmount0 > amount0) SafeTransfer.safeTransfer(token0, sender, receivedAmount0 - amount0);
        else if (receivedAmount0 != amount0) revert insufficientAmountReceivedAtMint();
      }

      if (amount1 > 0) {
        if (receivedAmount1 > amount1) SafeTransfer.safeTransfer(token1, sender, receivedAmount1 - amount1);
        else if (receivedAmount1 != amount1) revert insufficientAmountReceivedAtMint();
      }
    }

    _changeReserves(int256(amount0), int256(amount1), 0, 0);
    emit Mint(msg.sender, recipient, bottomTick, topTick, liquidityActual, amount0, amount1);
  }

  /// @inheritdoc IAlgebraPoolActions
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external override nonReentrant onlyValidTicks(bottomTick, topTick) returns (uint256 amount0, uint256 amount1) {
    if (amount > uint128(type(int128).max)) revert arithmeticError();
    _updateReserves();
    Position storage position = getOrCreatePosition(msg.sender, bottomTick, topTick);

    int128 liquidityDelta = -int128(amount);
    (amount0, amount1) = (bottomTick == topTick)
      ? _updateLimitOrderPosition(position, bottomTick, liquidityDelta)
      : _updatePositionTicksAndFees(position, bottomTick, topTick, liquidityDelta);

    if (amount0 | amount1 != 0) {
      (position.fees0, position.fees1) = (position.fees0 + uint128(amount0), position.fees1 + uint128(amount1));
    }

    if (amount | amount0 | amount1 != 0) emit Burn(msg.sender, bottomTick, topTick, amount, amount0, amount1);
  }

  /// @inheritdoc IAlgebraPoolActions
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external override nonReentrant returns (uint128 amount0, uint128 amount1) {
    // we don't check tick range validity, because if ticks are incorrect, the position will be empty
    Position storage position = getOrCreatePosition(msg.sender, bottomTick, topTick);
    (uint128 positionFees0, uint128 positionFees1) = (position.fees0, position.fees1);

    if (amount0Requested > positionFees0) amount0Requested = positionFees0;
    if (amount1Requested > positionFees1) amount1Requested = positionFees1;

    if (amount0Requested | amount1Requested != 0) {
      // use one if since fees0 and fees1 are tightly packed
      (amount0, amount1) = (amount0Requested, amount1Requested);

      unchecked {
        // single SSTORE
        (position.fees0, position.fees1) = (positionFees0 - amount0, positionFees1 - amount1);

        if (amount0 > 0) SafeTransfer.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) SafeTransfer.safeTransfer(token1, recipient, amount1);
        _changeReserves(-int256(uint256(amount0)), -int256(uint256(amount1)), 0, 0);
      }
      emit Collect(msg.sender, recipient, bottomTick, topTick, amount0, amount1);
    }
  }

  /// @inheritdoc IAlgebraPoolActions
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external override nonReentrant returns (int256 amount0, int256 amount1) {
    uint160 currentPrice;
    int24 currentTick;
    uint128 currentLiquidity;
    uint256 communityFee;
    (amount0, amount1, currentPrice, currentTick, currentLiquidity, communityFee) = _calculateSwap(zeroToOne, amountRequired, limitSqrtPrice);
    (uint256 balance0Before, uint256 balance1Before) = _updateReserves();
    if (zeroToOne) {
      unchecked {
        if (amount1 < 0) SafeTransfer.safeTransfer(token1, recipient, uint256(-amount1));
      }
      _swapCallback(amount0, amount1, data); // callback to get tokens from the caller
      if (balance0Before + uint256(amount0) > _balanceToken0()) revert insufficientInputAmount();
      _changeReserves(amount0, amount1, communityFee, 0); // reflect reserve change and pay communityFee
    } else {
      unchecked {
        if (amount0 < 0) SafeTransfer.safeTransfer(token0, recipient, uint256(-amount0));
      }
      _swapCallback(amount0, amount1, data); // callback to get tokens from the caller
      if (balance1Before + uint256(amount1) > _balanceToken1()) revert insufficientInputAmount();
      _changeReserves(amount0, amount1, 0, communityFee); // reflect reserve change and pay communityFee
    }

    emit Swap(msg.sender, recipient, amount0, amount1, currentPrice, currentLiquidity, currentTick);
  }

  /// @inheritdoc IAlgebraPoolActions
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external override nonReentrant returns (int256 amount0, int256 amount1) {
    if (amountRequired < 0) revert invalidAmountRequired(); // we support only exactInput here

    // Since the pool can get less tokens then sent, firstly we are getting tokens from the
    // original caller of the transaction. And change the _amountRequired_
    {
      // scope to prevent "stack too deep"
      (uint256 balance0Before, uint256 balance1Before) = _updateReserves();
      uint256 balanceBefore;
      uint256 balanceAfter;
      if (zeroToOne) {
        _swapCallback(amountRequired, 0, data);
        (balanceBefore, balanceAfter) = (balance0Before, _balanceToken0());
      } else {
        _swapCallback(0, amountRequired, data);
        (balanceBefore, balanceAfter) = (balance1Before, _balanceToken1());
      }

      int256 amountReceived = (balanceAfter - balanceBefore).toInt256();
      if (amountReceived < amountRequired) amountRequired = amountReceived;
    }
    if (amountRequired == 0) revert insufficientInputAmount();

    uint160 currentPrice;
    int24 currentTick;
    uint128 currentLiquidity;
    uint256 communityFee;
    (amount0, amount1, currentPrice, currentTick, currentLiquidity, communityFee) = _calculateSwap(zeroToOne, amountRequired, limitSqrtPrice);

    unchecked {
      // only transfer to the recipient
      if (zeroToOne) {
        if (amount1 < 0) SafeTransfer.safeTransfer(token1, recipient, uint256(-amount1));
        // return the leftovers
        if (amount0 < amountRequired) SafeTransfer.safeTransfer(token0, sender, uint256(amountRequired - amount0));
        _changeReserves(amount0, amount1, communityFee, 0); // reflect reserve change and pay communityFee
      } else {
        if (amount0 < 0) SafeTransfer.safeTransfer(token0, recipient, uint256(-amount0));
        // return the leftovers
        if (amount1 < amountRequired) SafeTransfer.safeTransfer(token1, sender, uint256(amountRequired - amount1));
        _changeReserves(amount0, amount1, 0, communityFee); // reflect reserve change and pay communityFee
      }
    }

    emit Swap(msg.sender, recipient, amount0, amount1, currentPrice, currentLiquidity, currentTick);
  }

  /// @inheritdoc IAlgebraPoolActions
  function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external override nonReentrant {
    (uint256 balance0Before, uint256 balance1Before) = _updateReserves();
    uint256 fee0;
    if (amount0 > 0) {
      fee0 = FullMath.mulDivRoundingUp(amount0, Constants.BASE_FEE, Constants.FEE_DENOMINATOR);
      SafeTransfer.safeTransfer(token0, recipient, amount0);
    }
    uint256 fee1;
    if (amount1 > 0) {
      fee1 = FullMath.mulDivRoundingUp(amount1, Constants.BASE_FEE, Constants.FEE_DENOMINATOR);
      SafeTransfer.safeTransfer(token1, recipient, amount1);
    }

    IAlgebraFlashCallback(msg.sender).algebraFlashCallback(fee0, fee1, data);

    uint256 paid0 = _balanceToken0();
    if (balance0Before + fee0 > paid0) revert flashInsufficientPaid0();
    uint256 paid1 = _balanceToken1();
    if (balance1Before + fee1 > paid1) revert flashInsufficientPaid1();

    unchecked {
      paid0 -= balance0Before;
      paid1 -= balance1Before;
    }
    uint256 _communityFee = globalState.communityFee;
    if (_communityFee > 0) {
      uint256 communityFee0;
      if (paid0 > 0) communityFee0 = FullMath.mulDiv(paid0, _communityFee, Constants.COMMUNITY_FEE_DENOMINATOR);
      uint256 communityFee1;
      if (paid1 > 0) communityFee1 = FullMath.mulDiv(paid1, _communityFee, Constants.COMMUNITY_FEE_DENOMINATOR);

      _changeReserves(int256(communityFee0), int256(communityFee1), communityFee0, communityFee1);
    }
    emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
  }

  /// @dev using function to save bytecode
  function _checkIfAdministrator() private view {
    if (!IAlgebraFactory(factory).hasRoleOrOwner(Constants.POOLS_ADMINISTRATOR_ROLE, msg.sender)) revert notAllowed();
  }

  /// @inheritdoc IAlgebraPoolPermissionedActions
  function setCommunityFee(uint8 newCommunityFee) external override nonReentrant {
    _checkIfAdministrator();
    if (newCommunityFee > Constants.MAX_COMMUNITY_FEE || newCommunityFee == globalState.communityFee) revert invalidNewCommunityFee();
    globalState.communityFee = newCommunityFee;
    emit CommunityFee(newCommunityFee);
  }

  /// @inheritdoc IAlgebraPoolPermissionedActions
  function setTickSpacing(int24 newTickSpacing, int24 newTickspacingLimitOrders) external override nonReentrant {
    _checkIfAdministrator();
    if (
      newTickSpacing <= 0 ||
      newTickSpacing > Constants.MAX_TICK_SPACING ||
      (tickSpacing == newTickSpacing && tickSpacingLimitOrders == newTickspacingLimitOrders)
    ) revert invalidNewTickSpacing();
    // newTickspacingLimitOrders isn't limited, so it is possible to forbid new limit orders completely
    if (newTickspacingLimitOrders <= 0 || tickSpacingLimitOrders == newTickspacingLimitOrders) revert invalidNewTickSpacing();
    tickSpacing = newTickSpacing;
    tickSpacingLimitOrders = newTickspacingLimitOrders;
    emit TickSpacing(newTickSpacing, newTickspacingLimitOrders);
  }

  /// @inheritdoc IAlgebraPoolPermissionedActions
  function setIncentive(address newIncentiveAddress) external override {
    if (msg.sender != IAlgebraFactory(factory).farmingAddress()) revert onlyFarming();
    activeIncentive = newIncentiveAddress;
    emit Incentive(newIncentiveAddress);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './interfaces/IAlgebraPoolDeployer.sol';
import './AlgebraPool.sol';

/// @title Algebra pool deployer
/// @notice Is used by AlgebraFactory to deploy pools
contract AlgebraPoolDeployer is IAlgebraPoolDeployer {
  /// @dev two storage slots for dense cache packing
  bytes32 private cache0;
  bytes32 private cache1;

  address private immutable factory;
  address private immutable communityVault;

  constructor(address _factory, address _communityVault) {
    require(_factory != address(0) && _communityVault != address(0));
    (factory, communityVault) = (_factory, _communityVault);
  }

  /// @inheritdoc IAlgebraPoolDeployer
  function getDeployParameters()
    external
    view
    override
    returns (address _dataStorage, address _factory, address _communityVault, address _token0, address _token1)
  {
    (_dataStorage, _token0, _token1) = _readFromCache();
    (_factory, _communityVault) = (factory, communityVault);
  }

  /// @inheritdoc IAlgebraPoolDeployer
  function deploy(address dataStorage, address token0, address token1) external override returns (address pool) {
    require(msg.sender == factory);

    _writeToCache(dataStorage, token0, token1);
    pool = address(new AlgebraPool{salt: keccak256(abi.encode(token0, token1))}());
    (cache0, cache1) = (bytes32(0), bytes32(0));
  }

  /// @notice densely packs three addresses into two storage slots
  function _writeToCache(address dataStorage, address token0, address token1) private {
    assembly {
      // cache0 = [dataStorage, token0[0, 96]], cache1 = [token0[0, 64], 0-s x32 , token1]
      token0 := and(token0, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) // clean higher bits, just in case
      sstore(cache0.slot, or(shr(64, token0), shl(96, and(dataStorage, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))))
      sstore(cache1.slot, or(shl(160, token0), and(token1, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))
    }
  }

  /// @notice reads three densely packed addresses from two storage slots
  function _readFromCache() private view returns (address dataStorage, address token0, address token1) {
    (bytes32 _cache0, bytes32 _cache1) = (cache0, cache1);
    assembly {
      dataStorage := shr(96, _cache0)
      token0 := or(shl(64, and(_cache0, 0xFFFFFFFFFFFFFFFFFFFFFFFF)), shr(160, _cache1))
      token1 := and(_cache1, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
  }
}

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

import '../interfaces/callback/IAlgebraSwapCallback.sol';
import '../interfaces/IAlgebraPool.sol';
import '../interfaces/IAlgebraPoolDeployer.sol';
import '../interfaces/IAlgebraPoolErrors.sol';
import '../interfaces/IDataStorageOperator.sol';
import '../interfaces/IERC20Minimal.sol';
import '../libraries/TickManagement.sol';
import '../libraries/LimitOrderManagement.sol';
import '../libraries/Constants.sol';
import './common/Timestamp.sol';

/// @title Algebra pool base abstract contract
/// @notice Contains state variables, immutables and common internal functions
abstract contract AlgebraPoolBase is IAlgebraPool, IAlgebraPoolErrors, Timestamp {
  using TickManagement for mapping(int24 => TickManagement.Tick);

  struct GlobalState {
    uint160 price; // The square root of the current price in Q64.96 format
    int24 tick; // The current tick
    uint16 feeZtO; // The current fee for ZtO swap in hundredths of a bip, i.e. 1e-6
    uint16 feeOtZ; // The current fee for OtZ swap in hundredths of a bip, i.e. 1e-6
    uint16 timepointIndex; // The index of the last written timepoint
    uint8 communityFee; // The community fee represented as a percent of all collected fee in thousandths (1e-3)
    bool unlocked; // True if the contract is unlocked, otherwise - false
  }

  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override dataStorageOperator;
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override factory;
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override token0;
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override token1;
  /// @inheritdoc IAlgebraPoolImmutables
  address public immutable override communityVault;

  /// @inheritdoc IAlgebraPoolState
  uint256 public override totalFeeGrowth0Token;
  /// @inheritdoc IAlgebraPoolState
  uint256 public override totalFeeGrowth1Token;
  /// @inheritdoc IAlgebraPoolState
  GlobalState public override globalState;

  /// @inheritdoc IAlgebraPoolState
  uint128 public override liquidity;
  /// @inheritdoc IAlgebraPoolState
  int24 public override tickSpacing;
  /// @inheritdoc IAlgebraPoolState
  int24 public override tickSpacingLimitOrders;
  /// @inheritdoc IAlgebraPoolState
  uint32 public override communityFeeLastTimestamp;
  /// @inheritdoc IAlgebraPoolState
  int24 public prevInitializedTick;

  /// @dev The amounts of token0 and token1 that will be sent to the vault
  uint128 internal communityFeePending0;
  uint128 internal communityFeePending1;

  /// @dev The timestamp of the last timepoint write to the DataStorage
  uint32 internal lastTimepointTimestamp;
  /// @inheritdoc IAlgebraPoolState
  uint160 public override secondsPerLiquidityCumulative;

  /// @inheritdoc IAlgebraPoolState
  address public override activeIncentive;

  /// @inheritdoc IAlgebraPoolState
  mapping(int24 => TickManagement.Tick) public override ticks;
  /// @inheritdoc IAlgebraPoolState
  mapping(int24 => LimitOrderManagement.LimitOrder) public override limitOrders;

  /// @inheritdoc IAlgebraPoolState
  mapping(int16 => uint256) public override tickTable;

  /// @inheritdoc IAlgebraPoolImmutables
  function maxLiquidityPerTick() external pure override returns (uint128) {
    return Constants.MAX_LIQUIDITY_PER_TICK;
  }

  /// @inheritdoc IAlgebraPoolState
  function getCommunityFeePending() external view returns (uint128, uint128) {
    return (communityFeePending0, communityFeePending1);
  }

  modifier onlyValidTicks(int24 bottomTick, int24 topTick) {
    TickManagement.checkTickRangeValidity(bottomTick, topTick);
    _;
  }

  constructor() {
    (dataStorageOperator, factory, communityVault, token0, token1) = IAlgebraPoolDeployer(msg.sender).getDeployParameters();
    globalState.feeZtO = Constants.BASE_FEE;
    globalState.feeOtZ = Constants.BASE_FEE;
    prevInitializedTick = TickMath.MIN_TICK;
    tickSpacing = Constants.INIT_TICK_SPACING;
    tickSpacingLimitOrders = type(int24).max; // disabled by default
  }

  function _balanceToken0() internal view returns (uint256) {
    return IERC20Minimal(token0).balanceOf(address(this));
  }

  function _balanceToken1() internal view returns (uint256) {
    return IERC20Minimal(token1).balanceOf(address(this));
  }

  /// @dev Using function to save bytecode
  function _swapCallback(int256 amount0, int256 amount1, bytes calldata data) internal {
    IAlgebraSwapCallback(msg.sender).algebraSwapCallback(amount0, amount1, data);
  }

  /// @dev Once per block, writes data to dataStorage and updates the accumulator `secondsPerLiquidityCumulative`
  function _writeTimepoint(
    uint16 timepointIndex,
    uint32 blockTimestamp,
    int24 tick,
    uint128 currentLiquidity
  ) internal returns (uint16 newTimepointIndex, uint16 newFeeZtO, uint16 newFeeOtZ) {
    uint32 _lastTs = lastTimepointTimestamp;
    if (_lastTs == blockTimestamp) return (timepointIndex, 0, 0); // writing should only happen once per block

    unchecked {
      // just timedelta if liquidity == 0
      // overflow and underflow are desired
      secondsPerLiquidityCumulative += (uint160(blockTimestamp - _lastTs) << 128) / (currentLiquidity > 0 ? currentLiquidity : 1);
    }
    lastTimepointTimestamp = blockTimestamp;

    // failure should not occur. But in case of failure, the pool will remain operational
    try IDataStorageOperator(dataStorageOperator).write(timepointIndex, blockTimestamp, tick) returns (
      uint16 _newTimepointIndex,
      uint16 _newFeeZtO,
      uint16 _newFeeOtZ
    ) {
      return (_newTimepointIndex, _newFeeZtO, _newFeeOtZ);
    } catch {
      emit DataStorageFailure();
      return (timepointIndex, 0, 0);
    }
  }

  /// @dev Get secondsPerLiquidityCumulative accumulator value for current blockTimestamp
  function _getSecondsPerLiquidityCumulative(uint32 blockTimestamp, uint128 currentLiquidity) internal view returns (uint160 _secPerLiqCumulative) {
    uint32 _lastTs;
    (_lastTs, _secPerLiqCumulative) = (lastTimepointTimestamp, secondsPerLiquidityCumulative);
    unchecked {
      if (_lastTs != blockTimestamp)
        // just timedelta if liquidity == 0
        // overflow and underflow are desired
        _secPerLiqCumulative += (uint160(blockTimestamp - _lastTs) << 128) / (currentLiquidity > 0 ? currentLiquidity : 1);
    }
  }

  /// @dev Add or remove a tick to the corresponding data structure
  function _insertOrRemoveTick(
    int24 tick,
    int24 currentTick,
    int24 prevInitializedTick,
    bool remove
  ) internal virtual returns (int24 newPrevInitializedTick);
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

import './AlgebraPoolBase.sol';

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the blockchain
abstract contract DerivedState is AlgebraPoolBase {
  /// @inheritdoc IAlgebraPoolDerivedState
  function getInnerCumulatives(
    int24 bottomTick,
    int24 topTick
  ) external view override onlyValidTicks(bottomTick, topTick) returns (uint160 innerSecondsSpentPerLiquidity, uint32 innerSecondsSpent) {
    TickManagement.Tick storage _bottomTick = ticks[bottomTick];
    TickManagement.Tick storage _topTick = ticks[topTick];

    if (_bottomTick.nextTick == _bottomTick.prevTick || _topTick.nextTick == _topTick.prevTick) revert tickIsNotInitialized();
    (uint160 lowerOuterSecondPerLiquidity, uint32 lowerOuterSecondsSpent) = (_bottomTick.outerSecondsPerLiquidity, _bottomTick.outerSecondsSpent);
    (uint160 upperOuterSecondPerLiquidity, uint32 upperOuterSecondsSpent) = (_topTick.outerSecondsPerLiquidity, _topTick.outerSecondsSpent);

    int24 currentTick = globalState.tick;
    unchecked {
      if (currentTick < bottomTick) {
        return (lowerOuterSecondPerLiquidity - upperOuterSecondPerLiquidity, lowerOuterSecondsSpent - upperOuterSecondsSpent);
      }

      if (currentTick < topTick) {
        uint32 time = _blockTimestamp();
        return (
          _getSecondsPerLiquidityCumulative(time, liquidity) - lowerOuterSecondPerLiquidity - upperOuterSecondPerLiquidity,
          time - lowerOuterSecondsSpent - upperOuterSecondsSpent
        );
      } else return (upperOuterSecondPerLiquidity - lowerOuterSecondPerLiquidity, upperOuterSecondsSpent - lowerOuterSecondsSpent);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../libraries/LimitOrderManagement.sol';
import '../libraries/LowGasSafeMath.sol';
import '../libraries/TickMath.sol';
import '../libraries/SafeCast.sol';
import './Positions.sol';

/// @title Algebra limit order positions abstract contract
/// @notice Contains the logic of recalculation and change of limit order positions
/// @dev For limit orders positions, the same structure is used as for liquidity positions. However, it is interpreted differently
abstract contract LimitOrderPositions is Positions {
  using LimitOrderManagement for mapping(int24 => LimitOrderManagement.LimitOrder);
  using LowGasSafeMath for uint128;
  using SafeCast for int256;
  using SafeCast for uint256;

  /**
   * @dev Updates limit order position inner data and applies `amountToSellDelta`
   * @param position The position object to operate with
   * @param tick The tick which price corresponds to the limit order
   * @param amountToSellDelta The amount of token to be added to the sale or subtracted (in case of cancellation)
   * @return amount0 The abs amount of token0 that corresponds to amountToSellDelta
   * @return amount1 The abs amount of token1 that corresponds to amountToSellDelta
   */
  function _updateLimitOrderPosition(
    Position storage position,
    int24 tick,
    int128 amountToSellDelta
  ) internal returns (uint256 amount0, uint256 amount1) {
    _recalculateLimitOrderPosition(position, tick, amountToSellDelta);

    if (amountToSellDelta != 0) {
      bool remove = amountToSellDelta < 0;
      (int24 currentTick, int24 prevTick) = (globalState.tick, prevInitializedTick);

      if (limitOrders.addOrRemoveLimitOrder(tick, amountToSellDelta)) {
        // if tick flipped
        TickManagement.Tick storage _tickData = ticks[tick];
        _tickData.hasLimitOrders = !remove;
        if (_tickData.nextTick == _tickData.prevTick) {
          // tick isn't initialized
          int24 newPrevTick = _insertOrRemoveTick(tick, currentTick, prevTick, remove);
          if (newPrevTick != prevTick) prevInitializedTick = newPrevTick;
        }
      }

      if (remove) {
        unchecked {
          return (tick > currentTick) ? (uint256(int256(-amountToSellDelta)), uint256(0)) : (uint256(0), uint256(int256(-amountToSellDelta)));
        }
      }
    }
  }

  /**
   * @dev Recalculates how many of the desired amount of tokens have been sold
   * @param position The position object to operate with
   * @param tick The tick which price corresponds to the limit order
   * @param amountToSellDelta The amount of token to be added to the sale or subtracted (in case of cancellation)
   */
  function _recalculateLimitOrderPosition(Position storage position, int24 tick, int128 amountToSellDelta) private {
    uint256 amountToSell;
    uint256 amountToSellInitial;
    unchecked {
      (amountToSell, amountToSellInitial) = (position.liquidity >> 128, uint128(position.liquidity)); // unpack data
    }
    if (amountToSell == 0 && amountToSellDelta == 0) return;

    LimitOrderManagement.LimitOrder storage _limitOrder = limitOrders[tick];
    unchecked {
      uint256 _cumulativeDelta;
      bool zeroToOne;
      {
        uint256 _bought1Cumulative;
        if (!_limitOrder.initialized) {
          // maker pays for storage slots
          (_limitOrder.boughtAmount0Cumulative, _limitOrder.boughtAmount1Cumulative, _limitOrder.initialized) = (1, 1, true);
          _bought1Cumulative = 1;
        } else {
          _bought1Cumulative = _limitOrder.boughtAmount1Cumulative;
        }
        if (amountToSell == 0) {
          // initial value isn't zero, but accumulators can overflow
          if (position.innerFeeGrowth0Token == 0) position.innerFeeGrowth0Token = _limitOrder.boughtAmount0Cumulative;
          if (position.innerFeeGrowth1Token == 0) position.innerFeeGrowth1Token = _limitOrder.boughtAmount1Cumulative;
        }
        _cumulativeDelta = _bought1Cumulative - position.innerFeeGrowth1Token;
        zeroToOne = _cumulativeDelta > 0;
        if (!zeroToOne) _cumulativeDelta = _limitOrder.boughtAmount0Cumulative - position.innerFeeGrowth0Token;
      }

      if (_cumulativeDelta > 0) {
        uint256 boughtAmount;
        if (amountToSellInitial > 0) {
          boughtAmount = FullMath.mulDiv(_cumulativeDelta, amountToSellInitial, Constants.Q128);
          uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(tick);
          uint256 price = FullMath.mulDiv(sqrtPrice, sqrtPrice, Constants.Q96);
          (uint256 nominator, uint256 denominator) = zeroToOne ? (price, Constants.Q96) : (Constants.Q96, price);
          uint256 amountToBuy = FullMath.mulDiv(amountToSell, nominator, denominator);

          if (boughtAmount < amountToBuy) {
            amountToSell = FullMath.mulDiv(amountToBuy - boughtAmount, denominator, nominator); // unspent input
          } else {
            boughtAmount = amountToBuy;
            amountToSell = 0;
          }
        }
        // casts aren't checked since boughtAmount must be <= type(uint128).max (we are not supporting tokens with totalSupply > type(uint128).max)
        if (zeroToOne) {
          position.innerFeeGrowth1Token = position.innerFeeGrowth1Token + _cumulativeDelta;
          if (boughtAmount > 0) position.fees1 = position.fees1.add128(uint128(boughtAmount));
        } else {
          position.innerFeeGrowth0Token = position.innerFeeGrowth0Token + _cumulativeDelta;
          if (boughtAmount > 0) position.fees0 = position.fees0.add128(uint128(boughtAmount));
        }
      }
      if (amountToSell == 0) amountToSellInitial = 0; // reset if all amount sold

      if (amountToSellDelta != 0) {
        int128 amountToSellInitialDelta = amountToSellDelta;
        // add/remove liquidity to tick with partly executed limit order
        if (amountToSell != amountToSellInitial && amountToSell != 0) {
          // in case of overflow it will be not possible to add tokens for sell until the limit order is fully closed
          amountToSellInitialDelta = amountToSellDelta < 0
            ? (-FullMath.mulDiv(uint128(-amountToSellDelta), amountToSellInitial, amountToSell).toInt256()).toInt128()
            : FullMath.mulDiv(uint128(amountToSellDelta), amountToSellInitial, amountToSell).toInt256().toInt128();

          limitOrders.addVirtualLiquidity(tick, amountToSellInitialDelta - amountToSellDelta);
        }
        amountToSell = LiquidityMath.addDelta(uint128(amountToSell), amountToSellDelta);
        amountToSellInitial = LiquidityMath.addDelta(uint128(amountToSellInitial), amountToSellInitialDelta);
      }
      if (amountToSell == 0) amountToSellInitial = 0; // reset if all amount cancelled

      require(amountToSell <= type(uint128).max && amountToSellInitial <= type(uint128).max); // should never fail, just in case
      (position.liquidity) = ((amountToSell << 128) | amountToSellInitial); // tightly pack data
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './AlgebraPoolBase.sol';
import '../libraries/LiquidityMath.sol';
import '../libraries/TickManagement.sol';

/// @title Algebra positions abstract contract
/// @notice Contains the logic of recalculation and change of liquidity positions
abstract contract Positions is AlgebraPoolBase {
  using TickManagement for mapping(int24 => TickManagement.Tick);

  struct Position {
    uint256 liquidity; // The amount of liquidity concentrated in the range
    uint256 innerFeeGrowth0Token; // The last updated fee growth per unit of liquidity
    uint256 innerFeeGrowth1Token;
    uint128 fees0; // The amount of token0 owed to a LP
    uint128 fees1; // The amount of token1 owed to a LP
  }

  /// @inheritdoc IAlgebraPoolState
  mapping(bytes32 => Position) public override positions;

  /**
   * @notice This function fetches certain position object
   * @param owner The address owing the position
   * @param bottomTick The position's bottom tick
   * @param topTick The position's top tick
   * @return position The Position object
   */
  function getOrCreatePosition(address owner, int24 bottomTick, int24 topTick) internal view returns (Position storage) {
    bytes32 key;
    assembly {
      key := or(shl(24, or(shl(24, owner), and(bottomTick, 0xFFFFFF))), and(topTick, 0xFFFFFF))
    }
    return positions[key];
  }

  struct UpdatePositionCache {
    uint160 price; // The square root of the current price in Q64.96 format
    int24 prevInitializedTick; // The previous initialized tick in linked list
    uint16 feeZtO; // The current fee for ZtO swaps in hundredths of a bip, i.e. 1e-6
    uint16 feeOtZ; // The current fee for OtZ swaps in hundredths of a bip, i.e. 1e-6
    uint16 timepointIndex; // The index of the last written timepoint
  }

  /**
   * @dev Updates position's ticks and its fees
   * @return amount0 The abs amount of token0 that corresponds to liquidityDelta
   * @return amount1 The abs amount of token1 that corresponds to liquidityDelta
   */
  function _updatePositionTicksAndFees(
    Position storage position,
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta
  ) internal returns (uint256 amount0, uint256 amount1) {
    // using memory cache to avoid "stack too deep" error
    UpdatePositionCache memory cache = UpdatePositionCache(
      globalState.price,
      prevInitializedTick,
      globalState.feeZtO,
      globalState.feeOtZ,
      globalState.timepointIndex
    );

    int24 currentTick = globalState.tick;

    bool toggledBottom;
    bool toggledTop;
    {
      // scope to prevent "stack too deep"
      (uint256 _totalFeeGrowth0Token, uint256 _totalFeeGrowth1Token) = (totalFeeGrowth0Token, totalFeeGrowth1Token);
      if (liquidityDelta != 0) {
        uint32 time = _blockTimestamp();
        uint160 _secondsPerLiquidityCumulative = _getSecondsPerLiquidityCumulative(time, liquidity);

        toggledBottom = ticks.update(
          bottomTick,
          currentTick,
          liquidityDelta,
          _totalFeeGrowth0Token,
          _totalFeeGrowth1Token,
          _secondsPerLiquidityCumulative,
          time,
          false // isTopTick: false
        );

        toggledTop = ticks.update(
          topTick,
          currentTick,
          liquidityDelta,
          _totalFeeGrowth0Token,
          _totalFeeGrowth1Token,
          _secondsPerLiquidityCumulative,
          time,
          true // isTopTick: true
        );
      }

      (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) = ticks.getInnerFeeGrowth(
        bottomTick,
        topTick,
        currentTick,
        _totalFeeGrowth0Token,
        _totalFeeGrowth1Token
      );

      _recalculatePosition(position, liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);
    }

    if (liquidityDelta != 0) {
      // if liquidityDelta is negative and the tick was toggled, it means that it should not be initialized anymore, so we delete it
      if (toggledBottom || toggledTop) {
        int24 previousTick = cache.prevInitializedTick;
        if (toggledBottom) {
          previousTick = _insertOrRemoveTick(bottomTick, currentTick, previousTick, liquidityDelta < 0);
        }
        if (toggledTop) {
          previousTick = _insertOrRemoveTick(topTick, currentTick, previousTick, liquidityDelta < 0);
        }
        cache.prevInitializedTick = previousTick;
      }

      int128 globalLiquidityDelta;
      (amount0, amount1, globalLiquidityDelta) = LiquidityMath.getAmountsForLiquidity(bottomTick, topTick, liquidityDelta, currentTick, cache.price);
      if (globalLiquidityDelta != 0) {
        uint128 liquidityBefore = liquidity;
        (uint16 newTimepointIndex, uint16 newFeeZtO, uint16 newFeeOtZ) = _writeTimepoint(
          cache.timepointIndex,
          _blockTimestamp(),
          currentTick,
          liquidityBefore
        );
        if (cache.timepointIndex != newTimepointIndex) {
          cache.timepointIndex = newTimepointIndex;
          if (cache.feeZtO != newFeeZtO || cache.feeOtZ != newFeeOtZ) {
            cache.feeZtO = newFeeZtO;
            cache.feeOtZ = newFeeOtZ;
            emit Fee(newFeeZtO, newFeeOtZ);
          }
        }
        liquidity = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);
      }
      prevInitializedTick = cache.prevInitializedTick;
      (globalState.feeZtO, globalState.feeOtZ, globalState.timepointIndex) = (cache.feeZtO, cache.feeOtZ, cache.timepointIndex);
    }
  }

  /**
   * @notice Increases amounts of tokens owed to owner of the position
   * @param position The position object to operate with
   * @param liquidityDelta The amount on which to increase\decrease the liquidity
   * @param innerFeeGrowth0Token Total fee token0 fee growth per 1/liquidity between position's lower and upper ticks
   * @param innerFeeGrowth1Token Total fee token1 fee growth per 1/liquidity between position's lower and upper ticks
   */
  function _recalculatePosition(
    Position storage position,
    int128 liquidityDelta,
    uint256 innerFeeGrowth0Token,
    uint256 innerFeeGrowth1Token
  ) internal {
    uint128 liquidityBefore = uint128(position.liquidity);

    if (liquidityDelta == 0) {
      if (liquidityBefore == 0) return; // Do not recalculate the empty ranges
    } else {
      // change position liquidity
      position.liquidity = LiquidityMath.addDelta(liquidityBefore, liquidityDelta);
    }

    unchecked {
      // update the position
      uint256 _innerFeeGrowth0Token;
      uint128 fees0;
      if ((_innerFeeGrowth0Token = position.innerFeeGrowth0Token) != innerFeeGrowth0Token) {
        position.innerFeeGrowth0Token = innerFeeGrowth0Token;
        fees0 = uint128(FullMath.mulDiv(innerFeeGrowth0Token - _innerFeeGrowth0Token, liquidityBefore, Constants.Q128));
      }
      uint256 _innerFeeGrowth1Token;
      uint128 fees1;
      if ((_innerFeeGrowth1Token = position.innerFeeGrowth1Token) != innerFeeGrowth1Token) {
        position.innerFeeGrowth1Token = innerFeeGrowth1Token;
        fees1 = uint128(FullMath.mulDiv(innerFeeGrowth1Token - _innerFeeGrowth1Token, liquidityBefore, Constants.Q128));
      }

      // To avoid overflow owner has to collect fee before it
      if (fees0 | fees1 != 0) {
        position.fees0 += fees0;
        position.fees1 += fees1;
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './AlgebraPoolBase.sol';

/// @title Algebra reentrancy protection
/// @notice Provides a modifier that protects against reentrancy
abstract contract ReentrancyGuard is AlgebraPoolBase {
  modifier nonReentrant() {
    _lock();
    _;
    _unlock();
  }

  /// @dev using private function to save bytecode
  function _lock() private {
    if (!globalState.unlocked) revert IAlgebraPoolErrors.locked();
    globalState.unlocked = false;
  }

  /// @dev using private function to save bytecode
  function _unlock() private {
    globalState.unlocked = true;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../libraries/SafeTransfer.sol';
import '../libraries/SafeCast.sol';
import './AlgebraPoolBase.sol';

/// @title Algebra reserves management abstract contract
/// @notice Encapsulates logic for tracking and changing pool reserves
abstract contract ReservesManager is AlgebraPoolBase {
  using SafeCast for uint256;

  /// @dev The tracked token0 and token1 reserves of pool
  uint128 private reserve0;
  uint128 private reserve1;

  /// @inheritdoc IAlgebraPoolState
  function getReserves() external view returns (uint128, uint128) {
    return (reserve0, reserve1);
  }

  /// @dev updates reserves data and distributes excess in the form of fee to liquidity providers.
  /// If any of the balances is greater than uint128, the excess is sent to the communityVault
  function _updateReserves() internal returns (uint256 balance0, uint256 balance1) {
    (balance0, balance1) = (_balanceToken0(), _balanceToken1());
    // we do not support tokens with totalSupply > type(uint128).max, so any excess will be sent to communityVault
    // this situation can only occur if the tokens are sent directly to the pool from outside
    unchecked {
      if (balance0 > type(uint128).max) {
        SafeTransfer.safeTransfer(token0, communityVault, balance0 - type(uint128).max);
        balance0 = type(uint128).max;
      }
      if (balance1 > type(uint128).max) {
        SafeTransfer.safeTransfer(token1, communityVault, balance1 - type(uint128).max);
        balance1 = type(uint128).max;
      }
    }

    uint128 _liquidity = liquidity;
    if (_liquidity == 0) return (balance0, balance1);

    (uint128 _reserve0, uint128 _reserve1) = (reserve0, reserve1);
    (bool hasExcessToken0, bool hasExcessToken1) = (balance0 > _reserve0, balance1 > _reserve1);
    if (hasExcessToken0 || hasExcessToken1) {
      unchecked {
        if (hasExcessToken0) totalFeeGrowth0Token += FullMath.mulDiv(balance0 - _reserve0, Constants.Q128, _liquidity);
        if (hasExcessToken1) totalFeeGrowth1Token += FullMath.mulDiv(balance1 - _reserve1, Constants.Q128, _liquidity);
        (reserve0, reserve1) = (uint128(balance0), uint128(balance1));
      }
    }
  }

  /**
   * @notice Applies deltas to reserves and pays communityFees
   * @param deltaR0 Amount of token0 to add/subtract to/from reserve0, must not exceed uint128
   * @param deltaR1 Amount of token1 to add/subtract to/from reserve1, must not exceed uint128
   * @param communityFee0 Amount of token0 to pay as communityFee, must not exceed uint128
   * @param communityFee1 Amount of token1 to pay as communityFee, must not exceed uint128
   */
  function _changeReserves(int256 deltaR0, int256 deltaR1, uint256 communityFee0, uint256 communityFee1) internal {
    if (communityFee0 | communityFee1 != 0) {
      unchecked {
        // overflow is desired since we do not support tokens with totalSupply > type(uint128).max
        uint256 _cfPending0 = uint256(communityFeePending0) + communityFee0;
        uint256 _cfPending1 = uint256(communityFeePending1) + communityFee1;
        uint32 currentTimestamp = _blockTimestamp();
        // underflow in timestamps is desired
        if (
          currentTimestamp - communityFeeLastTimestamp >= Constants.COMMUNITY_FEE_TRANSFER_FREQUENCY ||
          _cfPending0 > type(uint128).max ||
          _cfPending1 > type(uint128).max
        ) {
          if (_cfPending0 > 0) SafeTransfer.safeTransfer(token0, communityVault, _cfPending0);
          if (_cfPending1 > 0) SafeTransfer.safeTransfer(token1, communityVault, _cfPending1);
          communityFeeLastTimestamp = currentTimestamp;
          (deltaR0, deltaR1) = (deltaR0 - _cfPending0.toInt256(), deltaR1 - _cfPending1.toInt256());
          (_cfPending0, _cfPending1) = (0, 0);
        }
        // the previous block guarantees that no overflow occurs
        (communityFeePending0, communityFeePending1) = (uint128(_cfPending0), uint128(_cfPending1));
      }
    }

    if (deltaR0 | deltaR1 == 0) return;
    (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
    if (deltaR0 != 0) _reserve0 = (uint256(int256(_reserve0) + deltaR0)).toUint128();
    if (deltaR1 != 0) _reserve1 = (uint256(int256(_reserve1) + deltaR1)).toUint128();
    (reserve0, reserve1) = (uint128(_reserve0), uint128(_reserve1));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../interfaces/IAlgebraVirtualPool.sol';
import '../libraries/PriceMovementMath.sol';
import '../libraries/LimitOrderManagement.sol';
import '../libraries/LowGasSafeMath.sol';
import '../libraries/SafeCast.sol';
import './AlgebraPoolBase.sol';

/// @title Algebra swap calculation abstract contract
/// @notice Contains _calculateSwap encapsulating internal logic of swaps
abstract contract SwapCalculation is AlgebraPoolBase {
  using TickManagement for mapping(int24 => TickManagement.Tick);
  using LimitOrderManagement for mapping(int24 => LimitOrderManagement.LimitOrder);
  using SafeCast for uint256;
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for int256;

  struct SwapCalculationCache {
    uint256 communityFee; // The community fee of the selling token, uint256 to minimize casts
    uint160 secondsPerLiquidityCumulative; // The global secondPerLiquidity at the moment
    bool crossedAnyTick; //  If we have already crossed at least one active tick
    int256 amountRequiredInitial; // The initial value of the exact input\output amount
    int256 amountCalculated; // The additive amount of total output\input calculated through the swap
    uint256 totalFeeGrowth; // The initial totalFeeGrowth + the fee growth during a swap
    uint256 totalFeeGrowthB;
    bool exactInput; // Whether the exact input or output is specified
    uint16 fee; // The current dynamic fee
    uint16 timepointIndex; // The index of last written timepoint
    int24 prevInitializedTick; // The previous initialized tick in linked list
    uint32 blockTimestamp; // The timestamp of current block
  }

  struct PriceMovementCache {
    uint160 stepSqrtPrice; // The Q64.96 sqrt of the price at the start of the step
    int24 nextTick; // The tick till the current step goes
    bool initialized; // True if the _nextTick_ is initialized
    uint160 nextTickPrice; // The Q64.96 sqrt of the price calculated from the _nextTick_
    uint256 input; // The additive amount of tokens that have been provided
    uint256 output; // The additive amount of token that have been withdrawn
    uint256 feeAmount; // The total amount of fee earned within a current step
    bool inLimitOrder; // If a limit order is currently being executed
  }

  function _calculateSwap(
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice
  ) internal returns (int256 amount0, int256 amount1, uint160 currentPrice, int24 currentTick, uint128 currentLiquidity, uint256 communityFeeAmount) {
    if (amountRequired == 0) revert zeroAmountRequired();
    if (amountRequired == type(int256).min) revert invalidAmountRequired(); // to avoid problems when changing sign
    SwapCalculationCache memory cache;
    {
      // load from one storage slot
      currentPrice = globalState.price;
      currentTick = globalState.tick;
      cache.fee = zeroToOne ? globalState.feeZtO : globalState.feeOtZ;
      cache.timepointIndex = globalState.timepointIndex;
      cache.communityFee = globalState.communityFee;
      cache.prevInitializedTick = prevInitializedTick;

      (cache.amountRequiredInitial, cache.exactInput) = (amountRequired, amountRequired > 0);

      currentLiquidity = liquidity;

      if (zeroToOne) {
        if (limitSqrtPrice >= currentPrice || limitSqrtPrice <= TickMath.MIN_SQRT_RATIO) revert invalidLimitSqrtPrice();
        cache.totalFeeGrowth = totalFeeGrowth0Token;
      } else {
        if (limitSqrtPrice <= currentPrice || limitSqrtPrice >= TickMath.MAX_SQRT_RATIO) revert invalidLimitSqrtPrice();
        cache.totalFeeGrowth = totalFeeGrowth1Token;
      }

      cache.blockTimestamp = _blockTimestamp();

      (uint16 newTimepointIndex, uint16 newFeeZtO, uint16 newFeeOtZ) = _writeTimepoint(
        cache.timepointIndex,
        cache.blockTimestamp,
        currentTick,
        currentLiquidity
      );

      // new timepoint appears only for first swap/mint/burn in block
      if (newTimepointIndex != cache.timepointIndex) {
        cache.timepointIndex = newTimepointIndex;
        if (globalState.feeZtO != newFeeZtO || globalState.feeOtZ != newFeeOtZ) {
          globalState.feeZtO = newFeeZtO;
          globalState.feeOtZ = newFeeOtZ;
          cache.fee = zeroToOne ? newFeeZtO : newFeeOtZ;
          emit Fee(newFeeZtO, newFeeOtZ);
        }
      }
    }

    PriceMovementCache memory step;
    step.nextTick = zeroToOne ? cache.prevInitializedTick : ticks[cache.prevInitializedTick].nextTick;
    unchecked {
      // swap until there is remaining input or output tokens or we reach the price limit
      while (true) {
        step.stepSqrtPrice = currentPrice;
        step.initialized = true;
        step.nextTickPrice = TickMath.getSqrtRatioAtTick(step.nextTick);

        if (step.stepSqrtPrice == step.nextTickPrice && ticks[step.nextTick].hasLimitOrders) {
          step.inLimitOrder = true;
          bool isLimitOrderExecuted = false;
          // calculate the amounts from LO
          (isLimitOrderExecuted, step.output, step.input, step.feeAmount) = limitOrders.executeLimitOrders(
            step.nextTick,
            currentPrice,
            zeroToOne,
            amountRequired,
            cache.fee / 2
          );
          if (isLimitOrderExecuted) {
            if (ticks[step.nextTick].liquidityTotal == 0) {
              cache.prevInitializedTick = _insertOrRemoveTick(step.nextTick, currentTick, cache.prevInitializedTick, true);
              step.initialized = false;
            } else {
              ticks[step.nextTick].hasLimitOrders = false;
            }
            step.inLimitOrder = false;
          }
        } else {
          (currentPrice, step.input, step.output, step.feeAmount) = PriceMovementMath.movePriceTowardsTarget(
            zeroToOne,
            currentPrice,
            (zeroToOne == (step.nextTickPrice < limitSqrtPrice)) // move the price to the target or to the limit
              ? limitSqrtPrice
              : step.nextTickPrice,
            currentLiquidity,
            amountRequired,
            cache.fee
          );
        }

        if (cache.exactInput) {
          amountRequired -= (step.input + step.feeAmount).toInt256(); // decrease remaining input amount
          cache.amountCalculated = cache.amountCalculated.sub(step.output.toInt256()); // decrease calculated output amount
        } else {
          amountRequired += step.output.toInt256(); // increase remaining output amount (since its negative)
          cache.amountCalculated = cache.amountCalculated.add((step.input + step.feeAmount).toInt256()); // increase calculated input amount
        }

        if (cache.communityFee > 0) {
          uint256 delta = (step.feeAmount.mul(cache.communityFee)) / Constants.COMMUNITY_FEE_DENOMINATOR;
          step.feeAmount -= delta;
          communityFeeAmount += delta;
        }

        if (currentLiquidity > 0) cache.totalFeeGrowth += FullMath.mulDiv(step.feeAmount, Constants.Q128, currentLiquidity);

        if (currentPrice == step.nextTickPrice && !step.inLimitOrder) {
          // if the reached tick is initialized then we need to cross it
          if (step.initialized) {
            // we have opened LOs
            if (ticks[step.nextTick].hasLimitOrders) {
              currentTick = zeroToOne ? step.nextTick : step.nextTick - 1;
              continue;
            }

            if (!cache.crossedAnyTick) {
              cache.crossedAnyTick = true;
              cache.secondsPerLiquidityCumulative = secondsPerLiquidityCumulative;
              cache.totalFeeGrowthB = zeroToOne ? totalFeeGrowth1Token : totalFeeGrowth0Token;
            }

            int128 liquidityDelta;
            if (zeroToOne) {
              liquidityDelta = -ticks.cross(
                step.nextTick,
                cache.totalFeeGrowth, // A == 0
                cache.totalFeeGrowthB, // B == 1
                cache.secondsPerLiquidityCumulative,
                cache.blockTimestamp
              );
              cache.prevInitializedTick = ticks[cache.prevInitializedTick].prevTick;
            } else {
              liquidityDelta = ticks.cross(
                step.nextTick,
                cache.totalFeeGrowthB, // B == 0
                cache.totalFeeGrowth, // A == 1
                cache.secondsPerLiquidityCumulative,
                cache.blockTimestamp
              );
              cache.prevInitializedTick = step.nextTick;
            }
            currentLiquidity = LiquidityMath.addDelta(currentLiquidity, liquidityDelta);
          }

          (currentTick, step.nextTick) = zeroToOne
            ? (step.nextTick - 1, cache.prevInitializedTick)
            : (step.nextTick, ticks[cache.prevInitializedTick].nextTick);
        } else if (currentPrice != step.stepSqrtPrice) {
          // if the price has changed but hasn't reached the target
          currentTick = TickMath.getTickAtSqrtRatio(currentPrice);
          break; // since the price hasn't reached the target, amountRequired should be 0
        }
        // check stop condition
        if (amountRequired == 0 || currentPrice == limitSqrtPrice) {
          break;
        }
      }

      if (cache.crossedAnyTick) {
        // ticks cross data is needed to be duplicated in a virtual pool
        address _activeIncentive = activeIncentive;
        if (_activeIncentive != address(0)) {
          bool isIncentiveActive; // if the incentive is stopped or faulty, the active incentive will be reset to 0
          try IAlgebraVirtualPool(_activeIncentive).crossTo(currentTick, zeroToOne) returns (bool success) {
            isIncentiveActive = success;
          } catch {
            // pool will reset activeIncentive in this case
          }
          if (!isIncentiveActive) {
            activeIncentive = address(0);
            emit Incentive(address(0));
          }
        }
      }

      (amount0, amount1) = zeroToOne == cache.exactInput // the amount to provide could be less than initially specified (e.g. reached limit)
        ? (cache.amountRequiredInitial - amountRequired, cache.amountCalculated) // the amount to get could be less than initially specified (e.g. reached limit)
        : (cache.amountCalculated, cache.amountRequiredInitial - amountRequired);
    }

    (globalState.price, globalState.tick, globalState.timepointIndex) = (currentPrice, currentTick, cache.timepointIndex);

    liquidity = currentLiquidity;
    prevInitializedTick = cache.prevInitializedTick;
    if (zeroToOne) {
      totalFeeGrowth0Token = cache.totalFeeGrowth;
    } else {
      totalFeeGrowth1Token = cache.totalFeeGrowth;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../libraries/TickManagement.sol';
import '../libraries/TickTree.sol';
import './AlgebraPoolBase.sol';

/// @title Algebra tick structure abstract contract
/// @notice Encapsulates the logic of interaction with the data structure with ticks
/// @dev Ticks are stored as a doubly linked list. A two-layer bitmap tree is used to search through the list
abstract contract TickStructure is AlgebraPoolBase {
  using TickManagement for mapping(int24 => TickManagement.Tick);
  using TickTree for mapping(int16 => uint256);

  uint256 internal tickTreeRoot; // The root of bitmap search tree
  mapping(int16 => uint256) internal tickSecondLayer; // The second layer bitmap search tree

  // the leaves of the tree are stored in `tickTable`

  constructor() {
    ticks.initTickState();
  }

  /**
   * @notice Used to add or remove a tick from a doubly linked list and search tree
   * @param tick The tick being removed or added now
   * @param currentTick The current global tick in the pool
   * @param _prevInitializedTick Previous active tick before `currentTick`
   * @param remove Remove or add the tick
   * @return newPrevInitializedTick New previous active tick before `currentTick` if changed
   */
  function _insertOrRemoveTick(
    int24 tick,
    int24 currentTick,
    int24 _prevInitializedTick,
    bool remove
  ) internal override returns (int24 newPrevInitializedTick) {
    uint256 oldTickTreeRoot = tickTreeRoot;

    int24 prevTick;
    if (remove) {
      prevTick = ticks.removeTick(tick);
      if (_prevInitializedTick == tick) _prevInitializedTick = prevTick;
    } else {
      int24 nextTick;
      if (_prevInitializedTick < tick && tick <= currentTick) {
        nextTick = ticks[_prevInitializedTick].nextTick;
        prevTick = _prevInitializedTick;
        _prevInitializedTick = tick;
      } else {
        nextTick = tickTable.getNextTick(tickSecondLayer, oldTickTreeRoot, tick);
        prevTick = ticks[nextTick].prevTick;
      }
      ticks.insertTick(tick, prevTick, nextTick);
    }

    uint256 newTickTreeRoot = tickTable.toggleTick(tickSecondLayer, tick, oldTickTreeRoot);
    if (newTickTreeRoot != oldTickTreeRoot) tickTreeRoot = newTickTreeRoot;
    return _prevInitializedTick;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#flash
/// @notice Any contract that calls IAlgebraPoolActions#flash must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraFlashCallback {
  /// @notice Called to `msg.sender` after transferring to the recipient from IAlgebraPool#flash.
  /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
  /// The caller of this method _must_ be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
  /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#flash call
  function algebraFlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#mint
/// @notice Any contract that calls IAlgebraPoolActions#mint must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraMintCallback {
  /// @notice Called to `msg.sender` after minting liquidity to a position from IAlgebraPool#mint.
  /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
  /// The caller of this method _must_ be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
  /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#mint call
  function algebraMintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IAlgebraPoolActions#swap
/// @notice Any contract that calls IAlgebraPoolActions#swap must implement this interface
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraSwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IAlgebraPool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method _must_ be checked to be a AlgebraPool deployed by the canonical AlgebraFactory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IAlgebraPoolActions#swap call
  function algebraSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external;
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

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/// @title The interface for a Algebra Pool
/// @dev The pool interface is broken up into many smaller pieces.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Algebra Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain.
/// Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolDeployer {
  /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
  /// @dev Called by the pool constructor to fetch the parameters of the pool
  /// @return dataStorage The pools associated dataStorage
  /// @return factory The factory address
  /// @return communityVault The community vault address
  /// @return token0 The first token of the pool by address sort order
  /// @return token1 The second token of the pool by address sort order
  function getDeployParameters() external view returns (address dataStorage, address factory, address communityVault, address token0, address token1);

  /// @dev Deploys a pool with the given parameters by transiently setting the parameters in cache.
  /// @param dataStorage The pools associated dataStorage
  /// @param token0 The first token of the pool by address sort order
  /// @param token1 The second token of the pool by address sort order
  /// @return pool The deployed pool's address
  function deploy(address dataStorage, address token0, address token1) external returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

/// @title Errors emitted by a pool
/// @notice Contains custom errors emitted by the pool
interface IAlgebraPoolErrors {
  // ####  pool errors  ####

  /// @notice Emitted by the reentrancy guard
  error locked();

  /// @notice Emitted if arithmetic error occurred
  error arithmeticError();

  /// @notice Emitted if an attempt is made to initialize the pool twice
  error alreadyInitialized();

  /// @notice Emitted if 0 is passed as amountRequired to swap function
  error zeroAmountRequired();

  /// @notice Emitted if invalid amount is passed as amountRequired to swapSupportingFeeOnInputTokens function
  error invalidAmountRequired();

  /// @notice Emitted if the pool received fewer tokens than it should have
  error insufficientInputAmount();
  /// @notice Emitted if the pool received fewer tokens than it should have to mint calculated actual liquidity
  error insufficientAmountReceivedAtMint();

  /// @notice Emitted if there was an attempt to mint zero liquidity
  error zeroLiquidityDesired();
  /// @notice Emitted if actual amount of liquidity is zero (due to insufficient amount of tokens received)
  error zeroLiquidityActual();

  /// @notice Emitted if the pool received fewer tokens{0,1} after flash than it should have
  error flashInsufficientPaid0();
  error flashInsufficientPaid1();

  /// @notice Emitted if limitSqrtPrice param is incorrect
  error invalidLimitSqrtPrice();

  /// @notice Tick must be divisible by tickspacing
  error tickIsNotSpaced();

  /// @notice Emitted if a method is called that is accessible only to the factory owner or dedicated role
  error notAllowed();
  /// @notice Emitted if a method is called that is accessible only to the farming
  error onlyFarming();

  error invalidNewTickSpacing();
  error invalidNewCommunityFee();

  // ####  LiquidityMath errors  ####
  /// @notice Emitted if liquidity underflows
  error liquiditySub();
  /// @notice Emitted if liquidity overflows
  error liquidityAdd();

  // ####  TickManagement errors  ####
  error topTickLowerThanBottomTick();
  error bottomTickLowerThanMIN();
  error topTickAboveMAX();
  error liquidityOverflow();
  error tickIsNotInitialized();
  error tickInvalidLinks();

  // ####  SafeTransfer errors  ####
  error transferFailed();

  // ####  TickMath errors  ####
  error tickOutOfRange();
  error priceOutOfRange();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the virtual pool
/// @dev Used to calculate active liquidity in farmings
interface IAlgebraVirtualPool {
  /// @dev This function is called by the main pool if an initialized ticks are crossed by swap.
  /// If any one of crossed ticks is also initialized in a virtual pool it should be crossed too
  /// @param targetTick The target tick up to which we need to cross all active ticks
  /// @param zeroToOne The direction
  function crossTo(int24 targetTick, bool zeroToOne) external returns (bool success);
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

/// @title Minimal ERC20 interface for Algebra
/// @notice Contains a subset of the full ERC20 interface that is used in Algebra
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IERC20Minimal {
  /// @notice Returns the balance of a token
  /// @param account The account for which to look up the number of tokens it has, i.e. its balance
  /// @return The number of tokens held by the account
  function balanceOf(address account) external view returns (uint256);

  /// @notice Transfers the amount of token from the `msg.sender` to the recipient
  /// @param recipient The account that will receive the amount transferred
  /// @param amount The number of tokens to send from the sender to the recipient
  /// @return Returns true for a successful transfer, false for an unsuccessful transfer
  function transfer(address recipient, uint256 amount) external returns (bool);

  /// @notice Returns the current allowance given to a spender by an owner
  /// @param owner The account of the token owner
  /// @param spender The account of the token spender
  /// @return The current allowance granted by `owner` to `spender`
  function allowance(address owner, address spender) external view returns (uint256);

  /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
  /// @param spender The account which will be allowed to spend a given amount of the owners tokens
  /// @param amount The amount of tokens allowed to be used by `spender`
  /// @return Returns true for a successful approval, false for unsuccessful
  function approve(address spender, uint256 amount) external returns (bool);

  /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
  /// @param sender The account from which the transfer will be initiated
  /// @param recipient The recipient of the transfer
  /// @param amount The amount of the transfer
  /// @return Returns true for a successful transfer, false for unsuccessful
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
  /// @param from The account from which the tokens were sent, i.e. the balance decreased
  /// @param to The account to which the tokens were sent, i.e. the balance increased
  /// @param value The amount of tokens that were transferred
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
  /// @param owner The account that approved spending of its tokens
  /// @param spender The account for which the spending allowance was modified
  /// @param value The new allowance from the owner to the spender
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /// @notice Sets the initial price for the pool
  /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
  /// @dev Initialization should be done in one transaction with pool creation to avoid front-running
  /// @param price the initial sqrt price of the pool as a Q64.96
  function initialize(uint160 price) external;

  /// @notice Adds liquidity for the given recipient/bottomTick/topTick position
  /// @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
  /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
  /// on bottomTick, topTick, the amount of liquidity, and the current price. If bottomTick == topTick position is treated as a limit order
  /// @param sender The address which will receive potential surplus of paid tokens
  /// @param recipient The address for which the liquidity will be created
  /// @param bottomTick The lower tick of the position in which to add liquidity
  /// @param topTick The upper tick of the position in which to add liquidity
  /// @param amount The desired amount of liquidity to mint
  /// @param data Any data that should be passed through to the callback
  /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
  /// @return liquidityActual The actual minted amount of liquidity
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  ) external returns (uint256 amount0, uint256 amount1, uint128 liquidityActual);

  /// @notice Collects tokens owed to a position
  /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
  /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
  /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
  /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
  /// @param recipient The address which should receive the fees collected
  /// @param bottomTick The lower tick of the position for which to collect fees
  /// @param topTick The upper tick of the position for which to collect fees
  /// @param amount0Requested How much token0 should be withdrawn from the fees owed
  /// @param amount1Requested How much token1 should be withdrawn from the fees owed
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
  /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
  /// @dev Fees must be collected separately via a call to #collect
  /// @param bottomTick The lower tick of the position for which to burn liquidity
  /// @param topTick The upper tick of the position for which to burn liquidity
  /// @param amount How much liquidity to burn
  /// @return amount0 The amount of token0 sent to the recipient
  /// @return amount1 The amount of token1 sent to the recipient
  function burn(int24 bottomTick, int24 topTick, uint128 amount) external returns (uint256 amount0, uint256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0
  /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#AlgebraSwapCallback
  /// @param recipient The address to receive the output of the swap
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
  /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
  /// @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback#AlgebraSwapCallback
  /// @param sender The address called this function (Comes from the Router)
  /// @param recipient The address to receive the output of the swap
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountRequired The amount of the swap, which implicitly configures the swap as exact input
  /// @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
  /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
  /// @param data Any data to be passed through to the callback. If using the Router it should contain SwapRouter#SwapCallbackData
  /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
  /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountRequired,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
  /// @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback#AlgebraFlashCallback
  /// @dev All excess tokens paid in the callback are distributed to currently in-range liquidity providers as an additional fee.
  /// If there are no in-range liquidity providers, the fee will be transferred to the first active provider in the future
  /// @param recipient The address which will receive the token0 and token1 amounts
  /// @param amount0 The amount of token0 to send
  /// @param amount1 The amount of token1 to send
  /// @param data Any data to be passed through to the callback
  function flash(address recipient, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolDerivedState {
  /// @notice Returns a snapshot of seconds per liquidity and seconds inside a tick range
  /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
  /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
  /// snapshot is taken and the second snapshot is taken.
  /// @param bottomTick The lower tick of the range
  /// @param topTick The upper tick of the range
  /// @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
  /// @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
  function getInnerCumulatives(
    int24 bottomTick,
    int24 topTick
  ) external view returns (uint160 innerSecondsSpentPerLiquidity, uint32 innerSecondsSpent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
  /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
  /// @param price The initial sqrt price of the pool, as a Q64.96
  /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
  event Initialize(uint160 price, int24 tick);

  /// @notice Emitted when liquidity is minted for a given position
  /// @dev If the top and bottom ticks match, this should be treated as a limit order
  /// @param sender The address that minted the liquidity
  /// @param owner The owner of the position and recipient of any minted liquidity
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param liquidityAmount The amount of liquidity minted to the position range
  /// @param amount0 How much token0 was required for the minted liquidity
  /// @param amount1 How much token1 was required for the minted liquidity
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /// @notice Emitted when fees are collected by the owner of a position
  /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
  /// @param owner The owner of the position for which fees are collected
  /// @param recipient The address that received fees
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param amount0 The amount of token0 fees collected
  /// @param amount1 The amount of token1 fees collected
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /// @notice Emitted when a position's liquidity is removed
  /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
  /// @param owner The owner of the position for which liquidity is removed
  /// @param bottomTick The lower tick of the position
  /// @param topTick The upper tick of the position
  /// @param liquidityAmount The amount of liquidity to remove
  /// @param amount0 The amount of token0 withdrawn
  /// @param amount1 The amount of token1 withdrawn
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /// @notice Emitted by the pool for any swaps between token0 and token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the output of the swap
  /// @param amount0 The delta of the token0 balance of the pool
  /// @param amount1 The delta of the token1 balance of the pool
  /// @param price The sqrt(price) of the pool after the swap, as a Q64.96
  /// @param liquidity The liquidity of the pool after the swap
  /// @param tick The log base 1.0001 of price of the pool after the swap
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /// @notice Emitted by the pool for any flashes of token0/token1
  /// @param sender The address that initiated the swap call, and that received the callback
  /// @param recipient The address that received the tokens from flash
  /// @param amount0 The amount of token0 that was flashed
  /// @param amount1 The amount of token1 that was flashed
  /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
  /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /// @notice Emitted when the community fee is changed by the pool
  /// @param communityFeeNew The updated value of the community fee in thousandths (1e-3)
  event CommunityFee(uint8 communityFeeNew);

  /// @notice Emitted when the tick spacing changes
  /// @param newTickSpacing The updated value of the new tick spacing
  /// @param newTickSpacingLimitOrders The updated value of the new tick spacing for limit orders
  event TickSpacing(int24 newTickSpacing, int24 newTickSpacingLimitOrders);

  /// @notice Emitted when new activeIncentive is set
  /// @param newIncentiveAddress The address of the new incentive
  event Incentive(address indexed newIncentiveAddress);

  /// @notice Emitted when the fee changes inside the pool
  /// @param feeZtO The current fee for ZtO swaps in hundredths of a bip, i.e. 1e-6
  /// @param feeOtZ The current fee for OtZ swaps in hundredths of a bip, i.e. 1e-6
  event Fee(uint16 feeZtO, uint16 feeOtZ);

  /// @notice Emitted in case of an error when trying to write to the DataStorage
  /// @dev This shouldn't happen
  event DataStorageFailure();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /// @notice The contract that stores all the timepoints and can perform actions with them
  /// @return The operator address
  function dataStorageOperator() external view returns (address);

  /// @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
  /// @return The contract address
  function factory() external view returns (address);

  /// @notice The first of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token0() external view returns (address);

  /// @notice The second of the two tokens of the pool, sorted by address
  /// @return The token contract address
  function token1() external view returns (address);

  /// @notice The contract to which community fees are transferred
  /// @return The communityVault address
  function communityVault() external view returns (address);

  /// @notice The maximum amount of position liquidity that can use any tick in the range
  /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
  /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
  /// @return The max amount of liquidity per tick
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by permissioned addresses
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolPermissionedActions {
  /// @notice Set the community's % share of the fees. Cannot exceed 25% (250). Only factory owner or POOLS_ADMINISTRATOR_ROLE role
  /// @param communityFee new community fee percent in thousandths (1e-3)
  function setCommunityFee(uint8 communityFee) external;

  /// @notice Set the new tick spacing values. Only factory owner or POOLS_ADMINISTRATOR_ROLE role
  /// @param newTickSpacing The new tick spacing value
  /// @param newTickSpacingLimitOrders The new tick spacing value for limit orders
  function setTickSpacing(int24 newTickSpacing, int24 newTickSpacingLimitOrders) external;

  /// @notice Sets an active incentive. Only farming
  /// @param newIncentiveAddress The address associated with the incentive
  function setIncentive(address newIncentiveAddress) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
      uint256 prod0 = a * b; // Least significant 256 bits of the product
      uint256 prod1; // Most significant 256 bits of the product
      assembly {
        let mm := mulmod(a, b, not(0))
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
      }

      // Make sure the result is less than 2**256.
      // Also prevents denominator == 0
      require(denominator > prod1);

      // Handle non-overflow cases, 256 by 256 division
      if (prod1 == 0) {
        assembly {
          result := div(prod0, denominator)
        }
        return result;
      }

      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [prod1 prod0]
      // Compute remainder using mulmod
      // Subtract 256 bit remainder from 512 bit number
      assembly {
        let remainder := mulmod(a, b, denominator)
        prod1 := sub(prod1, gt(remainder, prod0))
        prod0 := sub(prod0, remainder)
      }

      // Factor powers of two out of denominator
      // Compute largest power of two divisor of denominator.
      // Always >= 1.
      uint256 twos = (0 - denominator) & denominator;
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
      // correct result modulo 2**256. Since the preconditions guarantee
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
    unchecked {
      if (a == 0 || ((result = a * b) / a == b)) {
        require(denominator > 0);
        assembly {
          result := add(div(result, denominator), gt(mod(result, denominator), 0))
        }
      } else {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
          require(result < type(uint256).max);
          result++;
        }
      }
    }
  }

  /// @notice Returns ceil(x / y)
  /// @dev division by 0 has unspecified behavior, and must be checked externally
  /// @param x The dividend
  /// @param y The divisor
  /// @return z The quotient, ceil(x / y)
  function unsafeDivRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
    assembly {
      z := add(div(x, y), gt(mod(x, y), 0))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../interfaces/IAlgebraPoolErrors.sol';
import './FullMath.sol';
import './Constants.sol';

/// @title LimitOrderManagement
/// @notice Contains functions for managing limit orders and relevant calculations
library LimitOrderManagement {
  struct LimitOrder {
    uint128 amountToSell;
    uint128 soldAmount;
    uint256 boughtAmount0Cumulative;
    uint256 boughtAmount1Cumulative;
    bool initialized;
  }

  /// @notice Updates a limit order state and returns true if the tick was flipped from initialized to uninitialized, or vice versa
  /// @param self The mapping containing limit order cumulatives for initialized ticks
  /// @param tick The tick that will be updated
  /// @param amount The amount of liquidity that will be added/removed
  /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
  function addOrRemoveLimitOrder(mapping(int24 => LimitOrder) storage self, int24 tick, int128 amount) internal returns (bool flipped) {
    LimitOrder storage data = self[tick];
    uint128 _amountToSell = data.amountToSell;
    unchecked {
      if (amount > 0) {
        flipped = _amountToSell == 0;
        _amountToSell += uint128(amount);
      } else {
        _amountToSell -= uint128(-amount);
        flipped = _amountToSell == 0;
        if (flipped) data.soldAmount = 0; // reset filled amount if all orders are closed
      }
      data.amountToSell = _amountToSell;
    }
  }

  /// @notice Adds/removes liquidity to tick with partly executed limit order
  /// @param self The mapping containing limit order cumulatives for initialized ticks
  /// @param tick The tick that will be updated
  /// @param amount The amount of liquidity that will be added/removed
  function addVirtualLiquidity(mapping(int24 => LimitOrder) storage self, int24 tick, int128 amount) internal {
    LimitOrder storage data = self[tick];
    if (amount > 0) {
      data.amountToSell += uint128(amount);
      data.soldAmount += uint128(amount);
    } else {
      data.amountToSell -= uint128(-amount);
      data.soldAmount -= uint128(-amount);
    }
  }

  /// @notice Executes a limit order on the specified tick
  /// @param self The mapping containing limit order cumulatives for initialized ticks
  /// @param tick Limit order execution tick
  /// @param tickSqrtPrice Limit order execution price
  /// @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @param amountA Amount of tokens that will be swapped
  /// @param fee The fee taken from the input amount, expressed in hundredths of a bip
  /// @return closed Status of limit order after execution
  /// @return amountOut Amount of token that user receive after swap
  /// @return amountIn Amount of token that user need to pay
  function executeLimitOrders(
    mapping(int24 => LimitOrder) storage self,
    int24 tick,
    uint160 tickSqrtPrice,
    bool zeroToOne,
    int256 amountA,
    uint16 fee
  ) internal returns (bool closed, uint256 amountOut, uint256 amountIn, uint256 feeAmount) {
    unchecked {
      bool exactIn = amountA > 0;
      if (!exactIn) amountA = -amountA;
      if (amountA < 0) revert IAlgebraPoolErrors.invalidAmountRequired(); // in case of type(int256).min

      // price is defined as "token1/token0"
      uint256 price = FullMath.mulDiv(tickSqrtPrice, tickSqrtPrice, Constants.Q96);

      uint256 amountB = (zeroToOne == exactIn)
        ? FullMath.mulDiv(uint256(amountA), price, Constants.Q96) // tokenA is token0
        : FullMath.mulDiv(uint256(amountA), Constants.Q96, price); // tokenA is token1

      // limit orders buy tokenIn and sell tokenOut
      (amountOut, amountIn) = exactIn ? (amountB, uint256(amountA)) : (uint256(amountA), amountB);

      LimitOrder storage data = self[tick];
      (uint128 amountToSell, uint128 soldAmount) = (data.amountToSell, data.soldAmount);
      uint256 unsoldAmount = amountToSell - soldAmount; // safe since soldAmount always < amountToSell

      if (exactIn) {
        amountOut = FullMath.mulDiv(amountOut, Constants.FEE_DENOMINATOR - fee, Constants.FEE_DENOMINATOR);
      }

      if (amountOut >= unsoldAmount) {
        if (amountOut > unsoldAmount) {
          amountOut = unsoldAmount;
        }
        (closed, data.amountToSell, data.soldAmount) = (true, 0, 0);
      } else {
        // overflow is desired since we do not support tokens with totalSupply > type(uint128).max
        data.soldAmount = soldAmount + uint128(amountOut);
      }

      amountIn = zeroToOne ? FullMath.mulDivRoundingUp(amountOut, Constants.Q96, price) : FullMath.mulDivRoundingUp(amountOut, price, Constants.Q96);
      if (exactIn) {
        if (amountOut == unsoldAmount) {
          feeAmount = FullMath.mulDivRoundingUp(amountIn, fee, Constants.FEE_DENOMINATOR);
        } else {
          feeAmount = uint256(amountA) - amountIn;
        }
      } else {
        feeAmount = FullMath.mulDivRoundingUp(amountIn, fee, Constants.FEE_DENOMINATOR - fee);
      }

      // overflows are desired since there are relative accumulators
      if (zeroToOne) {
        data.boughtAmount0Cumulative += FullMath.mulDiv(amountIn, Constants.Q128, amountToSell);
      } else {
        data.boughtAmount1Cumulative += FullMath.mulDiv(amountIn, Constants.Q128, amountToSell);
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IAlgebraPoolErrors.sol';
import './TickMath.sol';
import './TokenDeltaMath.sol';

/// @title Math library for liquidity
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library LiquidityMath {
  /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
  /// @param x The liquidity before change
  /// @param y The delta by which liquidity should be changed
  /// @return z The liquidity delta
  function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
    unchecked {
      if (y < 0) {
        if ((z = x - uint128(-y)) >= x) revert IAlgebraPoolErrors.liquiditySub();
      } else {
        if ((z = x + uint128(y)) < x) revert IAlgebraPoolErrors.liquidityAdd();
      }
    }
  }

  function getAmountsForLiquidity(
    int24 bottomTick,
    int24 topTick,
    int128 liquidityDelta,
    int24 currentTick,
    uint160 currentPrice
  ) internal pure returns (uint256 amount0, uint256 amount1, int128 globalLiquidityDelta) {
    uint160 priceAtBottomTick = TickMath.getSqrtRatioAtTick(bottomTick);
    uint160 priceAtTopTick = TickMath.getSqrtRatioAtTick(topTick);

    int256 amount0Int;
    int256 amount1Int;
    if (currentTick < bottomTick) {
      // If current tick is less than the provided bottom one then only the token0 has to be provided
      amount0Int = TokenDeltaMath.getToken0Delta(priceAtBottomTick, priceAtTopTick, liquidityDelta);
    } else if (currentTick < topTick) {
      amount0Int = TokenDeltaMath.getToken0Delta(currentPrice, priceAtTopTick, liquidityDelta);
      amount1Int = TokenDeltaMath.getToken1Delta(priceAtBottomTick, currentPrice, liquidityDelta);
      globalLiquidityDelta = liquidityDelta;
    } else {
      // If current tick is greater than the provided top one then only the token1 has to be provided
      amount1Int = TokenDeltaMath.getToken1Delta(priceAtBottomTick, priceAtTopTick, liquidityDelta);
    }

    unchecked {
      (amount0, amount1) = liquidityDelta < 0 ? (uint256(-amount0Int), uint256(-amount1Int)) : (uint256(amount0Int), uint256(amount1Int));
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library LowGasSafeMath {
  /// @notice Returns x + y, reverts if sum overflows uint256
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }

  /// @notice Returns x - y, reverts if underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require((z = x - y) <= x);
    }
  }

  /// @notice Returns x * y, reverts if overflows
  /// @param x The multiplicand
  /// @param y The multiplier
  /// @return z The product of x and y
  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    unchecked {
      require(x == 0 || (z = x * y) / x == y);
    }
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      require((z = x + y) >= x == (y >= 0));
    }
  }

  /// @notice Returns x - y, reverts if overflows or underflows
  /// @param x The minuend
  /// @param y The subtrahend
  /// @return z The difference of x and y
  function sub(int256 x, int256 y) internal pure returns (int256 z) {
    unchecked {
      require((z = x - y) <= x == (y >= 0));
    }
  }

  /// @notice Returns x + y, reverts if overflows or underflows
  /// @param x The augend
  /// @param y The addend
  /// @return z The sum of x and y
  function add128(uint128 x, uint128 y) internal pure returns (uint128 z) {
    unchecked {
      require((z = x + y) >= x);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../interfaces/IAlgebraPoolErrors.sol';
import './FullMath.sol';
import './LowGasSafeMath.sol';
import './TokenDeltaMath.sol';
import './TickMath.sol';
import './Constants.sol';

/// @title Computes the result of price movement
/// @notice Contains methods for computing the result of price movement within a single tick price range.
library PriceMovementMath {
  using LowGasSafeMath for uint256;
  using SafeCast for uint256;

  /// @notice Gets the next sqrt price given an input amount of token0 or token1
  /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
  /// @param price The starting Q64.96 sqrt price, i.e., before accounting for the input amount
  /// @param liquidity The amount of usable liquidity
  /// @param input How much of token0, or token1, is being swapped in
  /// @param zeroToOne Whether the amount in is token0 or token1
  /// @return resultPrice The Q64.96 sqrt price after adding the input amount to token0 or token1
  function getNewPriceAfterInput(uint160 price, uint128 liquidity, uint256 input, bool zeroToOne) internal pure returns (uint160 resultPrice) {
    return getNewPrice(price, liquidity, input, zeroToOne, true);
  }

  /// @notice Gets the next sqrt price given an output amount of token0 or token1
  /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
  /// @param price The starting Q64.96 sqrt price before accounting for the output amount
  /// @param liquidity The amount of usable liquidity
  /// @param output How much of token0, or token1, is being swapped out
  /// @param zeroToOne Whether the amount out is token0 or token1
  /// @return resultPrice The Q64.96 sqrt price after removing the output amount of token0 or token1
  function getNewPriceAfterOutput(uint160 price, uint128 liquidity, uint256 output, bool zeroToOne) internal pure returns (uint160 resultPrice) {
    return getNewPrice(price, liquidity, output, zeroToOne, false);
  }

  function getNewPrice(uint160 price, uint128 liquidity, uint256 amount, bool zeroToOne, bool fromInput) internal pure returns (uint160 resultPrice) {
    unchecked {
      require(price != 0);
      require(liquidity != 0);

      if (zeroToOne == fromInput) {
        // rounding up or down
        if (amount == 0) return price;
        uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

        if (fromInput) {
          uint256 product;
          if ((product = amount * price) / amount == price) {
            uint256 denominator = liquidityShifted + product;
            if (denominator >= liquidityShifted) return uint160(FullMath.mulDivRoundingUp(liquidityShifted, price, denominator)); // always fits in 160 bits
          }

          return uint160(FullMath.unsafeDivRoundingUp(liquidityShifted, (liquidityShifted / price).add(amount))); // denominator always > 0
        } else {
          uint256 product;
          require((product = amount * price) / amount == price); // if the product overflows, we know the denominator underflows
          require(liquidityShifted > product); // in addition, we must check that the denominator does not underflow
          return FullMath.mulDivRoundingUp(liquidityShifted, price, liquidityShifted - product).toUint160();
        }
      } else {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (fromInput) {
          return
            uint256(price)
              .add(amount <= type(uint160).max ? (amount << Constants.RESOLUTION) / liquidity : FullMath.mulDiv(amount, Constants.Q96, liquidity))
              .toUint160();
        } else {
          uint256 quotient = amount <= type(uint160).max
            ? FullMath.unsafeDivRoundingUp(amount << Constants.RESOLUTION, liquidity) // denominator always > 0
            : FullMath.mulDivRoundingUp(amount, Constants.Q96, liquidity);

          require(price > quotient);
          return uint160(price - quotient); // always fits 160 bits
        }
      }
    }
  }

  function getTokenADelta01(uint160 to, uint160 from, uint128 liquidity) internal pure returns (uint256) {
    return TokenDeltaMath.getToken0Delta(to, from, liquidity, true);
  }

  function getTokenADelta10(uint160 to, uint160 from, uint128 liquidity) internal pure returns (uint256) {
    return TokenDeltaMath.getToken1Delta(from, to, liquidity, true);
  }

  function getTokenBDelta01(uint160 to, uint160 from, uint128 liquidity) internal pure returns (uint256) {
    return TokenDeltaMath.getToken1Delta(to, from, liquidity, false);
  }

  function getTokenBDelta10(uint160 to, uint160 from, uint128 liquidity) internal pure returns (uint256) {
    return TokenDeltaMath.getToken0Delta(from, to, liquidity, false);
  }

  /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
  /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
  /// @param zeroToOne The direction of price movement
  /// @param currentPrice The current Q64.96 sqrt price of the pool
  /// @param targetPrice The Q64.96 sqrt price that cannot be exceeded, from which the direction of the swap is inferred
  /// @param liquidity The usable liquidity
  /// @param amountAvailable How much input or output amount is remaining to be swapped in/out
  /// @param fee The fee taken from the input amount, expressed in hundredths of a bip
  /// @return resultPrice The Q64.96 sqrt price after swapping the amount in/out, not to exceed the price target
  /// @return input The amount to be swapped in, of either token0 or token1, based on the direction of the swap
  /// @return output The amount to be received, of either token0 or token1, based on the direction of the swap
  /// @return feeAmount The amount of input that will be taken as a fee
  function movePriceTowardsTarget(
    bool zeroToOne,
    uint160 currentPrice,
    uint160 targetPrice,
    uint128 liquidity,
    int256 amountAvailable,
    uint16 fee
  ) internal pure returns (uint160 resultPrice, uint256 input, uint256 output, uint256 feeAmount) {
    unchecked {
      function(uint160, uint160, uint128) pure returns (uint256) getAmountA = zeroToOne ? getTokenADelta01 : getTokenADelta10;

      if (amountAvailable >= 0) {
        // exactIn or not
        uint256 amountAvailableAfterFee = FullMath.mulDiv(uint256(amountAvailable), Constants.FEE_DENOMINATOR - fee, Constants.FEE_DENOMINATOR);
        input = getAmountA(targetPrice, currentPrice, liquidity);
        if (amountAvailableAfterFee >= input) {
          resultPrice = targetPrice;
          feeAmount = FullMath.mulDivRoundingUp(input, fee, Constants.FEE_DENOMINATOR - fee);
        } else {
          resultPrice = getNewPriceAfterInput(currentPrice, liquidity, amountAvailableAfterFee, zeroToOne);
          if (targetPrice != resultPrice) {
            input = getAmountA(resultPrice, currentPrice, liquidity);

            // we didn't reach the target, so take the remainder of the maximum input as fee
            feeAmount = uint256(amountAvailable) - input;
          } else {
            feeAmount = FullMath.mulDivRoundingUp(input, fee, Constants.FEE_DENOMINATOR - fee);
          }
        }

        output = (zeroToOne ? getTokenBDelta01 : getTokenBDelta10)(resultPrice, currentPrice, liquidity);
      } else {
        function(uint160, uint160, uint128) pure returns (uint256) getAmountB = zeroToOne ? getTokenBDelta01 : getTokenBDelta10;

        output = getAmountB(targetPrice, currentPrice, liquidity);
        amountAvailable = -amountAvailable;
        if (amountAvailable < 0) revert IAlgebraPoolErrors.invalidAmountRequired(); // in case of type(int256).min

        if (uint256(amountAvailable) >= output) resultPrice = targetPrice;
        else {
          resultPrice = getNewPriceAfterOutput(currentPrice, liquidity, uint256(amountAvailable), zeroToOne);

          if (targetPrice != resultPrice) {
            output = getAmountB(resultPrice, currentPrice, liquidity);
          }

          // cap the output amount to not exceed the remaining output amount
          if (output > uint256(amountAvailable)) {
            output = uint256(amountAvailable);
          }
        }

        input = getAmountA(resultPrice, currentPrice, liquidity);
        feeAmount = FullMath.mulDivRoundingUp(input, fee, Constants.FEE_DENOMINATOR - fee);
      }
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0 || ^0.8.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
library SafeCast {
  /// @notice Cast a uint256 to a uint160, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint160
  function toUint160(uint256 y) internal pure returns (uint160 z) {
    require((z = uint160(y)) == y);
  }

  /// @notice Cast a uint256 to a uint128, revert on overflow
  /// @param y The uint256 to be downcasted
  /// @return z The downcasted integer, now type uint128
  function toUint128(uint256 y) internal pure returns (uint128 z) {
    require((z = uint128(y)) == y);
  }

  /// @notice Cast a int256 to a int128, revert on overflow or underflow
  /// @param y The int256 to be downcasted
  /// @return z The downcasted integer, now type int128
  function toInt128(int256 y) internal pure returns (int128 z) {
    require((z = int128(y)) == y);
  }

  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    require((z = int256(y)) >= 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IAlgebraPoolErrors.sol';

/// @title SafeTransfer
/// @notice Safe ERC20 transfer library that gracefully handles missing return values.
/// @dev Credit to Solmate under MIT license: https://github.com/transmissions11/solmate/blob/ed67feda67b24fdeff8ad1032360f0ee6047ba0a/src/utils/SafeTransferLib.sol
/// @dev Please note that this library does not check if the token has a code! That responsibility is delegated to the caller.
library SafeTransfer {
  /// @notice Transfers tokens to a recipient
  /// @dev Calls transfer on token contract, errors with transferFailed() if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param amount The amount of the token to transfer
  function safeTransfer(address token, address to, uint256 amount) internal {
    bool success;
    assembly {
      let freeMemoryPointer := mload(0x40) // we will need to restore 0x40 slot
      mstore(0x00, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // "transfer(address,uint256)" selector
      mstore(0x04, and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // append cleaned "to" address
      mstore(0x24, amount)
      // now we use 0x00 - 0x44 bytes (68), freeMemoryPointer is dirty
      success := call(gas(), token, 0, 0, 0x44, 0, 0x20)
      success := and(
        // set success to true if call isn't reverted and returned exactly 1 (can't just be non-zero data) or nothing
        or(and(eq(mload(0), 1), eq(returndatasize(), 32)), iszero(returndatasize())),
        success
      )
      mstore(0x40, freeMemoryPointer) // restore the freeMemoryPointer
    }

    if (!success) revert IAlgebraPoolErrors.transferFailed();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import '../interfaces/IAlgebraPoolErrors.sol';

import './TickMath.sol';
import './LiquidityMath.sol';
import './Constants.sol';

/// @title TickManagement
/// @notice Contains functions for managing tick processes and relevant calculations
library TickManagement {
  // info stored for each initialized individual tick
  struct Tick {
    uint128 liquidityTotal; // the total position liquidity that references this tick
    int128 liquidityDelta; // amount of net liquidity added (subtracted) when tick is crossed left-right (right-left),
    // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
    // only has relative meaning, not absolute — the value depends on when the tick is initialized
    uint256 outerFeeGrowth0Token;
    uint256 outerFeeGrowth1Token;
    int24 prevTick;
    int24 nextTick;
    uint160 outerSecondsPerLiquidity; // the seconds per unit of liquidity on the _other_ side of current tick, (relative meaning)
    uint32 outerSecondsSpent; // the seconds spent on the other side of the current tick, only has relative meaning
    bool hasLimitOrders;
  }

  function checkTickRangeValidity(int24 bottomTick, int24 topTick) internal pure {
    if (topTick > TickMath.MAX_TICK) revert IAlgebraPoolErrors.topTickAboveMAX();
    if (topTick < bottomTick) revert IAlgebraPoolErrors.topTickLowerThanBottomTick();
    if (bottomTick < TickMath.MIN_TICK) revert IAlgebraPoolErrors.bottomTickLowerThanMIN();
  }

  /// @notice Retrieves fee growth data
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param bottomTick The lower tick boundary of the position
  /// @param topTick The upper tick boundary of the position
  /// @param currentTick The current tick
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @return innerFeeGrowth0Token The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
  /// @return innerFeeGrowth1Token The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
  function getInnerFeeGrowth(
    mapping(int24 => Tick) storage self,
    int24 bottomTick,
    int24 topTick,
    int24 currentTick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token
  ) internal view returns (uint256 innerFeeGrowth0Token, uint256 innerFeeGrowth1Token) {
    Tick storage lower = self[bottomTick];
    Tick storage upper = self[topTick];

    unchecked {
      if (currentTick < topTick) {
        if (currentTick >= bottomTick) {
          innerFeeGrowth0Token = totalFeeGrowth0Token - lower.outerFeeGrowth0Token;
          innerFeeGrowth1Token = totalFeeGrowth1Token - lower.outerFeeGrowth1Token;
        } else {
          innerFeeGrowth0Token = lower.outerFeeGrowth0Token;
          innerFeeGrowth1Token = lower.outerFeeGrowth1Token;
        }
        innerFeeGrowth0Token -= upper.outerFeeGrowth0Token;
        innerFeeGrowth1Token -= upper.outerFeeGrowth1Token;
      } else {
        innerFeeGrowth0Token = upper.outerFeeGrowth0Token - lower.outerFeeGrowth0Token;
        innerFeeGrowth1Token = upper.outerFeeGrowth1Token - lower.outerFeeGrowth1Token;
      }
    }
  }

  /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be updated
  /// @param currentTick The current tick
  /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @param secondsPerLiquidityCumulative The all-time seconds per max(1, liquidity) of the pool
  /// @param time The current block timestamp cast to a uint32
  /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
  /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
  function update(
    mapping(int24 => Tick) storage self,
    int24 tick,
    int24 currentTick,
    int128 liquidityDelta,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    uint160 secondsPerLiquidityCumulative,
    uint32 time,
    bool upper
  ) internal returns (bool flipped) {
    Tick storage data = self[tick];

    int128 liquidityDeltaBefore = data.liquidityDelta;
    uint128 liquidityTotalBefore = data.liquidityTotal;

    uint128 liquidityTotalAfter = LiquidityMath.addDelta(liquidityTotalBefore, liquidityDelta);
    if (liquidityTotalAfter > Constants.MAX_LIQUIDITY_PER_TICK) revert IAlgebraPoolErrors.liquidityOverflow();

    // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
    data.liquidityDelta = upper ? int128(int256(liquidityDeltaBefore) - liquidityDelta) : int128(int256(liquidityDeltaBefore) + liquidityDelta);

    data.liquidityTotal = liquidityTotalAfter;

    flipped = (liquidityTotalAfter == 0);
    if (liquidityTotalBefore == 0) {
      flipped = !flipped;
      // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
      if (tick <= currentTick) {
        data.outerFeeGrowth0Token = totalFeeGrowth0Token;
        data.outerFeeGrowth1Token = totalFeeGrowth1Token;
        data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative;
        data.outerSecondsSpent = time;
      }
    }

    if (flipped) flipped = !data.hasLimitOrders;
  }

  /// @notice Transitions to next tick as needed by price movement
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The destination tick of the transition
  /// @param totalFeeGrowth0Token The all-time global fee growth, per unit of liquidity, in token0
  /// @param totalFeeGrowth1Token The all-time global fee growth, per unit of liquidity, in token1
  /// @param secondsPerLiquidityCumulative The current seconds per liquidity
  /// @param time The current block.timestamp
  /// @return liquidityDelta The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
  function cross(
    mapping(int24 => Tick) storage self,
    int24 tick,
    uint256 totalFeeGrowth0Token,
    uint256 totalFeeGrowth1Token,
    uint160 secondsPerLiquidityCumulative,
    uint32 time
  ) internal returns (int128 liquidityDelta) {
    Tick storage data = self[tick];

    unchecked {
      data.outerSecondsSpent = time - data.outerSecondsSpent;
      data.outerSecondsPerLiquidity = secondsPerLiquidityCumulative - data.outerSecondsPerLiquidity;

      data.outerFeeGrowth1Token = totalFeeGrowth1Token - data.outerFeeGrowth1Token;
      data.outerFeeGrowth0Token = totalFeeGrowth0Token - data.outerFeeGrowth0Token;
    }
    return data.liquidityDelta;
  }

  /// @notice Used for initial setup if ticks list
  /// @param self The mapping containing all tick information for initialized ticks
  function initTickState(mapping(int24 => Tick) storage self) internal {
    (self[TickMath.MIN_TICK].prevTick, self[TickMath.MIN_TICK].nextTick) = (TickMath.MIN_TICK, TickMath.MAX_TICK);
    (self[TickMath.MAX_TICK].prevTick, self[TickMath.MAX_TICK].nextTick) = (TickMath.MIN_TICK, TickMath.MAX_TICK);
  }

  /// @notice Removes tick from linked list
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be removed
  /// @return prevTick
  function removeTick(mapping(int24 => Tick) storage self, int24 tick) internal returns (int24) {
    (int24 prevTick, int24 nextTick) = (self[tick].prevTick, self[tick].nextTick);
    delete self[tick];

    if (tick == TickMath.MIN_TICK || tick == TickMath.MAX_TICK) {
      // MIN_TICK and MAX_TICK cannot be removed from tick list
      (self[tick].prevTick, self[tick].nextTick) = (prevTick, nextTick);
      return prevTick;
    } else {
      if (prevTick == nextTick) revert IAlgebraPoolErrors.tickIsNotInitialized();
      self[prevTick].nextTick = nextTick;
      self[nextTick].prevTick = prevTick;
      return prevTick;
    }
  }

  /// @notice Adds tick to linked list
  /// @param self The mapping containing all tick information for initialized ticks
  /// @param tick The tick that will be inserted
  /// @param prevTick The previous active tick
  /// @param nextTick The next active tick
  function insertTick(mapping(int24 => Tick) storage self, int24 tick, int24 prevTick, int24 nextTick) internal {
    if (tick == TickMath.MIN_TICK || tick == TickMath.MAX_TICK) return;
    if (prevTick >= tick || nextTick <= tick) revert IAlgebraPoolErrors.tickInvalidLinks();
    (self[tick].prevTick, self[tick].nextTick) = (prevTick, nextTick);

    self[prevTick].nextTick = tick;
    self[nextTick].prevTick = tick;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4 <0.9.0;

import '../interfaces/IAlgebraPoolErrors.sol';

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/blob/main/contracts/libraries
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
  /// @return price A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
  /// at the given tick
  function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 price) {
    unchecked {
      // get abs value
      int24 mask = tick >> (24 - 1);
      uint256 absTick = uint24((tick ^ mask) - mask);
      if (absTick > uint24(MAX_TICK)) revert IAlgebraPoolErrors.tickOutOfRange();

      uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
      if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
      if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
      if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
      if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
      if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
      if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
      if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
      if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
      if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
      if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
      if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
      if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
      if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
      if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
      if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
      if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
      if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
      if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
      if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

      if (tick > 0) ratio = type(uint256).max / ratio;

      // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
      // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
      // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
      price = uint160((ratio + 0xFFFFFFFF) >> 32);
    }
  }

  /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
  /// @dev Throws in case price < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
  /// ever return.
  /// @param price The sqrt ratio for which to compute the tick as a Q64.96
  /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
  function getTickAtSqrtRatio(uint160 price) internal pure returns (int24 tick) {
    unchecked {
      // second inequality must be >= because the price can never reach the price at the max tick
      if (price < MIN_SQRT_RATIO || price >= MAX_SQRT_RATIO) revert IAlgebraPoolErrors.priceOutOfRange();
      uint256 ratio = uint256(price) << 32;

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

      tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= price ? tickHi : tickLow;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './Constants.sol';
import './TickMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state and search tree
/// @dev The leafs mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickTree {
  int16 internal constant SECOND_LAYER_OFFSET = 3466; // ceil(MAX_TICK / 256)

  /// @notice Toggles the initialized state for a given tick from false to true, or vice versa
  /// @param leafs The mapping of words with ticks
  /// @param secondLayer The mapping of words with leafs
  /// @param tick The tick to toggle
  /// @param treeRoot The word with info about active subtrees
  function toggleTick(
    mapping(int16 => uint256) storage leafs,
    mapping(int16 => uint256) storage secondLayer,
    int24 tick,
    uint256 treeRoot
  ) internal returns (uint256 newTreeRoot) {
    newTreeRoot = treeRoot;
    (bool toggledNode, int16 nodeNumber) = _toggleTickInNode(leafs, tick);
    if (toggledNode) {
      unchecked {
        (toggledNode, nodeNumber) = _toggleTickInNode(secondLayer, nodeNumber + SECOND_LAYER_OFFSET);
      }
      if (toggledNode) {
        assembly {
          newTreeRoot := xor(newTreeRoot, shl(nodeNumber, 1))
        }
      }
    }
  }

  /// @notice Calculates the required node and toggles tick in it
  /// @param row The level of tree
  /// @param tick The tick to toggle
  /// @return toggledNode Toggled whole node or not
  /// @return nodeNumber Number of corresponding node
  function _toggleTickInNode(mapping(int16 => uint256) storage row, int24 tick) private returns (bool toggledNode, int16 nodeNumber) {
    assembly {
      nodeNumber := sar(8, tick)
    }
    uint256 node = row[nodeNumber];
    assembly {
      toggledNode := iszero(node)
      node := xor(node, shl(and(tick, 0xFF), 1))
      toggledNode := xor(toggledNode, iszero(node))
    }
    row[nodeNumber] = node;
  }

  /// @notice Returns the next initialized tick in tree to the right (gte) of the given tick or `MAX_TICK`
  /// @param leafs The words with ticks
  /// @param secondLayer The words with info about active leafs
  /// @param treeRoot The word with info about active subtrees
  /// @param tick The starting tick
  /// @return nextTick The next initialized tick or `MAX_TICK`
  function getNextTick(
    mapping(int16 => uint256) storage leafs,
    mapping(int16 => uint256) storage secondLayer,
    uint256 treeRoot,
    int24 tick
  ) internal view returns (int24 nextTick) {
    unchecked {
      tick++;
      int16 nodeNumber;
      bool initialized;
      assembly {
        // index in treeRoot
        nodeNumber := shr(8, add(sar(8, tick), SECOND_LAYER_OFFSET))
      }
      if (treeRoot & (1 << uint16(nodeNumber)) != 0) {
        // if subtree has active ticks
        // try to find initialized tick in the corresponding leaf of the tree
        (nodeNumber, nextTick, initialized) = _getNextActiveBitInSameNode(leafs, tick);
        if (initialized) return nextTick;

        // try to find next initialized leaf in the tree
        (nodeNumber, nextTick, initialized) = _getNextActiveBitInSameNode(secondLayer, nodeNumber + SECOND_LAYER_OFFSET + 1);
      }
      if (!initialized) {
        // try to find which subtree has an active leaf
        (nextTick, initialized) = _nextActiveBitInTheSameNode(treeRoot, ++nodeNumber);
        if (!initialized) return TickMath.MAX_TICK;
        nextTick = _getFirstActiveBitInNode(secondLayer, nextTick);
      }
      nextTick = _getFirstActiveBitInNode(leafs, nextTick - SECOND_LAYER_OFFSET);
    }
  }

  /// @notice Calculates node with given tick and returns next active tick
  /// @param row level of search tree
  /// @param tick The starting tick
  /// @return nodeNumber Number of corresponding node
  /// @return nextTick Number of next active tick or last tick in node
  /// @return initialized Is nextTick initialized or not
  function _getNextActiveBitInSameNode(
    mapping(int16 => uint256) storage row,
    int24 tick
  ) private view returns (int16 nodeNumber, int24 nextTick, bool initialized) {
    assembly {
      nodeNumber := sar(8, tick)
    }
    (nextTick, initialized) = _nextActiveBitInTheSameNode(row[nodeNumber], tick);
  }

  /// @notice Returns first active tick in given node
  /// @param row level of search tree
  /// @param nodeNumber Number of corresponding node
  /// @return nextTick Number of next active tick or last tick in node
  function _getFirstActiveBitInNode(mapping(int16 => uint256) storage row, int24 nodeNumber) private view returns (int24 nextTick) {
    assembly {
      nextTick := shl(8, nodeNumber)
    }
    (nextTick, ) = _nextActiveBitInTheSameNode(row[int16(nodeNumber)], nextTick);
  }

  /// @notice Returns the next initialized tick contained in the same word as the tick that is
  /// to the right or at (gte) of the given tick
  /// @param word The word in which to compute the next initialized tick
  /// @param tick The starting tick
  /// @return nextTick The next initialized or uninitialized tick up to 256 ticks away from the current tick
  /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
  function _nextActiveBitInTheSameNode(uint256 word, int24 tick) private pure returns (int24 nextTick, bool initialized) {
    uint256 bitNumber;
    assembly {
      bitNumber := and(tick, 0xFF)
    }
    unchecked {
      uint256 _row = word >> bitNumber; // all the 1s at or to the left of the bitNumber
      if (_row == 0) {
        nextTick = tick + int24(uint24(255 - bitNumber));
      } else {
        nextTick = tick + int24(uint24(getSingleSignificantBit((0 - _row) & _row))); // least significant bit
        initialized = true;
      }
    }
  }

  /// @notice get position of single 1-bit
  /// @dev it is assumed that word contains exactly one 1-bit, otherwise the result will be incorrect
  /// @param word The word containing only one 1-bit
  function getSingleSignificantBit(uint256 word) internal pure returns (uint8 singleBitPos) {
    assembly {
      singleBitPos := iszero(and(word, 0x5555555555555555555555555555555555555555555555555555555555555555))
      singleBitPos := or(singleBitPos, shl(7, iszero(and(word, 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(6, iszero(and(word, 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(5, iszero(and(word, 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF))))
      singleBitPos := or(singleBitPos, shl(4, iszero(and(word, 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF))))
      singleBitPos := or(singleBitPos, shl(3, iszero(and(word, 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF))))
      singleBitPos := or(singleBitPos, shl(2, iszero(and(word, 0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F))))
      singleBitPos := or(singleBitPos, shl(1, iszero(and(word, 0x3333333333333333333333333333333333333333333333333333333333333333))))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.17;

import './SafeCast.sol';
import './FullMath.sol';
import './Constants.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library TokenDeltaMath {
  using SafeCast for uint256;

  /// @notice Gets the token0 delta between two prices
  /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper)
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up or down
  /// @return token0Delta Amount of token0 required to cover a position of size liquidity between the two passed prices
  function getToken0Delta(uint160 priceLower, uint160 priceUpper, uint128 liquidity, bool roundUp) internal pure returns (uint256 token0Delta) {
    unchecked {
      uint256 priceDelta = priceUpper - priceLower;
      require(priceDelta < priceUpper); // forbids underflow and 0 priceLower
      uint256 liquidityShifted = uint256(liquidity) << Constants.RESOLUTION;

      token0Delta = roundUp
        ? FullMath.unsafeDivRoundingUp(FullMath.mulDivRoundingUp(priceDelta, liquidityShifted, priceUpper), priceLower) // denominator always > 0
        : FullMath.mulDiv(priceDelta, liquidityShifted, priceUpper) / priceLower;
    }
  }

  /// @notice Gets the token1 delta between two prices
  /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The amount of usable liquidity
  /// @param roundUp Whether to round the amount up, or down
  /// @return token1Delta Amount of token1 required to cover a position of size liquidity between the two passed prices
  function getToken1Delta(uint160 priceLower, uint160 priceUpper, uint128 liquidity, bool roundUp) internal pure returns (uint256 token1Delta) {
    unchecked {
      require(priceUpper >= priceLower);
      uint256 priceDelta = priceUpper - priceLower;
      token1Delta = roundUp ? FullMath.mulDivRoundingUp(priceDelta, liquidity, Constants.Q96) : FullMath.mulDiv(priceDelta, liquidity, Constants.Q96);
    }
  }

  /// @notice Helper that gets signed token0 delta
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The change in liquidity for which to compute the token0 delta
  /// @return token0Delta Amount of token0 corresponding to the passed liquidityDelta between the two prices
  function getToken0Delta(uint160 priceLower, uint160 priceUpper, int128 liquidity) internal pure returns (int256 token0Delta) {
    unchecked {
      token0Delta = liquidity >= 0
        ? getToken0Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
        : -getToken0Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
    }
  }

  /// @notice Helper that gets signed token1 delta
  /// @param priceLower A Q64.96 sqrt price
  /// @param priceUpper Another Q64.96 sqrt price
  /// @param liquidity The change in liquidity for which to compute the token1 delta
  /// @return token1Delta Amount of token1 corresponding to the passed liquidityDelta between the two prices
  function getToken1Delta(uint160 priceLower, uint160 priceUpper, int128 liquidity) internal pure returns (int256 token1Delta) {
    unchecked {
      token1Delta = liquidity >= 0
        ? getToken1Delta(priceLower, priceUpper, uint128(liquidity), true).toInt256()
        : -getToken1Delta(priceLower, priceUpper, uint128(-liquidity), false).toInt256();
    }
  }
}