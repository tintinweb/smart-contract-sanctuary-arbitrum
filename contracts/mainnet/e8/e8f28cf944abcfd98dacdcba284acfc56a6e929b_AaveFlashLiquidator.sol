// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {Deployments} from "@deployments/Deployments.sol";
import {IFlashLoanReceiver} from "@interfaces/aave/IFlashLoanReceiver.sol";
import {IFlashLender} from "@interfaces/aave/IFlashLender.sol";
import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {FlashLiquidatorBase} from "./FlashLiquidatorBase.sol";

contract AaveFlashLiquidator is IFlashLoanReceiver, FlashLiquidatorBase {

    constructor() FlashLiquidatorBase(
        Deployments.NOTIONAL, Deployments.AAVE_LENDER
    ) { }

    function _flashLiquidate(
        address asset,
        uint256 amount,
        bool withdraw,
        LiquidationParams calldata params
    ) internal override {
        address[] memory assets = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        assets[0] = asset;
        amounts[0] = amount;

        IFlashLender(FLASH_LENDER).flashLoan(
            address(this),
            assets,
            amounts,
            new uint256[](1), // modes
            address(this),
            abi.encode(asset, amount, withdraw, params),
            0
        );
    }

    function executeOperation(
        address[] calldata /* assets */,
        uint256[] calldata /* amounts */,
        uint256[] calldata premiums,
        address /* initiator */,
        bytes calldata params
    ) external returns (bool) {
        // NOTE: caller is checked in handleLiquidation
        super.handleLiquidation(premiums[0], false, params); // repay = false for Aave
        return true;
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
    ITradingModule internal constant TRADING_MODULE = ITradingModule(0xBf6B9c5608D520469d8c4BD1E24F850497AF0Bb8);
    address internal constant TREASURY_MANAGER = 0x53144559C0d4a3304e2DD9dAfBD685247429216d;
    address internal constant EMERGENCY_EXIT_MANAGER = 0xbf778Fc19d0B55575711B6339A3680d07352B221;
    address internal constant BALANCER_SPOT_PRICE = 0x904d881ceC1b8bc3f3Ff32cCf9533c1843706E9e;
    IWrappedfCashFactory internal constant WRAPPED_FCASH_FACTORY = IWrappedfCashFactory(0x5D051DeB5db151C2172dCdCCD42e6A2953E27261);

    // Chainlink L2 Sequencer Uptime: https://docs.chain.link/data-feeds/l2-sequencer-feeds/
    AggregatorV2V3Interface internal constant SEQUENCER_UPTIME_ORACLE = AggregatorV2V3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);
    address internal constant AAVE_LENDER = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    //   function ADDRESSES_PROVIDER() external view returns (address);

    //   function LENDING_POOL() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IFlashLender {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.24;

import {NotionalProxy} from "@interfaces/notional/NotionalProxy.sol";
import {IStrategyVault} from "@interfaces/notional/IStrategyVault.sol";
import {WETH9} from "@interfaces/WETH9.sol";
import {TokenUtils, IERC20} from "@contracts/utils/TokenUtils.sol";
import {Constants} from "@contracts/global/Constants.sol";
import {
    Token, 
    VaultAccount, 
    BatchLend,
    BalanceActionWithTrades,
    TradeActionType,
    DepositActionType,
    PortfolioAsset
} from "@contracts/global/Types.sol";
import {BoringOwnable} from "./BoringOwnable.sol";
import {Deployments} from "@deployments/Deployments.sol";

abstract contract FlashLiquidatorBase is BoringOwnable {
    using TokenUtils for IERC20;
    uint16 internal constant ONLY_VAULT_DELEVERAGE           = 1 << 5;

    uint256 internal constant MAX_CURRENCIES = 3;

    NotionalProxy public immutable NOTIONAL;
    address public immutable FLASH_LENDER;

    enum LiquidationType {
        UNKNOWN,
        DELEVERAGE_VAULT_ACCOUNT,
        LIQUIDATE_CASH_BALANCE
    }

    struct LiquidationParams {
        LiquidationType liquidationType;
        address vault;
        address[] accounts;
        bytes redeemData;
        // NOTE: these two are only used for cash liquidation
        uint16 currencyId;
        uint16 currencyIndex;
    }

    error ErrInvalidCurrencyIndex(uint16 index);

    constructor(NotionalProxy notional_, address flashLender_) {
        // Make sure we are using the correct Deployments lib
        uint256 chainId;
        assembly { chainId := chainid() }
        require(Deployments.CHAIN_ID == chainId);

        NOTIONAL = notional_;
        FLASH_LENDER = flashLender_;
        owner = msg.sender;
        uint16 maxCurrencyId = notional_.getMaxCurrencyId();
        uint16[] memory currencies = new uint16[](maxCurrencyId);
        for (uint16 i = 1; i <= maxCurrencyId; i++) currencies[i - 1] = i;
        enableCurrencies(currencies);

        emit OwnershipTransferred(address(0), owner);
    }

    /// @notice Used for profit estimation off chain
    function estimateProfit(
        address asset,
        uint256 amount,
        LiquidationParams calldata params
    ) external onlyOwner returns (uint256) {
        uint256 balance = IERC20(asset).balanceOf(address(this));
        _flashLiquidate(asset, amount, false, params);
        return IERC20(asset).balanceOf(address(this)) - balance;
    }

    /// @notice Primary entry point for the liquidation call
    function flashLiquidate(
        address asset,
        uint256 amount,
        LiquidationParams calldata params
    ) external {
        _flashLiquidate(asset, amount, true, params);
    }

    /// @notice Internal implementation that calls the flash lender in order to receive
    /// a callback on this liquidator in the `handleLiquidation` method.
    function _flashLiquidate(
        address asset,
        uint256 amount,
        bool withdraw,
        LiquidationParams calldata params
    ) internal virtual;

    /// @notice This is the primary entry point after the flash lender transfers the funds
    function handleLiquidation(uint256 fee, bool repay, bytes memory data) internal {
        require(msg.sender == address(FLASH_LENDER));

        (
            address asset,
            uint256 amount,
            bool withdraw,
            LiquidationParams memory params
        ) = abi.decode(data, (address, uint256, bool, LiquidationParams));
        bool isWETH = asset == address(Deployments.WETH);
        bool useVaultDeleverage = (
            NOTIONAL.getVaultConfig(params.vault).flags & ONLY_VAULT_DELEVERAGE == ONLY_VAULT_DELEVERAGE
        );

        // Notional uses ETH internally but flash lenders may send WETH
        if (isWETH) _unwrapETH(amount);

        // Liquidator will liquidate the all the accounts in batch
        uint256 vaultSharesFromLiquidation;
        for (uint256 i; i < params.accounts.length; i++) {
            address account = params.accounts[i];
            (
                VaultAccount memory vaultAccount,
                int256 accruedFeeInUnderlying
            ) = _settleAccountIfNeeded(account, params.vault);

            if (params.liquidationType == LiquidationType.DELEVERAGE_VAULT_ACCOUNT) {
                // Accrue the total vault shares received by deleveraging
                vaultSharesFromLiquidation += _deleverageVaultAccount(
                    account, params.vault, useVaultDeleverage, accruedFeeInUnderlying, isWETH
                );
            } else if (params.liquidationType == LiquidationType.LIQUIDATE_CASH_BALANCE) {
                // NOTE: cannot do batch cash liquidations at this point
                require(params.accounts.length == 1);
                _liquidateCashBalance(vaultAccount, params, asset, useVaultDeleverage);
            }
        }

        // Exit all the vault shares that we've accumulated during liquidation
        if (0 < vaultSharesFromLiquidation) {
            NOTIONAL.exitVault(
                address(this),
                params.vault,
                address(this),
                vaultSharesFromLiquidation,
                0, 0, params.redeemData
            );
        }

        // Rewrap ETH for repayment
        if (isWETH) _wrapETH();

        // Send profits back to the owner
        if (withdraw) {
            _withdrawToOwner(asset, IERC20(asset).balanceOf(address(this)) - amount - fee);
        }

        // Repay the flash lender
        if (repay) {
            IERC20(asset).transfer(msg.sender, amount + fee);
        }
    }

    /// @notice Used to maintain approvals for various currencies, called initially in the constructor
    function enableCurrencies(uint16[] memory currencies) public onlyOwner {
        for (uint256 i; i < currencies.length; i++) {
            (/* Token memory assetToken */, Token memory underlyingToken) = NOTIONAL.getCurrency(currencies[i]);
            if (underlyingToken.tokenAddress == Constants.ETH_ADDRESS) {
                IERC20(address(Deployments.WETH)).checkApprove(address(FLASH_LENDER), type(uint256).max);
            } else {
                IERC20(underlyingToken.tokenAddress).checkApprove(address(FLASH_LENDER), type(uint256).max);
                IERC20(underlyingToken.tokenAddress).checkApprove(address(NOTIONAL), type(uint256).max);
            }
        }
    }

    /// @notice Used via static call on the liquidation bot to get parameters for liquidation
    function getOptimalDeleveragingParams(
        address account, address vault
    ) external returns (uint16 currencyIndex, int256 maxUnderlying) {
        (/* */, int256 accruedFeeInUnderlying) = _settleAccountIfNeeded(account, vault);
        return _getOptimalDeleveragingParams(account, vault, accruedFeeInUnderlying);
    }

    /*** INTERNAL METHODS ***/

    function _settleAccountIfNeeded(
        address account, address vault
    ) private returns (VaultAccount memory vaultAccount, int256 accruedFeeInUnderlying) {
        (
            vaultAccount,
            accruedFeeInUnderlying
        ) = NOTIONAL.getVaultAccountWithFeeAccrual(account, vault);

        if (vaultAccount.maturity != 0 && vaultAccount.maturity < block.timestamp) {
            NOTIONAL.settleVaultAccount(account, vault);
        }
    }

    function _getOptimalDeleveragingParams(
        address account,
        address vault,
        int256 accruedFeeInUnderlying
    ) private view returns (uint16 currencyIndex, int256 maxUnderlying) {
        (
            /* VaultAccountHealthFactors memory h */,
            int256[3] memory maxLiquidatorDepositUnderlying,
            uint256[3] memory vaultSharesToLiquidator
        ) = NOTIONAL.getVaultAccountHealthFactors(account, vault);

        currencyIndex = vaultSharesToLiquidator[0] < vaultSharesToLiquidator[1] ? 
            (vaultSharesToLiquidator[1] < vaultSharesToLiquidator[2] ? 2 : 1) :
            (vaultSharesToLiquidator[0] < vaultSharesToLiquidator[2] ? 2 : 0); 
        maxUnderlying = maxLiquidatorDepositUnderlying[currencyIndex];

        // If there is an accrued fee, add it to the max underlying to ensure that dust
        // amounts do not cause liquidations to fail.
        if (maxUnderlying > 0) maxUnderlying = maxUnderlying + accruedFeeInUnderlying;
    }

    function _deleverageVaultAccount(
        address account,
        address vault,
        bool useVaultDeleverage,
        int256 accruedFeeInUnderlying,
        bool isETH
    ) private returns (uint256 vaultSharesFromLiquidation) {
        (uint16 currencyIndex, int256 maxUnderlying) = _getOptimalDeleveragingParams(
            account, vault, accruedFeeInUnderlying
        );
        // Short circuit accounts where no liquidation is necessary
        if (maxUnderlying == 0) return 0;

        uint256 msgValue = isETH ? uint256(maxUnderlying * 1e10) : 0;
        if (useVaultDeleverage) {
            (
                vaultSharesFromLiquidation, /* */
            ) = IStrategyVault(vault).deleverageAccount{value: msgValue}(
                account, vault, address(this), currencyIndex, maxUnderlying
            );
        } else {
            (
                vaultSharesFromLiquidation, /* */
            ) = NOTIONAL.deleverageAccount{value: msgValue}(
                account, vault, address(this), currencyIndex, maxUnderlying
            );
        }
    }

    function _liquidateCashBalance(
        VaultAccount memory vaultAccount,
        LiquidationParams memory params,
        address asset,
        bool useVaultDeleverage
    ) private {
        require(vaultAccount.maturity != Constants.PRIME_CASH_VAULT_MATURITY);

        int256 cashBalance;
        if (params.currencyIndex == 0) {
            cashBalance = vaultAccount.tempCashBalance;
        } else if (params.currencyIndex < MAX_CURRENCIES) {
            (/* */, /* */, int256[2] memory accountSecondaryCashHeld) = 
                NOTIONAL.getVaultAccountSecondaryDebt(vaultAccount.account, params.vault);
            cashBalance = accountSecondaryCashHeld[params.currencyIndex - 1];
        } else {
            revert ErrInvalidCurrencyIndex(params.currencyIndex);
        }

        (int256 fCashDeposit, /* */)  = NOTIONAL.getfCashRequiredToLiquidateCash(
            params.currencyId, vaultAccount.maturity, cashBalance
        );

        _lend(params.currencyId, vaultAccount.maturity, uint256(fCashDeposit), 0, asset);

        if (useVaultDeleverage) {
            IStrategyVault(params.vault).liquidateVaultCashBalance(
                vaultAccount.account, params.vault, address(this), params.currencyIndex, fCashDeposit
            );
        } else {
            NOTIONAL.liquidateVaultCashBalance(
                vaultAccount.account, params.vault, address(this), params.currencyIndex, fCashDeposit
            );
        }

        // Withdraw all cash held
        NOTIONAL.withdraw(params.currencyId, type(uint88).max, true);
    }

    function _lend(
        uint16 currencyId,
        uint256 maturity,
        uint256 fCashAmount,
        uint32 minLendRate,
        address asset
    ) private {
        // ETH prevents usage of BatchLend here. This also prevents batch cash liquidations
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](1);
        action[0].actionType = DepositActionType.DepositUnderlying;
        action[0].depositActionAmount = currencyId == Constants.ETH_CURRENCY_ID ? 
            address(this).balance : 
            IERC20(asset).balanceOf(address(this));
        action[0].currencyId = currencyId;
        action[0].withdrawEntireCashBalance = true;
        action[0].redeemToUnderlying = true;
        uint256 marketIndex = NOTIONAL.getMarketIndex(maturity, block.timestamp);

        action[0].trades = new bytes32[](1);
        action[0].trades[0] = bytes32(
            (uint256(uint8(TradeActionType.Lend)) << 248) |
            (uint256(marketIndex) << 240) |
            (uint256(fCashAmount) << 152) |
            (uint256(minLendRate) << 120)
        );
        
        uint256 msgValue;
        if (currencyId == Constants.ETH_CURRENCY_ID) {
            msgValue = action[0].depositActionAmount;
        }

        NOTIONAL.batchBalanceAndTradeAction{value: msgValue}(address(this), action);
    }

    function _withdrawToOwner(address token, uint256 amount) private {
        if (amount == type(uint256).max) {
            amount = IERC20(token).balanceOf(address(this));
        }
        if (amount > 0) {
            IERC20(token).checkTransfer(owner, amount);
        }
    }

    function _wrapETH() private {
        Deployments.WETH.deposit{value: address(this).balance}();
    }

    function _unwrapETH(uint256 amount) private {
        Deployments.WETH.withdraw(amount);
    }

    function withdrawToOwner(address token, uint256 amount) external onlyOwner {
        _withdrawToOwner(token, amount);
    }

    function wrapETH() external onlyOwner {
        _wrapETH();
    }

    receive() external payable {} 
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
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