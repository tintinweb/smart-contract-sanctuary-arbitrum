// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./interfaces/IDCADataStructures.sol";
import "./interfaces/IDCAAccount.sol";
import "./interfaces/IDCAExecutor.sol";
import "./security/onlyExecutor.sol";

contract DCAAccount is OnlyExecutor, IDCAAccount {
    Strategy[] private strategies_;
    // Thought on tracking balances, do we
    // a) base & target are mixed according to the token
    // b) separate accounting for base & target funds
    //   Option A
    mapping(IERC20 => uint256) private _balances;
    //   Option B
    mapping(IERC20 => uint256) private _baseBalances;
    mapping(IERC20 => uint256) private _targetBalances;

    mapping(uint256 => uint256) internal _lastExecution; // strategyId to block number
    mapping(IERC20 => uint256) internal _costPerBlock;
    // Mapping of Interval enum to block amounts
    mapping(Interval => uint256) public IntervalTimings;

    IDCAExecutor internal _executorAddress;

    uint24 private _poolFee = 3000;
    uint256 private _totalIntervalsExecuted;
    uint256 private _totalActiveStrategies;

    address constant WETH = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;
    address constant USDC = 0xd513E4537510C75E24f941f159B7CAFA74E7B3B9;
    address constant DAI = 0xe73C6dA65337ef99dBBc014C7858973Eba40a10b;
    address constant USDT = 0x8dA9412AbB78db20d0B496573D9066C474eA21B8;

    ISwapRouter immutable SWAP_ROUTER;

    constructor(
        address executorAddress_,
        address swapRouter_
    ) OnlyExecutor(address(executorAddress_)) Ownable(address(msg.sender)) {
        _changeDefaultExecutor(IDCAExecutor(executorAddress_));
        SWAP_ROUTER = ISwapRouter(swapRouter_);

        IntervalTimings[Interval.TestInterval] = 20;
        IntervalTimings[Interval.OneDay] = 5760;
        IntervalTimings[Interval.TwoDays] = 11520;
        IntervalTimings[Interval.OneWeek] = 40320;
        IntervalTimings[Interval.OneMonth] = 172800;
    }

    // Public Functions
    function Execute(uint256 strategyId_, uint256 feeAmount_) public override {
        require(strategies_[strategyId_].active, "Strategy is not active");
        _executeDCATrade(strategyId_, feeAmount_);
    }

    function SetupStrategy(
        Strategy memory newStrategy_,
        uint256 seedFunds_,
        bool subscribeToExecutor_
    ) public override onlyOwner {
        //Adds a new strategy to the system
        //Transfers the given amount of the base token to the account
        //If true subscribes the strategy to the default executor
        newStrategy_.strategyId = strategies_.length;
        newStrategy_.accountAddress = address(this);
        newStrategy_.active = false;
        strategies_.push(newStrategy_);

        if (seedFunds_ > 0)
            FundAccount(newStrategy_.baseToken.tokenAddress, seedFunds_);
        if (subscribeToExecutor_) _subscribeToExecutor(newStrategy_);
    }

    function SubscribeStrategy(uint256 strategyId_) public override onlyOwner {
        //Add the given strategy, once checking there are funds
        //to the default DCAExecutor
        require(
            !strategies_[strategyId_].active,
            "Strategy is already Subscribed"
        );
        _subscribeToExecutor(strategies_[strategyId_]);
    }

    function UnsubscribeStrategy(
        uint256 strategyId_
    ) public override onlyOwner {
        //remove the given strategy from its active executor
        require(
            strategies_[strategyId_].active,
            "Strategy is already Unsubscribed"
        );
        _unsubscribeToExecutor(strategyId_);
    }

    function ExecutorDeactivateStrategy(
        uint256 strategyId_
    ) public onlyExecutor {
        Strategy memory oldStrategy = strategies_[strategyId_];
        _costPerBlock[
            oldStrategy.baseToken.tokenAddress
        ] -= _calculateCostPerBlock(oldStrategy.amount, oldStrategy.interval);
        strategies_[oldStrategy.strategyId].active = false;
        _totalActiveStrategies -= 1;

        emit StrategyUnsubscribed(oldStrategy.strategyId);
    }

    function FundAccount(
        IERC20 token_,
        uint256 amount_
    ) public override onlyOwner {
        //Transfer the given amount of the given ERC20 token to the DCAAccount
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);
        _baseBalances[token_] += amount_;
    }

    function UnFundAccount(IERC20 token_, uint256 amount_) public onlyOwner {
        //Transfer the given amount of the given ERC20 token out of the DCAAccount
        require(_baseBalances[token_] <= amount_, "Balance of token to low");
        IERC20(token_).transfer(msg.sender, amount_);
        _baseBalances[token_] -= amount_;
    }

    function WithdrawSavings(IERC20 token_, uint256 amount_) public onlyOwner {
        //Transfer the given amount of the given ERC20 token out of the DCAAccount
        require(_targetBalances[token_] <= amount_, "Balance of token to low");
        IERC20(token_).transfer(msg.sender, amount_);
        _targetBalances[token_] -= amount_;
    }

    function GetBaseTokenCostPerBlock(
        IERC20 baseToken_
    ) public view returns (uint256) {
        return _costPerBlock[baseToken_];
    }

    function GetBaseTokenRemainingBlocks(
        IERC20 baseToken_
    ) public view returns (uint256) {
        return _baseBalances[baseToken_] / _costPerBlock[baseToken_];
    }

    function GetBaseBalance(
        IERC20 token_
    ) public view override returns (uint256) {
        return _baseBalances[token_];
    }

    function GetTargetBalance(
        IERC20 token_
    ) public view override returns (uint256) {
        return _targetBalances[token_];
    }

    function GetStrategyData(
        uint256 strategyId_
    ) public view returns (Strategy memory) {
        return strategies_[strategyId_];
    }

    // Internal & Private functions
    function _executeDCATrade(
        uint256 strategyId_,
        uint256 feeAmount_
    ) internal {
        //Example of how this might work using Uniswap
        //Get the stragegy
        Strategy memory selectedStrat = strategies_[strategyId_];

        //Check there is the balance
        if (
            _baseBalances[selectedStrat.baseToken.tokenAddress] <
            selectedStrat.amount
        ) revert("Base Balance too low");
        //  Work out the fee amounts
        uint256 feeAmount = _calculateFee(
            selectedStrat.baseToken,
            selectedStrat.amount,
            feeAmount_
        );
        uint256 tradeAmount = selectedStrat.amount - feeAmount;

        // Approve the router to spend the token in Uniswap.
        _approveSwapSpend(selectedStrat.baseToken.tokenAddress, tradeAmount);
        // Transfer teh fee to the DCAExecutpr
        _transferFee(feeAmount, selectedStrat.baseToken.tokenAddress);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(selectedStrat.baseToken.tokenAddress),
                tokenOut: address(selectedStrat.targetToken.tokenAddress),
                fee: _poolFee,
                recipient: address(this),
                deadline: block.timestamp + 60,
                amountIn: tradeAmount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        //  The call to `exactInputSingle` executes the swap.
        uint256 amountOut = SWAP_ROUTER.exactInputSingle(params);

        //  Update some tracking metrics
        //  Update balance & timetrack
        _targetBalances[selectedStrat.baseToken.tokenAddress] += amountOut;
        _baseBalances[selectedStrat.targetToken.tokenAddress] -= selectedStrat
            .amount;
        _lastExecution[selectedStrat.strategyId] = block.timestamp;
        _totalIntervalsExecuted += 1;

        emit StratogyExecuted(selectedStrat.strategyId);
    }

    function _subscribeToExecutor(Strategy memory newStrategy_) private {
        _costPerBlock[
            newStrategy_.baseToken.tokenAddress
        ] += _calculateCostPerBlock(newStrategy_.amount, newStrategy_.interval);

        _executorAddress.Subscribe(newStrategy_);
        strategies_[newStrategy_.strategyId].active = true;
        _totalActiveStrategies += 1;
        emit StrategySubscribed(
            newStrategy_.strategyId,
            address(_executorAddress)
        );
    }

    function _unsubscribeToExecutor(uint256 strategyId_) private {
        Strategy memory oldStrategy = strategies_[strategyId_];
        _costPerBlock[
            oldStrategy.baseToken.tokenAddress
        ] -= _calculateCostPerBlock(oldStrategy.amount, oldStrategy.interval);

        _executorAddress.Unsubscribe(oldStrategy);
        strategies_[oldStrategy.strategyId].active = false;
        _totalActiveStrategies -= 1;
        emit StrategyUnsubscribed(oldStrategy.strategyId);
    }

    function _changeDefaultExecutor(IDCAExecutor newAddress_) internal {
        require(
            _executorAddress != newAddress_,
            "Already using this DCA executor"
        );
        _executorAddress = newAddress_;
        _changeExecutorAddress(address(newAddress_));
        emit DCAExecutorChanged(address(newAddress_));
    }

    function _calculateCostPerBlock(
        uint256 amount_,
        Interval interval_
    ) internal view returns (uint256) {
        return amount_ / IntervalTimings[interval_];
    }

    function _calculateFee(
        TokeData memory strategyBaseToken_,
        uint256 strategyAmount_,
        uint256 feeAmount_
    ) internal returns (uint256 feeAmount) {
        // Need some logic to handel conversion of percent to the baseToken decimal places
        feeAmount = strategyAmount_ / feeAmount_;
        return feeAmount;
    }

    function _transferFee(uint256 feeAmount_, IERC20 tokenAddress_) internal {
        // Transfer teh fee to the DCAExecutpr
        tokenAddress_.transfer(address(_executorAddress), feeAmount_);
    }

    function _approveSwapSpend(IERC20 tokenAddress_, uint256 amount_) private {
        tokenAddress_.approve(address(SWAP_ROUTER), amount_);
    }

    function _buildSwapParams(
        IERC20 baseToken_,
        IERC20 targetToken_,
        uint256 amount_
    ) internal returns (ISwapRouter.ExactInputSingleParams memory) {
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        return
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(baseToken_),
                tokenOut: address(targetToken_),
                fee: _poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount_,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "./IDCADataStructures.sol";
import "./IDCAExecutor.sol";

interface IDCAAccount is IDCADataStructures {
    event StratogyExecuted(uint256 indexed strategyId_);
    event DCAExecutorChanged(address newAddress_);
    event StrategySubscribed(uint256 strategyId_, address executor_);
    event StrategyUnsubscribed(uint256 strategyId_);

    function Execute(uint256 strategyId_, uint256 feeAmount_) external;

    function SetupStrategy(
        Strategy calldata newStrategy_,
        uint256 seedFunds_,
        bool subscribeToEcecutor_
    ) external;

    function SubscribeStrategy(
        uint256 strategyId_
    ) external;

    function UnsubscribeStrategy(
        uint256 stratogyId
    ) external;

    function FundAccount(IERC20 token_, uint256 amount_) external;

    function GetBaseBalance(IERC20 token_) external returns (uint256);

    function GetTargetBalance(IERC20 token_) external returns (uint256);

    function UnFundAccount(IERC20 token_, uint256 amount_) external;

    function WithdrawSavings(IERC20 token_, uint256 amount_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDCADataStructures {
    // Define an enum to represent the interval type
    enum Interval {
        TestInterval, //Only for development
        OneDay, // 1 day = 5760 blocks
        TwoDays, // 2 days = 11520 blocks
        OneWeek, // 1 week = 40320 blocks
        OneMonth // 1 month = 172800 blocks
    }

    struct FeeDistribution {
        //These may move to s struct or set of if more call data is needed
        uint16 amountToExecutor; //In percent
        uint16 amountToComputing; //In percent
        uint16 amountToAdmin;
        uint16 feeAmount; //In percent
        address executionAddress;
        address computingAddress; //need to look into how distributed computing payments work
        address adminAddress;
    }

    // Define the Strategy struct
    struct Strategy {
        address accountAddress;
        TokeData baseToken;
        TokeData targetToken;
        Interval interval;
        uint256 amount;
        uint strategyId;
        bool reinvest;
        bool active;
        address revestContract; // should this be call data to execute?
    }

    struct TokeData {
        IERC20 tokenAddress;
        uint8 decimals;
        string ticker;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./IDCADataStructures.sol";

interface IDCAExecutor is IDCADataStructures {
    event ExecutionEOAAddressChange(address newExecutionEOA_, address changer_);
    event ExecutedDCA(Interval indexed interval_);
    event DCAAccontSubscription(Strategy interval_, bool active_);

    function Subscribe(
        Strategy calldata strategy_
    ) external returns (bool sucsess);

    function Unsubscribe(
        Strategy calldata strategy_
    ) external returns (bool sucsess);

    function Execute(Interval interval_) external;

    function ForceFeeFund() external;

    
}

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OnlyExecutor is Ownable {
    address private _executor;

    constructor(address executorAddress_) {
        _executor = executorAddress_;
    }

    modifier onlyExecutor() {
        require(_executor == msg.sender, "Address is not the executor");
        _;
    }

    function _changeExecutorAddress(address newAddress_) internal {
        _executor = newAddress_;
    }

    function removeExecutor() public onlyOwner {
        _executor = address(0x0);
    }

    function changeExecutor(address newExecutorAddress_) public onlyOwner {
        _executor = address(newExecutorAddress_);
    }
}