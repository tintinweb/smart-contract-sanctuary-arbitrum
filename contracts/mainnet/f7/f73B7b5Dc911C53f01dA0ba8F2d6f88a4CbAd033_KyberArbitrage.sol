// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./IAsset.sol";

// https://docs.balancer.fi/reference/swaps/single-swap.html#swap-function

interface IBalancerVault {
    // function WETH() external view returns (address);

    //BALANCER STRUCT
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    //BALANCER ENUM
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    //BALANCER STRUCT
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    // function batchSwap(
    //     uint8 kind,
    //     SingleSwap[] swaps,
    //     address[] assets,
    //     FundManagement funds,
    //     int256[] limits,
    //     uint256 deadline
    // ) external returns (int256[] assetDeltas);

    // function deregisterTokens(bytes32 poolId, address[] tokens) external;

    // // function exitPool(
    // //     bytes32 poolId,
    // //     address sender,
    // //     address recipient,
    // //     tuple request
    // // ) external;

    // function flashLoan(
    //     address recipient,
    //     address[] tokens,
    //     uint256[] amounts,
    //     bytes userData
    // ) external;

    // function getActionId(bytes4 selector) external view returns (bytes32);

    // function getAuthorizer() external view returns (address);

    // function getDomainSeparator() external view returns (bytes32);

    // function getInternalBalance(
    //     address user,
    //     address[] tokens
    // ) external view returns (uint256[] balances);

    // function getNextNonce(address user) external view returns (uint256);

    // function getPausedState()
    //     external
    //     view
    //     returns (
    //         bool paused,
    //         uint256 pauseWindowEndTime,
    //         uint256 bufferPeriodEndTime
    //     );

    function getPool(bytes32 poolId) external view returns (address, uint8);

    function getPoolTokenInfo(
        bytes32 poolId,
        address token
    )
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    function getPoolTokens(
        bytes32 poolId
    )
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    // function getProtocolFeesCollector() external view returns (address);

    // function hasApprovedRelayer(
    //     address user,
    //     address relayer
    // ) external view returns (bool);

    // function joinPool(
    //     bytes32 poolId,
    //     address sender,
    //     address recipient,
    //     tuple request
    // ) external;

    // function managePoolBalance(tuple[] ops) external;

    // function manageUserBalance(tuple[] ops) external;

    // function queryBatchSwap(
    //     uint8 kind,
    //     SingleSwap[] swaps,
    //     address[] assets,
    //     FundManagement funds
    // ) external returns (int256[]);

    // function registerPool(uint8 specialization) external returns (bytes32);

    // function registerTokens(
    //     bytes32 poolId,
    //     address[] tokens,
    //     address[] assetManagers
    // ) external;

    // function setAuthorizer(address newAuthorizer) external;

    // function setPaused(bool paused) external;

    // function setRelayerApproval(
    //     address sender,
    //     address relayer,
    //     bool approved
    // ) external;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);
}

