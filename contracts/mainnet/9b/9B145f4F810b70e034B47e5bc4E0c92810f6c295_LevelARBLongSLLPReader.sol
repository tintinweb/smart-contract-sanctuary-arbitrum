// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum ManagerAction {
  Deposit,
  Withdraw,
  AddLiquidity,
  RemoveLiquidity
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalAvailableSupply() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function deposit(uint256 _assetAmount, uint256 _minSharesAmount) payable external;
  function withdraw(uint256 _ibTokenAmount, uint256 _minWithdrawAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlinkOracle {
  function consult(address _token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address _token) external view returns (uint256 price);
  function addTokenPriceFeed(address _token, address _feed) external;
  function addTokenMaxDelay(address _token, uint256 _maxDelay) external;
  function addTokenMaxDeviation(address _token, uint256 _maxDeviation) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILevelARBOracle {
  function getLLPPrice(address _token, bool _bool) external view returns (uint256);
  function getLLPAmountIn(
    uint256 _amtOut,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

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
     * @dev Returns the amount of tokens owned by `accoungit t`.
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

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../../enum/ManagerAction.sol";

interface ILevelARBLongSLLPManager {
  struct WorkData {
    address token;
    uint256 lpAmt;
    uint256 borrowUSDTAmt;
    uint256 repayUSDTAmt;
  }

  function debtAmt() external view returns (uint256);
  function lpAmt() external view returns (uint256);
  function work(
    ManagerAction _action,
    WorkData calldata _data
  ) external;
  function lendingPoolUSDT() external view returns (address);
  function stakePool() external view returns (address);
  function compound() external;
  function updateKeeper(address _keeper, bool _approval) external;
  function unstakeAndTransferLVL() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILevelARBLongSLLPVault {
  struct VaultConfig {
    // Target leverage of the vault in 1e18
    uint256 targetLeverage;
    // Management fee per second in % in 1e18
    uint256 mgmtFeePerSecond;
    // Performance fee in % in 1e18
    uint256 perfFee;
    // Max capacity of vault in 1e18
    uint256 maxCapacity;
  }

  function svTokenValue() external view returns (uint256);
  function treasury() external view returns (address);
  function vaultConfig() external view returns (VaultConfig memory);
  function totalSupply() external view returns (uint256);
  function mintMgmtFee() external;
  function togglePause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ILevelMasterV2 {
  function pendingReward(
    uint256 _pid,
    address _user
  ) external view returns (uint256 pending);
  function userInfo(
    uint256 _pid,
    address _user
  ) external view returns (uint256, int256);
  function deposit(uint256 pid, uint256 amount, address to) external;
  function withdraw(uint256 pid, uint256 amount, address to) external;
  function harvest(uint256 pid, address to) external;
  function addLiquidity(
    uint256 pid,
    address assetToken,
    uint256 assetAmount,
    uint256 minLpAmount,
    address to
  ) external;
  function removeLiquidity(
    uint256 pid,
    uint256 lpAmount,
    address toToken,
    uint256 minOut,
    address to
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ILiquidityPool {

  struct AssetInfo {
    /// @notice amount of token deposited (via add liquidity or increase long position)
    uint256 poolAmount;
    /// @notice amount of token reserved for paying out when user decrease long position
    uint256 reservedAmount;
    /// @notice total borrowed (in USD) to leverage
    uint256 guaranteedValue;
    /// @notice total size of all short positions
    uint256 totalShortSize;
  }

  function calcRemoveLiquidity(
    address _tranche,
    address _tokenOut,
    uint256 _lpAmt
  ) external view returns (
    uint256 outAmount,
    uint256 outAmountAfterFee,
    uint256 fee
  );
  function calcSwapOutput(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (
    uint256 amountOut,
    uint256 feeAmount
  );
  function fee() external view returns (
    uint256 positionFee,
    uint256 liquidationFee,
    uint256 baseSwapFee,
    uint256 taxBasisPoint,
    uint256 stableCoinBaseSwapFee,
    uint256 stableCoinTaxBasisPoint,
    uint256 daoFee
  );
  function isAsset(address _asset) external view returns (bool isAsset);
  function targetWeights(address _token) external view returns (uint256 weight);
  function totalWeight() external view returns (uint256 totalWeight);
  function getPoolValue(bool _bool) external view returns (uint256 value);
  function getTrancheValue(
    address _tranche,
    bool _max
  ) external view returns (uint256 sum);

  function addRemoveLiquidityFee() external view returns (uint256);
  function virtualPoolValue() external view returns (uint256);
  function getPoolAsset(address _token) external view returns (AssetInfo memory);
  function trancheAssets(address _tranche, address _token) external view returns (
    uint256 poolAmount,
    uint256 reservedAmount,
    uint256 guaranteedValue,
    uint256 totalShortSize
  );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPoolLens {
  function getTrancheValue(
    address _tranche,
    bool _max
  ) external view returns (uint256);

  function getPoolValue(bool _max) external view returns (uint256);

  function getAssetAum(
    address _tranche,
    address _token,
    bool _max
  ) external view returns (uint256);

  function getAssetPoolAum(
    address _token,
    bool _max
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {

  /* ========== ERRORS ========== */

  // Authorization
  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();

  // Vault deposit errors
  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InsufficientDepositBalance();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error InsufficientLendingLiquidity();

  // Vault withdrawal errors
  error InvalidWithdrawToken();
  error EmptyWithdrawAmount();
  error InsufficientWithdrawAmount();
  error InsufficientWithdrawBalance();
  error InsufficientAssetsReceived();

  // Vault rebalance errors
  error EmptyLiquidityProviderAmount();

  // Flash loan prevention
  error WithdrawNotAllowedInSameDepositBlock();

  // Invalid Token
  error InvalidTokenIn();
  error InvalidTokenOut();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../interfaces/tokens/IERC20.sol";
import "../../../interfaces/lending/ILendingPool.sol";
import "../../../interfaces/oracles/IChainlinkOracle.sol";
import "../../../interfaces/oracles/ILevelARBOracle.sol";
import "../../../interfaces/vaults/level/arb/ILevelARBLongSLLPVault.sol";
import "../../../interfaces/vaults/level/arb/ILevelARBLongSLLPManager.sol";
import "../../../interfaces/vaults/level/arb/ILiquidityPool.sol";
import "../../../interfaces/vaults/level/arb/IPoolLens.sol";
import "../../../interfaces/vaults/level/arb/ILevelMasterV2.sol";
import "../../../utils/Errors.sol";

contract LevelARBLongSLLPReader {
    /* ========== STATE VARIABLES ========== */

  // Vault's address
  ILevelARBLongSLLPVault public immutable vault;
  // Vault's manager address
  ILevelARBLongSLLPManager public immutable manager;
  // Level liquidity pool
  ILiquidityPool public immutable liquidityPool;
  // Level pool lens
  IPoolLens public immutable poolLens;
  // Chainlink oracle
  IChainlinkOracle public immutable chainlinkOracle;
  // Steadefi deployed Level ARB oracle
  ILevelARBOracle public immutable levelARBOracle;
  // LLP stake pool
  ILevelMasterV2 public immutable sllpStakePool;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
  address public constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
  address public constant SLLP = 0x5573405636F4b895E511C9C54aAfbefa0E7Ee458;

  /* ========== MAPPINGS ========== */

  // Mapping of approved tokens
  mapping(address => bool) public tokens;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _manager Manager contract
    * @param _liquidityPool Level liquidity pool
    * @param _poolLens Level pool lens
    * @param _chainlinkOracle Chainlink oracle
    * @param _levelARBOracle Steadefi deployed Level ARB oracle
    * @param _sllpStakePool SLLP stake pool
  */
  constructor(
    ILevelARBLongSLLPVault _vault,
    ILevelARBLongSLLPManager _manager,
    ILiquidityPool _liquidityPool,
    IPoolLens _poolLens,
    IChainlinkOracle _chainlinkOracle,
    ILevelARBOracle _levelARBOracle,
    ILevelMasterV2 _sllpStakePool
  ) {
    tokens[WETH] = true;
    tokens[WBTC] = true;
    tokens[USDT] = true;
    tokens[USDC] = true;
    tokens[SLLP] = true;

    vault = _vault;
    manager = _manager;
    liquidityPool = _liquidityPool;
    poolLens = _poolLens;
    chainlinkOracle = _chainlinkOracle;
    levelARBOracle = _levelARBOracle;
    sllpStakePool = _sllpStakePool;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Returns the total value of token assets held by the manager; asset = debt + equity
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValue() public view returns (uint256) {
    return (sllpPrice(false) * manager.lpAmt() / SAFE_MULTIPLIER);
  }

  /**
    * Returns the total value of token assets held by the manager; asset = debt + equity
    * Allows _sllpPrice to be passed to save gas from recurring calls by external contract(s)
    * @param _sllpPrice    Price of SLLP token in 1e18
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValueWithPrice(uint256 _sllpPrice) external view returns (uint256) {
    return (_sllpPrice * manager.lpAmt() / SAFE_MULTIPLIER);
  }

  /**
    * Returns the value of token debt held by the manager
    * @return debtValue   Value of all debt in 1e18
  */
  function debtValue() public view returns (uint256) {
    return tokenValue(USDT, manager.debtAmt());
  }

  /**
    * Returns the value of token equity held by the manager; equity = asset - debt
    * @return equityValue   Value of total equity in 1e18
  */
  function equityValue() public view returns (uint256) {
    uint256 _assetValue = assetValue();
    uint256 _debtValue = debtValue();
    // in underflow condition return 0
    if (_debtValue > _assetValue) return 0;
    unchecked {
      return (_assetValue - _debtValue);
    }
  }

  /**
    * Returns all SLLP asset token addresses and current weights
    * @return tokenAddresses array of whitelisted tokens
    * @return tokenAmts array of token amts in 1e18
  */
  function assetAmt() public view returns (address[4] memory, uint256[4] memory) {
    address[4] memory tokenAddresses = [WETH, WBTC, USDT, USDC];
    uint256[4] memory tokenAmts;

    uint256 _lpAmt = manager.lpAmt();
    uint256 _totalLpSupply = IERC20(SLLP).totalSupply();

    for (uint256 i = 0; i < tokenAddresses.length;) {
      uint256 _assetAmt = poolLens.getAssetAum(SLLP, tokenAddresses[i], false)
                          * SAFE_MULTIPLIER
                          / chainlinkOracle.consultIn18Decimals(tokenAddresses[i]);

      tokenAmts[i] = _assetAmt * _lpAmt / _totalLpSupply / 1e12 / 10**(18 - IERC20(tokenAddresses[i]).decimals());

      unchecked { i ++; }
    }

    return (tokenAddresses, tokenAmts);
  }

  /**
    * Returns the amt of token debt held by manager
    * @return debtAmt   Amt of token debt in token decimals
  */
  function debtAmt() public view returns (uint256) {
    return manager.debtAmt();
  }

  /**
    * Returns the amt of LP tokens held by manager
    * @return lpAmt   Amt of LP tokens in 1e18
  */
  function lpAmt() public view returns (uint256) {
    return manager.lpAmt();
  }

  /**
    * Returns the current leverage (asset / equity)
    * @return leverage   Current leverage in 1e18
  */
  function leverage() public view returns (uint256) {
    if (assetValue() == 0 || equityValue() == 0) return 0;
    return assetValue() * SAFE_MULTIPLIER / equityValue();
  }

  /**
    * Debt ratio: token debt value / total asset value
    * @return debtRatio   Current debt ratio % in 1e18
  */
  function debtRatio() public view returns (uint256) {
    if (assetValue() == 0) return 0;
    return debtValue() * SAFE_MULTIPLIER / assetValue();
  }

  /**
    * Convert token amount to value using oracle price
    * @param _token Token address
    * @param _amt Amount of token in token decimals
    @ @return tokenValue Token value in 1e18
  */
  function tokenValue(address _token, uint256 _amt) public view returns (uint256) {
    return _amt * 10**(18 - IERC20(_token).decimals())
                * chainlinkOracle.consultIn18Decimals(_token)
                / SAFE_MULTIPLIER;
  }

  /**
    * Gets price of SLLP token
    * @param _bool true for maximum price, false for minimum price
    * @return sllpPrice price of SLLP in 1e18
   */
  function sllpPrice(bool _bool) public view returns (uint256) {
    return levelARBOracle.getLLPPrice(SLLP, _bool) / 1e12;
  }

  /**
    * Returns the current token weight
    * @param _token   token's address
    * @return tokenWeight token weight in 1e18
  */
  function currentTokenWeight(address _token) public view returns (uint256) {
    if (!tokens[_token]) revert Errors.InvalidDepositToken();

    return poolLens.getAssetAum(SLLP, _token, false)
           * 1e18
           / poolLens.getTrancheValue(SLLP, false);
  }

  /**
    * Returns all whitelisted token addresses and current weights
    * Hardcoded to be WETH, WBTC, USDT, USDC
    * @return tokenAddresses array of whitelisted tokens
    * @return tokenWeight array of token weights in 1e18
  */
  function currentTokenWeights() public view returns (address[4] memory, uint256[4] memory) {
    address[4] memory tokenAddresses = [WETH, WBTC, USDT, USDC];
    uint256[4] memory tokenWeight;

    for (uint256 i = 0; i < tokenAddresses.length;) {
      tokenWeight[i] = currentTokenWeight(tokenAddresses[i]);
      unchecked { i ++; }
    }

    return (tokenAddresses, tokenWeight);
  }

  /**
    * Returns the target token weight
    * @param _token   token's address
    * @return tokenWeight token weight in 1e18
  */
  function targetTokenWeight(address _token) public view returns (uint256) {
    if (!tokens[_token]) revert Errors.InvalidDepositToken();

    // normalize weights in 1e3 to 1e18 by multiplying by 1e15
    return liquidityPool.targetWeights(_token) * 1e15;
  }

  /**
    * Returns all whitelisted token addresses and target weights
    * Hardcoded to be WETH, WBTC, USDT, USDC
    * @return tokenAddresses array of whitelisted tokens
    * @return tokenWeight array of token weights in 1e18
  */
  function targetTokenWeights() public view returns (address[4] memory, uint256[4] memory) {
    address[4] memory tokenAddresses = [WETH, WBTC, USDT, USDC];
    uint256[4] memory tokenWeight;

    for (uint256 i = 0; i < tokenAddresses.length;) {
      tokenWeight[i] = targetTokenWeight(tokenAddresses[i]);
      unchecked { i ++; }
    }

    return (tokenAddresses, tokenWeight);
  }

  /**
    * Get tranche LLP value
    * @param _token  Address of LLP
    * @param _bool true for maximum price, false for minimum price
    * @return tranche value in 1e30
  */
  function getTrancheValue(address _token, bool _bool) public view returns (uint256) {
    return liquidityPool.getTrancheValue(_token, _bool);
  }

  /**
    * Get total value of liqudiity pool across all LLPs in USD
    * @return pool value in 1e30
  */
  function getPoolValue() public view returns (uint256) {
    return liquidityPool.getPoolValue(false);
  }

  /**
    * To get additional deposit value (in USD) vault can accept based on lending pools available liquidity
    @ @return additionalCapacity Additional capacity in USDT value 1e18
  */
  function additionalCapacity() public view returns (uint256) {
    ILevelARBLongSLLPVault.VaultConfig memory _vaultConfig = vault.vaultConfig();

    address lendingPool = manager.lendingPoolUSDT();

    uint256 lendPoolMax = tokenValue(address(USDT), ILendingPool(lendingPool).totalAvailableSupply())
      * SAFE_MULTIPLIER
      / (_vaultConfig.targetLeverage - 1e18);

    return lendPoolMax;
  }

  /**
    * External function to get soft capacity vault can hold based on lending pool available liquidity and current equity value
    @ @return capacity soft capacity of vault
  */
  function capacity() external view returns (uint256) {
    return additionalCapacity() + equityValue();
  }
}