pragma solidity 0.8.18;

import {IOrderManagerWithStorage} from "../interfaces/IOrderManagerWithStorage.sol";
import {IPoolWithStorage} from "../interfaces/IPoolWithStorage.sol";
import {ILiquidityCalculator} from "../interfaces/ILiquidityCalculator.sol";
import {PositionLogic} from "../lib/PositionLogic.sol";
import {DataTypes} from "../lib/DataTypes.sol";
import {Constants} from "../lib/Constants.sol";

contract OrderLens {
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    struct LeverageOrderView {
        uint256 id;
        address indexToken;
        address collateralToken;
        address payToken;
        DataTypes.Side side;
        DataTypes.UpdatePositionType updateType;
        uint256 triggerPrice;
        uint256 sizeChange;
        uint256 collateral;
        uint256 expiresAt;
        bool triggerAboveThreshold;
    }

    struct SwapOrderView {
        uint256 id;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 price;
    }

    IOrderManagerWithStorage public immutable orderManager;
    IPoolWithStorage public immutable pool;

    constructor(address _orderManager, address _pool) {
        require(_orderManager != address(0), "invalid address");
        require(_pool != address(0), "invalid address");
        orderManager = IOrderManagerWithStorage(_orderManager);
        pool = IPoolWithStorage(_pool);
    }

    function getOpenLeverageOrders(address _owner, uint256 _skip, uint256 _take, uint256 _head)
        external
        view
        returns (LeverageOrderView[] memory, uint256)
    {
        uint256 totalOrder = orderManager.userLeverageOrderCount(_owner);

        uint256 remain = totalOrder > _head ? totalOrder - _head : 0;
        if (remain == 0 || _skip >= totalOrder) {
            return (new LeverageOrderView[](0), remain);
        }

        uint256 startIndex = totalOrder - _skip;

        LeverageOrderView[] memory openOrders = new LeverageOrderView[](_take);
        uint256 count = 0;

        for (uint256 i = startIndex; i > _head && count < _take; --i) {
            uint256 orderId = orderManager.userLeverageOrders(_owner, i - 1);
            LeverageOrderView memory order = _parseLeverageOrder(orderId);
            if (order.indexToken != address(0)) {
                openOrders[count] = order;
                count++;
            }
        }

        if (count == _take) {
            return (openOrders, remain);
        }
        // trim empty item
        LeverageOrderView[] memory ret = new LeverageOrderView[](count);
        for (uint256 i = 0; i < count; i++) {
            ret[i] = openOrders[i];
        }

        return (ret, remain);
    }

    /// @param _head number of elements to skip from head
    function getOpenSwapOrders(address _owner, uint256 _skip, uint256 _take, uint256 _head)
        external
        view
        returns (SwapOrderView[] memory, uint256 remain)
    {
        uint256 totalOrder = orderManager.userSwapOrderCount(_owner);
        remain = totalOrder > _head ? totalOrder - _head : 0;
        if (remain == 0 || _skip >= totalOrder) {
            return (new SwapOrderView[](0), remain);
        }

        uint256 startIndex = totalOrder - _skip;
        SwapOrderView[] memory openOrders = new SwapOrderView[](_take);
        uint256 count = 0;

        for (uint256 i = startIndex; i > _head && count < _take; --i) {
            uint256 orderId = orderManager.userSwapOrders(_owner, i - 1);
            SwapOrderView memory order = _parseSwapOrder(orderId);
            if (order.tokenIn != address(0)) {
                openOrders[count] = order;
                count++;
            }
        }

        if (count == _take) {
            return (openOrders, remain);
        }
        // trim empty item
        SwapOrderView[] memory ret = new SwapOrderView[](count);
        for (uint256 i = 0; i < count; i++) {
            ret[i] = openOrders[i];
        }

        return (ret, remain);
    }

    function canExecuteLeverageOrders(uint256[] calldata _orderIds) external view returns (bool[] memory) {
        uint256 count = _orderIds.length;
        bool[] memory rejected = new bool[](count);
        uint256 positionFee = pool.positionFee();
        uint256 liquidationFee = pool.liquidationFee();
        for (uint256 i = 0; i < count; ++i) {
            uint256 orderId = _orderIds[i];
            DataTypes.LeverageOrder memory order = orderManager.leverageOrders(orderId);
            if (order.status != DataTypes.OrderStatus.OPEN) {
                rejected[i] = true;
                continue;
            }

            if (order.expiresAt != 0 && order.expiresAt < block.timestamp) {
                continue;
            }

            DataTypes.UpdatePositionRequest memory request = orderManager.updatePositionRequests(orderId);
            DataTypes.Position memory position = pool.positions(
                PositionLogic.getPositionKey(order.owner, order.indexToken, order.collateralToken, request.side)
            );

            if (request.updateType == DataTypes.UpdatePositionType.DECREASE) {
                if (position.size == 0) {
                    rejected[i] = true;
                    continue;
                }

                if (request.sizeChange < position.size) {
                    // partial close
                    if (position.collateralValue < request.collateral) {
                        rejected[i] = true;
                        continue;
                    }

                    uint256 newSize = position.size - request.sizeChange;
                    uint256 fee = positionFee * request.sizeChange / Constants.PRECISION;
                    uint256 newCollateral = position.collateralValue - request.collateral;
                    newCollateral = newCollateral > fee ? newCollateral - fee : 0;
                    rejected[i] = newCollateral < liquidationFee || newCollateral > newSize; // leverage
                    continue;
                }
            }
        }

        return rejected;
    }

    function canExecuteSwapOrders(uint256[] calldata _orderIds) external view returns (bool[] memory rejected) {
        uint256 count = _orderIds.length;
        rejected = new bool[](count);

        for (uint256 i = 0; i < count; ++i) {
            uint256 orderId = _orderIds[i];
            DataTypes.SwapOrder memory order = orderManager.swapOrders(orderId);
            if (order.status != DataTypes.OrderStatus.OPEN) {
                rejected[i] = true;
                continue;
            }

            ILiquidityCalculator liquidityCalculator = pool.liquidityCalculator();
            address tokenIn = order.tokenIn == ETH ? WETH : order.tokenIn;
            address tokenOut = order.tokenOut == ETH ? WETH : order.tokenOut;
            (uint256 amountOut,,,) = liquidityCalculator.calcSwapOutput(tokenIn, tokenOut, order.amountIn);
            rejected[i] = amountOut < order.minAmountOut;
        }
    }

    function _parseLeverageOrder(uint256 _id) private view returns (LeverageOrderView memory leverageOrder) {
        DataTypes.LeverageOrder memory order = orderManager.leverageOrders(_id);
        if (order.status == DataTypes.OrderStatus.OPEN) {
            DataTypes.UpdatePositionRequest memory request = orderManager.updatePositionRequests(_id);
            leverageOrder.id = _id;
            leverageOrder.indexToken = order.indexToken;
            leverageOrder.collateralToken = order.collateralToken;
            leverageOrder.payToken = order.payToken != address(0) ? order.payToken : order.collateralToken;
            leverageOrder.triggerPrice = order.price;
            leverageOrder.triggerAboveThreshold = order.triggerAboveThreshold;
            leverageOrder.expiresAt = order.expiresAt;
            leverageOrder.side = request.side;
            leverageOrder.updateType = request.updateType;
            leverageOrder.sizeChange = request.sizeChange;
            leverageOrder.collateral = request.collateral;
        }
    }

    function _parseSwapOrder(uint256 _id) private view returns (SwapOrderView memory swapOrder) {
        DataTypes.SwapOrder memory order = orderManager.swapOrders(_id);

        if (order.status == DataTypes.OrderStatus.OPEN) {
            swapOrder.id = _id;
            swapOrder.tokenIn = order.tokenIn;
            swapOrder.tokenOut = order.tokenOut;
            swapOrder.amountIn = order.amountIn;
            swapOrder.minAmountOut = order.minAmountOut;
            swapOrder.price = order.price;
        }
    }
}

