// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IPoolHook} from "../interfaces/IPoolHook.sol";
import {IPoolWithStorage} from "../interfaces/IPoolWithStorage.sol";
import {IMintableErc20} from "../interfaces/IMintableErc20.sol";
import {ILevelOracle} from "../interfaces/ILevelOracle.sol";
import {ITradingContest} from "../interfaces/ITradingContest.sol";
import {ITradingIncentiveController} from "../interfaces/ITradingIncentiveController.sol";
import {IReferralController} from "../interfaces/IReferralController.sol";
import {DataTypes} from "../lib/DataTypes.sol";

contract PoolHook is IPoolHook {
    uint8 constant lyLevelDecimals = 18;
    uint256 constant VALUE_PRECISION = 1e30;

    address private immutable pool;
    IMintableErc20 public immutable lyLevel;

    IReferralController immutable referralController;
    ITradingContest immutable tradingContest;
    ITradingIncentiveController immutable tradingIncentiveController;

    constructor(
        address _lyLevel,
        address _pool,
        address _referralController,
        address _tradingIncentiveController,
        address _tradingContest
    ) {
        if (_lyLevel == address(0)) revert InvalidAddress();
        if (_pool == address(0)) revert InvalidAddress();
        if (_referralController == address(0)) revert InvalidAddress();
        if (_tradingContest == address(0)) revert InvalidAddress();
        if (_tradingIncentiveController == address(0)) revert InvalidAddress();

        lyLevel = IMintableErc20(_lyLevel);
        pool = _pool;
        referralController = IReferralController(_referralController);
        tradingIncentiveController = ITradingIncentiveController(_tradingIncentiveController);
        tradingContest = ITradingContest(_tradingContest);
    }

    modifier onlyPool() {
        _validatePool(msg.sender);
        _;
    }

    /**
     * @inheritdoc IPoolHook
     */
    function postIncreasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        DataTypes.Side _side,
        bytes calldata _extradata
    ) external onlyPool {
        (,, uint256 _feeValue) = abi.decode(_extradata, (uint256, uint256, uint256));
        _updateReferralData(_owner, _feeValue);
        _sentTradingRecord(_owner, _feeValue);
        emit PostIncreasePositionExecuted(pool, _owner, _indexToken, _collateralToken, _side, _extradata);
    }

    /**
     * @inheritdoc IPoolHook
     */
    function postDecreasePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        DataTypes.Side _side,
        bytes calldata _extradata
    ) external onlyPool {
        ( /*uint256 sizeChange*/ , /* uint256 collateralValue */, uint256 _feeValue) =
            abi.decode(_extradata, (uint256, uint256, uint256));
        _updateReferralData(_owner, _feeValue);
        _sentTradingRecord(_owner, _feeValue);
        emit PostDecreasePositionExecuted(msg.sender, _owner, _indexToken, _collateralToken, _side, _extradata);
    }

    /**
     * @inheritdoc IPoolHook
     */
    function postLiquidatePosition(
        address _owner,
        address _indexToken,
        address _collateralToken,
        DataTypes.Side _side,
        bytes calldata _extradata
    ) external onlyPool {
        ( /*uint256 sizeChange*/ , /* uint256 collateralValue */, uint256 _feeValue) =
            abi.decode(_extradata, (uint256, uint256, uint256));
        _updateReferralData(_owner, _feeValue);
        _sentTradingRecord(_owner, _feeValue);
        emit PostLiquidatePositionExecuted(msg.sender, _owner, _indexToken, _collateralToken, _side, _extradata);
    }

    /**
     * @inheritdoc IPoolHook
     */
    function postSwap(address _user, address _tokenIn, address _tokenOut, bytes calldata _data) external onlyPool {
        ( /*uint256 amountIn*/ , /* uint256 amountOut */, uint256 feeValue, bytes memory extradata) =
            abi.decode(_data, (uint256, uint256, uint256, bytes));
        (address benificier) = extradata.length != 0 ? abi.decode(extradata, (address)) : (address(0));
        benificier = benificier == address(0) ? _user : benificier;
        _updateReferralData(benificier, feeValue);
        _sentTradingRecord(benificier, feeValue);
        emit PostSwapExecuted(msg.sender, _user, _tokenIn, _tokenOut, _data);
    }

    // ========= Admin function ========

    function _updateReferralData(address _trader, uint256 _value) internal {
        if (address(referralController) != address(0) && _trader != address(0)) {
            referralController.updateFee(_trader, _value);
        }
    }

    function _sentTradingRecord(address _trader, uint256 _value) internal {
        if (_value == 0 || _trader == address(0)) {
            return;
        }

        if (address(tradingIncentiveController) != address(0)) {
            tradingIncentiveController.record(_value);
        }

        if (address(tradingContest) != address(0)) {
            tradingContest.record(_trader, _value);
        }

        uint256 _lyTokenAmount = (_value * 10 ** lyLevelDecimals) / VALUE_PRECISION;
        lyLevel.mint(_trader, _lyTokenAmount);
    }

    function _validatePool(address sender) internal view {
        if (sender != pool) {
            revert OnlyPool();
        }
    }

    event ReferralControllerSet(address controller);
    event TradingIncentiveSet(address tradingRecord, address tradingIncentiveController);

    error InvalidAddress();
    error OnlyPool();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {IPool} from "./IPool.sol";
