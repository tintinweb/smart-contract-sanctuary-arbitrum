// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BasePosition.sol";
import "./BaseRouter.sol";
import "../swap/interfaces/ISwapRouter.sol";
import "./interfaces/IRouter.sol";

import {BaseConstants} from "../constants/BaseConstants.sol";
import {Position, OrderInfo, VaultBond, OrderStatus} from "../constants/Structs.sol";

contract Router is BaseRouter, IRouter, ReentrancyGuard {
    mapping(bytes32 => PositionBond) private bonds;

    mapping(bytes32 => PrepareTransaction) private txns;
    mapping(bytes32 => mapping(uint256 => TxDetail)) private txnDetails;

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
        bool isFastExecute
    );
    event ExecutionReverted(
        bytes32 key, 
        address account, 
        bool isLong, 
        uint256 posId, 
        uint256[] params, 
        uint256[] prices,
        address[] collateralPath,
        uint256 txType,
        string err
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
        _validateExecutor();
        _prevalidate(_path, _params[_params.length - 1]);

        if (_orderType != OrderType.MARKET) {
            require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid triggerGasFee
            payable(executor).transfer(msg.value);
        }

        uint256 txType;

        //Scope to avoid stack too deep error
        {
            txType = _getTransactionTypeFromOrder(_orderType);
            _verifyParamsLength(txType, _params);
        }

        uint256 posId;
        Position memory position;
        OrderInfo memory order;

        //Scope to avoid stack too deep error
        {
            posId = positionKeeper.lastPositionIndex(msg.sender);
            (position, order) = positionKeeper.getPositions(msg.sender, _path[0], _isLong, posId);
            position.owner = msg.sender;
            position.refer = _refer;

            order.pendingCollateral = _params[4];
            order.pendingSize = _params[5];
            order.collateralToken = _path[1];
            order.status = OrderStatus.PENDING;
        }

        bytes32 key;

        //Scope to avoid stack too deep error
        {
            key = _getPositionKey(msg.sender, _path[0], _isLong, posId);
        }

        bool isFastExecute;
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            (isFastExecute, prices) = _getPricesAndCheckFastExecute(_path);
            vaultUtils.validatePositionData(
                _isLong, 
                _path[0], 
                _orderType, 
                prices[0], 
                _params, 
                true
            );

            _transferAssetToVault(
                msg.sender,
                _path[1],
                order.pendingCollateral,
                key,
                txType
            );

            PositionBond storage bond;
            bond = bonds[key];
            bond.owner = position.owner;
            bond.posId = posId;
            bond.isLong = _isLong;
            txnDetails[key][txType].params = _params;
            bond.leverage = order.pendingSize * BASIS_POINTS_DIVISOR / order.pendingCollateral;
        }

        if (_orderType == OrderType.MARKET) {
            order.positionType = POSITION_MARKET;
        } else if (_orderType == OrderType.LIMIT) {
            order.positionType = POSITION_LIMIT;
            order.lmtPrice = _params[2];
        } else if (_orderType == OrderType.STOP) {
            order.positionType = POSITION_STOP_MARKET;
            order.stpPrice = _params[3];
        } else if (_orderType == OrderType.STOP_LIMIT) {
            order.positionType = POSITION_STOP_LIMIT;
            order.lmtPrice = _params[2];
            order.stpPrice = _params[3];
        } else {
            revert("IVLOT"); //Invalid order type
        }

        if (isFastExecute && _orderType == OrderType.MARKET) {
            _openNewMarketPosition(
                key, 
                _path,
                prices, 
                _params, 
                order
            );
        } else {
            _createPrepareTransaction(
                msg.sender,
                _isLong,
                posId,
                txType,
                _params,
                _path,
                isFastExecute
            );
        }

        _processOpenNewPosition(
            txType,
            key,
            abi.encode(position, order),
            _params,
            prices,
            _path,
            isFastExecute
        );
    }

    function _openNewMarketPosition(
        bytes32 _key, 
        address[] memory _path,
        uint256[] memory _prices, 
        uint256[] memory _params,
        OrderInfo memory _order
    ) internal {
        uint256 pendingCollateral;
        bool isSwapSuccess = true;
                    
        if (_isSwapRequired(_path)) {
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
        } 

        if (!isSwapSuccess) {
            _order.status = OrderStatus.CANCELED;
            _revertExecute(
                _key,
                CREATE_POSITION_MARKET,
                true,
                _params,
                _prices,
                _path,
                "SWF" //Swap failed
            );
        }

        _order.status = OrderStatus.FILLED;
        delete txns[_key];
    }

    function _processOpenNewPosition(
        uint256 _txType,
        bytes32 _key, 
        bytes memory _data, 
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path,
        bool isFastExecute
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
            isFastExecute
        );

        if (_txType == CREATE_POSITION_MARKET && isFastExecute) {
            delete txns[_key];
            delete txnDetails[_key][CREATE_POSITION_MARKET];
        }
    }

    function _revertExecute(
        bytes32 _key, 
        uint256 _txType,
        bool _isTakeAssetBack,
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path,
        string memory err
    ) internal {
        if (_isTakeAssetBack) {
            _takeAssetBack(_key, _txType);

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
            _txType, 
            err
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

        uint256 txType = _isPlus ? ADD_COLLATERAL : REMOVE_COLLATERAL;
        bool isFastExecute;
        uint256[] memory prices;

        {
            (isFastExecute, prices) = _getPricesAndCheckFastExecute(_path);
            _modifyPosition(
                msg.sender,
                _isLong,
                _posId,
                txType,
                _isPlus ? true : false,
                _params,
                prices,
                _path,
                isFastExecute
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

        //Fast execute disabled for adding position
        (, uint256[] memory prices) = _getPricesAndCheckFastExecute(_path);
        _modifyPosition(
            msg.sender,
            _isLong,
            _posId,
            ADD_POSITION,
            true,
            _params,
            prices,
            _path,
            false
        );
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

       //Fast execute for adding trailing stop
        (, uint256[] memory  prices) = _getPricesAndCheckFastExecute(_path);
        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            ADD_TRAILING_STOP,
            false,
            _params,
            prices,
            _path,
            true
        );
    }

    function updateTrailingStop(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external override nonReentrant {
        _prevalidate(_indexToken);
        require(msg.sender == executor || msg.sender == _account, "IVLPO"); //Invalid positionOwner
        uint256[] memory prices = new uint256[](1);
        address[] memory path = _getSinglePath(_indexToken);
        (bool isFastExecute, uint256 price) = _getPriceAndCheckFastExecute(_indexToken);
        prices[0] = price;
        
        _modifyPosition(
            _account, 
            _isLong, 
            _posId,
            UPDATE_TRAILING_STOP,
            false,
            new uint256[](0),
            prices,
            path,
            isFastExecute
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

        (, uint256 indexPrice) = _getPriceAndCheckFastExecute(_indexToken);
        prices[0] = indexPrice;
        path[0] = _indexToken;

        //Fast execute for canceling pending order
        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            CANCEL_PENDING_ORDER,
            false,
            new uint256[](0),
            prices,
            path,
            true
        );
    }

    /*
    @dev: Trigger position from triggerOrderManager
    */
    function triggerPosition(
        bytes32 _key,
        bool _isFastExecute,
        uint256 _txType,
        address[] memory _path,
        uint256[] memory _prices
    ) external override {
        require(msg.sender == address(triggerOrderManager), "FBD"); //Forbidden
        _modifyPosition(
            bonds[_key].owner, 
            bonds[_key].isLong, 
            bonds[_key].posId,
            _txType,
            false,
            _getParams(_key, _txType),
            _prices,
            _path,
            msg.sender == executor ? true : _isFastExecute
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
        (bool isFastExecute, uint256[] memory prices) = _getPricesAndCheckFastExecute(_path);

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            CLOSE_POSITION,
            false,
            _params,
            prices,
            _path,
            isFastExecute
        );
    }

    function setPriceAndExecute(bytes32 _key, uint256 _txType, uint256[] memory _prices) external {
        require(msg.sender == executor || msg.sender == address(positionHandler), "FBD"); //Forbidden
        address[] memory path = getExecutePath(_key, _txType);
        require(path.length > 0 && path.length == _prices.length, "IVLARL"); //Invalid array length
        _setPriceAndExecute(_key, _txType, path, _prices);
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
        uint256[] memory _prices, 
        string memory err
    ) external override {
        require(msg.sender == executor || msg.sender == address(positionHandler), "FBD"); //Forbidden
        require(txns[_key].status == TRANSACTION_STATUS_PENDING, "IVLPTS/NPND"); //Invalid preapre transaction status, must pending
        address[] memory path = _getPath(_key, _txType);
        uint256[] memory params = _getParams(_key, _txType);
        require(path.length > 0 && params.length > 0, "IVLARL"); //Invalid array length
        require(_prices.length > 0, "IVLTPAL"); //Invalid token prices array length
        txns[_key].status == TRANSACTION_STATUS_EXECUTE_REVERTED;
        bool isTakeAssetBack = IVault(vault).getBondAmount(_key,  _txType) > 0 &&  (
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
            isTakeAssetBack,
            params, 
            _prices, 
            path,
            err
        );
    }

    function _modifyPosition(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType,
        bool _isTakeAssetRequired,
        uint256[] memory _params,
        uint256[] memory _prices,
        address[] memory _path,
        bool _isFastExecute
    ) internal {
        require(!settingsManager.isEmergencyStop(), "EMSTP"); //Emergency stopped
        bytes32 key;

        //Scope to avoid stack too deep error
        {
            key = _getPositionKey(_account, _path[0], _isLong, _posId);
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

            return;
        } 

        require(_params.length > 0, "IVLPRL");

        if (_txType == ADD_POSITION || 
            _txType == ADD_COLLATERAL ||
            _txType == REMOVE_COLLATERAL ||
            _txType == ADD_TRAILING_STOP ||
            _txType == UPDATE_TRAILING_STOP || 
            _txType == CLOSE_POSITION) {
            require(positionKeeper.getPositionSize(key) > 0, "IVLPS/NI"); //Invalid position, not initialized
        }

        //Transfer collateral to vault if required
        if (_isTakeAssetRequired) {
            _transferAssetToVault(
                _account,
                _path[1],
                _params[0],
                key,
                _txType
            );
        }

        if (!_isFastExecute || _txType == ADD_POSITION) {
            _createPrepareTransaction(
                _account,
                _isLong,
                _posId,
                _txType,
                _params,
                _path,
                _isFastExecute
            );
        } else {
            bytes memory data;
            uint256 amountIn = _params[0];
            bool isSwapSuccess = true;

            //Scope to avoid stack too deep error
            {
                uint256 swapAmountOut;

                if (_isSwapRequired(_path) && _isRequiredAmountOutMin(_txType)) {
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
                    true,
                    _params,
                    _prices,
                    _path,
                    "SWF"
                );

                delete txns[key];
                delete txnDetails[key][_txType];
                return;
            }

            uint256 executeTxType = _getTxTypeForExecuting(_txType);

            if (executeTxType == ADD_COLLATERAL || executeTxType == REMOVE_COLLATERAL) {
                data = abi.encode(amountIn, positionKeeper.getPosition(key));
            } else if (executeTxType == ADD_TRAILING_STOP) {
                data = abi.encode(_params, positionKeeper.getOrder(key));
            } else if (executeTxType == UPDATE_TRAILING_STOP) {
                data = abi.encode(_account, _isLong, positionKeeper.getOrder(key));
            }  else if (executeTxType == CANCEL_PENDING_ORDER) {
                data = abi.encode(positionKeeper.getOrder(key));
            } else if (executeTxType == CLOSE_POSITION) {
                (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(key);
                require(_params[0] <= position.size, "ISFPS"); //Insufficient position size
                data = abi.encode(_params[0], position, order);
            } else if (executeTxType == CONFIRM_POSITION) {
                data = abi.encode(
                    amountIn, 
                    amountIn * bonds[key].leverage / BASIS_POINTS_DIVISOR, 
                    positionKeeper.getPosition(key)
                );
            } else if (executeTxType == TRIGGER_POSITION) {
                (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(key);
                data = abi.encode(_account, position, order);
            } else {
                revert("IVLETXT"); //Invalid execute txType
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

            _clearPrepareTransaction(key, _txType);
        }
    }

    function clearPrepareTransaction(bytes32 _key, uint256 _txType) external {
        require(msg.sender == address(positionHandler), "FBD");
        _clearPrepareTransaction(_key, _txType);
    }

    function _clearPrepareTransaction(bytes32 _key, uint256 _txType) internal {
        delete txns[_key];
        delete txnDetails[_key][_txType];
    }

    function _executeOpenNewMarketPosition(
        bytes32 _key,
        address[] memory _path,
        uint256[] memory _prices,
        uint256[] memory _params
    ) internal {
        require(_params.length > 0 && _path.length > 0 && _path.length == _prices.length, "IVLARL"); //Invalid array length
        bool isValid = vaultUtils.validatePositionData(
            bonds[_key].isLong, 
            _path[0], 
            OrderType.MARKET, 
            _prices[0], 
            _params, 
            false
        );

        if (!isValid) {
            _revertExecute(
                _key,
                CREATE_POSITION_MARKET,
                true,
                _params,
                _prices,
                _path,
                "VLDF" //Validate failed
            );

            return;
        }

        (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(_key);
        _openNewMarketPosition(   
            _key, 
            _path,
            _prices,
            _params, 
            order
        );

        _processOpenNewPosition(
            CREATE_POSITION_MARKET,
            _key,
            abi.encode(position, order),
            _params,
            _prices,
            _path,
            true
        );
    }

    function _createPrepareTransaction(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _txType,
        uint256[] memory _params,
        address[] memory _path,
        bool isFastExecute
    ) internal {
        bytes32 key = _getPositionKey(_account, _path[0], _isLong, _posId);
        PrepareTransaction storage transaction = txns[key];
        require(transaction.status != TRANSACTION_STATUS_PENDING, "IVLPTS/PRCS"); //Invalid prepare transaction status, processing
        transaction.txType = _txType;
        transaction.startTime = block.timestamp;
        transaction.status = TRANSACTION_STATUS_PENDING;
        txnDetails[key][_txType].path = _path;
        txnDetails[key][_txType].params = _params;
        (, uint256 amountOutMin) = _extractDeadlineAndAmountOutMin(_txType, _params);

        if (_isSwapRequired(_path) && _isRequiredAmountOutMin(_txType)) {
            require(amountOutMin > 0, "IVLAOM");
        }

        emit CreatePrepareTransaction(
            _account,
            _isLong,
            _posId,
            _txType,
            _params,
            _path,
            key,
            isFastExecute
        );
    }

    function _extractDeadlineAndAmountOutMin(uint256 _type, uint256[] memory _params) internal view returns(uint256, uint256) {
        uint256 deadline;
        uint256 amountOutMin;

        if (_type == CREATE_POSITION_MARKET 
                || _type == CREATE_POSITION_LIMIT
                || _type == CREATE_POSITION_STOP_MARKET
                || _type == CREATE_POSITION_STOP_LIMIT) {
            deadline = _params[6];

            if (_type == CREATE_POSITION_MARKET) {
                require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
            }

            amountOutMin = _params[7];
        } else if (_type == REMOVE_COLLATERAL) {
            deadline = _params[1];
            require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
        } else if (_type == ADD_COLLATERAL) {
            deadline = _params[1];
            require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
            amountOutMin = _params[2];
        } else if (_type == ADD_POSITION) {
            deadline = _params[2];
            require(deadline > 0 && deadline > block.timestamp, "IVLDL"); //Invalid deadline
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
            isValid = _params.length == 8;
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
        require(_path.length > 0 && _path.length == _prices.length, "IVLARL"); //Invalid array length
        
        if (_txType == LIQUIDATE_POSITION) {
            _modifyPosition(
                bonds[_key].owner,
                bonds[_key].isLong,
                bonds[_key].posId,
                LIQUIDATE_POSITION,
                false,
                new uint256[](0),
                _prices,
                _path,
                true
            );
            txns[_key].status = TRANSACTION_STATUS_EXECUTED;

            return;
        } else if (_txType == CREATE_POSITION_MARKET) {
            _executeOpenNewMarketPosition(
                _key,
                _getPath(_key, CREATE_POSITION_MARKET),
                _prices,
                _getParams(_key, CREATE_POSITION_MARKET) 
            );

            return;
        }

        PrepareTransaction storage txn = txns[_key];
        require(txn.status == TRANSACTION_STATUS_PENDING, "IVLPTS/NPND"); //Invalid prepare transaction status, not pending
        txn.status = TRANSACTION_STATUS_EXECUTED;
        (uint256 deadline, ) = _extractDeadlineAndAmountOutMin(txn.txType, _getParams(_key, txn.txType));

        if (deadline > 0 && deadline <= block.timestamp) {
            _revertExecute(
                _key,
                txn.txType,
                txn.txType == REMOVE_COLLATERAL || txn.txType == CLOSE_POSITION ? false : true,
                _getParams(_key, txn.txType),
                _prices,
                _path,
                "DLEXD" //Deadline exceeded
            );

            return;
        }

        _modifyPosition(
            bonds[_key].owner,
            bonds[_key].isLong,
            bonds[_key].posId,
            txn.txType,
            false,
            _getParams(_key, txn.txType),
            _prices,
            _path,
            true
        );
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
        uint256 _amountIn,
        bytes32 _key,
        uint256 _txType
    ) internal {
        require(_amountIn > 0, "IVLAM"); //Invalid amount
        vault.takeAssetIn(_account, _amountIn, _token, _key, _txType);
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

        //Scope to avoid stack too deep error
        {
            try swapRouter.swapFromInternal(
                    bonds[_key].owner,
                    _key,
                    _txType,
                    token0,
                    _amountIn,
                    token1,
                    _amountOutMin
                ) returns (uint256 swapAmountOut) {
                    require(_amountOutMin >= swapAmountOut, "SWF/TLTR"); //Swap failed, too little received
                    return (true, swapAmountOut);
            } catch {
                return (false, _amountIn);
            }
        }
    }

    function _takeAssetBack(bytes32 _key, uint256 _txType) internal {
        vault.takeAssetBack(
            bonds[_key].owner, 
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
    
    //
    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory) {
        return txns[_key];
    }

    function getBond(bytes32 _key) external view returns (PositionBond memory) {
        return bonds[_key];
    }

    function getTxDetail(bytes32 _key, uint256 _txType) external view returns (TxDetail memory) {
        return txnDetails[_key][_txType];
    }

    function getPath(bytes32 _key, uint256 _txType) external view returns (address[] memory) {
        return _getPath(_key, _txType);
    }

    function getParams(bytes32 _key, uint256 _txType) external view returns (uint256[] memory) {
        return  _getParams(_key, _txType);
    }
    
    function _getPath(bytes32 _key, uint256 _txType) internal view returns (address[] memory) {
        return txnDetails[_key][_txType].path;
    }

    function getExecutePath(bytes32 _key, uint256 _txType) public view returns (address[] memory) {
        if (_isNotRequirePreparePath(_txType)) {
            return positionKeeper.getPositionFinalPath(_key);
        } else if (_txType == CONFIRM_POSITION) {
            return _getPath(_key, ADD_POSITION);
        } else {
            return _getPath(_key, _txType);
        }
    }

    function _isNotRequirePreparePath(uint256 _txType) internal pure returns (bool) {
        return _txType == TRIGGER_POSITION || _txType == REMOVE_COLLATERAL;
    }

    function _getParams(bytes32 _key, uint256 _txType) internal view returns (uint256[] memory) {
        return txnDetails[_key][_txType].params; 
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

    function _isRequiredAmountOutMin(uint256 _txType) internal pure returns (bool) {
        return _txType == CREATE_POSITION_MARKET ||
            _txType == CREATE_POSITION_LIMIT ||
            _txType == CREATE_POSITION_STOP_LIMIT ||
            _txType == CREATE_POSITION_STOP_MARKET ||
            _txType == ADD_COLLATERAL ||
            _txType == ADD_POSITION;
    }
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
    uint256 leverage;
    uint256 posId;
    bool isLong;
}

struct VaultBond {
    address owner;
    address token; //Collateral token
    uint256 amount; //Collateral amount
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

interface ISwapRouter {
    function swapFromInternal(
        address _account,
        bytes32 _key,
        uint256 _txType,
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
    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

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

    function getPositionIndexToken(bytes32 _key) external view returns (address);

    function getPositionCollateralToken(bytes32 _key) external view returns (address);

    function getPositionFinalPath(bytes32 _key) external view returns (address[] memory);

    function lastPositionIndex(address _account) external view returns (uint256);
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

    function getBond(bytes32 _key, uint256 _txType) external view returns (VaultBond memory);

    function getBondOwner(bytes32 _key, uint256 _txType) external view returns (address);

    function getBondToken(bytes32 _key, uint256 _txType) external view returns (address);

    function getBondAmount(bytes32 _key, uint256 _txType) external view returns (uint256);
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