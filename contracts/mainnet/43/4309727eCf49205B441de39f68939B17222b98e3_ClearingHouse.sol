// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BlockContext } from "./utils/BlockContext.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { OwnerPausableUpgradeSafe } from "./OwnerPausable.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IInsuranceFund } from "./interfaces/IInsuranceFund.sol";
import { IMultiTokenRewardRecipient } from "./interfaces/IMultiTokenRewardRecipient.sol";
import { IntMath } from "./utils/IntMath.sol";
import { UIntMath } from "./utils/UIntMath.sol";
import { TransferHelper } from "./utils/TransferHelper.sol";
import { AmmMath } from "./utils/AmmMath.sol";
import { IClearingHouse } from "./interfaces/IClearingHouse.sol";
import { IInsuranceFundCallee } from "./interfaces/IInsuranceFundCallee.sol";
import { IWhitelistMaster } from "./interfaces/IWhitelistMaster.sol";

contract ClearingHouse is IClearingHouse, IInsuranceFundCallee, OwnerPausableUpgradeSafe, ReentrancyGuardUpgradeable, BlockContext {
    using UIntMath for uint256;
    using IntMath for int256;
    using TransferHelper for IERC20;

    //
    // Struct and Enum
    //

    enum PnlCalcOption {
        SPOT_PRICE,
        TWAP,
        ORACLE
    }

    /// @param MAX_PNL most beneficial way for traders to calculate position notional
    /// @param MIN_PNL least beneficial way for traders to calculate position notional
    enum PnlPreferenceOption {
        MAX_PNL,
        MIN_PNL
    }

    struct InternalOpenPositionParams {
        IAmm amm;
        Side side;
        address trader;
        uint256 amount;
        uint256 leverage;
        bool isQuote;
        bool canOverFluctuationLimit;
    }

    /// @notice This struct is used for avoiding stack too deep error when passing too many var between functions
    struct PositionResp {
        Position position;
        // the quote asset amount trader will send if open position, will receive if close
        uint256 exchangedQuoteAssetAmount;
        // if realizedPnl + realizedFundingPayment + margin is negative, it's the abs value of it
        uint256 badDebt;
        // the base asset amount trader will receive if open position, will send if close
        int256 exchangedPositionSize;
        // funding payment incurred during this position response
        int256 fundingPayment;
        // realizedPnl = unrealizedPnl * closedRatio
        int256 realizedPnl;
        // positive = trader transfer margin to vault, negative = trader receive margin from vault
        // it's 0 when internalReducePosition, its addedMargin when _increasePosition
        // it's min(0, oldPosition + realizedFundingPayment + realizedPnl) when _closePosition
        int256 marginToVault;
        // unrealized pnl after open position
        int256 unrealizedPnlAfter;
        // fee to the insurance fund
        uint256 spreadFee;
        // fee to the toll pool which provides rewards to the token stakers
        uint256 tollFee;
    }

    struct AmmMap {
        // issue #1471
        // last block when it turn restriction mode on.
        // In restriction mode, no one can do multi open/close/liquidate position in the same block.
        // If any underwater position being closed (having a bad debt and make insuranceFund loss),
        // or any liquidation happened,
        // restriction mode is ON in that block and OFF(default) in the next block.
        // This design is to prevent the attacker being benefited from the multiple action in one block
        // in extreme cases
        uint256 lastRestrictionBlock;
        int256 latestCumulativePremiumFractionLong;
        int256 latestCumulativePremiumFractionShort;
        mapping(address => Position) positionMap;
    }

    // constants
    uint256 public constant LIQ_SWITCH_RATIO = 0.2 ether; // 20%

    //**********************************************************//
    //    Can not change the order of below state variables     //
    //**********************************************************//
    //string public override versionRecipient;

    // key by amm address
    mapping(address => AmmMap) internal ammMap;

    // prepaid bad debt balance, key by Amm address
    mapping(address => uint256) public prepaidBadDebts;

    // contract dependencies
    IInsuranceFund public insuranceFund;
    IMultiTokenRewardRecipient public tollPool;

    mapping(address => bool) public backstopLiquidityProviderMap;

    // vamm => balance of vault
    mapping(IAmm => uint256) public vaults;

    // amm => revenue since last funding, used for calculation of k-adjustment budget
    mapping(IAmm => int256) public netRevenuesSinceLastFunding;

    address public whitelistMaster;

    uint256[50] private __gap;

    //**********************************************************//
    //    Can not change the order of above state variables     //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    //

    //
    // EVENTS
    //
    event BackstopLiquidityProviderChanged(address indexed account, bool indexed isProvider);
    event MarginChanged(address indexed sender, address indexed amm, int256 amount, int256 fundingPayment);
    event PositionSettled(address indexed amm, address indexed trader, uint256 valueTransferred);
    event RestrictionModeEntered(address amm, uint256 blockNumber);
    event Repeg(address amm, uint256 quoteAssetReserve, uint256 baseAssetReserve, int256 cost);
    event UpdateK(address amm, uint256 quoteAssetReserve, uint256 baseAssetReserve, int256 cost);

    /// @notice This event is emitted when position change
    /// @param trader the address which execute this transaction
    /// @param amm IAmm address
    /// @param margin margin
    /// @param positionNotional margin * leverage
    /// @param exchangedPositionSize position size
    /// @param fee transaction fee
    /// @param positionSizeAfter position size after this transaction, might be increased or decreased
    /// @param realizedPnl realized pnl after this position changed
    /// @param unrealizedPnlAfter unrealized pnl after this position changed
    /// @param badDebt position change amount cleared by insurance funds
    /// @param liquidationPenalty amount of remaining margin lost due to liquidation
    /// @param spotPrice quote asset reserve / base asset reserve
    /// @param fundingPayment funding payment (+: trader paid, -: trader received)
    event PositionChanged(
        address indexed trader,
        address indexed amm,
        int256 margin,
        uint256 positionNotional,
        int256 exchangedPositionSize,
        uint256 fee,
        int256 positionSizeAfter,
        int256 realizedPnl,
        int256 unrealizedPnlAfter,
        uint256 badDebt,
        uint256 liquidationPenalty,
        uint256 spotPrice,
        int256 fundingPayment
    );

    /// @notice This event is emitted when position liquidated
    /// @param trader the account address being liquidated
    /// @param amm IAmm address
    /// @param positionNotional liquidated position value minus liquidationFee
    /// @param positionSize liquidated position size
    /// @param feeToLiquidator liquidation fee to the liquidator
    /// @param feeToInsuranceFund liquidation fee to the insurance fund
    /// @param liquidator the address which execute this transaction
    /// @param badDebt liquidation bad debt cleared by insurance funds
    event PositionLiquidated(
        address indexed trader,
        address indexed amm,
        uint256 positionNotional,
        uint256 positionSize,
        uint256 feeToLiquidator,
        uint256 feeToInsuranceFund,
        address liquidator,
        uint256 badDebt
    );

    modifier checkAccess() {
        if (whitelistMaster != address(0)) {
            require(IWhitelistMaster(whitelistMaster).isWhitelisted(_msgSender()), "CH_NW"); // not whitelisted
        }
        _;
    }

    function initialize(IInsuranceFund _insuranceFund) public initializer {
        _requireNonZeroAddress(address(_insuranceFund));

        __OwnerPausable_init();

        __ReentrancyGuard_init();

        insuranceFund = _insuranceFund;
    }

    //
    // External
    //

    /**
     * @notice make protocol private that works for only whitelisted users
     * @dev only owner can call
     * @param _whitelistMaster the address of whitelist master where the whitelisted addresses are stored
     */
    function makePrivate(address _whitelistMaster) external onlyOwner {
        _requireNonZeroAddress(_whitelistMaster);
        whitelistMaster = _whitelistMaster;
    }

    /**
     * @notice make protocol public that works for all
     * @dev only owner can call
     */
    function makePublic() external onlyOwner {
        whitelistMaster = address(0);
    }

    /**
     * @notice set the toll pool address
     * @dev only owner can call
     */
    function setTollPool(address _tollPool) external onlyOwner {
        _requireNonZeroAddress(_tollPool);
        tollPool = IMultiTokenRewardRecipient(_tollPool);
    }

    /**
     * @notice set backstop liquidity provider
     * @dev only owner can call
     * @param account provider address
     * @param isProvider wether the account is a backstop liquidity provider
     */
    function setBackstopLiquidityProvider(address account, bool isProvider) external onlyOwner {
        _requireNonZeroAddress(account);
        backstopLiquidityProviderMap[account] = isProvider;
        emit BackstopLiquidityProviderChanged(account, isProvider);
    }

    /**
     * @dev only the insurance fund can call this function
     */
    function depositCallback(IERC20 _token, uint256 _amount) external {
        require(_msgSender() == address(insuranceFund), "CH_NIF"); // not insurnce fund
        _token.safeTransfer(address(insuranceFund), _amount);
    }

    /**
     * @notice add margin to increase margin ratio
     * @param _amm IAmm address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IAmm _amm, uint256 _addedMargin) external whenNotPaused nonReentrant checkAccess {
        // check condition
        _requireAmm(_amm, true);
        _requireNonZeroInput(_addedMargin);

        address trader = _msgSender();
        Position memory position = getPosition(_amm, trader);
        // update margin
        position.margin = position.margin + _addedMargin.toInt();

        _setPosition(_amm, trader, position);
        // transfer token from trader
        _deposit(_amm, trader, _addedMargin);
        emit MarginChanged(trader, address(_amm), int256(_addedMargin), 0);
    }

    /**
     * @notice remove margin to decrease margin ratio
     * @param _amm IAmm address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IAmm _amm, uint256 _removedMargin) external whenNotPaused nonReentrant checkAccess {
        // check condition
        _requireAmm(_amm, true);
        _requireNonZeroInput(_removedMargin);

        address trader = _msgSender();
        // realize funding payment if there's no bad debt
        Position memory position = getPosition(_amm, trader);

        // update margin and cumulativePremiumFraction
        int256 marginDelta = _removedMargin.toInt() * -1;
        (
            int256 remainMargin,
            uint256 badDebt,
            int256 fundingPayment,
            int256 latestCumulativePremiumFraction
        ) = _calcRemainMarginWithFundingPayment(_amm, position, marginDelta, position.size > 0);
        require(badDebt == 0, "CH_MNE"); // margin is not enough
        position.margin = remainMargin;
        position.lastUpdatedCumulativePremiumFraction = latestCumulativePremiumFraction;

        // check enough margin (same as the way Curie calculates the free collateral)
        // Use a more conservative way to restrict traders to remove their margin
        // We don't allow unrealized PnL to support their margin removal
        require(_calcFreeCollateral(_amm, trader, remainMargin) >= 0, "CH_FCNE"); //free collateral is not enough

        _setPosition(_amm, trader, position);

        // transfer token back to trader
        _withdraw(_amm, trader, _removedMargin);
        emit MarginChanged(trader, address(_amm), marginDelta, fundingPayment);
    }

    /**
     * @notice settle all the positions when amm is shutdown. The settlement price is according to IAmm.settlementPrice
     * @param _amm IAmm address
     */
    function settlePosition(IAmm _amm) external nonReentrant checkAccess {
        // check condition
        _requireAmm(_amm, false);
        address trader = _msgSender();
        Position memory pos = getPosition(_amm, trader);
        _requirePositionSize(pos.size);
        // update position
        _setPosition(
            _amm,
            trader,
            Position({ size: 0, margin: 0, openNotional: 0, lastUpdatedCumulativePremiumFraction: 0, blockNumber: _blockNumber() })
        );
        // calculate settledValue
        // If Settlement Price = 0, everyone takes back her collateral.
        // else Returned Fund = Position Size * (Settlement Price - Open Price) + Collateral
        uint256 settlementPrice = _amm.getSettlementPrice();
        uint256 settledValue;
        if (settlementPrice == 0 && pos.margin > 0) {
            settledValue = pos.margin.abs();
        } else {
            // returnedFund = positionSize * (settlementPrice - openPrice) + positionMargin
            // openPrice = positionOpenNotional / positionSize.abs()
            int256 returnedFund = pos.size.mulD(settlementPrice.toInt() - (pos.openNotional.divD(pos.size.abs())).toInt()) + pos.margin;
            // if `returnedFund` is negative, trader can't get anything back
            if (returnedFund > 0) {
                settledValue = returnedFund.abs();
            }
        }
        // transfer token based on settledValue. no insurance fund support
        if (settledValue > 0) {
            _withdraw(_amm, trader, settledValue);
            // _amm.quoteAsset().safeTransfer(trader, settledValue);
            //_transfer(_amm.quoteAsset(), trader, settledValue);
        }
        // emit event
        emit PositionSettled(address(_amm), trader, settledValue);
    }

    // if increase position
    //   marginToVault = addMargin
    //   marginDiff = realizedFundingPayment + realizedPnl(0)
    //   pos.margin += marginToVault + marginDiff
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if reduce position()
    //   marginToVault = 0
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginToVault + marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin), set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    //   required(enoughMarginRatio)
    // else if close
    //   marginDiff = realizedFundingPayment + realizedPnl
    //   pos.margin += marginDiff
    //   if pos.margin < 0, badDebt = abs(pos.margin)
    //   marginToVault = -pos.margin
    //   set pos.margin = 0
    //   vault.margin += marginToVault + marginDiff
    // else if close and open a larger position in reverse side
    //   close()
    //   positionNotional -= exchangedQuoteAssetAmount
    //   newMargin = positionNotional / leverage
    //   _increasePosition(newMargin, leverage)
    // else if liquidate
    //   close()
    //   pay liquidation fee to liquidator
    //   move the remain margin to insuranceFund

    /**
     * @notice open a position
     * @param _amm amm address
     * @param _side enum Side; BUY for long and SELL for short
     * @param _amount leveraged asset amount to be exact amount in 18 digits. Can Not be 0
     * @param _leverage leverage  in 18 digits. Can Not be 0
     * @param _oppositeAmountBound minimum or maxmum asset amount expected to get to prevent from slippage.
     * @param _isQuote if _assetAmount is quote asset, then true, otherwise false.
     */
    function openPosition(
        IAmm _amm,
        Side _side,
        uint256 _amount,
        uint256 _leverage,
        uint256 _oppositeAmountBound,
        bool _isQuote
    ) external whenNotPaused nonReentrant checkAccess {
        _requireAmm(_amm, true);
        _requireNonZeroInput(_amount);
        _requireNonZeroInput(_leverage);
        _requireMoreMarginRatio(int256(1 ether).divD(_leverage.toInt()), _amm.initMarginRatio(), true);
        _requireNotRestrictionMode(_amm);

        address trader = _msgSender();
        PositionResp memory positionResp;
        {
            // add scope for stack too deep error
            int256 oldPositionSize = getPosition(_amm, trader).size;
            bool isNewPosition = oldPositionSize == 0 ? true : false;

            // increase or decrease position depends on old position's side and size
            if (isNewPosition || (oldPositionSize > 0 ? Side.BUY : Side.SELL) == _side) {
                positionResp = _increasePosition(
                    InternalOpenPositionParams({
                        amm: _amm,
                        side: _side,
                        trader: trader,
                        amount: _amount,
                        leverage: _leverage,
                        isQuote: _isQuote,
                        canOverFluctuationLimit: false
                    })
                );
            } else {
                positionResp = _openReversePosition(
                    InternalOpenPositionParams({
                        amm: _amm,
                        side: _side,
                        trader: trader,
                        amount: _amount,
                        leverage: _leverage,
                        isQuote: _isQuote,
                        canOverFluctuationLimit: false
                    })
                );
            }

            _checkSlippage(
                _side,
                positionResp.exchangedQuoteAssetAmount,
                positionResp.exchangedPositionSize.abs(),
                _oppositeAmountBound,
                _isQuote
            );

            // update the position state
            _setPosition(_amm, trader, positionResp.position);
            // if opening the exact position size as the existing one == closePosition, can skip the margin ratio check
            if (positionResp.position.size != 0) {
                _requireMoreMarginRatio(getMarginRatio(_amm, trader), _amm.maintenanceMarginRatio(), true);
            }

            // to prevent attacker to leverage the bad debt to withdraw extra token from insurance fund
            require(positionResp.badDebt == 0, "CH_BDP"); //bad debt position

            // transfer the actual token between trader and vault
            if (positionResp.marginToVault > 0) {
                _deposit(_amm, trader, positionResp.marginToVault.abs());
            } else if (positionResp.marginToVault < 0) {
                _withdraw(_amm, trader, positionResp.marginToVault.abs());
            }
        }

        // transfer token for fees
        _transferFee(trader, _amm, positionResp.spreadFee, positionResp.tollFee);

        // emit event
        uint256 spotPrice = _amm.getSpotPrice();
        int256 fundingPayment = positionResp.fundingPayment; // pre-fetch for stack too deep error
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin,
            positionResp.exchangedQuoteAssetAmount,
            positionResp.exchangedPositionSize,
            positionResp.spreadFee + positionResp.tollFee,
            positionResp.position.size,
            positionResp.realizedPnl,
            positionResp.unrealizedPnlAfter,
            positionResp.badDebt,
            0,
            spotPrice,
            fundingPayment
        );
    }

    /**
     * @notice close all the positions
     * @param _amm IAmm address
     */
    function closePosition(IAmm _amm, uint256 _quoteAssetAmountLimit) external whenNotPaused nonReentrant checkAccess {
        // check conditions
        _requireAmm(_amm, true);
        _requireNotRestrictionMode(_amm);

        // update position
        address trader = _msgSender();

        PositionResp memory positionResp;
        {
            Position memory position = getPosition(_amm, trader);
            // // if it is long position, close a position means short it(which means base dir is ADD_TO_AMM) and vice versa
            // IAmm.Dir dirOfBase = position.size > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM;

            positionResp = _closePosition(_amm, trader, false);
            _checkSlippage(
                position.size > 0 ? Side.SELL : Side.BUY,
                positionResp.exchangedQuoteAssetAmount,
                positionResp.exchangedPositionSize.abs(),
                _quoteAssetAmountLimit,
                false
            );

            // to prevent attacker to leverage the bad debt to withdraw extra token from insurance fund
            require(positionResp.badDebt == 0, "CH_BDP"); //bad debt position

            _setPosition(_amm, trader, positionResp.position);

            // add scope for stack too deep error
            // transfer the actual token from trader and vault
            _withdraw(_amm, trader, positionResp.marginToVault.abs());
        }

        // transfer token for fees
        _transferFee(trader, _amm, positionResp.spreadFee, positionResp.tollFee);

        // prepare event
        uint256 spotPrice = _amm.getSpotPrice();
        int256 fundingPayment = positionResp.fundingPayment;
        emit PositionChanged(
            trader,
            address(_amm),
            positionResp.position.margin,
            positionResp.exchangedQuoteAssetAmount,
            positionResp.exchangedPositionSize,
            positionResp.spreadFee + positionResp.tollFee,
            positionResp.position.size,
            positionResp.realizedPnl,
            positionResp.unrealizedPnlAfter,
            positionResp.badDebt,
            0,
            spotPrice,
            fundingPayment
        );
    }

    function liquidateWithSlippage(
        IAmm _amm,
        address _trader,
        uint256 _quoteAssetAmountLimit
    ) external nonReentrant checkAccess returns (uint256 quoteAssetAmount, bool isPartialClose) {
        Position memory position = getPosition(_amm, _trader);
        (quoteAssetAmount, isPartialClose) = _liquidate(_amm, _trader);

        uint256 quoteAssetAmountLimit = isPartialClose
            ? _quoteAssetAmountLimit.mulD(_amm.partialLiquidationRatio())
            : _quoteAssetAmountLimit;

        _checkSlippage(position.size > 0 ? Side.SELL : Side.BUY, quoteAssetAmount, 0, quoteAssetAmountLimit, false);

        return (quoteAssetAmount, isPartialClose);
    }

    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @dev liquidator can NOT open any positions in the same block to prevent from price manipulation.
     * @param _amm IAmm address
     * @param _trader trader address
     */
    function liquidate(IAmm _amm, address _trader) external nonReentrant checkAccess {
        _liquidate(_amm, _trader);
    }

    /**
     * @notice if funding rate is positive, traders with long position pay traders with short position and vice versa.
     * @param _amm IAmm address
     */
    function payFunding(IAmm _amm) external checkAccess {
        _requireAmm(_amm, true);
        uint256 budget = insuranceFund.getAvailableBudgetFor(_amm);
        bool repegable;
        int256 repegCost;
        uint256 newQuoteAssetReserve;
        uint256 newBaseAssetReserve;
        int256 kRevenueWithRepeg; // k revenue after having done repeg
        int256 kRevenueWithoutRepeg; // k revenue without repeg

        // ------------------- funding payment ---------------------//
        int256 fundingPayment;
        {
            uint256 totalReserveForFunding = budget; // reserve allocated for the funding payment
            {
                (uint256 quoteAssetReserve, uint256 baseAssetReserve) = _amm.getReserve();
                kRevenueWithoutRepeg = _amm.getMaxKDecreaseRevenue(quoteAssetReserve, baseAssetReserve); // always positive
                totalReserveForFunding = budget + kRevenueWithoutRepeg.abs();

                // repegable is always true when repeg is needed because of max budget
                (repegable, repegCost, newQuoteAssetReserve, newBaseAssetReserve) = _amm.repegCheck(type(uint256).max);
                if (repegable) {
                    kRevenueWithRepeg = _amm.getMaxKDecreaseRevenue(newQuoteAssetReserve, newBaseAssetReserve);
                    if (kRevenueWithRepeg - repegCost > kRevenueWithoutRepeg) {
                        // in this case,
                        // if the funding payment is not enough with budget+kRevenueWithRepeg-cost, then it is also not enough without repeg, hence amm is shut down in all cases
                        // if it is enough, then repeg also will be done later, as a result have no budget error
                        totalReserveForFunding = budget + (kRevenueWithRepeg - repegCost).abs();
                    }
                    // in the other case where "kRevenueWithRepeg-cost <= kRevenueWithoutRepeg"
                    // if the funding payment is not enough with budget+kRevenueWithoutRepeg, then it is also not enough with repeg, hence amm is shut down in all cases
                    // if it is enough, then repeg is optional. if budget+kRevenueWithRepeg-fundingcost >= cost, repeg is done, otherwise repeg is not done
                }
            }

            int256 premiumFractionLong;
            int256 premiumFractionShort;
            // pay funding considering the revenue from k decreasing
            // if fundingPayment <= totalReserveForFunding, funding pay is done, otherwise amm is shut down and fundingPayment = 0
            (premiumFractionLong, premiumFractionShort, fundingPayment) = _amm.settleFunding(totalReserveForFunding);
            ammMap[address(_amm)].latestCumulativePremiumFractionLong = premiumFractionLong + getLatestCumulativePremiumFractionLong(_amm);
            ammMap[address(_amm)].latestCumulativePremiumFractionShort =
                premiumFractionShort +
                getLatestCumulativePremiumFractionShort(_amm);
        }

        // positive funding payment means profit, so reverse it
        int256 adjustmentCost = -1 * fundingPayment;
        // --------------------------------------------------------//

        // -------------------      repeg     ---------------------//
        // if amm was not shut down by funding pay and repeg is needed,
        // and the repeg cost is smaller than the "budget+kRevenueWithRepeg+fundingPayment", then repeg is done
        if (_amm.open() && repegable && (budget.toInt() + kRevenueWithRepeg + fundingPayment >= repegCost)) {
            _amm.adjust(newQuoteAssetReserve, newBaseAssetReserve);
            adjustmentCost += repegCost;
            emit Repeg(address(_amm), newQuoteAssetReserve, newBaseAssetReserve, repegCost);
        } else {
            repegable = false;
        }
        // --------------------------------------------------------//

        // -------------------    update K    ---------------------//
        {
            int256 budgetForUpdateK = netRevenuesSinceLastFunding[_amm] + fundingPayment - repegCost; // consider repegCost regardless whether it happens or not
            if (budgetForUpdateK > 0) {
                // if the overall sum is a REVENUE to the system, give back 25% of the REVENUE in k increase
                budgetForUpdateK = budgetForUpdateK / 4;
            } else {
                // if the overall sum is a COST to the system, take back half of the COST in k decrease
                budgetForUpdateK = budgetForUpdateK / 2;
            }
            bool isAdjustable;
            int256 kAdjustmentCost;
            (isAdjustable, kAdjustmentCost, newQuoteAssetReserve, newBaseAssetReserve) = _amm.getFormulaicUpdateKResult(budgetForUpdateK);
            // adjustmentCost + kAdjustmentCost should be smaller than insurance fund budget
            // otherwise do max decrease K
            if (adjustmentCost + kAdjustmentCost > budget.toInt()) {
                (isAdjustable, kAdjustmentCost, newQuoteAssetReserve, newBaseAssetReserve) = _amm.getFormulaicUpdateKResult(
                    repegable ? -kRevenueWithRepeg : -kRevenueWithoutRepeg
                );
            }
            if (isAdjustable) {
                _amm.adjust(newQuoteAssetReserve, newBaseAssetReserve);
                emit UpdateK(address(_amm), newQuoteAssetReserve, newBaseAssetReserve, kAdjustmentCost);
            }

            // apply all cost/revenue
            _applyAdjustmentCost(_amm, adjustmentCost + kAdjustmentCost);
        }
        // --------------------------------------------------------//

        // init netRevenuesSinceLastFunding for the next funding period's revenue
        netRevenuesSinceLastFunding[_amm] = 0;
        _enterRestrictionMode(_amm);
    }

    //
    // VIEW FUNCTIONS
    //

    /**
     * @notice get margin ratio, marginRatio = (margin + funding payment + unrealized Pnl) / positionNotional
     * use spot price to calculate unrealized Pnl and positionNotional when the price gap is not over the spread limit
     * use oracle price to calculate them when the price gap is over the spread limit
     * @param _amm IAmm address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader) public view returns (int256) {
        (bool isOverSpread, , ) = _amm.isOverSpread(LIQ_SWITCH_RATIO);
        if (isOverSpread) {
            return _getMarginRatioByCalcOption(_amm, _trader, PnlCalcOption.ORACLE);
        } else {
            return _getMarginRatioByCalcOption(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        }
    }

    /**
     * @notice get personal position information
     * @param _amm IAmm address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IAmm _amm, address _trader) public view returns (Position memory) {
        return ammMap[address(_amm)].positionMap[_trader];
    }

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _amm IAmm address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and TWAP for twap price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) public view returns (uint256 positionNotional, int256 unrealizedPnl) {
        Position memory position = getPosition(_amm, _trader);
        uint256 positionSizeAbs = position.size.abs();
        if (positionSizeAbs != 0) {
            bool isShortPosition = position.size < 0;
            IAmm.Dir dir = isShortPosition ? IAmm.Dir.REMOVE_FROM_AMM : IAmm.Dir.ADD_TO_AMM;
            if (_pnlCalcOption == PnlCalcOption.TWAP) {
                positionNotional = _amm.getBaseTwap(dir, positionSizeAbs);
            } else if (_pnlCalcOption == PnlCalcOption.SPOT_PRICE) {
                positionNotional = _amm.getBasePrice(dir, positionSizeAbs);
            } else {
                uint256 oraclePrice = _amm.getUnderlyingPrice();
                positionNotional = positionSizeAbs.mulD(oraclePrice);
            }
            // unrealizedPnlForLongPosition = positionNotional - openNotional
            // unrealizedPnlForShortPosition = positionNotionalWhenBorrowed - positionNotionalWhenReturned =
            // openNotional - positionNotional = unrealizedPnlForLongPosition * -1
            unrealizedPnl = isShortPosition
                ? position.openNotional.toInt() - positionNotional.toInt()
                : positionNotional.toInt() - position.openNotional.toInt();
        }
    }

    /**
     * @notice get latest cumulative premium fraction for long.
     * @param _amm IAmm address
     * @return latest cumulative premium fraction for long in 18 digits
     */
    function getLatestCumulativePremiumFractionLong(IAmm _amm) public view returns (int256 latest) {
        latest = ammMap[address(_amm)].latestCumulativePremiumFractionLong;
    }

    /**
     * @notice get latest cumulative premium fraction for short.
     * @param _amm IAmm address
     * @return latest cumulative premium fraction for short in 18 digits
     */
    function getLatestCumulativePremiumFractionShort(IAmm _amm) public view returns (int256 latest) {
        latest = ammMap[address(_amm)].latestCumulativePremiumFractionShort;
    }

    function getVaultFor(IAmm _amm) external view override returns (uint256 vault) {
        vault = vaults[_amm];
    }

    function _enterRestrictionMode(IAmm _amm) internal {
        uint256 blockNumber = _blockNumber();
        ammMap[address(_amm)].lastRestrictionBlock = blockNumber;
        emit RestrictionModeEntered(address(_amm), blockNumber);
    }

    function _setPosition(
        IAmm _amm,
        address _trader,
        Position memory _position
    ) internal {
        Position storage positionStorage = ammMap[address(_amm)].positionMap[_trader];
        positionStorage.size = _position.size;
        positionStorage.margin = _position.margin;
        positionStorage.openNotional = _position.openNotional;
        positionStorage.lastUpdatedCumulativePremiumFraction = _position.lastUpdatedCumulativePremiumFraction;
        positionStorage.blockNumber = _position.blockNumber;
    }

    function _liquidate(IAmm _amm, address _trader) internal returns (uint256 quoteAssetAmount, bool isPartialClose) {
        _requireAmm(_amm, true);
        _requireMoreMarginRatio(getMarginRatio(_amm, _trader), _amm.maintenanceMarginRatio(), false);

        PositionResp memory positionResp;
        uint256 liquidationPenalty;
        {
            uint256 liquidationBadDebt;
            uint256 feeToLiquidator;
            uint256 feeToInsuranceFund;

            int256 marginRatioBasedOnSpot = _getMarginRatioByCalcOption(_amm, _trader, PnlCalcOption.SPOT_PRICE);
            uint256 _partialLiquidationRatio = _amm.partialLiquidationRatio();
            uint256 _liquidationFeeRatio = _amm.liquidationFeeRatio();
            if (
                // check margin(based on spot price) is enough to pay the liquidation fee
                // after partially close, otherwise we fully close the position.
                // that also means we can ensure no bad debt happen when partially liquidate
                marginRatioBasedOnSpot > int256(_liquidationFeeRatio) && _partialLiquidationRatio < 1 ether && _partialLiquidationRatio != 0
            ) {
                Position memory position = getPosition(_amm, _trader);
                positionResp = _openReversePosition(
                    InternalOpenPositionParams({
                        amm: _amm,
                        side: position.size > 0 ? Side.SELL : Side.BUY,
                        trader: _trader,
                        amount: position.size.mulD(_partialLiquidationRatio.toInt()).abs(),
                        leverage: 1 ether,
                        isQuote: false,
                        canOverFluctuationLimit: true
                    })
                );

                // half of the liquidationFee goes to liquidator & another half goes to insurance fund
                liquidationPenalty = positionResp.exchangedQuoteAssetAmount.mulD(_liquidationFeeRatio);
                feeToLiquidator = liquidationPenalty / 2;
                feeToInsuranceFund = liquidationPenalty - feeToLiquidator;

                positionResp.position.margin = positionResp.position.margin - liquidationPenalty.toInt();
                _setPosition(_amm, _trader, positionResp.position);

                isPartialClose = true;
            } else {
                // liquidationPenalty = getPosition(_amm, _trader).margin.abs();
                positionResp = _closePosition(_amm, _trader, true);
                uint256 remainMargin = positionResp.marginToVault < 0 ? positionResp.marginToVault.abs() : 0;
                feeToLiquidator = positionResp.exchangedQuoteAssetAmount.mulD(_liquidationFeeRatio) / 2;

                // if the remainMargin is not enough for liquidationFee, count it as bad debt
                // else, then the rest will be transferred to insuranceFund
                liquidationBadDebt = positionResp.badDebt;
                if (feeToLiquidator > remainMargin) {
                    liquidationPenalty = feeToLiquidator;
                    liquidationBadDebt = liquidationBadDebt + feeToLiquidator - remainMargin;
                    remainMargin = 0;
                } else {
                    liquidationPenalty = remainMargin;
                    remainMargin = remainMargin - feeToLiquidator;
                }
                // transfer the actual token between trader and vault
                if (liquidationBadDebt > 0) {
                    require(backstopLiquidityProviderMap[_msgSender()], "CH_NBLP"); //not backstop LP
                    _realizeBadDebt(_amm, liquidationBadDebt);
                    // include liquidation bad debt into the k-adjustment calculation
                    netRevenuesSinceLastFunding[_amm] -= int256(liquidationBadDebt);
                }
                feeToInsuranceFund = remainMargin;
                _setPosition(_amm, _trader, positionResp.position);
            }

            _withdraw(_amm, _msgSender(), feeToLiquidator);

            if (feeToInsuranceFund > 0) {
                _transferToInsuranceFund(_amm, feeToInsuranceFund);
                // include liquidation fee to the insurance fund into the k-adjustment calculation
                netRevenuesSinceLastFunding[_amm] += int256(feeToInsuranceFund);
            }

            _enterRestrictionMode(_amm);

            emit PositionLiquidated(
                _trader,
                address(_amm),
                positionResp.exchangedQuoteAssetAmount,
                positionResp.exchangedPositionSize.toUint(),
                feeToLiquidator,
                feeToInsuranceFund,
                _msgSender(),
                liquidationBadDebt
            );
        }

        // emit event
        uint256 spotPrice = _amm.getSpotPrice();
        emit PositionChanged(
            _trader,
            address(_amm),
            positionResp.position.margin,
            positionResp.exchangedQuoteAssetAmount,
            positionResp.exchangedPositionSize,
            0,
            positionResp.position.size,
            positionResp.realizedPnl,
            positionResp.unrealizedPnlAfter,
            positionResp.badDebt,
            liquidationPenalty,
            spotPrice,
            positionResp.fundingPayment
        );

        return (positionResp.exchangedQuoteAssetAmount, isPartialClose);
    }

    // only called from openPosition and _closeAndOpenReversePosition. caller need to ensure there's enough marginRatio
    function _increasePosition(InternalOpenPositionParams memory params) internal returns (PositionResp memory positionResp) {
        Position memory oldPosition = getPosition(params.amm, params.trader);
        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(params.amm, params.trader, PnlCalcOption.SPOT_PRICE);
        (positionResp.exchangedQuoteAssetAmount, positionResp.exchangedPositionSize, positionResp.spreadFee, positionResp.tollFee) = params
            .amm
            .swapInput(
                params.isQuote == (params.side == Side.BUY) ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                params.amount,
                params.isQuote,
                params.canOverFluctuationLimit
            );

        int256 newSize = oldPosition.size + positionResp.exchangedPositionSize;

        int256 increaseMarginRequirement = positionResp.exchangedQuoteAssetAmount.divD(params.leverage).toInt();
        (
            int256 remainMargin,
            uint256 badDebt,
            int256 fundingPayment,
            int256 latestCumulativePremiumFraction
        ) = _calcRemainMarginWithFundingPayment(params.amm, oldPosition, increaseMarginRequirement, params.side == Side.BUY);

        // update positionResp
        positionResp.badDebt = badDebt;
        positionResp.unrealizedPnlAfter = unrealizedPnl;
        positionResp.marginToVault = increaseMarginRequirement;
        positionResp.fundingPayment = fundingPayment;
        positionResp.position = Position(
            newSize, //Number of base asset (e.g. BAYC)
            remainMargin,
            oldPosition.openNotional + positionResp.exchangedQuoteAssetAmount, //In Quote Asset (e.g. USDC)
            latestCumulativePremiumFraction,
            _blockNumber()
        );
    }

    function _openReversePosition(InternalOpenPositionParams memory params) internal returns (PositionResp memory) {
        (uint256 oldPositionNotional, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(
            params.amm,
            params.trader,
            PnlCalcOption.SPOT_PRICE
        );
        Position memory oldPosition = getPosition(params.amm, params.trader);
        PositionResp memory positionResp;

        // reduce position if old position is larger
        if (params.isQuote ? oldPositionNotional > params.amount : oldPosition.size.abs() > params.amount) {
            (
                positionResp.exchangedQuoteAssetAmount,
                positionResp.exchangedPositionSize,
                positionResp.spreadFee,
                positionResp.tollFee
            ) = params.amm.swapOutput(
                params.isQuote == (params.side == Side.BUY) ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                params.amount,
                params.isQuote,
                params.canOverFluctuationLimit
            );
            if (oldPosition.size != 0) {
                positionResp.realizedPnl = unrealizedPnl.mulD(positionResp.exchangedPositionSize.abs().toInt()).divD(
                    oldPosition.size.abs().toInt()
                );
            }
            int256 remainMargin;
            int256 latestCumulativePremiumFraction;
            (
                remainMargin,
                positionResp.badDebt,
                positionResp.fundingPayment,
                latestCumulativePremiumFraction
            ) = _calcRemainMarginWithFundingPayment(params.amm, oldPosition, positionResp.realizedPnl, oldPosition.size > 0);

            // positionResp.unrealizedPnlAfter = unrealizedPnl - realizedPnl
            positionResp.unrealizedPnlAfter = unrealizedPnl - positionResp.realizedPnl;

            // calculate openNotional (it's different depends on long or short side)
            // long: unrealizedPnl = positionNotional - openNotional => openNotional = positionNotional - unrealizedPnl
            // short: unrealizedPnl = openNotional - positionNotional => openNotional = positionNotional + unrealizedPnl
            // positionNotional = oldPositionNotional - exchangedQuoteAssetAmount
            int256 remainOpenNotional = oldPosition.size > 0
                ? oldPositionNotional.toInt() - positionResp.exchangedQuoteAssetAmount.toInt() - positionResp.unrealizedPnlAfter
                : positionResp.unrealizedPnlAfter + oldPositionNotional.toInt() - positionResp.exchangedQuoteAssetAmount.toInt();
            require(remainOpenNotional > 0, "CH_ONNP"); // open notional value is not positive

            positionResp.position = Position(
                oldPosition.size + positionResp.exchangedPositionSize,
                remainMargin,
                remainOpenNotional.abs(),
                latestCumulativePremiumFraction,
                _blockNumber()
            );
            return positionResp;
        }

        return _closeAndOpenReversePosition(params);
    }

    function _closeAndOpenReversePosition(InternalOpenPositionParams memory params) internal returns (PositionResp memory positionResp) {
        // new position size is larger than or equal to the old position size
        // so either close or close then open a larger position
        PositionResp memory closePositionResp = _closePosition(params.amm, params.trader, params.canOverFluctuationLimit);

        // the old position is underwater. trader should close a position first
        require(closePositionResp.badDebt == 0, "CH_BDP"); // bad debt position

        // update open notional after closing position
        uint256 amount = params.isQuote
            ? params.amount - closePositionResp.exchangedQuoteAssetAmount
            : params.amount - closePositionResp.exchangedPositionSize.abs();

        // if remain asset amount is too small (eg. 100 wei) then the required margin might be 0
        // then the clearingHouse will stop opening position
        if (amount <= 100 wei) {
            positionResp = closePositionResp;
        } else {
            _setPosition(params.amm, params.trader, closePositionResp.position);
            params.amount = amount;
            PositionResp memory increasePositionResp = _increasePosition(params);
            positionResp = PositionResp({
                position: increasePositionResp.position,
                exchangedQuoteAssetAmount: closePositionResp.exchangedQuoteAssetAmount + increasePositionResp.exchangedQuoteAssetAmount,
                badDebt: closePositionResp.badDebt + increasePositionResp.badDebt,
                fundingPayment: closePositionResp.fundingPayment + increasePositionResp.fundingPayment,
                exchangedPositionSize: closePositionResp.exchangedPositionSize + increasePositionResp.exchangedPositionSize,
                realizedPnl: closePositionResp.realizedPnl + increasePositionResp.realizedPnl,
                unrealizedPnlAfter: 0,
                marginToVault: closePositionResp.marginToVault + increasePositionResp.marginToVault,
                spreadFee: closePositionResp.spreadFee + increasePositionResp.spreadFee,
                tollFee: closePositionResp.tollFee + increasePositionResp.tollFee
            });
        }
        return positionResp;
    }

    function _closePosition(
        IAmm _amm,
        address _trader,
        bool _canOverFluctuationLimit
    ) internal returns (PositionResp memory positionResp) {
        // check conditions
        Position memory oldPosition = getPosition(_amm, _trader);
        _requirePositionSize(oldPosition.size);

        (, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE);
        (int256 remainMargin, uint256 badDebt, int256 fundingPayment, ) = _calcRemainMarginWithFundingPayment(
            _amm,
            oldPosition,
            unrealizedPnl,
            oldPosition.size > 0
        );

        positionResp.realizedPnl = unrealizedPnl;
        positionResp.badDebt = badDebt;
        positionResp.fundingPayment = fundingPayment;
        positionResp.marginToVault = remainMargin * -1;
        positionResp.position = Position({
            size: 0,
            margin: 0,
            openNotional: 0,
            lastUpdatedCumulativePremiumFraction: 0,
            blockNumber: _blockNumber()
        });

        (positionResp.exchangedQuoteAssetAmount, positionResp.exchangedPositionSize, positionResp.spreadFee, positionResp.tollFee) = _amm
            .swapOutput(
                oldPosition.size > 0 ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
                oldPosition.size.abs(),
                false,
                _canOverFluctuationLimit
            );
    }

    function _checkSlippage(
        Side _side,
        uint256 _quote,
        uint256 _base,
        uint256 _oppositeAmountBound,
        bool _isQuote
    ) internal pure {
        // skip when _oppositeAmountBound is zero
        if (_oppositeAmountBound == 0) {
            return;
        }
        // long + isQuote, want more output base as possible, so we set a lower bound of output base
        // short + isQuote, want less input base as possible, so we set a upper bound of input base
        // long + !isQuote, want less input quote as possible, so we set a upper bound of input quote
        // short + !isQuote, want more output quote as possible, so we set a lower bound of output quote
        if (_isQuote) {
            if (_side == Side.BUY) {
                // too little received when long
                require(_base >= _oppositeAmountBound, "CH_TLRL");
            } else {
                // too much requested when short
                require(_base <= _oppositeAmountBound, "CH_TMRS");
            }
        } else {
            if (_side == Side.BUY) {
                // too much requested when long
                require(_quote <= _oppositeAmountBound, "CH_TMRL");
            } else {
                // too little received when short
                require(_quote >= _oppositeAmountBound, "CH_TLRS");
            }
        }
    }

    function _transferFee(
        address _from,
        IAmm _amm,
        uint256 _spreadFee,
        uint256 _tollFee
    ) internal {
        IERC20 quoteAsset = _amm.quoteAsset();

        // transfer spread to market in order to use it to make market better
        if (_spreadFee > 0) {
            quoteAsset.safeTransferFrom(_from, address(this), _spreadFee);
            insuranceFund.deposit(_amm, _spreadFee);
            // consider fees in k-adjustment
            netRevenuesSinceLastFunding[_amm] += _spreadFee.toInt();
        }

        // transfer toll to tollPool
        if (_tollFee > 0) {
            _requireNonZeroAddress(address(tollPool));
            quoteAsset.safeTransferFrom(_from, address(tollPool), _tollFee);
        }
    }

    function _deposit(
        IAmm _amm,
        address _sender,
        uint256 _amount
    ) internal {
        vaults[_amm] += _amount;
        IERC20 quoteToken = _amm.quoteAsset();
        quoteToken.safeTransferFrom(_sender, address(this), _amount);
    }

    function _withdraw(
        IAmm _amm,
        address _receiver,
        uint256 _amount
    ) internal {
        // if withdraw amount is larger than the balance of given Amm's vault
        // means this trader's profit comes from other under collateral position's future loss
        // and the balance of given Amm's vault is not enough
        // need money from IInsuranceFund to pay first, and record this prepaidBadDebt
        // in this case, insurance fund loss must be zero
        uint256 vault = vaults[_amm];
        IERC20 quoteToken = _amm.quoteAsset();
        if (vault < _amount) {
            uint256 balanceShortage = _amount - vault;
            prepaidBadDebts[address(_amm)] += balanceShortage;
            _withdrawFromInsuranceFund(_amm, balanceShortage);
        }
        vaults[_amm] -= _amount;
        quoteToken.safeTransfer(_receiver, _amount);
    }

    function _realizeBadDebt(IAmm _amm, uint256 _badDebt) internal {
        uint256 badDebtBalance = prepaidBadDebts[address(_amm)];
        if (badDebtBalance >= _badDebt) {
            // no need to move extra tokens because vault already prepay bad debt, only need to update the numbers
            prepaidBadDebts[address(_amm)] = badDebtBalance - _badDebt;
        } else {
            // in order to realize all the bad debt vault need extra tokens from insuranceFund
            _withdrawFromInsuranceFund(_amm, _badDebt - badDebtBalance);
            prepaidBadDebts[address(_amm)] = 0;
        }
    }

    // withdraw fund from insurance fund to vault
    function _withdrawFromInsuranceFund(IAmm _amm, uint256 _amount) internal {
        vaults[_amm] += _amount;
        insuranceFund.withdraw(_amm, _amount);
    }

    // transfer fund from vault to insurance fund
    function _transferToInsuranceFund(IAmm _amm, uint256 _amount) internal {
        uint256 vault = vaults[_amm];
        if (vault < _amount) {
            _amount = vault;
        }
        vaults[_amm] = vault - _amount;
        insuranceFund.deposit(_amm, _amount);
    }

    /**
     * @notice apply cost for funding payment, repeg and k-adjustment
     * @dev negative cost is revenue, otherwise is expense of insurance fund
     */
    function _applyAdjustmentCost(IAmm _amm, int256 _cost) private {
        if (_cost > 0) {
            _withdrawFromInsuranceFund(_amm, _cost.abs());
        } else if (_cost < 0) {
            _transferToInsuranceFund(_amm, _cost.abs());
        }
    }

    //
    // INTERNAL VIEW FUNCTIONS
    //

    function _getMarginRatioByCalcOption(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    ) internal view returns (int256) {
        Position memory position = getPosition(_amm, _trader);
        _requirePositionSize(position.size);
        (uint256 positionNotional, int256 unrealizedPnl) = getPositionNotionalAndUnrealizedPnl(_amm, _trader, _pnlCalcOption);
        (int256 remainMargin, , , ) = _calcRemainMarginWithFundingPayment(_amm, position, unrealizedPnl, position.size > 0);
        return remainMargin.divD(positionNotional.toInt());
    }

    function _calcRemainMarginWithFundingPayment(
        IAmm _amm,
        Position memory _oldPosition,
        int256 _marginDelta,
        bool isLong
    )
        internal
        view
        returns (
            int256 remainMargin,
            uint256 badDebt,
            int256 fundingPayment,
            int256 latestCumulativePremiumFraction
        )
    {
        // calculate funding payment
        latestCumulativePremiumFraction = isLong
            ? getLatestCumulativePremiumFractionLong(_amm)
            : getLatestCumulativePremiumFractionShort(_amm);
        if (_oldPosition.size != 0) {
            fundingPayment = (latestCumulativePremiumFraction - _oldPosition.lastUpdatedCumulativePremiumFraction).mulD(_oldPosition.size);
        }

        // calculate remain margin
        remainMargin = _marginDelta - fundingPayment + _oldPosition.margin;

        // if remain margin is negative, consider it as bad debt
        if (remainMargin < 0) {
            badDebt = remainMargin.abs();
        }
    }

    /// @param _marginWithFundingPayment margin + funding payment - bad debt
    function _calcFreeCollateral(
        IAmm _amm,
        address _trader,
        int256 _marginWithFundingPayment
    ) internal view returns (int256) {
        Position memory pos = getPosition(_amm, _trader);
        (int256 unrealizedPnl, uint256 positionNotional) = _getPreferencePositionNotionalAndUnrealizedPnl(
            _amm,
            _trader,
            PnlPreferenceOption.MIN_PNL
        );

        // min(margin + funding, margin + funding + unrealized PnL) - position value * initMarginRatio
        int256 accountValue = unrealizedPnl + _marginWithFundingPayment;
        int256 minCollateral = unrealizedPnl > 0 ? _marginWithFundingPayment : accountValue;

        // margin requirement
        // if holding a long position, using open notional (mapping to quote debt in Curie)
        // if holding a short position, using position notional (mapping to base debt in Curie)
        int256 marginRequirement = pos.size > 0
            ? pos.openNotional.toInt().mulD(_amm.initMarginRatio().toInt())
            : positionNotional.toInt().mulD(_amm.initMarginRatio().toInt());

        return minCollateral - marginRequirement;
    }

    function _getPreferencePositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlPreferenceOption _pnlPreference
    ) internal view returns (int256 unrealizedPnl, uint256 positionNotional) {
        (uint256 spotPositionNotional, int256 spotPricePnl) = (
            getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.SPOT_PRICE)
        );

        (uint256 twapPositionNotional, int256 twapPricePnl) = (getPositionNotionalAndUnrealizedPnl(_amm, _trader, PnlCalcOption.TWAP));

        // if MAX_PNL
        //    spotPnL >  twapPnL return (spotPnL, spotPositionNotional)
        //    spotPnL <= twapPnL return (twapPnL, twapPositionNotional)
        // if MIN_PNL
        //    spotPnL >  twapPnL return (twapPnL, twapPositionNotional)
        //    spotPnL <= twapPnL return (spotPnL, spotPositionNotional)
        (unrealizedPnl, positionNotional) = (_pnlPreference == PnlPreferenceOption.MAX_PNL) == (spotPricePnl > twapPricePnl)
            ? (spotPricePnl, spotPositionNotional)
            : (twapPricePnl, twapPositionNotional);
    }

    //
    // REQUIRE FUNCTIONS
    //
    function _requireAmm(IAmm _amm, bool _open) private view {
        require(insuranceFund.isExistedAmm(_amm), "CH_ANF"); //vAMM not found
        require(_open == _amm.open(), _open ? "CH_AC" : "CH_AO"); //vAmm is closed, vAmm is opened
    }

    function _requireNonZeroInput(uint256 _input) private pure {
        require(_input != 0, "CH_ZI"); //zero input
    }

    function _requirePositionSize(int256 _size) private pure {
        require(_size != 0, "CH_ZP"); //zero position size
    }

    function _requireNotRestrictionMode(IAmm _amm) private view {
        uint256 currentBlock = _blockNumber();
        if (currentBlock == ammMap[address(_amm)].lastRestrictionBlock) {
            require(getPosition(_amm, _msgSender()).blockNumber != currentBlock, "CH_RM"); //restriction mode, only one action allowed
        }
    }

    function _requireMoreMarginRatio(
        int256 _marginRatio,
        uint256 _baseMarginRatio,
        bool _largerThanOrEqualTo
    ) private pure {
        int256 remainingMarginRatio = _marginRatio - _baseMarginRatio.toInt();
        require(_largerThanOrEqualTo ? remainingMarginRatio >= 0 : remainingMarginRatio < 0, "CH_MRNC"); //Margin ratio not meet criteria
    }

    function _requireRatio(uint256 _ratio) private pure {
        require(_ratio <= 1 ether, "CH_IR"); //invalid ratio
    }

    function _requireNonZeroAddress(address _input) private pure {
        require(_input != address(0), "CH_ZA");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeableSafe } from "./OwnableUpgradeableSafe.sol";

