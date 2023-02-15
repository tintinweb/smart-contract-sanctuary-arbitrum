// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IPikaPerp.sol";
import '../lib/UniERC20.sol';
import "./IPikaPerp.sol";
import "./PikaPerpV3.sol";
import "../access/Governable.sol";

contract PositionManager is Governable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;
    using Address for address payable;

    struct OpenPositionRequest {
        address account;
        uint256 productId;
        uint256 margin;
        uint256 leverage;
        uint256 tradeFee;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 index;
        uint256 blockNumber;
        uint256 blockTime;
    }

    struct ClosePositionRequest {
        address account;
        uint256 productId;
        uint256 margin;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 index;
        uint256 blockNumber;
        uint256 blockTime;
    }

    address public admin;

    address public immutable pikaPerp;
    address public feeCalculator;
    address public oracle;
    address public immutable collateralToken;
    uint256 public minExecutionFee;

    uint256 public minBlockDelayPositionKeeper;
    uint256 public minBlockDelayPriceKeeper;
    uint256 public minTimeExecuteDelayPublic;
    uint256 public minTimeCancelDelayPublic;
    uint256 public maxTimeDelay;

    bool public isUserExecuteEnabled = true;
    bool public isUserCancelEnabled = true;
    bool public allowPublicKeeper = false;
    bool public allowUserCloseOnly = false;
    bool public isPriceKeeperCall = false;

    bytes32[] public openPositionRequestKeys;
    bytes32[] public closePositionRequestKeys;

    uint256 public openPositionRequestKeysStart;
    uint256 public closePositionRequestKeysStart;

    uint256 public immutable tokenBase;
    uint256 public constant BASE = 1e8;
    uint256 public constant FEE_BASE = 1e4;

    mapping (address => bool) public isPositionKeeper;
    mapping (address => bool) public isPriceKeeper;

    mapping (address => uint256) public openPositionsIndex;
    mapping (bytes32 => OpenPositionRequest) public openPositionRequests;

    mapping (address => uint256) public closePositionsIndex;
    mapping (bytes32 => ClosePositionRequest) public closePositionRequests;

    event CreateOpenPosition(
        address indexed account,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockNumber,
        uint256 blockTime,
        uint256 gasPrice
    );

    event ExecuteOpenPosition(
        address indexed account,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockGap,
        uint256 timeGap
    );

    event CancelOpenPosition(
        address indexed account,
        uint256 productId,
        uint256 margin,
        uint256 leverage,
        uint256 tradeFee,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockGap,
        uint256 timeGap
    );

    event CreateClosePosition(
        address indexed account,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockNumber,
        uint256 blockTime
    );

    event ExecuteClosePosition(
        address indexed account,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockGap,
        uint256 timeGap
    );

    event CancelClosePosition(
        address indexed account,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 acceptablePrice,
        uint256 executionFee,
        uint256 index,
        uint256 blockGap,
        uint256 timeGap
    );
    event ExecuteOpenPositionError(address indexed account, uint256 index, string executionError);
    event ExecuteClosePositionError(address indexed account, uint256 index, string executionError);
    event SetPositionKeeper(address indexed account, bool isActive);
    event SetPriceKeeper(address indexed account, bool isActive);
    event SetMinExecutionFee(uint256 minExecutionFee);
    event SetIsUserExecuteEnabled(bool isUserExecuteEnabled);
    event SetIsUserCancelEnabled(bool isUserCancelEnabled);
    event SetDelayValues(uint256 minBlockDelayPositionKeeper, uint256 minBlockDelayPriceKeeper, uint256 minTimeExecuteDelayPublic,
        uint256 minTimeCancelDelayPublic, uint256 maxTimeDelay);
    event SetRequestKeysStartValues(uint256 increasePositionRequestKeysStart, uint256 decreasePositionRequestKeysStart);
    event SetAllowPublicKeeper(bool allowPublicKeeper);
    event SetAllowUserCloseOnly(bool allowUserCloseOnly);
    event SetAdmin(address admin);

    modifier onlyPositionKeeper() {
        require(isPositionKeeper[msg.sender], "PositionManager: !positionKeeper");
        _;
    }

    modifier onlyPriceKeeper() {
        require(isPriceKeeper[msg.sender], "PositionManager: !priceKeeper");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "PositionManager: !admin");
        _;
    }

    constructor(
        address _pikaPerp,
        address _feeCalculator,
        address _oracle,
        address _collateralToken,
        uint256 _minExecutionFee,
        uint256 _tokenBase
    ) public {
        pikaPerp = _pikaPerp;
        feeCalculator = _feeCalculator;
        oracle = _oracle;
        collateralToken = _collateralToken;
        minExecutionFee = _minExecutionFee;
        tokenBase = _tokenBase;
        admin = msg.sender;
    }

    function setFeeCalculator(address _feeCalculator) external onlyAdmin {
        feeCalculator = _feeCalculator;
    }

    function setOracle(address _oracle) external onlyAdmin {
        oracle = _oracle;
    }

    function setPositionKeeper(address _account, bool _isActive) external onlyAdmin {
        isPositionKeeper[_account] = _isActive;
        emit SetPositionKeeper(_account, _isActive);
    }

    function setPriceKeeper(address _account, bool _isActive) external onlyAdmin {
        isPriceKeeper[_account] = _isActive;
        emit SetPriceKeeper(_account, _isActive);
    }

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyAdmin {
        minExecutionFee = _minExecutionFee;
        emit SetMinExecutionFee(_minExecutionFee);
    }

    function setIsUserExecuteEnabled(bool _isUserExecuteEnabled) external onlyAdmin {
        isUserExecuteEnabled = _isUserExecuteEnabled;
        emit SetIsUserExecuteEnabled(_isUserExecuteEnabled);
    }

    function setIsUserCancelEnabled(bool _isUserCancelEnabled) external onlyAdmin {
        isUserCancelEnabled = _isUserCancelEnabled;
        emit SetIsUserCancelEnabled(_isUserCancelEnabled);
    }

    function setDelayValues(
        uint256 _minBlockDelayPositionKeeper,
        uint256 _minBlockDelayPriceKeeper,
        uint256 _minTimeExecuteDelayPublic,
        uint256 _minTimeCancelDelayPublic,
        uint256 _maxTimeDelay
    ) external onlyAdmin {
        minBlockDelayPositionKeeper = _minBlockDelayPositionKeeper;
        minBlockDelayPriceKeeper = _minBlockDelayPriceKeeper;
        minTimeExecuteDelayPublic = _minTimeExecuteDelayPublic;
        minTimeCancelDelayPublic = _minTimeCancelDelayPublic;
        maxTimeDelay = _maxTimeDelay;
        emit SetDelayValues(_minBlockDelayPositionKeeper, _minBlockDelayPriceKeeper, _minTimeExecuteDelayPublic, _minTimeCancelDelayPublic, _maxTimeDelay);
    }

    function setRequestKeysStartValues(uint256 _increasePositionRequestKeysStart, uint256 _decreasePositionRequestKeysStart) external onlyAdmin {
        openPositionRequestKeysStart = _increasePositionRequestKeysStart;
        closePositionRequestKeysStart = _decreasePositionRequestKeysStart;

        emit SetRequestKeysStartValues(_increasePositionRequestKeysStart, _decreasePositionRequestKeysStart);
    }

    function setAllowPublicKeeper(bool _allowPublicKeeper) external onlyAdmin {
        allowPublicKeeper = _allowPublicKeeper;
        emit SetAllowPublicKeeper(_allowPublicKeeper);
    }

    function setAllowUserCloseOnly(bool _allowUserCloseOnly) external onlyAdmin {
        allowUserCloseOnly = _allowUserCloseOnly;
        emit SetAllowUserCloseOnly(_allowUserCloseOnly);
    }

    function setAdmin(address _admin) external onlyGov {
        admin = _admin;
        emit SetAdmin(_admin);
    }

    function executeNPositionsWithPrices(
        address[] memory tokens,
        uint256[] memory prices,
        uint256 n,
        address payable _executionFeeReceiver
    ) external {
        executePositionsWithPrices(tokens, prices, openPositionRequestKeysStart + n, closePositionRequestKeysStart + n, _executionFeeReceiver);
    }

    function executePositionsWithPrices(
        address[] memory tokens,
        uint256[] memory prices,
        uint256 _openEndIndex,
        uint256 _closeEndIndex,
        address payable _executionFeeReceiver
    ) public onlyPriceKeeper {
        isPriceKeeperCall = true;
        IOracle(oracle).setPrices(tokens, prices);
        executePositions(_openEndIndex, _closeEndIndex, _executionFeeReceiver);
        isPriceKeeperCall = false;
    }

    function executeNPositions(uint256 n, address payable _executionFeeReceiver) external {
        require(canPositionKeeperExecute(), "PositionManager: cannot execute");
        executePositions(openPositionRequestKeysStart + n, closePositionRequestKeysStart + n, _executionFeeReceiver);
    }

    function executePositions(uint256 _openEndIndex, uint256 _closeEndIndex, address payable _executionFeeReceiver) public {
        executeOpenPositions(_openEndIndex, _executionFeeReceiver);
        executeClosePositions(_closeEndIndex, _executionFeeReceiver);
    }

    function executeOpenPositions(uint256 _endIndex, address payable _executionFeeReceiver) public onlyPositionKeeper {
        uint256 index = openPositionRequestKeysStart;
        uint256 length = openPositionRequestKeys.length;

        if (index >= length) { return; }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = openPositionRequestKeys[index];

            // if the request was executed then delete the key from the array
            // if the request was not executed then break from the loop, this can happen if the
            // minimum number of blocks has not yet passed
            // an error could be thrown if the request is too old or if the slippage is
            // higher than what the user specified, or if there is insufficient liquidity for the position
            // in case an error was thrown, cancel the request
            try this.executeOpenPosition(key, _executionFeeReceiver) returns (bool _wasExecuted) {
                if (!_wasExecuted) { break; }
            } catch Error(string memory executionError) {
                emit ExecuteOpenPositionError(openPositionRequests[key].account, index, executionError);
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelOpenPosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) { break; }
                } catch {}
            } catch (bytes memory /*lowLevelData*/) {
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelOpenPosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) { break; }
                } catch {}
            }

            delete openPositionRequestKeys[index];
            index++;
        }

        openPositionRequestKeysStart = index;
    }

    function executeClosePositions(uint256 _endIndex, address payable _executionFeeReceiver) public onlyPositionKeeper {
        uint256 index = closePositionRequestKeysStart;
        uint256 length = closePositionRequestKeys.length;

        if (index >= length) { return; }

        if (_endIndex > length) {
            _endIndex = length;
        }

        while (index < _endIndex) {
            bytes32 key = closePositionRequestKeys[index];

            // if the request was executed then delete the key from the array
            // if the request was not executed then break from the loop, this can happen if the
            // minimum number of blocks has not yet passed
            // an error could be thrown if the request is too old
            // in case an error was thrown, cancel the request
            try this.executeClosePosition(key, _executionFeeReceiver) returns (bool _wasExecuted) {
                if (!_wasExecuted) { break; }
            } catch Error(string memory executionError)  {
                emit ExecuteClosePositionError(closePositionRequests[key].account, index, executionError);
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelClosePosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) { break; }
                } catch {}
            } catch (bytes memory /*lowLevelData*/) {
                // wrap this call in a try catch to prevent invalid cancels from blocking the loop
                try this.cancelClosePosition(key, _executionFeeReceiver) returns (bool _wasCancelled) {
                    if (!_wasCancelled) { break; }
                } catch {}
            }

            delete closePositionRequestKeys[index];
            index++;
        }

        closePositionRequestKeysStart = index;
    }

    function createOpenPosition(
        uint256 _productId,
        uint256 _margin,
        uint256 _leverage,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee
    ) external payable nonReentrant {
        require(_executionFee >= minExecutionFee, "PositionManager: invalid executionFee");

        uint256 tradeFee = getTradeFeeRate(_productId, msg.sender) * _margin * _leverage / (FEE_BASE * BASE);
        if (IERC20(collateralToken).isETH()) {
            IERC20(collateralToken).uniTransferFromSenderToThis((_executionFee + _margin + tradeFee) * tokenBase / BASE);
        } else {
            require(msg.value == _executionFee * 1e18 / BASE, "PositionManager: incorrect execution fee transferred");
            IERC20(collateralToken).uniTransferFromSenderToThis((_margin + tradeFee) * tokenBase / BASE);
        }

        _createOpenPosition(
            msg.sender,
            _productId,
            _margin,
            tradeFee,
            _leverage,
            _isLong,
            _acceptablePrice,
            _executionFee
        );
    }

    function createClosePosition(
        uint256 _productId,
        uint256 _margin,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee
    ) external payable nonReentrant {
        require(_executionFee >= minExecutionFee, "PositionManager: invalid executionFee");
        require(msg.value == _executionFee * 1e18 / BASE, "PositionManager: invalid msg.value");

        _createClosePosition(
            msg.sender,
            _productId,
            _margin,
            _isLong,
            _acceptablePrice,
            _executionFee
        );
    }

    function getRequestQueueLengths() external view returns (uint256, uint256, uint256, uint256) {
        return (
        openPositionRequestKeysStart,
        openPositionRequestKeys.length,
        closePositionRequestKeysStart,
        closePositionRequestKeys.length
        );
    }

    function executeOpenPosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        OpenPositionRequest memory request = openPositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeOpenPositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldExecute = _validateExecution(request.blockNumber, request.blockTime, request.account, request.productId, true, request.isLong, request.acceptablePrice);
        if (!shouldExecute) { return false; }

        delete openPositionRequests[_key];

        if (IERC20(collateralToken).isETH()) {
            IPikaPerp(pikaPerp).openPosition{value: (request.margin + request.tradeFee) * tokenBase / BASE }(request.account, request.productId, request.margin, request.isLong, request.leverage);
        } else {
            IERC20(collateralToken).safeApprove(pikaPerp, 0);
            IERC20(collateralToken).safeApprove(pikaPerp, (request.margin + request.tradeFee) * tokenBase / BASE);
            IPikaPerp(pikaPerp).openPosition(request.account, request.productId, request.margin, request.isLong, request.leverage);
        }

        _executionFeeReceiver.sendValue(request.executionFee * 1e18 / BASE);

        emit ExecuteOpenPosition(
            request.account,
            request.productId,
            request.margin,
            request.leverage,
            request.tradeFee,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            request.index,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function cancelOpenPosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        OpenPositionRequest memory request = openPositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeOpenePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldCancel = _validateCancellation(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) { return false; }

        delete openPositionRequests[_key];

        if (IERC20(collateralToken).isETH()) {
            IERC20(collateralToken).uniTransfer(request.account, (request.margin + request.tradeFee) * tokenBase / BASE);
            IERC20(collateralToken).uniTransfer(_executionFeeReceiver, request.executionFee * tokenBase / BASE);
        } else {
            IERC20(collateralToken).uniTransfer(request.account, (request.margin + request.tradeFee) * tokenBase / BASE);
            payable(_executionFeeReceiver).sendValue(request.executionFee * 1e18 / BASE);
        }

        emit CancelOpenPosition(
            request.account,
            request.productId,
            request.margin,
            request.leverage,
            request.tradeFee,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            request.index,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function executeClosePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        ClosePositionRequest memory request = closePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeClosePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldExecute = _validateExecution(request.blockNumber, request.blockTime, request.account, request.productId, false, !request.isLong, request.acceptablePrice);
        if (!shouldExecute) { return false; }

        delete closePositionRequests[_key];

        IPikaPerp(pikaPerp).closePosition(request.account, request.productId, request.margin , request.isLong);

        _executionFeeReceiver.sendValue(request.executionFee * 1e18 / BASE);

        emit ExecuteClosePosition(
            request.account,
            request.productId,
            request.margin,
            request.isLong,
            request.acceptablePrice,
            request.executionFee,
            request.index,
            block.number.sub(request.blockNumber),
            block.timestamp.sub(request.blockTime)
        );

        return true;
    }

    function cancelClosePosition(bytes32 _key, address payable _executionFeeReceiver) public nonReentrant returns (bool) {
        ClosePositionRequest memory request = closePositionRequests[_key];
        // if the request was already executed or cancelled, return true so that the executeClosePositions loop will continue executing the next request
        if (request.account == address(0)) { return true; }

        bool shouldCancel = _validateCancellation(request.blockNumber, request.blockTime, request.account);
        if (!shouldCancel) { return false; }

        delete closePositionRequests[_key];

        _executionFeeReceiver.sendValue(request.executionFee * 1e18 / BASE);

        emit CancelClosePosition(
                request.account,
                request.productId,
                request.margin,
                request.isLong,
                request.acceptablePrice,
                request.executionFee,
                request.index,
                block.number.sub(request.blockNumber),
                block.timestamp.sub(request.blockTime)
            );

        return true;
    }

    function getRequestKey(address _account, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function getOpenPositionRequest(address _account, uint256 _index) public view returns (OpenPositionRequest memory) {
        return openPositionRequests[getRequestKey(_account, _index)];
    }

    function getClosePositionRequest(address _account, uint256 _index) public view returns (ClosePositionRequest memory) {
        return closePositionRequests[getRequestKey(_account, _index)];
    }

    function getOpenPositionRequestFromKey(bytes32 _key) public view returns (OpenPositionRequest memory) {
        return openPositionRequests[_key];
    }

    function getClosePositionRequestFromKey(bytes32 _key) public view returns (ClosePositionRequest memory) {
        return closePositionRequests[_key];
    }

    function canPriceKeeperExecute() public view returns(bool) {
        return (openPositionRequestKeysStart < openPositionRequestKeys.length &&
        openPositionRequests[openPositionRequestKeys[openPositionRequestKeysStart]].blockNumber.add(minBlockDelayPriceKeeper) <= block.timestamp) ||
        (closePositionRequestKeysStart < closePositionRequestKeys.length &&
        closePositionRequests[closePositionRequestKeys[closePositionRequestKeysStart]].blockNumber.add(minBlockDelayPriceKeeper) <= block.timestamp);
    }

    function canPositionKeeperExecute() public view returns(bool) {
        return (openPositionRequestKeysStart < openPositionRequestKeys.length &&
            openPositionRequests[openPositionRequestKeys[openPositionRequestKeysStart]].blockNumber.add(minBlockDelayPositionKeeper) <= block.timestamp) ||
            (closePositionRequestKeysStart < closePositionRequestKeys.length &&
            closePositionRequests[closePositionRequestKeys[closePositionRequestKeysStart]].blockNumber.add(minBlockDelayPositionKeeper) <= block.timestamp);
    }

    function _validateExecution(uint256 _positionBlockNumber, uint256 _positionBlockTime, address _account,
        uint256 _productId, bool _isOpen, bool _isLong, uint256 _acceptablePrice
    ) internal view returns (bool) {
        if (_positionBlockTime.add(maxTimeDelay) <= block.timestamp) {
            revert("PositionManager: request has expired");
        }

        bool isKeeperCall = msg.sender == address(this) || isPositionKeeper[msg.sender];

        if (!isUserExecuteEnabled && !isKeeperCall) {
            revert("PositionManager: forbidden");
        }

        if (isKeeperCall) {
            (address productToken,,,,,,,,) = IPikaPerp(pikaPerp).getProduct(_productId);
            uint256 price = _isLong ? IOracle(oracle).getPrice(productToken, true) : IOracle(oracle).getPrice(productToken, false);
            if (_isLong) {
                require(price <= _acceptablePrice, "PositionManager: current price too low");
            } else {
                require(price >= _acceptablePrice, "PositionManager: current price too high");
            }
            return isPriceKeeperCall ? _positionBlockNumber.add(minBlockDelayPriceKeeper) <= block.number :
                _positionBlockNumber.add(minBlockDelayPositionKeeper) <= block.number;
        }

        require((!_isOpen || !allowUserCloseOnly) && (msg.sender == _account || allowPublicKeeper), "PositionManager: forbidden");

        require(_positionBlockTime.add(minTimeExecuteDelayPublic) <= block.timestamp, "PositionManager: min delay not yet passed for execution");

        return true;
    }

    function _validateCancellation(uint256 _positionBlockNumber, uint256 _positionBlockTime, address _account) internal view returns (bool) {
        bool isKeeperCall = msg.sender == address(this) || isPositionKeeper[msg.sender];

        if (!isUserCancelEnabled && !isKeeperCall) {
            revert("PositionManager: forbidden");
        }

        if (isKeeperCall) {
            return isPriceKeeperCall ? _positionBlockNumber.add(minBlockDelayPriceKeeper) <= block.number :
            _positionBlockNumber.add(minBlockDelayPositionKeeper) <= block.number;
        }

        require(msg.sender == _account, "PositionManager: forbidden");

        require(_positionBlockTime.add(minTimeCancelDelayPublic) <= block.timestamp, "PositionManager: min delay not yet passed for cancellation");

        return true;
    }

    function _createOpenPosition(
        address _account,
        uint256 _productId,
        uint256 _margin,
        uint256 _tradeFee,
        uint256 _leverage,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee
    ) internal {
        uint256 index = openPositionsIndex[_account].add(1);
        openPositionsIndex[_account] = index;

        OpenPositionRequest memory request = OpenPositionRequest(
            _account,
            _productId,
            _margin,
            _leverage,
            _tradeFee,
            _isLong,
            _acceptablePrice,
            _executionFee,
            index,
            block.number,
            block.timestamp
        );

        bytes32 key = getRequestKey(_account, index);
        openPositionRequests[key] = request;

        openPositionRequestKeys.push(key);

        emit CreateOpenPosition(
            _account,
            _productId,
            _margin,
            _leverage,
            _tradeFee,
            _isLong,
            _acceptablePrice,
            _executionFee,
            index,
            block.number,
            block.timestamp,
            tx.gasprice
        );
    }

    function _createClosePosition(
        address _account,
        uint256 _productId,
        uint256 _margin,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee
    ) internal {
        uint256 index = closePositionsIndex[_account].add(1);
        closePositionsIndex[_account] = index;

        ClosePositionRequest memory request = ClosePositionRequest(
            _account,
            _productId,
            _margin,
            _isLong,
            _acceptablePrice,
            _executionFee,
            index,
            block.number,
            block.timestamp
        );

        bytes32 key = getRequestKey(_account, index);
        closePositionRequests[key] = request;

        closePositionRequestKeys.push(key);

        emit CreateClosePosition(
            _account,
            _productId,
            _margin,
            _isLong,
            _acceptablePrice,
            _executionFee,
            index,
            block.number,
            block.timestamp
        );
    }

    function getTradeFeeRate(uint256 _productId, address _account) private returns(uint256) {
        (address productToken,,uint256 fee,,,,,,) = IPikaPerp(pikaPerp).getProduct(_productId);
        return IFeeCalculator(feeCalculator).getFee(productToken, fee, _account, msg.sender);
    }

    fallback() external payable {}
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPikaPerp {
    function getTotalShare() external view returns(uint256);
    function getShare(address stakeOwner) external view returns(uint256);
    function distributeProtocolReward() external returns(uint256);
    function distributePikaReward() external returns(uint256);
    function distributeVaultReward() external returns(uint256);
    function getPendingPikaReward() external view returns(uint256);
    function getPendingProtocolReward() external view returns(uint256);
    function getPendingVaultReward() external view returns(uint256);
    function stake(uint256 amount, address user) external payable;
    function redeem(uint256 shares) external;
    function openPosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 leverage
    ) external payable;
    function closePositionWithId(
        uint256 positionId,
        uint256 margin
    ) external;
    function closePosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong
    ) external;
    function liquidatePositions(uint256[] calldata positionIds) external;
    function getProduct(uint256 productId) external view returns (
        address,uint256,uint256,bool,uint256,uint256,uint256,uint256,uint256);
    function getPosition(
        address account,
        uint256 productId,
        bool isLong
    ) external view returns (uint256,uint256,uint256,uint256,uint256,address,uint256,bool,int256);
    function getMaxExposure(uint256 productWeight) external view returns(uint256);
    function getCumulativeFunding(uint256 _productId) external view returns(uint256);
    function liquidationThreshold() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

// Originally: https://github.com/CryptoManiacsZone/mooniswap/blob/master/contracts/libraries/UniERC20.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(0));
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (isETH(token)) {
                (bool success, ) = payable(to).call{value: amount}("");
                require(success, "Transfer failed");
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                if (msg.value > amount) {
                    // Return remainder if exist
                    uint256 refundAmount = msg.value.sub(amount);
                    (bool success, ) = msg.sender.call{value: refundAmount}("");
                    require(success, "Transfer failed");
                }
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '../oracle/IOracle.sol';
import '../lib/UniERC20.sol';
import '../lib/PerpLib.sol';
import './IPikaPerp.sol';
import './IFundingManager.sol';
import '../staking/IVaultReward.sol';

contract PikaPerpV3 is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;
    // All amounts are stored with 8 decimals

    // Structs

    struct Vault {
        // 32 bytes
        uint128 cap; // Maximum capacity. 16 bytes
        uint128 balance; // 16 bytes
        // 32 bytes
        uint96 staked; // Total staked by users. 12 bytes
        uint96 shares; // Total ownership shares. 12 bytes
        uint64 stakingPeriod; // Time required to lock stake (seconds). 8 bytes
    }

    struct Stake {
        // 32 bytes
        address owner; // 20 bytes
        uint96 amount; // 12 bytes
        // 32 bytes
        uint128 shares; // 16 bytes
        uint128 timestamp; // 16 bytes
    }

    struct Product {
        // 32 bytes
        address productToken;
        uint72 maxLeverage;
        uint16 fee; // In bps. 0.5% = 50.
        bool isActive;
        // 32 bytes
        uint64 openInterestLong;
        uint64 openInterestShort;
        uint32 minPriceChange; // 1.5%, the minimum oracle price up change for trader to close trade with profit
        uint32 weight; // share of the max exposure
        uint64 reserve; // Virtual reserve used to calculate slippage
    }

    struct Position {
        // 32 bytes
        uint64 productId;
        uint64 leverage;
        uint64 price;
        uint64 oraclePrice;
        // 32 bytes
        uint128 margin;
        int128 funding;
        // 32 bytes
        address owner;
        bool isLong;
        bool isNextPrice;
        uint80 timestamp;
    }

    // Variables

    address public owner;
    address public guardian;
    address public gov;
    address private token;
    address public oracle;
    address public protocolRewardDistributor;
    address public pikaRewardDistributor;
    address public vaultRewardDistributor;
    address public vaultTokenReward;
    address public feeCalculator;
    address public fundingManager;
    uint256 private tokenBase;
    uint256 public minMargin;
    uint256 public protocolRewardRatio = 2000;  // 20%
    uint256 public pikaRewardRatio = 3000;  // 30%
    uint256 public maxShift = 0.003e8; // max shift (shift is used adjust the price to balance the longs and shorts)
    uint256 public minProfitTime = 6 hours; // the time window where minProfit is effective
    uint256 public totalWeight; // total exposure weights of all product
    uint256 public exposureMultiplier = 10000; // exposure multiplier
    uint256 public utilizationMultiplier = 10000; // exposure multiplier
    uint256 public maxExposureMultiplier = 3; // total open interest of a product should not exceed maxExposureMultiplier * maxExposure
    uint256 private liquidationBounty = 5000; // In bps. 5000 = 50%
    uint256 public liquidationThreshold = 8000; // In bps. 8000 = 80%
    uint256 private pendingProtocolReward; // protocol reward collected
    uint256 private pendingPikaReward; // pika reward collected
    uint256 private pendingVaultReward; // vault reward collected
    uint256 public totalOpenInterest;
    uint256 public shiftDivider = 3;
    bool private canUserStake = true;
    bool private allowPublicLiquidator = false;
    bool private isTradeEnabled = true;
    bool private isManagerOnlyForOpen = false;
    bool private isManagerOnlyForClose = false;
    Vault private vault;
    uint256 private constant BASE = 10**8;

    mapping(uint256 => Product) private products;
    mapping(address => Stake) private stakes;
    mapping(uint256 => Position) private positions;
    mapping (address => bool) public liquidators;
    mapping (address => bool) public nextPriceManagers;
    mapping (address => bool) public managers;
    mapping (address => mapping (address => bool)) public approvedManagers;
    // Events

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 shares
    );
    event Redeemed(
        address indexed user,
        address indexed receiver,
        uint256 amount,
        uint256 shares,
        uint256 shareBalance,
        bool isFullRedeem
    );
    event NewPosition(
        uint256 indexed positionId,
        address indexed user,
        uint256 indexed productId,
        bool isLong,
        uint256 price,
        uint256 oraclePrice,
        uint256 margin,
        uint256 leverage,
        uint256 fee,
        bool isNextPrice,
        int256 funding
    );

    event AddMargin(
        uint256 indexed positionId,
        address indexed sender,
        address indexed user,
        uint256 margin,
        uint256 newMargin,
        uint256 newLeverage
    );
    event ClosePosition(
        uint256 indexed positionId,
        address indexed user,
        uint256 indexed productId,
        uint256 price,
        uint256 entryPrice,
        uint256 margin,
        uint256 leverage,
        uint256 fee,
        int256 pnl,
        int256 fundingPayment,
        bool wasLiquidated
    );
    event PositionLiquidated(
        uint256 indexed positionId,
        address indexed liquidator,
        uint256 liquidatorReward,
        uint256 remainingReward
    );
    event ProtocolRewardDistributed(
        address to,
        uint256 amount
    );
    event PikaRewardDistributed(
        address to,
        uint256 amount
    );
    event VaultRewardDistributed(
        address to,
        uint256 amount
    );
    event VaultUpdated(
        Vault vault
    );
    event ProductAdded(
        uint256 productId,
        Product product
    );
    event ProductUpdated(
        uint256 productId,
        Product product
    );
    event AddressesSet(
        address oracle,
        address feeCalculator,
        address fundingManager
    );
    event OwnerUpdated(
        address newOwner
    );
    event GuardianUpdated(
        address newGuardian
    );
    event GovUpdated(
        address newGov
    );

    // Constructor

    constructor(address _token, uint256 _tokenBase, address _oracle, address _feeCalculator, address _fundingManager) {
        owner = msg.sender;
        guardian = msg.sender;
        gov = msg.sender;
        token = _token;
        tokenBase = _tokenBase;
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
    }

    // Methods

    function stake(uint256 amount, address user) external payable nonReentrant {
        require((canUserStake || msg.sender == owner) && (msg.sender == user || _validateManager(user)), "!stake");
        IVaultReward(vaultRewardDistributor).updateReward(user);
        IVaultReward(vaultTokenReward).updateReward(user);
        IERC20(token).uniTransferFromSenderToThis(amount * tokenBase / BASE);
        require(uint256(vault.staked) + amount <= uint256(vault.cap), "!cap");
        uint256 shares = vault.staked > 0 ? amount * uint256(vault.shares) / uint256(vault.balance) : amount;
        vault.balance += uint128(amount);
        vault.staked += uint96(amount);
        vault.shares += uint96(shares);

        if (stakes[user].amount == 0) {
            stakes[user] = Stake({
            owner: user,
            amount: uint96(amount),
            shares: uint128(shares),
            timestamp: uint128(block.timestamp)
            });
        } else {
            stakes[user].amount += uint96(amount);
            stakes[user].shares += uint128(shares);
            if (!_validateManager(user)) {
                stakes[user].timestamp = uint128(block.timestamp);
            }
        }

        emit Staked(
            user,
            amount,
            shares
        );

    }

    function redeem(
        address user,
        uint256 shares,
        address receiver
    ) external {

        require(shares <= uint256(vault.shares) && (user == msg.sender || _validateManager(user)), "!redeem");

        IVaultReward(vaultRewardDistributor).updateReward(user);
        IVaultReward(vaultTokenReward).updateReward(user);
        Stake storage _stake = stakes[user];
        bool isFullRedeem = shares >= uint256(_stake.shares);
        if (isFullRedeem) {
            shares = uint256(_stake.shares);
        }

        uint256 timeDiff = block.timestamp - uint256(_stake.timestamp);
        require(timeDiff > uint256(vault.stakingPeriod), "!period");

        uint256 shareBalance = shares * uint256(vault.balance) / uint256(vault.shares);

        uint256 amount = shares * _stake.amount / uint256(_stake.shares);

        _stake.amount -= uint96(amount);
        _stake.shares -= uint128(shares);
        vault.staked -= uint96(amount);
        vault.shares -= uint96(shares);
        vault.balance -= uint128(shareBalance);

        require(totalOpenInterest <= uint256(vault.balance) * utilizationMultiplier / (10**4), "!utilized");

        if (isFullRedeem) {
            delete stakes[user];
        }
        IERC20(token).uniTransfer(receiver, shareBalance * tokenBase / BASE);

        emit Redeemed(
            user,
            receiver,
            amount,
            shares,
            shareBalance,
            isFullRedeem
        );
    }

    function openPosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong,
        uint256 leverage
    ) public payable nonReentrant {
        require(_validateManager(user) || (!isManagerOnlyForOpen && user == msg.sender), "!allowed");
        require(isTradeEnabled, "!enabled");
        // Check params
        require(margin >= minMargin && margin < type(uint64).max, "!margin");
        require(leverage >= 1 * BASE, "!lev");

        // Check product
        Product storage product = products[productId];
        require(product.isActive, "!active");
        require(leverage <= uint256(product.maxLeverage), "!max-lev");

        // Transfer margin plus fee
        uint256 tradeFee = PerpLib._getTradeFee(margin, leverage, uint256(product.fee), product.productToken, user, msg.sender, feeCalculator);
        IERC20(token).uniTransferFromSenderToThis((margin + tradeFee) * tokenBase / BASE);

        _updatePendingRewards(tradeFee);

        uint256 price = _calculatePrice(product.productToken, isLong, product.openInterestLong,
            product.openInterestShort, uint256(vault.balance) * uint256(product.weight) * exposureMultiplier / uint256(totalWeight) / (10**4),
            uint256(product.reserve), margin * leverage / BASE);

        _updateFundingAndOpenInterest(productId, margin * leverage / BASE, isLong, true);
        int256 funding = IFundingManager(fundingManager).getFunding(productId);

        Position storage position = positions[getPositionId(user, productId, isLong)];
        if (position.margin > 0) {
            price = (uint256(position.margin) * position.leverage * uint256(position.price) + margin * leverage * price) /
                (uint256(position.margin) * position.leverage + margin * leverage);
            funding = (int256(uint256(position.margin)) * int256(uint256(position.leverage)) * int256(position.funding) + int256(margin * leverage) * funding) /
                (int256(uint256(position.margin)) * int256(uint256(position.leverage)) + int256(margin * leverage));
            leverage = (uint256(position.margin) * uint256(position.leverage) + margin * leverage) / (uint256(position.margin) + margin);
            margin = uint256(position.margin) + margin;
        }

        positions[getPositionId(user, productId, isLong)] = Position({
        owner: user,
        productId: uint64(productId),
        margin: uint128(margin),
        leverage: uint64(leverage),
        price: uint64(price),
        oraclePrice: uint64(IOracle(oracle).getPrice(product.productToken)),
        timestamp: uint80(block.timestamp),
        isLong: isLong,
        // if no existing position, isNextPrice depends on if sender is a nextPriceManager,
        // else it is false if either existing position's isNextPrice is false or the current new position sender is not a nextPriceManager
        isNextPrice: position.margin == 0 ? nextPriceManagers[msg.sender] : (!position.isNextPrice ? false : nextPriceManagers[msg.sender]),
        funding: int128(funding)
        });
        emit NewPosition(
            getPositionId(user, productId, isLong),
            user,
            productId,
            isLong,
            price,
            IOracle(oracle).getPrice(product.productToken),
            margin,
            leverage,
            tradeFee,
            position.margin == 0 ? nextPriceManagers[msg.sender] : (!position.isNextPrice ? false : nextPriceManagers[msg.sender]),
            funding
        );
    }

    // Add margin to Position with positionId
    function addMargin(uint256 positionId, uint256 margin) external payable nonReentrant {

        IERC20(token).uniTransferFromSenderToThis(margin * tokenBase / BASE);

        // Check params
        require(margin >= minMargin, "!margin");

        // Check position
        Position storage position = positions[positionId];
        require(msg.sender == position.owner || _validateManager(position.owner), "!allowed");

        // New position params
        uint256 newMargin = uint256(position.margin) + margin;
        uint256 newLeverage = uint256(position.leverage) * uint256(position.margin) / newMargin;
        require(newLeverage >= 1 * BASE, "!low-lev");

        position.margin = uint128(newMargin);
        position.leverage = uint64(newLeverage);

        emit AddMargin(
            positionId,
            msg.sender,
            position.owner,
            margin,
            newMargin,
            newLeverage
        );

    }

    function closePosition(
        address user,
        uint256 productId,
        uint256 margin,
        bool isLong
    ) external {
        return closePositionWithId(getPositionId(user, productId, isLong), margin);
    }

    // Closes position from Position with id = positionId
    function closePositionWithId(
        uint256 positionId,
        uint256 margin
    ) public nonReentrant {
        // Check position
        Position storage position = positions[positionId];
        require(_validateManager(position.owner) || (!isManagerOnlyForClose && msg.sender == position.owner), "!close");

        // Check product
        Product storage product = products[uint256(position.productId)];

        bool isFullClose;
        if (margin >= uint256(position.margin)) {
            margin = uint256(position.margin);
            isFullClose = true;
        }

        uint256 price = _calculatePrice(product.productToken, !position.isLong, product.openInterestLong, product.openInterestShort,
            getMaxExposure(uint256(product.weight)), uint256(product.reserve), margin * position.leverage / BASE);

        _updateFundingAndOpenInterest(uint256(position.productId), margin * uint256(position.leverage) / BASE, position.isLong, false);
        int256 fundingPayment = PerpLib._getFundingPayment(fundingManager, position.isLong, position.productId, position.leverage, margin, position.funding);
        int256 pnl = PerpLib._getPnl(position.isLong, uint256(position.price), uint256(position.leverage), margin, price) - fundingPayment;
        bool isLiquidatable;
        if (pnl < 0 && uint256(-1 * pnl) >= margin * liquidationThreshold / (10**4)) {
            margin = uint256(position.margin);
            pnl = -1 * int256(uint256(position.margin));
            isLiquidatable = true;
        } else {
            // front running protection: if oracle price up change is smaller than threshold and minProfitTime has not passed
            // and either open or close order is not using next oracle price, the pnl is be set to 0
            if (pnl > 0 && !PerpLib._canTakeProfit(position.isLong, uint256(position.timestamp), uint256(position.oraclePrice),
                IOracle(oracle).getPrice(product.productToken), product.minPriceChange, minProfitTime) && (!position.isNextPrice || !nextPriceManagers[msg.sender])) {
                pnl = 0;
            }
        }

        uint256 totalFee = _updateVaultAndGetFee(pnl, position, margin, uint256(product.fee), product.productToken);

        emit ClosePosition(
            positionId,
            position.owner,
            uint256(position.productId),
            price,
            uint256(position.price),
            margin,
            uint256(position.leverage),
            totalFee,
            pnl,
            fundingPayment,
            isLiquidatable
        );

        if (isFullClose) {
            delete positions[positionId];
        } else {
            position.margin -= uint128(margin);
        }
    }

    function _updateVaultAndGetFee(
        int256 pnl,
        Position memory position,
        uint256 margin,
        uint256 fee,
        address productToken
    ) private returns(uint256) {
        uint256 totalFee = PerpLib._getTradeFee(margin, uint256(position.leverage), fee, productToken, position.owner, msg.sender, feeCalculator);
        int256 pnlAfterFee = pnl - int256(totalFee);
        // Update vault
        if (pnlAfterFee < 0) {
            uint256 _pnlAfterFee = uint256(-1 * pnlAfterFee);
            if (_pnlAfterFee < margin) {
                IERC20(token).uniTransfer(position.owner, (margin - _pnlAfterFee) * tokenBase / BASE);
                vault.balance += uint128(_pnlAfterFee);
            } else {
                vault.balance += uint128(margin);
                return totalFee;
            }

        } else {
            uint256 _pnlAfterFee = uint256(pnlAfterFee);
            // Check vault
            require(uint256(vault.balance) >= _pnlAfterFee, "!bal");
            vault.balance -= uint128(_pnlAfterFee);

            IERC20(token).uniTransfer(position.owner, (margin + _pnlAfterFee) * tokenBase / BASE);
        }

        _updatePendingRewards(totalFee);
        vault.balance -= uint128(totalFee);

        return totalFee;
    }

    // Liquidate positionIds
    function liquidatePositions(uint256[] calldata positionIds) external {
        require(liquidators[msg.sender] || allowPublicLiquidator, "!liquidator");

        uint256 totalLiquidatorReward;
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 positionId = positionIds[i];
            uint256 liquidatorReward = liquidatePosition(positionId);
            totalLiquidatorReward = totalLiquidatorReward + liquidatorReward;
        }
        if (totalLiquidatorReward > 0) {
            IERC20(token).uniTransfer(msg.sender, totalLiquidatorReward * tokenBase / BASE);
        }
    }


    function liquidatePosition(
        uint256 positionId
    ) private returns(uint256 liquidatorReward) {
        Position storage position = positions[positionId];
        if (position.productId == 0) {
            return 0;
        }
        Product storage product = products[uint256(position.productId)];
        uint256 price = IOracle(oracle).getPrice(product.productToken); // use oracle price for liquidation

        uint256 remainingReward;
        _updateFundingAndOpenInterest(uint256(position.productId), uint256(position.margin) * uint256(position.leverage) / BASE, position.isLong, false);
        int256 fundingPayment = PerpLib._getFundingPayment(fundingManager, position.isLong, position.productId, position.leverage, position.margin, position.funding);
        int256 pnl = PerpLib._getPnl(position.isLong, position.price, position.leverage, position.margin, price) - fundingPayment;
        require (pnl < 0 && uint256(-1 * pnl) >= uint256(position.margin) * liquidationThreshold / (10**4));
        if (uint256(position.margin) > uint256(-1*pnl)) {
            uint256 _pnl = uint256(-1*pnl);
            liquidatorReward = (uint256(position.margin) - _pnl) * liquidationBounty / (10**4);
            remainingReward = uint256(position.margin) - _pnl - liquidatorReward;
            _updatePendingRewards(remainingReward);
            vault.balance += uint128(_pnl);
        } else {
            vault.balance += uint128(position.margin);
        }

        emit ClosePosition(
            positionId,
            position.owner,
            uint256(position.productId),
            price,
            uint256(position.price),
            uint256(position.margin),
            uint256(position.leverage),
            0,
            -1*int256(uint256(position.margin)),
            fundingPayment,
            true
        );

        delete positions[positionId];

        emit PositionLiquidated(
            positionId,
            msg.sender,
            liquidatorReward,
            remainingReward
        );

        return liquidatorReward;
    }

    function _updatePendingRewards(uint256 reward) private {
        pendingProtocolReward = pendingProtocolReward + (reward * protocolRewardRatio / (10**4));
        pendingPikaReward = pendingPikaReward + (reward * pikaRewardRatio / (10**4));
        pendingVaultReward = pendingVaultReward + (reward * (10**4 - protocolRewardRatio - pikaRewardRatio) / (10**4));
    }

    function _updateFundingAndOpenInterest(uint256 productId, uint256 amount, bool isLong, bool isIncrease) private {
        IFundingManager(fundingManager).updateFunding(productId);
        Product storage product = products[productId];
        if (isIncrease) {
            totalOpenInterest = totalOpenInterest + amount;
            uint256 maxExposure = getMaxExposure(uint256(product.weight));
            require(totalOpenInterest <= uint256(vault.balance) * utilizationMultiplier / 10**4 &&
                uint256(product.openInterestLong) + uint256(product.openInterestShort) + amount < maxExposureMultiplier * maxExposure, "!maxOI");
            if (isLong) {
                product.openInterestLong = product.openInterestLong + uint64(amount);
                require(uint256(product.openInterestLong) <= uint256(maxExposure) + uint256(product.openInterestShort), "!exposure-long");
            } else {
                product.openInterestShort = product.openInterestShort + uint64(amount);
                require(uint256(product.openInterestShort) <= uint256(maxExposure) + uint256(product.openInterestLong), "!exposure-short");
            }
        } else {
            totalOpenInterest = totalOpenInterest - amount;
            if (isLong) {
                if (uint256(product.openInterestLong) >= amount) {
                    product.openInterestLong -= uint64(amount);
                } else {
                    product.openInterestLong = 0;
                }
            } else {
                if (uint256(product.openInterestShort) >= amount) {
                    product.openInterestShort -= uint64(amount);
                } else {
                    product.openInterestShort = 0;
                }
            }
        }
    }

    function _validateManager(address account) private view returns(bool) {
        return managers[msg.sender] && approvedManagers[account][msg.sender];
    }

    function distributeProtocolReward() external returns(uint256) {
        require(msg.sender == protocolRewardDistributor, "!dist");
        uint256 _pendingProtocolReward = pendingProtocolReward * tokenBase / BASE;
        if (pendingProtocolReward > 0) {
            pendingProtocolReward = 0;
            IERC20(token).uniTransfer(protocolRewardDistributor, _pendingProtocolReward);
            emit ProtocolRewardDistributed(protocolRewardDistributor, _pendingProtocolReward);
        }
        return _pendingProtocolReward;
    }

    function distributePikaReward() external returns(uint256) {
        require(msg.sender == pikaRewardDistributor, "!dist");
        uint256 _pendingPikaReward = pendingPikaReward * tokenBase / BASE;
        if (pendingPikaReward > 0) {
            pendingPikaReward = 0;
            IERC20(token).uniTransfer(pikaRewardDistributor, _pendingPikaReward);
            emit PikaRewardDistributed(pikaRewardDistributor, _pendingPikaReward);
        }
        return _pendingPikaReward;
    }

    function distributeVaultReward() external returns(uint256) {
        require(msg.sender == vaultRewardDistributor, "!dist");
        uint256 _pendingVaultReward = pendingVaultReward * tokenBase / BASE;
        if (pendingVaultReward > 0) {
            pendingVaultReward = 0;
            IERC20(token).uniTransfer(vaultRewardDistributor, _pendingVaultReward);
            emit VaultRewardDistributed(vaultRewardDistributor, _pendingVaultReward);
        }
        return _pendingVaultReward;
    }

    // Getters

    function getPendingPikaReward() external view returns(uint256) {
        return pendingPikaReward * tokenBase / BASE;
    }

    function getPendingProtocolReward() external view returns(uint256) {
        return pendingProtocolReward * tokenBase / BASE;
    }

    function getPendingVaultReward() external view returns(uint256) {
        return pendingVaultReward * tokenBase / BASE;
    }

    function getVault() external view returns(Vault memory) {
        return vault;
    }

    function getProduct(uint256 productId) external view returns (
        address,uint256,uint256,bool,uint256,uint256,uint256,uint256,uint256
    ) {
        Product memory product = products[productId];
        return (
        product.productToken,
        uint256(product.maxLeverage),
        uint256(product.fee),
        product.isActive,
        uint256(product.openInterestLong),
        uint256(product.openInterestShort),
        uint256(product.minPriceChange),
        uint256(product.weight),
        uint256(product.reserve));
    }

    function getPositionId(
        address account,
        uint256 productId,
        bool isLong
    ) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(account, productId, isLong)));
    }

    function getPosition(
        address account,
        uint256 productId,
        bool isLong
    ) external view returns (
        uint256,uint256,uint256,uint256,uint256,address,uint256,bool,int256
    ) {
        Position memory position = positions[getPositionId(account, productId, isLong)];
        return(
        uint256(position.productId),
        uint256(position.leverage),
        uint256(position.price),
        uint256(position.oraclePrice),
        uint256(position.margin),
        position.owner,
        uint256(position.timestamp),
        position.isLong,
        position.funding);
    }

    function getPositions(uint256[] calldata positionIds) external view returns(Position[] memory _positions) {
        uint256 length = positionIds.length;
        _positions = new Position[](length);
        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[positionIds[i]];
        }
    }

    function getMaxExposure(uint256 productWeight) public view returns(uint256) {
        return uint256(vault.balance) * productWeight * exposureMultiplier / uint256(totalWeight) / (10**4);
    }

    function getTotalShare() external view returns(uint256) {
        return uint256(vault.shares);
    }

    function getShare(address stakeOwner) external view returns(uint256) {
        return uint256(stakes[stakeOwner].shares);
    }

    function getStake(address stakeOwner) external view returns(Stake memory) {
        return stakes[stakeOwner];
    }

    // Private methods

    function _calculatePrice(
        address productToken,
        bool isLong,
        uint256 openInterestLong,
        uint256 openInterestShort,
        uint256 maxExposure,
        uint256 reserve,
        uint256 amount
    ) private view returns(uint256) {
        uint256 oraclePrice = isLong ? IOracle(oracle).getPrice(productToken, true) : IOracle(oracle).getPrice(productToken, false);
        int256 shift = (int256(openInterestLong) - int256(openInterestShort)) * int256(maxShift) / int256(maxExposure);
        if (isLong) {
            uint256 slippage = (reserve * reserve / (reserve - amount) - reserve) * BASE / amount;
            slippage = shift >= 0 ? slippage + uint256(shift) : slippage - (uint256(-1 * shift) / shiftDivider);
            return oraclePrice * slippage / BASE;
        } else {
            uint256 slippage = (reserve - (reserve * reserve) / (reserve + amount)) * BASE / amount;
            slippage = shift >= 0 ? slippage + (uint256(shift) / shiftDivider) : slippage - uint256(-1 * shift);
            return oraclePrice * slippage / BASE;
        }
    }

    // Owner methods

    function updateVault(Vault memory _vault) external {
        onlyOwner();
        require(_vault.cap > 0 && _vault.stakingPeriod > 0 && _vault.stakingPeriod < 30 days, "!allowed");

        vault.cap = _vault.cap;
        vault.stakingPeriod = _vault.stakingPeriod;

        emit VaultUpdated(vault);
    }

    function addProduct(uint256 productId, Product memory _product) external {
        onlyOwner();
        require(productId > 0);
        Product memory product = products[productId];

        require(product.maxLeverage == 0 && _product.maxLeverage > 1 * BASE && _product.productToken != address(0));

        products[productId] = Product({
        productToken: _product.productToken,
        maxLeverage: _product.maxLeverage,
        fee: _product.fee,
        isActive: true,
        openInterestLong: 0,
        openInterestShort: 0,
        minPriceChange: _product.minPriceChange,
        weight: _product.weight,
        reserve: _product.reserve
        });
        totalWeight = totalWeight + _product.weight;

        emit ProductAdded(productId, products[productId]);
    }

    function updateProduct(uint256 productId, Product memory _product) external {
        onlyOwner();
        require(productId > 0);
        Product storage product = products[productId];

        require(product.maxLeverage > 0 && _product.maxLeverage >= 1 * BASE && _product.productToken != address(0));

        product.productToken = _product.productToken;
        product.maxLeverage = _product.maxLeverage;
        product.fee = _product.fee;
        product.isActive = _product.isActive;
        product.minPriceChange = _product.minPriceChange;
        totalWeight = totalWeight - product.weight + _product.weight;
        product.weight = _product.weight;
        product.reserve = _product.reserve;

        emit ProductUpdated(productId, product);

    }

    function setDistributors(
        address _protocolRewardDistributor,
        address _pikaRewardDistributor,
        address _vaultRewardDistributor,
        address _vaultTokenReward
    ) external {
        onlyOwner();
        protocolRewardDistributor = _protocolRewardDistributor;
        pikaRewardDistributor = _pikaRewardDistributor;
        vaultRewardDistributor = _vaultRewardDistributor;
        vaultTokenReward = _vaultTokenReward;
    }

    function setManager(address _manager, bool _isActive) external {
        onlyOwner();
        managers[_manager] = _isActive;
    }

    function setAccountManager(address _manager, bool _isActive) external {
        approvedManagers[msg.sender][_manager] = _isActive;
    }

    function setRewardRatio(uint256 _protocolRewardRatio, uint256 _pikaRewardRatio) external {
        onlyOwner();
        require(_protocolRewardRatio + _pikaRewardRatio <= 10000);
        protocolRewardRatio = _protocolRewardRatio;
        pikaRewardRatio = _pikaRewardRatio;
    }

    function setMinMargin(uint256 _minMargin) external {
        onlyOwner();
        minMargin = _minMargin;
    }

    function setTradeEnabled(bool _isTradeEnabled) external {
        require(msg.sender == owner || managers[msg.sender]);
        isTradeEnabled = _isTradeEnabled;
    }

    function setParameters(
        uint256 _maxShift,
        uint256 _minProfitTime,
        bool _canUserStake,
        bool _allowPublicLiquidator,
        bool _isManagerOnlyForOpen,
        bool _isManagerOnlyForClose,
        uint256 _exposureMultiplier,
        uint256 _utilizationMultiplier,
        uint256 _maxExposureMultiplier,
        uint256 _liquidationBounty,
        uint256 _liquidationThreshold,
        uint256 _shiftDivider
    ) external {
        onlyOwner();
        require(_maxShift <= 0.01e8 && _minProfitTime <= 24 hours && _shiftDivider > 0 && _liquidationThreshold > 5000 && _maxExposureMultiplier > 0);
        maxShift = _maxShift;
        minProfitTime = _minProfitTime;
        canUserStake = _canUserStake;
        allowPublicLiquidator = _allowPublicLiquidator;
        isManagerOnlyForOpen = _isManagerOnlyForOpen;
        isManagerOnlyForClose = _isManagerOnlyForClose;
        exposureMultiplier = _exposureMultiplier;
        utilizationMultiplier = _utilizationMultiplier;
        maxExposureMultiplier = _maxExposureMultiplier;
        liquidationBounty = _liquidationBounty;
        liquidationThreshold = _liquidationThreshold;
        shiftDivider = _shiftDivider;
    }

    function setAddresses(address _oracle, address _feeCalculator, address _fundingManager) external {
        onlyOwner();
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
        emit AddressesSet(_oracle, _feeCalculator, _fundingManager);
    }

    function setLiquidator(address _liquidator, bool _isActive) external {
        onlyOwner();
        liquidators[_liquidator] = _isActive;
    }

    function setNextPriceManager(address _nextPriceManager, bool _isActive) external {
        onlyOwner();
        nextPriceManagers[_nextPriceManager] = _isActive;
    }

    function setOwner(address _owner) external {
        onlyGov();
        owner = _owner;
        emit OwnerUpdated(_owner);
    }

    function setGuardian(address _guardian) external {
        onlyGov();
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }

    function setGov(address _gov) external {
        onlyGov();
        gov = _gov;
        emit GovUpdated(_gov);
    }

    function pauseTrading() external {
        require(msg.sender == guardian, "!guard");
        isTradeEnabled = false;
        canUserStake = false;
    }

    function onlyOwner() private {
        require(msg.sender == owner, "!owner");
    }

    function onlyGov() private {
        require(msg.sender == gov, "!gov");
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;

interface IOracle {
    function getPrice(address feed) external view returns (uint256);
    function getPrice(address token, bool isMax) external view returns (uint256);
    function getLastNPrices(address token, uint256 n) external view returns(uint256[] memory);
    function setPrices(address[] memory tokens, uint256[] memory prices) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../oracle/IOracle.sol";
import '../perp/IFeeCalculator.sol';
import '../perp/IFundingManager.sol';

library PerpLib {
    uint256 private constant BASE = 10**8;
    uint256 private constant FUNDING_BASE = 10**12;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        uint256 positionOraclePrice,
        uint256 oraclePrice,
        uint256 minPriceChange,
        uint256 minProfitTime
    ) internal view returns(bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        } else if (isLong && oraclePrice > positionOraclePrice * (10**4 + minPriceChange) / (10**4)) {
            return true;
        } else if (!isLong && oraclePrice < positionOraclePrice * (10**4 - minPriceChange) / (10**4)) {
            return true;
        }
        return false;
    }

    function _getPnl(
        bool isLong,
        uint256 positionPrice,
        uint256 positionLeverage,
        uint256 margin,
        uint256 price
    ) internal view returns(int256 _pnl) {
        bool pnlIsNegative;
        uint256 pnl;
        if (isLong) {
            if (price >= positionPrice) {
                pnl = margin * positionLeverage * (price - positionPrice) / positionPrice / BASE;
            } else {
                pnl = margin * positionLeverage * (positionPrice - price) / positionPrice / BASE;
                pnlIsNegative = true;
            }
        } else {
            if (price > positionPrice) {
                pnl = margin * positionLeverage * (price - positionPrice) / positionPrice / BASE;
                pnlIsNegative = true;
            } else {
                pnl = margin * positionLeverage * (positionPrice - price) / positionPrice / BASE;
            }
        }

        if (pnlIsNegative) {
            _pnl = -1 * int256(pnl);
        } else {
            _pnl = int256(pnl);
        }

        return _pnl;
    }

    function _getFundingPayment(
        address fundingManager,
        bool isLong,
        uint256 productId,
        uint256 positionLeverage,
        uint256 margin,
        int256 funding
    ) internal view returns(int256) {
        return isLong ? int256(margin * positionLeverage) * (IFundingManager(fundingManager).getFunding(productId) - funding) / int256(BASE * FUNDING_BASE) :
            int256(margin * positionLeverage) * (funding - IFundingManager(fundingManager).getFunding(productId)) / int256(BASE * FUNDING_BASE);
    }

    function _getTradeFee(
        uint256 margin,
        uint256 leverage,
        uint256 productFee,
        address productToken,
        address user,
        address sender,
        address feeCalculator
    ) internal view returns(uint256) {
        uint256 fee = IFeeCalculator(feeCalculator).getFee(productToken, productFee, user, sender);
        return margin * leverage / BASE * fee / 10**4;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFundingManager {
    function updateFunding(uint256) external;
    function getFunding(uint256) external view returns(int256);
    function getFundingRate(uint256) external view returns(int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVaultReward {
    function updateReward(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeCalculator {
    function getFee(address token, uint256 productFee, address user, address sender) external view returns (uint256);
}