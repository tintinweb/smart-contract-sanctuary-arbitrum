// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./interfaces/IPriceManager.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPositionKeeper.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/ITriggerOrderManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


import "./BasePosition.sol";
import "./interfaces/IPositionRouter.sol";
import {Constants} from "../constants/Constants.sol";
import {Position, TriggerStatus, TriggerOrder} from "../constants/Structs.sol";

contract TriggerOrderManager is ITriggerOrderManager, BasePosition, ReentrancyGuard {
    address public router;

    mapping(bytes32 => TriggerOrder) public triggerOrders;

    event SetRouter(address router);
    event ExecuteTriggerOrders(
        bytes32 key,
        uint256[] tpPrices,
        uint256[] slPrices,
        uint256[] tpAmountPercents,
        uint256[] slAmountPercents,
        uint256[] tpTriggeredAmounts,
        uint256[] slTriggeredAmounts,
        TriggerStatus status
    );
    event UpdateTriggerOrders(
        bytes32 key,
        uint256[] tpPrices,
        uint256[] slPrices,
        uint256[] tpAmountPercents,
        uint256[] slAmountPercents,
        uint256[] tpTriggeredAmounts,
        uint256[] slTriggeredAmounts,
        TriggerStatus status,
        bool isLastSynchronizePrice
    );
    event UpdateTriggerStatus(bytes32 key, TriggerStatus status);

    modifier onlyPositionaHandler() {
        _validatePositionInitialized();
        require(msg.sender == address(positionHandler), "Forbidden: Not positionHandler");
        _;
    }

    constructor(address _settingsManager, address _priceManager) BasePosition(_settingsManager, _priceManager) {

    }

    //Config functions
    function setPositionRouter(address _router) external onlyOwner {
        require(Address.isContract(_router), "Invalid contract address, router");
        router = _router;
        emit SetRouter(_router);
    }
    //End config functions

    function triggerPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        _validatePositionKeeper();
        _validatePositionHandler();
        _validateRouter();
        require(settingsManager.isTradable(_indexToken), "Invalid indexToken");
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(key);
        require(msg.sender == position.owner || _isExecutor(msg.sender), "Invalid positionOwner");
        address[] memory path;
        bool isFastExecute;
        uint256[] memory prices;
        uint256 txType;

        if (position.size == 0) {
            //Trigger for creating position
            PrepareTransaction memory txn = IPositionRouter(router).getTransaction(key);
            require(txn.status == TRANSACTION_STATUS_PENDING, "Invalid txStatus");
            txType = _getTxTypeFromPositionType(order.positionType);
            require(_isDelayPosition(txType), "Invalid delayOrder");
            uint256[] memory params = IPositionRouter(router).getParams(key, txType);
            require(params.length > 0, "Invalid triggerParams");

            path = IPositionRouter(router).getPath(key, txType);
            require(_indexToken == path[0], "Invalid indexToken");
            (isFastExecute, prices) = _getPricesAndCheckFastExecute(path);

            if (!isFastExecute) {
                revert("This delay position trigger has already pending");
            }
        }  else {
            //Trigger for addTrailingStop or updateTriggerOrders
            path = positionKeeper.getPositionFinalPath(key);
            (isFastExecute, prices) = _getPricesAndCheckFastExecute(path);
            txType = order.positionType == POSITION_TRAILING_STOP ? ADD_TRAILING_STOP : TRIGGER_POSITION;

            if (txType == ADD_TRAILING_STOP && !isFastExecute) {
                revert("This trigger has already pending");
            }
        }

        require(path.length > 0 && path.length == prices.length, "Invalid arrayLength");
        IPositionRouter(router).triggerPosition(
            key,
            isFastExecute,
            txType,
            path,
            prices
        );
    }

    function cancelTriggerOrders(address _token, bool _isLong, uint256 _posId) external {
        bytes32 key = _getPositionKey(msg.sender, _token, _isLong, _posId);
        TriggerOrder storage order = triggerOrders[key];
        require(order.status == TriggerStatus.OPEN, "TriggerOrder was cancelled");
        order.status = TriggerStatus.CANCELLED;
        emit UpdateTriggerStatus(key, order.status);
    }

    function executeTriggerOrders(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external override onlyPositionaHandler returns (bool, uint256) {
        bytes32 key = _getPositionKey(_account, _token, _isLong, _posId);
        TriggerOrder storage order = triggerOrders[key];
        Position memory position = positionKeeper.getPosition(key);
        require(order.status == TriggerStatus.OPEN, "TriggerOrder not Open");
        uint256 price = _indexPrice == 0 ? priceManager.getLastPrice(_token) : _indexPrice;

        for (bool tp = true; ; tp = false) {
            uint256[] storage prices = tp ? order.tpPrices : order.slPrices;
            uint256[] storage triggeredAmounts = tp ? order.tpTriggeredAmounts : order.slTriggeredAmounts;
            uint256[] storage amountPercents = tp ? order.tpAmountPercents : order.slAmountPercents;
            uint256 closeAmountPercent;

            for (uint256 i = 0; i != prices.length && closeAmountPercent < BASIS_POINTS_DIVISOR; ++i) {
                bool pricesAreUpperBounds = tp ? _isLong : !_isLong;

                if (triggeredAmounts[i] == 0 && (pricesAreUpperBounds ? prices[i] <= price : price <= prices[i])) {
                    closeAmountPercent += amountPercents[i];
                    triggeredAmounts[i] = (position.size * amountPercents[i]) / BASIS_POINTS_DIVISOR;
                }
            }

            if (closeAmountPercent != 0) {
                emit ExecuteTriggerOrders(
                    key,
                    order.tpPrices,
                    order.slPrices,
                    order.tpAmountPercents,
                    order.slAmountPercents,
                    order.tpTriggeredAmounts,
                    order.slTriggeredAmounts,
                    order.status
                );

                if (closeAmountPercent >= BASIS_POINTS_DIVISOR) {
                    order.status = TriggerStatus.TRIGGERED;
                    return (true, BASIS_POINTS_DIVISOR);
                }
                
                return (true, closeAmountPercent);
            }

            if (!tp) {
                break;
            }
        }

        return (false, 0);
    }

    function updateTriggerOrders(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _tpPrices,
        uint256[] memory _slPrices,
        uint256[] memory _tpAmountPercents,
        uint256[] memory _slAmountPercents,
        uint256[] memory _tpTriggeredAmounts,
        uint256[] memory _slTriggeredAmounts
    ) external payable nonReentrant {
        _validatePositionInitialized();
        bytes32 key = _getPositionKey(msg.sender, _indexToken, _isLong, _posId);
        Position memory position = positionKeeper.getPosition(msg.sender, _indexToken, _isLong, _posId);
        require(position.size > 0, "Zero positionSize");
        require(position.owner == msg.sender, "Invalid positionOwner");
        payable(settingsManager.getFeeManager()).transfer(msg.value);
        (bool isFastExecute, uint256 indexPrice) = _getPriceAndCheckFastExecute(_indexToken);
        require(_validateTriggerOrdersData(
                _isLong,
                indexPrice,
                _tpPrices,
                _slPrices,
                _tpTriggeredAmounts,
                _slTriggeredAmounts), 
        "Invalid triggerData");

        if (triggerOrders[key].tpPrices.length + triggerOrders[key].slPrices.length < _tpPrices.length + _slPrices.length) {
            require(msg.value == settingsManager.triggerGasFee(), "Invalid triggerGasFee");
        }

        triggerOrders[key] = TriggerOrder({
                key: key,
                isLong: _isLong,
                tpTriggeredAmounts: _tpTriggeredAmounts,
                slTriggeredAmounts: _slTriggeredAmounts,
                tpPrices: _tpPrices,
                tpAmountPercents: _tpAmountPercents,
                slPrices: _slPrices,
                slAmountPercents: _slAmountPercents,
                status: TriggerStatus.OPEN
            });

        emit UpdateTriggerOrders(
            key,
            _tpPrices,
            _slPrices,
            _tpAmountPercents,
            _slAmountPercents,
            _tpTriggeredAmounts,
            _slTriggeredAmounts,
            TriggerStatus.OPEN,
            isFastExecute
        );
    }

    function getTriggerOrderInfo(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (TriggerOrder memory) {
        return _getTriggerOrderInfo(_getPositionKey(_account, _indexToken, _isLong, _posId));
    }

    function getTriggerOrderInfo(bytes32 _key) external view returns (TriggerOrder memory) {
        return _getTriggerOrderInfo(_key);
    }

    function _getTriggerOrderInfo(bytes32 _key) internal view returns (TriggerOrder memory) {
        return triggerOrders[_key];
    }

    function validateTPSLTriggers(
        bytes32 _key,
        uint256 _indexPrice
    ) external view override returns (bool) {
        return _validateTPSLTriggers(
            _key,
            _indexPrice
        );
    }

    function validateTPSLTriggers(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external view returns (bool) {
        return _validateTPSLTriggers(_getPositionKey(_account, _token, _isLong, _posId), _indexPrice);
    }

    function _validateTPSLTriggers(
        bytes32 _key,
        uint256 _indexPrice
    ) internal view returns (bool) {
        require(_indexPrice > 0, "Invalid indexPrice");
        (address owner, , bool isLong, ) = positionKeeper.getBasePosition(_key);
        require(owner != address(0), "Invalid pOwner");
        TriggerOrder storage order = triggerOrders[_key];

        if (order.status != TriggerStatus.OPEN) {
            return false;
        }

        for (bool tp = true; ; tp = false) {
            uint256[] storage prices = tp ? order.tpPrices : order.slPrices;
            uint256[] storage triggeredAmounts = tp ? order.tpTriggeredAmounts : order.slTriggeredAmounts;
            uint256[] storage amountPercents = tp ? order.tpAmountPercents : order.slAmountPercents;
            uint256 closeAmountPercent;
            
            for (uint256 i = 0; i != prices.length && closeAmountPercent < BASIS_POINTS_DIVISOR; ++i) {
                bool pricesAreUpperBounds = tp ? isLong : !isLong;
                
                if (triggeredAmounts[i] == 0 && (pricesAreUpperBounds ? prices[i] <= _indexPrice : _indexPrice <= prices[i])) {
                    closeAmountPercent += amountPercents[i];
                }
            }

            if (closeAmountPercent != 0) {
                return true;
            }

            if (!tp) {
                break;
            }
        }

        return false;
    }

    function validateTriggerOrdersData(
        bool _isLong,
        uint256 _indexPrice,
        uint256[] memory _tpPrices,
        uint256[] memory _slPrices,
        uint256[] memory _tpTriggeredAmounts,
        uint256[] memory _slTriggeredAmounts
    ) external pure returns (bool) {
        return _validateTriggerOrdersData(
            _isLong,
            _indexPrice,
            _tpPrices,
            _slPrices,
            _tpTriggeredAmounts,
            _slTriggeredAmounts
        );
    }

    function _validateTriggerOrdersData(
        bool _isLong,
        uint256 _indexPrice,
        uint256[] memory _tpPrices,
        uint256[] memory _slPrices,
        uint256[] memory _tpTriggeredAmounts,
        uint256[] memory _slTriggeredAmounts
    ) internal pure returns (bool) {
        for (bool tp = true; ; tp = false) {
            uint256[] memory prices = tp ? _tpPrices : _slPrices;
            uint256[] memory triggeredAmounts = tp ? _tpTriggeredAmounts : _slTriggeredAmounts;
            bool pricesAreUpperBounds = tp ? _isLong : !_isLong;
            
            for (uint256 i = 0; i < prices.length; ++i) {
                if (triggeredAmounts[i] == 0 && (_indexPrice < prices[i]) != pricesAreUpperBounds) {
                    return false;
                }
            }

            if (!tp) {
                break;
            }
        }

        return true;
    }

    function _validatePositionInitialized() internal view {
        require(address(positionHandler) != address(0), "PositionHandler not initialized");
        require(address(positionKeeper) != address(0), "PositionKeeper not initialized");
    }

    function _validateRouter() internal view {
        require(router != address(0), "PositionRouter not initialized");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./BaseConstants.sol";
import "./BasePositionConstants.sol";

contract Constants is BaseConstants, BasePositionConstants {
    address public constant ZERO_ADDRESS = address(0);

    uint8 public constant ORDER_FILLED = 1;

    uint8 public constant ORDER_NOT_FILLED = 0;

    uint8 public constant STAKING_PID_FOR_CHARGE_FEE = 1;

    uint256 public constant DEFAULT_FUNDING_RATE_FACTOR = 100;
    
    uint256 public constant DEFAULT_MAX_OPEN_INTEREST = 10000000000 * PRICE_PRECISION;

    uint256 public constant FUNDING_RATE_PRECISION = 1000000;
    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;
    
    uint256 public constant MAX_DEPOSIT_FEE = 10000; // 10%
    uint256 public constant MAX_DELTA_TIME = 24 hours;
    uint256 public constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 public constant MAX_FEE_REWARD_BASIS_POINTS = BASIS_POINTS_DIVISOR; // 100%
    uint256 public constant MAX_FUNDING_RATE_FACTOR = 10000; // 1%
    uint256 public constant MAX_FUNDING_RATE_INTERVAL = 48 hours;
    uint256 public constant MAX_LIQUIDATION_FEE_USD = 100 * PRICE_PRECISION; // 100 USD
    uint256 public constant MAX_STAKING_FEE = 10000; // 10%
    uint256 public constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 public constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 public constant MAX_VESTING_DURATION = 700 days;
    uint256 public constant MIN_FUNDING_RATE_INTERVAL = 1 hours;
    uint256 public constant MIN_LEVERAGE = 10000; // 1x
    uint256 public constant MIN_FEE_REWARD_BASIS_POINTS = 50000; // 50%

    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;

    function checkSlippage(
        bool isLong,
        uint256 expectedMarketPrice,
        uint256 slippageBasisPoints,
        uint256 actualMarketPrice
    ) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <=
                    (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR,
                "Long position: Check slippage exceeded"
            );
        } else {
            require(
                (expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
                    actualMarketPrice,
                "Short position: Check slippage exceeded"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IPriceManager {
    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _indexPrice
    ) external view returns (bool, uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getLatestSynchronizedPrice(address _token) external view returns (uint256, uint256, bool);

    function getLatestSynchronizedPrices(address[] memory _tokens) external view returns (uint256[] memory, bool);

    function setLatestPrice(address _token, uint256 _latestPrice) external;

    function setLatestPrices(address[] memory _tokens, uint256[] memory _prices) external;

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _nextPrice
    ) external view returns (uint256);

    function isForex(address _token) external view returns (bool);

    function maxLeverage(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);

    function getTokenDecimals(address _token) external view returns(uint256);

    function floorTokenAmount(uint256 _amount, address _token) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/ISettingsManager.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPositionKeeper.sol";

import "../constants/PositionConstants.sol";
import "../access/BaseExecutor.sol";

contract BasePosition is PositionConstants, BaseExecutor {
    ISettingsManager public settingsManager;
    IPriceManager public priceManager;
    IPositionHandler public positionHandler;
    IPositionKeeper public positionKeeper;

    constructor(
        address _settingsManager, 
        address _priceManager
    ) {
        settingsManager = ISettingsManager(_settingsManager);
        priceManager = IPriceManager(_priceManager);
    }

    event SetSettingsManager(address settingsManager);
    event SetPriceManager(address priceManager);
    event SetPositionHandler(address positionHandler);
    event SetPositionKeeper(address positionKeeper);

    //Config functions
    function setPositionHandler(address _positionHandler) external onlyOwner {
        _setPositionHandler(_positionHandler);
    }

    function setPositionKeeper(address _positionKeeper) external onlyOwner {
        _setPositionKeeper(_positionKeeper);
    }

    function setSettingsManager(address _settingsManager) external onlyOwner {
        _setSettingsManager(_settingsManager);
    }

    function setPriceManager(address _priceManager) external onlyOwner {
        _setPriceManager(_priceManager);
    }

    //End config functions

    function _setSettingsManager(address _settingsManager) internal {
        settingsManager = ISettingsManager(_settingsManager);
        emit SetSettingsManager(_settingsManager);
    }

    function _setPriceManager(address _priceManager) internal {
        priceManager = IPriceManager(_priceManager);
        emit SetPriceManager(_priceManager);
    }

    function _setPositionHandler(address _positionHandler) internal {
        positionHandler = IPositionHandler(_positionHandler);
        emit SetPositionHandler(_positionHandler);
    }

    function _setPositionKeeper(address _positionKeeper) internal {
        positionKeeper = IPositionKeeper(_positionKeeper);
        emit SetPositionKeeper(_positionKeeper);
    }

    function _prevalidate(address _indexToken) internal view {
        _validateInitialized();
        require(settingsManager.marketOrderEnabled(), "SM/MOD"); //Market order disabled
        require(settingsManager.isTradable(_indexToken), "SM/NAT"); //Not tradable token
    }

    function _validateInitialized() internal view {
        _validateSettingsManager();
        _validatePriceManager();
        _validatePositionHandler();
        _validatePositionKeeper();
    }

    function _validateSettingsManager() internal view {
        require(address(settingsManager) != address(0), "NI/SM"); //SettingsManager not initialized
    }

    function _validatePriceManager() internal view {
        require(address(priceManager) != address(0), "NI/PM"); //PriceManager not initialized
    }

    function _validatePositionHandler() internal view {
        require(address(positionHandler) != address(0), "NI/PH"); //PositionHandler not initialized
    }

    function _validatePositionKeeper() internal view {
        require(address(positionKeeper) != address(0), "NI/PK"); //PositionKeeper not intialized
    }

    function _getPriceAndCheckFastExecute(address _indexToken) internal view returns (bool, uint256) {
        (uint256 price, , bool isFastExecute) = priceManager.getLatestSynchronizedPrice(_indexToken);
        return (isFastExecute, price);
    }

    function _getPricesAndCheckFastExecute(address[] memory _path) internal view returns (bool, uint256[] memory) {
        require(_path.length >= 1 && _path.length <= 3, "IVLPTL");
        bool isFastExecute;
        uint256[] memory prices;

        {
            (prices, isFastExecute) = priceManager.getLatestSynchronizedPrices(_path);
        }

        return (isFastExecute, prices);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT,
    TRAILING_STOP
}

enum OrderStatus {
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    OPEN,
    TRIGGERED,
    CANCELLED
}

enum DataType {
    POSITION,
    ORDER
}

struct OrderInfo {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 pendingSize;
    uint256 pendingCollateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    address collateralToken;
}

struct Position {
    address owner;
    address indexToken;
    bool isLong;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    uint256 entryFundingRate;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
    uint256 posId;
    uint256 openedFee;
}

struct TriggerOrder {
    bytes32 key;
    bool isLong;
    uint256[] slPrices;
    uint256[] slAmountPercents;
    uint256[] slTriggeredAmounts;
    uint256[] tpPrices;
    uint256[] tpAmountPercents;
    uint256[] tpTriggeredAmounts;
    TriggerStatus status;
}

struct ConvertOrder {
    uint256 index;
    address indexToken;
    address sender;
    address recipient;
    uint256 amountIn;
    uint256 amountOut;
    uint256 state;
}

struct SwapPath {
    address pairAddress;
    uint256 fee;
}

struct SwapRequest {
    bytes32 orderKey;
    address tokenIn;
    address pool;
    uint256 amountIn;
}

struct PrepareTransaction {
    uint256 txType;
    uint256 startTime;

    /*
    uint256 public constant TRANSACTION_STATUS_NONE = 0;
    uint256 public constant TRANSACTION_STATUS_PENDING = 1;
    uint256 public constant TRANSACTION_STATUS_EXECUTED = 2;
    uint256 public constant TRANSACTION_STATUS_EXECUTE_REVERTED = 3;
    */
    uint256 status;
}

struct TxDetail {
    uint256[] params;
    address[] path;
}

struct VaultBond {
    address owner;
    address token; //Collateral token
    uint256 amount; //Collateral amount
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {
    Position, 
    OrderInfo, 
    OrderType, 
    DataType, 
    OrderStatus
} from "../../constants/Structs.sol";

interface IPositionKeeper {
    function leverages(bytes32 _key) external returns (uint256);

    function globalAmounts(address _token, bool _isLong) external view returns (uint256);

    function openNewPosition(
        bytes32 _key,
        bool _isLong, 
        uint256 _posId,
        uint256 _collateralIndex,
        address[] memory _path,
        uint256[] memory _params,
        bytes memory _data
    ) external;

    function unpackAndStorage(bytes32 _key, bytes memory _data, DataType _dataType) external;

    function deletePosition(bytes32 _key) external;

    function deleteOrder(bytes32 _key) external;

    function deletePositions(bytes32 _key) external;

    //Emit event functions
    function emitAddPositionEvent(
        bytes32 key, 
        bool confirmDelayStatus, 
        uint256 collateral, 
        uint256 size
    ) external;

    function emitAddOrRemoveCollateralEvent(
        bytes32 _key,
        bool _isPlus,
        uint256 _amount,
        uint256 _amountInUSD,
        uint256 _reserveAmount,
        uint256 _collateral,
        uint256 _size
    ) external;

    function emitAddTrailingStopEvent(bytes32 _key, uint256[] memory data) external;

    function emitUpdateTrailingStopEvent(bytes32 _key, uint256 _stpPrice) external;

    function emitUpdateOrderEvent(bytes32 _key, uint256 _positionType, OrderStatus _orderStatus) external;

    function emitConfirmDelayTransactionEvent(
        bytes32 _key,
        bool _confirmDelayStatus,
        uint256 _collateral,
        uint256 _size,
        uint256 _feeUsd
    ) external;

    function emitPositionExecutedEvent(
        bytes32 _key,
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _prices
    ) external;

    function emitIncreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _fee,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external;

    function emitDecreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _fee,
        uint256 _collateralDelta,
        uint256 _sizeDelta
    ) external;

    function emitClosePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function emitLiquidatePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _fee
    ) external;

    function updateGlobalShortData(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _markPrice,
        bool _isIncrease
    ) external;

    //View functions
    function getPositions(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (Position memory, OrderInfo memory);

    function getPositions(bytes32 _key) external view returns (Position memory, OrderInfo memory);

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view returns (Position memory);

    function getPosition(bytes32 _key) external view returns (Position memory);

    function getOrder(bytes32 _key) external view returns (OrderInfo memory);

    function getPositionOpenedFee(bytes32 _key) external view returns (uint256);

    function getPositionSize(bytes32 _key) external view returns (uint256);

    function getPositionOwner(bytes32 _key) external view returns (address);

    function getPositionIndexToken(bytes32 _key) external view returns (address);

    function getPositionCollateralToken(bytes32 _key) external view returns (address);

    function getPositionFinalPath(bytes32 _key) external view returns (address[] memory);

    function lastPositionIndex(address _account) external view returns (uint256);

    function getBasePosition(bytes32 _key) external view returns (address, address, bool, uint256);

    function getPositionType(bytes32 _key) external view returns (bool);

    function getGlobalShortDelta(address _token) external view returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ITriggerOrderManager {
    function executeTriggerOrders(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external returns (bool, uint256);

    function validateTPSLTriggers(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external returns (bool);

    function validateTPSLTriggers(
        bytes32 _key,
        uint256 _indexPrice
    ) external view returns (bool);

    function triggerPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external;

    function validateTriggerOrdersData(
        bool _isLong,
        uint256 _indexPrice,
        uint256[] memory _tpPrices,
        uint256[] memory _slPrices,
        uint256[] memory _tpTriggeredAmounts,
        uint256[] memory _slTriggeredAmounts
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IPositionHandler {
    function openNewPosition(
        bytes32 _key,
        bool _isLong, 
        uint256 _posId,
        uint256 _collateralIndex,
        bytes memory _data,
        uint256[] memory _params,
        uint256[] memory _prices, 
        address[] memory _path,
        bool _isFastExecute,
        bool _isNewPosition
    ) external;

    function modifyPosition(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType, 
        bytes memory _data,
        address[] memory path,
        uint256[] memory prices
    ) external;

    // function setPriceAndExecuteInBatch(
    //     address[] memory _path,
    //     uint256[] memory _prices,
    //     bytes32[] memory _keys, 
    //     uint256[] memory _txTypes
    // ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {PrepareTransaction, TxDetail, OrderType} from "../../constants/Structs.sol";

interface IPositionRouter {
    /*
    @dev: Open new position.
    Path length must between 2 to 3 which:
        path[0] is approval tradable (isTradable)
        If enableNonStableCollateral is true:
            + Path lengths must be 2, which path[1] is approval stable (isStable) or approval collateral (isCollateral)
        Else: 
            + Path lengths must be 2, which path[1] isStable
            + Path length must be 3, which path[1] isCollateral and path[2] isStable
    Params length must be 8.
        param[0] is mark price (for market type only, other type use 0)
        param[1] is slippage (for market type only, other type use 0)
        param[2] is limit price (for limit/stop/stop_limit type only, market use 0)
        param[3] is stop price (for limit/stop/stop_limit type only, market use 0)
        param[4] is collateral amount
        param[5] is size (collateral * leverage)
        param[6] is deadline (for market type only, other type use 0)
        param[7] is min stable received if swap is required
    */
    function openNewPosition(
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    /*
    @dev: Add or remove collateral.
    + AddCollateral: _isPlus is true, 
        Params length must be 1, which params[0] is collateral token amount
    + RemoveCollateral: _isPlus is false,
        Params length must be 2, which params[0] is sizeDelta in USD, params[1] is deadline
    Path is same as openNewPosition
    */
    function addOrRemoveCollateral(
        bool _isLong,
        uint256 _posId,
        bool _isPlus,
        uint256[] memory _params,
        address[] memory _path
    ) external;

    /*
    @dev: Add to exist position.
    Params length must be 3, which:
        params[0] is collateral token amount,
        params[1] is collateral size (params[0] x leverage)
    path is same as openNewPosition
    */
    function addPosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    /*
    @dev: Add trailing stop.
    */
    function addTrailingStop(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    /*
    @dev: Update trailing stop.
    */
    function updateTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _indexPrice
    ) external;

    /*
    @dev: Cancel pending order, not allow to cancel market order
    */
    function cancelPendingOrder(
        address _indexToken, 
        bool _isLong, 
        uint256 _posId
    ) external;

    /*
    @dev: Close position
    Params length must be 2, which: 
        [0] is closing size delta in USD,
        [1] is deadline
    Path length must between 2 or 3, which: 
        [0] is indexToken, 
        [1] or [2] must be isStable or isCollateral (same logic enableNonStableCollateral)
    */
    function closePosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external;

    function triggerPosition(
        bytes32 _key,
        bool _isFastExecute,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) external;

    /*
    @dev: Execute delay transaction, can only call by executor/positionHandler
    */
    function execute(
        bytes32 _key, 
        uint256 _txType,
        uint256[] memory _prices
    ) external;

    /*
    @dev: Revert execution when trying to execute transaction not success, can only call by executor/positionHandler
    */
    function revertExecution(
        bytes32 _key, 
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices, 
        string memory err
    ) external;

    function clearPrepareTransaction(bytes32 _key, uint256 _txType) external;

    //View functions
    function getExecutePath(bytes32 _key, uint256 _txType) external view returns (address[] memory);

    function getPath(bytes32 _key, uint256 _txType) external view returns (address[] memory);

    function getParams(bytes32 _key, uint256 _txType) external view returns (uint256[] memory);

    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory);

    function getTxDetail(bytes32 _key, uint256 _txType) external view returns (TxDetail memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ISettingsManager {
    function decreaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function updateCumulativeFundingRate(address _token, bool _isLong) external;

    function openInterestPerAsset(address _token) external view returns (uint256);

    function openInterestPerSide(bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function collectMarginFees(
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function getFeeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function fundingRateFactor(address _token, bool _isLong) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isCollateral(address _token) external view returns (bool);

    function isTradable(address _token) external view returns (bool);

    function isStable(address _token) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token, bool _isLong) external view returns (uint256);

    function maxPriceUpdatedDelay() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);
    
    function pauseForexForCloseTime() external view returns (bool);

    function priceMovementPercent() external view returns (uint256);

    function referFee() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function unstakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function positionDefaultSlippage() external view returns (uint256);

    function setPositionDefaultSlippage(uint256 _slippage) external;

    function isActive() external view returns (bool);

    function isEnableNonStableCollateral() external view returns (bool);

    function isEnableConvertRUSD() external view returns (bool);

    function isEnableUnstaking() external view returns (bool);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;

    function isApprovalCollateralToken(address _token) external view returns (bool);

    function isApprovalCollateralToken(address _token, bool _raise) external view returns (bool);

    function isEmergencyStop() external view returns (bool);

    function validateCollateralPathAndCheckSwap(address[] memory _collateralPath) external view returns (bool);

    function maxProfitPercent() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract BaseConstants {
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals

    uint256 public constant DEFAULT_ROLP_PRICE = 100000; //1 USDC

    uint256 public constant ROLP_DECIMALS = 18;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract BasePositionConstants {
    //Constant params
    // uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals
    // uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;

    uint256 public constant CREATE_POSITION_MARKET = 1;
    uint256 public constant CREATE_POSITION_LIMIT = 2;
    uint256 public constant CREATE_POSITION_STOP_MARKET = 3;
    uint256 public constant CREATE_POSITION_STOP_LIMIT = 4;
    uint256 public constant ADD_COLLATERAL = 5;
    uint256 public constant REMOVE_COLLATERAL = 6;
    uint256 public constant ADD_POSITION = 7;
    uint256 public constant CONFIRM_POSITION = 8;
    uint256 public constant ADD_TRAILING_STOP = 9;
    uint256 public constant UPDATE_TRAILING_STOP = 10;
    uint256 public constant TRIGGER_POSITION = 11;
    uint256 public constant UPDATE_TRIGGER_POSITION = 12;
    uint256 public constant CANCEL_PENDING_ORDER = 13;
    uint256 public constant CLOSE_POSITION = 14;
    uint256 public constant LIQUIDATE_POSITION = 15;
    uint256 public constant REVERT_EXECUTE = 16;
    //uint public constant STORAGE_PATH = 99; //Internal usage for router only

    uint256 public constant TRANSACTION_STATUS_NONE = 0;
    uint256 public constant TRANSACTION_STATUS_PENDING = 1;
    uint256 public constant TRANSACTION_STATUS_EXECUTED = 2;
    uint256 public constant TRANSACTION_STATUS_EXECUTE_REVERTED = 3;
    //End constant params

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    function _getTxTypeFromPositionType(uint256 _positionType) internal pure returns (uint256) {
        if (_positionType == POSITION_LIMIT) {
            return CREATE_POSITION_LIMIT;
        } else if (_positionType == POSITION_STOP_MARKET) {
            return CREATE_POSITION_STOP_MARKET;
        } else if (_positionType == POSITION_STOP_LIMIT) {
            return CREATE_POSITION_STOP_LIMIT;
        } else {
            revert("IVLPST"); //Invalid positionType
        }
    } 

    function _isDelayPosition(uint256 _txType) internal pure returns (bool) {
        return _txType == CREATE_POSITION_STOP_LIMIT
            || _txType == CREATE_POSITION_STOP_MARKET
            || _txType == CREATE_POSITION_LIMIT;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseExecutor is Ownable {
    mapping(address => bool) public executors;

    event SetExecutor(address indexed account, bool hasAccess);

    function setExecutor(address _account, bool _hasAccess) onlyOwner external {
        executors[_account] = _hasAccess;
        emit SetExecutor(_account, _hasAccess);
    }

    function _isExecutor(address _account) internal view returns (bool) {
        return executors[_account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./BasePositionConstants.sol";

contract PositionConstants is BasePositionConstants {
    //Constant params
    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint8 public constant ORDER_FILLED = 1;

    uint256 public constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 public constant TRAILING_STOP_TYPE_PERCENT = 1;

    uint256 public constant LIQUIDATE_NONE_EXCEED = 0;
    uint256 public constant LIQUIDATE_FEE_EXCEED = 1;
    uint256 public constant LIQUIDATE_THRESHOLD_EXCEED = 2;

    // function checkSlippage(
    //     bool isLong,
    //     uint256 expectedMarketPrice,
    //     uint256 slippageBasisPoints,
    //     uint256 actualMarketPrice
    // ) internal pure returns (bool) {
    //     return isLong 
    //         ? (actualMarketPrice <=
    //                 (expectedMarketPrice * (BASIS_POINTS_DIVISOR + slippageBasisPoints)) / BASIS_POINTS_DIVISOR)
    //         : ((expectedMarketPrice * (BASIS_POINTS_DIVISOR - slippageBasisPoints)) / BASIS_POINTS_DIVISOR <=
    //                 actualMarketPrice);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}