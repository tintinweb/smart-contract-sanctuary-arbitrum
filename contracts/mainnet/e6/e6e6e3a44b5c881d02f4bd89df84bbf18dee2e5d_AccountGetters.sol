// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2PriceTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    GmxMarketGetters
} from "../../../strategies/gmxFrf/libraries/GmxMarketGetters.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2OrderTypes
} from "../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2MarketTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";
import { IMarketConfiguration } from "../interfaces/IMarketConfiguration.sol";
import { PercentMath } from "../../../libraries/PercentMath.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import { OrderStoreUtils } from "../../../lib/gmx/order/OrderStoreUtils.sol";
import { Pricing } from "../libraries/Pricing.sol";
import { DeltaConvergenceMath } from "../libraries/DeltaConvergenceMath.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import { Order } from "../../../lib/gmx/order/Order.sol";
import { GmxStorageGetters } from "./GmxStorageGetters.sol";

/**
 * @title AccountGetters
 * @author GoldLink
 *
 * @dev Manages all orders that flow through this account. This includes order execution,
 * cancellation, and freezing. This is required because the
 */
library AccountGetters {
    using PercentMath for uint256;
    using Order for IGmxV2OrderTypes.Props;

    // ============ External Functions ============

    /**
     * @notice Get the total value of the account in terms of USDC.
     * @param manager             The configuration manager for the strategy.
     * @param account             The account to get the value of
     * @return strategyAssetValue The value of a position in terms of USDC.
     */
    function getAccountValueUsdc(
        IGmxFrfStrategyManager manager,
        address account
    ) external view returns (uint256 strategyAssetValue) {
        // First we get the value in USD, since our oracles are priced in USD. Then
        // we can use the USDC oracle price to get the value in USDC.
        uint256 valueUSD = 0;

        // Add the value of ERC-20 tokens held by this account. We do not count native tokens
        // since this can be misleading in cases where liquidators are paying an execution fee.
        valueUSD += _getAccountTokenValueUSD(manager, account);
        // Get the value of all positions that currently exist.
        valueUSD += getAccountPositionsValueUSD(manager, account);
        // Get the values of the orders that are currently active. This only applies to increase orders,
        // because the value of decreases orders is reflected in the position.
        valueUSD += getAccountOrdersValueUSD(manager, account);
        // Get the value of all settled funding fees.
        valueUSD += getSettledFundingFeesValueUSD(manager, account);

        // Since the strategy asset is USDC, return the value of these assets in terms of USDC. This converts from USD -> USDC.
        // This is neccesary for borrower accounting to function properly, as the bank is unware of GMX-specific USD.
        return
            Pricing.getTokenAmountForUSD(
                manager,
                address(manager.USDC()),
                valueUSD
            );
    }

    /**
     * @notice Implements is liquidation finished, validating:
     * 1. There are no pending orders for the account.
     * 2. There are no open positions for the account.
     * 3. There are no unclaimed funding fees for the acocunt.
     * 4. The long token balance of this account is below the dust threshold for the market.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account to check whether the liquidation is finished.
     * @return finished If the liquidation is finished and the `StrategyBank` can now execute
     * the liquidation, returning funds to lenders.
     */
    function isLiquidationFinished(
        IGmxFrfStrategyManager manager,
        address account
    ) external view returns (bool) {
        IGmxV2DataStore dataStore = manager.gmxV2DataStore();

        {
            // Check to make sure there are zero pending orders. This is important in the event that the borrower had an active order, and before
            // the keeper finishes executed the order, a liquidation was both initiated and processed.
            uint256 orderCount = OrderStoreUtils.getAccountOrderCount(
                dataStore,
                account
            );
            if (orderCount != 0) {
                return false;
            }
        }

        // All positions must be liquidated before the liquidation is finished. If an account is allowed to repay its debts while still having active positions,
        // then lenders may not recieve all of their funds back.
        uint256 positionCount = PositionStoreUtils.getAccountPositionCount(
            dataStore,
            account
        );
        if (positionCount != 0) {
            return false;
        }

        // Get all available markets to check funding fees for.
        address[] memory markets = manager.getAvailableMarkets();

        uint256 marketsLength = markets.length;
        for (uint256 i = 0; i < marketsLength; ++i) {
            (address shortToken, address longToken) = GmxMarketGetters
                .getMarketTokens(dataStore, markets[i]);

            // If there are unclaimed short tokens that are owed to the account, these must be claimed as they can directly be paid back to lenders
            // and therefore must be accounted for in the liquidation process. The `minimumSwapRebalanceSize` is not used here because external actors cannot
            // force unclaimed funding fees to be non zero.
            uint256 unclaimedShortTokens = GmxStorageGetters
                .getClaimableFundingFees(
                    dataStore,
                    markets[i],
                    shortToken,
                    account
                );
            if (unclaimedShortTokens != 0) {
                return false;
            }

            uint256 unclaimedLongTokens = GmxStorageGetters
                .getClaimableFundingFees(
                    dataStore,
                    markets[i],
                    longToken,
                    account
                );

            IMarketConfiguration.UnwindParameters memory unwindConfig = manager
                .getMarketUnwindConfiguration(markets[i]);

            // It would be possible to prevent liquidation by continuously sending tokens to the account, so we use the configured "dust threshold" to
            // determine if the tokens held by the account have any meaningful value. The two are combined because otherwise this may result in forcing a liquidator
            // to claim funding fees, just to have the `minSwapRebalanceSize` check to pass.
            if (
                IERC20(longToken).balanceOf(account) + unclaimedLongTokens >=
                unwindConfig.minSwapRebalanceSize
            ) {
                return false;
            }
        }

        // Since there are no remaining positions, no remaining orders,  and the token balances of the account + unclaimed funding fees
        // are below the minimum swap rebalance size, the liquidation is finished.
        return true;
    }

    // ============ Public Functions ============

    /**
     * @notice Get account orders value USD, the USD value of all account orders. The value of an order only relates to the actual assets associated with it, not
     * the size of the order itself. This implies the only orders that have a value > 0 are increase orders, because the initial collateral is locked into the order.
     * Decrease orders have zero value because the value they produce is accounted for in the position pnl/collateral value.
     * @param manager     The configuration manager for the strategy.
     * @param account     The account to get the orders value for.
     * @return totalValue The USD value of all account orders.
     */
    function getAccountOrdersValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) public view returns (uint256 totalValue) {
        // Get the keys of all account orders.
        bytes32[] memory accountOrderKeys = OrderStoreUtils.getAccountOrderKeys(
            manager.gmxV2DataStore(),
            account
        );

        // Iterate through all account orders and sum `totalValue`.
        uint256 accountOrderKeysLength = accountOrderKeys.length;
        for (uint256 i = 0; i < accountOrderKeysLength; ++i) {
            totalValue += getOrderValueUSD(manager, accountOrderKeys[i]);
        }

        return totalValue;
    }

    /**
     * @notice Get the order associated with `orderId` 's value in terms of USD. The value of any non-increase order is 0, and the value of an increase order is simply the value
     * of the initial collateral.
     * @param manager        The configuration manager for the strategy.
     * @param orderId        The id of the order to get the value of in USD.
     * @return orderValueUSD The value of the order in USD.
     */
    function getOrderValueUSD(
        IGmxFrfStrategyManager manager,
        bytes32 orderId
    ) public view returns (uint256 orderValueUSD) {
        IGmxV2DataStore dataStore = manager.gmxV2DataStore();

        IGmxV2OrderTypes.Props memory order = OrderStoreUtils.get(
            dataStore,
            orderId
        );

        // If an increase order exists and has not yet been executed, include the value in the account's value,
        // since the order will contain a portion of the USDC that the account is entitled to. Otherwise, the value of the order
        // is 0.
        if (order.orderType() != IGmxV2OrderTypes.OrderType.MarketIncrease) {
            return 0;
        }

        // If an order exists and has not yet been executed, the best we can do to get the value of
        // the order is to get the value of the initial collateral.
        return
            Pricing.getTokenValueUSD(
                manager,
                order.addresses.initialCollateralToken,
                order.numbers.initialCollateralDeltaAmount
            );
    }

    /**
     * @notice Get the value of all positions in USD for an account.
     * @param manager     The configuration manager for the strategy.
     * @param account     The account of to value positions for.
     * @return totalValue The value of all positions in USD for this account.
     */
    function getAccountPositionsValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) public view returns (uint256 totalValue) {
        // Get all possible markets this account can have a position in.
        address[] memory availableMarkets = manager.getAvailableMarkets();

        // Iterate over all positions for this account and add value of each position.
        uint256 availableMarketsLength = availableMarkets.length;
        for (uint256 i = 0; i < availableMarketsLength; ++i) {
            totalValue += getPositionValue(
                manager,
                account,
                availableMarkets[i]
            );
        }

        return totalValue;
    }

    /**
     * @notice Get the value of a position in USD.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account the get the position in `market`'s value for.
     * @param market    The market to get the value of the position for.
     * @return valueUSD The value of the position in USD.
     */
    function getPositionValue(
        IGmxFrfStrategyManager manager,
        address account,
        address market
    ) public view returns (uint256 valueUSD) {
        return
            DeltaConvergenceMath.getPositionValueUSD(manager, account, market);
    }

    /**
     * @notice Get the value of all account claims in terms of USD. This calculates the value of all unclaimed, settled funding fees for the account.
     * This method does NOT include the value of collateral claims, as collateral claims cannot be indexed on chain.
     * @param manager   The configuration manager for the strategy.
     * @param account   The account to get the claimable funding fees value for.
     * @return valueUSD The value of all funding fees in USD for the account.
     */
    function getSettledFundingFeesValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) public view returns (uint256 valueUSD) {
        address[] memory availableMarkets = manager.getAvailableMarkets();
        IGmxV2DataStore dataStore = manager.gmxV2DataStore();

        // Iterate through all available markets and sum claimable fees.
        // If there is no position, `valueUSD` will be zero.
        uint256 availableMarketsLength = availableMarkets.length;
        for (uint256 i = 0; i < availableMarketsLength; ++i) {
            address market = availableMarkets[i];

            (address shortToken, address longToken) = GmxMarketGetters
                .getMarketTokens(dataStore, market);

            // This returns the total of the unclaimed, settled funding fees. These are positive funding fees that are accrued when a position is decreased.
            // It is important to note that these are only a subset of the position's total funding fees, as there exist unclaimed fees that must also be
            // accounted for within the position.
            (
                uint256 shortFeesClaimable,
                uint256 longFeesClaimable
            ) = getSettledFundingFees(
                    dataStore,
                    account,
                    availableMarkets[i],
                    shortToken,
                    longToken
                );

            // Short and long funding fees earned by the position are not claimable until they
            // are settled. Settlement occurs when the position size is decreased, which can occur in
            // `executeDecreasePosition`, `executeSettleFundingFees`, `executeLiquidatePosition`, `executeReleveragePosition`,
            // and `executeRebalancePosition`. Settlement is triggered any time the position size is decreased.  Once fees are settled,
            // they can be claimed by the account immediately and do not require keeper execution.
            valueUSD += Pricing.getTokenValueUSD(
                manager,
                shortToken,
                shortFeesClaimable
            );

            valueUSD += Pricing.getTokenValueUSD(
                manager,
                longToken,
                longFeesClaimable
            );
        }
    }

    /**
     * @notice Get the settked funding fees for an account for a specific market. These are funding fees
     * that have yet to be claimed by the account, but have already been settled.
     * @param dataStore                The data store to fetch claimable fees from.
     * @param account                  The account to check claimable funding fees for.
     * @param market                   The market the fees are for.
     * @param shortToken               The short token for the market to check claimable fees for.
     * @param longToken                The long token for the market to check claimable fees for.
     * @return shortTokenAmountSettled The amount of settled short token fees owed to this account.
     * @return longTokenAmountSettled  The amount of settled long token fees owed to this account.
     */
    function getSettledFundingFees(
        IGmxV2DataStore dataStore,
        address account,
        address market,
        address shortToken,
        address longToken
    )
        public
        view
        returns (
            uint256 shortTokenAmountSettled,
            uint256 longTokenAmountSettled
        )
    {
        // Get short and long amount claimable.
        shortTokenAmountSettled = GmxStorageGetters.getClaimableFundingFees(
            dataStore,
            market,
            shortToken,
            account
        );
        longTokenAmountSettled = GmxStorageGetters.getClaimableFundingFees(
            dataStore,
            market,
            longToken,
            account
        );

        return (shortTokenAmountSettled, longTokenAmountSettled);
    }

    // ============ Private Functions ============

    /**
     * @notice Calculates the valuation of all ERC20 assets in an account.
     * @param manager       The `GmxFrfStrategyManager` to use.
     * @param account       The account to calculate the valuation for.
     * @return accountValue The total value of the account in USD.
     */
    function _getAccountTokenValueUSD(
        IGmxFrfStrategyManager manager,
        address account
    ) private view returns (uint256 accountValue) {
        // Load in all registered assets.
        address[] memory assets = manager.getRegisteredAssets();

        // Iterate through all registered assets and sum account value.
        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i < assetsLength; ++i) {
            address asset = assets[i];

            // Get the balance of the asset in the account.
            uint256 assetBalance = IERC20(asset).balanceOf(account);

            // Increase total account value by asset value in USD.
            accountValue += Pricing.getTokenValueUSD(
                manager,
                asset,
                assetBalance
            );
        }
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PositionTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's position types. A few structs are the same as GMX but a number are
 * added.
 * Adapted from these three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/Position.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/PositionPricingUtils.sol
 */
interface IGmxV2PositionTypes {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    struct Flags {
        bool isLong;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        PositionFees fees;
        IGmxV2PriceTypes.ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionFeesParams {
        address dataStore;
        address referralStorage;
        IGmxV2PositionTypes.Props position;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        bool forPositiveImpact;
        address longToken;
        address shortToken;
        uint256 sizeDeltaUsd;
        address uiFeeReceiver;
    }

    struct GetPriceImpactUsdParams {
        address dataStore;
        IGmxV2MarketTypes.Props market;
        int256 usdDelta;
        bool isLong;
    }

    struct OpenInterestParams {
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 nextLongOpenInterest;
        uint256 nextShortOpenInterest;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }

    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PositionTypes } from "./IGmxV2PositionTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PriceTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Prices, removes all logic from GMX contract and adds additional
 * structs.
 * The structs here come from three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/price/Price.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderPricingUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/SwapPricingUtils.sol
 */
interface IGmxV2PriceTypes {
    struct Props {
        uint256 min;
        uint256 max;
    }

    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        IGmxV2PositionTypes.PositionFees fees;
        ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionInfoCache {
        IGmxV2MarketTypes.Props market;
        Props collateralTokenPrice;
        uint256 pendingBorrowingFeeUsd;
        int256 latestLongTokenFundingAmountPerSize;
        int256 latestShortTokenFundingAmountPerSize;
    }

    struct SwapFees {
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 amountAfterFees;
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2DataStore } from "../interfaces/gmx/IGmxV2DataStore.sol";
import { IGmxV2MarketTypes } from "../interfaces/gmx/IGmxV2MarketTypes.sol";

/**
 * @title GmxMarketGetters
 * @author GoldLink
 *
 * @dev Library for getting values directly for gmx markets.
 */
library GmxMarketGetters {
    // ============ Constants ============

    bytes32 internal constant MARKET_SALT =
        keccak256(abi.encode("MARKET_SALT"));
    bytes32 internal constant MARKET_KEY = keccak256(abi.encode("MARKET_KEY"));
    bytes32 internal constant MARKET_TOKEN =
        keccak256(abi.encode("MARKET_TOKEN"));
    bytes32 internal constant INDEX_TOKEN =
        keccak256(abi.encode("INDEX_TOKEN"));
    bytes32 internal constant LONG_TOKEN = keccak256(abi.encode("LONG_TOKEN"));
    bytes32 internal constant SHORT_TOKEN =
        keccak256(abi.encode("SHORT_TOKEN"));

    // ============ Internal Functions ============

    /**
     * @notice Get the market token for a given market.
     * @param dataStore    The data store being queried for the market token.
     * @param market       The market whose token is being fetched.
     * @return marketToken The token for the market.
     */
    function getMarketToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address marketToken) {
        return
            dataStore.getAddress(keccak256(abi.encode(market, MARKET_TOKEN)));
    }

    /**
     * @notice Get the index token for a given market.
     * @param dataStore   The data store being queried for the index token.
     * @param market      The market whose index token is being fetched.
     * @return indexToken The token for the index for a given market.
     */
    function getIndexToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address indexToken) {
        return dataStore.getAddress(keccak256(abi.encode(market, INDEX_TOKEN)));
    }

