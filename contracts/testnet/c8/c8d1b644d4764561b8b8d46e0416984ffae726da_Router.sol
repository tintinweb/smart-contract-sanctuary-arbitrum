// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

import "./BaseRouter.sol";
import "../swap/interfaces/ISwapRouter.sol";
import "./interfaces/IRouter.sol";

import "./BasePosition.sol";
import {BaseConstants} from "../constants/BaseConstants.sol";
import {Position, OrderInfo, OrderStatus} from "../constants/Structs.sol";

contract Router is BaseRouter, IRouter, ReentrancyGuard {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    mapping(bytes32 => PrepareTransaction) private transactions;
    mapping(bytes32 => Bond) public bonds;
    mapping(bytes32 => mapping(uint256 => BondDetail)) private bondDetails;
    EnumerableMap.AddressToUintMap private lastPrices;

    address public triggerOrderManager;
    ISwapRouter public swapRouter;

    event SetTriggerOrderManager(address triggerOrderManager);
    event SetSwapRouter(address swapRouter);
    event CreatePrepareTransaction(
        address indexed account,
        bool isLong,
        uint256 posId,
        uint256 txType,
        uint256[] params,
        address[] path,
        bytes32 indexed key,
        bool isDirectExecute
    );
    event ExecutionReverted(
        bytes32 key, 
        address account, 
        bool isLong, 
        uint256 posId, 
        uint256[] params, 
        uint256[] prices,
        address[] collateralPath,
        uint256 txType
    );

    modifier preventTradeForForexCloseTime(address _token) {
        if (priceManager.isForex(_token)) {
            require(!settingsManager.pauseForexForCloseTime() , "PTFCT"); //Prevent trade for forex close time
        }
        _;
    }

    constructor(
        address _vault, 
        address _positionHandler, 
        address _positionKeeper,
        address _settingsManager,
        address _priceManager,
        address _vaultUtils,
        address _triggerOrderManager,
        address _swapRouter
    ) BaseRouter(_vault, _positionHandler, _positionKeeper, _settingsManager, _priceManager, _vaultUtils) {
        _setTriggerOrderManager(_triggerOrderManager);
        _setSwapRouter(_swapRouter);
    }

    //Config functions
    function setTriggerOrderManager(address _triggerOrderManager) external onlyOwner {
        _setTriggerOrderManager(_triggerOrderManager);
    }

    function setSwapRouter(address _swapRouter) external onlyOwner {
        _setSwapRouter(_swapRouter);
    }

    function _setTriggerOrderManager(address _triggerOrderManager) internal {
        triggerOrderManager = _triggerOrderManager;
        emit SetTriggerOrderManager(_triggerOrderManager);
    }

    function _setSwapRouter(address _swapRouter) private {
        swapRouter = ISwapRouter(_swapRouter);
        emit SetSwapRouter(_swapRouter);
    }
    //End config functions

    function openNewPosition(
        bool _isLong,
        OrderType _orderType,
        address _refer,
        uint256[] memory _params,
        address[] memory _path
    ) external payable nonReentrant preventTradeForForexCloseTime(_path[0]) {
        require(!settingsManager.isEmergencyStop(), "EMSTP"); //Emergency stopped
        require(_params.length == 6, "IVLPRL"); //Invalid params length
        _validateExecutor();
        _prevalidate(_path, _params[_params.length - 1]);

        if (_orderType != OrderType.MARKET) {
            require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid triggerGasFee
            payable(executor).transfer(msg.value);
        }

        uint256 posId;
        Position memory position;
        OrderInfo memory order;
        Bond storage bond;

        //Scope to avoid stack too deep error
        {
            posId = positionKeeper.lastPositionIndex(msg.sender);
            (position, order) = positionKeeper.getPositions(msg.sender, _path[0], _isLong, posId);
            position.owner = msg.sender;
            position.refer = _refer;

            order.pendingCollateral = _params[2];
            order.pendingSize = _params[3];
            order.collateralToken = _path[1];
            order.status = OrderStatus.PENDING;
        }

        bytes32 key;
        uint256 txType;

        //Scope to avoid stack too deep error
        {
            key = _getPositionKey(msg.sender, _path[0], _isLong, posId);
            txType = _getTransactionTypeFromOrder(_orderType);
        }

        bool isDirectExecuted;
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            (isDirectExecuted, prices) = _getPricesAndCheckDirectExecute(_path);
            _transferAssetToVault(
                msg.sender,
                _path[1],
                order.pendingCollateral
            );

            bond = bonds[key];
            bond.owner = position.owner;
            bond.posId = posId;
            //bond.indexToken = _path[0];
            bond.isLong = _isLong;
            bondDetails[key][txType].amount += order.pendingCollateral;
            bondDetails[key][txType].token = _path[1];
            bondDetails[key][txType].params = _params;
            bond.leverage = order.pendingSize * BASIS_POINTS_DIVISOR / order.pendingCollateral;
        }

        if (_orderType == OrderType.MARKET) {
            order.positionType = POSITION_MARKET;

            if (isDirectExecuted) {
                _openNewMarketPosition(
                    msg.sender,
                    key, 
                    _path,
                    prices, 
                    _params, 
                    order
                );
            } 
        } else if (_orderType == OrderType.LIMIT) {
            order.positionType = POSITION_LIMIT;
            order.lmtPrice = _params[0];
        } else if (_orderType == OrderType.STOP) {
            order.positionType = POSITION_STOP_MARKET;
            order.stpPrice = _params[1];
        } else if (_orderType == OrderType.STOP_LIMIT) {
            order.positionType = POSITION_STOP_LIMIT;
            order.lmtPrice = _params[0];
            order.stpPrice = _params[1];
        } else {
            revert("IVLOT"); //Invalid order type
        }

        _createPerepareTransaction(
            msg.sender,
            _isLong,
            posId,
            txType,
            _params,
            _path,
            isDirectExecuted
        );

        _processOpenNewPosition(
            key,
            isDirectExecuted,
            abi.encode(position, order),
            _params,
            prices,
            _path
        );
    }

    function _openNewMarketPosition(
        address _account,
        bytes32 _key, 
        address[] memory _path,
        uint256[] memory _prices, 
        uint256[] memory _params,
        OrderInfo memory _order
    ) internal {
        uint256 pendingCollateral;
                    
        if (_isSwapRequired(_path)) {
            bool isSwapSuccess; 
            uint256 swapAmountOut;

            //Scope to avoid stack too deep error
            {
                pendingCollateral = _order.pendingCollateral;
                _order.pendingCollateral = 0;
                (, uint256 amountOutMin) = _extractDeadlineAndAmountOutMin(CREATE_POSITION_MARKET, _params);
                require(amountOutMin > 0, "IVLAOM"); //Invalid amounOutMin
                (isSwapSuccess, swapAmountOut) = _processSwap(
                    _key,
                    pendingCollateral,
                    amountOutMin,
                    CREATE_POSITION_MARKET,
                    _path
                );
            }

            if (!isSwapSuccess) {
                _order.status = OrderStatus.CANCELED;
                _revertExecute(
                    _key,
                    POSITION_MARKET,
                    pendingCollateral,
                    true,
                    _params,
                    _prices,
                    _path
                );

                delete transactions[_key];
                return;
            }
        } else {
            _order.status = OrderStatus.FILLED;
        }

        vault.reduceBond(_account, pendingCollateral, _path[1], _key, CREATE_POSITION_MARKET);
        bondDetails[_key][CREATE_POSITION_MARKET].token = address(0);
        bondDetails[_key][CREATE_POSITION_MARKET].amount -= pendingCollateral;
    }

    function _processOpenNewPosition(
        bytes32 _key, 
        bool _isDirectExecuted,
        bytes memory _data, 
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path  
    ) internal {
        positionHandler.openNewPosition(
            _key,
            bonds[_key].isLong,
            bonds[_key].posId,
            _isSwapRequired(_path) ? _path.length - 1 : 1,
            _data,
            _params, 
            _prices,
            _path,
            _isDirectExecuted
        );
    }

    function _revertExecute(
        bytes32 _key, 
        uint256 _txType,
        uint256 _revertAmount,
        bool _isTakeAssetBack,
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path
    ) internal {
        if (_isTakeAssetBack) {
            _takeAssetBack(_key, _revertAmount, _prices[1], _txType);

            if (_txType == CREATE_POSITION_STOP_MARKET) {
                (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(_key);
                positionHandler.modifyPosition(
                    bonds[_key].owner,
                    bonds[_key].isLong,
                    bonds[_key].posId,
                    REVERT_EXECUTE,
                    abi.encode(position, order),
                    _path,
                    _prices
                );
            }
        }

        emit ExecutionReverted(
            _key,
            bonds[_key].owner,
            bonds[_key].isLong,
            bonds[_key].posId,
            _params,
            _prices,
            _path,
            _txType
        );
    }

    function addOrRemoveCollateral(
        bool _isLong,
        uint256 _posId,
        bool _isPlus,
        uint256[] memory _params,
        address[] memory _path
    ) external override nonReentrant preventTradeForForexCloseTime(_path[0]) {
        if (_isPlus) {
            _verifyParamsLength(ADD_COLLATERAL, _params);
            _prevalidate(_path, _params[_params.length - 1]);
        } else {
            _verifyParamsLength(REMOVE_COLLATERAL, _params);
            _prevalidate(_path, 0, false);
        }

        bytes32 key = _getPositionKey(msg.sender, _path[0], _isLong, _posId);
        uint256 txType = _isPlus ? ADD_COLLATERAL : REMOVE_COLLATERAL;
        _checkInProcessing(key, txType);
        bool isDirectExecuted;
        uint256[] memory prices;

        {
            (isDirectExecuted, prices) = _getPricesAndCheckDirectExecute(_path);
            _modifyPosition(
                msg.sender,
                _isLong,
                _posId,
                txType,
                isDirectExecuted,
                _isPlus ? true : false,
                _params,
                prices,
                _path
            );
        }
    }

    function addPosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable override nonReentrant preventTradeForForexCloseTime(_path[0]) {
        require(msg.value == settingsManager.triggerGasFee(), "IVLTGF");
        _verifyParamsLength(ADD_POSITION, _params);
        _prevalidate(_path, _params[_params.length - 1]);
        _validateExecutor();
        payable(executor).transfer(msg.value);
        bool isDirectExecuted;
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            (isDirectExecuted, prices) = _getPricesAndCheckDirectExecute(_path);
            _modifyPosition(
                msg.sender,
                _isLong,
                _posId,
                ADD_POSITION,
                isDirectExecuted,
                true,
                _params,
                prices,
                _path
            );
        }
    }

    function addTrailingStop(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable override nonReentrant {
        require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid triggerFasFee
        _validateExecutor();
        _prevalidate(_path, 0, false);
        _verifyParamsLength(ADD_TRAILING_STOP, _params);
        payable(executor).transfer(msg.value);
        bool isDirectExecuted;
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            (isDirectExecuted, prices) = _getPricesAndCheckDirectExecute(_path);
        }

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            ADD_TRAILING_STOP,
            isDirectExecuted,
            false,
            _params,
            prices,
            _path
        );
    }

    function updateTrailingStop(
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external override nonReentrant {
        _prevalidate(_indexToken);
        bool isDirectExecuted;
        uint256[] memory prices = new uint256[](1);
        address[] memory path = _getSinglePath(_indexToken);

        //Scope to avoid stack too deep error
        {
            uint256 price;
            (isDirectExecuted, price) = _getPriceAndCheckDirectExecute(_indexToken);
            prices[0] = price;
        }

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            UPDATE_TRAILING_STOP,
            isDirectExecuted,
            true,
            new uint256[](0),
            prices,
            path
        );
    }

    function cancelPendingOrder(
        address _indexToken, 
        bool _isLong, 
        uint256 _posId
    ) external override nonReentrant {
        _prevalidate(_indexToken);
        uint256[] memory prices;
        address[] memory path;

        (bool isDirectExecuted, uint256 indexPrice) = _getPriceAndCheckDirectExecute(_indexToken);
        prices[0] = indexPrice;
        path[0] = _indexToken;

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            CANCEL_PENDING_ORDER,
            isDirectExecuted,
            false,
            new uint256[](0),
            prices,
            path
        );
    }

    /*
    @dev: Trigger position from triggerOrderManager
    */
    function triggerPosition(
        bytes32 _key,
        bool _isDirectExecuted,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) external override {
        require(msg.sender == address(triggerOrderManager), "FBD"); //Forbidden
        require(_path.length > 0 && _path.length == _prices.length, "IVLARL"); //Invalid array length
        _modifyPosition(
            bonds[_key].owner, 
            bonds[_key].isLong, 
            bonds[_key].posId,
            _txType,
            _isDirectExecuted,
            false,
            _getParams(_key, _txType),
            _prices,
            _path
        );
    }

    function closePosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external override nonReentrant preventTradeForForexCloseTime(_path[0]) {
        _prevalidate(_path, 0, false);
        _verifyParamsLength(CLOSE_POSITION, _params);
        (bool isDirectExecuted, uint256[] memory prices) = _getPricesAndCheckDirectExecute(_path);

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            CLOSE_POSITION,
            isDirectExecuted,
            false,
            _params,
            prices,
            _path
        );
    }

    function setPriceAndExecute(bytes32 _key, uint256 _txType, uint256[] memory _prices) external {
        require(msg.sender == executor 
            || msg.sender == address(positionHandler) 
            || msg.sender == address(triggerOrderManager)
        , "FBD"); //Forbidden
        require(bondDetails[_key][_txType].path.length > 0, "NE/EXCTD"); //Transaction not exist or has already executed
        require(bondDetails[_key][_txType].path.length == _prices.length, "IVLARL"); //Invalid array length
        _setPriceAndExecute(_key, _getTxTypeForExecuting(_txType), bondDetails[_key][_txType].path, _prices);
    }

    function _getTxTypeForExecuting(uint256 _txType) internal pure returns (uint256) {
        if (_txType == ADD_POSITION) {
            _txType == CONFIRM_POSITION;
        } else if (_txType == CREATE_POSITION_LIMIT 
            || _txType == CREATE_POSITION_STOP_MARKET
            || _txType == CREATE_POSITION_STOP_LIMIT) {
            _txType = TRIGGER_POSITION;
        }

        return _txType;
    }

    function revertExecution(
        bytes32 _key, 
        uint256 _txType,
        uint256[] memory _prices 
    ) external override {
        require(msg.sender == executor || msg.sender == address(positionHandler), "FBD"); //Forbidden
        require(transactions[_key].status == TRANSACTION_PENDING, "IVLPTS/NPND"); //Invalid preapre transaction status, not pending
        address[] memory path = _getPath(_key, _txType);
        uint256[] memory params = _getParams(_key, _txType);
        require(path.length > 0 && params.length > 0, "IVLARL"); //Invalid array length
        require(_prices.length > 0, "IVLTPAL"); //Invalid token prices array length
        transactions[_key].status == TRANSACTION_EXECUTE_FAILED;
        uint256 revertAmount = bondDetails[_key][_txType].amount;
        bool isTakeAssetBack = revertAmount > 0 &&  (
            _txType == CREATE_POSITION_MARKET
            || _txType == CREATE_POSITION_LIMIT
            || _txType == CREATE_POSITION_STOP_MARKET
            || _txType == CREATE_POSITION_STOP_LIMIT
            || _txType == ADD_COLLATERAL
            || _txType == ADD_POSITION
        );

        _revertExecute(
            _key, 
            _txType,
            revertAmount,
            isTakeAssetBack,
            params, 
            _prices, 
            path
        );

        emit ExecutionReverted(
            _key,
            bonds[_key].owner,
            bonds[_key].isLong,
            bonds[_key].posId,
            params,
            _prices,
            path,
            _txType
        );
    }

    function _modifyPosition(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType,
        bool _isDirectExecuted,
        bool _isTakeAssetRequired,
        uint256[] memory _params,
        uint256[] memory _prices,
        address[] memory _path
    ) internal {
        require(!settingsManager.isEmergencyStop(), "EMSTP"); //Emergency stopped
        bytes32 key;

        //Scope to avoid stack too deep error
        {
            key = _getPositionKey(_account, _path[0], _isLong, _posId);
            require(bonds[key].owner == _account, "IVLPO"); //Invalid position owner
        }

        if (_txType == LIQUIDATE_POSITION) {
            positionHandler.modifyPosition(
                _account, 
                bonds[key].isLong,
                bonds[key].posId,
                LIQUIDATE_POSITION,
                abi.encode(positionKeeper.getPosition(key)),
                _path,
                _prices
            );

            delete transactions[key];
            return;
        }

        //Transfer collateral to vault if required
        if (_isTakeAssetRequired) {
            _transferAssetToVault(
                _account,
                _path[1],
                _params[0]
            );
            bondDetails[_getPositionKey(_account, _path[0], _isLong, _posId)][_txType].amount += _params[0];
            bondDetails[_getPositionKey(_account, _path[0], _isLong, _posId)][_txType].token = _path[1];
        }

        if (!_isDirectExecuted || _txType == ADD_POSITION) {
            _createPerepareTransaction(
                _account,
                _isLong,
                _posId,
                _txType,
                _params,
                _path,
                _isDirectExecuted
            );
        } else {
            bondDetails[key][_txType].path = new address[](0);
            bytes memory data;
            uint256 amountIn = _params[0];
            bool isSwapSuccess = true;

            //Scope to avoid stack too deep error
            {
                uint256 swapAmountOut;
                key = _getPositionKey(_account, _path[0], _isLong, _posId);

                if (_txType != REMOVE_COLLATERAL 
                        && _txType != CANCEL_PENDING_ORDER
                        && _txType != CLOSE_POSITION
                        && _isSwapRequired(_path)) {
                    uint256 amountOutMin = _params[_params.length - 1];
                    require(amountOutMin > 0, "IVLAOM"); //Invalid amount out min
                    (isSwapSuccess, swapAmountOut) = _processSwap(
                        key,
                        _params[0],
                        amountOutMin,
                        _txType,
                        _path
                    );
                    amountIn = _fromTokenToUSD(_getLastCollateralPath(_path), swapAmountOut, _prices[_prices.length - 1]);
                }
            }

            if (!isSwapSuccess) {
                _revertExecute(
                    key,
                    _txType,
                    _params[0],
                    true,
                    _params,
                    _prices,
                    _path
                );

                delete transactions[key];
                return;
            }

            bondDetails[key][_txType].token = address(0);
            bondDetails[key][_txType].amount -= amountIn;

            if (_txType == ADD_COLLATERAL || _txType == REMOVE_COLLATERAL) {
                data = abi.encode(amountIn, positionKeeper.getPosition(key));
            } else if (_txType == ADD_TRAILING_STOP) {
                data = abi.encode(_params, positionKeeper.getOrder(key));
            } else if (_txType == UPDATE_TRAILING_STOP) {
                data = abi.encode(_account, _isLong, positionKeeper.getOrder(key));
            }  else if (_txType == CANCEL_PENDING_ORDER) {
                (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(key);
                data = abi.encode(position, order);
            } else if (_txType == CLOSE_POSITION) {
                (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(key);
                require(_params[0] <= position.size, "ISFPS"); //Insufficient position size
                data = abi.encode(_params[0], position, order);
            } else if (_txType == CONFIRM_POSITION) {
                data = abi.encode(
                    amountIn, 
                    amountIn * bonds[key].leverage / BASIS_POINTS_DIVISOR, 
                    positionKeeper.getPosition(key)
                );
            } else if (_txType == TRIGGER_POSITION) {
                (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(key);
                data = abi.encode(_account, position, order);
            }

            positionHandler.modifyPosition(
                _account,
                bonds[key].isLong,
                bonds[key].posId,
                _txType,
                data,
                _path,
                _prices
            );

            delete transactions[key];
        }
    }

    function _createPerepareTransaction(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType,
        uint256[] memory _params,
        address[] memory _path,
        bool _isDirectExecuted
    ) internal {
        bytes32 key = _getPositionKey(_account, _path[0], _isLong, _posId);
        bondDetails[key][_txType].path = _path;
        PrepareTransaction storage transaction = transactions[key];
        require(transaction.status == 0, "IVLPTS/PND"); //Invalid prepare transaction status, on pending
        transaction.txType = _txType;
        transaction.startTime = block.timestamp;
        transaction.status = TRANSACTION_PENDING;
        (, uint256 amountOutMin) = _extractDeadlineAndAmountOutMin(_txType, _params);

        if (_txType != REMOVE_COLLATERAL && _txType != CLOSE_POSITION
                && !settingsManager.isEnableNonStableCollateral() && _path.length > 2) {
            require(amountOutMin > 0, "IVLAOM");
        }

        emit CreatePrepareTransaction(
            _account,
            _isLong,
            _posId,
            _txType,
            _params,
            _path,
            _getPositionKey(_account, _path[0], _isLong, _posId),
            _isDirectExecuted
        );
    }

    function _extractDeadlineAndAmountOutMin(uint256 _type, uint256[] memory _params) internal pure returns(uint256, uint256) {
        uint256 deadline;
        uint256 amountOutMin;

        if (_type == CREATE_POSITION_MARKET) {
            deadline = _params[4];
            require(deadline > 0, "IVLDL"); //Invalid deadline
            amountOutMin = _params[5];
        } else if (_type == ADD_COLLATERAL) {
            deadline = _params[1];
            require(deadline > 0, "IVLDL"); //Invalid deadline
            amountOutMin = _params[2];
        } else if (_type == REMOVE_COLLATERAL) {
            deadline = _params[1];
            require(deadline > 0, "IVLDL"); //Invalid deadline
        } else if (_type == ADD_POSITION) {
            deadline = _params[2];
            require(deadline > 0, "IVLDL"); //Invalid deadline
            amountOutMin = _params[3];
        }

        return (deadline, amountOutMin);
    }

    function _verifyParamsLength(uint256 _type, uint256[] memory _params) internal pure {
        bool isValid;

        if (_type == CREATE_POSITION_MARKET
            || _type == CREATE_POSITION_LIMIT
            || _type == CREATE_POSITION_STOP_MARKET
            || _type == CREATE_POSITION_STOP_LIMIT) {
            isValid = _params.length == 6;
        } else if (_type == ADD_COLLATERAL) {
            isValid = _params.length == 3;
        } else if (_type == REMOVE_COLLATERAL) {
            isValid = _params.length == 2;
        } else if (_type == ADD_POSITION) {
            isValid = _params.length == 4;
        } else if (_type == CLOSE_POSITION) {
            isValid = _params.length == 2;
        } else if (_type == ADD_TRAILING_STOP) {
            isValid = _params.length == 5;
        }

        require(isValid, "IVLPRL"); //Invalid params length
    }

    function _setPriceAndExecute(
        bytes32 _key, 
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) internal {
        require(_path.length > 0, "IVLPTL"); //Invalid path length
        require(_prices.length == _path.length, "IVLARL"); //Invalid array length
        if (_txType == LIQUIDATE_POSITION) {
            _modifyPosition(
                bonds[_key].owner,
                bonds[_key].isLong,
                bonds[_key].posId,
                LIQUIDATE_POSITION,
                true,
                false,
                new uint256[](0),
                _prices,
                _path
            );
            transactions[_key].status = 1;
            return;
        } 

        PrepareTransaction storage txn = transactions[_key];
        require(txn.status == TRANSACTION_PENDING, "IVLPTS/NPND"); //Invalid prepare transaction status, not pending
        txn.status = TRANSACTION_EXECUTED;
        (uint256 deadline, ) = _extractDeadlineAndAmountOutMin(txn.txType, _getParams(_key, txn.txType));

        if (deadline > 0 && deadline <= block.timestamp) {
            _revertExecute(
                _key,
                txn.txType,
                bondDetails[_key][txn.txType].amount,
                txn.txType == REMOVE_COLLATERAL || txn.txType == CLOSE_POSITION ? false : true,
                _getParams(_key, txn.txType),
                _prices,
                _path
            );

            return;
        }

        if (txn.txType == CREATE_POSITION_MARKET) {
            uint256[] memory params = _getParams(_key, CREATE_POSITION_MARKET);
            bool isValid = vaultUtils.validatePositionData(
                bonds[_key].isLong, 
                _path[0], 
                OrderType.MARKET, 
                _prices[0], 
                params, 
                false
            );

            if (!isValid) {
                uint256 revertAmount = bondDetails[_key][CREATE_POSITION_MARKET].amount;
                bondDetails[_key][CREATE_POSITION_MARKET].amount -= revertAmount;

                _revertExecute(
                    _key,
                    txn.txType,
                    revertAmount,
                    true,
                    params,
                    _prices,
                    _path
                );

                return;
            }

            (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(_key);
            _openNewMarketPosition(
                position.owner,
                _key, 
                _path,
                _prices,
                params, 
                order
            );

            _processOpenNewPosition(
                _key,
                true,
                abi.encode(position, order),
                params,
                _prices,
                _path
            );
        } else {
            _modifyPosition(
                bonds[_key].owner,
                bonds[_key].isLong,
                bonds[_key].posId,
                txn.txType,
                true,
                false,
                _getParams(_key, txn.txType),
                _prices,
                _path
            );
        }

        delete transactions[_key];
    }

    function _prevalidate(
        address[] memory _path, 
        uint256 _amountOutMin
    ) internal view {
        _prevalidate(_path, _amountOutMin, true);
    }

    function _prevalidate(
        address[] memory _path, 
        uint256 _amountOutMin,
        bool _isVerifyAmountOutMin
    ) internal view {
        require(_path.length >= 2 && _path.length <= 3, "IVLPTL"); //Invalid path length
        _prevalidate(_path[0]);
        address[] memory collateralPath = _cutFrom(_path, 1);
        bool shouldSwap = settingsManager.validateCollateralPathAndCheckSwap(collateralPath);

        if (shouldSwap && collateralPath.length == 2 && _isVerifyAmountOutMin && _amountOutMin == 0) {
            revert("IVLAOM"); //Invalid amountOutMin
        }
    }

    function _getFirstCollateralPath(address[] memory _path) internal pure returns (address) {
        return _path[0];
    }

    function _getLastCollateralPath(address[] memory _path) internal pure returns (address) {
        return _path[_path.length - 1];
    }

    function _transferAssetToVault(
        address _account, 
        address _token,
        uint256 _amountIn
    ) internal {
        require(_amountIn > 0, "IVLAM"); //Invalid amount
        vault.takeAssetIn(_account, _amountIn, _token);
    }

    function _fillIndexAndColalteralTokens(
        address _indexToken, 
        address[] memory _collateralPath
    ) internal pure returns (address[] memory) {
        address[] memory fillAddresses = new address[](_collateralPath.length + 1);
        
        for (uint256 i = 0; i < _collateralPath.length; i++) {
            fillAddresses[i] = i == 0 ? _indexToken : _collateralPath[i + 1];
        }

        return fillAddresses;
    }

    function _isSwapRequired(address[] memory _path) internal pure returns (bool) {
        if (_path.length == 2) {
            return false;
        }

        return _cutFrom(_path, 1).length != 1;
    }

    function _valdiateSwapRouter() internal view {
        require(address(swapRouter) != address(0), "IVLSR");
    }

    function _processSwap(
        bytes32 _key,
        uint256 _pendingCollateral, 
        uint256 _amountOutMin,
        uint256 _txType,
        address[] memory _path
    ) internal returns (bool, uint256) {
        bool isSwapSuccess; 
        uint256 swapAmountOut;

        {
            (isSwapSuccess, swapAmountOut) = _bondSwap(
                _key, 
                _txType,
                _pendingCollateral,
                _amountOutMin,
                _path[1],
                _getLastCollateralPath(_path)
            );
        }

        if (!isSwapSuccess) {
            return (false, _pendingCollateral);
        } 

        return (true, swapAmountOut); 
    }

    function _bondSwap(
        bytes32 _key,
        uint256 _txType,
        uint256 _amountIn, 
        uint256 _amountOutMin,
        address token0,
        address token1
    ) internal returns (bool, uint256) {
        require(token0 != address(0), "ZT0"); //Zero token0
        require(token1 != address(0), "ZT1"); //Zero token1
        require(token0 != token1, "ST0/1"); //Same token0/token1
        _valdiateSwapRouter();
        require(bondDetails[_key][_txType].amount >= _amountIn, "ISFB");
        bondDetails[_key][_txType].amount -= _amountIn;

        //Scope to avoid stack too deep error
        {
            try swapRouter.swapFromInternal(
                    _key,
                    token0,
                    _amountIn,
                    token1,
                    _amountOutMin
                ) returns (uint256 swapAmountOut) {
                    require(_amountOutMin >= swapAmountOut, "SWF/TLTR"); //Swap failed, too little received
                    return (true, swapAmountOut);
            } catch {
                bondDetails[_key][_txType].amount += _amountIn;
                return (false, _amountIn);
            }
        }
    }

    function _takeAssetBack(bytes32 _key, uint256 _amountOut, uint256 _tokenPrice, uint256 _txType) internal {
        require(bondDetails[_key][_txType].amount >= _amountOut, "ISFBA"); //Insufficient bond amount
        bondDetails[_key][_txType].amount -= _amountOut;
        address token = bondDetails[_key][_txType].token;
        require(token != address(0), "IVLBT"); //Invalid bond token
        bondDetails[_key][_txType].token = address(0);

        vault.takeAssetBack(
            bonds[_key].owner, 
            _amountOut, 
            token, 
            _tokenPrice,
            _key,
            _txType
        );
    }

    function _fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _price) internal view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }

        uint256 decimals = priceManager.tokenDecimals(_token);
        require(decimals > 0, "IVLDEC");
        return (_tokenAmount * _price) / (10 ** decimals);
    }

    function _checkInProcessing(bytes32 _key, uint256 _txType) internal view {
        require(bondDetails[_key][_txType].path.length == 0, "IPCS"); //In processing
    }
    
    //View functions
    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory) {
        return transactions[_key];
    }

    // function getBond(bytes32 _key) external view override returns (Bond memory) {
    //     return bonds[_key];
    // }

    function getPath(bytes32 _key, uint256 _txType) external view override returns (address[] memory) {
        return _getPath(_key, _txType);
    }

    function getParams(bytes32 _key, uint256 _txType) external view override returns (uint256[] memory) {
        return _getParams(_key, _txType);
    }

    function _getPath(bytes32 _key, uint256 _txType) internal view returns (address[] memory) {
        return bondDetails[_key][_txType].path;
    }

    function _getParams(bytes32 _key, uint256 _txType) internal view returns (uint256[] memory) {
        return bondDetails[_key][_txType].params; 
    }

    function _getTransactionTypeFromOrder(OrderType _orderType) internal pure returns (uint256) {
        if (_orderType == OrderType.MARKET) {
            return CREATE_POSITION_MARKET;
        } else if (_orderType == OrderType.LIMIT) {
            return CREATE_POSITION_LIMIT;
        } else if (_orderType == OrderType.STOP) {
            return CREATE_POSITION_STOP_MARKET;
        } else if (_orderType == OrderType.STOP_LIMIT) {
            return CREATE_POSITION_STOP_LIMIT;
        } else {
            revert("IVLOT"); //Invalid order type
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPositionKeeper.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/IVaultUtils.sol";
import "./BasePosition.sol";

pragma solidity ^0.8.12;

abstract contract BaseRouter is BasePosition {
    IVault public vault;
    IVaultUtils public vaultUtils;

    event SetVault(address vault);
    event SetVaultUtils(address vaultUtils);

    constructor(
        address _vault, 
        address _positionHandler, 
        address _positionKeeper,
        address _settingsManager,
        address _priceManager,
        address _vaultUtils
    ) BasePosition(_settingsManager, _priceManager) {
        _setVault(_vault);
        _setVaultUtils(_vaultUtils);
        _setPositionHandler(_positionHandler);
        _setPositionKeeper(_positionKeeper);
    }

    function setVault(address _vault) external onlyOwner {
        _setVault(_vault);
    }

    function setVaultUtils(address _vaultUtils) external onlyOwner {
        _setVaultUtils(_vaultUtils);
    }

    function _setVault(address _vault) private {
        vault = IVault(_vault);
        emit SetVault(_vault);
    }

    function _setVaultUtils(address _vaultUtils) private {
        vaultUtils = IVaultUtils(_vaultUtils);
        emit SetVaultUtils(_vaultUtils);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ISwapRouter {
    function swapFromInternal(
        bytes32 _key,
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut,
        uint256 _amountOutMin
    ) external returns (uint256);

    function swap(
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _receiver, 
        uint256 _amountOutMin 
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {PrepareTransaction, Bond, BondDetail, OrderType} from "../../constants/Structs.sol";

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
    Params length must be 6.
        For all orders: 
        params[2] is collateral
        params[3] is position size (collateral * leverage)
        params[4] is deadline, for market type must > 0, other is 0,
            if the transaction is delayed, check this deadline for executing or reverting
        params[5] is amountOutMin, if the collateral token is not stable, we will swap to a stable following path, 
            revert if swapOutAmount < amountOutMin
        Market order:
            params[0] is mark price
            params[1] is slippage percentage
        Limit order:
            params[0] is limit price
            params[1] must be 0
        Stop-market order:
            params[0] must be 0
            params[1] is stop price
        Stop-limit order:
            params[0] is limit price
            params[1] is stop price
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
        address _indexToken,
        bool _isLong,
        uint256 _posId
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
        bool _isDirectExecuted,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) external;

    /*
    @dev: Execute delay transaction, can only call by executor/positionHandler
    */
    function setPriceAndExecute(
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
        uint256[] memory _prices 
    ) external;

    //View functions
    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory);

    //function getBond(bytes32 _key) external view returns (Bond memory);

    function getPath(bytes32 _key, uint256 _txType) external view returns (address[] memory);

    function getParams(bytes32 _key, uint256 _txType) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/ISettingsManager.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPositionKeeper.sol";

import "../constants/BasePositionConstants.sol";

contract BasePosition is BasePositionConstants, Ownable {
    ISettingsManager public settingsManager;
    IPriceManager public priceManager;
    IPositionHandler public positionHandler;
    IPositionKeeper public positionKeeper;
    address public executor;

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
    event SetExecutor(address executor);

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

    function setExecutor(address _executor) external onlyOwner {
        require(!Address.isContract(_executor) && _executor != address(0), "IVLE/NVA"); //Invalid executor, not valid address
        executor = _executor;
        emit SetExecutor(_executor);
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

    function _validateExecutor() internal view {
        require(executor != address(0), "NI/E"); //Executor not initialized
    }

    function _getPriceAndCheckDirectExecute(address _indexToken) internal view returns (bool, uint256) {
        (uint256 price, , bool isDirectExecuted) = priceManager.getLatestSynchronizedPrice(_indexToken);
        return (isDirectExecuted, price);
    }

    function _getPricesAndCheckDirectExecute(address[] memory _path) internal view returns (bool, uint256[] memory) {
        require(_path.length >= 2 && _path.length <= 3, "IVLPTL");
        bool isDirectExecuted;
        uint256[] memory prices;

        {
            (prices, isDirectExecuted) = priceManager.getLatestSynchronizedPrices(_path);
        }

        return (isDirectExecuted, prices);
    }

    function _cutFrom(address[] memory _arr, uint256 _startIndex) internal pure returns (address[] memory) {
        require(_arr.length > 1 && _arr.length <= 3, "IVLARL"); //Invalid array length
        address[] memory newArr;

        if (_arr.length == 2 && _startIndex == 1) {
            newArr = new address[](1);
            newArr[0] = _arr[1];
            return newArr;
        }

        require(_startIndex < _arr.length - 1, "IVLARL/S"); //Invalid array length, startIndex
        newArr = new address[](_arr.length - _startIndex);
        uint256 count = 0;

        for (uint256 i = _startIndex; i < _arr.length; i++) {
            newArr[count] = _arr[i];
            count++;
        }

        return newArr;
    }

    function _getSinglePath(address _indexToken) internal pure returns (address[] memory) {
        address[] memory path = new address[](1);
        path[0] = _indexToken;
        return path;
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
    PENDING,
    OPEN,
    TRIGGERED,
    CANCELLED
}

enum DataType {
    POSITION,
    ORDER,
    TRANSACTION
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
    //uint256 amountOutMin;
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
    uint256 public constant TRANSACTION_PENDING = 1;
    uint256 public constant TRANSACTION_EXECUTED = 2;
    uint256 public constant TRANSACTION_EXECUTE_FAILED = 3;
    */
    uint256 status;
}

struct Bond {
    address owner;
    //address indexToken;
    uint256 leverage;
    uint256 posId;
    bool isLong;
}

struct BondDetail {
    address token; //Collateral token
    uint256 amount; //Collateral amount
    uint256[] params;
    address[] path;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

pragma solidity ^0.8.12;

interface IVault {
    function accountDeltaAndFeeIntoTotalBalance(
        bool _hasProfit, 
        uint256 _adjustDelta, 
        uint256 _fee,
        address _token
    ) external;

    function distributeFee(address _account, address _refer, uint256 _fee, address _token) external;

    function takeAssetIn(
        address _account, 
        uint256 _amount, 
        address _token
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
        uint256 _amount,
        address _token,
        uint256 _tokenPrice,
        bytes32 _key,
        uint256 _txType
    ) external;

    function reduceBond(
        address _account, 
        uint256 _amount, 
        address _token, 
        bytes32 _key,
        uint256 _txType
    ) external;

    function transferBounty(address _account, uint256 _amount) external;

    function ROLP() external view returns(address);

    function RUSD() external view returns(address);

    function totalUSD() external view returns(uint256);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Position, Bond, OrderInfo, OrderType} from "../../constants/Structs.sol";

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
        bool _isDirectExecuted
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

    function setPriceAndExecuteInBatch(
        address[] memory _path,
        uint256[] memory _prices,
        bytes32[] memory _keys, 
        uint256[] memory _txTypes
    ) external;
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
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee,
        uint256 _indexPrice
    ) external;

    function emitClosePositionEvent(
        address _account, 
        address _indexToken, 
        bool _isLong, 
        uint256 _posId, 
        uint256 _indexPrice
    ) external;

    function emitDecreasePositionEvent(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _sizeDelta,
        uint256 _fee,
        uint256 _indexPrice
    ) external;

    function emitLiquidatePositionEvent(
        address _account, 
        address _indexToken, 
        bool _isLong, 
        uint256 _posId, 
        uint256 _indexPrice
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

    function getPositionCollateralToken(bytes32 _key) external view returns (address);

    function lastPositionIndex(address _account) external view returns (uint256);
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

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function isForex(address _token) external view returns (bool);

    function maxLeverage(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _tokenPrice) external view returns (uint256);
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
    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant POSITION_MARKET = 0;
    uint256 public constant POSITION_LIMIT = 1;
    uint256 public constant POSITION_STOP_MARKET = 2;
    uint256 public constant POSITION_STOP_LIMIT = 3;
    uint256 public constant POSITION_TRAILING_STOP = 4;

    uint256 public constant CREATE_POSITION_MARKET = 0;
    uint256 public constant CREATE_POSITION_LIMIT = 1;
    uint256 public constant CREATE_POSITION_STOP_MARKET = 2;
    uint256 public constant CREATE_POSITION_STOP_LIMIT = 3;
    uint256 public constant ADD_COLLATERAL = 4;
    uint256 public constant REMOVE_COLLATERAL = 5;
    uint256 public constant ADD_POSITION = 6;
    uint256 public constant CONFIRM_POSITION = 7;
    uint256 public constant ADD_TRAILING_STOP = 8;
    uint256 public constant UPDATE_TRAILING_STOP = 9;
    uint256 public constant TRIGGER_POSITION = 10;
    uint256 public constant UPDATE_TRIGGER_POSITION = 11;
    uint256 public constant CANCEL_PENDING_ORDER = 12;
    uint256 public constant CLOSE_POSITION = 13;
    uint256 public constant LIQUIDATE_POSITION = 14;
    uint256 public constant REVERT_EXECUTE = 15;

    uint256 public constant TRANSACTION_PENDING = 1;
    uint256 public constant TRANSACTION_EXECUTED = 2;
    uint256 public constant TRANSACTION_EXECUTE_FAILED = 3;
    //End constant params

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }
}