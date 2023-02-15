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
import { SignedDecimal } from "../utils/SignedDecimal.sol";
import { IAmm } from "./IAmm.sol";
import { IDelegateApproval } from "./IDelegateApproval.sol";

interface IClearingHouse {
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

    //
    // EXTERNAL
    //

    function delegateApproval() external view returns(IDelegateApproval);

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
    ) external;

    function openPositionFor(
        IAmm _amm,
        Side _side,
        Decimal.decimal memory _quoteAssetAmount,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _baseAssetAmountLimit,
        address _trader
    ) external;

    /**
     * @notice close position
     * @param _amm amm address
     * @param _quoteAssetAmountLimit quote asset amount limit in 18 digits (slippage). 0 for any slippage
     */
    function closePosition(IAmm _amm, Decimal.decimal memory _quoteAssetAmountLimit)
        external;

    function closePositionFor(IAmm _amm, Decimal.decimal memory _quoteAssetAmountLimit, address _trader)
        external;


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
    ) external;

    function partialCloseFor(
        IAmm _amm,
        Decimal.decimal memory _partialCloseRatio,
        Decimal.decimal memory _quoteAssetAmountLimit,
        address _trader
    ) external;

    /**
     * @notice add margin to increase margin ratio
     * @param _amm amm address
     * @param _addedMargin added margin in 18 digits
     */
    function addMargin(IAmm _amm, Decimal.decimal calldata _addedMargin)
        external;
    
    function addMarginFor(IAmm _amm, Decimal.decimal calldata _addedMargin, address _trader)
        external;
       
    /**
     * @notice remove margin to decrease margin ratio
     * @param _amm amm address
     * @param _removedMargin removed margin in 18 digits
     */
    function removeMargin(IAmm _amm, Decimal.decimal calldata _removedMargin)
        external;

    function removeMarginFor(IAmm _amm, Decimal.decimal calldata _removedMargin, address _trader)
        external;
        
    /**
     * @notice liquidate trader's underwater position. Require trader's margin ratio less than maintenance margin ratio
     * @param _amm amm address
     * @param _trader trader address
     */
    function liquidate(IAmm _amm, address _trader) external;

    /**
     * @notice settle funding payment
     * @dev dynamic funding mechanism refer (https://nftperp.notion.site/Technical-Stuff-8e4cb30f08b94aa2a576097a5008df24)
     * @param _amm amm address
     */
    function settleFunding(IAmm _amm) external;

  
    //
    // PUBLIC
    //

    /**
     * @notice get personal position information
     * @param _amm IAmm address
     * @param _trader trader address
     * @return struct Position
     */
    function getPosition(IAmm _amm, address _trader) external view returns (Position memory);

    /**
     * @notice get margin ratio, marginRatio = (margin + funding payment + unrealized Pnl) / positionNotional
     * @param _amm amm address
     * @param _trader trader address
     * @return margin ratio in 18 digits
     */
    function getMarginRatio(IAmm _amm, address _trader)
        external
        view
        returns (SignedDecimal.signedDecimal memory);

    /**
     * @notice get position notional and unrealized Pnl without fee expense and funding payment
     * @param _amm amm address
     * @param _trader trader address
     * @param _pnlCalcOption enum PnlCalcOption, SPOT_PRICE for spot price and ORACLE for oracle price
     * @return positionNotional position notional
     * @return unrealizedPnl unrealized Pnl
     */
    // unrealizedPnlForLongPosition = positionNotional - openNotional
    // unrealizedPnlForShortPosition = positionNotionalWhenBorrowed - positionNotionalWhenReturned =
    // openNotional - positionNotional = unrealizedPnlForLongPosition * -1
    function getPositionNotionalAndUnrealizedPnl(
        IAmm _amm,
        address _trader,
        PnlCalcOption _pnlCalcOption
    )
        external
        view
        returns (
            Decimal.decimal memory positionNotional,
            SignedDecimal.signedDecimal memory unrealizedPnl
        );

    /**
     * @notice get latest cumulative premium fraction.
     * @param _amm IAmm address
     * @return latestCumulativePremiumFractionLong cumulative premium fraction long
     * @return latestCumulativePremiumFractionShort cumulative premium fraction short
     */
    function getLatestCumulativePremiumFraction(IAmm _amm)
        external
        view
        returns (
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionLong,
            SignedDecimal.signedDecimal memory latestCumulativePremiumFractionShort
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
pragma abicoder v2;

interface IDelegateApproval {
    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be approved
    event DelegationApproved(address indexed trader, address delegate, uint8 actions);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be revoked
    event DelegationRevoked(address indexed trader, address delegate, uint8 actions);

    /// @param delegate The address of delegate
    /// @param actions The actions to be approved
    function approve(address delegate, uint8 actions) external;

    /// @param delegate The address of delegate
    /// @param actions The actions to be revoked
    function revoke(address delegate, uint8 actions) external;

    /// @return action The value of action `_CLEARINGHOUSE_OPENPOSITION`
    function getClearingHouseOpenPositionAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_CLOSEPOSITION`
    function getClearingHouseClosePositionAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_ADDMARGIN`
    function getClearingHouseAddMarginAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_REMOVEMARGIN`
    function getClearingHouseRemoveMarginAction() external pure returns (uint8);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return actions The approved actions
    function getApprovedActions(address trader, address delegate) external view returns (uint8);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be checked
    /// @return true if delegate is allowed to perform **each** actions for trader, otherwise false
    function hasApprovalFor(
        address trader,
        address delegate,
        uint8 actions
    ) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can open position for trader, otherwise false
    function canOpenPositionFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can close position for trader, otherwise false
    function canClosePositionFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can add margin for trader, otherwise false
    function canAddMarginFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can remove margin for trader, otherwise false
    function canRemoveMarginFor(address trader, address delegate) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import { Decimal } from "../utils/Decimal.sol";
import { SignedDecimal } from "../utils/SignedDecimal.sol";
import { IAmm } from "./IAmm.sol";
import "../utils/Structs.sol";

interface INFTPerpOrder {
    event OrderCreated(bytes32 indexed orderHash, bytes orderDetails);
    event OrderFulfilled(bytes32 indexed orderhash);
    event FailedToFulfill(bytes reason);
    event SetManagementFee(uint256 _fee);
    event OrderCancelled(bytes32 indexed orderHash);

    function createOrder(
        IAmm _amm,
        Structs.OrderType _orderType, 
        uint64 _expirationTimestamp,
        uint256 _triggerPrice,
        Decimal.decimal memory _slippage,
        Decimal.decimal memory _leverage,
        Decimal.decimal memory _quoteAssetAmount
    ) external payable returns(bytes32);

    function fulfillOrder(bytes32 _orderHash) external;

    function cancelOrder(bytes32 _orderHash) external;

    function hasEnoughAllowances(bytes32[] memory _orders) external returns(bool[] memory);

    function canFulfillOrder(bytes32 _orderhash) external view returns(bool);

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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IClearingHouse.sol";
import "../interfaces/INFTPerpOrder.sol";
import "./Decimal.sol";
import "./SignedDecimal.sol";
import "./Structs.sol";

library LibOrder {
    using Decimal for Decimal.decimal;
    using SignedDecimal for SignedDecimal.signedDecimal;

    struct CanExec {
        // is expired
        bool ts;
        // is price trigger met
        bool pr;
        // is account's position delegated and does account have enough allowance
        bool ha;
        // is position open
        bool op;
    }

    // Execute open order
    function fulfillOrder(Structs.Order memory orderStruct, IClearingHouse clearingHouse) internal {
        (Structs.OrderType orderType, address account,) = getOrderDetails(orderStruct);

        Decimal.decimal memory quoteAssetAmount = orderStruct.position.quoteAssetAmount;
        Decimal.decimal memory slippage = orderStruct.position.slippage;
        IAmm _amm = orderStruct.position.amm;
        
        if(orderType == Structs.OrderType.BUY_SLO || orderType == Structs.OrderType.SELL_SLO){
            // calculate current notional amount of user's position
            // - if notional amount gt initial quoteAsset amount set partially close position
            // - else close entire positon
            Decimal.decimal memory positionNotional = getPositionNotional(_amm, account, clearingHouse);
            if(positionNotional.d > quoteAssetAmount.d){
                // partially close position
                clearingHouse.partialCloseFor(
                    _amm, 
                    quoteAssetAmount.divD(positionNotional), 
                    slippage, 
                    account
                );
            } else {
                // fully close position
                clearingHouse.closePositionFor(
                    _amm, 
                    slippage, 
                    account
                );
            } 
        } else {
            IClearingHouse.Side side = orderType == Structs.OrderType.BUY_LO ? IClearingHouse.Side.BUY : IClearingHouse.Side.SELL;
            // execute Limit Order(open position)
            clearingHouse.openPositionFor(
                _amm, 
                side, 
                quoteAssetAmount, 
                orderStruct.position.leverage, 
                slippage, 
                account
            );
        }
    }

    function isAccountOwner(Structs.Order memory orderStruct) public view returns(bool){
        (, address account ,) = getOrderDetails(orderStruct);
        return msg.sender == account;
    }

    function canFulfillOrder(Structs.Order memory orderStruct, IClearingHouse clearingHouse) public view returns(bool){
        (Structs.OrderType orderType, address account , uint64 expiry) = getOrderDetails(orderStruct);
        CanExec memory canExec;
        // should be markprice
        uint256 _markPrice = orderStruct.position.amm.getMarkPrice().toUint();
        // order has not expired
        canExec.ts = expiry == 0 || block.timestamp < expiry;
        // position size
        int256 positionSize = getPositionSize(orderStruct.position.amm, account, clearingHouse);
        //how to check if a position is open?
        canExec.op = positionSize != 0;

        canExec.ha = hasEnoughAllowance(
                orderStruct,
                clearingHouse
            );

        if(orderType == Structs.OrderType.BUY_SLO || orderType == Structs.OrderType.SELL_SLO){
            canExec.pr = orderType == Structs.OrderType.BUY_SLO 
                    ? _markPrice >= orderStruct.trigger
                    : _markPrice <= orderStruct.trigger;
        } else {
            canExec.op = true;
            canExec.pr = orderType == Structs.OrderType.BUY_LO 
                    ? _markPrice <= orderStruct.trigger
                    : _markPrice >= orderStruct.trigger;
        }

        return canExec.ts && canExec.pr && canExec.op && canExec.ha;
    }

    function hasEnoughAllowance(
        Structs.Order memory orderStruct,
        IClearingHouse clearingHouse
    ) internal view returns(bool){
        (Structs.OrderType orderType, address account, ) = getOrderDetails(orderStruct);

        bool isSLO = orderType == Structs.OrderType.BUY_SLO || orderType == Structs.OrderType.SELL_SLO ? true : false;

        // is position delegated
        bool isd = isSLO ? clearingHouse.delegateApproval().canClosePositionFor(account, address(this))
                         : clearingHouse.delegateApproval().canClosePositionFor(account, address(this)); 

        IClearingHouse.Side _side;
        if(isSLO){
            if(getPositionSize(orderStruct.position.amm, account, clearingHouse) > 0){
                _side = IClearingHouse.Side.SELL;
            } else {
                _side = IClearingHouse.Side.BUY;
            }
        } else {
            if(orderType == Structs.OrderType.BUY_LO){
                _side = IClearingHouse.Side.BUY;
            } else {
                _side = IClearingHouse.Side.SELL;
            }
        }

        uint256 fees = calculateFees(
            orderStruct.position.amm, 
            isSLO ? getPositionNotional(orderStruct.position.amm, account, clearingHouse)
                  : orderStruct.position.quoteAssetAmount.mulD(orderStruct.position.leverage),
            _side, 
            isSLO ? false : true
        ).toUint();

        uint256 _qAssetAmt = isSLO ? 0 : orderStruct.position.quoteAssetAmount.toUint();
        
        uint256 balance = getAccountBalance(orderStruct.position.amm.quoteAsset(), account);
        uint256 chApproval = getAllowanceCH(orderStruct.position.amm.quoteAsset(), account, clearingHouse);
        return balance >= _qAssetAmt + fees  && chApproval >= _qAssetAmt + fees && isd;
    }


    ///@dev Get user's position size
    function getPositionSize(IAmm amm, address account, IClearingHouse clearingHouse) public view returns(int256){
         return clearingHouse.getPosition(amm, account).size.toInt();
    }

    ///@dev Get User's positon notional amount
    function getPositionNotional(IAmm amm, address account, IClearingHouse clearingHouse) public view returns(Decimal.decimal memory){
         return clearingHouse.getPosition(amm, account).openNotional;
    }

    function getPositionMargin(IAmm amm, address account, IClearingHouse clearingHouse) public view returns(Decimal.decimal memory){
        return clearingHouse.getPosition(amm, account).margin;
    }
    
    ///@dev Get Order Info/Details
    function getOrderDetails(
        Structs.Order memory orderStruct
    ) public pure returns(Structs.OrderType, address, uint64){
        //Todo: make more efficient
        return (
            Structs.OrderType(uint8(orderStruct.detail >> 248)),
            address(uint160(orderStruct.detail << 32 >> 96)),
            uint64(orderStruct.detail << 192 >> 192)
        );  
    }

    function getAllowanceCH(IERC20 token, address account, IClearingHouse clearingHouse) internal view returns(uint256){
        return token.allowance(account, address(clearingHouse));
    }

    function getAccountBalance(IERC20 token, address account) internal view returns(uint256){
        return token.balanceOf(account);
    }

    function calculateFees(
        IAmm _amm,
        Decimal.decimal memory _positionNotional,
        IClearingHouse.Side _side,
        bool _isOpenPos
    ) internal view returns (Decimal.decimal memory fees) {
        fees = _amm.calcFee(
            _side == IClearingHouse.Side.BUY ? IAmm.Dir.ADD_TO_AMM : IAmm.Dir.REMOVE_FROM_AMM,
            _positionNotional,
            _isOpenPos
        );
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
pragma solidity ^0.8.13;
import "../interfaces/IAmm.sol";
import "./Decimal.sol";

library Structs {
    enum OrderType {
        SELL_LO, 
        BUY_LO, 
        SELL_SLO,
        BUY_SLO
    }

    struct Position {
        IAmm amm;
        Decimal.decimal quoteAssetAmount;
        Decimal.decimal slippage;
        Decimal.decimal leverage;
    }

    struct Order {
        // ordertype, account, expirationTimestamp
        uint256 detail;
        uint256 trigger;
        Position position;
    }
}