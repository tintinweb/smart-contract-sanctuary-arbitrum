// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import {IOrderHook} from "../interfaces/IOrderHook.sol";
import {IReferralController} from "../interfaces/IReferralController.sol";
import {DataTypes} from "../lib/DataTypes.sol";
import "../interfaces/IOrderManagerWithStorage.sol";

contract OrderHook is IOrderHook {
    address public immutable orderManager;
    IReferralController public referralController;

    modifier onlyOrderManager() {
        _requireOrderManager();
        _;
    }

    constructor(address _orderManager, address _referralController) {
        require(_orderManager != address(0), "invalid address");
        require(_referralController != address(0), "invalid address");
        orderManager = _orderManager;
        referralController = IReferralController(_referralController);
    }

    function postPlaceOrder(uint256 _orderId, bytes calldata _extradata) external onlyOrderManager {
        if (_extradata.length == 0) {
            return;
        }
        DataTypes.LeverageOrder memory order = IOrderManagerWithStorage(orderManager).leverageOrders(_orderId);
        address referrer = abi.decode(_extradata, (address));
        _setReferrer(order.owner, referrer);
    }

    function preSwap(address _trader, bytes calldata _extradata) external onlyOrderManager {
        if (_extradata.length == 0) {
            return;
        }
        address referrer = abi.decode(_extradata, (address));
        _setReferrer(_trader, referrer);
    }

    function postPlaceSwapOrder(uint256 _swapOrderId, bytes calldata _extradata) external onlyOrderManager {
        if (_extradata.length == 0) {
            return;
        }
        DataTypes.SwapOrder memory order = IOrderManagerWithStorage(orderManager).swapOrders(_swapOrderId);
        address trader = order.owner;
        address referrer = abi.decode(_extradata, (address));
        _setReferrer(trader, referrer);
    }

    function _setReferrer(address _trader, address _referrer) internal {
        if (_referrer != address(0)) {
            referralController.setReferrer(_trader, _referrer);
        }
    }

    function _requireOrderManager() internal view {
        require(msg.sender == orderManager, "!orderManager");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.0;

interface IOrderHook {
    function postPlaceOrder(uint256 orderId, bytes calldata extradata) external;

    function preSwap(address sender, bytes calldata extradata) external;

    function postPlaceSwapOrder(uint256 swapOrderId, bytes calldata extradata) external;
}

pragma solidity 0.8.18;

interface IReferralController {
    function updateFee(address _trader, uint256 _value) external;
    function setReferrer(address _trader, address _referrer) external;
    function setPoolHook(address _poolHook) external;
    function setOrderHook(address _orderHook) external;
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