    /**
     * @notice Get the long token for a given market.
     * @param dataStore  The data store being queried for the long token.
     * @param market     The market whose long token is being fetched.
     * @return longToken The token for the long asset for a given market.
     */
    function getLongToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address longToken) {
        return dataStore.getAddress(keccak256(abi.encode(market, LONG_TOKEN)));
    }

    /**
     * @notice Get the short token for a given market.
     * @param dataStore   The data store being queried for the short token.
     * @param market      The market whose short token is being fetched.
     * @return shortToken The token for the short asset for a given market.
     */
    function getShortToken(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address shortToken) {
        return dataStore.getAddress(keccak256(abi.encode(market, SHORT_TOKEN)));
    }

    /**
     * @notice Get the short and long tokens for a given market.
     * @param dataStore   The data store being queried for the short and long tokens.
     * @param market      The market whose short and long tokens are being fetched.
     * @return shortToken The token for the short asset for a given market.
     * @return longToken  The token for the long asset for a given market.
     */
    function getMarketTokens(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (address shortToken, address longToken) {
        return (
            getShortToken(dataStore, market),
            getLongToken(dataStore, market)
        );
    }

    /**
     * @notice Get the market information for a given market.
     * @param dataStore The data store being queried for the market information.
     * @param market    The market whose market information is being fetched.
     * @return props    The properties of a specific market.
     */
    function getMarket(
        IGmxV2DataStore dataStore,
        address market
    ) internal view returns (IGmxV2MarketTypes.Props memory props) {
        return
            IGmxV2MarketTypes.Props(
                getMarketToken(dataStore, market),
                getIndexToken(dataStore, market),
                getLongToken(dataStore, market),
                getShortToken(dataStore, market)
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/Reader.sol
// Modified as follows:
// - Using GoldLink types

pragma solidity ^0.8.0;

import {
    IGmxV2MarketTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IGmxV2PriceTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import { IGmxV2OrderTypes } from "./IGmxV2OrderTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2DataStore
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";

interface IGmxV2Reader {
    function getMarket(
        IGmxV2DataStore dataStore,
        address key
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getMarketBySalt(
        IGmxV2DataStore dataStore,
        bytes32 salt
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getPosition(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2PositionTypes.Props memory);

    function getOrder(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2OrderTypes.Props memory);

    function getPositionPnlUsd(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);

    function getAccountPositions(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2PositionTypes.Props[] memory);

    function getAccountPositionInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32[] memory positionKeys,
        IGmxV2MarketTypes.MarketPrices[] memory prices,
        address uiFeeReceiver
    ) external view returns (IGmxV2PositionTypes.PositionInfo[] memory);

    function getPositionInfo(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32 positionKey,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (IGmxV2PositionTypes.PositionInfo memory);

    function getAccountOrders(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2OrderTypes.Props[] memory);

    function getMarkets(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.Props[] memory);

    function getMarketInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices[] memory marketPricesList,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.MarketInfo[] memory);

    function getMarketInfo(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address marketKey
    ) external view returns (IGmxV2MarketTypes.MarketInfo memory);

    function getMarketTokenPrice(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        IGmxV2PriceTypes.Props memory longTokenPrice,
        IGmxV2PriceTypes.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, IGmxV2MarketTypes.PoolValueInfo memory);

    function getNetPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool maximize
    ) external view returns (int256);

    function getPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getOpenInterestWithPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPnlToPoolFactor(
        IGmxV2DataStore dataStore,
        address marketAddress,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getSwapAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address tokenIn,
        uint256 amountIn,
        address uiFeeReceiver
    )
        external
        view
        returns (uint256, int256, IGmxV2PriceTypes.SwapFees memory fees);

    function getExecutionPrice(
        IGmxV2DataStore dataStore,
        address marketKey,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        uint256 positionSizeInUsd,
        uint256 positionSizeInTokens,
        int256 sizeDeltaUsd,
        bool isLong
    ) external view returns (IGmxV2PriceTypes.ExecutionPriceResult memory);

    function getSwapPriceImpact(
        IGmxV2DataStore dataStore,
        address marketKey,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        IGmxV2PriceTypes.Props memory tokenInPrice,
        IGmxV2PriceTypes.Props memory tokenOutPrice
    ) external view returns (int256, int256);

    function getAdlState(
        IGmxV2DataStore dataStore,
        address market,
        bool isLong,
        IGmxV2MarketTypes.MarketPrices memory prices
    ) external view returns (uint256, bool, int256, uint256);

    function getDepositAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 longTokenAmount,
        uint256 shortTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256);

    function getWithdrawalAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified from: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/order/Order.sol
// Modified as follows:
// - Removed all logic
// - Added additional order structs

pragma solidity ^0.8.0;

interface IGmxV2OrderTypes {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease,
        Liquidation
    }

    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2DataStore
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Datastore.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/data/DataStore.sol
 */
interface IGmxV2DataStore {
    // ============ External Functions ============

    function getAddress(bytes32 key) external view returns (address);

    function getUint(bytes32 key) external view returns (uint256);

    function getBool(bytes32 key) external view returns (bool);

    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function containsBytes32(
        bytes32 setKey,
        bytes32 value
    ) external view returns (bool);

    function getAddressArray(
        bytes32 key
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Types used by Gmx V2 for market information.
 * Adapted from these four files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/Market.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketPoolValueInfo.sol
 */
interface IGmxV2MarketTypes {
    // ============ Enums ============

    enum FundingRateChangeType {
        NoChange,
        Increase,
        Decrease
    }

    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    struct MarketPrices {
        IGmxV2PriceTypes.Props indexTokenPrice;
        IGmxV2PriceTypes.Props longTokenPrice;
        IGmxV2PriceTypes.Props shortTokenPrice;
    }

    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    struct VirtualInventory {
        uint256 virtualPoolAmountForLongToken;
        uint256 virtualPoolAmountForShortToken;
        int256 virtualInventoryForPositions;
    }

    struct MarketInfo {
        IGmxV2MarketTypes.Props market;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        BaseFundingValues baseFunding;
        GetNextFundingAmountPerSizeResult nextFunding;
        VirtualInventory virtualInventory;
        bool isDisabled;
    }

    struct BaseFundingValues {
        PositionType fundingFeeAmountPerSize;
        PositionType claimableFundingAmountPerSize;
    }

    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct PoolValueInfo {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;
        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;
        uint256 impactPoolAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IChainlinkAggregatorV3 } from "./external/IChainlinkAggregatorV3.sol";

/**
 * @title IChainlinkAdapter
 * @author GoldLink
 *
 * @dev Oracle registry interface for registering and retrieving price feeds for assets using chainlink oracles.
 */
interface IChainlinkAdapter {
    // ============ Structs ============

    /// @dev Struct to hold the configuration for an oracle.
    struct OracleConfiguration {
        // The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
        uint256 validPriceDuration;
        // The address of the chainlink oracle to fetch prices from.
        IChainlinkAggregatorV3 oracle;
    }

    // ============ Events ============

    /// @notice Emitted when registering an oracle for an asset.
    /// @param asset              The address of the asset whose price oracle is beig set.
    /// @param oracle             The address of the price oracle for the asset.
    /// @param validPriceDuration The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
    event AssetOracleRegistered(
        address indexed asset,
        IChainlinkAggregatorV3 indexed oracle,
        uint256 validPriceDuration
    );

    /// @notice Emitted when removing a price oracle for an asset.
    /// @param asset The asset whose price oracle is being removed.
    event AssetOracleRemoved(address indexed asset);

    // ============ External Functions ============

    /// @dev Get the price of an asset.
    function getAssetPrice(
        address asset
    ) external view returns (uint256 price, uint256 oracleDecimals);

    /// @dev Get the oracle registered for a specific asset.
    function getAssetOracle(
        address asset
    ) external view returns (IChainlinkAggregatorV3 oracle);

    /// @dev Get the oracle configuration for a specific asset.
    function getAssetOracleConfiguration(
        address asset
    )
        external
        view
        returns (IChainlinkAggregatorV3 oracle, uint256 validPriceDuration);

    /// @dev Get all assets registered with oracles in this adapter.
    function getRegisteredAssets()
        external
        view
        returns (address[] memory registeredAssets);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IMarketConfiguration
 * @author GoldLink
 *
 * @dev Manages the configuration of markets for the GmxV2 funding rate farming strategy.
 */
interface IMarketConfiguration {
    // ============ Structs ============

    /// @dev Parameters for pricing an order.
    struct OrderPricingParameters {
        // The maximum swap slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxSwapSlippagePercent;
        // The maximum slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxPositionSlippagePercent;
        // The minimum order size in USD for this market.
        uint256 minOrderSizeUsd;
        // The maximum order size in USD for this market.
        uint256 maxOrderSizeUsd;
        // Whether or not increase orders are enabled.
        bool increaseEnabled;
    }

    /// @dev Parameters for unwinding an order.
    struct UnwindParameters {
        // The minimum amount of delta the position is allowed to have before it can be rebalanced.
        uint256 maxDeltaProportion;
        // The minimum size of a token sale rebalance required. This is used to prevent dust orders from preventing rebalancing of a position via unwinding a position from occuring.
        uint256 minSwapRebalanceSize;
        // The maximum amount of leverage a position is allowed to have.
        uint256 maxPositionLeverage;
        // The fee rate that pays rebalancers for purchasing additional assets to match the short position.
        uint256 unwindFee;
    }

    /// @dev Parameters shared across order types for a market.
    struct SharedOrderParameters {
        // The callback gas limit for all orders.
        uint256 callbackGasLimit;
        // The execution fee buffer percentage required for placing an order.
        uint256 executionFeeBufferPercent;
        // The referral code to use for all orders.
        bytes32 referralCode;
        // The ui fee receiver used for all orders.
        address uiFeeReceiver;
        // The `withdrawalBufferPercentage` for all accounts.
        uint256 withdrawalBufferPercentage;
    }

    /// @dev Parameters for a position established on GMX through the strategy.
    struct PositionParameters {
        // The minimum position size in USD for this market, in order to prevent
        // dust orders from needing to be liquidated. This implies that if a position is partially closed,
        // the value of the position after the partial close must be greater than this value.
        uint256 minPositionSizeUsd;
        // The maximum position size in USD for this market.
        uint256 maxPositionSizeUsd;
    }

    /// @dev Object containing all parameters for a market.
    struct MarketConfiguration {
        // The order pricing parameters for the market.
        OrderPricingParameters orderPricingParameters;
        // The shared order parameters for the market.
        SharedOrderParameters sharedOrderParameters;
        // The position parameters for the market.
        PositionParameters positionParameters;
        // The unwind parameters for the market.
        UnwindParameters unwindParameters;
    }

    // ============ Events ============

    /// @notice Emitted when setting the configuration for a market.
    /// @param market             The address of the market whose configuration is being updated.
    /// @param marketParameters   The updated market parameters for the market.
    /// @param positionParameters The updated position parameters for the market.
    /// @param unwindParameters   The updated unwind parameters for the market.
    event MarketConfigurationSet(
        address indexed market,
        OrderPricingParameters marketParameters,
        PositionParameters positionParameters,
        UnwindParameters unwindParameters
    );

    /// @notice Emitted when setting the asset liquidation fee.
    /// @param asset                    The asset whose liquidation fee percent is being set.
    /// @param newLiquidationFeePercent The new liquidation fee percent for the asset.
    event AssetLiquidationFeeSet(
        address indexed asset,
        uint256 newLiquidationFeePercent
    );

    /// @notice Emitted when setting the liquidation order timeout deadline.
    /// @param newLiquidationOrderTimeoutDeadline The window after which a liquidation order
    /// can be canceled.
    event LiquidationOrderTimeoutDeadlineSet(
        uint256 newLiquidationOrderTimeoutDeadline
    );

    /// @notice Emitted when setting the callback gas limit.
    /// @param newCallbackGasLimit The gas limit on any callback made from the strategy.
    event CallbackGasLimitSet(uint256 newCallbackGasLimit);

    /// @notice Emitted when setting the execution fee buffer percent.
    /// @param newExecutionFeeBufferPercent The percentage of the initially calculated execution fee that needs to be provided additionally
    /// to prevent orders from failing execution.
    event ExecutionFeeBufferPercentSet(uint256 newExecutionFeeBufferPercent);

    /// @notice Emitted when setting the referral code.
    /// @param newReferralCode The code applied to all orders for the strategy, tying orders back to
    /// this protocol.
    event ReferralCodeSet(bytes32 newReferralCode);

    /// @notice Emitted when setting the ui fee receiver.
    /// @param newUiFeeReceiver The fee paid to the UI, this protocol for placing orders.
    event UiFeeReceiverSet(address newUiFeeReceiver);

    /// @notice Emitted when setting the withdrawal buffer percentage.
    /// @param newWithdrawalBufferPercentage The new withdrawal buffer percentage that was set.
    event WithdrawalBufferPercentageSet(uint256 newWithdrawalBufferPercentage);

    // ============ External Functions ============

    /// @dev Set a market for the GMX FRF strategy.
    function setMarket(
        address market,
        IChainlinkAdapter.OracleConfiguration memory oracleConfig,
        OrderPricingParameters memory marketParameters,
        PositionParameters memory positionParameters,
        UnwindParameters memory unwindParameters,
        uint256 longTokenLiquidationFeePercent
    ) external;

    /// @dev Update the oracle for USDC.
    function updateUsdcOracle(
        IChainlinkAdapter.OracleConfiguration calldata strategyAssetOracleConfig
    ) external;

    /// @dev Disable increase orders in a market.
    function disableMarketIncreases(address marketAddress) external;

    /// @dev Set the asset liquidation fee percentage for an asset.
    function setAssetLiquidationFee(
        address asset,
        uint256 newLiquidationFeePercent
    ) external;

    /// @dev Set the asset liquidation timeout for an asset. The time that must
    /// pass before a liquidated order can be cancelled.
    function setLiquidationOrderTimeoutDeadline(
        uint256 newLiquidationOrderTimeoutDeadline
    ) external;

    /// @dev Set the callback gas limit.
    function setCallbackGasLimit(uint256 newCallbackGasLimit) external;

    /// @dev Set the execution fee buffer percent.
    function setExecutionFeeBufferPercent(
        uint256 newExecutionFeeBufferPercent
    ) external;

    /// @dev Set the referral code for all trades made through the GMX Frf strategy.
    function setReferralCode(bytes32 newReferralCode) external;

    /// @dev Set the address of the UI fee receiver.
    function setUiFeeReceiver(address newUiFeeReceiver) external;

    /// @dev Set the buffer on the account value that must be maintained to withdraw profit
    /// with an active loan.
    function setWithdrawalBufferPercentage(
        uint256 newWithdrawalBufferPercentage
    ) external;

    /// @dev Get if a market is approved for the GMX FRF strategy.
    function isApprovedMarket(address market) external view returns (bool);

    /// @dev Get the config that dictates parameters for unwinding an order.
    function getMarketUnwindConfiguration(
        address market
    ) external view returns (UnwindParameters memory);

    /// @dev Get the config for a specific market.
    function getMarketConfiguration(
        address market
    ) external view returns (MarketConfiguration memory);

    /// @dev Get the list of available markets for the GMX FRF strategy.
    function getAvailableMarkets() external view returns (address[] memory);

    /// @dev Get the asset liquidation fee percent.
    function getAssetLiquidationFeePercent(
        address asset
    ) external view returns (uint256);

    /// @dev Get the liquidation order timeout deadline.
    function getLiquidationOrderTimeoutDeadline()
        external
        view
        returns (uint256);

    /// @dev Get the callback gas limit.
    function getCallbackGasLimit() external view returns (uint256);

    /// @dev Get the execution fee buffer percent.
    function getExecutionFeeBufferPercent() external view returns (uint256);

    /// @dev Get the referral code.
    function getReferralCode() external view returns (bytes32);

    /// @dev Get the UI fee receiver
    function getUiFeeReceiver() external view returns (address);

    /// @dev Get profit withdraw buffer percent.
    function getProfitWithdrawalBufferPercent() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

import { Constants } from "./Constants.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

pragma solidity 0.8.20;

/**
 * @title PercentMath
 * @author GoldLink
 *
 * @dev Library for calculating percentages and fractions from percentages.
 * Meant to handle getting fractions in WAD and fraction values from percentages.
 */
library PercentMath {
    using Math for uint256;

    // ============ Internal Functions ============

    /**
     * @notice Implements percent to fraction, deriving a fraction from a percentage.
     * @dev The percentage was calculated with WAD precision.
     * @dev Rounds down.
     * @param whole          The total value.
     * @param percentage     The percent of the whole to derive from.
     * @return fractionValue The value of the fraction.
     */
    function percentToFraction(
        uint256 whole,
        uint256 percentage
    ) internal pure returns (uint256 fractionValue) {
        return whole.mulDiv(percentage, Constants.ONE_HUNDRED_PERCENT);
    }

    /**
     * @notice Implements percent to fraction ceil, deriving a fraction from
     * the ceiling of a percentage.
     * @dev The percentage was calculated with WAD precision.
     * @dev Rounds up.
     * @param whole          The total value.
     * @param percentage     The percent of the whole to derive from.
     * @return fractionValue The value of the fraction.
     */
    function percentToFractionCeil(
        uint256 whole,
        uint256 percentage
    ) internal pure returns (uint256 fractionValue) {
        return
            whole.mulDiv(
                percentage,
                Constants.ONE_HUNDRED_PERCENT,
                Math.Rounding.Ceil
            );
    }

    /**
     * @notice Implements fraction to percent, deriving the percent of the whole
     * that a fraction is.
     * @dev The percentage is calculated with WAD precision.
     * @dev Rounds down.
     * @param fraction    The fraction value.
     * @param whole       The whole value.
     * @return percentage The percent of the whole the `fraction` represents.
     */
    function fractionToPercent(
        uint256 fraction,
        uint256 whole
    ) internal pure returns (uint256 percentage) {
        return fraction.mulDiv(Constants.ONE_HUNDRED_PERCENT, whole);
    }

    /**
     * @notice Implements fraction to percent ceil, deriving the percent of the whole
     * that a fraction is.
     * @dev The percentage is calculated with WAD precision.
     * @dev Rounds up.
     * @param fraction    The fraction value.
     * @param whole       The whole value.
     * @return percentage The percent of the whole the `fraction` represents.
     */
    function fractionToPercentCeil(
        uint256 fraction,
        uint256 whole
    ) internal pure returns (uint256 percentage) {
        return
            fraction.mulDiv(
                Constants.ONE_HUNDRED_PERCENT,
                whole,
                Math.Rounding.Ceil
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Borrowed from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/PositionStoreUtils.sol
// Modified as follows:
// - Removed setters
// - added additional getters

pragma solidity ^0.8.0;

import { Keys } from "../keys/Keys.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";

import { Position } from "./Position.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";

library PositionStoreUtils {
    using Position for IGmxV2PositionTypes.Props;

    // ============ Constants ============

    bytes32 public constant ACCOUNT = keccak256(abi.encode("ACCOUNT"));
    bytes32 public constant MARKET = keccak256(abi.encode("MARKET"));
    bytes32 public constant COLLATERAL_TOKEN =
        keccak256(abi.encode("COLLATERAL_TOKEN"));

    bytes32 public constant SIZE_IN_USD = keccak256(abi.encode("SIZE_IN_USD"));
    bytes32 public constant SIZE_IN_TOKENS =
        keccak256(abi.encode("SIZE_IN_TOKENS"));
    bytes32 public constant COLLATERAL_AMOUNT =
        keccak256(abi.encode("COLLATERAL_AMOUNT"));
    bytes32 public constant BORROWING_FACTOR =
        keccak256(abi.encode("BORROWING_FACTOR"));
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE =
        keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    bytes32 public constant LONG_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE =
        keccak256(abi.encode("LONG_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    bytes32 public constant SHORT_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE =
        keccak256(abi.encode("SHORT_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    bytes32 public constant INCREASED_AT_BLOCK =
        keccak256(abi.encode("INCREASED_AT_BLOCK"));
    bytes32 public constant DECREASED_AT_BLOCK =
        keccak256(abi.encode("DECREASED_AT_BLOCK"));

    bytes32 public constant IS_LONG = keccak256(abi.encode("IS_LONG"));

    // ============ Internal Functions ============

    function get(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (IGmxV2PositionTypes.Props memory) {
        IGmxV2PositionTypes.Props memory position;
        if (!dataStore.containsBytes32(Keys.POSITION_LIST, key)) {
            return position;
        }

        position.setAccount(
            dataStore.getAddress(keccak256(abi.encode(key, ACCOUNT)))
        );

        position.setMarket(
            dataStore.getAddress(keccak256(abi.encode(key, MARKET)))
        );

        position.setCollateralToken(
            dataStore.getAddress(keccak256(abi.encode(key, COLLATERAL_TOKEN)))
        );

        position.setSizeInUsd(
            dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_USD)))
        );

        position.setSizeInTokens(
            dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_TOKENS)))
        );

        position.setCollateralAmount(
            dataStore.getUint(keccak256(abi.encode(key, COLLATERAL_AMOUNT)))
        );

        position.setBorrowingFactor(
            dataStore.getUint(keccak256(abi.encode(key, BORROWING_FACTOR)))
        );

        position.setFundingFeeAmountPerSize(
            dataStore.getUint(
                keccak256(abi.encode(key, FUNDING_FEE_AMOUNT_PER_SIZE))
            )
        );

        position.setLongTokenClaimableFundingAmountPerSize(
            dataStore.getUint(
                keccak256(
                    abi.encode(
                        key,
                        LONG_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE
                    )
                )
            )
        );

        position.setShortTokenClaimableFundingAmountPerSize(
            dataStore.getUint(
                keccak256(
                    abi.encode(
                        key,
                        SHORT_TOKEN_CLAIMABLE_FUNDING_AMOUNT_PER_SIZE
                    )
                )
            )
        );

        position.setIncreasedAtBlock(
            dataStore.getUint(keccak256(abi.encode(key, INCREASED_AT_BLOCK)))
        );

        position.setDecreasedAtBlock(
            dataStore.getUint(keccak256(abi.encode(key, DECREASED_AT_BLOCK)))
        );

        position.setIsLong(
            dataStore.getBool(keccak256(abi.encode(key, IS_LONG)))
        );

        return position;
    }

    function getPositionCount(
        IGmxV2DataStore dataStore
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.POSITION_LIST);
    }

    function getPositionKeys(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return dataStore.getBytes32ValuesAt(Keys.POSITION_LIST, start, end);
    }

    function getAccountPositionCount(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.accountPositionListKey(account));
    }

    function getAccountPositionKeys(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return
            dataStore.getBytes32ValuesAt(
                Keys.accountPositionListKey(account),
                start,
                end
            );
    }

    function getAccountPositionKeys(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (bytes32[] memory keys) {
        uint256 positionCount = getAccountPositionCount(dataStore, account);

        return getAccountPositionKeys(dataStore, account, 0, positionCount);
    }

    function getAccountPositions(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (IGmxV2PositionTypes.Props[] memory positions) {
        bytes32[] memory keys = getAccountPositionKeys(dataStore, account);

        positions = new IGmxV2PositionTypes.Props[](keys.length);

        uint256 keysLength = keys.length;
        for (uint256 i = 0; i < keysLength; ++i) {
            positions[i] = get(dataStore, keys[i]);
        }
    }

    function getPositionKey(
        address account,
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        bytes32 key = keccak256(
            abi.encode(account, market, collateralToken, isLong)
        );

        return key;
    }

    function getPositionMarket(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (address) {
        return dataStore.getAddress(keccak256(abi.encode(key, MARKET)));
    }

    function getPositionSizeUsd(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (uint256) {
        return dataStore.getUint(keccak256(abi.encode(key, SIZE_IN_USD)));
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Borrowed from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/order/OrderStoreUtils.sol
// Modified as follows:
// - GoldLink types
// - set functions removed
// - additional getters like getting keys for storage values

pragma solidity ^0.8.0;

import { Keys } from "../keys/Keys.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import { IGmxV2OrderTypes } from "../interfaces/external/IGmxV2OrderTypes.sol";
import { Order } from "./Order.sol";

library OrderStoreUtils {
    using Order for IGmxV2OrderTypes.Props;

    // ============ Constants ============

    bytes32 public constant ACCOUNT = keccak256(abi.encode("ACCOUNT"));
    bytes32 public constant RECEIVER = keccak256(abi.encode("RECEIVER"));
    bytes32 public constant CALLBACK_CONTRACT =
        keccak256(abi.encode("CALLBACK_CONTRACT"));
    bytes32 public constant UI_FEE_RECEIVER =
        keccak256(abi.encode("UI_FEE_RECEIVER"));
    bytes32 public constant MARKET = keccak256(abi.encode("MARKET"));
    bytes32 public constant INITIAL_COLLATERAL_TOKEN =
        keccak256(abi.encode("INITIAL_COLLATERAL_TOKEN"));
    bytes32 public constant SWAP_PATH = keccak256(abi.encode("SWAP_PATH"));

    bytes32 public constant ORDER_TYPE = keccak256(abi.encode("ORDER_TYPE"));
    bytes32 public constant DECREASE_POSITION_SWAP_TYPE =
        keccak256(abi.encode("DECREASE_POSITION_SWAP_TYPE"));
    bytes32 public constant SIZE_DELTA_USD =
        keccak256(abi.encode("SIZE_DELTA_USD"));
    bytes32 public constant INITIAL_COLLATERAL_DELTA_AMOUNT =
        keccak256(abi.encode("INITIAL_COLLATERAL_DELTA_AMOUNT"));
    bytes32 public constant TRIGGER_PRICE =
        keccak256(abi.encode("TRIGGER_PRICE"));
    bytes32 public constant ACCEPTABLE_PRICE =
        keccak256(abi.encode("ACCEPTABLE_PRICE"));
    bytes32 public constant EXECUTION_FEE =
        keccak256(abi.encode("EXECUTION_FEE"));
    bytes32 public constant CALLBACK_GAS_LIMIT =
        keccak256(abi.encode("CALLBACK_GAS_LIMIT"));
    bytes32 public constant MIN_OUTPUT_AMOUNT =
        keccak256(abi.encode("MIN_OUTPUT_AMOUNT"));
    bytes32 public constant UPDATED_AT_BLOCK =
        keccak256(abi.encode("UPDATED_AT_BLOCK"));

    bytes32 public constant IS_LONG = keccak256(abi.encode("IS_LONG"));
    bytes32 public constant SHOULD_UNWRAP_NATIVE_TOKEN =
        keccak256(abi.encode("SHOULD_UNWRAP_NATIVE_TOKEN"));
    bytes32 public constant IS_FROZEN = keccak256(abi.encode("IS_FROZEN"));

    // ============ Internal Functions ============

    function get(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (IGmxV2OrderTypes.Props memory) {
        IGmxV2OrderTypes.Props memory order;
        if (!dataStore.containsBytes32(Keys.ORDER_LIST, key)) {
            return order;
        }

        order.setAccount(
            dataStore.getAddress(keccak256(abi.encode(key, ACCOUNT)))
        );

        order.setReceiver(
            dataStore.getAddress(keccak256(abi.encode(key, RECEIVER)))
        );

        order.setCallbackContract(
            dataStore.getAddress(keccak256(abi.encode(key, CALLBACK_CONTRACT)))
        );

        order.setUiFeeReceiver(
            dataStore.getAddress(keccak256(abi.encode(key, UI_FEE_RECEIVER)))
        );

        order.setMarket(
            dataStore.getAddress(keccak256(abi.encode(key, MARKET)))
        );

        order.setInitialCollateralToken(
            dataStore.getAddress(
                keccak256(abi.encode(key, INITIAL_COLLATERAL_TOKEN))
            )
        );

        order.setSwapPath(
            dataStore.getAddressArray(keccak256(abi.encode(key, SWAP_PATH)))
        );

        order.setOrderType(
            IGmxV2OrderTypes.OrderType(
                dataStore.getUint(keccak256(abi.encode(key, ORDER_TYPE)))
            )
        );

        order.setDecreasePositionSwapType(
            IGmxV2OrderTypes.DecreasePositionSwapType(
                dataStore.getUint(
                    keccak256(abi.encode(key, DECREASE_POSITION_SWAP_TYPE))
                )
            )
        );

        order.setSizeDeltaUsd(
            dataStore.getUint(keccak256(abi.encode(key, SIZE_DELTA_USD)))
        );

        order.setInitialCollateralDeltaAmount(
            dataStore.getUint(
                keccak256(abi.encode(key, INITIAL_COLLATERAL_DELTA_AMOUNT))
            )
        );

        order.setTriggerPrice(
            dataStore.getUint(keccak256(abi.encode(key, TRIGGER_PRICE)))
        );

        order.setAcceptablePrice(
            dataStore.getUint(keccak256(abi.encode(key, ACCEPTABLE_PRICE)))
        );

        order.setExecutionFee(
            dataStore.getUint(keccak256(abi.encode(key, EXECUTION_FEE)))
        );

        order.setCallbackGasLimit(
            dataStore.getUint(keccak256(abi.encode(key, CALLBACK_GAS_LIMIT)))
        );

        order.setMinOutputAmount(
            dataStore.getUint(keccak256(abi.encode(key, MIN_OUTPUT_AMOUNT)))
        );

        order.setUpdatedAtBlock(
            dataStore.getUint(keccak256(abi.encode(key, UPDATED_AT_BLOCK)))
        );

        order.setIsLong(dataStore.getBool(keccak256(abi.encode(key, IS_LONG))));

        order.setShouldUnwrapNativeToken(
            dataStore.getBool(
                keccak256(abi.encode(key, SHOULD_UNWRAP_NATIVE_TOKEN))
            )
        );

        order.setIsFrozen(
            dataStore.getBool(keccak256(abi.encode(key, IS_FROZEN)))
        );

        return order;
    }

    function getOrderMarket(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) internal view returns (address) {
        return dataStore.getAddress(keccak256(abi.encode(key, MARKET)));
    }

    function getOrderCount(
        IGmxV2DataStore dataStore
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.ORDER_LIST);
    }

    function getOrderKeys(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return dataStore.getBytes32ValuesAt(Keys.ORDER_LIST, start, end);
    }

    function getAccountOrderCount(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (uint256) {
        return dataStore.getBytes32Count(Keys.accountOrderListKey(account));
    }

    function getAccountOrderKeys(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) internal view returns (bytes32[] memory) {
        return
            dataStore.getBytes32ValuesAt(
                Keys.accountOrderListKey(account),
                start,
                end
            );
    }

    function getAccountOrderKeys(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (bytes32[] memory) {
        uint256 orderCount = getAccountOrderCount(dataStore, account);

        return getAccountOrderKeys(dataStore, account, 0, orderCount);
    }

    function getAccountOrders(
        IGmxV2DataStore dataStore,
        address account
    ) internal view returns (IGmxV2OrderTypes.Props[] memory) {
        bytes32[] memory keys = getAccountOrderKeys(dataStore, account);

        IGmxV2OrderTypes.Props[] memory orders = new IGmxV2OrderTypes.Props[](
            keys.length
        );

        uint256 keysLength = keys.length;
        for (uint256 i = 0; i < keysLength; ++i) {
            orders[i] = get(dataStore, keys[i]);
        }

        return orders;
    }

    function getOrderInMarket(
        IGmxV2DataStore dataStore,
        address account,
        address market
    )
        internal
        view
        returns (IGmxV2OrderTypes.Props memory order, bytes32 orderId)
    {
        bytes32[] memory keys = getAccountOrderKeys(dataStore, account);

        uint256 keysLength = keys.length;
        for (uint256 i = 0; i < keysLength; ++i) {
            address orderMarket = getOrderMarket(dataStore, keys[i]);

            if (orderMarket != market) continue;

            return (get(dataStore, keys[i]), keys[i]);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import {
    IERC20Metadata
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";

/**
 * @title Pricing
 * @author GoldLink
 *
 * @dev Library for price conversion for getting the GMX price and USDC price.
 * The internal GMX account system uses 30 decimals to represent USD prices per unit of the underlying token.
 * Example from the GMX documentation:
 * The price of ETH is 5000, and ETH has 18 decimals.
 * The price of one unit of ETH is 5000 / (10 ^ 18), 5 * (10 ^ -15).
 * To handle the decimals, multiply the value by (10 ^ 30).
 * Price would be stored as 5000 / (10 ^ 18) * (10 ^ 30) => 5000 * (10 ^ 12).
 * To read more, see GMX's documentation on oracle prices: https://github.com/gmx-io/gmx-synthetics?tab=readme-ov-file#oracle-prices
 */
library Pricing {
    // ============ Constants ============

    /// @dev The number of decimals used to represent USD within GMX.
    uint256 internal constant USD_DECIMALS = 30;

    // ============ Internal Functions ============

    /**
     * @notice Get the value of an ERC20 token in USD.
     * @param oracle      The `IGmxFrfStrategyManager` to use for the valuation.
     * @param asset       The address of the ERC20 token to evaluate. The asset must have a valid oracle registered within the `IChainlinkAdapter`.
     * @param tokenAmount The token amount to get the valuation for.
     * @return assetValue The value of the token amount in USD.
     */
    function getTokenValueUSD(
        IGmxFrfStrategyManager oracle,
        address asset,
        uint256 tokenAmount
    ) internal view returns (uint256 assetValue) {
        // Exit early if the token amount is 0.
        if (tokenAmount == 0) {
            return 0;
        }

        // Query the oracle for the price of the asset.
        uint256 assetPrice = getUnitTokenPriceUSD(oracle, asset);

        return getTokenValueUSD(tokenAmount, assetPrice);
    }

    /**
     * @notice Get the value of an ERC20 token in USD.
     * @param  tokenAmount The token amount to get the valuation for.
     * @param  price       The price of the token in USD. (1 USD = 1e30).
     * @return assetValue  The value of the token amount in USD.
     * @dev The provided  `IChainlinkAdapter` MUST have a price precision of 30.
     */
    function getTokenValueUSD(
        uint256 tokenAmount,
        uint256 price
    ) internal pure returns (uint256 assetValue) {
        // Per the GMX documentation, the value of a token in terms of USD is simply calculated via multiplication.
        // This is because the USD price already inherently accounts for the decimals of the token.
        return price * tokenAmount;
    }

    /**
     * @notice Gets the price of a given token per unit in USD. USD is represented with 30 decimals of precision.
     * @param oracle      The `IChainlinkAdapter` to use for pricing this token.
     * @param token       The address of the ERC20 token to evaluate. The asset must have a valid oracle registered within the `IChainlinkAdapter`.
     * @return assetValue The value of the token amount in USD.
     */
    function getUnitTokenPriceUSD(
        IGmxFrfStrategyManager oracle,
        address token
    ) internal view returns (uint256) {
        (uint256 price, uint256 oracleDecimals) = oracle.getAssetPrice(token);

        // The total decimals that the price is represented with, which includes both the oracle's
        // decimals and the token's decimals.
        uint256 totalPriceDecimals = oracleDecimals + getAssetDecimals(token);

        // The offset in decimals between the USD price and the the both the oracle's decimals and the token's decimals.
        uint256 decimalOffset = Math.max(USD_DECIMALS, totalPriceDecimals) -
            Math.min(USD_DECIMALS, totalPriceDecimals);

        return
            (USD_DECIMALS >= totalPriceDecimals)
                ? price * (10 ** decimalOffset)
                : price / (10 ** decimalOffset);
    }

    /**
     * @notice Get the amount of a token that is equivalent to a given USD amount based on `token's` current oracle price.
     * @param oracle       The `IChainlinkAdapter` to use for querying the oracle price for this token.
     * @param token        The token address for the token to quote `usdAmount` in.
     * @param usdAmount    The amount in USD to convert to tokens. (1 usd = 1^30)
     * @return tokenAmount The amount of `token` equivalent to `usdAmount` based on the current `oracle` price.
     */
    function getTokenAmountForUSD(
        IGmxFrfStrategyManager oracle,
        address token,
        uint256 usdAmount
    ) internal view returns (uint256) {
        uint256 assetPrice = getUnitTokenPriceUSD(oracle, token);

        // As defined per the GMX documentation, the value of a token in terms of USD is simply calculated via division.
        return usdAmount / assetPrice;
    }

    /**
     * @notice Fetch decimals for an asset.
     * @param token     The token to get the decimals for.
     * @return decimals The decimals of the token.
     */
    function getAssetDecimals(
        address token
    ) internal view returns (uint256 decimals) {
        return IERC20Metadata(token).decimals();
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import { PercentMath } from "../../../libraries/PercentMath.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2PriceTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    IGmxV2MarketTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import {
    PositionStoreUtils
} from "../../../lib/gmx/position/PositionStoreUtils.sol";
import {
    IGmxFrfStrategyManager
} from "../interfaces/IGmxFrfStrategyManager.sol";
import {
    GmxStorageGetters
} from "../../../strategies/gmxFrf/libraries/GmxStorageGetters.sol";
import {
    GmxMarketGetters
} from "../../../strategies/gmxFrf/libraries/GmxMarketGetters.sol";
import { IMarketConfiguration } from "../interfaces/IMarketConfiguration.sol";
import { Pricing } from "./Pricing.sol";

/**
 * @title DeltaConvergenceMath
 * @author GoldLink
 *
 * @dev Math and checks library for validating position delta.
 */
library DeltaConvergenceMath {
    using PercentMath for uint256;

    // ============ Structs ============

    struct DeltaCalculationParameters {
        address marketAddress;
        address account;
        uint256 shortTokenPrice;
        uint256 longTokenPrice;
        address uiFeeReceiver;
        IGmxV2MarketTypes.Props market;
    }

    struct DecreasePositionResult {
        uint256 positionSizeNextUsd;
        uint256 estimatedOutputUsd;
        uint256 collateralToRemove;
        uint256 executionPrice;
    }

    struct IncreasePositionResult {
        uint256 sizeDeltaUsd;
        uint256 executionPrice;
        uint256 positionSizeNextUsd;
        uint256 swapOutputTokens;
        uint256 swapOutputMarkedToMarket;
    }

    struct PositionTokenBreakdown {
        uint256 tokensShort;
        uint256 tokensLong;
        uint256 accountBalanceLongTokens;
        uint256 claimableLongTokens;
        uint256 unsettledLongTokens;
        uint256 collateralLongTokens;
        uint256 fundingAndBorrowFeesLongTokens;
        uint256 leverage;
        IGmxV2PositionTypes.PositionInfo positionInfo;
    }

    // ============ Internal Functions ============

    /**
     * @notice Get the value of a position in terms of USD. The `valueUSD` reflects the value that could be extracted from the position if it were liquidated right away,
     * and thus accounts for the price impact of closing the position.
     * @param manager    The manager that controls the strategy and maintains configuration state.
     * @param account    The account to get the position value for.
     * @param market     The market the position is for.
     * @return valueUSD  The expected value of the position after closing the position given at the current market prices and GMX pool state.
     */
    function getPositionValueUSD(
        IGmxFrfStrategyManager manager,
        address account,
        address market
    ) internal view returns (uint256 valueUSD) {
        // Passing true for `useMaxSizeDelta` because the cost of exiting the entire positon must be considered
        // (due to price impact and fees) in order properly account the estimated value.
        IGmxV2PositionTypes.PositionInfo memory positionInfo = _getPositionInfo(
            manager,
            account,
            market,
            0,
            true
        );

        (address shortToken, address longToken) = GmxMarketGetters
            .getMarketTokens(manager.gmxV2DataStore(), market);

        uint256 shortTokenPrice = Pricing.getUnitTokenPriceUSD(
            manager,
            shortToken
        );

        uint256 longTokenPrice = Pricing.getUnitTokenPriceUSD(
            manager,
            longToken
        );

        return
            getPositionValueUSD(positionInfo, shortTokenPrice, longTokenPrice);
    }

    /**
     * @notice Get the value of a position in terms of USD. The `valueUSD` reflects the value that could be extracted from the position if it were liquidated right away,
     * and thus accounts for the price impact of closing the position.
     * @param positionInfo    The position information, which is queried from GMX via the `Reader.getPositionInfo` function.
     * @param shortTokenPrice The price of the short token.
     * @param longTokenPrice  The price of the long token.
     * @return valueUSD       The expected value of the position after closing the position given at the current market prices and GMX pool state. This value can only be considered an estimate,
     * as asset prices can change in between the time the value is calculated and when the GMX keeper actually executes the order. Furthermore, price impact can change during this period,
     * as other state changing actions can effect the GMX pool, resulting in a different price impact values.
     */
    function getPositionValueUSD(
        IGmxV2PositionTypes.PositionInfo memory positionInfo,
        uint256 shortTokenPrice,
        uint256 longTokenPrice
    ) internal pure returns (uint256 valueUSD) {
        // The value of a position is made up of the following fields:
        // 1. The value of the collateral.
        // 2. The value of unsettled positive funding fees, which consist of both shortTokens and longTokens.
        // 3. The loss of value due to borrowing fees and negative fees, which consist strictly of the `collateralToken.` At the time of decreasing the position, this value is offset by profit if possible,
        // however, this is not accounted for in the PnL.
        // 4. The PnL, which is a signed integer representing the profit or loss of the position.
        // 5. The loss due to the price impact of closing the position, which is ultimately included in the `positionPnlIncludingPriceImpactUsd` field.
        // 6. The loss due to the price impact of swapping the collateral token into USDC.

        // It is important to also not the values that may be related to the position but are not included in the value of the position.
        // 1. The unclaimed, settled funding fees are not included in the value of a position because, once settled, they are inherently seperate and can be atomically claimed.
        //    Furthermore, they are not "locked" in the position and can be though of as an auxiliary token balance.
        // 2. The value of the ERC20 tokens in the account. These do not relate to the position that is held on GMX and therefore are factored into the value of the account separately.

        // This accounts for the value of the unsettled short token funding fees.
        valueUSD += Pricing.getTokenValueUSD(
            positionInfo.fees.funding.claimableShortTokenAmount,
            shortTokenPrice
        );

        // The amount of collateral tokens initially held in the position, before accounting for fees, is just the collateral token amount plus the unclaimed funding fees.
        // These are all measured in terms of the longToken of the GMX market, which is also always the token that Goldlink uses to collateralize the position.
        uint256 collateralTokenHeldInPosition = positionInfo
            .position
            .numbers
            .collateralAmount +
            positionInfo.fees.funding.claimableLongTokenAmount;

        // The cost is measured in terms of the collateral token, which includes the GMX borrowing fees and negative funding fees.
        // Therefore, subtract the cost from the collateral tokens to recieve the net amount of collateral tokens held in the position.
        collateralTokenHeldInPosition -= Math.min(
            collateralTokenHeldInPosition,
            positionInfo.fees.totalCostAmount
        );

        // This accounts for the value of the collateral, the unsettled long token funding fees, the negative funding fee amount, the borrowing fees, the UI fee,
        // and the positive impact of the referral bonus.
        valueUSD += Pricing.getTokenValueUSD(
            collateralTokenHeldInPosition,
            longTokenPrice
        );

        // The absolute value of the pnl in terms of USD. This also includes the price impact of closing the position,
        // which can either increase or decrease the value of the position. It is important to include the price impact because for large positions,
        // liquidation may result in high slippage, which can result in the loss of lender funds. In order to trigger liquidations for these positions early, including the price impact
        // in the calculation of the position value is necessary.
        uint256 absPnlAfterPriceImpactUSD = SignedMath.abs(
            positionInfo.pnlAfterPriceImpactUsd
        );

        return
            (positionInfo.pnlAfterPriceImpactUsd < 0)
                ? valueUSD - Math.min(absPnlAfterPriceImpactUSD, valueUSD)
                : valueUSD + absPnlAfterPriceImpactUSD;
    }

    /**
     * @notice Get the market delta for an account, which gives a breakdown of the position encompassed by `market`.
     * @param manager         The configuration manager for the strategy.
     * @param account         The account to get the market delta for.
     * @param sizeDeltaUsd    The size delta to evaluate based off.
     * @param useMaxSizeDelta Whether to use the max size delta.
     */
    function getAccountMarketDelta(
        IGmxFrfStrategyManager manager,
        address account,
        address market,
        uint256 sizeDeltaUsd,
        bool useMaxSizeDelta
    ) internal view returns (PositionTokenBreakdown memory breakdown) {
        // If the market is not approved, then there is zero delta.
        if (!manager.isApprovedMarket(market)) {
            return breakdown;
        }

        // Get the long token for the market.
        (, address longToken) = GmxMarketGetters.getMarketTokens(
            manager.gmxV2DataStore(),
            market
        );

        breakdown.accountBalanceLongTokens = IERC20(longToken).balanceOf(
            account
        );
        breakdown.tokensLong += breakdown.accountBalanceLongTokens;

        // Claimable funding fees are considered as long tokens.
        breakdown.claimableLongTokens += GmxStorageGetters
            .getClaimableFundingFees(
                manager.gmxV2DataStore(),
                market,
                longToken,
                account
            );

        breakdown.tokensLong += breakdown.claimableLongTokens;

        // Get the position information.
        breakdown.positionInfo = _getPositionInfo(
            manager,
            account,
            market,
            sizeDeltaUsd,
            useMaxSizeDelta
        );

        // Position collateral.
        breakdown.collateralLongTokens = breakdown
            .positionInfo
            .position
            .numbers
            .collateralAmount;
        breakdown.tokensLong += breakdown.collateralLongTokens;

        // Unclaimed funding fees.
        breakdown.unsettledLongTokens = breakdown
            .positionInfo
            .fees
            .funding
            .fundingFeeAmount;
        breakdown.tokensLong += breakdown.unsettledLongTokens;

        // Position size.
        breakdown.tokensShort += breakdown
            .positionInfo
            .position
            .numbers
            .sizeInTokens;

        breakdown.fundingAndBorrowFeesLongTokens =
            breakdown.positionInfo.fees.funding.fundingFeeAmount +
            breakdown.positionInfo.fees.borrowing.borrowingFeeAmount;

        // This should not normally happen, but it can in the event that someone checks for the delta
        // of a position before a GMX keeper liquidates the underwater position.

        breakdown.tokensLong -= Math.min(
            breakdown.fundingAndBorrowFeesLongTokens,
            breakdown.tokensLong
        );

        breakdown.leverage = _getLeverage(manager, market, breakdown);

        return breakdown;
    }

    function getIncreaseOrderValues(
        IGmxFrfStrategyManager manager,
        uint256 initialCollateralDeltaAmount,
        DeltaCalculationParameters memory values
    ) internal view returns (IncreasePositionResult memory result) {
        // First we need to see if an active position exists, because `getPositionInfo` will revert if it does not exist.
        IGmxV2MarketTypes.MarketPrices memory prices = _makeMarketPrices(
            values.shortTokenPrice,
            values.longTokenPrice
        );

        // We need to figure out the expected swap output given the initial collateral delta amount.
        (result.swapOutputTokens, , ) = manager.gmxV2Reader().getSwapAmountOut(
            manager.gmxV2DataStore(),
            values.market,
            prices,
            values.market.shortToken,
            initialCollateralDeltaAmount,
            values.uiFeeReceiver
        );

        bytes32 positionKey = PositionStoreUtils.getPositionKey(
            values.account,
            values.marketAddress,
            values.market.longToken,
            false
        );

        // Get position information if one already exists.
        IGmxV2PositionTypes.PositionInfo memory info;
        if (
            PositionStoreUtils.getPositionSizeUsd(
                manager.gmxV2DataStore(),
                positionKey
            ) != 0
        ) {
            info = manager.gmxV2Reader().getPositionInfo(
                manager.gmxV2DataStore(),
                manager.gmxV2ReferralStorage(),
                positionKey,
                prices,
                0,
                values.uiFeeReceiver,
                true
            );
        }

        uint256 collateralAfterSwapTokens = info
            .position
            .numbers
            .collateralAmount +
            result.swapOutputTokens -
            info.fees.funding.fundingFeeAmount -
            info.fees.borrowing.borrowingFeeAmount;

        uint256 sizeDeltaEstimate = getIncreaseSizeDelta(
            info.position.numbers.sizeInTokens,
            collateralAfterSwapTokens,
            values.longTokenPrice
        );

        // Estimate the execution price with the estimated size delta.
        IGmxV2PriceTypes.ExecutionPriceResult memory executionPrices = manager
            .gmxV2Reader()
            .getExecutionPrice(
                manager.gmxV2DataStore(),
                values.marketAddress,
                IGmxV2PriceTypes.Props(
                    values.longTokenPrice,
                    values.longTokenPrice
                ),
                info.position.numbers.sizeInUsd,
                info.position.numbers.sizeInTokens,
                int256(sizeDeltaEstimate),
                false
            );

        // Recompute size delta using the execution price.
        result.sizeDeltaUsd = getIncreaseSizeDelta(
            info.position.numbers.sizeInTokens,
            collateralAfterSwapTokens,
            executionPrices.executionPrice
        );

        result.positionSizeNextUsd =
            info.position.numbers.sizeInUsd +
            result.sizeDeltaUsd;

        result.executionPrice = executionPrices.executionPrice;

        result.swapOutputMarkedToMarket = Math.mulDiv(
            initialCollateralDeltaAmount,
            values.shortTokenPrice,
            values.longTokenPrice
        );

        return result;
    }

    function getDecreaseOrderValues(
        IGmxFrfStrategyManager manager,
        uint256 sizeDeltaUsd,
        DeltaCalculationParameters memory values
    ) internal view returns (DecreasePositionResult memory result) {
        PositionTokenBreakdown memory breakdown = getAccountMarketDelta(
            manager,
            values.account,
            values.marketAddress,
            sizeDeltaUsd,
            false
        );

        // The total cost amount is equal to the sum of the fees associated with the decrease, in terms of the collateral token.
        // This accounts for negative funding fees, borrowing fees,
        uint256 collateralLostInDecrease = breakdown
            .positionInfo
            .fees
            .totalCostAmount;

        {
            uint256 profitInCollateralToken = SignedMath.abs(
                breakdown.positionInfo.pnlAfterPriceImpactUsd
            ) / values.longTokenPrice;

            if (breakdown.positionInfo.pnlAfterPriceImpactUsd > 0) {
                collateralLostInDecrease -= Math.min(
                    collateralLostInDecrease,
                    profitInCollateralToken
                ); // Offset the loss in collateral with position profits.
            } else {
                collateralLostInDecrease += profitInCollateralToken; // adding because this variable is meant to represent a net loss in collateral.
            }
        }

        uint256 sizeDeltaActual = Math.min(
            sizeDeltaUsd,
            breakdown.positionInfo.position.numbers.sizeInUsd
        );

        result.positionSizeNextUsd =
            breakdown.positionInfo.position.numbers.sizeInUsd -
            sizeDeltaActual;

        uint256 shortTokensAfterDecrease;

        {
            uint256 proportionalDecrease = sizeDeltaActual.fractionToPercent(
                breakdown.positionInfo.position.numbers.sizeInUsd
            );

            shortTokensAfterDecrease =
                breakdown.tokensShort -
                breakdown
                    .positionInfo
                    .position
                    .numbers
                    .sizeInTokens
                    .percentToFraction(proportionalDecrease);
        }

        uint256 longTokensAfterDecrease = breakdown.tokensLong -
            collateralLostInDecrease;

        // This is the difference in long vs short tokens currently.
        uint256 imbalance = Math.max(
            shortTokensAfterDecrease,
            longTokensAfterDecrease
        ) - Math.min(shortTokensAfterDecrease, longTokensAfterDecrease);

        if (shortTokensAfterDecrease < longTokensAfterDecrease) {
            // We need to remove long tokens equivalent to the imbalance to make the position delta neutral.
            // However, it is possible that there are a significant number of long tokens in the contract that are impacting the imbalance.
            // If this is the case, then if we were to simply remove the imbalance, it can result in a position with very high leverage. Therefore, we will simply remove
            // the minimum of `collateralAmount - collateralLostInDecrease` the difference in the longCollateral and shortTokens. The rest of the delta imbalance can be left to rebalancers.
            uint256 remainingCollateral = breakdown
                .positionInfo
                .position
                .numbers
                .collateralAmount - collateralLostInDecrease;

            if (remainingCollateral > shortTokensAfterDecrease) {
                result.collateralToRemove = Math.min(
                    remainingCollateral - shortTokensAfterDecrease,
                    imbalance
                );
            }
        }

        if (result.collateralToRemove != 0) {
            (uint256 expectedSwapOutput, , ) = manager
                .gmxV2Reader()
                .getSwapAmountOut(
                    manager.gmxV2DataStore(),
                    values.market,
                    _makeMarketPrices(
                        values.shortTokenPrice,
                        values.longTokenPrice
                    ),
                    values.market.longToken,
                    result.collateralToRemove,
                    values.uiFeeReceiver
                );

            result.estimatedOutputUsd =
                expectedSwapOutput *
                values.shortTokenPrice;
        }

        if (breakdown.positionInfo.pnlAfterPriceImpactUsd > 0) {
            result.estimatedOutputUsd += SignedMath.abs(
                breakdown.positionInfo.pnlAfterPriceImpactUsd
            );
        }

        result.executionPrice = breakdown
            .positionInfo
            .executionPriceResult
            .executionPrice;
    }

    /**
     * @notice Get prices of a short and long token.
     * @param manager          The IGmxFrfStrategyManager of the strategy.
     * @param shortToken       The short token whose price is being queried.
     * @param longToken        The long token whose price is being queried.
     * @return shortTokenPrice The price of the short token.
     * @return longTokenPrice  The price of the long token.
     */
    function getMarketPrices(
        IGmxFrfStrategyManager manager,
        address shortToken,
        address longToken
    ) internal view returns (uint256 shortTokenPrice, uint256 longTokenPrice) {
        shortTokenPrice = Pricing.getUnitTokenPriceUSD(manager, shortToken);

        longTokenPrice = Pricing.getUnitTokenPriceUSD(manager, longToken);

        return (shortTokenPrice, longTokenPrice);
    }

    function getIncreaseSizeDelta(
        uint256 currentShortPositionSizeTokens,
        uint256 collateralAfterSwapTokens,
        uint256 executionPrice
    ) internal pure returns (uint256) {
        if (collateralAfterSwapTokens < currentShortPositionSizeTokens) {
            return 0;
        }

        uint256 diff = collateralAfterSwapTokens -
            currentShortPositionSizeTokens;

        return diff * executionPrice;
    }

    /**
     * @notice Get delta proportion, the proportion of the position that is directional.
     * @param shortPositionSizeTokens The size of the short position.
     * @param longPositionSizeTokens  The size of the long position.
     * @return proportion             The proportion of the position that is directional.
     * @return isShort                If the direction is short.
     */
    function getDeltaProportion(
        uint256 shortPositionSizeTokens,
        uint256 longPositionSizeTokens
    ) internal pure returns (uint256 proportion, bool isShort) {
        // Get the direction of the position.
        isShort = shortPositionSizeTokens > longPositionSizeTokens;

        // Get the proportion of the position that is directional.
        proportion = (isShort)
            ? shortPositionSizeTokens.fractionToPercent(longPositionSizeTokens)
            : longPositionSizeTokens.fractionToPercent(shortPositionSizeTokens);
    }

    // ============ Private Functions ============

    function _getLeverage(
        IGmxFrfStrategyManager manager,
        address market,
        PositionTokenBreakdown memory breakdown
    ) private view returns (uint256 leverage) {
        if (breakdown.positionInfo.position.numbers.sizeInUsd == 0) {
            // Position with 0 size has 0 leverage.
            return 0;
        }

        // The important part here is the position info, not the tokens held in the account. The leverage of the position as GMX sees it is as follows:
        // Short Position Size: Fixed number in terms of USD representing the size of the short. This only changes when you increase or decrease the size, and is not affected by changes in price.
        // Collateral in tokens is gotten by fetching the position `collateralAmount` and subtracting the `totalCostAmount` from that.

        uint256 collateralInTokens = breakdown
            .positionInfo
            .position
            .numbers
            .collateralAmount - breakdown.positionInfo.fees.totalCostAmount;

        uint256 longTokenPrice = Pricing.getUnitTokenPriceUSD(
            manager,
            GmxMarketGetters.getLongToken(manager.gmxV2DataStore(), market)
        );

        // Only negative price impact contributes to the collateral value, positive price impact is not considered when a position is being liquidated.
        if (breakdown.positionInfo.executionPriceResult.priceImpactUsd < 0) {
            collateralInTokens -=
                uint256(
                    -breakdown.positionInfo.executionPriceResult.priceImpactUsd
                ) /
                longTokenPrice;
        }

        // The absolute value of the pnl in tokens.
        uint256 absPnlTokens = SignedMath.abs(
            breakdown.positionInfo.basePnlUsd
        ) / longTokenPrice;

        if (breakdown.positionInfo.basePnlUsd < 0) {
            collateralInTokens -= Math.min(absPnlTokens, collateralInTokens);
        } else {
            collateralInTokens += absPnlTokens;
        }

        if (collateralInTokens == 0) {
            return type(uint256).max;
        }

        // Make sure to convert collateral tokens back to USD.
        leverage = breakdown
            .positionInfo
            .position
            .numbers
            .sizeInUsd
            .fractionToPercent(collateralInTokens * longTokenPrice);

        return leverage;
    }

    function _makeMarketPrices(
        uint256 shortTokenPrice,
        uint256 longTokenPrice
    ) private pure returns (IGmxV2MarketTypes.MarketPrices memory) {
        return
            IGmxV2MarketTypes.MarketPrices(
                IGmxV2PriceTypes.Props(longTokenPrice, longTokenPrice),
                IGmxV2PriceTypes.Props(longTokenPrice, longTokenPrice),
                IGmxV2PriceTypes.Props(shortTokenPrice, shortTokenPrice)
            );
    }

    function _makeMarketPrices(
        IGmxFrfStrategyManager manager,
        address shortToken,
        address longToken
    ) private view returns (IGmxV2MarketTypes.MarketPrices memory) {
        (uint256 shortTokenPrice, uint256 longTokenPrice) = getMarketPrices(
            manager,
            shortToken,
            longToken
        );

        return _makeMarketPrices(shortTokenPrice, longTokenPrice);
    }

    function _getPositionInfo(
        IGmxFrfStrategyManager manager,
        address account,
        address market,
        uint256 sizeDeltaUsd,
        bool useMaxSizeDelta
    ) private view returns (IGmxV2PositionTypes.PositionInfo memory position) {
        (address shortToken, address longToken) = GmxMarketGetters
            .getMarketTokens(manager.gmxV2DataStore(), market);

        // Key is just the hash of the account, market, collateral token and a boolean representing whether or not the position is long.
        // Since the strategy only allows short positions, the position is always short and thus we pass in false to get the position key.
        // Furthermore, since a short position can only be hedged properly with the long token of a market, which the strategy enforces,
        // the long token is always the collateral token.
        bytes32 positionKey = PositionStoreUtils.getPositionKey(
            account,
            market,
            longToken,
            false
        );

        // If no position exists, then there are no values to consider. Furthermore, this prevents `Reader.getPositionInfo` from reverting.
        if (
            PositionStoreUtils.getPositionSizeUsd(
                manager.gmxV2DataStore(),
                positionKey
            ) == 0
        ) {
            return position;
        }

        position = manager.gmxV2Reader().getPositionInfo(
            manager.gmxV2DataStore(),
            manager.gmxV2ReferralStorage(),
            positionKey,
            _makeMarketPrices(manager, shortToken, longToken),
            sizeDeltaUsd,
            manager.getUiFeeReceiver(),
            useMaxSizeDelta
        );

        return position;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IMarketConfiguration } from "./IMarketConfiguration.sol";
import { IDeploymentConfiguration } from "./IDeploymentConfiguration.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IGmxFrfStrategyManager
 * @author GoldLink
 *
 * @dev Interface for manager contract for configuration vars.
 */
interface IGmxFrfStrategyManager is
    IMarketConfiguration,
    IDeploymentConfiguration,
    IChainlinkAdapter
{}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/gas/GasUtils.sol
// Modified as follows:
// - Copied exactly from GMX V2 with structs removed and touch removed

pragma solidity ^0.8.0;

import { IGmxV2OrderTypes } from "../interfaces/external/IGmxV2OrderTypes.sol";

library Order {
    // ============ Internal Functions ============

    // @dev set the order account
    // @param props Props
    // @param value the value to set to
    function setAccount(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.account = value;
    }

    // @dev the order receiver
    // @param props Props
    // @return the order receiver
    function receiver(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.receiver;
    }

    // @dev set the order receiver
    // @param props Props
    // @param value the value to set to
    function setReceiver(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.receiver = value;
    }

    // @dev the order callbackContract
    // @param props Props
    // @return the order callbackContract
    function callbackContract(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.callbackContract;
    }

    // @dev set the order callbackContract
    // @param props Props
    // @param value the value to set to
    function setCallbackContract(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.callbackContract = value;
    }

    // @dev the order market
    // @param props Props
    // @return the order market
    function market(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.market;
    }

    // @dev set the order market
    // @param props Props
    // @param value the value to set to
    function setMarket(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.market = value;
    }

    // @dev the order initialCollateralToken
    // @param props Props
    // @return the order initialCollateralToken
    function initialCollateralToken(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.initialCollateralToken;
    }

    // @dev set the order initialCollateralToken
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralToken(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.initialCollateralToken = value;
    }

    // @dev the order uiFeeReceiver
    // @param props Props
    // @return the order uiFeeReceiver
    function uiFeeReceiver(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.uiFeeReceiver;
    }

    // @dev set the order uiFeeReceiver
    // @param props Props
    // @param value the value to set to
    function setUiFeeReceiver(
        IGmxV2OrderTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.uiFeeReceiver = value;
    }

    // @dev the order swapPath
    // @param props Props
    // @return the order swapPath
    function swapPath(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (address[] memory) {
        return props.addresses.swapPath;
    }

    // @dev set the order swapPath
    // @param props Props
    // @param value the value to set to
    function setSwapPath(
        IGmxV2OrderTypes.Props memory props,
        address[] memory value
    ) internal pure {
        props.addresses.swapPath = value;
    }

    // @dev the order type
    // @param props Props
    // @return the order type
    function orderType(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (IGmxV2OrderTypes.OrderType) {
        return props.numbers.orderType;
    }

    // @dev set the order type
    // @param props Props
    // @param value the value to set to
    function setOrderType(
        IGmxV2OrderTypes.Props memory props,
        IGmxV2OrderTypes.OrderType value
    ) internal pure {
        props.numbers.orderType = value;
    }

    function decreasePositionSwapType(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (IGmxV2OrderTypes.DecreasePositionSwapType) {
        return props.numbers.decreasePositionSwapType;
    }

    function setDecreasePositionSwapType(
        IGmxV2OrderTypes.Props memory props,
        IGmxV2OrderTypes.DecreasePositionSwapType value
    ) internal pure {
        props.numbers.decreasePositionSwapType = value;
    }

    // @dev the order sizeDeltaUsd
    // @param props Props
    // @return the order sizeDeltaUsd
    function sizeDeltaUsd(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.sizeDeltaUsd;
    }

    // @dev set the order sizeDeltaUsd
    // @param props Props
    // @param value the value to set to
    function setSizeDeltaUsd(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.sizeDeltaUsd = value;
    }

    // @dev the order initialCollateralDeltaAmount
    // @param props Props
    // @return the order initialCollateralDeltaAmount
    function initialCollateralDeltaAmount(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.initialCollateralDeltaAmount;
    }

    // @dev set the order initialCollateralDeltaAmount
    // @param props Props
    // @param value the value to set to
    function setInitialCollateralDeltaAmount(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.initialCollateralDeltaAmount = value;
    }

    // @dev the order triggerPrice
    // @param props Props
    // @return the order triggerPrice
    function triggerPrice(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.triggerPrice;
    }

    // @dev set the order triggerPrice
    // @param props Props
    // @param value the value to set to
    function setTriggerPrice(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.triggerPrice = value;
    }

    // @dev the order acceptablePrice
    // @param props Props
    // @return the order acceptablePrice
    function acceptablePrice(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.acceptablePrice;
    }

    // @dev set the order acceptablePrice
    // @param props Props
    // @param value the value to set to
    function setAcceptablePrice(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.acceptablePrice = value;
    }

    // @dev set the order executionFee
    // @param props Props
    // @param value the value to set to
    function setExecutionFee(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.executionFee = value;
    }

    // @dev the order executionFee
    // @param props Props
    // @return the order executionFee
    function executionFee(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.executionFee;
    }

    // @dev the order callbackGasLimit
    // @param props Props
    // @return the order callbackGasLimit
    function callbackGasLimit(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.callbackGasLimit;
    }

    // @dev set the order callbackGasLimit
    // @param props Props
    // @param value the value to set to
    function setCallbackGasLimit(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.callbackGasLimit = value;
    }

    // @dev the order minOutputAmount
    // @param props Props
    // @return the order minOutputAmount
    function minOutputAmount(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.minOutputAmount;
    }

    // @dev set the order minOutputAmount
    // @param props Props
    // @param value the value to set to
    function setMinOutputAmount(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.minOutputAmount = value;
    }

    // @dev the order updatedAtBlock
    // @param props Props
    // @return the order updatedAtBlock
    function updatedAtBlock(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.updatedAtBlock;
    }

    // @dev set the order updatedAtBlock
    // @param props Props
    // @param value the value to set to
    function setUpdatedAtBlock(
        IGmxV2OrderTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.updatedAtBlock = value;
    }

    // @dev whether the order is for a long or short
    // @param props Props
    // @return whether the order is for a long or short
    function isLong(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.isLong;
    }

    // @dev set whether the order is for a long or short
    // @param props Props
    // @param value the value to set to
    function setIsLong(
        IGmxV2OrderTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.isLong = value;
    }

    // @dev whether to unwrap the native token before transfers to the user
    // @param props Props
    // @return whether to unwrap the native token before transfers to the user
    function shouldUnwrapNativeToken(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.shouldUnwrapNativeToken;
    }

    // @dev set whether the native token should be unwrapped before being
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setShouldUnwrapNativeToken(
        IGmxV2OrderTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.shouldUnwrapNativeToken = value;
    }

    // @dev whether the order is frozen
    // @param props Props
    // @return whether the order is frozen
    function isFrozen(
        IGmxV2OrderTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.isFrozen;
    }

    // @dev set whether the order is frozen
    // transferred to the receiver
    // @param props Props
    // @param value the value to set to
    function setIsFrozen(
        IGmxV2OrderTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.isFrozen = value;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Keys } from "../../../lib/gmx/keys/Keys.sol";
import { IGmxV2DataStore } from "../interfaces/gmx/IGmxV2DataStore.sol";

/**
 * @title GmxStorageGetters
 * @author GoldLink
 *
 * @dev Library for getting values directly from Gmx's `datastore` contract.
 */
library GmxStorageGetters {
    // ============ Internal Functions ============

    /**
     * @notice Get claimable collateral time divisor.
     * @param dataStore                       The data store the time divisor in in.
     * @return claimableCollateralTimeDivisor The time divisor for calculating the initial claim timestamp.
     */
    function getClaimableCollateralTimeDivisor(
        IGmxV2DataStore dataStore
    ) internal view returns (uint256 claimableCollateralTimeDivisor) {
        return dataStore.getUint(Keys.CLAIMABLE_COLLATERAL_TIME_DIVISOR);
    }

    /**
     * @notice Get account claimable collateral.
     * @param dataStore            The data store the claimable collateral is registered in.
     * @param market               The market the claimable collateral is for.
     * @param token                The token associated with the account's claimable collateral.
     * @param timeKey              The time key for the claimable collateral.
     * @param account              The account that has claimable collateral.
     * @return claimableCollateral The claimable collateral an account has for a market.
     */
    function getAccountClaimableCollateral(
        IGmxV2DataStore dataStore,
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal view returns (uint256 claimableCollateral) {
        bytes32 key = Keys.claimableCollateralAmountKey(
            market,
            token,
            timeKey,
            account
        );

        return dataStore.getUint(key);
    }

    /**
     * @notice Get claimable funding fees.
     * @param token                 The token associated with the account's claimable funding fees.
     * @param market                The market the claimable funding fees are for.
     * @param account               The account that has claimable funding fees.
     * @return claimableFundingFees The claimable funding fees an account has for a market.
     */
    function getClaimableFundingFees(
        IGmxV2DataStore dataStore,
        address market,
        address token,
        address account
    ) internal view returns (uint256 claimableFundingFees) {
        bytes32 key = Keys.claimableFundingAmountKey(market, token, account);

        return dataStore.getUint(key);
    }

    /**
     * @notice Get saved callback contract an account has for a market.
     * @param dataStore              The data store the saved callback contractl is in.
     * @param market                 The market the saved callback contract is for.
     * @param account                The account that has the saved callback contract.
     * @return savedCallbackContract The address of the saved callback contract.
     */
    function getSavedCallbackContract(
        IGmxV2DataStore dataStore,
        address account,
        address market
    ) internal view returns (address savedCallbackContract) {
        bytes32 key = Keys.savedCallbackContract(account, market);

        return dataStore.getAddress(key);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

interface IGmxV2ReferralStorage {}

// SPDX-License-Identifier: MIT
//
// Adapted from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.20;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title Constants
 * @author GoldLink
 *
 * @dev Core constants for the GoldLink Protocol.
 */
library Constants {
    ///
    /// COMMON
    ///
    /// @dev ONE_HUNDRED_PERCENT is one WAD.
    uint256 internal constant ONE_HUNDRED_PERCENT = 1e18;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Taken directly from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/data/Keys.sol

pragma solidity ^0.8.0;

library Keys {
    // ============ Constants ============

    // @dev key for the address of the wrapped native token
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));
    // @dev key for the nonce value used in NonceUtils
    bytes32 public constant NONCE = keccak256(abi.encode("NONCE"));

    // @dev for sending received fees
    bytes32 public constant FEE_RECEIVER =
        keccak256(abi.encode("FEE_RECEIVER"));

    // @dev for holding tokens that could not be sent out
    bytes32 public constant HOLDING_ADDRESS =
        keccak256(abi.encode("HOLDING_ADDRESS"));

    // @dev key for in strict price feed mode
    bytes32 public constant IN_STRICT_PRICE_FEED_MODE =
        keccak256(abi.encode("IN_STRICT_PRICE_FEED_MODE"));

    // @dev key for the minimum gas for execution error
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS =
        keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS"));

    // @dev key for the minimum gas that should be forwarded for execution error handling
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD =
        keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD"));

    // @dev key for the min additional gas for execution
    bytes32 public constant MIN_ADDITIONAL_GAS_FOR_EXECUTION =
        keccak256(abi.encode("MIN_ADDITIONAL_GAS_FOR_EXECUTION"));

    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS =
        keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev key for deposit fees
    bytes32 public constant DEPOSIT_FEE_TYPE =
        keccak256(abi.encode("DEPOSIT_FEE_TYPE"));
    // @dev key for withdrawal fees
    bytes32 public constant WITHDRAWAL_FEE_TYPE =
        keccak256(abi.encode("WITHDRAWAL_FEE_TYPE"));
    // @dev key for swap fees
    bytes32 public constant SWAP_FEE_TYPE =
        keccak256(abi.encode("SWAP_FEE_TYPE"));
    // @dev key for position fees
    bytes32 public constant POSITION_FEE_TYPE =
        keccak256(abi.encode("POSITION_FEE_TYPE"));
    // @dev key for ui deposit fees
    bytes32 public constant UI_DEPOSIT_FEE_TYPE =
        keccak256(abi.encode("UI_DEPOSIT_FEE_TYPE"));
    // @dev key for ui withdrawal fees
    bytes32 public constant UI_WITHDRAWAL_FEE_TYPE =
        keccak256(abi.encode("UI_WITHDRAWAL_FEE_TYPE"));
    // @dev key for ui swap fees
    bytes32 public constant UI_SWAP_FEE_TYPE =
        keccak256(abi.encode("UI_SWAP_FEE_TYPE"));
    // @dev key for ui position fees
    bytes32 public constant UI_POSITION_FEE_TYPE =
        keccak256(abi.encode("UI_POSITION_FEE_TYPE"));

    // @dev key for ui fee factor
    bytes32 public constant UI_FEE_FACTOR =
        keccak256(abi.encode("UI_FEE_FACTOR"));
    // @dev key for max ui fee receiver factor
    bytes32 public constant MAX_UI_FEE_FACTOR =
        keccak256(abi.encode("MAX_UI_FEE_FACTOR"));

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));
    // @dev key for the claimable ui fee amount
    bytes32 public constant CLAIMABLE_UI_FEE_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_UI_FEE_AMOUNT"));

    // @dev key for the market list
    bytes32 public constant MARKET_LIST = keccak256(abi.encode("MARKET_LIST"));

    // @dev key for the fee batch list
    bytes32 public constant FEE_BATCH_LIST =
        keccak256(abi.encode("FEE_BATCH_LIST"));

    // @dev key for the deposit list
    bytes32 public constant DEPOSIT_LIST =
        keccak256(abi.encode("DEPOSIT_LIST"));
    // @dev key for the account deposit list
    bytes32 public constant ACCOUNT_DEPOSIT_LIST =
        keccak256(abi.encode("ACCOUNT_DEPOSIT_LIST"));

    // @dev key for the withdrawal list
    bytes32 public constant WITHDRAWAL_LIST =
        keccak256(abi.encode("WITHDRAWAL_LIST"));
    // @dev key for the account withdrawal list
    bytes32 public constant ACCOUNT_WITHDRAWAL_LIST =
        keccak256(abi.encode("ACCOUNT_WITHDRAWAL_LIST"));

    // @dev key for the position list
    bytes32 public constant POSITION_LIST =
        keccak256(abi.encode("POSITION_LIST"));
    // @dev key for the account position list
    bytes32 public constant ACCOUNT_POSITION_LIST =
        keccak256(abi.encode("ACCOUNT_POSITION_LIST"));

    // @dev key for the order list
    bytes32 public constant ORDER_LIST = keccak256(abi.encode("ORDER_LIST"));
    // @dev key for the account order list
    bytes32 public constant ACCOUNT_ORDER_LIST =
        keccak256(abi.encode("ACCOUNT_ORDER_LIST"));

    // @dev key for the subaccount list
    bytes32 public constant SUBACCOUNT_LIST =
        keccak256(abi.encode("SUBACCOUNT_LIST"));

    // @dev key for is market disabled
    bytes32 public constant IS_MARKET_DISABLED =
        keccak256(abi.encode("IS_MARKET_DISABLED"));

    // @dev key for the max swap path length allowed
    bytes32 public constant MAX_SWAP_PATH_LENGTH =
        keccak256(abi.encode("MAX_SWAP_PATH_LENGTH"));
    // @dev key used to store markets observed in a swap path, to ensure that a swap path contains unique markets
    bytes32 public constant SWAP_PATH_MARKET_FLAG =
        keccak256(abi.encode("SWAP_PATH_MARKET_FLAG"));
    // @dev key used to store the min market tokens for the first deposit for a market
    bytes32 public constant MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT =
        keccak256(abi.encode("MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT"));

    // @dev key for whether the create deposit feature is disabled
    bytes32 public constant CREATE_DEPOSIT_FEATURE_DISABLED =
        keccak256(abi.encode("CREATE_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the cancel deposit feature is disabled
    bytes32 public constant CANCEL_DEPOSIT_FEATURE_DISABLED =
        keccak256(abi.encode("CANCEL_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the execute deposit feature is disabled
    bytes32 public constant EXECUTE_DEPOSIT_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_DEPOSIT_FEATURE_DISABLED"));

    // @dev key for whether the create withdrawal feature is disabled
    bytes32 public constant CREATE_WITHDRAWAL_FEATURE_DISABLED =
        keccak256(abi.encode("CREATE_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the cancel withdrawal feature is disabled
    bytes32 public constant CANCEL_WITHDRAWAL_FEATURE_DISABLED =
        keccak256(abi.encode("CANCEL_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the execute withdrawal feature is disabled
    bytes32 public constant EXECUTE_WITHDRAWAL_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_WITHDRAWAL_FEATURE_DISABLED"));

    // @dev key for whether the create order feature is disabled
    bytes32 public constant CREATE_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("CREATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute order feature is disabled
    bytes32 public constant EXECUTE_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute adl feature is disabled
    // for liquidations, it can be disabled by using the EXECUTE_ORDER_FEATURE_DISABLED key with the Liquidation
    // order type, ADL orders have a MarketDecrease order type, so a separate key is needed to disable it
    bytes32 public constant EXECUTE_ADL_FEATURE_DISABLED =
        keccak256(abi.encode("EXECUTE_ADL_FEATURE_DISABLED"));
    // @dev key for whether the update order feature is disabled
    bytes32 public constant UPDATE_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("UPDATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the cancel order feature is disabled
    bytes32 public constant CANCEL_ORDER_FEATURE_DISABLED =
        keccak256(abi.encode("CANCEL_ORDER_FEATURE_DISABLED"));

    // @dev key for whether the claim funding fees feature is disabled
    bytes32 public constant CLAIM_FUNDING_FEES_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_FUNDING_FEES_FEATURE_DISABLED"));
    // @dev key for whether the claim collateral feature is disabled
    bytes32 public constant CLAIM_COLLATERAL_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_COLLATERAL_FEATURE_DISABLED"));
    // @dev key for whether the claim affiliate rewards feature is disabled
    bytes32 public constant CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED"));
    // @dev key for whether the claim ui fees feature is disabled
    bytes32 public constant CLAIM_UI_FEES_FEATURE_DISABLED =
        keccak256(abi.encode("CLAIM_UI_FEES_FEATURE_DISABLED"));
    // @dev key for whether the subaccount feature is disabled
    bytes32 public constant SUBACCOUNT_FEATURE_DISABLED =
        keccak256(abi.encode("SUBACCOUNT_FEATURE_DISABLED"));

    // @dev key for the minimum required oracle signers for an oracle observation
    bytes32 public constant MIN_ORACLE_SIGNERS =
        keccak256(abi.encode("MIN_ORACLE_SIGNERS"));
    // @dev key for the minimum block confirmations before blockhash can be excluded for oracle signature validation
    bytes32 public constant MIN_ORACLE_BLOCK_CONFIRMATIONS =
        keccak256(abi.encode("MIN_ORACLE_BLOCK_CONFIRMATIONS"));
    // @dev key for the maximum usable oracle price age in seconds
    bytes32 public constant MAX_ORACLE_PRICE_AGE =
        keccak256(abi.encode("MAX_ORACLE_PRICE_AGE"));
    // @dev key for the maximum oracle price deviation factor from the ref price
    bytes32 public constant MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR =
        keccak256(abi.encode("MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR"));
    // @dev key for the percentage amount of position fees to be received
    bytes32 public constant POSITION_FEE_RECEIVER_FACTOR =
        keccak256(abi.encode("POSITION_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of swap fees to be received
    bytes32 public constant SWAP_FEE_RECEIVER_FACTOR =
        keccak256(abi.encode("SWAP_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of borrowing fees to be received
    bytes32 public constant BORROWING_FEE_RECEIVER_FACTOR =
        keccak256(abi.encode("BORROWING_FEE_RECEIVER_FACTOR"));

    // @dev key for the base gas limit used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_BASE_AMOUNT =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the base gas limit used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_BASE_AMOUNT =
        keccak256(abi.encode("EXECUTION_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_MULTIPLIER_FACTOR =
        keccak256(abi.encode("EXECUTION_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the estimated gas limit for deposits
    bytes32 public constant DEPOSIT_GAS_LIMIT =
        keccak256(abi.encode("DEPOSIT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for withdrawals
    bytes32 public constant WITHDRAWAL_GAS_LIMIT =
        keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT"));
    // @dev key for the estimated gas limit for single swaps
    bytes32 public constant SINGLE_SWAP_GAS_LIMIT =
        keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    // @dev key for the estimated gas limit for increase orders
    bytes32 public constant INCREASE_ORDER_GAS_LIMIT =
        keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for decrease orders
    bytes32 public constant DECREASE_ORDER_GAS_LIMIT =
        keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for swap orders
    bytes32 public constant SWAP_ORDER_GAS_LIMIT =
        keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for token transfers
    bytes32 public constant TOKEN_TRANSFER_GAS_LIMIT =
        keccak256(abi.encode("TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for native token transfers
    bytes32 public constant NATIVE_TOKEN_TRANSFER_GAS_LIMIT =
        keccak256(abi.encode("NATIVE_TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the maximum request block age, after which the request will be considered expired
    bytes32 public constant REQUEST_EXPIRATION_BLOCK_AGE =
        keccak256(abi.encode("REQUEST_EXPIRATION_BLOCK_AGE"));

    bytes32 public constant MAX_CALLBACK_GAS_LIMIT =
        keccak256(abi.encode("MAX_CALLBACK_GAS_LIMIT"));
    bytes32 public constant SAVED_CALLBACK_CONTRACT =
        keccak256(abi.encode("SAVED_CALLBACK_CONTRACT"));

    // @dev key for the min collateral factor
    bytes32 public constant MIN_COLLATERAL_FACTOR =
        keccak256(abi.encode("MIN_COLLATERAL_FACTOR"));
    // @dev key for the min collateral factor for open interest multiplier
    bytes32 public constant MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER =
        keccak256(
            abi.encode("MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER")
        );
    // @dev key for the min allowed collateral in USD
    bytes32 public constant MIN_COLLATERAL_USD =
        keccak256(abi.encode("MIN_COLLATERAL_USD"));
    // @dev key for the min allowed position size in USD
    bytes32 public constant MIN_POSITION_SIZE_USD =
        keccak256(abi.encode("MIN_POSITION_SIZE_USD"));

    // @dev key for the virtual id of tokens
    bytes32 public constant VIRTUAL_TOKEN_ID =
        keccak256(abi.encode("VIRTUAL_TOKEN_ID"));
    // @dev key for the virtual id of markets
    bytes32 public constant VIRTUAL_MARKET_ID =
        keccak256(abi.encode("VIRTUAL_MARKET_ID"));
    // @dev key for the virtual inventory for swaps
    bytes32 public constant VIRTUAL_INVENTORY_FOR_SWAPS =
        keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_SWAPS"));
    // @dev key for the virtual inventory for positions
    bytes32 public constant VIRTUAL_INVENTORY_FOR_POSITIONS =
        keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_POSITIONS"));

    // @dev key for the position impact factor
    bytes32 public constant POSITION_IMPACT_FACTOR =
        keccak256(abi.encode("POSITION_IMPACT_FACTOR"));
    // @dev key for the position impact exponent factor
    bytes32 public constant POSITION_IMPACT_EXPONENT_FACTOR =
        keccak256(abi.encode("POSITION_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the max decrease position impact factor
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR =
        keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR"));
    // @dev key for the max position impact factor for liquidations
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS =
        keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS"));
    // @dev key for the position fee factor
    bytes32 public constant POSITION_FEE_FACTOR =
        keccak256(abi.encode("POSITION_FEE_FACTOR"));
    // @dev key for the swap impact factor
    bytes32 public constant SWAP_IMPACT_FACTOR =
        keccak256(abi.encode("SWAP_IMPACT_FACTOR"));
    // @dev key for the swap impact exponent factor
    bytes32 public constant SWAP_IMPACT_EXPONENT_FACTOR =
        keccak256(abi.encode("SWAP_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the swap fee factor
    bytes32 public constant SWAP_FEE_FACTOR =
        keccak256(abi.encode("SWAP_FEE_FACTOR"));
    // @dev key for the oracle type
    bytes32 public constant ORACLE_TYPE = keccak256(abi.encode("ORACLE_TYPE"));
    // @dev key for open interest
    bytes32 public constant OPEN_INTEREST =
        keccak256(abi.encode("OPEN_INTEREST"));
    // @dev key for open interest in tokens
    bytes32 public constant OPEN_INTEREST_IN_TOKENS =
        keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    // @dev key for collateral sum for a market
    bytes32 public constant COLLATERAL_SUM =
        keccak256(abi.encode("COLLATERAL_SUM"));
    // @dev key for pool amount
    bytes32 public constant POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    // @dev key for max pool amount
    bytes32 public constant MAX_POOL_AMOUNT =
        keccak256(abi.encode("MAX_POOL_AMOUNT"));
    // @dev key for max pool amount for deposit
    bytes32 public constant MAX_POOL_AMOUNT_FOR_DEPOSIT =
        keccak256(abi.encode("MAX_POOL_AMOUNT_FOR_DEPOSIT"));
    // @dev key for max open interest
    bytes32 public constant MAX_OPEN_INTEREST =
        keccak256(abi.encode("MAX_OPEN_INTEREST"));
    // @dev key for position impact pool amount
    bytes32 public constant POSITION_IMPACT_POOL_AMOUNT =
        keccak256(abi.encode("POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for min position impact pool amount
    bytes32 public constant MIN_POSITION_IMPACT_POOL_AMOUNT =
        keccak256(abi.encode("MIN_POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for position impact pool distribution rate
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTION_RATE =
        keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTION_RATE"));
    // @dev key for position impact pool distributed at
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTED_AT =
        keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTED_AT"));
    // @dev key for swap impact pool amount
    bytes32 public constant SWAP_IMPACT_POOL_AMOUNT =
        keccak256(abi.encode("SWAP_IMPACT_POOL_AMOUNT"));
    // @dev key for price feed
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    // @dev key for price feed multiplier
    bytes32 public constant PRICE_FEED_MULTIPLIER =
        keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    // @dev key for price feed heartbeat
    bytes32 public constant PRICE_FEED_HEARTBEAT_DURATION =
        keccak256(abi.encode("PRICE_FEED_HEARTBEAT_DURATION"));
    // @dev key for realtime feed id
    bytes32 public constant REALTIME_FEED_ID =
        keccak256(abi.encode("REALTIME_FEED_ID"));
    // @dev key for realtime feed multipler
    bytes32 public constant REALTIME_FEED_MULTIPLIER =
        keccak256(abi.encode("REALTIME_FEED_MULTIPLIER"));
    // @dev key for stable price
    bytes32 public constant STABLE_PRICE =
        keccak256(abi.encode("STABLE_PRICE"));
    // @dev key for reserve factor
    bytes32 public constant RESERVE_FACTOR =
        keccak256(abi.encode("RESERVE_FACTOR"));
    // @dev key for open interest reserve factor
    bytes32 public constant OPEN_INTEREST_RESERVE_FACTOR =
        keccak256(abi.encode("OPEN_INTEREST_RESERVE_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR =
        keccak256(abi.encode("MAX_PNL_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_TRADERS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_TRADERS"));
    // @dev key for max pnl factor for adl
    bytes32 public constant MAX_PNL_FACTOR_FOR_ADL =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_ADL"));
    // @dev key for min pnl factor for adl
    bytes32 public constant MIN_PNL_FACTOR_AFTER_ADL =
        keccak256(abi.encode("MIN_PNL_FACTOR_AFTER_ADL"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_DEPOSITS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    // @dev key for max pnl factor for withdrawals
    bytes32 public constant MAX_PNL_FACTOR_FOR_WITHDRAWALS =
        keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    // @dev key for latest ADL block
    bytes32 public constant LATEST_ADL_BLOCK =
        keccak256(abi.encode("LATEST_ADL_BLOCK"));
    // @dev key for whether ADL is enabled
    bytes32 public constant IS_ADL_ENABLED =
        keccak256(abi.encode("IS_ADL_ENABLED"));
    // @dev key for funding factor
    bytes32 public constant FUNDING_FACTOR =
        keccak256(abi.encode("FUNDING_FACTOR"));
    // @dev key for funding exponent factor
    bytes32 public constant FUNDING_EXPONENT_FACTOR =
        keccak256(abi.encode("FUNDING_EXPONENT_FACTOR"));
    // @dev key for saved funding factor
    bytes32 public constant SAVED_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("SAVED_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for funding increase factor
    bytes32 public constant FUNDING_INCREASE_FACTOR_PER_SECOND =
        keccak256(abi.encode("FUNDING_INCREASE_FACTOR_PER_SECOND"));
    // @dev key for funding decrease factor
    bytes32 public constant FUNDING_DECREASE_FACTOR_PER_SECOND =
        keccak256(abi.encode("FUNDING_DECREASE_FACTOR_PER_SECOND"));
    // @dev key for min funding factor
    bytes32 public constant MIN_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("MIN_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for max funding factor
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND =
        keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for threshold for stable funding
    bytes32 public constant THRESHOLD_FOR_STABLE_FUNDING =
        keccak256(abi.encode("THRESHOLD_FOR_STABLE_FUNDING"));
    // @dev key for threshold for decrease funding
    bytes32 public constant THRESHOLD_FOR_DECREASE_FUNDING =
        keccak256(abi.encode("THRESHOLD_FOR_DECREASE_FUNDING"));
    // @dev key for funding fee amount per size
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE =
        keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    // @dev key for claimable funding amount per size
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT_PER_SIZE =
        keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    // @dev key for when funding was last updated at
    bytes32 public constant FUNDING_UPDATED_AT =
        keccak256(abi.encode("FUNDING_UPDATED_AT"));
    // @dev key for claimable funding amount
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT"));
    // @dev key for claimable collateral amount
    bytes32 public constant CLAIMABLE_COLLATERAL_AMOUNT =
        keccak256(abi.encode("CLAIMABLE_COLLATERAL_AMOUNT"));
    // @dev key for claimable collateral factor
    bytes32 public constant CLAIMABLE_COLLATERAL_FACTOR =
        keccak256(abi.encode("CLAIMABLE_COLLATERAL_FACTOR"));
    // @dev key for claimable collateral time divisor
    bytes32 public constant CLAIMABLE_COLLATERAL_TIME_DIVISOR =
        keccak256(abi.encode("CLAIMABLE_COLLATERAL_TIME_DIVISOR"));
    // @dev key for claimed collateral amount
    bytes32 public constant CLAIMED_COLLATERAL_AMOUNT =
        keccak256(abi.encode("CLAIMED_COLLATERAL_AMOUNT"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_FACTOR =
        keccak256(abi.encode("BORROWING_FACTOR"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_EXPONENT_FACTOR =
        keccak256(abi.encode("BORROWING_EXPONENT_FACTOR"));
    // @dev key for skipping the borrowing factor for the smaller side
    bytes32 public constant SKIP_BORROWING_FEE_FOR_SMALLER_SIDE =
        keccak256(abi.encode("SKIP_BORROWING_FEE_FOR_SMALLER_SIDE"));
    // @dev key for cumulative borrowing factor
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR =
        keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR"));
    // @dev key for when the cumulative borrowing factor was last updated at
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR_UPDATED_AT =
        keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR_UPDATED_AT"));
    // @dev key for total borrowing amount
    bytes32 public constant TOTAL_BORROWING =
        keccak256(abi.encode("TOTAL_BORROWING"));
    // @dev key for affiliate reward
    bytes32 public constant AFFILIATE_REWARD =
        keccak256(abi.encode("AFFILIATE_REWARD"));
    // @dev key for max allowed subaccount action count
    bytes32 public constant MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT =
        keccak256(abi.encode("MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount action count
    bytes32 public constant SUBACCOUNT_ACTION_COUNT =
        keccak256(abi.encode("SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount auto top up amount
    bytes32 public constant SUBACCOUNT_AUTO_TOP_UP_AMOUNT =
        keccak256(abi.encode("SUBACCOUNT_AUTO_TOP_UP_AMOUNT"));
    // @dev key for subaccount order action
    bytes32 public constant SUBACCOUNT_ORDER_ACTION =
        keccak256(abi.encode("SUBACCOUNT_ORDER_ACTION"));
    // @dev key for fee distributor swap order token index
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX =
        keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX"));
    // @dev key for fee distributor swap fee batch
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_FEE_BATCH =
        keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_FEE_BATCH"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // ============ Internal Functions ============

    // @dev key for the account deposit list
    // @param account the account for the list
    function accountDepositListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_DEPOSIT_LIST, account));
    }

    // @dev key for the account withdrawal list
    // @param account the account for the list
    function accountWithdrawalListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_WITHDRAWAL_LIST, account));
    }

    // @dev key for the account position list
    // @param account the account for the list
    function accountPositionListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_POSITION_LIST, account));
    }

    // @dev key for the account order list
    // @param account the account for the list
    function accountOrderListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_ORDER_LIST, account));
    }

    // @dev key for the subaccount list
    // @param account the account for the list
    function subaccountListKey(
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_LIST, account));
    }

    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount for account
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(
        address market,
        address token,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token, account)
            );
    }

    // @dev key for deposit gas limit
    // @param singleToken whether a single token or pair tokens are being deposited
    // @return key for deposit gas limit
    function depositGasLimitKey(
        bool singleToken
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(DEPOSIT_GAS_LIMIT, singleToken));
    }

    // @dev key for withdrawal gas limit
    // @return key for withdrawal gas limit
    function withdrawalGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(WITHDRAWAL_GAS_LIMIT));
    }

    // @dev key for single swap gas limit
    // @return key for single swap gas limit
    function singleSwapGasLimitKey() internal pure returns (bytes32) {
        return SINGLE_SWAP_GAS_LIMIT;
    }

    // @dev key for increase order gas limit
    // @return key for increase order gas limit
    function increaseOrderGasLimitKey() internal pure returns (bytes32) {
        return INCREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for decrease order gas limit
    // @return key for decrease order gas limit
    function decreaseOrderGasLimitKey() internal pure returns (bytes32) {
        return DECREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for swap order gas limit
    // @return key for swap order gas limit
    function swapOrderGasLimitKey() internal pure returns (bytes32) {
        return SWAP_ORDER_GAS_LIMIT;
    }

    function swapPathMarketFlagKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_PATH_MARKET_FLAG, market));
    }

    // @dev key for whether create deposit is disabled
    // @param the create deposit module
    // @return key for whether create deposit is disabled
    function createDepositFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CREATE_DEPOSIT_FEATURE_DISABLED, module));
    }

    // @dev key for whether cancel deposit is disabled
    // @param the cancel deposit module
    // @return key for whether cancel deposit is disabled
    function cancelDepositFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CANCEL_DEPOSIT_FEATURE_DISABLED, module));
    }

    // @dev key for whether execute deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function executeDepositFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(EXECUTE_DEPOSIT_FEATURE_DISABLED, module));
    }

    // @dev key for whether create withdrawal is disabled
    // @param the create withdrawal module
    // @return key for whether create withdrawal is disabled
    function createWithdrawalFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CREATE_WITHDRAWAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether cancel withdrawal is disabled
    // @param the cancel withdrawal module
    // @return key for whether cancel withdrawal is disabled
    function cancelWithdrawalFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CANCEL_WITHDRAWAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether execute withdrawal is disabled
    // @param the execute withdrawal module
    // @return key for whether execute withdrawal is disabled
    function executeWithdrawalFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(EXECUTE_WITHDRAWAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether create order is disabled
    // @param the create order module
    // @return key for whether create order is disabled
    function createOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CREATE_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether execute order is disabled
    // @param the execute order module
    // @return key for whether execute order is disabled
    function executeOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(EXECUTE_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether execute adl is disabled
    // @param the execute adl module
    // @return key for whether execute adl is disabled
    function executeAdlFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(EXECUTE_ADL_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether update order is disabled
    // @param the update order module
    // @return key for whether update order is disabled
    function updateOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(UPDATE_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether cancel order is disabled
    // @param the cancel order module
    // @return key for whether cancel order is disabled
    function cancelOrderFeatureDisabledKey(
        address module,
        uint256 orderType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CANCEL_ORDER_FEATURE_DISABLED, module, orderType)
            );
    }

    // @dev key for whether claim funding fees is disabled
    // @param the claim funding fees module
    function claimFundingFeesFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CLAIM_FUNDING_FEES_FEATURE_DISABLED, module));
    }

    // @dev key for whether claim colltareral is disabled
    // @param the claim funding fees module
    function claimCollateralFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIM_COLLATERAL_FEATURE_DISABLED, module));
    }

    // @dev key for whether claim affiliate rewards is disabled
    // @param the claim affiliate rewards module
    function claimAffiliateRewardsFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED, module)
            );
    }

    // @dev key for whether claim ui fees is disabled
    // @param the claim ui fees module
    function claimUiFeesFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIM_UI_FEES_FEATURE_DISABLED, module));
    }

    // @dev key for whether subaccounts are disabled
    // @param the subaccount module
    function subaccountFeatureDisabledKey(
        address module
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_FEATURE_DISABLED, module));
    }

    // @dev key for ui fee factor
    // @param account the fee receiver account
    // @return key for ui fee factor
    function uiFeeFactorKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(UI_FEE_FACTOR, account));
    }

    // @dev key for gas to forward for token transfer
    // @param the token to check
    // @return key for gas to forward for token transfer
    function tokenTransferGasLimit(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOKEN_TRANSFER_GAS_LIMIT, token));
    }

    // @dev the default callback contract
    // @param account the user's account
    // @param market the address of the market
    // @param callbackContract the callback contract
    function savedCallbackContract(
        address account,
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SAVED_CALLBACK_CONTRACT, account, market));
    }

    // @dev the min collateral factor key
    // @param the market for the min collateral factor
    function minCollateralFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_COLLATERAL_FACTOR, market));
    }

    // @dev the min collateral factor for open interest multiplier key
    // @param the market for the factor
    function minCollateralFactorForOpenInterestMultiplierKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER,
                    market,
                    isLong
                )
            );
    }

    // @dev the key for the virtual token id
    // @param the token to get the virtual id for
    function virtualTokenIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(VIRTUAL_TOKEN_ID, token));
    }

    // @dev the key for the virtual market id
    // @param the market to get the virtual id for
    function virtualMarketIdKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(VIRTUAL_MARKET_ID, market));
    }

    // @dev the key for the virtual inventory for positions
    // @param the virtualTokenId the virtual token id
    function virtualInventoryForPositionsKey(
        bytes32 virtualTokenId
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(VIRTUAL_INVENTORY_FOR_POSITIONS, virtualTokenId)
            );
    }

    // @dev the key for the virtual inventory for swaps
    // @param the virtualMarketId the virtual market id
    // @param the token to check the inventory for
    function virtualInventoryForSwapsKey(
        bytes32 virtualMarketId,
        bool isLongToken
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    VIRTUAL_INVENTORY_FOR_SWAPS,
                    virtualMarketId,
                    isLongToken
                )
            );
    }

    // @dev key for position impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for position impact factor
    function positionImpactFactorKey(
        address market,
        bool isPositive
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(POSITION_IMPACT_FACTOR, market, isPositive));
    }

    // @dev key for position impact exponent factor
    // @param market the market address to check
    // @return key for position impact exponent factor
    function positionImpactExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(POSITION_IMPACT_EXPONENT_FACTOR, market));
    }

    // @dev key for the max position impact factor
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorKey(
        address market,
        bool isPositive
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_POSITION_IMPACT_FACTOR, market, isPositive)
            );
    }

    // @dev key for the max position impact factor for liquidations
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorForLiquidationsKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS, market)
            );
    }

    // @dev key for position fee factor
    // @param market the market address to check
    // @param forPositiveImpact whether the fee is for an action that has a positive price impact
    // @return key for position fee factor
    function positionFeeFactorKey(
        address market,
        bool forPositiveImpact
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(POSITION_FEE_FACTOR, market, forPositiveImpact)
            );
    }

    // @dev key for swap impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for swap impact factor
    function swapImpactFactorKey(
        address market,
        bool isPositive
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_IMPACT_FACTOR, market, isPositive));
    }

    // @dev key for swap impact exponent factor
    // @param market the market address to check
    // @return key for swap impact exponent factor
    function swapImpactExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_IMPACT_EXPONENT_FACTOR, market));
    }

    // @dev key for swap fee factor
    // @param market the market address to check
    // @return key for swap fee factor
    function swapFeeFactorKey(
        address market,
        bool forPositiveImpact
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(SWAP_FEE_FACTOR, market, forPositiveImpact));
    }

    // @dev key for oracle type
    // @param token the token to check
    // @return key for oracle type
    function oracleTypeKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(ORACLE_TYPE, token));
    }

    // @dev key for open interest
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest
    function openInterestKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(OPEN_INTEREST, market, collateralToken, isLong)
            );
    }

    // @dev key for open interest in tokens
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest in tokens
    function openInterestInTokensKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    OPEN_INTEREST_IN_TOKENS,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for collateral sum for a market
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for collateral sum
    function collateralSumKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(COLLATERAL_SUM, market, collateralToken, isLong)
            );
    }

    // @dev key for amount of tokens in a market's pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's pool
    function poolAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(POOL_AMOUNT, market, token));
    }

    // @dev the key for the max amount of pool tokens
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_POOL_AMOUNT, market, token));
    }

    // @dev the key for the max amount of pool tokens for deposits
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountForDepositKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(MAX_POOL_AMOUNT_FOR_DEPOSIT, market, token));
    }

    // @dev the key for the max open interest
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function maxOpenInterestKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_OPEN_INTEREST, market, isLong));
    }

    // @dev key for amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for amount of tokens in a market's position impact pool
    function positionImpactPoolAmountKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(POSITION_IMPACT_POOL_AMOUNT, market));
    }

    // @dev key for min amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for min amount of tokens in a market's position impact pool
    function minPositionImpactPoolAmountKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_POSITION_IMPACT_POOL_AMOUNT, market));
    }

    // @dev key for position impact pool distribution rate
    // @param market the market to check
    // @return key for position impact pool distribution rate
    function positionImpactPoolDistributionRateKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(POSITION_IMPACT_POOL_DISTRIBUTION_RATE, market)
            );
    }

    // @dev key for position impact pool distributed at
    // @param market the market to check
    // @return key for position impact pool distributed at
    function positionImpactPoolDistributedAtKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(POSITION_IMPACT_POOL_DISTRIBUTED_AT, market));
    }

    // @dev key for amount of tokens in a market's swap impact pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's swap impact pool
    function swapImpactPoolAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SWAP_IMPACT_POOL_AMOUNT, market, token));
    }

    // @dev key for reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for reserve factor
    function reserveFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(RESERVE_FACTOR, market, isLong));
    }

    // @dev key for open interest reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for open interest reserve factor
    function openInterestReserveFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(OPEN_INTEREST_RESERVE_FACTOR, market, isLong));
    }

    // @dev key for max pnl factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for max pnl factor
    function maxPnlFactorKey(
        bytes32 pnlFactorType,
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(MAX_PNL_FACTOR, pnlFactorType, market, isLong)
            );
    }

    // @dev the key for min PnL factor after ADL
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function minPnlFactorAfterAdlKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_PNL_FACTOR_AFTER_ADL, market, isLong));
    }

    // @dev key for latest adl block
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for latest adl block
    function latestAdlBlockKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(LATEST_ADL_BLOCK, market, isLong));
    }

    // @dev key for whether adl is enabled
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for whether adl is enabled
    function isAdlEnabledKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(IS_ADL_ENABLED, market, isLong));
    }

    // @dev key for funding factor
    // @param market the market to check
    // @return key for funding factor
    function fundingFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_FACTOR, market));
    }

    // @dev the key for funding exponent
    // @param market the market for the pool
    function fundingExponentFactorKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_EXPONENT_FACTOR, market));
    }

    // @dev the key for saved funding factor
    // @param market the market for the pool
    function savedFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(SAVED_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev the key for funding increase factor
    // @param market the market for the pool
    function fundingIncreaseFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FUNDING_INCREASE_FACTOR_PER_SECOND, market));
    }

    // @dev the key for funding decrease factor
    // @param market the market for the pool
    function fundingDecreaseFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FUNDING_DECREASE_FACTOR_PER_SECOND, market));
    }

    // @dev the key for min funding factor
    // @param market the market for the pool
    function minFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MIN_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev the key for max funding factor
    // @param market the market for the pool
    function maxFundingFactorPerSecondKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(MAX_FUNDING_FACTOR_PER_SECOND, market));
    }

    // @dev the key for threshold for stable funding
    // @param market the market for the pool
    function thresholdForStableFundingKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(THRESHOLD_FOR_STABLE_FUNDING, market));
    }

    // @dev the key for threshold for decreasing funding
    // @param market the market for the pool
    function thresholdForDecreaseFundingKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(THRESHOLD_FOR_DECREASE_FUNDING, market));
    }

    // @dev key for funding fee amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for funding fee amount per size
    function fundingFeeAmountPerSizeKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    FUNDING_FEE_AMOUNT_PER_SIZE,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for claimabel funding amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for claimable funding amount per size
    function claimableFundingAmountPerSizeKey(
        address market,
        address collateralToken,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMABLE_FUNDING_AMOUNT_PER_SIZE,
                    market,
                    collateralToken,
                    isLong
                )
            );
    }

    // @dev key for when funding was last updated
    // @param market the market to check
    // @return key for when funding was last updated
    function fundingUpdatedAtKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FUNDING_UPDATED_AT, market));
    }

    // @dev key for claimable funding amount
    // @param market the market to check
    // @param token the token to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FUNDING_AMOUNT, market, token));
    }

    // @dev key for claimable funding amount by account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(
        address market,
        address token,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIMABLE_FUNDING_AMOUNT, market, token, account)
            );
    }

    // @dev key for claimable collateral amount
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CLAIMABLE_COLLATERAL_AMOUNT, market, token));
    }

    // @dev key for claimable collateral amount for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMABLE_COLLATERAL_AMOUNT,
                    market,
                    token,
                    timeKey,
                    account
                )
            );
    }

    // @dev key for claimable collateral factor for a timeKey
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(
        address market,
        address token,
        uint256 timeKey
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(CLAIMABLE_COLLATERAL_FACTOR, market, token, timeKey)
            );
    }

    // @dev key for claimable collateral factor for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMABLE_COLLATERAL_FACTOR,
                    market,
                    token,
                    timeKey,
                    account
                )
            );
    }

    // @dev key for claimable collateral factor
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimedCollateralAmountKey(
        address market,
        address token,
        uint256 timeKey,
        address account
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CLAIMED_COLLATERAL_AMOUNT,
                    market,
                    token,
                    timeKey,
                    account
                )
            );
    }

    // @dev key for borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for borrowing factor
    function borrowingFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(BORROWING_FACTOR, market, isLong));
    }

    // @dev the key for borrowing exponent
    // @param market the market for the pool
    // @param isLong whether to get the key for the long or short side
    function borrowingExponentFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(BORROWING_EXPONENT_FACTOR, market, isLong));
    }

    // @dev key for cumulative borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor
    function cumulativeBorrowingFactorKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(CUMULATIVE_BORROWING_FACTOR, market, isLong));
    }

    // @dev key for cumulative borrowing factor updated at
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor updated at
    function cumulativeBorrowingFactorUpdatedAtKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CUMULATIVE_BORROWING_FACTOR_UPDATED_AT,
                    market,
                    isLong
                )
            );
    }

    // @dev key for total borrowing amount
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for total borrowing amount
    function totalBorrowingKey(
        address market,
        bool isLong
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(TOTAL_BORROWING, market, isLong));
    }

    // @dev key for affiliate reward amount
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(
        address market,
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(AFFILIATE_REWARD, market, token));
    }

    function maxAllowedSubaccountActionCountKey(
        address account,
        address subaccount,
        bytes32 actionType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT,
                    account,
                    subaccount,
                    actionType
                )
            );
    }

    function subaccountActionCountKey(
        address account,
        address subaccount,
        bytes32 actionType
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SUBACCOUNT_ACTION_COUNT,
                    account,
                    subaccount,
                    actionType
                )
            );
    }

    function subaccountAutoTopUpAmountKey(
        address account,
        address subaccount
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(SUBACCOUNT_AUTO_TOP_UP_AMOUNT, account, subaccount)
            );
    }

    // @dev key for affiliate reward amount for an account
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(
        address market,
        address token,
        address account
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(AFFILIATE_REWARD, market, token, account));
    }

    // @dev key for is market disabled
    // @param market the market to check
    // @return key for is market disabled
    function isMarketDisabledKey(
        address market
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(IS_MARKET_DISABLED, market));
    }

    // @dev key for min market tokens for first deposit
    // @param market the market to check
    // @return key for min market tokens for first deposit
    function minMarketTokensForFirstDepositKey(
        address market
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT, market));
    }

    // @dev key for price feed address
    // @param token the token to get the key for
    // @return key for price feed address
    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED, token));
    }

    // @dev key for realtime feed ID
    // @param token the token to get the key for
    // @return key for realtime feed ID
    function realtimeFeedIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(REALTIME_FEED_ID, token));
    }

    // @dev key for realtime feed multiplier
    // @param token the token to get the key for
    // @return key for realtime feed multiplier
    function realtimeFeedMultiplierKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(REALTIME_FEED_MULTIPLIER, token));
    }

    // @dev key for price feed multiplier
    // @param token the token to get the key for
    // @return key for price feed multiplier
    function priceFeedMultiplierKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED_MULTIPLIER, token));
    }

    function priceFeedHeartbeatDurationKey(
        address token
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(PRICE_FEED_HEARTBEAT_DURATION, token));
    }

    // @dev key for stable price value
    // @param token the token to get the key for
    // @return key for stable price value
    function stablePriceKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(STABLE_PRICE, token));
    }

    // @dev key for fee distributor swap token index
    // @param orderKey the swap order key
    // @return key for fee distributor swap token index
    function feeDistributorSwapTokenIndexKey(
        bytes32 orderKey
    ) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX, orderKey));
    }

    // @dev key for fee distributor swap fee batch key
    // @param orderKey the swap order key
    // @return key for fee distributor swap fee batch key
    function feeDistributorSwapFeeBatchKey(
        bytes32 orderKey
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_DISTRIBUTOR_SWAP_FEE_BATCH, orderKey));
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Borrowed from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/Position.sol
// Modified as follows:
// - GoldLink types
// - removed structs

