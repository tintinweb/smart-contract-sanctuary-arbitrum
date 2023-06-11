// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/clearinghouse/IClearinghouse.sol";
import "./interfaces/IOffchainBook.sol";
import "./interfaces/engine/ISpotEngine.sol";
import "./interfaces/engine/IPerpEngine.sol";
import "./interfaces/engine/IProductEngine.sol";
import "./libraries/MathSD21x18.sol";
import "./libraries/RiskHelper.sol";
import "./common/Constants.sol";
import "./Version.sol";

// NOTE: not related to VertexQuerier
// custom querier contract just for queries with FNode
// VertexQuerier has some issues with abi generation
contract FQuerier is Version {
    using MathSD21x18 for int128;

    IClearinghouse private clearinghouse;
    IEndpoint private endpoint;
    ISpotEngine private spotEngine;
    IPerpEngine private perpEngine;

    function initialize(address _clearinghouse) external {
        clearinghouse = IClearinghouse(_clearinghouse);
        endpoint = IEndpoint(clearinghouse.getEndpoint());

        spotEngine = ISpotEngine(
            clearinghouse.getEngineByType(IProductEngine.EngineType.SPOT)
        );

        perpEngine = IPerpEngine(
            clearinghouse.getEngineByType(IProductEngine.EngineType.PERP)
        );
    }

    struct SpotBalance {
        uint32 productId;
        ISpotEngine.LpBalance lpBalance;
        ISpotEngine.Balance balance;
    }

    struct PerpBalance {
        uint32 productId;
        IPerpEngine.LpBalance lpBalance;
        IPerpEngine.Balance balance;
    }

    // for config just go to the chain
    struct SpotProduct {
        uint32 productId;
        int128 oraclePriceX18;
        RiskHelper.Risk risk;
        ISpotEngine.Config config;
        ISpotEngine.State state;
        ISpotEngine.LpState lpState;
        BookInfo bookInfo;
    }

    struct PerpProduct {
        uint32 productId;
        int128 oraclePriceX18;
        RiskHelper.Risk risk;
        IPerpEngine.State state;
        IPerpEngine.LpState lpState;
        BookInfo bookInfo;
    }

    struct BookInfo {
        int128 sizeIncrement;
        int128 priceIncrementX18;
        int128 minSize;
        int128 collectedFees;
        int128 lpSpreadX18;
    }

    struct HealthInfo {
        int128 assets;
        int128 liabilities;
        int128 health;
    }

    struct SubaccountInfo {
        bytes32 subaccount;
        bool exists;
        HealthInfo[] healths;
        int128[][] healthContributions;
        uint32 spotCount;
        uint32 perpCount;
        SpotBalance[] spotBalances;
        PerpBalance[] perpBalances;
        SpotProduct[] spotProducts;
        PerpProduct[] perpProducts;
    }

    struct ProductInfo {
        SpotProduct[] spotProducts;
        PerpProduct[] perpProducts;
    }

    function getClearinghouse() external view returns (address) {
        return address(clearinghouse);
    }

    function _getAllProductIds()
        internal
        view
        returns (uint32[] memory spotIds, uint32[] memory perpIds)
    {
        spotIds = spotEngine.getProductIds();
        perpIds = perpEngine.getProductIds();
    }

    function getAllProducts() public view returns (ProductInfo memory) {
        (
            uint32[] memory spotIds,
            uint32[] memory perpIds
        ) = _getAllProductIds();
        return
            ProductInfo({
                spotProducts: getSpotProducts(spotIds),
                perpProducts: getPerpProducts(perpIds)
            });
    }

    function getSpotProducts(uint32[] memory productIds)
        public
        view
        returns (SpotProduct[] memory spotProducts)
    {
        spotProducts = new SpotProduct[](productIds.length);

        for (uint32 i = 0; i < productIds.length; i++) {
            uint32 productId = productIds[i];
            spotProducts[i] = getSpotProduct(productId);
        }
    }

    function getPerpProducts(uint32[] memory productIds)
        public
        view
        returns (PerpProduct[] memory perpProducts)
    {
        perpProducts = new PerpProduct[](productIds.length);

        for (uint32 i = 0; i < productIds.length; i++) {
            uint32 productId = productIds[i];
            perpProducts[i] = getPerpProduct(productId);
        }
    }

    function getSpotProduct(uint32 productId)
        public
        view
        returns (SpotProduct memory)
    {
        (
            ISpotEngine.LpState memory lpState,
            ,
            ISpotEngine.State memory state,

        ) = spotEngine.getStatesAndBalances(productId, 0);
        int128 oraclePriceX18 = productId == QUOTE_PRODUCT_ID
            ? ONE
            : endpoint.getPricesX18((productId - 1) / 2).spotPriceX18;
        return
            SpotProduct({
                productId: productId,
                oraclePriceX18: oraclePriceX18,
                risk: clearinghouse.getRisk(productId),
                config: spotEngine.getConfig(productId),
                state: state,
                lpState: lpState,
                bookInfo: productId != 0
                    ? getBookInfo(productId, spotEngine)
                    : BookInfo(0, 0, 0, 0, 0)
            });
    }

    function getPerpProduct(uint32 productId)
        public
        view
        returns (PerpProduct memory)
    {
        (
            IPerpEngine.LpState memory lpState,
            ,
            IPerpEngine.State memory state,

        ) = perpEngine.getStatesAndBalances(productId, 0);

        return
            PerpProduct({
                productId: productId,
                oraclePriceX18: endpoint
                    .getPricesX18((productId - 1) / 2)
                    .perpPriceX18,
                risk: clearinghouse.getRisk(productId),
                state: state,
                lpState: lpState,
                bookInfo: productId != 0
                    ? getBookInfo(productId, perpEngine)
                    : BookInfo(0, 0, 0, 0, 0)
            });
    }

    function getSubaccountInfo(bytes32 subaccount)
        public
        view
        returns (SubaccountInfo memory)
    {
        SubaccountInfo memory subaccountInfo;

        {
            (
                uint32[] memory spotIds,
                uint32[] memory perpIds
            ) = _getAllProductIds();

            // initial, maintenance, pnl
            subaccountInfo.subaccount = subaccount;
            subaccountInfo.exists = true;
            subaccountInfo.healths = new HealthInfo[](3);

            uint256 productIdsLength = spotIds.length + perpIds.length;
            subaccountInfo.healthContributions = new int128[][](
                productIdsLength
            );
            for (uint256 i = 0; i < productIdsLength; i++) {
                subaccountInfo.healthContributions[i] = new int128[](3);
            }

            subaccountInfo.spotBalances = new SpotBalance[](spotIds.length);
            subaccountInfo.perpBalances = new PerpBalance[](perpIds.length);
            subaccountInfo.spotProducts = new SpotProduct[](spotIds.length);
            subaccountInfo.perpProducts = new PerpProduct[](perpIds.length);
        }

        uint32 maxHealthGroup = clearinghouse.getMaxHealthGroup();
        for (uint32 i = 0; i <= maxHealthGroup; i++) {
            IClearinghouse.HealthGroup memory group;
            group.spotId = i * 2 + 1;
            group.perpId = i * 2 + 2;
            IClearinghouseState.HealthVars memory healthVars;
            healthVars.pricesX18 = endpoint.getPricesX18(i);

            {
                (
                    ISpotEngine.LpState memory lpState,
                    ISpotEngine.LpBalance memory lpBalance,
                    ISpotEngine.State memory state,
                    ISpotEngine.Balance memory balance
                ) = spotEngine.getStatesAndBalances(group.spotId, subaccount);

                if (lpBalance.amount != 0) {
                    (int128 ammBase, int128 ammQuote) = MathHelper
                        .ammEquilibrium(
                            lpState.base.amount,
                            lpState.quote.amount,
                            healthVars.pricesX18.spotPriceX18
                        );

                    for (uint128 j = 0; j < 3; ++j) {
                        subaccountInfo.healthContributions[group.spotId][
                                j
                            ] += ammQuote.mul(lpBalance.amount).div(
                            lpState.supply
                        );
                    }

                    healthVars.spotInLpAmount = ammBase
                        .mul(lpBalance.amount)
                        .div(lpState.supply);
                }

                healthVars.spotAmount = balance.amount;
                healthVars.spotRisk = clearinghouse.getRisk(group.spotId);

                subaccountInfo.spotBalances[
                    subaccountInfo.spotCount
                ] = SpotBalance({
                    productId: group.spotId,
                    balance: balance,
                    lpBalance: lpBalance
                });
                subaccountInfo.spotProducts[
                    subaccountInfo.spotCount++
                ] = SpotProduct({
                    productId: group.spotId,
                    oraclePriceX18: healthVars.pricesX18.spotPriceX18,
                    risk: healthVars.spotRisk,
                    config: spotEngine.getConfig(group.spotId),
                    state: state,
                    lpState: lpState,
                    bookInfo: getBookInfo(group.spotId, spotEngine)
                });
            }
            {
                (
                    IPerpEngine.LpState memory lpState,
                    IPerpEngine.LpBalance memory lpBalance,
                    IPerpEngine.State memory state,
                    IPerpEngine.Balance memory balance
                ) = perpEngine.getStatesAndBalances(group.perpId, subaccount);

                if (lpBalance.amount != 0) {
                    (int128 ammBase, int128 ammQuote) = MathHelper
                        .ammEquilibrium(
                            lpState.base,
                            lpState.quote,
                            healthVars.pricesX18.perpPriceX18
                        );

                    for (uint128 j = 0; j < 3; ++j) {
                        subaccountInfo.healthContributions[group.perpId][
                                j
                            ] += ammQuote.mul(lpBalance.amount).div(
                            lpState.supply
                        );
                    }
                    healthVars.perpInLpAmount = ammBase
                        .mul(lpBalance.amount)
                        .div(lpState.supply);
                }

                for (uint128 j = 0; j < 3; ++j) {
                    subaccountInfo.healthContributions[group.perpId][
                        j
                    ] += balance.vQuoteBalance;
                }

                healthVars.perpAmount = balance.amount;
                healthVars.perpRisk = clearinghouse.getRisk(group.perpId);

                if (
                    (healthVars.spotAmount > 0) != (healthVars.perpAmount > 0)
                ) {
                    if (healthVars.spotAmount > 0) {
                        healthVars.basisAmount = MathHelper.min(
                            healthVars.spotAmount,
                            -healthVars.perpAmount
                        );
                    } else {
                        healthVars.basisAmount = MathHelper.max(
                            healthVars.spotAmount,
                            -healthVars.perpAmount
                        );
                    }
                    healthVars.spotAmount -= healthVars.basisAmount;
                    healthVars.perpAmount += healthVars.basisAmount;
                }

                subaccountInfo.perpBalances[
                    subaccountInfo.perpCount
                ] = PerpBalance({
                    productId: group.perpId,
                    balance: balance,
                    lpBalance: lpBalance
                });
                subaccountInfo.perpProducts[
                    subaccountInfo.perpCount++
                ] = PerpProduct({
                    productId: group.perpId,
                    oraclePriceX18: healthVars.pricesX18.perpPriceX18,
                    risk: healthVars.perpRisk,
                    state: state,
                    lpState: lpState,
                    bookInfo: getBookInfo(group.perpId, perpEngine)
                });
            }

            // risk for the basis trade, discounted
            if (healthVars.basisAmount != 0) {
                int128 posAmount = MathHelper.abs(healthVars.basisAmount);

                for (uint8 healthType = 0; healthType < 3; ++healthType) {
                    // add the actual value of the basis (PNL)
                    int128 totalSpreadPenalty = RiskHelper
                        ._getSpreadPenaltyX18(
                            healthVars.spotRisk,
                            healthVars.perpRisk,
                            posAmount,
                            IProductEngine.HealthType(healthType)
                        )
                        .mul(posAmount)
                        .mul(
                            healthVars.pricesX18.spotPriceX18 +
                                healthVars.pricesX18.perpPriceX18
                        );

                    subaccountInfo.healthContributions[group.spotId][
                        healthType
                    ] +=
                        healthVars.pricesX18.spotPriceX18.mul(
                            healthVars.basisAmount
                        ) -
                        totalSpreadPenalty /
                        2;
                    subaccountInfo.healthContributions[group.perpId][
                        healthType
                    ] +=
                        healthVars.pricesX18.perpPriceX18.mul(
                            -healthVars.basisAmount
                        ) -
                        totalSpreadPenalty /
                        2;
                }
            }

            // apply risk for spot and perp positions
            int128 combinedSpot = healthVars.spotAmount +
                healthVars.spotInLpAmount;

            for (uint8 healthType = 0; healthType < 3; ++healthType) {
                int128 healthContribution = RiskHelper
                    ._getWeightX18(
                        healthVars.spotRisk,
                        combinedSpot,
                        IProductEngine.HealthType(healthType)
                    )
                    .mul(combinedSpot)
                    .mul(healthVars.pricesX18.spotPriceX18);

                // Spot LP penalty
                healthContribution -= (ONE -
                    RiskHelper._getWeightX18(
                        healthVars.spotRisk,
                        healthVars.spotInLpAmount,
                        IProductEngine.HealthType(healthType)
                    )).mul(healthVars.spotInLpAmount).mul(
                        healthVars.pricesX18.spotPriceX18
                    );

                subaccountInfo.healthContributions[group.spotId][
                        healthType
                    ] += healthContribution;
            }

            int128 combinedPerp = healthVars.perpAmount +
                healthVars.perpInLpAmount;

            for (uint8 healthType = 0; healthType < 3; ++healthType) {
                int128 healthContribution = RiskHelper
                    ._getWeightX18(
                        healthVars.perpRisk,
                        combinedPerp,
                        IProductEngine.HealthType(healthType)
                    )
                    .mul(combinedPerp)
                    .mul(healthVars.pricesX18.perpPriceX18);

                // perp LP penalty
                healthContribution -= (ONE -
                    RiskHelper._getWeightX18(
                        healthVars.perpRisk,
                        healthVars.perpInLpAmount,
                        IProductEngine.HealthType(healthType)
                    )).mul(healthVars.perpInLpAmount).mul(
                        healthVars.pricesX18.perpPriceX18
                    );

                subaccountInfo.healthContributions[group.perpId][
                        healthType
                    ] += healthContribution;
            }
        }

        // handle the quote balance since its not present in healthGroups
        {
            (
                ISpotEngine.State memory state,
                ISpotEngine.Balance memory balance
            ) = spotEngine.getStateAndBalance(QUOTE_PRODUCT_ID, subaccount);
            subaccountInfo
                .spotBalances[subaccountInfo.spotCount]
                .balance = balance;
            subaccountInfo
                .spotProducts[subaccountInfo.spotCount]
                .oraclePriceX18 = ONE;
            subaccountInfo
                .spotProducts[subaccountInfo.spotCount]
                .risk = clearinghouse.getRisk(QUOTE_PRODUCT_ID);
            subaccountInfo
                .spotProducts[subaccountInfo.spotCount]
                .config = spotEngine.getConfig(QUOTE_PRODUCT_ID);
            subaccountInfo
                .spotProducts[subaccountInfo.spotCount++]
                .state = state;

            for (uint128 i = 0; i < 3; ++i) {
                subaccountInfo.healthContributions[QUOTE_PRODUCT_ID][
                    i
                ] += balance.amount;
            }
        }

        for (uint128 i = 0; i < 3; ++i) {
            for (
                uint128 j = 0;
                j < subaccountInfo.healthContributions.length;
                ++j
            ) {
                if (subaccountInfo.healthContributions[j][i] > 0) {
                    subaccountInfo.healths[i].assets += subaccountInfo
                        .healthContributions[j][i];
                } else {
                    subaccountInfo.healths[i].liabilities -= subaccountInfo
                        .healthContributions[j][i];
                }
            }
            subaccountInfo.healths[i].health =
                subaccountInfo.healths[i].assets -
                subaccountInfo.healths[i].liabilities;
        }

        return subaccountInfo;
    }

    function getSpotBalances(bytes32 subaccount, uint32[] memory productIds)
        public
        view
        returns (SpotBalance[] memory spotBalances)
    {
        spotBalances = new SpotBalance[](productIds.length);

        for (uint32 i = 0; i < productIds.length; i++) {
            uint32 productId = productIds[i];
            spotBalances[i] = getSpotBalance(subaccount, productId);
        }
    }

    function getPerpBalances(bytes32 subaccount, uint32[] memory productIds)
        public
        view
        returns (PerpBalance[] memory perpBalances)
    {
        perpBalances = new PerpBalance[](productIds.length);

        for (uint32 i = 0; i < productIds.length; i++) {
            uint32 productId = productIds[i];
            perpBalances[i] = getPerpBalance(subaccount, productId);
        }
    }

    function getSpotBalance(bytes32 subaccount, uint32 productId)
        public
        view
        returns (SpotBalance memory)
    {
        (
            ,
            ISpotEngine.LpBalance memory lpBalance,
            ,
            ISpotEngine.Balance memory balance
        ) = spotEngine.getStatesAndBalances(productId, subaccount);
        return
            SpotBalance({
                productId: productId,
                lpBalance: lpBalance,
                balance: balance
            });
    }

    function getPerpBalance(bytes32 subaccount, uint32 productId)
        public
        view
        returns (PerpBalance memory)
    {
        (
            ,
            IPerpEngine.LpBalance memory lpBalance,
            ,
            IPerpEngine.Balance memory balance
        ) = perpEngine.getStatesAndBalances(productId, subaccount);
        return
            PerpBalance({
                productId: productId,
                lpBalance: lpBalance,
                balance: balance
            });
    }

    function getBookInfo(uint32 productId, IProductEngine engine)
        public
        view
        returns (BookInfo memory bookInfo)
    {
        IOffchainBook book = IOffchainBook(engine.getOrderbook(productId));
        IOffchainBook.Market memory market = book.getMarket();
        return
            BookInfo({
                sizeIncrement: market.sizeIncrement,
                priceIncrementX18: market.priceIncrementX18,
                minSize: book.getMinSize(),
                collectedFees: market.collectedFees,
                lpSpreadX18: market.lpSpreadX18
            });
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IClearinghouseState.sol";
import "./IClearinghouseEventEmitter.sol";
import "../engine/IProductEngine.sol";
import "../IEndpoint.sol";
import "../IEndpointGated.sol";
import "../IVersion.sol";

interface IClearinghouse is
    IClearinghouseState,
    IClearinghouseEventEmitter,
    IEndpointGated,
    IVersion
{
    function addEngine(address engine, IProductEngine.EngineType engineType)
        external;

    function registerProductForId(
        address book,
        RiskStore memory riskStore,
        uint32 healthGroup
    ) external returns (uint32);

    function modifyProductConfig(uint32 productId, RiskStore memory riskStore)
        external;

    function depositCollateral(IEndpoint.DepositCollateral calldata tx)
        external;

    function withdrawCollateral(IEndpoint.WithdrawCollateral calldata tx)
        external;

    function mintLp(IEndpoint.MintLp calldata tx) external;

    function burnLp(IEndpoint.BurnLp calldata tx) external;

    function rebate(IEndpoint.Rebate calldata tx) external;

    function liquidateSubaccount(IEndpoint.LiquidateSubaccount calldata tx)
        external;

    function depositInsurance(IEndpoint.DepositInsurance calldata tx) external;

    function settlePnl(IEndpoint.SettlePnl calldata tx) external;

    function updateFeeRates(IEndpoint.UpdateFeeRates calldata tx) external;

    function claimSequencerFees(
        IEndpoint.ClaimSequencerFees calldata tx,
        int128[] calldata fees
    ) external;

    /// @notice Retrieve quote ERC20 address
    function getQuote() external view returns (address);

    /// @notice Returns all supported engine types for the clearinghouse
    function getSupportedEngines()
        external
        view
        returns (IProductEngine.EngineType[] memory);

    /// @notice Returns the registered engine address by type
    function getEngineByType(IProductEngine.EngineType engineType)
        external
        view
        returns (address);

    /// @notice Returns the engine associated with a product ID
    function getEngineByProduct(uint32 productId)
        external
        view
        returns (address);

    /// @notice Returns the orderbook associated with a product ID
    function getOrderbook(uint32 productId) external view returns (address);

    /// @notice Returns number of registered products
    function getNumProducts() external view returns (uint32);

    /// @notice Returns health for the subaccount across all engines
    function getHealth(bytes32 subaccount, IProductEngine.HealthType healthType)
        external
        view
        returns (int128);

    /// @notice Returns the amount of insurance remaining in this clearinghouse
    function getInsurance() external view returns (int128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./clearinghouse/IClearinghouse.sol";
import "./IFeeCalculator.sol";
import "./IVersion.sol";

interface IOffchainBook is IVersion {
    event FillOrder(
        // original order information
        bytes32 indexed digest,
        bytes32 indexed subaccount,
        int128 priceX18,
        int128 amount,
        uint64 expiration,
        uint64 nonce,
        // whether this order is taking or making
        bool isTaker,
        // amount paid in fees (in quote)
        int128 feeAmount,
        // change in this subaccount's base balance from this fill
        int128 baseDelta,
        // change in this subaccount's quote balance from this fill
        int128 quoteDelta
    );

    struct Market {
        uint32 productId;
        int128 sizeIncrement;
        int128 priceIncrementX18;
        int128 lpSpreadX18;
        int128 collectedFees;
        int128 sequencerFees;
    }

    function initialize(
        IClearinghouse _clearinghouse,
        IProductEngine _engine,
        address _endpoint,
        address _admin,
        IFeeCalculator _fees,
        uint32 _productId,
        int128 _sizeIncrement,
        int128 _priceIncrementX18,
        int128 _minSize,
        int128 _lpSpreadX18
    ) external;

    function modifyConfig(
        int128 _sizeIncrement,
        int128 _priceIncrementX18,
        int128 _minSize,
        int128 _lpSpreadX18
    ) external;

    function getMinSize() external view returns (int128);

    function getDigest(IEndpoint.Order memory order)
        external
        view
        returns (bytes32);

    function getMarket() external view returns (Market memory);

    function swapAMM(IEndpoint.SwapAMM calldata tx) external;

    function matchOrderAMM(
        IEndpoint.MatchOrderAMM calldata tx,
        address takerLinkedSigner
    ) external;

    function matchOrders(IEndpoint.MatchOrdersWithSigner calldata tx) external;

    function dumpFees() external;

    function claimSequencerFee() external returns (int128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IProductEngine.sol";
import "../clearinghouse/IClearinghouseState.sol";

interface ISpotEngine is IProductEngine {
    struct Config {
        address token;
        int128 interestInflectionUtilX18;
        int128 interestFloorX18;
        int128 interestSmallCapX18;
        int128 interestLargeCapX18;
    }

    struct State {
        int128 cumulativeDepositsMultiplierX18;
        int128 cumulativeBorrowsMultiplierX18;
        int128 totalDepositsNormalized;
        int128 totalBorrowsNormalized;
    }

    struct Balance {
        int128 amount;
        int128 lastCumulativeMultiplierX18;
    }

    struct BalanceNormalized {
        int128 amountNormalized;
    }

    struct LpState {
        int128 supply;
        Balance quote;
        Balance base;
    }

    struct LpBalance {
        int128 amount;
    }

    struct Balances {
        BalanceNormalized balance;
        LpBalance lpBalance;
    }

    struct UpdateProductTx {
        uint32 productId;
        int128 sizeIncrement;
        int128 priceIncrementX18;
        int128 minSize;
        int128 lpSpreadX18;
        Config config;
        IClearinghouseState.RiskStore riskStore;
    }

    function getStateAndBalance(uint32 productId, bytes32 subaccount)
        external
        view
        returns (State memory, Balance memory);

    function getBalance(uint32 productId, bytes32 subaccount)
        external
        view
        returns (Balance memory);

    function hasBalance(uint32 productId, bytes32 subaccount)
        external
        view
        returns (bool);

    function getStatesAndBalances(uint32 productId, bytes32 subaccount)
        external
        view
        returns (
            LpState memory,
            LpBalance memory,
            State memory,
            Balance memory
        );

    function getBalances(uint32 productId, bytes32 subaccount)
        external
        view
        returns (LpBalance memory, Balance memory);

    function getLpState(uint32 productId)
        external
        view
        returns (LpState memory);

    function getConfig(uint32 productId) external view returns (Config memory);

    function getWithdrawFee(uint32 productId) external view returns (int128);

    function updateStates(uint128 dt) external;

    function manualAssert(
        int128[] calldata totalDeposits,
        int128[] calldata totalBorrows
    ) external view;

    function socializeSubaccount(bytes32 subaccount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IProductEngine.sol";
import "../clearinghouse/IClearinghouseState.sol";

interface IPerpEngine is IProductEngine {
    struct State {
        int128 cumulativeFundingLongX18;
        int128 cumulativeFundingShortX18;
        int128 availableSettle;
        int128 openInterest;
    }

    struct Balance {
        int128 amount;
        int128 vQuoteBalance;
        int128 lastCumulativeFundingX18;
    }

    struct LpState {
        int128 supply;
        // TODO: this should be removed; we can just get it from State.cumulativeFundingLongX18
        int128 lastCumulativeFundingX18;
        int128 cumulativeFundingPerLpX18;
        int128 base;
        int128 quote;
    }

    struct LpBalance {
        int128 amount;
        // NOTE: funding payments should be rolled
        // into Balance.vQuoteBalance;
        int128 lastCumulativeFundingX18;
    }

    struct UpdateProductTx {
        uint32 productId;
        int128 sizeIncrement;
        int128 priceIncrementX18;
        int128 minSize;
        int128 lpSpreadX18;
        IClearinghouseState.RiskStore riskStore;
    }

    function getStateAndBalance(uint32 productId, bytes32 subaccount)
        external
        view
        returns (State memory, Balance memory);

    function getBalance(uint32 productId, bytes32 subaccount)
        external
        view
        returns (Balance memory);

    function hasBalance(uint32 productId, bytes32 subaccount)
        external
        view
        returns (bool);

    function getStatesAndBalances(uint32 productId, bytes32 subaccount)
        external
        view
        returns (
            LpState memory,
            LpBalance memory,
            State memory,
            Balance memory
        );

    function getBalances(uint32 productId, bytes32 subaccount)
        external
        view
        returns (LpBalance memory, Balance memory);

    function getLpState(uint32 productId)
        external
        view
        returns (LpState memory);

    /// @dev Returns amount settled and emits SettlePnl events for each product
    function settlePnl(bytes32 subaccount, uint256 productIds)
        external
        returns (int128);

    function getSettlementState(uint32 productId, bytes32 subaccount)
        external
        view
        returns (
            int128 availableSettle,
            LpState memory lpState,
            LpBalance memory lpBalance,
            State memory state,
            Balance memory balance
        );

    function updateStates(uint128 dt, int128[] calldata avgPriceDiffs) external;

    function manualAssert(int128[] calldata openInterests) external view;

    function getPositionPnl(uint32 productId, bytes32 subaccount)
        external
        view
        returns (int128);

    function socializeSubaccount(bytes32 subaccount, int128 insurance)
        external
        returns (int128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../clearinghouse/IClearinghouse.sol";
import "./IProductEngineState.sol";

interface IProductEngine is IProductEngineState {
    event AddProduct(uint32 productId);

    enum EngineType {
        SPOT,
        PERP
    }

    enum HealthType {
        INITIAL,
        MAINTENANCE,
        PNL
    }

    struct ProductDelta {
        uint32 productId;
        bytes32 subaccount;
        int128 amountDelta;
        int128 vQuoteDelta;
    }

    /// @notice Initializes the engine
    function initialize(
        address _clearinghouse,
        address _quote,
        address _endpoint,
        address _admin,
        address _fees
    ) external;

    /// @notice updates internal balances; given tuples of (product, subaccount, delta)
    /// since tuples aren't a thing in solidity, params specify the transpose
    function applyDeltas(ProductDelta[] calldata deltas) external;

    function updateProduct(bytes calldata txn) external;

    function swapLp(
        uint32 productId,
        int128 amount,
        int128 priceX18,
        int128 sizeIncrement,
        int128 lpSpreadX18
    ) external returns (int128, int128);

    function swapLp(
        uint32 productId,
        int128 baseDelta,
        int128 quoteDelta
    ) external returns (int128, int128);

    function mintLp(
        uint32 productId,
        bytes32 subaccount,
        int128 amountBase,
        int128 quoteAmountLow,
        int128 quoteAmountHigh
    ) external;

    function burnLp(
        uint32 productId,
        bytes32 subaccount,
        // passing 0 here means to burn all
        int128 amountLp
    ) external returns (int128);

    function decomposeLps(
        bytes32 liquidatee,
        bytes32 liquidator,
        address feeCalculator
    ) external returns (int128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "prb-math/contracts/PRBMathSD59x18.sol";

library MathSD21x18 {
    using PRBMathSD59x18 for int256;

    int128 private constant ONE_X18 = 1000000000000000000;
    int128 private constant MIN_X18 = -0x80000000000000000000000000000000;
    int128 private constant MAX_X18 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    string private constant ERR_OVERFLOW = "OF";
    string private constant ERR_DIV_BY_ZERO = "DBZ";

    function fromInt(int128 x) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) * ONE_X18;
            require(result >= MIN_X18 && result <= MAX_X18, ERR_OVERFLOW);
            return int128(result);
        }
    }

    function toInt(int128 x) internal pure returns (int128) {
        unchecked {
            return int128(x / ONE_X18);
        }
    }

    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_X18 && result <= MAX_X18, ERR_OVERFLOW);
            return int128(result);
        }
    }

    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_X18 && result <= MAX_X18, ERR_OVERFLOW);
            return int128(result);
        }
    }

    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) / ONE_X18;
            require(result >= MIN_X18 && result <= MAX_X18, ERR_OVERFLOW);
            return int128(result);
        }
    }

    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0, ERR_DIV_BY_ZERO);
            int256 result = (int256(x) * ONE_X18) / y;
            require(result >= MIN_X18 && result <= MAX_X18, ERR_OVERFLOW);
            return int128(result);
        }
    }

    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_X18, ERR_OVERFLOW);
            return x < 0 ? -x : x;
        }
    }

    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x).sqrt();
            require(result >= MIN_X18 && result <= MAX_X18, ERR_OVERFLOW);
            return int128(result);
        }
    }

    // note that y is not X18
    function pow(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y >= 0, ERR_OVERFLOW);
            int128 result = ONE_X18;
            for (int128 i = 1; i <= y; i *= 2) {
                if (i & y != 0) {
                    result = mul(result, x);
                }
                x = mul(x, x);
            }
            return result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./MathSD21x18.sol";
