// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./interfaces/IPool.sol";
import "./interfaces/IStore.sol";

contract Pool is IPool {
    uint256 public constant BPS_DIVIDER = 10000;

    address public gov;
    address public trade;
    address public treasury;

    IStore public store;

    // Methods

    modifier onlyTrade() {
        require(msg.sender == trade, "!trade");
        _;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    constructor(address _gov) {
        gov = _gov;
    }

    function updateGov(address _gov) external onlyGov {
        require(_gov != address(0), "!address");

        address oldGov = gov;
        gov = _gov;

        emit GovernanceUpdated(oldGov, _gov);
    }

    function link(address _trade, address _store, address _treasury) external onlyGov {
        trade = _trade;
        store = IStore(_store);
        treasury = _treasury;
    }

    function addLiquidity(uint256 amount) external {
        require(amount > 0, "!amount");
        uint256 balance = store.poolBalance();
        address user = msg.sender;
        store.transferIn(user, amount);

        uint256 clpSupply = store.getCLPSupply();

        uint256 clpAmount = balance == 0 || clpSupply == 0 ? amount : amount * clpSupply / balance;

        store.incrementPoolBalance(amount);
        store.mintCLP(user, clpAmount);

        emit AddLiquidity(user, amount, clpAmount, store.poolBalance());
    }

    function addLiquidityThroughUniswap(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint24 poolFee)
        external
        payable
    {
        require(poolFee > 0, "!poolFee");
        require(msg.value != 0 || amountIn > 0 && tokenIn != address(0), "!input");

        address user = msg.sender;

        // executes swap, tokens will be deposited to store contract
        uint256 amountOut = store.swapExactInputSingle{value: msg.value}(user, amountIn, amountOutMin, tokenIn, poolFee);

        // add store supported liquidity
        uint256 balance = store.poolBalance();
        uint256 clpSupply = store.getCLPSupply();
        uint256 clpAmount = balance == 0 || clpSupply == 0 ? amountOut : amountOut * clpSupply / balance;

        store.incrementPoolBalance(amountOut);
        store.mintCLP(user, clpAmount);

        emit AddLiquidity(user, amountOut, clpAmount, store.poolBalance());
    }

    function removeLiquidity(uint256 amount) external {
        require(amount > 0, "!amount");

        address user = msg.sender;
        uint256 balance = store.poolBalance();
        uint256 clpSupply = store.getCLPSupply();
        require(balance > 0 && clpSupply > 0, "!empty");

        uint256 userBalance = store.getUserPoolBalance(user);
        if (amount > userBalance) amount = userBalance;

        uint256 feeAmount = amount * store.poolWithdrawalFee() / BPS_DIVIDER;
        uint256 amountMinusFee = amount - feeAmount;

        // CLP amount
        uint256 clpAmount = amountMinusFee * clpSupply / balance;

        store.decrementPoolBalance(amountMinusFee);
        store.burnCLP(user, clpAmount);

        store.transferOut(user, amountMinusFee);

        emit RemoveLiquidity(user, amount, feeAmount, clpAmount, store.poolBalance());
    }

    function creditTraderLoss(address user, string memory market, uint256 amount) external onlyTrade {
        store.incrementBufferBalance(amount);
        store.decrementBalance(user, amount);

        uint256 lastPaid = store.poolLastPaid();
        uint256 _now = block.timestamp;

        if (lastPaid == 0) {
            store.setPoolLastPaid(_now);
            return;
        }

        uint256 bufferBalance = store.bufferBalance();
        uint256 bufferPayoutPeriod = store.bufferPayoutPeriod();

        uint256 amountToSendPool = bufferBalance * (block.timestamp - lastPaid) / bufferPayoutPeriod;

        if (amountToSendPool > bufferBalance) amountToSendPool = bufferBalance;

        store.incrementPoolBalance(amountToSendPool);
        store.decrementBufferBalance(amountToSendPool);
        store.setPoolLastPaid(_now);

        emit PoolPayIn(user, market, amount, amountToSendPool, store.poolBalance(), store.bufferBalance());
    }

    function debitTraderProfit(address user, string memory market, uint256 amount) external onlyTrade {
        if (amount == 0) return;

        uint256 bufferBalance = store.bufferBalance();

        if (amount > bufferBalance) {
            uint256 diffToPayFromPool = amount - bufferBalance;
            uint256 poolBalance = store.poolBalance();
            require(diffToPayFromPool < poolBalance, "!pool-balance");
            store.decrementBufferBalance(bufferBalance);
            store.decrementPoolBalance(diffToPayFromPool);
        } else {
            store.decrementBufferBalance(amount);
        }

        store.incrementBalance(user, amount);

        emit PoolPayOut(user, market, amount, store.poolBalance(), store.bufferBalance());
    }

    function creditFee(address user, string memory market, uint256 fee, bool isLiquidation) external onlyTrade {
        if (fee == 0) return;

        uint256 poolFee = fee * store.poolFeeShare() / BPS_DIVIDER;
        uint256 treasuryFee = fee - poolFee;

        store.incrementPoolBalance(poolFee);
        store.transferOut(treasury, treasuryFee);

        emit FeePaid(
            user,
            market,
            fee, // paid by user //
            poolFee,
            isLiquidation
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IPool {
    event AddLiquidity(address indexed user, uint256 amount, uint256 clpAmount, uint256 poolBalance);
    event FeePaid(address indexed user, string market, uint256 fee, uint256 poolFee, bool isLiquidation);
    event GovernanceUpdated(address indexed oldGov, address indexed newGov);
    event PoolPayIn(
        address indexed user,
        string market,
        uint256 amount,
        uint256 bufferToPoolAmount,
        uint256 poolBalance,
        uint256 bufferBalance
    );
    event PoolPayOut(address indexed user, string market, uint256 amount, uint256 poolBalance, uint256 bufferBalance);
    event RemoveLiquidity(
        address indexed user, uint256 amount, uint256 feeAmount, uint256 clpAmount, uint256 poolBalance
    );

    function addLiquidity(uint256 amount) external;

    function addLiquidityThroughUniswap(address tokenIn, uint256 amountIn, uint256 amountOutMin, uint24 poolFee)
        external
        payable;

    function creditFee(address user, string memory market, uint256 fee, bool isLiquidation) external;

    function creditTraderLoss(address user, string memory market, uint256 amount) external;

    function debitTraderProfit(address user, string memory market, uint256 amount) external;

    function removeLiquidity(uint256 amount) external;

    function updateGov(address _gov) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IStore {
    // Events
    event GovernanceUpdated(address indexed oldGov, address indexed newGov);

    // Structs
    struct Market {
        string symbol;
        address feed;
        uint16 minSettlementTime; // overflows at ~18hrs
        uint16 maxLeverage; // overflows at 65535
        uint32 fee; // in bps, overflows at 4.3 billion
        uint32 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 maxOI;
        uint256 minSize;
    }

    struct Order {
        bool isLong;
        bool isReduceOnly;
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        uint72 orderId; // overflows at 4.7 * 10**21
        address user;
        string market;
        uint64 timestamp;
        uint192 fee;
        uint256 price;
        uint256 margin;
        uint256 size;
    }

    struct Position {
        bool isLong;
        uint64 timestamp;
        address user;
        string market;
        int256 fundingTracker;
        uint256 price;
        uint256 margin;
        uint256 size;
    }

    function BPS_DIVIDER() external view returns (uint256);

    function FUNDING_INTERVAL() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MAX_KEEPER_FEE_SHARE() external view returns (uint256);

    function MAX_POOL_WITHDRAWAL_FEE() external view returns (uint256);

    function addOrUpdatePosition(Position memory position) external;

    function addOrder(Order memory order) external returns (uint256);

    function bufferBalance() external view returns (uint256);

    function bufferPayoutPeriod() external view returns (uint256);

    function burnCLP(address user, uint256 amount) external;

    function clp() external view returns (address);

    function currency() external view returns (address);

    function decrementBalance(address user, uint256 amount) external;

    function decrementBufferBalance(uint256 amount) external;

    function decrementOI(string memory market, uint256 size, bool isLong) external;

    function decrementPoolBalance(uint256 amount) external;

    function getBalance(address user) external view returns (uint256);

    function getCLPSupply() external view returns (uint256);

    function getEstimatedOutputTokens(uint256 amountIn, address tokenIn, uint24 poolFee)
        external
        returns (uint256 amountOut);

    function getFundingFactor(string memory market) external view returns (uint256);

    function getFundingLastUpdated(string memory market) external view returns (uint256);

    function getFundingTracker(string memory market) external view returns (int256);

    function getLockedMargin(address user) external view returns (uint256);

    function getMarket(string memory market) external view returns (Market memory _market);

    function getMarketList() external view returns (string[] memory);

    function getOILong(string memory market) external view returns (uint256);

    function getOIShort(string memory market) external view returns (uint256);

    function getOrder(uint256 id) external view returns (Order memory _order);

    function getOrders() external view returns (Order[] memory _orders);

    function getPosition(address user, string memory market) external view returns (Position memory position);

    function getUserOrders(address user) external view returns (Order[] memory _orders);

    function getUserPoolBalance(address user) external view returns (uint256);

    function getUserPositions(address user) external view returns (Position[] memory _positions);

    function getUserWithLockedMargin(uint256 i) external view returns (address);

    function getUsersWithLockedMarginLength() external view returns (uint256);

    function gov() external view returns (address);

    function incrementBalance(address user, uint256 amount) external;

    function incrementBufferBalance(uint256 amount) external;

    function incrementOI(string memory market, uint256 size, bool isLong) external;

    function incrementPoolBalance(uint256 amount) external;

    function keeperFeeShare() external view returns (uint256);

    function link(address _trade, address _pool, address _currency, address _clp) external;

    function linkUniswap(address _swapRouter, address _quoter, address _weth) external;

    function lockMargin(address user, uint256 amount) external;

    function marketList(uint256) external view returns (string memory);

    function minimumMarginLevel() external view returns (uint256);

    function mintCLP(address user, uint256 amount) external;

    function pool() external view returns (address);

    function poolBalance() external view returns (uint256);

    function poolFeeShare() external view returns (uint256);

    function poolLastPaid() external view returns (uint256);

    function poolWithdrawalFee() external view returns (uint256);

    function quoter() external view returns (address);

    function removeOrder(uint256 _orderId) external;

    function removePosition(address user, string memory market) external;

    function setBufferPayoutPeriod(uint256 amount) external;

    function setFundingLastUpdated(string memory market, uint256 timestamp) external;

    function setKeeperFeeShare(uint256 amount) external;

    function setMarket(string memory market, Market memory marketInfo) external;

    function setMinimumMarginLevel(uint256 amount) external;

    function setPoolFeeShare(uint256 amount) external;

    function setPoolLastPaid(uint256 timestamp) external;

    function setPoolWithdrawalFee(uint256 amount) external;

    function swapExactInputSingle(address user, uint256 amountIn, uint256 amountOutMin, address tokenIn, uint24 poolFee)
        external
        payable
        returns (uint256 amountOut);

    function swapRouter() external view returns (address);

    function trade() external view returns (address);

    function transferIn(address user, uint256 amount) external;

    function transferOut(address user, uint256 amount) external;

    function unlockMargin(address user, uint256 amount) external;

    function updateFundingTracker(string memory market, int256 fundingIncrement) external;

    function updateGov(address _gov) external;

    function updateOrder(Order memory order) external;

    function weth() external view returns (address);
}