pragma solidity ^0.8.0;

import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";

library Position {
    // ============ Internal Functions ============

    function account(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.account;
    }

    function setAccount(
        IGmxV2PositionTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.account = value;
    }

    function market(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.market;
    }

    function setMarket(
        IGmxV2PositionTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.market = value;
    }

    function collateralToken(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (address) {
        return props.addresses.collateralToken;
    }

    function setCollateralToken(
        IGmxV2PositionTypes.Props memory props,
        address value
    ) internal pure {
        props.addresses.collateralToken = value;
    }

    function sizeInUsd(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.sizeInUsd;
    }

    function setSizeInUsd(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.sizeInUsd = value;
    }

    function sizeInTokens(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.sizeInTokens;
    }

    function setSizeInTokens(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.sizeInTokens = value;
    }

    function collateralAmount(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.collateralAmount;
    }

    function setCollateralAmount(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.collateralAmount = value;
    }

    function borrowingFactor(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.borrowingFactor;
    }

    function setBorrowingFactor(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.borrowingFactor = value;
    }

    function fundingFeeAmountPerSize(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.fundingFeeAmountPerSize;
    }

    function setFundingFeeAmountPerSize(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.fundingFeeAmountPerSize = value;
    }

    function longTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.longTokenClaimableFundingAmountPerSize;
    }

    function setLongTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.longTokenClaimableFundingAmountPerSize = value;
    }

    function shortTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.shortTokenClaimableFundingAmountPerSize;
    }

    function setShortTokenClaimableFundingAmountPerSize(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.shortTokenClaimableFundingAmountPerSize = value;
    }

    function increasedAtBlock(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.increasedAtBlock;
    }

    function setIncreasedAtBlock(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.increasedAtBlock = value;
    }

    function decreasedAtBlock(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.decreasedAtBlock;
    }

    function setDecreasedAtBlock(
        IGmxV2PositionTypes.Props memory props,
        uint256 value
    ) internal pure {
        props.numbers.decreasedAtBlock = value;
    }

    function isLong(
        IGmxV2PositionTypes.Props memory props
    ) internal pure returns (bool) {
        return props.flags.isLong;
    }

    function setIsLong(
        IGmxV2PositionTypes.Props memory props,
        bool value
    ) internal pure {
        props.flags.isLong = value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IWrappedNativeToken
} from "../../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import {
    IGmxV2ExchangeRouter
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ExchangeRouter.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2RoleStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2RoleStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import { ISwapCallbackRelayer } from "./ISwapCallbackRelayer.sol";