contract OwnerPausableUpgradeSafe is OwnableUpgradeableSafe, PausableUpgradeable {
    function __OwnerPausable_init() internal initializer {
        __Ownable_init();
        __Pausable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getQuotePrice, getBasePrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    function swapInput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        );

    function swapOutput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        );

    function repegCheck(uint256 budget)
        external
        returns (
            bool,
            int256,
            uint256,
            uint256
        );

    function adjust(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external;

    function shutdown() external;

    function settleFunding(uint256 _cap)
        external
        returns (
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment
        );

    function calcFee(uint256 _quoteAssetAmount) external view returns (uint256, uint256);

    //
    // VIEW
    //

    function getFormulaicUpdateKResult(int256 budget)
        external
        view
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        );

    function getMaxKDecreaseRevenue(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external view returns (int256 revenue);

    function isOverFluctuationLimit(Dir _dirOfBase, uint256 _baseAssetAmount) external view returns (bool);

    function getQuoteTwap(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getBaseTwap(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getQuotePrice(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getBasePrice(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getQuotePriceWithReserves(
        Dir _dir,
        uint256 _quoteAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getBasePriceWithReserves(
        Dir _dir,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getSpotPrice() external view returns (uint256);

    // overridden by state variable

    function initMarginRatio() external view returns (uint256);

    function maintenanceMarginRatio() external view returns (uint256);

    function liquidationFeeRatio() external view returns (uint256);

    function partialLiquidationRatio() external view returns (uint256);

    function quoteAsset() external view returns (IERC20);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function priceFeed() external view returns (IPriceFeed);

    function getReserve() external view returns (uint256, uint256);

    function open() external view returns (bool);

    function adjustable() external view returns (bool);

    function canLowerK() external view returns (bool);

    function ptcKIncreaseMax() external view returns (uint256);

    function ptcKDecreaseMax() external view returns (uint256);

    function getSettlementPrice() external view returns (uint256);

    function getCumulativeNotional() external view returns (int256);

    function getBaseAssetDelta() external view returns (int256);

    function getUnderlyingPrice() external view returns (uint256);

    function isOverSpreadLimit()
        external
        view
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        );

    function isOverSpread(uint256 _limit)
        external
        view
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        );

    function getFundingPaymentEstimation(uint256 _cap)
        external
        view
        returns (
            bool notPayable,
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment,
            uint256 underlyingPrice
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library IntMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    function toUint(int256 x) internal pure returns (uint256) {
        return uint256(abs(x));
    }

    function abs(int256 x) internal pure returns (uint256) {
        uint256 t = 0;
        if (x < 0) {
            t = uint256(0 - x);
        } else {
            t = uint256(x);
        }
        return t;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(int256 x, int256 y) internal pure returns (int256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        if (x * y < 0) {
            return int256(Math.mulDiv(abs(x), abs(y), 10**uint256(decimals))) * (-1);
        } else {
            return int256(Math.mulDiv(abs(x), abs(y), 10**uint256(decimals)));
        }
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(int256 x, int256 y) internal pure returns (int256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        if (x * y < 0) {
            return int256(Math.mulDiv(abs(x), 10**uint256(decimals), abs(y))) * (-1);
        } else {
            return int256(Math.mulDiv(abs(x), 10**uint256(decimals), abs(y)));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IAmm } from "./IAmm.sol";

interface IInsuranceFund {
    function withdraw(IAmm _amm, uint256 _amount) external;

    function deposit(IAmm _amm, uint256 _amount) external;

    function isExistedAmm(IAmm _amm) external view returns (bool);

    function getAllAmms() external view returns (IAmm[] memory);

    function getAvailableBudgetFor(IAmm _amm) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Implements simple fixed point math add, sub, mul and div operations.
library UIntMath {
    string private constant ERROR_NON_CONVERTIBLE = "Math: uint value is bigger than _INT256_MAX";

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require(uint256(type(int256).max) >= x, ERROR_NON_CONVERTIBLE);
        return int256(x);
    }

    // function modD(uint256 x, uint256 y) internal pure returns (uint256) {
    //     return (x * unit(18)) % y;
    // }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return Math.mulDiv(x, y, unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(uint256 x, uint256 y) internal pure returns (uint256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return Math.mulDiv(x, unit(decimals), y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultiTokenRewardRecipient {
    function notifyTokenAmount(IERC20 _token, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TH_STF"); // failed Safe Transfer From
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TH_ST"); // failed Safe Transfer
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TH_SA"); // failed Safe Approve
    }

    // /// @notice Transfers ETH to the recipient address
    // /// @dev Fails with `STE`
    // /// @param to The destination of the transfer
    // /// @param value The value to be transferred
    // function safeTransferETH(address to, uint256 value) internal {
    //     (bool success, ) = to.call{value: value}(new bytes(0));
    //     require(success, 'STE');
    // }
}

// SPDX-License-Identifier: BSD-3-CLAUSE
pragma solidity 0.8.9;

import { IAmm } from "./IAmm.sol";

interface IClearingHouse {
    enum Side {
        BUY,
        SELL
    }

    /// @notice This struct records personal position information
    /// @param size denominated in amm.baseAsset
    /// @param margin isolated margin
    /// @param openNotional the quoteAsset value of position when opening position. the cost of the position
    /// @param lastUpdatedCumulativePremiumFraction for calculating funding payment, record at the moment every time when trader open/reduce/close position
    /// @param blockNumber the block number of the last position
    struct Position {
        int256 size;
        int256 margin;
        uint256 openNotional;
        int256 lastUpdatedCumulativePremiumFraction;
        uint256 blockNumber;
    }

    function addMargin(IAmm _amm, uint256 _addedMargin) external;

    function removeMargin(IAmm _amm, uint256 _removedMargin) external;

    function settlePosition(IAmm _amm) external;

    function openPosition(
        IAmm _amm,
        Side _side,
        uint256 _amount,
        uint256 _leverage,
        uint256 _oppositeAmountLimit,
        bool _isQuote
    ) external;

    function closePosition(IAmm _amm, uint256 _quoteAssetAmountLimit) external;

    function liquidate(IAmm _amm, address _trader) external;

    function payFunding(IAmm _amm) external;

    // VIEW FUNCTIONS
    function getMarginRatio(IAmm _amm, address _trader) external view returns (int256);

    function getPosition(IAmm _amm, address _trader) external view returns (Position memory);

    function getVaultFor(IAmm _amm) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IntMath } from "./IntMath.sol";
import { UIntMath } from "./UIntMath.sol";

library AmmMath {
    using UIntMath for uint256;
    using IntMath for int256;

    struct BudgetedKScaleCalcParams {
        uint256 quoteAssetReserve;
        uint256 baseAssetReserve;
        int256 budget;
        int256 positionSize;
        uint256 ptcKIncreaseMax;
        uint256 ptcKDecreaseMax;
    }

    /**
     * @notice calculate reserves after repegging with preserving K
     * @dev https://docs.google.com/document/d/1JcKFCFY7vDxys0eWl0K1B3kQEEz-mrr7VU3-JPLPkkE/edit?usp=sharing
     */
    function calcReservesAfterRepeg(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        uint256 _targetPrice,
        int256 _positionSize
    ) internal pure returns (uint256 newQuoteAssetReserve, uint256 newBaseAssetReserve) {
        uint256 spotPrice = _quoteAssetReserve.divD(_baseAssetReserve);
        newQuoteAssetReserve = Math.mulDiv(_baseAssetReserve, Math.sqrt(spotPrice.mulD(_targetPrice)), 1e9);
        newBaseAssetReserve = Math.mulDiv(_baseAssetReserve, Math.sqrt(spotPrice.divD(_targetPrice)), 1e9);
        // in case net user position size is short and its absolute value is bigger than the expected base asset reserve
        if (_positionSize < 0 && newBaseAssetReserve <= _positionSize.abs()) {
            newQuoteAssetReserve = _baseAssetReserve.mulD(_targetPrice);
            newBaseAssetReserve = _baseAssetReserve;
        }
    }

    // function calcBudgetedQuoteReserve(
    //     uint256 _quoteAssetReserve,
    //     uint256 _baseAssetReserve,
    //     int256 _positionSize,
    //     uint256 _budget
    // ) internal pure returns (uint256 newQuoteAssetReserve) {
    //     newQuoteAssetReserve = _positionSize > 0
    //         ? _budget + _quoteAssetReserve + Math.mulDiv(_budget, _baseAssetReserve, _positionSize.abs())
    //         : _budget + _quoteAssetReserve - Math.mulDiv(_budget, _baseAssetReserve, _positionSize.abs());
    // }

    /**
     *@notice calculate the cost for adjusting the reserves
     *@dev
     *For #long>#short (d>0): cost = (y'-x'y'/(x'+d)) - (y-xy/(x+d)) = y'd/(x'+d) - yd/(x+d)
     *For #long<#short (d<0): cost = (xy/(x-|d|)-y) - (x'y'/(x'-|d|)-y') = y|d|/(x-|d|) - y'|d|/(x'-|d|)
     *@param _quoteAssetReserve y
     *@param _baseAssetReserve x
     *@param _positionSize d
     *@param _newQuoteAssetReserve y'
     *@param _newBaseAssetReserve x'
     */

    function calcCostForAdjustReserves(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        int256 _positionSize,
        uint256 _newQuoteAssetReserve,
        uint256 _newBaseAssetReserve
    ) internal pure returns (int256 cost) {
        if (_positionSize > 0) {
            cost =
                (Math.mulDiv(_newQuoteAssetReserve, uint256(_positionSize), (_newBaseAssetReserve + uint256(_positionSize)))).toInt() -
                (Math.mulDiv(_quoteAssetReserve, uint256(_positionSize), (_baseAssetReserve + uint256(_positionSize)))).toInt();
        } else {
            cost =
                (Math.mulDiv(_quoteAssetReserve, uint256(-_positionSize), (_baseAssetReserve - uint256(-_positionSize)), Math.Rounding.Up))
                    .toInt() -
                (
                    Math.mulDiv(
                        _newQuoteAssetReserve,
                        uint256(-_positionSize),
                        (_newBaseAssetReserve - uint256(-_positionSize)),
                        Math.Rounding.Up
                    )
                ).toInt();
        }
    }

    function calculateBudgetedKScale(BudgetedKScaleCalcParams memory params) internal pure returns (uint256, uint256) {
        if (params.positionSize == 0 && params.budget > 0) {
            return (params.ptcKIncreaseMax, 1 ether);
        } else if (params.positionSize == 0 && params.budget < 0) {
            return (params.ptcKDecreaseMax, 1 ether);
        }
        int256 numerator;
        int256 denominator;
        {
            int256 x = params.baseAssetReserve.toInt();
            int256 y = params.quoteAssetReserve.toInt();
            int256 x_d = x + params.positionSize;
            int256 num1 = y.mulD(params.positionSize).mulD(params.positionSize);
            int256 num2 = params.positionSize.mulD(x_d).mulD(params.budget);
            int256 denom2 = x.mulD(x_d).mulD(params.budget);
            int256 denom1 = num1;
            numerator = num1 + num2;
            denominator = denom1 - denom2;
        }
        if (params.budget > 0 && denominator < 0) {
            return (params.ptcKIncreaseMax, 1 ether);
        } else if (params.budget < 0 && numerator < 0) {
            return (params.ptcKDecreaseMax, 1 ether);
        }
        // if (numerator > 0 != denominator > 0 || denominator == 0 || numerator == 0) {
        //     return (_budget > 0 ? params.ptcKIncreaseMax : params.ptcKDecreaseMax, 1 ether);
        // }
        uint256 absNum = numerator.abs();
        uint256 absDen = denominator.abs();
        if (absNum > absDen) {
            uint256 curChange = absNum.divD(absDen);
            uint256 maxChange = params.ptcKIncreaseMax.divD(1 ether);
            if (curChange > maxChange) {
                return (params.ptcKIncreaseMax, 1 ether);
            } else {
                return (absNum, absDen);
            }
        } else {
            uint256 curChange = absNum.divD(absDen);
            uint256 maxChange = params.ptcKDecreaseMax.divD(1 ether);
            if (curChange < maxChange) {
                return (params.ptcKDecreaseMax, 1 ether);
            } else {
                return (absNum, absDen);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInsuranceFundCallee {
    function depositCallback(IERC20 _token, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IWhitelistMaster {
    function addToWhitelist(address[] memory _addresses) external;

    function removeFromWhitelist(address[] memory _addresses) external;

    function isWhitelisted(address _address) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OwnableUpgradeableSafe is OwnableUpgradeable {
    function renounceOwnership() public view override onlyOwner {
        revert("OS_NR"); // not able to renounce
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;

    function decimals(bytes32 _priceFeedKey) external view returns (uint8);
}