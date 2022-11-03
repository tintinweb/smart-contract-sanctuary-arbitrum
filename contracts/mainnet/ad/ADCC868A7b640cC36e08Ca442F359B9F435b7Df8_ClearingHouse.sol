// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "./utils/Decimal.sol";
import { SignedDecimal } from "./utils/SignedDecimal.sol";
import { MixedDecimal } from "./utils/MixedDecimal.sol";
import { DecimalERC20 } from "./utils/DecimalERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnerPausableUpgradeable } from "./OwnerPausable.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";

/**
                                                                              
                            ####
                        @@@@    @@@@                      
                    /@@@            @@@\
                @@@@                    @@@@
            /@@@                            @@@\
        /@@@                                    @@@\
    /@@@                                            @@@\
 ////   ############################################   \\\\
 █▀▀ █░░ █▀▀ ▄▀█ █▀█ █ █▄░█ █▀▀   █░█ █▀█ █░█ █▀ █▀▀
 █▄▄ █▄▄ ██▄ █▀█ █▀▄ █ █░▀█ █▄█   █▀█ █▄█ █▄█ ▄█ ██▄                                        
#############################################################                                                    
            @@   @@       @@   @@       @@   @@
            @@   @@       @@   @@       @@   @@       
            @@   @@       @@   @@       @@   @@       
            @@   @@       @@   @@       @@   @@       
            @@   @@       @@   @@       @@   @@       
            @@   @@       @@   @@       @@   @@       
            @@   @@       @@   @@       @@   @@       
            @@   @@       @@   @@       @@   @@       
        ...........................................                                                    
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
...........................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

 */

/**
 * @title Clearing House
 * @notice
 * - issues and stores positions of traders
 * - settles all collateral between traders
 */
