// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXRouter {
  function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
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

import "../interfaces/swaps/gmx/IGMXRouter.sol";
import "../interfaces/vaults/gmx/IGMXVault.sol";
import "../interfaces/vaults/gmx/IGMXGLPManager.sol";
import "../interfaces/tokens/IERC20.sol";


contract GMXOracle {
  /* ========== STATE VARIABLES ========== */

  // GMX router contract
  IGMXRouter public immutable gmxRouter;
  // GMX vault contract
  IGMXVault public immutable gmxVault;
  // GMX GLP manager contract
  IGMXGLPManager public immutable glpManager;

  /* ========== CONSTANTS ========== */

  address constant GLP = 0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _gmxRouter GMX router contract address
    * @param _gmxVault GMX vault contract address
    * @param _glpManager GMX GLP manager contract address
  */
  constructor(address _gmxRouter, address _gmxVault, address _glpManager) {
    require(_gmxRouter != address(0), "Invalid address");
    require(_gmxVault != address(0), "Invalid address");
    require(_glpManager != address(0), "Invalid address");

    gmxRouter = IGMXRouter(_gmxRouter);
    gmxVault = IGMXVault(_gmxVault);
    glpManager = IGMXGLPManager(_glpManager);
  }

  /* ========== VIEW FUNCTIONs ========== */

  /**
    * Used to get how much GLP in is required to get amtOut of tokenOut
    * @param _amtOut  Amount of tokenOut
    * @param _tokenIn  GLP
    * @param _tokenOut  Token to get out
    * @return  Amount of GLP in
  */
  function getGlpAmountIn(
    uint256 _amtOut,
    address _tokenIn,
    address _tokenOut
  ) public view returns (uint256) {
    require(_tokenIn == GLP, "Oracle tokenIn must be GLP");
    require(gmxVault.whitelistedTokens(_tokenOut), "Oracle tokenOut must be GMX whitelisted");

    uint256 BASIS_POINT_DIVISOR = gmxVault.BASIS_POINTS_DIVISOR(); //10000
    uint256 PRICE_PRECISION = gmxVault.PRICE_PRECISION(); // 1e30

    // get token out price from gmxVault which returns in 1e30
    uint256 tokenOutPrice = gmxVault.getMinPrice(_tokenOut) / 1e12;
    // get estimated value of tokenOut in usdg
    uint256 estimatedUsdgAmount = _amtOut * tokenOutPrice / 1e18;

    // get fee using estimatedUsdgAmount
    uint256 feeBasisPoints =  gmxVault.getFeeBasisPoints(
      _tokenOut,
      estimatedUsdgAmount,
      gmxVault.mintBurnFeeBasisPoints(),
      gmxVault.taxBasisPoints(),
      false
    );

    // reverse gmxVault _collectSwapFees
    // add 2 wei to ensure rounding up
    uint256 beforeFeeAmt = (_amtOut + 2) * BASIS_POINT_DIVISOR
                           / (BASIS_POINT_DIVISOR - feeBasisPoints);

    // reverse gmxVault adjustForDecimals
    uint256 beforeAdjustForDecimalsAmt = beforeFeeAmt * (10 ** 18)
                                         / (10 ** gmxVault.tokenDecimals(_tokenOut));

    // reverse gmxVault getRedemptionAmount
    uint256 usdgAmount = beforeAdjustForDecimalsAmt * gmxVault.getMaxPrice(_tokenOut)
                         / PRICE_PRECISION;

    // reverse glpManager _removeLiquidity
    uint256 aumInUsdg = glpManager.getAumInUsdg(false);
    uint256 glpSupply = IERC20(GLP).totalSupply();

    return usdgAmount * glpSupply / aumInUsdg;
  }
}