pragma solidity 0.8.18;

import "./IOrderManager.sol";
import {DataTypes} from "../lib/DataTypes.sol";

interface IOrderManagerWithStorage is IOrderManager {
    function leverageOrders(uint256 id) external view returns (DataTypes.LeverageOrder memory);
    function updatePositionRequests(uint256 id) external view returns (DataTypes.UpdatePositionRequest memory);
    function swapOrders(uint256 id) external view returns (DataTypes.SwapOrder memory);
    function userLeverageOrderCount(address user) external view returns (uint256);
    function userLeverageOrders(address user, uint256 id) external view returns (uint256 orderId);
    function userSwapOrderCount(address user) external view returns (uint256);
    function userSwapOrders(address user, uint256 id) external view returns (uint256 orderId);
}

pragma solidity >= 0.8.0;

import {IPool} from "./IPool.sol";
import {ILevelOracle} from "./ILevelOracle.sol";
import {ILiquidityCalculator} from "./ILiquidityCalculator.sol";
import {DataTypes} from "../lib/DataTypes.sol";

interface IPoolWithStorage is IPool {
    function oracle() external view returns (ILevelOracle);
    function trancheAssets(address tranche, address token) external view returns (DataTypes.AssetInfo memory);
    function allTranches(uint256 index) external view returns (address);
    function positions(bytes32 positionKey) external view returns (DataTypes.Position memory);
    function isStableCoin(address token) external view returns (bool);
    function poolBalances(address token) external view returns (uint256);
    function feeReserves(address token) external view returns (uint256);
    function borrowIndices(address token) external view returns (uint256);
    function lastAccrualTimestamps(address token) external view returns (uint256);
    function daoFee() external view returns (uint256);
    function riskFactor(address token, address tranche) external view returns (uint256);
    function liquidityCalculator() external view returns (ILiquidityCalculator);
    function targetWeights(address token) external view returns (uint256);
    function totalWeight() external view returns (uint256);
    function virtualPoolValue() external view returns (uint256);
    function isTranche(address tranche) external view returns (bool);
    function positionFee() external view returns (uint256);
    function liquidationFee() external view returns (uint256);
    function positionRevisions(bytes32 key) external view returns (uint256 rev);
}