/**
 * @title IDeploymentConfiguration
 * @author GoldLink
 *
 * @dev Actions that can be performed by the GMX V2 Adapter Controller.
 */
interface IDeploymentConfiguration {
    // ============ Structs ============

    struct Deployments {
        IGmxV2ExchangeRouter exchangeRouter;
        address orderVault;
        IGmxV2Reader reader;
        IGmxV2DataStore dataStore;
        IGmxV2RoleStore roleStore;
        IGmxV2ReferralStorage referralStorage;
    }

    // ============ Events ============

    /// @notice Emitted when setting the exchange router.
    /// @param exchangeRouter The address of the exhcange router being set.
    event ExchangeRouterSet(address exchangeRouter);

    /// @notice Emitted when setting the order vault.
    /// @param orderVault The address of the order vault being set.
    event OrderVaultSet(address orderVault);

    /// @notice Emitted when setting the reader.
    /// @param reader The address of the reader being set.
    event ReaderSet(address reader);

    /// @notice Emitted when setting the data store.
    /// @param dataStore The address of the data store being set.
    event DataStoreSet(address dataStore);

    /// @notice Emitted when setting the role store.
    /// @param roleStore The address of the role store being set.
    event RoleStoreSet(address roleStore);

    /// @notice Emitted when setting the referral storage.
    /// @param referralStorage The address of the referral storage being set.
    event ReferralStorageSet(address referralStorage);

