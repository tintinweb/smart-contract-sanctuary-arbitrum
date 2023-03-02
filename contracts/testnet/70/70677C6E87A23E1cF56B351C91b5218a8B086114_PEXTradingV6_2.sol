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
import './IPairsStorage.sol';
pragma solidity 0.8.17;

interface IAggregator{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(IPairsStorage);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function tokenUsdtReservesLp() external view returns(uint, uint);
    function openFeeP(uint) external view returns(uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

// SPDX-License-Identifier: MIT
import './IStorageT.sol';
pragma solidity 0.8.17;

interface INftRewards{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; IStorageT.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairsStorage{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function incrementCurrentOrderId() external returns(uint);
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairsCount() external view returns (uint);
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosUsdt(uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable{
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPEXPairInfos{
    function maxNegativePnlOnOpenP() external view returns(uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice,   // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (USDT)
    ) external view returns(
        uint priceImpactP,      // PRECISION (%)
        uint priceAfterImpact   // PRECISION
    );

   function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice,  // PRECISION
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage
    ) external view returns(uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral,   // 1e18 (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee    // 1e18 (USDT)
    ) external returns(uint amount, uint rolloverFee); // 1e18 (USDT)
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPToken{
    function sendAssets(uint assets, address receiver) external;
    function receiveAssets(uint assets, address user) external;

    function currentBalanceUsdt() external view returns(uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './ITokenV5.sol';
import './IPToken.sol';
import './IPairsStorage.sol';
import './IPausable.sol';
import './IAggregator.sol';

interface IStorageT{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosUSDT;       // 1e18
        uint positionSizeUsdt;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint openInterestUsdt;       // 1e18
        uint storeTradeBlock;
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (USDT)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function usdt() external view returns(IERC20);
    function token() external view returns(ITokenV5);
    function linkErc677() external view returns(ITokenV5);
    function priceAggregator() external view returns(IAggregator);
    function vault() external view returns(IPToken);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function transferUsdt(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint) external returns(uint);
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestUsdt(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function isBotListed(address) external view returns (bool);
    function fakeBlockNumber() external view returns(uint); // Testing
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenV5{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Delegatable {
    mapping (address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }

    function delegatedAction(address trader, bytes calldata call_data) external returns (bytes memory) {
        require(delegations[trader] == msg.sender, "DELEGATE_NOT_APPROVED");

        senderOverride = trader;
        (bool success, bytes memory result) = address(this).delegatecall(call_data);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577 (return the original revert reason)
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        senderOverride = address(0);

        return result;
    }


    function _msgSender() public view returns (address) {
        if (senderOverride == address(0)) {
            return msg.sender;
        } else {
            return senderOverride;
        }
    }
}

// SPDX-License-Identifier: MIT
import './Delegatable.sol';
import '../interfaces/ITokenV5.sol';
import '../interfaces/IPairsStorage.sol';
import '../interfaces/IStorageT.sol';
import '../interfaces/IPEXPairInfos.sol';
import '../interfaces/INftRewards.sol';

pragma solidity 0.8.17;

contract PEXTradingV6_2 is Delegatable {

    // Contracts (constant)
    IStorageT public immutable storageT;
    INftRewards public immutable nftRewards;
    IPEXPairInfos public immutable pairInfos;

    // Params (constant)
    uint constant PRECISION = 1e10;
    uint constant MAX_SL_P = 75;  // -75% PNL

    // Params (adjustable)
    uint public maxPosUsdt;            // 1e18 (eg. 75000 * 1e18)
    uint public limitOrdersTimelock;  // block (eg. 30)
    uint public marketOrdersTimeout;  // block (eg. 30)

    // State
    bool public isPaused;  // Prevent opening new trades
    bool public isDone;    // Prevent any interaction with the contract

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint value);

    event MarketOrderInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        bool open
    );

    event OpenLimitPlaced(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );
    event OpenLimitUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newPrice,
        uint newTp,
        uint newSl
    );
    event OpenLimitCanceled(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event TpUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newTp
    );
    event SlUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );
    event SlUpdateInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );

    event NftOrderInitiated(
        uint orderId,
        address indexed nftHolder,
        address indexed trader,
        uint indexed pairIndex
    );
    event NftOrderSameBlock(
        address indexed nftHolder,
        address indexed trader,
        uint indexed pairIndex
    );

    event ChainlinkCallbackTimeout(
        uint indexed orderId,
        IStorageT.PendingMarketOrder order
    );
    event CouldNotCloseTrade(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    constructor(
        IStorageT _storageT,
        INftRewards _nftRewards,
        IPEXPairInfos _pairInfos,
        uint _maxPosUsdt,
        uint _limitOrdersTimelock,
        uint _marketOrdersTimeout
    ) {
        require(address(_storageT) != address(0)
            && address(_nftRewards) != address(0)
            && address(_pairInfos) != address(0)
            && _maxPosUsdt > 0
            && _limitOrdersTimelock > 0
            && _marketOrdersTimeout > 0, "WRONG_PARAMS");

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;

        maxPosUsdt = _maxPosUsdt;
        limitOrdersTimelock = _limitOrdersTimelock;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov(){
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier notContract(){
        require(tx.origin == msg.sender);
        _;
    }
    modifier notDone(){
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setMaxPosUsdt(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        maxPosUsdt = value;
        
        emit NumberUpdated("maxPosUsdt", value);
    }
    function setLimitOrdersTimelock(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        limitOrdersTimelock = value;
        
        emit NumberUpdated("limitOrdersTimelock", value);
    }
    function setMarketOrdersTimeout(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;
        
        emit NumberUpdated("marketOrdersTimeout", value);
    }

    // Manage state
    function pause() external onlyGov{
        isPaused = !isPaused;

        emit Paused(isPaused);
    }
    function done() external onlyGov{
        isDone = !isDone;

        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        IStorageT.Trade memory t,
        INftRewards.OpenLimitOrderType orderType, // LEGACY => market
        uint slippageP // for market orders only
    ) external notContract notDone{

        require(!isPaused, "PAUSED");

        IAggregator aggregator = storageT.priceAggregator();
        IPairsStorage pairsStored = aggregator.pairsStorage();

        address sender = _msgSender();

        require(storageT.openTradesCount(sender, t.pairIndex)
            + storageT.pendingMarketOpenCount(sender, t.pairIndex)
            + storageT.openLimitOrdersCount(sender, t.pairIndex)
            < storageT.maxTradesPerPair(), 
            "MAX_TRADES_PER_PAIR");

        require(storageT.pendingOrderIdsCount(sender)
            < storageT.maxPendingMarketOrders(), 
            "MAX_PENDING_ORDERS");

        require(t.positionSizeUsdt <= maxPosUsdt, "ABOVE_MAX_POS");
        require(t.positionSizeUsdt * t.leverage
            >= pairsStored.pairMinLevPosUsdt(t.pairIndex), "BELOW_MIN_POS");

        require(t.leverage > 0 && t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) 
            && t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex), 
            "LEVERAGE_INCORRECT");

        require(t.tp == 0 || (t.buy ?
                t.tp > t.openPrice :
                t.tp < t.openPrice), "WRONG_TP");

        require(t.sl == 0 || (t.buy ?
                t.sl < t.openPrice :
                t.sl > t.openPrice), "WRONG_SL");

        (uint priceImpactP, ) = pairInfos.getTradePriceImpact(
            0,
            t.pairIndex,
            t.buy,
            t.positionSizeUsdt * t.leverage
        );

        require(priceImpactP * t.leverage
            <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");

        require(uint(orderType) >= 0 && uint(orderType) <= 1, "WRONG_ORDERTYPE");

        storageT.transferUsdt(sender, address(storageT), t.positionSizeUsdt);

        if(orderType != INftRewards.OpenLimitOrderType.LEGACY){
            uint index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

            storageT.storeOpenLimitOrder(
                IStorageT.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index,
                    t.positionSizeUsdt,
                    0,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    uint(orderType) // tokenId was not used, so i replace this param with orderType
                )
            );

            nftRewards.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);

            emit OpenLimitPlaced(
                sender,
                t.pairIndex,
                index
            );

        }else{
            uint orderId = aggregator.getPrice(
                t.pairIndex, 
                IAggregator.OrderType.MARKET_OPEN, 
                t.positionSizeUsdt * t.leverage
            );

            storageT.storePendingMarketOrder(
                IStorageT.PendingMarketOrder(
                    IStorageT.Trade(
                        sender,
                        t.pairIndex,
                        0,
                        0,
                        t.positionSizeUsdt,
                        0, 
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    slippageP,
                    0,
                    0
                ), orderId, true
            );

            emit MarketOrderInitiated(
                orderId,
                sender,
                t.pairIndex,
                true
            );
        }
    }

    // Close trade (MARKET)
    function closeTradeMarket(
        uint pairIndex,
        uint index
    ) external notContract notDone{

        address sender = _msgSender();

        IStorageT.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        IStorageT.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(storageT.pendingOrderIdsCount(sender)
            < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");

        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint orderId = storageT.priceAggregator().getPrice(
            pairIndex, 
            IAggregator.OrderType.MARKET_CLOSE, 
            t.initialPosUSDT * t.leverage / PRECISION
        );

        storageT.storePendingMarketOrder(
            IStorageT.PendingMarketOrder(
                IStorageT.Trade(
                    sender, pairIndex, index, 0, 0, 0, false, 0, 0, 0
                ),
                0, 0, 0, 0, 0
            ), orderId, false
        );

        emit MarketOrderInitiated(
            orderId,
            sender,
            pairIndex,
            false
        );
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex, 
        uint index, 
        uint price,  // PRECISION
        uint tp,
        uint sl
    ) external notContract notDone{

        address sender = _msgSender();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT");

        IStorageT.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender, pairIndex, index
        );

        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        require(tp == 0 || (o.buy ?
            tp > price :
            tp < price), "WRONG_TP");

        require(sl == 0 || (o.buy ?
            sl < price :
            sl > price), "WRONG_SL");

        o.minPrice = price;
        o.maxPrice = price;

        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);

        emit OpenLimitUpdated(
            sender,
            pairIndex,
            index,
            price,
            tp,
            sl
        );
    }

    function cancelOpenLimitOrder(
        uint pairIndex,
        uint index
    ) external notContract notDone{

        address sender = _msgSender();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT");

        IStorageT.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender, pairIndex, index
        );

        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferUsdt(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(
            sender,
            pairIndex,
            index
        );
    }

    // Manage limit order (TP/SL)
    function updateTp(
        uint pairIndex,
        uint index,
        uint newTp
    ) external notContract notDone{

        address sender = _msgSender();

        IStorageT.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        IStorageT.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(t.leverage > 0, "NO_TRADE");
        require(block.number - i.tpLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK");

        storageT.updateTp(sender, pairIndex, index, newTp);

        emit TpUpdated(
            sender,
            pairIndex,
            index,
            newTp
        );
    }

    function updateSl(
        uint pairIndex,
        uint index,
        uint newSl
    ) external notContract notDone{

        address sender = _msgSender();

        IStorageT.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        IStorageT.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(t.leverage > 0, "NO_TRADE");

        uint maxSlDist = t.openPrice * MAX_SL_P / 100 / t.leverage;

        require(newSl == 0 || (t.buy ? 
            newSl >= t.openPrice - maxSlDist :
            newSl <= t.openPrice + maxSlDist), "SL_TOO_BIG");
        
        require(block.number - i.slLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK");

        IAggregator aggregator = storageT.priceAggregator();

        if(newSl == 0
        || !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)){

            storageT.updateSl(sender, pairIndex, index, newSl);

            emit SlUpdated(
                sender,
                pairIndex,
                index,
                newSl
            );

        }else{
            uint orderId = aggregator.getPrice(
                pairIndex,
                IAggregator.OrderType.UPDATE_SL, 
                t.initialPosUSDT * t.leverage / PRECISION
            );

            aggregator.storePendingSlOrder(
                orderId, 
                IAggregator.PendingSl(
                    sender, pairIndex, index, t.openPrice, t.buy, newSl
                )
            );
            
            emit SlUpdateInitiated(
                orderId,
                sender,
                pairIndex,
                index,
                newSl
            );
        }
    }

    // Execute limit order
    function executeNftOrder(
        IStorageT.LimitOrder orderType, 
        address trader, 
        uint pairIndex, 
        uint index,
        uint nftId
    ) external notContract notDone{

        address sender = _msgSender();

        require(storageT.isBotListed(sender), "NOT_IN_BOTLISTS");

        require(block.number >=
            storageT.nftLastSuccess(nftId) + storageT.nftSuccessTimelock(),
            "SUCCESS_TIMELOCK");

        IStorageT.Trade memory t;

        if(orderType == IStorageT.LimitOrder.OPEN){
            require(storageT.hasOpenLimitOrder(trader, pairIndex, index),
                "NO_LIMIT");

        }else{
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");

            if(orderType == IStorageT.LimitOrder.LIQ){
                uint liqPrice = getTradeLiquidationPrice(t);
                
                require(t.sl == 0 || (t.buy ?
                    liqPrice > t.sl :
                    liqPrice < t.sl), "HAS_SL");

            }else{
                require(orderType != IStorageT.LimitOrder.SL || t.sl > 0,
                    "NO_SL");
                require(orderType != IStorageT.LimitOrder.TP || t.tp > 0,
                    "NO_TP");
            }
        }

        INftRewards.TriggeredLimitId memory triggeredLimitId =
            INftRewards.TriggeredLimitId(
                trader, pairIndex, index, orderType
            );

        if(!nftRewards.triggered(triggeredLimitId)
        || nftRewards.timedOut(triggeredLimitId)){
            
            uint leveragedPosUsdt;

            if(orderType == IStorageT.LimitOrder.OPEN){

                IStorageT.OpenLimitOrder memory l = storageT.getOpenLimitOrder(
                    trader, pairIndex, index
                );

                leveragedPosUsdt = l.positionSize * l.leverage;

                (uint priceImpactP, ) = pairInfos.getTradePriceImpact(
                    0,
                    l.pairIndex,
                    l.buy,
                    leveragedPosUsdt
                );
                
                require(priceImpactP * l.leverage <= pairInfos.maxNegativePnlOnOpenP(),
                    "PRICE_IMPACT_TOO_HIGH");

            }else{
                leveragedPosUsdt = t.initialPosUSDT * t.leverage / PRECISION;
            }

            storageT.transferLinkToAggregator(sender, pairIndex, leveragedPosUsdt);

            uint orderId = storageT.priceAggregator().getPrice(
                pairIndex, 
                orderType == IStorageT.LimitOrder.OPEN ? 
                    IAggregator.OrderType.LIMIT_OPEN : 
                    IAggregator.OrderType.LIMIT_CLOSE,
                leveragedPosUsdt
            );

            storageT.storePendingNftOrder(
                IStorageT.PendingNftOrder(
                    sender,
                    nftId,
                    trader,
                    pairIndex,
                    index,
                    orderType
                ), orderId
            );

            nftRewards.storeFirstToTrigger(triggeredLimitId, sender);
            
            emit NftOrderInitiated(
                orderId,
                sender,
                trader,
                pairIndex
            );

        }else{
            nftRewards.storeTriggerSameBlock(triggeredLimitId, sender);
            
            emit NftOrderSameBlock(
                sender,
                trader,
                pairIndex
            );
        }
    }
    // Avoid stack too deep error in executeNftOrder
    function getTradeLiquidationPrice(
        IStorageT.Trade memory t
    ) private view returns(uint){
        return pairInfos.getTradeLiquidationPrice(
            t.trader,
            t.pairIndex,
            t.index,
            t.openPrice,
            t.buy,
            t.initialPosUSDT / PRECISION,
            t.leverage
        );
    }

    // Market timeout
    function openTradeMarketTimeout(uint _order) external notContract notDone{
        address sender = _msgSender();

        IStorageT.PendingMarketOrder memory o =
            storageT.reqID_pendingMarketOrder(_order);

        IStorageT.Trade memory t = o.trade;

        require(o.block > 0
            && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferUsdt(address(storageT), sender, t.positionSizeUsdt);

        emit ChainlinkCallbackTimeout(
            _order,
            o
        );
    }
    
    function closeTradeMarketTimeout(uint _order) external notContract notDone{
        address sender = _msgSender();

        IStorageT.PendingMarketOrder memory o =
            storageT.reqID_pendingMarketOrder(_order);

        IStorageT.Trade memory t = o.trade;

        require(o.block > 0
            && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature(
                "closeTradeMarket(uint256,uint256)",
                t.pairIndex,
                t.index
            )
        );

        if(!success){
            emit CouldNotCloseTrade(
                sender,
                t.pairIndex,
                t.index
            );
        }

        emit ChainlinkCallbackTimeout(
            _order,
            o
        );
    }
}