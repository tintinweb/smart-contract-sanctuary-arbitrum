// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../access/BaseExecutor.sol";
import "./interfaces/IPositionKeeper.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IVaultUtils.sol";
import "./interfaces/ITriggerOrderManager.sol";
import "./interfaces/IRouter.sol";

import {PositionConstants} from "../constants/PositionConstants.sol";
import {Position, OrderInfo, OrderStatus, OrderType, DataType} from "../constants/Structs.sol";

contract PositionHandler is PositionConstants, IPositionHandler, BaseExecutor {
    mapping(bytes32 => bool) private processing;

    IPositionKeeper public positionKeeper;
    IPriceManager public priceManager;
    ISettingsManager public settingsManager;
    ITriggerOrderManager public triggerOrderManager;
    IVault public vault;
    IVaultUtils public vaultUtils;
    bool public isInitialized;
    address public router;

    event Initialized(
        IPriceManager priceManager,
        ISettingsManager settingsManager,
        ITriggerOrderManager triggerOrderManager,
        IVault vault,
        IVaultUtils vaultUtils
    );
    event SetRouter(address router);
    event SetPositionKeeper(address positionKeeper);
    event SyncPriceOutdated(bytes32 key, uint256 txType, address[] path);

    modifier onlyRouter() {
        require(msg.sender == router, "FBD");
        _;
    }

    modifier inProcess(bytes32 key) {
        require(!processing[key], "InP"); //In processing
        processing[key] = true;
        _;
        processing[key] = false;
    }

    //Config functions
    function setRouter(address _router) external onlyOwner {
        require(Address.isContract(_router), "IVLCA"); //Invalid contract address
        router = _router;
        emit SetRouter(_router);
    }

    function setPositionKeeper(address _positionKeeper) external onlyOwner {
        require(Address.isContract(_positionKeeper), "IVLC/PK"); //Invalid contract positionKeeper
        positionKeeper = IPositionKeeper(_positionKeeper);
        emit SetPositionKeeper(_positionKeeper);
    }

    function initialize(
        IPriceManager _priceManager,
        ISettingsManager _settingsManager,
        ITriggerOrderManager _triggerOrderManager,
        IVault _vault,
        IVaultUtils _vaultUtils
    ) external onlyOwner {
        require(!isInitialized, "AI"); //Already initialized
        require(Address.isContract(address(_priceManager)), "IVLC/PM"); //Invalid contract priceManager
        require(Address.isContract(address(_settingsManager)), "IVLC/SM"); //Invalid contract settingsManager
        require(Address.isContract(address(_triggerOrderManager)), "IVLC/TOM"); //Invalid contract triggerOrderManager
        require(Address.isContract(address(_vault)), "IVLC/V"); //Invalid contract vault
        require(Address.isContract(address(_vaultUtils)), "IVLC/VU"); //Invalid contract vaultUtils
        priceManager = _priceManager;
        settingsManager = _settingsManager;
        triggerOrderManager = _triggerOrderManager;
        vault = _vault;
        vaultUtils = _vaultUtils;
        isInitialized = true;
        emit Initialized(
            _priceManager,
            _settingsManager,
            _triggerOrderManager,
            _vault,
            _vaultUtils
        );
    }
    //End config functions

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
    ) external override onlyRouter inProcess(_key) {
        require(_collateralIndex > 0 && _collateralIndex < _path.length, "IVLCTI"); //Invalid collateral index
        (Position memory position, OrderInfo memory order) = abi.decode(_data, ((Position), (OrderInfo)));
        vaultUtils.validatePositionData(
            _isLong, 
            _getFirstPath(_path), 
            _getOrderType(order.positionType), 
            _getFirstParams(_prices), 
            _params, 
            true
        );
        
        if (order.positionType == POSITION_MARKET && _isFastExecute) {
            _increaseMarketPosition(
                _key,
                _isLong,
                _collateralIndex,
                _path,
                _prices, 
                position,
                order
            );
            vault.decreaseBond(_key, position.owner, CREATE_POSITION_MARKET);
        }

        if (_isNewPosition) {
            positionKeeper.openNewPosition(
                _key,
                _isLong,
                _posId,
                _collateralIndex,
                _path,
                _params, 
                abi.encode(position, order)
            );
        } else {
            positionKeeper.unpackAndStorage(_key, abi.encode(position), DataType.POSITION);
        }
    }

    function _increaseMarketPosition(
        bytes32 _key,
        bool _isLong,
        uint256 _collateralIndex,
        address[] memory _path,
        uint256[] memory _prices, 
        Position memory _position,
        OrderInfo memory _order
    ) internal {
        require(_order.pendingCollateral > 0 && _order.pendingSize > 0, "IVLOPC/S"); //Invalid order pending collateral/size
        uint256 collateralDecimals = priceManager.getTokenDecimals(_path[_collateralIndex]);
        uint256 collateralPrice = _getLastParams(_prices);
        uint256 pendingCollateral = _fromTokenToUSD(_order.pendingCollateral, collateralPrice, collateralDecimals);
        uint256 pendingSize = _fromTokenToUSD(_order.pendingSize, collateralPrice, collateralDecimals);
        _increasePosition(
            _key,
            pendingCollateral,
            pendingSize,
            _isLong,
            _path,
            _prices,
            _position
        );
        _order.pendingCollateral = 0;
        _order.pendingSize = 0;
        _order.collateralToken = address(0);
    }

    function modifyPosition(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType, 
        bytes memory _data,
        address[] memory _path,
        uint256[] memory _prices
    ) external onlyRouter inProcess(_getPositionKey(_account, _getFirstPath(_path), _isLong, _posId)) {
        if (_txType != CANCEL_PENDING_ORDER) {
            require(_path.length == _prices.length && _path.length > 0, "IVLARL"); //Invalid array length
        }
        
        bytes32 key = _getPositionKey(_account, _getFirstPath(_path), _isLong, _posId);
        require(_account == positionKeeper.getPositionOwner(key), "IVLPO"); //Invalid positionOwner
        bool isDelayPosition = false;
        uint256 delayPositionTxType;

        if (_txType == ADD_COLLATERAL || _txType == REMOVE_COLLATERAL) {
            (uint256 amountIn, Position memory position) = abi.decode(_data, ((uint256), (Position)));
            _addOrRemoveCollateral(
                key, 
                _isLong,
                _txType, 
                amountIn, 
                _path, 
                _prices, 
                position
            );
        } else if (_txType == ADD_TRAILING_STOP) {
            (uint256[] memory params, OrderInfo memory order) = abi.decode(_data, ((uint256[]), (OrderInfo)));
            _addTrailingStop(key, _isLong, params, order, _getFirstParams(_prices));
        } else if (_txType == UPDATE_TRAILING_STOP) {
            (OrderInfo memory order) = abi.decode(_data, ((OrderInfo)));
            _updateTrailingStop(key, _isLong, _getFirstParams(_prices), order);
        } else if (_txType == CANCEL_PENDING_ORDER) {
            OrderInfo memory order = abi.decode(_data, ((OrderInfo)));
            _cancelPendingOrder(_account, key, order);
        } else if (_txType == CLOSE_POSITION) {
            (uint256 sizeDelta, Position memory position) = abi.decode(_data, ((uint256), (Position)));
            require(sizeDelta > 0 && sizeDelta <= position.size, "IVLPSD"); //Invalid position size delta
            _decreasePosition(
                _getFirstPath(_path),
                sizeDelta,
                _isLong,
                _posId,
                _prices,
                position
            );
        } else if (_txType == TRIGGER_POSITION) {
            (Position memory position, OrderInfo memory order) = abi.decode(_data, ((Position), (OrderInfo)));
            isDelayPosition = position.size == 0;
            delayPositionTxType = isDelayPosition ? _getTxTypeFromPositionType(order.positionType) : 0;
            _triggerPosition(
                key,
                _isLong,
                _posId,
                _path,
                _prices,
                position,
                order
            );
        } else if (_txType == ADD_POSITION) {
            (
                uint256 pendingCollateral, 
                uint256 pendingSize, 
                Position memory position
            ) = abi.decode(_data, ((uint256), (uint256), (Position)));
            _confirmDelayTransaction(
                _isLong,
                _posId,
                pendingCollateral,
                pendingSize,
                _path,
                _prices,
                position
            );
        } else if (_txType == LIQUIDATE_POSITION) {
            (Position memory position) = abi.decode(_data, (Position));
            _liquidatePosition(
                _isLong,
                _posId,
                _prices,
                _path,
                position
            );
        } else if (_txType == REVERT_EXECUTE) {
            (uint256 originalTxType, Position memory position) = abi.decode(_data, ((uint256), (Position)));

            if (originalTxType == CREATE_POSITION_MARKET && position.size == 0) {
                positionKeeper.deletePosition(key);
            } else if (originalTxType == ADD_TRAILING_STOP || 
                    originalTxType == ADD_COLLATERAL || 
                    _isDelayPosition(originalTxType)) {
                positionKeeper.deleteOrder(key);
            }
        } else {
            revert("IVLTXT"); //Invalid txType
        }

        //Reduce vault bond
        bool isTriggerDelayPosition = _txType == TRIGGER_POSITION && isDelayPosition;

        if (_txType == CREATE_POSITION_MARKET ||
                _txType == ADD_COLLATERAL ||
                _txType == ADD_POSITION ||
                isTriggerDelayPosition) {

            uint256 exactTxType = isTriggerDelayPosition && delayPositionTxType > 0 ? delayPositionTxType : _txType;
            vault.decreaseBond(key, _account, exactTxType);
        }
    }

    /*
    @dev: Set price and execute in batch, temporarily disabled, implement later
    */
    function setPriceAndExecuteInBatch(
        address[] memory _tokens,
        uint256[] memory _prices,
        bytes32[] memory _keys, 
        uint256[] memory _txTypes
    ) external {
        require(_keys.length == _txTypes.length && _keys.length > 0, "IVLARL2"); //Invalid array length
        priceManager.setLatestPrices(_tokens, _prices);
        require(_isExecutor(msg.sender), "FBD/NE"); //Forbidden, not executor 

        for (uint256 i = 0; i < _keys.length; i++) {
            address[] memory path = IRouter(router).getExecutePath(_keys[i], _txTypes[i]);

            if (path.length > 0) {
                (uint256[] memory prices, bool isLastestSync) = priceManager.getLatestSynchronizedPrices(path);

                if (isLastestSync && !processing[_keys[i]]) {
                    try IRouter(router).execute(_keys[i], _txTypes[i], prices) {}
                    catch (bytes memory err) {
                        IRouter(router).revertExecution(_keys[i], _txTypes[i], path, prices, string(err));
                    }
                } else {
                    emit SyncPriceOutdated(_keys[i], _txTypes[i], path);
                }
            }
        }
    }

    function _addOrRemoveCollateral(
        bytes32 _key,
        bool _isLong,
        uint256 _txType,
        uint256 _amountIn,
        address[] memory _path,
        uint256[] memory _prices,
        Position memory _position
    ) internal {
        uint256 amountInUSD;

        if (_txType == ADD_COLLATERAL) {
            amountInUSD = vaultUtils.validateAddCollateral(
                _position.size, 
                _position.collateral, 
                _amountIn, 
                _getLastPath(_path), 
                _getLastParams(_prices)
            );
            _position.collateral += amountInUSD;
            _position.reserveAmount += amountInUSD;
            positionKeeper.unpackAndStorage(_key, abi.encode(_position), DataType.POSITION);
            positionKeeper.increasePoolAmount(_getFirstPath(_path), _isLong, amountInUSD);
        } else {
            require(_amountIn <= _position.collateral, "ISFPC"); //Insufficient position collateral
            amountInUSD = _amountIn;
            _position.collateral -= _amountIn;
            vaultUtils.validateRemoveCollateral(
                amountInUSD, 
                _isLong, 
                _getFirstPath(_path), 
                _getFirstParams(_prices), 
                _position
            );
            _position.reserveAmount -= _amountIn;
            _position.lastIncreasedTime = block.timestamp;

            vault.takeAssetOut(
                _position.owner, 
                _position.refer, 
                0,
                _amountIn, 
                positionKeeper.getPositionCollateralToken(_key), 
                _getLastParams(_prices)
            );

            positionKeeper.unpackAndStorage(_key, abi.encode(_position), DataType.POSITION);
            positionKeeper.decreasePoolAmount(_getFirstPath(_path), _isLong, _amountIn);
        }

        positionKeeper.emitAddOrRemoveCollateralEvent(
            _key, 
            _txType == ADD_COLLATERAL, 
            _amountIn,
            amountInUSD,
            _position.reserveAmount, 
            _position.collateral, 
            _position.size
        );
    }

    function _addTrailingStop(
        bytes32 _key,
        bool _isLong,
        uint256[] memory _params,
        OrderInfo memory _order,
        uint256 _indexPrice
    ) internal {
        require(positionKeeper.getPositionSize(_key) > 0, "IVLPSZ"); //Invalid position size
        vaultUtils.validateTrailingStopInputData(_key, _isLong, _params, _indexPrice);
        _order.pendingCollateral = _getFirstParams(_params);
        _order.pendingSize = _params[1];
        _order.status = OrderStatus.PENDING;
        _order.positionType = POSITION_TRAILING_STOP;
        _order.stepType = _params[2];
        _order.stpPrice = _params[3];
        _order.stepAmount = _params[4];
        positionKeeper.unpackAndStorage(_key, abi.encode(_order), DataType.ORDER);
        positionKeeper.emitAddTrailingStopEvent(_key, _params);
    }

    function _cancelPendingOrder(
        address _account,
        bytes32 _key,
        OrderInfo memory _order
    ) internal {
        require(_order.status == OrderStatus.PENDING, "IVLOS/P"); //Invalid _order status, must be pending
        require(_order.positionType != POSITION_MARKET, "NACMO"); //Not allowing cancel market order
        bool isTrailingStop = _order.positionType == POSITION_TRAILING_STOP;

        if (isTrailingStop) {
            require(_order.pendingCollateral > 0, "IVLOPDC");
        } else {
            require(_order.pendingCollateral > 0  && _order.collateralToken != address(0), "IVLOPDC/T"); //Invalid order pending collateral or token
        }
        
        _order.pendingCollateral = 0;
        _order.pendingSize = 0;
        _order.lmtPrice = 0;
        _order.stpPrice = 0;
        _order.collateralToken = address(0);

        if (isTrailingStop) {
            _order.status = OrderStatus.FILLED;
            _order.positionType = POSITION_MARKET;
        } else {
            _order.status = OrderStatus.CANCELED;
        }
        
        positionKeeper.unpackAndStorage(_key, abi.encode(_order), DataType.ORDER);
        positionKeeper.emitUpdateOrderEvent(_key, _order.positionType, _order.status);

        if (!isTrailingStop) {
            vault.takeAssetBack(
                _account, 
                _key, 
                _getTxTypeFromPositionType(_order.positionType)
            );
        }
    }

    function _triggerPosition(
        bytes32 _key,
        bool _isLong,
        uint256 _posId,
        address[] memory _path, 
        uint256[] memory _prices, 
        Position memory _position, 
        OrderInfo memory _order
    ) internal {
        settingsManager.updateCumulativeFundingRate(_getFirstPath(_path), _isLong);
        uint8 statusFlag = vaultUtils.validateTrigger(_isLong, _getFirstParams(_prices), _order);
        (bool hitTrigger, uint256 triggerAmountPercent) = triggerOrderManager.executeTriggerOrders(
            _position.owner,
            _getFirstPath(_path),
            _isLong,
            _posId,
            _getFirstParams(_prices)
        );
        require(statusFlag == ORDER_FILLED || hitTrigger, "TGNRD");  //Trigger not ready

        //When TriggerOrder from TriggerOrderManager reached price condition
        if (hitTrigger) {
            _decreasePosition(
                _getFirstPath(_path),
                (_position.size * (triggerAmountPercent)) / BASIS_POINTS_DIVISOR,
                _isLong,
                _posId,
                _prices,
                _position
            );
        }

        //When limit/stopLimit/stopMarket order reached price condition 
        if (statusFlag == ORDER_FILLED) {
            if (_order.positionType == POSITION_LIMIT || _order.positionType == POSITION_STOP_MARKET) {
                uint256 collateralDecimals = priceManager.getTokenDecimals(_order.collateralToken);
                uint256 collateralPrice = _getLastParams(_prices);
                _increasePosition(
                    _key,
                    _fromTokenToUSD(_order.pendingCollateral, collateralPrice, collateralDecimals),
                    _fromTokenToUSD(_order.pendingSize, collateralPrice, collateralDecimals),
                    _isLong,
                    _path,
                    _prices, 
                    _position
                );
                _order.pendingCollateral = 0;
                _order.pendingSize = 0;
                _order.status = OrderStatus.FILLED;
                _order.collateralToken = address(0);
            } else if (_order.positionType == POSITION_STOP_LIMIT) {
                _order.positionType = POSITION_LIMIT;
            } else if (_order.positionType == POSITION_TRAILING_STOP) {
                //Double check position size and collateral if hitTriggered
                if (_position.size > 0 && _position.collateral > 0) {
                    _decreasePosition(_getFirstPath(_path), _order.pendingSize, _isLong, _posId, _prices, _position);
                    _order.positionType = POSITION_MARKET;
                    _order.pendingCollateral = 0;
                    _order.pendingSize = 0;
                    _order.status = OrderStatus.FILLED;
                    _order.collateralToken = address(0);
                }
            }
        }

        positionKeeper.unpackAndStorage(_key, abi.encode(_order), DataType.ORDER);
        positionKeeper.emitUpdateOrderEvent(_key, _order.positionType, _order.status);
    }

    function _confirmDelayTransaction(
        bool _isLong,
        uint256 _posId,
        uint256 _pendingCollateral,
        uint256 _pendingSize,
        address[] memory _path,
        uint256[] memory _prices,
        Position memory _position
    ) internal {
        bytes32 key = _getPositionKey(_position.owner, _getFirstPath(_path), _isLong, _posId);
        vaultUtils.validateConfirmDelay(_position.owner, _getFirstPath(_path), _isLong, _posId, true);
        require(vault.getBondAmount(key, ADD_POSITION) >= 0, "ISFBA"); //Insufficient bond amount

        uint256 fee = settingsManager.collectMarginFees(
            _position.owner,
            _getFirstPath(_path),
            _isLong,
            _pendingSize,
            _position.size,
            _position.entryFundingRate
        );

        uint256 pendingCollateralInUSD;
        uint256 pendingSizeInUSD;
      
        //Scope to avoid stack too deep error
        {
            uint256 collateralDecimals = priceManager.getTokenDecimals(_getLastPath(_path));
            uint256 collateralPrice = _getLastParams(_prices);
            pendingCollateralInUSD = _fromTokenToUSD(_pendingCollateral, collateralPrice, collateralDecimals);
            pendingSizeInUSD = _fromTokenToUSD(_pendingSize, collateralPrice, collateralDecimals);
        }

        _increasePosition(
            key,
            pendingCollateralInUSD + fee,
            pendingSizeInUSD,
            _isLong,
            _path,
            _prices,
            _position
        );
        positionKeeper.emitConfirmDelayTransactionEvent(
            key,
            true,
            _pendingCollateral,
            _pendingSize,
            fee
        );
    }

    function _liquidatePosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _prices,
        address[] memory _path,
        Position memory _position
    ) internal {
        settingsManager.updateCumulativeFundingRate(_getFirstPath(_path), _isLong);
        bytes32 key = _getPositionKey(_position.owner, _getFirstPath(_path), _isLong, _posId);
        uint256 previousFee = _position.totalFee;
        _position.totalFee = 0;
        (uint256 liquidationState, uint256 fee) = vaultUtils.validateLiquidation(
            _position.owner,
            _getFirstPath(_path),
            _isLong,
            false,
            _getFirstParams(_prices),
            _position
        );
        require(liquidationState != LIQUIDATE_NONE_EXCEED, "NLS");

        if (liquidationState == LIQUIDATE_THRESHOLD_EXCEED) {
            // Max leverage exceeded but there is collateral remaining after deducting losses so decreasePosition instead
            _decreasePosition(_getFirstPath(_path), _position.size, _isLong, _posId, _prices, _position);
            positionKeeper.unpackAndStorage(key, abi.encode(_position), DataType.POSITION);
            return;
        }
        fee += previousFee;
        _accountDeltaAndFeeIntoTotalBalance(
            key,
            true,
            0,
            fee,
            address(0),
            _getLastParams(_prices)
        );
        vault.transferBounty(settingsManager.feeManager(), fee);
        settingsManager.decreaseOpenInterest(_getFirstPath(_path), _position.owner, _isLong, _position.size);
        positionKeeper.decreasePoolAmount(_getFirstPath(_path), _isLong, fee);
        positionKeeper.emitLiquidatePositionEvent(key, _getFirstParams(_prices), fee);
    }

    function _updateTrailingStop(
        bytes32 _key,
        bool _isLong,
        uint256 _indexPrice,
        OrderInfo memory _order
    ) internal {
        vaultUtils.validateTrailingStopPrice(_isLong, _key, true, _indexPrice);
        
        if (_isLong) {
            _order.stpPrice = _order.stepType == 0
                ? _indexPrice - _order.stepAmount
                : (_indexPrice * (BASIS_POINTS_DIVISOR - _order.stepAmount)) / BASIS_POINTS_DIVISOR;
        } else {
            _order.stpPrice = _order.stepType == 0
                ? _indexPrice + _order.stepAmount
                : (_indexPrice * (BASIS_POINTS_DIVISOR + _order.stepAmount)) / BASIS_POINTS_DIVISOR;
        }

        positionKeeper.unpackAndStorage(_key, abi.encode(_order), DataType.ORDER);
        positionKeeper.emitUpdateTrailingStopEvent(_key, _order.stpPrice);
    }

    function _decreasePosition(
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _prices,
        Position memory _position
    ) internal {
        settingsManager.updateCumulativeFundingRate(_indexToken, _isLong);
        settingsManager.decreaseOpenInterest(
            _indexToken,
            _position.owner,
            _isLong,
            _sizeDelta
        );
        positionKeeper.decreaseReservedAmount(_indexToken, _isLong, _sizeDelta);
        bytes32 key;
        uint256[4] memory posData; //[usdOut, fee, collateralDelta, adjustedDelta]
        bool hasProfit;
        bool isParitalDecrease;

        //Scope to avoid stack too deep error
        {
            key = _getPositionKey(_position.owner, _indexToken, _isLong, _posId);
            (posData, hasProfit, isParitalDecrease, _position) = vaultUtils.beforeDecreasePosition(
                _position.owner,
                _indexToken,
                _isLong, 
                _posId,
                _sizeDelta,
                _getFirstParams(_prices),
                true
            );
            _position.totalFee = 0;
        }

        //Collect vault fee
        if (posData[3] > 0) {
            _accountDeltaAndFeeIntoTotalBalance(
                key,
                hasProfit,
                posData[3],
                posData[1],
                address(0),
                _getLastParams(_prices)
            );
        }

        positionKeeper.unpackAndStorage(key, abi.encode(_position), DataType.POSITION);

        if (isParitalDecrease) {
            positionKeeper.emitDecreasePositionEvent(
                key,
                _getFirstParams(_prices), 
                posData[1], 
                posData[2],
                _sizeDelta
            );
        } else {
            positionKeeper.emitClosePositionEvent(
                key,
                _getFirstParams(_prices), 
                posData[1],
                posData[2],
                _sizeDelta
            );
        }

        if (posData[1] <= posData[0]) {
            if (posData[1] != posData[0]) {
                positionKeeper.decreasePoolAmount(_indexToken, _isLong, posData[0] - posData[1]);
            }
            
            vault.takeAssetOut(
                _position.owner, 
                _position.refer, 
                posData[1], 
                posData[0], 
                positionKeeper.getPositionCollateralToken(key), 
                _getLastParams(_prices)
            );
        } else if (posData[1] != 0) {
            vault.distributeFee(_position.owner, _position.refer, posData[1], _indexToken);
        }
    }

    function _increasePosition(
        bytes32 _key,
        uint256 _amountIn,
        uint256 _sizeDelta,
        bool _isLong,
        address[] memory _path,
        uint256[] memory _prices,
        Position memory _position
    ) internal {
        settingsManager.updateCumulativeFundingRate(_getFirstPath(_path), _isLong);
        address indexToken;
        uint256 indexPrice;

        {
            indexToken = _getFirstPath(_path);
            indexPrice = _getFirstParams(_prices);
        }

        if (_position.size == 0) {
            _position.averagePrice = indexPrice;
        }

        if (_position.size > 0 && _sizeDelta > 0) {
            _position.averagePrice = priceManager.getNextAveragePrice(
                indexToken,
                _position.size,
                _position.averagePrice,
                _isLong,
                _sizeDelta,
                indexPrice
            );
        }
        uint256 fee = settingsManager.collectMarginFees(
            _position.owner,
            indexToken,
            _isLong,
            _sizeDelta,
            _position.size,
            _position.entryFundingRate
        );
        vault.collectVaultFee(_position.refer, _amountIn);

        //Storage open fee and charge later
        _position.totalFee += fee;
        _position.collateral += _amountIn;
        _position.reserveAmount += _amountIn;
        _position.entryFundingRate = settingsManager.cumulativeFundingRates(indexToken, _isLong);
        _position.size += _sizeDelta;
        _position.lastIncreasedTime = block.timestamp;
        _position.lastPrice = indexPrice;
        _accountDeltaAndFeeIntoTotalBalance(
            bytes32(0),
            true, 
            0, 
            fee, 
            _getLastPath(_path),
            _getLastParams(_prices)
        );
        
        settingsManager.validatePosition(_position.owner, indexToken, _isLong, _position.size, _position.collateral);
        vaultUtils.validateLiquidation(_position.owner, indexToken, _isLong, true, indexPrice, _position);
        settingsManager.increaseOpenInterest(indexToken, _position.owner, _isLong, _sizeDelta);
        positionKeeper.unpackAndStorage(_key, abi.encode(_position), DataType.POSITION);
        positionKeeper.increaseReservedAmount(indexToken, _isLong, _sizeDelta);
        positionKeeper.increasePoolAmount(indexToken, _isLong, _amountIn);
        positionKeeper.emitIncreasePositionEvent(
            _key,
            indexPrice,
            fee, 
            _amountIn, 
            _sizeDelta
        );
    }

    function _accountDeltaAndFeeIntoTotalBalance(
        bytes32 _key,
        bool _hasProfit,
        uint256 _adjustedDelta,
        uint256 _fee,
        address _collateralToken,
        uint256 _collateralPrice
    ) internal {
        vault.accountDeltaAndFeeIntoTotalBalance(
            _hasProfit, 
            _adjustedDelta, 
            _fee, 
            _collateralToken == address(0) && uint256(_key) > 0 ? positionKeeper.getPositionCollateralToken(_key) : _collateralToken,
            _collateralPrice
        );
    }

    function _validateDecreasePosition(
        address _indexToken,
        bool _isLong,
        uint256 _indexPrice,
        Position memory _position
    ) internal view {
        vaultUtils.validateDecreasePosition(_indexToken, _isLong, true, _indexPrice, _position);
    }

    function _calculateMarginFee(
        address _indexToken, 
        bool _isLong, 
        uint256 _sizeDelta, 
        Position memory _position
    ) internal view returns (uint256){
        return settingsManager.collectMarginFees(
            _position.owner,
            _indexToken,
            _isLong,
            _sizeDelta,
            _position.size,
            _position.entryFundingRate
        );
    }

    /*
    @dev: Set the latest lastPrices for fastPriceFeed
    */
    function _setLatestPrices(address _indexToken, address[] memory _collateralPath, uint256[] memory _prices) internal {
        for (uint256 i = 0; i < _prices.length; i++) {
            uint256 price = _prices[i];

            if (price > 0) {
                try priceManager.setLatestPrice(i == 0 ? _indexToken : _collateralPath[i + 1], price){}
                catch {}
            }
        }
    }

    function _fromTokenToUSD(uint256 _tokenAmount, uint256 _price, uint256 _decimals) internal pure returns (uint256) {
        return (_tokenAmount * _price) / (10 ** _decimals);
    }

    function _getOrderType(uint256 _positionType) internal pure returns (OrderType) {
        if (_positionType == POSITION_MARKET) {
            return OrderType.MARKET;
        } else if (_positionType == POSITION_LIMIT) {
            return OrderType.LIMIT;
        } else if (_positionType == POSITION_STOP_MARKET) {
            return OrderType.STOP;
        } else if (_positionType == POSITION_STOP_LIMIT) {
            return OrderType.STOP_LIMIT;
        } else {
            revert("IVLOT"); //Invalid order type
        }
    }

    function _getFirstPath(address[] memory _path) internal pure returns (address) {
        return _path[0];
    }

    function _getLastPath(address[] memory _path) internal pure returns (address) {
        return _path[_path.length - 1];
    }

    function _getFirstParams(uint256[] memory _params) internal pure returns (uint256) {
        return _params[0];
    }

    function _getLastParams(uint256[] memory _params) internal pure returns (uint256) {
        return _params[_params.length - 1];
    }

    //This function is using for re-intialized settings
    function reInitializedForDev(bool _isInitialized) external onlyOwner {
       isInitialized = _isInitialized;
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
    address refer;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    uint256 entryFundingRate;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
    uint256 totalFee;
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

struct PositionBond {
    address owner;
    address indexToken;
    bool isLong;
    uint256 posId;
    uint256 leverage;
}

struct VaultBond {
    address owner;
    address token; //Collateral token
    uint256 amount; //Collateral amount
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

import {
    Position, 
    OrderInfo, 
    OrderType, 
    DataType, 
    OrderStatus
} from "../../constants/Structs.sol";

interface IPositionKeeper {
    function poolAmounts(address _token, bool _isLong) external view returns (uint256);

    function reservedAmounts(address _token, bool _isLong) external view returns (uint256);

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

    function increaseReservedAmount(address _token, bool _isLong, uint256 _amount) external;

    function decreaseReservedAmount(address _token, bool _isLong, uint256 _amount) external;

    function increasePoolAmount(address _indexToken, bool _isLong, uint256 _amount) external;

    function decreasePoolAmount(address _indexToken, bool _isLong, uint256 _amount) external;

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

    function getPositionFee(bytes32 _key) external view returns (uint256);

    function getPositionSize(bytes32 _key) external view returns (uint256);

    function getPositionOwner(bytes32 _key) external view returns (address);

    function getPositionIndexToken(bytes32 _key) external view returns (address);

    function getPositionCollateralToken(bytes32 _key) external view returns (address);

    function getPositionFinalPath(bytes32 _key) external view returns (address[] memory);

    function lastPositionIndex(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Position, OrderInfo, OrderType} from "../../constants/Structs.sol";

interface IVaultUtils {
    function validateConfirmDelay(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        bool _raise
    ) external view returns (bool);

    function validateDecreasePosition(
        address _indexToken,
        bool _isLong,
        bool _raise, 
        uint256 _indexPrice,
        Position memory _position
    ) external view returns (bool);

    function validateLiquidation(
        address _account,
        address _indexToken,
        bool _isLong,
        bool _raise, 
        uint256 _indexPrice,
        Position memory _position
    ) external view returns (uint256, uint256);

    function validatePositionData(
        bool _isLong,
        address _indexToken,
        OrderType _orderType,
        uint256 _latestTokenPrice,
        uint256[] memory _params,
        bool _raise
    ) external view returns (bool);

    function validateSizeCollateralAmount(uint256 _size, uint256 _collateral) external view;

    function validateTrailingStopInputData(
        bytes32 _key,
        bool _isLong,
        uint256[] memory _params,
        uint256 _indexPrice
    ) external view returns (bool);

    function validateTrailingStopPrice(
        bool _isLong,
        bytes32 _key,
        bool _raise,
        uint256 _indexPrice
    ) external view returns (bool);

    function validateTrigger(
        bool _isLong,
        uint256 _indexPrice,
        OrderInfo memory _order
    ) external pure returns (uint8);

    function validateTrigger(
        bytes32 _key,
        uint256 _indexPrice
    ) external view returns (uint8);

    function validateAmountIn(
        address _collateralToken,
        uint256 _amountIn,
        uint256 _collateralPrice
    ) external view returns (uint256);

    function validateAddCollateral(
        uint256 _amountIn,
        address _collateralToken,
        uint256 _collateralPrice,
        bytes32 _key
    ) external view returns (uint256);

    function validateAddCollateral(
        uint256 _positionSize, 
        uint256 _positionCollateral, 
        uint256 _amountIn,
        address _collateralToken,
        uint256 _collateralPrice
    ) external view returns (uint256);

    function validateRemoveCollateral(
        uint256 _amountIn, 
        bool _isLong,
        address _indexToken,
        uint256 _indexPrice,
        bytes32 _key
    ) external;

    function validateRemoveCollateral(
        uint256 _amountIn, 
        bool _isLong,
        address _indexToken,
        uint256 _indexPrice,
        Position memory _position
    ) external;

    function beforeDecreasePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _sizeDelta,
        uint256 _indexPrice,
        bool _isInternal
    ) external view returns (uint256[4] memory, bool, bool, Position memory);
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

import {VaultBond} from "../../constants/Structs.sol";

interface IVault {
    function accountDeltaAndFeeIntoTotalBalance(
        bool _hasProfit, 
        uint256 _adjustDelta, 
        uint256 _fee,
        address _token,
        uint256 _tokenPrice
    ) external;

    function distributeFee(address _account, address _refer, uint256 _fee, address _token) external;

    function takeAssetIn(
        address _account, 
        uint256 _amount, 
        address _token,
        bytes32 _key,
        uint256 _txType
    ) external;

    function collectVaultFee(
        address _refer, 
        uint256 _usdAmount
    ) external;

    function takeAssetOut(
        address _account, 
        address _refer, 
        uint256 _fee, 
        uint256 _usdOut, 
        address _token, 
        uint256 _tokenPrice
    ) external;

    function takeAssetBack(
        address _account, 
        bytes32 _key,
        uint256 _txType
    ) external;

    function decreaseBond(bytes32 _key, address _account, uint256 _txType) external;

    function transferBounty(address _account, uint256 _amount) external;

    function ROLP() external view returns(address);

    function RUSD() external view returns(address);

    function totalUSDReserved() external view returns(uint256);

    function totalROLP() external view returns(uint256);

    function updateTotalROLP() external;

    function updateBalance(address _token) external;

    function updateBalances() external;

    function getBalance(address _token) external view returns (uint256);

    function getBalances() external view returns (address[] memory, uint256[] memory);

    function convertRUSD(
        address _account,
        address _recipient, 
        address _tokenOut, 
        uint256 _amount
    ) external;

    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _rolpAmount, address _receiver) external;

    function emergencyDeposit(address _token, uint256 _amount) external;

    function getBond(bytes32 _key, uint256 _txType) external view returns (VaultBond memory);

    function getBondOwner(bytes32 _key, uint256 _txType) external view returns (address);

    function getBondToken(bytes32 _key, uint256 _txType) external view returns (address);

    function getBondAmount(bytes32 _key, uint256 _txType) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {PrepareTransaction, PositionBond, TxDetail, OrderType} from "../../constants/Structs.sol";

interface IRouter {
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
        address _refer,
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

    function getBond(bytes32 _key) external view returns (PositionBond memory);

    function getTxDetail(bytes32 _key, uint256 _txType) external view returns (TxDetail memory);
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
        uint256 _posId
    ) external view returns (bool);

    function validateTPSLTriggers(
        address _account,
        address _token,
        bool _isLong,
        uint256 _posId,
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
        address _account,
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

    function isEmergencyStop() external view returns (bool);

    function validateCollateralPathAndCheckSwap(address[] memory _collateralPath) external view returns (bool);
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