    // ============ External Functions ============

    /// @dev Set the exchange router for the strategy.
    function setExchangeRouter(IGmxV2ExchangeRouter exchangeRouter) external;

    /// @dev Set the order vault for the strategy.
    function setOrderVault(address orderVault) external;

    /// @dev Set the reader for the strategy.
    function setReader(IGmxV2Reader reader) external;

    /// @dev Set the data store for the strategy.
    function setDataStore(IGmxV2DataStore dataStore) external;

    /// @dev Set the role store for the strategy.
    function setRoleStore(IGmxV2RoleStore roleStore) external;

    /// @dev Set the referral storage for the strategy.
    function setReferralStorage(IGmxV2ReferralStorage referralStorage) external;

    /// @dev Get the configured Gmx V2 `ExchangeRouter` deployment address.
    function gmxV2ExchangeRouter() external view returns (IGmxV2ExchangeRouter);

    /// @dev Get the configured Gmx V2 `OrderVault` deployment address.
    function gmxV2OrderVault() external view returns (address);

    /// @dev Get the configured Gmx V2 `Reader` deployment address.
    function gmxV2Reader() external view returns (IGmxV2Reader);

    /// @dev Get the configured Gmx V2 `DataStore` deployment address.
    function gmxV2DataStore() external view returns (IGmxV2DataStore);

