// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IPositionKeeper.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IPositionRouter.sol";
import "../tokens/interfaces/IMintable.sol";

import  "../constants/PositionConstants.sol";

contract PositionKeeper is PositionConstants, IPositionKeeper, ReentrancyGuard, Ownable {
    address public positionRouter;
    address public positionHandler;
    address public settingsManager;
    address public priceManager;

    uint256 public shortsTrackerAveragePriceWeight;

    mapping(address => uint256) public override lastPositionIndex;
    mapping(bytes32 => Position) public positions;
    mapping(bytes32 => OrderInfo) public orders;
    mapping(bytes32 => FinalPath) public finalPaths;

    mapping(bytes32 => uint256) public override leverages;
    mapping(address => mapping(bool => uint256)) public override globalAmounts; //Global long/short trading amount
    mapping (address => uint256) public globalShortAveragePrices;

    struct FinalPath {
        address indexToken;
        address collateralToken;
    }

    event SetRouter(address positionRouter);
    event SetPositionHandler(address positionHandler);
    event SetSettingsManager(address settingsManager);
    event SetPriceManager(address priceManager);
    event NewOrder(
        bytes32 key,
        address indexed account,
        bool isLong,
        uint256 posId,
        uint256 positionType,
        OrderStatus orderStatus,
        address[] path,
        uint256[] triggerData
    );
    event AddOrRemoveCollateral(
        bytes32 indexed key,
        bool isPlus,
        uint256 nativeAmount,
        uint256 amountInUSD,
        uint256 reserveAmount,
        uint256 collateral,
        uint256 size
    );
    event AddPosition(bytes32 indexed key, bool confirmDelayStatus, uint256 collateral, uint256 size);
    event AddTrailingStop(bytes32 key, uint256[] data);
    event UpdateTrailingStop(bytes32 key, uint256 stpPrice);
    event UpdateOrder(bytes32 key, uint256 positionType, OrderStatus orderStatus);
    event ConfirmDelayTransactionExecuted(
        bytes32 indexed key,
        bool confirmDelayStatus,
        uint256 collateral,
        uint256 size,
        uint256 feeUsd
    );
    event PositionExecuted(
        bytes32 key,
        address indexed account,
        address indexToken,
        bool isLong,
        uint256 posId,
        uint256[] prices
    );
    event IncreasePosition(
        bytes32 key,
        address indexed account,
        address indexed indexToken,
        bool isLong,
        uint256 posId,
        int256 entryFunding,
        uint256[6] posData
    );
    event ClosePosition(
        bytes32 key, 
        int256 realisedPnl, 
        uint256 markPrice, 
        uint256[2] posData,
        uint256 tradingFee,
        int256 fundingFee
    );
    event DecreasePosition(
        bytes32 key,
        address indexed account,
        address indexed indexToken,
        bool isLong,
        uint256 posId,
        uint256[5] posData,
        int256 realisedPnl,
        int256 entryFunding,
        uint256 tradingFee,
        int256 fundingFee
    );
    event LiquidatePosition(bytes32 key, int256 realisedPnl, uint256 markPrice, uint256 feeUsd);
    event GlobalShortDataUpdated(address indexed token, uint256 globalShortSize, uint256 globalShortAveragePrice);
    
    modifier onlyPositionHandler() {
        require(positionHandler != address(0) && msg.sender == positionHandler, "Forbidden");
        _;
    }
    
    //Config functions
    function setPositionRouter(address _router) external onlyOwner {
        require(Address.isContract(_router), "Invalid positionRouter");
        positionRouter = _router;
        emit SetRouter(_router);
    }

    function setPositionHandler(address _positionHandler) external onlyOwner {
        require(Address.isContract(_positionHandler), "Invalid positionHandler");
        positionHandler = _positionHandler;
        emit SetPositionHandler(_positionHandler);
    }

    function setSettingsManager(address _setttingsManager) external onlyOwner {
        require(Address.isContract(_setttingsManager), "Invalid settingsManager");
        settingsManager = _setttingsManager;
        emit SetSettingsManager(_setttingsManager);
    }

    function setPriceManager(address _priceManager) external onlyOwner {
        require(Address.isContract(_priceManager), "Invalid priceManager");
        priceManager = _priceManager;
        emit SetPriceManager(_priceManager);
    }
    //End config functions

    function openNewPosition(
        bytes32 _key,
        bool _isLong, 
        uint256 _posId,
        address[] memory _path,
        uint256[] memory _params,
        bytes memory _data
    ) external nonReentrant onlyPositionHandler {
        _validateSettingsManager();
        Position memory position;
        OrderInfo memory order;

        //Scope to avoid stack too deep error
        {
            (positions[_key], orders[_key]) = abi.decode(_data, ((Position), (OrderInfo)));
            position = positions[_key];
            order = orders[_key];
        }

        if (finalPaths[_key].collateralToken == address(0)) {
            finalPaths[_key].collateralToken = _path[_path.length - 1];
            finalPaths[_key].indexToken = _path[0];
        }

        emit NewOrder(
            _key, 
            position.owner, 
            _isLong, 
            _posId, 
            order.positionType, 
            order.status, 
            _path,
            _params
        );

        lastPositionIndex[position.owner] += 1;
    }

    function unpackAndStorage(bytes32 _key, bytes memory _data, DataType _dataType) external nonReentrant onlyPositionHandler {
        if (_dataType == DataType.POSITION) {
            positions[_key] = abi.decode(_data, (Position));
            uint256 leverage = positions[_key].size == 0 && positions[_key].collateral == 0 ? 0 : positions[_key].size * BASIS_POINTS_DIVISOR / positions[_key].collateral;
            leverages[_key] = leverage;
        } else if (_dataType == DataType.ORDER) {
            orders[_key] = abi.decode(_data, (OrderInfo));
        } else {
            revert("Invalid data type");
        }
    }

    function deletePosition(bytes32 _key) external override nonReentrant onlyPositionHandler {
        _deletePositions(_key, false);
    }

    function deleteOrder(bytes32 _key) external override nonReentrant onlyPositionHandler {
        delete orders[_key];
    }

    function deletePositions(bytes32 _key) external override nonReentrant onlyPositionHandler {
        _deletePositions(_key, true);
    } 

    function _deletePositions(bytes32 _key, bool _isDeleteOrder) internal {
        if (_isDeleteOrder) {
            delete orders[_key];
        }

        delete positions[_key];
    }

    //Emit event functions
    function emitAddPositionEvent(
        bytes32 key, 
        bool confirmDelayStatus, 
        uint256 collateral, 
        uint256 size
    ) external nonReentrant onlyPositionHandler {
        emit AddPosition(key, confirmDelayStatus, collateral, size);
    }

    function emitAddOrRemoveCollateralEvent(
        bytes32 _key,
        bool _isPlus,
        uint256 _amount,
        uint256 _amountInUSD,
        uint256 _reserveAmount,
        uint256 _collateral,
        uint256 _size
    ) external nonReentrant onlyPositionHandler {
        emit AddOrRemoveCollateral(
            _key,
            _isPlus,
            _amount,
            _amountInUSD,
            _reserveAmount,
            _collateral,
            _size
        );
    }

    function emitAddTrailingStopEvent(bytes32 _key, uint256[] memory _data) external nonReentrant onlyPositionHandler {
        emit AddTrailingStop(_key, _data);
    }

    function emitUpdateTrailingStopEvent(bytes32 _key, uint256 _stpPrice) external nonReentrant onlyPositionHandler {
        emit UpdateTrailingStop(_key, _stpPrice);
    }

    function emitUpdateOrderEvent(bytes32 _key, uint256 _positionType, OrderStatus _orderStatus) external nonReentrant onlyPositionHandler {
        emit UpdateOrder(_key, _positionType, _orderStatus);
    }

    function emitConfirmDelayTransactionEvent(
        bytes32 _key,
        bool _confirmDelayStatus,
        uint256 _collateral,
        uint256 _size,
        uint256 _feeUsd
    ) external nonReentrant onlyPositionHandler {
        emit ConfirmDelayTransactionExecuted(_key, _confirmDelayStatus, _collateral, _size, _feeUsd);
    }

    function emitPositionExecutedEvent(
        bytes32 _key,
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _prices
    ) external nonReentrant onlyPositionHandler {
        emit PositionExecuted(
            _key,
            _account,
            _indexToken,
            _isLong,
            _posId,
            _prices
        );
    }

    function emitIncreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external nonReentrant onlyPositionHandler {
        Position memory position = positions[_key];
        globalAmounts[position.indexToken][position.isLong] += _sizeDelta;

        emit IncreasePosition(
            _key,
            position.owner,
            position.indexToken,
            position.isLong,
            position.posId,
            position.entryFunding,
            [
                _collateralDelta,
                _sizeDelta,
                position.reserveAmount,
                position.averagePrice,
                _indexPrice,
                _fee
            ]
        );
    }

    function emitDecreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _tradingFee,
        int256 _fundingFee,
        bool _isPartialClose
    ) external override onlyPositionHandler {
        Position memory position = positions[_key];
        _decreaseGlobalAmount(_sizeDelta, position.indexToken, position.isLong);

        if (_isPartialClose) {
            emit DecreasePosition(
                _key,
                position.owner,
                position.indexToken,
                position.isLong,
                position.posId,
                [
                    _collateralDelta,
                    _sizeDelta,
                    position.reserveAmount,
                    position.averagePrice,
                    _indexPrice
                ],
                position.realisedPnl,
                position.entryFunding,
                _tradingFee,
                _fundingFee
            );
        } else {
            delete leverages[_key];
            emit ClosePosition(
                _key, 
                position.realisedPnl, 
                _indexPrice, 
                [
                    _collateralDelta, 
                    _sizeDelta
                ],
                _tradingFee,
                _fundingFee
            );
            delete positions[_key];
        }
    }

    function _decreaseGlobalAmount(uint256 _sizeDelta, address _indexToken, bool _isLong) internal {
        uint256 globalAmount = globalAmounts[_indexToken][_isLong];
        uint256 decreaseGlobalAmount = _sizeDelta > globalAmount ? globalAmount : _sizeDelta;
        globalAmounts[_indexToken][_isLong] -= decreaseGlobalAmount;
    }

    function emitLiquidatePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _fee
    ) external override onlyPositionHandler {
        Position memory position = positions[_key];
        _validateSettingsManager();
        _decreaseGlobalAmount(position.size, position.indexToken, position.isLong);
        emit LiquidatePosition(_key, position.realisedPnl, _indexPrice, _fee);
        delete positions[_key];
    }
    //End emit event functions

    //View functions
    function getPositions(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view override returns (Position memory, OrderInfo memory) {
        bytes32 key = _getPositionKey(_account, _indexToken, _isLong, _posId);
        Position memory position = positions[key];
        OrderInfo memory order = orders[key];
        return (position, order);
    }

    function getPositions(bytes32 _key) external view override returns (Position memory, OrderInfo memory) {
        return (positions[_key], orders[_key]);
    }

    function getPosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external view override returns (Position memory) {
        return positions[_getPositionKey(_account, _indexToken, _isLong, _posId)];
    }

    function getPosition(bytes32 _key) external override view returns (Position memory) {
        return positions[_key];
    }

    function getOrder(bytes32 _key) external override view returns (OrderInfo memory) {
        return orders[_key];
    }

    function getPositionPreviousFee(bytes32 _key) external override view returns (uint256) {
        return positions[_key].previousFee;
    }

    function getPositionSize(bytes32 _key) external override view returns (uint256) {
        return positions[_key].size;
    } 

    function getPositionCollateralToken(bytes32 _key) external override view returns (address) {
        return finalPaths[_key].collateralToken;
    }

    function getPositionIndexToken(bytes32 _key) external override view returns (address) {
        return finalPaths[_key].indexToken;
    }

    function getPositionFinalPath(bytes32 _key) external override view returns (address[] memory) {
        address[] memory finalPath = new address[](2);
        finalPath[0] = finalPaths[_key].indexToken;
        finalPath[1] = finalPaths[_key].collateralToken;
        return finalPath;
    }

    function getPositionOwner(bytes32 _key) external override view returns (address) {
        return positions[_key].owner;
    }

    function getPositionType(bytes32 _key) external override view returns (bool) {
        return positions[_key].isLong;
    }

    function getBasePosition(bytes32 _key) external override view returns (address, address, bool, uint256) {
        return (positions[_key].owner, positions[_key].indexToken, positions[_key].isLong, positions[_key].posId);
    }

    function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external onlyOwner {
        require(shortsTrackerAveragePriceWeight <= BASIS_POINTS_DIVISOR, "Invalid weight");
        shortsTrackerAveragePriceWeight = _shortsTrackerAveragePriceWeight;
    }

    function getGlobalShortDelta(address _token) public view returns (bool, uint256) {
        uint256 size = globalAmounts[_token][false];
        uint256 averagePrice = globalShortAveragePrices[_token];
        if (size == 0) { return (false, 0); }

        uint256 nextPrice = IPriceManager(priceManager).getLastPrice(_token);
        uint256 priceDelta = averagePrice > nextPrice ? averagePrice - nextPrice : nextPrice - averagePrice;
        uint256 delta = (size * priceDelta) / averagePrice;
        bool hasProfit = averagePrice > nextPrice;

        return (hasProfit, delta);
    }

    function updateGlobalShortData(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _indexPrice,
        bool _isIncrease
    ) external {
        require(msg.sender == address(positionHandler), "Forbidden");
        Position memory position = positions[_key];

        if (position.isLong || _sizeDelta == 0) {
            return;
        }

        (uint256 globalShortSize, uint256 globalShortAveragePrice) = getNextGlobalShortData(
            _indexPrice,
            _sizeDelta,
            _isIncrease,
            position
        );

        globalShortAveragePrices[position.indexToken] = globalShortAveragePrice;
        emit GlobalShortDataUpdated(position.indexToken, globalShortSize, globalShortAveragePrice);
    }

    function getNextGlobalShortData(
        uint256 _indexPrice,
        uint256 _sizeDelta,
        bool _isIncrease,
        Position memory _position
    ) public view returns (uint256, uint256) {
        int256 realisedPnl = _getRealisedPnl(_sizeDelta, _isIncrease, _position);
        uint256 averagePrice = globalShortAveragePrices[_position.indexToken];
        uint256 priceDelta = averagePrice > _indexPrice ? averagePrice - _indexPrice : _indexPrice - averagePrice;

        uint256 nextSize;
        uint256 delta;

        {
            uint256 size = globalAmounts[_position.indexToken][false];
            nextSize = _isIncrease ? size + _sizeDelta : size - _sizeDelta;

            if (nextSize == 0) {
                return (0, 0);
            }

            if (averagePrice == 0) {
                return (nextSize, _indexPrice);
            }

            delta = (size * priceDelta) / averagePrice;
        }

        uint256 nextAveragePrice = _getNextGlobalAveragePrice(
            averagePrice,
            _indexPrice,
            nextSize,
            delta,
            realisedPnl
        );

        return (nextSize, nextAveragePrice);
    }

    function _getNextGlobalAveragePrice(
        uint256 _averagePrice,
        uint256 _indexPrice,
        uint256 _nextSize,
        uint256 _delta,
        int256 _realisedPnl
    ) public pure returns (uint256) {
        (bool hasProfit, uint256 nextDelta) = _getNextDelta(_delta, _averagePrice, _indexPrice, _realisedPnl);
        uint256 nextAveragePrice = (_indexPrice
            * _nextSize)
            / (hasProfit ? _nextSize - nextDelta : _nextSize + nextDelta);

        return nextAveragePrice;
    }

    function _getNextDelta(
        uint256 _delta,
        uint256 _averagePrice,
        uint256 _indexPrice,
        int256 _realisedPnl
    ) internal pure returns (bool, uint256) {
        bool hasProfit = _averagePrice > _indexPrice;

        if (hasProfit) {
            // global shorts pnl is positive
            if (_realisedPnl > 0) {
                if (uint256(_realisedPnl) > _delta) {
                    _delta = uint256(_realisedPnl) - _delta;
                    hasProfit = false;
                } else {
                    _delta = _delta - uint256(_realisedPnl);
                }
            } else {
                _delta = _delta + uint256(-_realisedPnl);
            }

            return (hasProfit, _delta);
        }

        if (_realisedPnl > 0) {
            _delta = _delta + uint256(_realisedPnl);
        } else {
            if (uint256(-_realisedPnl) > _delta) {
                _delta = uint256(-_realisedPnl) - _delta;
                hasProfit = true;
            } else {
                _delta = _delta - uint256(-_realisedPnl);
            }
        }
        return (hasProfit, _delta);
    }

    function _getRealisedPnl(
        uint256 _sizeDelta,
        bool _isIncrease,
        Position memory _position
    ) internal view returns (int256) {
        if (_isIncrease) {
            return 0;
        }

        (bool hasProfit, uint256 delta) = IPriceManager(priceManager).getDelta(
            _position.indexToken,
            _position.size,
            _position.averagePrice,
            _position.isLong, 
            0
        );
        // Get the proportional change in pnl
        uint256 adjustedDelta = (_sizeDelta * delta) / _position.size;
        require(adjustedDelta < uint256(type(int256).max), "Overflow");
        return hasProfit ? int256(adjustedDelta) : -int256(adjustedDelta);
    }

    function _validateSettingsManager() internal view {
        require(settingsManager != address(0), "Settings manager not initialzied");
    }

    function _validateRouter() internal view {
         require(positionRouter != address(0), "Router not initialzied");
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

pragma solidity ^0.8.12;

interface IPositionHandler {
    // function openNewPosition(
    //     bytes32 _key,
    //     bool _isFastExecute,
    //     bool _isNewPosition,
    //     uint256[] memory _params,
    //     uint256[] memory _prices, 
    //     address[] memory _path,
    //     bytes memory _data
    // ) external;

    function modifyPosition(
        bytes32 _key,
        uint256 _txType, 
        address[] memory _path,
        uint256[] memory _prices,
        bytes memory _data
    ) external;
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
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function emitDecreasePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 tradingFee,
        int256 _fundingFee,
        bool _isPartialClose
    ) external ;

    function emitLiquidatePositionEvent(
        bytes32 _key,
        uint256 _indexPrice,
        uint256 _fee
    ) external;

    function updateGlobalShortData(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _indexPrice,
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

    function getPositionPreviousFee(bytes32 _key) external view returns (uint256);

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

import {Position} from "../../constants/Structs.sol";

interface ISettingsManager {
    function decreaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAsset(address _token) external view returns (uint256);

    function openInterestPerSide(bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function getFeeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isCollateral(address _token) external view returns (bool);

    function isTradable(address _token) external view returns (bool);

    function isStable(address _token) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token) external view returns (uint256);

    function maxPriceUpdatedDelay() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);
    
    function pauseForexForCloseTime() external view returns (bool);

    function priceMovementPercent() external view returns (uint256);

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

    function basisFundingRateFactor() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);

    function fundingRateFactor(address _token) external view returns (uint256);

    function fundingIndex(address _token) external view returns (int256);

    function getFundingRate(address _indexToken, address _collateralToken) external view returns (int256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(address token) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getBorrowFee(
        address _indexToken,
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function getFees(
        bytes32 _key,
        uint256 _sizeDelta,
        uint256 _loanDelta,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee
    ) external view returns (uint256, int256);

    function getFees(
        uint256 _sizeDelta,
        uint256 _loanDelta,
        bool _isApplyTradingFee,
        bool _isApplyBorrowFee,
        bool _isApplyFundingFee,
        Position memory _position
    ) external view returns (uint256, int256);

    function getDiscountFee(address _account, uint256 _fee) external view returns (uint256);

    function updateFunding(address _indexToken, address _collateralToken) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IMintable {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function setMinter(address _minter) external;

    function revokeMinter(address _minter) external;

    function isMinter(address _account) external returns (bool);
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
    Params length must be 5, which:
        [0] is pending collateral,
        [1] is pending size,
        [2] is step type,
        [3] is stop price,
        [4] is step amount
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

    //Change these constants or must notice on login of PositionRouter
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

    function _isOpenPosition(uint256 _txType) internal pure returns (bool) {
        return _txType == CREATE_POSITION_MARKET 
            || _isDelayPosition(_txType);
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
    int256 entryFunding;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
    uint256 posId;
    uint256 previousFee;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}