contract ClearingHouse is DecimalERC20, OwnerPausableUpgradeable, ReentrancyGuardUpgradeable {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;
    using MixedDecimal for SignedDecimal.signedDecimal;

    /// @notice BUY = LONG, SELL = SHORT
    enum Side {
        BUY,
        SELL
    }

    /**
     * @title Position
     * @notice This struct records position information
     * @param size denominated in amm.baseAsset
     * @param margin isolated margin (collateral amt)
     * @param openNotional the quoteAsset value of the position. the cost of the position
     * @param lastUpdatedCumulativePremiumFraction for calculating funding payment, recorded at position update
     * @param blockNumber recorded at every position update
     */
    struct Position {
        SignedDecimal.signedDecimal size;
        Decimal.decimal margin;
        Decimal.decimal openNotional;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFractionLong;
        SignedDecimal.signedDecimal lastUpdatedCumulativePremiumFractionShort;
        uint256 blockNumber;
    }

    /// @notice records vault position sizes
    struct TotalPositionSize {
        SignedDecimal.signedDecimal netPositionSize;
        Decimal.decimal positionSizeLong;
        Decimal.decimal positionSizeShort;
    }

    /// @notice used for avoiding stack too deep error
    struct PositionResp {
        Position position;
        Decimal.decimal exchangedQuoteAssetAmount;
        Decimal.decimal badDebt;
        SignedDecimal.signedDecimal exchangedPositionSize;
        SignedDecimal.signedDecimal fundingPayment;
        SignedDecimal.signedDecimal realizedPnl;
        SignedDecimal.signedDecimal marginToVault;
        SignedDecimal.signedDecimal unrealizedPnlAfter;
    }

    /// @notice used for avoiding stack too deep error
    struct CalcRemainMarginReturnParams {
        SignedDecimal.signedDecimal latestCumulativePremiumFractionLong;
        SignedDecimal.signedDecimal latestCumulativePremiumFractionShort;
        SignedDecimal.signedDecimal fundingPayment;
        Decimal.decimal badDebt;
        Decimal.decimal remainingMargin;
    }

    //
    // STATE VARS
    //

    IInsuranceFund public insuranceFund;
    Decimal.decimal public fundingRateDeltaCapRatio;

    // key by amm address
    mapping(address => mapping(address => Position)) public positionMap;
    mapping(address => Decimal.decimal) public openInterestNotionalMap;
    mapping(address => TotalPositionSize) public totalPositionSizeMap;
    mapping(address => SignedDecimal.signedDecimal[]) public cumulativePremiumFractionLong;
    mapping(address => SignedDecimal.signedDecimal[]) public cumulativePremiumFractionShort;
    mapping(address => address) public repegBots;

    // key by token
    mapping(address => Decimal.decimal) public tollMap;

    enum PnlCalcOption {
        SPOT_PRICE,
        ORACLE
    }

    //
    // EVENTS
    //

    /**
     * @notice This event is emitted when position is changed
     * @param trader - trader
     * @param amm - amm
     * @param margin - updated margin
     * @param exchangedPositionNotional - the position notional exchanged in the trade
     * @param exchangedPositionSize - the position size exchanged in the trade
     * @param fee - trade fee
     * @param positionSizeAfter - updated position size
     * @param realizedPnl - realized pnl on the trade
     * @param unrealizedPnlAfter - unrealized pnl remaining after the trade
     * @param badDebt - margin cleared by insurance fund (optimally 0)
     * @param liquidationPenalty - liquidation fee
     * @param markPrice - updated mark price
     * @param fundingPayment - funding payment (+: paid, -: received)
     */
    event PositionChanged(
        address indexed trader,
        address indexed amm,
        uint256 margin,
        uint256 exchangedPositionNotional,
        int256 exchangedPositionSize,
        uint256 fee,
        int256 positionSizeAfter,
        int256 realizedPnl,
        int256 unrealizedPnlAfter,
        uint256 badDebt,
        uint256 liquidationPenalty,
        uint256 markPrice,
        int256 fundingPayment
    );

    /**
     * @notice This event is emitted when position is liquidated
     * @param trader - trader
     * @param amm - amm
     * @param liquidator - liquidator
     * @param liquidatedPositionNotional - liquidated position notional
     * @param liquidatedPositionSize - liquidated position size
     * @param liquidationReward - liquidation reward to the liquidator
     * @param insuranceFundProfit - insurance fund profit on liquidation
     * @param badDebt - liquidation fee cleared by insurance fund (optimally 0)
     */
    event PositionLiquidated(
        address indexed trader,
        address indexed amm,
        address indexed liquidator,
        uint256 liquidatedPositionNotional,
        uint256 liquidatedPositionSize,
        uint256 liquidationReward,
        uint256 insuranceFundProfit,
        uint256 badDebt
    );

    /**
     * @notice emitted on funding payments
     * @param amm - amm
     * @param markPrice - mark price on funding
     * @param indexPrice - index price on funding
     * @param premiumFractionLong - total premium longs pay (when +ve), receive (when -ve)
     * @param premiumFractionShort - total premium shorts receive (when +ve), pay (when -ve)
     * @param insuranceFundPnl - insurance fund pnl from funding
     */
    event FundingPayment(
        address indexed amm,
        uint256 markPrice,
        uint256 indexPrice,
        int256 premiumFractionLong,
        int256 premiumFractionShort,
        int256 insuranceFundPnl
    );

    /**
     * @notice emitted on adding or removing margin
     * @param trader - trader address
     * @param amm - amm address
     * @param amount - amount changed
     * @param fundingPayment - funding payment
     */
    event MarginChanged(
        address indexed trader,
        address indexed amm,
        int256 amount,
        int256 fundingPayment
    );

    /**
     * @notice emitted on repeg (convergence event)
     * @param amm - amm address
     * @param quoteAssetReserveBefore - quote reserve before repeg
     * @param baseAssetReserveBefore - base reserve before repeg
     * @param quoteAssetReserveAfter - quote reserve after repeg
     * @param baseAssetReserveAfter - base reserve after repeg
     * @param repegPnl - effective pnl incurred on vault positions after repeg
     * @param repegDebt - amount borrowed from insurance fund
     */
    event Repeg(
        address indexed amm,
        uint256 quoteAssetReserveBefore,
        uint256 baseAssetReserveBefore,
        uint256 quoteAssetReserveAfter,
        uint256 baseAssetReserveAfter,
        int256 repegPnl,
        uint256 repegDebt
    );

    /// @notice emitted on setting repeg bots
    event RepegBotSet(address indexed amm, address indexed bot);

    modifier onlyRepegBot(IAmm _amm) {
        address sender = _msgSender();
        require(sender == repegBots[address(_amm)] || sender == owner(), "not allowed");
        _;
    }

    //
    // EXTERNAL
    //

    function initialize(IInsuranceFund _insuranceFund, uint256 _fundingRateDeltaCapRatio)
        external
        initializer
    {
        require(address(_insuranceFund) != address(0), "addr(0)");
        __OwnerPausable_init();
        __ReentrancyGuard_init();

        insuranceFund = _insuranceFund;
        fundingRateDeltaCapRatio = Decimal.decimal(_fundingRateDeltaCapRatio);
    }

    /**
     * @notice open a position
     * @param _amm amm address
     * @param _side enum Side; BUY for long and SELL for short
     * @param _quoteAssetAmount quote asset amount in 18 digits. Can Not be 0
     * @param _leverage leverage in 18 digits. Can Not be 0
     * @param _baseAssetAmountLimit base asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function openPosition(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) external whenNotPaused nonReentrant {
        _requireAmm(_amm);
        _requireNonZeroInput(_quoteAssetAmount);
        _requireNonZeroInput(_leverage);
        _requireMoreMarginRatio(
            MixedDecimal.fromDecimal(Decimal.one()).divD(_leverage),
            _amm.getRatios().initMarginRatio,
            true
        );
        _requireNonSandwich(_amm);

        address trader = _msgSender();
        PositionResp memory positionResp;
        // add scope for stack too deep error
        {
            int256 oldPositionSize = getPosition(_amm, trader).size.toInt();
            bool isNewPosition = oldPositionSize == 0 ? true : false;

            // increase or decrease position depends on old position's side and size
            if (isNewPosition || (oldPositionSize > 0 ? Side.BUY : Side.SELL) == _side) {
                positionResp = _internalIncreasePosition(
                    _amm,
                    _side,
                    _quoteAssetAmount.mulD(_leverage),
                    _baseAssetAmountLimit,
                    _leverage
                );
            } else {
                positionResp = _openReversePosition(
                    _amm,
                    _side,
                    trader,
                    _quoteAssetAmount,
                    _leverage,
                    _baseAssetAmountLimit,
                    false
                );
            }

            // update position
            setPosition(_amm, trader, positionResp.position);
            // opening opposite exact position size as the existing one == closePosition, can skip the margin ratio check
            if (!isNewPosition && positionResp.position.size.toInt() != 0) {
                _requireMoreMarginRatio(
                    getMarginRatio(_amm, trader),
                    _amm.getRatios().maintenanceMarginRatio,
                    true
                );
            }

            require(positionResp.badDebt.toUint() == 0, "bad debt");

            // transfer the token between trader and vault
            IERC20 quoteToken = _amm.quoteAsset();
            if (positionResp.marginToVault.toInt() > 0) {
                _transferFrom(quoteToken, trader, address(this), positionResp.marginToVault.abs());
            } else if (positionResp.marginToVault.toInt() < 0) {
                _withdraw(quoteToken, trader, positionResp.marginToVault.abs());
            }
        }

        // fees
        Decimal.decimal memory fees = _transferFees(
            trader,
            _amm,
            positionResp.exchangedQuoteAssetAmount,
            _side,
            true
        );

        // emit event
        uint256 markPrice = _amm.getMarkPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt(); // pre-fetch for stack too deep error
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            fees.toUint(),
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            0,
            markPrice,
            fundingPayment
        );
    }

    /**
     * @notice close position
     * @param _amm amm address
     * @param _quoteAssetAmountLimit quote asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function closePosition(IAmm _amm, Decimal.decimal memory _quoteAssetAmountLimit)
        external
        whenNotPaused
        nonReentrant
    {
        _requireAmm(_amm);
        _requireNonSandwich(_amm);

        address trader = _msgSender();
        PositionResp memory positionResp;
        Position memory position = getPosition(_amm, trader);

        // add scope for stack too deep error
        {
            // closing a long means taking a short
            IAmm.Dir dirOfBase = position.size.toInt() > 0
                ? IAmm.Dir.ADD_TO_AMM
                : IAmm.Dir.REMOVE_FROM_AMM;

            IAmm.Ratios memory ratios = _amm.getRatios();

            // if trade goes over fluctuation limit, then partial close, else full close
            if (
                _amm.isOverFluctuationLimit(dirOfBase, position.size.abs()) &&
                ratios.partialLiquidationRatio.toUint() != 0
            ) {
                positionResp = _internalPartialClose(
                    _amm,
                    trader,
                    ratios.partialLiquidationRatio,
                    Decimal.zero()
                );
            } else {
                positionResp = _internalClosePosition(_amm, trader, _quoteAssetAmountLimit);
            }

            require(positionResp.badDebt.toUint() == 0, "bad debt");

            // transfer the token from trader and vault
            IERC20 quoteToken = _amm.quoteAsset();
            _withdraw(quoteToken, trader, positionResp.marginToVault.abs());
        }

        // fees
        Decimal.decimal memory fees = _transferFees(
            trader,
            _amm,
            positionResp.exchangedQuoteAssetAmount,
            position.size.toInt() > 0 ? Side.SELL : Side.BUY,
            false
        );

        // emit event
        uint256 markPrice = _amm.getMarkPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt();
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            fees.toUint(),
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            0,
            markPrice,
            fundingPayment
        );
    }

    /**
     * @notice partially close position
     * @param _amm amm address
     * @param _partialCloseRatio % to close
     * @param _quoteAssetAmountLimit quote asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function partialClose(
        IAmm _amm,
        Decimal.decimal memory _partialCloseRatio,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) external whenNotPaused nonReentrant {
        _requireAmm(_amm);
        _requireNonZeroInput(_partialCloseRatio);
        require(_partialCloseRatio.cmp(Decimal.one()) < 0, "not partial close");
        _requireNonSandwich(_amm);

        address trader = _msgSender();
        Position memory position = getPosition(_amm, trader);
        SignedDecimal.signedDecimal memory sizeToClose = position.size.mulD(_partialCloseRatio);

        // if partial close causes price to go over fluctuation limit, trim down to partial liq ratio
        Decimal.decimal memory partialLiquidationRatio = _amm.getRatios().partialLiquidationRatio;
        if (
            _amm.isOverFluctuationLimit(
                position.size.toInt() > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                sizeToClose.abs()
            ) &&
            partialLiquidationRatio.toUint() != 0 &&
            _partialCloseRatio.cmp(partialLiquidationRatio) > 0
        ) {
            _partialCloseRatio = partialLiquidationRatio;
        }

        PositionResp memory positionResp = _internalPartialClose(
            _amm,
            trader,
            _partialCloseRatio,
            _quoteAssetAmountLimit
        );

        require(positionResp.badDebt.toUint() == 0, "bad debt");

        // transfer the token from trader and vault
        IERC20 quoteToken = _amm.quoteAsset();
        _withdraw(quoteToken, trader, positionResp.marginToVault.abs());

        // fees
        Decimal.decimal memory fees = _transferFees(
            trader,
            _amm,
            positionResp.exchangedQuoteAssetAmount,
            position.size.toInt() > 0 ? Side.SELL : Side.BUY,
            false
        );

        // emit event
        uint256 markPrice = _amm.getMarkPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt();

        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            fees.toUint(),
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            0,
            markPrice,
            fundingPayment
        );
    }

    /**
     * @notice add margin to increase margin ratio
     * @param _amm amm address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IAmm _amm, Decimal.decimal calldata _addedMargin)
        external
        whenNotPaused
        nonReentrant
    {
        _requireAmm(_amm);
        _requireNonZeroInput(_addedMargin);

        address trader = _msgSender();
        Position memory position = getPosition(_amm, trader);
        // update margin
        position.margin = position.margin.addD(_addedMargin);

        setPosition(_amm, trader, position);
        // transfer token from trader
        IERC20 quoteToken = _amm.quoteAsset();
        _transferFrom(quoteToken, trader, address(this), _addedMargin);
        emit MarginChanged(trader, address(_amm), int256(_addedMargin.toUint()), 0);
    }

    /**
     * @notice remove margin to decrease margin ratio
     * @param _amm amm address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IAmm _amm, Decimal.decimal calldata _removedMargin)
        external
        whenNotPaused
        nonReentrant
    {
        _requireAmm(_amm);
        _requireNonZeroInput(_removedMargin);

        address trader = _msgSender();
        // realize funding payment if there's no bad debt
        Position memory position = getPosition(_amm, trader);

        // update margin and cumulativePremiumFraction
        SignedDecimal.signedDecimal memory marginDelta = MixedDecimal
            .fromDecimal(_removedMargin)
            .mulScalar(-1);
        CalcRemainMarginReturnParams
            memory calcRemainMarginReturnParams = _calcRemainMarginWithFundingPayment(
                _amm,
                position,
                marginDelta
            );
        require(calcRemainMarginReturnParams.badDebt.toUint() == 0, "bad debt");

        position.margin = calcRemainMarginReturnParams.remainingMargin;
        position.lastUpdatedCumulativePremiumFractionLong = calcRemainMarginReturnParams
            .latestCumulativePremiumFractionLong;
        position.lastUpdatedCumulativePremiumFractionShort = calcRemainMarginReturnParams
            .latestCumulativePremiumFractionShort;

        // check enough margin
        // Use a more conservative way to restrict traders to remove their margin
        // We don't allow unrealized PnL to support their margin removal
        require(
            _calcFreeCollateral(_amm, trader, calcRemainMarginReturnParams.remainingMargin)
                .toInt() >= 0,
            "free collateral is not enough"
        );

        // update position
        setPosition(_amm, trader, position);

        // transfer token back to trader
        IERC20 quoteToken = _amm.quoteAsset();
        _withdraw(quoteToken, trader, _removedMargin);
        emit MarginChanged(
            trader,
            address(_amm),
            marginDelta.toInt(),
            calcRemainMarginReturnParams.fundingPayment.toInt()
        );
    }

    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @param _amm amm address
     * @param _trader trader address
     */
    function liquidate(IAmm _amm, address _trader) external nonReentrant {
        _internalLiquidate(_amm, _trader);
    }

    /**
     * @notice settle funding payment
     * @dev dynamic funding mechanism refer (https://nftperp.notion.site/Technical-Stuff-8e4cb30f08b94aa2a576097a5008df24)
     * @param _amm amm address
     */
    function settleFunding(IAmm _amm) external whenNotPaused {
        _requireAmm(_amm);

        (
            SignedDecimal.signedDecimal memory premiumFraction,
            Decimal.decimal memory markPrice,
            Decimal.decimal memory indexPrice
        ) = _amm.settleFunding();

        /**
         * implement dynamic funding
         * premium fraction long = premium fraction * (√(PSL * PSS) / PSL)
         * premium fraction short = premium fraction * (√(PSL * PSS) / PSS)
         * funding rate longs = long premium / index
         * funding rate shorts = short premium / index
         */

        TotalPositionSize memory tps = totalPositionSizeMap[address(_amm)];
        Decimal.decimal memory squaredPositionSizeProduct = tps
            .positionSizeLong
            .mulD(tps.positionSizeShort)
            .sqrt();

        SignedDecimal.signedDecimal memory premiumFractionLong;
        SignedDecimal.signedDecimal memory premiumFractionShort;
        SignedDecimal.signedDecimal memory insuranceFundPnl;

        // if PSL or PSL is zero, use regular funding
        if (squaredPositionSizeProduct.toUint() == 0) {
            premiumFractionLong = premiumFraction;
            premiumFractionShort = premiumFraction;
            insuranceFundPnl = tps.netPositionSize.mulD(premiumFraction);
        } else {
            premiumFractionLong = premiumFraction.mulD(
                squaredPositionSizeProduct.divD(tps.positionSizeLong)
            );
            premiumFractionShort = premiumFraction.mulD(
                squaredPositionSizeProduct.divD(tps.positionSizeShort)
            );
        }

        SignedDecimal.signedDecimal memory fundingRateLong = premiumFractionLong.divD(indexPrice);
        SignedDecimal.signedDecimal memory fundingRateShort = premiumFractionShort.divD(indexPrice);
        Decimal.decimal memory fundingRateDeltaAbs = fundingRateLong.subD(fundingRateShort).abs();

        // capped dynamic funding, funding rate of a side is capped if it is more than fundingRateDeltaCapRatio
        if (fundingRateDeltaAbs.cmp(fundingRateDeltaCapRatio) <= 0) {
            // no capping
            _amm.updateFundingRate(premiumFractionLong, premiumFractionShort, indexPrice);
        } else {
            // capping
            Decimal.decimal memory x = fundingRateDeltaCapRatio.mulD(indexPrice); /** @aster2709: not sure what to call this :p  */

            if (premiumFraction.toInt() > 0) {
                // longs pay shorts
                if (premiumFractionLong.toInt() > premiumFractionShort.toInt()) {
                    // cap long losses, insurnace fund covers beyond cap
                    SignedDecimal.signedDecimal memory newPremiumFractionLong = premiumFractionShort
                        .addD(x);
                    SignedDecimal.signedDecimal memory coveredPremium = premiumFractionLong.subD(
                        newPremiumFractionLong
                    );
                    insuranceFundPnl = coveredPremium.mulD(tps.positionSizeLong).mulScalar(-1);
                    premiumFractionLong = newPremiumFractionLong;
                } else {
                    // cap short profits, insurance fund benefits beyond cap
                    SignedDecimal.signedDecimal memory newPremiumFractionShort = premiumFractionLong
                        .addD(x);
                    SignedDecimal.signedDecimal memory coveredPremium = premiumFractionShort.subD(
                        newPremiumFractionShort
                    );
                    insuranceFundPnl = coveredPremium.mulD(tps.positionSizeShort);
                    premiumFractionShort = newPremiumFractionShort;
                }
            } else {
                // shorts pay longs
                if (premiumFractionLong.toInt() < premiumFractionShort.toInt()) {
                    // cap long profits, insurnace fund benefits beyond cap
                    SignedDecimal.signedDecimal memory newPremiumFractionLong = premiumFractionShort
                        .subD(x);
                    SignedDecimal.signedDecimal memory coveredPremium = premiumFractionLong.subD(
                        newPremiumFractionLong
                    );
                    insuranceFundPnl = coveredPremium.mulD(tps.positionSizeLong).mulScalar(-1);
                } else {
                    // cap short losses, insurnace fund covers beyond cap
                    SignedDecimal.signedDecimal memory newPremiumFractionShort = premiumFractionLong
                        .subD(x);
                    SignedDecimal.signedDecimal memory coveredPremium = premiumFractionShort.subD(
                        newPremiumFractionShort
                    );
                    insuranceFundPnl = coveredPremium.mulD(tps.positionSizeShort);
                    premiumFractionShort = newPremiumFractionShort;
                }
            }
            _amm.updateFundingRate(premiumFractionLong, premiumFractionShort, indexPrice);
        }

        // update cumulative premium fractions
        (
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionLong,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionShort
        ) = getLatestCumulativePremiumFraction(_amm);
        cumulativePremiumFractionLong[address(_amm)].push(
            premiumFractionLong.addD(latestCumulativePremiumFractionLong)
        );
        cumulativePremiumFractionShort[address(_amm)].push(
            premiumFractionShort.addD(latestCumulativePremiumFractionShort)
        );

        // settle insurance fund pnl
        IERC20 quoteToken = _amm.quoteAsset();
        if (insuranceFundPnl.toInt() > 0) {
            _transferToInsuranceFund(quoteToken, insuranceFundPnl.abs());
        } else if (insuranceFundPnl.toInt() < 0) {
            insuranceFund.withdraw(quoteToken, insuranceFundPnl.abs());
        }
        emit FundingPayment(
            address(_amm),
            markPrice.toUint(),
            indexPrice.toUint(),
            premiumFractionLong.toInt(),
            premiumFractionShort.toInt(),
            insuranceFundPnl.toInt()
        );
    }

    /**
     * @notice repeg mark price to index price
     * @dev only repeg bot can call
     * @param _amm amm address
     */
    function repegPrice(IAmm _amm) external onlyRepegBot(_amm) {
        (
            Decimal.decimal memory quoteAssetBefore,
            Decimal.decimal memory baseAssetBefore,
            Decimal.decimal memory quoteAssetAfter,
            Decimal.decimal memory baseAssetAfter,
            SignedDecimal.signedDecimal memory repegPnl
        ) = _amm.repegPrice();
        Decimal.decimal memory repegDebt = _settleRepegPnl(_amm, repegPnl);

        emit Repeg(
            address(_amm),
            quoteAssetBefore.toUint(),
            baseAssetBefore.toUint(),
            quoteAssetAfter.toUint(),
            baseAssetAfter.toUint(),
            repegPnl.toInt(),
            repegDebt.toUint()
        );
    }

    function repegLiquidityDepth(IAmm _amm, Decimal.decimal memory _multiplier)
        external
        onlyRepegBot(_amm)
    {
        (
            Decimal.decimal memory quoteAssetBefore,
            Decimal.decimal memory baseAssetBefore,
            Decimal.decimal memory quoteAssetAfter,
            Decimal.decimal memory baseAssetAfter,
            SignedDecimal.signedDecimal memory repegPnl
        ) = _amm.repegK(_multiplier);
        Decimal.decimal memory repegDebt = _settleRepegPnl(_amm, repegPnl);

        emit Repeg(
            address(_amm),
            quoteAssetBefore.toUint(),
            baseAssetBefore.toUint(),
            quoteAssetAfter.toUint(),
            baseAssetAfter.toUint(),
            repegPnl.toInt(),
            repegDebt.toUint()
        );
    }

    /**
     * @notice set repeg bot
     * @dev only owner
     * @param _amm amm address
     * @param _repegBot bot address to be set
     */
    function setRepegBot(address _amm, address _repegBot) external onlyOwner {
        repegBots[_amm] = _repegBot;
        emit RepegBotSet(_amm, _repegBot);
    }

    //
    // PUBLIC
    //

    /**
     * @notice get personal position information
     * @param _amm IAmm address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IAmm _amm, address _trader) public view returns (Position memory) {
        return positionMap[address(_amm)][_trader];
    }

    /**
     * @notice get margin ratio, marginRatio = (margin + funding payment + unrealized Pnl) / positionNotional
     * @param _amm amm address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader)
        public
        view
        returns (SignedDecimal.signedDecimal memory)
    {
        return _getMarginRatioByCalcOption(_amm, _trader, PnlCalcOption.SPOT_PRICE);
    }

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _amm amm address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and ORACLE for oracle price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    )
        public
        view
        returns (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        )
    {
        Position memory position = getPosition(_amm, _trader);
        Decimal.decimal memory positionSizeAbs = position.size.abs();
        if (positionSizeAbs.toUint() != 0) {
            bool isShortPosition = position.size.toInt() < 0;
            IAmm.Dir dir = isShortPosition ? IAmm.Dir.REMOVE_FROM_AMM : IAmm.Dir.ADD_TO_AMM;
            if (_pnlCalcOption == PnlCalcOption.SPOT_PRICE) {
                positionNotional = _amm.getOutputPrice(dir, positionSizeAbs);
            } else {
                Decimal.decimal memory oraclePrice = _amm.getIndexPrice();
                positionNotional = positionSizeAbs.mulD(oraclePrice);
            }
            // unrealizedPnlForLongPosition = positionNotional - openNotional
            // unrealizedPnlForShortPosition = positionNotionalWhenBorrowed - positionNotionalWhenReturned =
            // openNotional - positionNotional = unrealizedPnlForLongPosition * -1
            unrealizedPnl = isShortPosition
                ? MixedDecimal.fromDecimal(position.openNotional).subD(positionNotional)
                : MixedDecimal.fromDecimal(positionNotional).subD(position.openNotional);
        }
    }

    /**
     * @notice get latest cumulative premium fraction.
     * @param _amm IAmm address
     * @return latestCumulativePremiumFractionLong cumulative premium fraction long
     * @return latestCumulativePremiumFractionShort cumulative premium fraction short
     */
    function getLatestCumulativePremiumFraction(IAmm _amm)
        public
        view
        returns (
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionLong,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionShort
        )
    {
        address amm = address(_amm);
        uint256 lenLong = cumulativePremiumFractionLong[amm].length;
        uint256 lenShort = cumulativePremiumFractionShort[amm].length;
        if (lenLong > 0) {
            latestCumulativePremiumFractionLong = cumulativePremiumFractionLong[amm][lenLong - 1];
        }
        if (lenShort > 0) {
            latestCumulativePremiumFractionShort = cumulativePremiumFractionShort[amm][
                lenShort - 1
            ];
        }
    }

    //
    // INTERNAL
    //

    function _getMarginRatio(
        IAmm _amm,
        Position memory _position,
        SignedDecimal.signedDecimal memory _unrealizedPnl,
        Decimal.decimal memory _positionNotional
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        CalcRemainMarginReturnParams
            memory calcRemainMarginReturnParams = _calcRemainMarginWithFundingPayment(
                _amm,
                _position,
                _unrealizedPnl
            );
        return
            MixedDecimal
                .fromDecimal(calcRemainMarginReturnParams.remainingMargin)
                .subD(calcRemainMarginReturnParams.badDebt)
                .divD(_positionNotional);
    }

    // only called from openPosition and _closeAndOpenReversePosition. calling fn needs to ensure there's enough marginRatio
    function _internalIncreasePosition(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _openNotional,
        Decimal.decimal memory _minPositionSize,
        Decimal.decimal memory _leverage
    ) internal returns (PositionResp memory positionResp) {
        address trader = _msgSender();
        Position memory oldPosition = getPosition(_amm, trader);
        positionResp.exchangedPositionSize = _swapInput(
            _amm,
            _side,
            _openNotional,
            _minPositionSize,
            false
        );
        SignedDecimal.signedDecimal memory newSize = oldPosition.size.addD(
            positionResp.exchangedPositionSize
        );

        _updateOpenInterestNotional(_amm, MixedDecimal.fromDecimal(_openNotional));
        _updateTotalPositionSize(_amm, positionResp.exchangedPositionSize, _side);

        Decimal.decimal memory maxHoldingBaseAsset = _amm.getMaxHoldingBaseAsset();
        if (maxHoldingBaseAsset.toUint() != 0) {
            // total position size should be less than `positionUpperBound`
            require(newSize.abs().cmp(maxHoldingBaseAsset) <= 0, "positionSize cap");
        }

        SignedDecimal.signedDecimal memory marginToAdd = MixedDecimal.fromDecimal(
            _openNotional.divD(_leverage)
        );
        CalcRemainMarginReturnParams
            memory calcRemainMarginReturnParams = _calcRemainMarginWithFundingPayment(
                _amm,
                oldPosition,
                marginToAdd
            );

        (, SignedDecimal.signedDecimal memory unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
            _amm,
            trader,
            PnlCalcOption.SPOT_PRICE
        );

        // update positionResp
        positionResp.exchangedQuoteAssetAmount = _openNotional;
        positionResp.unrealizedPnlAfter = unrealizedPnl;
        positionResp.marginToVault = marginToAdd;
        positionResp.fundingPayment = calcRemainMarginReturnParams.fundingPayment;
        positionResp.position = Position(
            newSize,
            calcRemainMarginReturnParams.remainingMargin,
            oldPosition.openNotional.addD(positionResp.exchangedQuoteAssetAmount),
            calcRemainMarginReturnParams.latestCumulativePremiumFractionLong,
            calcRemainMarginReturnParams.latestCumulativePremiumFractionShort,
            block.number
        );
    }

    function _openReversePosition(
        IAmm _amm,
        Side _side,
        address _trader,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) internal returns (PositionResp memory) {
        Decimal.decimal memory openNotional = _quoteAssetAmount.mulD(_leverage);
        (
            Decimal.decimal memory oldPositionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        ) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        PositionResp memory positionResp;

        // reduce position if old position is larger
        if (oldPositionNotional.toUint() > openNotional.toUint()) {
            // for reducing oi and tps from respective side

            Position memory oldPosition = getPosition(_amm, _trader);
            {
                positionResp.exchangedPositionSize = _swapInput(
                    _amm,
                    _side,
                    openNotional,
                    _baseAssetAmountLimit,
                    _canOverFluctuationLimit
                );

                // realizedPnl = unrealizedPnl * closedRatio
                // closedRatio = positionResp.exchangedPositionSize / oldPosition.size
                if (oldPosition.size.toInt() != 0) {
                    positionResp.realizedPnl = unrealizedPnl
                        .mulD(positionResp.exchangedPositionSize.abs())
                        .divD(oldPosition.size.abs());
                }

                CalcRemainMarginReturnParams
                    memory calcRemainMarginReturnParams = _calcRemainMarginWithFundingPayment(
                        _amm,
                        oldPosition,
                        positionResp.realizedPnl
                    );

                // positionResp.unrealizedPnlAfter = unrealizedPnl - realizedPnl
                positionResp.unrealizedPnlAfter = unrealizedPnl.subD(positionResp.realizedPnl);
                positionResp.exchangedQuoteAssetAmount = openNotional;

                // calculate openNotional (it's different depends on long or short side)
                // long: unrealizedPnl = positionNotional - openNotional => openNotional = positionNotional - unrealizedPnl
                // short: unrealizedPnl = openNotional - positionNotional => openNotional = positionNotional + unrealizedPnl
                // positionNotional = oldPositionNotional - exchangedQuoteAssetAmount
                SignedDecimal.signedDecimal memory remainOpenNotional = oldPosition.size.toInt() > 0
                    ? MixedDecimal
                        .fromDecimal(oldPositionNotional)
                        .subD(positionResp.exchangedQuoteAssetAmount)
                        .subD(positionResp.unrealizedPnlAfter)
                    : positionResp.unrealizedPnlAfter.addD(oldPositionNotional).subD(
                        positionResp.exchangedQuoteAssetAmount
                    );
                require(remainOpenNotional.toInt() > 0, "remainNotional <= 0");

                positionResp.position = Position(
                    oldPosition.size.addD(positionResp.exchangedPositionSize),
                    calcRemainMarginReturnParams.remainingMargin,
                    remainOpenNotional.abs(),
                    calcRemainMarginReturnParams.latestCumulativePremiumFractionLong,
                    calcRemainMarginReturnParams.latestCumulativePremiumFractionShort,
                    block.number
                );
            }

            // update open interest and total position sizes
            Side side = _side == Side.BUY ? Side.BUY : Side.SELL; // reduce
            _updateTotalPositionSize(_amm, positionResp.exchangedPositionSize, side);
            _updateOpenInterestNotional(
                _amm,
                positionResp
                .realizedPnl
                .addD(positionResp.badDebt) // bad debt also considers as removed notional
                    .addD(oldPosition.openNotional)
                    .subD(positionResp.position.openNotional)
                    .mulScalar(-1)
            );
            return positionResp;
        }
        return
            _closeAndOpenReversePosition(
                _amm,
                _side,
                _trader,
                _quoteAssetAmount,
                _leverage,
                _baseAssetAmountLimit
            );
    }

    function _closeAndOpenReversePosition(
        IAmm _amm,
        Side _side,
        address _trader,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit
    ) internal returns (PositionResp memory positionResp) {
        // new position size is larger than or equal to the old position size
        // so either close or close then open a larger position
        PositionResp memory closePositionResp = _internalClosePosition(
            _amm,
            _trader,
            Decimal.zero()
        );

        // the old position is underwater. trader should close a position first
        require(closePositionResp.badDebt.toUint() == 0, "bad debt");

        // update open notional after closing position
        Decimal.decimal memory openNotional = _quoteAssetAmount.mulD(_leverage).subD(
            closePositionResp.exchangedQuoteAssetAmount
        );

        // if remain exchangedQuoteAssetAmount is too small (eg. 1wei) then the required margin might be 0
        // then the clearingHouse will stop opening position
        if (openNotional.divD(_leverage).toUint() == 0) {
            positionResp = closePositionResp;
        } else {
            Decimal.decimal memory updatedBaseAssetAmountLimit;
            if (_baseAssetAmountLimit.toUint() > closePositionResp.exchangedPositionSize.toUint()) {
                updatedBaseAssetAmountLimit = _baseAssetAmountLimit.subD(
                    closePositionResp.exchangedPositionSize.abs()
                );
            }

            PositionResp memory increasePositionResp = _internalIncreasePosition(
                _amm,
                _side,
                openNotional,
                updatedBaseAssetAmountLimit,
                _leverage
            );
            positionResp = PositionResp({
                position: increasePositionResp.position,
                exchangedQuoteAssetAmount: closePositionResp.exchangedQuoteAssetAmount.addD(
                    increasePositionResp.exchangedQuoteAssetAmount
                ),
                badDebt: closePositionResp.badDebt.addD(increasePositionResp.badDebt),
                fundingPayment: closePositionResp.fundingPayment.addD(
                    increasePositionResp.fundingPayment
                ),
                exchangedPositionSize: closePositionResp.exchangedPositionSize.addD(
                    increasePositionResp.exchangedPositionSize
                ),
                realizedPnl: closePositionResp.realizedPnl.addD(increasePositionResp.realizedPnl),
                unrealizedPnlAfter: SignedDecimal.zero(),
                marginToVault: closePositionResp.marginToVault.addD(
                    increasePositionResp.marginToVault
                )
            });
        }
        return positionResp;
    }

    function _internalClosePosition(
        IAmm _amm,
        address _trader,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) internal returns (PositionResp memory positionResp) {
        // check conditions
        Position memory oldPosition = getPosition(_amm, _trader);
        _requirePositionSize(oldPosition.size);

        (, SignedDecimal.signedDecimal memory unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
            _amm,
            _trader,
            PnlCalcOption.SPOT_PRICE
        );
        CalcRemainMarginReturnParams
            memory calcRemainMarginReturnParams = _calcRemainMarginWithFundingPayment(
                _amm,
                oldPosition,
                unrealizedPnl
            );

        positionResp.exchangedPositionSize = oldPosition.size.mulScalar(-1);
        positionResp.realizedPnl = unrealizedPnl;
        positionResp.badDebt = calcRemainMarginReturnParams.badDebt;
        positionResp.fundingPayment = calcRemainMarginReturnParams.fundingPayment;
        positionResp.marginToVault = MixedDecimal
            .fromDecimal(calcRemainMarginReturnParams.remainingMargin)
            .mulScalar(-1);

        // for amm.swapOutput, the direction is in base asset, from the perspective of Amm
        positionResp.exchangedQuoteAssetAmount = _amm.swapOutput(
            oldPosition.size.toInt() > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
            oldPosition.size.abs(),
            _quoteAssetAmountLimit
        );

        Side side = oldPosition.size.toInt() > 0 ? Side.BUY : Side.SELL;
        // bankrupt position's bad debt will be also consider as a part of the open interest
        _updateOpenInterestNotional(
            _amm,
            unrealizedPnl
                .addD(calcRemainMarginReturnParams.badDebt)
                .addD(oldPosition.openNotional)
                .mulScalar(-1)
        );
        _updateTotalPositionSize(_amm, positionResp.exchangedPositionSize, side);
        _clearPosition(_amm, _trader);
    }

    function _internalPartialClose(
        IAmm _amm,
        address _trader,
        Decimal.decimal memory _partialCloseRatio,
        Decimal.decimal memory _quoteAssetAmountLimit
    ) internal returns (PositionResp memory) {
        // check conditions
        Position memory oldPosition = getPosition(_amm, _trader);
        _requirePositionSize(oldPosition.size);

        (
            Decimal.decimal memory oldPositionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        ) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);

        SignedDecimal.signedDecimal memory sizeToClose = oldPosition.size.mulD(_partialCloseRatio);
        SignedDecimal.signedDecimal memory marginToRemove = MixedDecimal.fromDecimal(
            oldPosition.margin.mulD(_partialCloseRatio)
        );

        PositionResp memory positionResp;
        CalcRemainMarginReturnParams memory calcRemaingMarginReturnParams;
        // scope for avoiding stack too deep error
        {
            positionResp.exchangedPositionSize = sizeToClose.mulScalar(-1);

            positionResp.realizedPnl = unrealizedPnl.mulD(_partialCloseRatio);
            positionResp.unrealizedPnlAfter = unrealizedPnl.subD(positionResp.realizedPnl);

            calcRemaingMarginReturnParams = _calcRemainMarginWithFundingPayment(
                _amm,
                oldPosition,
                marginToRemove.mulScalar(-1)
            );
            positionResp.badDebt = calcRemaingMarginReturnParams.badDebt;
            positionResp.fundingPayment = calcRemaingMarginReturnParams.fundingPayment;
            positionResp.marginToVault = marginToRemove.addD(positionResp.realizedPnl).mulScalar(
                -1
            );

            // for amm.swapOutput, the direction is in base asset, from the perspective of Amm
            positionResp.exchangedQuoteAssetAmount = _amm.swapOutput(
                oldPosition.size.toInt() > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                sizeToClose.abs(),
                _quoteAssetAmountLimit
            );
        }

        SignedDecimal.signedDecimal memory remainOpenNotional = oldPosition.size.toInt() > 0
            ? MixedDecimal
                .fromDecimal(oldPositionNotional)
                .subD(positionResp.exchangedQuoteAssetAmount)
                .subD(positionResp.unrealizedPnlAfter)
            : positionResp.unrealizedPnlAfter.addD(oldPositionNotional).subD(
                positionResp.exchangedQuoteAssetAmount
            );
        require(remainOpenNotional.toInt() > 0, "value of openNotional <= 0");

        positionResp.position = Position(
            oldPosition.size.subD(sizeToClose),
            calcRemaingMarginReturnParams.remainingMargin,
            remainOpenNotional.abs(),
            calcRemaingMarginReturnParams.latestCumulativePremiumFractionLong,
            calcRemaingMarginReturnParams.latestCumulativePremiumFractionShort,
            block.number
        );

        // for reducing oi and tps from respective side
        Side side = oldPosition.size.toInt() > 0 ? Side.BUY : Side.SELL;
        _updateOpenInterestNotional(
            _amm,
            positionResp
            .realizedPnl
            .addD(positionResp.badDebt) // bad debt also considers as removed notional
                .addD(oldPosition.openNotional)
                .subD(positionResp.position.openNotional)
                .mulScalar(-1)
        );
        _updateTotalPositionSize(_amm, positionResp.exchangedPositionSize, side);

        // update position
        setPosition(_amm, _trader, positionResp.position);

        return positionResp;
    }

    function _internalLiquidate(IAmm _amm, address _trader)
        internal
        returns (Decimal.decimal memory quoteAssetAmount, bool isPartialClose)
    {
        _requireAmm(_amm);

        SignedDecimal.signedDecimal memory marginRatio = getMarginRatio(_amm, _trader);

        if (_amm.isOverSpreadLimit()) {
            SignedDecimal.signedDecimal
                memory marginRatioBasedOnOracle = _getMarginRatioByCalcOption(
                    _amm,
                    _trader,
                    PnlCalcOption.ORACLE
                );
            if (marginRatioBasedOnOracle.subD(marginRatio).toInt() > 0) {
                marginRatio = marginRatioBasedOnOracle;
            }
        }

        IAmm.Ratios memory ratios = _amm.getRatios();
        _requireMoreMarginRatio(marginRatio, ratios.maintenanceMarginRatio, false);

        PositionResp memory positionResp;
        Decimal.decimal memory liquidationPenalty;
        {
            Decimal.decimal memory liquidationBadDebt;
            Decimal.decimal memory feeToLiquidator;
            Decimal.decimal memory feeToInsuranceFund;
            IERC20 quoteAsset = _amm.quoteAsset();

            // partially liquidate if over liquidation fee ratio
            if (
                marginRatio.toInt() > int256(ratios.liquidationFeeRatio.toUint()) &&
                ratios.partialLiquidationRatio.toUint() != 0
            ) {
                Position memory position = getPosition(_amm, _trader);

                Decimal.decimal memory partiallyLiquidatedPositionNotional = _amm.getOutputPrice(
                    position.size.toInt() > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                    position.size.mulD(ratios.partialLiquidationRatio).abs()
                );

                positionResp = _openReversePosition(
                    _amm,
                    position.size.toInt() > 0 ? Side.SELL : Side.BUY,
                    _trader,
                    partiallyLiquidatedPositionNotional,
                    Decimal.one(),
                    Decimal.zero(),
                    true
                );

                // half of the liquidationFee goes to liquidator & another half goes to insurance fund
                liquidationPenalty = positionResp.exchangedQuoteAssetAmount.mulD(
                    ratios.liquidationFeeRatio
                );
                feeToLiquidator = liquidationPenalty.divScalar(2);
                feeToInsuranceFund = liquidationPenalty.subD(feeToLiquidator);

                positionResp.position.margin = positionResp.position.margin.subD(
                    liquidationPenalty
                );

                // update position
                setPosition(_amm, _trader, positionResp.position);

                isPartialClose = true;
            } else {
                positionResp = _internalClosePosition(_amm, _trader, Decimal.zero());

                Decimal.decimal memory remainingMargin = positionResp.marginToVault.abs();

                feeToLiquidator = positionResp
                    .exchangedQuoteAssetAmount
                    .mulD(ratios.liquidationFeeRatio)
                    .divScalar(2);

                if (feeToLiquidator.toUint() > remainingMargin.toUint()) {
                    liquidationBadDebt = feeToLiquidator.subD(remainingMargin);
                } else {
                    feeToInsuranceFund = remainingMargin.subD(feeToLiquidator);
                }

                liquidationPenalty = feeToLiquidator.addD(feeToInsuranceFund);
            }

            if (feeToInsuranceFund.toUint() > 0) {
                _transferToInsuranceFund(quoteAsset, feeToInsuranceFund);
            }
            // reward liquidator
            _withdraw(quoteAsset, _msgSender(), feeToLiquidator);

            emit PositionLiquidated(
                _trader,
                address(_amm),
                _msgSender(),
                positionResp.exchangedQuoteAssetAmount.toUint(),
                positionResp.exchangedPositionSize.toUint(),
                feeToLiquidator.toUint(),
                feeToInsuranceFund.toUint(),
                liquidationBadDebt.toUint()
            );
        }

        // emit event
        uint256 markPrice = _amm.getMarkPrice().toUint();
        int256 fundingPayment = positionResp.fundingPayment.toInt();
        emit PositionChanged(
            _trader,
            address(_amm),
            positionResp.position.margin.toUint(),
            positionResp.exchangedQuoteAssetAmount.toUint(),
            positionResp.exchangedPositionSize.toInt(),
            0,
            positionResp.position.size.toInt(),
            positionResp.realizedPnl.toInt(),
            positionResp.unrealizedPnlAfter.toInt(),
            positionResp.badDebt.toUint(),
            liquidationPenalty.toUint(),
            markPrice,
            fundingPayment
        );

        return (positionResp.exchangedQuoteAssetAmount, isPartialClose);
    }

    function _swapInput(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _inputAmount,
        Decimal.decimal memory _minOutputAmount,
        bool _canOverFluctuationLimit
    ) internal returns (SignedDecimal.signedDecimal memory) {
        // for amm.swapInput, the direction is in quote asset, from the perspective of Amm
        IAmm.Dir dir = (_side == Side.BUY) ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM;
        SignedDecimal.signedDecimal memory outputAmount = MixedDecimal.fromDecimal(
            _amm.swapInput(dir, _inputAmount, _minOutputAmount, _canOverFluctuationLimit)
        );
        if (IAmm.Dir.REMOVE_FROM_AMM == dir) {
            return outputAmount.mulScalar(-1);
        }
        return outputAmount;
    }

    function _transferFees(
        address _from,
        IAmm _amm,
        Decimal.decimal memory _positionNotional,
        Side _side,
        bool _isOpenPos
    ) internal returns (Decimal.decimal memory fees) {
        fees = _amm.calcFee(
            _side == Side.BUY ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
            _positionNotional,
            _isOpenPos
        );

        if (fees.toUint() > 0) {
            IERC20 quoteToken = _amm.quoteAsset();
            /**
             * toll fees - fees towards clearing house
             * spread fees - fees towards insurance fund
             */
            Decimal.decimal memory tollFees = fees.divScalar(2);
            Decimal.decimal memory spreadFees = fees.subD(tollFees);

            _transferFrom(quoteToken, _from, address(this), tollFees);
            tollMap[address(quoteToken)] = tollMap[address(quoteToken)].addD(tollFees);

            _transferFrom(quoteToken, _from, address(insuranceFund), spreadFees);
        }
    }

    function _withdraw(
        IERC20 _token,
        address _receiver,
        Decimal.decimal memory _amount
    ) internal {
        // token balance (without toll fees)
        Decimal.decimal memory tollTotal = tollMap[address(_token)];
        Decimal.decimal memory totalTokenBalance = _balanceOf(_token, address(this)).subD(
            tollTotal
        );
        // if token balance is less than withdrawal amount, use toll to cover deficit
        // if toll balance is still insufficient, borrow from insurance fund
        if (totalTokenBalance.toUint() < _amount.toUint()) {
            Decimal.decimal memory balanceShortage = _amount.subD(totalTokenBalance);
            Decimal.decimal memory tollShortage = _coverWithToll(_token, balanceShortage);
            if (tollShortage.toUint() > 0) {
                insuranceFund.withdraw(_token, tollShortage);
            }
        }

        _transfer(_token, _receiver, _amount);
    }

    function _coverWithToll(IERC20 _token, Decimal.decimal memory _amount)
        internal
        returns (Decimal.decimal memory tollShortage)
    {
        Decimal.decimal memory tollTotal = tollMap[address(_token)];
        if (tollTotal.toUint() > _amount.toUint()) {
            tollMap[address(_token)] = tollTotal.subD(_amount);
        } else {
            tollShortage = _amount.subD(tollTotal);
            tollMap[address(_token)] = Decimal.zero();
        }
    }

    function _settleRepegPnl(IAmm _amm, SignedDecimal.signedDecimal memory _repegPnl)
        internal
        returns (Decimal.decimal memory repegDebt)
    {
        if (_repegPnl.toInt() != 0) {
            Decimal.decimal memory repegPnlAbs = _repegPnl.abs();
            IERC20 token = _amm.quoteAsset();
            // settle pnl with insurance fund
            if (_repegPnl.isNegative()) {
                // use toll to cover repeg loss
                // if toll is not enough, borrow deficit from insurance fund
                repegDebt = _coverWithToll(token, repegPnlAbs);
                if (repegDebt.toUint() > 0) {
                    insuranceFund.withdraw(token, repegDebt);
                }
            } else {
                // transfer to insurance fund
                _transferToInsuranceFund(token, repegPnlAbs);
            }
        }
    }

    function _transferToInsuranceFund(IERC20 _token, Decimal.decimal memory _amount) internal {
        Decimal.decimal memory totalTokenBalance = _balanceOf(_token, address(this));
        Decimal.decimal memory amountToTransfer = _amount.cmp(totalTokenBalance) > 0
            ? totalTokenBalance
            : _amount;
        _transfer(_token, address(insuranceFund), amountToTransfer);
    }

    function _updateOpenInterestNotional(IAmm _amm, SignedDecimal.signedDecimal memory _amount)
        internal
    {
        // when cap = 0 means no cap
        uint256 openInterestNotionalCap = _amm.getOpenInterestNotionalCap().toUint();
        SignedDecimal.signedDecimal memory openInterestNotional = MixedDecimal.fromDecimal(
            openInterestNotionalMap[address(_amm)]
        );
        openInterestNotional = _amount.addD(openInterestNotional);
        if (openInterestNotional.toInt() < 0) {
            openInterestNotional = SignedDecimal.zero();
        }
        if (openInterestNotionalCap != 0) {
            require(
                openInterestNotional.toUint() <= openInterestNotionalCap,
                "over open interest cap"
            );
        }

        openInterestNotionalMap[address(_amm)] = openInterestNotional.abs();
    }

    function _updateTotalPositionSize(
        IAmm _amm,
        SignedDecimal.signedDecimal memory _amount,
        Side _side
    ) internal {
        TotalPositionSize memory tps = totalPositionSizeMap[address(_amm)];
        tps.netPositionSize = _amount.addD(tps.netPositionSize);
        if (_side == Side.BUY) {
            tps.positionSizeLong = _amount.addD(tps.positionSizeLong).abs();
        } else {
            tps.positionSizeShort = _amount.mulScalar(-1).addD(tps.positionSizeShort).abs();
        }
        totalPositionSizeMap[address(_amm)] = tps;
    }

    function setPosition(
        IAmm _amm,
        address _trader,
        Position memory _position
    ) internal {
        Position storage positionStorage = positionMap[address(_amm)][_trader];
        positionStorage.size = _position.size;
        positionStorage.margin = _position.margin;
        positionStorage.openNotional = _position.openNotional;
        positionStorage.lastUpdatedCumulativePremiumFractionLong = _position
            .lastUpdatedCumulativePremiumFractionLong;
        positionStorage.lastUpdatedCumulativePremiumFractionShort = _position
            .lastUpdatedCumulativePremiumFractionShort;
        positionStorage.blockNumber = _position.blockNumber;
    }

    function _clearPosition(IAmm _amm, address _trader) internal {
        // keep the record in order to retain the last updated block number
        positionMap[address(_amm)][_trader] = Position({
            size: SignedDecimal.zero(),
            margin: Decimal.zero(),
            openNotional: Decimal.zero(),
            lastUpdatedCumulativePremiumFractionLong: SignedDecimal.zero(),
            lastUpdatedCumulativePremiumFractionShort: SignedDecimal.zero(),
            blockNumber: block.number
        });
    }

    function _calcRemainMarginWithFundingPayment(
        IAmm _amm,
        Position memory _oldPosition,
        SignedDecimal.signedDecimal memory _marginDelta
    ) internal view returns (CalcRemainMarginReturnParams memory calcRemainMarginReturnParams) {
        // calculate funding payment
        (
            calcRemainMarginReturnParams.latestCumulativePremiumFractionLong,
            calcRemainMarginReturnParams.latestCumulativePremiumFractionShort
        ) = getLatestCumulativePremiumFraction(_amm);

        if (_oldPosition.size.toInt() != 0) {
            if (_oldPosition.size.toInt() > 0) {
                calcRemainMarginReturnParams.fundingPayment = calcRemainMarginReturnParams
                    .latestCumulativePremiumFractionLong
                    .subD(_oldPosition.lastUpdatedCumulativePremiumFractionLong)
                    .mulD(_oldPosition.size);
            } else {
                calcRemainMarginReturnParams.fundingPayment = calcRemainMarginReturnParams
                    .latestCumulativePremiumFractionShort
                    .subD(_oldPosition.lastUpdatedCumulativePremiumFractionShort)
                    .mulD(_oldPosition.size);
            }
        }

        // calculate remain margin
        SignedDecimal.signedDecimal memory signedRemainMargin = _marginDelta
            .subD(calcRemainMarginReturnParams.fundingPayment)
            .addD(_oldPosition.margin);

        // if remain margin is negative, set to zero and leave the rest to bad debt
        if (signedRemainMargin.toInt() < 0) {
            calcRemainMarginReturnParams.badDebt = signedRemainMargin.abs();
        } else {
            calcRemainMarginReturnParams.remainingMargin = signedRemainMargin.abs();
        }
    }

    function _calcFreeCollateral(
        IAmm _amm,
        address _trader,
        Decimal.decimal memory _marginWithFundingPayment
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        Position memory pos = getPosition(_amm, _trader);
        (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        ) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);

        // min(margin + funding, margin + funding + unrealized PnL) - position value * initMarginRatio
        SignedDecimal.signedDecimal memory accountValue = unrealizedPnl.addD(
            _marginWithFundingPayment
        );
        SignedDecimal.signedDecimal memory minCollateral = unrealizedPnl.toInt() > 0
            ? MixedDecimal.fromDecimal(_marginWithFundingPayment)
            : accountValue;

        // margin requirement
        // if holding a long position, using open notional
        // if holding a short position, using position notional
        Decimal.decimal memory initMarginRatio = _amm.getRatios().initMarginRatio;
        SignedDecimal.signedDecimal memory marginRequirement = pos.size.toInt() > 0
            ? MixedDecimal.fromDecimal(pos.openNotional).mulD(initMarginRatio)
            : MixedDecimal.fromDecimal(positionNotional).mulD(initMarginRatio);

        return minCollateral.subD(marginRequirement);
    }

    function _getMarginRatioByCalcOption(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) internal view returns (SignedDecimal.signedDecimal memory) {
        Position memory position = getPosition(_amm, _trader);
        _requirePositionSize(position.size);
        (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory pnl
        ) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, _pnlCalcOption);
        return _getMarginRatio(_amm, position, pnl, positionNotional);
    }

    function _requireAmm(IAmm _amm) internal view {
        require(insuranceFund.isExistedAmm(_amm), "amm not found");
    }

    function _requireNonZeroInput(Decimal.decimal memory _decimal) internal pure {
        require(_decimal.toUint() != 0, "0 input");
    }

    function _requirePositionSize(SignedDecimal.signedDecimal memory _size) internal pure {
        require(_size.toInt() != 0, "positionSize is 0");
    }

    function _requireNonSandwich(IAmm _amm) internal view {
        uint256 currentBlock = block.number;
        require(getPosition(_amm, _msgSender()).blockNumber != currentBlock, "non sandwich");
    }

    function _requireMoreMarginRatio(
        SignedDecimal.signedDecimal memory _marginRatio,
        Decimal.decimal memory _baseMarginRatio,
        bool _largerThanOrEqualTo
    ) internal pure {
        int256 remainingMarginRatio = _marginRatio.subD(_baseMarginRatio).toInt();
        require(
            _largerThanOrEqualTo ? remainingMarginRatio >= 0 : remainingMarginRatio < 0,
            "margin ratio not meet critera"
        );
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { DecimalMath } from "./DecimalMath.sol";

library Decimal {
    using DecimalMath for uint256;

    struct decimal {
        uint256 d;
    }

    function zero() internal pure returns (decimal memory) {
        return decimal(0);
    }

    function one() internal pure returns (decimal memory) {
        return decimal(DecimalMath.unit(18));
    }

    function toUint(decimal memory x) internal pure returns (uint256) {
        return x.d;
    }

    function modD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        return decimal((x.d * (DecimalMath.unit(18))) % y.d);
    }

    function cmp(decimal memory x, decimal memory y) internal pure returns (int8) {
        if (x.d > y.d) {
            return 1;
        } else if (x.d < y.d) {
            return -1;
        }
        return 0;
    }

    /// @dev add two decimals
    function addD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a decimal by a uint256
    function mulScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(decimal memory x, decimal memory y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a decimal by a uint256
    function divScalar(decimal memory x, uint256 y) internal pure returns (decimal memory) {
        decimal memory t;
        t.d = x.d / y;
        return t;
    }

    /// @dev square root
    function sqrt(decimal memory _y) internal pure returns (decimal memory) {
        uint256 y = _y.d * 1e18;
        uint256 z;
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return decimal(z);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { SignedDecimalMath } from "./SignedDecimalMath.sol";
import { Decimal } from "./Decimal.sol";

library SignedDecimal {
    using SignedDecimalMath for int256;

    struct signedDecimal {
        int256 d;
    }

    function zero() internal pure returns (signedDecimal memory) {
        return signedDecimal(0);
    }

    function toInt(signedDecimal memory x) internal pure returns (int256) {
        return x.d;
    }

    function isNegative(signedDecimal memory x) internal pure returns (bool) {
        if (x.d < 0) {
            return true;
        }
        return false;
    }

    function abs(signedDecimal memory x) internal pure returns (Decimal.decimal memory) {
        Decimal.decimal memory t;
        if (x.d < 0) {
            t.d = uint256(0 - x.d);
        } else {
            t.d = uint256(x.d);
        }
        return t;
    }

    /// @dev add two decimals
    function addD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.addd(y.d);
        return t;
    }

    /// @dev subtract two decimals
    function subD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.subd(y.d);
        return t;
    }

    /// @dev multiple two decimals
    function mulD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.muld(y.d);
        return t;
    }

    /// @dev multiple a signedDecimal by a int256
    function mulScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d * y;
        return t;
    }

    /// @dev divide two decimals
    function divD(signedDecimal memory x, signedDecimal memory y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d.divd(y.d);
        return t;
    }

    /// @dev divide a signedDecimal by a int256
    function divScalar(signedDecimal memory x, int256 y)
        internal
        pure
        returns (signedDecimal memory)
    {
        signedDecimal memory t;
        t.d = x.d / y;
        return t;
    }

    /// @dev square root
    function sqrt(signedDecimal memory _y) internal pure returns (signedDecimal memory) {
        int256 y = _y.d * 1e18;
        int256 z;
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        return signedDecimal(z);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { Decimal } from "./Decimal.sol";
import { SignedDecimal } from "./SignedDecimal.sol";

/// @dev To handle a signedDecimal add/sub/mul/div a decimal and provide convert decimal to signedDecimal helper
library MixedDecimal {
    using SignedDecimal for SignedDecimal.signedDecimal;

    uint256 private constant _INT256_MAX = 2**255 - 1;
    string private constant ERROR_NON_CONVERTIBLE =
        "MixedDecimal: uint value is bigger than _INT256_MAX";

    modifier convertible(Decimal.decimal memory x) {
        require(_INT256_MAX >= x.d, ERROR_NON_CONVERTIBLE);
        _;
    }

    function fromDecimal(Decimal.decimal memory x)
        internal
        pure
        convertible(x)
        returns (SignedDecimal.signedDecimal memory)
    {
        return SignedDecimal.signedDecimal(int256(x.d));
    }

    function toUint(SignedDecimal.signedDecimal memory x) internal pure returns (uint256) {
        return x.abs().d;
    }

    /// @dev add SignedDecimal.signedDecimal and Decimal.decimal, using SignedSafeMath directly
    function addD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d + int256(y.d);
        return t;
    }

    /// @dev subtract SignedDecimal.signedDecimal by Decimal.decimal, using SignedSafeMath directly
    function subD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t.d = x.d - int256(y.d);
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by Decimal.decimal
    function mulD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.mulD(fromDecimal(y));
        return t;
    }

    /// @dev multiple a SignedDecimal.signedDecimal by a uint256
    function mulScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.mulScalar(int256(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a Decimal.decimal
    function divD(SignedDecimal.signedDecimal memory x, Decimal.decimal memory y)
        internal
        pure
        convertible(y)
        returns (SignedDecimal.signedDecimal memory)
    {
        SignedDecimal.signedDecimal memory t;
        t = x.divD(fromDecimal(y));
        return t;
    }

    /// @dev divide a SignedDecimal.signedDecimal by a uint256
    function divScalar(SignedDecimal.signedDecimal memory x, uint256 y)
        internal
        pure
        returns (SignedDecimal.signedDecimal memory)
    {
        require(_INT256_MAX >= y, ERROR_NON_CONVERTIBLE);
        SignedDecimal.signedDecimal memory t;
        t = x.divScalar(int256(y));
        return t;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "./Decimal.sol";

/**
 * @title DecimalERC20
 * @notice wrapper to interact with erc20 in decimal math
 */
abstract contract DecimalERC20 {
    using Decimal for Decimal.decimal;

    mapping(address => uint256) private decimalMap;

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//

    uint256[50] private __gap;

    function _transfer(
        IERC20 _token,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 rawValue = _toUint(_token, _value);
        require(_token.transfer(_to, rawValue), "transfer failed");
        _validateBalance(_token, _to, rawValue, balanceBefore);
    }

    function _transferFrom(
        IERC20 _token,
        address _from,
        address _to,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        Decimal.decimal memory balanceBefore = _balanceOf(_token, _to);
        uint256 rawValue = _toUint(_token, _value);
        require(_token.transferFrom(_from, _to, rawValue), "transferFrom failed");
        _validateBalance(_token, _to, rawValue, balanceBefore);
    }

    function _approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) internal {
        _updateDecimal(address(_token));
        // to be compatible with some erc20 tokens like USDT
        __approve(_token, _spender, Decimal.zero());
        __approve(_token, _spender, _value);
    }

    //
    // VIEW
    //
    function _allowance(
        IERC20 _token,
        address _owner,
        address _spender
    ) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.allowance(_owner, _spender));
    }

    function _balanceOf(IERC20 _token, address _owner)
        internal
        view
        returns (Decimal.decimal memory)
    {
        return _toDecimal(_token, _token.balanceOf(_owner));
    }

    function _totalSupply(IERC20 _token) internal view returns (Decimal.decimal memory) {
        return _toDecimal(_token, _token.totalSupply());
    }

    function _toDecimal(IERC20 _token, uint256 _number)
        internal
        view
        returns (Decimal.decimal memory)
    {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return Decimal.decimal(_number / (10**(tokenDecimals - 18)));
        }

        return Decimal.decimal(_number * (10**(uint256(18) - tokenDecimals)));
    }

    function _toUint(IERC20 _token, Decimal.decimal memory _decimal)
        internal
        view
        returns (uint256)
    {
        uint256 tokenDecimals = _getTokenDecimals(address(_token));
        if (tokenDecimals >= 18) {
            return _decimal.toUint() * (10**(tokenDecimals - 18));
        }
        return _decimal.toUint() / (10**(uint256(18) - tokenDecimals));
    }

    function _getTokenDecimals(address _token) internal view returns (uint256) {
        uint256 tokenDecimals = decimalMap[_token];
        if (tokenDecimals == 0) {
            (bool success, bytes memory data) = _token.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            require(success && data.length != 0, "get decimals failed");
            tokenDecimals = abi.decode(data, (uint256));
        }
        return tokenDecimals;
    }

    //
    // PRIVATE
    //
    function _updateDecimal(address _token) private {
        uint256 tokenDecimals = _getTokenDecimals(_token);
        if (decimalMap[_token] != tokenDecimals) {
            decimalMap[_token] = tokenDecimals;
        }
    }

    function __approve(
        IERC20 _token,
        address _spender,
        Decimal.decimal memory _value
    ) private {
        require(_token.approve(_spender, _toUint(_token, _value)), "approve failed");
    }

    // To prevent from deflationary token, check receiver's balance is as expectation.
    function _validateBalance(
        IERC20 _token,
        address _to,
        uint256 _roundedDownValue,
        Decimal.decimal memory _balanceBefore
    ) private view {
        require(
            _balanceOf(_token, _to).cmp(
                _balanceBefore.addD(_toDecimal(_token, _roundedDownValue))
            ) == 0,
            "balance inconsistent"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OwnerPausableUpgradeable is OwnableUpgradeable, PausableUpgradeable {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    // solhint-disable func-name-mixedcase
    function __OwnerPausable_init() internal onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    /**
     * @notice pauses trading
     * @dev only owner
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice resumes trading
     * @dev only owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "../utils/Decimal.sol";
import { SignedDecimal } from "../utils/SignedDecimal.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getInputPrice, getOutputPrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    struct Ratios {
        Decimal.decimal feeRatio;
        Decimal.decimal initMarginRatio;
        Decimal.decimal maintenanceMarginRatio;
        Decimal.decimal partialLiquidationRatio;
        Decimal.decimal liquidationFeeRatio;
    }

    function swapInput(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        Decimal.decimal calldata _baseAssetAmountLimit,
        bool _canOverFluctuationLimit
    ) external returns (Decimal.decimal memory);

    function swapOutput(
        Dir _dirOfBase,
        Decimal.decimal calldata _baseAssetAmount,
        Decimal.decimal calldata _quoteAssetAmountLimit
    ) external returns (Decimal.decimal memory);

    function settleFunding()
        external
        returns (
            SignedDecimal.signedDecimal memory premiumFraction,
            Decimal.decimal memory markPrice,
            Decimal.decimal memory indexPrice
        );

    function repegPrice()
        external
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        );

    function repegK(Decimal.decimal memory _multiplier)
        external
        returns (
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            Decimal.decimal memory,
            SignedDecimal.signedDecimal memory
        );

    function updateFundingRate(
        SignedDecimal.signedDecimal memory,
        SignedDecimal.signedDecimal memory,
        Decimal.decimal memory
    ) external;

    //
    // VIEW
    //

    function calcFee(
        Dir _dirOfQuote,
        Decimal.decimal calldata _quoteAssetAmount,
        bool _isOpenPos
    ) external view returns (Decimal.decimal memory fees);

    function getMarkPrice() external view returns (Decimal.decimal memory);

    function getIndexPrice() external view returns (Decimal.decimal memory);

    function getReserves() external view returns (Decimal.decimal memory, Decimal.decimal memory);

    function getFeeRatio() external view returns (Decimal.decimal memory);

    function getInitMarginRatio() external view returns (Decimal.decimal memory);

    function getMaintenanceMarginRatio() external view returns (Decimal.decimal memory);

    function getPartialLiquidationRatio() external view returns (Decimal.decimal memory);

    function getLiquidationFeeRatio() external view returns (Decimal.decimal memory);

    function getMaxHoldingBaseAsset() external view returns (Decimal.decimal memory);

    function getOpenInterestNotionalCap() external view returns (Decimal.decimal memory);

    function getBaseAssetDelta() external view returns (SignedDecimal.signedDecimal memory);

    function getCumulativeNotional() external view returns (SignedDecimal.signedDecimal memory);

    function fundingPeriod() external view returns (uint256);

    function quoteAsset() external view returns (IERC20);

    function open() external view returns (bool);

    function getRatios() external view returns (Ratios memory);

    function calcPriceRepegPnl(Decimal.decimal memory _repegTo)
        external
        view
        returns (SignedDecimal.signedDecimal memory repegPnl);

    function calcKRepegPnl(Decimal.decimal memory _k)
        external
        view
        returns (SignedDecimal.signedDecimal memory repegPnl);

    function isOverFluctuationLimit(Dir _dirOfBase, Decimal.decimal memory _baseAssetAmount)
        external
        view
        returns (bool);

    function isOverSpreadLimit() external view returns (bool);

    function getInputTwap(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputTwap(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPrice(Dir _dir, Decimal.decimal calldata _quoteAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getOutputPrice(Dir _dir, Decimal.decimal calldata _baseAssetAmount)
        external
        view
        returns (Decimal.decimal memory);

    function getInputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);

    function getOutputPriceWithReserves(
        Dir _dir,
        Decimal.decimal memory _baseAssetAmount,
        Decimal.decimal memory _quoteAssetPoolAmount,
        Decimal.decimal memory _baseAssetPoolAmount
    ) external view returns (Decimal.decimal memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Decimal } from "../utils/Decimal.sol";
import { IAmm } from "./IAmm.sol";

interface IInsuranceFund {
    function withdraw(IERC20 _quoteToken, Decimal.decimal calldata _amount) external;

    function isExistedAmm(IAmm _amm) external view returns (bool);

    function getAllAmms() external view returns (IAmm[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

library DecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * y) / (unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library SignedDecimalMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    /// @dev Adds x and y, assuming they are both fixed point with 18 decimals.
    function addd(int256 x, int256 y) internal pure returns (int256) {
        return x + y;
    }

    /// @dev Subtracts y from x, assuming they are both fixed point with 18 decimals.
    function subd(int256 x, int256 y) internal pure returns (int256) {
        return x - y;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function muld(int256 x, int256 y) internal pure returns (int256) {
        return muld(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divd(int256 x, int256 y) internal pure returns (int256) {
        return divd(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / (y);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}