    /// @dev Get the configured Gmx V2 `RoleStore` deployment address.
    function gmxV2RoleStore() external view returns (IGmxV2RoleStore);

    /// @dev Get the configured Gmx V2 `ReferralStorage` deployment address.
    function gmxV2ReferralStorage()
        external
        view
        returns (IGmxV2ReferralStorage);

    /// @dev Get the usdc deployment address.
    function USDC() external view returns (IERC20);

    /// @dev Get the wrapped native token deployment address.
    function WRAPPED_NATIVE_TOKEN() external view returns (IWrappedNativeToken);

    /// @dev The collateral claim distributor.
    function COLLATERAL_CLAIM_DISTRIBUTOR() external view returns (address);

    /// @dev Get the wrapped native token deployment address.
    function SWAP_CALLBACK_RELAYER()
        external
        view
        returns (ISwapCallbackRelayer);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWrappedNativeToken
 * @author GoldLink
 *
 * @dev Interface for wrapping native network tokens.
 */
interface IWrappedNativeToken is IERC20 {
    // ============ External Functions ============

    /// @dev Deposit ETH into contract for wrapped tokens.
    function deposit() external payable;

    /// @dev Withdraw ETH by burning wrapped tokens.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IGmxV2OrderTypes
} from "../../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's ExchangeRouter.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/router/ExchangeRouter.sol
 */
interface IGmxV2ExchangeRouter {
    struct SimulatePricesParams {
        address[] primaryTokens;
        IGmxV2PriceTypes.Props[] primaryPrices;
    }

    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external payable;