import "../interfaces/engine/IProductEngine.sol";
import "../common/Constants.sol";
import "./MathHelper.sol";

/// @title RiskHelper
/// @dev Provides basic math functions
library RiskHelper {
    using MathSD21x18 for int128;

    struct Risk {
        int128 longWeightInitialX18;
        int128 shortWeightInitialX18;
        int128 longWeightMaintenanceX18;
        int128 shortWeightMaintenanceX18;
        int128 largePositionPenaltyX18;
    }

    function _getSpreadPenaltyX18(
        Risk memory spotRisk,
        Risk memory perpRisk,
        int128 amount,
        IProductEngine.HealthType healthType
    ) internal pure returns (int128) {
        return
            (ONE - _getWeightX18(spotRisk, amount, healthType)).mul(
                ONE - _getWeightX18(perpRisk, amount, healthType)
            );
    }

    function _getWeightX18(
        Risk memory risk,
        int128 amount,
        IProductEngine.HealthType healthType
    ) internal pure returns (int128) {
        // (1 + imf * sqrt(amount))
        if (healthType == IProductEngine.HealthType.PNL) {
            return ONE;
        }

        int128 weight;
        if (amount >= 0) {
            weight = healthType == IProductEngine.HealthType.INITIAL
                ? risk.longWeightInitialX18
                : risk.longWeightMaintenanceX18;
        } else {
            weight = healthType == IProductEngine.HealthType.INITIAL
                ? risk.shortWeightInitialX18
                : risk.shortWeightMaintenanceX18;
        }

        if (risk.largePositionPenaltyX18 > 0) {
            if (amount > 0) {
                // 1.1 / (1 + imf * sqrt(amount))
                int128 threshold_sqrt = (int128(11e17).div(weight) - ONE).div(
                    risk.largePositionPenaltyX18
                );
                if (amount.abs() > threshold_sqrt.mul(threshold_sqrt)) {
                    weight = int128(11e17).div(
                        ONE +
                            risk.largePositionPenaltyX18.mul(
                                amount.abs().sqrt()
                            )
                    );
                }
            } else {
                // 0.9 * (1 + imf * sqrt(amount))
                int128 threshold_sqrt = (weight.div(int128(9e17)) - ONE).div(
                    risk.largePositionPenaltyX18
                );
                if (amount.abs() > threshold_sqrt.mul(threshold_sqrt)) {
                    weight = int128(9e17).mul(
                        ONE +
                            risk.largePositionPenaltyX18.mul(
                                amount.abs().sqrt()
                            )
                    );
                }
            }
        }

        return weight;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @dev Each clearinghouse has a unique quote product
uint32 constant QUOTE_PRODUCT_ID = 0;

/// @dev Fees account
bytes32 constant FEES_ACCOUNT = bytes32(0);

uint128 constant MINIMUM_LIQUIDITY = 10**3;

int128 constant ONE = 10**18;

uint8 constant MAX_DECIMALS = 18;

int128 constant TAKER_SEQUENCER_FEE = 4e17; // $0.40

int128 constant SLOW_MODE_FEE = 1000000; // $1

int128 constant LIQUIDATION_FEE = 1e18; // $1
int128 constant HEALTHCHECK_FEE = 1e18; // $1

uint64 constant VERSION = 16;

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./common/Constants.sol";
import "./interfaces/IVersion.sol";

abstract contract Version is IVersion {
    function getVersion() external pure returns (uint64) {
        return VERSION;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../engine/IProductEngine.sol";
import "../IEndpoint.sol";
import "../../libraries/RiskHelper.sol";

interface IClearinghouseState {
    struct RiskStore {
        // these weights are all
        // between 0 and 2
        // these integers are the real
        // weights times 1e9
        int32 longWeightInitial;
        int32 shortWeightInitial;
        int32 longWeightMaintenance;
        int32 shortWeightMaintenance;
        int32 largePositionPenalty;
    }

    struct HealthGroup {
        uint32 spotId;
        uint32 perpId;
    }

    struct HealthVars {
        int128 spotAmount;
        int128 perpAmount;
        // 1 unit of basis amount is 1 unit long spot and 1 unit short perp
        int128 basisAmount;
        int128 spotInLpAmount;
        int128 perpInLpAmount;
        IEndpoint.Prices pricesX18;
        RiskHelper.Risk spotRisk;
        RiskHelper.Risk perpRisk;
    }

    function getMaxHealthGroup() external view returns (uint32);

    function getRisk(uint32 productId)
        external
        view
        returns (RiskHelper.Risk memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IClearinghouseEventEmitter {
    /// @notice Emitted during initialization
    event ClearinghouseInitialized(
        address endpoint,
        address quote,
        address fees
    );

    /// @notice Emitted when collateral is modified for a subaccount
    event ModifyCollateral(
        int128 amount,
        bytes32 indexed subaccount,
        uint32 productId
    );

    event Liquidation(
        bytes32 indexed liquidatorSubaccount,
        bytes32 indexed liquidateeSubaccount,
        uint8 indexed mode,
        uint32 healthGroup,
        int128 amount,
        int128 amountQuote,
        int128 insuranceCover
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./clearinghouse/IClearinghouse.sol";
import "./IVersion.sol";

interface IEndpoint is IVersion {
    event SubmitTransactions();

    event SubmitSlowModeTransaction(
        uint64 executableAt,
        address sender,
        bytes tx
    );

    // events that we parse transactions into
    enum TransactionType {
        LiquidateSubaccount,
        DepositCollateral,
        WithdrawCollateral,
        SpotTick,
        UpdatePrice,
        SettlePnl,
        MatchOrders,
        DepositInsurance,
        ExecuteSlowMode,
        MintLp,
        BurnLp,
        SwapAMM,
        MatchOrderAMM,
        DumpFees,
        ClaimSequencerFees,
        PerpTick,
        ManualAssert,
        Rebate,
        UpdateProduct,
        LinkSigner,
        UpdateFeeRates
    }

    struct UpdateProduct {
        address engine;
        bytes tx;
    }

    /// requires signature from sender
    enum LiquidationMode {
        SPREAD,
        SPOT,
        PERP
    }

    struct LiquidateSubaccount {
        bytes32 sender;
        bytes32 liquidatee;
        uint8 mode;
        uint32 healthGroup;
        int128 amount;
        uint64 nonce;
    }

    struct SignedLiquidateSubaccount {
        LiquidateSubaccount tx;
        bytes signature;
    }

    struct DepositCollateral {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
    }

    struct SignedDepositCollateral {
        DepositCollateral tx;
        bytes signature;
    }

    struct WithdrawCollateral {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
        uint64 nonce;
    }

    struct SignedWithdrawCollateral {
        WithdrawCollateral tx;
        bytes signature;
    }

    struct MintLp {
        bytes32 sender;
        uint32 productId;
        uint128 amountBase;
        uint128 quoteAmountLow;
        uint128 quoteAmountHigh;
        uint64 nonce;
    }

    struct SignedMintLp {
        MintLp tx;
        bytes signature;
    }

    struct BurnLp {
        bytes32 sender;
        uint32 productId;
        uint128 amount;
        uint64 nonce;
    }

    struct SignedBurnLp {
        BurnLp tx;
        bytes signature;
    }

    struct LinkSigner {
        bytes32 sender;
        bytes32 signer;
        uint64 nonce;
    }

    struct SignedLinkSigner {
        LinkSigner tx;
        bytes signature;
    }

    /// callable by endpoint; no signature verifications needed
    struct PerpTick {
        uint128 time;
        int128[] avgPriceDiffs;
    }

    struct SpotTick {
        uint128 time;
    }

    struct ManualAssert {
        int128[] openInterests;
        int128[] totalDeposits;
        int128[] totalBorrows;
    }

    struct Rebate {
        bytes32[] subaccounts;
        int128[] amounts;
    }

    struct UpdateFeeRates {
        address user;
        uint32 productId;
        // the absolute value of fee rates can't be larger than 100%,
        // so their X18 values are in the range [-1e18, 1e18], which
        // can be stored by using int64.
        int64 makerRateX18;
        int64 takerRateX18;
    }

    struct ClaimSequencerFees {
        bytes32 subaccount;
    }

    struct UpdatePrice {
        uint32 productId;
        int128 priceX18;
    }

    struct SettlePnl {
        bytes32[] subaccounts;
        uint256[] productIds;
    }

    /// matching
    struct Order {
        bytes32 sender;
        int128 priceX18;
        int128 amount;
        uint64 expiration;
        uint64 nonce;
    }

    struct SignedOrder {
        Order order;
        bytes signature;
    }

    struct MatchOrders {
        uint32 productId;
        bool amm; // whether taker order should hit AMM first (deprecated)
        SignedOrder taker;
        SignedOrder maker;
    }

    struct MatchOrdersWithSigner {
        MatchOrders matchOrders;
        address takerLinkedSigner;
        address makerLinkedSigner;
    }

    // just swap against AMM -- theres no maker order
    struct MatchOrderAMM {
        uint32 productId;
        int128 baseDelta;
        int128 quoteDelta;
        SignedOrder taker;
    }

    struct SwapAMM {
        bytes32 sender;
        uint32 productId;
        int128 amount;
        int128 priceX18;
    }

    struct DepositInsurance {
        uint128 amount;
    }

    struct SignedDepositInsurance {
        DepositInsurance tx;
        bytes signature;
    }

    struct SlowModeTx {
        uint64 executableAt;
        address sender;
        bytes tx;
    }

    struct SlowModeConfig {
        uint64 timeout;
        uint64 txCount;
        uint64 txUpTo;
    }

    struct Prices {
        int128 spotPriceX18;
        int128 perpPriceX18;
    }

    function depositCollateral(
        bytes12 subaccountName,
        uint32 productId,
        uint128 amount
    ) external;

    function setBook(uint32 productId, address book) external;

    function submitTransactionsChecked(
        uint64 idx,
        bytes[] calldata transactions
    ) external;

    function submitSlowModeTransaction(bytes calldata transaction) external;

    function getPriceX18(uint32 productId) external view returns (int128);

    function getPricesX18(uint32 healthGroup)
        external
        view
        returns (Prices memory);

    function getTime() external view returns (uint128);

    function getNonce(address sender) external view returns (uint64);

    function getNumSubaccounts() external view returns (uint64);

    function getSubaccountId(bytes32 subaccount) external view returns (uint64);

    function getSubaccountById(uint64 subaccountId)
        external
        view
        returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

import "./IEndpoint.sol";

interface IEndpointGated {
    // this is all that remains lol, everything else is private or a modifier etc.
    function getOraclePriceX18(uint32 productId) external view returns (int128);

    function getOraclePricesX18(uint32 healthGroup)
        external
        view
        returns (IEndpoint.Prices memory);

    function getEndpoint() external view returns (address endpoint);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVersion {
    function getVersion() external returns (uint64);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IProductEngine.sol";

interface IProductEngineState {
    /// @notice return clearinghouse addr
    function getClearinghouse() external view returns (address);

    /// @notice return productIds associated with engine
    function getProductIds() external view returns (uint32[] memory);

    /// @notice return the type of engine
    function getEngineType() external pure returns (IProductEngine.EngineType);

    /// @notice Returns orderbook for a product ID
    function getOrderbook(uint32 productId) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./MathSD21x18.sol";

/// @title MathHelper
/// @dev Provides basic math functions
library MathHelper {
    using MathSD21x18 for int128;

    /// @notice Returns market id for two given product ids
    function max(int128 a, int128 b) internal pure returns (int128) {
        return a > b ? a : b;
    }

    function min(int128 a, int128 b) internal pure returns (int128) {
        return a < b ? a : b;
    }

    function abs(int128 val) internal pure returns (int128) {
        return val < 0 ? -val : val;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(int128 y) internal pure returns (int128 z) {
        require(y >= 0, "ds-math-sqrt-non-positive");
        if (y > 3) {
            z = y;
            int128 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function sqrt256(int256 y) internal pure returns (int256 z) {
        require(y >= 0, "ds-math-sqrt-non-positive");
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
    }

    function int2str(int128 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        bool negative = value < 0;
        uint128 absval = uint128(negative ? -value : value);
        string memory out = uint2str(absval);
        if (negative) {
            out = string.concat("-", out);
        }
        return out;
    }

    function uint2str(uint128 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint128 temp = value;
        uint128 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint128(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SignedSafeMath.sol#L86
    function add(int128 x, int128 y) internal pure returns (int128) {
        int128 z = x + y;
        require((y >= 0 && z >= x) || (y < 0 && z < x), "ds-math-add-overflow");
        return z;
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.1.0/contracts/math/SignedSafeMath.sol#L69
    function sub(int128 x, int128 y) internal pure returns (int128) {
        int128 z = x - y;
        require(
            (y >= 0 && z <= x) || (y < 0 && z > x),
            "ds-math-sub-underflow"
        );
        return z;
    }

    function mul(int128 x, int128 y) internal pure returns (int128 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function floor(int128 x, int128 y) internal pure returns (int128 z) {
        require(y > 0, "ds-math-floor-neg-mod");
        int128 r = x % y;
        if (r == 0) {
            z = x;
        } else {
            z = (x >= 0 ? x - r : x - r - y);
        }
    }

    function ceil(int128 x, int128 y) internal pure returns (int128 z) {
        require(y > 0, "ds-math-ceil-neg-mod");
        int128 r = x % y;
        if (r == 0) {
            z = x;
        } else {
            z = (x >= 0 ? x + y - r : x - r);
        }
    }

    // we don't need to floor base with sizeIncrement in this function
    // because this function is only used by `view` functions, which means
    // the returned values will not be written into storage.
    function ammEquilibrium(
        int128 base,
        int128 quote,
        int128 priceX18
    ) internal pure returns (int128, int128) {
        if (base == 0 || quote == 0) {
            return (0, 0);
        }
        int256 k = int256(base) * quote;
        // base * price * base == k
        // base = sqrt(k / price);
        base = int128(MathHelper.sqrt256((k * 1e18) / priceX18));
        quote = (base == 0) ? int128(0) : int128(k / base);
        return (base, quote);
    }

    function isSwapValid(
        int128 baseDelta,
        int128 quoteDelta,
        int128 base,
        int128 quote
    ) internal pure returns (bool) {
        if (
            base == 0 ||
            quote == 0 ||
            base + baseDelta <= 0 ||
            quote + quoteDelta <= 0
        ) {
            return false;
        }
        int256 kPrev = int256(base) * quote;
        int256 kNew = int256(base + baseDelta) * (quote + quoteDelta);
        return kNew > kPrev;
    }

    function swap(
        int128 amountSwap,
        int128 base,
        int128 quote,
        int128 priceX18,
        int128 sizeIncrement,
        int128 lpSpreadX18
    ) internal pure returns (int128, int128) {
        // (amountSwap % sizeIncrement) is guaranteed to be 0
        if (base == 0 || quote == 0) {
            return (0, 0);
        }
        int128 currentPriceX18 = quote.div(base);

        int128 keepRateX18 = 1e18 - lpSpreadX18;

        // selling
        if (amountSwap > 0) {
            priceX18 = priceX18.div(keepRateX18);
            if (priceX18 >= currentPriceX18) {
                return (0, 0);
            }
        } else {
            priceX18 = priceX18.mul(keepRateX18);
            if (priceX18 <= currentPriceX18) {
                return (0, 0);
            }
        }

        int256 k = int256(base) * quote;
        int128 baseAtPrice = int128(
            (MathHelper.sqrt256(k) * 1e9) / MathHelper.sqrt(priceX18)
        );
        // base -> base + amountSwap

        int128 baseSwapped;

        if (
            (amountSwap > 0 && base + amountSwap > baseAtPrice) ||
            (amountSwap < 0 && base + amountSwap < baseAtPrice)
        ) {
            // we hit price limits before we exhaust amountSwap
            if (baseAtPrice >= base) {
                baseSwapped = MathHelper.floor(
                    baseAtPrice - base,
                    sizeIncrement
                );
            } else {
                baseSwapped = MathHelper.ceil(
                    baseAtPrice - base,
                    sizeIncrement
                );
            }
        } else {
            // just swap it all
            // amountSwap is already guaranteed to adhere to sizeIncrement
            baseSwapped = amountSwap;
        }

        int128 quoteSwapped = int128(k / (base + baseSwapped) - quote);
        if (amountSwap > 0) {
            quoteSwapped = quoteSwapped.mul(keepRateX18);
        } else {
            quoteSwapped = quoteSwapped.div(keepRateX18);
        }
        return (baseSwapped, quoteSwapped);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
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

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./IVersion.sol";

interface IFeeCalculator is IVersion {
    struct FeeRates {
        int64 makerRateX18;
        int64 takerRateX18;
        uint8 isNonDefault; // 1: non-default, 0: default
    }

    function getClearinghouse() external view returns (address);

    function migrate(address _clearinghouse) external;

    function recordVolume(bytes32 subaccount, uint128 quoteVolume) external;

    function getFeeFractionX18(
        bytes32 subaccount,
        uint32 productId,
        bool taker
    ) external view returns (int128);

    function getInterestFeeFractionX18(uint32 productId)
        external
        view
        returns (int128);

    function getLiquidationFeeFractionX18(bytes32 subaccount, uint32 productId)
        external
        view
        returns (int128);

    function updateFeeRates(
        address user,
        uint32 productId,
        int64 makerRateX18,
        int64 takerRateX18
    ) external;
}