pragma solidity >= 0.8.0;

interface ILiquidityCalculator {
    function getTrancheValue(address _tranche, bool _max) external view returns (uint256);

    function getPoolValue(bool _max) external view returns (uint256 sum);

    function calcSwapFee(address _token, uint256 _tokenPrice, uint256 _valueChange, bool _isSwapIn)
        external
        view
        returns (uint256);

    function calcAddRemoveLiquidityFee(address _token, uint256 _tokenPrice, uint256 _valueChange, bool _isAdd)
        external
        view
        returns (uint256);

    function calcAddLiquidity(address _tranche, address _token, uint256 _amountIn)
        external
        view
        returns (uint256 outLpAmount, uint256 feeAmount);

    function calcRemoveLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount)
        external
        view
        returns (uint256 outAmountAfterFee, uint256 feeAmount);

    function calcSwapOutput(address _tokenIn, address _tokenOut, uint256 _amountIn)
        external
        view
        returns (uint256 amountOutAfterFee, uint256 feeAmount, uint256 priceIn, uint256 priceOut);

    // ========= Events ===========
    event AddRemoveLiquidityFeeSet(uint256 value);
    event SwapFeeSet(
        uint256 baseSwapFee, uint256 taxBasisPoint, uint256 stableCoinBaseSwapFee, uint256 stableCoinTaxBasisPoint
    );

    // ========= Errors ==========
    error InvalidAddress();
    error ValueTooHigh(uint256 value);
}

pragma solidity >=0.8.0;

import {SafeCast} from "./SafeCast.sol";
import {DataTypes} from "./DataTypes.sol";

