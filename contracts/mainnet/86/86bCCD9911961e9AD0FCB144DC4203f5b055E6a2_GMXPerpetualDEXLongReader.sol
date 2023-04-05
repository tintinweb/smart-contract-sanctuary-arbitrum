// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/tokens/IERC20.sol";
import "../../interfaces/vaults/gmx/IGMXPerpetualDEXLongVault.sol";
import "../../interfaces/vaults/gmx/IGMXPerpetualDEXLongManager.sol";
import "../../interfaces/vaults/gmx/IGMXGLPManager.sol";
import "../../interfaces/lending/ILendingPool.sol";
import "../../interfaces/oracles/IChainlinkOracle.sol";


contract GMXPerpetualDEXLongReader {
  /* ========== STATE VARIABLES ========== */

  // Vault's address
  IGMXPerpetualDEXLongVault public immutable vault;
  // Vault's manager address
  IGMXPerpetualDEXLongManager public immutable manager;
  // GLP manager
  IGMXGLPManager public immutable glpManager;
  // Chainlink oracle
  IChainlinkOracle public immutable chainlinkOracle;
  // Deposit token - USDC
  IERC20 public immutable token;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  uint256 public constant GLP_PRICE_DIVIDER = 1e12;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _manager Manager contract
  */
  constructor(
    IGMXPerpetualDEXLongVault _vault,
    IGMXPerpetualDEXLongManager _manager
  ) {
    require(address(_vault) != address(0), "Invalid address");
    require(address(_manager) != address(0), "Invalid address");

    vault = _vault;
    manager = _manager;
    chainlinkOracle = IChainlinkOracle(vault.chainlinkOracle());
    glpManager = IGMXGLPManager(manager.glpManager());
    token = IERC20(vault.token());
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Returns the total value of token assets held by the manager; asset = debt + equity
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValue() public view returns (uint256) {
    uint256 tokenAssetAmt = manager.lpTokenAmt();

    // false passed in to get minimum/sell price
    // @note glpManager returns price in 1e30
    return (glpPrice() / GLP_PRICE_DIVIDER * tokenAssetAmt / SAFE_MULTIPLIER);
  }

  /**
    * Returns the total value of token assets held by the manager; asset = debt + equity
    * @param _glpPrice    Price of GLP token
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValueWithPrice(uint256 _glpPrice) external view returns (uint256) {
     uint256 tokenAssetAmt = manager.lpTokenAmt();
    return (_glpPrice / GLP_PRICE_DIVIDER * tokenAssetAmt / SAFE_MULTIPLIER);
  }

  /**
    * Returns the value of token debt held by the manager
    * @return debtValue   Value of token A and token B debt in 1e18
  */
  function debtValue() public view returns (uint256) {
    return tokenValue(address(token), manager.debtInfo());
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
    * Returns the amt of token assets held by manager
    * @return assetAddresses   Array of token addresses
    * @return assetAmt   Array of token amt in token decimals
  */
  function assetAmt() public view returns (address[] memory, uint256[] memory) {
    (address[] memory tokenAddress, uint256[] memory tokenAmt) = manager.assetInfo();
    return (tokenAddress, tokenAmt);
  }

  /**
    * Returns the amt of token debt held by manager
    * @return debtAmt   Amt of token debt in token decimals
  */
  function debtAmt() public view returns (uint256) {
    return manager.debtInfo();
  }

  /**
    * Returns the amt of LP tokens held by manager
    * @return lpAmt   Amt of LP tokens in 1e18
  */
  function lpAmt() public view returns (uint256) {
    return manager.lpTokenAmt();
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
    * Gets price of GLP token
    * @return glpPrice price of GLP in 1e18
   */
  function glpPrice() public view returns (uint256) {
    return glpManager.getPrice(false);
  }

  /**
    * Returns the desired token weight
    * @param _token Token address
    * @return tokenWeight Token weight in 1e18
  */
  function currentTokenWeight(address _token) external view returns (uint256) {
    return manager.currentTokenWeight(_token);
  }

  /**
    * Returns all whitelisted Token addresses and current weights
    * @return tokenAddress Array of token addresses
    * @return tokenWeight Array of token weights in 1e18
  */
  function currentTokenWeights() external view returns (address[] memory, uint256[] memory) {
    (address[] memory tokenAddress, uint256[] memory tokenWeight) = manager.currentTokenWeights();
    return (tokenAddress, tokenWeight);
  }

  /**
    * To get additional capacity vault can hold based on lending pool available liquidity
    @ @return additionalCapacity Additional capacity vault can hold based on lending pool available liquidity
  */
  function additionalCapacity() public view returns (uint256) {
    IGMXPerpetualDEXLongVault.VaultConfig memory _vaultConfig = vault.vaultConfig();

    address tokenLendingPool = manager.tokenLendingPool();

    uint256 lendPoolMax = tokenValue(address(token), ILendingPool(tokenLendingPool).totalAvailableSupply())
      * SAFE_MULTIPLIER
      / (_vaultConfig.targetLeverage - SAFE_MULTIPLIER);

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

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalAvailableSupply() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function deposit(uint256 _assetAmount, uint256 _minSharesAmount) external;
  function withdraw(uint256 _ibTokenAmount, uint256 _minWithdrawAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
  function withdrawReserve(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXPerpetualDEXLongVault {
  struct VaultConfig {
    // Target leverage of the vault in 1e18
    uint256 targetLeverage;
  }

  function token() external view returns (address);
  function treasury() external view returns (address);
  function perfFee() external view returns (uint256);
  function chainlinkOracle() external view returns (address);
  function vaultConfig() external view returns (VaultConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../enum/ManagerAction.sol";

interface IGMXPerpetualDEXLongManager {
  function debtInfo() external view returns (uint256);
  function lpTokenAmt() external view returns (uint256);
  function currentTokenWeight(address _token) external view returns (uint256);
  function currentTokenWeights() external view returns (address[] memory, uint256[] memory);
  function assetInfo() external view returns (address[] memory, uint256[] memory);
  function glpManager() external view returns (address);
  function work(
    ManagerAction _action,
    uint256 _lpAmt,
    uint256 _borrowTokenAAmt,
    uint256 _repayTokenAAmt
  ) external;
  function compound(address[] memory _rewardTrackers) external;
  function tokenLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXGLPManager {
  function getPrice(bool _maximise) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum ManagerAction {
  Deposit,
  Withdraw,
  AddLiquidity,
  RemoveLiquidity
}