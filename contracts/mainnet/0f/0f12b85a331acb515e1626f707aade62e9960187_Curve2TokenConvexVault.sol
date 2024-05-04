// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {Deployments} from "@deployments/Deployments.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {IERC20, TokenUtils} from "@contracts/utils/TokenUtils.sol";
import {ConvexStakingMixin, ConvexVaultDeploymentParams} from "./mixins/ConvexStakingMixin.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {IConvexBooster, IConvexBoosterArbitrum} from "@interfaces/convex/IConvexBooster.sol";
import {IConvexRewardPool, IConvexRewardPoolArbitrum} from "@interfaces/convex/IConvexRewardPool.sol";
import {
    CurveInterface,
    ICurvePool,
    ICurve2TokenPoolV1,
    ICurve2TokenPoolV2,
    ICurveStableSwapNG
} from "@interfaces/curve/ICurvePool.sol";

contract Curve2TokenConvexVault is ConvexStakingMixin {
    // This contract does not properly support Curve pools where one of the tokens is
    // held as an LP token. However, unlike Balancer pools there is no reliable way to
    // determine if the token held in the Curve pool is an LP token or not, therefore
    // we do not have an explicit check here.
    constructor(NotionalProxy notional_, ConvexVaultDeploymentParams memory params) 
        ConvexStakingMixin(notional_, params) {}

    function strategy() external override pure returns (bytes4) {
        return bytes4(keccak256("Curve2TokenConvexVault"));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

import {Constants} from "../Constants.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {IWstETH} from "@interfaces/IWstETH.sol";
import {IBalancerVault, IAsset} from "@interfaces/balancer/IBalancerVault.sol";
import {WETH9} from "@interfaces/WETH9.sol";
import {ISwapRouter as UniV3ISwapRouter} from "@interfaces/uniswap/v3/ISwapRouter.sol";
import {IUniV2Router2} from "@interfaces/uniswap/v2/IUniV2Router2.sol";
import {ICurveRouter} from "@interfaces/curve/ICurveRouter.sol";
import {ICurveRegistry} from "@interfaces/curve/ICurveRegistry.sol";
import {ICurveMetaRegistry} from "@interfaces/curve/ICurveMetaRegistry.sol";
import {ICurveRouterV2} from "@interfaces/curve/ICurveRouterV2.sol";
import {ITradingModule} from "@interfaces/trading/ITradingModule.sol";
import {IWrappedfCashFactory} from "@interfaces/notional/IWrappedfCashFactory.sol";
import {AggregatorV2V3Interface} from "@interfaces/chainlink/AggregatorV2V3Interface.sol";

library Deployments {
    uint256 internal constant CHAIN_ID = Constants.CHAIN_ID_ARBITRUM;
    NotionalProxy internal constant NOTIONAL = NotionalProxy(0x1344A36A1B56144C3Bc62E7757377D288fDE0369);
    address internal constant ETH_ADDRESS = address(0);
    WETH9 internal constant WETH =
        WETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IBalancerVault internal constant BALANCER_VAULT =
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    UniV3ISwapRouter internal constant UNIV3_ROUTER = UniV3ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address internal constant ZERO_EX = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    IUniV2Router2 internal constant UNIV2_ROUTER = IUniV2Router2(address(0));

    address internal constant ALT_ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ICurveRouterV2 public constant CURVE_ROUTER_V2 = ICurveRouterV2(0x4c2Af2Df2a7E567B5155879720619EA06C5BB15D);
    // Curve meta registry is not deployed on arbitrum
    ICurveMetaRegistry public constant CURVE_META_REGISTRY = ICurveMetaRegistry(address(0));
    address internal constant CURVE_V1_HANDLER = address(0);
    address internal constant CURVE_V2_HANDLER = address(0);
    address internal constant CURVE_MINTER = 0xabC000d88f23Bb45525E447528DBF656A9D55bf5;
    ITradingModule internal constant TRADING_MODULE = ITradingModule(0xBf6B9c5608D520469d8c4BD1E24F850497AF0Bb8);
    address internal constant TREASURY_MANAGER = 0x53144559C0d4a3304e2DD9dAfBD685247429216d;
    address internal constant EMERGENCY_EXIT_MANAGER = 0xbf778Fc19d0B55575711B6339A3680d07352B221;
    address internal constant BALANCER_SPOT_PRICE = 0x904d881ceC1b8bc3f3Ff32cCf9533c1843706E9e;
    IWrappedfCashFactory internal constant WRAPPED_FCASH_FACTORY = IWrappedfCashFactory(0x5D051DeB5db151C2172dCdCCD42e6A2953E27261);

    // Chainlink L2 Sequencer Uptime: https://docs.chain.link/data-feeds/l2-sequencer-feeds/
    AggregatorV2V3Interface internal constant SEQUENCER_UPTIME_ORACLE = AggregatorV2V3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    address internal constant AAVE_LENDER = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/// @title All shared constants for the Notional system should be declared here.
library Constants {
    uint8 internal constant CETH_DECIMAL_PLACES = 8;

    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant INCENTIVE_ACCUMULATION_PRECISION = 1e18;

    // ETH will be initialized as the first currency
    address internal constant ETH_ADDRESS = address(0);
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint8 internal constant ETH_DECIMAL_PLACES = 18;
    int256 internal constant ETH_DECIMALS = 1e18;
    // Used to prevent overflow when converting decimal places to decimal precision values via
    // 10**decimalPlaces. This is a safe value for int256 and uint256 variables. We apply this
    // constraint when storing decimal places in governance.
    uint256 internal constant MAX_DECIMAL_PLACES = 36;

    // Address of the reserve account
    address internal constant RESERVE = address(0);

    // Most significant bit
    bytes32 internal constant MSB = 0x8000000000000000000000000000000000000000000000000000000000000000;

    // Each bit set in this mask marks where an active market should be in the bitmap
    // if the first bit refers to the reference time. Used to detect idiosyncratic
    // fcash in the nToken accounts
    bytes32 internal constant ACTIVE_MARKETS_MASK = (
        MSB >> ( 90 - 1) | // 3 month
        MSB >> (105 - 1) | // 6 month
        MSB >> (135 - 1) | // 1 year
        MSB >> (147 - 1) | // 2 year
        MSB >> (183 - 1) | // 5 year
        MSB >> (211 - 1) | // 10 year
        MSB >> (251 - 1)   // 20 year
    );

    // Basis for percentages
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    // Max number of traded markets, also used as the maximum number of assets in a portfolio array
    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;
    // Max number of fCash assets in a bitmap, this is based on the gas costs of calculating free collateral
    // for a bitmap portfolio
    uint256 internal constant MAX_BITMAP_ASSETS = 20;
    uint256 internal constant FIVE_MINUTES = 300;

    // Internal date representations, note we use a 6/30/360 week/month/year convention here
    uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;

    // These constants are used in DateTime.sol
    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    // Offsets for each time chunk denominated in days
    uint256 internal constant MAX_DAY_OFFSET = 90;
    uint256 internal constant MAX_WEEK_OFFSET = 360;
    uint256 internal constant MAX_MONTH_OFFSET = 2160;
    uint256 internal constant MAX_QUARTER_OFFSET = 7650;

    // Offsets for each time chunk denominated in bits
    uint256 internal constant WEEK_BIT_OFFSET = 90;
    uint256 internal constant MONTH_BIT_OFFSET = 135;
    uint256 internal constant QUARTER_BIT_OFFSET = 195;

    // This is a constant that represents the time period that all rates are normalized by, 360 days
    uint256 internal constant IMPLIED_RATE_TIME = 360 * DAY;
    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
    // One basis point in RATE_PRECISION terms
    uint256 internal constant BASIS_POINT = uint256(RATE_PRECISION / 10000);
    // Used to when calculating the amount to deleverage of a market when minting nTokens
    uint256 internal constant DELEVERAGE_BUFFER = 300 * BASIS_POINT;
    // Used for scaling cash group factors
    uint256 internal constant FIVE_BASIS_POINTS = 5 * BASIS_POINT;
    // Used for residual purchase incentive and cash withholding buffer
    uint256 internal constant TEN_BASIS_POINTS = 10 * BASIS_POINT;

    // This is the ABDK64x64 representation of RATE_PRECISION
    // RATE_PRECISION_64x64 = ABDKMath64x64.fromUint(RATE_PRECISION)
    int128 internal constant RATE_PRECISION_64x64 = 0x3b9aca000000000000000000;
    int128 internal constant LOG_RATE_PRECISION_64x64 = 382276781265598821176;
    // Limit the market proportion so that borrowing cannot hit extremely high interest rates
    int256 internal constant MAX_MARKET_PROPORTION = RATE_PRECISION * 99 / 100;

    uint8 internal constant FCASH_ASSET_TYPE = 1;
    // Liquidity token asset types are 1 + marketIndex (where marketIndex is 1-indexed)
    uint8 internal constant MIN_LIQUIDITY_TOKEN_INDEX = 2;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;

    // Used for converting bool to bytes1, solidity does not have a native conversion
    // method for this
    bytes1 internal constant BOOL_FALSE = 0x00;
    bytes1 internal constant BOOL_TRUE = 0x01;

    // Account context flags
    bytes1 internal constant HAS_ASSET_DEBT = 0x01;
    bytes1 internal constant HAS_CASH_DEBT = 0x02;
    bytes2 internal constant ACTIVE_IN_PORTFOLIO = 0x8000;
    bytes2 internal constant ACTIVE_IN_BALANCES = 0x4000;
    bytes2 internal constant UNMASK_FLAGS = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES = uint16(UNMASK_FLAGS);

    // Equal to 100% of all deposit amounts for nToken liquidity across fCash markets.
    int256 internal constant DEPOSIT_PERCENT_BASIS = 1e8;
    uint256 internal constant SLIPPAGE_LIMIT_PRECISION = 1e8;

    /// @notice Precision for all percentages used by the vault
    /// 1e4 = 100% (i.e. maxPoolShare)
    uint16 internal constant VAULT_PERCENT_BASIS = 1e4;

    // Placeholder constant to mark the variable rate prime cash maturity
    uint40 internal constant PRIME_CASH_VAULT_MATURITY = type(uint40).max;

    uint256 internal constant CHAIN_ID_MAINNET = 1;
    uint256 internal constant CHAIN_ID_ARBITRUM = 42161;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {IERC20} from "@interfaces/IERC20.sol";
import {IEIP20NonStandard} from "@interfaces/IEIP20NonStandard.sol";
import {Deployments} from "@deployments/Deployments.sol";

library TokenUtils {
    error ERC20Error();

    function getDecimals(address token) internal view returns (uint8 decimals) {
        decimals = (token == Deployments.ETH_ADDRESS || token == Deployments.ALT_ETH_ADDRESS) ?
            18 : IERC20(token).decimals();
        require(decimals <= 18);
    }

    function tokenBalance(address token) internal view returns (uint256) {
        return
            token == Deployments.ETH_ADDRESS
                ? address(this).balance
                : IERC20(token).balanceOf(address(this));
    }

    function checkApprove(IERC20 token, address spender, uint256 amount) internal {
        if (address(token) == address(0)) return;

        IEIP20NonStandard(address(token)).approve(spender, 0);
        _checkReturnCode();
        if (amount > 0) {
            IEIP20NonStandard(address(token)).approve(spender, amount);
            _checkReturnCode();
        }
    }

    function checkRevoke(IERC20 token, address spender) internal {
        if (address(token) == address(0)) return;

        IEIP20NonStandard(address(token)).approve(spender, 0);
        _checkReturnCode();
    }

    function checkTransfer(IERC20 token, address receiver, uint256 amount) internal {
        IEIP20NonStandard(address(token)).transfer(receiver, amount);
        _checkReturnCode();
    }

    // Supports checking return codes on non-standard ERC20 contracts
    function _checkReturnCode() private pure {
        bool success;
        uint256[1] memory result;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := 1 // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(result, 0, 32)
                    success := mload(result) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        if (!success) revert ERC20Error();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {TokenUtils, IERC20} from "@contracts/utils/TokenUtils.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {Deployments} from "@deployments/Deployments.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {IConvexBooster, IConvexBoosterArbitrum} from "@interfaces/convex/IConvexBooster.sol";
import {IConvexRewardToken} from "@interfaces/convex/IConvexRewardToken.sol";
import {IConvexRewardPool, IConvexRewardPoolArbitrum} from "@interfaces/convex/IConvexRewardPool.sol";
import {Curve2TokenPoolMixin, DeploymentParams} from "./Curve2TokenPoolMixin.sol";

struct ConvexVaultDeploymentParams {
    address rewardPool;
    DeploymentParams baseParams;
}

abstract contract ConvexStakingMixin is Curve2TokenPoolMixin {
    using TokenUtils for IERC20;

    /// @notice Convex booster contract used for staking BPT
    address internal immutable CONVEX_BOOSTER;
    /// @notice Convex reward pool contract used for unstaking and claiming reward tokens
    address internal immutable CONVEX_REWARD_POOL;
    uint256 internal immutable CONVEX_POOL_ID;

    constructor(NotionalProxy notional_, ConvexVaultDeploymentParams memory params) 
        Curve2TokenPoolMixin(notional_, params.baseParams) {
        CONVEX_REWARD_POOL = params.rewardPool;

        address convexBooster;
        uint256 poolId;

        if (Deployments.CHAIN_ID == Constants.CHAIN_ID_MAINNET) {
            IConvexRewardPool rewardPool = IConvexRewardPool(CONVEX_REWARD_POOL);

            convexBooster = rewardPool.operator();
            poolId = rewardPool.pid();

        } else if (Deployments.CHAIN_ID == Constants.CHAIN_ID_ARBITRUM) {
            IConvexRewardPoolArbitrum rewardPool = IConvexRewardPoolArbitrum(CONVEX_REWARD_POOL);

            convexBooster = rewardPool.convexBooster();
            poolId = rewardPool.convexPoolId();
        } else {
            revert("Unsupported chain");
        }

        CONVEX_POOL_ID = poolId;
        CONVEX_BOOSTER = convexBooster;
    }

    function _stakeLpTokens(uint256 lpTokens) internal override {
        // Method signatures are slightly different on mainnet and arbitrum
        bool success;
        if (Deployments.CHAIN_ID == Constants.CHAIN_ID_MAINNET) {
            success = IConvexBooster(CONVEX_BOOSTER).deposit(CONVEX_POOL_ID, lpTokens, true);
        } else if (Deployments.CHAIN_ID == Constants.CHAIN_ID_ARBITRUM) {
            success = IConvexBoosterArbitrum(CONVEX_BOOSTER).deposit(CONVEX_POOL_ID, lpTokens);
        }
        require(success);
    }

    function _unstakeLpTokens(uint256 poolClaim) internal override {
        bool success;
        // Do not claim rewards when unstaking
        if (Deployments.CHAIN_ID == Constants.CHAIN_ID_MAINNET) {
            success = IConvexRewardPool(CONVEX_REWARD_POOL).withdrawAndUnwrap(poolClaim, false);
        } else if (Deployments.CHAIN_ID == Constants.CHAIN_ID_ARBITRUM) {
            success = IConvexRewardPoolArbitrum(CONVEX_REWARD_POOL).withdraw(poolClaim, false);
        }
        require(success);
    }

    function _initialApproveTokens() internal override {
        // If either token is Deployments.ETH_ADDRESS the check approve will short circuit
        IERC20(TOKEN_1).checkApprove(address(CURVE_POOL), type(uint256).max);
        IERC20(TOKEN_2).checkApprove(address(CURVE_POOL), type(uint256).max);
        CURVE_POOL_TOKEN.checkApprove(address(CONVEX_BOOSTER), type(uint256).max);
    }

    function _isInvalidRewardToken(address token) internal override view returns (bool) {
        // ETH is also at address(0) but that is never given out as a reward token
        if (WHITELISTED_REWARD != address(0) && token == WHITELISTED_REWARD) return false;

        return (
            token == TOKEN_1 ||
            token == TOKEN_2 ||
            token == address(CURVE_POOL_TOKEN) ||
            token == address(CONVEX_REWARD_POOL) ||
            token == address(CONVEX_BOOSTER) ||
            token == address(Deployments.ETH_ADDRESS) ||
            token == address(Deployments.WETH)
        );
    }

    function _claimRewardTokens() internal override {
        if (Deployments.CHAIN_ID == Constants.CHAIN_ID_MAINNET) {
            require(IConvexRewardPool(CONVEX_REWARD_POOL).getReward(address(this), true));
        } else if (Deployments.CHAIN_ID == Constants.CHAIN_ID_ARBITRUM) {
            IConvexRewardPoolArbitrum(CONVEX_REWARD_POOL).getReward(address(this));
        } else {
            revert();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";
import "./nTokenERC20.sol";
import "./nERC1155Interface.sol";
import "./NotionalGovernance.sol";
import "./NotionalCalculations.sol";
import "./NotionalViews.sol";
import "./NotionalTreasury.sol";
import {IVaultController} from "./IVaultController.sol";

interface NotionalProxy is
    nTokenERC20,
    nERC1155Interface,
    NotionalGovernance,
    NotionalTreasury,
    NotionalCalculations,
    NotionalViews,
    IVaultController
{
    /** User trading events */
    event CashBalanceChange(
        address indexed account,
        uint16 indexed currencyId,
        int256 netCashChange
    );
    event nTokenSupplyChange(
        address indexed account,
        uint16 indexed currencyId,
        int256 tokenSupplyChange
    );
    event MarketsInitialized(uint16 currencyId);
    event SweepCashIntoMarkets(uint16 currencyId, int256 cashIntoMarkets);
    event SettledCashDebt(
        address indexed settledAccount,
        uint16 indexed currencyId,
        address indexed settler,
        int256 amountToSettleAsset,
        int256 fCashAmount
    );
    event nTokenResidualPurchase(
        uint16 indexed currencyId,
        uint40 indexed maturity,
        address indexed purchaser,
        int256 fCashAmountToPurchase,
        int256 netAssetCashNToken
    );
    event LendBorrowTrade(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash
    );
    event AddRemoveLiquidity(
        address indexed account,
        uint16 indexed currencyId,
        uint40 maturity,
        int256 netAssetCash,
        int256 netfCash,
        int256 netLiquidityTokens
    );

    /// @notice Emitted once when incentives are migrated
    event IncentivesMigrated(
        uint16 currencyId,
        uint256 migrationEmissionRate,
        uint256 finalIntegralTotalSupply,
        uint256 migrationTime
    );

    /// @notice Emitted when reserve fees are accrued
    event ReserveFeeAccrued(uint16 indexed currencyId, int256 fee);
    /// @notice Emitted whenever an account context has updated
    event AccountContextUpdate(address indexed account);
    /// @notice Emitted when an account has assets that are settled
    event AccountSettled(address indexed account);
    /// @notice Emitted when an asset rate is settled
    event SetSettlementRate(uint256 indexed currencyId, uint256 indexed maturity, uint128 rate);

    /* Liquidation Events */
    event LiquidateLocalCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        int256 netLocalFromLiquidator
    );

    event LiquidateCollateralCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 collateralCurrencyId,
        int256 netLocalFromLiquidator,
        int256 netCollateralTransfer,
        int256 netNTokenTransfer
    );

    event LiquidatefCashEvent(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 fCashCurrency,
        int256 netLocalFromLiquidator,
        uint256[] fCashMaturities,
        int256[] fCashNotionalTransfer
    );

    /** UUPS Upgradeable contract calls */
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function getImplementation() external view returns (address);

    function owner() external view returns (address);

    function pauseRouter() external view returns (address);

    function pauseGuardian() external view returns (address);

    /** Initialize Markets Action */
    function initializeMarkets(uint16 currencyId, bool isFirstInit) external;

    function sweepCashIntoMarkets(uint16 currencyId) external;

    /** Redeem nToken Action */
    function nTokenRedeem(
        address redeemer,
        uint16 currencyId,
        uint96 tokensToRedeem_,
        bool sellTokenAssets,
        bool acceptResidualAssets
    ) external returns (int256);

    /** Account Action */
    function enableBitmapCurrency(uint16 currencyId) external;

    function settleAccount(address account) external;

    function depositUnderlyingToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external payable returns (uint256);

    function depositAssetToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external returns (uint256);

    function withdraw(
        uint16 currencyId,
        uint88 amountInternalPrecision,
        bool redeemToUnderlying
    ) external returns (uint256);

    /** Batch Action */
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions)
        external
        payable;

    function batchBalanceAndTradeActionWithCallback(
        address account,
        BalanceActionWithTrades[] calldata actions,
        bytes calldata callbackData
    ) external payable;

    function batchLend(address account, BatchLend[] calldata actions) external;

    /** Liquidation Action */
    function calculateLocalCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function liquidateLocalCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function calculateCollateralCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation
    )
        external
        returns (
            int256,
            int256,
            int256
        );

    function liquidateCollateralCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation,
        bool withdrawCollateral,
        bool redeemToUnderlying
    )
        external
        returns (
            int256,
            int256,
            int256
        );

    function calculatefCashLocalLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function calculatefCashCrossCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IConvexBooster {
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function stakerRewards() external view returns(address);
}

interface IConvexBoosterArbitrum {
    function deposit(uint256 _pid, uint256 _amount) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IRewardPool} from "../common/IRewardPool.sol";

interface IConvexRewardPool is IRewardPool {
    function extraRewards(uint256 idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
}


interface IConvexRewardPoolArbitrum {
    function rewardLength() external view returns (uint256);
    function rewards(uint256 i) external view returns (address, uint256, uint256);
    function getReward(address _account) external;
    function convexBooster() external view returns (address);
    function balanceOf(address _account) external view returns(uint256);
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function convexPoolId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

enum CurveInterface {
    V1,
    V2,
    StableSwapNG
}

interface ICurvePool {
    function coins(uint256 idx) external view returns (address);

    // @notice Perform an exchange between two coins
    // @dev Index values can be found via the `coins` public getter method
    // @dev see: https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#readContract
    // @param i Index value for the stEth to send -- 1
    // @param j Index value of the Eth to recieve -- 0
    // @param dx Amount of `i` (stEth) being exchanged
    // @param minDy Minimum amount of `j` (Eth) to receive
    // @return Actual amount of `j` (Eth) received
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external payable returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
}

interface ICurvePoolV1 is ICurvePool {
    function lp_token() external view returns (address);
}

interface ICurvePoolV2 is ICurvePool {
    function token() external view returns (address);
}

interface ICurve2TokenPoolV1 is ICurvePoolV1 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external payable returns (uint256);
    function remove_liquidity(uint256 amount, uint256[2] calldata _min_amounts) external returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);
}

interface ICurve2TokenPoolV2 is ICurvePoolV2 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, bool use_eth) external payable returns (uint256);
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount, bool use_eth, address receiver) external returns (uint256);
    // Curve V2 does not return the amounts removed
    function remove_liquidity(uint256 amount, uint256[2] calldata _min_amounts, bool use_eth, address receiver) external;
}

interface ICurveStableSwapNG is ICurvePoolV1 {
    function add_liquidity(uint256[] calldata amounts, uint256 min_mint_amount) external payable returns (uint256);
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount) external returns (uint256);
    function remove_liquidity(uint256 amount, uint256[] calldata _min_amounts) external returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import {IERC20} from "./IERC20.sol";

interface IWstETH is IERC20 {
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function stEthPerToken() external view returns (uint256);
    function stETH() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerVault {
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }
    enum MetaStableExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for ManagedPool
    }
    enum ComposableExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        EXACT_BPT_IN_FOR_ALL_TOKENS_OUT
    }
    enum WeightedPoolExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }


    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId)
        external
        view
        returns (address, PoolSpecialization);

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function flashLoan(
        address recipient, 
        address[] calldata tokens, 
        uint256[] calldata amounts, 
        bytes calldata userData
    ) external;

    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    function manageUserBalance(UserBalanceOp[] memory ops) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface WETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IUniV2Router2 {
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRouter {
    function exchange(
        uint256 _amount,
        address[6] calldata _route,
        uint256[8] calldata _indices,
        uint256 _min_received
    ) external payable;

    function get_exchange_routing(
        address _initial,
        address _target,
        uint256 _amount
    ) external view returns (
        address[6] memory route,
        uint256[8] memory indexes,
        uint256 expectedOutputAmount
    );

    function can_route(address _initial, address _target) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRegistry {
    function find_pool_for_coins(address _from, address _to, uint256 i)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveMetaRegistry {
    function get_registry_handlers_from_pool(address _pool)
        external
        view
        returns (address[10] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveRouterV2 {
    function exchange(
        address _pool,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _expected,
        address _receiver
    ) external returns (uint256);

    function exchange_multiple(
        address[9] calldata _route,
        uint256[3][4] calldata _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] calldata _pools,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "../chainlink/AggregatorV2V3Interface.sol";

enum DexId {
    _UNUSED,        // flag = 1
    UNISWAP_V2,     // flag = 2
    UNISWAP_V3,     // flag = 4
    ZERO_EX,        // flag = 8
    BALANCER_V2,    // flag = 16
    // NOTE: this id is unused in the TradingModule
    CURVE,          // flag = 32 
    NOTIONAL_VAULT, // flag = 64
    CURVE_V2        // flag = 128
}

enum TradeType {
    EXACT_IN_SINGLE,  // flag = 1
    EXACT_OUT_SINGLE, // flag = 2
    EXACT_IN_BATCH,   // flag = 4
    EXACT_OUT_BATCH   // flag = 8
}

struct Trade {
    TradeType tradeType;
    address sellToken;
    address buyToken;
    uint256 amount;
    /// minBuyAmount or maxSellAmount
    uint256 limit;
    uint256 deadline;
    bytes exchangeData;
}

error InvalidTrade();
error DynamicTradeFailed();
error TradeFailed();

interface ITradingModule {
    struct TokenPermissions {
        bool allowSell;
        /// @notice allowed DEXes
        uint32 dexFlags;
        /// @notice allowed trade types
        uint32 tradeTypeFlags; 
    }

    event TradeExecuted(
        address indexed sellToken,
        address indexed buyToken,
        uint256 sellAmount,
        uint256 buyAmount
    );

    event PriceOracleUpdated(address token, address oracle);
    event MaxOracleFreshnessUpdated(uint32 currentValue, uint32 newValue);
    event TokenPermissionsUpdated(address sender, address token, TokenPermissions permissions);

    function priceOracles(address token) external view returns (AggregatorV2V3Interface oracle, uint8 rateDecimals);

    function getExecutionData(uint16 dexId, address from, Trade calldata trade)
        external view returns (
            address spender,
            address target,
            uint256 value,
            bytes memory params
        );

    function setPriceOracle(address token, AggregatorV2V3Interface oracle) external;

    function setTokenPermissions(
        address sender, 
        address token, 
        TokenPermissions calldata permissions
    ) external;

    function getOraclePrice(address inToken, address outToken)
        external view returns (int256 answer, int256 decimals);

    function executeTrade(
        uint16 dexId,
        Trade calldata trade
    ) external payable returns (uint256 amountSold, uint256 amountBought);

    function executeTradeWithDynamicSlippage(
        uint16 dexId,
        Trade memory trade,
        uint32 dynamicSlippageLimit
    ) external payable returns (uint256 amountSold, uint256 amountBought);

    function getLimitAmount(
        address from,
        TradeType tradeType,
        address sellToken,
        address buyToken,
        uint256 amount,
        uint32 slippageLimit
    ) external view returns (uint256 limitAmount);

    function canExecuteTrade(address from, uint16 dexId, Trade calldata trade) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IWrappedfCashFactory {
    function deployWrapper(uint16 currencyId, uint40 maturity) external returns (address);
    function computeAddress(uint16 currencyId, uint40 maturity) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `approve` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external;

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IConvexRewardToken {
    function rewardToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {TokenUtils, IERC20} from "@contracts/utils/TokenUtils.sol";
import {IERC20} from "@interfaces/IERC20.sol";
import {Deployments} from "@deployments/Deployments.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {TokenUtils} from "@contracts/utils/TokenUtils.sol";
import {SingleSidedLPVaultBase} from "@contracts/vaults/common/SingleSidedLPVaultBase.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {
    CurveInterface,
    ICurvePool,
    ICurvePoolV1,
    ICurvePoolV2,
    ICurve2TokenPoolV1,
    ICurve2TokenPoolV2,
    ICurveStableSwapNG
} from "@interfaces/curve/ICurvePool.sol";
import {ITradingModule} from "@interfaces/trading/ITradingModule.sol";
import {ICurveGauge} from "@interfaces/curve/ICurveGauge.sol";

interface Minter {
    function mint(address gauge) external;
}

struct DeploymentParams {
    uint16 primaryBorrowCurrencyId;
    address pool;
    ITradingModule tradingModule;
    address poolToken;
    address gauge;
    CurveInterface curveInterface;
    address whitelistedReward;
}

abstract contract Curve2TokenPoolMixin is SingleSidedLPVaultBase {
    using TokenUtils for IERC20;
    uint256 internal constant _NUM_TOKENS = 2;
    uint256 internal constant CURVE_PRECISION = 1e18;

    address internal immutable CURVE_POOL;
    address internal immutable CURVE_GAUGE;
    IERC20 internal immutable CURVE_POOL_TOKEN;
    CurveInterface internal immutable CURVE_INTERFACE;

    uint8 internal immutable _PRIMARY_INDEX;
    uint8 internal immutable SECONDARY_INDEX;
    address internal immutable TOKEN_1;
    address internal immutable TOKEN_2;
    uint8 internal immutable DECIMALS_1;
    uint8 internal immutable DECIMALS_2;
    uint8 internal immutable PRIMARY_DECIMALS;
    uint8 internal immutable SECONDARY_DECIMALS;

    address immutable WHITELISTED_REWARD;

    function NUM_TOKENS() internal pure override returns (uint256) { return _NUM_TOKENS; }
    function PRIMARY_INDEX() internal view override returns (uint256) { return _PRIMARY_INDEX; }
    function POOL_TOKEN() internal view override returns (IERC20) { return CURVE_POOL_TOKEN; }
    function POOL_PRECISION() internal pure override returns (uint256) { return CURVE_PRECISION; }
    function TOKENS() public view override returns (IERC20[] memory, uint8[] memory) {
        IERC20[] memory tokens = new IERC20[](_NUM_TOKENS);
        uint8[] memory decimals = new uint8[](_NUM_TOKENS);

        (tokens[0], decimals[0]) = (IERC20(TOKEN_1), DECIMALS_1);
        (tokens[1], decimals[1]) = (IERC20(TOKEN_2), DECIMALS_2);

        return (tokens, decimals);
    }

    constructor(
        NotionalProxy notional_,
        DeploymentParams memory params
    ) SingleSidedLPVaultBase(notional_, params.tradingModule) {
        CURVE_POOL = params.pool;
        CURVE_GAUGE = params.gauge;
        CURVE_INTERFACE = params.curveInterface;
        CURVE_POOL_TOKEN = IERC20(params.poolToken);

        address primaryToken = _getNotionalUnderlyingToken(params.primaryBorrowCurrencyId);

        // We interact with curve pools directly so we never pass the token addresses back
        // to the curve pools. The amounts are passed back based on indexes instead. Therefore
        // we can rewrite the token addresses from ALT Eth (0xeeee...) back to (0x0000...) which
        // is used by the vault internally to represent ETH.
        TOKEN_1 = _rewriteAltETH(ICurvePool(CURVE_POOL).coins(0));
        TOKEN_2 = _rewriteAltETH(ICurvePool(CURVE_POOL).coins(1));
        _PRIMARY_INDEX = TOKEN_1 == primaryToken ? 0 : 1;
        SECONDARY_INDEX = 1 - _PRIMARY_INDEX;
        
        DECIMALS_1 = TokenUtils.getDecimals(TOKEN_1);
        DECIMALS_2 = TokenUtils.getDecimals(TOKEN_2);
        PRIMARY_DECIMALS = _PRIMARY_INDEX == 0 ? DECIMALS_1 : DECIMALS_2;
        SECONDARY_DECIMALS = _PRIMARY_INDEX == 0 ? DECIMALS_2 : DECIMALS_1;

        // Allows one of the pool tokens to be whitelisted as a reward token to be re-entered
        // back into the pool to increase LP shares.
        WHITELISTED_REWARD = params.whitelistedReward;
    }

    function _rewriteAltETH(address token) private pure returns (address) {
        return token == address(Deployments.ALT_ETH_ADDRESS) ? Deployments.ETH_ADDRESS : address(token);
    }

    function _checkReentrancyContext() internal override {
        uint256[2] memory minAmounts;
        if (CURVE_INTERFACE == CurveInterface.V1) {
            ICurve2TokenPoolV1(CURVE_POOL).remove_liquidity(0, minAmounts);
        } else if (CURVE_INTERFACE == CurveInterface.StableSwapNG) {
            // Total supply on stable swap has a non-reentrant lock
            ICurveStableSwapNG(CURVE_POOL).totalSupply();
        } else if (CURVE_INTERFACE == CurveInterface.V2) {
            // Curve V2 does a `-1` on the liquidity amount so set the amount removed to 1 to
            // avoid an underflow.
            ICurve2TokenPoolV2(CURVE_POOL).remove_liquidity(1, minAmounts, true, address(this));
        } else {
            revert();
        }
    }
    function _stakeLpTokens(uint256 lpTokens) internal virtual {
        ICurveGauge(CURVE_GAUGE).deposit(lpTokens);
    }

    function _joinPoolAndStake(
        uint256[] memory _amounts, uint256 minPoolClaim
    ) internal override returns (uint256 lpTokens) {
        // Only two tokens are ever allowed in this strategy, remaps the array
        // into a fixed length array here.
        uint256[2] memory amounts;
        amounts[0] = _amounts[0];
        amounts[1] = _amounts[1];

        // Although Curve uses ALT_ETH to represent native ETH, it is rewritten in the Curve2TokenPoolMixin
        // to the Deployments.ETH_ADDRESS which we use internally.
        (IERC20[] memory tokens, /* */) = TOKENS();
        uint256 msgValue;
        if (address(tokens[0]) == Deployments.ETH_ADDRESS) {
            msgValue = amounts[0];
        } else if (address(tokens[1]) == Deployments.ETH_ADDRESS) {
            msgValue = amounts[1];
        }

        // Slightly different method signatures in v1 and v2
        if (CURVE_INTERFACE == CurveInterface.V1) {
            lpTokens = ICurve2TokenPoolV1(CURVE_POOL).add_liquidity{value: msgValue}(
                amounts, minPoolClaim
            );
        } else if (CURVE_INTERFACE == CurveInterface.V2) {
            lpTokens = ICurve2TokenPoolV2(CURVE_POOL).add_liquidity{value: msgValue}(
                amounts, minPoolClaim, 0 < msgValue // use_eth = true if msgValue > 0
            );
        } else if (CURVE_INTERFACE == CurveInterface.StableSwapNG) {
            // StableSwapNG uses dynamic arrays
            lpTokens = ICurveStableSwapNG(CURVE_POOL).add_liquidity{value: msgValue}(
                _amounts, minPoolClaim
            );
        } else {
            revert();
        }

        _stakeLpTokens(lpTokens);
    }

    function _unstakeLpTokens(uint256 poolClaim) internal virtual {
        ICurveGauge(CURVE_GAUGE).withdraw(poolClaim);
    }

    function _unstakeAndExitPool(
        uint256 poolClaim, uint256[] memory _minAmounts, bool isSingleSided
    ) internal override returns (uint256[] memory exitBalances) {
        _unstakeLpTokens(poolClaim);

        exitBalances = new uint256[](2);
        if (isSingleSided) {
            // Redeem single-sided
            if (CURVE_INTERFACE == CurveInterface.V1 || CURVE_INTERFACE == CurveInterface.StableSwapNG) {
                // Method signature is the same for v1 and stable swap ng
                exitBalances[_PRIMARY_INDEX] = ICurve2TokenPoolV1(CURVE_POOL).remove_liquidity_one_coin(
                    poolClaim, int8(_PRIMARY_INDEX), _minAmounts[_PRIMARY_INDEX]
                );
            } else if (CURVE_INTERFACE == CurveInterface.V2) {
                exitBalances[_PRIMARY_INDEX] = ICurve2TokenPoolV2(CURVE_POOL).remove_liquidity_one_coin(
                    // Last two parameters are useEth = true and receiver = this contract
                    poolClaim, _PRIMARY_INDEX, _minAmounts[_PRIMARY_INDEX], true, address(this)
                );
            } else {
                revert();
            }
        } else {
            // Redeem proportionally, min amounts are rewritten to a fixed length array
            uint256[2] memory minAmounts;
            minAmounts[0] = _minAmounts[0];
            minAmounts[1] = _minAmounts[1];

            if (CURVE_INTERFACE == CurveInterface.V1) {
                uint256[2] memory _exitBalances = ICurve2TokenPoolV1(CURVE_POOL).remove_liquidity(poolClaim, minAmounts);
                exitBalances[0] = _exitBalances[0];
                exitBalances[1] = _exitBalances[1];
            } else if (CURVE_INTERFACE == CurveInterface.V2) {
                exitBalances[0] = TokenUtils.tokenBalance(TOKEN_1);
                exitBalances[1] = TokenUtils.tokenBalance(TOKEN_2);
                // Remove liquidity on CurveV2 does not return the exit amounts so we have to measure
                // them before and after.
                ICurve2TokenPoolV2(CURVE_POOL).remove_liquidity(
                    // Last two parameters are useEth = true and receiver = this contract
                    poolClaim, minAmounts, true, address(this)
                );
                exitBalances[0] = TokenUtils.tokenBalance(TOKEN_1) - exitBalances[0];
                exitBalances[1] = TokenUtils.tokenBalance(TOKEN_2) - exitBalances[1];
            } else if (CURVE_INTERFACE == CurveInterface.StableSwapNG) {
                exitBalances = ICurveStableSwapNG(CURVE_POOL).remove_liquidity(poolClaim, _minAmounts);
            } else {
                revert();
            }
        }
    }

    function _checkPriceAndCalculateValue() internal view override returns (uint256 oneLPValueInPrimary) {
        uint256[] memory balances = new uint256[](2);
        balances[0] = ICurvePool(CURVE_POOL).balances(0);
        balances[1] = ICurvePool(CURVE_POOL).balances(1);

        // The primary index spot price is left as zero.
        uint256[] memory spotPrices = new uint256[](2);
        uint256 primaryPrecision = 10 ** PRIMARY_DECIMALS;
        uint256 secondaryPrecision = 10 ** SECONDARY_DECIMALS;

        // `get_dy` returns the price of one unit of the primary token
        // converted to the secondary token. The spot price is in secondary
        // precision and then we convert it to POOL_PRECISION.
        spotPrices[SECONDARY_INDEX] = ICurvePool(CURVE_POOL).get_dy(
            int8(_PRIMARY_INDEX), int8(SECONDARY_INDEX), primaryPrecision
        ) * POOL_PRECISION() / secondaryPrecision;

        return _calculateLPTokenValue(balances, spotPrices);
    }

    function _initialApproveTokens() internal override virtual {
        // If either token is Deployments.ETH_ADDRESS the check approve will short circuit
        IERC20(TOKEN_1).checkApprove(address(CURVE_POOL), type(uint256).max);
        IERC20(TOKEN_2).checkApprove(address(CURVE_POOL), type(uint256).max);
        CURVE_POOL_TOKEN.checkApprove(address(CURVE_GAUGE), type(uint256).max);
    }

    function _isInvalidRewardToken(address token) internal override virtual view returns (bool) {
        if (WHITELISTED_REWARD != address(0) && token == WHITELISTED_REWARD) return false;

        return (
            token == TOKEN_1 ||
            token == TOKEN_2 ||
            token == address(CURVE_GAUGE) ||
            token == address(CURVE_POOL_TOKEN) ||
            token == address(Deployments.ETH_ADDRESS) ||
            token == address(Deployments.WETH)
        );
    }

    function _claimRewardTokens() internal override virtual {
        ICurveGauge(CURVE_GAUGE).claim_rewards();
        Minter(Deployments.CURVE_MINTER).mint(CURVE_GAUGE);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@interfaces/chainlink/AggregatorV2V3Interface.sol";
import "@interfaces/notional/IPrimeCashHoldingsOracle.sol";
import "@interfaces/notional/AssetRateAdapter.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 primeCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/****** Calldata objects ******/

/// @notice Defines a batch lending action
struct BatchLend {
    uint16 currencyId;
    // True if the contract should try to transfer underlying tokens instead of asset tokens
    bool depositUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/****** In memory objects ******/
/// @notice Internal object that represents settled cash balances
struct SettleAmount {
    uint16 currencyId;
    int256 positiveSettledCash;
    int256 negativeSettledCash;
    PrimeRate presentPrimeRate;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 deprecated_maxCollateralBalance;
}

/// @notice Internal object that represents an nToken portfolio
struct nTokenPortfolio {
    CashGroupParameters cashGroup;
    PortfolioState portfolioState;
    int256 totalSupply;
    int256 cashBalance;
    uint256 lastInitializedTime;
    bytes6 parameters;
    address tokenAddress;
}

/// @notice Internal object used during liquidation
struct LiquidationFactors {
    address account;
    // Aggregate free collateral of the account denominated in ETH underlying, 8 decimal precision
    int256 netETHValue;
    // Amount of net local currency asset cash before haircuts and buffers available
    int256 localPrimeAvailable;
    // Amount of net collateral currency asset cash before haircuts and buffers available
    int256 collateralAssetAvailable;
    // Haircut value of nToken holdings denominated in asset cash, will be local or collateral nTokens based
    // on liquidation type
    int256 nTokenHaircutPrimeValue;
    // nToken parameters for calculating liquidation amount
    bytes6 nTokenParameters;
    // ETH exchange rate from local currency to ETH
    ETHRate localETHRate;
    // ETH exchange rate from collateral currency to ETH
    ETHRate collateralETHRate;
    // Asset rate for the local currency, used in cross currency calculations to calculate local asset cash required
    PrimeRate localPrimeRate;
    // Used during currency liquidations if the account has liquidity tokens
    CashGroupParameters collateralCashGroup;
    // Used during currency liquidations if it is only a calculation, defaults to false
    bool isCalculation;
}

/// @notice Internal asset array portfolio state
struct PortfolioState {
    // Array of currently stored assets
    PortfolioAsset[] storedAssets;
    // Array of new assets to add
    PortfolioAsset[] newAssets;
    uint256 lastNewAssetIndex;
    // Holds the length of stored assets after accounting for deleted assets
    uint256 storedAssetLength;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @notice Internal object used to handle balance state during a transaction
struct BalanceState {
    uint16 currencyId;
    // Cash balance stored in balance state at the beginning of the transaction
    int256 storedCashBalance;
    // nToken balance stored at the beginning of the transaction
    int256 storedNTokenBalance;
    // The net cash change as a result of asset settlement or trading
    int256 netCashChange;
    // Amount of prime cash to redeem and withdraw from the system
    int256 primeCashWithdraw;
    // Net token transfers into or out of the account
    int256 netNTokenTransfer;
    // Net token supply change from minting or redeeming
    int256 netNTokenSupplyChange;
    // The last time incentives were claimed for this currency
    uint256 lastClaimTime;
    // Accumulator for incentives that the account no longer has a claim over
    uint256 accountIncentiveDebt;
    // Prime rate for converting prime cash balances
    PrimeRate primeRate;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct Deprecated_AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev Cash group when loaded into memory
struct CashGroupParameters {
    uint16 currencyId;
    uint256 maxMarketIndex;
    PrimeRate primeRate;
    bytes32 data;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint16 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalPrimeCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

/****** Storage objects ******/

/// @dev Token object in storage:
///  20 bytes for token address
///  1 byte for hasTransferFee
///  1 byte for tokenType
///  1 byte for tokenDecimals
///  9 bytes for maxCollateralBalance (may not always be set)
struct TokenStorage {
    // Address of the token
    address tokenAddress;
    // Transfer fees will change token deposit behavior
    bool hasTransferFee;
    TokenType tokenType;
    uint8 decimalPlaces;
    uint72 deprecated_maxCollateralBalance;
}

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
}

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
}

/// @dev Governance parameters for a cash group, total storage is 9 bytes + 7 bytes for liquidity token haircuts
/// and 7 bytes for rate scalars, total of 23 bytes. Note that this is stored packed in the storage slot so there
/// are no indexes stored for liquidityTokenHaircuts or rateScalars, maxMarketIndex is used instead to determine the
/// length.
struct CashGroupSettings {
    // Index of the AMMs on chain that will be made available. Idiosyncratic fCash
    // that is dated less than the longest AMM will be tradable.
    uint8 maxMarketIndex;
    // Time window in 5 minute increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // Total fees per trade, specified in BPS
    uint8 totalFeeBPS;
    // Share of the fees given to the protocol, denominated in percentage
    uint8 reserveFeeShare;
    // Debt buffer specified in 5 BPS increments
    uint8 debtBuffer5BPS;
    // fCash haircut specified in 5 BPS increments
    uint8 fCashHaircut5BPS;
    // If an account has a negative cash balance, it can be settled by incurring debt at the 3 month market. This
    // is the basis points for the penalty rate that will be added the current 3 month oracle rate.
    uint8 settlementPenaltyRate5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationfCashHaircut5BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationDebtBuffer5BPS;
    // Liquidity token haircut applied to cash claims, specified as a percentage between 0 and 100
    uint8[] liquidityTokenHaircuts;
    // Rate scalar used to determine the slippage of the market
    uint8[] rateScalars;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
    // If this is set to true, the account can borrow variable prime cash and incur
    // negative cash balances inside BatchAction. This does not impact the settlement
    // of negative fCash to prime cash which will happen regardless of this setting. This
    // exists here mainly as a safety setting to ensure that accounts do not accidentally
    // incur negative cash balances.
    bool allowPrimeBorrow;
}

/// @dev Holds nToken context information mapped via the nToken address, total storage is
/// 16 bytes
struct nTokenContext {
    // Currency id that the nToken represents
    uint16 currencyId;
    // Annual incentive emission rate denominated in WHOLE TOKENS (multiply by
    // INTERNAL_TOKEN_PRECISION to get the actual rate)
    uint32 incentiveAnnualEmissionRate;
    // The last block time at utc0 that the nToken was initialized at, zero if it
    // has never been initialized
    uint32 lastInitializedTime;
    // Length of the asset array, refers to the number of liquidity tokens an nToken
    // currently holds
    uint8 assetArrayLength;
    // Each byte is a specific nToken parameter
    bytes5 nTokenParameters;
    // Reserved bytes for future usage
    bytes15 _unused;
    // Set to true if a secondary rewarder is set
    bool hasSecondaryRewarder;
}

/// @dev Holds account balance information, total storage 32 bytes
struct BalanceStorage {
    // Number of nTokens held by the account
    uint80 nTokenBalance;
    // Last time the account claimed their nTokens
    uint32 lastClaimTime;
    // Incentives that the account no longer has a claim over
    uint56 accountIncentiveDebt;
    // Cash balance of the account
    int88 cashBalance;
}

/// @dev Holds information about a settlement rate, total storage 25 bytes
struct SettlementRateStorage {
    uint40 blockTime;
    uint128 settlementRate;
    uint8 underlyingDecimalPlaces;
}

/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalPrimeCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
}

struct InterestRateParameters {
    // First kink for the utilization rate in RATE_PRECISION
    uint256 kinkUtilization1;
    // Second kink for the utilization rate in RATE_PRECISION
    uint256 kinkUtilization2;
    // First kink interest rate in RATE_PRECISION
    uint256 kinkRate1;
    // Second kink interest rate in RATE_PRECISION
    uint256 kinkRate2;
    // Max interest rate in RATE_PRECISION
    uint256 maxRate;
    // Minimum fee charged in RATE_PRECISION
    uint256 minFeeRate;
    // Maximum fee charged in RATE_PRECISION
    uint256 maxFeeRate;
    // Percentage of the interest rate that will be applied as a fee
    uint256 feeRatePercent;
}

// Specific interest rate curve settings for each market
struct InterestRateCurveSettings {
    // First kink for the utilization rate, specified as a percentage
    // between 1-100
    uint8 kinkUtilization1;
    // Second kink for the utilization rate, specified as a percentage
    // between 1-100
    uint8 kinkUtilization2;
    // Interest rate at the first kink, set as 1/256 units from the kink
    // rate max
    uint8 kinkRate1;
    // Interest rate at the second kink, set as 1/256 units from the kink
    // rate max
    uint8 kinkRate2;
    // Max interest rate, set in 25 bps increments
    uint8 maxRate25BPS;
    // Minimum fee charged in basis points
    uint8 minFeeRateBPS;
    // Maximum fee charged in basis points
    uint8 maxFeeRateBPS;
    // Percentage of the interest rate that will be applied as a fee
    uint8 feeRatePercent;
}

struct ifCashStorage {
    // Notional amount of fCash at the slot, limited to int128 to allow for
    // future expansion
    int128 notional;
}

/// @dev A single portfolio asset in storage, total storage of 19 bytes
struct PortfolioAssetStorage {
    // Currency Id for the asset
    uint16 currencyId;
    // Maturity of the asset
    uint40 maturity;
    // Asset type (fCash or Liquidity Token marker)
    uint8 assetType;
    // Notional
    int88 notional;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes. This is the deprecated version
struct nTokenTotalSupplyStorage_deprecated {
    // Total supply of the nToken
    uint96 totalSupply;
    // Integral of the total supply used for calculating the average total supply
    uint128 integralTotalSupply;
    // Last timestamp the supply value changed, used for calculating the integralTotalSupply
    uint32 lastSupplyChangeTime;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes.
struct nTokenTotalSupplyStorage {
    // Total supply of the nToken
    uint96 totalSupply;
    // How many NOTE incentives should be issued per nToken in 1e18 precision
    uint128 accumulatedNOTEPerNToken;
    // Last timestamp when the accumulation happened
    uint32 lastAccumulatedTime;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

struct VaultConfigParams {
    // Vault Flags (documented in VaultConfiguration.sol)
    uint16 flags;
    // Primary currency the vault borrows in
    uint16 borrowCurrencyId;
    // Specified in whole tokens in 1e8 precision, allows a 4.2 billion min borrow size
    uint256 minAccountBorrowSize;
    // Minimum collateral ratio for a vault specified in basis points, valid values are greater than 10_000
    // where the largest minimum collateral ratio is 65_536 which is much higher than anything reasonable.
    uint16 minCollateralRatioBPS;
    // Allows up to a 12.75% annualized fee
    uint8 feeRate5BPS;
    // A percentage that represents the share of the cash raised that will go to the liquidator
    uint8 liquidationRate;
    // A percentage of the fee given to the protocol
    uint8 reserveFeeShare;
    // Maximum market index where a vault can borrow from
    uint8 maxBorrowMarketIndex;
    // Maximum collateral ratio that a liquidator can push a an account to during deleveraging
    uint16 maxDeleverageCollateralRatioBPS;
    // An optional list of secondary borrow currencies
    uint16[2] secondaryBorrowCurrencies;
    // Required collateral ratio for accounts to stay inside a vault, prevents accounts
    // from "free riding" on vaults. Enforced on entry and exit, not on deleverage.
    uint16 maxRequiredAccountCollateralRatioBPS;
    // Specified in whole tokens in 1e8 precision, allows a 4.2 billion min borrow size
    uint256[2] minAccountSecondaryBorrow;
    // Specified as a percent discount off the exchange rate of the excess cash that will be paid to
    // the liquidator during liquidateExcessVaultCash
    uint8 excessCashLiquidationBonus;
}

struct VaultBorrowCapacityStorage {
    // Total fCash across all maturities that caps the borrow capacity
    uint80 maxBorrowCapacity;
    // Total fCash debt across all maturities
    uint80 totalfCashDebt;
}

struct VaultAccountSecondaryDebtShareStorage {
    // Maturity for the account's secondary borrows. This is stored separately from
    // the vault account maturity to ensure that we have access to the proper state
    // during a roll borrow position. It should never be allowed to deviate from the
    // vaultAccount.maturity value (unless it is cleared to zero).
    uint40 maturity;
    // Account debt for the first secondary currency in either fCash or pCash denomination
    uint80 accountDebtOne;
    // Account debt for the second secondary currency in either fCash or pCash denomination
    uint80 accountDebtTwo;
}

struct VaultConfig {
    address vault;
    uint16 flags;
    uint16 borrowCurrencyId;
    int256 minAccountBorrowSize;
    int256 feeRate;
    int256 minCollateralRatio;
    int256 liquidationRate;
    int256 reserveFeeShare;
    uint256 maxBorrowMarketIndex;
    int256 maxDeleverageCollateralRatio;
    uint16[2] secondaryBorrowCurrencies;
    PrimeRate primeRate;
    int256 maxRequiredAccountCollateralRatio;
    int256[2] minAccountSecondaryBorrow;
}

/// @notice Represents a Vault's current borrow and collateral state
struct VaultStateStorage {
    // This represents the total amount of borrowing in the vault for the current
    // vault term. If the vault state is the prime cash maturity, this is stored in
    // prime cash debt denomination, if fCash then it is stored in internal underlying.
    uint80 totalDebt;
    // The total amount of prime cash in the pool held as a result of emergency settlement
    uint80 deprecated_totalPrimeCash;
    // Total vault shares in this maturity
    uint80 totalVaultShares;
    // Set to true if a vault's debt position has been migrated to the prime cash vault
    bool isSettled;
    // NOTE: 8 bits left
    // ----- This breaks into a new storage slot -------    
    // The total amount of strategy tokens held in the pool
    uint80 deprecated_totalStrategyTokens;
    // Valuation of a strategy token at settlement
    int80 deprecated_settlementStrategyTokenValue;
    // NOTE: 96 bits left
}

/// @notice Represents the remaining assets in a vault post settlement
struct Deprecated_VaultSettledAssetsStorage {
    // Remaining strategy tokens that have not been withdrawn
    uint80 remainingStrategyTokens;
    // Remaining asset cash that has not been withdrawn
    int80 remainingPrimeCash;
}

struct VaultState {
    uint256 maturity;
    // Total debt is always denominated in underlying on the stack
    int256 totalDebtUnderlying;
    uint256 totalVaultShares;
    bool isSettled;
}

/// @notice Represents an account's position within an individual vault
struct VaultAccountStorage {
    // Total amount of debt for the account in the primary borrowed currency.
    // If the account is borrowing prime cash, this is stored in prime cash debt
    // denomination, if fCash then it is stored in internal underlying.
    uint80 accountDebt;
    // Vault shares that the account holds
    uint80 vaultShares;
    // Maturity when the vault shares and fCash will mature
    uint40 maturity;
    // Last time when a vault was entered or exited, used to ensure that vault accounts do not
    // flash enter/exit. While there is no specified attack vector here, we can use it to prevent
    // an entire class of attacks from happening without reducing UX.
    // NOTE: in the original version this value was set to the block.number, however, in this
    // version it is being changed to time based. On ETH mainnet block heights are much smaller
    // than block times, accounts that migrate from lastEntryBlockHeight => lastUpdateBlockTime
    // will not see any issues with entering / exiting the protocol.
    uint32 lastUpdateBlockTime;
    // ----------------  Second Storage Slot ----------------------
    // Cash balances held by the vault account as a result of lending at zero interest or due
    // to deleveraging (liquidation). In the previous version of leveraged vaults, accounts would
    // simply lend at zero interest which was not a problem. However, with vaults being able to
    // discount fCash to present value, lending at zero percent interest may have an adverse effect
    // on the account's collateral position (i.e. lending at zero puts them further into danger).
    // Holding cash against debt will eliminate that risk, making vault liquidation more similar to
    // regular Notional liquidation.
    uint80 primaryCash;
    uint80 secondaryCashOne;
    uint80 secondaryCashTwo;
}

struct VaultAccount {
    // On the stack, account debts are always in underlying
    int256 accountDebtUnderlying;
    uint256 maturity;
    uint256 vaultShares;
    address account;
    // This cash balance is used just within a transaction to track deposits
    // and withdraws for an account. Must be zeroed by the time we store the account
    int256 tempCashBalance;
    uint256 lastUpdateBlockTime;
}

// Used to hold vault account liquidation factors in memory
struct VaultAccountHealthFactors {
    // Account's calculated collateral ratio
    int256 collateralRatio;
    // Total outstanding debt across all borrowed currencies in primary
    int256 totalDebtOutstandingInPrimary;
    // Total value of vault shares in underlying denomination
    int256 vaultShareValueUnderlying;
    // Debt outstanding in local currency denomination after present value and
    // account cash held netting applied
    int256[3] debtOutstanding;
}

// PrimeCashInterestRateParameters take up 16 bytes, this takes up 32 bytes so we
// can expand another 16 bytes to increase the storage slots a bit....
struct PrimeCashFactorsStorage {
    // Storage slot 1 [Prime Supply Factors, 248 bytes]
    uint40 lastAccrueTime;
    uint88 totalPrimeSupply;
    uint88 lastTotalUnderlyingValue;
    // Overflows at 429% interest using RATE_PRECISION
    uint32 oracleSupplyRate;
    bool allowDebt;

    // Storage slot 2 [Prime Debt Factors, 256 bytes]
    uint88 totalPrimeDebt;
    // Each one of these values below is stored as a FloatingPoint32 value which
    // gives us approx 7 digits of precision for each value. Because these are used
    // to maintain supply and borrow caps, they are not required to be exact.
    uint32 maxUnderlyingSupply;
    uint128 _reserved;
    // Reserving the next 128 bytes for future use in case we decide to implement debt
    // caps on a currency. In that case, we will need to track the total fcash overall
    // and subtract the total debt held in vaults.
    // uint32 maxUnderlyingDebt;
    // uint32 totalfCashDebtOverall;
    // uint32 totalfCashDebtInVaults;
    // uint32 totalPrimeDebtInVaults;
    // 8 bytes left
    
    // Storage slot 3 [Prime Scalars, 240 bytes]
    // Scalars are stored in 18 decimal precision (i.e. double rate precision) and uint80
    // maxes out at approx 1,210,000e18
    // ln(1,210,000) = rate * years = 14
    // Approx 46 years at 30% interest
    // Approx 233 years at 6% interest
    uint80 underlyingScalar;
    uint80 supplyScalar;
    uint80 debtScalar;
    // The time window in 5 min increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // 8 bytes left
}

struct PrimeCashFactors {
    uint256 lastAccrueTime;
    uint256 totalPrimeSupply;
    uint256 totalPrimeDebt;
    uint256 oracleSupplyRate;
    uint256 lastTotalUnderlyingValue;
    uint256 underlyingScalar;
    uint256 supplyScalar;
    uint256 debtScalar;
    uint256 rateOracleTimeWindow;
}

struct PrimeRate {
    int256 supplyFactor;
    int256 debtFactor;
    uint256 oracleSupplyRate;
}

struct PrimeSettlementRateStorage {
    uint80 supplyScalar;
    uint80 debtScalar;
    uint80 underlyingScalar;
    bool isSet;
}

struct PrimeCashHoldingsOracle {
   IPrimeCashHoldingsOracle oracle; 
}

// Per currency rebalancing context
struct RebalancingContextStorage {
    // Holds the previous underlying scalar to calculate the oracle money market rate
    uint80 previousUnderlyingScalarAtRebalance;
    // Rebalancing has a cool down period that sets the time averaging of the oracle money market rate
    uint40 rebalancingCooldownInSeconds;
    uint40 lastRebalanceTimestampInSeconds;
    // The annualized underlying money market interest rate calculated based on the underlying scalar
    uint32 oracleMoneyMarketRate;
    // 64 bytes left
}

struct TotalfCashDebtStorage {
    uint80 totalfCashDebt;
    // These two variables are used to track fCash lend at zero
    // edge conditions for leveraged vaults.
    uint80 fCashDebtHeldInSettlementReserve;
    uint80 primeCashHeldInSettlementReserve;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface nTokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function nTokenBalanceOf(uint16 currencyId, address account) external view returns (uint256);

    function nTokenTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function pCashTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function nTokenTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function pCashTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function nTokenTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pCashTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pCashTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferApproveAll(address spender, uint256 amount) external returns (bool);

    function nTokenClaimIncentives() external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface nERC1155Interface {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function signedBalanceOf(address account, uint256 id) external view returns (int256);

    function signedBalanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (int256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable;

    function decodeToAssets(uint256[] calldata ids, uint256[] calldata amounts)
        external
        view
        returns (PortfolioAsset[] memory);

    function encodeToId(
        uint16 currencyId,
        uint40 maturity,
        uint8 assetType
    ) external pure returns (uint256 id);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";
import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../../interfaces/notional/NotionalGovernance.sol";
import "../../interfaces/notional/IRewarder.sol";
import "../../interfaces/aave/ILendingPool.sol";

interface NotionalGovernance {
    event ListCurrency(uint16 newCurrencyId);
    event UpdateETHRate(uint16 currencyId);
    event UpdateAssetRate(uint16 currencyId);
    event UpdateCashGroup(uint16 currencyId);
    event DeployNToken(uint16 currencyId, address nTokenAddress);
    event UpdateDepositParameters(uint16 currencyId);
    event UpdateInitializationParameters(uint16 currencyId);
    event UpdateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate);
    event UpdateTokenCollateralParameters(uint16 currencyId);
    event UpdateGlobalTransferOperator(address operator, bool approved);
    event UpdateAuthorizedCallbackContract(address operator, bool approved);
    event UpdateMaxCollateralBalance(uint16 currencyId, uint72 maxCollateralBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseRouterAndGuardianUpdated(address indexed pauseRouter, address indexed pauseGuardian);
    event UpdateSecondaryIncentiveRewarder(uint16 indexed currencyId, address rewarder);
    event UpdateLendingPool(address pool);

    function transferOwnership(address newOwner, bool direct) external;

    function claimOwnership() external;

    function upgradeNTokenBeacon(address newImplementation) external;

    function setPauseRouterAndGuardian(address pauseRouter_, address pauseGuardian_) external;

    function listCurrency(
        TokenStorage calldata assetToken,
        TokenStorage calldata underlyingToken,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external returns (uint16 currencyId);

    function updateMaxCollateralBalance(
        uint16 currencyId,
        uint72 maxCollateralBalanceInternalPrecision
    ) external;

    function enableCashGroup(
        uint16 currencyId,
        AssetRateAdapter assetRateOracle,
        CashGroupSettings calldata cashGroup,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external;

    function updateDepositParameters(
        uint16 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) external;

    function updateInitializationParameters(
        uint16 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) external;

    function updateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate) external;

    function updateTokenCollateralParameters(
        uint16 currencyId,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) external;

    function updateCashGroup(uint16 currencyId, CashGroupSettings calldata cashGroup) external;

    function updateAssetRate(uint16 currencyId, AssetRateAdapter rateOracle) external;

    function updateETHRate(
        uint16 currencyId,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external;

    function updateGlobalTransferOperator(address operator, bool approved) external;

    function updateAuthorizedCallbackContract(address operator, bool approved) external;

    function setLendingPool(ILendingPool pool) external;

    function setSecondaryIncentiveRewarder(uint16 currencyId, IRewarder rewarder) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalCalculations {
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);

    function nTokenPresentValueAssetDenominated(uint16 currencyId) external view returns (int256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);

    function convertNTokenToUnderlying(uint16 currencyId, int256 nTokenBalance) external view returns (int256);

    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        returns (uint256);

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(
        uint256 maturity,
        uint256 blockTime
    ) external pure returns (uint8 marketIndex);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashAmount,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashDebt,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    ) external view returns (
        uint256 depositAmountUnderlying,
        uint256 depositAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    ) external view returns (
        uint256 borrowAmountUnderlying,
        uint256 borrowAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool useUnderlying
    ) external view returns (int256);

    function convertUnderlyingToPrimeCash(
        uint16 currencyId,
        int256 underlyingExternal
    ) external view returns (int256);

    function convertSettledfCash(
        uint16 currencyId,
        uint256 maturity,
        int256 fCashBalance,
        uint256 blockTime
    ) external view returns (int256 signedPrimeSupplyValue);

    function accruePrimeInterest(
        uint16 currencyId
    ) external returns (PrimeRate memory pr, PrimeCashFactors memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalViews {
    function getMaxCurrencyId() external view returns (uint16);

    function getCurrencyId(address tokenAddress) external view returns (uint16 currencyId);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getRateStorage(uint16 currencyId)
        external
        view
        returns (ETHRateStorage memory ethRate, AssetRateStorage memory assetRate);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            Deprecated_AssetRateParameters memory assetRate
        );

    function getCashGroup(uint16 currencyId) external view returns (CashGroupSettings memory);

    function getCashGroupAndAssetRate(uint16 currencyId)
        external
        view
        returns (CashGroupSettings memory cashGroup, Deprecated_AssetRateParameters memory assetRate);

    function getInterestRateCurve(uint16 currencyId) external view returns (
        InterestRateParameters[] memory nextInterestRateCurve,
        InterestRateParameters[] memory activeInterestRateCurve
    );

    function getInitializationParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory annualizedAnchorRates, int256[] memory proportions);

    function getDepositParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds);

    function nTokenAddress(uint16 currencyId) external view returns (address);

    function pCashAddress(uint16 currencyId) external view returns (address);

    function pDebtAddress(uint16 currencyId) external view returns (address);

    function getNoteToken() external view returns (address);

    function getOwnershipStatus() external view returns (address owner, address pendingOwner);

    function getGlobalTransferOperatorStatus(address operator)
        external
        view
        returns (bool isAuthorized);

    function getAuthorizedCallbackContractStatus(address callback)
        external
        view
        returns (bool isAuthorized);

    function getSecondaryIncentiveRewarder(uint16 currencyId)
        external
        view
        returns (address incentiveRewarder);

    function getPrimeFactors(uint16 currencyId, uint256 blockTime) external view returns (
        PrimeRate memory primeRate,
        PrimeCashFactors memory factors,
        uint256 maxUnderlyingSupply,
        uint256 totalUnderlyingSupply
    );

    function getPrimeFactorsStored(uint16 currencyId) external view returns (PrimeCashFactors memory);

    function getPrimeCashHoldingsOracle(uint16 currencyId) external view returns (address);

    function getTotalfCashDebtOutstanding(uint16 currencyId, uint256 maturity) external view returns (int256);

    function getSettlementRate(uint16 currencyId, uint40 maturity)
        external
        view
        returns (PrimeRate memory);

    function getMarket(
        uint16 currencyId,
        uint256 maturity,
        uint256 settlementDate
    ) external view returns (MarketParameters memory);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getActiveMarketsAtBlockTime(uint16 currencyId, uint32 blockTime)
        external
        view
        returns (MarketParameters[] memory);

    function getReserveBalance(uint16 currencyId) external view returns (int256 reserveBalance);

    function getNTokenPortfolio(address tokenAddress)
        external
        view
        returns (PortfolioAsset[] memory liquidityTokens, PortfolioAsset[] memory netfCashAssets);

    function getNTokenAccount(address tokenAddress)
        external
        view
        returns (
            uint16 currencyId,
            uint256 totalSupply,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            bytes5 nTokenParameters,
            int256 cashBalance,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        );

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function getAccountContext(address account) external view returns (AccountContext memory);

    function getAccountPrimeDebtBalance(uint16 currencyId, address account) external view returns (
        int256 debtBalance
    );

    function getAccountBalance(uint16 currencyId, address account)
        external
        view
        returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime
        );

    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

    function getAssetsBitmap(address account, uint16 currencyId) external view returns (bytes32);

    function getFreeCollateral(address account) external view returns (int256, int256[] memory);

    function getTreasuryManager() external view returns (address);

    function getReserveBuffer(uint16 currencyId) external view returns (uint256);

    function getRebalancingTarget(uint16 currencyId, address holding) external view returns (uint8);

    function getRebalancingCooldown(uint16 currencyId) external view returns (uint40);

    function getStoredTokenBalances(address[] calldata tokens) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface NotionalTreasury {

    /// @notice Emitted when reserve balance is updated
    event ReserveBalanceUpdated(uint16 indexed currencyId, int256 newBalance);
    /// @notice Emitted when reserve balance is harvested
    event ExcessReserveBalanceHarvested(uint16 indexed currencyId, int256 harvestAmount);
    /// @dev Emitted when treasury manager is updated
    event TreasuryManagerChanged(address indexed previousManager, address indexed newManager);
    /// @dev Emitted when reserve buffer value is updated
    event ReserveBufferUpdated(uint16 currencyId, uint256 bufferAmount);

    function claimCOMPAndTransfer(address[] calldata ctokens) external returns (uint256);

    function transferReserveToTreasury(uint16[] calldata currencies)
        external
        returns (uint256[] memory);

    function setTreasuryManager(address manager) external;

    function setReserveBuffer(uint16 currencyId, uint256 amount) external;

    function setReserveCashBalance(uint16 currencyId, int256 reserveBalance) external;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.6;
pragma abicoder v2;

import {
    VaultConfigParams,
    VaultConfig,
    VaultState,
    VaultAccount,
    VaultAccountHealthFactors,
    PrimeRate
} from "../../contracts/global/Types.sol";

interface IVaultAction {
    /// @notice Emitted when a new vault is listed or updated
    event VaultUpdated(address indexed vault, bool enabled, uint80 maxPrimaryBorrowCapacity);
    /// @notice Emitted when a vault's status is updated
    event VaultPauseStatus(address indexed vault, bool enabled);
    /// @notice Emitted when a vault's deleverage status is updated
    event VaultDeleverageStatus(address indexed vaultAddress, bool disableDeleverage);
    /// @notice Emitted when a secondary currency borrow capacity is updated
    event VaultUpdateSecondaryBorrowCapacity(address indexed vault, uint16 indexed currencyId, uint80 maxSecondaryBorrowCapacity);
    /// @notice Emitted when the borrow capacity on a vault changes
    event VaultBorrowCapacityChange(address indexed vault, uint16 indexed currencyId, uint256 totalUsedBorrowCapacity);

    /// @notice Emitted when a vault executes a secondary borrow
    event VaultSecondaryTransaction(
        address indexed vault,
        address indexed account,
        uint16 indexed currencyId,
        uint256 maturity,
        int256 netUnderlyingDebt,
        int256 netPrimeSupply
    );

    /** Vault Action Methods */

    /// @notice Governance only method to whitelist a particular vault
    function updateVault(
        address vaultAddress,
        VaultConfigParams memory vaultConfig,
        uint80 maxPrimaryBorrowCapacity
    ) external;

    /// @notice Governance only method to pause a particular vault
    function setVaultPauseStatus(
        address vaultAddress,
        bool enable
    ) external;

    function setVaultDeleverageStatus(
        address vaultAddress,
        bool disableDeleverage
    ) external;

    /// @notice Governance only method to set the borrow capacity
    function setMaxBorrowCapacity(
        address vaultAddress,
        uint80 maxVaultBorrowCapacity
    ) external;

    /// @notice Governance only method to update a vault's secondary borrow capacity
    function updateSecondaryBorrowCapacity(
        address vaultAddress,
        uint16 secondaryCurrencyId,
        uint80 maxBorrowCapacity
    ) external;

    function borrowSecondaryCurrencyToVault(
        address account,
        uint256 maturity,
        uint256[2] calldata underlyingToBorrow,
        uint32[2] calldata maxBorrowRate,
        uint32[2] calldata minRollLendRate
    ) external returns (int256[2] memory underlyingTokensTransferred);

    function repaySecondaryCurrencyFromVault(
        address account,
        uint256 maturity,
        uint256[2] calldata underlyingToRepay,
        uint32[2] calldata minLendRate
    ) external payable returns (int256[2] memory underlyingDepositExternal);

    function settleSecondaryBorrowForAccount(address vault, address account) external;
}

interface IVaultAccountAction {
    /**
     * @notice Borrows a specified amount of fCash in the vault's borrow currency and deposits it
     * all plus the depositAmountExternal into the vault to mint strategy tokens.
     *
     * @param account the address that will enter the vault
     * @param vault the vault to enter
     * @param depositAmountExternal some amount of additional collateral in the borrowed currency
     * to be transferred to vault
     * @param maturity the maturity to borrow at
     * @param fCash amount to borrow
     * @param maxBorrowRate maximum interest rate to borrow at
     * @param vaultData additional data to pass to the vault contract
     */
    function enterVault(
        address account,
        address vault,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint256 fCash,
        uint32 maxBorrowRate,
        bytes calldata vaultData
    ) external payable returns (uint256 strategyTokensAdded);

    /**
     * @notice Re-enters the vault at a longer dated maturity. The account's existing borrow
     * position will be closed and a new borrow position at the specified maturity will be
     * opened. All strategy token holdings will be rolled forward.
     *
     * @param account the address that will reenter the vault
     * @param vault the vault to reenter
     * @param fCashToBorrow amount of fCash to borrow in the next maturity
     * @param maturity new maturity to borrow at
     */
    function rollVaultPosition(
        address account,
        address vault,
        uint256 fCashToBorrow,
        uint256 maturity,
        uint256 depositAmountExternal,
        uint32 minLendRate,
        uint32 maxBorrowRate,
        bytes calldata enterVaultData
    ) external payable returns (uint256 strategyTokensAdded);

    /**
     * @notice Prior to maturity, allows an account to withdraw their position from the vault. Will
     * redeem some number of vault shares to the borrow currency and close the borrow position by
     * lending `fCashToLend`. Any shortfall in cash from lending will be transferred from the account,
     * any excess profits will be transferred to the account.
     *
     * Post maturity, will net off the account's debt against vault cash balances and redeem all remaining
     * strategy tokens back to the borrowed currency and transfer the profits to the account.
     *
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param vaultSharesToRedeem amount of vault tokens to exit, only relevant when exiting pre-maturity
     * @param fCashToLend amount of fCash to lend
     * @param minLendRate the minimum rate to lend at
     * @param exitVaultData passed to the vault during exit
     * @return underlyingToReceiver amount of underlying tokens returned to the receiver on exit
     */
    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    function settleVaultAccount(address account, address vault) external;
}

interface IVaultLiquidationAction {
    event VaultDeleverageAccount(
        address indexed vault,
        address indexed account,
        uint16 currencyId,
        uint256 vaultSharesToLiquidator,
        int256 depositAmountPrimeCash
    );

    event VaultLiquidatorProfit(
        address indexed vault,
        address indexed account,
        address indexed liquidator,
        uint256 vaultSharesToLiquidator,
        bool transferSharesToLiquidator
    );
    
    event VaultAccountCashLiquidation(
        address indexed vault,
        address indexed account,
        address indexed liquidator,
        uint16 currencyId,
        int256 fCashDeposit,
        int256 cashToLiquidator
    );

    /**
     * @notice If an account is below the minimum collateral ratio, this method wil deleverage (liquidate)
     * that account. `depositAmountExternal` in the borrow currency will be transferred from the liquidator
     * and used to offset the account's debt position. The liquidator will receive either vaultShares or
     * cash depending on the vault's configuration.
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param liquidator the address that will receive profits from liquidation
     * @param depositAmountPrimeCash amount of cash to deposit
     * @return vaultSharesFromLiquidation amount of vaultShares received from liquidation
     */
    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash);

    function liquidateVaultCashBalance(
        address account,
        address vault,
        address liquidator,
        uint256 currencyIndex,
        int256 fCashDeposit
    ) external returns (int256 cashToLiquidator);

    function liquidateExcessVaultCash(
        address account,
        address vault,
        address liquidator,
        uint256 excessCashIndex,
        uint256 debtIndex,
        uint256 _depositUnderlyingInternal
    ) external payable returns (int256 cashToLiquidator);
}

interface IVaultAccountHealth {
    function getVaultAccountHealthFactors(address account, address vault) external view returns (
        VaultAccountHealthFactors memory h,
        int256[3] memory maxLiquidatorDepositUnderlying,
        uint256[3] memory vaultSharesToLiquidator
    );

    function calculateDepositAmountInDeleverage(
        uint256 currencyIndex,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        VaultState memory vaultState,
        int256 depositUnderlyingInternal
    ) external returns (int256 depositInternal, uint256 vaultSharesToLiquidator, PrimeRate memory);

    function getfCashRequiredToLiquidateCash(
        uint16 currencyId,
        uint256 maturity,
        int256 vaultAccountCashBalance
    ) external view returns (int256 fCashRequired, int256 discountFactor);

    function checkVaultAccountCollateralRatio(address vault, address account) external;

    function getVaultAccount(address account, address vault) external view returns (VaultAccount memory);
    function getVaultAccountWithFeeAccrual(
        address account, address vault
    ) external view returns (VaultAccount memory, int256 accruedPrimeVaultFeeInUnderlying);

    function getVaultConfig(address vault) external view returns (VaultConfig memory vaultConfig);

    function getBorrowCapacity(address vault, uint16 currencyId) external view returns (
        uint256 currentPrimeDebtUnderlying,
        uint256 totalfCashDebt,
        uint256 maxBorrowCapacity
    );

    function getSecondaryBorrow(address vault, uint16 currencyId, uint256 maturity) 
        external view returns (int256 totalDebt);

    /// @notice View method to get vault state
    function getVaultState(address vault, uint256 maturity) external view returns (VaultState memory vaultState);

    function getVaultAccountSecondaryDebt(address account, address vault) external view returns (
        uint256 maturity,
        int256[2] memory accountSecondaryDebt,
        int256[2] memory accountSecondaryCashHeld
    );

    function signedBalanceOfVaultTokenId(address account, uint256 id) external view returns (int256);
}

interface IVaultController is IVaultAccountAction, IVaultAction, IVaultLiquidationAction, IVaultAccountHealth {}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IRewardPool {
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function balanceOf(address _account) external view returns(uint256);
    function pid() external view returns(uint256);
    function operator() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import {BaseStrategyVault} from "./BaseStrategyVault.sol";
import {Errors} from "@contracts/global/Errors.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {TypeConvert} from "@contracts/global/TypeConvert.sol";
import {TokenUtils} from "@contracts/utils/TokenUtils.sol";
import {StrategyUtils} from "./StrategyUtils.sol";
import {VaultStorage} from "./VaultStorage.sol";

import {IERC20} from "@interfaces/IERC20.sol";
import {
    ISingleSidedLPStrategyVault,
    StrategyVaultSettings,
    InitParams,
    StrategyVaultState,
    SingleSidedRewardTradeParams,
    DepositParams,
    DepositTradeParams,
    RedeemParams,
    TradeParams
} from "@interfaces/notional/ISingleSidedLPStrategyVault.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {ITradingModule, DexId} from "@interfaces/trading/ITradingModule.sol";

/**
 * @notice Base contract for the SingleSidedLP strategy. This strategy deposits into an LP
 * pool given a single borrowed currency. Allows for users to trade via external exchanges
 * during entry and exit, but the general expected behavior is single sided entries and
 * exits. Inheriting contracts will fill in the implementation details for integration with
 * the external DEX pool.
 */
abstract contract SingleSidedLPVaultBase is BaseStrategyVault, UUPSUpgradeable, ISingleSidedLPStrategyVault {
    using TypeConvert for uint256;
    using VaultStorage for StrategyVaultState;

    uint256 internal constant MAX_TOKENS = 5;
    uint8 internal constant NOT_FOUND = type(uint8).max;
    /// @notice Bit mask for the 'LOCKED" flag big
    uint32 internal constant FLAG_LOCKED = 1 << 0;

    /************************************************************************
     * VIRTUAL FUNCTIONS                                                    *
     * These virtual functions are used to isolate implementation specific  *
     * behavior.                                                            *
     ************************************************************************/

    /// @notice Total number of tokens held by the LP token
    function NUM_TOKENS() internal view virtual returns (uint256);

    /// @notice Addresses of tokens held and decimal places of each token. ETH will always be
    /// recorded in this array as Deployments.ETH_Address
    function TOKENS() public view virtual returns (IERC20[] memory, uint8[] memory decimals);

    /// @notice Address of the LP token
    function POOL_TOKEN() internal view virtual returns (IERC20);

    /// @notice Index of the TOKENS() array that refers to the primary borrowed currency by the
    /// leveraged vault. All valuations are done in terms of this currency.
    function PRIMARY_INDEX() internal view virtual returns (uint256);

    /// @notice Precision (i.e. 10 ** decimals) of the LP token.
    function POOL_PRECISION() internal view virtual returns (uint256);

    /// @notice Returns the value of one LP token in terms of the primary borrowed currency by this
    /// strategy. Will revert if the spot price on the pool is not within some deviation tolerance of
    /// the implied oracle price. This is intended to prevent any pool manipulation.
    /// The value of the LP token is calculated as the value of the token if all the balance claims are
    /// withdrawn proportionally and then converted to the primary currency at the oracle price. Slippage
    /// from selling the tokens is not considered, any slippage effects will be captured by the maximum
    /// leverage ratio allowed before liquidation.
    function _checkPriceAndCalculateValue() internal view virtual returns (uint256 oneLPValueInPrimary);

    /// @notice Called once during initialization to set the initial token approvals.
    function _initialApproveTokens() internal virtual;

    /// @notice Called to claim reward tokens
    function _claimRewardTokens() internal virtual;

    /// @notice Called during reward reinvestment to validate that the token being sold is not one
    /// of the tokens that is required for the vault to function properly (i.e. one of the pool tokens
    /// or any of the reward booster tokens).
    function _isInvalidRewardToken(address token) internal view virtual returns (bool);

    /// @notice Implementation specific wrapper for joining a pool with the given amounts. Will also
    /// stake on the relevant booster protocol.
    function _joinPoolAndStake(
        uint256[] memory amounts, uint256 minPoolClaim
    ) internal virtual returns (uint256 lpTokens);

    /// @notice Implementation specific wrapper for unstaking from the booster protocol and withdrawing
    /// funds from the LP pool
    function _unstakeAndExitPool(
        uint256 poolClaim, uint256[] memory minAmounts, bool isSingleSided
    ) internal virtual returns (uint256[] memory exitBalances);

    /// @notice Returns the total supply of the pool token. Is a virtual function because
    /// ComposableStablePools use a "virtual supply" and a different method must be called
    /// to get the actual total supply.
    function _totalPoolSupply() internal view virtual returns (uint256) {
        return POOL_TOKEN().totalSupply();
    }

    /************************************************************************
     * CLASS FUNCTIONS                                                      *
     * Below are class functions that represent the base implementation     *
     * of the Single Sided LP strategy.                                     *
     ************************************************************************/

    constructor(NotionalProxy notional_, ITradingModule tradingModule_)
        BaseStrategyVault(notional_, tradingModule_) {}

    /************************************************************************
     * EXTERNAL VIEW FUNCTIONS                                              *
     ************************************************************************/

    /// @notice Returns basic information about the vault for use in the user interface.
    function getStrategyVaultInfo() external view override returns (SingleSidedLPStrategyVaultInfo memory) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        StrategyVaultSettings memory settings = VaultStorage.getStrategyVaultSettings();

        return SingleSidedLPStrategyVaultInfo({
            pool: address(POOL_TOKEN()),
            singleSidedTokenIndex: uint8(PRIMARY_INDEX()),
            totalLPTokens: state.totalPoolClaim,
            totalVaultShares: state.totalVaultSharesGlobal,
            maxPoolShare: settings.maxPoolShare,
            oraclePriceDeviationLimitPercent: settings.oraclePriceDeviationLimitPercent
        });
    }

    /// @notice Returns the current locked status of the vault
    function isLocked() public view returns (bool) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        return _hasFlag(state.flags, FLAG_LOCKED);
    }

    /// @notice Returns the current price of a vault share, even when there are no vault shares
    /// in the strategy. Used by the user interface to collect historical valuation information.
    function getExchangeRate(uint256 /* maturity */) external view override returns (int256) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        uint256 oneLPValueInPrimary = _checkPriceAndCalculateValue();
        // If inside an emergency exit, just report the one LP value in primary since the total
        // pool claim will be 0
        if (state.totalVaultSharesGlobal == 0 || isLocked()) {
            return oneLPValueInPrimary.toInt();
        } else {
            uint256 lpTokensPerVaultShare = (uint256(Constants.INTERNAL_TOKEN_PRECISION) * state.totalPoolClaim)
                / state.totalVaultSharesGlobal;
            return (oneLPValueInPrimary * lpTokensPerVaultShare / POOL_PRECISION()).toInt();
        }
    }

    /************************************************************************
     * ADMIN FUNCTIONS                                                      *
     * Administrative functions to set settings and initialize the vault.   *
     * These methods are only callable by the Notional owner.               *
     ************************************************************************/

    /// @notice Allow Notional owner to upgrade the contract
    function _authorizeUpgrade(
        address /* newImplementation */
    ) internal override onlyNotionalOwner {}

    /// @notice Updates the vault settings include the maximum oracle deviation limit and the
    /// maximum percent of the LP pool that the vault can hold.
    function setStrategyVaultSettings(StrategyVaultSettings calldata settings) external onlyNotionalOwner {
        // Validation occurs inside this method
        VaultStorage.setStrategyVaultSettings(settings);
    }

    /// @notice Called to initialize the vault and set the initial approvals. All of the other vault
    /// parameters are set via immutable parameters already.
    function initialize(InitParams calldata params) external override initializer onlyNotionalOwner {
        // Initialize the base vault
        __INIT_VAULT(params.name, params.borrowCurrencyId);

        // Settings are validated in setStrategyVaultSettings
        VaultStorage.setStrategyVaultSettings(params.settings);

        _initialApproveTokens();
    }

    /************************************************************************
     * USER FUNCTIONS                                                       *
     * These functions are called during normal usage of the vault.         *
     * They allow for deposits and redemptions from the vault as well as a  *
     * valuation check that is used by Notional to determine if the user is *
     * properly collateralized.                                             *
     ************************************************************************/

    /// @notice This is a virtual function called by BaseStrategyVault which ensures that
    /// this method is only called by Notional after an initial borrow has been made and
    /// the deposit amount has been transferred to this vault. Will join the LP pool with
    /// the funds given and then return the total vault shares minted.
    function _depositFromNotional(
        address /* account */, uint256 deposit, uint256 /* maturity */, bytes calldata data
    ) internal override virtual whenNotLocked returns (uint256 vaultSharesMinted) {
        // Short circuit any zero deposit amounts
        if (deposit == 0) return 0;

        DepositParams memory params = abi.decode(data, (DepositParams));
        uint256[] memory amounts = new uint256[](NUM_TOKENS());
        amounts[PRIMARY_INDEX()] = deposit;

        // If depositTrades are specified, then parts of the initial deposit are traded
        // for corresponding amounts of the other pool tokens via external exchanges. If
        // these amounts are not specified then the pool will just be joined single sided.
        // Deposit trades are not automatically enabled on vaults since the trading module
        // requires explicit permission for every token that can be sold by an address.
        if (params.depositTrades.length > 0) {
            (IERC20[] memory tokens, /* */) = TOKENS();
            // This is an external library call so the memory location of amounts is
            // different before and after the call.
            amounts = StrategyUtils.executeDepositTrades(
                tokens,
                amounts,
                params.depositTrades,
                PRIMARY_INDEX()
            );
        }

        uint256 lpTokens = _joinPoolAndStake(amounts, params.minPoolClaim);
        return _mintVaultShares(lpTokens);
    }

    /// @notice Given a number of LP tokens minted, issues vault shares back to the holder. Vault
    /// shares are claim on the LP tokens held by the vault. As rewards are reinvested, one vault
    /// share is a claim on an increasing amount of LP tokens.
    function _mintVaultShares(uint256 lpTokens) internal returns (uint256 vaultShares) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        if (state.totalPoolClaim == 0) {
            // Vault Shares are in 8 decimal precision
            vaultShares = (lpTokens * uint256(Constants.INTERNAL_TOKEN_PRECISION)) / POOL_PRECISION();
        } else {
            vaultShares = (lpTokens * state.totalVaultSharesGlobal) / state.totalPoolClaim;
        }

        // Updates internal storage here
        state.totalPoolClaim += lpTokens;
        state.totalVaultSharesGlobal += vaultShares.toUint80();
        state.setStrategyVaultState();

        // Checks that the vault does not own too large of a portion of the pool. If this is the case,
        // single sided exits may have a detrimental effect on the liquidity.
        uint256 maxPoolShare = VaultStorage.getStrategyVaultSettings().maxPoolShare;
        uint256 maxSupplyThreshold = (_totalPoolSupply() * maxPoolShare) / Constants.VAULT_PERCENT_BASIS;
        if (maxSupplyThreshold < state.totalPoolClaim)
            revert Errors.PoolShareTooHigh(state.totalPoolClaim, maxSupplyThreshold);
    }

    /// @notice This is a virtual function called by BaseStrategyVault which ensures that
    /// this method is only called by Notional after an initial position has been made. Will
    /// withdraw the LP tokens from the pool, either single sided or proportionally. On a
    /// proportional exit, will trade all the tokens back to the primary in order to exit the pool.
    /// @return finalPrimaryBalance which is the amount of funds that the vault will transfer back
    /// to Notional and the account to repay debts and withdraw profits.
    function _redeemFromNotional(
        address /* account */, uint256 vaultShares, uint256 /* maturity */, bytes calldata data
    ) internal override virtual whenNotLocked returns (uint256 finalPrimaryBalance) {
        // Short circuit any zero redemption amounts, this can occur during rolling positions
        // or withdraw cash balances post liquidation.
        if (vaultShares == 0) return 0;

        // Updates internal account to deduct the vault shares.
        uint256 poolClaim = _redeemVaultShares(vaultShares);
        RedeemParams memory params = abi.decode(data, (RedeemParams));

        bool isSingleSided = params.redemptionTrades.length == 0;
        // Returns the amount of each token that has been withdrawn from the pool.
        uint256[] memory exitBalances = _unstakeAndExitPool(poolClaim, params.minAmounts, isSingleSided);
        if (!isSingleSided) {
            // If not a single sided trade, will execute trades back to the primary token on
            // external exchanges. This method will execute EXACT_IN trades to ensure that
            // all of the balance in the other tokens is sold for primary.
            (IERC20[] memory tokens, /* */) = TOKENS();
            // Redemption trades are not automatically enabled on vaults since the trading module
            // requires explicit permission for every token that can be sold by an address.
            return StrategyUtils.executeRedemptionTrades(
                tokens,
                exitBalances,
                params.redemptionTrades,
                PRIMARY_INDEX()
            );
        } else {
            // No explicit check is done here to ensure that the other balances are zero, assumed
            // that the `_unstakeAndExitPool` method on the implementation is correct and will only
            // ever withdraw to a single balance.
            return exitBalances[PRIMARY_INDEX()];
        }
    }

    /// @notice Updates internal account for vault share redemption.
    function _redeemVaultShares(uint256 vaultShares) internal returns (uint256 poolClaim) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        // Will revert on divide by zero, which is the correct behavior
        poolClaim = (vaultShares * state.totalPoolClaim) / state.totalVaultSharesGlobal;

        state.totalPoolClaim -= poolClaim;
        // Will revert on underflow if vault shares is greater than total shares global
        state.totalVaultSharesGlobal -= vaultShares.toUint80();
        state.setStrategyVaultState();
    }

    /// @notice Converts the vault shares to an oracle value in underlying tokens. Used by Notional
    /// to determine the collateral position of a vault user. If the vault is locked due to an
    /// emergency exit, this function will revert which will prevent users from entering, exiting,
    /// and being liquidated. During emergency exit, the vault will not be holding any LP tokens and
    /// therefore this calculation will not be correct.
    function convertStrategyToUnderlying(
        address /* */, uint256 vaultShares, uint256 /* */
    ) public view virtual override whenNotLocked returns (int256 underlyingValue) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        // Will revert on divide by zero, which is the correct behavior
        uint256 lpTokens = (vaultShares * state.totalPoolClaim) / state.totalVaultSharesGlobal;
        uint256 oneLPValueInPrimary = _checkPriceAndCalculateValue();

        return (oneLPValueInPrimary * lpTokens / POOL_PRECISION()).toInt();
    }

    /// @notice Returns the pair price of two tokens via the TRADING_MODULE which holds a registry
    /// of oracles. Will revert of the oracle pair is not listed.
    function _getOraclePairPrice(address base, address quote) internal view returns (uint256) {
        (int256 rate, int256 precision) = TRADING_MODULE.getOraclePrice(base, quote);
        require(rate > 0);
        require(precision > 0);
        return uint256(rate) * POOL_PRECISION() / uint256(precision);
    }

    /// @notice Helper method called by _checkPriceAndCalculateValue which will supply the relevant
    /// pool balances and spot prices. Calculates the claim of one LP token on relevant pool balances
    /// and compares the oracle price to the spot price, reverting if the deviation is too high.
    /// @return oneLPValueInPrimary the value of one LP token in terms of the primary borrowed currency
    function _calculateLPTokenValue(
        uint256[] memory balances,
        uint256[] memory spotPrices
    ) internal view returns (uint256 oneLPValueInPrimary) {
        (IERC20[] memory tokens, uint8[] memory decimals) = TOKENS();
        address primaryToken = address(tokens[PRIMARY_INDEX()]);
        uint256 primaryDecimals = 10 ** decimals[PRIMARY_INDEX()];
        uint256 totalSupply = _totalPoolSupply();
        uint256 limit = VaultStorage.getStrategyVaultSettings().oraclePriceDeviationLimitPercent;

        for (uint256 i; i < tokens.length; i++) {
            // Skip the pool token if it is in the token list (i.e. ComposablePools)
            if (address(tokens[i]) == address(POOL_TOKEN())) continue;
            // This is the claim on the pool balance of 1 LP token.
            uint256 tokenClaim = balances[i] * POOL_PRECISION() / totalSupply;
            if (i == PRIMARY_INDEX()) {
                oneLPValueInPrimary += tokenClaim;
            } else {
                uint256 price = _getOraclePairPrice(primaryToken, address(tokens[i]));

                // Check that the spot price and the oracle price are near each other. If this is
                // not true then we assume that the LP pool is being manipulated.
                uint256 lowerLimit = price * (Constants.VAULT_PERCENT_BASIS - limit) / Constants.VAULT_PERCENT_BASIS;
                uint256 upperLimit = price * (Constants.VAULT_PERCENT_BASIS + limit) / Constants.VAULT_PERCENT_BASIS;
                if (spotPrices[i] < lowerLimit || upperLimit < spotPrices[i]) {
                    revert Errors.InvalidPrice(price, spotPrices[i]);
                }

                // Convert the token claim to primary using the oracle pair price.
                uint256 secondaryDecimals = 10 ** decimals[i];
                oneLPValueInPrimary += (tokenClaim * POOL_PRECISION() * primaryDecimals) / 
                    (price * secondaryDecimals);
            }
        }
    }

    /************************************************************************
     * REWARD REINVESTMENT                                                  *
     * Methods used by bots to claim reward tokens and reinvest them as LP  *
     * tokens which are donated to all vault users.                         *
     ************************************************************************/

    /// @notice Ensures that only whitelisted bots can claim reward tokens.
    function claimRewardTokens() external override onlyRole(REWARD_REINVESTMENT_ROLE) {
        _claimRewardTokens();
    }

    /// @notice Ensures that only whitelisted bots can reinvest rewards. Since rewards
    /// are typically less liquid than pool tokens and lack oracles, reward reinvestment
    /// is done using explicitly set slippage limits by the reinvestment bots. Reinvestment
    /// will fail if the spot prices are not close to the oracle prices to ensure that
    /// there is no front running the reinvestment.
    function reinvestReward(
        SingleSidedRewardTradeParams[] calldata trades,
        uint256 minPoolClaim
    ) external whenNotLocked onlyRole(REWARD_REINVESTMENT_ROLE) returns (
        address rewardToken,
        uint256 amountSold,
        uint256 poolClaimAmount
    ) {
        // Will revert if spot prices are not in line with the oracle values
        _checkPriceAndCalculateValue();

        // Require one trade per token, if we do not want to buy any tokens at a
        // given index then the amount should be set to zero. This applies to pool
        // tokens like in the ComposableStablePool.
        require(trades.length == NUM_TOKENS());
        uint256[] memory amounts;
        // The sell token on all trades must be the same (checked inside executeRewardTrades) so
        // just validate here that the sellToken is a valid reward token (i.e. none of the tokens
        // used in the regular functioning of the vault).
        rewardToken = trades[0].sellToken;
        if (_isInvalidRewardToken(rewardToken)) revert Errors.InvalidRewardToken(rewardToken);
        (amountSold, amounts) = _executeRewardTrades(trades, rewardToken);

        poolClaimAmount = _joinPoolAndStake(amounts, minPoolClaim);

        // Increase LP token amount without minting additional vault shares
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        // Do not re-invest if there are no vault shares
        require(state.totalVaultSharesGlobal > 0);
        state.totalPoolClaim += poolClaimAmount;
        state.setStrategyVaultState();
    }

    function _executeRewardTrades(
        SingleSidedRewardTradeParams[] calldata trades,
        address rewardToken
    ) internal returns (uint256 amountSold, uint256[] memory amounts) {
        (IERC20[] memory tokens, /* */) = TOKENS();
        (amounts, amountSold) = StrategyUtils.executeRewardTrades(
            tokens, trades, rewardToken, address(POOL_TOKEN())
        );
    }

    /************************************************************************
     * EMERGENCY EXIT                                                       *
     * In case of an emergency, will allow a whitelisted guardian to exit   *
     * funds on the vault and locks the vault from further usage. The owner *
     * can restore funds to the LP pool and reinstate vault usage. If the   *
     * vault cannot be fully restored after an exit, the vault will need to *
     * be upgraded and unwound manually to ensure that debts are repaid and *
     * users can withdraw their funds.                                      *
     ************************************************************************/

    /// @notice Allows the function to execute only when the vault is not locked
    modifier whenNotLocked() {
        if (isLocked()) revert Errors.VaultLocked();
        _;
    }

    /// @notice Allows the function to execute only when the vault is locked
    modifier whenLocked() {
        if (!isLocked()) revert Errors.VaultNotLocked();
        _;
    }

    /// @notice Checks if a flag bit is set
    function _hasFlag(uint32 flags, uint32 flagID) private pure returns (bool) {
        return (flags & flagID) == flagID;
    }

    /// @notice Locks the vault, preventing deposits and redemptions. Used during
    /// emergency exit
    function _lockVault() internal {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        // Set locked flag
        state.flags = state.flags | FLAG_LOCKED;
        VaultStorage.setStrategyVaultState(state);
        emit VaultLocked();
    }

    /// @notice Unlocks the vault, called during restore vault.
    function _unlockVault() internal {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        // Remove locked flag
        state.flags = state.flags & ~FLAG_LOCKED;
        VaultStorage.setStrategyVaultState(state);
        emit VaultUnlocked();
    }

    /// @notice Allows the emergency exit role to trigger an emergency exit on the vault.
    /// In this situation, the `claimToExit` is withdrawn proportionally to the underlying
    /// tokens and held on the vault. The vault is locked so that no entries, exits or
    /// valuations of vaultShares can be performed.
    /// @param claimToExit if this is set to zero, the entire pool claim is withdrawn
    function emergencyExit(
        uint256 claimToExit, bytes calldata /* data */
    ) external override onlyRole(EMERGENCY_EXIT_ROLE) {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();
        if (claimToExit == 0 || claimToExit > state.totalPoolClaim) claimToExit = state.totalPoolClaim;

        // By setting min amounts to zero, we will accept whatever tokens come from the pool
        // in a proportional exit. Front running will not have an effect since no trading will
        // occur during a proportional exit.
        uint256[] memory exitBalances = _unstakeAndExitPool(claimToExit, new uint256[](NUM_TOKENS()), false);

        state.totalPoolClaim = state.totalPoolClaim - claimToExit;
        state.setStrategyVaultState();

        emit EmergencyExit(claimToExit, exitBalances);
        _lockVault();
    }

    /// @notice Restores withdrawn tokens from emergencyExit back into the vault proportionally.
    /// Unlocks the vault after restoration so that normal functionality is restored.
    /// @param minPoolClaim slippage limit to prevent front running
    /// @param data the owner will pass in an array of amounts for the pool to re-enter the vault.
    /// This prevents any front running or manipulation of the vault balances.
    function restoreVault(
        uint256 minPoolClaim, bytes calldata data
    ) external override whenLocked onlyNotionalOwner {
        StrategyVaultState memory state = VaultStorage.getStrategyVaultState();

        uint256[] memory amounts = abi.decode(data, (uint256[]));

        // No trades are specified so this joins proportionally using the
        // amounts specified.
        uint256 poolTokens = _joinPoolAndStake(amounts, minPoolClaim);

        state.totalPoolClaim = state.totalPoolClaim + poolTokens;
        state.setStrategyVaultState();

        _unlockVault();
    }

    /// @notice This is a trusted method that can only be executed while the vault is locked. The owner
    /// may trade tokens prior to restoring the vault if the tokens withdrawn are imbalanced. In this
    /// method, one of the tokens held is sold for other tokens that go into the pool. If multiple tokens
    /// need to be sold then this method will be called multiple times prior to restoreVault.
    function tradeTokensBeforeRestore(
        SingleSidedRewardTradeParams[] calldata trades
    ) external override whenLocked onlyNotionalOwner {
        // The sell token on all trades must be the same (checked inside executeRewardTrades). In this
        // method we do not validate the sell token so we can sell any of the tokens held on the vault
        // in exchange for any other token that goes into the pool.
        _executeRewardTrades(trades, trades[0].sellToken);
    }

    // Storage gap for future potential upgrades
    uint256[100] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface ICurveGauge {
    function claim_rewards() external;
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;
pragma abicoder v2;

struct DepositData {
    address[] targets;
    bytes[] callData;
    uint256[] msgValue;
    uint256 underlyingDepositAmount;
    address assetToken;
}

struct RedeemData {
    address[] targets;
    bytes[] callData;
    uint256 expectedUnderlying;
    address assetToken;
}

interface IPrimeCashHoldingsOracle {
    /// @notice Returns a list of the various holdings for the prime cash
    /// currency
    function holdings() external view returns (address[] memory);

    /// @notice Returns the underlying token that all holdings can be redeemed
    /// for.
    function underlying() external view returns (address);
    
    /// @notice Returns the native decimal precision of the underlying token
    function decimals() external view returns (uint8);

    /// @notice Returns the total underlying held by the caller in all the
    /// listed holdings
    function getTotalUnderlyingValueStateful() external returns (
        uint256 nativePrecision,
        uint256 internalPrecision
    );

    function getTotalUnderlyingValueView() external view returns (
        uint256 nativePrecision,
        uint256 internalPrecision
    );

    /// @notice Returns calldata for how to withdraw an amount
    function getRedemptionCalldata(uint256 withdrawAmount) external view returns (
        RedeemData[] memory redeemData
    );

    function holdingValuesInUnderlying() external view returns (uint256[] memory);

    function getRedemptionCalldataForRebalancing(
        address[] calldata _holdings, 
        uint256[] calldata withdrawAmounts
    ) external view returns (
        RedeemData[] memory redeemData
    );

    function getDepositCalldataForRebalancing(
        address[] calldata _holdings, 
        uint256[] calldata depositAmounts
    ) external view returns (
        DepositData[] memory depositData
    );
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

interface IRewarder {
    function claimRewards(
        address account,
        uint16 currencyId,
        uint256 nTokenBalanceBefore,
        uint256 nTokenBalanceAfter,
        int256  netNTokenSupplyChange,
        uint256 NOTETokensClaimed
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

struct LendingPoolStorage {
  ILendingPool lendingPool;
}

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (ReserveData memory);

  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "../../proxy/AccessControlUpgradeable.sol";

import {Token, TokenType} from "@contracts/global/Types.sol";
import {Deployments} from "@deployments/Deployments.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {IStrategyVault} from "@interfaces/notional/IStrategyVault.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {ITradingModule, Trade} from "@interfaces/trading/ITradingModule.sol";
import {IERC20} from "@interfaces/IERC20.sol";
import {TokenUtils} from "@contracts/utils/TokenUtils.sol";
import {TradeHandler} from "../../trading/TradeHandler.sol";
import {nProxy} from "../../proxy/nProxy.sol";

abstract contract BaseStrategyVault is Initializable, IStrategyVault, AccessControlUpgradeable {
    using TokenUtils for IERC20;
    using TradeHandler for Trade;

    bytes32 internal constant EMERGENCY_EXIT_ROLE = keccak256("EMERGENCY_EXIT_ROLE");
    bytes32 internal constant REWARD_REINVESTMENT_ROLE = keccak256("REWARD_REINVESTMENT_ROLE");
    bytes32 internal constant STATIC_SLIPPAGE_TRADING_ROLE = keccak256("STATIC_SLIPPAGE_TRADING_ROLE");

    /// @notice Hardcoded on the implementation contract during deployment
    NotionalProxy internal immutable NOTIONAL;
    ITradingModule internal immutable TRADING_MODULE;
    uint8 constant internal INTERNAL_TOKEN_DECIMALS = 8;

    // Borrowing Currency ID the vault is configured with
    uint16 private _BORROW_CURRENCY_ID;
    // True if the underlying is ETH
    bool private _UNDERLYING_IS_ETH;
    // Address of the underlying token
    IERC20 private _UNDERLYING_TOKEN;
    // NOTE: end of first storage slot here

    // Name of the vault
    string private _NAME;


    /**************************************************************************/
    /* Global Modifiers, Constructor and Initializer                          */
    /**************************************************************************/
    modifier onlyNotional() {
        require(msg.sender == address(NOTIONAL), "Unauthorized");
        _;
    }

    modifier onlyNotionalOwner() {
        require(msg.sender == address(NOTIONAL.owner()), "Unauthorized");
        _;
    }
    
    /// @notice Set the NOTIONAL address on deployment
    constructor(NotionalProxy notional_, ITradingModule tradingModule_) initializer {
        // Make sure we are using the correct Deployments lib
        require(Deployments.CHAIN_ID == block.chainid);

        NOTIONAL = notional_;
        TRADING_MODULE = tradingModule_;
    }

    /// @notice Override this method and revert if the contract should not receive ETH.
    /// Upgradeable proxies must have this implemented on the proxy for transfer calls
    /// succeed (use nProxy for this).
    receive() external virtual payable {
        // Allow ETH transfers to succeed
    }

    /// @notice All strategy vaults MUST implement 8 decimal precision
    function decimals() public override pure returns (uint8) {
        return INTERNAL_TOKEN_DECIMALS;
    }

    function name() external override view returns (string memory) {
        return _NAME;
    }

    function strategy() external virtual view returns (bytes4);

    function _borrowCurrencyId() internal view returns (uint16) {
        return _BORROW_CURRENCY_ID;
    }

    function _underlyingToken() internal view returns (IERC20) {
        return _UNDERLYING_TOKEN;
    }

    function _isUnderlyingETH() internal view returns (bool) {
        return _UNDERLYING_IS_ETH;
    }

    /// @notice Can only be called once during initialization
    function __INIT_VAULT(
        string memory name_,
        uint16 borrowCurrencyId_
    ) internal onlyInitializing {
        _NAME = name_;
        _BORROW_CURRENCY_ID = borrowCurrencyId_;

        address underlyingAddress = _getNotionalUnderlyingToken(borrowCurrencyId_);
        _UNDERLYING_TOKEN = IERC20(underlyingAddress);
        _UNDERLYING_IS_ETH = underlyingAddress == address(0);
        _setupRole(DEFAULT_ADMIN_ROLE, NOTIONAL.owner());
    }

    function _getNotionalUnderlyingToken(uint16 currencyId) internal view returns (address) {
        (/* */, Token memory underlyingToken) = NOTIONAL.getCurrency(currencyId);
        return underlyingToken.tokenAddress;
    }

    /// @notice Can be used to delegate call to the TradingModule's implementation in order to execute
    /// a trade.
    function _executeTrade(
        uint16 dexId,
        Trade memory trade
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        return trade._executeTrade(dexId);
    }

    /**************************************************************************/
    /* Virtual Methods Requiring Implementation                               */
    /**************************************************************************/
    function convertStrategyToUnderlying(
        address account,
        uint256 vaultShares,
        uint256 maturity
    ) public view virtual returns (int256 underlyingValue);

    function getExchangeRate(uint256 maturity) external virtual view returns (int256);
    
    // Vaults need to implement these two methods
    function _depositFromNotional(
        address account,
        uint256 deposit,
        uint256 maturity,
        bytes calldata data
    ) internal virtual returns (uint256 vaultSharesMinted);

    function _redeemFromNotional(
        address account,
        uint256 vaultShares,
        uint256 maturity,
        bytes calldata data
    ) internal virtual returns (uint256 tokensFromRedeem);

    function _convertVaultSharesToPrimeMaturity(
        address /* account */,
        uint256 /* vaultShares */,
        uint256 /* maturity */
    ) internal virtual returns (uint256 /* primeVaultShares */) {
        revert();
    }

    function _checkReentrancyContext() internal virtual;

    /**************************************************************************/
    /* Default External Method Implementations                                */
    /**************************************************************************/
    function depositFromNotional(
        address account,
        uint256 deposit,
        uint256 maturity,
        bytes calldata data
    ) external payable onlyNotional returns (uint256 vaultSharesMinted) {
        return _depositFromNotional(account, deposit, maturity, data);
    }

    function redeemFromNotional(
        address account,
        address receiver,
        uint256 vaultShares,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external onlyNotional returns (uint256 transferToReceiver) {
        uint256 borrowedCurrencyAmount = _redeemFromNotional(account, vaultShares, maturity, data);

        uint256 transferToNotional;
        if (account == address(this) || borrowedCurrencyAmount <= underlyingToRepayDebt) {
            // It may be the case that insufficient tokens were redeemed to repay the debt. If this
            // happens the Notional will attempt to recover the shortfall from the account directly.
            // This can happen if an account wants to reduce their leverage by paying off debt but
            // does not want to sell strategy tokens to do so.
            // The other situation would be that the vault is calling redemption to deleverage or
            // settle. In that case all tokens go back to Notional.
            transferToNotional = borrowedCurrencyAmount;
        } else {
            transferToNotional = underlyingToRepayDebt;
            unchecked { transferToReceiver = borrowedCurrencyAmount - underlyingToRepayDebt; }
        }

        if (_UNDERLYING_IS_ETH) {
            if (transferToReceiver > 0) payable(receiver).transfer(transferToReceiver);
            if (transferToNotional > 0) payable(address(NOTIONAL)).transfer(transferToNotional);
        } else {
            if (transferToReceiver > 0) _UNDERLYING_TOKEN.checkTransfer(receiver, transferToReceiver);
            if (transferToNotional > 0) _UNDERLYING_TOKEN.checkTransfer(address(NOTIONAL), transferToNotional);
        }
    }

    function convertVaultSharesToPrimeMaturity(
        address account,
        uint256 vaultShares,
        uint256 maturity
    ) external onlyNotional returns (uint256 primeVaultShares) { 
        require(maturity != Constants.PRIME_CASH_VAULT_MATURITY);
        return _convertVaultSharesToPrimeMaturity(account, vaultShares, maturity);
    }

    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash) {
        require(msg.sender == liquidator);
        _checkReentrancyContext();
        return NOTIONAL.deleverageAccount{value: msg.value}(
            account, vault, liquidator, currencyIndex, depositUnderlyingInternal
        );
    }

    function liquidateVaultCashBalance(
        address account,
        address vault,
        address liquidator,
        uint256 currencyIndex,
        int256 fCashDeposit
    ) external returns (int256 cashToLiquidator) {
        require(msg.sender == liquidator);
        return NOTIONAL.liquidateVaultCashBalance(
            account, vault, liquidator, currencyIndex, fCashDeposit
        );
    }

    function _canUseStaticSlippage() internal view returns (bool) {
        return hasRole(STATIC_SLIPPAGE_TRADING_ROLE, msg.sender);
    }

    // Storage gap for future potential upgrades
    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * Common vault errors
 */
library Errors {
    /// @notice Pool price deviates too much from the oracle price
    error InvalidPrice(uint256 oraclePrice, uint256 poolPrice);
    /// @notice The provided slippage is above the configured limit
    error SlippageTooHigh(uint256 slippage, uint32 limit);
    /// @notice Attemping to trade an invalid token
    error InvalidRewardToken(address token);
    /// @notice The vault occupies too much of the underlying pool
    error PoolShareTooHigh(uint256 totalPoolClaim, uint256 poolClaimThreshold);
    /// @notice Staking operation failed
    error StakeFailed();
    /// @notice Unstaking operation failed
    error UnstakeFailed();
    /// @notice Zero pool claim returned due to rounding error
    error ZeroPoolClaim();
    /// @notice Zero vault shares returned due to rounding error
    error ZeroStrategyTokens();
    /// @notice Operation is only permitted when the vault is unlocked
    error VaultLocked();
    /// @notice Operation is only permitted when the vault is locked
    error VaultNotLocked();
    /// @notice Trading through the specified dex is not permitted
    error InvalidDexId(uint256 dexId);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

library TypeConvert {

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function toInt80(int256 x) internal pure returns (int80) {
        require (int256(type(int80).min) <= x && x <= int256(type(int80).max)); // dev: toInt overflow
        return int80(x);
    }

    function toUint80(uint256 x) internal pure returns (uint80) {
        require (x <= uint256(type(uint80).max));
        return uint80(x);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {IERC20} from "@interfaces/IERC20.sol";
import {
    TradeParams,
    DepositTradeParams,
    RedeemParams,
    SingleSidedRewardTradeParams
} from "@interfaces/notional/ISingleSidedLPStrategyVault.sol";
import {TradeHandler} from "../../trading/TradeHandler.sol";
import {Deployments} from "@deployments/Deployments.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {Errors} from "@contracts/global/Errors.sol";
import {ITradingModule, Trade, TradeType, DexId} from "@interfaces/trading/ITradingModule.sol";

/**
 * @notice External library deployed for the purposes of handling SingleSidedLP trades. All
 * the methods in this library are called inside a `delegateCall` context which ensures that
 * the library has access to the calling vault's token balances
 */
library StrategyUtils {
    using TradeHandler for Trade;

    /// @notice Trades the amount of primary token into other secondary tokens prior
    /// to entering a pool.
    function executeDepositTrades(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        DepositTradeParams[] memory depositTrades,
        uint256 primaryIndex
    ) external returns (uint256[] memory) {
        address primaryToken = address(tokens[primaryIndex]);

        for (uint256 i; i < amounts.length; i++) {
            if (i == primaryIndex) continue;
            DepositTradeParams memory t = depositTrades[i];
            // Do not allow ZERO_EX trading in this method since we cannot validate
            // the arbitrary exchange data.
            if (DexId(t.tradeParams.dexId) == DexId.ZERO_EX) revert Errors.InvalidDexId(uint256(DexId.ZERO_EX));

            if (t.tradeAmount > 0) {
                // Always selling the primaryToken and buying the secondary token.
                (uint256 amountSold, uint256 amountBought) = _executeDynamicSlippageTradeExactIn(
                    t.tradeParams, primaryToken, address(tokens[i]), t.tradeAmount
                );

                amounts[i] = amountBought;
                // Will revert on underflow if over-selling the primary borrowed
                amounts[primaryIndex] -= amountSold;
            }
        }

        return amounts;
    }

    /// @notice Trades the amount of secondary tokens into the primary token after
    /// exiting a pool.
    function executeRedemptionTrades(
        IERC20[] memory tokens,
        uint256[] memory exitBalances,
        TradeParams[] memory redemptionTrades,
        uint256 primaryIndex
    ) external returns (uint256 finalPrimaryBalance) {
        address primaryToken = address(tokens[primaryIndex]);

        for (uint256 i; i < exitBalances.length; i++) {
            if (i == primaryIndex) {
                finalPrimaryBalance += exitBalances[i];
                continue;
            }

            TradeParams memory t = redemptionTrades[i];
            // Do not allow ZERO_EX trading in this method since we cannot validate
            // the arbitrary exchange data.
            if (DexId(t.dexId) == DexId.ZERO_EX) revert Errors.InvalidDexId(uint256(DexId.ZERO_EX));

            // Always sell the entire exit balance to the primary token
            if (exitBalances[i] > 0) {
                (/* */, uint256 amountBought) = _executeDynamicSlippageTradeExactIn(
                    t, address(tokens[i]), primaryToken, exitBalances[i]
                );

                finalPrimaryBalance += amountBought;
            }
        }
    }

    /// @notice Executes a set of trades to sell the reward token for constituent pool tokens.
    function executeRewardTrades(
        IERC20[] memory tokens,
        SingleSidedRewardTradeParams[] calldata trades,
        address rewardToken,
        address poolToken
    ) external returns(uint256[] memory amounts, uint256 amountSold) {
        amounts = new uint256[](trades.length);
        uint256 initialRewardBalance = IERC20(rewardToken).balanceOf(address(this));
        for (uint256 i; i < trades.length; i++) {
            // All trades must sell the same token.
            require(trades[i].sellToken == rewardToken);
            // Bypass certain invalid trades
            if (trades[i].amount == 0) continue;
            if (trades[i].buyToken == poolToken) continue;

            // The reward trade can only purchase tokens that go into the pool
            require(trades[i].buyToken == address(tokens[i]));

            uint256 sold;
            uint256 bought;
            if (rewardToken == trades[i].buyToken) {
                // In some rare cases the reward token is actually one of the the tokens
                // in the pool and we do not want to execute a trade against it. In these
                // cases we skip the trade and just mark the amount as "sold" with
                // an equal amount "bought".
                sold = trades[i].amount;
                bought = sold;
            } else {
                // It may be possible that the entire balance of reward tokens is not sold by the vault,
                // but that is ok.
                (sold, bought) = _executeTradeWithStaticSlippage(
                    trades[i].tradeParams, rewardToken, trades[i].buyToken, trades[i].amount
                );
            }

            amounts[i] = bought;
            amountSold += sold;
        }

        // Ensures that in the case when the reward token is one of the tokens in the pool we do not
        // over sell the actual reward token balance.
        require(amountSold <= initialRewardBalance, "Insufficient Reward Tokens");
    }

    /// @notice Executes a trade that uses a dynamic slippage amount relative to the current
    /// oracle price.
    function _executeDynamicSlippageTradeExactIn(
        TradeParams memory params,
        address sellToken,
        address buyToken,
        uint256 amount
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        // Can only do exact in trades
        require(
            params.tradeType == TradeType.EXACT_IN_SINGLE ||
            params.tradeType == TradeType.EXACT_IN_BATCH
        );
        // Ensure that the slippage percent is valid
        require(params.oracleSlippagePercentOrLimit <= Constants.SLIPPAGE_LIMIT_PRECISION);

        Trade memory trade = Trade(
            params.tradeType,
            sellToken,
            buyToken,
            amount,
            0, // No absolute slippage limit is set here
            block.timestamp, // deadline
            params.exchangeData
        );

        (amountSold, amountBought) = trade._executeTradeWithDynamicSlippage(
            params.dexId, uint32(params.oracleSlippagePercentOrLimit)
        );
    }

    /// @notice Executes a trade with a static slippage limit, only used during
    /// reward reinvestment trades since oracles between the reward token and the
    /// purchased tokens may not exist.
    function _executeTradeWithStaticSlippage(
        TradeParams memory params,
        address sellToken,
        address buyToken,
        uint256 amount
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        require(
            params.tradeType == TradeType.EXACT_IN_SINGLE ||
            params.tradeType == TradeType.EXACT_IN_BATCH
        );

        Trade memory trade = Trade(
            params.tradeType,
            sellToken,
            buyToken,
            amount,
            params.oracleSlippagePercentOrLimit,
            block.timestamp, // deadline
            params.exchangeData
        );

        // Execute trade using the absolute slippage limit set by `oracleSlippagePercentOrLimit`
        (amountSold, amountBought) = trade._executeTrade(params.dexId);
    }

    function getLibInfo() external pure returns (address notional, address tradingModule) {
        notional = address(Deployments.NOTIONAL);
        tradingModule = address(Deployments.TRADING_MODULE);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {StrategyVaultSettings, StrategyVaultState} from "@interfaces/notional/ISingleSidedLPStrategyVault.sol";
import {Constants} from "@contracts/global/Constants.sol";

/** 
 * Common vault storage slots
 */
library VaultStorage {
    /// @notice Emitted when vault settings are updated
    event StrategyVaultSettingsUpdated(StrategyVaultSettings settings);

    /// @notice Storage slot for vault settings
    uint256 private constant STRATEGY_VAULT_SETTINGS_SLOT = 1000001;
    /// @notice Storage slot for vault state
    uint256 private constant STRATEGY_VAULT_STATE_SLOT    = 1000002;
    /// @notice Append only

    /// @notice returns the storage slot that contains the vault settings
    function _settings() private pure returns (mapping(uint256 => StrategyVaultSettings) storage store) {
        // Assign storage slot
        assembly { store.slot := STRATEGY_VAULT_SETTINGS_SLOT }
    }

    /// @notice returns the storage slot that contains the vault state
    function _state() private pure returns (mapping(uint256 => StrategyVaultState) storage store) {
        // Assign storage slot
        assembly { store.slot := STRATEGY_VAULT_STATE_SLOT }
    }

    /// @notice returns strategy vault settings
    /// @return vault settings
    function getStrategyVaultSettings() internal view returns (StrategyVaultSettings memory) {
        // Hardcode to the zero slot
        return _settings()[0];
    }

    /// @notice writes the strategy vault settings to storage
    /// @param settings vault settings
    function setStrategyVaultSettings(StrategyVaultSettings memory settings) internal {
        // Check limits
        require(settings.maxPoolShare <= Constants.VAULT_PERCENT_BASIS);
        require(settings.oraclePriceDeviationLimitPercent <= Constants.VAULT_PERCENT_BASIS);

        mapping(uint256 => StrategyVaultSettings) storage store = _settings();
        // Hardcode to the zero slot
        store[0] = settings;

        emit StrategyVaultSettingsUpdated(settings);
    }

    /// @notice returns the strategy vault state
    /// @return vault state
    function getStrategyVaultState() internal view returns (StrategyVaultState memory) {
        // Hardcode to the zero slot
        return _state()[0];
    }

    /// @notice writes the strategy vault state to storage
    /// @param state vault state
    function setStrategyVaultState(StrategyVaultState memory state) internal {
        mapping(uint256 => StrategyVaultState) storage store = _state();
        // Hardcode to the zero slot
        store[0] = state;
    }

}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.6;

import {ITradingModule, Trade, TradeType} from "../trading/ITradingModule.sol";
import {IStrategyVault} from "./IStrategyVault.sol";
import {IERC20} from "../IERC20.sol";

/// @notice Parameters for trades
struct TradeParams {
    /// @notice DEX ID
    uint16 dexId;
    /// @notice Trade type (i.e. Single/Batch)
    TradeType tradeType;
    /// @notice For dynamic trades, this field specifies the slippage percentage relative to
    /// the oracle price. For static trades, this field specifies the slippage limit amount.
    uint256 oracleSlippagePercentOrLimit;
    /// @notice DEX specific data
    bytes exchangeData;
}

/// @notice Deposit trade parameters
struct DepositTradeParams {
    /// @notice Amount of primary tokens to sell
    uint256 tradeAmount;
    /// @notice Trade parameters
    TradeParams tradeParams;
}

/// @notice Deposit parameters
struct DepositParams {
    /// @notice min pool claim for slippage control
    uint256 minPoolClaim;
    /// @notice DepositTradeParams or empty (single-sided entry)
    DepositTradeParams[] depositTrades;
}

/// @notice Redeem parameters
struct RedeemParams {
    /// @notice min amounts for slippage control
    uint256[] minAmounts;
    /// @notice Redemption trades or empty (single-sided exit)
    TradeParams[] redemptionTrades;
}

/// @notice Single-sided reinvestment trading parameters
struct SingleSidedRewardTradeParams {
    /// @notice Address of the token to sell (typically one of the reward tokens)
    address sellToken;
    /// @notice Address of the token to buy (typically one of the pool tokens)
    address buyToken;
    /// @notice Amount of tokens to sell
    uint256 amount;
    /// @notice Trade params
    TradeParams tradeParams;
}

/// @notice Common strategy vault state
struct StrategyVaultState {
    /// @notice Total number of pool tokens
    uint256 totalPoolClaim;
    /// @notice Total number of vault shares across all maturities
    uint80 totalVaultSharesGlobal;
    /// @notice Timestamp of previous settlement
    uint32 lastSettlementTimestamp;
    /// @notice Vault flags
    uint32 flags;
}
struct InitParams {
    string name;
    uint16 borrowCurrencyId;
    StrategyVaultSettings settings;
}

/// @notice Common strategy vault settings
struct StrategyVaultSettings {
    /// @notice Slippage limit for emergency settlement (vault owns too much of the pool)
    uint32 deprecated_emergencySettlementSlippageLimitPercent;
    /// @notice Max share of the pool that the vault is allowed to hold
    uint16 maxPoolShare;
    /// @notice Limits the amount of allowable deviation from the oracle price
    uint16 oraclePriceDeviationLimitPercent;
    /// @notice Slippage limit for joining/exiting pools
    uint16 deprecated_poolSlippageLimitPercent;
}

interface ISingleSidedLPStrategyVault {
    /// @notice Emitted when vault settings are updated
    event StrategyVaultSettingsUpdated(StrategyVaultSettings settings);
    /// @notice Emitted after an emergency exit
    event EmergencyExit(uint256 poolClaimExit, uint256[] exitBalances);
    /// @notice Emitted when the vault is locked
    event VaultLocked();
    /// @notice Emitted when the vault is unlocked
    event VaultUnlocked();

    struct SingleSidedLPStrategyVaultInfo {
        address pool;
        uint8 singleSidedTokenIndex;
        uint256 totalLPTokens;
        uint256 totalVaultShares;
        uint256 maxPoolShare;
        uint256 oraclePriceDeviationLimitPercent;
    }

    function initialize(InitParams calldata params) external;
    function TOKENS() external view returns (IERC20[] memory, uint8[] memory decimals);

    function getStrategyVaultInfo() external view returns (SingleSidedLPStrategyVaultInfo memory);
    function emergencyExit(uint256 claimToExit, bytes calldata data) external;
    function restoreVault(uint256 minPoolClaim, bytes calldata data) external;
    function isLocked() external view returns (bool);

    function claimRewardTokens() external;
    function reinvestReward(
        SingleSidedRewardTradeParams[] calldata trades,
        uint256 minPoolClaim
    ) external returns (address rewardToken, uint256 amountSold, uint256 poolClaimAmount);

    function tradeTokensBeforeRestore(SingleSidedRewardTradeParams[] calldata trades) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                // string(
                //     abi.encodePacked(
                //         "AccessControl: account ",
                //         StringsUpgradeable.toHexString(uint160(account), 20),
                //         " is missing role ",
                //         StringsUpgradeable.toHexString(uint256(role), 32)
                //     )
                // )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender());

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.6;

interface IStrategyVault {

    struct StrategyVaultRoles {
        bytes32 emergencyExit;
        bytes32 rewardReinvestment;
        bytes32 staticSlippageTrading;
    }

    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function strategy() external view returns (bytes4 strategyId);

    // Tells a vault to deposit some amount of tokens from Notional and mint strategy tokens with it.
    function depositFromNotional(
        address account,
        uint256 depositAmount,
        uint256 maturity,
        bytes calldata data
    ) external payable returns (uint256 strategyTokensMinted);

    // Tells a vault to redeem some amount of strategy tokens from Notional and transfer the resulting asset cash
    function redeemFromNotional(
        address account,
        address receiver,
        uint256 strategyTokens,
        uint256 maturity,
        uint256 underlyingToRepayDebt,
        bytes calldata data
    ) external returns (uint256 transferToReceiver);

    function convertStrategyToUnderlying(
        address account,
        uint256 strategyTokens,
        uint256 maturity
    ) external view returns (int256 underlyingValue);

    function getExchangeRate(uint256 maturity) external view returns (int256);

    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash);

    function liquidateVaultCashBalance(
        address account,
        address vault,
        address liquidator,
        uint256 currencyIndex,
        int256 fCashDeposit
    ) external returns (int256 cashToLiquidator);

    function convertVaultSharesToPrimeMaturity(
        address account,
        uint256 vaultShares,
        uint256 maturity
    ) external returns (uint256 primeVaultShares);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {
    ITradingModule,
    Trade,
    TradeFailed,
    DynamicTradeFailed
} from "@interfaces/trading/ITradingModule.sol";
import { Deployments } from "@deployments/Deployments.sol";
import {nProxy} from "../proxy/nProxy.sol";

/// @notice TradeHandler is an internal library to be compiled into StrategyVaults to interact
/// with the TradeModule and execute trades
library TradeHandler {

    /// @notice Can be used to delegate call to the TradingModule's implementation in order to execute
    /// a trade.
    function _executeTradeWithDynamicSlippage(
        Trade memory trade,
        uint16 dexId,
        uint32 dynamicSlippageLimit
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        (bool success, bytes memory result) = nProxy(payable(address(Deployments.TRADING_MODULE))).getImplementation()
            .delegatecall(abi.encodeWithSelector(
                ITradingModule.executeTradeWithDynamicSlippage.selector,
                dexId, trade, dynamicSlippageLimit
            )
        );
        if (!success) revert DynamicTradeFailed();
        (amountSold, amountBought) = abi.decode(result, (uint256, uint256));
    }

    /// @notice Can be used to delegate call to the TradingModule's implementation in order to execute
    /// a trade.
    function _executeTrade(
        Trade memory trade,
        uint16 dexId
    ) internal returns (uint256 amountSold, uint256 amountBought) {
        (bool success, bytes memory result) = nProxy(payable(address(Deployments.TRADING_MODULE))).getImplementation()
            .delegatecall(abi.encodeWithSelector(ITradingModule.executeTrade.selector, dexId, trade));
        if (!success) revert TradeFailed();
        (amountSold, amountBought) = abi.decode(result, (uint256, uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract nProxy is ERC1967Proxy {
    constructor(
        address _logic,
        bytes memory _data
    ) ERC1967Proxy(_logic, _data) {}

    receive() external payable override {
        // Allow ETH transfers to succeed
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}