library PositionLogic {
    using SafeCast for uint256;

    function getPositionKey(address _owner, address _indexToken, address _collateralToken, DataTypes.Side _side)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_owner, _indexToken, _collateralToken, _side));
    }

    function calcPnl(DataTypes.Side _side, uint256 _positionSize, uint256 _entryPrice, uint256 _indexPrice)
        internal
        pure
        returns (int256)
    {
        if (_positionSize == 0 || _entryPrice == 0) {
            return 0;
        }
        int256 entryPrice = _entryPrice.toInt256();
        int256 positionSize = _positionSize.toInt256();
        int256 indexPrice = _indexPrice.toInt256();
        if (_side == DataTypes.Side.LONG) {
            return ((indexPrice - entryPrice) * positionSize) / entryPrice;
        } else {
            return ((entryPrice - indexPrice) * positionSize) / entryPrice;
        }
    }

    /// @notice calculate new avg entry price when increase position
    /// @dev for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    ///      for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function calcAveragePrice(
        DataTypes.Side _side,
        uint256 _lastSize,
        uint256 _nextSize,
        uint256 _entryPrice,
        uint256 _nextPrice,
        int256 _realizedPnL
    ) internal pure returns (uint256) {
        if (_nextSize == 0) {
            return 0;
        }
        if (_lastSize == 0) {
            return _nextPrice;
        }
        int256 pnl = calcPnl(_side, _lastSize, _entryPrice, _nextPrice) - _realizedPnL;
        int256 nextSize = _nextSize.toInt256();
        int256 divisor = _side == DataTypes.Side.LONG ? nextSize + pnl : nextSize - pnl;
        return divisor <= 0 ? 0 : _nextSize * _nextPrice / uint256(divisor);
    }
}

pragma solidity >=0.8.0;

library DataTypes {
    enum Side {
        LONG,
        SHORT
    }

    enum UpdatePositionType {
        INCREASE,
        DECREASE
    }

    struct UpdatePositionRequest {
        uint256 sizeChange;
        uint256 collateral;
        UpdatePositionType updateType;
        Side side;
    }

    enum OrderType {
        MARKET,
        LIMIT
    }

    enum OrderStatus {
        OPEN,
        FILLED,
        EXPIRED,
        CANCELLED
    }

    struct LeverageOrder {
        address owner;
        address indexToken;
        address collateralToken;
        OrderStatus status;
        bool triggerAboveThreshold;
        address payToken;
        uint256 price;
        uint256 executionFee;
        uint256 submissionBlock;
        uint256 expiresAt;
        uint256 submissionTimestamp;
    }

    struct SwapOrder {
        address owner;
        address tokenIn;
        address tokenOut;
        OrderStatus status;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 price;
        uint256 executionFee;
        uint256 submissionBlock;
        uint256 submissionTimestamp;
    }

    struct AssetInfo {
        /// @notice amount of token deposited (via add liquidity or increase long position)
        uint256 poolAmount;
        /// @notice amount of token reserved for paying out when user decrease long position
        uint256 reservedAmount;
        /// @notice total borrowed (in USD) to leverage
        uint256 guaranteedValue;
        /// @notice total size of all short positions
        uint256 totalShortSize;
        /// @notice average entry price of all short positions
        uint256 averageShortPrice;
    }

    struct Position {
        /// @dev contract size is evaluated in dollar
        uint256 size;
        /// @dev collateral value in dollar
        uint256 collateralValue;
        /// @dev contract size in indexToken
        uint256 reserveAmount;
        /// @dev average entry price
        uint256 entryPrice;
        /// @dev last cumulative interest rate
        uint256 borrowIndex;
    }
}

pragma solidity >= 0.8.0;

