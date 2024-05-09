// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/SafeCast.sol";
import "../libraries/SignedSafeMath.sol";
import "../interfaces/IMarketLogic.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IMarketPriceFeed.sol";
import "../interfaces/IFundingLogic.sol";

contract MarketLogic is IMarketLogic {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int8;
    using SafeCast for int256;
    using SafeCast for uint256;

    uint256 constant RATE_PRECISION = 1e6;          // rate decimal 1e6
    uint256 constant PRICE_PRECISION = 1e10;        // price decimal 1e10
    uint256 constant AMOUNT_PRECISION = 1e20;       // amount decimal 1e20

    address manager;
    address marketPriceFeed;

    event UpdateMarketPriceFeed(address marketPriceFeed);
    event DustPositionClosed(address taker, address market, uint256 positionId, uint256 amount, uint256 takerMargin, uint256 makerMargin, uint256 value, int256 fundingPayment, uint256 interestPayment);

    constructor(address _manager) {
        require(_manager != address(0), "MarketLogic: manager is zero address");
        manager = _manager;
    }

    modifier onlyMarket() {
        require(IManager(manager).checkMarket(msg.sender), "MarketLogic: Must be market");
        _;
    }

    function updateMarketPriceFeed(address _marketPriceFeed) external {
        require(IManager(manager).checkController(msg.sender), "MarketLogic: !controller");
        require(_marketPriceFeed != address(0), "MarketLogic: marketPriceFeed is zero address");
        marketPriceFeed = _marketPriceFeed;
        emit UpdateMarketPriceFeed(_marketPriceFeed);
    }

    /// @notice temporary variables used by the trading process
    struct TradeInternalParams {
        MarketDataStructure.MarketConfig marketConfig;     // config of the market
        MarketDataStructure.PositionMode positionMode;     // position mode

        uint8 marketType;                   // market type
        address pool;

        uint256 orderValue;                 // order values
        uint256 deltaAmount;                // amount changes of the position during the order execution
        uint256 price;                      // trade price
        uint256 indexPrice;                 // index price when order execution
        uint256 closeRatio;                 // close ratio if reducing position

        uint256 settleTakerMargin;          // taker margin to be settled
        uint256 settleMakerMargin;          // maker(pool) margin to be settled
        uint256 settleValue;                // position value to be settled
        uint256 settleDebtShare;            // position debt shares to be settled
        uint256 interestPayment;            // interests amount to be settled

        uint256 feeAvailable;               // available trading fee, original trading fee subs the discount and invitor reward
        uint256 feeForOriginal;             // fee charged by increase or decrease original position
        uint256 feeForPositionReversal;     // fee charged by position reversal part
        uint256 feeToDiscountSettle;        // fee discount of the origin part
        int256 toTaker;                     // refund to the taker
        uint256 tmpMakerMargin;
    }

    /// @notice trade logic, calculate all things when an order is executed
    /// @param id order id
    /// @param positionId position id
    /// @param discountRate discount ratio of the trading fee
    /// @param inviteRate fee reward ratio for the invitor
    /// @return order order
    /// @return position position
    /// @return response response detailed in the data structure declaration
    function trade(uint256 id, uint256 positionId, uint256 discountRate, uint256 inviteRate) external override onlyMarket returns (MarketDataStructure.Order memory order, MarketDataStructure.Position memory position, MarketDataStructure.TradeResponse memory response) {
        // init parameters and configurations to be used
        TradeInternalParams memory iParams;
        iParams.marketConfig = IMarket(msg.sender).getMarketConfig();
        iParams.marketType = IMarket(msg.sender).marketType();
        iParams.pool = IMarket(msg.sender).pool();
        order = IMarket(msg.sender).getOrder(id);
        iParams.positionMode = IMarket(msg.sender).positionModes(order.taker);
        position = IMarket(msg.sender).getPosition(positionId);
        
        // position initiation if empty
        if (position.amount == 0) {
            position.id = positionId;
            position.taker = order.taker;
            position.market = order.market;
            position.multiplier = order.multiplier;
            position.takerLeverage = order.takerLeverage;
            position.direction = order.direction;
            position.isETH = order.isETH;
            position.stopLossPrice = 0;
            position.takeProfitPrice = 0;
            position.lastTPSLTs = 0;
        } else {
            // ensure the same leverage in order and position if the position is not empty
            require(position.takerLeverage == order.takerLeverage,"MT0");
        }

        // get trading price, calculate delta amount and delta value
        if (order.orderType == MarketDataStructure.OrderType.Open || order.orderType == MarketDataStructure.OrderType.TriggerOpen) {
            iParams.orderValue = adjustPrecision(order.freezeMargin.mul(order.takerLeverage), iParams.marketConfig.marketAssetPrecision, AMOUNT_PRECISION);
            if (iParams.marketType == 2) {
                iParams.orderValue = iParams.orderValue.mul(RATE_PRECISION).div(position.multiplier);
            }
        } else {
            require(position.amount != 0 && position.direction != order.direction,"MT1");
            iParams.deltaAmount = position.amount >= order.amount ? order.amount : position.amount;
        }
        
        (iParams.deltaAmount, iParams.orderValue, iParams.price) = getPrice(iParams.pool ,order.market, order.direction, iParams.deltaAmount, iParams.orderValue, false);
        require((order.takerOpenPriceMin > 0 ? iParams.price >= order.takerOpenPriceMin : true) && (order.takerOpenPriceMax > 0 ? iParams.price <= order.takerOpenPriceMax : true), "MT2");

        response.tradeValue = iParams.marketType == 1 ? iParams.deltaAmount : iParams.orderValue;
        order.takerFee = iParams.orderValue.mul(iParams.marketConfig.tradeFeeRate).div(RATE_PRECISION);
        if (iParams.marketType == 2) order.takerFee = order.takerFee.mul(position.multiplier).div(RATE_PRECISION);
        order.takerFee = adjustPrecision(order.takerFee, AMOUNT_PRECISION, iParams.marketConfig.marketAssetPrecision);
        order.feeToInviter = order.takerFee.mul(inviteRate).div(RATE_PRECISION);
        order.feeToDiscount = order.takerFee.mul(discountRate).div(RATE_PRECISION);
        iParams.feeAvailable = order.takerFee.sub(order.feeToInviter).sub(order.feeToDiscount);
        order.feeToMaker = iParams.feeAvailable.mul(iParams.marketConfig.makerFeeRate).div(RATE_PRECISION);
        order.feeToExchange = iParams.feeAvailable.sub(order.feeToMaker);

        if (position.direction == order.direction) {
            // increase position amount
            if (position.amount > 0) increasePositionValidate(iParams.price, iParams.pool, iParams.marketType, iParams.marketConfig.marketAssetPrecision, position);
            
            position.amount = position.amount.add(iParams.deltaAmount);
            position.value = position.value.add(iParams.orderValue);
            order.rlzPnl = 0;
            order.amount = iParams.deltaAmount;
            iParams.tmpMakerMargin = adjustPrecision(iParams.orderValue, AMOUNT_PRECISION, iParams.marketConfig.marketAssetPrecision);
            position.makerMargin = position.makerMargin.add(iParams.tmpMakerMargin);
            position.takerMargin = position.takerMargin.add(order.freezeMargin.sub(order.takerFee).add(order.feeToDiscount));
            // interests global information updated before
            position.debtShare = position.debtShare.add(IPool(iParams.pool).getCurrentShare(position.direction, iParams.tmpMakerMargin));

            response.isIncreasePosition = true;
        } else {
            // decrease the position or position reversal
            iParams.closeRatio = iParams.deltaAmount.mul(AMOUNT_PRECISION).div(position.amount);

            if (position.amount >= iParams.deltaAmount) {
                // decrease the position, no position reversal
                // split the position data according to the close ratio
                iParams.settleTakerMargin = position.takerMargin.mul(iParams.closeRatio).div(AMOUNT_PRECISION);
                iParams.settleMakerMargin = position.makerMargin.mul(iParams.closeRatio).div(AMOUNT_PRECISION);
                iParams.settleValue = position.value.mul(iParams.closeRatio).div(AMOUNT_PRECISION);
                iParams.settleDebtShare = position.debtShare.mul(iParams.closeRatio).div(AMOUNT_PRECISION);
                order.fundingPayment = position.fundingPayment.mul(iParams.closeRatio.toInt256()).div(AMOUNT_PRECISION.toInt256());

                // calculate the trading pnl, funding payment and interest payment
                order.rlzPnl = calculatePnl(iParams.orderValue, iParams.settleValue, iParams.marketType, iParams.marketConfig.marketAssetPrecision, position);
                order.interestPayment = getInterestPayment(iParams.pool, position.direction, position.debtShare, position.makerMargin);
                response.leftInterestPayment = order.interestPayment.mul(AMOUNT_PRECISION - iParams.closeRatio).div(AMOUNT_PRECISION);
                order.interestPayment = order.interestPayment.sub(response.leftInterestPayment);
                iParams.toTaker = iParams.settleTakerMargin.sub(order.takerFee).toInt256().sub(order.interestPayment.toInt256()).add(order.feeToDiscount.toInt256()).add(order.rlzPnl).sub(order.fundingPayment);

                // in case of bankruptcy
                require(iParams.toTaker >= 0, "MT3");
                // rlzPnl - fundingPayment <= maker(pool) margin
                require(order.rlzPnl <= iParams.settleMakerMargin.toInt256().add(order.fundingPayment), "MT4");

                // update order and position data
                response.toTaker = iParams.toTaker.toUint256().add(order.freezeMargin);

                order.amount = iParams.deltaAmount;
                position.fundingPayment = position.fundingPayment.sub(order.fundingPayment);
                position.pnl = position.pnl.add(order.rlzPnl);
                position.takerMargin = position.takerMargin.sub(iParams.settleTakerMargin);
                position.makerMargin = position.makerMargin.sub(iParams.settleMakerMargin);
                position.debtShare = position.debtShare.sub(iParams.settleDebtShare);
                position.amount = position.amount.sub(iParams.deltaAmount);
                position.value = position.value.sub(iParams.settleValue);

                response.isDecreasePosition = true;
            }
            else {
                // position reversal, only allowed in the one-way position mode
                // which is equivalent to two separate processes: 1. fully close the position; 2. open a new with opposite direction;
                require(iParams.positionMode == MarketDataStructure.PositionMode.OneWay, "MT5");

                // split the order data according to the close ratio
                iParams.settleTakerMargin = order.freezeMargin.mul(AMOUNT_PRECISION).div(iParams.closeRatio);
                iParams.settleValue = iParams.orderValue.mul(AMOUNT_PRECISION).div(iParams.closeRatio);

                // calculate the trading pnl, funding payment and interest payment
                order.rlzPnl = calculatePnl(iParams.settleValue, position.value, iParams.marketType, iParams.marketConfig.marketAssetPrecision, position);

                // specially the trading fee will be split to tow parts
                iParams.feeToDiscountSettle = order.feeToDiscount.mul(AMOUNT_PRECISION).div(iParams.closeRatio);
                iParams.feeForOriginal = order.takerFee.mul(AMOUNT_PRECISION).div(iParams.closeRatio);
                iParams.feeForPositionReversal = order.takerFee.sub(iParams.feeForOriginal).sub(order.feeToDiscount.sub(iParams.feeToDiscountSettle));
                iParams.feeForOriginal = iParams.feeForOriginal.sub(iParams.feeToDiscountSettle);

                order.interestPayment = getInterestPayment(iParams.pool, position.direction, position.debtShare, position.makerMargin);
                iParams.toTaker = position.takerMargin.toInt256().sub(position.fundingPayment).sub(iParams.feeForOriginal.toInt256()).sub(order.interestPayment.toInt256()).add(order.rlzPnl);

                // in case of bankruptcy
                require(iParams.toTaker >= 0, "MT6");
                // rlzPnl - fundingPayment <= maker(pool) margin
                require(order.rlzPnl <= position.makerMargin.toInt256().add(position.fundingPayment), "MT7");

                response.toTaker = iParams.toTaker.toUint256().add(iParams.settleTakerMargin);

                // update order and position data
                order.fundingPayment = position.fundingPayment;
                order.amount = position.amount;
                position.amount = iParams.deltaAmount.sub(position.amount);
                position.value = iParams.orderValue.sub(iParams.settleValue);
                position.direction = order.direction;
                position.takerMargin = order.freezeMargin.sub(iParams.settleTakerMargin);
                iParams.tmpMakerMargin = adjustPrecision(position.value, AMOUNT_PRECISION, iParams.marketConfig.marketAssetPrecision);
                position.makerMargin = iParams.tmpMakerMargin;
                position.takerMargin = position.takerMargin.sub(iParams.feeForPositionReversal);
                position.fundingPayment = 0;
                position.pnl = position.pnl.add(order.rlzPnl);
                position.debtShare = IPool(iParams.pool).getCurrentShare(position.direction, iParams.tmpMakerMargin);
                position.stopLossPrice = 0;
                position.takeProfitPrice = 0;
                position.lastTPSLTs = 0;
                
                response.isDecreasePosition = true;
                response.isIncreasePosition = true;
            }
        }
        // clear dust position
        if (position.amount < iParams.marketConfig.DUST && position.amount > 0) {
            getPrice(iParams.pool ,order.market, position.direction.neg256().toInt8(), position.amount, 0, false);
            
            int256 settleDustMargin = position.takerMargin.toInt256().sub(position.fundingPayment).sub(response.leftInterestPayment.toInt256());
            if (settleDustMargin > 0) {
                response.toTaker = response.toTaker.add(settleDustMargin.toUint256());
            } else {
                order.rlzPnl = order.rlzPnl.add(settleDustMargin);
            }

            emit DustPositionClosed(
                order.taker,
                order.market,
                position.id,
                position.amount,
                position.takerMargin,
                position.makerMargin,
                position.value,
                position.fundingPayment,
                response.leftInterestPayment
            );

            order.interestPayment = order.interestPayment.add(response.leftInterestPayment);
            order.fundingPayment = order.fundingPayment.add(position.fundingPayment);

            position.fundingPayment = 0;
            position.takerMargin = 0;
            position.makerMargin = 0;
            position.debtShare = 0;
            position.amount = 0;
            position.value = 0;

            response.isIncreasePosition = false;
        }

        order.frX96 = IMarket(msg.sender).fundingGrowthGlobalX96();
        order.tradeTs = block.timestamp;
        order.tradePrice = iParams.price;
        order.status = MarketDataStructure.OrderStatus.Opened;
        position.lastUpdateTs = position.amount > 0 ? block.timestamp : 0;

        return (order, position, response);
    }

    /// @notice calculation trading pnl using the position open value and closing order value
    /// @param  closeValue close order value
    /// @param  openValue position open value
    /// @param  marketType market type
    /// @param  marketAssetPrecision base asset precision of the market
    /// @param  position position data
    function calculatePnl(
        uint256 closeValue,
        uint256 openValue,
        uint8 marketType,
        uint256 marketAssetPrecision,
        MarketDataStructure.Position memory position
    ) internal pure returns (int256 rlzPnl){
        rlzPnl = closeValue.toInt256().sub(openValue.toInt256());
        if (marketType == 1) rlzPnl = rlzPnl.neg256();
        if (marketType == 2) rlzPnl = rlzPnl.mul(position.multiplier.toInt256()).div((RATE_PRECISION).toInt256());
        rlzPnl = rlzPnl.mul(position.direction);
        rlzPnl = rlzPnl.mul(marketAssetPrecision.toInt256()).div(AMOUNT_PRECISION.toInt256());
    }

    /// @notice validation when increase position, require the position is neither bankruptcy nor reaching the profit earn limit
    /// @param price trading price
    /// @param pool pool address
    /// @param marketType market type
    /// @param marketAssetPrecision precision of market base asset
    /// @param position position data
    function increasePositionValidate(
        uint256 price,
        address pool,
        uint8 marketType,
    //    uint256 discountRate,
    //    uint256 feeRate,
        uint256 marketAssetPrecision,
        MarketDataStructure.Position memory position
    ) internal view {
        uint256 closeValue;
        if (marketType == 0 || marketType == 2) {
            closeValue = position.amount.mul(price).div(PRICE_PRECISION);
        } else {
            closeValue = position.amount.mul(PRICE_PRECISION).div(price);
        }

        int256 pnl = calculatePnl(closeValue, position.value, marketType, marketAssetPrecision, position);
        uint256 interestPayment = getInterestPayment(pool, position.direction, position.debtShare, position.makerMargin);

        /*----
        uint256 fee = closeValue.mul(feeRate).div(RATE_PRECISION);
        if (marketType == 2) fee = fee.mul(position.multiplier).div(RATE_PRECISION);
        fee = adjustPrecision(fee, AMOUNT_PRECISION, marketAssetPrecision);
        fee = fee.sub(fee.mul(discountRate).div(RATE_PRECISION));
        if (pnl.neg256() > position.takerMargin.toInt256().sub(position.fundingPayment).sub(interestPayment.toInt256()).sub(fee.toInt256())) return 8;
        // ---- */

        // taker margin + pnl - fundingPayment - interestPayment > 0
        require(pnl.neg256() <= position.takerMargin.toInt256().sub(position.fundingPayment).sub(interestPayment.toInt256()), "MI0");
        // pnl - fundingPayment < maker(pool) margin
        require(pnl <= position.makerMargin.toInt256().add(position.fundingPayment), "MI1");
    }

    struct LiquidateInfoInternalParams {
        MarketDataStructure.MarketConfig marketConfig;
        uint8 marketType;
        address pool;
        int256 remain;
        uint256 riskFund;
        int256 leftTakerMargin;
        int256 leftMakerMargin;
        uint256 closeValue;
    }

    /// @notice  calculate when position is liquidated, maximum profit stopped and tpsl closed by user setting
    /// @param params parameters, detailed in the data structure declaration
    /// @return response LiquidateInfoResponse
    function getLiquidateInfo(LiquidityInfoParams memory params) public override onlyMarket returns (LiquidateInfoResponse memory response) {
        LiquidateInfoInternalParams memory iParams;
        iParams.marketConfig = IMarket(params.position.market).getMarketConfig();
        iParams.marketType = IMarket(params.position.market).marketType();
        iParams.pool = IMarket(params.position.market).pool();

        //if Liquidate,trade fee is zero
        if (params.action == MarketDataStructure.OrderType.Liquidate || params.action == MarketDataStructure.OrderType.TakeProfit) {
            response.indexPrice = getIndexOrMarketPrice(params.position.market, params.position.direction == - 1, true);
            require(isLiquidateOrProfitMaximum(params.position, iParams.marketConfig.mm, response.indexPrice, iParams.marketConfig.marketAssetPrecision), "MarketLogic: position is not enough liquidate");
            getPrice(iParams.pool, params.position.market, params.position.direction.neg256().toInt8(), params.position.amount, 0, true);
            response.price = response.indexPrice;
        } else {
            response.indexPrice = getIndexOrMarketPrice(params.position.market, params.position.direction == - 1, params.position.useIP);
            (,, response.price) = getPrice(iParams.pool, params.position.market, params.position.direction.neg256().toInt8(), params.position.amount, 0, false);
            if (params.action == MarketDataStructure.OrderType.UserTakeProfit) {
                require(params.position.takeProfitPrice > 0 && (params.position.direction == 1 ? response.indexPrice >= params.position.takeProfitPrice : response.indexPrice <= params.position.takeProfitPrice), "MarketLogic:indexPrice does not match takeProfitPrice");
            } else if (params.action == MarketDataStructure.OrderType.UserStopLoss) {
                require(params.position.stopLossPrice > 0 && (params.position.direction == 1 ? response.indexPrice <= params.position.stopLossPrice : response.indexPrice >= params.position.stopLossPrice), "MarketLogic:indexPrice does not match stopLossPrice");
            } else if (params.action == MarketDataStructure.OrderType.ClearAll) {
                response.price = params.clearPrice;
            } else {
                require(false, "MarketLogic:action error");
            }
        }

        (response.pnl, iParams.closeValue) = getUnPNL(params.position, response.price, iParams.marketConfig.marketAssetPrecision);

        response.tradeValue = iParams.marketType == 1 ? params.position.amount : iParams.closeValue;

        if (params.action != MarketDataStructure.OrderType.Liquidate) {
            response.takerFee = adjustPrecision(iParams.closeValue.mul(iParams.marketConfig.tradeFeeRate).div(RATE_PRECISION), AMOUNT_PRECISION, iParams.marketConfig.marketAssetPrecision);
            response.feeToDiscount = response.takerFee.mul(params.discountRate).div(RATE_PRECISION);
            response.feeToInviter = response.takerFee.mul(params.inviteRate).div(RATE_PRECISION);
            response.feeToMaker = response.takerFee.sub(response.feeToDiscount).sub(response.feeToInviter).mul(iParams.marketConfig.makerFeeRate).div(RATE_PRECISION);
            response.feeToExchange = response.takerFee.sub(response.feeToInviter).sub(response.feeToDiscount).sub(response.feeToMaker);
        }

        //calc close position interests payment
        response.payInterest = getInterestPayment(iParams.pool, params.position.direction, params.position.debtShare, params.position.makerMargin);

        // adjust pnl if bankruptcy occurred on either user side or maker(pool) side
        iParams.leftTakerMargin = params.position.takerMargin.toInt256().sub(params.position.fundingPayment).sub(response.takerFee.toInt256()).add(response.feeToDiscount.toInt256()).sub(response.payInterest.toInt256());
        if (iParams.leftTakerMargin.add(response.pnl) < 0) {
            response.pnl = iParams.leftTakerMargin.neg256();
        }

        iParams.leftMakerMargin = params.position.makerMargin.toInt256().add(params.position.fundingPayment);
        if (iParams.leftMakerMargin.sub(response.pnl) < 0) {
            response.pnl = iParams.leftMakerMargin;
        }

        //if Liquidate,should calc riskFunding
        if (params.action == MarketDataStructure.OrderType.Liquidate) {
            iParams.remain = iParams.leftTakerMargin.add(response.pnl);
            if (iParams.remain > 0) {
                iParams.riskFund = adjustPrecision(params.position.value.mul(iParams.marketConfig.liquidateRate).div(RATE_PRECISION), AMOUNT_PRECISION, iParams.marketConfig.marketAssetPrecision);
                if (iParams.remain > iParams.riskFund.toInt256()) {
                    response.toTaker = iParams.remain.sub(iParams.riskFund.toInt256()).toUint256();
                    response.riskFunding = iParams.riskFund;
                } else {
                    response.toTaker = 0;
                    response.riskFunding = iParams.remain.toUint256();
                }
            }
        } else {
            response.toTaker = iParams.leftTakerMargin.add(response.pnl).toUint256();
        }

        return response;
    }

    struct InternalParams {
        int256 pnl;
        uint256 currentValue;
        uint256 payInterest;
        bool isTakerLiq;
        bool isMakerBroke;
    }

    /// @notice check if the position should be liquidated or reaches the maximum profit
    /// @param  position position info
    function isLiquidateOrProfitMaximum(MarketDataStructure.Position memory position, uint256 mm, uint256 indexPrice, uint256 toPrecision) public view override returns (bool) {
        InternalParams memory params;
        //calc position unrealized pnl
        (params.pnl, params.currentValue) = getUnPNL(position, indexPrice, toPrecision);
        
        //calc position current payInterest
        params.payInterest = getInterestPayment(IMarket(position.market).pool(), position.direction, position.debtShare, position.makerMargin);

        //if takerMargin - fundingPayment + pnl - payInterest <= currentValue * mm,position is liquidity
        params.isTakerLiq = position.takerMargin.toInt256().sub(position.fundingPayment).add(params.pnl).sub(params.payInterest.toInt256()) <= params.currentValue.mul(mm).mul(toPrecision).div(RATE_PRECISION).div(AMOUNT_PRECISION).toInt256();
        //if pnl - fundingPayment >= makerMargin,position is liquidity
        params.isMakerBroke = params.pnl.sub(position.fundingPayment) >= position.makerMargin.toInt256();

        return params.isTakerLiq || params.isMakerBroke;
    }

    /// @notice calculate position unPnl
    /// @param position position data
    /// @param price trading price
    /// @param toPrecision result precision
    /// @return pnl
    /// @return currentValue close value by price
    function getUnPNL(MarketDataStructure.Position memory position, uint256 price, uint256 toPrecision) public view returns (int256 pnl, uint256 currentValue){
        uint8 marketType = IMarket(position.market).marketType();

        if (marketType == 0 || marketType == 2) {
            currentValue = price.mul(position.amount).div(PRICE_PRECISION);
            pnl = currentValue.toInt256().sub(position.value.toInt256());
            if (marketType == 2) {
                pnl = pnl.mul(position.multiplier.toInt256()).div(RATE_PRECISION.toInt256());
                currentValue = currentValue.mul(position.multiplier).div(RATE_PRECISION);
            }
        } else {
            currentValue = position.amount.mul(PRICE_PRECISION).div(price);
            pnl = position.value.toInt256().sub(currentValue.toInt256());
        }

        pnl = pnl.mul(position.direction).mul(toPrecision.toInt256()).div(AMOUNT_PRECISION.toInt256());
    }

    /// @notice calculate the maximum position margin can be removed out
    /// @param position position data
    /// @return maxDecreaseMargin
    function getMaxTakerDecreaseMargin(MarketDataStructure.Position memory position) external view override returns (uint256 maxDecreaseMargin) {
        MarketDataStructure.MarketConfig memory marketConfig = IMarket(position.market).getMarketConfig();
        address fundingLogic = IMarket(position.market).getLogicAddress();
        (position.frLastX96, ) = IFundingLogic(fundingLogic).getFunding(position.market);
        position.fundingPayment = position.fundingPayment.add(IFundingLogic(fundingLogic).getFundingPayment(position.market, position.id, position.frLastX96));
        uint256 payInterest = getInterestPayment(IMarket(position.market).pool(), position.direction, position.debtShare, position.makerMargin);
        (int256 pnl,) = getUnPNL(position, getIndexOrMarketPrice(position.market, position.direction == 1, true), marketConfig.marketAssetPrecision);
        uint256 minIM = adjustPrecision(position.value.mul(marketConfig.dMMultiplier).div(marketConfig.takerLeverageMax), AMOUNT_PRECISION, marketConfig.marketAssetPrecision);
        int256 profitAndFundingAndInterest = pnl.sub(payInterest.toInt256()).sub(position.fundingPayment);
        int256 maxDecreaseMarginLimit = position.takerMargin.toInt256().sub(marketConfig.takerMarginMin.toInt256());
        int256 maxDecrease = position.takerMargin.toInt256().add(profitAndFundingAndInterest > 0 ? 0 : profitAndFundingAndInterest).sub(minIM.toInt256());
        if (maxDecreaseMarginLimit > 0 && maxDecrease > 0) {
            maxDecreaseMargin = maxDecreaseMarginLimit > maxDecrease ? maxDecrease.toUint256() : maxDecreaseMarginLimit.toUint256();
        } else {
            maxDecreaseMargin = 0;
        }
    }

    /// @notice create a new order
    /// @param params CreateParams
    /// @return order
    function createOrderInternal(MarketDataStructure.CreateInternalParams memory params) external view override returns (MarketDataStructure.Order memory order){
        address market = msg.sender;
        MarketDataStructure.MarketConfig memory marketConfig = IMarket(market).getMarketConfig();
        MarketDataStructure.PositionMode positionMode = IMarket(market).positionModes(params._taker);

        order.isETH = params.isETH;
        order.status = MarketDataStructure.OrderStatus.Open;
        order.market = market;
        order.taker = params._taker;
        order.multiplier = marketConfig.multiplier;
        order.takerOpenPriceMin = params.minPrice;
        order.takerOpenPriceMax = params.maxPrice;
        order.triggerPrice = marketConfig.createTriggerOrderPaused ? 0 : params.triggerPrice;
        order.triggerDirection = marketConfig.createTriggerOrderPaused ? int8(0) : params.triggerDirection;
        order.useIP = params.useIP;
        order.createTs = block.timestamp;
        order.mode = positionMode;

        //get position id by direction an orderType
        uint256 positionId = params.reduceOnly == 0 ? IMarket(market).getPositionId(params._taker, params.direction) : params.id;
        MarketDataStructure.Position memory position = IMarket(market).getPosition(positionId);

        if (params.reduceOnly == 1) {
            require(params.id != 0, "MarketLogic:id error");
            require(position.taker == params._taker, "MarketLogic: position not belong to taker");
            require(position.amount > 0, "MarketLogic: amount error");
            order.takerLeverage = position.takerLeverage;
            order.direction = position.direction.neg256().toInt8();
            order.amount = params.amount;
            order.isETH = position.isETH;
            // only under the hedging position model reduce only orders are allowed to be trigger orders
            if (positionMode == MarketDataStructure.PositionMode.OneWay) {
                order.triggerPrice = 0;
                order.triggerDirection = 0;
            }
            order.orderType = order.triggerPrice > 0 ? MarketDataStructure.OrderType.TriggerClose : MarketDataStructure.OrderType.Close;
        } else {
            //open orders or trigger open orders
            uint256 value = adjustPrecision(params.margin.mul(params.leverage), marketConfig.marketAssetPrecision, AMOUNT_PRECISION);
            require(params.direction == 1 || params.direction == - 1, "MarketLogic: direction error");
            require(marketConfig.takerLeverageMin <= params.leverage && params.leverage <= marketConfig.takerLeverageMax, "MarketLogic: leverage not allow");
            require(marketConfig.takerMarginMin <= params.margin && params.margin <= marketConfig.takerMarginMax, "MarketLogic: margin not allow");
            require(marketConfig.takerValueMin <= value && value <= marketConfig.takerValueMax, "MarketLogic: value not allow");
            require(position.amount > 0 ? position.takerLeverage == params.leverage : true, "MarketLogic: leverage error");
            order.isETH = params.isETH;
            order.direction = params.direction;
            order.takerLeverage = params.leverage;
            order.freezeMargin = params.margin;
            order.orderType = order.triggerPrice > 0 ? MarketDataStructure.OrderType.TriggerOpen : MarketDataStructure.OrderType.Open;
        }

        if (params.isLiquidate) {
            order.orderType = MarketDataStructure.OrderType.Liquidate;
            order.executeFee = 0;
        } else {
            order.executeFee = IManager(manager).executeOrderFee();
        }
        
        return order;
    }

    /// @notice check order params
    /// @param id order id
    function checkOrder(uint256 id) external view override {
        address market = msg.sender;
        MarketDataStructure.Order memory order = IMarket(market).getOrder(id);
        MarketDataStructure.MarketConfig memory marketConfig = IMarket(market).getMarketConfig();
        //if open or trigger open ,should be check taker value limit
        if (order.orderType == MarketDataStructure.OrderType.Open || order.orderType == MarketDataStructure.OrderType.TriggerOpen) {
            int256 orderValue = IMarket(market).takerOrderTotalValues(order.taker, order.direction);
            require(orderValue <= marketConfig.takerValueLimit, "MarketLogic: total value of unexecuted orders exceeded limits");
            MarketDataStructure.Position memory position = IMarket(market).getPosition(IMarket(market).getPositionId(order.taker, order.direction));
            if (order.direction == position.direction) {
                require(position.value.toInt256().add(orderValue) <= marketConfig.takerValueLimit, "MarketLogic: total value of unexecuted orders exceeded limits");
            }
        }

        if (order.triggerPrice > 0) require(order.triggerDirection == 1 || order.triggerDirection == - 1, "MarketLogic:trigger direction error");
        require(IMarket(market).takerOrderNum(order.taker, order.orderType) <= IManager(manager).orderNumLimit(), "MarketLogic: number of unexecuted orders exceed limit");
    }

    /// @notice check if users are available to change the position mode
    ///         users are allowed to change position mode only under the situation that there's no any type of order and no position under the market.
    /// @param _taker taker address
    /// @param _mode margin mode
    function checkSwitchMode(address _market, address _taker, MarketDataStructure.PositionMode _mode) public view override {
        MarketDataStructure.PositionMode positionMode = IMarket(_market).positionModes(_taker);
        require(positionMode != _mode, "MarketLogic: mode not change");
        require(
            getOrderNum(_market, _taker, MarketDataStructure.OrderType.Open) == 0 &&
            getOrderNum(_market, _taker, MarketDataStructure.OrderType.TriggerOpen) == 0 &&
            getOrderNum(_market, _taker, MarketDataStructure.OrderType.Close) == 0 &&
            getOrderNum(_market, _taker, MarketDataStructure.OrderType.TriggerClose) == 0,
            "MarketLogic: change position mode with orders"
        );
        require(
            getPositionAmount(_market, _taker, - 1) == 0 && getPositionAmount(_market, _taker, 1) == 0,
            "MarketLogic: change position mode with none-zero position"
        );
    }

    /// @notice calculation position interest
    /// @param  pool pool address
    /// @param  direction position direction
    /// @param  debtShare debt share amount
    /// @param  makerMargin maker(pool) margin
    /// @return uint256 interest
    function getInterestPayment(address pool, int8 direction, uint256 debtShare, uint256 makerMargin) internal view returns (uint256){
        uint256 borrowAmount = IPool(pool).getCurrentAmount(direction, debtShare);
        return borrowAmount < makerMargin ? 0 : borrowAmount.sub(makerMargin);
    }

    function getOrderNum(address _market, address _taker, MarketDataStructure.OrderType orderType) internal view returns (uint256){
        return IMarket(_market).takerOrderNum(_taker, orderType);
    }

    function getPositionAmount(address _market, address _taker, int8 direction) internal view returns (uint256){
        return IMarket(_market).getPosition(IMarket(_market).getPositionId(_taker, direction)).amount;
    }

    /// @notice get trading price
    /// @param market market address
    /// @param takerDirection taker direction
    /// @param deltaValue trading size
    /// @param isLiquidation trading value 
    /// @return size real trading size
    /// @return vol real trading value
    /// @return tradePrice
    function getPrice(address pool, address market, int8 takerDirection, uint256 deltaSize, uint256 deltaValue, bool isLiquidation) internal returns (uint256 size, uint256 vol, uint256 tradePrice){
        (size, vol, tradePrice) = IMarketPriceFeed(marketPriceFeed).priceForTrade(pool, market, IMarket(market).token(), takerDirection, deltaSize, deltaValue, isLiquidation);
    }

    function getIndexOrMarketPrice(address _market, bool _maximise, bool isIndexPrice) public view override returns (uint256){
        return isIndexPrice ? IMarketPriceFeed(marketPriceFeed).priceForIndex(IMarket(_market).token(), _maximise)
            : IMarketPriceFeed(marketPriceFeed).getMarketPrice(_market, IMarket(_market).token(), _maximise);
    }

    /// @notice precision conversion
    /// @param _value value
    /// @param _from original precision
    /// @param _to target precision
    function adjustPrecision(uint256 _value, uint256 _from, uint256 _to) internal pure returns (uint256){
        return _value.mul(_to).div(_from);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

//import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256 constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256 constant PRICE_PRECISION = 1e10;
    uint256 constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address vault;                                              // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 baseAssetDecimals;                                  // base token decimals
    address interestLogic;                                      // interest logic address
    address WETH;                                               // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity
    uint256 public mm;                                          // maintenance margin ratio
    bool public clearAll;
    uint256 public minLeverage;
    uint256 public maxLeverage;
    uint256 public penaltyRate;

    int256 public balance;                                      // balance that is available to use of this pool
    int256 public balanceReal;
    uint256 public reserveRate;                                 // reserve ratio
    uint256 sharePrice;                                         // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId;                                      // liquidity operations order id
    uint256 eventId;                                            // event count

    address[] marketList;                                       // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)
    mapping(uint256 => IPool.Position) public makerPositions;   // mapping of liquidity positions for addresses
    mapping(address => uint256) public makerPositionIds;        // mapping of liquidity positions for addresses

    //structs
    struct MarketConfig {
        uint256 marketType;
        uint256 fundUtRateLimit;                                // fund utilization ratio limit, 0: cant't open; example 200000  r = fundUtRateLimit/RATE_PRECISION=0.2
        uint256 openLimit;                                      // 0: 0 authorized credit limit; > 0 limit is min(openLimit, fundUtRateLimit * balance)
    }

    struct DataByMarket {
        int256 rlzPNL;                                          // realized profit and loss
        uint256 cumulativeFee;                                  // cumulative trade fee for pool
        uint256 longMakerFreeze;                                // user total long margin freeze, that is the pool short margin freeze
        uint256 shortMakerFreeze;                               // user total short margin freeze, that is pool long margin freeze
        uint256 takerTotalMargin;                               // all taker's margin
        int256 makerFundingPayment;                             // pending fundingPayment
        uint256 interestPayment;                                // interestPayment          
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    struct PoolParams {
        uint256 _minAmount;
        uint256 _minLiquidity;
        address _market;
        uint256 _openRate;
        uint256 _openLimit;
        uint256 _reserveRate;
        uint256 _ratio;
        bool _add;
        bool _remove;
        address _interestLogic;
        address _marketPriceFeed;
        uint256 _mm;
        uint256 _minLeverage;
        uint256 _maxLeverage;
        uint256 _penaltyRate;
    }

    struct GlobalHf {
        uint256 sharePrice;
        uint256[] indexPrices;
        uint256 allMakerFreeze;
        DataByMarket allMarketPos;
        uint256 poolInterest;
        int256 totalUnPNL;
        uint256 poolTotalTmp;
    }

    event RegisterMarket(address market);
    event AddLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 initMargin, uint256 liquidity, uint256 entryValue, uint256 sharePrice, uint256 totalValue);
    event RemoveLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker, uint256 sharePrice, uint256 rmFee, uint256 totalValue, uint256 actionType);
    event Liquidate(uint256 id, address maker,uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker,uint256 penalty, uint256 sharePrice, uint256 totalValue);
    event ActivatedClearAll(uint256 ts, uint256[] indexPrices);
    event AddMakerPositionMargin(uint256 id, uint256 positionId, uint256 addMargin);
    event ReStarted(address pool);
    event OpenUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
    event CloseUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 riskFunding,
        int256 rlzPnl,
        int256 fundingPayment,
        uint256 interestPayment,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IFundingLogic {
    function getFunding(address market) external view returns (int256 fundingGrowthGlobalX96, int256 deltaFundingRate);

    function getFundingPayment(address market, uint256 positionId, int256 fundingGrowthGlobalX96) external view returns (int256 fundingPayment);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSuperSigner(address _signer) external view returns (bool);

    function checkSigner(address signer, uint8 sType) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkExecutorRouter(address _executorRouter) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function checkMarketLogic(address _logic) external view returns (bool);

    function checkMarketPriceFeed(address _feed) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused(address market) external view returns (bool);

    function isInterestPaused(address pool) external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkExecutor(address _executor, uint8 eType) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);

    function modifySingleInterestStatus(address pool, bool _interestPaused) external;

    function modifySingleFundingStatus(address market, bool _fundingPaused) external;
    
    function router() external view returns (address);

    function executorRouter() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IMarket {
    function setMarketConfig(MarketDataStructure.MarketConfig memory _config) external;

    function updateFundingGrowthGlobal() external;

    function getMarketConfig() external view returns (MarketDataStructure.MarketConfig memory);

    function marketType() external view returns (uint8);

    function positionModes(address) external view returns (MarketDataStructure.PositionMode);

    function fundingGrowthGlobalX96() external view returns (int256);

    function lastFrX96Ts() external view returns (uint256);

    function takerOrderTotalValues(address, int8) external view returns (int256);

    function pool() external view returns (address);

    function getPositionId(address _trader, int8 _direction) external view returns (uint256);

    function getPosition(uint256 _id) external view returns (MarketDataStructure.Position memory);

    function getOrderIds(address _trader) external view returns (uint256[] memory);

    function getOrder(uint256 _id) external view returns (MarketDataStructure.Order memory);

    function createOrder(MarketDataStructure.CreateInternalParams memory params) external returns (uint256 id);

    function cancel(uint256 _id) external;

    function executeOrder(uint256 _id) external returns (int256, uint256, bool);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action, uint256 clearPrice) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice, bool isExecutedByIndexPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);
    
    function triggerOrderID() external view returns (uint256);

    function marketLogic() external view returns (address);

    function token() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IMarketLogic {
    struct LiquidityInfoParams {
        MarketDataStructure.Position position;
        MarketDataStructure.OrderType action;
        uint256 discountRate;
        uint256 inviteRate;
        uint256 clearPrice;
    }

    struct LiquidateInfoResponse {
        int256 pnl;
        uint256 takerFee;
        uint256 feeToMaker;
        uint256 feeToExchange;
        uint256 feeToInviter;
        uint256 feeToDiscount;
        uint256 riskFunding;
        uint256 payInterest;
        uint256 toTaker;
        uint256 tradeValue;
        uint256 price;
        uint256 indexPrice;
    }

    function trade(uint256 id, uint256 positionId, uint256, uint256) external returns (MarketDataStructure.Order memory order, MarketDataStructure.Position memory position, MarketDataStructure.TradeResponse memory response);

    function createOrderInternal(MarketDataStructure.CreateInternalParams memory params) external view returns (MarketDataStructure.Order memory order);

    function getLiquidateInfo(LiquidityInfoParams memory params) external returns (LiquidateInfoResponse memory response);

    function isLiquidateOrProfitMaximum(MarketDataStructure.Position memory position, uint256 mm, uint256 indexPrice, uint256 toPrecision) external view returns (bool);

    function getMaxTakerDecreaseMargin(MarketDataStructure.Position memory position) external view returns (uint256 maxDecreaseMargin);

    function checkOrder(uint256 id) external view;

    function checkSwitchMode(address _market, address _taker, MarketDataStructure.PositionMode _mode) external view;

    function getIndexOrMarketPrice(address _market, bool _maximise, bool isIndexPrice) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IPriceHelper.sol";

interface IMarketPriceFeed {
    function priceForTrade(address pool, address market, string memory token, int8 takerDirection, uint256 deltaSize, uint256 deltaValue, bool isLiquidation) external returns (uint256 size, uint256 vol, uint256 tradePrice);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);

    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;

    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    function modifyMarketTickConfig(address pool, address market, string memory token, IPriceHelper.MarketTickConfig memory cfg) external;

    function getMarketPrice(address market, string memory _token, bool maximise) external view returns (uint256 marketPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }
    
    struct UpdateParams {
        uint256 orderId;
        uint256 makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 takerMargin;
        uint256 amount;
        uint256 total;
        int256 makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 takerDirection;//old position direction
        uint256 marginToVault;// reduce position size ,order margin should be to record in vault
        uint256 deltaDebtShare;//reduce position debt share
        uint256 payInterest;//settled interest payment
        bool isOutETH;//margin is ETH
        uint256 toRiskFund;
        uint256 toTaker;//balance of reduce position to taker
        address taker;//taker address
        uint256 feeToInviter; //trade fee to inviter
        address inviter;//inviter address
        uint256 feeToExchange;//fee to exchange
        bool isClearAll;
    }

    struct Position{
        address maker;
        uint256 initMargin;
        uint256 liquidity;
        uint256 entryValue;
        uint256 lastAddTime;
        uint256 makerStopLossPrice;
        uint256 makerProfitPrice;
    }
    
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function makerPositions(uint256 positionId) external view returns (Position memory);

    function openUpdate(UpdateParams memory params) external;

    function closeUpdate(UpdateParams memory params) external;

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external;

    function addLiquidity(uint256 orderId, address sender, uint256 amount, uint256 leverage) external returns(uint256 liquidity);

    function removeLiquidity(uint256 orderId, address sender, uint256 liquidity, bool isETH, bool isSystem) external returns (uint256 settleLiquidity);

    function liquidate(uint256 positionId) external ;

    function registerMarket(address _market) external returns (bool);

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getBaseAsset() external view returns (address);

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function clearAll() external view returns (bool);

    function makerPositionIds(address maker) external view returns (uint256);
    
    function mm()external view returns (uint256);
    
    function globalHf()external view returns (bool status, uint256 poolTotalTmp, int256 totalUnPNL);

    function addMakerPositionMargin(uint256 positionId, uint256 addMargin) external;

    function setTPSLPrice(address maker, uint256 positionId, uint256 tp, uint256 sl) external;
    
    function balance() external view returns (int256);
    
    function balanceReal() external view returns (int256);
    
    function getMarketList() external view returns (address[] memory);

    function poolDataByMarkets(address market) external view returns (int256, uint256, uint256, uint256, uint256, int256, uint256, uint256, uint256, uint256, uint256);
    
    function interestData(int8 direction) external view returns (IPool.InterestData memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "../libraries/Tick.sol";

interface IPriceHelper {
    struct MarketTickConfig {
        bool isLinear;
        uint8 marketType;
        uint8 liquidationIndex;
        uint256 baseAssetDivisor;
        uint256 multiplier; // different precision from rate divisor
        uint256 maxLiquidity;
        Tick.Config[7] tickConfigs;
    }

    struct CalcTradeInfoParams {
        address pool;
        address market;
        uint256 indexPrice;
        bool isTakerLong;
        bool liquidation;
        uint256 deltaSize;
        uint256 deltaValue;
    }

    function calcTradeInfo(CalcTradeInfoParams memory params) external returns(uint256 deltaSize, uint256 volTotal, uint256 tradePrice);
    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;
    function modifyMarketTickConfig(address pool, address market, MarketTickConfig memory cfg, uint256 indexPrice) external;
    function getMarketPrice(address market, uint256 indexPrice) external view returns (uint256 marketPrice);
    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    event TickConfigChanged(address market, MarketTickConfig cfg);
    event TickInfoChanged(address market, uint8 index, uint256 size, uint256 premiumX96);
    event Slot0StateChanged(address market, uint256 netSize, uint256 premiumX96, bool isLong, uint8 currentTick);
    event LiquidationBufferSizeChanged(address market, uint8 index, uint256 bufferSize);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

library Constant {
    uint256 constant Q96 = 1 << 96;
    uint256 constant RATE_DIVISOR = 1e8;
    uint256 constant PRICE_DIVISOR = 1e10;// 1e10
    uint256 constant SIZE_DIVISOR = 1e20;// 1e20 for AMOUNT_PRECISION
    uint256 constant TICK_LENGTH = 7;
    uint256 constant MULTIPLIER_DIVISOR = 1e6;

    int256 constant FundingRate1_10000X96 = int256(Q96) * 1 / 10000;
    int256 constant FundingRate4_10000X96 = int256(Q96) * 4 / 10000;
    int256 constant FundingRate5_10000X96 = int256(Q96) * 5 / 10000;
    int256 constant FundingRate6_10000X96 = int256(Q96) * 6 / 10000;
    int256 constant FundingRateMaxX96 = int256(Q96) * 375 / 100000;
    int256 constant FundingRate8Hours = 8 hours;
    int256 constant FundingRate24Hours = 24 hours;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @notice data structure used by Pool

library MarketDataStructure {
    /// @notice enumerate of user trade order status
    enum OrderStatus {
        Open,
        Opened,
        OpenFail,
        Canceled
    }

    /// @notice enumerate of user trade order types
    enum OrderType{
        Open,
        Close,
        TriggerOpen,
        TriggerClose,
        Liquidate,
        TakeProfit,
        UserTakeProfit,
        UserStopLoss,
        ClearAll
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        Hedge,
        OneWay
    }

    enum PositionKey{
        Short,
        Long,
        OneWay
    }

    /// @notice Position data structure
    struct Position {
        uint256 id;                 // position id, generated by counter
        address taker;              // taker address
        address market;             // market address
        int8 direction;             // position direction
        uint16 takerLeverage;       // leverage used by trader
        uint256 amount;             // position amount
        uint256 value;              // position value
        uint256 takerMargin;        // margin of trader
        uint256 makerMargin;        // margin of maker(pool)
        uint256 multiplier;         // multiplier of quanto perpetual contracts
        int256 frLastX96;           // last settled funding global cumulative value
        uint256 stopLossPrice;      // stop loss price of this position set by trader
        uint256 takeProfitPrice;    // take profit price of this position set by trader
        bool useIP;                 // true if the tp/sl is executed by index price
        uint256 lastTPSLTs;         // last timestamp of trading setting the stop loss price or take profit price
        int256 fundingPayment;      // cumulative funding need to pay of this position
        uint256 debtShare;          // borrowed share of interest module
        int256 pnl;                 // cumulative realized pnl of this position
        bool isETH;                 // true if the margin is payed by ETH
        uint256 lastUpdateTs;       // last updated timestamp of this position
    }

    /// @notice data structure of trading orders
    struct Order {
        uint256 id;                             // order id, generated by counter
        address market;                         // market address
        address taker;                          // trader address
        int8 direction;                         // order direction
        uint16 takerLeverage;                   // order leverage
        int8 triggerDirection;                  // price condition if order is trigger order: {0: not available, 1: >=, -1: <= }
        uint256 triggerPrice;                   // trigger price, 0: not available
        bool useIP;                             // true if the order is executed by index price
        uint256 freezeMargin;                   // frozen margin of this order
        uint256 amount;                         // order amount
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 takerOpenPriceMin;              // minimum trading price for slippage control
        uint256 takerOpenPriceMax;              // maximum trading price for slippage control

        OrderType orderType;                    // order type
        uint256 riskFunding;                    // risk funding penalty if this is a liquidate order

        uint256 takerFee;                       // taker trade fee
        uint256 feeToInviter;                   // reward of trading fee to the inviter
        uint256 feeToExchange;                  // trading fee charged by protocol
        uint256 feeToMaker;                     // fee reward to the pool
        uint256 feeToDiscount;                  // fee discount
        uint256 executeFee;                     // execution fee
        bytes32 code;                           // invite code

        uint256 tradeTs;                        // trade timestamp
        uint256 tradePrice;                     // trade price
        uint256 tradeIndexPrice;                // index price when executing
        int256 rlzPnl;                          // realized pnl by this order

        int256 fundingPayment;                  // settled funding payment
        int256 frX96;                           // latest cumulative funding growth global
        int256 frLastX96;                       // last cumulative funding growth global
        int256 fundingAmount;                   // funding amount by this order, calculated by amount, frX96 and frLastX96

        uint256 interestPayment;                // settled interest amount
        
        uint256 createTs;                       // create timestamp
        OrderStatus status;                     // order status
        MarketDataStructure.PositionMode mode;  // margin mode, one-way or hedge
        bool isETH;                             // true if the margin is payed by ETH
    }

    /// @notice configuration of markets
    struct MarketConfig {
        uint256 mm;                             // maintenance margin ratio
        uint256 liquidateRate;                  // penalty ratio when position is liquidated, penalty = position.value * liquidateRate
        uint256 tradeFeeRate;                   // trading fee rate
        uint256 makerFeeRate;                   // ratio of trading fee that goes to the pool
        bool createOrderPaused;                 // true if order creation is paused
        bool setTPSLPricePaused;                // true if tpsl price setting is paused
        bool createTriggerOrderPaused;          // true if trigger order creation is paused
        bool updateMarginPaused;                // true if updating margin is paused
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 marketAssetPrecision;           // margin asset decimals
        uint256 DUST;                           // dust amount,scaled by AMOUNT_PRECISION (1e20)

        uint256 takerLeverageMin;               // minimum leverage that trader can use
        uint256 takerLeverageMax;               // maximum leverage that trader can use
        uint256 dMMultiplier;                   // used to calculate the initial margin when trading decrease position margin

        uint256 takerMarginMin;                 // minimum margin of a single trader order
        uint256 takerMarginMax;                 // maximum margin of a single trader order
        uint256 takerValueMin;                  // minimum value amount of a single trader order
        uint256 takerValueMax;                  // maximum value amount of a single trader order
        int256 takerValueLimit;                 // maximum position value of a single position
    }

    /// @notice internal parameter data structure when creating an order
    struct CreateInternalParams {
        address _taker;             // trader address
        uint256 id;                 // order id, generated by id counter
        uint256 minPrice;           // slippage: minimum trading price, validated in Router
        uint256 maxPrice;           // slippage: maximum trading price, validated in Router
        uint256 margin;             // order margin
        uint256 amount;             // close order amount, 0 if order is an open order
        uint16 leverage;            // order leverage, validated in MarketLogic
        int8 direction;             // order direction, validated in MarketLogic
        int8 triggerDirection;      // trigger condition, validated in MarketLogic
        uint256 triggerPrice;       // trigger price
        bool useIP;                 // true if the order is executed by index price
        uint8 reduceOnly;           // 0: false, 1: true
        bool isLiquidate;           // is liquidate order, liquidate orders are generated automatically
        bool isETH;                 // true if order margin payed in ETH
    }

    /// @notice returned data structure when an order is executed, used by MarketLogic.sol::trade
    struct TradeResponse {
        uint256 toTaker;            // refund to the taker
        uint256 tradeValue;         // value of the order
        uint256 leftInterestPayment;// interest payment on the remaining portion of the position
        bool isIncreasePosition;    // if the order causes position value increased
        bool isDecreasePosition;    // true if the order causes position value decreased
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * copy from openzeppelin-contracts
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeCast.sol";

library SignedSafeMath {
    using SafeCast for int256;

    int256 constant private _INT256_MIN = - 2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == - 1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == - 1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }


    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > - 2 ** 255, "PerpMath: inversion overflow");
        return - a;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "./Constant.sol";
import "./SafeMath.sol";

library Tick {
    using SafeMath for uint256;

    struct Info {
        uint256 size;
        uint256 premiumX96;
    }

    struct Config {
        uint32 sizeRate;
        uint32 premium;
    }

    function calcTickInfo(uint32 sizeRate, uint32 premium, bool isLinear, uint256 liquidity, uint256 indexPrice) internal pure returns (uint256 size, uint256 premiumX96){
        if(isLinear) {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(Constant.PRICE_DIVISOR).div(indexPrice);
        } else {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(indexPrice).div(Constant.PRICE_DIVISOR);
        }

        premiumX96 = uint256(premium).mul(Constant.Q96).div(Constant.RATE_DIVISOR);
    }
}