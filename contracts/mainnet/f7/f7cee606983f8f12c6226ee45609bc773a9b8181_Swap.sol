// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/vault/IVault.sol";
import "../../interfaces/vault/IReader.sol";
import "../../interfaces/core/ISwap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Swap is ISwap {

 IVault public immutable vault;
 IReader public immutable reader;

 constructor(address vault_, address _reader) {
  vault = IVault(vault_);
  reader = IReader(_reader);
 }


  function swapTokens(
    uint256 _amountToSwap,
    address _fromAsset,
    address _toAsset,
    address _receiver
  ) external returns (uint256 amountReturned_, uint256 feesPaidInOut_) {
    (, feesPaidInOut_) = reader.getAmountOut(
      IVault(vault),
      _fromAsset,
      _toAsset,
      _amountToSwap
    );
    IERC20(_fromAsset).transfer(address(vault), _amountToSwap);
    amountReturned_ = vault.swap(_fromAsset, _toAsset, _receiver);
    require(amountReturned_ > 0, "SWAP: swap to stables failed");
    return (amountReturned_, feesPaidInOut_);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

// import "./IVaultUtils.sol";

interface IVault {
  /*==================== Events *====================*/
  event BuyUSDW(
    address account,
    address token,
    uint256 tokenAmount,
    uint256 usdwAmount,
    uint256 feeBasisPoints
  );
  event SellUSDW(
    address account,
    address token,
    uint256 usdwAmount,
    uint256 tokenAmount,
    uint256 feeBasisPoints
  );
  event Swap(
    address account,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 indexed amountOut,
    uint256 indexed amountOutAfterFees,
    uint256 indexed feeBasisPoints
  );
  event DirectPoolDeposit(address token, uint256 amount);
  error TokenBufferViolation(address tokenAddress);
  error PriceZero();

  event PayinWLP(
    // address of the token sent into the vault
    address tokenInAddress,
    // amount payed in (was in escrow)
    uint256 amountPayin
  );

  event PlayerPayout(
    // address the player receiving the tokens (do we need this? i guess it does not matter to who we send tokens for profit/loss calculations?)
    address recipient,
    // address of the token paid to the player
    address tokenOut,
    // net amount sent to the player (this is NOT the net loss, since it includes the payed in tokens, excludes wagerFee and swapFee!)
    uint256 amountPayoutTotal
  );

  event AmountOutNull();

  event WithdrawAllFees(
    address tokenCollected,
    uint256 swapFeesCollected,
    uint256 wagerFeesCollected,
    uint256 referralFeesCollected
  );

  event RebalancingWithdraw(address tokenWithdrawn, uint256 amountWithdrawn);

  event RebalancingDeposit(address tokenDeposit, uint256 amountDeposit);

  event WagerFeeChanged(uint256 newWagerFee);

  event ReferralDistributionReverted(uint256 registeredTooMuch, uint256 maxVaueAllowed);

  /*==================== Operational Functions *====================*/
  function setPayoutHalted(bool _setting) external;

  function isSwapEnabled() external view returns (bool);

  //   function setVaultUtils(IVaultUtils _vaultUtils) external;

  function setError(uint256 _errorCode, string calldata _error) external;

  function usdw() external view returns (address);

  function feeCollector() external returns (address);

  function hasDynamicFees() external view returns (bool);

  function totalTokenWeights() external view returns (uint256);

  function getTargetUsdwAmount(address _token) external view returns (uint256);

  function inManagerMode() external view returns (bool);

  function isManager(address _account) external view returns (bool);

  function tokenBalances(address _token) external view returns (uint256);

  function setInManagerMode(bool _inManagerMode) external;

  function setManager(address _manager, bool _isManager, bool _isWLPManager) external;

  function setIsSwapEnabled(bool _isSwapEnabled) external;

  function setUsdwAmount(address _token, uint256 _amount) external;

  function setBufferAmount(address _token, uint256 _amount) external;

  function setFees(
    uint256 _taxBasisPoints,
    uint256 _stableTaxBasisPoints,
    uint256 _mintBurnFeeBasisPoints,
    uint256 _swapFeeBasisPoints,
    uint256 _stableSwapFeeBasisPoints,
    uint256 _minimumBurnMintFee,
    bool _hasDynamicFees
  ) external;

  function setTokenConfig(
    address _token,
    uint256 _tokenDecimals,
    uint256 _redemptionBps,
    uint256 _maxUsdwAmount,
    bool _isStable
  ) external;

  function setPriceFeedRouter(address _priceFeed) external;

  function withdrawAllFees(address _token) external returns (uint256, uint256, uint256);

  function directPoolDeposit(address _token) external;

  function deposit(address _tokenIn, address _receiver, bool _swapLess) external returns (uint256);

  function withdraw(address _tokenOut, address _receiverTokenOut) external returns (uint256);

  function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

  function tokenToUsdMin(
    address _tokenToPrice,
    uint256 _tokenAmount
  ) external view returns (uint256);

  function priceOracleRouter() external view returns (address);

  function taxBasisPoints() external view returns (uint256);

  function stableTaxBasisPoints() external view returns (uint256);

  function mintBurnFeeBasisPoints() external view returns (uint256);

  function swapFeeBasisPoints() external view returns (uint256);

  function stableSwapFeeBasisPoints() external view returns (uint256);

  function minimumBurnMintFee() external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);

  function allWhitelistedTokens(uint256) external view returns (address);

  function stableTokens(address _token) external view returns (bool);

  function swapFeeReserves(address _token) external view returns (uint256);

  function tokenDecimals(address _token) external view returns (uint256);

  function tokenWeights(address _token) external view returns (uint256);

  function poolAmounts(address _token) external view returns (uint256);

  function bufferAmounts(address _token) external view returns (uint256);

  function usdwAmounts(address _token) external view returns (uint256);

  function maxUsdwAmounts(address _token) external view returns (uint256);

  function getRedemptionAmount(address _token, uint256 _usdwAmount) external view returns (uint256);

  function getMaxPrice(address _token) external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function setVaultManagerAddress(address _vaultManagerAddress, bool _setting) external;

  function wagerFeeBasisPoints() external view returns (uint256);

  function setWagerFee(uint256 _wagerFee) external;

  function wagerFeeReserves(address _token) external view returns (uint256);

  function referralReserves(address _token) external view returns (uint256);

  function getReserve() external view returns (uint256);

  function getWlpValue() external view returns (uint256);

  function usdToTokenMin(address _token, uint256 _usdAmount) external view returns (uint256);

  function usdToTokenMax(address _token, uint256 _usdAmount) external view returns (uint256);

  function usdToToken(
    address _token,
    uint256 _usdAmount,
    uint256 _price
  ) external view returns (uint256);

  function returnTotalOutAndIn(
    address token_
  ) external view returns (uint256 totalOutAllTime_, uint256 totalInAllTime_);

  function payout(
    address _wagerToken,
    address _escrowAddress,
    uint256 _escrowAmount,
    address _recipient,
    uint256 _totalAmount
  ) external;

  function payoutNoEscrow(address _wagerAsset, address _recipient, uint256 _totalAmount) external;

  function payin(address _inputToken, address _escrowAddress, uint256 _escrowAmount) external;

  function setAsideReferral(address _token, uint256 _amount) external;

  function payinWagerFee(address _tokenIn) external;

  function payinSwapFee(address _tokenIn) external;

  function payinPoolProfits(address _tokenIn) external;

  function removeAsideReferral(address _token, uint256 _amountRemoveAside) external;

  function setFeeCollector(address _feeCollector) external;

  function upgradeVault(address _newVault, address _token, uint256 _amount, bool _upgrade) external;

  function setCircuitBreakerAmount(address _token, uint256 _amount) external;

  function clearTokenConfig(address _token) external;

  function updateTokenBalance(address _token) external;

  function setCircuitBreakerEnabled(bool _setting) external;

  function setPoolBalance(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "./IVault.sol";

// import "../gmx/IVaultPriceFeedGMX.sol";

interface IReader {
  function getFees(
    address _vault,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getWagerFees(
    address _vault,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getSwapFeeBasisPoints(
    IVault _vault,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256, uint256, uint256);

  function getAmountOut(
    IVault _vault,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256, uint256);

  function getMaxAmountIn(
    IVault _vault,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256);

  //   function getPrices(
  //     IVaultPriceFeedGMX _priceFeed,
  //     address[] memory _tokens
  //   ) external view returns (uint256[] memory);

  function getVaultTokenInfo(
    address _vault,
    address _weth,
    uint256 _usdwAmount,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getFullVaultTokenInfo(
    address _vault,
    address _weth,
    uint256 _usdwAmount,
    address[] memory _tokens
  ) external view returns (uint256[] memory);

  function getFeesForGameSetupFeesUSD(
    address _tokenWager,
    address _tokenWinnings,
    uint256 _amountWager
  ) external view returns (uint256 wagerFeeUsd_, uint256 swapFeeUsd_, uint256 swapFeeBp_);

  function getNetWinningsAmount(
    address _tokenWager,
    address _tokenWinnings,
    uint256 _amountWager,
    uint256 _multiple
  ) external view returns (uint256 amountWon_, uint256 wagerFeeToken_, uint256 swapFeeToken_);

  function getSwapFeePercentageMatrix(
    uint256 _usdValueOfSwapAsset
  ) external view returns (uint256[] memory);

  function adjustForDecimals(
    uint256 _amount,
    address _tokenDiv,
    address _tokenMul
  ) external view returns (uint256 scaledAmount_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISwap {
  function swapTokens(
    uint256 _amountToSwap,
    address _fromAsset,
    address _toAsset,
    address _receiver
  ) external returns (uint256 amountReturned_, uint256 feesPaidInOut_);
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