library Constants {
    // common precision for fee, tax, interest rate, maintenace margin ratio
    uint256 public constant PRECISION = 1e10;
    uint256 public constant LP_INITIAL_PRICE = 1e12; // fix to 1$
    uint256 public constant MAX_BASE_SWAP_FEE = 1e8; // 1%
    uint256 public constant MAX_TAX_BASIS_POINT = 1e8; // 1%
    uint256 public constant MAX_POSITION_FEE = 1e8; // 1%
    uint256 public constant MAX_LIQUIDATION_FEE = 10e30; // 10$
    uint256 public constant MAX_TRANCHES = 3;
    uint256 public constant MAX_ASSETS = 10;
    uint256 public constant MAX_INTEREST_RATE = 1e7; // 0.1%
    uint256 public constant MAX_MAINTENANCE_MARGIN = 5e8; // 5%
    uint256 public constant USD_VALUE_DECIMAL = 5e8; // 5%
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

pragma solidity >=0.8.0;

import {DataTypes} from "../lib/DataTypes.sol";

interface IOrderManager {
    function placeLeverageOrder(
        DataTypes.UpdatePositionType _updateType,
        DataTypes.Side _side,
        address _indexToken,
        address _collateralToken,
        DataTypes.OrderType _orderType,
        bytes calldata data
    ) external payable returns (uint256 orderId);

    function executeLeverageOrder(uint256 _orderId, address payable _feeTo) external;

    function cancelLeverageOrder(uint256 _orderId) external;

    function placeSwapOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _price,
        bytes calldata _extradata
    ) external payable returns (uint256 orderId);

    function executeSwapOrder(uint256 _orderId, address payable _feeTo) external;

    function cancelSwapOrder(uint256 _orderId) external;

    function swap(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata extradata
    ) external payable;

    // ========== EVENTS =========

    event LeverageOrderPlaced(
        uint256 indexed key, DataTypes.LeverageOrder order, DataTypes.UpdatePositionRequest request
    );
    event LeverageOrderCancelled(uint256 indexed key);
    event LeverageOrderExecuted(
        uint256 indexed key, DataTypes.LeverageOrder order, DataTypes.UpdatePositionRequest request, uint256 fillPrice
    );
    event LeverageOrderExpired(uint256 indexed key);
    event SwapOrderPlaced(uint256 indexed key, DataTypes.SwapOrder order);
    event SwapOrderCancelled(uint256 indexed key);
    event SwapOrderExecuted(uint256 indexed key, uint256 amountIn, uint256 amountOut);
    event Swap(
        address indexed account,
        address indexed tokenIn,
        address indexed tokenOut,
        address pool,
        uint256 amountIn,
        uint256 amountOut
    );
    event OracleChanged(address);
    event PoolSet(address indexed pool);
    event MinLeverageExecutionFeeSet(uint256 leverageExecutionFee);
    event MinSwapExecutionFeeSet(uint256 swapExecutionFee);
    event OrderHookSet(address indexed hook);
    event ExecutorSet(address indexed executor);
    event ControllerSet(address indexed controller);
    event SetEnablePublicExecution(bool isEnable);
    event SetExecutionDelayTime(uint256 delay);

    // ======= ERRORS ========

    error OnlyExecutor();
    error OnlyWeth();
    error ZeroAddress();
    error InvalidExecutionFee();
    error InvalidLeverageTokenPair(address indexToken, address collateralToken);
    error InvalidSwapPair();
    error SameTokenSwap();
    error OnlyOrderOwner();
    error OrderNotOpen();
    error ExecutionDelay();
    error ExecutionFeeTooLow();
    error SlippageReached();
    error ZeroPurchaseAmount();
    error InvalidPurchaseToken();
    error OnlyOwnerOrController();
}

pragma solidity >=0.8.0;

import {DataTypes} from "../lib/DataTypes.sol";

interface IPool {
    struct TokenWeight {
        address token;
        uint256 weight;
    }

    struct RiskConfig {
        address tranche;
        uint256 riskFactor;
    }

    function isValidLeverageTokenPair(
        address _indexToken,
        address _collateralToken,
        DataTypes.Side _side,
        bool _isIncrease
    ) external view returns (bool);