//  {
//         pool: "0x4e7f40cd37cee710f5e87ad72959d30ef8a01a5d00010000000000000000000b",
//         tokenIn: "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
//         tokenOut: "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619",
//         limitReturnAmount: "0",
//         swapAmount: "12154711",
//         amountOut: "7396822524192005",
//         exchange: "balancer",
//         poolLength: 4,
//         poolType: "balancer-weighted",
//         vault: "0xba12222222228d8ba445958a75a0704d566bf2c8",
//       },

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC20 {
    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
    // event Transfer(address indexed from, address indexed to, uint256 value);

    // function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IPoolAddressesProvider.sol";
import "./IPool.sol";

// import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
// import {IPool} from "../../interfaces/IPool.sol";

/**
 * @title IFlashLoanSimpleReceiver
 * @author Aave
 * @notice Defines the basic interface of a flashloan-receiver contract.
 * @dev Implement this interface to develop a flashloan-compatible flashLoanReceiver contract
 */
interface IFlashLoanSimpleReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param premium The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);

    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    function POOL() external view returns (IPool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;
import "./IPoolAddressesProvider.sol";
import "../libraries/DataTypes.sol";

// import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
// import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 */
interface IPool {
    /**
     * @dev Emitted on mintUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
     * @param amount The amount of supplied assets
     * @param referralCode The referral code used
     */
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on backUnbacked()
     * @param reserve The address of the underlying asset of the reserve
     * @param backer The address paying for the backing
     * @param amount The amount added as backing
     * @param fee The amount paid in fees
     */
    event BackUnbacked(
        address indexed reserve,
        address indexed backer,
        uint256 amount,
        uint256 fee
    );

    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        DataTypes.InterestRateMode interestRateMode
    );

    /**
     * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
     * @param asset The address of the underlying asset of the reserve
     * @param totalDebt The total isolation mode debt for the reserve
     */
    event IsolationModeTotalDebtUpdated(
        address indexed asset,
        uint256 totalDebt
    );

    /**
     * @dev Emitted when the user selects a certain asset category for eMode
     * @param user The address of the user
     * @param categoryId The category id
     */
    event UserEModeSet(address indexed user, uint8 categoryId);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     */
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        DataTypes.InterestRateMode interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param stableBorrowRate The next stable borrow rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Mints an `amount` of aTokens to the `onBehalfOf`
     * @param asset The address of the underlying asset to mint
     * @param amount The amount to mint
     * @param onBehalfOf The address that will receive the aTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Back the current unbacked underlying with `amount` and pay `fee`.
     * @param asset The address of the underlying asset to back
     * @param amount The amount to back
     * @param fee The amount paid in fees
     * @return The backed amount
     */
    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external returns (uint256);

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
     */
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

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
     */
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

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
     */
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
     */
    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
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
     */
    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    /**
     * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
     * @param asset The address of the underlying asset borrowed
     * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
     */
    function swapBorrowRateMode(
        address asset,
        uint256 interestRateMode
    ) external;

    /**
     * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
     *        much has been borrowed at a stable rate and suppliers are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     */
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(
        address asset,
        bool useAsCollateral
    ) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param interestRateModes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata interestRateModes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration. For further details please visit https://docs.aave.com/developers/
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
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
     * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param aTokenAddress The address of the aToken that will be assigned to the reserve
     * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     */
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap calldata configuration
    ) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(
        address asset
    ) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(
        address user
    ) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(
        address asset
    ) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
     * "dynamic" variable index based on time, current stored index and virtual rate at the current
     * moment (approx. a borrower would get if opening a position). This means that is always used in
     * combination with variable debt supply/balances.
     * If using this function externally, consider that is possible to have an increasing normalized
     * variable debt that is not equivalent to how the variable debt index would be updated in storage
     * (e.g. only updates with non-zero variable debt supply)
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(
        address asset
    ) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(
        address asset
    ) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Validates and finalizes an aToken transfer
     * @dev Only callable by the overlying aToken of the `asset`
     * @param asset The address of the underlying asset of the aToken
     * @param from The user from which the aTokens are transferred
     * @param to The user receiving the aTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The aToken balance of the `from` user before the transfer
     * @param balanceToBefore The aToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Updates the protocol fee on the bridging
     * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
     */
    function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to aToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    ) external;

    /**
     * @notice Configures a new category for the eMode.
     * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
     * The category 0 is reserved as it's the default for volatile assets
     * @param id The id of the category
     * @param config The configuration of the category
     */
    function configureEModeCategory(
        uint8 id,
        DataTypes.EModeCategory memory config
    ) external;

    /**
     * @notice Returns the data of an eMode category
     * @param id The id of the category
     * @return The configuration data of the category
     */
    function getEModeCategoryData(
        uint8 id
    ) external view returns (DataTypes.EModeCategory memory);

    /**
     * @notice Allows a user to use the protocol in eMode
     * @param categoryId The id of the category
     */
    function setUserEMode(uint8 categoryId) external;

    /**
     * @notice Returns the eMode the user is using
     * @param user The address of the user
     * @return The eMode id
     */
    function getUserEMode(address user) external view returns (uint256);

    /**
     * @notice Resets the isolation mode total debt of the given asset to zero
     * @dev It requires the given asset has zero debt ceiling
     * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
     */
    function resetIsolationModeTotalDebt(address asset) external;

    /**
     * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
     * @return The percentage of available liquidity to borrow, expressed in bps
     */
    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the bridge fees sent to protocol
     * @return The bridge fee sent to the protocol treasury
     */
    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;

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
     */
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
    // /**
    //  * @dev Emitted when the market identifier is updated.
    //  * @param oldMarketId The old id of the market
    //  * @param newMarketId The new id of the market
    //  */
    // event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);
    // /**
    //  * @dev Emitted when the pool is updated.
    //  * @param oldAddress The old address of the Pool
    //  * @param newAddress The new address of the Pool
    //  */
    // event PoolUpdated(address indexed oldAddress, address indexed newAddress);
    // /**
    //  * @dev Emitted when the pool configurator is updated.
    //  * @param oldAddress The old address of the PoolConfigurator
    //  * @param newAddress The new address of the PoolConfigurator
    //  */
    // event PoolConfiguratorUpdated(
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when the price oracle is updated.
    //  * @param oldAddress The old address of the PriceOracle
    //  * @param newAddress The new address of the PriceOracle
    //  */
    // event PriceOracleUpdated(
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when the ACL manager is updated.
    //  * @param oldAddress The old address of the ACLManager
    //  * @param newAddress The new address of the ACLManager
    //  */
    // event ACLManagerUpdated(
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when the ACL admin is updated.
    //  * @param oldAddress The old address of the ACLAdmin
    //  * @param newAddress The new address of the ACLAdmin
    //  */
    // event ACLAdminUpdated(
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when the price oracle sentinel is updated.
    //  * @param oldAddress The old address of the PriceOracleSentinel
    //  * @param newAddress The new address of the PriceOracleSentinel
    //  */
    // event PriceOracleSentinelUpdated(
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when the pool data provider is updated.
    //  * @param oldAddress The old address of the PoolDataProvider
    //  * @param newAddress The new address of the PoolDataProvider
    //  */
    // event PoolDataProviderUpdated(
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when a new proxy is created.
    //  * @param id The identifier of the proxy
    //  * @param proxyAddress The address of the created proxy contract
    //  * @param implementationAddress The address of the implementation contract
    //  */
    // event ProxyCreated(
    //     bytes32 indexed id,
    //     address indexed proxyAddress,
    //     address indexed implementationAddress
    // );
    // /**
    //  * @dev Emitted when a new non-proxied contract address is registered.
    //  * @param id The identifier of the contract
    //  * @param oldAddress The address of the old contract
    //  * @param newAddress The address of the new contract
    //  */
    // event AddressSet(
    //     bytes32 indexed id,
    //     address indexed oldAddress,
    //     address indexed newAddress
    // );
    // /**
    //  * @dev Emitted when the implementation of the proxy registered with id is updated
    //  * @param id The identifier of the contract
    //  * @param proxyAddress The address of the proxy contract
    //  * @param oldImplementationAddress The address of the old implementation contract
    //  * @param newImplementationAddress The address of the new implementation contract
    //  */
    // event AddressSetAsProxy(
    //     bytes32 indexed id,
    //     address indexed proxyAddress,
    //     address oldImplementationAddress,
    //     address indexed newImplementationAddress
    // );
    // /**
    //  * @notice Returns the id of the Aave market to which this contract points to.
    //  * @return The market id
    //  */
    // function getMarketId() external view returns (string memory);
    // /**
    //  * @notice Associates an id with a specific PoolAddressesProvider.
    //  * @dev This can be used to create an onchain registry of PoolAddressesProviders to
    //  * identify and validate multiple Aave markets.
    //  * @param newMarketId The market id
    //  */
    // function setMarketId(string calldata newMarketId) external;
    // /**
    //  * @notice Returns an address by its identifier.
    //  * @dev The returned address might be an EOA or a contract, potentially proxied
    //  * @dev It returns ZERO if there is no registered address with the given id
    //  * @param id The id
    //  * @return The address of the registered for the specified id
    //  */
    // function getAddress(bytes32 id) external view returns (address);
    // /**
    //  * @notice General function to update the implementation of a proxy registered with
    //  * certain `id`. If there is no proxy registered, it will instantiate one and
    //  * set as implementation the `newImplementationAddress`.
    //  * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
    //  * setter function, in order to avoid unexpected consequences
    //  * @param id The id
    //  * @param newImplementationAddress The address of the new implementation
    //  */
    // function setAddressAsProxy(
    //     bytes32 id,
    //     address newImplementationAddress
    // ) external;
    // /**
    //  * @notice Sets an address for an id replacing the address saved in the addresses map.
    //  * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
    //  * @param id The id
    //  * @param newAddress The address to set
    //  */
    // function setAddress(bytes32 id, address newAddress) external;
    // /**
    //  * @notice Returns the address of the Pool proxy.
    //  * @return The Pool proxy address
    //  */
    function getPool() external view returns (address);

    // /**
    //  * @notice Updates the implementation of the Pool, or creates a proxy
    //  * setting the new `pool` implementation when the function is called for the first time.
    //  * @param newPoolImpl The new Pool implementation
    //  */
    // function setPoolImpl(address newPoolImpl) external;
    // /**
    //  * @notice Returns the address of the PoolConfigurator proxy.
    //  * @return The PoolConfigurator proxy address
    //  */
    // function getPoolConfigurator() external view returns (address);
    // /**
    //  * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
    //  * setting the new `PoolConfigurator` implementation when the function is called for the first time.
    //  * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
    //  */
    // function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;
    // /**
    //  * @notice Returns the address of the price oracle.
    //  * @return The address of the PriceOracle
    //  */
    // function getPriceOracle() external view returns (address);
    // /**
    //  * @notice Updates the address of the price oracle.
    //  * @param newPriceOracle The address of the new PriceOracle
    //  */
    // function setPriceOracle(address newPriceOracle) external;
    // /**
    //  * @notice Returns the address of the ACL manager.
    //  * @return The address of the ACLManager
    //  */
    // function getACLManager() external view returns (address);
    // /**
    //  * @notice Updates the address of the ACL manager.
    //  * @param newAclManager The address of the new ACLManager
    //  */
    // function setACLManager(address newAclManager) external;
    // /**
    //  * @notice Returns the address of the ACL admin.
    //  * @return The address of the ACL admin
    //  */
    // function getACLAdmin() external view returns (address);
    // /**
    //  * @notice Updates the address of the ACL admin.
    //  * @param newAclAdmin The address of the new ACL admin
    //  */
    // function setACLAdmin(address newAclAdmin) external;
    // /**
    //  * @notice Returns the address of the price oracle sentinel.
    //  * @return The address of the PriceOracleSentinel
    //  */
    // function getPriceOracleSentinel() external view returns (address);
    // /**
    //  * @notice Updates the address of the price oracle sentinel.
    //  * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
    //  */
    // function setPriceOracleSentinel(address newPriceOracleSentinel) external;
    // /**
    //  * @notice Returns the address of the data provider.
    //  * @return The address of the DataProvider
    //  */
    function getPoolDataProvider() external view returns (address);

    struct tokensAAVE {
        string symbol;
        address token;
    }

    function getAllReservesTokens() external view returns (tokensAAVE[] memory);
    // /**
    //  * @notice Updates the address of the data provider.
    //  * @param newDataProvider The address of the new DataProvider
    //  */
    // function setPoolDataProvider(address newDataProvider) external;
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPoolCamelot {
    // function DOMAIN_SEPARATOR() external view returns (bytes32);

    // function FEE_DENOMINATOR() external view returns (uint256);

    // function MAX_FEE_PERCENT() external view returns (uint256);

    // function MINIMUM_LIQUIDITY() external view returns (uint256);

    // function PERMIT_TYPEHASH() external view returns (bytes32);

    // function allowance(address, address) external view returns (uint256);

    // function approve(address spender, uint256 value) external returns (bool);

    // function balanceOf(address) external view returns (uint256);

    // function burn(
    //     address to
    // ) external returns (uint256 amount0, uint256 amount1);

    // function decimals() external view returns (uint8);

    // function drainWrongToken(address token, address to) external;

    // function factory() external view returns (address);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256);

    // function getReserves()
    //     external
    //     view
    //     returns (
    //         uint112 _reserve0,
    //         uint112 _reserve1,
    //         uint16 _token0FeePercent,
    //         uint16 _token1FeePercent
    //     );

    // function initialize(address _token0, address _token1) external;

    // function initialized() external view returns (bool);

    // function kLast() external view returns (uint256);

    // function mint(address to) external returns (uint256 liquidity);

    // function name() external view returns (string);

    // function nonces(address) external view returns (uint256);

    // function pairTypeImmutable() external view returns (bool);

    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // function precisionMultiplier0() external view returns (uint256);

    // function precisionMultiplier1() external view returns (uint256);

    // function setFeePercent(
    //     uint16 newToken0FeePercent,
    //     uint16 newToken1FeePercent
    // ) external;

    // function setPairTypeImmutable() external;

    // function setStableSwap(
    //     bool stable,
    //     uint112 expectedReserve0,
    //     uint112 expectedReserve1
    // ) external;

    // function skim(address to) external;

    // function stableSwap() external view returns (bool);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) external;

    // function swap(
    //     uint256 amount0Out,
    //     uint256 amount1Out,
    //     address to,
    //     bytes memory data,
    //     address referrer
    // ) external;

    // function symbol() external view returns (string);

    // function sync() external;

    function token0() external view returns (address);

    // function token0FeePercent() external view returns (uint16);

    function token1() external view returns (address);

    // function token1FeePercent() external view returns (uint16);

    // function totalSupply() external view returns (uint256);

    // function transfer(address to, uint256 value) external returns (bool);

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 value
    // ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// https://bia.is/tools/abi2solidity/

// https://curve.readthedocs.io/ref-addresses.html
interface IPoolCurve {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function fee() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    // @view
    // @external
    // def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    //     """
    //     @notice Calculate the current output dy given input dx
    //     @dev Index values can be found via the `coins` public getter method
    //     @param i Index value for the coin to send
    //     @param j Index valie of the coin to recieve
    //     @param dx Amount of `i` being exchanged
    //     @return Amount of `j` predicted
    //     """","name":"coins","inputs":[{"name":"arg0","type":"uint256"}],"outputs":[{"name":"","type":"address"}]

    // function exchange(
    //     int128 i,
    //     int128 j,
    //     uint256 _dx,
    //     uint256 _min_dy
    // ) external returns (uint256);

    // function exchange(
    //     int128 i,
    //     int128 j,
    //     uint256 _dx,
    //     uint256 _min_dy,
    //     address _receiver
    // ) external returns (uint256);

    function coins(uint256 arg0) external view returns (address);

    //stateMutability":"view","type":"function","name":"balances","inputs":[{"name":"arg0","type":"uint256"}],"outputs":[{"name":"","type":"uint256"}],"

    //     @external
    // @nonreentrant('lock')
    // def exchange(
    //     i: int128,
    //     j: int128,
    //     _dx: uint256,
    //     _min_dy: uint256,
    //     _receiver: address = msg.sender,
    // ) -> uint256:
    // nonpayable function exchange inputs [i int128,j int128, _dx uint256, _min_dy uint256,_receiver address],outputs type":"uint256"}]},
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPoolDODO {
    // function _QUOTE_TOKEN_() external view returns (address);

    // function _BASE_TOKEN_() external view returns (address);

    function _BASE_PRICE_CUMULATIVE_LAST_() external view returns (uint256);

    function _BASE_RESERVE_() external view returns (uint112);

    function _BASE_TARGET_() external view returns (uint112);

    // function _BASE_TOKEN_() external view returns (address);

    function _BLOCK_TIMESTAMP_LAST_() external view returns (uint32);

    function _IS_OPEN_TWAP_() external view returns (bool);

    function _I_() external view returns (uint128);

    // function _K_() external view returns (uint64);

    // function _LP_FEE_RATE_() external view returns (uint64);

    // function _MAINTAINER_() external view returns (address);

    function _MT_FEE_RATE_MODEL_() external view returns (address);

    // function _NEW_OWNER_() external view returns (address);
    //
    // function _OWNER_() external view returns (address);

    function _QUOTE_RESERVE_() external view returns (uint112);

    function _QUOTE_TARGET_() external view returns (uint112);

    // function _QUOTE_TOKEN_() external view returns (address);

    function _RState_() external view returns (uint32);

    // function claimOwnership() external;

    //   function flashLoan ( uint256 baseAmount, uint256 quoteAmount, address assetTo, bytes data ) external;
    function getBaseInput() external view returns (uint256 input);

    function getMidPrice() external view returns (uint256 midPrice);

    //   function getPMMState (  ) external view returns ( tuple state );
    function getPMMStateForCall()
        external
        view
        returns (
            uint256 i,
            uint256 K,
            uint256 B,
            uint256 Q,
            uint256 B0,
            uint256 Q0,
            uint256 R
        );

    function getQuoteInput() external view returns (uint256 input);

    function getUserFeeRate(
        address user
    ) external view returns (uint256 lpFeeRate, uint256 mtFeeRate);

    function getVaultReserve()
        external
        view
        returns (uint256 baseReserve, uint256 quoteReserve);

    function init(
        address owner,
        address maintainer,
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 k,
        uint256 i,
        bool isOpenTWAP
    ) external;

    function initOwner(address newOwner) external;

    function querySellBase(
        address trader,
        uint256 payBaseAmount
    )
        external
        view
        returns (
            uint256 receiveQuoteAmount,
            uint256 mtFee,
            uint8 newRState,
            uint256 newBaseTarget
        );

    function querySellQuote(
        address trader,
        uint256 payQuoteAmount
    )
        external
        view
        returns (
            uint256 receiveBaseAmount,
            uint256 mtFee,
            uint8 newRState,
            uint256 newQuoteTarget
        );

    function ratioSync() external;

    function reset(
        address assetTo,
        uint256 newLpFeeRate,
        uint256 newI,
        uint256 newK,
        uint256 baseOutAmount,
        uint256 quoteOutAmount,
        uint256 minBaseReserve,
        uint256 minQuoteReserve
    ) external returns (bool);

    function retrieve(address to, address token, uint256 amount) external;

    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function _BASE_BALANCE_() external view returns (uint256);

    function _BASE_BALANCE_LIMIT_() external view returns (uint256);

    function _BASE_CAPITAL_RECEIVE_QUOTE_() external view returns (uint256);

    function _BASE_CAPITAL_TOKEN_() external view returns (address);

    function _BASE_TOKEN_() external view returns (address);

    function _BUYING_ALLOWED_() external view returns (bool);

    function _CLAIMED_(address) external view returns (bool);

    function _CLOSED_() external view returns (bool);

    function _DEPOSIT_BASE_ALLOWED_() external view returns (bool);

    function _DEPOSIT_QUOTE_ALLOWED_() external view returns (bool);

    function _GAS_PRICE_LIMIT_() external view returns (uint256);

    function _K_() external view returns (uint256);

    function _LP_FEE_RATE_() external view returns (uint256);

    function _MAINTAINER_() external view returns (address);

    function _MT_FEE_RATE_() external view returns (uint256);

    function _NEW_OWNER_() external view returns (address);

    function _ORACLE_() external view returns (address);

    function _OWNER_() external view returns (address);

    function _QUOTE_BALANCE_() external view returns (uint256);

    function _QUOTE_BALANCE_LIMIT_() external view returns (uint256);

    function _QUOTE_CAPITAL_RECEIVE_BASE_() external view returns (uint256);

    function _QUOTE_CAPITAL_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _R_STATUS_() external view returns (uint8);

    function _SELLING_ALLOWED_() external view returns (bool);

    function _SUPERVISOR_() external view returns (address);

    function _TARGET_BASE_TOKEN_AMOUNT_() external view returns (uint256);

    function _TARGET_QUOTE_TOKEN_AMOUNT_() external view returns (uint256);

    function _TRADE_ALLOWED_() external view returns (bool);

    function buyBaseToken(
        uint256 amount,
        uint256 maxPayQuote,
        bytes memory data
    ) external returns (uint256);

    function claimAssets() external;

    function claimOwnership() external;

    function depositBase(uint256 amount) external returns (uint256);

    function depositBaseTo(
        address to,
        uint256 amount
    ) external returns (uint256);

    function depositQuote(uint256 amount) external returns (uint256);

    function depositQuoteTo(
        address to,
        uint256 amount
    ) external returns (uint256);

    function disableBaseDeposit() external;

    function disableBuying() external;

    function disableQuoteDeposit() external;

    function disableSelling() external;

    function disableTrading() external;

    function donateBaseToken(uint256 amount) external;

    function donateQuoteToken(uint256 amount) external;

    function enableBaseDeposit() external;

    function enableBuying() external;

    function enableQuoteDeposit() external;

    function enableSelling() external;

    function enableTrading() external;

    function finalSettlement() external;

    function getBaseCapitalBalanceOf(
        address lp
    ) external view returns (uint256);

    function getExpectedTarget()
        external
        view
        returns (uint256 baseTarget, uint256 quoteTarget);

    function getLpBaseBalance(
        address lp
    ) external view returns (uint256 lpBalance);

    function getLpQuoteBalance(
        address lp
    ) external view returns (uint256 lpBalance);

    // function getMidPrice() external view returns (uint256 midPrice);

    function getOraclePrice() external view returns (uint256);

    function getQuoteCapitalBalanceOf(
        address lp
    ) external view returns (uint256);

    function getTotalBaseCapital() external view returns (uint256);

    function getTotalQuoteCapital() external view returns (uint256);

    function getWithdrawBasePenalty(
        uint256 amount
    ) external view returns (uint256 penalty);

    function getWithdrawQuotePenalty(
        uint256 amount
    ) external view returns (uint256 penalty);

    function init(
        address owner,
        address supervisor,
        address maintainer,
        address baseToken,
        address quoteToken,
        address oracle,
        uint256 lpFeeRate,
        uint256 mtFeeRate,
        uint256 k,
        uint256 gasPriceLimit
    ) external;

    function queryBuyBaseToken(
        uint256 amount
    ) external view returns (uint256 payQuote);

    function querySellBaseToken(
        uint256 amount
    ) external view returns (uint256 receiveQuote);

    function retrieve(address token, uint256 amount) external;

    function sellBaseToken(
        uint256 amount,
        uint256 minReceiveQuote,
        bytes memory data
    ) external returns (uint256);

    function setBaseBalanceLimit(uint256 newBaseBalanceLimit) external;

    function setGasPriceLimit(uint256 newGasPriceLimit) external;

    function setK(uint256 newK) external;

    function setLiquidityProviderFeeRate(
        uint256 newLiquidityPorviderFeeRate
    ) external;

    function setMaintainer(address newMaintainer) external;

    function setMaintainerFeeRate(uint256 newMaintainerFeeRate) external;

    function setOracle(address newOracle) external;

    function setQuoteBalanceLimit(uint256 newQuoteBalanceLimit) external;

    function setSupervisor(address newSupervisor) external;

    function transferOwnership(address newOwner) external;

    // function version() external pure returns (uint256);

    function version() external pure returns (string memory);

    function withdrawAllBase() external returns (uint256);

    function withdrawAllBaseTo(address to) external returns (uint256);

    function withdrawAllQuote() external returns (uint256);

    function withdrawAllQuoteTo(address to) external returns (uint256);

    function withdrawBase(uint256 amount) external returns (uint256);

    function withdrawBaseTo(
        address to,
        uint256 amount
    ) external returns (uint256);

    function withdrawQuote(uint256 amount) external returns (uint256);

    function withdrawQuoteTo(
        address to,
        uint256 amount
    ) external returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// https://bia.is/tools/abi2solidity/

// https://curve.readthedocs.io/ref-addresses.html
interface IPoolGmx {
    // function BASIS_POINTS_DIVISOR() external view returns (uint256);

    // function FUNDING_RATE_PRECISION() external view returns (uint256);

    // function MAX_FEE_BASIS_POINTS() external view returns (uint256);

    // function MAX_FUNDING_RATE_FACTOR() external view returns (uint256);

    // function MAX_LIQUIDATION_FEE_USD() external view returns (uint256);

    // function MIN_FUNDING_RATE_INTERVAL() external view returns (uint256);

    // function MIN_LEVERAGE() external view returns (uint256);

    // function PRICE_PRECISION() external view returns (uint256);

    // function USDG_DECIMALS() external view returns (uint256);

    // function addRouter(address _router) external;

    // function adjustForDecimals(
    //     uint256 _amount,
    //     address _tokenDiv,
    //     address _tokenMul
    // ) external view returns (uint256);

    // function allWhitelistedTokens(uint256) external view returns (address);

    // function allWhitelistedTokensLength() external view returns (uint256);

    // function approvedRouters(address, address) external view returns (bool);

    // function bufferAmounts(address) external view returns (uint256);

    // function buyUSDG(
    //     address _token,
    //     address _receiver
    // ) external returns (uint256);

    // function clearTokenConfig(address _token) external;

    // function cumulativeFundingRates(address) external view returns (uint256);

    // function decreasePosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     uint256 _collateralDelta,
    //     uint256 _sizeDelta,
    //     bool _isLong,
    //     address _receiver
    // ) external returns (uint256);

    // function directPoolDeposit(address _token) external;

    // function errorController() external view returns (address);

    // function errors(uint256) external view returns (string);

    // function feeReserves(address) external view returns (uint256);

    // function fundingInterval() external view returns (uint256);

    // function fundingRateFactor() external view returns (uint256);

    // function getDelta(
    //     address _indexToken,
    //     uint256 _size,
    //     uint256 _averagePrice,
    //     bool _isLong,
    //     uint256 _lastIncreasedTime
    // ) external view returns (bool, uint256);

    // function getFeeBasisPoints(
    //     address _token,
    //     uint256 _usdgDelta,
    //     uint256 _feeBasisPoints,
    //     uint256 _taxBasisPoints,
    //     bool _increment
    // ) external view returns (uint256);

    // function getFundingFee(
    //     address _token,
    //     uint256 _size,
    //     uint256 _entryFundingRate
    // ) external view returns (uint256);

    // function getGlobalShortDelta(
    //     address _token
    // ) external view returns (bool, uint256);

    // function getMaxPrice(address _token) external view returns (uint256);

    // function getMinPrice(address _token) external view returns (uint256);

    // function getNextAveragePrice(
    //     address _indexToken,
    //     uint256 _size,
    //     uint256 _averagePrice,
    //     bool _isLong,
    //     uint256 _nextPrice,
    //     uint256 _sizeDelta,
    //     uint256 _lastIncreasedTime
    // ) external view returns (uint256);

    // function getNextFundingRate(address _token) external view returns (uint256);

    // function getNextGlobalShortAveragePrice(
    //     address _indexToken,
    //     uint256 _nextPrice,
    //     uint256 _sizeDelta
    // ) external view returns (uint256);

    // function getPosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // )
    //     external
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         bool,
    //         uint256
    //     );

    // function getPositionDelta(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external view returns (bool, uint256);

    // function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    // function getPositionKey(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external pure returns (bytes32);

    // function getPositionLeverage(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external view returns (uint256);

    // function getRedemptionAmount(
    //     address _token,
    //     uint256 _usdgAmount
    // ) external view returns (uint256);

    // function getRedemptionCollateral(
    //     address _token
    // ) external view returns (uint256);

    // function getRedemptionCollateralUsd(
    //     address _token
    // ) external view returns (uint256);

    // function getTargetUsdgAmount(
    //     address _token
    // ) external view returns (uint256);

    // function getUtilisation(address _token) external view returns (uint256);

    // function globalShortAveragePrices(address) external view returns (uint256);

    // function globalShortSizes(address) external view returns (uint256);

    // function gov() external view returns (address);

    // function guaranteedUsd(address) external view returns (uint256);

    // function hasDynamicFees() external view returns (bool);

    // function inManagerMode() external view returns (bool);

    // function inPrivateLiquidationMode() external view returns (bool);

    // function includeAmmPrice() external view returns (bool);

    // function increasePosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     uint256 _sizeDelta,
    //     bool _isLong
    // ) external;

    // function initialize(
    //     address _router,
    //     address _usdg,
    //     address _priceFeed,
    //     uint256 _liquidationFeeUsd,
    //     uint256 _fundingRateFactor,
    //     uint256 _stableFundingRateFactor
    // ) external;

    // function isInitialized() external view returns (bool);

    // function isLeverageEnabled() external view returns (bool);

    // function isLiquidator(address) external view returns (bool);

    // function isManager(address) external view returns (bool);

    // function isSwapEnabled() external view returns (bool);

    // function lastFundingTimes(address) external view returns (uint256);

    // function liquidatePosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong,
    //     address _feeReceiver
    // ) external;

    // function liquidationFeeUsd() external view returns (uint256);

    // function marginFeeBasisPoints() external view returns (uint256);

    // function maxGasPrice() external view returns (uint256);

    // function maxLeverage() external view returns (uint256);

    // function maxUsdgAmounts(address) external view returns (uint256);

    // function minProfitBasisPoints(address) external view returns (uint256);

    // function minProfitTime() external view returns (uint256);

    // function mintBurnFeeBasisPoints() external view returns (uint256);

    // function poolAmounts(address) external view returns (uint256);

    // function positions(
    //     bytes32
    // )
    //     external
    //     view
    //     returns (
    //         uint256 size,
    //         uint256 collateral,
    //         uint256 averagePrice,
    //         uint256 entryFundingRate,
    //         uint256 reserveAmount,
    //         int256 realisedPnl,
    //         uint256 lastIncreasedTime
    //     );

    // function priceFeed() external view returns (address);

    // function removeRouter(address _router) external;

    // function reservedAmounts(address) external view returns (uint256);

    // function router() external view returns (address);

    // function sellUSDG(
    //     address _token,
    //     address _receiver
    // ) external returns (uint256);

    // function setBufferAmount(address _token, uint256 _amount) external;

    // function setError(uint256 _errorCode, string _error) external;

    // function setErrorController(address _errorController) external;

    // function setFees(
    //     uint256 _taxBasisPoints,
    //     uint256 _stableTaxBasisPoints,
    //     uint256 _mintBurnFeeBasisPoints,
    //     uint256 _swapFeeBasisPoints,
    //     uint256 _stableSwapFeeBasisPoints,
    //     uint256 _marginFeeBasisPoints,
    //     uint256 _liquidationFeeUsd,
    //     uint256 _minProfitTime,
    //     bool _hasDynamicFees
    // ) external;

    // function setFundingRate(
    //     uint256 _fundingInterval,
    //     uint256 _fundingRateFactor,
    //     uint256 _stableFundingRateFactor
    // ) external;

    // function setGov(address _gov) external;

    // function setInManagerMode(bool _inManagerMode) external;

    // function setInPrivateLiquidationMode(
    //     bool _inPrivateLiquidationMode
    // ) external;

    // function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    // function setIsSwapEnabled(bool _isSwapEnabled) external;

    // function setLiquidator(address _liquidator, bool _isActive) external;

    // function setManager(address _manager, bool _isManager) external;

    // function setMaxGasPrice(uint256 _maxGasPrice) external;

    // function setMaxLeverage(uint256 _maxLeverage) external;

    // function setPriceFeed(address _priceFeed) external;

    // function setTokenConfig(
    //     address _token,
    //     uint256 _tokenDecimals,
    //     uint256 _tokenWeight,
    //     uint256 _minProfitBps,
    //     uint256 _maxUsdgAmount,
    //     bool _isStable,
    //     bool _isShortable
    // ) external;

    // function setUsdgAmount(address _token, uint256 _amount) external;

    // function shortableTokens(address) external view returns (bool);

    // function stableFundingRateFactor() external view returns (uint256);

    // function stableSwapFeeBasisPoints() external view returns (uint256);

    // function stableTaxBasisPoints() external view returns (uint256);

    // function stableTokens(address) external view returns (bool);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    // function swapFeeBasisPoints() external view returns (uint256);

    // function taxBasisPoints() external view returns (uint256);

    // function tokenBalances(address) external view returns (uint256);

    // function tokenDecimals(address) external view returns (uint256);

    // function tokenToUsdMin(
    //     address _token,
    //     uint256 _tokenAmount
    // ) external view returns (uint256);

    // function tokenWeights(address) external view returns (uint256);

    // function totalTokenWeights() external view returns (uint256);

    // function updateCumulativeFundingRate(address _token) external;

    // function upgradeVault(
    //     address _newVault,
    //     address _token,
    //     uint256 _amount
    // ) external;

    // function usdToToken(
    //     address _token,
    //     uint256 _usdAmount,
    //     uint256 _price
    // ) external view returns (uint256);

    // function usdToTokenMax(
    //     address _token,
    //     uint256 _usdAmount
    // ) external view returns (uint256);

    // function usdToTokenMin(
    //     address _token,
    //     uint256 _usdAmount
    // ) external view returns (uint256);

    // function usdg() external view returns (address);

    // function usdgAmounts(address) external view returns (uint256);

    // function useSwapPricing() external view returns (bool);

    // function validateLiquidation(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong,
    //     bool _raise
    // ) external view returns (uint256, uint256);

    // function whitelistedTokenCount() external view returns (uint256);

    // function whitelistedTokens(address) external view returns (bool);

    // function withdrawFees(
    //     address _token,
    //     address _receiver
    // ) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPoolKyberswap {
    //https://polygonscan.com/address/0x546C79662E028B661dFB4767664d0273184E4dD1#code
    // function MINIMUM_LIQUIDITY() external view returns (uint256);

    // function PERMIT_TYPEHASH() external view returns (bytes32);

    // function allowance(
    //     address owner,
    //     address spender
    // ) external view returns (uint256);

    // function ampBps() external view returns (uint32);

    // function approve(address spender, uint256 amount) external returns (bool);

    // function balanceOf(address account) external view returns (uint256);

    // function burn(
    //     address to
    // ) external returns (uint256 amount0, uint256 amount1);

    // function decimals() external view returns (uint8);

    // function decreaseAllowance(
    //     address spender,
    //     uint256 subtractedValue
    // ) external returns (bool);

    // function domainSeparator() external view returns (bytes32);

    // function factory() external view returns (address);

    // function getReserves()
    //     external
    //     view
    //     returns (uint112 _reserve0, uint112 _reserve1);

    function getTradeInfo()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint112 _vReserve0,
            uint112 _vReserve1,
            uint256 _feeInPrecision
        );

    // function increaseAllowance(
    //     address spender,
    //     uint256 addedValue
    // ) external returns (bool);

    // function initialize(
    //     address _token0,
    //     address _token1,
    //     uint32 _ampBps,
    //     uint24 _feeUnits
    // ) external;

    // function kLast() external view returns (uint256);

    // function mint(address to) external returns (uint256 liquidity);

    // function name() external view returns (string memory);

    // function nonces(address) external view returns (uint256);

    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // function skim(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory callbackData
    ) external;

    // function symbol() external view returns (string memory);

    // function sync() external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    // function totalSupply() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IPoolKyberswapV2 {
    // function allowance(
    //     address owner,
    //     address spender
    // ) external view returns (uint256);

    // function approve(address spender, uint256 amount) external returns (bool);

    // function balanceOf(address account) external view returns (uint256);

    // function burn(
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 qty
    // )
    //     external
    //     returns (uint256 qty0, uint256 qty1, uint256 feeGrowthInsideLast);

    // function burnRTokens(
    //     uint256 _qty,
    //     bool isLogicalBurn
    // ) external returns (uint256 qty0, uint256 qty1);

    // function decimals() external view returns (uint8);

    // function decreaseAllowance(
    //     address spender,
    //     uint256 subtractedValue
    // ) external returns (bool);

    // function factory() external view returns (address);

    // function flash(
    //     address recipient,
    //     uint256 qty0,
    //     uint256 qty1,
    //     bytes memory data
    // ) external;

    // function getFeeGrowthGlobal() external view returns (uint256);

    // function getLiquidityState()
    //     external
    //     view
    //     returns (uint128 baseL, uint128 reinvestL, uint128 reinvestLLast);

    function getPoolState()
        external
        view
        returns (
            uint160 sqrtP,
            int24 currentTick,
            int24 nearestCurrentTick,
            bool locked
        );

    // function getPositions(
    //     address owner,
    //     int24 tickLower,
    //     int24 tickUpper
    // ) external view returns (uint128 liquidity, uint256 feeGrowthInsideLast);

    // function getSecondsPerLiquidityData()
    //     external
    //     view
    //     returns (uint128 secondsPerLiquidityGlobal, uint32 lastUpdateTime);

    // function getSecondsPerLiquidityInside(
    //     int24 tickLower,
    //     int24 tickUpper
    // ) external view returns (uint128 secondsPerLiquidityInside);

    // function increaseAllowance(
    //     address spender,
    //     uint256 addedValue
    // ) external returns (bool);

    // function initializedTicks(
    //     int24
    // ) external view returns (int24 previous, int24 next);

    // function maxTickLiquidity() external view returns (uint128);

    // function mint(
    //     address recipient,
    //     int24 tickLower,
    //     int24 tickUpper,
    //     int24[2] memory ticksPrevious,
    //     uint128 qty,
    //     bytes memory data
    // )
    //     external
    //     returns (uint256 qty0, uint256 qty1, uint256 feeGrowthInsideLast);

    // function name() external view returns (string memory);

    function swap(
        address recipient,
        int256 swapQty,
        bool isToken0,
        uint160 limitSqrtP,
        bytes memory data
    ) external returns (int256 deltaQty0, int256 deltaQty1);

    // function swapFeeUnits() external view returns (uint24);

    // function symbol() external view returns (string memory);

    // function tickDistance() external view returns (int24);

    // function ticks(
    //     int24
    // )
    //     external
    //     view
    //     returns (
    //         uint128 liquidityGross,
    //         int128 liquidityNet,
    //         uint256 feeGrowthOutside,
    //         uint128 secondsPerLiquidityOutside
    //     );

    function token0() external view returns (address);

    function token1() external view returns (address);

    // function totalSupply() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    // function transferFrom(
    //     address sender,
    //     address recipient,
    //     uint256 amount
    // ) external returns (bool);

    // function unlockPool(
    //     uint160 initialSqrtP
    // ) external returns (uint256 qty0, uint256 qty1);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// https://bia.is/tools/abi2solidity/

// https://curve.readthedocs.io/ref-addresses.html
interface IPoolMetavault {
    // function BASIS_POINTS_DIVISOR() external view returns (uint256);
    // function FUNDING_RATE_PRECISION() external view returns (uint256);
    // function MAX_FEE_BASIS_POINTS() external view returns (uint256);
    // function MAX_FUNDING_RATE_FACTOR() external view returns (uint256);
    // function MAX_LIQUIDATION_FEE_USD() external view returns (uint256);
    // function MIN_FUNDING_RATE_INTERVAL() external view returns (uint256);
    // function MIN_LEVERAGE() external view returns (uint256);
    // function PRICE_PRECISION() external view returns (uint256);
    // function USDM_DECIMALS() external view returns (uint256);
    // function addRouter(address _router) external;
    // function adjustForDecimals(
    //     uint256 _amount,
    //     address _tokenDiv,
    //     address _tokenMul
    // ) external view returns (uint256);
    // function allWhitelistedTokens(uint256) external view returns (address);
    // function allWhitelistedTokensLength() external view returns (uint256);
    // function approvedRouters(address, address) external view returns (bool);
    // function bufferAmounts(address) external view returns (uint256);
    // function buyUSDM(
    //     address _token,
    //     address _receiver
    // ) external returns (uint256);
    // function clearTokenConfig(address _token) external;
    // function cumulativeFundingRates(address) external view returns (uint256);
    // function decreasePosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     uint256 _collateralDelta,
    //     uint256 _sizeDelta,
    //     bool _isLong,
    //     address _receiver
    // ) external returns (uint256);
    // function directPoolDeposit(address _token) external;
    // function errorController() external view returns (address);
    // function errors(uint256) external view returns (string);
    // function feeReserves(address) external view returns (uint256);
    // function fundingInterval() external view returns (uint256);
    // function fundingRateFactor() external view returns (uint256);
    // function getDelta(
    //     address _indexToken,
    //     uint256 _size,
    //     uint256 _averagePrice,
    //     bool _isLong,
    //     uint256 _lastIncreasedTime
    // ) external view returns (bool, uint256);
    // function getEntryFundingRate(
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external view returns (uint256);
    // function getFeeBasisPoints(
    //     address _token,
    //     uint256 _usdmDelta,
    //     uint256 _feeBasisPoints,
    //     uint256 _taxBasisPoints,
    //     bool _increment
    // ) external view returns (uint256);
    // function getFundingFee(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong,
    //     uint256 _size,
    //     uint256 _entryFundingRate
    // ) external view returns (uint256);
    // function getGlobalShortDelta(
    //     address _token
    // ) external view returns (bool, uint256);
    // function getMaxPrice(address _token) external view returns (uint256);
    // function getMinPrice(address _token) external view returns (uint256);
    // function getNextAveragePrice(
    //     address _indexToken,
    //     uint256 _size,
    //     uint256 _averagePrice,
    //     bool _isLong,
    //     uint256 _nextPrice,
    //     uint256 _sizeDelta,
    //     uint256 _lastIncreasedTime
    // ) external view returns (uint256);
    // function getNextFundingRate(address _token) external view returns (uint256);
    // function getNextGlobalShortAveragePrice(
    //     address _indexToken,
    //     uint256 _nextPrice,
    //     uint256 _sizeDelta
    // ) external view returns (uint256);
    // function getPosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // )
    //     external
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         bool,
    //         uint256
    //     );
    // function getPositionDelta(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external view returns (bool, uint256);
    // function getPositionFee(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong,
    //     uint256 _sizeDelta
    // ) external view returns (uint256);
    // function getPositionKey(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external pure returns (bytes32);
    // function getPositionLeverage(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong
    // ) external view returns (uint256);
    // function getRedemptionAmount(
    //     address _token,
    //     uint256 _usdmAmount
    // ) external view returns (uint256);
    // function getRedemptionCollateral(
    //     address _token
    // ) external view returns (uint256);
    // function getRedemptionCollateralUsd(
    //     address _token
    // ) external view returns (uint256);
    // function getTargetUsdmAmount(
    //     address _token
    // ) external view returns (uint256);
    // function getUtilisation(address _token) external view returns (uint256);
    // function globalShortAveragePrices(address) external view returns (uint256);
    // function globalShortSizes(address) external view returns (uint256);
    // function gov() external view returns (address);
    // function guaranteedUsd(address) external view returns (uint256);
    // function hasDynamicFees() external view returns (bool);
    // function inManagerMode() external view returns (bool);
    // function inPrivateLiquidationMode() external view returns (bool);
    // function includeAmmPrice() external view returns (bool);
    // function increasePosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     uint256 _sizeDelta,
    //     bool _isLong
    // ) external;
    // function initialize(
    //     address _router,
    //     address _usdm,
    //     address _priceFeed,
    //     uint256 _liquidationFeeUsd,
    //     uint256 _fundingRateFactor,
    //     uint256 _stableFundingRateFactor
    // ) external;
    // function isInitialized() external view returns (bool);
    // function isLeverageEnabled() external view returns (bool);
    // function isLiquidator(address) external view returns (bool);
    // function isManager(address) external view returns (bool);
    // function isSwapEnabled() external view returns (bool);
    // function lastFundingTimes(address) external view returns (uint256);
    // function liquidatePosition(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong,
    //     address _feeReceiver
    // ) external;
    // function liquidationFeeUsd() external view returns (uint256);
    // function marginFeeBasisPoints() external view returns (uint256);
    // function maxGasPrice() external view returns (uint256);
    // function maxGlobalShortSizes(address) external view returns (uint256);
    // function maxLeverage() external view returns (uint256);
    // function maxUsdmAmounts(address) external view returns (uint256);
    // function minProfitBasisPoints(address) external view returns (uint256);
    // function minProfitTime() external view returns (uint256);
    // function mintBurnFeeBasisPoints() external view returns (uint256);
    // function poolAmounts(address) external view returns (uint256);
    // function positions(
    //     bytes32
    // )
    //     external
    //     view
    //     returns (
    //         uint256 size,
    //         uint256 collateral,
    //         uint256 averagePrice,
    //         uint256 entryFundingRate,
    //         uint256 reserveAmount,
    //         int256 realisedPnl,
    //         uint256 lastIncreasedTime
    //     );
    // function priceFeed() external view returns (address);
    // function removeRouter(address _router) external;
    // function reservedAmounts(address) external view returns (uint256);
    // function router() external view returns (address);
    // function sellUSDM(
    //     address _token,
    //     address _receiver
    // ) external returns (uint256);
    // function setBufferAmount(address _token, uint256 _amount) external;
    // function setError(uint256 _errorCode, string _error) external;
    // function setErrorController(address _errorController) external;
    // function setFees(
    //     uint256 _taxBasisPoints,
    //     uint256 _stableTaxBasisPoints,
    //     uint256 _mintBurnFeeBasisPoints,
    //     uint256 _swapFeeBasisPoints,
    //     uint256 _stableSwapFeeBasisPoints,
    //     uint256 _marginFeeBasisPoints,
    //     uint256 _liquidationFeeUsd,
    //     uint256 _minProfitTime,
    //     bool _hasDynamicFees
    // ) external;
    // function setFundingRate(
    //     uint256 _fundingInterval,
    //     uint256 _fundingRateFactor,
    //     uint256 _stableFundingRateFactor
    // ) external;
    // function setGov(address _gov) external;
    // function setInManagerMode(bool _inManagerMode) external;
    // function setInPrivateLiquidationMode(
    //     bool _inPrivateLiquidationMode
    // ) external;
    // function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    // function setIsSwapEnabled(bool _isSwapEnabled) external;
    // function setLiquidator(address _liquidator, bool _isActive) external;
    // function setManager(address _manager, bool _isManager) external;
    // function setMaxGasPrice(uint256 _maxGasPrice) external;
    // function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    // function setMaxLeverage(uint256 _maxLeverage) external;
    // function setPriceFeed(address _priceFeed) external;
    // function setTokenConfig(
    //     address _token,
    //     uint256 _tokenDecimals,
    //     uint256 _tokenWeight,
    //     uint256 _minProfitBps,
    //     uint256 _maxUsdmAmount,
    //     bool _isStable,
    //     bool _isShortable
    // ) external;
    // function setUsdmAmount(address _token, uint256 _amount) external;
    // function setVaultUtils(address _vaultUtils) external;
    // function shortableTokens(address) external view returns (bool);
    // function stableFundingRateFactor() external view returns (uint256);
    // function stableSwapFeeBasisPoints() external view returns (uint256);
    // function stableTaxBasisPoints() external view returns (uint256);
    // function stableTokens(address) external view returns (bool);
    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);
    // function swapFeeBasisPoints() external view returns (uint256);
    // function taxBasisPoints() external view returns (uint256);
    // function tokenBalances(address) external view returns (uint256);
    // function tokenDecimals(address) external view returns (uint256);
    // function tokenToUsdMin(
    //     address _token,
    //     uint256 _tokenAmount
    // ) external view returns (uint256);
    // function tokenWeights(address) external view returns (uint256);
    // function totalTokenWeights() external view returns (uint256);
    // function updateCumulativeFundingRate(
    //     address _collateralToken,
    //     address _indexToken
    // ) external;
    // function upgradeVault(
    //     address _newVault,
    //     address _token,
    //     uint256 _amount
    // ) external;
    // function usdToToken(
    //     address _token,
    //     uint256 _usdAmount,
    //     uint256 _price
    // ) external view returns (uint256);
    // function usdToTokenMax(
    //     address _token,
    //     uint256 _usdAmount
    // ) external view returns (uint256);
    // function usdToTokenMin(
    //     address _token,
    //     uint256 _usdAmount
    // ) external view returns (uint256);
    // function usdm() external view returns (address);
    // function usdmAmounts(address) external view returns (uint256);
    // function useSwapPricing() external view returns (bool);
    // function validateLiquidation(
    //     address _account,
    //     address _collateralToken,
    //     address _indexToken,
    //     bool _isLong,
    //     bool _raise
    // ) external view returns (uint256, uint256);
    // function vaultUtils() external view returns (address);
    // function whitelistedTokenCount() external view returns (uint256);
    // function whitelistedTokens(address) external view returns (bool);
    // function withdrawFees(
    //     address _token,
    //     address _receiver
    // ) external returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IPoolSaddle {
    // function MAX_BPS() external view returns (uint256);
    // // function addLiquidity(
    // //     uint256[] amounts,
    // //     uint256 minToMint,
    // //     uint256 deadline
    // // ) external returns (uint256);
    // // function calculateRemoveLiquidity(
    // //     uint256 amount
    // // ) external view returns (uint256[]);
    // function calculateRemoveLiquidityOneToken(
    //     uint256 tokenAmount,
    //     uint8 tokenIndex
    // ) external view returns (uint256 availableTokenAmount);
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    // function calculateTokenAmount(
    //     uint256[] memory amounts,
    //     bool deposit
    // ) external view returns (uint256);
    // // function flashLoan(
    // //     address receiver,
    // //     address token,
    // //     uint256 amount,
    // //     bytes params
    // // ) external;
    // function flashLoanFeeBPS() external view returns (uint256);
    // function getA() external view returns (uint256);
    // function getAPrecise() external view returns (uint256);
    // function getAdminBalance(uint256 index) external view returns (uint256);
    // function getToken(uint8 index) external view returns (address);
    // function getTokenBalance(uint8 index) external view returns (uint256);
    function getTokenIndex(address tokenAddress) external view returns (uint8);

    // function getVirtualPrice() external view returns (uint256);
    // // function initialize(
    // //     address[] _pooledTokens,
    // //     uint8[] decimals,
    // //     string lpTokenName,
    // //     string lpTokenSymbol,
    // //     uint256 _a,
    // //     uint256 _fee,
    // //     uint256 _adminFee,
    // //     address lpTokenTargetAddress
    // // ) external;
    // function owner() external view returns (address);
    // function pause() external;
    // function paused() external view returns (bool);
    // function protocolFeeShareBPS() external view returns (uint256);
    // function rampA(uint256 futureA, uint256 futureTime) external;
    // // function removeLiquidity(
    // //     uint256 amount,
    // //     uint256[] minAmounts,
    // //     uint256 deadline
    // // ) external returns (uint256[]);
    // // function removeLiquidityImbalance(
    // //     uint256[] amounts,
    // //     uint256 maxBurnAmount,
    // //     uint256 deadline
    // // ) external returns (uint256);
    // function removeLiquidityOneToken(
    //     uint256 tokenAmount,
    //     uint8 tokenIndex,
    //     uint256 minAmount,
    //     uint256 deadline
    // ) external returns (uint256);
    // function renounceOwnership() external;
    // function setAdminFee(uint256 newAdminFee) external;
    // function setFlashLoanFees(
    //     uint256 newFlashLoanFeeBPS,
    //     uint256 newProtocolFeeShareBPS
    // ) external;
    // function setSwapFee(uint256 newSwapFee) external;
    // function stopRampA() external;
    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
    // function swapStorage()
    //     external
    //     view
    //     returns (
    //         uint256 initialA,
    //         uint256 futureA,
    //         uint256 initialATime,
    //         uint256 futureATime,
    //         uint256 swapFee,
    //         uint256 adminFee,
    //         address lpToken
    //     );
    // function transferOwnership(address newOwner) external;
    // function unpause() external;
    // function withdrawAdminFees() external;
}

//SPDX-License-Identifier: MIT
//https://polygonscan.com/address/0xe0ce1d5380681d0d944b91c5a56d2b56e3cc93dc#code
//pool: "0xe0ce1D5380681d0d944b91C5A56D2B56e3cc93Dc",
pragma solidity ^0.8.4;

interface IPoolUniV2 {
    // function DOMAIN_SEPARATOR() external view returns (bytes32);

    // function HOLDING_ADDRESS() external view returns (address);

    // function MINIMUM_LIQUIDITY() external view returns (uint256);

    // function PERMIT_TYPEHASH() external view returns (bytes32);

    // function allowance(address, address) external view returns (uint256);

    // function approve(address spender, uint256 value) external returns (bool);

    // function balanceOf(address) external view returns (uint256);

    // function burn(
    //     address to
    // ) external returns (uint256 amount0, uint256 amount1);

    // function decimals() external view returns (uint8);

    // function destroy(uint256 value) external returns (bool);

    // function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    // function handleEarnings() external returns (uint256 amount);

    // function initialize(address _token0, address _token1) external;

    // function kLast() external view returns (uint256);

    // function mint(address to) external returns (uint256 liquidity);

    // function name() external view returns (string);

    // function nonces(address) external view returns (uint256);

    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // function price0CumulativeLast() external view returns (uint256);

    // function price1CumulativeLast() external view returns (uint256);

    // function skim(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) external;

    ///function symbol() external view returns (string);

    // function sync() external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    // function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT
//https://polygonscan.com/address/0xe0ce1d5380681d0d944b91c5a56d2b56e3cc93dc#code
//pool: "0xe0ce1D5380681d0d944b91C5A56D2B56e3cc93Dc",
pragma solidity ^0.8.4;

interface IPoolUniV3 {
    // function burn(
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount
    // ) external returns (uint256 amount0, uint256 amount1);

    // function collect(
    //     address recipient,
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount0Requested,
    //     uint128 amount1Requested
    // ) external returns (uint128 amount0, uint128 amount1);

    // function collectProtocol(
    //     address recipient,
    //     uint128 amount0Requested,
    //     uint128 amount1Requested
    // ) external returns (uint128 amount0, uint128 amount1);

    // function factory() external view returns (address);

    // function fee() external view returns (uint24);

    // function feeGrowthGlobal0X128() external view returns (uint256);

    // function feeGrowthGlobal1X128() external view returns (uint256);

    // function flash(
    //     address recipient,
    //     uint256 amount0,
    //     uint256 amount1,
    //     bytes memory data
    // ) external;

    // function increaseObservationCardinalityNext(
    //     uint16 observationCardinalityNext
    // ) external;

    // function initialize(uint160 sqrtPriceX96) external;

    // function liquidity() external view returns (uint128);

    // function maxLiquidityPerTick() external view returns (uint128);

    // function mint(
    //     address recipient,
    //     int24 tickLower,
    //     int24 tickUpper,
    //     uint128 amount,
    //     bytes memory data
    // ) external returns (uint256 amount0, uint256 amount1);

    // function observations(
    //     uint256
    // )
    //     external
    //     view
    //     returns (
    //         uint32 blockTimestamp,
    //         int56 tickCumulative,
    //         uint160 secondsPerLiquidityCumulativeX128,
    //         bool initialized
    //     );

    // function observe(
    //     uint32[] memory secondsAgos
    // )
    //     external
    //     view
    //     returns (
    //         int56[] memory tickCumulatives,
    //         uint160[] memory secondsPerLiquidityCumulativeX128s
    //     );

    // function positions(
    //     bytes32
    // )
    //     external
    //     view
    //     returns (
    //         uint128 liquidity,
    //         uint256 feeGrowthInside0LastX128,
    //         uint256 feeGrowthInside1LastX128,
    //         uint128 tokensOwed0,
    //         uint128 tokensOwed1
    //     );

    // function protocolFees()
    //     external
    //     view
    //     returns (uint128 token0, uint128 token1);

    // function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    // function snapshotCumulativesInside(
    //     int24 tickLower,
    //     int24 tickUpper
    // )
    //     external
    //     view
    //     returns (
    //         int56 tickCumulativeInside,
    //         uint160 secondsPerLiquidityInsideX128,
    //         uint32 secondsInside
    //     );

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    // function tickBitmap(int16) external view returns (uint256);

    // function tickSpacing() external view returns (int24);

    // function ticks(
    //     int24
    // )
    //     external
    //     view
    //     returns (
    //         uint128 liquidityGross,
    //         int128 liquidityNet,
    //         uint256 feeGrowthOutside0X128,
    //         uint256 feeGrowthOutside1X128,
    //         int56 tickCumulativeOutside,
    //         uint160 secondsPerLiquidityOutsideX128,
    //         uint32 secondsOutside,
    //         bool initialized
    //     );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPoolVelodrome {
    // function DOMAIN_SEPARATOR() external view returns (bytes32);

    // function PERMIT_TYPEHASH() external view returns (bytes32);

    // function allowance(address, address) external view returns (uint256);

    // function approve(address spender, uint256 amount) external returns (bool);

    // function balanceOf(address) external view returns (uint256);

    // function blockTimestampLast() external view returns (uint256);

    // function burn(
    //     address to
    // ) external returns (uint256 amount0, uint256 amount1);

    // function chainId() external view returns (uint256);

    // function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    // function claimable0(address) external view returns (uint256);

    // function claimable1(address) external view returns (uint256);

    // function current(
    //     address tokenIn,
    //     uint256 amountIn
    // ) external view returns (uint256 amountOut);

    // function currentCumulativePrices()
    //     external
    //     view
    //     returns (
    //         uint256 reserve0Cumulative,
    //         uint256 reserve1Cumulative,
    //         uint256 blockTimestamp
    //     );

    // function decimals() external view returns (uint8);

    // function factory() external view returns (address);

    // function fees() external view returns (address);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256);

    // function getReserves()
    //     external
    //     view
    //     returns (
    //         uint112 _reserve0,
    //         uint112 _reserve1,
    //         uint32 _blockTimestampLast
    //     );

    // function index0() external view returns (uint256);

    // function index1() external view returns (uint256);

    // // function lastObservation() external view returns (tuple );

    // function metadata()
    //     external
    //     view
    //     returns (
    //         uint256 dec0,
    //         uint256 dec1,
    //         uint256 r0,
    //         uint256 r1,
    //         bool st,
    //         address t0,
    //         address t1
    //     );

    // function mint(address to) external returns (uint256 liquidity);

    // function name() external view returns (string memory);

    // function nonces(address) external view returns (uint256);

    // function observationLength() external view returns (uint256);

    // function observations(
    //     uint256
    // )
    //     external
    //     view
    //     returns (
    //         uint256 timestamp,
    //         uint256 reserve0Cumulative,
    //         uint256 reserve1Cumulative
    //     );

    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // function prices(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 points
    // ) external view returns (uint256[] memory);

    // function quote(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 granularity
    // ) external view returns (uint256 amountOut);

    // function reserve0() external view returns (uint256);

    // function reserve0CumulativeLast() external view returns (uint256);

    // function reserve1() external view returns (uint256);

    // function reserve1CumulativeLast() external view returns (uint256);

    // function sample(
    //     address tokenIn,
    //     uint256 amountIn,
    //     uint256 points,
    //     uint256 window
    // ) external view returns (uint256[] memory);

    // function skim(address to) external;

    // function stable() external view returns (bool);

    // function supplyIndex0(address) external view returns (uint256);

    // function supplyIndex1(address) external view returns (uint256);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes memory data
    ) external;

    // function symbol() external view returns (string memory);

    // function sync() external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function tokens() external view returns (address, address);

    // function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    // function transferFrom(
    //     address src,
    //     address dst,
    //     uint256 amount
    // ) external returns (bool);

    // function treasury() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    // event PairCreated(
    //     address indexed token0,
    //     address indexed token1,
    //     address pair,
    //     uint256
    // );

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    // function allPairs(uint256) external view returns (address pair);

    // function allPairsLength() external view returns (uint256);

    // function feeTo() external view returns (address);

    // function feeToSetter() external view returns (address);

    // function createPair(address tokenA, address tokenB)
    //     external
    //     returns (address pair);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    // event Approval(
    //     address indexed owner,
    //     address indexed spender,
    //     uint256 value
    // );
    // event Transfer(address indexed from, address indexed to, uint256 value);

    // function name() external pure returns (string memory);

    // function symbol() external pure returns (string memory);

    // function decimals() external pure returns (uint8);

    // function totalSupply() external view returns (uint256);

    // function balanceOf(address owner) external view returns (uint256);

    // function allowance(
    //     address owner,
    //     address spender
    // ) external view returns (uint256);

    // function approve(address spender, uint256 value) external returns (bool);

    // function transfer(address to, uint256 value) external returns (bool);

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 value
    // ) external returns (bool);

    // function DOMAIN_SEPARATOR() external view returns (bytes32);

    // function PERMIT_TYPEHASH() external pure returns (bytes32);

    // function nonces(address owner) external view returns (uint256);

    // function permit(
    //     address owner,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) external;

    // event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    // event Burn(
    //     address indexed sender,
    //     uint256 amount0,
    //     uint256 amount1,
    //     address indexed to
    // );
    // event Swap(
    //     address indexed sender,
    //     uint256 amount0In,
    //     uint256 amount1In,
    //     uint256 amount0Out,
    //     uint256 amount1Out,
    //     address indexed to
    // );
    // event Sync(uint112 reserve0, uint112 reserve1);

    // function MINIMUM_LIQUIDITY() external pure returns (uint256);

    // function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    // function price0CumulativeLast() external view returns (uint256);

    // function price1CumulativeLast() external view returns (uint256);

    // function kLast() external view returns (uint256);

    // function mint(address to) external returns (uint256 liquidity);

    // function burn(
    //     address to
    // ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    // function skim(address to) external;

    // function sync() external;

    // function initialize(address, address) external;
}

//SPDX-License-Identifier: Unlicense
//https://polygonscan.com/

pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPoolUniV2.sol";
import "./interfaces/IPoolUniV3.sol";
import "./interfaces/IPoolAddressesProvider.sol";
import "./libraries/SafeMath.sol";
import "./libraries/DexSwaps.sol";
import "./interfaces/IPoolDODO.sol";
import "./interfaces/IAsset.sol";
import "./interfaces/IBalancerVault.sol";
import "./interfaces/IPoolCurve.sol";
import "./interfaces/IPoolSaddle.sol";
import "./interfaces/IPoolMetavault.sol";
import "./interfaces/IPoolAddressesProvider.sol";
import "./libraries/FlashLoanSimpleReceiverBase.sol";

contract KyberArbitrage is DexSwaps, FlashLoanSimpleReceiverBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    address public owner;
    address addressProvider;
    //Declare an Event
    event ArbitrageExecuted(
        address token,
        uint256 amountIn,
        uint256 amountOut,
        uint256 ratio,
        uint256 profit
    );

    constructor(
        address _addressProvider
    ) FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider)) {
        addressProvider = _addressProvider;
        owner = (msg.sender);
        console.log("create KyberArbitrage");
    }

    // ////////////////////////////ARBITRAGE
    function Arbitrage(
        bytes[] calldata encodedSwap,
        address tokenIn,
        uint256 amountIn
    ) external {
        console.log("create Arbitrage");
        bytes memory data = abi.encode(encodedSwap); // before flash loan
        console.log(
            "BAlance antes del prestamo de usdt ",
            IERC20(tokenIn).balanceOf(address(this))
        );
        // AAVE Flash Loan
        requestFlashLoan(data, tokenIn, amountIn);
    }

    // ////////////////////////////executeOperation

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address,
        bytes calldata params //mandar data
    ) external override returns (bool) {
        SwapInfo[6] memory swapInfoArray = SetSwapInfoArray(params); // in side Onflashloan  callback
        uint256 amountIn = amount;
        uint256 amountOwed = amount + premium;
        // console.log("amount in ", amountIn);
        // console.log(
        //     "ERC20(asset).balanceOf(address(this) ",
        //     IERC20(asset).balanceOf(address(this))
        // );
        // ExecuteSwaps
        for (uint8 i; i < swapInfoArray.length; i++) {
            console.log("i ", i);

            if (swapInfoArray[i].pool != address(0)) {
                amountIn = ExecuteSwap(swapInfoArray[i], amountIn);
            }
        }

        uint256 FinalBalance = amountIn;
        // uint256 FinalBalance = IERC20(asset).balanceOf(address(this)); ///////////////////// temporal

        // console.log("\n\n");
        // console.log("amount", amount);
        // console.log("premium", premium);
        // console.log("amountOwed", amountOwed);
        // console.log("FinalBalance", FinalBalance);

        require(FinalBalance > amountOwed, "Arbitrage not profitable");

        console.log("FinalBalance - amountOwed", FinalBalance - amountOwed);

        IERC20(asset).transfer(owner, FinalBalance - amountOwed);
        approveToken(asset, address(POOL));
        emit ArbitrageExecuted(
            asset,
            amount,
            FinalBalance,
            (FinalBalance * 1000000) / amount,
            FinalBalance - amount
        );
        return true;
    }

    ///////////////////// EXECUTE SWAP
    function ExecuteSwap(
        SwapInfo memory swapInfo,
        uint256 amountIn
    ) public returns (uint256) {
        console.log(swapInfo.poolType);
        // UNISWAP V2
        if (swapInfo.poolType == 0) {
            SwapUniswapV2(swapInfo, amountIn);
        }
        // UNISWAP V3
        else if (swapInfo.poolType == 1) {
            SwapUniswapV3(swapInfo, amountIn);
        }
        // // BALANCER
        else if (swapInfo.poolType == 2) {
            SwapBalancer(swapInfo, amountIn);
        }
        // // CURVE
        else if (swapInfo.poolType == 3) {
            SwapCurve(swapInfo, amountIn);
        }
        //DODO
        else if (swapInfo.poolType == 4) {
            SwapDodo(swapInfo, amountIn);
        }
        //DODO CLASSIC
        else if (swapInfo.poolType == 10) {
            SwapDodoClassic(swapInfo, amountIn);
        }
        // // KYBERSWAP V1
        else if (swapInfo.poolType == 5) {
            SwapKyberswapV1(swapInfo, amountIn);
        }
        // // KYBERSWAP V2
        else if (swapInfo.poolType == 6) {
            SwapKyberswapV2(swapInfo, amountIn);
        }
        // //METAVAULT
        else if (swapInfo.poolType == 7) {
            SwapMetavault(swapInfo, amountIn);
        }
        // // SADDLE
        else if (swapInfo.poolType == 8) {
            SwapSaddle(swapInfo, amountIn);
        }
        // VELODROME
        else if (swapInfo.poolType == 9) {
            console.log("VELODROME", swapInfo.poolType);

            // SwapVelodrome(swapInfo, amountIn);
        }
        // //GMX
        else if (swapInfo.poolType == 11) {
            SwapGmx(swapInfo, amountIn);
        }
        // //camelot
        else if (swapInfo.poolType == 12) {
            console.log("camelot", swapInfo.poolType);

            SwapCamelot(swapInfo, amountIn);
        }
        uint256 balanceTokenOut = IERC20(swapInfo.tokenOut).balanceOf(
            address(this)
        );

        require(balanceTokenOut > 0, "Swap Failed");
        return balanceTokenOut;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IERC20(_address).balanceOf(address(this));
    }

    function testFunction() public pure returns (address) {
        return address(0);
    }

    function withdrawAll() public returns (address) {
        address[] memory tokens = tokensAAVE();
        for (uint256 i; i < tokens.length; i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokens[i]).transfer(owner, balance);
            }
            // console.log("\n", tokens[i]);
            // console.log(balance);
        }

        return address(0);
    }

    function SetSwapInfoArray(
        bytes memory data
    ) internal pure returns (SwapInfo[6] memory) {
        bytes[] memory decodedSwap = abi.decode(data, (bytes[]));
        SwapInfo[6] memory swapInfoArray;

        for (uint8 i; i < decodedSwap.length; i++) {
            swapInfoArray[i] = decodeSwapInfo(decodedSwap[i]);
        }

        return swapInfoArray;
    }

    function decodeSwapInfo(
        bytes memory data
    ) public pure returns (SwapInfo memory) {
        (
            address pool,
            address tokenIn,
            address tokenOut,
            uint8 poolType,
            bytes32 poolId
        ) = abi.decode(data, (address, address, address, uint8, bytes32));

        SwapInfo memory swapInfo = SwapInfo(
            pool,
            tokenIn,
            tokenOut,
            poolType,
            poolId
        );
        return swapInfo;
    }

    ///////////////////// AAVE FLASHLOAN
    function requestFlashLoan(
        bytes memory data,
        address _token,
        uint256 _amount
    ) public {
        address reciverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        uint16 referralCode = 0; // ?

        POOL.flashLoanSimple(reciverAddress, asset, amount, data, referralCode);
    }

    ///////////////////// AAVE TOKENS
    function tokensAAVE() public view returns (address[] memory) {
        IPoolAddressesProvider.tokensAAVE[]
            memory list = IPoolAddressesProvider(
                IPoolAddressesProvider(addressProvider).getPoolDataProvider()
            ).getAllReservesTokens();

        address[] memory addressList = new address[](list.length);
        for (uint256 i; i < list.length; i++) {
            addressList[i] = list[i].token;
        }
        return addressList;
    }

    function contractBalance(
        address referenceToken,
        address factory
    ) external view returns (Balance[] memory) {
        console.log(referenceToken, factory);
        address[] memory tokens = tokensAAVE();
        console.log("Contract -  contractBalance tokensAAVE");

        Balance[] memory balances = new Balance[](tokens.length + 1);

        for (uint256 i; i < tokens.length; i++) {
            string memory symbol = IERC20(tokens[i]).symbol();
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            uint256 referenceBalance;
            if (referenceToken != tokens[i]) {
                referenceBalance = getAmountsOut(
                    factory,
                    balance,
                    tokens[i],
                    referenceToken
                );
            } else {
                referenceBalance = balance;
            }

            uint8 decimals = IERC20(tokens[i]).decimals();
            balances[i] = Balance(
                symbol,
                tokens[i],
                decimals,
                balance,
                referenceBalance
            );
        }

        uint256 totalBalanceUSD;
        for (uint256 i; i < tokens.length; i++) {
            // console.log("totalBalanceUSD", totalBalanceUSD);
            totalBalanceUSD = balances[i].balanceUSD + totalBalanceUSD;
        }

        // console.log("tokens.length + 1", tokens.length + 1);
        // console.log("decimals", IERC20(referenceToken).decimals());

        balances[tokens.length] = Balance(
            "TOTAL",
            address(0),
            IERC20(referenceToken).decimals(),
            totalBalanceUSD,
            totalBalanceUSD
        );

        return balances;
    }

    function getAmountsOut(
        address factory,
        uint amountIn,
        address tokenIn,
        address tokenOut
    ) internal view returns (uint256 amountsOut) {
        address pool = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        // console.log("pool", pool);
        if (pool != address(0)) {
            (uint reserveIn, uint reserveOut, ) = IPoolUniV2(pool)
                .getReserves();
            uint amountInWithFee = amountIn.mul(997);
            uint numerator = amountInWithFee.mul(reserveOut);
            uint denominator = reserveIn.mul(1000).add(amountInWithFee);
            amountsOut = numerator / denominator;
        } else {
            amountsOut = 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

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

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct EModeCategory {
        // each eMode category has a custom ltv and liquidation threshold
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        // each eMode category may or may not have a custom oracle to override the individual assets price oracles
        address priceSource;
        string label;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currPrincipalStableDebt;
        uint256 currAvgStableBorrowRate;
        uint256 currTotalStableDebt;
        uint256 nextAvgStableBorrowRate;
        uint256 nextTotalStableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
        uint40 stableDebtLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveAToken;
        address priceOracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        InterestRateMode interestRateMode;
        address onBehalfOf;
        bool useATokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ExecuteSetUserEModeParams {
        uint256 reservesCount;
        address oracle;
        uint8 categoryId;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
        uint8 fromEModeCategory;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        uint256[] interestRateModes;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 maxStableRateBorrowSizePercent;
        uint256 reservesCount;
        address addressesProvider;
        uint8 userEModeCategory;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
        uint8 userEModeCategory;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        InterestRateMode interestRateMode;
        uint256 maxStableLoanPercent;
        uint256 reservesCount;
        address oracle;
        uint8 userEModeCategory;
        address priceOracleSentinel;
        bool isolationModeActive;
        address isolationModeCollateralAddress;
        uint256 isolationModeDebtCeiling;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct CalculateInterestRatesParams {
        uint256 unbacked;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        uint256 averageStableBorrowRate;
        uint256 reserveFactor;
        address reserve;
        address aToken;
    }

    struct InitReserveParams {
        address asset;
        address aTokenAddress;
        address stableDebtAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "./TickMath.sol";
import "./FullMath.sol";
// import "../interfaces/IUniswapV3Pool.sol";
// import "../interfaces/IUniswapV2Router02.sol";
// import "../interfaces/IUniswapV2Router01.sol";
import "hardhat/console.sol";
// import "../interfaces/IFactoryCurve.sol";
import "../interfaces/IPoolCurve.sol";
// import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
// import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// import "../interfaces/IRouterSOLIDLY.sol";
import "./SafeERC20.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IPoolUniV2.sol";
import "../interfaces/IPoolUniV3.sol";
import "../interfaces/IPoolKyberswap.sol";
import "../interfaces/IPoolKyberswapV2.sol";
import "../interfaces/IPoolVelodrome.sol";
import "../interfaces/IPoolCamelot.sol";

import "../interfaces/IPoolAddressesProvider.sol";
import "../libraries/SafeMath.sol";
import "../interfaces/IPoolDODO.sol";
import "../interfaces/IAsset.sol";
import "../interfaces/IBalancerVault.sol";
// import "../interfaces/IFactoryCurve.sol";
import "../interfaces/IPoolSaddle.sol";
import "../interfaces/IPoolMetavault.sol";
import "../interfaces/IPoolGmx.sol";

contract DexSwaps {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct SwapInfo {
        address pool;
        address tokenIn;
        address tokenOut;
        uint8 poolType;
        bytes32 poolId;
    }

    struct Balance {
        string symbol;
        address token;
        uint8 decimals;
        uint256 balance;
        uint256 balanceUSD;
    }
    uint256 constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function SwapUniswapV2(SwapInfo memory info, uint256 amountIn) internal {
        // // console.log("*********** SwapUniswapV2 ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        uint112 _reserve0;
        uint112 _reserve1;
        uint256 reserveIn;
        uint256 reserveOut;

        // approve the tokenIn on the pool
        approveToken(info.tokenIn, info.pool);

        // transfer: This function allows an address to send tokens to another address.
        IERC20(info.tokenIn).transfer(address(info.pool), amountIn);

        // Use IPoolUniV2 to get token 0 and 1
        address token0 = IPoolUniV2(info.pool).token0();
        address token1 = IPoolUniV2(info.pool).token1();

        //get the reserves from the pool
        (_reserve0, _reserve1, ) = IPoolUniV2(info.pool).getReserves();
        reserveIn = info.tokenIn == token0 ? _reserve0 : _reserve1;
        reserveOut = info.tokenIn == token1 ? _reserve0 : _reserve1;

        //make operatios to take amountOut
        uint256 amountOut;
        // uint256 amountIn = amountIn;
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;

        // validate if the amountOut is for token0 or token1
        uint256 amount0Out = info.tokenIn == token0 ? 0 : amountOut;
        uint256 amount1Out = info.tokenIn == token1 ? 0 : amountOut;

        //make the swap
        IPoolUniV2(info.pool).swap(amount0Out, amount1Out, address(this), "");
        // ///tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapUniswapV3(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("*********** SwapUniswapV3 ***********");
        bool zeroForOne;
        // ///tokensBalance(info.tokenIn, info.tokenOut);
        address token0 = IPoolUniV3(info.pool).token0();
        (uint160 sqrtPriceLimitX96, , , , , , ) = IPoolUniV3(info.pool).slot0();

        if (token0 == info.tokenIn) {
            zeroForOne = true;
            sqrtPriceLimitX96 = (sqrtPriceLimitX96 * 900) / 1000;
        } else {
            zeroForOne = false;
            sqrtPriceLimitX96 = (sqrtPriceLimitX96 * 1100) / 1000;
        }

        bytes memory data = abi.encode(info.pool, info.tokenIn, zeroForOne);

        IPoolUniV3(info.pool).swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            sqrtPriceLimitX96,
            data
        );

        // ///tokensBalance(info.tokenIn, info.tokenOut);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        (address pool, address tokenIn, bool zeroForOne) = abi.decode(
            data,
            (address, address, bool)
        );
        // console.log("uniswapV3SwapCallback");

        // console.logInt(amount0Delta);
        // console.logInt(amount1Delta);

        if (zeroForOne) {
            IERC20(tokenIn).transfer(address(pool), uint256(amount0Delta));
        } else {
            IERC20(tokenIn).transfer(address(pool), uint256(amount1Delta));
        }
        // console.log("*********** uniswapV3SwapCallback  transfer ***********");
    }

    function SwapMetavault(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n*********** SwapMetavault ***********");
        //tokensBalance(info.tokenIn, info.tokenOut);

        IERC20(info.tokenIn).transfer(info.pool, amountIn);
        IPoolMetavault(info.pool).swap(
            info.tokenIn,
            info.tokenOut,
            address(this)
        );
        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapGmx(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n*********** SwapGmx ***********");
        //tokensBalance(info.tokenIn, info.tokenOut);

        IERC20(info.tokenIn).transfer(info.pool, amountIn);
        IPoolGmx(info.pool).swap(info.tokenIn, info.tokenOut, address(this));
        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapCamelot(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n*********** SwapGmx ***********");
        //tokensBalance(info.tokenIn, info.tokenOut);

        //appruve
        // approveToken(info.tokenIn, info.pool);
        IERC20(info.tokenIn).transfer(info.pool, amountIn);

        address token0 = IPoolUniV2(info.pool).token0();
        // address token1 = IPoolUniV2(info.pool).token1();

        uint256 amount = IPoolCamelot(info.pool).getAmountOut(
            amountIn,
            info.tokenIn
        );
        console.log("amount", amount);

        uint256 amount0Out;
        uint256 amount1Out;

        if (info.tokenOut == token0) {
            amount0Out = amount;
        } else {
            amount1Out = amount;
        }

        IPoolCamelot(info.pool).swap(amount0Out, amount1Out, address(this), "");
        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapDodo(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n***********DexSwaps SwapDodo ***********");

        // tokensBalance(info.tokenIn, info.tokenOut);

        IERC20(info.tokenIn).transfer(info.pool, amountIn);
        // console.log("info.pool", info.pool);
        if (IPoolDODO(info.pool)._BASE_TOKEN_() == info.tokenIn) {
            // console.log("sellBase");
            IPoolDODO(info.pool).sellBase(address(this)); //WMATIC
        } else if (IPoolDODO(info.pool)._QUOTE_TOKEN_() == info.tokenIn) {
            // console.log("_QUOTE_TOKEN_");

            IPoolDODO(info.pool).sellQuote(address(this)); //USDC`
        }

        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapDodoClassic(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n***********DexSwaps SwapDodo ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        approveToken(info.tokenIn, info.pool);
        uint256 amountOut;

        // console.log("\ninfo.pool", info.pool);
        if (IPoolDODO(info.pool)._BASE_TOKEN_() == info.tokenIn) {
            amountOut = IPoolDODO(info.pool).queryBuyBaseToken(amountIn);

            // console.log("\nsellBaseToken amountOut", amountOut);

            IPoolDODO(info.pool).sellBaseToken(amountOut, amountOut, "");
        } else if (IPoolDODO(info.pool)._QUOTE_TOKEN_() == info.tokenIn) {
            amountOut = IPoolDODO(info.pool).querySellBaseToken(amountIn);

            // console.log("\nbuyBaseToken amountOut", amountOut);

            IPoolDODO(info.pool).buyBaseToken(amountOut, amountOut, "");
        }

        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapKyberswapV1(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n***********DexSwaps SwapKyberswapV1 ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        IERC20(info.tokenIn).transfer(address(info.pool), amountIn);
        (
            ,
            ,
            uint256 vReserveIn,
            uint256 vReserveOut,
            uint256 feeInPrecision
        ) = IPoolKyberswap(info.pool).getTradeInfo();
        uint256 PRECISION = 1e18;

        uint256 amountInWithFee = amountIn
            .mul(PRECISION.sub(feeInPrecision))
            .div(PRECISION);

        uint256 amount0Out;
        uint256 amount1Out;
        uint256 denominator;
        if (IPoolKyberswap(info.pool).token0() == info.tokenIn) {
            denominator = vReserveIn.add(amountInWithFee);
            amount1Out = amountInWithFee.mul(vReserveOut).div(denominator);
        } else {
            denominator = vReserveOut.add(amountInWithFee);
            amount0Out = amountInWithFee.mul(vReserveIn).div(denominator);
        }

        IPoolKyberswap(info.pool).swap(
            amount0Out,
            amount1Out,
            address(this),
            ""
        );

        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapKyberswapV2(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n***********DexSwaps SwapKiberswapV2 ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        IPoolKyberswapV2 pool = IPoolKyberswapV2(info.pool);

        (uint160 sqrtPriceLimitX96, , , ) = pool.getPoolState();
        bool zeroForOne;

        if (pool.token0() == info.tokenIn) {
            zeroForOne = true;
            sqrtPriceLimitX96 = (sqrtPriceLimitX96 * 900) / 1000;
        } else {
            zeroForOne = false;

            sqrtPriceLimitX96 = (sqrtPriceLimitX96 * 1100) / 1000;
        }
        pool.swap(
            address(this),
            int256(amountIn),
            zeroForOne,
            sqrtPriceLimitX96,
            ""
        );
        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    // function SwapVelodrome(SwapInfo memory info, uint256 amountIn) internal {
    //     // console.log("\n***********DexSwaps SwapVelodrome ***********");
    //     // tokensBalance(info.tokenIn, info.tokenOut);

    //     IERC20(info.tokenIn).transfer(info.pool, amountIn);

    //     IPoolVelodrome pool = IPoolVelodrome(info.pool);

    //     uint256 amountOut = pool.getAmountOut(amountIn, info.tokenIn);

    //     uint256 amount0Out = info.tokenIn == pool.token0() ? 0 : amountOut;
    //     uint256 amount1Out = info.tokenIn != pool.token0() ? 0 : amountOut;

    //     pool.swap(amount0Out, amount1Out, address(this), "");
    //     // tokensBalance(info.tokenIn, info.tokenOut);
    // }

    function SwapSaddle(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n*********** SwapSaddle ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        uint8 i = IPoolSaddle(info.pool).getTokenIndex(info.tokenIn);
        uint8 j = IPoolSaddle(info.pool).getTokenIndex(info.tokenOut);

        // // console.log("i", i);
        // // console.log("j", j);
        uint256 amountOut = IPoolSaddle(info.pool).calculateSwap(
            i,
            j,
            amountIn
        );
        // // console.log("amountOut", amountOut);
        approveToken(info.tokenIn, info.pool);

        IPoolSaddle(info.pool).swap(i, j, amountIn, amountOut, block.timestamp);

        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapCurve(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("\n*********** SwapCurve ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        uint256 i = 1000;
        uint256 j = 1000;

        for (uint k = 0; k < 20; k++) {
            if (i != 1000 && j != 1000) {
                break;
            }
            address coin = IPoolCurve(info.pool).coins(k);

            if (coin == info.tokenIn) {
                i = k;
            }
            if (coin == info.tokenOut) {
                j = k;
            }
        }

        approveToken(info.tokenIn, info.pool);
        uint256 dy = IPoolCurve(info.pool).get_dy(i, j, amountIn);

        IPoolCurve(info.pool).exchange(i, j, amountIn, dy);
        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    function SwapBalancer(SwapInfo memory info, uint256 amountIn) internal {
        // console.log("*********** SwapBalancer ***********");
        // tokensBalance(info.tokenIn, info.tokenOut);

        IBalancerVault.FundManagement memory fund = IBalancerVault
            .FundManagement(
                address(this),
                false,
                payable(address(this)),
                false
            );

        IBalancerVault.SingleSwap memory singleBalSwap = IBalancerVault
            .SingleSwap(
                info.poolId,
                IBalancerVault.SwapKind.GIVEN_IN,
                IAsset(info.tokenIn),
                IAsset(info.tokenOut),
                amountIn,
                ""
            );

        approveToken(info.tokenIn, info.pool);

        IBalancerVault(info.pool).swap(singleBalSwap, fund, 0, block.timestamp);
        // tokensBalance(info.tokenIn, info.tokenOut);
    }

    //IPoolKyberswapV2
    function swapCallback(
        int256 deltaQty0,
        int256 deltaQty1,
        bytes calldata
    ) external {
        int256 amount;
        IPoolKyberswapV2 pool = IPoolKyberswapV2(msg.sender);

        // tokensBalance(
        // 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270,
        // 0x1C954E8fe737F99f68Fa1CCda3e51ebDB291948C
        // );
        if (deltaQty0 > 0) {
            amount = deltaQty0;
            IERC20(pool.token0()).transfer(msg.sender, uint256(amount));
        } else {
            amount = deltaQty1;
            IERC20(pool.token1()).transfer(msg.sender, uint256(amount));
        }
    }

    // function tokensBalance(address tokenIn, address tokenOut) internal view {
    // uint256 balanceIn = IERC20(tokenIn).balanceOf(address(this));
    // uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));
    // console.log("\nbalance tokenIn", balanceIn, tokenIn);
    // console.log("balance tokenOut", balanceOut, tokenOut);
    // }

    function approveToken(address token, address pool) internal {
        if (IERC20(token).allowance(address(this), pool) == 0) {
            IERC20(token).approve(pool, MAX_INT);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
// pragma solidity 0.8.10;
pragma solidity ^0.8.4;

import "../interfaces/IPoolAddressesProvider.sol";
import "../interfaces/IPool.sol";

import "../interfaces/IFlashLoanSimpleReceiver.sol";

// import {IFlashLoanSimpleReceiver} from "../interfaces/IFlashLoanSimpleReceiver.sol";
// import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";
// import {IPool} from "../../interfaces/IPool.sol";

/**
 * @title FlashLoanSimpleReceiverBase
 * @author Aave
 * @notice Base contract to develop a flashloan-receiver contract.
 */
abstract contract FlashLoanSimpleReceiverBase is IFlashLoanSimpleReceiver {
    IPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    IPool public immutable override POOL;

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        POOL = IPool(provider.getPool());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "../interfaces/IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(
        int24 tick
    ) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0
                ? uint256(-int256(tick))
                : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160(
                (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
            );
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    // function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
    //     unchecked {
    //         // second inequality must be < because the price can never reach the price at the max tick
    //         if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
    //         uint256 ratio = uint256(sqrtPriceX96) << 32;

    //         uint256 r = ratio;
    //         uint256 msb = 0;

    //         assembly {
    //             let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := shl(5, gt(r, 0xFFFFFFFF))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := shl(4, gt(r, 0xFFFF))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := shl(3, gt(r, 0xFF))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := shl(2, gt(r, 0xF))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := shl(1, gt(r, 0x3))
    //             msb := or(msb, f)
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             let f := gt(r, 0x1)
    //             msb := or(msb, f)
    //         }

    //         if (msb >= 128) r = ratio >> (msb - 127);
    //         else r = ratio << (127 - msb);

    //         int256 log_2 = (int256(msb) - 128) << 64;

    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(63, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(62, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(61, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(60, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(59, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(58, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(57, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(56, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(55, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(54, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(53, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(52, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(51, f))
    //             r := shr(f, r)
    //         }
    //         assembly {
    //             r := shr(127, mul(r, r))
    //             let f := shr(128, r)
    //             log_2 := or(log_2, shl(50, f))
    //         }

    //         int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

    //         int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
    //         int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

    //         tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}