import {DataTypes} from "../lib/DataTypes.sol";

interface IPoolHook {
    /**
     * @notice Called after increase position or deposit collateral
     * @param extradata = encode of (sizeIncreased, collateralValueAdded, feeValue)
     * @dev all value of extradata is in USD
     */
    function postIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        DataTypes.Side side,
        bytes calldata extradata
    ) external;

    /**
     * @notice Called after decrease position / withdraw collateral
     * @param extradata = encode of (sizeDecreased, collateralValueReduced, feeValue)
     * @dev all value of extradata is in USD
     */
    function postDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        DataTypes.Side side,
        bytes calldata extradata
    ) external;

    /**
     * @notice Called after liquidate position
     * @param extradata = encode of (positionSize, collateralValue, feeValue)
     * @dev all value of extradata is in USD
     */
    function postLiquidatePosition(
        address owner,
        address indexToken,
        address collateralToken,
        DataTypes.Side side,
        bytes calldata extradata
    ) external;

    /**
     * @notice Called after increase position
     * @param user user who receive token out
     * @param tokenIn token swap from
     * @param tokenOut token swap to
     * @param data = encode of (amountIn, amountOutAfterFee, feeValue, extradata)
     * extradata include:
     *     - benificier address: address receive trading incentive
     * @dev
     *     - amountIn, amountOutAfterFee is number of token
     *     - feeValue is in USD
     */
    function postSwap(address user, address tokenIn, address tokenOut, bytes calldata data) external;

    event PreIncreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, DataTypes.Side side, bytes extradata
    );
    event PostIncreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, DataTypes.Side side, bytes extradata
    );
    event PreDecreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, DataTypes.Side side, bytes extradata
    );
    event PostDecreasePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, DataTypes.Side side, bytes extradata
    );
    event PreLiquidatePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, DataTypes.Side side, bytes extradata
    );
    event PostLiquidatePositionExecuted(
        address pool, address owner, address indexToken, address collateralToken, DataTypes.Side side, bytes extradata
    );

    event PostSwapExecuted(address pool, address user, address tokenIn, address tokenOut, bytes data);
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableErc20 is IERC20 {
    function mint(address to, uint256 amount) external;
}

pragma solidity >= 0.8.0;

interface ILevelOracle {
    function getPrice(address token, bool max) external view returns (uint256);
    function getMultiplePrices(address[] calldata tokens, bool max) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

struct BatchInfo {
    uint128 rewardTokens;
    uint64 startTime;
    uint64 endTime;
    uint64 startVestingTime;
    uint64 vestingDuration;
    uint128 totalWeight;
    bool leaderUpdated;
}

struct LeaderInfo {
    uint128 weight;
    uint128 claimed;
    uint256 totalPoint;
    uint8 index;
}

struct LeaderInfoView {
    address trader;
    uint128 rewardTokens;
    uint128 claimed;
    uint256 totalPoint;
    uint8 index;
}

struct ContestResult {
    address trader;
    uint8 index;
    uint256 totalPoint;
}

interface ITradingContest {
    function batchDuration() external returns (uint64);

    /**
     * @notice record trading point for trader
     * @param _user address of trader
     * @param _value fee collected in this trade
     */
    function record(address _user, uint256 _value) external;

    /**
     * @notice accept reward send from IncentiveController
     */
    function addReward(uint256 _rewardTokens) external;

    /**
     * @notice start a new batch and close current batch. Waiting for leaders to be set
     */
    function nextBatch() external;

    /**
     * @notice start first batch. Called only once by owner
     */
    function start(uint256 _startTime) external;

    function setPoolHook(address poolHook) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.0;

/**
 * @title ITradingIncentiveController
 * @author LevelFinance
 * @notice Tracking protocol fee and calculate incentive reward in a period of time called batch.
 * Once a batch finished, incentive distributed to lyLVL and Ladder
 */
interface ITradingIncentiveController {
    /**
     * @notice record trading fee collected in batch. Call by PoolHook only
     * @param _value trading generated. Includes swap and leverage trading
     */
    function record(uint256 _value) external;

    /**
     * @notice start tracking fee and calculate. Called only once by owner
     */
    function start(uint256 _startTime) external;

    /**
     * @notice finalize current batch and distribute rewards
     */
    function allocate() external;

    function setPoolHook(address poolHook) external;
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

interface ILiquidityCalculator {
    function getTrancheValue(address _tranche, bool _max) external view returns (uint256);

    function getPoolValue(bool _max) external view returns (uint256 sum);

    function calcSwapFee(bool _isStableSwap, address _token, uint256 _tokenPrice, uint256 _valueChange, bool _isSwapIn)
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