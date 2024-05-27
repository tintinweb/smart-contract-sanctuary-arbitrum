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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ======================= STRUCTS ========================= */

  struct Borrower {
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalBorrows() external view returns (uint256);
  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPRPerBorrower(address borrower) external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function approvedBorrower(address borrower) external view returns (bool);
  function approvedBorrowers() external view returns (address[] memory);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(
    address borrower,
    InterestRate memory newInterestRate
  ) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyPause() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateMaxInterestRate(
    address borrower,
    InterestRate memory newMaxInterestRate
  ) external;
  function updateTreasury(address newTreasury) external;
  function updateMaxBorrowers(uint256 newMaxBorrowers) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function updateTokenToDenominatorToken(address token, address dt) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { LRTTypes } from  "../../../strategy/lrt/LRTTypes.sol";

interface ILRTVault {
  function store() external view returns (LRTTypes.Store memory);
  function deposit(LRTTypes.DepositParams memory dp) external;
  function depositNative(LRTTypes.DepositParams memory dp) external payable;

  function withdraw(LRTTypes.WithdrawParams memory wp) external;

  function rebalanceAdd(
    LRTTypes.RebalanceAddParams memory rap
  ) external;

  function rebalanceRemove(
    LRTTypes.RebalanceRemoveParams memory rrp
  ) external;

  function compound(LRTTypes.CompoundParams memory cp) external;
  function compoundLRT() external;

  function emergencyPause() external;
  function emergencyRepay() external;
  function emergencyBorrow() external;
  function emergencyResume() external;
  function emergencyClose() external;
  function emergencyWithdraw(uint256 shareAmt) external;
  function emergencyStatusChange(LRTTypes.Status status) external;

  function updateTreasury(address treasury) external;
  function updateSwapRouter(address swapRouter) external;
  function updateLendingVaults(address newTokenBLendingVault) external;
  function updateFeePerSecond(uint256 feePerSecond) external;
  function updateParameterLimits(
    uint256 newLeverage,
    uint256 debtRatioStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;
  function updateMinVaultSlippage(uint256 minVaultSlippage) external;
  function updateSwapSlippage(uint256 swapSlippage) external;
  function updateChainlinkOracle(address addr) external;

  function updateMinAssetValue(uint256 value) external;
  function updateMaxAssetValue(uint256 value) external;

    function externalCall(
    address addr,
    string memory signature,
    bytes memory args
  ) external returns (bytes memory);

  function mintFee() external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ISwap {
  struct SwapParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in; in token decimals
    uint256 amountIn;
    // Amount of token out; in token decimals
    uint256 amountOut;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // Swap deadline timestamp
    uint256 deadline;
  }

  function swapExactTokensForTokens(
    SwapParams memory sp
  ) external returns (uint256);

  function swapTokensForExactTokens(
    SwapParams memory sp
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWNT } from "../../interfaces/tokens/IWNT.sol";
import { ILendingVault } from "../../interfaces/lending/ILendingVault.sol";
import { ILRTVault } from "../../interfaces/strategy/lrt/ILRTVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { ISwap } from "../../interfaces/swap/ISwap.sol";

/**
  * @title LRTTypes
  * @author Steadefi
  * @notice Re-usable library of Types struct definitions for Steadefi leveraged vaults
*/
library LRTTypes {

  /* ======================= STRUCTS ========================= */

  struct Store {
    // Status of the vault
    Status status;
    // Amount of LRT that vault accounts for as total assets
    uint256 lrtAmt;
    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;

    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 feePerSecond;
    // Treasury address
    address treasury;

    // Guards: change threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Guards: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e18; 69e16 = 0.69 = 69%
    // Guards: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e18; 61e16 = 0.61 = 61%
    // Guards: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e18; 15e16 = 0.15 = +15%
    // Guards: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e18; -15e16 = -0.15 = -15%
    // Guards: Minimum vault slippage for vault shares/assets in 1e4; e.g. 100 = 1%
    uint256 minVaultSlippage;
    // Slippage for swaps in 1e4; e.g. 100 = 1%
    uint256 swapSlippage;
    // Minimum asset value per vault deposit/withdrawal
    uint256 minAssetValue;
    // Maximum asset value per vault deposit/withdrawal
    uint256 maxAssetValue;

    // Token to borrow for this strategy
    IERC20 tokenB;
    // LRT of this strategy
    IERC20 LRT;
    // Native token for this chain (i.e. ETH)
    IWNT WNT;
    // LST for this chain
    IERC20 LST;
    // USDC for this chain
    IERC20 USDC;
    // Reward token (e.g. ARB)
    IERC20 rewardToken;

    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    ILRTVault vault;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;

    // Swap router for this vault
    ISwap swapRouter;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceCache
    RebalanceCache rebalanceCache;
    // CompoundCache
    CompoundCache compoundCache;
  }

  struct DepositCache {
    // Address of user
    address payable user;
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // Minimum amount of shares expected in 1e18
    uint256 minSharesAmt;
    // Actual amount of shares minted in 1e18
    uint256 sharesToUser;
    // Amount of LRT that vault received in 1e18
    uint256 lrtAmt;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user
    address payable user;
    // Ratio of shares out of total supply of shares to burn
    uint256 shareRatio;
    // Amount of LRT to remove liquidity from
    uint256 lrtAmt;
    // Withdrawal value in 1e18
    uint256 withdrawValue;
    // Minimum amount of assets that user receives
    uint256 minAssetsAmt;
    // Actual amount of assets that user receives
    uint256 assetsToUser;
    // Amount of tokenB that vault received in 1e18
    uint256 tokenBReceived;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct CompoundCache {
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // CompoundParams
    CompoundParams compoundParams;
  }

  struct RebalanceCache {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // BorrowParams
    BorrowParams borrowParams;
    // LRT amount to remove in 1e18
    uint256 lrtAmtToRemove;
    // HealthParams
    HealthParams healthParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lrt
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Slippage tolerance for swaps; e.g. 3 = 0.03%
    uint256 slippage;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct CompoundParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in
    uint256 amtIn;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct RebalanceAddParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // BorrowParams
    BorrowParams borrowParams;
  }

  struct RebalanceRemoveParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // LRT amount to remove in 1e18
    uint256 lrtAmtToRemove;
  }

  struct BorrowParams {
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct HealthParams {
    // LRT token balance in 1e18
    uint256 lrtAmtBefore;
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  struct AddLiquidityParams {
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
  }

  struct RemoveLiquidityParams {
    // Amount of LRT to remove liquidity
    uint256 lrtAmt;
  }

  /* ========== ENUM ========== */

  enum Status {
    // 0) Vault is open
    Open,
    // 1) User is depositing to vault
    Deposit,
    // 2) User deposit to vault failure
    Deposit_Failed,
    // 3) User is withdrawing from vault
    Withdraw,
    // 4) User withdrawal from vault failure
    Withdraw_Failed,
    // 5) Vault is rebalancing delta or debt  with more hedging
    Rebalance_Add,
    // 6) Vault is rebalancing delta or debt with less hedging
    Rebalance_Remove,
    // 7) Vault has rebalanced but still requires more rebalancing
    Rebalance_Open,
    // 8) Vault is compounding
    Compound,
    // 9) Vault is paused
    Paused,
    // 10) Vault is repaying
    Repay,
    // 11) Vault has repaid all debt after pausing
    Repaid,
    // 12) Vault is resuming
    Resume,
    // 13) Vault is closed after repaying debt
    Closed
  }

  enum Delta {
    // Neutral delta strategy; aims to hedge tokenA exposure
    Neutral,
    // Long delta strategy; aims to correlate with tokenA exposure
    Long,
    // Short delta strategy; aims to overhedge tokenA exposure
    Short
  }

  enum RebalanceType {
    // Rebalance delta; mostly borrowing/repay tokenA
    Delta,
    // Rebalance debt ratio; mostly borrowing/repay tokenB
    Debt
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { LRTTypes } from "./LRTTypes.sol";

library LRTWorker {

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event ExactTokensForTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );
  event TokensForExactTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @dev Swap exact amount of tokenIn for as many amount of tokenOut
    * @param self Vault store data
    * @param sp ISwap.SwapParams
    * @return amountOut Amount of tokens out in token decimals
  */
  function swapExactTokensForTokens(
    LRTTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    IERC20(sp.tokenIn).approve(address(self.swapRouter), sp.amountIn);

    emit ExactTokensForTokensSwapped(
      sp.tokenIn,
      sp.tokenOut,
      sp.amountIn,
      sp.amountOut,
      sp.slippage,
      sp.deadline
    );

    return self.swapRouter.swapExactTokensForTokens(sp);
  }

  /**
    * @dev Swap as little tokenIn for exact amount of tokenOut
    * @param self Vault store data
    * @param sp ISwap.SwapParams
    * @return amountIn Amount of tokens in in token decimals
  */
  function swapTokensForExactTokens(
    LRTTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    IERC20(sp.tokenIn).approve(address(self.swapRouter), sp.amountIn);

    emit TokensForExactTokensSwapped(
      sp.tokenIn,
      sp.tokenOut,
      sp.amountIn,
      sp.amountOut,
      sp.slippage,
      sp.deadline
    );

    return self.swapRouter.swapTokensForExactTokens(sp);
  }
}