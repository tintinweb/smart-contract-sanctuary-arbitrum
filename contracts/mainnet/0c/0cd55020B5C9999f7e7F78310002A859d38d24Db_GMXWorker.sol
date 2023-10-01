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
pragma solidity 0.8.21;

interface ILendingVault {

  /* ========== STRUCTS ========== */

  struct Borrower {
    // Boolean for whether borrower is approved to borrow from this vault
    bool approved;
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

  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(InterestRate memory newInterestRate) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function updateKeeper(address keeper, bool approval) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyShutdown() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function addTokenMaxDeviation(address token, uint256 maxDeviation) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXOracle {
  struct MarketPoolValueInfoProps {
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

  function getAmountsOut(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenIn,
    uint256 amountIn
  ) external view returns (uint256);

  function getAmountsIn(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    address tokenOut,
    uint256 amountsOut
  ) external view returns (uint256);

  function getMarketTokenInfo(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bytes32 pnlFactorType,
    bool maximize
  ) external view returns (
    int256,
    MarketPoolValueInfoProps memory
  );

  function getLpTokenReserves(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken
  ) external view returns (uint256, uint256);

  function getLpTokenValue(
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 givenValue,
    address marketToken,
    address indexToken,
    address longToken,
    address shortToken,
    bool isDeposit,
    bool maximize
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IGMXExchangeRouter {
  struct CreateDepositParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address initialLongToken;
    address initialShortToken;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minMarketTokens;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
  }

  struct CreateWithdrawalParams {
    address receiver;
    address callbackContract;
    address uiFeeReceiver;
    address market;
    address[] longTokenSwapPath;
    address[] shortTokenSwapPath;
    uint256 minLongTokenAmount;
    uint256 minShortTokenAmount;
    bool shouldUnwrapNativeToken;
    uint256 executionFee;
    uint256 callbackGasLimit;
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

  enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
  }

  enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
  }

  function sendWnt(address receiver, uint256 amount) external payable;

  function sendTokens(
    address token,
    address receiver,
    uint256 amount
  ) external payable;

  function createDeposit(
    CreateDepositParams calldata params
  ) external payable returns (bytes32);

  function createWithdrawal(
    CreateWithdrawalParams calldata params
  ) external payable returns (bytes32);

  function createOrder(
    CreateOrderParams calldata params
  ) external payable returns (bytes32);

  // function cancelDeposit(bytes32 key) external payable;

  // function cancelWithdrawal(bytes32 key) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { GMXTypes } from  "../../../strategy/gmx/GMXTypes.sol";

interface IGMXVault {
  function store() external view returns (GMXTypes.Store memory);
  function isTokenWhitelisted(address token) external view returns (bool);

  function deposit(GMXTypes.DepositParams memory dp) payable external;
  function depositNative(GMXTypes.DepositParams memory dp) payable external;
  function processMint(bytes32 depositKey) external;

  function withdraw(GMXTypes.WithdrawParams memory wp) payable external;
  function processSwapForRepay(bytes32 orderKey) external;
  function processRepay(bytes32 withdrawKey, bytes32 orderKey) external;
  function processSwapForWithdraw(bytes32 orderKey) external;
  function processBurn(bytes32 withdrawKey, bytes32 orderKey) external;

  function emergencyWithdraw(GMXTypes.WithdrawParams memory wp) external;
  function mintMgmtFee() external;
  function compound(address token, uint256 slippage, uint256 deadline) external;

  function rebalanceAdd(
    GMXTypes.RebalanceAddParams memory rebalanceAddParams
  ) payable external;
  function processRebalanceAdd(bytes32 depositKey) external;

  function rebalanceRemove(
    GMXTypes.RebalanceRemoveParams memory rebalanceRemoveParams
  ) payable external;
  function processRebalanceRemoveSwapForRepay(bytes32 withdrawKey) external;
  function processRebalanceRemoveRepay(
    bytes32 withdrawKey,
    bytes32 swapKey
  ) external;
  function processRebalanceRemoveAddLiquidity(
    bytes32 depositKey
  ) external;


  function emergencyShutdown(uint256 slippage, uint256 deadline) external;
  function emergencyResume(uint256 slippage, uint256 deadline) external;
  function updateKeeper(address keeper, bool approval) external;
  function updateTreasury(address treasury) external;
  function updateMgmtFeePerSecond(uint256 mgmtFeePerSecond) external;
  function updatePerformanceFee(uint256 performanceFee) external;
  function updateMaxCapacity(uint256 maxCapacity) external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;

  function updateInvariants(
    uint256 debtRatioStepThreshold,
    uint256 deltaStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;

  function updateMinExecutionFee(uint256 minExecutionFee) external;

  function updateMinExecutionFee(
    address depositHandler,
    address withdrawalHandler,
    address orderHandler
  ) external;
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
import { IGMXVault } from "../../interfaces/strategy/gmx/IGMXVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { IGMXOracle } from "../../interfaces/oracles/IGMXOracle.sol";
import { IGMXExchangeRouter } from "../../interfaces/protocols/gmx/IGMXExchangeRouter.sol";

library GMXTypes {

  /* ========== STRUCTS ========== */

  struct Store {
    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 mgmtFeePerSecond;
    // Performance fee in % in 1e18
    uint256 performanceFee;
    // Max capacity of vault in USD value in 1e18
    uint256 maxCapacity;
    // Treasury address
    address treasury;

    // Invariant: threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Invariant: threshold for delta change after deposit/withdraw
    uint256 deltaStepThreshold; // in 1e4; e.g. 500 = 5%
    // Invariant: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e4; e.g. 6900 = 0.69
    // Invariant: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e4; e.g. 6100 = 0.61
    // Invariant: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e4; e.g. 10500 = 1.05
    // Invariant: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e4; e.g. 9500 = 0.95
    // Minimum execution fee required
    uint256 minExecutionFee; // in 1e18

    // Token A in this strategy; long token + index token
    IERC20 tokenA;
    // Token B in this strategy; short token
    IERC20 tokenB;
    // LP token of this strategy; market token
    IERC20 lpToken;
    // Native token for this chain (e.g. WETH, WAVAX, WBNB, etc.)
    IWNT WNT;

    // Token A lending vault
    ILendingVault tokenALendingVault;
    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    IGMXVault vault;
    // Queue contract address; if address(0) it means there is no queue enabled
    address queue;
    // Callback contract address; if address(0) it means there is no callback enabled
    address callback;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;
    // GMX Oracle contract address
    IGMXOracle gmxOracle;

    // GMX exchange router contract address
    IGMXExchangeRouter exchangeRouter;
    // GMX router contract address
    address router;
    // GMX deposit vault address
    address depositVault;
    // GMX withdrawal vault address
    address withdrawalVault;
    // GMX order vault address
    address orderVault;
    // GMX deposit handler address
    address depositHandler;
    // GMX withdrawal handler address
    address withdrawalHandler;
    // GMX order handler address
    address orderHandler;

    // Status of the vault
    Status status;

    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;
    // Timestamp when last user deposit happened
    uint256 lastDepositBlock;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceAddCache
    RebalanceAddCache rebalanceAddCache;
    // RebalanceRemoveCache
    RebalanceRemoveCache rebalanceRemoveCache;
  }

  struct DepositCache {
    // Address of user that is depositing
    address user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // USD value of deposit in 1e18; filled by vault
    uint256 depositValue;
    // Amount of shares to mint in 1e18; filled by vault
    uint256 sharesToUser;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user that is withdrawing
    address user;
    // Timestamp of withdrawal created, filled by vault
    uint256 timestamp;
    // Ratio of shares out of total supply of shares to burn; filled by vault
    uint256 shareRatio;
    // Actual amount of withdraw token that user receives
    uint256 withdrawTokenAmt;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct RebalanceAddCache {
    // This should be the approved keeper address; filled by vault
    address user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // RebalanceAddParams
    RebalanceAddParams rebalanceAddParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct RebalanceRemoveCache {
    // This should be the approved keeper address; filled by vault
    address user;
    // Timestamp of deposit created, filled by vault
    uint256 timestamp;
    // Withdraw key from GMX in bytes32
    bytes32 withdrawKey;
    // Deposit key from GMX in bytes32
    bytes32 depositKey;
    // RebalanceRemoveParams
    RebalanceRemoveParams rebalanceRemoveParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lpToken
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Minimum amount of shares to receive in 1e18
    uint256 minSharesAmt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Address of token to withdraw to; could be tokenA, tokenB or lpToken
    address token;
    // Minimum amount of token to receive in token decimals
    uint256 minWithdrawTokenAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
    // Amount of shares to remove in 1e18; filled by vault
    uint256 lpAmtToRemove;
    // SwapParams Swap for repay parameters
    SwapParams swapForRepayParams;
    // SwapParams Swap for withdraw parameters
    SwapParams swapForWithdrawParams;
  }

  struct RebalanceAddParams {
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // RepayParams
    RepayParams repayParams;
  }

  struct RebalanceRemoveParams {
    // Amount of LP tokens to remove
    uint256 lpAmtToRemove;
    // DepositParams
    DepositParams depositParams;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // BorrowParams
    BorrowParams borrowParams;
    // RepayParams
    RepayParams repayParams;
    // SwapParams Swap for repay parameters
    SwapParams swapForRepayParams;
  }

  struct AddLiquidityParams {
    // Amount of tokenA to add liquidity
    uint256 tokenAAmt;
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
    // Slippage tolerance for adding liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for adding liquidity
    uint256 executionFee;
  }

  struct RemoveLiquidityParams {
    // Amount of lpToken to remove liquidity
    uint256 lpTokenAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Execution fee sent to GMX for removing liquidity
    uint256 executionFee;
  }

  struct BorrowParams {
    // Amount of tokenA to borrow in tokenA decimals
    uint256 borrowTokenAAmt;
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenA to repay in tokenA decimals
    uint256 repayTokenAAmt;
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct SwapParams {
    // Address of token swapping from; filled by vault
    address tokenFrom;
    // Address of token swapping to; filled by vault
    address tokenTo;
    // Amount of token swapping from; filled by vault
    uint256 tokenFromAmt;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // TODO Timestamp of deadline
    uint256 deadline;
    // Execution fee sent to GMX for swap orders
    uint256 executionFee;
    // Order key from GMX in bytes32
    bytes32 orderKey;
  }

  struct HealthParams {
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // LP token balance in 1e18
    uint256 lpAmtBefore;
    // Debt amount of tokenA in token decimals
    uint256 debtAmtTokenABefore;
    // Debt amount of tokenB in token decimals
    uint256 debtAmtTokenBBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  /* ========== ENUM ========== */

  enum Status {
    // Vault is not open for any action
    Closed,
    // Vault is open for deposit/withdraw/rebalance
    Open,
    // User is depositing assets
    Deposit,
    // Vault is borrowing assets
    Borrow,
    // Vault is swapping for adding liquidity; note: unused
    Swap_For_Add,
    // Vault is adding liquidity
    Add_Liquidity,
    // Vault is minting shares
    Mint,
    // Vault is staking LP token; note: unused
    Stake,
    // User is withdrawing assets
    Withdraw,
    // Vault is unstaking LP token; note: unused
    Unstake,
    // Vault is removing liquidity
    Remove_Liquidity,
    // Vault is swapping assets for repayments
    Swap_For_Repay,
    // Vault is repaying assets
    Repay,
    // Vault is swapping assets for withdrawal
    Swap_For_Withdraw,
    // Vault is burning shares
    Burn,
    // Vault is rebalancing by adding more debt
    Rebalance_Add,
    // Vault is borrowing during rebalancing add
    Rebalance_Add_Borrow,
    // Vault is repaying during rebalancing add
    Rebalance_Add_Repay,
    // Vault is swapping for adding liquidity during rebalancing add; note: unused
    Rebalance_Add_Swap_For_Add,
    // Vault is adding liquidity during rebalancing add
    Rebalance_Add_Add_Liquidity,
    // Vault is rebalancing by reducing debt
    Rebalance_Remove,
    // Vault is removing liquidity during rebalancing remove
    Rebalance_Remove_Remove_Liquidity,
    // Vault is borrowing during rebalancing remove
    Rebalance_Remove_Borrow,
    // Vault is swapping for repay during rebalancing remove
    Rebalance_Remove_Swap_For_Repay,
    // Vault is repaying during rebalancing remove
    Rebalance_Remove_Repay,
    // Vault is swapping for adding liquidity during rebalancing remove; note: unused
    Rebalance_Remove_Swap_For_Add,
    // Vault is adding liquidity during rebalancing remove
    Rebalance_Remove_Add_Liquidity,
    // Vault is compounding
    Compound
  }

  enum Delta {
    Neutral,
    Long
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IGMXExchangeRouter } from  "../../interfaces/protocols/gmx/IGMXExchangeRouter.sol";
import { GMXTypes } from "./GMXTypes.sol";

library GMXWorker {

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * @dev Add strategy's tokens for liquidity and receive LP tokens
    * @param self Vault store data
    * @param alp GMXTypes.AddLiquidityParams
    * @return depositKey Hashed key of created deposit in bytes32
  */
  function addLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.AddLiquidityParams memory alp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{ value: alp.executionFee }(
      self.depositVault,
      alp.executionFee
    );

    // Send tokens
    self.exchangeRouter.sendTokens(
      address(self.tokenA),
      self.depositVault,
      alp.tokenAAmt
    );

    self.exchangeRouter.sendTokens(
      address(self.tokenB),
      self.depositVault,
      alp.tokenBAmt
    );

    // TODO calculate slippage in minMarketTokens
    // alp.slippage

    // Create deposit
    IGMXExchangeRouter.CreateDepositParams memory _cdp =
      IGMXExchangeRouter.CreateDepositParams({
        receiver: address(this),
        callbackContract: self.callback,
        uiFeeReceiver: address(0), // TODO uiFeeReceiver?
        market: address(self.lpToken),
        initialLongToken: address(self.tokenA),
        initialShortToken: address(self.tokenB),
        longTokenSwapPath: new address[](0),
        shortTokenSwapPath: new address[](0),
        minMarketTokens: 0,
        shouldUnwrapNativeToken: true,
        executionFee: alp.executionFee,
        callbackGasLimit: 2000000
      });

    return self.exchangeRouter.createDeposit(_cdp);
  }

  /**
    * @dev Remove liquidity of strategy's LP token and receive underlying tokens
    * @param self Vault store data
    * @param rlp GMXTypes.RemoveLiquidityParams
    * @return withdrawKey Hashed key of created withdraw in bytes32
  */
  function removeLiquidity(
    GMXTypes.Store storage self,
    GMXTypes.RemoveLiquidityParams memory rlp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{value: rlp.executionFee }(
      self.withdrawalVault,
      rlp.executionFee
    );

    // Send GM LP tokens
    self.exchangeRouter.sendTokens(
      address(self.lpToken),
      self.withdrawalVault,
      rlp.lpTokenAmt
    );

    // TODO address slippage
    // TODO address slippage in minLongTokenAmount/minShortTokenAmount

    // Create withdrawal
    IGMXExchangeRouter.CreateWithdrawalParams memory _cwp =
      IGMXExchangeRouter.CreateWithdrawalParams({
        receiver: address(this),
        callbackContract: self.callback,
        uiFeeReceiver: address(0),
        market: address(self.lpToken),
        longTokenSwapPath: new address[](0),
        shortTokenSwapPath: new address[](0),
        minLongTokenAmount: 0,
        minShortTokenAmount: 0,
        shouldUnwrapNativeToken: true,
        executionFee: rlp.executionFee,
        callbackGasLimit: 2000000
      });

    return self.exchangeRouter.createWithdrawal(_cwp);
  }

  /**
    * @dev Swap one token for another token
    * @param self Vault store data
    * @param sp GMXTypes.SwapParams struct
    * @return swapKey Key hash of order created
  */
  function swap(
    GMXTypes.Store storage self,
    GMXTypes.SwapParams memory sp
  ) external returns (bytes32) {
    // Send native token for execution fee
    self.exchangeRouter.sendWnt{value: sp.executionFee}(
      self.orderVault,
      sp.executionFee
    );

    // Send tokens
    self.exchangeRouter.sendTokens(
      sp.tokenFrom,
      self.orderVault,
      sp.tokenFromAmt
    );

    address[] memory _swapPath = new address[](1);
    _swapPath[0] = address(self.lpToken);

    IGMXExchangeRouter.CreateOrderParamsAddresses memory _addresses;
    _addresses.receiver = address(this);
    _addresses.initialCollateralToken = sp.tokenFrom;
    _addresses.callbackContract = self.callback;
    _addresses.market = address(0);
    _addresses.swapPath = _swapPath;
    _addresses.uiFeeReceiver = address(0);

    IGMXExchangeRouter.CreateOrderParamsNumbers memory _numbers;
    _numbers.sizeDeltaUsd = 0;
    _numbers.initialCollateralDeltaAmount = 0;
    _numbers.triggerPrice = 0;
    _numbers.acceptablePrice = 0;
    _numbers.executionFee = sp.executionFee;
    _numbers.callbackGasLimit = 2000000;
    _numbers.minOutputAmount = 0; // TODO

    IGMXExchangeRouter.CreateOrderParams memory _params =
      IGMXExchangeRouter.CreateOrderParams({
        addresses: _addresses,
        numbers: _numbers,
        orderType: IGMXExchangeRouter.OrderType.MarketSwap,
        decreasePositionSwapType: IGMXExchangeRouter.DecreasePositionSwapType.NoSwap,
        isLong: false,
        shouldUnwrapNativeToken: true,
        referralCode: bytes32(0)
      });

    // Returns bytes32 orderKey
    return self.exchangeRouter.createOrder(_params);

    // Note that keeper is needed to continue the swap once GMX keeper has fulfilled it
  }
}