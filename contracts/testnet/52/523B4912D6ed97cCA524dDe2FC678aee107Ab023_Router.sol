// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./BaseRouter.sol";
import "../swap/interfaces/ISwapRouter.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IRouter.sol";

import {BasePositionConstants} from "../constants/BasePositionConstants.sol";
import {BaseConstants} from "../constants/BaseConstants.sol";
import {Position, OrderInfo, OrderStatus} from "../constants/Structs.sol";

contract Router is BaseRouter, BasePositionConstants, IRouter, ReentrancyGuard {
    mapping(bytes32 => PrepareTransaction) private transactions;
    mapping(bytes32 => PositionBond) private bonds;
    mapping(bytes32 => address[]) private paths;

    ISwapRouter public swapRouter;
    address public executor;

    event SetSwapRouter(address swapRouter);
    event SetExecutor(address executor);
    event CreateDelayTransaction(
        address indexed account,
        bool isLong,
        uint256 posId,
        uint256 txType,
        uint256[] params,
        address[] path,
        bytes32 indexed key
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
        require(address(settingsManager) != address(0), "IVLSM/NI"); //Invalid SettingsManager, not initialized

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
        address _swapRouter
    ) BaseRouter(_vault, _positionHandler, _positionKeeper, _settingsManager, _priceManager) {
        if (_swapRouter != address(0)) {
            _setSwapRouter(_swapRouter);
        }
    }

    //Config functions
    function setSwapRouter(address _swapRouter) external onlyOwner {
        _setSwapRouter(_swapRouter);
    }

    function _setSwapRouter(address _swapRouter) private {
        require(Address.isContract(_swapRouter), "IVLSR"); //Invalid swap router
        swapRouter = ISwapRouter(_swapRouter);
        emit SetSwapRouter(_swapRouter);
    }

    function setExecutor(address _executor) external onlyOwner {
        require(!Address.isContract(_executor), "IVLE"); //Invalid executor
        executor = _executor;
        emit SetExecutor(_executor);
    }

    //End config functions

    /*
    @dev: Open new position.
    Path length must between 2 or 3 which:
        path[0] is approved index tradable token,
        path[1] is approved stable token,
        or path[1] is approved collateral token and path[2] is approved stable token. 
        If the collateral token not stable, the first path must be approved collateral and the last path must be approved stable.
    Params length must be 6.
        For all orders: 
        _params[2] is collateral, 
        _params[3] is position size (collateral * leverage),
        _params[4] is deadline (must be bigger than 0), if the transaction is delayed, check this deadline for executing or reverting.
        _params[5] is amount out min if the collateral token is not stable token, we will swap to a stable following path
        Market order:
            _params[0] is mark price
            _params[1] is slippage percentage
        Limit order:
            _params[0] is limit price
            _params[1] must be 0
        Stop-market order:
            _params[0] must be 0
            _params[1] is stop price
        Stop-limit order:
            _params[0] is limit price
            _params[1] is stop price
    */
    function openNewPosition(
        bool _isLong,
        OrderType _orderType,
        address _refer,
        uint256[] memory _params,
        address[] memory _path
    ) external payable nonReentrant preventTradeForForexCloseTime(_path[0]) {
        require(_params.length == 6, "IVLPL"); //Invalid params length
        _prevalidate(_path, _params[_params.length - 1]);

        if (_orderType != OrderType.MARKET) {
            require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid trigger gas fee
            payable(settingsManager.executor()).transfer(msg.value);
        }

        uint256 posId;
        Position memory position;
        OrderInfo memory order;
        PositionBond storage bond;

        //Scope to avoid stack too deep error
        {
            posId = positionKeeper.lastPositionIndex(msg.sender);
            (position, order) = positionKeeper.getPositions(msg.sender, _path[0], _isLong, posId);
            position.deadline = _params[_params.length - 2];
            position.owner = msg.sender;
            position.refer = _refer;

            order.pendingCollateral = _params[2];
            order.pendingSize = _params[3];
            order.collateralToken = _path[1];
            order.amountOutMin = _params[_params.length - 1];
            order.status = OrderStatus.PENDING;
        }

        {
            _transferAssetToVault(
                msg.sender,
                _refer,
                _path[1],
                order.pendingCollateral
            );

            bond = bonds[_getPositionKey(msg.sender, _path[0], _isLong, posId)];
            bond.owner = position.owner;
            bond.posId = posId;
            bond.indexToken = _path[0];
            bond.isLong = _isLong;
            bond.amount += order.pendingCollateral;
            bond.token = _path[1];
            bond.leverage = order.pendingSize * BASIS_POINTS_DIVISOR / order.pendingCollateral;
        }

        bool isDirectExecuted;
        uint256[] memory prices;
        bytes32 key;

        //Scope to avoid stack too deep error
        {
            (isDirectExecuted, , prices) = _getPricesAndCheckDirectExecute(_path);
        }


        if (_orderType == OrderType.MARKET) {
            order.positionType = POSITION_MARKET;

            if (isDirectExecuted) {
                key = _getPositionKey(msg.sender, _path[0], _isLong, posId);
                _openNewMarketPosition(
                    key, 
                    order, 
                    _params, 
                    prices, 
                    _path
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

        //Scope to avoid stack too deep error
        {
            key = _getPositionKey(msg.sender, _path[0], _isLong, posId);
            uint256 txType = _getTransactionTypeFromOrder(_orderType);

            _createPerepareTransaction(
                msg.sender,
                _isLong,
                posId,
                txType,
                _params,
                _path
            );

            if (isDirectExecuted && _orderType == OrderType.MARKET) {
                transactions[key].status = 1;
            }

            paths[key] = _path;
            _processOpenNewPosition(
                key,
                isDirectExecuted,
                abi.encode(position, order),
                _params,
                prices,
                _path
            );
        }
    }

    function _openNewMarketPosition(
        bytes32 _key, 
        OrderInfo memory _order, 
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path
    ) internal {
        if (_shouldSwap(_path)) {
            (bool isSuccess, uint256 swapAmountOut) = _processSwap(
                _key,
                _order.pendingCollateral,
                _order.amountOutMin,
                _path
            );

            if (!isSuccess) {
                _order.status = OrderStatus.CANCELED;
                _revertExecute(
                    _key,
                    POSITION_MARKET,
                    _order.pendingCollateral,
                    _params,
                    _prices,
                    _path
                );
            } else {
                _order.collateralToken = _getLastCollateralPath(_path);
                bonds[_key].token = _order.collateralToken;
                _order.pendingCollateral = _fromTokenToUSD(_getLastCollateralPath(_path), swapAmountOut, _prices[_prices.length - 1]) / PRICE_PRECISION;
                _order.pendingSize = _order.pendingCollateral * bonds[_key].leverage / BASIS_POINTS_DIVISOR;
                _order.status = OrderStatus.FILLED;
            }
        } else {
            _order.pendingCollateral = _fromTokenToUSD(_getFirstCollateralPath(_cutFrom(_path, 1)), _order.pendingCollateral, _prices[1]) / PRICE_PRECISION;
            _order.pendingSize = _order.pendingCollateral * bonds[_key].leverage / BASIS_POINTS_DIVISOR;
            _order.status = OrderStatus.FILLED;
        }
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
        uint256[] memory _params, 
        uint256[] memory _prices, 
        address[] memory _path
    ) internal {
        _takeAssetOut(_key, _revertAmount);

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

    function addCollateral(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external nonReentrant preventTradeForForexCloseTime(_path[0]) {
        _verifyParamsLength(ADD_COLLATERAL, _params);
        _prevalidate(_path, _params[_params.length - 1]);
        bool isDirectExecuted;
        uint256[] memory prices;

        {
            (isDirectExecuted, _path, prices) = _getPricesAndCheckDirectExecute(_path);
            _modifyPosition(
                msg.sender,
                _isLong,
                _posId,
                ADD_COLLATERAL,
                isDirectExecuted,
                true,
                _params,
                prices,
                _path
            );
        }
    }

    function removeCollateral(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _amount
    ) external nonReentrant preventTradeForForexCloseTime(_indexToken) {
        require(_amount > 0, "IVLA");
        bool isDirectExecuted;
        uint256[] memory prices;
        address[] memory path;

        {
            uint256[] memory params = new uint256[](1);
            params[0] = _amount;
            uint256 indexPrice;
            (isDirectExecuted, indexPrice) = _getPriceAndCheckDirectExecute(_indexToken);
            prices[0] = indexPrice;
            _modifyPosition(
                msg.sender,
                _isLong,
                _posId,
                REMOVE_COLLATERAL,
                isDirectExecuted,
                false,
                params,
                prices,
                path
            );
        }
    }

    function addPosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable nonReentrant preventTradeForForexCloseTime(_path[0]) {
        require(msg.value == settingsManager.triggerGasFee(), "IVLTGF");
        _verifyParamsLength(ADD_POSITION, _params);
        _prevalidate(_path, _params[_params.length - 1]);
        payable(settingsManager.executor()).transfer(msg.value);
        bool isDirectExecuted;
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            (isDirectExecuted, , prices) = _getPricesAndCheckDirectExecute(_path);
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
    ) external payable nonReentrant {
        require(msg.value == settingsManager.triggerGasFee(), "IVLTGF"); //Invalid trigger gas fee
        _prevalidate(_path, _params[_params.length - 1]);
        _verifyParamsLength(ADD_TRAILING_STOP, _params);
        payable(settingsManager.executor()).transfer(msg.value);
        bool isDirectExecuted;
        uint256[] memory prices;

        //Scope to avoid stack too deep error
        {
            (isDirectExecuted, , prices) = _getPricesAndCheckDirectExecute(_path);
        }

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            ADD_TRAILING_STOP,
            isDirectExecuted,
            true,
            _params,
            prices,
            _path
        );
    }

    function updateTrailingStop(
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) external nonReentrant {
        _prevalidate(_indexToken);
        require(positionKeeper.getPositionOwner(_getPositionKey(msg.sender, _indexToken, _isLong, _posId)) == msg.sender, "IVLPO"); //Invalid position owner
        bool isDirectExecuted;
        uint256[] memory prices = new uint256[](1);
        address[] memory path = new address[](1);
        path[0] = _indexToken;

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
    ) external nonReentrant {
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

    function closePosition(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external nonReentrant preventTradeForForexCloseTime(_indexToken) {
        _prevalidate(_indexToken);
        _verifyParamsLength(CLOSE_POSITION, _params);
        address[] memory path = new address[](2);        
        path[0] = _indexToken;
        path[1] = positionKeeper.getPositionCollateralToken(_getPositionKey(msg.sender, _indexToken, _isLong, _posId));
        (bool isDirectExecuted, , uint256[] memory prices) = _getPricesAndCheckDirectExecute(path);

        _modifyPosition(
            msg.sender, 
            _isLong, 
            _posId,
            CLOSE_POSITION,
            isDirectExecuted,
            false,
            _params,
            prices,
            path
        );
    }

    function setPriceAndExecute(bytes32 _key, bool _isLiquidate, uint256[] memory _prices) external nonReentrant {
        require(msg.sender == executor || msg.sender == address(positionHandler), "FBD"); //Forbidden
        require(transactions[_key].path.length == _prices.length, "IVLAL"); //Invalid array length
        _setPriceAndExecute(_key, _isLiquidate, _prices);
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
        bytes32 key; 

        {
            key = _getPositionKey(_account, _path[0], _isLong, _posId);
            require(bonds[key].owner == _account, "IVLPO"); //Invalid position owner
        }

        if (_txType == LIQUIDATE_POSITION) {
            positionHandler.modifyPosition(
                key, 
                LIQUIDATE_POSITION,
                abi.encode(positionKeeper.getPosition(key)),
                _path,
                _prices
            );

            return;
        }

        //Transfer collateral to vault if required
        if (_isTakeAssetRequired) {
            _transferAssetToVault(
                _account,
                address(0),
                _path[1],
                _params[0]
            );
            bonds[_getPositionKey(_account, _path[0], _isLong, _posId)].amount += _params[0];
            bonds[_getPositionKey(_account, _path[0], _isLong, _posId)].token = _path[1];
        }

        if (!_isDirectExecuted || _txType == ADD_POSITION) {
            _createPerepareTransaction(
                _account,
                _isLong,
                _posId,
                _txType,
                _params,
                _path
            );
        } else {
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
                        && _shouldSwap(_path)) {
                    (isSwapSuccess, swapAmountOut) = _processSwap(
                        key,
                        _params[0],
                        transactions[key].amountOutMin == 0 ? _params[_params.length - 1] : transactions[key].amountOutMin,
                        _path
                    );
                    amountIn = _fromTokenToUSD(_getLastCollateralPath(_path), swapAmountOut, _prices[_prices.length - 1]) * PRICE_PRECISION;
                }
            }

            if (!isSwapSuccess) {
                _revertExecute(
                    key,
                    _txType,
                    _params[0],
                    _params,
                    _prices,
                    _path
                );

                return;
            } else {
                bonds[key].token = _getLastCollateralPath(_path);
            }

            if (_txType == ADD_COLLATERAL || _txType == REMOVE_COLLATERAL) {
                data = abi.encode(amountIn, positionKeeper.getPosition(key));
            } else if (_txType == ADD_TRAILING_STOP) {
                _params[0] = amountIn;
                _params[1] = amountIn * bonds[key].leverage / BASIS_POINTS_DIVISOR;
                data = abi.encode(_params, positionKeeper.getOrder(key));
            } else if (_txType == UPDATE_TRAILING_STOP) {
                data = abi.encode(_isLong, positionKeeper.getOrder(key));
            } else if (_txType == CANCEL_PENDING_ORDER) {
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
                data = abi.encode(position, order);
            }

            positionHandler.modifyPosition(
                key, 
                _txType,
                data,
                _path,
                _prices
            );
        }
    }

    function _createPerepareTransaction(
        address _account,
        bool _isLong,
        uint256 _posId,
        uint256 _type,
        uint256[] memory _params,
        address[] memory _path
    ) internal {
        PrepareTransaction storage transaction = transactions[_getPositionKey(_account, _path[0], _isLong, _posId)];
        transaction.txType = _type;
        transaction.params = _params;
        transaction.path = _path;
        transaction.startTime = block.timestamp;
        transaction.status = 0;
        (uint256 deadline, uint256 amountOutMin) = _extractDeadlineAndAmountOutMin(_type, _params);
        require(deadline > 0, "IVLDDL/ZERO");
        require(deadline > block.timestamp, "IVLDDL/EXCD");

        if (_type != REMOVE_COLLATERAL && _type != CLOSE_POSITION
                && !settingsManager.isEnableNonStableCollateral() && _path.length > 2) {
            require(amountOutMin > 0, "IVLAOM");
        }

        transaction.deadline = deadline;
        transaction.amountOutMin = amountOutMin;

        emit CreateDelayTransaction(
            _account,
            _isLong,
            _posId,
            _type,
            _params,
            _path,
            _getPositionKey(_account, _path[0], _isLong, _posId)
        );
    }

    function _extractDeadlineAndAmountOutMin(uint256 _type, uint256[] memory _params) internal pure returns(uint256, uint256) {
        uint256 deadline;
        uint256 amountOutMin;

        if (_params.length == 6) {
            deadline = _params[4];
            amountOutMin = _params[5];
        } else if (_type == ADD_COLLATERAL) {
            deadline = _params[1];
            amountOutMin = _params[2];
        } else if (_type == ADD_POSITION) {
            deadline = _params[2];
            amountOutMin = _params[3];
        } else if (_type == ADD_TRAILING_STOP) {
            deadline = _params[4];
            amountOutMin = _params[5];
        } else if (_params.length == 2) {
            deadline = _params[1];
        }

        return (deadline, amountOutMin);
    }

    function _verifyParamsLength(uint256 _type, uint256[] memory _params) internal pure {
        bool isValid;

        if ((_type >= 0 && _type <= 3) || _type == ADD_TRAILING_STOP) {
            isValid = _params.length == 6;
        } else if (_type == ADD_COLLATERAL) {
            isValid = _params.length == 3;
        } else if (_type == ADD_POSITION) {
            isValid = _params.length == 4;
        } else if (_type == CLOSE_POSITION) {
            isValid = _params.length == 2;
        }

        require(isValid, "IVLPRL"); //Invalid params length
    }

    function _setPriceAndExecute(
        bytes32 _key, 
        bool _isLiquidate,
        uint256[] memory _prices
    ) internal {
        require(_prices.length >= 1, "IVLPL"); //Invalid prices length

        if (_isLiquidate) {
            _modifyPosition(
                bonds[_key].owner,
                bonds[_key].isLong,
                bonds[_key].posId,
                LIQUIDATE_POSITION,
                true,
                false,
                new uint256[](0),
                _prices,
                paths[_key]
            );
            transactions[_key].status = 1;
            return;
        } 

        PrepareTransaction storage txn = transactions[_key];

        if (txn.txType == ADD_POSITION) {
            txn.txType = CONFIRM_POSITION;
        } else if (txn.txType >= 1 && txn.txType <= 3) {
            txn.txType = TRIGGER_POSITION;
        }

        require(txn.status == 0, "IVLTS"); //Invalid transaction status
        txn.status = 1;

        if (txn.deadline <= block.timestamp) {
            _revertExecute(
                _key,
                txn.txType,
                bonds[_key].amount,
                txn.params,
                _prices,
                txn.path
            );

            return;
        }

        if (txn.txType == CREATE_POSITION_MARKET) {
            (Position memory position, OrderInfo memory order) = positionKeeper.getPositions(_key);
            _openNewMarketPosition(
                _key, 
                order, 
                txn.params, 
                _prices, 
                txn.path
            );

            _processOpenNewPosition(
                _key,
                true,
                abi.encode(position, order),
                txn.params,
                _prices,
                txn.path
            );
        } else {
            _modifyPosition(
                bonds[_key].owner,
                bonds[_key].isLong,
                bonds[_key].posId,
                txn.txType,
                true,
                false,
                txn.params,
                _prices,
                txn.path
            );
        }

        delete transactions[_key];
    }

    function _prevalidate(
        address[] memory _path, 
        uint256 _amountOutMin
    ) internal view {
        require(_path.length > 1 && _path.length <= 3, "IVLPTL");
        _prevalidate(_path[0]);
        address[] memory collateralPath = _cutFrom(_path, 1);

        if (settingsManager.isEnableNonStableCollateral()) {
            require(collateralPath.length == 1, "IVLCPLMB1");

            if (!_checkColalteralTokenIsStable(collateralPath[0])) { 
                revert("IVLCPNAT");
            }
        } else {
            require(collateralPath.length == 1 || collateralPath.length == 2, "IVLCPLMB12");
            require(settingsManager.isStable(_getLastCollateralPath(collateralPath)), "IVLCPLT");

            if (collateralPath.length == 2 && !settingsManager.isCollateral(collateralPath[0])) {
                revert("IVLCPFT");
            } 
            
            if (collateralPath.length == 2 && _amountOutMin == 0) {
                revert("IVLAOM");
            }
        }
    }

    function _getFirstCollateralPath(address[] memory _path) internal pure returns (address) {
        require(_path.length > 0 && _path.length <= 3, "ICPL");
        return _path[0];
    }

    function _getLastCollateralPath(address[] memory _path) internal pure returns (address) {
        require(_path.length > 0 && _path.length <= 3, "ICPL");
        return _path[_path.length - 1];
    }

    function _transferAssetToVault(
        address _account, 
        address _refer, 
        address _token,
        uint256 _amountIn
    ) internal {
        require(_amountIn > 0, "IVLAMI"); //Invalid amount in
        vault.takeAssetIn(_account, _refer, _amountIn, 0, _token);
    }

    function _checkColalteralTokenIsStable(address _collateralToken) internal view returns (bool) {
        bool isStable = settingsManager.isStable(_collateralToken);
        bool isCollateral = settingsManager.isCollateral(_collateralToken);
        require(isStable || isCollateral, "IVLCPNAT");
        require(!(isStable && isCollateral), "IVLSC/SM");
        return isStable;
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

    function _getPricesAndCheckDirectExecute(address[] memory _path) internal view returns (bool, address[] memory, uint256[] memory) {
        require(_path.length > 0 && _path.length <= 3, "IVLPTL");
        bool isDirectExecuted;
        uint256[] memory prices;

        {
            (prices, isDirectExecuted) = priceManager.getLatestSynchronizedPrices(
                _getMaxPriceUpdatedDelay(),
                _path
            );
        }

        return (isDirectExecuted, _path, prices);
    }

    function _getPriceAndCheckDirectExecute(address _indexToken) internal view returns (bool, uint256) {
        (uint256 price, uint256 updatedAt, bool isFastPrice) = priceManager.getLatestSynchronizedPrice(_indexToken);
        return ((block.timestamp - updatedAt <= _getMaxPriceUpdatedDelay()) && isFastPrice, price);
    }

    function _getMaxPriceUpdatedDelay() internal view returns (uint256) {
        return settingsManager.maxPriceUpdatedDelay();
    }

    function _shouldSwap(address[] memory _path) internal view returns (bool) {
        if (_path.length == 1) {
            return false;
        }

        address[] memory collateralPath = _cutFrom(_path, 1);

        return !(
            _checkColalteralTokenIsStable(_getFirstCollateralPath(collateralPath)) ||
            (collateralPath.length == 1 && settingsManager.isEnableNonStableCollateral())
        );
    }

    function _valdiateSwapRouter() internal view {
        require(address(swapRouter) != address(0), "IVLSR");
    }

    function _processSwap(
        bytes32 _key,
        uint256 _pendingCollateral, 
        uint256 _amountOutMin,
        address[] memory _path
    ) internal returns (bool, uint256) {
        bool isSwapSuccess; 
        uint256 swapAmountOut;

        {
            (isSwapSuccess, swapAmountOut) = _bondSwap(
                _key, 
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
        uint256 _amountIn, 
        uint256 _amountOutMin,
        address token0,
        address token1
    ) internal returns (bool, uint256) {
        require(token0 != address(0), "ZT0");
        require(token1 != address(0), "ZT1");
        require(token0 != token1, "ST0/1");
        _valdiateSwapRouter();
        PositionBond storage bond = bonds[_key];
        require(bond.amount >= _amountIn, "ISFB");
        bond.amount -= _amountIn;

        //Scope to avoid stack too deep error
        {
            try swapRouter.swapFromInternal(
                    _key,
                    token0,
                    _amountIn,
                    token1,
                    _amountOutMin
                ) returns (uint256 swapAmountOut) {
                    require(_amountOutMin >= swapAmountOut, "SWFTLTR"); //Swap failed, too little received
                    return (true, swapAmountOut);
            } catch {
                bond.amount += _amountIn;
                return (false, _amountIn);
            }
        }
    }

    function _takeAssetOut(bytes32 _key, uint256 _amountOut) internal {
        PositionBond storage bond = bonds[_key];
        require(bond.amount >= _amountOut, "ISFBA");
        bond.amount -= _amountOut;
        address token = bond.token;
        bond.token = address(0);

        vault.takeAssetOut(
            bond.owner, 
            address(0), 
            0,
            _amountOut, 
            token, 
            PRICE_PRECISION
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
    
    //View functions
    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory) {
        return transactions[_key];
    }

    function getBond(bytes32 _key) external view override returns (PositionBond memory) {
        return bonds[_key];
    }

    function getOriginalPath(bytes32 _key) external view returns (address[] memory) {
        return paths[_key];
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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./interfaces/IVault.sol";
import "./interfaces/IPositionHandler.sol";
import "./interfaces/IPositionKeeper.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IPriceManager.sol";

pragma solidity ^0.8.12;

abstract contract BaseRouter is Ownable {
    IVault public vault;
    IPositionHandler public positionHandler;
    IPositionKeeper public positionKeeper;
    IPriceManager public priceManager;
    ISettingsManager public settingsManager;

    event SetVault(address vault);
    event SetPositionHandler(address positionHandler);
    event SetPositionKeeper(address positionKeeper);
    event SetSettingsManager(address settingsManager);
    event SetPriceManager(address priceManager);

    constructor(
        address _vault, 
        address _positionHandler, 
        address _positionKeeper,
        address _settingsManager,
        address _priceManager
    ) {
        _setVault(_vault);
        _setPositionHandler(_positionHandler);
        _setPositionKeeper(_positionKeeper);
        _setSettingsManager(_settingsManager);
        _setPriceManager(_priceManager);
    }

    function setVault(address _vault) external onlyOwner {
        _setVault(_vault);
    }

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

    function _setVault(address _vault) private {
        require(Address.isContract(_vault), "IVLA"); //Invalid address
        vault = IVault(_vault);
        emit SetVault(_vault);
    }

    function _setPositionHandler(address _positionHandler) private {
        require(Address.isContract(_positionHandler), "IVLA"); //Invalid address
        positionHandler = IPositionHandler(_positionHandler);
        emit SetPositionHandler(_positionHandler);
    }

    function _setPositionKeeper(address _positionKeeper) private {
        require(Address.isContract(_positionKeeper), "IVLA"); //Invalid address
        positionKeeper = IPositionKeeper(_positionKeeper);
        emit SetPositionKeeper(_positionKeeper);
    }

    function _setSettingsManager(address _settingsManager) private {
        require(Address.isContract(_settingsManager), "IVLA"); //Invalid address
        settingsManager = ISettingsManager(_settingsManager);
        emit SetSettingsManager(_settingsManager);
    }

    function _setPriceManager(address _priceManager) private {
        require(Address.isContract(_priceManager), "IVLA"); //Invalid address
        priceManager = IPriceManager(_priceManager);
        emit SetPriceManager(_priceManager);
    }

    function _prevalidate(address _indexToken) internal view {
        require(address(vault) != address(0), "NI/V"); //Vault not initialized
        require(address(positionHandler) != address(0), "NI/PH"); //PositionHandler not initialized
        require(address(positionKeeper) != address(0), "NI/PK"); //PositionKeeper not intialized
        require(address(priceManager) != address(0), "NI/PM"); //PriceManager not intialized
        require(settingsManager.marketOrderEnabled(), "SER/MOD"); //Market order disabled
        require(settingsManager.isTradable(_indexToken), "SER/NAT"); //Not tradable token
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract BasePositionConstants {
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
    uint256 public constant CANCEL_PENDING_ORDER = 11;
    uint256 public constant CLOSE_POSITION = 12;
    uint256 public constant LIQUIDATE_POSITION = 13;

    function _getPositionKey(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _posId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _isLong, _posId));
    }

    function _cutFrom(address[] memory _arr, uint256 _startIndex) internal pure returns (address[] memory) {
        require(_arr.length > 1 && _arr.length <= 3, "IVLAL");
        address[] memory newArr;

        if (_arr.length == 2 && _startIndex == 1) {
            newArr = new address[](1);
            newArr[0] = _arr[1];
            return newArr;
        }

        require(_startIndex < _arr.length - 1, "IVLAL/S");
        newArr = new address[](_arr.length - _startIndex);
        uint256 count = 0;

        for (uint256 i = _startIndex; i < _arr.length; i++) {
            newArr[count] = _arr[i];
            count++;
        }

        return newArr;
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
    NONE,
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
    uint256 amountOutMin;
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
    uint256 deadline;
    uint256 slippage;
    uint256 totalFee;
}

struct TriggerOrder {
    bytes32 key;
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
    uint256 status; //0 = pending, 1 = executed
    uint256 deadline;
    uint256 amountOutMin;
    uint256[] params;
    address[] path;
}

struct PositionBond {
    address owner;
    address indexToken;
    address token; //Collateral token
    uint256 amount; //Collateral amount
    uint256 leverage;
    uint256 posId;
    bool isLong;
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

interface IStaking {
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {PrepareTransaction, PositionBond, OrderType} from "../../constants/Structs.sol";

interface IRouter {
    //Write functions

    /*
    @dev: Open new position.
    Path length must between 2 or 3 which:
        path[0] is approved index tradable token,
        path[1] is approved stable token,
        or path[1] is approved collateral token and path[2] is approved stable token. 
        If the collateral token not stable, the first path must be approved collateral and the last path must be approved stable.
    Params length must be 6.
        For all orders: 
        _params[2] is collateral, 
        _params[3] is position size (collateral * leverage),
        _params[4] is deadline (must be bigger than 0), if the transaction is delayed, check this deadline for executing or reverting.
        _params[5] is amount out min if the collateral token is not stable token, we will swap to a stable following path
        Market order:
            _params[0] is mark price
            _params[1] is slippage percentage
        Limit order:
            _params[0] is limit price
            _params[1] must be 0
        Stop-market order:
            _params[0] must be 0
            _params[1] is stop price
        Stop-limit order:
            _params[0] is limit price
            _params[1] is stop price
    */
    function openNewPosition(
        bool _isLong,
        OrderType _orderType,
        address _refer,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    function addCollateral(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external;

    function removeCollateral(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256 _amount
    ) external;

    function addPosition(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    function addTrailingStop(
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params,
        address[] memory _path
    ) external payable;

    function cancelPendingOrder(
        address _indexToken, 
        bool _isLong, 
        uint256 _posId
    ) external;

    //Params length must be 2, [0] is close size delta, [1] is deadline
    function closePosition(
        address _indexToken,
        bool _isLong,
        uint256 _posId,
        uint256[] memory _params
    ) external;

    function setPriceAndExecute(
        bytes32 _key, 
        bool _isLiquidate,
        uint256[] memory _prices
    ) external;

    //View functions
    function getTransaction(bytes32 _key) external view returns (PrepareTransaction memory);

    function getBond(bytes32 _key) external view returns (PositionBond memory);
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
        address _refer, 
        uint256 _amount, 
        uint256 _fee, 
        address _token
    ) external;

    function takeAssetOut(
        address _account, 
        address _refer, 
        uint256 _fee, 
        uint256 _usdOut, 
        address _token, 
        uint256 _tokenPrice
    ) external;

    function transferBounty(
        address _account, 
        uint256 _amount, 
        address _token, 
        uint256 _tokenPrice
    ) external;

    function ROLP() external view returns(address);

    function RUSD() external view returns(address);

    function totalUSD() external view returns(uint256);

    function totalROLP() external view returns(uint256);

    function updateTotalROLP() external;

    function updateBalance(address _token) external;

    function updateBalances() external;

    function getBalance(address _token) external view returns (uint256);

    function getBalances() external view returns (address[] memory, uint256[] memory);

    // function convertRUSD(
    //     address _token, 
    //     address _recipient, 
    //     uint256 _amount
    // ) external;

    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _rolpAmount, address _receiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {Position, PositionBond, OrderInfo, OrderType} from "../../constants/Structs.sol";

interface IPositionHandler {
    function getBond(bytes32 _key) external view returns (PositionBond memory);

    function openNewPosition(
        bytes32 _key,
        bool _isLong, 
        uint256 _posId,
        bytes memory _data,
        uint256[] memory _params,
        uint256[] memory _prices, 
        address[] memory _path,
        bool _isDirectExecuted
    ) external;

    function modifyPosition(
        bytes32 _key, 
        uint256 _txType, 
        bytes memory _data,
        address[] memory path,
        uint256[] memory prices
    ) external;

    function setPriceAndExecuteInBatch(
        bytes32[] memory _keys, 
        bool[] memory _isLiquidates, 
        address[][] memory _batchPath,
        uint256[][] memory _batchPrices
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {SwapPath} from "../../constants/Structs.sol";

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

    function executor() external view returns (address);

    function priceMovementPercent() external view returns (uint256);

    function referFee() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function positionDefaultSlippage() external view returns (uint256);

    function setPositionDefaultSlippage(uint256 _slippage) external;

    function isOnBeta() external view returns (bool);

    function isEnableNonStableCollateral() external view returns (bool);

    function isEnableConvertRUSD() external view returns (bool);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;
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

    function getPositionOwner(bytes32 _key) external view returns (address);

    function getPositionCollateralToken(bytes32 _key) external view returns (address);

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

    function getLatestSynchronizedPrices(uint256 _maxDelayAllowance, address[] memory _tokens) external view returns (uint256[] memory, bool);

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

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view returns (uint256);
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