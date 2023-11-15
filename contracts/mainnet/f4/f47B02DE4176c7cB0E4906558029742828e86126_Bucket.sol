// SPDX-License-Identifier: AGPL-3.0
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
  function transferFrom(
    address sender,
    address recipient,
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 * @dev It only contains one single function, needed as a hook on aToken and debtToken transfers.
 */
interface IAaveIncentivesController {
  /**
   * @dev Called by the corresponding asset on transfer hook in order to update the rewards distribution.
   * @dev The units of `totalSupply` and `userBalance` should be the same.
   * @param user The address of the user whose asset balance has changed
   * @param totalSupply The total supply of the asset prior to user balance change
   * @param userBalance The previous user balance prior to balance change
   */
  function handleAction(
    address user,
    uint256 totalSupply,
    uint256 userBalance
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from '../dependencies/openzeppelin/contracts/IERC20.sol';
import {IScaledBalanceToken} from './IScaledBalanceToken.sol';
import {IInitializableAToken} from './IInitializableAToken.sol';

/**
 * @title IAToken
 * @author Aave
 * @notice Defines the basic interface for an AToken.
 */
interface IAToken is IERC20, IScaledBalanceToken, IInitializableAToken {
  /**
   * @dev Emitted during the transfer action
   * @param from The user whose tokens are being transferred
   * @param to The recipient
   * @param value The scaled amount being transferred
   * @param index The next liquidity index of the reserve
   */
  event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

  /**
   * @notice Mints `amount` aTokens to `user`
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted aTokens
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address caller,
    address onBehalfOf,
    uint256 amount,
    uint256 index
  ) external returns (bool);

  /**
   * @notice Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @dev In some instances, the mint event could be emitted from a burn transaction
   * if the amount to burn is less than the interest that the user accrued
   * @param from The address from which the aTokens will be burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The next liquidity index of the reserve
   */
  function burn(
    address from,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
   * @notice Mints aTokens to the reserve treasury
   * @param amount The amount of tokens getting minted
   * @param index The next liquidity index of the reserve
   */
  function mintToTreasury(uint256 amount, uint256 index) external;

  /**
   * @notice Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
   * @param from The address getting liquidated, current owner of the aTokens
   * @param to The recipient
   * @param value The amount of tokens getting transferred
   */
  function transferOnLiquidation(
    address from,
    address to,
    uint256 value
  ) external;

  /**
   * @notice Transfers the underlying asset to `target`.
   * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
   * @param target The recipient of the underlying
   * @param amount The amount getting transferred
   */
  function transferUnderlyingTo(address target, uint256 amount) external;

  /**
   * @notice Handles the underlying received by the aToken after the transfer has been completed.
   * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
   * transfer is concluded. However in the future there may be aTokens that allow for example to stake the underlying
   * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
   * @param user The user executing the repayment
   * @param onBehalfOf The address of the user who will get his debt reduced/removed
   * @param amount The amount getting repaid
   */
  function handleRepayment(
    address user,
    address onBehalfOf,
    uint256 amount
  ) external;

  /**
   * @notice Allow passing a signed message to approve spending
   * @dev implements the permit function as for
   * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
   * @param owner The owner of the funds
   * @param spender The spender
   * @param value The amount
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v Signature param
   * @param s Signature param
   * @param r Signature param
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @notice Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @return The address of the underlying asset
   */
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  /**
   * @notice Returns the address of the Aave treasury, receiving the fees on this aToken.
   * @return Address of the Aave treasury
   */
  function RESERVE_TREASURY_ADDRESS() external view returns (address);

  /**
   * @notice Get the domain separator for the token
   * @dev Return cached value if chainId matches cache, otherwise recomputes separator
   * @return The domain separator of the token at current chain
   */
  function DOMAIN_SEPARATOR() external view returns (bytes32);

  /**
   * @notice Returns the nonce for owner.
   * @param owner The address of the owner
   * @return The nonce of the owner
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';
import {IPool} from './IPool.sol';

/**
 * @title IInitializableAToken
 * @author Aave
 * @notice Interface for the initialize function on AToken
 */
interface IInitializableAToken {
  /**
   * @dev Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals The decimals of the underlying
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the aToken
   * @param pool The pool contract that is initializing this contract
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    IPool pool,
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

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
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

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
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

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
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

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
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   */
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   */
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

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
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

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
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

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
  function getUserAccountData(address user)
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
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   */
  function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
    external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   */
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   */
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

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
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   */
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

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
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

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
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

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
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

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
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

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
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   */
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   */
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   */
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   */
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   */
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   */
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   */
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   */
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IScaledBalanceToken
 * @author Aave
 * @notice Defines the basic interface for a scaled-balance token.
 */
interface IScaledBalanceToken {
  /**
   * @dev Emitted after the mint action
   * @param caller The address performing the mint
   * @param onBehalfOf The address of the user that will receive the minted tokens
   * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
   * @param index The next liquidity index of the reserve
   */
  event Mint(
    address indexed caller,
    address indexed onBehalfOf,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @dev Emitted after the burn action
   * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
   * @param from The address from which the tokens will be burned
   * @param target The address that will receive the underlying, if any
   * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
   * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
   * @param index The next liquidity index of the reserve
   */
  event Burn(
    address indexed from,
    address indexed target,
    uint256 value,
    uint256 balanceIncrease,
    uint256 index
  );

  /**
   * @notice Returns the scaled balance of the user.
   * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
   * at the moment of the update
   * @param user The user whose balance is calculated
   * @return The scaled balance of the user
   */
  function scaledBalanceOf(address user) external view returns (uint256);

  /**
   * @notice Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled total supply
   */
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
   * @return The scaled total supply
   */
  function scaledTotalSupply() external view returns (uint256);

  /**
   * @notice Returns last index interest was accrued to the user's balance
   * @param user The address of the user
   * @return The last index interest was accrued to the user's balance, expressed in ray
   */
  function getPreviousIndex(address user) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
interface IERC165 {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IActivityRewardDistributorStorage, IERC20, IPrimexDNS, ITraderBalanceVault} from "./IActivityRewardDistributorStorage.sol";
import {IWhiteBlackList} from "../WhiteBlackList/WhiteBlackList/IWhiteBlackList.sol";
import {IBucket} from "../Bucket/IBucket.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface IActivityRewardDistributor is IActivityRewardDistributorStorage, IPausable {
    enum Role {
        LENDER,
        TRADER
    }

    struct BucketWithRole {
        address bucketAddress;
        Role role;
    }

    /**
     * @notice Emitted on claimReward()
     * @param user The address of the user who claimed reward
     * @param bucket The address of the bucket this reward is related to
     * @param role User role - TRADER or LENDER
     * @param amount Claimed amount
     */
    event ClaimReward(address indexed user, address indexed bucket, Role indexed role, uint256 amount);

    /**
     * @notice  Initializes the ActivityRewardDistributor contract.
     * @dev This function should only be called once during the initial setup of the contract.
     * @param _pmx The address of the PMXToken contract.
     * @param _dns The address of the PrimexDNS contract.
     * @param _registry The address of the PrimexRegistry contract.
     * @param _treasury The address of the treasury where fees will be collected.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _whiteBlackList The address of the WhiteBlackList contract.
     */
    function initialize(
        IERC20 _pmx,
        IPrimexDNS _dns,
        address _registry,
        address _treasury,
        ITraderBalanceVault _traderBalanceVault,
        IWhiteBlackList _whiteBlackList
    ) external;

    /**
     * @notice  Saves user activity in the protocol for reward calculation
     * @param   bucket  The address of the bucket
     * @param   user  User address
     * @param   newBalance  User balance after action
     * @param   role  User role - TRADER or LENDER
     */
    function updateUserActivity(IBucket bucket, address user, uint256 newBalance, Role role) external;

    /**
     * @notice  Saves activity of multiple users in the protocol for reward calculation
     * @param   bucket  The address of the bucket
     * @param   users  Array of user addresses
     * @param   newBalances  Array of users balances after action
     * @param   length  The length of the users and oldBalances arrays
     * @param   role  User role - TRADER or LENDER
     */
    function updateUsersActivities(
        IBucket bucket,
        address[] calldata users,
        uint256[] calldata newBalances,
        uint256 length,
        Role role
    ) external;

    /**
     * @notice Allows the caller to claim their accumulated reward from the specified buckets.
     * @param bucketsArray The array of BucketWithRole objects containing the buckets from which to claim the rewards.
     */
    function claimReward(BucketWithRole[] calldata bucketsArray) external;

    /**
     * @notice Sets up activity rewards distribution in bucket with the specified role and reward parameters.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param bucket The address of the bucket to set up.
     * @param role The role associated with the bucket.
     * @param increaseAmount The amount by which to increase the total reward for the bucket (in PMX).
     * Adds specified amount to totalReward of the bucket. Initial value of totalReward is 0.
     * @param rewardPerDay The reward amount per day for the bucket.
     */
    function setupBucket(address bucket, Role role, uint256 increaseAmount, uint256 rewardPerDay) external;

    /**
     * @notice Allows the caller to withdraw PMX tokens from a specific bucket.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param bucket The address of the bucket from which to withdraw PMX tokens.
     * @param role The role associated with the bucket.
     * @param amount The amount of PMX tokens to withdraw.
     */
    function withdrawPmx(address bucket, Role role, uint256 amount) external;

    /**
     * @notice Decreases the reward per day for a bucket and role.
     * @dev Only callable by the EMERGENCY_ADMIN role.
     * @param bucket The address of the bucket for which to decrease the reward per day.
     * @param role The role associated with the bucket.
     * @param rewardPerDay The amount by which to decrease the reward per day.
     */
    function decreaseRewardPerDay(address bucket, Role role, uint256 rewardPerDay) external;

    /**
     * @notice Returns the accumulated reward for a specific bucket and role.
     * @param bucket The address of the bucket for which to retrieve the accumulated reward.
     * @param role The role associated with the bucket.
     * @return The accumulated reward for the specified bucket and role.
     */
    function getBucketAccumulatedReward(address bucket, Role role) external view returns (uint256);

    /**
     * @notice Returns the claimable reward for a user across multiple buckets.
     * @param bucketsArray The array of BucketWithRole objects containing the buckets to check for claimable rewards.
     * @param user The address of the user for whom to calculate the claimable reward.
     * @return The total claimable reward for the specified user across all provided buckets.
     */
    function getClaimableReward(BucketWithRole[] calldata bucketsArray, address user) external view returns (uint256);

    /**
     * @notice Retrieves the user information from a specific bucket and role.
     * @param bucket The address of the bucket from which to retrieve the user information.
     * @param role The role associated with the bucket.
     * @param user The address of the user for whom to retrieve the information.
     * @return A UserInfo struct containing the user information.
     */
    function getUserInfoFromBucket(address bucket, Role role, address user) external view returns (UserInfo memory);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";

interface IActivityRewardDistributorStorage {
    /*
     * @param oldBalance last updated balance for user
     * @param fixedReward the accumulated value of the reward at the time lastUpdatedRewardIndex
     * @param lastUpdatedRewardIndex last index with which the user's reward was accumulated
     */
    struct UserInfo {
        uint256 fixedReward;
        uint256 lastUpdatedRewardIndex;
        uint256 oldBalance;
    }

    /*
     * @param users data to calculate users rewards in this bucket
     * @param rewardIndex an index that accumulates user rewards
     * @param lastUpdatedTimestamp timestamp of the last update of user activity
     * @param rewardPerToken current reward for one token(PToken or DebtToken of bucket)
     * @param isFinished Shows that the bucket has distributed all the rewards
     * @param fixedReward reward distributed by a bucket over the past period
     * with a certain reward per day or with the entire reward fully distributed
     * @param lastUpdatedRewardTimestamp timestamp of last fixed reward update
     * @param rewardPerDay current reward distributed for 1 day
     * @param totalReward Full distributable reward
     * @param endTimestamp end time of the distribution of rewards, which is calculated relative to the rewardPerDay and totalReward
     */
    struct BucketInfo {
        mapping(address => UserInfo) users;
        //accumulated reward per token
        uint256 rewardIndex;
        uint256 lastUpdatedTimestamp;
        uint256 rewardPerToken;
        uint256 scaledTotalSupply;
        bool isFinished;
        // setted by admin's actions
        uint256 fixedReward;
        uint256 lastUpdatedRewardTimestamp;
        uint256 rewardPerDay;
        uint256 totalReward;
        uint256 endTimestamp;
    }

    function pmx() external returns (IERC20);

    function dns() external returns (IPrimexDNS);

    function registry() external returns (address);

    function traderBalanceVault() external returns (ITraderBalanceVault);

    function treasury() external view returns (address);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IFeeExecutorStorage} from "./IFeeExecutorStorage.sol";

interface IFeeExecutor is IFeeExecutorStorage {
    /**
     * @dev Sets tier bonuses for a specific bucket.
     * @param _bucket The address of the bucket.
     * @param _tiers The array of tier values.
     * @param _bonuses The array of NFT bonus parameters.
     */
    function setTierBonus(address _bucket, uint256[] calldata _tiers, NFTBonusParams[] calldata _bonuses) external;

    /**
     * @dev Updates the accumulatedAmount and the lastUpdatedIndex of the existing ActivatedBonus. Called by the Debt-Token
     * @param _user User for which the bonus will be updated. If user doesn't have the bonus for paused
     * @param _oldScaledBalance Balance of the user before the operation at which the updateBonus function was called (e.g mint/burn)
     * @param _bucket The Bucket to which the ActivatedBonus relates
     **/
    function updateBonus(address _user, uint256 _oldScaledBalance, address _bucket, uint256 _currentIndex) external;

    /**
     * @dev Updates the accumulatedAmount and the lastUpdatedIndex of the existing ActivatedBonus. Called directly by the user
     * @param _nftId Id of activated token
     **/
    function updateBonus(uint256 _nftId) external;

    /**
     * @dev Updates the accumulatedAmount and the lastUpdatedIndex of the existing ActivatedBonus. Called by the P-Token or Debt-Token
     * @param _users Array of the users for whom the bonus will be updated.
     * @param _oldBalances Array of the balances before the operation at which the updateBonus function was called (e.g mint/transfer)
     * @param _bucket The Bucket to which the ActivatedBonus relates
     **/
    function updateBonuses(
        address[] memory _users,
        uint256[] memory _oldBalances,
        address _bucket,
        uint256 _currentIndex
    ) external;

    /**
     * @dev Returns accumulated amount of p-tokens at the moment
     * @param _user The user for which the accumatedAmount will return. If the bonus does not exist will return 0.
     * If the NFT does not exist will throw an error
     * @param _nftId Id of activated token
     * @return The accumulated amount.
     */
    function getAccumulatedAmount(address _user, uint256 _nftId) external returns (uint256);

    /**
     * @dev Returns the available amount (accumulated - claimedAmount) of p-tokens at the moment.
     * @param _user The user for which the available amount will return. If the bonus does not exist will return 0.
     * If the NFT does not exist will throw an error
     * @param _nftId Id of activated token
     **/
    function getAvailableAmount(address _user, uint256 _nftId) external returns (uint256);

    /**
     * @dev Retrieves the bonus information for a user and NFT.
     * @param _user The address of the user.
     * @param _nftId The ID of the NFT.
     * @return bonus The activated bonus information.
     */
    function getBonus(address _user, uint256 _nftId) external view returns (ActivatedBonus memory);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IBucket} from "../Bucket/IBucket.sol";

interface IFeeExecutorStorage {
    struct ActivatedBonus {
        uint256 nftId;
        IBucket bucket;
        uint256 percent;
        uint256 maxAmount;
        uint256 accumulatedAmount;
        uint256 lastUpdatedIndex;
        uint256 deadline;
        //if we allow to claim funds before the end of the bonus
        uint256 claimedAmount;
    }

    struct NFTBonusParams {
        uint256 percent;
        uint256 maxAmount;
        uint256 duration;
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {WadRayMath} from "../libraries/utils/WadRayMath.sol";

import {TokenTransfersLibrary} from "../libraries/TokenTransfersLibrary.sol";

import "./BucketStorage.sol";
import {VAULT_ACCESS_ROLE, PM_ROLE, BATCH_MANAGER_ROLE, MAX_ASSET_DECIMALS, SECONDS_PER_YEAR} from "../Constants.sol";
import {BIG_TIMELOCK_ADMIN, MEDIUM_TIMELOCK_ADMIN, SMALL_TIMELOCK_ADMIN} from "../Constants.sol";
import {IBucket, IBucketV2} from "./IBucket.sol";

/* solhint-disable max-states-count */
contract Bucket is IBucketV2, BucketStorage {
    using WadRayMath for uint256;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    /**
     * @inheritdoc IBucket
     */
    function initialize(ConstructorParams calldata _params, address _registry) public override initializer {
        _require(
            IERC165Upgradeable(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165Upgradeable(address(_params.pToken)).supportsInterface(type(IPToken).interfaceId) &&
                IERC165Upgradeable(address(_params.dns)).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165Upgradeable(address(_params.debtToken)).supportsInterface(type(IDebtToken).interfaceId) &&
                IERC165Upgradeable(address(_params.positionManager)).supportsInterface(
                    type(IPositionManager).interfaceId
                ) &&
                IERC165Upgradeable(address(_params.priceOracle)).supportsInterface(type(IPriceOracle).interfaceId) &&
                IERC165Upgradeable(address(_params.reserve)).supportsInterface(type(IReserve).interfaceId) &&
                IERC165Upgradeable(address(_params.interestRateStrategy)).supportsInterface(
                    type(IInterestRateStrategy).interfaceId
                ) &&
                IERC165Upgradeable(address(_params.whiteBlackList)).supportsInterface(
                    type(IWhiteBlackList).interfaceId
                ),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        _require(
            _params.borrowedAsset.decimals() <= MAX_ASSET_DECIMALS,
            Errors.ASSET_DECIMALS_EXCEEDS_MAX_VALUE.selector
        );
        _require(_params.withdrawalFeeRate <= WadRayMath.WAD / 10, Errors.WITHDRAW_RATE_IS_MORE_10_PERCENT.selector);
        _require(
            _params.feeBuffer > WadRayMath.WAD && _params.feeBuffer < WadRayMath.WAD + WadRayMath.WAD / 100,
            Errors.INVALID_FEE_BUFFER.selector
        );
        _require(_params.reserveRate < WadRayMath.WAD, Errors.RESERVE_RATE_SHOULD_BE_LESS_THAN_1.selector);
        _require(_params.maxTotalDeposit > 0, Errors.MAX_TOTAL_DEPOSIT_IS_ZERO.selector);

        if (_params.liquidityMiningAmount == 0) {
            LMparams.isBucketLaunched = true;
            emit BucketLaunched();
        } else {
            _require(
                _params.liquidityMiningDeadline > block.timestamp &&
                    IERC165Upgradeable(address(_params.liquidityMiningRewardDistributor)).supportsInterface(
                        type(ILiquidityMiningRewardDistributor).interfaceId
                    ) &&
                    _params.maxAmountPerUser > 0,
                Errors.INCORRECT_LIQUIDITY_MINING_PARAMS.selector
            );
            LMparams.maxStabilizationEndTimestamp = _params.liquidityMiningDeadline + _params.stabilizationDuration;
            LMparams.maxDuration = LMparams.maxStabilizationEndTimestamp - block.timestamp;
            LMparams.liquidityMiningRewardDistributor = _params.liquidityMiningRewardDistributor;
            LMparams.accumulatingAmount = _params.liquidityMiningAmount;
            LMparams.deadlineTimestamp = _params.liquidityMiningDeadline;
            LMparams.stabilizationDuration = _params.stabilizationDuration;
            LMparams.maxAmountPerUser = _params.maxAmountPerUser;
            estimatedBar = _params.estimatedBar;
            estimatedLar = _params.estimatedLar;
            isReinvestToAaveEnabled = _params.isReinvestToAaveEnabled;
        }
        maxTotalDeposit = _params.maxTotalDeposit;
        _params.interestRateStrategy.setBarCalculationParams(_params.barCalcParams);
        name = _params.name;
        pToken = _params.pToken;
        dns = _params.dns;
        positionManager = _params.positionManager;
        priceOracle = _params.priceOracle;
        debtToken = _params.debtToken;
        reserve = _params.reserve;
        whiteBlackList = _params.whiteBlackList;
        borrowedAsset = _params.borrowedAsset;
        feeBuffer = _params.feeBuffer;
        withdrawalFeeRate = _params.withdrawalFeeRate;
        reserveRate = _params.reserveRate;

        for (uint256 i; i < _params.assets.length; i++) {
            _addAsset(_params.assets[i]);
        }
        registry = _registry;
        interestRateStrategy = _params.interestRateStrategy;
        liquidityIndex = 1e27;
        variableBorrowIndex = 1e27;
        __ReentrancyGuard_init();
        __ERC165_init();
    }

    /**
     * @inheritdoc IBucket
     */
    function addAsset(address _newAsset) external override {
        _onlyRole(MEDIUM_TIMELOCK_ADMIN);
        _addAsset(_newAsset);
    }

    /**
     * @inheritdoc IBucket
     */
    function removeAsset(address _assetToDelete) external override {
        _onlyRole(SMALL_TIMELOCK_ADMIN);
        Asset storage assetToDelete = allowedAssets[_assetToDelete];
        _require(assetToDelete.isSupported, Errors.ASSET_IS_NOT_SUPPORTED.selector);

        address assetToMove = assets[assets.length - 1];
        assets[assetToDelete.index] = assetToMove;
        assets.pop();

        allowedAssets[assetToMove].index = assetToDelete.index;
        delete allowedAssets[_assetToDelete];

        emit RemoveAsset(_assetToDelete);
    }

    function setBarCalculationParams(bytes calldata _params) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        interestRateStrategy.setBarCalculationParams(_params);
        emit BarCalculationParamsChanged(_params);
    }

    /**
     * @inheritdoc IBucket
     */
    function setReserveRate(uint256 _reserveRate) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(_reserveRate < WadRayMath.WAD, Errors.RESERVE_RATE_SHOULD_BE_LESS_THAN_1.selector);
        reserveRate = _reserveRate;
        emit ReserveRateChanged(_reserveRate);
    }

    /**
     * @inheritdoc IBucket
     */
    function setFeeBuffer(uint256 _feeBuffer) external override {
        _onlyRole(MEDIUM_TIMELOCK_ADMIN);
        _require(
            _feeBuffer > WadRayMath.WAD && _feeBuffer < WadRayMath.WAD + WadRayMath.WAD / 100,
            Errors.INVALID_FEE_BUFFER.selector
        );
        feeBuffer = _feeBuffer;
        emit FeeBufferChanged(_feeBuffer);
    }

    /**
     * @inheritdoc IBucket
     */
    function setWithdrawalFee(uint256 _withdrawalFeeRate) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(_withdrawalFeeRate <= WadRayMath.WAD / 10, Errors.WITHDRAW_RATE_IS_MORE_10_PERCENT.selector);
        withdrawalFeeRate = _withdrawalFeeRate;
        emit WithdrawalFeeChanged(_withdrawalFeeRate);
    }

    /**
     * @inheritdoc IBucket
     */
    function setInterestRateStrategy(address _interestRateStrategy) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(
            IERC165Upgradeable(_interestRateStrategy).supportsInterface(type(IInterestRateStrategy).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        interestRateStrategy = IInterestRateStrategy(_interestRateStrategy);
        emit InterestRateStrategyChanged(_interestRateStrategy);
    }

    /**
     * @inheritdoc IBucket
     */
    function setMaxTotalDeposit(uint256 _maxTotalDeposit) external override {
        _onlyRole(MEDIUM_TIMELOCK_ADMIN);
        _require(_maxTotalDeposit > 0, Errors.MAX_TOTAL_DEPOSIT_IS_ZERO.selector);
        maxTotalDeposit = _maxTotalDeposit;
        emit MaxTotalDepositChanged(_maxTotalDeposit);
    }

    /**
     * @inheritdoc IBucket
     */
    function deposit(address _pTokenReceiver, uint256 _amount) external override nonReentrant {
        deposit(_pTokenReceiver, _amount, true);
    }

    /**
     * @inheritdoc IBucketV2
     */
    function deposit(
        address _pTokenReceiver,
        uint256 _amount,
        bool _takeDepositFromWallet
    ) public override nonReentrant {
        _notBlackListed();
        _require(pToken.totalSupply() + _amount < maxTotalDeposit, Errors.DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT.selector);
        if (_takeDepositFromWallet) {
            TokenTransfersLibrary.doTransferIn(address(borrowedAsset), msg.sender, _amount);
        } else {
            positionManager.traderBalanceVault().withdrawFrom(
                msg.sender,
                address(this),
                address(borrowedAsset),
                _amount,
                false
            );
        }
        if (LMparams.isBucketLaunched) {
            _deposit(_pTokenReceiver, _amount);
        } else {
            _require(_pTokenReceiver == msg.sender, Errors.CALLER_IS_NOT_P_TOKEN_RECEIVER.selector);
            _depositLM(_pTokenReceiver, _amount);
        }
        emit Deposit(msg.sender, _pTokenReceiver, _amount);
    }

    /**
     * @inheritdoc IBucket
     */
    function withdrawAfterDelisting(uint256 _amount) external override {
        _onlyRole(BIG_TIMELOCK_ADMIN);
        _require(isWithdrawAfterDelistingAvailable(), Errors.WITHDRAWAL_NOT_ALLOWED.selector);
        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), dns.treasury(), _amount);
    }

    /**
     * @inheritdoc IBucket
     */
    function receiveDeposit(
        address _pTokenReceiver,
        uint256 _amount,
        uint256 _duration,
        string calldata _bucketFrom
    ) external override nonReentrant {
        _require(pToken.totalSupply() + _amount < maxTotalDeposit, Errors.DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT.selector);
        _require(dns.getBucketAddress(_bucketFrom) == msg.sender, Errors.FORBIDDEN.selector);
        if (LMparams.isBucketLaunched) {
            if (_duration > 0) pToken.lockDeposit(_pTokenReceiver, _deposit(_pTokenReceiver, _amount), _duration);
        } else {
            _depositLM(_pTokenReceiver, _amount);
        }
        emit Deposit(msg.sender, _pTokenReceiver, _amount);
    }

    /**
     * @inheritdoc IBucket
     */
    function depositFromBucket(
        string calldata _bucketTo,
        ISwapManager _swapManager,
        PrimexPricingLibrary.Route[] calldata routes,
        uint256 _amountOutMin
    ) external override nonReentrant {
        _notBlackListed();
        // don't need check that _bucketTo isn't this bucket name
        // tx will be reverted by ReentrancyGuard
        _require(
            !LMparams.isBucketLaunched && block.timestamp > LMparams.deadlineTimestamp,
            Errors.DEADLINE_IS_NOT_PASSED.selector
        );
        if (isReinvestToAaveEnabled && aaveDeposit > 0) {
            _withdrawBucketLiquidityFromAave();
        }
        IBucket receiverBucket = IBucket(dns.getBucketAddress(_bucketTo));

        LMparams.liquidityMiningRewardDistributor.reinvest(
            name,
            _bucketTo,
            msg.sender,
            receiverBucket.getLiquidityMiningParams().isBucketLaunched,
            LMparams.deadlineTimestamp
        );

        uint256 allUserBalance = pToken.burn(msg.sender, type(uint256).max, liquidityIndex);
        emit Withdraw(msg.sender, address(receiverBucket), allUserBalance);
        IERC20Metadata bucketToAsset = receiverBucket.borrowedAsset();
        if (bucketToAsset != borrowedAsset) {
            // Need this check that _swapManager is legit.
            // Without it, user can specify any address of _swapManager to withdraw their funds with an extra reward
            _require(
                IAccessControl(registry).hasRole(VAULT_ACCESS_ROLE, address(_swapManager)),
                Errors.FORBIDDEN.selector
            );
            borrowedAsset.approve(address(_swapManager), allUserBalance);
            allUserBalance = _swapManager.swap(
                ISwapManager.SwapParams({
                    tokenA: address(borrowedAsset),
                    tokenB: address(bucketToAsset),
                    amountTokenA: allUserBalance,
                    amountOutMin: _amountOutMin,
                    routes: routes,
                    receiver: address(receiverBucket),
                    deadline: block.timestamp,
                    isSwapFromWallet: true,
                    isSwapToWallet: true,
                    isSwapFeeInPmx: false,
                    payFeeFromWallet: false
                }),
                0,
                false
            );
        } else {
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), address(receiverBucket), allUserBalance);
        }

        receiverBucket.receiveDeposit(msg.sender, allUserBalance, LMparams.stabilizationDuration, name);
    }

    /**
     * @inheritdoc IBucket
     */
    function returnLiquidityFromAaveToBucket() external override {
        _onlyRole(SMALL_TIMELOCK_ADMIN);
        _withdrawBucketLiquidityFromAave();
    }

    /**
     * @inheritdoc IBucket
     */
    function withdraw(address _borrowAssetReceiver, uint256 _amount) external override nonReentrant {
        _notBlackListed();
        if (!LMparams.isBucketLaunched) {
            LMparams.liquidityMiningRewardDistributor.removePoints(name, msg.sender, _amount);
        } else if (block.timestamp < LMparams.stabilizationEndTimestamp) {
            _require(
                _amount <=
                    pToken.balanceOf(msg.sender) -
                        LMparams.liquidityMiningRewardDistributor.getLenderAmountInMining(name, msg.sender),
                Errors.MINING_AMOUNT_WITHDRAW_IS_LOCKED_ON_STABILIZATION_PERIOD.selector
            );
        }

        if (LMparams.isBucketLaunched) _updateIndexes();
        uint256 amountToWithdraw = pToken.burn(msg.sender, _amount, liquidityIndex);
        uint256 amountToLender = (WadRayMath.WAD - withdrawalFeeRate).wmul(amountToWithdraw);
        uint256 amountToTreasury = amountToWithdraw - amountToLender;
        if (!LMparams.isBucketLaunched && isReinvestToAaveEnabled && aaveDeposit > 0) {
            // if liquidity mining failed, take all tokens from aave during first withdraw from bucket
            if (block.timestamp > LMparams.deadlineTimestamp) {
                _withdrawBucketLiquidityFromAave();
            } else {
                // if liquidity mining is in progress, withdraw needed amount from aave
                address aavePool = dns.aavePool();
                IPool(aavePool).withdraw(address(borrowedAsset), amountToWithdraw, address(this));
                emit WithdrawFromAave(aavePool, amountToWithdraw);
                aaveDeposit -= amountToWithdraw;
            }
        }

        _require(
            amountToWithdraw <= borrowedAsset.balanceOf(address(this)),
            Errors.NOT_ENOUGH_LIQUIDITY_IN_THE_BUCKET.selector
        );

        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), dns.treasury(), amountToTreasury);
        emit TopUpTreasury(msg.sender, amountToTreasury);

        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _borrowAssetReceiver, amountToLender);
        if (LMparams.isBucketLaunched) _updateRates();

        emit Withdraw(msg.sender, _borrowAssetReceiver, amountToWithdraw);
    }

    /**
     * @inheritdoc IBucket
     */
    function increaseDebt(address _trader, uint256 _amount, address _to) external override {
        _onlyRole(PM_ROLE);
        _require(LMparams.isBucketLaunched, Errors.BUCKET_IS_NOT_LAUNCHED.selector);
        TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _to, _amount);
        _updateIndexes();
        debtToken.mint(_trader, _amount, variableBorrowIndex);
        _updateRates();
    }

    /**
     * @inheritdoc IBucket
     */
    function decreaseTraderDebt(
        address _trader,
        uint256 _debtToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount
    ) external override {
        _onlyRole(PM_ROLE);
        // don't need require on isBucketLaunched,
        // because if we can't openPosition in this bucket then we can't closePosition in this bucket
        if (_amountToReturn > 0) {
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _receiverOfAmountToReturn, _amountToReturn);
        }
        _updateIndexes();
        debtToken.burn(_trader, _debtToBurn, variableBorrowIndex);
        _updateRates();
        if (_permanentLossAmount > 0) {
            permanentLossScaled += _permanentLossAmount.rdiv(liquidityIndex);
        }
    }

    /**
     * @inheritdoc IBucket
     */
    function batchDecreaseTradersDebt(
        address[] calldata _traders,
        uint256[] calldata _debtsToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount,
        uint256 _length
    ) external override {
        _onlyRole(BATCH_MANAGER_ROLE);
        // don't need require on isBucketLaunched,
        // because if we can't openPosition in this bucket then we can't closePosition in this bucket
        if (_amountToReturn > 0) {
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), _receiverOfAmountToReturn, _amountToReturn);
        }
        _updateIndexes();
        debtToken.batchBurn(_traders, _debtsToBurn, variableBorrowIndex, _length);
        _updateRates();
        if (_permanentLossAmount > 0) {
            permanentLossScaled += _permanentLossAmount.rdiv(liquidityIndex);
        }
    }

    /**
     * @inheritdoc IBucket
     */
    function getLiquidityMiningParams() external view override returns (LiquidityMiningParams memory) {
        return LMparams;
    }

    /**
     * @inheritdoc IBucket
     */
    function isDeprecated() external view override returns (bool) {
        (, IPrimexDNSStorage.Status status, , ) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Deprecated;
    }

    /**
     * @inheritdoc IBucket
     */
    function isActive() external view override returns (bool) {
        (, IPrimexDNSStorage.Status status, , ) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Active;
    }

    /**
     * @inheritdoc IBucket
     */
    function isDelisted() external view override returns (bool) {
        (, IPrimexDNSStorage.Status status, uint256 delistingDeadline, ) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Deprecated && delistingDeadline < block.timestamp;
    }

    /**
     * @inheritdoc IBucket
     */
    function isBucketStable() external view override returns (bool) {
        return LMparams.isBucketLaunched && block.timestamp > LMparams.stabilizationEndTimestamp;
    }

    /**
     * @inheritdoc IBucket
     */
    function maxAssetLeverage(address _asset) external view override returns (uint256) {
        _require(allowedAssets[_asset].isSupported, Errors.ASSET_IS_NOT_SUPPORTED.selector);
        uint256 maintenanceBuffer = positionManager.maintenanceBuffer();
        //  The formula is:
        //  (WAD + maintenanceBuffer) feeBuffer /
        //  ((WAD + maintenanceBuffer) feeBuffer) -
        //  (WAD - securityBuffer) (WAD - pairPriceDropBA) (WAD - oracleTolerableLimitAB) (WAD - oracleTolerableLimitBA)
        return
            (WadRayMath.WAD + maintenanceBuffer).wmul(feeBuffer).wdiv(
                (WadRayMath.WAD + maintenanceBuffer).wmul(feeBuffer) -
                    (WadRayMath.WAD - positionManager.securityBuffer())
                        .wmul(WadRayMath.WAD - priceOracle.getPairPriceDrop(_asset, address(borrowedAsset)))
                        .wmul(WadRayMath.WAD - positionManager.getOracleTolerableLimit(address(borrowedAsset), _asset))
                        .wmul(WadRayMath.WAD - positionManager.getOracleTolerableLimit(_asset, address(borrowedAsset)))
            );
    }

    /**
     * @inheritdoc IBucket
     */
    function getNormalizedVariableDebt() external view override returns (uint256) {
        return _calculateCompoundedInterest(bar, lastUpdatedBlockTimestamp).rmul(variableBorrowIndex);
    }

    /**
     * @inheritdoc IBucket
     */
    function getAllowedAssets() external view override returns (address[] memory) {
        return assets;
    }

    /**
     * @inheritdoc IBucket
     */
    function paybackPermanentLoss(uint256 amount) public override nonReentrant {
        _notBlackListed();
        uint256 amountScaled = amount.rdiv(getNormalizedIncome());
        _require(amountScaled > 0, Errors.AMOUNT_SCALED_SHOULD_BE_GREATER_THAN_ZERO.selector);
        if (amountScaled > permanentLossScaled) {
            amountScaled = permanentLossScaled;
            amount = permanentLoss();
        }
        unchecked {
            permanentLossScaled -= amountScaled;
        }
        pToken.burn(msg.sender, amount, getNormalizedIncome());
    }

    /**
     * @inheritdoc IBucket
     */
    function isWithdrawAfterDelistingAvailable() public view override returns (bool) {
        (, IPrimexDNSStorage.Status status, , uint256 adminDeadline) = dns.buckets(name);
        return status == IPrimexDNSStorage.Status.Deprecated && adminDeadline < block.timestamp;
    }

    /**
     * @inheritdoc IBucket
     */
    function permanentLoss() public view override returns (uint256) {
        return permanentLossScaled.rmul(getNormalizedIncome());
    }

    /**
     * @inheritdoc IBucket
     */
    function getNormalizedIncome() public view override returns (uint256) {
        return _calculateLinearInterest(lar, lastUpdatedBlockTimestamp).rmul(liquidityIndex);
    }

    /**
     * @inheritdoc IBucket
     */
    function availableLiquidity() public view override returns (uint256) {
        return borrowedAsset.balanceOf(address(this)) + aaveDeposit;
    }

    /// @notice Interface checker
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IBucketV2).interfaceId ||
            _interfaceId == type(IBucket).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Internal function to deposit funds into the bucket.
     * @param _pTokenReceiver The address to receive the pTokens.
     * @param _amount The amount of funds to deposit.
     * @return _mintedAmount The amount of pTokens minted during deposit
     */
    function _deposit(address _pTokenReceiver, uint256 _amount) internal returns (uint256 _mintedAmount) {
        // launched phase
        // here it's also checked that the bucket is active
        _require(dns.getBucketAddress(name) == address(this), Errors.BUCKET_OUTSIDE_PRIMEX_PROTOCOL.selector);
        _updateIndexes();
        _mintedAmount = pToken.mint(_pTokenReceiver, _amount, liquidityIndex);
        _updateRates();
    }

    /**
     * @notice Internal function for depositing during liquidity mining period.
     * @param _pTokenReceiver The address of the receiver of the pToken.
     * @param _amount The amount of tokens to be deposited.
     */
    function _depositLM(address _pTokenReceiver, uint256 _amount) internal {
        // liquidity mining phase
        _require(block.timestamp <= LMparams.deadlineTimestamp, Errors.DEADLINE_IS_PASSED.selector);

        uint256 _availableLiquidityBeforeTransfer = availableLiquidity() - _amount;

        // we don't need update rates and indexes because
        // they're zero and 1 ray accordingly while no one borrow
        pToken.mint(_pTokenReceiver, _amount, liquidityIndex);

        if (_availableLiquidityBeforeTransfer >= LMparams.accumulatingAmount) {
            _launchBucket();
            return;
        }
        uint256 tokensLeft = LMparams.accumulatingAmount - _availableLiquidityBeforeTransfer;
        uint256 miningAmount;
        if (tokensLeft > _amount) {
            miningAmount = _amount;
            if (isReinvestToAaveEnabled) {
                uint256 bucketBalance = borrowedAsset.balanceOf(address(this));
                aaveDeposit += bucketBalance;
                address aavePool = dns.aavePool();
                borrowedAsset.approve(aavePool, bucketBalance);
                IPool(aavePool).supply(address(borrowedAsset), bucketBalance, address(this), 0);
                emit DepositToAave(aavePool, bucketBalance);
            }
        } else {
            miningAmount = tokensLeft;
            _launchBucket();
        }

        _require(
            LMparams.liquidityMiningRewardDistributor.getLenderAmountInMining(name, _pTokenReceiver) + miningAmount <=
                LMparams.maxAmountPerUser,
            Errors.DEPOSIT_IS_MORE_AMOUNT_PER_USER.selector
        );

        // save lender activity for future reward distribution
        LMparams.liquidityMiningRewardDistributor.addPoints(
            name,
            _pTokenReceiver,
            miningAmount,
            LMparams.maxStabilizationEndTimestamp,
            LMparams.maxDuration,
            block.timestamp
        );
    }

    /**
     * @dev Updates the liquidityIndex and variableBorrowIndex
     */
    function _updateIndexes() internal {
        uint256 newLiquidityIndex = _calculateLinearInterest(lar, lastUpdatedBlockTimestamp).rmul(liquidityIndex);
        _require(newLiquidityIndex <= type(uint128).max, Errors.LIQUIDITY_INDEX_OVERFLOW.selector);
        liquidityIndex = uint128(newLiquidityIndex);

        uint256 newVariableBorrowIndex = _calculateCompoundedInterest(bar, lastUpdatedBlockTimestamp).rmul(
            variableBorrowIndex
        );
        _require(newVariableBorrowIndex <= type(uint128).max, Errors.BORROW_INDEX_OVERFLOW.selector);
        uint256 previousVariableBorrowIndex = variableBorrowIndex;
        variableBorrowIndex = uint128(newVariableBorrowIndex);

        lastUpdatedBlockTimestamp = block.timestamp;
        _mintToReserve(debtToken.scaledTotalSupply(), previousVariableBorrowIndex, variableBorrowIndex);
    }

    /**
     * @dev Mints portion of the interest that goes to the Primex Reserve
     */
    function _mintToReserve(
        uint256 _scaledVariableDebt,
        uint256 _previousVariableBorrowIndex,
        uint256 _newVariableBorrowIndex
    ) internal {
        if (reserveRate == 0) {
            return;
        }
        // debt accrued is the current debt minus the debt at the last update
        // percentage multiplied
        pToken.mintToReserve(
            address(reserve),
            (_scaledVariableDebt.rmul(_newVariableBorrowIndex) - _scaledVariableDebt.rmul(_previousVariableBorrowIndex))
                .wmul(reserveRate),
            liquidityIndex
        );
    }

    /**
     * @notice Internal function to set the isBucketLaunched flag to true.
     * Set the stabilizationPeriodEnd timestamp.
     * If investment is enabled withdraw all liquidity from Aave.
     */

    function _launchBucket() internal {
        LMparams.isBucketLaunched = true;
        LMparams.stabilizationEndTimestamp = block.timestamp + LMparams.stabilizationDuration;
        if (isReinvestToAaveEnabled) {
            _withdrawBucketLiquidityFromAave();
        }
        emit BucketLaunched();
    }

    /**
     * @notice Internal function to withdraw all liquidity from Aave
     */
    function _withdrawBucketLiquidityFromAave() internal {
        address aavePool = dns.aavePool();
        uint256 aaveBalance = IAToken(IPool(aavePool).getReserveData(address(borrowedAsset)).aTokenAddress).balanceOf(
            address(this)
        );
        isReinvestToAaveEnabled = false;
        if (aaveBalance == 0) return;

        IPool(aavePool).withdraw(address(borrowedAsset), type(uint256).max, address(this));
        emit WithdrawFromAave(aavePool, aaveBalance);

        // if there is earned interest, withdraw it to treasury
        if (aaveBalance > aaveDeposit) {
            uint256 interest = aaveBalance - aaveDeposit;
            TokenTransfersLibrary.doTransferOut(address(borrowedAsset), dns.treasury(), interest);
            emit TopUpTreasury(aavePool, interest);
        }
        aaveDeposit = 0;
    }

    /**
     * @dev Updates bucket's BAR and LAR.
     */
    function _updateRates() internal {
        uint256 totalDemand = debtToken.totalSupply();
        uint256 totalDeposit = availableLiquidity() + totalDemand;
        if (totalDeposit == 0) {
            bar = 0;
            lar = 0;
        } else {
            (bar, lar) = interestRateStrategy.calculateInterestRates(totalDemand.rdiv(totalDeposit), reserveRate);
        }
        emit RatesIndexesUpdated(bar, lar, variableBorrowIndex, liquidityIndex, block.timestamp);
    }

    /**
     * @dev Internal function to add a new asset to the allowed assets list.
     * @param _newAsset The address of the new asset to be added.
     */
    function _addAsset(address _newAsset) internal {
        _require(_newAsset != address(0), Errors.CAN_NOT_ADD_WITH_ZERO_ADDRESS.selector);
        _require(!allowedAssets[_newAsset].isSupported, Errors.ASSET_ALREADY_SUPPORTED.selector);
        _require(
            IERC20Metadata(_newAsset).decimals() <= MAX_ASSET_DECIMALS,
            Errors.ASSET_DECIMALS_EXCEEDS_MAX_VALUE.selector
        );
        _require(
            priceOracle.pairPriceDrops(_newAsset, address(borrowedAsset)) > 0,
            Errors.PAIR_PRICE_DROP_IS_NOT_CORRECT.selector
        );
        // Check that both the new asset and the borrowed asset have oracle price feeds available
        priceOracle.getPriceFeedsPair(_newAsset, address(borrowedAsset));
        assets.push(_newAsset);
        allowedAssets[_newAsset] = Asset(assets.length - 1, true);
        emit AddAsset(_newAsset);
    }

    /**
     * @dev Calculates the accumulated interest per blocks delta
     * @param _rate The interest rate (in ray)
     * @param _lastUpdatedBlockTimestamp The block timestamp of the last update of interest rate
     * @return The interest rate accumulated during the secondsDelta (in ray)
     */
    function _calculateLinearInterest(
        uint256 _rate,
        uint256 _lastUpdatedBlockTimestamp
    ) internal view returns (uint256) {
        uint256 secondsDelta = block.timestamp - _lastUpdatedBlockTimestamp;
        return (_rate * secondsDelta) / SECONDS_PER_YEAR + WadRayMath.RAY;
    }

    /**
     * @dev Calculates borrow interest using compounded interest formula
     * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
     * (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
     * @param _bar Borrowing annual rate (originally APR) (in ray)
     * @param _blockTimestamp The block timestamp of the last update of borrow rate
     * @return The borrow interest rate compounded during the secondsDelta (in ray)
     */
    function _calculateCompoundedInterest(uint256 _bar, uint256 _blockTimestamp) internal view returns (uint256) {
        uint256 exp = block.timestamp - _blockTimestamp;

        if (exp == 0) {
            return WadRayMath.RAY;
        }

        uint256 expMinusOne = exp - 1;
        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;
        // multiply first to mitigate rounding related issues
        uint256 basePowerTwo = _bar.rmul(_bar) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR);
        uint256 basePowerThree = _bar.rmul(_bar).rmul(_bar) / (SECONDS_PER_YEAR * SECONDS_PER_YEAR * SECONDS_PER_YEAR);

        uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
        uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

        return WadRayMath.RAY + (_bar * exp) / SECONDS_PER_YEAR + secondTerm + thirdTerm;
    }

    /**
     * @dev Function that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    function _onlyRole(bytes32 _role) internal view {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
    }

    /**
     * @dev Function that checks if the sender is not blacklisted.
     */
    function _notBlackListed() internal view {
        _require(!whiteBlackList.isBlackListed(msg.sender), Errors.SENDER_IS_BLACKLISTED.selector);
    }
}
/* solhint-enable max-states-count */

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IAToken} from "@aave/core-v3/contracts/interfaces/IAToken.sol";

