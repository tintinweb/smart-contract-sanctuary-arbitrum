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
  function deposit(uint256 _assetAmount, uint256 _minSharesAmount) external;
  function withdraw(uint256 _ibTokenAmount, uint256 _minWithdrawAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
  function withdrawReserve(uint256 _amount) external;
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

interface IStakedGLP {
  function approve(address _spender, uint256 _amount) external returns (bool);
  function transfer(address _recipient, uint256 _amount) external returns (bool);
  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external returns (bool);
  function balanceOf(address _account) external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXGLPManager {
  function getPrice(bool _maximise) external view returns (uint256);
  function getAumInUsdg(bool _maximise) external view returns (uint256);
  function glp() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXVault {
  function usdgAmounts(address _token) external view returns (uint256);
  function allWhitelistedTokens(uint256 _index) external view returns (address);
  function allWhitelistedTokensLength() external view returns (uint256);
  function whitelistedTokens(address _token) external view returns (bool);
  function getMinPrice(address _token) external view returns (uint256);
  function getMaxPrice(address _token) external view returns (uint256);

  function BASIS_POINTS_DIVISOR() external view returns (uint256);
  function PRICE_PRECISION() external view returns (uint256);
  function mintBurnFeeBasisPoints() external view returns (uint256);
  function taxBasisPoints() external view returns (uint256);
  function getFeeBasisPoints(address _token, uint256 _usdgAmt, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
  function tokenDecimals(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../../../enum/ManagerAction.sol";

interface IGMXARBLongManager {
  struct WorkData {
    address token;
    uint256 lpAmt;
    uint256 borrowUSDCAmt;
    uint256 repayUSDCAmt;
  }

  function debtAmt() external view returns (uint256);
  function lpAmt() external view returns (uint256);
  function work(
    ManagerAction _action,
    WorkData calldata _data
  ) external;
  function lendingPoolUSDC() external view returns (address);
  function stakePool() external view returns (address);
  function compound() external;
  function updateKeeper(address _keeper, bool _approval) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXARBLongVault {
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

import "../../../../interfaces/tokens/IERC20.sol";
import "../../../../interfaces/vaults/gmx/v2/arb/IGMXARBLongVault.sol";
import "../../../../interfaces/vaults/gmx/v2/arb/IGMXARBLongManager.sol";
import "../../../../interfaces/lending/ILendingPool.sol";
import "../../../../interfaces/oracles/IChainlinkOracle.sol";
import "../../../../interfaces/vaults/gmx/IGMXVault.sol";
import "../../../../interfaces/vaults/gmx/IGMXGLPManager.sol";
import "../../../../interfaces/tokens/IStakedGLP.sol";

contract GMXARBLongReader {

  /* ========== STATE VARIABLES ========== */

  // Vault's address
  IGMXARBLongVault public immutable vault;
  // Vault's manager address
  IGMXARBLongManager public immutable manager;
  // Chainlink oracle
  IChainlinkOracle public immutable chainlinkOracle;
  // GMX Vault
  IGMXVault public immutable gmxVault;
  // GMX GLP Manager
  IGMXGLPManager public immutable glpManager;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
  address public constant WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;
  address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
  address public constant GLP = 0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258;
  address public constant sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _manager Manager contract
    * @param _chainlinkOracle Chainlink oracle
    * @param _gmxVault GMX Vault
    * @param _glpManager GMX GLP Manager
  */
  constructor(
    IGMXARBLongVault _vault,
    IGMXARBLongManager _manager,
    IChainlinkOracle _chainlinkOracle,
    IGMXVault _gmxVault,
    IGMXGLPManager _glpManager
  ) {
    vault = _vault;
    manager = _manager;
    chainlinkOracle = _chainlinkOracle;
    gmxVault = _gmxVault;
    glpManager = _glpManager;
 }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Returns the total value of token assets held by the manager; asset = debt + equity
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValue() public view returns (uint256) {
    return (glpPrice(false) * manager.lpAmt() / SAFE_MULTIPLIER);
  }

  /**
    * Returns the total value of token assets held by the manager; asset = debt + equity
    * Allows _glpPrice to be passed to save gas from recurring calls by external contract(s)
    * @param _glpPrice    Price of GLP token in 1e18
    * @return assetValue   Value of total assets in 1e18
  */
  function assetValueWithPrice(uint256 _glpPrice) external view returns (uint256) {
    return (_glpPrice * manager.lpAmt() / SAFE_MULTIPLIER);
  }

  /**
    * Returns the value of token debt held by the manager
    * @return debtValue   Value of all debt in 1e18
  */
  function debtValue() public view returns (uint256) {
    return tokenValue(USDC, manager.debtAmt());
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
    * Returns all GLP asset token addresses and current weights
    * @return tokenAddresses array of whitelisted tokens
    * @return tokenAmts array of token amts
  */
  function assetAmt() public view returns (address[] memory, uint256[] memory) {
    // get manager's glp balance
    uint256 _lpAmt = manager.lpAmt();
    // get total supply of glp
    uint256 glpTotalSupply = IStakedGLP(sGLP).totalSupply();
    // get total supply of USDG
    uint256 usdgSupply = getTotalUsdgAmount();

    // calculate manager's glp amt in USDG
    uint256 glpAmtInUsdg = (_lpAmt * SAFE_MULTIPLIER / glpTotalSupply)
      * usdgSupply
      / SAFE_MULTIPLIER;

    uint256 length = gmxVault.allWhitelistedTokensLength();
    address[] memory tokenAddresses = new address[](length);
    uint256[] memory tokenAmts = new uint256[](length);

    address whitelistedToken;
    bool isWhitelisted;
    uint256 tokenWeight;

    for (uint256 i = 0; i < length;) {
      // check if token is whitelisted
      whitelistedToken = gmxVault.allWhitelistedTokens(i);
      isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        tokenAddresses[i] = whitelistedToken;
        // calculate token weight expressed in token amt
        tokenWeight = gmxVault.usdgAmounts(whitelistedToken) * SAFE_MULTIPLIER / usdgSupply;
        tokenAmts[i] = (tokenWeight * glpAmtInUsdg / SAFE_MULTIPLIER)
                      * SAFE_MULTIPLIER
                      / (gmxVault.getMinPrice(whitelistedToken) / 1e12);
      }
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
    * Gets price of GLP token
    * @param _bool true for maximum price, false for minimum price
    * @return glpPrice price of GLP in 1e18
   */
  function glpPrice(bool _bool) public view returns (uint256) {
    return glpManager.getPrice(_bool) / 1e12;
  }

  /**
    * Returns the desired token weight
    * @param _token   token's address
    * @return tokenWeight token weight in 1e18
  */
  function currentTokenWeight(address _token) public view returns (uint256) {
    uint256 usdgSupply = getTotalUsdgAmount();

    return gmxVault.usdgAmounts(_token) * SAFE_MULTIPLIER / usdgSupply;
  }

  /**
    * Returns all whitelisted token addresses and current weights
    * @return tokenAddress array of whitelied tokens
    * @return tokenWeight array of token weights in 1e18
  */
  function currentTokenWeights() public view returns (address[] memory, uint256[]memory) {
    uint256 usdgSupply = getTotalUsdgAmount();
    uint256 length = gmxVault.allWhitelistedTokensLength();

    address[] memory tokenAddress = new address[](length);
    uint256[] memory tokenWeight = new uint256[](length);

    address whitelistedToken;
    bool isWhitelisted;

    for (uint256 i = 0; i < length;) {
      whitelistedToken = gmxVault.allWhitelistedTokens(i);
      isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        tokenAddress[i] = whitelistedToken;
        tokenWeight[i] = gmxVault.usdgAmounts(whitelistedToken)
          * (SAFE_MULTIPLIER)
          / (usdgSupply);
      }
      unchecked { i ++; }
    }

    return (tokenAddress, tokenWeight);
  }

  /**
    * Get total USDG supply
    * @return usdgSupply
  */
  function getTotalUsdgAmount() public view returns (uint256) {
    uint256 length = gmxVault.allWhitelistedTokensLength();
    uint256 usdgSupply;

    address whitelistedToken;
    bool isWhitelisted;

    for (uint256 i = 0; i < length;) {
      whitelistedToken = gmxVault.allWhitelistedTokens(i);
      isWhitelisted = gmxVault.whitelistedTokens(whitelistedToken);
      if (isWhitelisted) {
        usdgSupply += gmxVault.usdgAmounts(whitelistedToken);
      }
      unchecked { i += 1; }
    }
    return usdgSupply;
  }

  /**
    * To get additional capacity vault can hold based on lending pool available liquidity
    @ @return additionalCapacity Additional capacity in USDC value 1e18
  */
  function additionalCapacity() public view returns (uint256) {
    IGMXARBLongVault.VaultConfig memory _vaultConfig = vault.vaultConfig();

    address lendingPool = manager.lendingPoolUSDC();

    uint256 lendPoolMax = tokenValue(address(USDC), ILendingPool(lendingPool).totalAvailableSupply())
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