    function sendNativeToken(address receiver, uint256 amount) external payable;

    function setSavedCallbackContract(
        address market,
        address callbackContract
    ) external payable;

    function cancelWithdrawal(bytes32 key) external payable;

    function createOrder(
        IGmxV2OrderTypes.CreateOrderParams calldata params
    ) external payable returns (bytes32);

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external payable;

    function cancelOrder(bytes32 key) external payable;

    function simulateExecuteOrder(
        bytes32 key,
        SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);

    function setUiFeeFactor(uint256 uiFeeFactor) external payable;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2RoleStore
 * @author GoldLink
 *
 * @dev Interface for the GMX role store.
 * Adapted from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/role/RoleStore.sol
 */
interface IGmxV2RoleStore {
    function hasRole(
        address account,
        bytes32 roleKey
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { ISwapCallbackHandler } from "./ISwapCallbackHandler.sol";

/**
 * @title ISwapCallbackRelayer
 * @author GoldLink
 *
 * @dev Serves as a middle man for executing the swapCallback function in order to
 * prevent any issues that arise due to signature collisions and the msg.sender context
 * of a strategyAccount.
 */
interface ISwapCallbackRelayer {
    // ============ External Functions ============

    /// @dev Relay a swap callback on behalf of another address.
    function relaySwapCallback(
        address callbackHandler,
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title ISwapCallbackHandler
 * @author GoldLink
 *
 * @dev Interfaces that implents the `handleSwapCallback` function, which allows
 * atomic swaps of spot assets for the purpose of liquidations and user profit swaps.
 */
interface ISwapCallbackHandler {
    // ============ External Functions ============

    /// @dev Handle a swap callback.
    function handleSwapCallback(
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}