import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";
import "../libraries/Errors.sol";

import {IWhiteBlackList} from "../WhiteBlackList/WhiteBlackList/IWhiteBlackList.sol";
import {IBucketStorage} from "./IBucketStorage.sol";
import {IPToken} from "../PToken/IPToken.sol";
import {IDebtToken} from "../DebtToken/IDebtToken.sol";
import {IPositionManager} from "../PositionManager/IPositionManager.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IPrimexDNSStorage} from "../PrimexDNS/IPrimexDNSStorage.sol";
import {IReserve} from "../Reserve/IReserve.sol";
import {IInterestRateStrategy} from "../interfaces/IInterestRateStrategy.sol";
import {ISwapManager} from "../interfaces/ISwapManager.sol";
import {ILiquidityMiningRewardDistributor} from "../LiquidityMiningRewardDistributor/ILiquidityMiningRewardDistributor.sol";

abstract contract BucketStorage is IBucketStorage, ReentrancyGuardUpgradeable, ERC165Upgradeable {
    string public override name;
    address public override registry;
    IPositionManager public override positionManager;
    IReserve public override reserve;
    IPToken public override pToken;
    IDebtToken public override debtToken;
    IERC20Metadata public override borrowedAsset;
    uint256 public override feeBuffer;
    // The current borrow rate, expressed in ray. bar = borrowing annual rate (originally APR)
    uint128 public override bar;
    // The current interest rate, expressed in ray. lar = lending annual rate (originally APY)
    uint128 public override lar;
    // The estimated borrowing annual rate, expressed in ray
    uint128 public override estimatedBar;
    // The estimated lending annual rate, expressed in ray
    uint128 public override estimatedLar;
    uint128 public override liquidityIndex;
    uint128 public override variableBorrowIndex;
    // block where indexes were updated
    uint256 public lastUpdatedBlockTimestamp;
    uint256 public override permanentLossScaled;
    uint256 public reserveRate;
    uint256 public override withdrawalFeeRate;
    IWhiteBlackList public override whiteBlackList;
    mapping(address => Asset) public override allowedAssets;
    IInterestRateStrategy public interestRateStrategy;
    uint256 public aaveDeposit;
    bool public isReinvestToAaveEnabled;
    uint256 public override maxTotalDeposit;
    address[] internal assets;
    // solhint-disable-next-line var-name-mixedcase
    LiquidityMiningParams internal LMparams;
    IPrimexDNS internal dns;
    IPriceOracle internal priceOracle;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";

import {IPToken} from "../PToken/IPToken.sol";
import {IDebtToken} from "../DebtToken/IDebtToken.sol";
import {IPositionManager} from "../PositionManager/IPositionManager.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IWhiteBlackList} from "../WhiteBlackList/WhiteBlackList/IWhiteBlackList.sol";
import {IReserve} from "../Reserve/IReserve.sol";
import {ILiquidityMiningRewardDistributor} from "../LiquidityMiningRewardDistributor/ILiquidityMiningRewardDistributor.sol";
import {IInterestRateStrategy} from "../interfaces/IInterestRateStrategy.sol";
import {ISwapManager} from "../interfaces/ISwapManager.sol";
import {IBucketStorage} from "./IBucketStorage.sol";

interface IBucket is IBucketStorage {
    struct ConstructorParams {
        string name;
        IPToken pToken;
        IDebtToken debtToken;
        IPositionManager positionManager;
        IPriceOracle priceOracle;
        IPrimexDNS dns;
        IReserve reserve;
        IWhiteBlackList whiteBlackList;
        address[] assets;
        IERC20Metadata borrowedAsset;
        uint256 feeBuffer;
        uint256 withdrawalFeeRate;
        uint256 reserveRate;
        // liquidityMining params
        ILiquidityMiningRewardDistributor liquidityMiningRewardDistributor;
        uint256 liquidityMiningAmount;
        uint256 liquidityMiningDeadline;
        uint256 stabilizationDuration;
        IInterestRateStrategy interestRateStrategy;
        uint128 estimatedBar;
        uint128 estimatedLar;
        uint256 maxAmountPerUser;
        bool isReinvestToAaveEnabled;
        bytes barCalcParams;
        uint256 maxTotalDeposit;
    }

    event Deposit(address indexed depositer, address indexed pTokenReceiver, uint256 amount);

    event Withdraw(address indexed withdrawer, address indexed borrowAssetReceiver, uint256 amount);

    event DepositToAave(address indexed pool, uint256 amount);

    event WithdrawFromAave(address indexed pool, uint256 amount);

    event TopUpTreasury(address indexed sender, uint256 amount);

    event FeeBufferChanged(uint256 feeBuffer);

    event ReserveRateChanged(uint256 reserveRate);

    event RatesIndexesUpdated(
        uint128 bar,
        uint128 lar,
        uint128 variableBorrowIndex,
        uint128 liquidityIndex,
        uint256 timestamp
    );

    event WithdrawalFeeChanged(uint256 withdrawalFeeRate);

    event InterestRateStrategyChanged(address interestRateStrategy);

    event AddAsset(address addedAsset);

    event RemoveAsset(address deletedAsset);

    event MaxTotalDepositChanged(uint256 maxTotalDeposit);

    event BarCalculationParamsChanged(bytes params);

    event BucketLaunched();

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _params The ConstructorParams struct containing initialization parameters.
     * @param _registry The address of the registry contract.
     */
    function initialize(ConstructorParams memory _params, address _registry) external;

    /**
     * @dev Function to add new trading asset for this bucket
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _newAsset The address of trading asset
     */
    function addAsset(address _newAsset) external;

    /**
     * @notice Removes a trading asset from this bucket.
     * @dev Only callable by the SMALL_TIMELOCK_ADMIN role.
     * @param _assetToDelete The address of the asset to be removed.
     */
    function removeAsset(address _assetToDelete) external;

    function setBarCalculationParams(bytes memory _params) external;

    /**
     * @dev Sets the reserve rate.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _reserveRate The new reserve rate value.
     */
    function setReserveRate(uint256 _reserveRate) external;

    /**
     * @dev Sets the new fee buffer.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _feeBuffer The new fee buffer value.
     */
    function setFeeBuffer(uint256 _feeBuffer) external;

    /**
     * @dev Sets the withdrawal fee.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _withdrawalFee The new withdrawal fee value.
     */
    function setWithdrawalFee(uint256 _withdrawalFee) external;

    /**
     * @dev Sets the interest rate strategy contract address.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _interestRateStrategy The address of the interest rate strategy contract.
     */
    function setInterestRateStrategy(address _interestRateStrategy) external;

    /**
     * @notice The function sets the max total deposit for the particular bucket
     * @param _maxTotalDeposit The amount of max total deposit for the bucket
     */
    function setMaxTotalDeposit(uint256 _maxTotalDeposit) external;

    /**
     * @dev Deposits the 'amount' of underlying asset into the bucket. The 'PTokenReceiver' receives overlying pTokens.
     * @param _pTokenReceiver The address to receive the deposited pTokens.
     * @param _amount The amount of underlying tokens to be deposited
     */
    function deposit(address _pTokenReceiver, uint256 _amount) external;

    /**
     * @dev Withdraws the 'amount' of underlying asset from the bucket. The 'amount' of overlying pTokens will be burned.
     * @param _borrowAssetReceiver The address of receiver of the borrowed asset.
     * @param amount The amount of underlying tokens to be withdrawn.
     */
    function withdraw(address _borrowAssetReceiver, uint256 amount) external;

    /**
     * @notice Allows the BIG_TIMELOCK_ADMIN role to withdraw a specified amount of tokens after delisting.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawAfterDelisting(uint256 _amount) external;

    /**
     * @dev Receives a deposit and distributes it to the specified pToken receiver.
     * @dev Can be called only by another bucket.
     * @param _pTokenReceiver The address of the recipient of the pToken.
     * @param _amount The amount of tokens being deposited.
     * @param _duration The blocking time for a fixed-term deposit (if it's 0, then it will be a usual deposit)
     * @param _bucketFrom The name of the bucket from which the deposit is being made.
     */
    function receiveDeposit(
        address _pTokenReceiver,
        uint256 _amount,
        uint256 _duration,
        string memory _bucketFrom
    ) external;

    /**
     * @notice Deposits (reinvests) funds from a bucket to another bucket.
     * Used only in the case of failed liquidity mining in the bucket from where the transfer happens.
     * @param _bucketTo The name of the destination bucket.
     * @param _swapManager The address of the swap manager.
     * @param routes The array of routes for swapping tokens.
     * @param _amountOutMin The minimum amount of tokens to receive from the swap.
     */
    function depositFromBucket(
        string calldata _bucketTo,
        ISwapManager _swapManager,
        PrimexPricingLibrary.Route[] calldata routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @dev Allows the SMALL_TIMELOCK_ADMIN to withdraw all liquidity from Aave to Bucket.
     */
    function returnLiquidityFromAaveToBucket() external;

    /**
     * @dev Function to update rates and indexes when a trader opens a trading position.
     * Mints debt tokens to trader. Calls only by positionManager contract.
     * @param _trader The address of the trader, who opens position.
     * @param _amount The 'amount' for which the deal is open, and 'amount' of debtTokens will be minted to the trader.
     * @param _to The address to transfer the borrowed asset to.
     */

    function increaseDebt(address _trader, uint256 _amount, address _to) external;

    /**
     * @dev Function to update rates and indexes.
     * Burns debt tokens of trader. Called only by positionManager contract.
     * @param _trader The address of the trader, who opened position.
     * @param _debtToBurn The 'amount' of trader's debtTokens will be burned by the trader.
     * @param _receiverOfAmountToReturn Treasury in case of liquidation. TraderBalanceVault in other cases
     * @param _amountToReturn Amount to transfer from bucket
     * @param _permanentLossAmount The amount of the protocol's debt to creditors accrued for this position
     */
    function decreaseTraderDebt(
        address _trader,
        uint256 _debtToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount
    ) external;

    /**
     * @notice Batch decreases the debt of multiple traders.
     * @dev This function can only be called by the BATCH_MANAGER_ROLE.
     * @param _traders An array of addresses representing the traders.
     * @param _debtsToBurn An array of uint256 values representing the debts to burn for each trader.
     * @param _receiverOfAmountToReturn The address that will receive the amount to be returned.
     * @param _amountToReturn The amount to be returned.
     * @param _permanentLossAmount The amount of permanent loss.
     * @param _length The length of the traders array.
     */
    function batchDecreaseTradersDebt(
        address[] memory _traders,
        uint256[] memory _debtsToBurn,
        address _receiverOfAmountToReturn,
        uint256 _amountToReturn,
        uint256 _permanentLossAmount,
        uint256 _length
    ) external;

    /**
     * @notice This function allows a user to pay back a permanent loss by burning his pTokens.
     * @param amount The amount of pTokens to be burned to pay back the permanent loss.
     */
    function paybackPermanentLoss(uint256 amount) external;

    /**
     * @dev Calculates the permanent loss based on the scaled permanent loss and the normalized income.
     * @return The amount of permanent loss.
     */
    function permanentLoss() external view returns (uint256);

    /**
     * @dev Checks if the bucket is deprecated in the protocol.
     * @return Whether the bucket is deprecated or not.
     */
    function isDeprecated() external view returns (bool);

    /**
     * @dev Returns a boolean value indicating whether the bucket is delisted.
     * @return True if the bucket is delisted, otherwise false.
     */
    function isDelisted() external view returns (bool);

    /**
     * @dev Checks if an admin can withdraw from the bucket after delisting.
     * @return A boolean indicating whether withdrawal is available.
     */
    function isWithdrawAfterDelistingAvailable() external view returns (bool);

    /**
     * @dev Checks if this bucket is active in the protocol.
     * @return bool True if the bucket is active, false otherwise.
     */
    function isActive() external view returns (bool);

    /**
     * @dev Returns the parameters for liquidity mining.
     * @return LMparams The liquidity mining parameters.
     */
    function getLiquidityMiningParams() external view returns (LiquidityMiningParams memory);

    /**
     * @dev Returns a boolean value indicating whether the bucket is stable in the liquidity mining event.
     * @return A boolean value representing the stability of the bucket.
     */
    function isBucketStable() external view returns (bool);

    /**
     * @dev Calculates the max leverage according to the following formula:
     * ((1 + maintenanceBuffer) * feeBuffer) / ((1 + maintenanceBuffer) * feeBuffer - (1 - securityBuffer) *
     * (1 - pairPriceDropBA) * (1 - oracleTolerableLimitAB) * (1 - oracleTolerableLimitBA))
     * @param _asset The address of trading asset
     * @return The maximum leverage as a uint256 value.
     */
    function maxAssetLeverage(address _asset) external view returns (uint256);

    /**
     * @dev Returns the normalized income per unit of underlying asset, expressed in ray
     * @return The normalized income per unit of underlying asset, expressed in ray
     */
    function getNormalizedIncome() external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of underlying asset, expressed in ray
     */
    function getNormalizedVariableDebt() external view returns (uint256);

    /**
     * @dev Returns allowed trading assets for current bucket
     * @return List of addresses of allowed assets
     */
    function getAllowedAssets() external view returns (address[] memory);

    /**
     * @dev Returns current avalable liquidity of borrowedAsset for trading.
     * @return The amount of available borrowedAsset
     */
    function availableLiquidity() external view returns (uint256);
}

interface IBucketV2 is IBucket {
    /**
     * @dev Deposits the 'amount' of underlying asset into the bucket. The 'PTokenReceiver' receives overlying pTokens.
     * @param _pTokenReceiver The address to receive the deposited pTokens.
     * @param _amount The amount of underlying tokens to be deposited
     * @param _takeDepositFromWallet A flag indicating whether to make the deposit from user wallet
     */
    function deposit(address _pTokenReceiver, uint256 _amount, bool _takeDepositFromWallet) external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IPToken} from "../PToken/IPToken.sol";
import {IDebtToken} from "../DebtToken/IDebtToken.sol";
import {IPositionManager} from "../PositionManager/IPositionManager.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IReserve} from "../Reserve/IReserve.sol";
import {ILiquidityMiningRewardDistributor} from "../LiquidityMiningRewardDistributor/ILiquidityMiningRewardDistributor.sol";
import {IWhiteBlackList} from "../WhiteBlackList/WhiteBlackList/IWhiteBlackList.sol";
import {IInterestRateStrategy} from "../interfaces/IInterestRateStrategy.sol";

interface IBucketStorage {
    /**
     * @dev Parameters of liquidity mining
     */
    struct LiquidityMiningParams {
        ILiquidityMiningRewardDistributor liquidityMiningRewardDistributor;
        bool isBucketLaunched;
        uint256 accumulatingAmount;
        uint256 deadlineTimestamp;
        uint256 stabilizationDuration;
        uint256 stabilizationEndTimestamp;
        uint256 maxAmountPerUser; // if maxAmountPerUser is >= accumulatingAmount then check on maxAmountPerUser is off
        // Constant max variables are used for calculating users' points.
        // These intervals are used for fair distribution of points among Lenders.
        // Lenders who brought liquidity earlier receive more than the ones who deposited later.
        // To get maximum points per token, a Lender should deposit immediately after the Bucket deployment.
        uint256 maxDuration;
        uint256 maxStabilizationEndTimestamp;
    }
    //                                        1. Corner case of bucket launch
    //
    //                                              maxDuration
    //       ------------------------------------------------------------------------------------------------
    //      |                                                                                               |
    //      |                                                                        stabilizationDuration  |
    //      |                                                                      -------------------------|
    //      |                                                                     | bucket launch           |
    //   +--+---------------------------------------------------------------------+-------------------------+------> time
    //      bucket deploy                                                         deadlineTimestamp         maxStabilizationEndTimestamp
    //                                                                                                       (=stabilizationEndTimestamp here)
    //                                  (corner case of bucket launch)

    //                                        2. One of cases of bucket launch
    //
    //      |                     stabilizationDuration
    //      |                   -------------------------
    //      |                  |                         |
    //   +--+------------------+-------------------------+------------------------+-------------------------+------> time
    //      bucket deploy      bucket launch            stabilizationEndTimestamp  deadlineTimestamp        maxStabilizationEndTimestamp
    //                                                                            (after deadline bucket can't be launched)

    struct Asset {
        uint256 index;
        bool isSupported;
    }

    function liquidityIndex() external returns (uint128);

    function variableBorrowIndex() external returns (uint128);

    function name() external view returns (string memory);

    function registry() external view returns (address);

    function positionManager() external view returns (IPositionManager);

    function reserve() external view returns (IReserve);

    function permanentLossScaled() external view returns (uint256);

    function pToken() external view returns (IPToken);

    function debtToken() external view returns (IDebtToken);

    function borrowedAsset() external view returns (IERC20Metadata);

    function feeBuffer() external view returns (uint256);

    function withdrawalFeeRate() external view returns (uint256);

    /**
     * @notice bar = borrowing annual rate (originally APR)
     */
    function bar() external view returns (uint128);

    /**
     * @notice lar = lending annual rate (originally APY)
     */
    function lar() external view returns (uint128);

    function interestRateStrategy() external view returns (IInterestRateStrategy);

    function estimatedBar() external view returns (uint128);

    function estimatedLar() external view returns (uint128);

    function allowedAssets(address _asset) external view returns (uint256, bool);

    function whiteBlackList() external view returns (IWhiteBlackList);

    function maxTotalDeposit() external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// admin roles
bytes32 constant BIG_TIMELOCK_ADMIN = 0x00; // It's primary admin.
bytes32 constant MEDIUM_TIMELOCK_ADMIN = keccak256("MEDIUM_TIMELOCK_ADMIN");
bytes32 constant SMALL_TIMELOCK_ADMIN = keccak256("SMALL_TIMELOCK_ADMIN");
bytes32 constant EMERGENCY_ADMIN = keccak256("EMERGENCY_ADMIN");
bytes32 constant GUARDIAN_ADMIN = keccak256("GUARDIAN_ADMIN");
bytes32 constant NFT_MINTER = keccak256("NFT_MINTER");
bytes32 constant TRUSTED_TOLERABLE_LIMIT_ROLE = keccak256("TRUSTED_TOLERABLE_LIMIT_ROLE");

// inter-contract interactions roles
bytes32 constant NO_FEE_ROLE = keccak256("NO_FEE_ROLE");
bytes32 constant VAULT_ACCESS_ROLE = keccak256("VAULT_ACCESS_ROLE");
bytes32 constant PM_ROLE = keccak256("PM_ROLE");
bytes32 constant LOM_ROLE = keccak256("LOM_ROLE");
bytes32 constant BATCH_MANAGER_ROLE = keccak256("BATCH_MANAGER_ROLE");

// token constants
address constant NATIVE_CURRENCY = address(uint160(bytes20(keccak256("NATIVE_CURRENCY"))));
address constant USD = 0x0000000000000000000000000000000000000348;
uint256 constant USD_MULTIPLIER = 10 ** (18 - 8); // usd decimals in chainlink is 8
uint8 constant MAX_ASSET_DECIMALS = 18;

// time constants
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_DAY = 1 days;
uint256 constant HOUR = 1 hours;
uint256 constant TEN_WAD = 10 ether;

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import {IDebtTokenStorage, IBucket, IFeeExecutor, IERC20Upgradeable, IActivityRewardDistributor} from "./IDebtTokenStorage.sol";

interface IDebtToken is IDebtTokenStorage {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     **/
    event Mint(address indexed from, uint256 value);

    /**
     * @dev Emitted after DebtTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param value The amount being burned
     **/
    event Burn(address indexed from, uint256 value);

    /**
     * @dev contract initializer
     * @param _name The name of the ERC20 token.
     * @param _symbol The symbol of the ERC20 token.
     * @param _decimals The number of decimals for the ERC20 token.
     * @param _bucketsFactory Address of the buckets factory that will call the setBucket fucntion
     */
    function initialize(string memory _name, string memory _symbol, uint8 _decimals, address _bucketsFactory) external;

    /**
     * @dev Sets the bucket for the contract.
     * @param _bucket The address of the bucket to set.
     */
    function setBucket(IBucket _bucket) external;

    /**
     * @dev Sets the FeeDecreaser for current DebtToken.
     * @param _feeDecreaser The interest increaser address.
     */
    function setFeeDecreaser(IFeeExecutor _feeDecreaser) external;

    /**
     * @dev Sets the trader reward distributor contract address.
     * @param _traderRewardDistributor The address of the trader reward distributor contract.
     * Only the BIG_TIMELOCK_ADMIN role can call this function.
     */
    function setTraderRewardDistributor(IActivityRewardDistributor _traderRewardDistributor) external;

    /**
     * @dev Mints `amount` DebtTokens to `user`
     * @param _user The address receiving the minted tokens
     * @param _amount The amount of tokens getting minted
     * @param _index The current variableBorrowIndex
     */
    function mint(address _user, uint256 _amount, uint256 _index) external;

    /**
     * @dev Burns DebtTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param _user The owner of the DebtTokens, getting them burned
     * @param _amount The amount being burned
     * @param _index The current variableBorrowIndex
     **/
    function burn(address _user, uint256 _amount, uint256 _index) external;

    /**
     * @dev Burns a batch of tokens from multiple users.
     * @param _users An array of user addresses whose tokens will be burned.
     * @param _amounts An array of token amounts to be burned for each user.
     * @param _index The index used to calculate the scaled amounts.
     * @param _length The length of the user and amounts arrays.
     */
    function batchBurn(address[] memory _users, uint256[] memory _amounts, uint256 _index, uint256 _length) external;

    /**
     * @dev Returns the principal debt balance of the user
     * @param _user The address of the user.
     * @return The scaled balance of the user.
     */
    function scaledBalanceOf(address _user) external view returns (uint256);

    /**
     * @dev Returns the scaled total supply of debtToken.
     * @return The scaled total supply of the debtToken.
     */
    function scaledTotalSupply() external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IBucket} from "../Bucket/IBucket.sol";
import {IFeeExecutor} from "../BonusExecutor/IFeeExecutor.sol";
import {IActivityRewardDistributor} from "../ActivityRewardDistributor/IActivityRewardDistributor.sol";

interface IDebtTokenStorage is IERC20Upgradeable {
    function bucket() external view returns (IBucket);

    function feeDecreaser() external view returns (IFeeExecutor);

    function traderRewardDistributor() external view returns (IActivityRewardDistributor);
}

// Copyright 2020 Compound Labs, Inc.
// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.10;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
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

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

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

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {PositionLibrary} from "../libraries/PositionLibrary.sol";
import {LimitOrderLibrary} from "../libraries/LimitOrderLibrary.sol";
import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";

interface IConditionalClosingManager {
    /**
     * @notice Checks if a position can be closed.
     * @param _position The position details.
     * @param _params The encoded parameters for closing the position.
     * @param _additionalParams Additional encoded parameters.
     * @return A boolean indicating whether the position can be closed.
     */
    function canBeClosedBeforeSwap(
        PositionLibrary.Position calldata _position,
        bytes calldata _params,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Checks if a position can be closed.
     * @param _position The position details.
     * @param _params The encoded parameters for closing the position.
     * @param _additionalParams Additional encoded parameters (not used).
     * @param _closeAmount The amount of the position to be closed, measured in the same decimal format as the position's asset.
     * @param _borowedAssetAmount The amount of borrowed asset.
     * @return A boolean indicating whether the position can be closed.
     */
    function canBeClosedAfterSwap(
        PositionLibrary.Position calldata _position,
        bytes calldata _params,
        bytes calldata _additionalParams,
        uint256 _closeAmount,
        uint256 _borowedAssetAmount
    ) external returns (bool);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {LimitOrderLibrary} from "../libraries/LimitOrderLibrary.sol";
import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";

interface IConditionalOpeningManager {
    /**
     * @notice Checks if a limit order can be filled.
     * Is used as a view function outside transactions and allows to check whether a specific order can be executed imitating the swap.
     * @param _order The limit order details.
     * @param _params Open condition parameters for the order.
     * @param _additionalParams Additional parameters for the order.
     * @return A boolean value indicating if the limit order can be filled.
     */
    function canBeFilledBeforeSwap(
        LimitOrderLibrary.LimitOrder calldata _order,
        bytes calldata _params,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Checks if a limit order can be filled based on the exchange rate.
     * @dev This function compares the exchange rate with the limit price.
     * @param _order The limit order details.
     * @param _params Open condition parameters for the order.
     * @param _additionalParams Additional parameters for the order.
     * @param _exchangeRate The exchange rate in WAD format to compare with the limit price.
     * @return A boolean value indicating if the limit order can be filled based on the exchange rate.
     */
    function canBeFilledAfterSwap(
        LimitOrderLibrary.LimitOrder calldata _order,
        bytes calldata _params,
        bytes calldata _additionalParams,
        uint256 _exchangeRate
    ) external pure returns (bool);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import {IPositionManager} from "../PositionManager/IPositionManager.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {ICurveCalc} from "./routers/ICurveCalc.sol";
import {ICurveRegistry} from "./routers/ICurveRegistry.sol";

interface IDexAdapter {
    /**
     * @notice Possible dex types
     */
    enum DexType {
        none, // 0
        UniswapV2, // 1  "uniswap", "sushiswap", "quickswap" (v2)
        UniswapV3, // 2
        Curve, // 3
        Balancer, // 4
        AlgebraV3, // 5
        Meshswap // 6
    }

    /*
     * @param encodedPath Swap path encoded in bytes
     * Encoded differently for different dexes:
     * Uniswap v2 - just encoded array of asset addresses
     * Uniswap v3 - swap path is a sequence of bytes. In Solidity, a path can be built like that:
     *      bytes.concat(bytes20(address(weth)), bytes3(uint24(pool1Fee)), bytes20(address(usdc)), bytes3(uint24(pool2Fee)) ...)
     * Quickswap - swap path is a sequence of bytes. In Solidity, a path can be built like that:
     *      bytes.concat(bytes20(address(weth)), bytes20(address(usdc)), bytes20(address(usdt) ...)
     * Curve - encoded array of asset addresses and pool addresses
     * Balancer - encoded array of asset addresses, pool ids and asset limits
     * @param _amountIn TokenA amount in
     * @param _amountOutMin Min tokenB amount out
     * @param _to Destination address for swap
     * @param _deadline Timestamp deadline for swap
     * @param _dexRouter Dex router address
     */
    struct SwapParams {
        bytes encodedPath;
        uint256 amountIn;
        uint256 amountOutMin;
        address to;
        uint256 deadline;
        address dexRouter;
    }

    /*
     * @param encodedPath Swap path encoded in bytes
     * @param _amountIn TokenA amount in
     * @param _dexRouter Dex router address
     */
    struct GetAmountsParams {
        bytes encodedPath;
        uint256 amount; // amountIn or amountOut
        address dexRouter;
    }

    event QuoterChanged(address indexed dexRouter, address indexed quoter);
    event DexTypeChanged(address indexed dexRouter, uint256 indexed dexType);

    /**
     * @param _dexRouter The router address for which the quoter is set
     * @param _quoter The quoter address to set
     */
    function setQuoter(address _dexRouter, address _quoter) external;

    /**
     * @notice Set a dex type for a dex router
     * @param _dexRouter The dex router address
     * @param _dexType The dex type from enum DexType
     */
    function setDexType(address _dexRouter, uint256 _dexType) external;

    /**
     * @notice Swap ERC20 tokens
     * @param _params SwapParams struct
     */
    function swapExactTokensForTokens(SwapParams memory _params) external returns (uint256[3] memory);

    /**
     * @notice Performs chained getAmountOut calculations
     * @notice given an input amount of an asset, returns the maximum output amount of the other asset
     * @param _params GetAmountsParams struct
     */
    function getAmountsOut(GetAmountsParams memory _params) external returns (uint256[3] memory);

    /**
     * @notice Performs chained getAmountIn calculations
     * @notice given an output amount of an asset, returns the maximum input amount of the other asset
     * @param _params GetAmountsParams struct
     */
    function getAmountsIn(GetAmountsParams memory _params) external returns (uint256[3] memory);

    /**
     * @notice Dex type mapping dexRouter => dex type
     */
    function dexType(address) external view returns (DexType);

    /**
     * @notice Mapping from the dexRouter to its quoter
     */
    function quoters(address) external view returns (address);

    /**
     * @return The address of the Registry contract
     */
    function registry() external view returns (address);

    /**
     * @notice Gets the average amount of gas that is required for the swap on some dex
     * @param dexRouter The address of a router
     */
    function getGas(address dexRouter) external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IInterestRateStrategy {
    /**
     * @dev parameters for BAR calculation - they differ depending on bucket's underlying asset
     */
    struct BarCalculationParams {
        uint256 urOptimal;
        uint256 k0;
        uint256 k1;
        uint256 b0;
        int256 b1;
    }

    event BarCalculationParamsChanged(
        address indexed bucket,
        uint256 urOptimal,
        uint256 k0,
        uint256 k1,
        uint256 b0,
        int256 b1
    );

    /**
     * @dev Updates bucket's BAR and LAR.
     * Calculates using utilization ratio (UR):
     * BAR = UR <= URoptimal ? (k0 * UR + b0) : (k1 * UR + b1), where 'b1' may be < 0,
     * LAR = BAR * UR,
     * if reserveRate != 0, then LAR = LAR * (1 - reserveRate)
     * @param ur Utilization ratio
     * @param reserveRate The reserve portion of the interest that goes to the Primex reserve
     * @return tuple containing BAR and LAR
     */

    function calculateInterestRates(uint256 ur, uint256 reserveRate) external returns (uint128, uint128);

    /**
     * @dev Set parameters for BAR calculation.
     * @param _params parameters are represented in byte string
     */

    function setBarCalculationParams(bytes memory _params) external;

    /**
     * @dev Retrieves the calculation parameters for the Bar calculation.
     * @param _address an address of the bucket
     * @return BarCalculationParams struct containing the parameters.
     */
    function getBarCalculationParams(address _address) external view returns (BarCalculationParams memory);
}

// Copyright (c) 2016-2023 zOS Global Limited and contributors
// SPDX-License-Identifier: MIT

// Interface for OpenZeppelin's Pausable contract from https://github.com/OpenZeppelin/openzeppelin-contracts/
pragma solidity ^0.8.18;

interface IPausable {
    /**
     * @dev Triggers stopped state.
     * This function can only be called by an address with the EMERGENCY_ADMIN role.
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     * This function can only be called by an address with the SMALL_TIMELOCK_ADMIN or MEDIUM_TIMELOCK_ADMIN role depending on the contract.
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";

import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface ISwapManager is IPausable {
    event SpotSwap(
        address indexed trader,
        address indexed receiver,
        address tokenA,
        address tokenB,
        uint256 amountSold,
        uint256 amountBought
    );

    /**
     * @param tokenA The address of the asset to be swapped from.
     * @param tokenB The address of the asset to be received in the swap.
     * @param amountTokenA The amount of tokenA to be swapped.
     * @param amountOutMin The minimum amount of tokenB expected to receive.
     * @param routes An array of PrimexPricingLibrary.Route structs representing the routes for the swap.
     * @param receiver The address where the swapped tokens will be received.
     * @param deadline The deadline for the swap transaction.
     * @param isSwapFromWallet A flag indicating whether the swap is perfomed from a wallet or a protocol balance.
     * @param isSwapToWallet A flag indicating whether the swapped tokens will be sent to a wallet or a protocol balance.
     * @param isSwapFeeInPmx A flag indicating whether the swap fee is paid in PMX or in native token.
     * @param payFeeFromWallet A flag indicating whether the swap fee is perfomed from a wallet or a protocol balance.
     */
    struct SwapParams {
        address tokenA;
        address tokenB;
        uint256 amountTokenA;
        uint256 amountOutMin;
        PrimexPricingLibrary.Route[] routes;
        address receiver;
        uint256 deadline;
        bool isSwapFromWallet;
        bool isSwapToWallet;
        bool isSwapFeeInPmx;
        bool payFeeFromWallet;
    }

    /**
     * @notice Executes a swap on dexes defined in routes
     * @param params The SwapParams struct containing the details of the swap transaction.
     * @param maximumOracleTolerableLimit The maximum tolerable limit in WAD format (1 WAD = 100%)
     * @param needOracleTolerableLimitCheck Flag indicating whether to perform an oracle tolerable limit check.
     * @return The resulting amount after the swap.
     */
    function swap(
        SwapParams calldata params,
        uint256 maximumOracleTolerableLimit,
        bool needOracleTolerableLimitCheck
    ) external payable returns (uint256);

    /**
     * @notice Retrieves the instance of PrimexRegistry contract.
     */
    function registry() external view returns (IAccessControl);

    /**
     * @notice Retrieves the instance of TraderBalanceVault contract.
     */
    function traderBalanceVault() external view returns (ITraderBalanceVault);

    /**
     * @notice Retrieves the instance of PrimexDNS contract.
     */
    function primexDNS() external view returns (IPrimexDNS);

    /**
     * @notice Retrieves the instance of PriceOracle contract.
     */
    function priceOracle() external view returns (IPriceOracle);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {PositionLibrary} from "../libraries/PositionLibrary.sol";
import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";

interface ITakeProfitStopLossCCM {
    struct CanBeClosedParams {
        uint256 takeProfitPrice;
        uint256 stopLossPrice;
    }

    struct AdditionalParams {
        PrimexPricingLibrary.Route[] routes;
    }

    /**
     * @notice Checks if the take profit has been reached for a given position.
     * @param _position The position details.
     * @param takeProfitPrice The take profit price in WAD format.
     * @param routes The array of routes for asset swapping.
     * @return A boolean indicating whether the take profit has been reached.
     */
    function isTakeProfitReached(
        PositionLibrary.Position calldata _position,
        uint256 takeProfitPrice,
        PrimexPricingLibrary.Route[] memory routes
    ) external returns (bool);

    /**
     * @notice Checks if the take profit has been reached based on the given parameters.
     * @dev Used in closeBatchPositions() function.
     * @param _params The encoded parameters.
     * @param exchangeRate The exchange rate in WAD format.
     * @return A boolean indicating whether the take profit has been reached.
     */
    function isTakeProfitReached(bytes calldata _params, uint256 exchangeRate) external view returns (bool);

    /**
     * @notice Checks if the stop loss price has been reached for a given position.
     * @param _position The position details.
     * @param stopLossPrice The stop loss price in WAD format to compare against.
     * @return True if the stop loss price is reached, false otherwise.
     */
    function isStopLossReached(
        PositionLibrary.Position calldata _position,
        uint256 stopLossPrice
    ) external view returns (bool);

    /**
     * @notice Checks if the stop loss price has been reached on the given parameters.
     * @dev The takeProfitPrice and stopLossPrice values can be obtained from the encoded data via CanBeClosedParams struct.
     * @param _params The encoded closing condition parameters containing stop loss price.
     * @param oracleExchangeRate The current exchange rate from the oracle in WAD format.
     * @return True if the stop loss price is reached, false otherwise.
     */
    function isStopLossReached(bytes calldata _params, uint256 oracleExchangeRate) external view returns (bool);

    /**
     * @notice Retrieves the take profit and stop loss prices from the given parameters.
     * @param _params The encoded parameters for closing a position.
     * @return takeProfitPrice The take profit price.
     * @return stopLossPrice The stop loss price.
     */
    function getTakeProfitStopLossPrices(bytes calldata _params) external view returns (uint256, uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICurveCalc {
    // solhint-disable func-name-mixedcase
    function get_dx(
        // solhint-disable-next-line var-name-mixedcase
        int128 n_coins,
        uint256[8] memory balances,
        uint256 amp,
        uint256 fee,
        uint256[8] memory rates,
        uint256[8] memory precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256 dy
    ) external pure returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICurveRegistry {
    // solhint-disable func-name-mixedcase
    function get_n_coins(address _pool) external view returns (uint256[2] memory);

    function get_rates(address _pool) external view returns (uint256[8] memory);

    function get_coin_indices(address _pool, address _from, address _to) external view returns (int128, int128, bool);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IKeeperRewardDistributorStorage} from "./IKeeperRewardDistributorStorage.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface IKeeperRewardDistributor is IKeeperRewardDistributorStorage, IPausable {
    struct DecreasingGasByReasonParams {
        DecreasingReason reason;
        uint256 amount;
    }
    struct MaxGasPerPositionParams {
        KeeperActionType actionType;
        KeeperActionRewardConfig config;
    }

    /**
     * @dev     Params for initialize() function
     * @param   priceOracle  Address of the PriceOracle contract
     * @param   registry  Address of the Registry contract
     * @param   pmx  Address of PMXToken
     * @param   treasury  Address of the Treasury contract
     * @param   pmxPartInReward  Percentage of PMX in reward (in WAD)
     * @param   nativePartInReward  Percentage of native token in reward (in WAD)
     * @param   positionSizeCoefficientA  CoefficientA in the formula positionSize * CoefficientA + CoefficientB
     * @param   positionSizeCoefficientB  CoefficientB in the formula positionSize * CoefficientA + CoefficientB
     * @param   additionalGas  Additional gas added to actual gas spent
     * @param   defaultMaxGasPrice  Max gas price allowed during reward calculation (used when no oracle price found)
     * @param   oracleGasPriceTolerance  Percentage by which oracle gas price can be exceeded (in WAD)
     * @param   paymentModel  The model of payment for gas in the network
     * @param   maxGasPerPositionParams  Parameters for the setMaxGasPerPosition function
     * @param   decreasingGasByReasonParams  Parameters for the setDecreasingGasByReason function
     */
    struct InitParams {
        address priceOracle;
        address registry;
        address pmx;
        address treasury;
        address whiteBlackList;
        uint256 pmxPartInReward;
        uint256 nativePartInReward;
        uint256 positionSizeCoefficientA;
        int256 positionSizeCoefficientB;
        uint256 additionalGas;
        uint256 defaultMaxGasPrice;
        uint256 oracleGasPriceTolerance;
        PaymentModel paymentModel;
        MaxGasPerPositionParams[] maxGasPerPositionParams;
        DecreasingGasByReasonParams[] decreasingGasByReasonParams;
    }

    event ClaimFees(address indexed keeper, address indexed asset, uint256 amount);
    event DefaultMaxGasPriceChanged(uint256 indexed defaultMaxGasPrice);
    event OracleGasPriceToleranceChanged(uint256 indexed oracleGasPriceTolerance);
    event MaxGasPerPositionChanged(KeeperActionType indexed actionType, KeeperActionRewardConfig config);
    event DataLengthRestrictionsChanged(KeeperCallingMethod callingMethod, uint256 maxRoutesLength, uint256 baseLength);
    event DecreasingGasByReasonChanged(DecreasingReason indexed reason, uint256 amount);
    event PmxPartInRewardChanged(uint256 indexed pmxPartInReward);
    event NativePartInRewardChanged(uint256 indexed nativePartInReward);
    event PositionSizeCoefficientsChanged(
        uint256 indexed positionSizeCoefficientA,
        int256 indexed positionSizeCoefficientB
    );
    event AdditionalGasChanged(uint256 indexed additionalGas);
    event KeeperRewardUpdated(address indexed keeper, uint256 rewardInPmx, uint256 rewardInNativeCurrency);

    /**
     * @notice Initializes the KeeperRewardDistributor contract.
     * @param _params  Parameters for initialization
     */
    function initialize(InitParams calldata _params) external;

    /**
     * @dev Params for the updateReward function
     * @param keeper  Address of the keeper
     * @param positionAsset  Address of the position asset
     * @param positionSize  Size of the position
     * @param action  The action that was performed by the keeper
     * @param numberOfActions  Number of actions performed by the keeper
     * @param gasSpent Gas spent on executing transaction
     * @param decreasingCounter An array where each index contains the number of decreasing reasons according to the DecreasingReason enum
     * @param routesLength  The length of routes provided as input to the protocol function,
     * subject to an additional commission in the ARBITRUM payment model.
     */

    struct UpdateRewardParams {
        address keeper;
        address positionAsset;
        uint256 positionSize;
        KeeperActionType action;
        uint256 numberOfActions;
        uint256 gasSpent;
        uint256[] decreasingCounter;
        uint256 routesLength;
    }

    /**
     * @notice Updates reward for keeper for closing position or executing order
     * @dev Only callable by the PM_ROLE, LOM_ROLE, BATCH_MANAGER_ROLE roles.
     * @param _params The UpdateRewardParams params
     */
    function updateReward(UpdateRewardParams calldata _params) external;

    /**
     * @notice Claims earned reward of the keeper
     * @param _pmxAmount  Amount of PMX token to claim
     * @param _nativeAmount  Amount of native token to claim
     */
    function claim(uint256 _pmxAmount, uint256 _nativeAmount) external;

    /**
     * @notice Sets the default maximum gas price allowed.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _defaultMaxGasPrice The new default maximum gas price value.
     */
    function setDefaultMaxGasPrice(uint256 _defaultMaxGasPrice) external;

    /**
     * @notice Sets the amount of gas to be removed for the specified reason
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _reason The reason for which an amount is set
     * @param _amount Gas amount.
     */
    function setDecreasingGasByReason(DecreasingReason _reason, uint256 _amount) external;

    /**
     * @notice Sets the KeeperActionRewardConfig for the specified action type
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _actionType The action type for which the config is set
     * @param _config The KeeperActionRewardConfig struct
     */

    function setMaxGasPerPosition(KeeperActionType _actionType, KeeperActionRewardConfig calldata _config) external;

    /**
     * @notice Sets the dataLengthRestrictions for the specified KeeperCallingMethod.
     * @param _callingMethod The calling method for which dataLengthRestrictions is set
     * @param _maxRoutesLength The maximum routes length for which an additional fee will be paid in the ARBITRUM payment model, in bytes
     * @param _baseLength The length of the data entering the protocol function including method signature
     * and excluding dynamic types(e.g, routesLength), in bytes
     */
    function setDataLengthRestrictions(
        KeeperCallingMethod _callingMethod,
        uint256 _maxRoutesLength,
        uint256 _baseLength
    ) external;

    /**
     * @notice Sets the tolerance for gas price fluctuations from the oracle price.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _oracleGasPriceTolerance The new oracle gas price tolerance value (percent expressed as WAD).
     */
    function setOracleGasPriceTolerance(uint256 _oracleGasPriceTolerance) external;

    /**
     * @notice Sets the PMX token's portion in the reward calculation.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _pmxPartInReward The new PMX token's portion in the reward calculation (percent expressed as WAD).
     */
    function setPmxPartInReward(uint256 _pmxPartInReward) external;

    /**
     * @notice Sets the native token's portion in the reward calculation.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _nativePartInReward The new native token's portion in the reward calculation (percent expressed as WAD).
     */
    function setNativePartInReward(uint256 _nativePartInReward) external;

    /**
     * @notice Sets the position size coefficients for reward calculations.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _positionSizeCoefficientA The new positionSizeCoefficientA value (in WAD).
     * @param _positionSizeCoefficientB The new positionSizeCoefficientB value (in WAD).
     */
    function setPositionSizeCoefficients(uint256 _positionSizeCoefficientA, int256 _positionSizeCoefficientB) external;

    /**
     * @notice Sets the additional gas value for reward calculations.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _additionalGas The new additionalGas value.
     */
    function setAdditionalGas(uint256 _additionalGas) external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IKeeperRewardDistributorStorage {
    enum DecreasingReason {
        NonExistentIdForLiquidation,
        NonExistentIdForSLOrTP,
        IncorrectConditionForLiquidation,
        IncorrectConditionForSL,
        ClosePostionInTheSameBlock
    }

    enum KeeperActionType {
        OpenByOrder,
        StopLoss,
        TakeProfit,
        Liquidation,
        BucketDelisted
    }

    enum KeeperCallingMethod {
        ClosePositionByCondition,
        OpenPositionByOrder,
        CloseBatchPositions
    }

    /**
     * @dev Structure used in the calculation of keeper rewards in the ARBITRUM payment model
     * @param maxRoutesLength The maximum length of routes for which will be paid keeper rewards, depending on KeeperCallingMethod
     * @param baseLength The static length of the data entering the protocol function, depending on KeeperCallingMethod
     */
    struct DataLengthRestrictions {
        uint256 maxRoutesLength;
        uint256 baseLength;
    }

    /**
     * @dev Structure used in the calculation of maximum gas per position
     * @param baseMaxGas1 Base gas amount that used to calculate max gas amount
     * @param baseMaxGas2 Base gas amount that used to calculate max gas amount when number of keeper actions > inflectionPoint
     * @param multiplier2 The multiplier which is multiplied by the number of keeper actions when number of keeper actions > inflectionPoint
     * @param inflectionPoint Number of actions after which the multiplier2 takes effect
     */
    struct KeeperActionRewardConfig {
        uint256 baseMaxGas1;
        uint256 baseMaxGas2;
        uint256 multiplier1;
        uint256 multiplier2;
        uint256 inflectionPoint;
    }

    struct KeeperBalance {
        uint256 pmxBalance;
        uint256 nativeBalance;
    }
    enum PaymentModel {
        DEFAULT,
        ARBITRUM
    }

    function priceOracle() external view returns (address);

    function registry() external view returns (address);

    function pmx() external view returns (address);

    function treasury() external view returns (address payable);

    function pmxPartInReward() external view returns (uint256);

    function nativePartInReward() external view returns (uint256);

    function positionSizeCoefficientA() external view returns (uint256);

    function positionSizeCoefficientB() external view returns (int256);

    function additionalGas() external view returns (uint256);

    function defaultMaxGasPrice() external view returns (uint256);

    function oracleGasPriceTolerance() external view returns (uint256);

    function paymentModel() external view returns (PaymentModel);

    function keeperBalance(address) external view returns (uint256, uint256);

    function maxGasPerPosition(KeeperActionType) external view returns (uint256, uint256, uint256, uint256, uint256);

    function dataLengthRestrictions(KeeperCallingMethod) external view returns (uint256, uint256);

    function decreasingGasByReason(DecreasingReason) external view returns (uint256);

    function totalBalance() external view returns (uint256, uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

// solhint-disable-next-line func-visibility
function _require(bool condition, bytes4 selector) pure {
    if (!condition) _revert(selector);
}

// solhint-disable-next-line func-visibility
function _revert(bytes4 selector) pure {
    // solhint-disable-next-line no-inline-assembly
    assembly ("memory-safe") {
        let free_mem_ptr := mload(64)
        mstore(free_mem_ptr, selector)
        revert(free_mem_ptr, 4)
    }
}

library Errors {
    event Log(bytes4 error);

    //common
    error ADDRESS_NOT_SUPPORTED();
    error FORBIDDEN();
    error AMOUNT_IS_0();
    error CALLER_IS_NOT_TRADER();
    error CONDITION_INDEX_IS_OUT_OF_BOUNDS();
    error INVALID_PERCENT_NUMBER();
    error INVALID_SECURITY_BUFFER();
    error INVALID_MAINTENANCE_BUFFER();
    error TOKEN_ADDRESS_IS_ZERO();
    error IDENTICAL_TOKEN_ADDRESSES();
    error ASSET_DECIMALS_EXCEEDS_MAX_VALUE();
    error CAN_NOT_ADD_WITH_ZERO_ADDRESS();
    error SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT();
    error TOKEN_NOT_SUPPORTED();
    error INSUFFICIENT_DEPOSIT();
    error SHOULD_NOT_HAVE_DUPLICATES();
    // error LIMIT_PRICE_IS_ZERO();
    error BUCKET_IS_NOT_ACTIVE();
    error DIFFERENT_DATA_LENGTH();
    error RECIPIENT_OR_SENDER_MUST_BE_ON_WHITE_LIST();
    error SLIPPAGE_TOLERANCE_EXCEEDED();
    error OPERATION_NOT_SUPPORTED();
    error SENDER_IS_BLACKLISTED();
    error NATIVE_CURRENCY_CANNOT_BE_ASSET();
    error DISABLED_TRANSFER_NATIVE_CURRENCY();
    error INVALID_AMOUNT();

    // bonus executor
    error CALLER_IS_NOT_NFT();
    error BONUS_FOR_BUCKET_ALREADY_ACTIVATED();
    error WRONG_LENGTH();
    error BONUS_DOES_NOT_EXIST();
    error CALLER_IS_NOT_DEBT_TOKEN();
    error CALLER_IS_NOT_P_TOKEN();
    error MAX_BONUS_COUNT_EXCEEDED();
    error TIER_IS_NOT_ACTIVE();
    error BONUS_PERCENT_IS_ZERO();

    // bucket
    error INCORRECT_LIQUIDITY_MINING_PARAMS();
    error PAIR_PRICE_DROP_IS_NOT_CORRECT();
    error ASSET_IS_NOT_SUPPORTED();
    error BUCKET_OUTSIDE_PRIMEX_PROTOCOL();
    error DEADLINE_IS_PASSED();
    error DEADLINE_IS_NOT_PASSED();
    error BUCKET_IS_NOT_LAUNCHED();
    error BURN_AMOUNT_EXCEEDS_PROTOCOL_DEBT();
    error LIQUIDITY_INDEX_OVERFLOW();
    error BORROW_INDEX_OVERFLOW();
    error BAR_OVERFLOW();
    error LAR_OVERFLOW();
    error UR_IS_MORE_THAN_1();
    error ASSET_ALREADY_SUPPORTED();
    error DEPOSIT_IS_MORE_AMOUNT_PER_USER();
    error DEPOSIT_EXCEEDS_MAX_TOTAL_DEPOSIT();
    error MINING_AMOUNT_WITHDRAW_IS_LOCKED_ON_STABILIZATION_PERIOD();
    error WITHDRAW_RATE_IS_MORE_10_PERCENT();
    error INVALID_FEE_BUFFER();
    error RESERVE_RATE_SHOULD_BE_LESS_THAN_1();
    error MAX_TOTAL_DEPOSIT_IS_ZERO();
    error AMOUNT_SCALED_SHOULD_BE_GREATER_THAN_ZERO();
    error NOT_ENOUGH_LIQUIDITY_IN_THE_BUCKET();

    // p/debt token, PMXToken
    error BUCKET_IS_IMMUTABLE();
    error INVALID_MINT_AMOUNT();
    error INVALID_BURN_AMOUNT();
    error TRANSFER_NOT_SUPPORTED();
    error APPROVE_NOT_SUPPORTED();
    error CALLER_IS_NOT_BUCKET();
    error CALLER_IS_NOT_A_BUCKET_FACTORY();
    error CALLER_IS_NOT_P_TOKEN_RECEIVER();
    error DURATION_MUST_BE_MORE_THAN_0();
    error INCORRECT_ID();
    error THERE_ARE_NO_LOCK_DEPOSITS();
    error LOCK_TIME_IS_NOT_EXPIRED();
    error TRANSFER_AMOUNT_EXCEED_ALLOWANCE();
    error CALLER_IS_NOT_A_MINTER();
    error ACTION_ONLY_WITH_AVAILABLE_BALANCE();
    error FEE_DECREASER_CALL_FAILED();
    error TRADER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error INTEREST_INCREASER_CALL_FAILED();
    error LENDER_REWARD_DISTRIBUTOR_CALL_FAILED();
    error DEPOSIT_DOES_NOT_EXIST();
    error RECIPIENT_IS_BLACKLISTED();

    //LOM
    error ORDER_CAN_NOT_BE_FILLED();
    error ORDER_DOES_NOT_EXIST();
    error ORDER_IS_NOT_SPOT();
    error LEVERAGE_MUST_BE_MORE_THAN_1();
    error CANNOT_CHANGE_SPOT_ORDER_TO_MARGIN();
    error SHOULD_HAVE_OPEN_CONDITIONS();
    error INCORRECT_LEVERAGE();
    error INCORRECT_DEADLINE();
    error LEVERAGE_SHOULD_BE_1();
    error LEVERAGE_EXCEEDS_MAX_LEVERAGE();
    error SHOULD_OPEN_POSITION();
    error IS_SPOT_ORDER();
    error SHOULD_NOT_HAVE_CLOSE_CONDITIONS();
    error ORDER_HAS_EXPIRED();

    // LiquidityMiningRewardDistributor
    error BUCKET_IS_NOT_STABLE();
    error ATTEMPT_TO_WITHDRAW_MORE_THAN_DEPOSITED();
    error WITHDRAW_PMX_BY_ADMIN_FORBIDDEN();

    // nft
    error TOKEN_IS_BLOCKED();
    error ONLY_MINTERS();
    error PROGRAM_IS_NOT_ACTIVE();
    error CALLER_IS_NOT_OWNER();
    error TOKEN_IS_ALREADY_ACTIVATED();
    error WRONG_NETWORK();
    error ID_DOES_NOT_EXIST();
    error WRONG_URIS_LENGTH();

    // PM
    error ASSET_ADDRESS_NOT_SUPPORTED();
    error IDENTICAL_ASSET_ADDRESSES();
    error POSITION_DOES_NOT_EXIST();
    error AMOUNT_IS_MORE_THAN_POSITION_AMOUNT();
    error BORROWED_AMOUNT_IS_ZERO();
    error IS_SPOT_POSITION();
    error AMOUNT_IS_MORE_THAN_DEPOSIT();
    error DECREASE_AMOUNT_IS_ZERO();
    error INSUFFICIENT_DEPOSIT_SIZE();
    error IS_NOT_RISKY_OR_CANNOT_BE_CLOSED();
    error BUCKET_SHOULD_BE_UNDEFINED();
    error DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0();
    error POSITION_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error ADDRESS_IS_ZERO();
    error WRONG_TRUSTED_MULTIPLIER();
    error POSITION_SIZE_EXCEEDED();
    error POSITION_BUCKET_IS_INCORRECT();
    error THERE_MUST_BE_AT_LEAST_ONE_POSITION();
    error NOTHING_TO_CLOSE();

    // BatchManager
    error PARAMS_LENGTH_MISMATCH();
    error BATCH_CANNOT_BE_CLOSED_FOR_THIS_REASON();
    error CLOSE_CONDITION_IS_NOT_CORRECT();
    error SOLD_ASSET_IS_INCORRECT();

    // Price Oracle
    error ZERO_EXCHANGE_RATE();
    error NO_PRICEFEED_FOUND();
    error NO_PRICE_DROP_FEED_FOUND();

    //DNS
    error INCORRECT_FEE_RATE();
    error INCORRECT_RESTRICTIONS();
    error BUCKET_ALREADY_FROZEN();
    error BUCKET_IS_ALREADY_ADDED();
    error DEX_IS_ALREADY_ACTIVATED();
    error DEX_IS_ALREADY_FROZEN();
    error DEX_IS_ALREADY_ADDED();
    error BUCKET_NOT_ADDED();
    error DEX_NOT_ACTIVE();
    error BUCKET_ALREADY_ACTIVATED();
    error DEX_NOT_ADDED();
    error BUCKET_IS_INACTIVE();
    error WITHDRAWAL_NOT_ALLOWED();
    error BUCKET_IS_ALREADY_DEPRECATED();

    // Primex upkeep
    error NUMBER_IS_0();

    //referral program, WhiteBlackList
    error CALLER_ALREADY_REGISTERED();
    error MISMATCH();
    error PARENT_NOT_WHITELISTED();
    error ADDRESS_ALREADY_WHITELISTED();
    error ADDRESS_ALREADY_BLACKLISTED();
    error ADDRESS_NOT_BLACKLISTED();
    error ADDRESS_NOT_WHITELISTED();
    error ADDRESS_NOT_UNLISTED();
    error ADDRESS_IS_WHITELISTED();
    error ADDRESS_IS_NOT_CONTRACT();

    //Reserve
    error BURN_AMOUNT_IS_ZERO();
    error CALLER_IS_NOT_EXECUTOR();
    error ADDRESS_NOT_PRIMEX_BUCKET();
    error NOT_SUFFICIENT_RESERVE_BALANCE();
    error INCORRECT_TRANSFER_RESTRICTIONS();

    //Vault
    error AMOUNT_EXCEEDS_AVAILABLE_BALANCE();
    error INSUFFICIENT_FREE_ASSETS();
    error CALLER_IS_NOT_SPENDER();

    //Pricing Library
    error IDENTICAL_ASSETS();
    error SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO();
    error DIFFERENT_PRICE_DEX_AND_ORACLE();
    error TAKE_PROFIT_IS_LTE_LIMIT_PRICE();
    error STOP_LOSS_IS_GTE_LIMIT_PRICE();
    error STOP_LOSS_IS_LTE_LIQUIDATION_PRICE();
    error INSUFFICIENT_POSITION_SIZE();
    error INCORRECT_PATH();
    error DEPOSITED_TO_BORROWED_ROUTES_LENGTH_SHOULD_BE_0();
    error INCORRECT_CM_TYPE();
    error FEE_RATE_IN_NATIVE_IS_ZERO();

    // Token transfers
    error TOKEN_TRANSFER_IN_FAILED();
    error TOKEN_TRANSFER_IN_OVERFLOW();
    error TOKEN_TRANSFER_OUT_FAILED();
    error NATIVE_TOKEN_TRANSFER_FAILED();

    // Conditional Managers
    error LOW_PRICE_ROUND_IS_LESS_HIGH_PRICE_ROUND();
    error TRAILING_DELTA_IS_INCORRECT();
    error DATA_FOR_ROUND_DOES_NOT_EXIST();
    error HIGH_PRICE_TIMESTAMP_IS_INCORRECT();
    error NO_PRICE_FEED_INTERSECTION();
    error SHOULD_BE_CCM();
    error SHOULD_BE_COM();

    //Lens
    error DEPOSITED_AMOUNT_IS_0();
    error SPOT_DEPOSITED_ASSET_SHOULD_BE_EQUAL_BORROWED_ASSET();
    error ZERO_ASSET_ADDRESS();
    error ASSETS_SHOULD_BE_DIFFERENT();
    error ZERO_SHARES();
    error SHARES_AMOUNT_IS_GREATER_THAN_AMOUNT_TO_SELL();
    error NO_ACTIVE_DEXES();

    //Bots
    error WRONG_BALANCES();
    error INVALID_INDEX();
    error INVALID_DIVIDER();
    error ARRAYS_LENGTHS_IS_NOT_EQUAL();
    error DENOMINATOR_IS_0();

    //DexAdapter
    error ZERO_AMOUNT_IN();
    error ZERO_AMOUNT();
    error UNKNOWN_DEX_TYPE();
    error REVERTED_WITHOUT_A_STRING_TRY_TO_CHECK_THE_ANCILLARY_DATA();
    error DELTA_OF_TOKEN_OUT_HAS_POSITIVE_VALUE();
    error DELTA_OF_TOKEN_IN_HAS_NEGATIVE_VALUE();
    error QUOTER_IS_NOT_PROVIDED();
    error DEX_ROUTER_NOT_SUPPORTED();
    error QUOTER_NOT_SUPPORTED();
    error SWAP_DEADLINE_PASSED();

    //SpotTradingRewardDistributor
    error PERIOD_DURATION_IS_ZERO();
    error REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_PERIOD_IS_NOT_CORRECT();

    //ActivityRewardDistributor
    error TOTAL_REWARD_AMOUNT_IS_ZERO();
    error REWARD_PER_DAY_IS_NOT_CORRECT();
    error ZERO_BUCKET_ADDRESS();
    //KeeperRewardDistributor
    error INCORRECT_PART_IN_REWARD();

    //Treasury
    error TRANSFER_RESTRICTIONS_NOT_MET();
    error INSUFFICIENT_NATIVE_TOKEN_BALANCE();
    error INSUFFICIENT_TOKEN_BALANCE();
    error EXCEEDED_MAX_AMOUNT_DURING_TIMEFRAME();
    error EXCEEDED_MAX_SPENDING_LIMITS();
    error SPENDING_LIMITS_ARE_INCORRECT();
    error SPENDER_IS_NOT_EXIST();
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {WadRayMath} from "./utils/WadRayMath.sol";

import {PrimexPricingLibrary} from "./PrimexPricingLibrary.sol";
import {TokenTransfersLibrary} from "./TokenTransfersLibrary.sol";

import {NATIVE_CURRENCY} from "../Constants.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IPrimexDNSStorage} from "../PrimexDNS/IPrimexDNSStorage.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IBucket} from "../Bucket/IBucket.sol";
import {IConditionalOpeningManager} from "../interfaces/IConditionalOpeningManager.sol";
import {IConditionalClosingManager} from "../interfaces/IConditionalClosingManager.sol";
import {IPositionManager} from "../PositionManager/IPositionManager.sol";
import {ISwapManager} from "../interfaces/ISwapManager.sol";

import "./Errors.sol";

library LimitOrderLibrary {
    using WadRayMath for uint256;

    enum CloseReason {
        FilledMargin,
        FilledSpot,
        FilledSwap,
        Cancelled
    }

    struct Condition {
        uint256 managerType;
        bytes params;
    }

    /**
     * @dev Creates a limit order and locks the deposit asset in the traderBalanceVault
     * @param bucket The bucket, from which the loan will be taken
     * @param positionAsset The address of output token for exchange
     * @param depositAsset The address of the deposit token
     * @param depositAmount The amount of deposit trader funds for deal
     * @param feeToken An asset in which the fee will be paid. At this point it could be the pmx, the epmx or a native currency
     * @param trader The trader, who has created the order
     * @param deadline Unix timestamp after which the order will not be filled
     * @param id The unique id of the order
     * @param leverage leverage for trading
     * @param shouldOpenPosition The flag to indicate whether position should be opened
     * @param createdAt The timeStamp when the order was created
     * @param updatedConditionsAt The timestamp when the open condition was updated
     */
    struct LimitOrder {
        IBucket bucket;
        address positionAsset;
        address depositAsset;
        uint256 depositAmount;
        address feeToken;
        uint256 protocolFee;
        address trader;
        uint256 deadline;
        uint256 id;
        uint256 leverage;
        bool shouldOpenPosition;
        uint256 createdAt;
        uint256 updatedConditionsAt;
        // The byte-encoded params, can be used for future updates
        bytes extraParams;
    }

    /**
     * @dev Structure for the сreateLimitOrder with parameters necessary to create limit order
     * @param bucket The bucket, from which the loan will be taken
     * @param depositAsset The address of the deposit token (collateral for margin trade or
     * locked funds for spot)
     * @param depositAmount The amount of deposit funds for deal
     * @param positionAsset The address output token for exchange
     * @param deadline Unix timestamp after which the order will not be filled
     * @param takeDepositFromWallet Bool, add a collateral deposit within the current transaction
     * @param leverage leverage for trading
     * @param shouldOpenPosition Bool, indicate whether position should be opened
     * @param openingManagerAddresses Array of contract addresses that will be called in canBeFilled
     * @param openingManagerParams Array of bytes representing params for contracts in openingManagerAddresses
     * @param closingManagerAddresses Array of contract addresses that will be called in canBeClosed
     * @param closingManagerParams Array of bytes representing params for contracts in closingManagerAddresses
     */
    struct CreateLimitOrderParams {
        string bucket;
        uint256 depositAmount;
        address depositAsset;
        address positionAsset;
        uint256 deadline;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
        uint256 leverage;
        bool shouldOpenPosition;
        Condition[] openConditions;
        Condition[] closeConditions;
        bool isProtocolFeeInPmx;
    }

    struct CreateLimitOrderVars {
        bool isSpot;
        IBucket bucket;
        uint256 positionSize;
        address priceOracle;
        uint256 rate;
        address feeToken;
    }

    /**
     * @dev Opens a position on an existing order
     * @param orderId order id
     * @param com address of ConditionalOpeningManager
     * @param comAdditionalParams  params needed for ConditionalOpeningManager to calc canBeFilled
     * @param firstAssetRoutes routes to swap first asset
     * @param depositInThirdAssetRoutes routes to swap deposit asset
     */
    struct OpenPositionParams {
        uint256 orderId;
        uint256 conditionIndex;
        bytes comAdditionalParams;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
        address keeper;
    }

    struct OpenPositionByOrderVars {
        address assetIn;
        address assetOut;
        uint256 amountIn;
        uint256 amountOut;
        CloseReason closeReason;
        uint256 newPositionId;
        uint256 exchangeRate;
    }

    /**
     * @dev Params for PositionManager to open position
     * @param order order
     * @param firstAssetRoutes routes to swap first asset on dex
     * (borrowedAmount + depositAmount if deposit in borrowedAsset)
     * @param depositInThirdAssetRoutes routes to swap deposit in third asset on dex
     */
    struct OpenPositionByOrderParams {
        address sender;
        LimitOrder order;
        Condition[] closeConditions;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    /**
     * @dev Structure for the updateOrder with parameters necessary to update limit order
     * @param orderId order id to update
     * @param depositAmount The amount of deposit funds for deal
     * @param makeDeposit Bool, add a collateral deposit within the current transaction
     * @param leverage leverage for trading
     * @param takeDepositFromWallet Bool, add a collateral deposit within the current transaction
     * @param payFeeFromWallet A flag indicating whether the Limit Order fee is perfomed from a wallet or a protocol balance.
     */
    struct UpdateLimitOrderParams {
        uint256 orderId;
        uint256 depositAmount;
        uint256 leverage;
        bool isProtocolFeeInPmx;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
    }

    /**
     * @notice Updates the protocol fee for a LimitOrder.
     * @param _order The LimitOrder storage object to update.
     * @param _params The new parameters for the LimitOrder.
     * @param _traderBalanceVault The instance of the TraderBalanceVault contract.
     * @param _primexDNS The PrimexDNS contract for accessing PMX-related information.
     * @param _priceOracle The address of the price oracle contract.
     */
    function updateProtocolFee(
        LimitOrder storage _order,
        UpdateLimitOrderParams calldata _params,
        ITraderBalanceVault _traderBalanceVault,
        IPrimexDNS _primexDNS,
        address _priceOracle
    ) public {
        address feeToken;
        if (_params.isProtocolFeeInPmx) {
            feeToken = _primexDNS.pmx();
            _require(msg.value == 0, Errors.DISABLED_TRANSFER_NATIVE_CURRENCY.selector);
        } else {
            feeToken = NATIVE_CURRENCY;
        }
        if (
            _params.leverage != _order.leverage ||
            _params.depositAmount != _order.depositAmount ||
            feeToken != _order.feeToken
        ) {
            uint256 newProtocolFee = PrimexPricingLibrary.calculateProtocolFee(
                PrimexPricingLibrary.DepositData({
                    protocolFee: 0,
                    depositAsset: _order.depositAsset,
                    depositAmount: _params.depositAmount,
                    leverage: _params.leverage
                }),
                _primexDNS,
                _priceOracle,
                _order.shouldOpenPosition
                    ? IPrimexDNSStorage.OrderType.LIMIT_ORDER
                    : IPrimexDNSStorage.OrderType.SWAP_LIMIT_ORDER,
                feeToken
            );
            if (feeToken == _order.feeToken) {
                uint256 amount;
                unchecked {
                    if (newProtocolFee > _order.protocolFee) amount = newProtocolFee - _order.protocolFee;
                    else amount = _order.protocolFee - newProtocolFee;
                }
                depositLockOrUnlock(
                    _traderBalanceVault,
                    feeToken,
                    amount,
                    _params.payFeeFromWallet,
                    newProtocolFee > _order.protocolFee
                );
            } else {
                if (newProtocolFee > 0) {
                    //lock the new fee token
                    depositLockOrUnlock(_traderBalanceVault, feeToken, newProtocolFee, _params.payFeeFromWallet, true);
                }
                //unlock the old fee token
                depositLockOrUnlock(
                    _traderBalanceVault,
                    _order.feeToken,
                    _order.protocolFee,
                    _params.payFeeFromWallet,
                    false
                );
                _order.feeToken = feeToken;
            }
            _order.protocolFee = newProtocolFee;
        }
    }

    /**
     * @notice Updates the leverage of a limit order.
     * @param _order The limit order to update.
     * @param _leverage The new leverage value in WAD format for the order.
     */
    function updateLeverage(LimitOrder storage _order, uint256 _leverage) public {
        _require(_leverage > WadRayMath.WAD, Errors.LEVERAGE_MUST_BE_MORE_THAN_1.selector);
        _require(_order.leverage != WadRayMath.WAD, Errors.CANNOT_CHANGE_SPOT_ORDER_TO_MARGIN.selector);

        _require(
            _leverage < _order.bucket.maxAssetLeverage(_order.positionAsset),
            Errors.LEVERAGE_EXCEEDS_MAX_LEVERAGE.selector
        );
        _order.leverage = _leverage;
    }

    /**
     * @notice Updates the deposit details of a LimitOrder.
     * @param _order The LimitOrder to update.
     * @param _amount The amount of the asset being deposited.
     * @param _takeDepositFromWallet Boolean indicating whether to make a deposit or unlock the deposited asset.
     * @param traderBalanceVault The instance of ITraderBalanceVault used for deposit and unlock operations.
     */
    function updateDeposit(
        LimitOrderLibrary.LimitOrder storage _order,
        uint256 _amount,
        bool _takeDepositFromWallet,
        ITraderBalanceVault traderBalanceVault
    ) public {
        depositLockOrUnlock(
            traderBalanceVault,
            _order.depositAsset,
            (_amount > _order.depositAmount) ? _amount - _order.depositAmount : _order.depositAmount - _amount,
            _takeDepositFromWallet,
            _amount > _order.depositAmount
        );
        _order.depositAmount = _amount;
    }

    /**
     * @notice Sets the open conditions for a LimitOrder.
     * @param _order The limit order.
     * @param openConditionsMap The mapping of order IDs to open conditions.
     * @param openConditions The array of open conditions.
     * @param primexDNS The instance of the Primex DNS contract.
     */
    function setOpenConditions(
        LimitOrderLibrary.LimitOrder memory _order,
        mapping(uint256 => Condition[]) storage openConditionsMap,
        Condition[] memory openConditions,
        IPrimexDNS primexDNS
    ) public {
        _require(hasNoConditionManagerTypeDuplicates(openConditions), Errors.SHOULD_NOT_HAVE_DUPLICATES.selector);
        _require(openConditions.length > 0, Errors.SHOULD_HAVE_OPEN_CONDITIONS.selector);
        if (openConditionsMap[_order.id].length > 0) {
            delete openConditionsMap[_order.id];
        }
        Condition memory condition;
        for (uint256 i; i < openConditions.length; i++) {
            condition = openConditions[i];
            _require(
                IERC165Upgradeable(primexDNS.cmTypeToAddress(condition.managerType)).supportsInterface(
                    type(IConditionalOpeningManager).interfaceId
                ),
                Errors.SHOULD_BE_COM.selector
            );
            openConditionsMap[_order.id].push(condition);
        }
    }

    /**
     * @notice Sets the close conditions for a LimitOrder.
     * @param _order The limit order.
     * @param closeConditionsMap The mapping of order IDs to close conditions.
     * @param closeConditions The array of close conditions to set.
     * @param primexDNS The Primex DNS contract address.
     */
    function setCloseConditions(
        LimitOrderLibrary.LimitOrder memory _order,
        mapping(uint256 => Condition[]) storage closeConditionsMap,
        Condition[] memory closeConditions,
        IPrimexDNS primexDNS
    ) public {
        _require(hasNoConditionManagerTypeDuplicates(closeConditions), Errors.SHOULD_NOT_HAVE_DUPLICATES.selector);
        _require(
            _order.shouldOpenPosition || closeConditions.length == 0,
            Errors.SHOULD_NOT_HAVE_CLOSE_CONDITIONS.selector
        );

        if (closeConditionsMap[_order.id].length > 0) {
            delete closeConditionsMap[_order.id];
        }
        Condition memory condition;
        for (uint256 i; i < closeConditions.length; i++) {
            condition = closeConditions[i];
            _require(
                IERC165Upgradeable(primexDNS.cmTypeToAddress(condition.managerType)).supportsInterface(
                    type(IConditionalClosingManager).interfaceId
                ),
                Errors.SHOULD_BE_CCM.selector
            );
            closeConditionsMap[_order.id].push(condition);
        }
    }

    /**
     * @notice Creates a limit order.
     * @param _params The struct containing the order parameters.
     * @param pm The instance of the PositionManager contract.
     * @param traderBalanceVault The instance of the TraderBalanceVault contract.
     * @param primexDNS The instance of the PrimexDNS contract.
     * @return The created limit order.
     */
    function createLimitOrder(
        CreateLimitOrderParams calldata _params,
        IPositionManager pm,
        ITraderBalanceVault traderBalanceVault,
        IPrimexDNS primexDNS
    ) public returns (LimitOrder memory) {
        _require(_params.leverage >= WadRayMath.WAD, Errors.INCORRECT_LEVERAGE.selector);
        _require(_params.deadline > block.timestamp, Errors.INCORRECT_DEADLINE.selector);

        CreateLimitOrderVars memory vars;
        vars.isSpot = bytes(_params.bucket).length == 0;
        vars.positionSize = _params.depositAmount.wmul(_params.leverage);
        vars.priceOracle = address(pm.priceOracle());
        if (vars.isSpot) {
            _require(_params.leverage == WadRayMath.WAD, Errors.LEVERAGE_SHOULD_BE_1.selector);
            _require(_params.depositAsset != _params.positionAsset, Errors.SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT.selector);
            IPriceOracle(vars.priceOracle).getPriceFeedsPair(_params.positionAsset, _params.depositAsset);
        } else {
            _require(_params.shouldOpenPosition, Errors.SHOULD_OPEN_POSITION.selector);
            _require(_params.leverage > WadRayMath.WAD, Errors.LEVERAGE_MUST_BE_MORE_THAN_1.selector);
            vars.bucket = IBucket(primexDNS.getBucketAddress(_params.bucket));
            _require(vars.bucket.getLiquidityMiningParams().isBucketLaunched, Errors.BUCKET_IS_NOT_LAUNCHED.selector);

            (, bool tokenAllowed) = vars.bucket.allowedAssets(_params.positionAsset);
            _require(tokenAllowed, Errors.TOKEN_NOT_SUPPORTED.selector);
            _require(
                _params.leverage < vars.bucket.maxAssetLeverage(_params.positionAsset),
                Errors.LEVERAGE_EXCEEDS_MAX_LEVERAGE.selector
            );
        }
        LimitOrder memory order = LimitOrder({
            bucket: IBucket(address(0)),
            positionAsset: _params.positionAsset,
            depositAsset: _params.depositAsset,
            depositAmount: _params.depositAmount,
            feeToken: _params.isProtocolFeeInPmx ? primexDNS.pmx() : NATIVE_CURRENCY,
            protocolFee: 0,
            trader: msg.sender,
            deadline: _params.deadline,
            id: 0,
            leverage: _params.leverage,
            shouldOpenPosition: _params.shouldOpenPosition,
            createdAt: block.timestamp,
            updatedConditionsAt: block.timestamp,
            extraParams: ""
        });
        order.bucket = vars.bucket;

        PrimexPricingLibrary.validateMinPositionSize(
            pm.minPositionSize(),
            pm.minPositionAsset(),
            vars.positionSize,
            order.depositAsset,
            vars.priceOracle
        );
        if (_params.isProtocolFeeInPmx) {
            vars.feeToken = primexDNS.pmx();
            _require(msg.value == 0, Errors.DISABLED_TRANSFER_NATIVE_CURRENCY.selector);
        } else {
            vars.feeToken = NATIVE_CURRENCY;
        }

        order.protocolFee = PrimexPricingLibrary.calculateProtocolFee(
            PrimexPricingLibrary.DepositData({
                protocolFee: 0,
                depositAsset: _params.depositAsset,
                depositAmount: _params.depositAmount,
                leverage: _params.leverage
            }),
            primexDNS,
            vars.priceOracle,
            order.shouldOpenPosition
                ? IPrimexDNSStorage.OrderType.LIMIT_ORDER
                : IPrimexDNSStorage.OrderType.SWAP_LIMIT_ORDER,
            vars.feeToken
        );

        if (order.protocolFee > 0) {
            // fee locking
            depositLockOrUnlock(traderBalanceVault, vars.feeToken, order.protocolFee, _params.payFeeFromWallet, true);
        }
        // deposit locking
        depositLockOrUnlock(
            traderBalanceVault,
            order.depositAsset,
            order.depositAmount,
            _params.takeDepositFromWallet,
            true
        );

        return order;
    }

    /**
     * @notice Opens a position by order.
     * @param order The LimitOrder storage containing order details.
     * @param _params The OpenPositionParams calldata containing additional position parameters.
     * @param _closeConditions The Condition array containing close conditions for the position.
     * @param pm The instance of the PositionManager contract.
     * @param traderBalanceVault The instance of the TraderBalanceVault contract.
     * @param primexDNS The instance of the PrimexDNS contract.
     * @param swapManager The instance of the SwapManager contract.
     * @return vars The OpenPositionByOrderVars struct containing the result of the open position operation.
     */
    function openPositionByOrder(
        LimitOrder storage order,
        OpenPositionParams calldata _params,
        Condition[] memory _closeConditions,
        IPositionManager pm,
        ITraderBalanceVault traderBalanceVault,
        IPrimexDNS primexDNS,
        ISwapManager swapManager
    ) public returns (OpenPositionByOrderVars memory) {
        OpenPositionByOrderVars memory vars;
        bool isSpot = address(order.bucket) == address(0);

        if (order.shouldOpenPosition) {
            vars.closeReason = isSpot ? CloseReason.FilledSpot : CloseReason.FilledMargin;
            (vars.amountIn, vars.amountOut, vars.newPositionId, vars.exchangeRate) = pm.openPositionByOrder(
                OpenPositionByOrderParams({
                    sender: msg.sender,
                    order: order,
                    closeConditions: _closeConditions,
                    firstAssetRoutes: _params.firstAssetRoutes,
                    depositInThirdAssetRoutes: _params.depositInThirdAssetRoutes
                })
            );
        } else {
            _require(
                _params.depositInThirdAssetRoutes.length == 0,
                Errors.DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0.selector
            );
            vars.closeReason = CloseReason.FilledSwap;
            vars.amountIn = order.depositAmount;

            // calculateFee is false so 'depositData' and 'priceOracle' are default values except 'protocolFee'
            PrimexPricingLibrary.payProtocolFee(
                PrimexPricingLibrary.ProtocolFeeParams({
                    depositData: PrimexPricingLibrary.DepositData({
                        protocolFee: order.protocolFee,
                        depositAsset: address(0),
                        depositAmount: 0,
                        leverage: 0
                    }),
                    feeToken: order.feeToken,
                    isSwapFromWallet: false,
                    calculateFee: false,
                    orderType: IPrimexDNSStorage.OrderType.SWAP_LIMIT_ORDER,
                    trader: order.trader,
                    priceOracle: address(0),
                    traderBalanceVault: traderBalanceVault,
                    primexDNS: primexDNS
                })
            );

            traderBalanceVault.unlockAsset(
                ITraderBalanceVault.UnlockAssetParams({
                    trader: order.trader,
                    receiver: address(this),
                    asset: order.depositAsset,
                    amount: order.depositAmount
                })
            );

            vars.amountOut = swapManager.swap(
                ISwapManager.SwapParams({
                    tokenA: order.depositAsset,
                    tokenB: order.positionAsset,
                    amountTokenA: order.depositAmount,
                    amountOutMin: 0,
                    routes: _params.firstAssetRoutes,
                    receiver: order.trader,
                    deadline: order.deadline,
                    isSwapFromWallet: false,
                    isSwapToWallet: false,
                    isSwapFeeInPmx: false,
                    payFeeFromWallet: false
                }),
                pm.getOracleTolerableLimit(order.depositAsset, order.positionAsset),
                true
            );
            uint256 multiplierDepositAsset = 10 ** (18 - IERC20Metadata(order.depositAsset).decimals());
            uint256 multiplierPositionAsset = 10 ** (18 - IERC20Metadata(order.positionAsset).decimals());
            vars.exchangeRate =
                (vars.amountIn * multiplierDepositAsset).wdiv(vars.amountOut * multiplierPositionAsset) /
                multiplierDepositAsset;
        }

        vars.assetIn = isSpot ? order.depositAsset : address(order.bucket.borrowedAsset());
        vars.assetOut = order.positionAsset;
        return vars;
    }

    /**
     * @notice Checks if an array of Condition structs has no duplicate manager types.
     * @param conditions The array of Condition structs to be checked.
     * @return bool Boolean value indicating whether the array has no duplicate manager types.
     */
    function hasNoConditionManagerTypeDuplicates(Condition[] memory conditions) public pure returns (bool) {
        if (conditions.length == 0) {
            return true;
        }
        for (uint256 i; i < conditions.length - 1; i++) {
            for (uint256 j = i + 1; j < conditions.length; j++) {
                if (conditions[i].managerType == conditions[j].managerType) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @notice This function is used to either deposit or unlock assets in the trader balance vault.
     * @param traderBalanceVault The instance of the trader balance vault.
     * @param _depositAsset The address of the asset to be deposited or unlocked.
     * @param _amount The amount of the asset to be deposited or unlocked.
     * @param _takeDepositFromWallet Boolean indicating whether to make a deposit or not.
     * @param _isAdd Boolean indicating whether to lock or unlock asset. Should lock asset, if true.
     */
    function depositLockOrUnlock(
        ITraderBalanceVault traderBalanceVault,
        address _depositAsset,
        uint256 _amount,
        bool _takeDepositFromWallet,
        bool _isAdd
    ) internal {
        if (!_isAdd) {
            traderBalanceVault.unlockAsset(
                ITraderBalanceVault.UnlockAssetParams(msg.sender, msg.sender, _depositAsset, _amount)
            );
            return;
        }
        if (_takeDepositFromWallet) {
            if (_depositAsset == NATIVE_CURRENCY) {
                _require(msg.value >= _amount, Errors.INSUFFICIENT_DEPOSIT.selector);
                traderBalanceVault.increaseLockedBalance{value: _amount}(msg.sender, _depositAsset, _amount);
                if (msg.value > _amount) {
                    uint256 rest = msg.value - _amount;
                    traderBalanceVault.topUpAvailableBalance{value: rest}(msg.sender, NATIVE_CURRENCY, rest);
                }
                return;
            }
            TokenTransfersLibrary.doTransferFromTo(_depositAsset, msg.sender, address(traderBalanceVault), _amount);
            traderBalanceVault.increaseLockedBalance(msg.sender, _depositAsset, _amount);
            return;
        }
        traderBalanceVault.useTraderAssets(
            ITraderBalanceVault.LockAssetParams(
                msg.sender,
                address(0),
                _depositAsset,
                _amount,
                ITraderBalanceVault.OpenType.CREATE_LIMIT_ORDER
            )
        );
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import {WadRayMath} from "./utils/WadRayMath.sol";

import {PrimexPricingLibrary} from "./PrimexPricingLibrary.sol";
import {TokenTransfersLibrary} from "./TokenTransfersLibrary.sol";
import {LimitOrderLibrary} from "./LimitOrderLibrary.sol";
import "./Errors.sol";

import {NATIVE_CURRENCY} from "../Constants.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IPrimexDNSStorage} from "../PrimexDNS/IPrimexDNSStorage.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IBucket} from "../Bucket/IBucket.sol";
import {IConditionalClosingManager} from "../interfaces/IConditionalClosingManager.sol";
import {ITakeProfitStopLossCCM} from "../interfaces/ITakeProfitStopLossCCM.sol";
import {IKeeperRewardDistributorStorage} from "../KeeperRewardDistributor/IKeeperRewardDistributorStorage.sol";

library PositionLibrary {
    using WadRayMath for uint256;

    event ClosePosition(
        uint256 indexed positionId,
        address indexed trader,
        address indexed closedBy,
        address bucketAddress,
        address soldAsset,
        address positionAsset,
        uint256 decreasePositionAmount,
        int256 profit,
        uint256 positionDebt,
        uint256 amountOut,
        PositionLibrary.CloseReason reason
    );

    /**
     * @notice This struct represents a trading position
     * @param id unique identifier for the position
     * @param scaledDebtAmount scaled debt amount associated with the position
     * @param bucket instance of the Bucket associated for trading
     * @param soldAsset bucket asset in the case of margin trading or deposit asset in the case of spot trading
     * @param depositAmountInSoldAsset equivalent of trader deposit size (this deposit can be in any asset) in the sold asset
     * or just deposit amount for spot trading
     * @param positionAsset asset of the trading position
     * @param positionAmount amount of the trading position
     * @param trader address of the trader holding the position
     * @param openBorrowIndex variable borrow index when position was opened
     * @param createdAt timestamp when the position was created
     * @param updatedConditionsAt timestamp when the close condition was updated
     * @param extraParams byte-encoded params, can be used for future updates
     */
    struct Position {
        uint256 id;
        uint256 scaledDebtAmount;
        IBucket bucket;
        address soldAsset;
        uint256 depositAmountInSoldAsset;
        address positionAsset;
        uint256 positionAmount;
        address trader;
        uint256 openBorrowIndex;
        uint256 createdAt;
        uint256 updatedConditionsAt;
        bytes extraParams;
    }

    struct IncreaseDepositParams {
        uint256 amount;
        address asset;
        bool takeDepositFromWallet;
        PrimexPricingLibrary.Route[] routes;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        uint256 amountOutMin;
    }

    struct DecreaseDepositParams {
        uint256 amount;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        uint256 pairPriceDrop;
        uint256 securityBuffer;
        uint256 oracleTolerableLimit;
        uint256 maintenanceBuffer;
    }

    struct MultiSwapParams {
        address tokenA;
        address tokenB;
        uint256 amountTokenA;
        PrimexPricingLibrary.Route[] routes;
        address receiver;
        uint256 deadline;
        bool takeDepositFromWallet;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
    }

    struct ClosePositionParams {
        uint256 closeAmount;
        uint256 depositDecrease;
        uint256 scaledDebtAmount;
        address depositReceiver;
        PrimexPricingLibrary.Route[] routes;
        uint256 amountOutMin;
        uint256 oracleTolerableLimit;
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        LimitOrderLibrary.Condition closeCondition;
        bytes ccmAdditionalParams;
        bool borrowedAmountIsNotZero;
        uint256 pairPriceDrop;
        uint256 securityBuffer;
        bool needOracleTolerableLimitCheck;
    }

    struct ClosePositionVars {
        address dexAdapter;
        uint256 borowedAssetAmount;
        uint256 amountToReturn;
        uint256 permanentLoss;
        uint256 fee;
    }

    struct ClosePositionEventData {
        int256 profit;
        uint256 debtAmount;
        uint256 amountOut;
        IKeeperRewardDistributorStorage.KeeperActionType actionType;
    }

    struct OpenPositionVars {
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
        PrimexPricingLibrary.DepositData depositData;
        address feeToken;
        uint256 borrowedAmount;
        uint256 amountOutMin;
        uint256 deadline;
        bool isSpot;
        bool isThirdAsset;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
        bool byOrder;
        address sender;
        LimitOrderLibrary.Condition[] closeConditions;
        bool needOracleTolerableLimitCheck;
    }

    struct OpenPositionEventData {
        uint256 protocolFee;
        uint256 entryPrice;
        uint256 leverage;
    }

    /**
     * The struct for openPosition function local vars
     */
    struct OpenPositionLocalData {
        uint256 amountToTransfer;
        address dexAdapter;
        address depositReceiver;
        uint256 depositInPositionAsset;
        bool isSpot;
    }

    /**
     * @dev Structure for the OpenPositionParams when margin trading is activated
     * @param bucket The bucket, from which the loan will be taken
     * @param borrowedAmount The amount of tokens borrowed to be exchanged
     * @param depositInThirdAssetRoutes routes to swap deposit in third asset on dex
     */
    struct OpenPositionMarginParams {
        string bucket;
        uint256 borrowedAmount;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    /**
     * @dev Structure for the openPosition with parameters necessary to open a position
     * @param marginParams margin trading related params
     * @param firstAssetRoutes routes to swap first asset on dex
     * (borrowedAmount + depositAmount if deposit in borrowedAsset)
     * @param depositAsset The address of the deposit token (collateral for margin trade or
     * locked funds for spot)
     * @param depositAmount The amount of deposit funds for deal
     * @param positionAsset The address output token for exchange
     * @param amountOutMin The minimum amount of output tokens
     * that must be received for the transaction not to revert.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @param takeDepositFromWallet Bool, add a deposit within the current transaction
     * @param payFeeFromWallet Bool, add a fee  within the current transaction
     * @param closeConditions Array of conditions that position can be closed by
     */
    struct OpenPositionParams {
        OpenPositionMarginParams marginParams;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        address depositAsset;
        uint256 depositAmount;
        address positionAsset;
        uint256 amountOutMin;
        uint256 deadline;
        bool takeDepositFromWallet;
        bool payFeeFromWallet;
        bool isProtocolFeeInPmx;
        LimitOrderLibrary.Condition[] closeConditions;
    }
    struct PositionManagerParams {
        IPrimexDNS primexDNS;
        IPriceOracle priceOracle;
        ITraderBalanceVault traderBalanceVault;
        uint256 oracleTolerableLimit;
        uint256 oracleTolerableLimitForThirdAsset;
        uint256 minPositionSize;
        address minPositionAsset;
        uint256 maxPositionSize;
    }

    struct ScaledParams {
        uint256 decreasePercent;
        uint256 scaledDebtAmount;
        uint256 depositDecrease;
        bool borrowedAmountIsNotZero;
    }

    enum CloseReason {
        CLOSE_BY_TRADER,
        RISKY_POSITION,
        BUCKET_DELISTED,
        LIMIT_CONDITION,
        BATCH_LIQUIDATION,
        BATCH_STOP_LOSS,
        BATCH_TAKE_PROFIT
    }

    /**
     * @dev Increases the deposit amount for a position.
     * @param position The storage reference to the position.
     * @param params The parameters for increasing the deposit.
     * @return The amount of trader debtTokens burned.
     */
    function increaseDeposit(Position storage position, IncreaseDepositParams memory params) public returns (uint256) {
        _require(msg.sender == position.trader, Errors.CALLER_IS_NOT_TRADER.selector);
        _require(position.scaledDebtAmount != 0, Errors.BORROWED_AMOUNT_IS_ZERO.selector);
        address borrowedAsset = position.soldAsset;

        uint256 depositAmountInBorrowed;
        address depositReceiver = params.primexDNS.dexAdapter();
        if (params.asset == borrowedAsset) {
            depositReceiver = address(position.bucket);
            depositAmountInBorrowed = params.amount;
        }

        if (params.takeDepositFromWallet) {
            TokenTransfersLibrary.doTransferFromTo(params.asset, msg.sender, depositReceiver, params.amount);
        } else {
            params.traderBalanceVault.useTraderAssets(
                ITraderBalanceVault.LockAssetParams(
                    msg.sender,
                    depositReceiver,
                    params.asset,
                    params.amount,
                    ITraderBalanceVault.OpenType.OPEN
                )
            );
        }

        if (params.asset != borrowedAsset) {
            depositAmountInBorrowed = PrimexPricingLibrary.multiSwap(
                PrimexPricingLibrary.MultiSwapParams({
                    tokenA: params.asset,
                    tokenB: borrowedAsset,
                    amountTokenA: params.amount,
                    routes: params.routes,
                    dexAdapter: params.primexDNS.dexAdapter(),
                    receiver: address(position.bucket),
                    deadline: block.timestamp
                }),
                0,
                address(params.primexDNS),
                address(params.priceOracle),
                false // don't need oracle check. add amountOutMin?
            );
            _require(depositAmountInBorrowed >= params.amountOutMin, Errors.SLIPPAGE_TOLERANCE_EXCEEDED.selector);
        }

        uint256 debt = getDebt(position);
        uint256 amountToTrader;
        uint256 debtToBurn = depositAmountInBorrowed;

        if (depositAmountInBorrowed >= debt) {
            amountToTrader = depositAmountInBorrowed - debt;
            debtToBurn = debt;
            position.scaledDebtAmount = 0;
            if (amountToTrader > 0)
                params.traderBalanceVault.topUpAvailableBalance(position.trader, borrowedAsset, amountToTrader);
        } else {
            position.scaledDebtAmount =
                position.scaledDebtAmount -
                debtToBurn.rdiv(position.bucket.getNormalizedVariableDebt());
        }

        position.depositAmountInSoldAsset += debtToBurn;

        position.bucket.decreaseTraderDebt(
            position.trader,
            debtToBurn,
            address(params.traderBalanceVault),
            amountToTrader,
            0
        );
        return debtToBurn;
    }

    /**
     * @dev Decreases the deposit amount for a position.
     * @param position The storage reference to the position.
     * @param params The parameters for the decrease deposit operation.
     */
    function decreaseDeposit(Position storage position, DecreaseDepositParams memory params) public {
        _require(msg.sender == position.trader, Errors.CALLER_IS_NOT_TRADER.selector);
        _require(position.bucket != IBucket(address(0)), Errors.IS_SPOT_POSITION.selector);
        _require(position.bucket.isActive(), Errors.BUCKET_IS_NOT_ACTIVE.selector);
        _require(params.amount > 0, Errors.DECREASE_AMOUNT_IS_ZERO.selector);
        _require(params.amount <= position.depositAmountInSoldAsset, Errors.AMOUNT_IS_MORE_THAN_DEPOSIT.selector);
        position.depositAmountInSoldAsset -= params.amount;
        position.scaledDebtAmount =
            position.scaledDebtAmount +
            params.amount.rdiv(position.bucket.getNormalizedVariableDebt());

        params.traderBalanceVault.topUpAvailableBalance(position.trader, position.soldAsset, params.amount);

        _require(
            health(
                position,
                params.priceOracle,
                params.pairPriceDrop,
                params.securityBuffer,
                params.oracleTolerableLimit
            ) >= WadRayMath.WAD + params.maintenanceBuffer,
            Errors.INSUFFICIENT_DEPOSIT_SIZE.selector
        );
        position.bucket.increaseDebt(position.trader, params.amount, address(params.traderBalanceVault));
    }

    /**
     * @notice Closes a position.
     * @param position The position to be closed.
     * @param params The parameters for closing the position.
     * @param reason The reason for closing the position.
     * @return posEventData The event data for the closed position.
     */
    function closePosition(
        Position memory position,
        ClosePositionParams memory params,
        CloseReason reason
    ) public returns (ClosePositionEventData memory) {
        ClosePositionEventData memory posEventData;
        ClosePositionVars memory vars;

        if (params.borrowedAmountIsNotZero) {
            posEventData.debtAmount = params.scaledDebtAmount.rmul(position.bucket.getNormalizedVariableDebt());
        }

        vars.dexAdapter = params.primexDNS.dexAdapter();
        TokenTransfersLibrary.doTransferOut(position.positionAsset, vars.dexAdapter, params.closeAmount);
        posEventData.amountOut = PrimexPricingLibrary.multiSwap(
            PrimexPricingLibrary.MultiSwapParams({
                tokenA: position.positionAsset,
                tokenB: position.soldAsset,
                amountTokenA: params.closeAmount,
                routes: params.routes,
                dexAdapter: vars.dexAdapter,
                receiver: params.borrowedAmountIsNotZero
                    ? address(position.bucket)
                    : address(params.traderBalanceVault),
                deadline: block.timestamp
            }),
            params.oracleTolerableLimit,
            address(params.primexDNS),
            address(params.priceOracle),
            params.needOracleTolerableLimitCheck
        );

        _require(
            posEventData.amountOut >= params.amountOutMin && posEventData.amountOut > 0,
            Errors.SLIPPAGE_TOLERANCE_EXCEEDED.selector
        );

        bool canBeClosed;
        if (reason == CloseReason.CLOSE_BY_TRADER) {
            canBeClosed = position.trader == msg.sender;
        } else if (reason == CloseReason.RISKY_POSITION) {
            canBeClosed =
                health(
                    position,
                    params.priceOracle,
                    params.pairPriceDrop,
                    params.securityBuffer,
                    params.oracleTolerableLimit
                ) <
                WadRayMath.WAD;
            posEventData.actionType = IKeeperRewardDistributorStorage.KeeperActionType.Liquidation;
        } else if (reason == CloseReason.LIMIT_CONDITION) {
            address cm = params.primexDNS.cmTypeToAddress(params.closeCondition.managerType);
            _require(cm != address(0), Errors.INCORRECT_CM_TYPE.selector);

            canBeClosed = IConditionalClosingManager(cm).canBeClosedAfterSwap(
                position,
                params.closeCondition.params,
                params.ccmAdditionalParams,
                params.closeAmount,
                posEventData.amountOut
            );
            posEventData.actionType = IKeeperRewardDistributorStorage.KeeperActionType.StopLoss;
        } else if (reason == CloseReason.BUCKET_DELISTED) {
            canBeClosed = position.bucket != IBucket(address(0)) && position.bucket.isDelisted();
            posEventData.actionType = IKeeperRewardDistributorStorage.KeeperActionType.BucketDelisted;
        }
        _require(canBeClosed, Errors.POSITION_CANNOT_BE_CLOSED_FOR_THIS_REASON.selector);

        uint256 permanentLoss;
        if (posEventData.amountOut > posEventData.debtAmount) {
            unchecked {
                vars.amountToReturn = posEventData.amountOut - posEventData.debtAmount;
            }
        } else {
            unchecked {
                permanentLoss = posEventData.debtAmount - posEventData.amountOut;
            }
        }

        posEventData.profit = -int256(params.depositDecrease);

        if (reason != CloseReason.RISKY_POSITION) {
            if (vars.amountToReturn > 0) {
                posEventData.profit += int256(vars.amountToReturn);
                params.traderBalanceVault.topUpAvailableBalance(
                    reason == CloseReason.CLOSE_BY_TRADER ? params.depositReceiver : position.trader,
                    position.soldAsset,
                    vars.amountToReturn
                );
            }
        }

        if (params.borrowedAmountIsNotZero) {
            position.bucket.decreaseTraderDebt(
                position.trader,
                posEventData.debtAmount,
                reason == CloseReason.RISKY_POSITION ? params.primexDNS.treasury() : address(params.traderBalanceVault),
                vars.amountToReturn,
                permanentLoss
            );
        }

        // to avoid stack to deep
        CloseReason _reason = reason;
        if (params.closeAmount == position.positionAmount) {
            emit ClosePosition({
                positionId: position.id,
                trader: position.trader,
                closedBy: msg.sender,
                bucketAddress: address(position.bucket),
                soldAsset: position.soldAsset,
                positionAsset: position.positionAsset,
                decreasePositionAmount: position.positionAmount,
                profit: posEventData.profit,
                positionDebt: posEventData.debtAmount,
                amountOut: posEventData.amountOut,
                reason: _reason
            });
        }
        return posEventData;
    }

    /**
     * @dev Sets the maximum position size between two tokens.
     * @param maxPositionSize The storage mapping for maximum position sizes.
     * @param token0 The address of token0.
     * @param token1 The address of token1.
     * @param amountInToken0 The maximum position size in token0.
     * @param amountInToken1 The maximum position size in token1.
     */
    function setMaxPositionSize(
        mapping(address => mapping(address => uint256)) storage maxPositionSize,
        address token0,
        address token1,
        uint256 amountInToken0,
        uint256 amountInToken1
    ) public {
        _require(token0 != address(0) && token1 != address(0), Errors.TOKEN_ADDRESS_IS_ZERO.selector);
        _require(token0 != token1, Errors.IDENTICAL_ASSET_ADDRESSES.selector);

        maxPositionSize[token1][token0] = amountInToken0;
        maxPositionSize[token0][token1] = amountInToken1;
    }

    /**
     * @dev Sets the tolerable limit for an oracle between two assets.
     * @param oracleTolerableLimits The mapping to store oracle tolerable limits.
     * @param assetA The address of the first asset.
     * @param assetB The address of the second asset.
     * @param percent The percentage tolerable limit for the oracle in WAD format (1 WAD = 100%).
     */
    function setOracleTolerableLimit(
        mapping(address => mapping(address => uint256)) storage oracleTolerableLimits,
        address assetA,
        address assetB,
        uint256 percent
    ) public {
        _require(assetA != address(0) && assetB != address(0), Errors.ASSET_ADDRESS_NOT_SUPPORTED.selector);
        _require(assetA != assetB, Errors.IDENTICAL_ASSET_ADDRESSES.selector);
        _require(percent <= WadRayMath.WAD && percent > 0, Errors.INVALID_PERCENT_NUMBER.selector);
        oracleTolerableLimits[assetA][assetB] = percent;
        oracleTolerableLimits[assetB][assetA] = percent;
    }

    /**
     * @dev Sets the close conditions for a given position.
     * @param position The position for which to set the close conditions.
     * @param closeConditionsMap The storage mapping of close conditions for each position ID.
     * @param closeConditions The array of close conditions to be set.
     * @param primexDNS The address of the IPrimexDNS contract.
     */
    function setCloseConditions(
        Position memory position,
        mapping(uint256 => LimitOrderLibrary.Condition[]) storage closeConditionsMap,
        LimitOrderLibrary.Condition[] memory closeConditions,
        IPrimexDNS primexDNS
    ) public {
        _require(
            LimitOrderLibrary.hasNoConditionManagerTypeDuplicates(closeConditions),
            Errors.SHOULD_NOT_HAVE_DUPLICATES.selector
        );
        if (closeConditionsMap[position.id].length > 0) {
            delete closeConditionsMap[position.id];
        }
        LimitOrderLibrary.Condition memory condition;
        for (uint256 i; i < closeConditions.length; i++) {
            condition = closeConditions[i];
            _require(
                IERC165Upgradeable(primexDNS.cmTypeToAddress(condition.managerType)).supportsInterface(
                    type(IConditionalClosingManager).interfaceId
                ),
                Errors.SHOULD_BE_CCM.selector
            );

            closeConditionsMap[position.id].push(condition);
        }
    }

    /**
     * @notice Opens a position by depositing assets and borrowing funds (except when the position is spot)
     * @param _position The position to be opened
     * @param _vars Variables related to the position opening
     * @param _pmParams Parameters for the PositionManager contract
     * @return The updated position and event data
     */
    function openPosition(
        Position memory _position,
        OpenPositionVars memory _vars,
        PositionManagerParams memory _pmParams
    ) public returns (Position memory, OpenPositionEventData memory) {
        PrimexPricingLibrary.validateMinPositionSize(
            _pmParams.minPositionSize,
            _pmParams.minPositionAsset,
            _vars.borrowedAmount + _position.depositAmountInSoldAsset,
            _position.soldAsset,
            address(_pmParams.priceOracle)
        );
        OpenPositionLocalData memory data;
        data.amountToTransfer = _vars.borrowedAmount;
        data.dexAdapter = _pmParams.primexDNS.dexAdapter();
        data.depositReceiver = data.dexAdapter;
        if (_vars.depositData.depositAsset == _position.positionAsset) {
            _position.positionAmount = _vars.depositData.depositAmount;
            data.depositInPositionAsset = _vars.depositData.depositAmount;
            data.depositReceiver = address(this);
        } else if (_vars.depositData.depositAsset == _position.soldAsset) {
            data.amountToTransfer += _vars.depositData.depositAmount;
        }

        data.isSpot = _vars.borrowedAmount == 0;
        if (data.isSpot) _vars.depositData.depositAsset = _position.soldAsset;

        if (_vars.takeDepositFromWallet) {
            TokenTransfersLibrary.doTransferFromTo(
                _vars.depositData.depositAsset,
                msg.sender,
                data.depositReceiver,
                _vars.depositData.depositAmount
            );
        } else {
            _pmParams.traderBalanceVault.useTraderAssets(
                ITraderBalanceVault.LockAssetParams({
                    trader: _position.trader,
                    depositReceiver: data.depositReceiver,
                    depositAsset: _vars.depositData.depositAsset,
                    depositAmount: _vars.depositData.depositAmount,
                    openType: _vars.byOrder
                        ? ITraderBalanceVault.OpenType.OPEN_BY_ORDER
                        : ITraderBalanceVault.OpenType.OPEN
                })
            );
        }

        if (!data.isSpot) {
            _position.bucket.increaseDebt(_position.trader, _vars.borrowedAmount, data.dexAdapter);
            // @note You need to write index only after opening a position in bucket.
            // Since when opening position in the bucket, index becomes relevant (containing accumulated profit)
            _position.openBorrowIndex = _position.bucket.variableBorrowIndex();
            _position.scaledDebtAmount = _vars.borrowedAmount.rdiv(_position.openBorrowIndex);
        }
        if (_vars.isThirdAsset) {
            data.depositInPositionAsset = PrimexPricingLibrary.multiSwap(
                PrimexPricingLibrary.MultiSwapParams({
                    tokenA: _vars.depositData.depositAsset,
                    tokenB: _position.positionAsset,
                    amountTokenA: _vars.depositData.depositAmount,
                    routes: _vars.depositInThirdAssetRoutes,
                    dexAdapter: data.dexAdapter,
                    receiver: address(this),
                    deadline: _vars.deadline
                }),
                _pmParams.oracleTolerableLimitForThirdAsset,
                address(_pmParams.primexDNS),
                address(_pmParams.priceOracle),
                true
            );
            _position.positionAmount += data.depositInPositionAsset;
        } else {
            _require(
                _vars.depositInThirdAssetRoutes.length == 0,
                Errors.DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0.selector
            );
        }

        uint256 borrowedAmountInPositionAsset = PrimexPricingLibrary.multiSwap(
            PrimexPricingLibrary.MultiSwapParams({
                tokenA: _position.soldAsset,
                tokenB: _position.positionAsset,
                amountTokenA: data.isSpot ? _vars.depositData.depositAmount : data.amountToTransfer,
                routes: _vars.firstAssetRoutes,
                dexAdapter: data.dexAdapter,
                receiver: address(this),
                deadline: _vars.deadline
            }),
            _pmParams.oracleTolerableLimit,
            address(_pmParams.primexDNS),
            address(_pmParams.priceOracle),
            _vars.needOracleTolerableLimitCheck
        );
        _position.positionAmount += borrowedAmountInPositionAsset;
        _require(_pmParams.maxPositionSize >= _position.positionAmount, Errors.POSITION_SIZE_EXCEEDED.selector);
        uint256 leverage = WadRayMath.WAD;
        if (!data.isSpot) {
            if (_vars.depositData.depositAsset == _position.soldAsset) {
                leverage = (_vars.borrowedAmount + _position.depositAmountInSoldAsset).wdiv(
                    _position.depositAmountInSoldAsset
                );
            } else {
                leverage = (borrowedAmountInPositionAsset + data.depositInPositionAsset).wdiv(
                    data.depositInPositionAsset
                );
            }
            _require(
                leverage <= _position.bucket.maxAssetLeverage(_position.positionAsset),
                Errors.INSUFFICIENT_DEPOSIT.selector
            );
        }

        if (!_vars.byOrder) {
            _vars.depositData.leverage = leverage;
        }

        _require(_position.positionAmount >= _vars.amountOutMin, Errors.SLIPPAGE_TOLERANCE_EXCEEDED.selector);

        OpenPositionEventData memory posEventData;

        posEventData.protocolFee = PrimexPricingLibrary.payProtocolFee(
            PrimexPricingLibrary.ProtocolFeeParams({
                depositData: _vars.depositData,
                feeToken: _vars.feeToken,
                isSwapFromWallet: _vars.payFeeFromWallet,
                calculateFee: !_vars.byOrder,
                orderType: _vars.byOrder
                    ? IPrimexDNSStorage.OrderType.LIMIT_ORDER
                    : IPrimexDNSStorage.OrderType.MARKET_ORDER,
                trader: _position.trader,
                priceOracle: address(_pmParams.priceOracle),
                traderBalanceVault: _pmParams.traderBalanceVault,
                primexDNS: _pmParams.primexDNS
            })
        );

        uint256 multiplierBorrowedAsset = 10 ** (18 - IERC20Metadata(_position.soldAsset).decimals());
        uint256 multiplierPositionAsset = 10 ** (18 - IERC20Metadata(_position.positionAsset).decimals());
        posEventData.entryPrice =
            ((_vars.borrowedAmount + _position.depositAmountInSoldAsset) * multiplierBorrowedAsset).wdiv(
                _position.positionAmount * multiplierPositionAsset
            ) /
            multiplierBorrowedAsset;
        posEventData.leverage = _vars.depositData.leverage;
        return (_position, posEventData);
    }

    /**
     * @dev Retrieves the debt amount for a given position.
     * @param position The Position struct representing the position to get the debt amount for.
     * @return The debt amount in debtTokens.
     */
    function getDebt(Position memory position) public view returns (uint256) {
        if (position.scaledDebtAmount == 0) return 0;
        return position.scaledDebtAmount.rmul(position.bucket.getNormalizedVariableDebt());
    }

    /**
     * @dev Calculates the health of a position.
     * @dev health = ((1 - securityBuffer) * (1 - oracleTolerableLimit) * (1 - priceDrop) * borrowedAssetAmountOut) /
     (feeBuffer * debt)
     * @param position The position object containing relevant information.
     * @param priceOracle The price oracle contract used for obtaining asset prices.
     * @param pairPriceDrop The priceDrop in WAD format of the asset pair.
     * @param securityBuffer The security buffer in WAD format for the position.
     * @param oracleTolerableLimit The tolerable limit in WAD format for the price oracle.
     * @return The health value in WAD format of the position.
     */
    function health(
        Position memory position,
        IPriceOracle priceOracle,
        uint256 pairPriceDrop,
        uint256 securityBuffer,
        uint256 oracleTolerableLimit
    ) public view returns (uint256) {
        if (position.scaledDebtAmount == 0) return WadRayMath.WAD;
        return
            health(
                PrimexPricingLibrary.getOracleAmountsOut(
                    position.positionAsset,
                    position.soldAsset,
                    position.positionAmount,
                    address(priceOracle)
                ),
                pairPriceDrop,
                securityBuffer,
                oracleTolerableLimit,
                getDebt(position),
                position.bucket.feeBuffer()
            );
    }

    /**
     * @dev Creates a new position based on the given parameters.
     * @param _params The input parameters for creating the position.
     * @param primexDNS The address of the PrimexDNS contract.
     * @param priceOracle The address of the PriceOracle contract.
     * @return position The created Position struct.
     * @return vars The OpenPositionVars struct.
     */
    function createPosition(
        OpenPositionParams calldata _params,
        IPrimexDNS primexDNS,
        IPriceOracle priceOracle
    ) public view returns (Position memory, OpenPositionVars memory) {
        OpenPositionVars memory vars = OpenPositionVars({
            firstAssetRoutes: _params.firstAssetRoutes,
            depositInThirdAssetRoutes: _params.marginParams.depositInThirdAssetRoutes,
            depositData: PrimexPricingLibrary.DepositData({
                protocolFee: 0,
                depositAsset: address(0),
                depositAmount: _params.depositAmount,
                leverage: 0
            }),
            feeToken: _params.isProtocolFeeInPmx ? primexDNS.pmx() : NATIVE_CURRENCY,
            borrowedAmount: _params.marginParams.borrowedAmount,
            amountOutMin: _params.amountOutMin,
            deadline: _params.deadline,
            isSpot: _params.marginParams.borrowedAmount == 0,
            isThirdAsset: false,
            takeDepositFromWallet: _params.takeDepositFromWallet,
            payFeeFromWallet: _params.payFeeFromWallet,
            byOrder: false,
            sender: address(0),
            closeConditions: _params.closeConditions,
            needOracleTolerableLimitCheck: _params.marginParams.borrowedAmount > 0
        });
        PositionLibrary.Position memory position = PositionLibrary.Position({
            id: 0,
            scaledDebtAmount: 0,
            bucket: IBucket(address(0)),
            soldAsset: address(0),
            depositAmountInSoldAsset: 0,
            positionAsset: _params.positionAsset,
            positionAmount: 0,
            trader: msg.sender,
            openBorrowIndex: 0,
            createdAt: block.timestamp,
            updatedConditionsAt: block.timestamp,
            extraParams: ""
        });

        if (vars.isSpot) {
            _require(_params.depositAsset != _params.positionAsset, Errors.SHOULD_BE_DIFFERENT_ASSETS_IN_SPOT.selector);
            _require(bytes(_params.marginParams.bucket).length == 0, Errors.BUCKET_SHOULD_BE_UNDEFINED.selector);
            priceOracle.getPriceFeedsPair(_params.positionAsset, _params.depositAsset);
            position.soldAsset = _params.depositAsset;
            position.depositAmountInSoldAsset = vars.depositData.depositAmount;
            vars.depositData.leverage = WadRayMath.WAD;
        } else {
            position.bucket = IBucket(primexDNS.getBucketAddress(_params.marginParams.bucket));
            position.soldAsset = address(position.bucket.borrowedAsset());
            vars.depositData.depositAsset = _params.depositAsset;
            (, bool tokenAllowed) = position.bucket.allowedAssets(_params.positionAsset);
            _require(tokenAllowed, Errors.TOKEN_NOT_SUPPORTED.selector);

            vars.isThirdAsset =
                _params.depositAsset != position.soldAsset &&
                _params.depositAsset != _params.positionAsset;

            position.depositAmountInSoldAsset = PrimexPricingLibrary.getOracleAmountsOut(
                _params.depositAsset,
                position.soldAsset,
                _params.depositAmount,
                address(priceOracle)
            );
        }

        return (position, vars);
    }

    /**
     * @notice Creates a position based on the provided order parameters.
     * @dev This function calculates and returns a Position and OpenPositionVars struct.
     * @param _params The OpenPositionByOrderParams struct containing the order parameters.
     * @param priceOracle The price oracle contract used for retrieving asset prices.
     * @return position The Position struct representing the created position.
     * @return vars The OpenPositionVars struct containing additional variables related to the position.
     */
    function createPositionByOrder(
        LimitOrderLibrary.OpenPositionByOrderParams calldata _params,
        IPriceOracle priceOracle
    ) public view returns (Position memory, OpenPositionVars memory) {
        OpenPositionVars memory vars = OpenPositionVars({
            firstAssetRoutes: _params.firstAssetRoutes,
            depositInThirdAssetRoutes: _params.depositInThirdAssetRoutes,
            depositData: PrimexPricingLibrary.DepositData({
                protocolFee: _params.order.protocolFee,
                depositAsset: address(0),
                depositAmount: _params.order.depositAmount,
                leverage: _params.order.leverage
            }),
            feeToken: _params.order.feeToken,
            borrowedAmount: 0,
            amountOutMin: 0,
            deadline: _params.order.deadline,
            isSpot: _params.order.leverage == WadRayMath.WAD,
            isThirdAsset: false,
            takeDepositFromWallet: false,
            payFeeFromWallet: false,
            byOrder: true,
            sender: _params.sender,
            closeConditions: _params.closeConditions,
            needOracleTolerableLimitCheck: true
        });

        Position memory position = Position({
            id: 0,
            scaledDebtAmount: 0,
            bucket: IBucket(address(0)),
            soldAsset: address(0),
            depositAmountInSoldAsset: 0,
            positionAsset: _params.order.positionAsset,
            positionAmount: 0,
            trader: _params.order.trader,
            openBorrowIndex: 0,
            createdAt: block.timestamp,
            updatedConditionsAt: block.timestamp,
            extraParams: ""
        });

        if (vars.isSpot) {
            position.soldAsset = _params.order.depositAsset;
            position.depositAmountInSoldAsset = vars.depositData.depositAmount;
        } else {
            position.bucket = _params.order.bucket;
            position.soldAsset = address(position.bucket.borrowedAsset());
            vars.depositData.depositAsset = _params.order.depositAsset;
            vars.isThirdAsset =
                _params.order.depositAsset != position.soldAsset &&
                _params.order.depositAsset != _params.order.positionAsset;

            position.depositAmountInSoldAsset = PrimexPricingLibrary.getOracleAmountsOut(
                _params.order.depositAsset,
                position.soldAsset,
                _params.order.depositAmount,
                address(priceOracle)
            );
            vars.borrowedAmount = position.depositAmountInSoldAsset.wmul(_params.order.leverage - WadRayMath.WAD);
        }
        return (position, vars);
    }

    /**
     * @notice Calculates the health score for a position.
     * @param borrowedAssetAmountOut The amount of borrowed assets.
     * @param pairPriceDrop The priceDrop in WAD format of the pair.
     * @param securityBuffer The security buffer in WAD format.
     * @param oracleTolerableLimit The tolerable limit in WAD format for the oracle.
     * @param positionDebt The debt of the position.
     * @param feeBuffer The buffer for fees.
     * @return The health score of the position.
     */
    function health(
        uint256 borrowedAssetAmountOut,
        uint256 pairPriceDrop,
        uint256 securityBuffer,
        uint256 oracleTolerableLimit,
        uint256 positionDebt,
        uint256 feeBuffer
    ) public pure returns (uint256) {
        return
            (
                (WadRayMath.WAD - securityBuffer)
                    .wmul(WadRayMath.WAD - oracleTolerableLimit)
                    .wmul(WadRayMath.WAD - pairPriceDrop)
                    .wmul(borrowedAssetAmountOut)
            ).wdiv(feeBuffer.wmul(positionDebt));
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {BytesLib} from "./utils/BytesLib.sol";
import {WadRayMath} from "./utils/WadRayMath.sol";

import {NATIVE_CURRENCY, USD, USD_MULTIPLIER} from "../Constants.sol";
import {IDexAdapter} from "../interfaces/IDexAdapter.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IPrimexDNS, IPrimexDNSV2, IPrimexDNSStorage} from "../PrimexDNS/IPrimexDNS.sol";
import {IBucket} from "../Bucket/IBucket.sol";
import {IPositionManager} from "../PositionManager/IPositionManager.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";
import {TokenTransfersLibrary} from "./TokenTransfersLibrary.sol";

import "./Errors.sol";

library PrimexPricingLibrary {
    using WadRayMath for uint256;
    using BytesLib for bytes;

    struct Route {
        uint256 shares;
        SwapPath[] paths;
    }

    struct SwapPath {
        string dexName;
        bytes encodedPath;
    }

    struct MultiSwapParams {
        address tokenA;
        address tokenB;
        uint256 amountTokenA;
        Route[] routes;
        address dexAdapter;
        address receiver;
        uint256 deadline;
    }

    struct MultiSwapVars {
        uint256 sumOfShares;
        uint256 balance;
        uint256 amountOnDex;
        uint256 remainder;
        Route route;
    }

    struct AmountParams {
        address tokenA;
        address tokenB;
        uint256 amount;
        Route[] routes;
        address dexAdapter;
        address primexDNS;
    }

    struct LiquidationPriceCalculationParams {
        address bucket;
        address positionAsset;
        uint256 limitPrice;
        uint256 leverage;
    }

    struct DepositData {
        uint256 protocolFee;
        address depositAsset;
        uint256 depositAmount;
        uint256 leverage;
    }

    /**
     * @param depositData the deposit data through which the protocol fee can be calculated
     * if the position is opened through an order using deposit asset
     * @param feeToken An asset in which the fee will be paid. At this point it could be the pmx, the epmx or a native currency
     * @param isSwapFromWallet bool, the protocol fee is taken from the user wallet or from the Vault
     * @param trader trader address
     * @param priceOracle PriceOracle contract address
     * @param orderType Type of possible order in Primex protocol
     * @param traderBalanceVault TraderBalanceVault contract address
     * @param primexDNS PrimexDNS contract address
     */
    struct ProtocolFeeParams {
        DepositData depositData;
        address feeToken;
        bool isSwapFromWallet;
        address trader;
        address priceOracle;
        IPrimexDNSStorage.OrderType orderType;
        bool calculateFee;
        ITraderBalanceVault traderBalanceVault;
        IPrimexDNS primexDNS;
    }

    /**
     * The struct for payProtocolFee function
     */
    struct ProtocolFeeVars {
        bool fromLocked;
        address treasury;
    }

    /**
     * The struct for getLiquidationPrice and getLiquidationPriceByOrder functions
     */
    struct LiquidationPriceData {
        IBucket bucket;
        IPositionManager positionManager;
        IPriceOracle priceOracle;
        IERC20Metadata borrowedAsset;
    }

    event Withdraw(
        address indexed withdrawer,
        address borrowAssetReceiver,
        address borrowedAsset,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Encodes the given parameters into a bytes array based on the specified DEX type.
     * @param path The token path for the swap.
     * @param dexRouter The address of the DEX router.
     * @param ancillaryData Additional data required for certain DEX types.
     * @param dexAdapter The address of the DEX adapter.
     * @param isAmountToBuy A flag indicating whether it is the path for the swap with fixed amountIn or amountOut.
     * Swap with fixed amountIn, if true.
     * @return The encoded bytes array.
     */
    function encodePath(
        address[] memory path,
        address dexRouter,
        bytes32 ancillaryData,
        address dexAdapter,
        bool isAmountToBuy
    ) external view returns (bytes memory) {
        IDexAdapter.DexType type_ = IDexAdapter(dexAdapter).dexType(dexRouter);

        if (type_ == IDexAdapter.DexType.UniswapV2 || type_ == IDexAdapter.DexType.Meshswap) {
            return abi.encode(path);
        }
        if (type_ == IDexAdapter.DexType.UniswapV3) {
            if (isAmountToBuy)
                return bytes.concat(bytes20(path[1]), bytes3(uint24(uint256(ancillaryData))), bytes20(path[0]));
            return bytes.concat(bytes20(path[0]), bytes3(uint24(uint256(ancillaryData))), bytes20(path[1]));
        }
        if (type_ == IDexAdapter.DexType.AlgebraV3) {
            if (isAmountToBuy) return bytes.concat(bytes20(path[1]), bytes20(path[0]));
            return bytes.concat(bytes20(path[0]), bytes20(path[1]));
        }
        if (type_ == IDexAdapter.DexType.Curve) {
            address[] memory pools = new address[](1);
            pools[0] = address(uint160(uint256(ancillaryData)));
            return abi.encode(path, pools);
        }
        if (type_ == IDexAdapter.DexType.Balancer) {
            int256[] memory limits = new int256[](2);
            limits[0] = type(int256).max;
            bytes32[] memory pools = new bytes32[](1);
            pools[0] = ancillaryData;
            return abi.encode(path, pools, limits);
        }
        _revert(Errors.UNKNOWN_DEX_TYPE.selector);
    }

    /**
     * @notice Wrapped getAmountsOut to the dex
     * @param _params parameters necessary to get amount out
     * @return the amount of `tokenB` by the amount of 'tokenA' on dexes
     */
    function getAmountOut(AmountParams memory _params) public returns (uint256) {
        _require(_params.tokenA != _params.tokenB, Errors.IDENTICAL_ASSETS.selector);
        _require(
            IERC165(address(_params.primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        uint256 sumOfShares;
        for (uint256 i; i < _params.routes.length; i++) {
            sumOfShares += _params.routes[i].shares;
        }
        _require(sumOfShares > 0, Errors.SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO.selector);

        uint256 remainder = _params.amount;
        uint256 sum;
        uint256 amountOnDex;
        Route memory route;
        IDexAdapter.GetAmountsParams memory getAmountsParams;
        address[] memory path;

        for (uint256 i; i < _params.routes.length; i++) {
            route = _params.routes[i];
            amountOnDex = i == _params.routes.length - 1 ? remainder : (_params.amount * route.shares) / sumOfShares;
            remainder -= amountOnDex;

            for (uint256 j; j < route.paths.length; j++) {
                getAmountsParams.encodedPath = route.paths[j].encodedPath;
                getAmountsParams.amount = amountOnDex;
                getAmountsParams.dexRouter = IPrimexDNS(_params.primexDNS).getDexAddress(route.paths[j].dexName);
                path = decodePath(getAmountsParams.encodedPath, getAmountsParams.dexRouter, _params.dexAdapter);
                _require(path.length >= 2, Errors.INCORRECT_PATH.selector);
                amountOnDex = IDexAdapter(_params.dexAdapter).getAmountsOut(getAmountsParams)[1];
            }
            sum += amountOnDex;
        }

        return sum;
    }

    /**
     * @notice Wrapped getAmountIn to the dex
     * @param _params parameters necessary to get amount in
     * @return the amount of `tokenA` by the amount of 'tokenB' on dexes
     */
    function getAmountIn(AmountParams memory _params) public returns (uint256) {
        _require(_params.tokenA != _params.tokenB, Errors.IDENTICAL_ASSETS.selector);
        _require(
            IERC165(address(_params.primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        uint256 sumOfShares;
        for (uint256 i; i < _params.routes.length; i++) {
            sumOfShares += _params.routes[i].shares;
        }
        _require(sumOfShares > 0, Errors.SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO.selector);

        uint256 remainder = _params.amount;
        uint256 sum;
        uint256 amountOnDex;
        Route memory route;
        IDexAdapter.GetAmountsParams memory getAmountsParams;
        address[] memory path;

        for (uint256 i; i < _params.routes.length; i++) {
            route = _params.routes[i];
            amountOnDex = i == _params.routes.length - 1 ? remainder : (_params.amount * route.shares) / sumOfShares;
            remainder -= amountOnDex;
            for (uint256 j; j < route.paths.length; j++) {
                getAmountsParams.encodedPath = route.paths[route.paths.length - 1 - j].encodedPath;
                getAmountsParams.amount = amountOnDex;
                getAmountsParams.dexRouter = IPrimexDNS(_params.primexDNS).getDexAddress(
                    route.paths[route.paths.length - 1 - j].dexName
                );
                path = decodePath(getAmountsParams.encodedPath, getAmountsParams.dexRouter, _params.dexAdapter);
                _require(path.length >= 2, Errors.INCORRECT_PATH.selector);
                amountOnDex = IDexAdapter(_params.dexAdapter).getAmountsIn(getAmountsParams)[0];
            }
            sum += amountOnDex;
        }

        return sum;
    }

    /**
     * @notice Calculates the amount of deposit assets in borrowed assets.
     * @param _params The parameters for the calculation.
     * @param _isThirdAsset A flag indicating if deposit is in a third asset.
     * @param _priceOracle The address of the price oracle.
     * @return The amount of deposit assets is measured in borrowed assets.
     */
    function getDepositAmountInBorrowed(
        AmountParams memory _params,
        bool _isThirdAsset,
        address _priceOracle
    ) public returns (uint256) {
        _require(
            IERC165(_params.primexDNS).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        if (_params.tokenA == _params.tokenB) {
            _require(_params.routes.length == 0, Errors.DEPOSITED_TO_BORROWED_ROUTES_LENGTH_SHOULD_BE_0.selector);
            return _params.amount;
        }

        uint256 depositAmountInBorrowed = getAmountOut(_params);
        if (_isThirdAsset) {
            uint256 oracleDepositAmountOut = getOracleAmountsOut(
                _params.tokenA,
                _params.tokenB,
                _params.amount,
                _priceOracle
            );
            if (depositAmountInBorrowed > oracleDepositAmountOut) depositAmountInBorrowed = oracleDepositAmountOut;
        }

        return depositAmountInBorrowed;
    }

    /**
     * @notice Performs a multi-hop swap transaction using the specified parameters.
     * @dev This function executes a series of token swaps on different DEXs based on the provided routes.
     * @param _params The struct containing all the necessary parameters for the multi-hop swap.
     * @param _maximumOracleTolerableLimit The maximum tolerable limit in WAD format (1 WAD = 100%)
     * for the price difference between DEX and the oracle.
     * @param _primexDNS The address of the Primex DNS contract.
     * @param _priceOracle The address of the price oracle contract.
     * @param _needOracleTolerableLimitCheck Flag indicating whether to perform an oracle tolerable limit check.
     * @return The final balance of the _params.tokenB in the receiver's address after the multi-hop swap.
     */
    function multiSwap(
        MultiSwapParams memory _params,
        uint256 _maximumOracleTolerableLimit,
        address _primexDNS,
        address _priceOracle,
        bool _needOracleTolerableLimitCheck
    ) public returns (uint256) {
        _require(
            IERC165(_primexDNS).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        MultiSwapVars memory vars;
        vars.balance = IERC20Metadata(_params.tokenB).balanceOf(_params.receiver);
        for (uint256 i; i < _params.routes.length; i++) {
            vars.sumOfShares += _params.routes[i].shares;
        }
        _require(vars.sumOfShares > 0, Errors.SUM_OF_SHARES_SHOULD_BE_GREATER_THAN_ZERO.selector);

        vars.remainder = _params.amountTokenA;
        IDexAdapter.SwapParams memory swapParams;
        swapParams.deadline = _params.deadline;

        for (uint256 i; i < _params.routes.length; i++) {
            vars.route = _params.routes[i];
            vars.amountOnDex = i == _params.routes.length - 1
                ? vars.remainder
                : (_params.amountTokenA * vars.route.shares) / vars.sumOfShares;
            vars.remainder -= vars.amountOnDex;
            swapParams.to = _params.dexAdapter;

            for (uint256 j; j < vars.route.paths.length; j++) {
                swapParams.encodedPath = vars.route.paths[j].encodedPath;
                swapParams.amountIn = vars.amountOnDex;
                swapParams.dexRouter = IPrimexDNS(_primexDNS).getDexAddress(vars.route.paths[j].dexName);
                if (j == vars.route.paths.length - 1) {
                    swapParams.to = _params.receiver;
                }
                vars.amountOnDex = IDexAdapter(_params.dexAdapter).swapExactTokensForTokens(swapParams)[1];
            }
        }

        vars.balance = IERC20Metadata(_params.tokenB).balanceOf(_params.receiver) - vars.balance;
        if (_needOracleTolerableLimitCheck) {
            _require(
                vars.balance >=
                    getOracleAmountsOut(_params.tokenA, _params.tokenB, _params.amountTokenA, _priceOracle).wmul(
                        WadRayMath.WAD - _maximumOracleTolerableLimit
                    ),
                Errors.DIFFERENT_PRICE_DEX_AND_ORACLE.selector
            );
        }

        return vars.balance;
    }

    /**
     * @notice Pays the protocol fee.
     * @dev This function transfers the protocol fee from the trader to the protocol treasury.
     * @param params The parameters for paying the protocol fee.
     * @return protocolFee The amount of the protocol fee in PMX or NATIVE_CURRENCY paid.
     */
    function payProtocolFee(ProtocolFeeParams memory params) public returns (uint256 protocolFee) {
        if (!params.isSwapFromWallet || params.feeToken != NATIVE_CURRENCY) {
            _require(msg.value == 0, Errors.DISABLED_TRANSFER_NATIVE_CURRENCY.selector);
        }
        ProtocolFeeVars memory vars;
        vars.treasury = params.primexDNS.treasury();
        vars.fromLocked = true;

        protocolFee = params.depositData.protocolFee;
        if (params.calculateFee) {
            protocolFee = calculateProtocolFee(
                params.depositData,
                params.primexDNS,
                params.priceOracle,
                params.orderType,
                params.feeToken
            );
            if (protocolFee == 0) return 0;
            vars.fromLocked = false;
            if (params.isSwapFromWallet) {
                if (params.feeToken == NATIVE_CURRENCY) {
                    _require(msg.value >= protocolFee, Errors.INSUFFICIENT_DEPOSIT.selector);
                    TokenTransfersLibrary.doTransferOutETH(vars.treasury, protocolFee);
                    if (msg.value > protocolFee) {
                        uint256 rest = msg.value - protocolFee;
                        params.traderBalanceVault.topUpAvailableBalance{value: rest}(msg.sender, NATIVE_CURRENCY, rest);
                    }
                } else {
                    TokenTransfersLibrary.doTransferFromTo(params.feeToken, params.trader, vars.treasury, protocolFee);
                }
                return protocolFee;
            }
        }

        params.traderBalanceVault.withdrawFrom(
            params.trader,
            vars.treasury,
            params.feeToken,
            protocolFee,
            vars.fromLocked
        );
    }

    /**
     * @notice Calculate and return protocol fee
     * @param _depositData The deposit data through which the protocol fee can be calculated.
     * @param _primexDNS The address of the PrimexDNS contract.
     * @param _priceOracle The address of the PriceOracle contract.
     * @param _orderType Type of possible order in Primex protocol
     * @param _feeToken An asset in which the fee will be paid. At this point it could be the pmx, the epmx or a native currency
     * @return The amount of the protocol fee in '_feeToken' which needs to be paid according to the specified deposit parameters.
     */
    function calculateProtocolFee(
        DepositData memory _depositData,
        IPrimexDNS _primexDNS,
        address _priceOracle,
        IPrimexDNSStorage.OrderType _orderType,
        address _feeToken
    ) public view returns (uint256) {
        uint256 feeRate = _primexDNS.feeRates(_orderType, _feeToken);
        if (feeRate == 0) return 0;
        uint256 nativeFeeRate = _feeToken == NATIVE_CURRENCY
            ? feeRate
            : _primexDNS.feeRates(_orderType, NATIVE_CURRENCY);

        _depositData.protocolFee = getOracleAmountsOut(
            _depositData.depositAsset,
            NATIVE_CURRENCY,
            _depositData.depositAmount.wmul(_depositData.leverage).wmul(nativeFeeRate),
            _priceOracle
        );

        (uint256 minFee, uint256 maxFee) = IPrimexDNSV2(address(_primexDNS)).feeRestrictions(_orderType);
        if (minFee > _depositData.protocolFee) {
            _depositData.protocolFee = minFee;
        } else if (maxFee < _depositData.protocolFee) {
            _depositData.protocolFee = maxFee;
        }

        if (_feeToken != NATIVE_CURRENCY) {
            _require(nativeFeeRate != 0, Errors.FEE_RATE_IN_NATIVE_IS_ZERO.selector);
            uint256 discountMultiplier = feeRate.wdiv(nativeFeeRate);
            _depositData.protocolFee = getOracleAmountsOut(
                NATIVE_CURRENCY,
                _feeToken,
                _depositData.protocolFee.wmul(discountMultiplier),
                _priceOracle
            );
        }

        return _depositData.protocolFee;
    }

    /**
     * @param _tokenA asset for sell
     * @param _tokenB asset to buy
     * @param _amountAssetA Amount tokenA to sell
     * @param _priceOracle PriceOracle contract address
     * @return returns the amount of `tokenB` by the `amountAssetA` by the price of the oracle
     */
    function getOracleAmountsOut(
        address _tokenA,
        address _tokenB,
        uint256 _amountAssetA,
        address _priceOracle
    ) public view returns (uint256) {
        _require(
            IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        if (_tokenA == _tokenB) {
            return _amountAssetA;
        }
        (uint256 exchangeRate, bool isForward) = IPriceOracle(_priceOracle).getExchangeRate(_tokenA, _tokenB);
        uint256 amountAssetB;
        uint256 multiplier1 = _getAssetMultiplier(_tokenA);
        uint256 multiplier2 = _getAssetMultiplier(_tokenB);

        if (isForward) {
            amountAssetB = (_amountAssetA * multiplier1).wmul(exchangeRate) / multiplier2;
        } else {
            amountAssetB = (_amountAssetA * multiplier1).wdiv(exchangeRate) / multiplier2;
        }
        return amountAssetB;
    }

    /**
     * @param _tokenA asset for sell
     * @param _tokenB asset to buy
     * @param _amountsAssetA An array of amounts of tokenA to sell
     * @param _priceOracle PriceOracle contract address
     * @return returns an array of amounts of `tokenB` by the `amountsAssetA` by the price of the oracle
     */
    function getBatchOracleAmountsOut(
        address _tokenA,
        address _tokenB,
        uint256[] memory _amountsAssetA,
        address _priceOracle
    ) public view returns (uint256[] memory) {
        _require(
            IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        if (_tokenA == _tokenB) {
            return _amountsAssetA;
        }
        uint256[] memory amountsAssetB = new uint256[](_amountsAssetA.length);
        (uint256 exchangeRate, bool isForward) = IPriceOracle(_priceOracle).getExchangeRate(_tokenA, _tokenB);
        uint256 multiplier1 = 10 ** (18 - IERC20Metadata(_tokenA).decimals());
        uint256 multiplier2 = 10 ** (18 - IERC20Metadata(_tokenB).decimals());

        if (isForward) {
            for (uint256 i; i < _amountsAssetA.length; i++) {
                amountsAssetB[i] = (_amountsAssetA[i] * multiplier1).wmul(exchangeRate) / multiplier2;
            }
        } else {
            for (uint256 i; i < _amountsAssetA.length; i++) {
                amountsAssetB[i] = (_amountsAssetA[i] * multiplier1).wdiv(exchangeRate) / multiplier2;
            }
        }
        return amountsAssetB;
    }

    /**
     * @notice Calculates the liquidation price for a position.
     * @dev liquidationPrice = (feeBuffer * debt) /
     * ((1 - securityBuffer) * (1 - oracleTolerableLimit) * (1 - priceDrop) * positionAmount))
     * @param _bucket The address of the related bucket.
     * @param _positionAsset The address of the position asset.
     * @param _positionAmount The size of the opened position.
     * @param _positionDebt The debt amount in debtTokens associated with the position.
     * @return The calculated liquidation price in borrowed asset.
     */
    function getLiquidationPrice(
        address _bucket,
        address _positionAsset,
        uint256 _positionAmount,
        uint256 _positionDebt
    ) public view returns (uint256) {
        _require(_positionAsset != address(0), Errors.ADDRESS_NOT_SUPPORTED.selector);
        LiquidationPriceData memory data;
        data.bucket = IBucket(_bucket);

        (, bool tokenAllowed) = data.bucket.allowedAssets(_positionAsset);
        _require(tokenAllowed, Errors.TOKEN_NOT_SUPPORTED.selector);

        data.positionManager = data.bucket.positionManager();
        data.borrowedAsset = data.bucket.borrowedAsset();
        data.priceOracle = data.positionManager.priceOracle();

        uint256 multiplier1 = 10 ** (18 - data.borrowedAsset.decimals());
        uint256 denominator = (WadRayMath.WAD - data.positionManager.securityBuffer())
            .wmul(
                WadRayMath.WAD -
                    data.positionManager.getOracleTolerableLimit(_positionAsset, address(data.borrowedAsset))
            )
            .wmul(WadRayMath.WAD - data.priceOracle.getPairPriceDrop(_positionAsset, address(data.borrowedAsset)))
            .wmul(_positionAmount) * 10 ** (18 - IERC20Metadata(_positionAsset).decimals());
        // numerator = data.bucket.feeBuffer().wmul(_positionDebt) * multiplier1;
        return (data.bucket.feeBuffer().wmul(_positionDebt) * multiplier1).wdiv(denominator) / multiplier1;
    }

    /**
     * @notice Validates if a position meets the minimum size requirement.
     * @param _minPositionSize The minimum position size.
     * @param _minPositionAsset The asset associated with the minimum position size.
     * @param _amount The amount of the asset in the position.
     * @param _asset The asset associated with the position.
     * @param _priceOracle The address of the price oracle contract.
     */
    function validateMinPositionSize(
        uint256 _minPositionSize,
        address _minPositionAsset,
        uint256 _amount,
        address _asset,
        address _priceOracle
    ) public view {
        _require(
            isCorrespondsMinPositionSize(_minPositionSize, _minPositionAsset, _asset, _amount, _priceOracle),
            Errors.INSUFFICIENT_POSITION_SIZE.selector
        );
    }

    /**
     * @notice Checks if the given amount of _asset corresponds to the minimum position size _minPositionSize,
     * based on the _minPositionAsset and the provided _priceOracle.
     * Returns true if the amount corresponds to or exceeds the minimum position size, otherwise returns false.
     * @param _minPositionSize The minimum position size required.
     * @param _minPositionAsset The address of the asset used for determining the minimum position size.
     * @param _asset The address of the asset being checked.
     * @param _amount The amount of _asset being checked.
     * @param _priceOracle The address of the price oracle contract.
     * @return A boolean value indicating whether the amount corresponds to or exceeds the minimum position size.
     */
    function isCorrespondsMinPositionSize(
        uint256 _minPositionSize,
        address _minPositionAsset,
        address _asset,
        uint256 _amount,
        address _priceOracle
    ) public view returns (bool) {
        if (_minPositionSize == 0) return true;

        uint256 amountInMinPositionAsset = getOracleAmountsOut(_asset, _minPositionAsset, _amount, _priceOracle);
        return amountInMinPositionAsset >= _minPositionSize;
    }

    /**
     * @notice Decodes an encoded path and returns an array of addresses.
     * @param encodedPath The encoded path to be decoded.
     * @param dexRouter The address of the DEX router.
     * @param dexAdapter The address of the DEX adapter.
     * @return path An array of addresses representing the decoded path.
     */
    function decodePath(
        bytes memory encodedPath,
        address dexRouter,
        address dexAdapter
    ) public view returns (address[] memory path) {
        IDexAdapter.DexType type_ = IDexAdapter(dexAdapter).dexType(dexRouter);

        if (type_ == IDexAdapter.DexType.UniswapV2 || type_ == IDexAdapter.DexType.Meshswap) {
            path = abi.decode(encodedPath, (address[]));
        } else if (type_ == IDexAdapter.DexType.UniswapV3) {
            uint256 skip;
            uint256 offsetSize = 23; // address size(20) + fee size(3)
            uint256 pathLength = encodedPath.length / offsetSize + 1;
            path = new address[](pathLength);
            for (uint256 i; i < pathLength; i++) {
                path[i] = encodedPath.toAddress(skip, encodedPath.length);
                skip += offsetSize;
            }
        } else if (type_ == IDexAdapter.DexType.Curve) {
            (path, ) = abi.decode(encodedPath, (address[], address[]));
        } else if (type_ == IDexAdapter.DexType.Balancer) {
            (path, , ) = abi.decode(encodedPath, (address[], bytes32[], int256[]));
        } else if (type_ == IDexAdapter.DexType.AlgebraV3) {
            uint256 skip;
            uint256 offsetSize = 20; // address size(20)
            uint256 pathLength = encodedPath.length / offsetSize;
            path = new address[](pathLength);
            for (uint256 i; i < pathLength; i++) {
                path[i] = encodedPath.toAddress(skip, encodedPath.length);
                skip += offsetSize;
            }
        } else {
            _revert(Errors.UNKNOWN_DEX_TYPE.selector);
        }
    }

    /**
     * @notice Retrieves the price from two price feeds.
     * @dev This function returns the price ratio between the base price and the quote price.
     * @param basePriceFeed The address of the base price feed (AggregatorV3Interface).
     * @param quotePriceFeed The address of the quote price feed (AggregatorV3Interface).
     * @param roundBaseFeed The round ID of the base price feed.
     * @param roundQuoteFeed The round ID of the quote price feed.
     * @param checkedTimestamp The timestamp used to filter relevant prices. Set to 0 to consider all prices.
     * @return The price ratio in WAD format between the base price and the quote price, and the timestamp of the latest price.
     */
    function getPriceFromFeeds(
        AggregatorV3Interface basePriceFeed,
        AggregatorV3Interface quotePriceFeed,
        uint80 roundBaseFeed,
        uint80 roundQuoteFeed,
        uint256 checkedTimestamp
    ) internal view returns (uint256, uint256) {
        (, int256 basePrice, , uint256 basePriceUpdatedAt, ) = basePriceFeed.getRoundData(roundBaseFeed);
        (, , , uint256 basePriceUpdatedAtNext, ) = basePriceFeed.getRoundData(roundBaseFeed + 1);
        // update to current timestamp if roundBaseFeed is last round
        if (basePriceUpdatedAtNext == 0) basePriceUpdatedAtNext = block.timestamp;

        (, int256 quotePrice, , uint256 quotePriceUpdatedAt, ) = quotePriceFeed.getRoundData(roundQuoteFeed);
        (, , , uint256 quotePriceUpdatedAtNext, ) = quotePriceFeed.getRoundData(roundQuoteFeed + 1);
        // update to current timestamp if roundQuoteFeed is last round
        if (quotePriceUpdatedAtNext == 0) quotePriceUpdatedAtNext = block.timestamp;

        _require(basePriceUpdatedAt > 0 && quotePriceUpdatedAt > 0, Errors.DATA_FOR_ROUND_DOES_NOT_EXIST.selector);

        // we work only with prices that were relevant after position creation
        _require(
            checkedTimestamp == 0 ||
                (basePriceUpdatedAtNext > checkedTimestamp && quotePriceUpdatedAtNext > checkedTimestamp),
            Errors.HIGH_PRICE_TIMESTAMP_IS_INCORRECT.selector
        );
        // there should be an intersection between their duration
        _require(
            quotePriceUpdatedAt < basePriceUpdatedAtNext && basePriceUpdatedAt < quotePriceUpdatedAtNext,
            Errors.NO_PRICE_FEED_INTERSECTION.selector
        );
        //the return value will always be 18 decimals if the basePrice and quotePrice have the same decimals
        return (
            uint256(basePrice).wdiv(uint256(quotePrice)),
            quotePriceUpdatedAt < basePriceUpdatedAt ? quotePriceUpdatedAt : basePriceUpdatedAt
        );
    }

    /**
     * @notice Returns the asset multiplier for a given asset.
     * @dev If the asset is the native currency, the function returns 1.
     * If the asset is USD, the function returns the value stored in the constant USD_MULTIPLIER.
     * For any other asset, the function calculates the multiplier based on the number of decimals of the token.
     * @param _asset The address of the asset.
     * @return The asset multiplier. It is a number with 10 raised to a power of decimals of a given asset.
     */
    function _getAssetMultiplier(address _asset) internal view returns (uint256) {
        if (_asset == NATIVE_CURRENCY) return 1;
        if (_asset == USD) return USD_MULTIPLIER;

        return 10 ** (18 - IERC20Metadata(_asset).decimals());
    }
}

// Copyright 2020 Compound Labs, Inc.
// (c) 2023 Primex.finance
// SPDX-License-Identifier: BSD-3-Clause

// Modified version of token transfer logic that allows working with non-standart ERC-20 tokens, added method doTransferFromTo,
// modified doTransferIn

pragma solidity 0.8.18;

import "./Errors.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP20NonStandardInterface} from "../interfaces/EIP20NonStandardInterface.sol";

library TokenTransfersLibrary {
    function doTransferIn(address token, address from, uint256 amount) public returns (uint256) {
        return doTransferFromTo(token, from, address(this), amount);
    }

    function doTransferFromTo(address token, address from, address to, uint256 amount) public returns (uint256) {
        uint256 balanceBefore = IERC20(token).balanceOf(to);
        // The returned value is checked in the assembly code below.
        // Arbitrary `from` should be checked at a higher level. The library function cannot be called by the user.
        // slither-disable-next-line unchecked-transfer arbitrary-send-erc20
        EIP20NonStandardInterface(token).transferFrom(from, to, amount);

        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        _require(success, Errors.TOKEN_TRANSFER_IN_FAILED.selector);

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(token).balanceOf(to);
        _require(balanceAfter >= balanceBefore, Errors.TOKEN_TRANSFER_IN_OVERFLOW.selector);

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    function doTransferOut(address token, address to, uint256 amount) public {
        // The returned value is checked in the assembly code below.
        // slither-disable-next-line unchecked-transfer
        EIP20NonStandardInterface(token).transfer(to, amount);

        bool success;
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        _require(success, Errors.TOKEN_TRANSFER_OUT_FAILED.selector);
    }

    function doTransferOutETH(address to, uint256 value) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: value}(new bytes(0));
        _require(success, Errors.NATIVE_TOKEN_TRANSFER_FAILED.selector);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// A modified version of BytesLib
// Origin: https://github.com/1inch/universal-router/blob/b972662f8d3f0ba55ef99411720f613f77c3fab5/contracts/modules/uniswap/v3/BytesLib.sol
// Unused methods and constants were removed
pragma solidity 0.8.18;

library BytesLib {
    error ToAddressOverflow();
    error ToAddressOutOfBounds();

    /// @notice Returns the address starting at byte `_start`
    /// @dev _bytesLength must equal _bytes.length for this to function correctly
    /// @param _bytes The input bytes string to slice
    /// @param _start The starting index of the address
    /// @param _bytesLength The length of _bytes
    /// @return tempAddress The address starting at _start
    function toAddress(
        bytes memory _bytes,
        uint256 _start,
        uint256 _bytesLength
    ) internal pure returns (address tempAddress) {
        unchecked {
            if (_start + 20 < _start) revert ToAddressOverflow();
            if (_bytesLength < _start + 20) revert ToAddressOutOfBounds();
        }

        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

// A modified version of ds-math library
// Origin: https://github.com/dapphub/ds-math/blob/master/src/math.sol
// Unused methods were removed, errors changed

pragma solidity 0.8.18;
error DS_MATH_ADD_OVERFLOW();
error DS_MATH_MUL_OVERFLOW();

library WadRayMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if ((z = x + y) < x) revert DS_MATH_ADD_OVERFLOW();
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (!(y == 0 || (z = x * y) / y == x)) revert DS_MATH_MUL_OVERFLOW();
    }

    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < RAY / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";
import {IWhiteBlackList} from "../WhiteBlackList/WhiteBlackList/IWhiteBlackList.sol";
import {ILiquidityMiningRewardDistributorStorage} from "./ILiquidityMiningRewardDistributorStorage.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface ILiquidityMiningRewardDistributor is ILiquidityMiningRewardDistributorStorage, IPausable {
    struct RewardsInPMX {
        uint256 minReward;
        uint256 maxReward;
        uint256 extraReward;
    }

    /**
     * @notice Emitted when a reward is claimed by a receiver from a specific bucket.
     * @param receiver The address of the receiver.
     * @param bucket The address of the bucket from which the reward is claimed.
     * @param amount The amount of the claimed reward.
     */
    event ClaimedReward(address indexed receiver, address indexed bucket, uint256 amount);
    /**
     * @notice Emitted when PMX tokens are withdrawn by an admin.
     * @param amount The amount of PMX tokens withdrawn.
     */
    event WithdrawPmxByAdmin(uint256 indexed amount);

    /**
     * @notice Initializes the contract with the specified parameters.
     * @param _primexDNS The address of the IPrimexDNS contract.
     * @param _pmx The address of the PMX token contract.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _registry The address of the registry contract.
     * @param _treasury The address of the treasury contract.
     * @param _reinvestmentRate The rate at which rewards are reinvested.
     * @param _reinvestmentDuration The duration for which rewards are reinvested.
     * @param _whiteBlackList The address of the WhiteBlackList contract.
     */
    function initialize(
        IPrimexDNS _primexDNS,
        IERC20 _pmx,
        ITraderBalanceVault _traderBalanceVault,
        address _registry,
        address _treasury,
        uint256 _reinvestmentRate,
        uint256 _reinvestmentDuration,
        IWhiteBlackList _whiteBlackList
    ) external;

    /**
     * @notice Updates the reward amount for a specific bucket.
     * @dev Only callable by the PrimexDNS contract.
     * @param _bucketName The name of the bucket.
     * @param _pmxRewardsAmount The amount of PMX rewards to be allocated to the bucket.
     */
    function updateBucketReward(string memory _bucketName, uint256 _pmxRewardsAmount) external;

    /**
     * @notice Adds points for a user for future reward distribution.
     * @dev Only callable by the Bucket contract.
     * @param _bucketName The name of the bucket.
     * @param _user The address of the user.
     * @param _miningAmount The amount of mining points to be added.
     * @param _maxStabilizationPeriodEnd The maximum end timestamp of the stabilization period.
     * @param _maxPeriodTime The maximum period time.
     * @param _currentTimestamp The current timestamp.
     */
    function addPoints(
        string memory _bucketName,
        address _user,
        uint256 _miningAmount,
        uint256 _maxStabilizationPeriodEnd,
        uint256 _maxPeriodTime,
        uint256 _currentTimestamp
    ) external;

    /**
     * @notice Removes points for a user.
     * @dev Only callable by the Bucket contract.
     * @param _name The name of the bucket.
     * @param _user The address of the user.
     * @param _amount The amount of mining points to be removed.
     */
    function removePoints(string memory _name, address _user, uint256 _amount) external;

    /**
     * @notice Claims the accumulated rewards for a specific bucket.
     * @param _bucketName The name of the bucket.
     */
    function claimReward(string memory _bucketName) external;

    /**
     * @notice Moves rewards from one bucket to another.
     * @dev Only callable by the Bucket contract.
     * @param _bucketFrom The name of the source bucket.
     * @param _bucketTo The name of the destination bucket.
     * @param _user The address of the user.
     * @param _isBucketLaunched A flag indicating if the destination bucket is launched.
     * @param _liquidityMiningDeadline The deadline for liquidity mining
     */
    function reinvest(
        string memory _bucketFrom,
        string memory _bucketTo,
        address _user,
        bool _isBucketLaunched,
        uint256 _liquidityMiningDeadline
    ) external;

    /**
     * @dev The function to withdraw PMX from a delisted bucket or a bucket where liquidity mining failed (after reinvesting period).
     * Emits WithdrawPmxByAdmin event.
     * @param _bucketFrom Name of the bucket with failed liquidity mining event.
     */
    function withdrawPmxByAdmin(string memory _bucketFrom) external;

    /**
     * @notice Retrieves information about a lender in a specific bucket.
     * @param _bucketName The name of the bucket.
     * @param _lender The address of the lender.
     * @param _timestamp The timestamp for which the information is queried.
     * @return amountInMining The amount of tokens the lender has in mining for the given bucket.
     * @return currentPercent The current percentage of rewards the lender is eligible to receive for the given bucket.
     * Measured in WAD (1 WAD = 100%).
     * @return rewardsInPMX An object containing information about the lender's rewards in PMX for the given bucket.
     */
    function getLenderInfo(
        string calldata _bucketName,
        address _lender,
        uint256 _timestamp
    ) external view returns (uint256 amountInMining, uint256 currentPercent, RewardsInPMX memory rewardsInPMX);

    /**
     * @notice Retrieves rewards information about a specific bucket.
     * @param _bucketName The name of the bucket.
     * @return totalPmxReward The total amount of PMX reward in the bucket.
     * @return withdrawnRewards The total amount of withdrawn rewards from the bucket.
     * @return totalPoints The total number of mining points in the bucket.
     */
    function getBucketInfo(
        string calldata _bucketName
    ) external view returns (uint256 totalPmxReward, uint256 withdrawnRewards, uint256 totalPoints);

    /**
     * @notice Retrieves the amount of tokens a lender has in mining for a specific bucket.
     * @param _bucket The name of the bucket.
     * @param _lender The address of the lender.
     * @return The amount of tokens the lender has in mining for the given bucket.
     */
    function getLenderAmountInMining(string calldata _bucket, address _lender) external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";

interface ILiquidityMiningRewardDistributorStorage {
    struct LenderInfo {
        uint256 points;
        uint256 depositedAmount;
    }

    struct BucketInfo {
        uint256 totalPoints;
        uint256 totalPmxReward;
        uint256 withdrawnRewards;
        mapping(address => LenderInfo) lendersInfo;
    }

    function primexDNS() external view returns (IPrimexDNS);

    function pmx() external view returns (IERC20);

    function traderBalanceVault() external view returns (ITraderBalanceVault);

    function registry() external view returns (address);

    function reinvestmentRate() external view returns (uint256);

    function reinvestmentDuration() external view returns (uint256);

    function extraRewards(address, string calldata) external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {LimitOrderLibrary} from "../libraries/LimitOrderLibrary.sol";
import {PrimexPricingLibrary} from "../libraries/PrimexPricingLibrary.sol";
import {PositionLibrary} from "../libraries/PositionLibrary.sol";

import {IPositionManagerStorage} from "./IPositionManagerStorage.sol";
import {IKeeperRewardDistributor} from "../KeeperRewardDistributor/IKeeperRewardDistributor.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface IPositionManager is IPositionManagerStorage, IPausable {
    struct ClosePositionVars {
        PositionLibrary.Position position;
        bool borrowedAmountIsNotZero;
        uint256 oracleTolerableLimit;
        bool needOracleTolerableLimitCheck;
    }

    event SetMaxPositionSize(address token0, address token1, uint256 amountInToken0, uint256 amountInToken1);
    event SetDefaultOracleTolerableLimit(uint256 indexed oracleTolerableLimit);
    event SecurityBufferChanged(uint256 indexed securityBuffer);
    event MaintenanceBufferChanged(uint256 indexed maintenanceBuffer);
    event SetOracleTolerableLimit(address indexed assetA, address indexed assetB, uint256 oracleTolerableLimit);
    event KeeperRewardDistributorChanged(address indexed _keeperRewardDistributor);
    event MinPositionSizeAndAssetChanged(uint256 indexed _minPositionSize, address indexed _minPositionAsset);
    event OracleTolerableLimitMultiplierChanged(uint256 indexed newMultiplier);

    event OpenPosition(
        uint256 indexed positionId,
        address indexed trader,
        address indexed openedBy,
        PositionLibrary.Position position,
        address feeToken,
        uint256 protocolFee,
        uint256 entryPrice,
        uint256 leverage,
        LimitOrderLibrary.Condition[] closeConditions
    );

    event PartialClosePosition(
        uint256 indexed positionId,
        address indexed trader,
        address bucketAddress,
        address soldAsset,
        address positionAsset,
        uint256 decreasePositionAmount,
        uint256 depositedAmount,
        uint256 scaledDebtAmount,
        int256 profit,
        uint256 positionDebt,
        uint256 amountOut
    );

    event IncreaseDeposit(
        uint256 indexed positionId,
        address indexed trader,
        uint256 depositDelta,
        uint256 scaledDebtAmount
    );

    event DecreaseDeposit(
        uint256 indexed positionId,
        address indexed trader,
        uint256 depositDelta,
        uint256 scaledDebtAmount
    );

    event UpdatePositionConditions(
        uint256 indexed positionId,
        address indexed trader,
        LimitOrderLibrary.Condition[] closeConditions
    );

    /**
     * @notice Initializes the contract with the specified addresses and initializes inherited contracts.
     * @param _registry The address of the Registry contract.
     * @param _primexDNS The address of the PrimexDNS contract.
     * @param _traderBalanceVault The address of the TraderBalanceVault contract.
     * @param _priceOracle The address of the PriceOracle contract.
     * @param _keeperRewardDistributor The address of the KeeperRewardDistributor contract.
     * @param _whiteBlackList The address of the WhiteBlacklist contract.
     */
    function initialize(
        address _registry,
        address _primexDNS,
        address payable _traderBalanceVault,
        address _priceOracle,
        address _keeperRewardDistributor,
        address _whiteBlackList
    ) external;

    /**
     * @notice Sets the maximum position size for a pair of tokens.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _token0 The address of the first token in the pair.
     * @param _token1 The address of the second token in the pair.
     * @param _amountInToken0 The maximum amount of token0 allowed in the position.
     * @param _amountInToken1 The maximum amount of token1 allowed in the position.
     */
    function setMaxPositionSize(
        address _token0,
        address _token1,
        uint256 _amountInToken0,
        uint256 _amountInToken1
    ) external;

    /**
     * @notice Sets the default oracle tolerable limit for the protocol.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _percent The new value for the default oracle tolerable limit. Measured in WAD (1 WAD = 100%).
     */
    function setDefaultOracleTolerableLimit(uint256 _percent) external;

    /**
     * @notice Sets the oracle tolerable limit between two assets.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _assetA The address of the first asset.
     * @param _assetB The address of the second asset.
     * @param _percent The new value for the oracle tolerable limit between two assets. Measured in WAD (1 WAD = 100%).
     */
    function setOracleTolerableLimit(address _assetA, address _assetB, uint256 _percent) external;

    /**
     * @notice Function to set oracleTolerableLimitMultiplier.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param newMultiplier New multiplier in WAD format.
     */
    function setOracleTolerableLimitMultiplier(uint256 newMultiplier) external;

    /**
     * @notice Sets the security buffer value.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * 0 <= newSecurityBuffer < 1.
     * Buffer security parameter is used in calculating the liquidation conditions
     * https://docs.google.com/document/d/1kR8eaqV4289MAbLKgIfKsZ2NgjFpeC0vpVL7jVUTvho/edit#bookmark=id.i9v508hvrv42
     * @param newSecurityBuffer The new value of the security buffer in WAD format.
     */
    function setSecurityBuffer(uint256 newSecurityBuffer) external;

    /**
     * @notice Sets the maintenance buffer value.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * The new maintenance buffer value should be greater than zero and less than one.
     * Maintenance buffer is used in calculating the maximum leverage
     * https://docs.google.com/document/d/1kR8eaqV4289MAbLKgIfKsZ2NgjFpeC0vpVL7jVUTvho/edit#bookmark=id.87oc1j1s9z21
     * @param newMaintenanceBuffer The new value of the maintenance buffer in WAD format.
     */
    function setMaintenanceBuffer(uint256 newMaintenanceBuffer) external;

    /**
     * @notice Sets the address of the SpotTradingRewardDistributor contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _spotTradingRewardDistributor The address of the SpotTradingRewardDistributor contract.
     */
    function setSpotTradingRewardDistributor(address _spotTradingRewardDistributor) external;

    /**
     * @notice Sets the KeeperRewardDistributor contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _keeperRewardDistributor The address of the KeeperRewardDistributor contract.
     */
    function setKeeperRewardDistributor(IKeeperRewardDistributor _keeperRewardDistributor) external;

    /**
     * @notice Opens a position based on the provided order parameters.
     * @dev Only callable by the LOM_ROLE role.
     * @param _params The parameters for opening a position.
     * @return The total borrowed amount, position amount, position ID, and entry price of the new position.
     */
    function openPositionByOrder(
        LimitOrderLibrary.OpenPositionByOrderParams calldata _params
    ) external returns (uint256, uint256, uint256, uint256);

    /**
     * @notice Opens margin position.
     * @dev Locks trader's collateral in TraderBalanceVault. Takes loan from bucket for deal.
     * Makes swap bucket borrowedAsset amount on '_dex'. Updates rates and indexes in the '_bucket'.
     * Mints debtToken for trader (msg.sender)
     * @param _params The parameters required to open a position.
     */
    function openPosition(PositionLibrary.OpenPositionParams calldata _params) external payable;

    /**
     * @notice Close trader's active position or liquidate risky position.
     * @dev Protocol will fall down (revert) if two conditions occur both:
     * 1. (token1Price + position.depositedAmount).wdiv(positionDebt) will become lower than 1,
     * so position will make loss for Protocol.
     * 2. Not enough liquidity in bucket to pay that loss.
     * @param _id Position id for `msg.sender`.
     * @param _dealReceiver The receiver of the rest of trader's deposit.
     * @param _routes swap routes on dexes
     * @param _amountOutMin minimum allowed amount out for position
     */
    function closePosition(
        uint256 _id,
        address _dealReceiver,
        PrimexPricingLibrary.Route[] memory _routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @notice Closes trader's active position by closing condition
     * @param _id Position id.
     * @param _keeper The address of the keeper or the recipient of the reward.
     * @param _routes An array of routes for executing trades, swap routes on dexes.
     * @param _conditionIndex The index of the condition to be used for closing the position.
     * @param _ccmAdditionalParams Additional params needed for canBeClosed() of the ConditionalClosingManager.
     * @param _closeReason The reason for closing the position.
     */
    function closePositionByCondition(
        uint256 _id,
        address _keeper,
        PrimexPricingLibrary.Route[] calldata _routes,
        uint256 _conditionIndex,
        bytes calldata _ccmAdditionalParams,
        PositionLibrary.CloseReason _closeReason
    ) external;

    /**
     * @notice Allows the trader to partially close a position.
     * @param _positionId The ID of the position to be partially closed.
     * @param _amount The amount of the position asset to be closed from the position.
     * @param _depositReceiver The address where the remaining deposit will be sent.
     * @param _routes The routing information for swapping assets.
     * @param _amountOutMin The minimum amount to be received after swapping, measured in the same decimal format as the position's asset.
     */
    function partiallyClosePosition(
        uint256 _positionId,
        uint256 _amount,
        address _depositReceiver,
        PrimexPricingLibrary.Route[] calldata _routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @notice Updates the position with the given position ID by setting new close conditions.
     * @param _positionId The ID of the position to update.
     * @param _closeConditions An array of close conditions for the position.
     * @dev The caller of this function must be the trader who owns the position.
     * @dev Emits an `UpdatePositionConditions` event upon successful update.
     */
    function updatePositionConditions(
        uint256 _positionId,
        LimitOrderLibrary.Condition[] calldata _closeConditions
    ) external;

    /**
     * @notice Increases the deposit amount for a given position.
     * @param _positionId The ID of the position to increase the deposit for.
     * @param _amount The amount to increase the deposit by.
     * @param _asset The address of the asset to deposit.
     * @param _takeDepositFromWallet A flag indicating whether to make the deposit immediately.
     * @param _routes An array of routes to use for trading.
     * @param _amountOutMin The minimum amount of the output asset to receive from trading.
     */
    function increaseDeposit(
        uint256 _positionId,
        uint256 _amount,
        address _asset,
        bool _takeDepositFromWallet,
        PrimexPricingLibrary.Route[] calldata _routes,
        uint256 _amountOutMin
    ) external;

    /**
     * @notice Decreases the deposit amount for a given position.
     * @param _positionId The ID of the position.
     * @param _amount The amount to decrease the deposit by.
     */
    function decreaseDeposit(uint256 _positionId, uint256 _amount) external;

    /**
     * @notice Sets the minimum position size and the corresponding asset for positions.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _minPositionSize The new minimum position size.
     * @param _minPositionAsset The address of the asset associated with the minimum position size.
     */
    function setMinPositionSize(uint256 _minPositionSize, address _minPositionAsset) external;

    /**
     * @notice Checks if a position can be closed based on a specific condition.
     * @param _positionId The ID of the position.
     * @param _conditionIndex The index of the condition within the position's close conditions.
     * @param _additionalParams Additional parameters required for the condition check.
     * @return A boolean indicating whether the position can be closed.
     */
    function canBeClosed(
        uint256 _positionId,
        uint256 _conditionIndex,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Deletes a positions by their IDs from a specific bucket for a given traders.
     * @param _ids The IDs of the positions to be deleted.
     * @param _traders The addresses of the traders who owns the position.
     * @param _length The length of the traders array.
     * @param _bucket The address of the bucket from which the position is to be deleted.
     */
    function deletePositions(
        uint256[] calldata _ids,
        address[] calldata _traders,
        uint256 _length,
        address _bucket
    ) external;

    /**
     * @notice Transfers a specified amount of tokens from the contract to a specified address.
     * @dev Only callable by the BATCH_MANAGER_ROLE role.
     * @param _token The address of the token to be transferred.
     * @param _to The address to which the tokens will be transferred.
     * @param _amount The amount of tokens to be transferred.
     */
    function doTransferOut(address _token, address _to, uint256 _amount) external;

    /**
     * @notice Returns the oracle tolerable limit for the given asset pair.
     * @param assetA The address of the first asset in the pair.
     * @param assetB The address of the second asset in the pair.
     * @return The oracle tolerable limit in WAD format (1 WAD = 100%) for the asset pair.
     */
    function getOracleTolerableLimit(address assetA, address assetB) external view returns (uint256);

    /**
     * @notice Retrieves the position information for a given ID.
     * @param _id The ID of the position to retrieve.
     * @return position The position information associated with the given ID.
     */
    function getPosition(uint256 _id) external view returns (PositionLibrary.Position memory);

    /**
     * @notice Retrieves the position at the specified index.
     * @param _index The index of the position to retrieve.
     * @return The Position struct at the specified index.
     */
    function getPositionByIndex(uint256 _index) external view returns (PositionLibrary.Position memory);

    /**
     * @notice Returns the length of the positions array.
     * @return The length of the positions array.
     */
    function getAllPositionsLength() external view returns (uint256);

    /**
     * @notice Returns the length of the array containing the positions of a specific trader.
     * @param _trader The address of the trader.
     * @return The number of positions the trader has.
     */
    function getTraderPositionsLength(address _trader) external view returns (uint256);

    /**
     * @notice Returns the length of the array containing the positions of a specific bucket.
     * @param _bucket The address of the bucket.
     * @return The number of positions the bucket has.
     */
    function getBucketPositionsLength(address _bucket) external view returns (uint256);

    /**
     * @notice Returns the debt of a position with the given ID.
     * @param _id The ID of the position.
     * @return The debt of the position, measured in the same decimal format as debtTokens.
     */
    function getPositionDebt(uint256 _id) external view returns (uint256);

    /**
     * @notice Retrieves the close conditions for a specific position.
     * @param _positionId The ID of the position.
     * @return An array of close conditions associated with the position.
     */
    function getCloseConditions(uint256 _positionId) external view returns (LimitOrderLibrary.Condition[] memory);

    /**
     * @notice Retrieves the close condition for a given position and index.
     * @param _positionId The identifier of the position.
     * @param _index The index of the close condition.
     * @return The close condition at the specified position and index.
     */
    function getCloseCondition(
        uint256 _positionId,
        uint256 _index
    ) external view returns (LimitOrderLibrary.Condition memory);

    /**
     * @notice Сhecks if the position is risky.
     * @param _id the id of the position
     * @return (1) True if position is risky
     */
    function isPositionRisky(uint256 _id) external view returns (bool);

    /**
     * @notice Checks if a position with the given ID is delisted.
     * @param _id The ID of the position.
     * @return A boolean indicating whether the position is delisted or not.
     */
    function isDelistedPosition(uint256 _id) external view returns (bool);

    /**
     * @notice Retrieves the health value of a position.
     * @param _id The ID of the position.
     * @return The health value of the position in WAD format.
     */
    function healthPosition(uint256 _id) external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {PositionLibrary} from "../libraries/PositionLibrary.sol";
import {LimitOrderLibrary} from "../libraries/LimitOrderLibrary.sol";

import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IPriceOracle} from "../PriceOracle/IPriceOracle.sol";
import {IBucket} from "../Bucket/IBucket.sol";
import {ITraderBalanceVault} from "../TraderBalanceVault/ITraderBalanceVault.sol";
import {IKeeperRewardDistributor} from "../KeeperRewardDistributor/IKeeperRewardDistributor.sol";
import {ISpotTradingRewardDistributor} from "../SpotTradingRewardDistributor/ISpotTradingRewardDistributor.sol";

interface IPositionManagerStorage {
    function maxPositionSize(address, address) external returns (uint256);

    function defaultOracleTolerableLimit() external returns (uint256);

    function securityBuffer() external view returns (uint256);

    function maintenanceBuffer() external view returns (uint256);

    function positionsId() external view returns (uint256);

    function traderPositionIds(address _trader, uint256 _index) external view returns (uint256);

    function bucketPositionIds(address _bucket, uint256 _index) external view returns (uint256);

    function registry() external view returns (IAccessControl);

    function traderBalanceVault() external view returns (ITraderBalanceVault);

    function primexDNS() external view returns (IPrimexDNS);

    function priceOracle() external view returns (IPriceOracle);

    function keeperRewardDistributor() external view returns (IKeeperRewardDistributor);

    function spotTradingRewardDistributor() external view returns (ISpotTradingRewardDistributor);

    function minPositionSize() external view returns (uint256);

    function minPositionAsset() external view returns (address);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IPriceOracleStorage} from "./IPriceOracleStorage.sol";

interface IPriceOracle is IPriceOracleStorage {
    event PairPriceDropChanged(address indexed assetA, address indexed assetB, uint256 pairPriceDrop);
    event PriceFeedUpdated(address indexed assetA, address indexed assetB, address indexed priceFeed);
    event PriceDropFeedUpdated(address indexed assetA, address indexed assetB, address indexed priceDropFeed);
    event GasPriceFeedChanged(address priceFeed);

    /**
     * @param _registry The address of PrimexRegistry contract
     * @param _eth Weth address if eth isn't native token of network. Otherwise set to zero address.
     */
    function initialize(address _registry, address _eth) external;

    /**
     * @notice Function to set (change) the pair priceDrop of the trading assets
     * @dev Only callable by the SMALL_TIMELOCK_ADMIN.
     * @param _assetA The address of position asset
     * @param _assetB The address of borrowed asset
     * @param _pairPriceDrop The pair priceDrop (in wad)
     */
    function setPairPriceDrop(address _assetA, address _assetB, uint256 _pairPriceDrop) external;

    /**
     * @notice Increases the priceDrop of a pair of assets in the system.
     * @dev Only callable by the EMERGENCY_ADMIN role.
     * The _pairPriceDrop value must be greater than the current priceDrop value for the pair
     * and less than the maximum allowed priceDrop (WadRayMath.WAD / 2).
     * @param _assetA The address of position asset
     * @param _assetB The address of borrowed asset
     * @param _pairPriceDrop The new priceDrop value for the pair (in wad)
     */
    function increasePairPriceDrop(address _assetA, address _assetB, uint256 _pairPriceDrop) external;

    /**
     * @notice Add or update price feed for assets pair. For only the admin role.
     * @param assetA The first currency within the currency pair quotation (the base currency).
     * @param assetB The second currency within the currency pair quotation (the quote currency).
     * @param priceFeed The chain link price feed address for the pair assetA/assetB
     */
    function updatePriceFeed(address assetA, address assetB, address priceFeed) external;

    /**
     * @notice Sets the gas price feed contract address.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param priceFeed The address of the gas price feed contract.
     */
    function setGasPriceFeed(address priceFeed) external;

    /**
     * @notice Updates the priceDrop feed for a specific pair of assets.
     * @dev Add or update priceDrop feed for assets pair.
     * Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param assetA The address of the first asset in the pair.
     * @param assetB The address of the second asset in the pair.
     * @param priceDropFeed The chain link priceDrop feed address for the pair assetA/assetB
     */
    function updatePriceDropFeed(address assetA, address assetB, address priceDropFeed) external;

    /**
     * @notice Requests two priceFeeds - assetA/ETH and assetB/ETH (or assetA/USD and assetB/USD).
     * @dev If there is no price feed found, the code will return a message that no price feed found.
     * @param baseAsset The first currency within the currency pair quotation (the base currency).
     * @param quoteAsset The second currency within the currency pair quotation (the quote currency).
     * @return A tuple of basePriceFeed and quotePriceFeed. The addresses of the price feed for the base asset and quote asset respectively.
     */
    function getPriceFeedsPair(address baseAsset, address quoteAsset) external view returns (address, address);

    /**
     * @notice Requests priceFeed for the actual exchange rate for an assetA/assetB pair.
     * @dev If no price feed for the pair found, USD and ETH are used as intermediate tokens.
     * A price for assetA/assetB can be derived if two data feeds exist:
     * assetA/ETH and assetB/ETH (or assetA/USD and assetB/USD).
     * If there is no price feed found, the code will return a message that no price feed found.
     * @param assetA The first currency within the currency pair quotation (the base currency).
     * @param assetB The second currency within the currency pair quotation (the quote currency).
     * @return exchangeRate for assetA/assetB in 10**18 decimality which will be recalucaled in PrimexPricingLibrary.
     * @return direction of a pair as it stored in chainLinkPriceFeeds (i.e. returns 'true' for assetA/assetB, and 'false' for assetB/assetA).
     * Throws if priceFeed wasn't found or priceFeed hasn't answer is 0.
     */
    function getExchangeRate(address assetA, address assetB) external view returns (uint256, bool);

    /**
     * @notice Retrieves the direct price feed for the given asset pair.
     * @param assetA The address of the first asset.
     * @param assetB The address of the second asset.
     * @return priceFeed The address of the direct price feed.
     */
    function getDirectPriceFeed(address assetA, address assetB) external view returns (address);

    /**
     * @notice Retrieves the current gas price from the specified gas price feed.
     * @return The current gas price.
     */
    function getGasPrice() external view returns (int256);

    /**
     * @notice For a given asset pair retrieves the priceDrop rate which is the higher
     * of the oracle pair priceDrop and the historical pair priceDrop.
     * @param _assetA The address of asset A.
     * @param _assetB The address of asset B.
     * @return The priceDrop rate.
     */
    function getPairPriceDrop(address _assetA, address _assetB) external view returns (uint256);

    /**
     * @notice Retrieves the priceDrop rate between two assets based on the oracle pair priceDrop.
     * @param assetA The address of the first asset.
     * @param assetB The address of the second asset.
     * @return The priceDrop rate as a uint256 value.
     */
    function getOraclePriceDrop(address assetA, address assetB) external view returns (uint256);

    /**
     * @notice Retreives a priceDrop feed address from the oraclePriceDropFeeds mapping
     * @param assetA The address of the first asset in the pair.
     * @param assetB The address of the second asset in the pair.
     * @return priceDropFeed The address of the priceDrop feed associated with the asset pair.
     */
    function getOraclePriceDropFeed(address assetA, address assetB) external view returns (address);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IPriceOracleStorage {
    function registry() external view returns (address);

    function eth() external view returns (address);

    function gasPriceFeed() external view returns (address);

    function pairPriceDrops(address, address) external view returns (uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IPrimexDNSStorage, IPrimexDNSStorageV2} from "./IPrimexDNSStorage.sol";

interface IPrimexDNS is IPrimexDNSStorage {
    event AddNewBucket(BucketData newBucketData);
    event BucketDeprecated(address bucketAddress, uint256 delistingTime);
    event AddNewDex(DexData newDexData);
    event ChangeFeeRate(OrderType orderType, address token, uint256 rate);
    event ConditionalManagerChanged(uint256 indexed cmType, address indexed cmAddress);
    event PMXchanged(address indexed pmx);
    event AavePoolChanged(address indexed aavePool);
    event BucketActivated(address indexed bucketAddress);
    event BucketFrozen(address indexed bucketAddress);
    event DexAdapterChanged(address indexed newAdapterAddress);
    event DexActivated(address indexed routerAddress);
    event DexFrozen(address indexed routerAddress);

    /**
     * @param orderType The order type for which the rate is set
     * @param feeToken The token address for which the rate is set
     * @param rate Setting rate in WAD format (1 WAD = 100%)
     */
    struct FeeRateParams {
        OrderType orderType;
        address feeToken;
        uint256 rate;
    }

    /**
     * @notice Initializes the contract with the specified parameters.
     * @param _registry The address of the PrimexRegistry contract.
     * @param _pmx The address of the PMX token contract.
     * @param _treasury The address of the Treasury contract.
     * @param _delistingDelay The time (in seconds) between deprecation and delisting of a bucket.
     * @param _adminWithdrawalDelay The time (in seconds) between delisting of a bucket and an adminDeadline.
     * @param _feeRateParams Initial fee params
     */
    function initialize(
        address _registry,
        address _pmx,
        address _treasury,
        uint256 _delistingDelay,
        uint256 _adminWithdrawalDelay,
        FeeRateParams[] calldata _feeRateParams
    ) external;

    /**
     * @notice Deprecates a bucket.
     * @dev This function is used to deprecate a bucket by changing its current status to "Deprecated".
     * Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _bucket The name of the bucket to deprecate.
     * Emits a BucketDeprecated event with the bucket address and the delisting time.
     */
    function deprecateBucket(string memory _bucket) external;

    /**
     * @notice This function is used to set the address of the Aave pool contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _aavePool The address of the Aave pool contract to be set.
     */
    function setAavePool(address _aavePool) external;

    /**
     * @notice Sets the protocol rate in PMX.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     */
    function setFeeRate(FeeRateParams calldata _feeRateParams) external;

    /**
     * @notice Sets the address of the PMX token contract.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _pmx The address of the PMX token contract.
     */
    function setPMX(address _pmx) external;

    /**
     * @notice Activates a bucket by changing its status from inactive to active.
     * @dev Only callable by the SMALL_TIMELOCK_ADMIN role.
     * @param _bucket The bucket to activate.
     */
    function activateBucket(string memory _bucket) external;

    /**
     * @notice Freezes a bucket, preventing further operations on it,
     * by changing its status from active to inactive.
     * @dev Only callable by the EMERGENCY_ADMIN role.
     * @param _bucket The bucket to be frozen.
     */
    function freezeBucket(string memory _bucket) external;

    /**
     * @notice Adds a new bucket.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param _newBucket The address of the new bucket to be added.
     * @param _pmxRewardAmount The amount of PMX tokens to be rewarded from the bucket.
     * Emits a AddNewBucket event with the struct BucketData of the newly added bucket.
     */
    function addBucket(address _newBucket, uint256 _pmxRewardAmount) external;

    /**
     * @notice Activates a DEX by changing flag isActive on to true.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _dex The name of the DEX to activate.
     */
    function activateDEX(string memory _dex) external;

    /**
     * @notice Freezes a DEX by changing flag isActive to false.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _dex The name of the DEX to be frozen.
     */
    function freezeDEX(string memory _dex) external;

    /**
     * @notice Adds a new DEX to the protocol.
     * @dev Only callable by the MEDIUM_TIMELOCK_ADMIN role.
     * @param _name The name of the DEX.
     * @param _routerAddress The address of the DEX router.
     */
    function addDEX(string memory _name, address _routerAddress) external;

    /**
     * @notice Sets the address of the DEX adapter.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     * @param newAdapterAddress The address of the new DEX adapter.
     */
    function setDexAdapter(address newAdapterAddress) external;

    /**
     * @dev The function to specify the address of conditional manager of some type
     * 1 => LimitPriceCOM
     * 2 => TakeProfitStopLossCCM
     * 3 => TrailingStopCCM
     * @param _address Address to be set for a conditional manager
     * @param _cmType The type of a conditional manager
     */
    function setConditionalManager(uint256 _cmType, address _address) external;

    /**
     * @notice Retrieves the address of a bucket by its name.
     * @param _name The name of the bucket.
     * @return The address of the bucket.
     */
    function getBucketAddress(string memory _name) external view returns (address);

    /**
     * @notice Retrieves the address of the DEX router based on the given DEX name.
     * @param _name The name of the DEX.
     * @return The address of the DEX router.
     */
    function getDexAddress(string memory _name) external view returns (address);

    /**
     * @notice Retrieves the names of Dexes registered in the protocol.
     * @return An array of strings containing the names of all Dexes.
     */
    function getAllDexes() external view returns (string[] memory);
}

interface IPrimexDNSV2 is IPrimexDNS, IPrimexDNSStorageV2 {
    event ChangeFeeRestrictions(OrderType indexed orderType, FeeRestrictions feeRestrictions);

    /**
     * @notice Set the protocol fee restriction for one type of order.
     * @dev Only callable by the BIG_TIMELOCK_ADMIN role.
     */
    function setFeeRestrictions(OrderType _orderType, FeeRestrictions calldata _feeRestrictions) external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IPrimexDNSStorage {
    enum Status {
        Inactive,
        Active,
        Deprecated
    }

    enum OrderType {
        MARKET_ORDER,
        LIMIT_ORDER,
        SWAP_MARKET_ORDER,
        SWAP_LIMIT_ORDER
    }

    struct BucketData {
        address bucketAddress;
        Status currentStatus;
        uint256 delistingDeadline;
        // The deadline is for the admin to call Bucket.withdrawAfterDelisting().
        uint256 adminDeadline;
    }
    struct DexData {
        address routerAddress;
        bool isActive;
    }

    struct AdapterData {
        string[] dexes;
        bool isAdded;
    }

    function registry() external view returns (address);

    function delistingDelay() external view returns (uint256);

    function adminWithdrawalDelay() external view returns (uint256);

    function buckets(string memory) external view returns (address, Status, uint256, uint256);

    function dexes(string memory) external view returns (address, bool);

    function cmTypeToAddress(uint256 cmType) external view returns (address);

    function dexAdapter() external view returns (address);

    function pmx() external view returns (address);

    function treasury() external view returns (address);

    function aavePool() external view returns (address);

    function feeRates(OrderType _orderType, address _token) external view returns (uint256);
}

interface IPrimexDNSStorageV2 is IPrimexDNSStorage {
    struct FeeRestrictions {
        uint256 minProtocolFee;
        uint256 maxProtocolFee;
    }

    function feeRestrictions(
        OrderType _orderType
    ) external view returns (uint256 minProtocolFee, uint256 maxProtocolFee);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import {IPTokenStorage, IBucket, IFeeExecutor, IERC20MetadataUpgradeable, IActivityRewardDistributor} from "./IPTokenStorage.sol";

interface IPToken is IPTokenStorage {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     */
    event Mint(address indexed from, uint256 value);

    /**
     * @dev Emitted after pTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param value The amount being burned
     */
    event Burn(address indexed from, uint256 value);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param amount The amount being transferred
     * @param index The new liquidity index of the reserve
     */
    event BalanceTransfer(address indexed from, address indexed to, uint256 amount, uint256 index);

    event LockDeposit(address indexed user, uint256 indexed id, uint256 deadline, uint256 amount);
    event UnlockDeposit(address indexed user, uint256 indexed id);

    /**
     * @dev contract initializer
     * @param _name The name of the ERC20 token.
     * @param _symbol The symbol of the ERC20 token.
     * @param _decimals The number of decimals for the ERC20 token.
     * @param _bucketsFactory Address of the buckets factory that will call the setBucket fucntion
     */
    function initialize(string memory _name, string memory _symbol, uint8 _decimals, address _bucketsFactory) external;

    /**
     * @dev Sets the bucket for the contract.
     * @param _bucket The address of the bucket to set.
     */
    function setBucket(IBucket _bucket) external;

    /**
     * @dev Sets the InterestIncreaser for current PToken.
     * @param _interestIncreaser The interest increaser address.
     */
    function setInterestIncreaser(IFeeExecutor _interestIncreaser) external;

    /**
     * @dev Sets the lender reward distributor contract address.
     * @param _lenderRewardDistributor The address of the lender reward distributor contract.
     */
    function setLenderRewardDistributor(IActivityRewardDistributor _lenderRewardDistributor) external;

    /**
     * @notice Locks a deposit for a specified user.
     * @param _user The address of the user for whom the deposit is being locked.
     * @param _amount The amount to be locked as a deposit.
     * @param _duration The duration for which the deposit will be locked.
     * @dev This function can only be called externally and overrides the corresponding function in the parent contract.
     * @dev The user must not be blacklisted.
     */
    function lockDeposit(address _user, uint256 _amount, uint256 _duration) external;

    /**
     * @dev Unlocks a specific deposit.
     * @param _depositId The ID of the deposit to be unlocked.
     */
    function unlockDeposit(uint256 _depositId) external;

    /**
     * @dev Mints `amount` pTokens to `user`
     * @param _user The address receiving the minted tokens
     * @param _amount The amount of tokens getting minted
     * @param _index The current liquidityIndex
     * @return Minted amount of PTokens
     */
    function mint(address _user, uint256 _amount, uint256 _index) external returns (uint256);

    /**
     * @dev Mints pTokens to the reserve address
     * Compared to the normal mint, we don't revert when the amountScaled is equal to the zero. Additional checks were also removed
     * Only callable by the Bucket
     * @param _reserve The address of the reserve
     * @param _amount The amount of tokens getting minted
     * @param _index The current liquidityIndex
     */
    function mintToReserve(address _reserve, uint256 _amount, uint256 _index) external;

    /**
     * @dev Burns pTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param _user The owner of the pTokens, getting them burned
     * @param _amount The amount of underlying token being returned to receiver
     * @param _index The current liquidityIndex
     * @return Burned amount of PTokens
     */
    function burn(address _user, uint256 _amount, uint256 _index) external returns (uint256);

    /**
     * @dev Returns the scaled balance of the user.
     * @param _user The owner of pToken
     * @return The scaled balances of the user
     */
    function scaledBalanceOf(address _user) external view returns (uint256);

    /**
     * @dev Returns available balance of the user.
     * @param _user The owner of pToken
     * @return The available balance of the user
     */
    function availableBalanceOf(address _user) external view returns (uint256);

    /**
     * @dev Returns locked deposits and balance of user
     * @param _user The owner of locked deposits
     * @return Structure with deposits and total locked balance of user
     */
    function getUserLockedBalance(address _user) external view returns (LockedBalance memory);

    /**
     * @dev Returns the scaled total supply of pToken.
     * @return The scaled total supply of the pToken.
     */
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @dev Function to get a deposit index in user's deposit array.
     * @param id Deposit id.
     * @return index Deposit index in user's 'deposit' array.
     */
    function getDepositIndexById(uint256 id) external returns (uint256 index);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import {IBucket} from "../Bucket/IBucket.sol";
import {IFeeExecutor} from "../BonusExecutor/IFeeExecutor.sol";
import {IActivityRewardDistributor} from "../ActivityRewardDistributor/IActivityRewardDistributor.sol";

interface IPTokenStorage is IERC20MetadataUpgradeable {
    struct Deposit {
        uint256 lockedBalance;
        uint256 deadline;
        uint256 id;
    }

    struct LockedBalance {
        uint256 totalLockedBalance;
        Deposit[] deposits;
    }

    function bucket() external view returns (IBucket);

    function interestIncreaser() external view returns (IFeeExecutor);

    function lenderRewardDistributor() external view returns (IActivityRewardDistributor);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IBucket} from "../Bucket/IBucket.sol";
import {IPrimexDNS} from "../PrimexDNS/IPrimexDNS.sol";
import {IReserveStorage} from "./IReserveStorage.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface IReserve is IReserveStorage, IPausable {
    event BurnAmountCalculated(uint256 burnAmount);
    event TransferRestrictionsChanged(address indexed pToken, TransferRestrictions newTransferRestrictions);

    /**
     * @dev contract initializer
     * @param dns The address of PrimexDNS contract
     * @param registry The address of Registry contract
     */
    function initialize(IPrimexDNS dns, address registry) external;

    /**
     * @dev Burns the permanent loss amount (presented in pTokens) from the Reserve for a particular bucket
     * @param bucket The address of a bucket
     * Emits BurnAmountCalculated(burnAmount) event
     */
    function paybackPermanentLoss(IBucket bucket) external;

    /**
     * @dev Transfers some bonus in pTokens to receiver from Reserve
     * Can be called by executor only
     * @param _bucketName The bucket where the msg.sender should be a fee decreaser (for debtToken) or
     * interest increaser (for pToken)
     * @param _to The receiver of bonus pTokens
     * @param _amount The amount of bonus pTokens to transfer
     */
    function payBonus(string memory _bucketName, address _to, uint256 _amount) external;

    /**
     * @dev Function to transfer tokens to the Treasury. Only BIG_TIMELOCK_ADMIN can call it.
     * @param bucket The bucket from which to transfer pTokens
     * @param amount The amount of pTokens to transfer
     */
    function transferToTreasury(address bucket, uint256 amount) external;

    /**
     * @dev Function to set transfer restrictions for a token.
     * @notice Only BIG_TIMELOCK_ADMIN can call it.
     * @param pToken pToken to set restrictions for
     * @param transferRestrictions Min amount to be left in the Reserve
     */
    function setTransferRestrictions(address pToken, TransferRestrictions calldata transferRestrictions) external;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IReserveStorage {
    struct TransferRestrictions {
        uint256 minAmountToBeLeft;
        uint256 minPercentOfTotalSupplyToBeLeft;
    }

    event TransferFromReserve(address pToken, address to, uint256 amount);

    function transferRestrictions(address pToken) external view returns (uint256, uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {ISpotTradingRewardDistributorStorage} from "./ISpotTradingRewardDistributorStorage.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface ISpotTradingRewardDistributor is ISpotTradingRewardDistributorStorage, IPausable {
    event SpotTradingClaimReward(address indexed trader, uint256 amount);
    event RewardPerPeriodDecreased(uint256 indexed rewardPerPeriod);
    event TopUpUndistributedPmxBalance(uint256 indexed amount);
    event RewardPerPeriodChanged(uint256 indexed rewardPerPeriod);
    event PmxWithdrawn(uint256 indexed amount);

    /**
     * @dev contract initializer
     * @param registry The address of Registry contract
     * @param periodDuration The duration of a reward period
     * @param priceOracle The address of PriceOracle contract
     * @param pmx The address of PMX token
     * @param traderBalanceVault The address of TraderBalanceVault contract
     * @param treasury The address of Treasury contract
     */
    function initialize(
        address registry,
        uint256 periodDuration,
        address priceOracle,
        address pmx,
        address payable traderBalanceVault,
        address treasury
    ) external;

    /**
     * @dev Function to update spot trader activity. Only PM_ROLE can call it.
     * @param trader Address of a trader
     * @param positionAsset Address of a position asset
     * @param positionAmount Amount of a position asset
     */
    function updateTraderActivity(address trader, address positionAsset, uint256 positionAmount) external;

    /**
     * @dev Function to claim reward for spot trading activity.
     * Transfer rewards on the balance in traderBalanceVault
     * Emits SpotTradingClaimReward(address trader, uint256 amount)
     */
    function claimReward() external;

    /**
     * @dev Function to set new reward per period. Only BIG_TIMELOCK_ADMIN can call it.
     * @param rewardPerPeriod New value for reward per period
     */
    function setRewardPerPeriod(uint256 rewardPerPeriod) external;

    /**
     * @dev Function to decrease reward per period. Only EMERGENCY_ADMIN can call it.
     * @param _rewardPerPeriod New value for reward per period, must be less than the current value
     */
    function decreaseRewardPerPeriod(uint256 _rewardPerPeriod) external;

    /**
     * @dev Function to topUp the contract PMX balance
     * @param amount PMX amount to add to the contract balance
     */
    function topUpUndistributedPmxBalance(uint256 amount) external;

    /**
     * @dev Function to withdraw PMX from the contract to treasury
     * @param amount Amount of PMX to withdraw from the contract
     */
    function withdrawPmx(uint256 amount) external;

    /**
     * @dev Function to get SpotTraderActivity
     * @param periodNumber Period number
     * @param traderAddress Address of a trader
     * @return A struct with activity and hasClaimed members
     */
    function getSpotTraderActivity(uint256 periodNumber, address traderAddress) external view returns (uint256);

    /**
     * @dev Get information for the period corresponding to the given timestamp
     * @param timestamp The timestamp to get information about
     * @return totalReward Total reward for the corresponding period
     * @return totalActivity Total activity for the corresponding period
     */
    function getPeriodInfo(uint256 timestamp) external view returns (uint256, uint256);

    /**
     * @dev Function to get an array of period numbers when trader had any activity
     * @param trader Address of a trader
     * @return An array of period numbers with trader activity
     */
    function getPeriodsWithTraderActivity(address trader) external view returns (uint256[] memory);

    /**
     * @dev Function to calculate trader's reward for her activities during periods
     * @param trader Address of a trader
     * @return reward Amount of reward
     * @return currentPeriod The current period
     */
    function calculateReward(address trader) external view returns (uint256 reward, uint256 currentPeriod);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ISpotTradingRewardDistributorStorage {
    struct PeriodInfo {
        uint256 totalReward;
        // map trader address to her activity
        mapping(address => uint256) traderActivity;
        uint256 totalActivity;
    }

    function registry() external view returns (address);

    function dns() external view returns (address);

    function periodDuration() external view returns (uint256);

    function initialPeriodTimestamp() external view returns (uint256);

    function rewardPerPeriod() external view returns (uint256);

    function pmx() external view returns (address);

    function priceOracle() external view returns (address);

    function treasury() external view returns (address);

    function traderBalanceVault() external view returns (address payable);

    function undistributedPMX() external view returns (uint256);

    function periods(uint256 periodNumber) external view returns (uint256, uint256);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {ITraderBalanceVaultStorage} from "./ITraderBalanceVaultStorage.sol";
import {IPausable} from "../interfaces/IPausable.sol";

interface ITraderBalanceVault is ITraderBalanceVaultStorage, IPausable {
    /**
     * Types of way to open a position or order
     */
    enum OpenType {
        OPEN_BY_ORDER,
        OPEN,
        CREATE_LIMIT_ORDER
    }

    /**
     * @param trader The trader, who opens margin deal
     * @param depositReceiver the address to which the deposit is transferred when blocked.
     * This happens because the trader's deposit is involved in the position
     * @param borrowedAsset The token to lock for deal in a borrowed asset
     * @param depositAsset The token is a deposit asset
     * (it is blocked when creating a limit order
     * For others, the operations is transferred to the account of the receiver of the deposit and is swapped )
     * @param depositAmount Amount of tokens in a deposit asset
     * @param depositInBorrowedAmount Amount of tokens to lock for deal in a borrowed asset
     * @param openType Corresponds to the purpose of locking
     */
    struct LockAssetParams {
        address trader;
        address depositReceiver;
        address depositAsset;
        uint256 depositAmount;
        OpenType openType;
    }

    /**
     * @param trader The trader who opened the position
     * @param receiver The receiver of the rest of trader deposit.
     * @param asset Borrowed asset of the position being closed (the need for accrual of profit).
     * @param unlockAmount The amount of unlocked collateral for deal
     * @param returnToTrader The returned to trader amount when position was closed.
     */
    struct UnlockAssetParams {
        address trader;
        address receiver;
        address asset;
        uint256 amount;
    }

    /**
     * @param traders An array of traders for which available balance should be increased
     * @param amounts An array of amounts corresponding to traders' addresses that should be added to their available balances
     * @param asset Asset address which amount will be increased
     * @param length The amount of traders in an array
     */
    struct BatchTopUpAvailableBalanceParams {
        address[] traders;
        uint256[] amounts;
        address asset;
        uint256 length;
    }

    event Deposit(address indexed depositer, address indexed asset, uint256 amount);
    event Withdraw(address indexed withdrawer, address asset, uint256 amount);

    /**
     * @dev contract initializer
     * @param _registry The address of Registry contract
     * @param _whiteBlackList The address of WhiteBlackList contract
     */
    function initialize(address _registry, address _whiteBlackList) external;

    receive() external payable;

    /**
     * @dev Deposits trader collateral for margin deal
     * @param _asset The collateral asset for deal
     * @param _amount The amount of '_asset' to deposit
     */
    function deposit(address _asset, uint256 _amount) external payable;

    /**
     * @dev Withdraws the rest of trader's deposit after closing deal
     * @param _asset The collateral asset for withdraw
     * @param _amount The amount of '_asset' to withdraw
     */
    function withdraw(address _asset, uint256 _amount) external;

    /**
     * @dev Traders lock their collateral for the limit order.
     * @param _trader The owner of collateral
     * @param _asset The collateral asset for deal
     * @param _amount The amount of '_asset' to deposit
     */
    function increaseLockedBalance(address _trader, address _asset, uint256 _amount) external payable;

    /**
     * @dev Locks deposited trader's assets as collateral for orders.
     * Decreases the available balance when opening position.
     * Transfers deposited amount to the deposit receiver.
     * @param _params parameters necessary to lock asset
     */
    function useTraderAssets(LockAssetParams calldata _params) external;

    /**
     * @dev Unlocks trader's collateral when open position by order or update deposit.
     * @param _params parameters necessary to unlock asset
     */
    function unlockAsset(UnlockAssetParams calldata _params) external;

    /**
     * The function to increase available balance for several traders
     * @param _params A struct containing BatchTopUpAvailableBalanceParams
     */
    function batchTopUpAvailableBalance(BatchTopUpAvailableBalanceParams calldata _params) external;

    /**
     * Withdraws an asset amount from an asset holder to a receiver
     * @param _from Withdraw from address
     * @param _to Withdraw to address
     * @param _asset Address of an asset
     * @param _amount Amount of an asset
     * @param fromLocked True if withdraw from locked balance
     */
    function withdrawFrom(address _from, address _to, address _asset, uint256 _amount, bool fromLocked) external;

    /**
     * Increases available balance of a receiver in the protocol
     * @param receiver The address of an asset receiver
     * @param asset The asset address for which available balance will be increased
     * @param amount The amount of an asset
     */
    function topUpAvailableBalance(address receiver, address asset, uint256 amount) external payable;
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ITraderBalanceVaultStorage {
    struct TraderBalance {
        uint256 availableBalance;
        uint256 lockedBalance;
    }

    function registry() external view returns (address);

    /**
     *
     * @param trader Trader's address
     * @param asset Asset address
     * @return availableBalance availableBalance
     * @return lockedBalance lockedBalance
     */
    function balances(
        address trader,
        address asset
    ) external view returns (uint256 availableBalance, uint256 lockedBalance);
}

// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IWhiteBlackList {
    enum AccessType {
        UNLISTED,
        WHITELISTED,
        BLACKLISTED
    }
    event WhitelistedAddressAdded(address indexed addr);
    event WhitelistedAddressRemoved(address indexed addr);
    event BlacklistedAddressAdded(address indexed addr);
    event BlacklistedAddressRemoved(address indexed addr);

    function addAddressToWhitelist(address _address) external;

    function addAddressesToWhitelist(address[] calldata _addresses) external;

    function removeAddressFromWhitelist(address _address) external;

    function removeAddressesFromWhitelist(address[] calldata _addresses) external;

    function addAddressToBlacklist(address _address) external;

    function addAddressesToBlacklist(address[] calldata _addresses) external;

    function removeAddressFromBlacklist(address _address) external;

    function removeAddressesFromBlacklist(address[] calldata _addresses) external;

    function getAccessType(address _address) external view returns (AccessType);

    function isBlackListed(address _address) external view returns (bool);

    function registry() external view returns (address);
}