    function canSwap(address _tokenIn, address _tokenOut) external view returns (bool);

    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        DataTypes.Side _side
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        DataTypes.Side _side,
        address _receiver
    ) external;

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to, bytes calldata extradata)
        external;

    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external;

    function removeLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount, uint256 _minOut, address _to)
        external;

    function getPoolAsset(address _token) external view returns (DataTypes.AssetInfo memory);

    function getAllAssets() external view returns (address[] memory tokens, bool[] memory isStable);

    function getAllTranches() external view returns (address[] memory);

    // =========== EVENTS ===========

    event SetOrderManager(address indexed orderManager);
    event IncreasePosition(
        bytes32 indexed key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        DataTypes.Side side,
        uint256 indexPrice,
        uint256 feeValue
    );
    event UpdatePosition(
        bytes32 indexed key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 indexed key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        DataTypes.Side side,
        uint256 indexPrice,
        int256 pnl,
        uint256 feeValue
    );
    event ClosePosition(
        bytes32 indexed key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 indexed key,
        address account,
        address collateralToken,
        address indexToken,
        DataTypes.Side side,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice,
        int256 pnl,
        uint256 feeValue
    );
    event DaoFeeWithdrawn(address indexed token, address recipient, uint256 amount);
    event FeeDistributorSet(address indexed feeDistributor);
    event LiquidityAdded(
        address indexed tranche, address indexed sender, address token, uint256 amount, uint256 lpAmount, uint256 fee
    );
    event LiquidityRemoved(
        address indexed tranche, address indexed sender, address token, uint256 lpAmount, uint256 amountOut, uint256 fee
    );
    event TokenWeightSet(TokenWeight[]);
    event Swap(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        uint256 priceIn,
        uint256 priceOut
    );
    event PositionFeeSet(uint256 positionFee, uint256 liquidationFee);
    event DaoFeeSet(uint256 value);
    event InterestAccrued(address indexed token, uint256 borrowIndex);
    event MaxLeverageChanged(uint256 maxLeverage);
    event TokenWhitelisted(address indexed token);
    event TokenDelisted(address indexed token);
    event OracleChanged(address indexed oldOracle, address indexed newOracle);
    event InterestRateSet(uint256 interestRate, uint256 stableCoinInterestRate, uint256 interval);
    event InterestRateModelSet(address indexed token, address interestRateModel);
    event PoolHookChanged(address indexed hook);
    event TrancheAdded(address indexed lpToken);
    event TokenRiskFactorUpdated(address indexed token);
    event PnLDistributed(address indexed asset, address indexed tranche, int256 pnl);
    event MaintenanceMarginChanged(uint256 ratio);
    event MaxGlobalPositionSizeSet(address indexed token, uint256 maxLongRatios, uint256 maxShortSize);
    event PoolControllerChanged(address controller);
    event AssetRebalanced();
    event LiquidityCalculatorSet(address feeModel);
    event VirtualPoolValueRefreshed(uint256 value);
    event MaxLiquiditySet(address token, uint256 value);

    // ========== ERRORS ==============

    error UpdateCauseLiquidation();
    error InvalidLeverageTokenPair();
    error InvalidLeverage();
    error InvalidPositionSize();
    error OrderManagerOnly();
    error UnknownToken();
    error AssetNotListed();
    error InsufficientPoolAmount();
    error ReserveReduceTooMuch();
    error SlippageExceeded();
    error ValueTooHigh();
    error InvalidInterval();
    error PositionNotLiquidated();
    error ZeroAmount();
    error ZeroAddress();
    error RequireAllTokens();
    error DuplicateToken();
    error FeeDistributorOnly();
    error InvalidMaxLeverage();
    error InvalidSwapPair();
    error InvalidTranche();
    error TrancheAlreadyAdded();
    error RemoveLiquidityTooMuch();
    error CannotDistributeToTranches();
    error PositionNotExists();
    error MaxNumberOfTranchesReached();
    error TooManyTokenAdded();
    error AddLiquidityNotAllowed();
    error MaxGlobalShortSizeExceeded();
    error NotApplicableForStableCoin();
    error MaxLiquidityReach();
}

pragma solidity >= 0.8.0;

interface ILevelOracle {
    function getPrice(address token, bool max) external view returns (uint256);
    function getMultiplePrices(address[] calldata tokens, bool max) external view returns (uint256[] memory);
}

pragma solidity >=0.8.0;

library SafeCast {
    error Overflow();

    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert Overflow();
        }
        return uint256(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert Overflow();
        }
        return int256(value);
    }
}