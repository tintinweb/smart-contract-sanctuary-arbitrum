// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet} from "contracts/interfaces/ICopyWallet.sol";
import {IConfigs} from "contracts/interfaces/IConfigs.sol";
import {ICopyWalletGNSv8} from "contracts/interfaces/ICopyWalletGNSv8.sol";
import {CopyWallet} from "contracts/core/CopyWallet.sol";
import {IRouter} from "contracts/interfaces/GMXv1/IRouter.sol";
import {IPositionRouter} from "contracts/interfaces/GMXv1/IPositionRouter.sol";
import {IVault} from "contracts/interfaces/GMXv1/IVault.sol";
import {IPyth} from "contracts/interfaces/pyth/IPyth.sol";
import {PythStructs} from "contracts/interfaces/pyth/PythStructs.sol";
import {IGainsTrading} from "contracts/interfaces/GNSv8/IGainsTrading.sol";

contract CopyWalletGNSv8 is CopyWallet, ICopyWalletGNSv8 {
    /* ========== CONSTANTS ========== */
    bytes32 internal constant ETH_PRICE_FEED =
        0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace;
    /* ========== IMMUTABLES ========== */
    IGainsTrading internal immutable GAINS_TRADING;
    IPyth internal immutable PYTH;

    mapping(bytes32 => uint32) _keyIndexes;
    mapping(uint32 => TraderPosition) _traderPositions;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        ConstructorParams memory _params
    )
        CopyWallet(
            ICopyWallet.CopyWalletConstructorParams({
                factory: _params.factory,
                events: _params.events,
                configs: _params.configs,
                usdAsset: _params.usdAsset,
                automate: _params.automate,
                taskCreator: _params.taskCreator
            })
        )
    {
        GAINS_TRADING = IGainsTrading(_params.gainsTrading);
        PYTH = IPyth(_params.pyth);
    }

    /* ========== VIEWS ========== */

    function ethToUsd(uint256 _amount) public view override returns (uint256) {
        PythStructs.Price memory price = PYTH.getPriceUnsafe(ETH_PRICE_FEED);
        return (_convertToUint(price, 6) * _amount) / 10 ** 18;
    }

    function getTraderPosition(
        uint32 _index
    ) external view returns (TraderPosition memory traderPosition) {
        traderPosition = _traderPositions[_index];
    }

    function getKeyIndex(
        address _source,
        uint256 _sourceIndex
    ) external view returns (uint32 index) {
        bytes32 key = keccak256(abi.encodePacked(_source, _sourceIndex));
        index = _keyIndexes[key];
    }

    /* ========== PERPS ========== */

    function closePosition(uint32 _index) external nonReentrant {
        if (!isOwner(msg.sender)) revert Unauthorized();
        TraderPosition memory traderPosition = _traderPositions[_index];
        bytes32 key = keccak256(
            abi.encodePacked(
                traderPosition.trader,
                uint256(traderPosition.index)
            )
        );
        _closeOrder(traderPosition.trader, key, _index);
    }

    function _perpInit() internal override {}

    function _perpWithdrawAllMargin(bytes calldata _inputs) internal override {}

    function _perpModifyCollateral(bytes calldata _inputs) internal override {}

    function _perpCancelOrder(bytes calldata _inputs) internal override {
        uint256 index;
        assembly {
            index := calldataload(_inputs.offset)
        }
        GAINS_TRADING.cancelOpenOrder(uint32(index));
    }

    function _perpPlaceOrder(bytes calldata _inputs) internal override {
        address source;
        uint256 sourceIndex;
        uint256 pairIndex;
        bool isLong;
        uint256 collateral;
        uint256 leverage;
        uint256 price;
        uint256 tp;
        uint256 sl;
        assembly {
            source := calldataload(_inputs.offset)
            sourceIndex := calldataload(add(_inputs.offset, 0x20))
            pairIndex := calldataload(add(_inputs.offset, 0x40))
            isLong := calldataload(add(_inputs.offset, 0x60))
            collateral := calldataload(add(_inputs.offset, 0x80))
            leverage := calldataload(add(_inputs.offset, 0xa0))
            price := calldataload(add(_inputs.offset, 0xc0))
            tp := calldataload(add(_inputs.offset, 0xe0))
            sl := calldataload(add(_inputs.offset, 0x100))
        }
        _placeOrder({
            _source: source,
            _sourceIndex: sourceIndex,
            _pairIndex: pairIndex,
            _isLong: isLong,
            _collateral: collateral,
            _leverage: leverage,
            _price: price,
            _tp: tp,
            _sl: sl
        });
    }

    function _perpCloseOrder(bytes calldata _inputs) internal override {
        address source;
        uint256 sourceIndex;
        assembly {
            source := calldataload(_inputs.offset)
            sourceIndex := calldataload(add(_inputs.offset, 0x20))
        }

        bytes32 key = keccak256(abi.encodePacked(source, sourceIndex));
        uint32 index = _keyIndexes[key];
        TraderPosition memory traderPosition = _traderPositions[index];

        if (
            traderPosition.trader != source ||
            traderPosition.index != sourceIndex
        ) {
            revert SourceMismatch();
        }

        _closeOrder(source, key, index);
    }

    function _placeOrder(
        address _source,
        uint256 _sourceIndex,
        uint256 _pairIndex,
        bool _isLong,
        uint256 _collateral,
        uint256 _leverage,
        uint256 _price,
        uint256 _tp,
        uint256 _sl
    ) internal {
        bytes32 key = keccak256(abi.encodePacked(_source, _sourceIndex));
        if (_keyIndexes[key] > 0) {
            revert PositionExist();
        }
        IGainsTrading.Counter memory counter = GAINS_TRADING.getCounters(
            address(this),
            IGainsTrading.CounterType.TRADE
        );
        IGainsTrading.Trade memory trade;
        trade.user = address(this);
        trade.isOpen = true;
        trade.long = _isLong;
        trade.collateralIndex = 3;
        trade.pairIndex = uint16(_pairIndex);
        trade.collateralAmount = uint120(_collateral);
        trade.leverage = uint24(_leverage);
        trade.openPrice = uint64(_price / 10 ** 8);
        trade.tp = uint64(_tp / 10 ** 8);
        trade.sl = uint64(_sl / 10 ** 8);
        trade.index = counter.currentIndex;

        TraderPosition memory traderPosition = TraderPosition({
            trader: _source,
            index: uint32(_sourceIndex),
            __placeholder: 0
        });

        _keyIndexes[key] = trade.index;
        _traderPositions[trade.index] = traderPosition;

        USD_ASSET.approve(address(GAINS_TRADING), _collateral);

        GAINS_TRADING.openTrade(trade, 300, CONFIGS.feeReceiver());

        _postOrder({
            _id: uint256(key),
            _source: _source,
            _lastSizeUsd: 0,
            _sizeDeltaUsd: (_collateral * _leverage) / 1000,
            _isIncrease: true
        });
    }

    function _closeOrder(
        address _source,
        bytes32 _key,
        uint32 _index
    ) internal {
        IGainsTrading.Trade memory trade = GAINS_TRADING.getTrade(
            address(this),
            _index
        );

        GAINS_TRADING.closeTradeMarket(_index);

        uint256 size = (trade.collateralAmount * trade.leverage) / 1000;

        _postOrder({
            _id: uint256(_key),
            _source: _source,
            _lastSizeUsd: size,
            _sizeDeltaUsd: size,
            _isIncrease: false
        });
    }

    /* ========== TASKS ========== */

    // TODO task
    // function _perpValidTask(
    //     Task memory _task
    // ) internal view override returns (bool) {
    //     uint256 price = _indexPrice(address(uint160(_task.market)));
    //     if (_task.command == TaskCommand.STOP_ORDER) {
    //         if (_task.sizeDelta > 0) {
    //             // Long: increase position size (buy) once *above* trigger price
    //             // ex: unwind short position once price is above target price (prevent further loss)
    //             return price >= _task.triggerPrice;
    //         } else {
    //             // Short: decrease position size (sell) once *below* trigger price
    //             // ex: unwind long position once price is below trigger price (prevent further loss)
    //             return price <= _task.triggerPrice;
    //         }
    //     } else if (_task.command == TaskCommand.LIMIT_ORDER) {
    //         if (_task.sizeDelta > 0) {
    //             // Long: increase position size (buy) once *below* trigger price
    //             // ex: open long position once price is below trigger price
    //             return price <= _task.triggerPrice;
    //         } else {
    //             // Short: decrease position size (sell) once *above* trigger price
    //             // ex: open short position once price is above trigger price
    //             return price >= _task.triggerPrice;
    //         }
    //     }
    //     return false;
    // }
    // function _perpExecuteTask(
    //     uint256 _taskId,
    //     Task memory _task
    // ) internal override {
    //     bool isLong = _task.command == TaskCommand.LIMIT_ORDER && _task.sizeDelta > 0 || task.command == TaskCommand.STOP_ORDER && _task.sizeDelta < 0;
    //     // if margin was locked, free it
    //     if (_task.collateralDelta > 0) {
    //         lockedFund -= _abs(_task.collateralDelta);
    //     }
    //     if (_task.command == TaskCommand.STOP_ORDER) {
    //         (uint256 sizeUsdD30,,uint256 averagePriceD30) = getPosition(address(this), address(USD_ASSET), market, isLong);
    //         if (
    //             sizeUsdD30 == 0 ||
    //             _isSameSign(sizeUsdD30 * isLong ? 1 : -1 , _task.sizeDelta)
    //         ) {
    //             EVENTS.emitCancelGelatoTask({
    //                 taskId: _taskId,
    //                 gelatoTaskId: _task.gelatoTaskId,
    //                 reason: "INVALID_SIZE"
    //             });
    //             return;
    //         }
    //         if (_abs(_task.sizeDelta) > sizeUsdD30 / 10 ** 12) {
    //             // bound conditional order size delta to current position size
    //             _task.sizeDelta = -int256(sizeUsdD30 / 10 ** 12);
    //         }
    //     }

    //     if (_task.collateralDelta != 0) {
    //         if (_task.collateralDelta > 0) {
    //             _sufficientFund(_task.collateralDelta, true);
    //         }
    //     }
    //     _placeOrder({
    //         _source: _task.source,
    //         _market: address(uint160(_task.market)),
    //         _isLong: isLong,
    //         _isIncrease: _task.command == TaskCommand.LIMIT_ORDER,
    //         _collateralDelta: _task.collateralDelta > 0 ? _abs(_task.collateralDelta) : 0,
    //         _sizeUsdDelta: _abs(_task.sizeDelta),
    //         _acceptablePrice: _task.acceptablePrice
    //     });
    // }

    /* ========== UTILITIES ========== */

    function _convertToUint(
        PythStructs.Price memory price,
        uint8 targetDecimals
    ) private pure returns (uint256) {
        if (price.price < 0 || price.expo > 0 || price.expo < -255) {
            revert();
        }

        uint8 priceDecimals = uint8(uint32(-1 * price.expo));

        if (targetDecimals >= priceDecimals) {
            return
                uint(uint64(price.price)) *
                10 ** uint32(targetDecimals - priceDecimals);
        } else {
            return
                uint(uint64(price.price)) /
                10 ** uint32(priceDecimals - targetDecimals);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICopyWallet {
    enum Command {
        OWNER_MODIFY_FUND, //0
        OWNER_WITHDRAW_ETH, //1
        OWNER_WITHDRAW_TOKEN, //2
        PERP_CREATE_ACCOUNT, //3
        PERP_MODIFY_COLLATERAL, //4
        PERP_PLACE_ORDER, //5
        PERP_CLOSE_ORDER, //6
        PERP_CANCEL_ORDER, //7
        PERP_WITHDRAW_ALL_MARGIN, //8
        GELATO_CREATE_TASK, //9
        GELATO_UPDATE_TASK, //10
        GELETO_CANCEL_TASK //11
    }

    enum TaskCommand {
        STOP_ORDER, //0
        LIMIT_ORDER //1
    }

    struct CopyWalletConstructorParams {
        address factory;
        address events;
        address configs;
        address usdAsset;
        address automate;
        address taskCreator;
    }

    struct Position {
        address source;
        uint256 lastSizeUsd;
        uint256 lastSizeDeltaUsd;
        uint256 lastFeeUsd;
    }

    struct Task {
        bytes32 gelatoTaskId;
        TaskCommand command;
        address source;
        uint256 market;
        int256 collateralDelta;
        int256 sizeDelta;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        address referrer;
    }

    error LengthMismatch();

    error InvalidCommandType(uint256 commandType);

    error ZeroSizeDelta();

    error InsufficientAvailableFund(uint256 available, uint256 required);

    error EthWithdrawalFailed();

    error NoOpenPosition();

    error NoOrderFound();

    error NoTaskFound();

    error SourceMismatch();

    error PositionExist();

    error CannotExecuteTask(uint256 taskId, address executor);

    function VERSION() external view returns (bytes32);

    function executor() external view returns (address);

    function lockedFund() external view returns (uint256);

    function lockedFundD18() external view returns (uint256);

    function availableFund() external view returns (uint256);

    function availableFundD18() external view returns (uint256);

    function ethToUsd(uint256 _amount) external view returns (uint256);

    // TODO enable again
    // function checker(
    //     uint256 _taskId
    // ) external view returns (bool canExec, bytes memory execPayload);
    // function getTask(uint256 _taskId) external view returns (Task memory);
    // function executeTask(uint256 _taskId) external;

    function positions(uint256 _key) external view returns (Position memory);

    function init(address _owner, address _executor) external;

    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IConfigs {
    event ExecutorFeeSet(uint256 executorFee);

    event ProtocolFeeSet(uint256 protocolFee);

    event FeeReceiverSet(address feeReceiver);

    function executorFee() external view returns (uint256);

    function protocolFee() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function setExecutorFee(uint256 _executorFee) external;

    function setProtocolFee(uint256 _protocolFee) external;

    function setFeeReceiver(address _feeReceiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICopyWalletGNSv8 {
    error ExecutionFeeNotEnough();
    struct TraderPosition {
        address trader;
        uint32 index;
        uint64 __placeholder;
    }
    struct ConstructorParams {
        address factory;
        address events;
        address configs;
        address usdAsset;
        address automate;
        address taskCreator;
        address gainsTrading;
        address pyth;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ICopyWallet} from "../interfaces/ICopyWallet.sol";
import {IFactory} from "../interfaces/IFactory.sol";
import {IConfigs} from "../interfaces/IConfigs.sol";
import {IEvents} from "../interfaces/IEvents.sol";
import {ITaskCreator} from "../interfaces/ITaskCreator.sol";
import {IERC20} from "../interfaces/token/IERC20.sol";
import {IPerpsMarket} from "../interfaces/SNXv3/IPerpsMarket.sol";
import {Auth} from "../utils/Auth.sol";
import {AutomateReady} from "../utils/gelato/AutomateReady.sol";
import {Module, ModuleData, IAutomate} from "../utils/gelato/Types.sol";

abstract contract CopyWallet is
    ICopyWallet,
    Auth,
    AutomateReady,
    ReentrancyGuard
{
    /* ========== CONSTANTS ========== */

    bytes32 public constant VERSION = "0.1.0";
    bytes32 internal constant TRACKING_CODE = "COPIN";

    /* ========== IMMUTABLES ========== */

    IFactory internal immutable FACTORY;
    IEvents internal immutable EVENTS;
    IConfigs internal immutable CONFIGS;
    IERC20 internal immutable USD_ASSET; // USD token
    ITaskCreator internal immutable TASK_CREATOR;

    /* ========== STATES ========== */

    address public executor;
    uint256 public lockedFund;
    uint256 public taskId;

    mapping(uint256 => Task) internal _tasks;
    mapping(uint256 => Position) internal _positions;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        CopyWalletConstructorParams memory _params
    ) Auth(address(0)) AutomateReady(_params.automate, _params.taskCreator) {
        FACTORY = IFactory(_params.factory);
        EVENTS = IEvents(_params.events);
        CONFIGS = IConfigs(_params.configs);
        USD_ASSET = IERC20(_params.usdAsset);
        TASK_CREATOR = ITaskCreator(_params.taskCreator);
    }

    /* ========== VIEWS ========== */

    function ethToUsd(uint256 _amount) public view virtual returns (uint256) {}

    function availableFund() public view override returns (uint256) {
        return USD_ASSET.balanceOf(address(this)) - lockedFund;
    }

    function availableFundD18() public view override returns (uint256) {
        return _usdToD18(availableFund());
    }

    function lockedFundD18() public view override returns (uint256) {
        return _usdToD18(lockedFund);
    }

    function positions(uint256 _key) public view returns (Position memory) {
        return _positions[_key];
    }

    /* ========== INIT & OWNERSHIP ========== */

    function init(address _owner, address _executor) external override {
        if (msg.sender != address(FACTORY)) revert Unauthorized();
        _setInitialOwnership(_owner);
        _setExecutor(_executor);
        _perpInit();
    }

    function _setInitialOwnership(address _owner) private {
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function _setExecutor(address _executor) private {
        delegates[_executor] = true;
        executor = _executor;
        emit DelegatedCopyWalletAdded({
            caller: msg.sender,
            delegate: _executor
        });
    }

    function setExecutor(address _executor) external {
        if (!isOwner(msg.sender)) revert Unauthorized();
        _setExecutor(_executor);
    }

    function transferOwnership(address _newOwner) public override {
        super.transferOwnership(_newOwner);
        FACTORY.updateCopyWalletOwnership({
            _newOwner: _newOwner,
            _oldOwner: msg.sender
        });
    }

    /* ========== EXECUTE ========== */

    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external payable override nonReentrant {
        uint256 numCommands = _commands.length;
        if (_inputs.length != numCommands) {
            revert LengthMismatch();
        }
        for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
            _dispatch(_commands[commandIndex], _inputs[commandIndex]);
            unchecked {
                ++commandIndex;
            }
        }
        if (msg.sender == executor) {
            _chargeExecutorFee(msg.sender);
        }
    }

    function _dispatch(Command _command, bytes calldata _inputs) internal {
        uint256 commandIndex = uint256(_command);
        if (commandIndex < 3) {
            if (!isOwner(msg.sender)) revert Unauthorized();

            if (_command == Command.OWNER_MODIFY_FUND) {
                int256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _modifyFund({_amount: amount, _msgSender: msg.sender});
            } else if (_command == Command.OWNER_WITHDRAW_ETH) {
                uint256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _withdrawEth({_amount: amount, _msgSender: msg.sender});
            }
        } else {
            if (!isAuth(msg.sender)) revert Unauthorized();
            if (_command == Command.PERP_CREATE_ACCOUNT) {
                _perpCreateAccount();
            } else if (_command == Command.PERP_MODIFY_COLLATERAL) {
                _perpModifyCollateral(_inputs);
            } else if (_command == Command.PERP_PLACE_ORDER) {
                _perpPlaceOrder(_inputs);
            } else if (_command == Command.PERP_CLOSE_ORDER) {
                _perpCloseOrder(_inputs);
            } else if (_command == Command.PERP_CANCEL_ORDER) {
                _perpCancelOrder(_inputs);
            } else if (_command == Command.PERP_WITHDRAW_ALL_MARGIN) {
                _perpWithdrawAllMargin(_inputs);
            }
            // TODO task
            //  else if (_command == Command.GELATO_CREATE_TASK) {
            //     TaskCommand taskCommand;
            //     address source;
            //     uint256 market;
            //     int256 collateralDelta;
            //     int256 sizeDelta;
            //     uint256 triggerPrice;
            //     uint256 acceptablePrice;
            //     address referrer;
            //     assembly {
            //         taskCommand := calldataload(_inputs.offset)
            //         source := calldataload(add(_inputs.offset, 0x20))
            //         market := calldataload(add(_inputs.offset, 0x40))
            //         collateralDelta := calldataload(add(_inputs.offset, 0x60))
            //         sizeDelta := calldataload(add(_inputs.offset, 0x80))
            //         triggerPrice := calldataload(add(_inputs.offset, 0xa0))
            //         acceptablePrice := calldataload(add(_inputs.offset, 0xc0))
            //         referrer := calldataload(add(_inputs.offset, 0xe0))
            //     }
            //     _createGelatoTask({
            //         _command: taskCommand,
            //         _source: source,
            //         _market: market,
            //         _collateralDelta: collateralDelta,
            //         _sizeDelta: sizeDelta,
            //         _triggerPrice: triggerPrice,
            //         _acceptablePrice: acceptablePrice,
            //         _referrer: referrer
            //     });
            // } else if (_command == Command.GELATO_UPDATE_TASK) {
            //     uint256 requestTaskId;
            //     int256 collateralData;
            //     int256 sizeDelta;
            //     uint256 triggerPrice;
            //     uint256 acceptablePrice;
            //     assembly {
            //         requestTaskId := calldataload(_inputs.offset)
            //         collateralData := calldataload(add(_inputs.offset, 0x20))
            //         sizeDelta := calldataload(add(_inputs.offset, 0x40))
            //         triggerPrice := calldataload(add(_inputs.offset, 0x60))
            //         acceptablePrice := calldataload(add(_inputs.offset, 0x80))
            //     }
            //     _updateGelatoTask({
            //         _taskId: requestTaskId,
            //         _collateralDelta: collateralData,
            //         _sizeDelta: sizeDelta,
            //         _triggerPrice: triggerPrice,
            //         _acceptablePrice: acceptablePrice
            //     });
            // } else if (_command == Command.GELETO_CANCEL_TASK) {
            //     uint256 requestTaskId;
            //     assembly {
            //         requestTaskId := calldataload(_inputs.offset)
            //     }
            //     _cancelGelatoTask(requestTaskId);
            // }
            if (commandIndex > 12) {
                revert InvalidCommandType(commandIndex);
            }
        }
    }

    /* ========== FUNDS ========== */

    receive() external payable {}

    function _withdrawEth(uint256 _amount, address _msgSender) internal {
        if (_amount > 0) {
            (bool success, ) = payable(_msgSender).call{value: _amount}("");
            if (!success) revert EthWithdrawalFailed();

            EVENTS.emitEthWithdraw({user: _msgSender, amount: _amount});
        }
    }

    function _modifyFund(int256 _amount, address _msgSender) internal {
        /// @dev if amount is positive, deposit
        if (_amount > 0) {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transferFrom(_msgSender, address(this), _abs(_amount));
            EVENTS.emitDeposit({user: _msgSender, amount: _abs(_amount)});
        } else if (_amount < 0) {
            /// @dev if amount is negative, withdraw
            _sufficientFund(_amount, true);
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transfer(_msgSender, _abs(_amount));
            EVENTS.emitWithdraw({user: _msgSender, amount: _abs(_amount)});
        }
    }

    function _lockFund(int256 _amount, bool origin) internal {
        _sufficientFund(_amount, origin);
        lockedFund += origin ? _abs(_amount) : _d18ToUsd(_abs(_amount));
    }

    /* ========== FEES ========== */

    function _chargeExecutorFee(address _executor) internal returns (uint256) {
        uint256 fee;
        if (_executor == address(TASK_CREATOR)) {
            (fee, ) = _getFeeDetails();
        } else {
            fee = CONFIGS.executorFee();
        }
        uint256 feeUsd = ethToUsd(fee);
        address feeReceiver = CONFIGS.feeReceiver();
        if (feeUsd <= availableFund()) {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transfer(feeReceiver, feeUsd);
        } else {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            USD_ASSET.transferFrom(owner, feeReceiver, feeUsd);
        }
        EVENTS.emitChargeExecutorFee({
            executor: _executor,
            receiver: feeReceiver,
            fee: fee,
            feeUsd: feeUsd
        });
        return fee;
    }

    function _chargeProtocolFee(uint256 _sizeUsd, uint256 _feeUsd) internal {
        address feeReceiver = CONFIGS.feeReceiver();
        USD_ASSET.transfer(feeReceiver, _feeUsd);
        EVENTS.emitChargeProtocolFee({
            receiver: feeReceiver,
            sizeUsd: _sizeUsd,
            feeUsd: _feeUsd
        });
    }

    /* ========== PERPS ========== */

    // function _preOrder(
    //     uint256 _id,
    //     uint256 _lastSize,
    //     uint256 _sizeDelta,
    //     uint256 _price,
    //     bool _isIncrease
    // ) internal {}

    function _postOrder(
        uint256 _id,
        address _source,
        uint256 _lastSizeUsd,
        uint256 _sizeDeltaUsd,
        bool _isIncrease
    ) internal {
        Position memory position = _positions[_id];
        uint256 deltaUsd = _lastSizeUsd > position.lastSizeUsd
            ? _lastSizeUsd - position.lastSizeUsd
            : 0;

        if (deltaUsd > 0) {
            if (deltaUsd > position.lastSizeDeltaUsd)
                deltaUsd = position.lastSizeDeltaUsd;
            uint256 chargedFeeUsd = _protocolFee(deltaUsd * 2);
            if (chargedFeeUsd > position.lastFeeUsd)
                chargedFeeUsd = position.lastFeeUsd;
            lockedFund -= position.lastFeeUsd;
            _chargeProtocolFee(deltaUsd, chargedFeeUsd);
        }
        uint256 feeUsd = 0;
        if (_isIncrease) {
            feeUsd = _protocolFee(_sizeDeltaUsd * 2);
            _lockFund(int256(feeUsd), true);
        }
        _positions[_id] = Position({
            source: _source,
            lastSizeUsd: _lastSizeUsd,
            lastSizeDeltaUsd: _sizeDeltaUsd,
            lastFeeUsd: feeUsd
        });
    }

    function _perpInit() internal virtual {}

    function _perpCreateAccount() internal virtual {}

    function _perpModifyCollateral(bytes calldata _inputs) internal virtual {}

    function _perpPlaceOrder(bytes calldata _inputs) internal virtual {}

    function _perpCloseOrder(bytes calldata _inputs) internal virtual {}

    function _perpCancelOrder(bytes calldata _inputs) internal virtual {}

    function _perpWithdrawAllMargin(bytes calldata _inputs) internal virtual {}

    /* ========== TASKS ========== */

    // TODO task

    // function checker(
    //     uint256 _taskId
    // ) external view returns (bool canExec, bytes memory execPayload) {
    //     canExec = _validTask(_taskId);
    //     // calldata for execute func
    //     execPayload = abi.encodeCall(this.executeTask, (_taskId));
    //     if (tx.gasprice > 200 gwei) return (false, bytes("Gas price too high"));
    // }

    // function getTask(
    //     uint256 _taskId
    // ) public view override returns (Task memory) {
    //     return _tasks[_taskId];
    // }

    // function executeTask(
    //     uint256 _taskId
    // ) external nonReentrant onlyDedicatedMsgSender {
    //     Task memory task = getTask(_taskId);
    //     (_taskId);
    //     if (!_perpValidTask(task)) {
    //         revert CannotExecuteTask({taskId: _taskId, executor: msg.sender});
    //     }

    //     delete _tasks[_taskId];
    //     ITaskCreator(TASK_CREATOR).cancelTask(task.gelatoTaskId);
    //     uint256 fee = _chargeExecutorFee(address(TASK_CREATOR), 1);
    //     _perpExecuteTask(_taskId, task);
    //     EVENTS.emitGelatoTaskRunned({
    //         taskId: _taskId,
    //         gelatoTaskId: task.gelatoTaskId,
    //         fillPrice: task.triggerPrice,
    //         fee: fee
    //     });
    // }

    // function _validTask(uint256 _taskId) internal view returns (bool) {
    //     Task memory task = getTask(_taskId);

    //     if (task.market == 0) {
    //         return false;
    //     }
    //     return _perpValidTask(task);
    // }

    // function _createGelatoTask(
    //     TaskCommand _command,
    //     address _source,
    //     uint256 _market,
    //     int256 _collateralDelta,
    //     int256 _sizeDelta,
    //     uint256 _triggerPrice,
    //     uint256 _acceptablePrice,
    //     address _referrer
    // ) internal {
    //     if (_sizeDelta == 0) revert ZeroSizeDelta();
    //     if (_collateralDelta > 0) {
    //         _lockFund(_collateralDelta, true);
    //     }
    //     ModuleData memory moduleData = ModuleData({
    //         modules: new Module[](2),
    //         args: new bytes[](2)
    //     });
    //     moduleData.modules[0] = Module.RESOLVER;
    //     moduleData.modules[1] = Module.PROXY;
    //     moduleData.args[0] = abi.encode(
    //         address(this),
    //         abi.encodeCall(this.checker, taskId)
    //     );
    //     bytes32 _gelatoTaskId = ITaskCreator(TASK_CREATOR).createTask({
    //         execData: abi.encodeCall(this.executeTask, taskId),
    //         moduleData: moduleData
    //     });
    //     _tasks[taskId] = Task({
    //         gelatoTaskId: _gelatoTaskId,
    //         command: _command,
    //         source: _source,
    //         market: _market,
    //         collateralDelta: _collateralDelta,
    //         sizeDelta: _sizeDelta,
    //         triggerPrice: _triggerPrice,
    //         acceptablePrice: _acceptablePrice,
    //         referrer: _referrer
    //     });
    //     EVENTS.emitCreateGelatoTask({
    //         taskId: taskId,
    //         gelatoTaskId: _gelatoTaskId,
    //         command: _command,
    //         source: _source,
    //         market: _market,
    //         collateralDelta: _collateralDelta,
    //         sizeDelta: _sizeDelta,
    //         triggerPrice: _triggerPrice,
    //         acceptablePrice: _acceptablePrice,
    //         referrer: _referrer
    //     });
    //     ++taskId;
    // }

    // function _updateGelatoTask(
    //     uint256 _taskId,
    //     int256 _collateralDelta,
    //     int256 _sizeDelta,
    //     uint256 _triggerPrice,
    //     uint256 _acceptablePrice
    // ) internal {
    //     Task storage task = _tasks[_taskId];
    //     if (task.gelatoTaskId == 0) revert NoTaskFound();
    //     if (_sizeDelta != 0) task.sizeDelta = _sizeDelta;
    //     if (_collateralDelta != 0) task.collateralDelta = _collateralDelta;
    //     if (_triggerPrice != 0) task.triggerPrice = _triggerPrice;
    //     if (_acceptablePrice != 0) task.acceptablePrice = _acceptablePrice;
    //     EVENTS.emitUpdateGelatoTask({
    //         taskId: _taskId,
    //         gelatoTaskId: task.gelatoTaskId,
    //         collateralDelta: task.collateralDelta,
    //         sizeDelta: task.sizeDelta,
    //         triggerPrice: task.triggerPrice,
    //         acceptablePrice: task.acceptablePrice
    //     });
    // }

    // function _cancelGelatoTask(uint256 _taskId) internal {
    //     Task memory task = getTask(_taskId);
    //     ITaskCreator(TASK_CREATOR).cancelTask(task.gelatoTaskId);
    //     EVENTS.emitCancelGelatoTask({
    //         taskId: _taskId,
    //         gelatoTaskId: task.gelatoTaskId,
    //         reason: "MANUAL"
    //     });
    // }

    // function _perpValidTask(
    //     Task memory _task
    // ) internal view virtual returns (bool) {}

    // function _perpExecuteTask(
    //     uint256 _taskId,
    //     Task memory _task
    // ) internal virtual {}

    /* ========== INTERNAL GETTERS ========== */

    function _protocolFee(uint256 _size) internal view returns (uint256) {
        return _size / IConfigs(CONFIGS).protocolFee();
    }

    function _sufficientFund(int256 _amountOut, bool origin) internal view {
        /// @dev origin true => amount as fund asset decimals
        uint256 _fundOut = origin
            ? _abs(_amountOut)
            : _d18ToUsd(_abs(_amountOut));
        if (_fundOut > availableFund()) {
            revert InsufficientAvailableFund(availableFund(), _fundOut);
        }
    }

    /* ========== UTILITIES ========== */

    function _d18ToUsd(uint256 _amount) internal view returns (uint256) {
        /// @dev convert to fund asset decimals
        return (_amount * 10 ** USD_ASSET.decimals()) / 10 ** 18;
    }

    function _usdToD18(uint256 _amount) internal view returns (uint256) {
        /// @dev convert to fund asset decimals
        return (_amount * 10 ** 18) / 10 ** USD_ASSET.decimals();
    }

    function _abs(int256 x) internal pure returns (uint256 z) {
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    function _isSameSign(int256 x, int256 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IRouter {
    function approvedPlugins(
        address plugin,
        address account
    ) external returns (bool);

    function approvePlugin(address _plugin) external;

    function denyPlugin(address _plugin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IPositionRouter {
  function createIncreasePosition(
      address[] memory _path,
      address _indexToken,
      uint256 _amountIn,
      uint256 _minOut,
      uint256 _sizeDelta,
      bool _isLong,
      uint256 _acceptablePrice,
      uint256 _executionFee,
      bytes32 _referralCode,
      address _callbackTarget
  ) external payable returns (bytes32);

  function createDecreasePosition(
      address[] memory _path,
      address _indexToken,
      uint256 _collateralDelta,
      uint256 _sizeDelta,
      bool _isLong,
      address _receiver,
      uint256 _acceptablePrice,
      uint256 _minOut,
      uint256 _executionFee,
      bool _withdrawETH,
      address _callbackTarget
  ) external payable returns (bytes32);

  function minExecutionFee() external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IVault {
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
    // size collateral averagePrice entryFundingRate reserveAmount realisedPnl isWin lastIncreasedTime
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {PythStructs} from "./PythStructs.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IGainsTrading {
    enum TradeType {
        TRADE,
        LIMIT,
        STOP
    }

    enum CounterType {
        TRADE,
        PENDING_ORDER
    }

    struct Trade {
        // slot 1
        address user; // 160 bits
        uint32 index; // max: 4,294,967,295
        uint16 pairIndex; // max: 65,535
        uint24 leverage; // 1e3; max: 16,777.215
        bool long; // 8 bits
        bool isOpen; // 8 bits
        uint8 collateralIndex; // max: 255
        // slot 2
        TradeType tradeType; // 8 bits
        uint120 collateralAmount; // 1e18; max: 3.402e+38
        uint64 openPrice; // 1e10; max: 1.8e19
        uint64 tp; // 1e10; max: 1.8e19
        // slot 3 (192 bits left)
        uint64 sl; // 1e10; max: 1.8e19
        uint192 __placeholder;
    }

    struct Counter {
        uint32 currentIndex;
        uint32 openCount;
        uint192 __placeholder;
    }

    function getTrade(
        address _trader,
        uint32 _index
    ) external view returns (Trade memory);

    function openTrade(
        Trade calldata trade,
        uint16 _maxSlippageP,
        address _referrer
    ) external;

    function closeTradeMarket(uint32 _index) external;

    function cancelOpenOrder(uint32 _index) external;

    function getCounters(
        address _trader,
        CounterType _type
    ) external view returns (Counter memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IFactory {
    event NewCopyWallet(
        address indexed creator,
        address indexed account,
        bytes32 version
    );

    event CopyWalletImplementationUpgraded(address implementation);

    error FailedToInitCopyWallet(bytes data);

    error CopyWalletFailedToFetchVersion(bytes data);

    error CannotUpgrade();

    error CopyWalletDoesNotExist();

    function canUpgrade() external view returns (bool);

    function implementation() external view returns (address);

    function accounts(address _account) external view returns (bool);

    function getCopyWalletOwner(
        address _account
    ) external view returns (address);

    function getCopyWalletsOwnedBy(
        address _owner
    ) external view returns (address[] memory);

    function updateCopyWalletOwnership(
        address _newOwner,
        address _oldOwner
    ) external;

    function newCopyWallet(
        address initialExecutor
    ) external returns (address payable accountAddress);

    /// @dev this *will* impact all existing accounts
    /// @dev future accounts will also point to this new implementation (until
    /// upgradeCopyWalletImplementation() is called again with a newer implementation)
    /// @dev *DANGER* this function does not check the new implementation for validity,
    /// thus, a bad upgrade could result in severe consequences.
    function upgradeCopyWalletImplementation(address _implementation) external;

    /// @dev cannot be undone
    function removeUpgradability() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet} from "./ICopyWallet.sol";

interface IEvents {
    error OnlyCopyWallets();

    function factory() external view returns (address);

    function emitDeposit(address user, uint256 amount) external;

    event Deposit(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitWithdraw(address user, uint256 amount) external;

    event Withdraw(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitChargeExecutorFee(
        address executor,
        address receiver,
        uint256 fee,
        uint256 feeUsd
    ) external;

    event ChargeExecutorFee(
        address indexed executor,
        address indexed receiver,
        address indexed copyWallet,
        uint256 fee,
        uint256 feeUsd
    );

    function emitChargeProtocolFee(
        address receiver,
        uint256 sizeUsd,
        uint256 feeUsd
    ) external;

    event ChargeProtocolFee(
        address indexed receiver,
        address indexed copyWallet,
        uint256 sizeUsd,
        uint256 feeUsd
    );

    function emitCreateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    ) external;

    event CreateGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    );

    function emitUpdateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    ) external;

    event UpdateGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    );

    function emitCancelGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        bytes32 reason
    ) external;

    event CancelGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        bytes32 reason
    );

    function emitGelatoTaskRunned(
        uint256 taskId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    ) external;

    event GelatoTaskRunned(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
import {ModuleData} from "../utils/gelato/Types.sol";

interface ITaskCreator {
    function factory() external view returns (address);

    function cancelTask(bytes32 _gelatoTaskId) external;

    function createTask(
        bytes memory execData,
        ModuleData memory moduleData
    ) external returns (bytes32 _gelatoTaskId);

    function depositFunds1Balance(address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function decimals() external view returns (uint256);

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Consolidated Perpetuals Market Proxy Interface
/// @notice Responsible for interacting with Synthetix v3 perps markets
/// @author Synthetix
interface IPerpsMarket {
    /*//////////////////////////////////////////////////////////////
                             ACCOUNT MODULE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints an account token with an available id to `ERC2771Context._msgSender()`.
     *
     * Emits a {AccountCreated} event.
     */
    function createAccount() external returns (uint128 accountId);

    function grantPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external;

    /// @notice Returns the address that owns a given account, as recorded by the system.
    /// @param accountId The account id whose owner is being retrieved.
    /// @return owner The owner of the given account id.
    function getAccountOwner(
        uint128 accountId
    ) external view returns (address owner);

    /// @notice Returns `true` if `user` has been granted `permission` for account `accountId`.
    /// @param accountId The id of the account whose permission is being queried.
    /// @param permission The bytes32 identifier of the permission.
    /// @param user The target address whose permission is being queried.
    /// @return hasPermission A boolean with the response of the query.
    function hasPermission(
        uint128 accountId,
        bytes32 permission,
        address user
    ) external view returns (bool hasPermission);

    /// @notice Returns `true` if `target` is authorized to `permission` for account `accountId`.
    /// @param accountId The id of the account whose permission is being queried.
    /// @param permission The bytes32 identifier of the permission.
    /// @param target The target address whose permission is being queried.
    /// @return isAuthorized A boolean with the response of the query.
    function isAuthorized(
        uint128 accountId,
        bytes32 permission,
        address target
    ) external view returns (bool isAuthorized);

    /*//////////////////////////////////////////////////////////////
                           ASYNC ORDER MODULE
    //////////////////////////////////////////////////////////////*/

    struct OrderCommitmentRequest {
        /// @dev Order market id.
        uint128 marketId;
        /// @dev Order account id.
        uint128 accountId;
        /// @dev Order size delta (of asset units expressed in decimal 18 digits). It can be positive or negative.
        int128 sizeDelta;
        /// @dev Settlement strategy used for the order.
        uint128 settlementStrategyId;
        /// @dev Acceptable price set at submission.
        uint256 acceptablePrice;
        /// @dev An optional code provided by frontends to assist with tracking the source of volume and fees.
        bytes32 trackingCode;
        /// @dev Referrer address to send the referrer fees to.
        address referrer;
    }

    struct AsyncOrderData {
        /**
         * @dev Time at which the order was committed.
         */
        uint256 commitmentTime;
        /**
         * @dev Order request details.
         */
        OrderCommitmentRequest request;
    }

    /// @notice Commit an async order via this function
    /// @param commitment Order commitment data (see OrderCommitmentRequest struct).
    /// @return retOrder order details (see AsyncOrder.Data struct).
    /// @return fees order fees (protocol + settler)
    function commitOrder(
        OrderCommitmentRequest memory commitment
    ) external returns (AsyncOrderData memory retOrder, uint256 fees);

    /**
     * @notice Cancels an order when price exceeds the acceptable price. Uses the onchain benchmark price at commitment time.
     * @param accountId Id of the account used for the trade.
     */
    function cancelOrder(uint128 accountId) external;

    /// @notice Simulates what the order fee would be for the given market with the specified size.
    /// @dev Note that this does not include the settlement reward fee, which is based on the strategy type used
    /// @param marketId id of the market.
    /// @param sizeDelta size of position.
    /// @return orderFees incurred fees.
    /// @return fillPrice price at which the order would be filled.
    function computeOrderFees(
        uint128 marketId,
        int128 sizeDelta
    ) external view returns (uint256 orderFees, uint256 fillPrice);

    /**
     * @notice Get async order claim details
     * @param accountId id of the account.
     * @return order async order claim details (see AsyncOrder.Data struct).
     */
    function getOrder(
        uint128 accountId
    ) external view returns (AsyncOrderData memory order);

    /*//////////////////////////////////////////////////////////////
                          PERPS ACCOUNT MODULE
    //////////////////////////////////////////////////////////////*/

    // returns account's available margin taking into account positions unrealized pnl
    function getAvailableMargin(
        uint128 accountId
    ) external view returns (int256 availableMargin);

    /// @notice Modify the collateral delegated to the account.
    /// @param accountId Id of the account.
    /// @param synthMarketId Id of the synth market used as collateral. Synth market id, 0 for snxUSD.
    /// @param amountDelta requested change in amount of collateral delegated to the account.
    function modifyCollateral(
        uint128 accountId,
        uint128 synthMarketId,
        int256 amountDelta
    ) external;

    /*//////////////////////////////////////////////////////////////
                          PERPS MARKET MODULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the details of an open position.
    /// @param accountId Id of the account.
    /// @param marketId Id of the position market.
    /// @return totalPnl pnl of the entire position including funding.
    /// @return accruedFunding accrued funding of the position.
    /// @return positionSize size of the position.
    function getOpenPosition(
        uint128 accountId,
        uint128 marketId
    )
        external
        view
        returns (int256 totalPnl, int256 accruedFunding, int128 positionSize);

    /// @notice Gets the max size of an specific market.
    /// @param marketId id of the market.
    /// @return maxMarketSize the max market size in market asset units.
    function getMaxMarketSize(
        uint128 marketId
    ) external view returns (uint256 maxMarketSize);

    /**
     * @notice Gets a market's index price.
     * @param marketId Id of the market.
     * @return indexPrice Index price of the market.
     */
    function indexPrice(uint128 marketId) external view returns (uint);

    /**
     * @notice Gets a market's fill price for a specific order size and index price.
     * @param marketId Id of the market.
     * @param orderSize Order size.
     * @param price Index price.
     * @return price Fill price.
     */
    function fillPrice(
        uint128 marketId,
        int128 orderSize,
        uint price
    ) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @author JaredBorders ([email protected])
/// @dev This contract is intended to be inherited by the CopyWallet contract
abstract contract Auth {
    address public owner;

    mapping(address delegate => bool) public delegates;

    /// @dev reserved storage space for future contract upgrades
    /// @custom:caution reduce storage size when adding new storage variables
    uint256[19] private __gap;

    error Unauthorized();

    error InvalidDelegateAddress(address delegateAddress);

    event OwnershipTransferred(
        address indexed caller,
        address indexed newOwner
    );

    event DelegatedCopyWalletAdded(
        address indexed caller,
        address indexed delegate
    );

    event DelegatedCopyWalletRemoved(
        address indexed caller,
        address indexed delegate
    );

    /// @dev sets owner to _owner and not msg.sender
    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function isOwner(address msgSender) public view virtual returns (bool) {
        return (msgSender == owner);
    }

    function isAuth(address msgSender) public view virtual returns (bool) {
        return (msgSender == owner || delegates[msgSender]);
    }

    /// @dev only owner can transfer ownership (not delegates)
    function transferOwnership(address _newOwner) public virtual {
        if (!isOwner(msg.sender)) revert Unauthorized();

        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    /// @dev only owner can add a delegate (not delegates)
    function addDelegate(address _delegate) public virtual {
        if (!isOwner(msg.sender)) revert Unauthorized();

        if (_delegate == address(0) || delegates[_delegate]) {
            revert InvalidDelegateAddress(_delegate);
        }

        delegates[_delegate] = true;

        emit DelegatedCopyWalletAdded({caller: msg.sender, delegate: _delegate});
    }

    /// @dev only owner can remove a delegate (not delegates)
    function removeDelegate(address _delegate) public virtual {
        if (!isOwner(msg.sender)) revert Unauthorized();

        if (_delegate == address(0) || !delegates[_delegate]) {
            revert InvalidDelegateAddress(_delegate);
        }

        delete delegates[_delegate];

        emit DelegatedCopyWalletRemoved({
            caller: msg.sender,
            delegate: _delegate
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Types.sol";

abstract contract AutomateReady {
    IAutomate public immutable automate;
    address public immutable dedicatedMsgSender;
    address private immutable feeCollector;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev
     * Only tasks created by _taskCreator defined in constructor can call
     * the functions with this modifier.
     */
    modifier onlyDedicatedMsgSender() {
        require(msg.sender == dedicatedMsgSender, "Only dedicated msg.sender");
        _;
    }

    /**
     * @dev
     * _taskCreator is the address which will create tasks for this contract.
     */
    constructor(address _automate, address _taskCreator) {
        automate = IAutomate(_automate);
        IGelato gelato = IGelato(IAutomate(_automate).gelato());

        feeCollector = gelato.feeCollector();

        address proxyModuleAddress = IAutomate(_automate).taskModuleAddresses(
            Module.PROXY
        );

        address opsProxyFactoryAddress = IProxyModule(proxyModuleAddress)
            .opsProxyFactory();

        (dedicatedMsgSender, ) = IOpsProxyFactory(opsProxyFactoryAddress)
            .getProxyOf(_taskCreator);
    }

    /**
     * @dev
     * Transfers fee to gelato for synchronous fee payments.
     *
     * _fee & _feeToken should be queried from IAutomate.getFeeDetails()
     */
    function _transfer(uint256 _fee, address _feeToken) internal {
        if (_feeToken == ETH) {
            (bool success, ) = feeCollector.call{value: _fee}("");
            require(success, "_transfer: ETH transfer failed");
        } else {
            SafeERC20.safeTransfer(IERC20(_feeToken), feeCollector, _fee);
        }
    }

    function _getFeeDetails()
        internal
        view
        returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = automate.getFeeDetails();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

enum Module {
    RESOLVER,
    DEPRECATED_TIME,
    PROXY,
    SINGLE_EXEC,
    WEB3_FUNCTION,
    TRIGGER
}

enum TriggerType {
    TIME,
    CRON,
    EVENT,
    BLOCK
}

struct ModuleData {
    Module[] modules;
    bytes[] args;
}

interface IAutomate {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskModuleAddresses(Module) external view returns (address);
}

interface IProxyModule {
    function opsProxyFactory() external view returns (address);
}

interface IOpsProxyFactory {
    function getProxyOf(address account) external view returns (address, bool);
}

interface IGelato1Balance {
    function depositNative(address _sponsor) external payable;

    function depositToken(
        address _sponsor,
        address _token,
        uint256 _amount
    ) external;
}

interface IGelato {
    function feeCollector() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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