// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILevelOracle {
  function getPrice(address _token, bool _max) external view returns (uint256);
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


interface ILiquidityCalculator {
  function calcAddRemoveLiquidityFee(address _token, uint256 _tokenPrice, uint256 _valueChange, bool _isAdd) external view returns (uint256);


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

import "../interfaces/tokens/IERC20.sol";
import "../interfaces/vaults/level/arb/ILiquidityPool.sol";
import "../interfaces/vaults/level/arb/IPoolLens.sol";
import "../interfaces/vaults/level/arb/ILiquidityCalculator.sol";
import "../interfaces/oracles/ILevelOracle.sol";
import "../utils/Errors.sol";

contract LevelARBOracle {
  /* ========== STATE VARIABLES ========== */

  // SLLP token address router contract
  address public immutable SLLP;
  // MLLP token address router contract
  address public immutable MLLP;
  // JLLP token address router contract
  address public immutable JLLP;
  // Level liquidity pool
  ILiquidityPool public immutable liquidityPool;
  // Level Pool lens contract
  IPoolLens public immutable poolLens;
  // Level liquidity calculator
  ILiquidityCalculator public immutable liquidityCalculator;
  // Level official oracle
  ILevelOracle public immutable levelOracle;

  /* ========== CONSTANTS ========== */

  uint256 constant SAFE_MULTIPLIER = 1e18;

  /* ========== MAPPINGS ========== */

  // Mapping of approved token in (SLLP, MLLP, JLLP)
  mapping(address => bool) public tokenIn;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _SLLP SLLP token address
    * @param _MLLP MLLP token address
    * @param _JLLP JLLP token address
    * @param _liquidityPool Level liquidity pool address
    * @param _poolLens Level pool lens address
    * @param _liquidityCalculator Level liquidity calculator address
    * @param _levelOracle Level official oracle address
  */
  constructor(
    address _SLLP,
    address _MLLP,
    address _JLLP,
    address _liquidityPool,
    address _poolLens,
    address _liquidityCalculator,
    address _levelOracle
  ) {
    require(_SLLP != address(0), "Invalid address");
    require(_MLLP != address(0), "Invalid address");
    require(_JLLP != address(0), "Invalid address");
    require(_liquidityPool != address(0), "Invalid address");
    require(_poolLens != address(0), "Invalid address");
    require(_liquidityCalculator != address(0), "Invalid address");
    require(_levelOracle != address(0), "Invalid address");

    SLLP = _SLLP;
    MLLP = _MLLP;
    JLLP = _JLLP;

    tokenIn[SLLP] = true;
    tokenIn[MLLP] = true;
    tokenIn[JLLP] = true;

    liquidityPool = ILiquidityPool(_liquidityPool);
    poolLens = IPoolLens(_poolLens);
    liquidityCalculator = ILiquidityCalculator(_liquidityCalculator);
    levelOracle = ILevelOracle(_levelOracle);
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Get price of an LLP in USD value in 1e30
    * @param _token  Address of LLP
    * @param _bool true for maximum price, false for minimum price
    * @return  Amount of LLP in
  */
  function getLLPPrice(address _token, bool _bool) public view returns (uint256) {
    if (!tokenIn[_token]) revert Errors.InvalidTokenIn();

    // get tranche value (in 1e30)
    uint256 llpValue = poolLens.getTrancheValue(_token, _bool);

    // get total supply of tranche LLP tokens (in 1e18)
    uint256 totalSupply = IERC20(_token).totalSupply();

    // get estimated token value of 1 LLP in 1e30
    // note this returns price in 1e18 not 1e30; to remove * 1e12
    return (llpValue * SAFE_MULTIPLIER) / (totalSupply); // to normalize to 1e30
  }

  /**
    * Used to get how much LLP in is required to get amtOut of tokenOut
    * Reverse flow of Level pool removeLiquidity()
    * lpAmt = valueChange * totalSupply / trancheValue
    * valueChange = outAmount * tokenPrice
    * outAmount = outAmountAfterFees * (precision - fee) / precision
    * fee obtained from level's liquidity calculator contract
    * @param _amtOut  Amount of tokenOut wanted
    * @param _tokenIn  Address of LLP
    * @param _tokenOut  Address of token to get out
    * @return  Amount of LLP in
  */
  function getLLPAmountIn(
    uint256 _amtOut,
    address _tokenIn,
    address _tokenOut
  ) public view returns (uint256) {
    if (!tokenIn[_tokenIn]) revert Errors.InvalidTokenIn();
    if (!liquidityPool.isAsset(_tokenOut)) revert Errors.InvalidTokenOut();

    // if _amtOut is 0, just return 0 for LLP amount in as well
    if (_amtOut == 0) return 0;

    // from level poolStorage.sol
    uint256 PRECISION = 1e10;

    // returns price relative to token decimals. e.g.
    // USDT returns in 1e24 as it is 1e6, WBTC in 1e22 as token has 1e8
    // WETH in 1e12 as token has 1e18; price decimals * token decimals = 1e30
    uint256 tokenOutPrice = levelOracle.getPrice(_tokenOut, true);

    // value in 1e30
    uint256 estimatedUSDValue = _amtOut * tokenOutPrice;

    uint256 fee = liquidityCalculator.calcAddRemoveLiquidityFee(
      _tokenOut,
      tokenOutPrice,
      estimatedUSDValue,
      false
    );
    // amount in 1e18
    uint256 outAmountBeforeFees = (_amtOut + 10) * PRECISION / (PRECISION - fee);

    // valueChange in 1e30
    uint256 valueChange = outAmountBeforeFees * tokenOutPrice;

    // trancheValue returned in 1e30
    uint256 trancheValue = poolLens.getTrancheValue(_tokenIn, false);

    // lpAmt in 1e18
    uint256 lpAmtIn = valueChange * IERC20(_tokenIn).totalSupply() / trancheValue;

    return lpAmtIn * 1.002e18 / 1e18;
  }

  /* ========== INTERNAL FUNCTIONS  ========== */

  /**
    * Internal function from Level's contracts
  */
  function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a > b ? a - b : b - a;
    }
  }

  /**
    * Internal function from Level's contracts
  */
  function _zeroCapSub(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
      return a > b ? a - b : 0;
    }
  }
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