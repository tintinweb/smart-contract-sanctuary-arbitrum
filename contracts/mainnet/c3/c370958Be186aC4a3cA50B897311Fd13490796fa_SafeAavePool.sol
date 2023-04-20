// SPDX-License-Identifier: UNLICENSED
//forked and minimize from https://github.com/gelatodigital/ops/blob/f6c45c81971c36e414afc31276481c47e202bdbf/contracts/integrations/OpsReady.sol
pragma solidity ^0.8.16;

import {IAaveV3Pool} from "../interfaces/IAaveV3Pool.sol";

/**
 * @dev Inherit this contract to allow your smart contract to
 * - Make synchronous fee payments.
 * - Have call restrictions for functions to be automated.
 */
library SafeAavePool {
    string constant AAVE_MISMATCH = "AAVE_MISMATCH";

    function safeSupply(
        IAaveV3Pool pool,
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        if (amount > 0) {
            pool.supply(asset, amount, onBehalfOf, referralCode);
        }
    }

    function safeWithdraw(IAaveV3Pool pool, address asset, uint256 amount, address to) external {
        if (amount > 0) {
            if (amount != pool.withdraw(asset, amount, to)) {
                revert(AAVE_MISMATCH);
            }
        }
    }

    function safeBorrow(
        IAaveV3Pool pool,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external {
        if (amount > 0) {
            pool.borrow(asset, amount, interestRateMode, referralCode, onBehalfOf);
        }
    }

    function safeRepay(
        IAaveV3Pool pool,
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external {
        if (amount > 0) {
            if (amount != pool.repay(asset, amount, interestRateMode, onBehalfOf)) {
                revert(AAVE_MISMATCH);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
// Forked and minimized from https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPool.sol
pragma solidity ^0.8.0;

import {DataTypes} from "../vendor/aave/DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IAaveV3Pool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @return The final amount repaid
     **/
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @dev Deprecated: Use the `supply` function instead
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     **/
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Forked and minimized from https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/types/DataTypes.sol
pragma solidity 0.8.16;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //aToken address
        address aTokenAddress;
        //stableDebtToken address
        address stableDebtTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
        //the outstanding unbacked aTokens minted through the bridging feature
        uint128 unbacked;
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62-63: reserved
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused

        uint256 data;
    }

    // struct UserConfigurationMap {
    //     /**
    //      * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
    //      * The first bit indicates if an asset is used as collateral by the user, the second whether an
    //      * asset is borrowed by the user.
    //      */
    //     uint256 data;
    // }

    // struct EModeCategory {
    //     // each eMode category has a custom ltv and liquidation threshold
    //     uint16 ltv;
    //     uint16 liquidationThreshold;
    //     uint16 liquidationBonus;
    //     // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    //     address priceSource;
    //     string label;
    // }

    // enum InterestRateMode {
    //     NONE,
    //     STABLE,
    //     VARIABLE
    // }

    // struct ReserveCache {
    //     uint256 currScaledVariableDebt;
    //     uint256 nextScaledVariableDebt;
    //     uint256 currPrincipalStableDebt;
    //     uint256 currAvgStableBorrowRate;
    //     uint256 currTotalStableDebt;
    //     uint256 nextAvgStableBorrowRate;
    //     uint256 nextTotalStableDebt;
    //     uint256 currLiquidityIndex;
    //     uint256 nextLiquidityIndex;
    //     uint256 currVariableBorrowIndex;
    //     uint256 nextVariableBorrowIndex;
    //     uint256 currLiquidityRate;
    //     uint256 currVariableBorrowRate;
    //     uint256 reserveFactor;
    //     ReserveConfigurationMap reserveConfiguration;
    //     address aTokenAddress;
    //     address stableDebtTokenAddress;
    //     address variableDebtTokenAddress;
    //     uint40 reserveLastUpdateTimestamp;
    //     uint40 stableDebtLastUpdateTimestamp;
    // }

    // struct ExecuteLiquidationCallParams {
    //     uint256 reservesCount;
    //     uint256 debtToCover;
    //     address collateralAsset;
    //     address debtAsset;
    //     address user;
    //     bool receiveAToken;
    //     address priceOracle;
    //     uint8 userEModeCategory;
    //     address priceOracleSentinel;
    // }

    // struct ExecuteSupplyParams {
    //     address asset;
    //     uint256 amount;
    //     address onBehalfOf;
    //     uint16 referralCode;
    // }

    // struct ExecuteBorrowParams {
    //     address asset;
    //     address user;
    //     address onBehalfOf;
    //     uint256 amount;
    //     InterestRateMode interestRateMode;
    //     uint16 referralCode;
    //     bool releaseUnderlying;
    //     uint256 maxStableRateBorrowSizePercent;
    //     uint256 reservesCount;
    //     address oracle;
    //     uint8 userEModeCategory;
    //     address priceOracleSentinel;
    // }

    // struct ExecuteRepayParams {
    //     address asset;
    //     uint256 amount;
    //     InterestRateMode interestRateMode;
    //     address onBehalfOf;
    //     bool useATokens;
    // }

    // struct ExecuteWithdrawParams {
    //     address asset;
    //     uint256 amount;
    //     address to;
    //     uint256 reservesCount;
    //     address oracle;
    //     uint8 userEModeCategory;
    // }

    // struct ExecuteSetUserEModeParams {
    //     uint256 reservesCount;
    //     address oracle;
    //     uint8 categoryId;
    // }

    // struct FinalizeTransferParams {
    //     address asset;
    //     address from;
    //     address to;
    //     uint256 amount;
    //     uint256 balanceFromBefore;
    //     uint256 balanceToBefore;
    //     uint256 reservesCount;
    //     address oracle;
    //     uint8 fromEModeCategory;
    // }

    // struct FlashloanParams {
    //     address receiverAddress;
    //     address[] assets;
    //     uint256[] amounts;
    //     uint256[] interestRateModes;
    //     address onBehalfOf;
    //     bytes params;
    //     uint16 referralCode;
    //     uint256 flashLoanPremiumToProtocol;
    //     uint256 flashLoanPremiumTotal;
    //     uint256 maxStableRateBorrowSizePercent;
    //     uint256 reservesCount;
    //     address addressesProvider;
    //     uint8 userEModeCategory;
    //     bool isAuthorizedFlashBorrower;
    // }

    // struct FlashloanSimpleParams {
    //     address receiverAddress;
    //     address asset;
    //     uint256 amount;
    //     bytes params;
    //     uint16 referralCode;
    //     uint256 flashLoanPremiumToProtocol;
    //     uint256 flashLoanPremiumTotal;
    // }

    // struct FlashLoanRepaymentParams {
    //     uint256 amount;
    //     uint256 totalPremium;
    //     uint256 flashLoanPremiumToProtocol;
    //     address asset;
    //     address receiverAddress;
    //     uint16 referralCode;
    // }

    // struct CalculateUserAccountDataParams {
    //     UserConfigurationMap userConfig;
    //     uint256 reservesCount;
    //     address user;
    //     address oracle;
    //     uint8 userEModeCategory;
    // }

    // struct ValidateBorrowParams {
    //     ReserveCache reserveCache;
    //     UserConfigurationMap userConfig;
    //     address asset;
    //     address userAddress;
    //     uint256 amount;
    //     InterestRateMode interestRateMode;
    //     uint256 maxStableLoanPercent;
    //     uint256 reservesCount;
    //     address oracle;
    //     uint8 userEModeCategory;
    //     address priceOracleSentinel;
    //     bool isolationModeActive;
    //     address isolationModeCollateralAddress;
    //     uint256 isolationModeDebtCeiling;
    // }

    // struct ValidateLiquidationCallParams {
    //     ReserveCache debtReserveCache;
    //     uint256 totalDebt;
    //     uint256 healthFactor;
    //     address priceOracleSentinel;
    // }

    // struct CalculateInterestRatesParams {
    //     uint256 unbacked;
    //     uint256 liquidityAdded;
    //     uint256 liquidityTaken;
    //     uint256 totalStableDebt;
    //     uint256 totalVariableDebt;
    //     uint256 averageStableBorrowRate;
    //     uint256 reserveFactor;
    //     address reserve;
    //     address aToken;
    // }

    // struct InitReserveParams {
    //     address asset;
    //     address aTokenAddress;
    //     address stableDebtAddress;
    //     address variableDebtAddress;
    //     address interestRateStrategyAddress;
    //     uint16 reservesCount;
    //     uint16 maxNumberReserves;
    // }
}