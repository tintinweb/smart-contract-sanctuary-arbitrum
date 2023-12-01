//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {WithdrawLoanHelper} from './withdraw/WithdrawHelper.sol';
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {ICToken} from '../interfaces/ICToken.sol';
import {IVault} from "src/interfaces/IFlashLoan.sol";
import {PriceHelper} from '../libraries/PriceHelper.sol';
import {GLPHelper} from '../libraries/GLPHelper.sol';
import {SafeMath} from 'oz/utils/math/SafeMath.sol';
import {CTokenHelper} from '../libraries/CTokenHelper.sol';
import {ReentrancyGuard} from "oz/security/ReentrancyGuard.sol";
import {IVault, IFlashLoanRecipient} from "src/interfaces/IFlashLoan.sol";

contract WithdrawLever is WithdrawLoanHelper, ReentrancyGuard, IFlashLoanRecipient {
  using PriceHelper for IERC20;
  using SafeMath for uint;
  using GLPHelper for IERC20;
  using CTokenHelper for ICToken;

  uint public constant feeBase = 1e18;
  

  constructor(
    address _vault,
    address payable _feeRecipient,
    uint _withdrawFee
  ) {
    vault = IVault(_vault);
    feeRecipient = _feeRecipient;
    require(_withdrawFee < 1e18, "Error: Invalid fee");
    withdrawFee = _withdrawFee;
  }

  function setFees(uint _withdrawFee) external onlyOwner {
    require(_withdrawFee < 1e18, "Error: Invalid fee");
    withdrawFee = _withdrawFee;
  }

  function setFeeRecipient(address payable _feeRecipient) external onlyOwner {
    feeRecipient = _feeRecipient;
  }

  function getFeeAmount(uint256 baseAmount, uint fee) internal pure returns (uint256) {
    return baseAmount.mul(fee).div(feeBase);
  }

  function withdraw(
    ICToken redeemMarket,
    uint redeemAmount,
    ICToken[] memory repayMarkets,
    uint[] memory repayAmounts
  ) public nonReentrant {
    WithdrawParams memory params = WithdrawParams({
      account: msg.sender,
      redeemMarket: redeemMarket,
      redeemAmount: redeemAmount,
      repayMarkets: repayMarkets,
      repayAmounts: repayAmounts,
      maxSlippage: 10000 // default to .5%
    });
    withdrawInternal(params);
  }


  function withdraw(
    ICToken redeemMarket,
    uint redeemAmount,
    ICToken[] memory repayMarkets,
    uint[] memory repayAmounts,
    uint24 maxSlippage
  ) public nonReentrant {
    WithdrawParams memory params = WithdrawParams({
      account: msg.sender,
      redeemMarket: redeemMarket,
      redeemAmount: redeemAmount,
      repayMarkets: repayMarkets,
      repayAmounts: repayAmounts,
      maxSlippage: maxSlippage
    });
    withdrawInternal(params);
  }

  function withdrawInternal(
    WithdrawParams memory params
  ) internal {
    validateSequencer();
    IERC20[] memory tokens = new IERC20[](params.repayMarkets.length);
    for(uint i =0; i < params.repayMarkets.length; i++) {
      tokens[i] = params.repayMarkets[i].underlying();
    }

    uint256[] memory amounts = params.repayAmounts;

    setPendingWithdraw(params.account, params);

    makeFlashLoan(
      tokens,
      amounts,
      params.account
    );
  }

  function makeFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    address account
  ) internal {
    // debugLoan(tokens, amounts, data);
    vault.flashLoan(this, tokens, amounts, abi.encode(account));
  }

  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external onlyVault {
    address _account = abi.decode(userData, (address));
    // executions set pending for msg.sender in PositionHelper
    WithdrawParams memory data = getPendingWithdraw(_account);

    require(
      data.account != address(0) && data.account == _account,
      'Invalid Account'
    );

    // make the withdraw (includes tranfers to vault, feeReceiver, and user)
    leveragedWithdraw(tokens, amounts, feeAmounts, data);

    // Finally, delete the pending execution and set isPending(_account) to false
    removePendingWithdraw(_account);
  }

  modifier onlyVault() {
    require(msg.sender == address(vault), 'Only vault can call this');
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {IVault, IFlashLoanRecipient} from "src/interfaces/IFlashLoan.sol";
import {ICToken} from "src/interfaces/ICToken.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {PriceHelper} from "src/libraries/PriceHelper.sol";
import {CTokenHelper} from "src/libraries/CTokenHelper.sol";
import {GLPHelper} from "src/libraries/CTokenHelper.sol";
import {PendingExecutor} from 'src/vault/PendingExecutor.sol';
import {SwapProtector} from 'src/vault/SwapProtector.sol';

contract WithdrawLoanHelper is PendingExecutor, SwapProtector {
  using PriceHelper for IERC20;
  using CTokenHelper for ICToken;
  using SafeMath for uint;

  IVault public vault;
  uint public withdrawFee;
  address payable public feeRecipient;

  function redeemAllMarkets(
    address account,
    ICToken redeemMarket,
    uint redeemAmount
  ) internal returns (IERC20 redeemedToken, uint redeemedAmount) {
    redeemedToken = redeemMarket.underlying();
    ICToken market = redeemMarket;
    uint balance = market.underlying().balanceOf(address(this));
    // use return value in case of rounding errors
    market.redeemForAccount(account, redeemAmount);

    redeemedAmount = market.underlying().balanceOf(
      address(this)
    ).sub(balance);

    return (redeemedToken, redeemedAmount);
  }

  function repayAllMarkets(
    address account,
    ICToken[] memory repayMarkets,
    uint[] memory repayAmounts
  ) internal {
    for(uint i=0; i < repayMarkets.length; i++) {
      ICToken market = repayMarkets[i];
      uint repayAmount = repayAmounts[i];
      CTokenHelper.approveMarket(market, repayAmount);
      market.repayForAccount(account, repayAmount);
    }
  }

  function getAmountIn(IERC20 tokenFrom, IERC20 tokenTo, uint amountOut) internal view returns (uint) {
    // add increase base loanedAmount by withdrawFee% (implies loanedAmount*withdrawFee > flashloanFee)
    uint amountToAfterFees = amountOut.mul(1e18+withdrawFee).div(1e18);
    // simulate a reverse swap + fees to get amount in
    // this entails that fees must cover the swap fees and the slippage (as well as flashloan fee)
    return tokenTo.getTokensForNumTokens(amountToAfterFees, tokenFrom);
  }

  function feeAndSwapRedeemed(
    IERC20 redeemedToken,
    uint redeemedAmount,
    IERC20[] memory loanTokens,
    uint[] memory loanAmounts,
    uint[] memory loanFees,
    uint24 maxSlippage
  ) internal returns (uint userBalance) {
    userBalance = redeemedAmount;

    for(uint i = 0; i < loanTokens.length; i++) {
      uint amountIn = getAmountIn(redeemedToken, loanTokens[i], loanAmounts[i]);
      require(userBalance > amountIn, "Not enough funds to swap");
      uint amountOut = swap(
        redeemedToken,
        loanTokens[i],
        amountIn,
        maxSlippage
      );
      userBalance -= amountIn;
      // must be > since protocol fee transfer will revert if exactly the same
      require(amountOut > loanAmounts[i]+loanFees[i], 'Not enough funds received to repay loan');
      uint protocolFee = amountOut.sub(loanAmounts[i]+loanFees[i]);
      // transfer fees here since we know we have enough to repay the loan after
      loanTokens[i].transfer(feeRecipient, protocolFee);
      // Transfer the loan + fees back to the vault
      loanTokens[i].transfer(address(vault), loanAmounts[i]+loanFees[i]);
      // subtract the traded tokens from the user balance
    }
  }

  // can only be called from within the flashloan callback
  function leveragedWithdraw(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    WithdrawParams memory data
  ) internal {
    repayAllMarkets(
      data.account,
      data.repayMarkets,
      data.repayAmounts
    );

    (IERC20 redeemedToken, uint redeemedAmount) = redeemAllMarkets(
      data.account,
      data.redeemMarket,
      data.redeemAmount
    );

    uint userBalance = feeAndSwapRedeemed(
      redeemedToken,
      redeemedAmount,
      tokens,
      amounts,
      feeAmounts,
      data.maxSlippage
    );

    // transfer the remaining balance to the user
    GLPHelper.wrapTransfer(redeemedToken, data.account, userBalance);
  }
}

// SPDX-License-Identifier: No License
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.10;

import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {IGlpManager} from "tender/external/gmx/IGlpManager.sol";
import {IRewardRouterV2} from "tender/external/gmx/IRewardRouterV2.sol";
import {IStakedGlp} from "tender/external/gmx/IStakedGlp.sol";
import {IRewardTracker} from "tender/external/gmx/IRewardTracker.sol";
import {IComptroller} from "tender/external/compound/IComptroller.sol";
import {InterestRateModel} from "tender/external/compound/InterestRateModel.sol";

interface ICToken is IERC20 {
  // CERC20 functions
  function underlying() external view returns (IERC20);
  function mintForAccount(address account, uint256 mintAmount) external returns (uint256);
  function mint(uint256 mintAmount) external returns (uint256);
  function redeem(uint256 redeemTokens) external returns (uint256);
  function redeemForAccount(address account, uint256 redeemTokens) external returns (uint256);
  function redeemUnderlyingForAccount(address account, uint256 redeemAmount)
    external
    returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
  function redeemUnderlyingForUser(uint256 redeemAmount, address user) external returns (uint256);
  function borrow(uint256 borrowAmount) external returns (uint256);
  function borrowForAccount(address account, uint256 borrowAmount) external returns (uint256);
  function repayForAccount(address borrower, uint256 repayAmount) external returns (uint256);
  function repayBorrow(uint256 repayAmount) external returns (uint256);
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
  function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral)
    external
    returns (uint256);
  function depositNFT(address _NFTAddress, uint256 _TokenID) external;
  function withdrawNFT(address _NFTAddress, uint256 _TokenID) external;
  function compound() external returns (uint256);

  // CToken functions
  function glpManager() external view returns (IGlpManager);
  function gmxToken() external view returns (IERC20);
  function glpRewardRouter() external view returns (IRewardRouterV2);
  function stakedGLP() external view returns (IStakedGlp);
  function sbfGMX() external view returns (IRewardTracker);
  function stakedGmxTracker() external view returns (IRewardTracker);

  function _notEntered() external view returns (bool);

  function isGLP() external view returns (bool);
  function autocompound() external view returns (bool);
  function glpBlockDelta() external view returns (uint256);
  function lastGlpDepositAmount() external view returns (uint256);

  function comptroller() external view returns (IComptroller);
  function interestRateModel() external view returns (InterestRateModel);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function admin() external view returns (address);
  function pendingAdmin() external view returns (address);
  function initialExchangeRateMantissa() external view returns (uint256);
  function reserveFactorMantissa() external view returns (uint256);
  function accrualBlockNumber() external view returns (uint256);
  function borrowIndex() external view returns (uint256);
  function totalBorrows() external view returns (uint256);
  function totalReserves() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function withdrawFee() external view returns (uint256);
  function performanceFee() external view returns (uint256);
  function exchangeRateBefore() external view returns (uint256);
  function blocksBetweenRateChange() external view returns (uint256);
  function prevExchangeRate() external view returns (uint256);
  function depositsDuringLastInterval() external view returns (uint256);
  function isCToken() external view returns (bool);

  function performanceFeeMAX() external view returns (uint256);
  function withdrawFeeMAX() external view returns (uint256);
  function autoCompoundBlockThreshold() external view returns (uint256);

  event AccrueInterest(
    uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows
  );
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
  event Borrow(
    address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows
  );
  event RepayBorrow(
    address payer,
    address borrower,
    uint256 repayAmount,
    uint256 accountBorrows,
    uint256 totalBorrows
  );
  event LiquidateBorrow(
    address liquidator,
    address borrower,
    uint256 repayAmount,
    address cTokenCollateral,
    uint256 seizeTokens
  );
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
  event NewAdmin(address oldAdmin, address newAdmin);
  event NewComptroller(IComptroller oldComptroller, IComptroller newComptroller);
  event NewMarketInterestRateModel(
    InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel
  );
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  function transfer(address dst, uint256 amount) external returns (bool);
  function transferFrom(address src, address dst, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function balanceOfUnderlying(address owner) external returns (uint256);
  function getAccountSnapshot(address account)
    external
    view
    returns (uint256, uint256, uint256, uint256);
  function borrowRatePerBlock() external view returns (uint256);
  function supplyRatePerBlock() external view returns (uint256);
  function totalBorrowsCurrent() external returns (uint256);
  function borrowBalanceCurrent(address account) external returns (uint256);
  function borrowBalanceStored(address account) external view returns (uint256);
  function exchangeRateCurrent() external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function getCash() external view returns (uint256);
  function accrueInterest() external returns (uint256);
  function seize(address liquidator, address borrower, uint256 seizeTokens)
    external
    returns (uint256);

  /**
   * Admin Functions **
   */
  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);
  function _acceptAdmin() external returns (uint256);
  function _setComptroller(IComptroller newComptroller) external returns (uint256);
  function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);
  function _reduceReserves(uint256 reduceAmount) external returns (uint256);
  function _setInterestRateModel(InterestRateModel newInterestRateModel) external returns (uint256);
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {ICToken} from "./ICToken.sol";

interface IVault {
  function flashLoan(
    IFlashLoanRecipient receiver,
    IERC20[] calldata tokens,
    uint256[] calldata amounts,
    bytes calldata userData
  ) external;
}

interface IFlashLoanRecipient {
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {ICToken} from "./../interfaces/ICToken.sol";
import {Addresses} from "./Addresses.sol";
import {ITenderPriceOracle} from "tender/external/oracle/ITenderPriceOracle.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {IComptroller} from "tender/external/compound/IComptroller.sol";
import {GLPHelper} from './GLPHelper.sol';

library PriceHelper {
  using SafeMath for uint256;

  function getTotalValueUSD (
    IERC20[] memory tokens,
    uint[] memory amounts
  ) internal view returns (uint) {
    uint total = 0;
    for(uint i=0; i < tokens.length; i++) {
      total += getUSDValue(tokens[i], amounts[i]);
    }
    return total;
  }

  function getUSDValue(IERC20 token, uint amount) public view returns (uint) {
    return getUSDPerToken(token).mul(amount).div(10 ** token.decimals());
  }

  function getUSDPerToken(IERC20 token) public view returns (uint256) {
    ITenderPriceOracle oracle = ITenderPriceOracle(IComptroller(Addresses.unitroller).oracle());
    uint oraclePrice = oracle.getUSDPrice(token);
    uint256 oracleDecimals = oracle.getOracleDecimals(token);
    return oraclePrice.mul(10 ** (18 - oracleDecimals));
  }

  function getTokensPerUSD(IERC20 token) public view returns (uint256) {
    // return number of tokens that can be bought Per 1 USD
    uint256 scaledTokensPerUSD = uint256(1e36).div(getUSDPerToken(token));
    uint256 tokenDecimals = token.decimals();
    uint256 actualTokensPerUSD = scaledTokensPerUSD.div(10 ** (18 - tokenDecimals));
    return actualTokensPerUSD;
  }

  function getUSDPerUnderlying(ICToken token) public view returns (uint256) {
    return getUSDPerToken(token.underlying());
  }

  function getUnderlyingPerUSD(ICToken token) public view returns (uint256) {
    return getTokensPerUSD(token.underlying());
  }

  function getProportion(uint256 a, uint256 b) internal pure returns (uint256) {
    return a.mul(1e18).div(b);
  }

  // gives num token1 purchasable for 1 token 0
  function getTokens(IERC20 token0, IERC20 token1) public view returns (uint256) {
    uint256 usdPerToken0 = getUSDPerToken(token0);
    uint256 usdPerToken1 = getUSDPerToken(token1);
    return uint256(10 ** (token1.decimals() + 18)).div(getProportion(usdPerToken1, usdPerToken0));
  }

  // gives num token1 purchasable for numToken0 token0
  function getTokensForNumTokens(IERC20 token0, uint256 numToken0, IERC20 token1)
    public
    view
    returns (uint256)
  {
    uint256 token0ForToken1 = getTokens(token0, token1);
    uint256 numToken1ForNumToken0 = numToken0.mul(token0ForToken1).div(10 ** token0.decimals());
    return numToken1ForNumToken0;
  }
  // gives num token0 requred to purchase numtoken1 token1
  function getNumTokensForTokens(IERC20 token0, IERC20 token1, uint256 numToken1)
    public
    view
    returns (uint256)
  {
    uint256 token1ForToken0 = getTokens(token1, token0);
    uint256 numToken0ForNumToken1 = numToken1.mul(token1ForToken0).div(10 ** token1.decimals());
    return numToken0ForNumToken1;
  }
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IRewardRouterV2} from "tender/external/gmx/IRewardRouterV2.sol";
import {IRewardTracker} from "tender/external/gmx/IRewardTracker.sol";
import {IGlpManager} from "tender/external/gmx/IGlpManager.sol";
import {IGmxVault} from "tender/external/gmx/IGmxVault.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {Addresses} from "./Addresses.sol";
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";

library GLPHelper {
  using SafeMath for uint256;
  IGlpManager public constant glpManager = IGlpManager(Addresses.glpManager);
  IRewardTracker public constant stakedGlp = IRewardTracker(Addresses.stakedGlp);
  IRewardRouterV2 public constant glpRouter = IRewardRouterV2(Addresses.glpRouter);
  IERC20 public constant fsGLP = IERC20(Addresses.fsGLP);
  IGmxVault public constant glpVault = IGmxVault(Addresses.glpVault);

  function usdgAmounts(IERC20 token) public view returns (uint256) {
    return glpVault.usdgAmounts(address(token));
  }

  function getAumInUsdg() public view returns (uint256) {
    return glpManager.getAumInUsdg(true);
  }

  function glpPropCurrent(IERC20 token) public view returns (uint256) {
    return usdgAmounts(token).mul(1e18).div(getAumInUsdg());
  }

  function unstake(
    IERC20 receiveToken,
    uint amount,
    uint minOut
  ) internal returns (uint) {
    stakedGlp.approve(address(GLPHelper.glpRouter), amount);
    return glpRouter.unstakeAndRedeemGlp(
      address(receiveToken),
      amount,
      minOut,
      address(this)
    );
  }

  function wrapTransfer(
    IERC20 token,
    address receiver,
    uint amount
  ) internal returns (bool) {
    if(amount == 0) { return false; }
    else if (token == GLPHelper.fsGLP) {
      return IERC20(address(GLPHelper.stakedGlp)).transfer(receiver, amount);
    }
    return token.transfer(receiver, amount);
  }

  function wrapTransferFrom(
    IERC20 token,
    address spender,
    address receiver,
    uint amount
  ) internal returns (bool) {
    if(amount == 0) { return false; }
    else if (token == GLPHelper.fsGLP) {
      return IERC20(address(GLPHelper.stakedGlp)).transferFrom(spender, receiver, amount);
    }
    return token.transferFrom(spender, receiver, amount);
  }
  /*
   * @notice Mint and stake GLP
   * @param tokenIn Address of the token to mint with
   * @param amountIn Amount of the token to mint with
   * @param minUsdg Minimum usdg to receive during swap for mint
   * @param minGlp Minimum amount of GLP to receive
   */
  function mintAndStake(
    IERC20 tokenIn,
    uint256 amountIn,
    uint minUsdg,
    uint minGlp
  ) internal returns (uint) {
    tokenIn.approve(address(GLPHelper.glpManager), amountIn);
    return glpRouter.mintAndStakeGlp(
      address(tokenIn),
      amountIn,
      minUsdg,
      minGlp
    );
  }

  function approve(
    address spender,
    uint256 amount
  ) internal returns (bool) {
    return stakedGlp.approve(spender, amount);
  }
}

// SPDX-License-Identifier: No License
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import {ICToken} from "./../interfaces/ICToken.sol";
import {IComptroller} from "tender/external/compound/IComptroller.sol";
import {ITenderPriceOracle} from "tender/external/oracle/ITenderPriceOracle.sol";
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {PriceHelper} from "./PriceHelper.sol";
import {GLPHelper} from './GLPHelper.sol';
import {Addresses} from './Addresses.sol';

library CTokenHelper {
  using SafeMath for uint256;
  // Using this instead of reading from market since it is more gas efficient
  IComptroller public constant comptroller = IComptroller(Addresses.unitroller);

  function getCollateralFactor(ICToken cToken, address account) public view returns (uint256) {
    // we use tx.origin here in case this is called during the flashloan callback
    // since the vault has a check that msg.sender == tx.origin this is safe
    bool vip = comptroller.getIsAccountVip(account);
    (, uint256 collateralFactor,, uint256 collateralFactorVip,,,,) = comptroller.markets(address(cToken));
    return vip ? collateralFactorVip : collateralFactor;
  }

  function getLiquidationThreshold(ICToken cToken) public view returns (uint256) {
    bool vip = comptroller.getIsAccountVip(tx.origin);
    (,, uint256 liqThreshold, uint256 liqThresholdVip,,,,) = comptroller.markets(address(cToken));
    return vip ? liqThresholdVip : liqThreshold;
  }

  // 18 decimals: 1e18/result gives multiplier: (e.g. 10)
  function maxLeverageMultiplier(ICToken cToken, address account) public view returns (uint256) {
    uint256 totalValueThreshold = 1e18;
    uint256 maxValue = 1e36;
    uint256 collateralFactor = getCollateralFactor(cToken, account);
    uint256 totalValueDividend = totalValueThreshold.sub(collateralFactor);
    return maxValue.div(totalValueDividend);
  }

  function getHypotheticalLiquidity(
    ICToken market,
    address account,
    uint redeemAmount,
    uint borrowAmount
  ) public view returns (uint liquidity) {
    (,liquidity,) = comptroller.getHypotheticalAccountLiquidity(account, address(market), redeemAmount, borrowAmount, false);
  }

  function getLiquidity(address account) public view returns (uint) {
    // do not handle error because new users will revert
    (, uint liquidity, uint shortfall) = comptroller.getHypotheticalAccountLiquidity(account, address(0), 0, 0, false);
    require(shortfall == 0, "Error: shortfall detected");
    return liquidity;

  }

  function getMaxLeverageUSD(
    ICToken mintMarket,
    address account
  ) public view returns (uint) {
    uint liquidity = getLiquidity(account);
    return liquidity.mul(maxLeverageMultiplier(mintMarket, account)).div(1e18);
  }

  // returns max number of tokens supplyable from looping a given market
  function getMaxLeverageTokens(
    ICToken mintMarket,
    address account
  ) public view returns(uint) {
    uint leverageUSD = getMaxLeverageUSD(mintMarket, account);
    uint tokensPerUSD = PriceHelper.getTokensPerUSD(mintMarket.underlying());
    return tokensPerUSD.mul(leverageUSD).div(1e18);
  }

  function approveMarket(ICToken market, uint amount) internal returns (bool) {
    if(market.underlying() == GLPHelper.fsGLP) {
      return GLPHelper.stakedGlp.approve(address(market), amount);
    }
    return market.underlying().approve(address(market), amount);
  }
}

// SPDX-License-Identifier: No License
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {IAggregator} from "../interfaces/IAggregator.sol";
import {ICToken} from '../interfaces/ICToken.sol';
import {Addresses} from '../libraries/Addresses.sol';

/*
* @notice Security contract: Without this contract someone can arbitrarily execute deposits or withdraws for another account
* This is because Balancer takes an address to flash loan to as a parameter
* Prevents someone from flashloaning this contract with their own parameters
*/
contract PendingExecutor {
  IAggregator public immutable sequencerUptimeFeed = IAggregator(Addresses.sequencerFeed);
  uint256 private constant GRACE_PERIOD_TIME = 3600;
  // Check the sequencer status and return the latest price
  function validateSequencer() public view {
    // prettier-ignore
    (
      /*uint80 roundID*/,
      int256 answer,
      uint256 startedAt,
      /*uint256 updatedAt*/,
      /*uint80 answeredInRound*/
    ) = sequencerUptimeFeed.latestRoundData();

    // Answer == 0: Sequencer is up
    // Answer == 1: Sequencer is down
    bool isSequencerUp = answer == 0;
    uint256 timeSinceUp = block.timestamp - startedAt;
    require(isSequencerUp, 'Sequencer is down');
    require(timeSinceUp > GRACE_PERIOD_TIME, 'Grace period not over');
  }
  struct WithdrawParams {
    address account;
    ICToken redeemMarket;
    uint redeemAmount;
    ICToken[] repayMarkets;
    uint[] repayAmounts;
    uint24 maxSlippage;
  }
  mapping(address => WithdrawParams) private pendingWithdraws;
  mapping(address => bool) private hasPendingWithdraw;


  struct DepositParams {
    address account;
    IERC20 depositToken;
    uint256 depositAmount;
    uint leverageProportion;
    ICToken[] borrowMarkets;
    uint[] borrowProportions;
    ICToken destMarket;
    uint24 maxSlippage;
  }

  mapping(address => DepositParams) private pendingDeposits;
  mapping(address => bool) private hasPendingDeposit;

  function getPendingWithdraw(
    address account
  ) internal view returns (WithdrawParams memory) {
    require(hasPendingWithdraw[account], 'No Withdraw registered by account');
    return pendingWithdraws[account];
  }

  function getPendingDeposit(
    address account
  ) internal view returns (DepositParams memory) {
    require(hasPendingDeposit[account], 'No Withdraw registered by account');
    return pendingDeposits[account];
  }

  function setPendingWithdraw(
    address account,
    WithdrawParams memory data
  ) internal {
    pendingWithdraws[account] = data;
    hasPendingWithdraw[account] = true;
  }

  function setPendingDeposit(
    address account,
    DepositParams memory data
  ) internal {
    pendingDeposits[account] = data;
    hasPendingDeposit[account] = true;
  }

  function removePendingWithdraw(
    address account
  ) internal {
    delete pendingWithdraws[account];
    hasPendingWithdraw[account] = false;
  }

  function removePendingDeposit(
    address account
  ) internal {
    delete pendingDeposits[account];
    hasPendingDeposit[account] = false;
  }
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {Ownable} from "oz/access/Ownable.sol";
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {TokenSwap} from "src/libraries/TokenSwap.sol";

contract SwapProtector is Ownable {
  mapping(bytes => uint24) private pairFees;

  function getPairKey(IERC20 token0, IERC20 token1) public pure returns (bytes memory) {
    return (token0 < token1)
      ? abi.encode(token0, token1)
      : abi.encode(token1, token0);
  }

  function setPairFee(IERC20 token0, IERC20 token1, uint24 fee) public onlyOwner {
    bytes memory key = getPairKey(token0, token1);
    pairFees[key] = fee;
  }

  function getPairFee(IERC20 token0, IERC20 token1) public view returns (uint24) {
    uint24 fee = pairFees[getPairKey(token0, token1)];
    // default to 500 if it hasnt been set
    return (fee > 0) ? fee : 500;
  }

  function swap(IERC20 token0, IERC20 token1, uint amountIn, uint24 maxSlippage) internal returns (uint) {
    uint24 fee = getPairFee(token0, token1);
    return TokenSwap.swap(token0, token1, amountIn, fee, maxSlippage);
  }

  // withdraw any tokens that are sent to this contract or somehow get stuck
  function withdrawToken(IERC20 token, uint amount) external onlyOwner {
    token.transfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: No License
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGlpManager {
  function glp() external view returns (address);
  function usdg() external view returns (address);
  function vault() external view returns (address);
  function cooldownDuration() external returns (uint256);
  function getAumInUsdg(bool maximise) external view returns (uint256);
  function lastAddedAt(address _account) external returns (uint256);
  function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
  function addLiquidityForAccount(
    address _fundingAccount,
    address _account,
    address _token,
    uint256 _amount,
    uint256 _minUsdg,
    uint256 _minGlp
  ) external returns (uint256);
  function removeLiquidity(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
    external
    returns (uint256);
  function removeLiquidityForAccount(
    address _account,
    address _tokenOut,
    uint256 _glpAmount,
    uint256 _minOut,
    address _receiver
  ) external returns (uint256);
  function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external;
  function setCooldownDuration(uint256 _cooldownDuration) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardRouterV2 {
  function stakedGmxTracker() external view returns (address);
  function bonusGmxTracker() external view returns (address);
  function feeGmxTracker() external view returns (address);
  function stakedGlpTracker() external view returns (address);
  function feeGlpTracker() external view returns (address);
  function glpManager() external view returns (address);
  function handleRewards(
    bool _shouldClaimGmx,
    bool _shouldStakeGmx,
    bool _shouldClaimEsGmx,
    bool _shouldStakeEsGmx,
    bool _shouldStakeMultiplierPoints,
    bool _shouldClaimWeth,
    bool _shouldConvertWethToEth
  ) external;
  function signalTransfer(address _receiver) external;
  function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
    external
    returns (uint256);
  function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
  function stakeGmx(uint256 amount) external;
  function unstakeGmx(uint256 amount) external;
  function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
    external
    returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakedGlp {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function glp() external view returns (address);
  function glpManager() external view returns (address);
  function stakedGlpTracker() external view returns (address);
  function feeGlpTracker() external view returns (address);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IGlpManager} from "./IGlpManager.sol";

interface IRewardTracker {
  function balanceOf(address _account) external view returns (uint256);
  function approve(address _spender, uint256 _amount) external returns (bool);
  function depositBalances(address _account, address _depositToken) external view returns (uint256);
  function stakedAmounts(address _account) external view returns (uint256);
  function updateRewards() external;
  function stake(address _depositToken, uint256 _amount) external;
  function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
  function unstake(address _depositToken, uint256 _amount) external;
  function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
  function tokensPerInterval() external view returns (uint256);
  function claim(address _receiver) external returns (uint256);
  function claimForAccount(address _account, address _receiver) external returns (uint256);
  function claimable(address _account) external view returns (uint256);
  function averageStakedAmounts(address _account) external view returns (uint256);
  function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

interface IComptroller {
  function isComptroller() external view returns (bool);
  function oracle() external view returns (address);
  function markets(address)
    external
    view
    returns (
      bool isListed,
      uint256 collateralFactorMantissa,
      uint256 liquidationThresholdMantissa,
      uint256 collateralFactorMantissaVip,
      uint256 liquidationThresholdMantissaVip,
      bool isComped,
      bool isPrivate,
      bool onlyWhitelistedBorrow
    );
  function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
  function exitMarket(address cToken) external returns (uint256);
  function addToMarketExternal(address cToken, address borrower) external;
  function mintAllowed(address cToken, address minter, uint256 mintAmount) external returns (uint256);
  function mintVerify(address cToken, address minter, uint256 mintAmount, uint256 mintTokens) external;
  function redeemAllowed(address cToken, address redeemer, uint256 redeemTokens) external returns (uint256);
  function redeemVerify(address cToken, address redeemer, uint256 redeemAmount, uint256 redeemTokens) external;
  function borrowAllowed(address cToken, address borrower, uint256 borrowAmount) external returns (uint256);
  function borrowVerify(address cToken, address borrower, uint256 borrowAmount) external;
  function getIsAccountVip(address account) external view returns (bool);
  function getAllMarkets() external view returns (address[] memory);
  function getAccountLiquidity(address account, bool isLiquidationCheck)
    external
    view
    returns (uint256, uint256, uint256);
  function getHypotheticalAccountLiquidity(
    address account,
    address cTokenModify,
    uint256 redeemTokens,
    uint256 borrowAmount,
    bool isLiquidationCheck
  ) external view returns (uint256, uint256, uint256);
  function _setPriceOracle(address oracle_) external;
  function _supportMarket(address delegator, bool isComped, bool isPrivate, bool onlyWhitelistedBorrow) external;
  function _setFactorsAndThresholds(
    address delegator,
    uint256 collateralFactor,
    uint256 collateralVIP,
    uint256 threshold,
    uint256 thresholdVIP
  ) external;

  /// @notice Indicator that this is a Comptroller contract (for inspection)
  function repayBorrowAllowed(address cToken, address payer, address borrower, uint256 repayAmount)
    external
    returns (uint256);

  function repayBorrowVerify(
    address cToken,
    address payer,
    address borrower,
    uint256 repayAmount,
    uint256 borrowerIndex
  ) external;

  function liquidateBorrowAllowed(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount
  ) external returns (uint256);
  function liquidateBorrowVerify(
    address cTokenBorrowed,
    address cTokenCollateral,
    address liquidator,
    address borrower,
    uint256 repayAmount,
    uint256 seizeTokens
  ) external;

  function seizeAllowed(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external returns (uint256);

  function seizeVerify(
    address cTokenCollateral,
    address cTokenBorrowed,
    address liquidator,
    address borrower,
    uint256 seizeTokens
  ) external;
  function transferAllowed(address cToken, address src, address dst, uint256 transferTokens) external returns (uint256);

  function transferVerify(address cToken, address src, address dst, uint256 transferTokens) external;

  /**
   * Liquidity/Liquidation Calculations **
   */
  function liquidateCalculateSeizeTokens(address cTokenBorrowed, address cTokenCollateral, uint256 repayAmount)
    external
    view
    returns (uint256, uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Compound's InterestRateModel Interface
 * @author Compound
 */
interface InterestRateModel {
  /// @notice Indicator that this is an InterestRateModel contract (for inspection)
  /**
   * @notice Calculates the current borrow interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @return The borrow rate per block (as a percentage, and scaled by 1e18)
   */
  function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) external view returns (uint256);

  /**
   * @notice Calculates the current supply interest rate per block
   * @param cash The total amount of cash the market has
   * @param borrows The total amount of borrows the market has outstanding
   * @param reserves The total amount of reserves the market has
   * @param reserveFactorMantissa The current reserve factor the market has
   * @return The supply rate per block (as a percentage, and scaled by 1e18)
   */
  function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactorMantissa)
    external
    view
    returns (uint256);
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
 /*
  * @notice Address constants that can be relied upon throughout this repo
  * Any change to where these are located would imply changes made which will require a new deployment anyways
  */
library Addresses {
  // protocol address
    address public constant unitroller = 0xeed247Ba513A8D6f78BE9318399f5eD1a4808F8e;
      // GMX Addresses (when changes to these occur new logic for handling has been historically required)
    address public constant glpManager = 0x3963FfC9dff443c2A94f21b129D429891E32ec18;
    address public constant stakedGlp = 0x2F546AD4eDD93B956C8999Be404cdCAFde3E89AE;
    address public constant glpRouter = 0xB95DB5B167D75e6d04227CfFFA61069348d271F5;
    address public constant fsGLP = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address public constant glpVault = 0x489ee077994B6658eAfA855C308275EAd8097C4A;

    address public constant sequencerFeed = 0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
  }

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import {ICToken} from "../compound/ICToken.sol";
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {IChainlinkPriceOracle} from "./IChainlinkPriceOracle.sol";

interface ITenderPriceOracle {
  function getOracleDecimals(IERC20 token) external view returns (uint256);
  function getUSDPrice(IERC20 token) external view returns (uint256);

  function getUnderlyingDecimals(ICToken ctoken) external view returns (uint256);
  function getUnderlyingPrice(ICToken ctoken) external view returns (uint256);

  function setOracle(IERC20 token, IChainlinkPriceOracle oracle) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGmxVault {
  function isInitialized() external view returns (bool);
  function isSwapEnabled() external view returns (bool);
  function isLeverageEnabled() external view returns (bool);

  function setVaultUtils(address _vaultUtils) external;
  function setError(uint256 _errorCode, string calldata _error) external;

  function router() external view returns (address);
  function usdg() external view returns (address);
  function gov() external view returns (address);

  function whitelistedTokenCount() external view returns (uint256);
  function maxLeverage() external view returns (uint256);

  function minProfitTime() external view returns (uint256);
  function hasDynamicFees() external view returns (bool);
  function fundingInterval() external view returns (uint256);
  function totalTokenWeights() external view returns (uint256);
  function getTargetUsdgAmount(address _token) external view returns (uint256);

  function inManagerMode() external view returns (bool);
  function inPrivateLiquidationMode() external view returns (bool);

  function maxGasPrice() external view returns (uint256);

  function approvedRouters(address _account, address _router) external view returns (bool);
  function isLiquidator(address _account) external view returns (bool);
  function isManager(address _account) external view returns (bool);

  function minProfitBasisPoints(address _token) external view returns (uint256);
  function tokenBalances(address _token) external view returns (uint256);
  function lastFundingTimes(address _token) external view returns (uint256);

  function setMaxLeverage(uint256 _maxLeverage) external;
  function setInManagerMode(bool _inManagerMode) external;
  function setManager(address _manager, bool _isManager) external;
  function setIsSwapEnabled(bool _isSwapEnabled) external;
  function setIsLeverageEnabled(bool _isLeverageEnabled) external;
  function setMaxGasPrice(uint256 _maxGasPrice) external;
  function setUsdgAmount(address _token, uint256 _amount) external;
  function setBufferAmount(address _token, uint256 _amount) external;
  function setMaxGlobalShortSize(address _token, uint256 _amount) external;
  function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
  function setLiquidator(address _liquidator, bool _isActive) external;

  function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor)
    external;

  function setFees(
    uint256 _taxBasisPoints,
    uint256 _stableTaxBasisPoints,
    uint256 _mintBurnFeeBasisPoints,
    uint256 _swapFeeBasisPoints,
    uint256 _stableSwapFeeBasisPoints,
    uint256 _marginFeeBasisPoints,
    uint256 _liquidationFeeUsd,
    uint256 _minProfitTime,
    bool _hasDynamicFees
  ) external;

  function setTokenConfig(
    address _token,
    uint256 _tokenDecimals,
    uint256 _redemptionBps,
    uint256 _minProfitBps,
    uint256 _maxUsdgAmount,
    bool _isStable,
    bool _isShortable
  ) external;

  function setPriceFeed(address _priceFeed) external;
  function withdrawFees(address _token, address _receiver) external returns (uint256);

  function directPoolDeposit(address _token) external;
  function buyUSDG(address _token, address _receiver) external returns (uint256);
  function sellUSDG(address _token, address _receiver) external returns (uint256);
  function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
  function increasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;
  function decreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver
  ) external returns (uint256);
  function validateLiquidation(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong,
    bool _raise
  ) external view returns (uint256, uint256);
  function liquidatePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong,
    address _feeReceiver
  ) external;
  function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

  function priceFeed() external view returns (address);
  function fundingRateFactor() external view returns (uint256);
  function stableFundingRateFactor() external view returns (uint256);
  function cumulativeFundingRates(address _token) external view returns (uint256);
  function getNextFundingRate(address _token) external view returns (uint256);
  function getFeeBasisPoints(
    address _token,
    uint256 _usdgDelta,
    uint256 _feeBasisPoints,
    uint256 _taxBasisPoints,
    bool _increment
  ) external view returns (uint256);

  function liquidationFeeUsd() external view returns (uint256);
  function taxBasisPoints() external view returns (uint256);
  function stableTaxBasisPoints() external view returns (uint256);
  function mintBurnFeeBasisPoints() external view returns (uint256);
  function swapFeeBasisPoints() external view returns (uint256);
  function stableSwapFeeBasisPoints() external view returns (uint256);
  function marginFeeBasisPoints() external view returns (uint256);

  function allWhitelistedTokensLength() external view returns (uint256);
  function allWhitelistedTokens(uint256) external view returns (address);
  function whitelistedTokens(address _token) external view returns (bool);
  function stableTokens(address _token) external view returns (bool);
  function shortableTokens(address _token) external view returns (bool);
  function feeReserves(address _token) external view returns (uint256);
  function globalShortSizes(address _token) external view returns (uint256);
  function globalShortAveragePrices(address _token) external view returns (uint256);
  function maxGlobalShortSizes(address _token) external view returns (uint256);
  function tokenDecimals(address _token) external view returns (uint256);
  function tokenWeights(address _token) external view returns (uint256);
  function guaranteedUsd(address _token) external view returns (uint256);
  function poolAmounts(address _token) external view returns (uint256);
  function bufferAmounts(address _token) external view returns (uint256);
  function reservedAmounts(address _token) external view returns (uint256);
  function usdgAmounts(address _token) external view returns (uint256);
  function maxUsdgAmounts(address _token) external view returns (uint256);
  function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
  function getMaxPrice(address _token) external view returns (uint256);
  function getMinPrice(address _token) external view returns (uint256);

  function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime)
    external
    view
    returns (bool, uint256);
  function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong)
    external
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}

interface IAggregator {
  function latestRoundData() external view returns (
    uint80 roundID,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  );
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: No License
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IV3SwapRouter} from "tender/external/uniswap/IV3SwapRouter.sol";
import {IRewardRouterV2} from "tender/external/gmx/IRewardRouterV2.sol";
import {IRewardTracker} from "tender/external/gmx/IRewardTracker.sol";
import {IGlpManager} from "tender/external/gmx/IGlpManager.sol";
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";
import {GLPHelper} from './GLPHelper.sol';
import {PriceHelper} from './PriceHelper.sol';
import {Addresses} from './Addresses.sol';

library TokenSwap {
  using GLPHelper for IERC20;
  using PriceHelper for IERC20;
  IV3SwapRouter public constant swapRouter = IV3SwapRouter(Addresses.swapRouter);

  function getAmountOutMin(
    // 10000*100: 500 is .05% fee
    uint amountIn,
    uint24 fee,
    uint24 maxSlippage
  ) public pure returns (uint) {
    uint totalBps = 1000000;
    uint afterFee = amountIn * (totalBps - fee) / totalBps;
    return afterFee*(totalBps - maxSlippage)/totalBps;
  }

  function swap(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint amount,
    uint24 fee,
    uint24 maxSlippage
  ) internal returns (uint amountOut) {
    require(maxSlippage <= 1000000, "maxSlippage cannot be greater than 100%");
    uint amountOutBase = PriceHelper.getTokensForNumTokens(tokenIn, amount, tokenOut);
    uint minOut = getAmountOutMin(amountOutBase, fee, maxSlippage);

    if(tokenIn == GLPHelper.fsGLP) {
      amountOut = GLPHelper.unstake(tokenOut, amount, minOut);
    }
    else if(tokenOut == GLPHelper.fsGLP) {
      amountOut = GLPHelper.mintAndStake(tokenIn, amount, 0, minOut);
    }
    else if(tokenIn != tokenOut) {
      require(fee >= 100, 'fee cannot be less than .01%');
      amountOut = swapTokens(
        tokenIn,
        tokenOut,
        amount,
        fee,
        minOut
      );
    }
    else {
      amountOut = amount;
    }
    return amountOut;
  }

  function swapTokens(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint amount,
    uint24 fee,
    uint amountOutMin
  ) internal returns (uint256 amountOut) {
    tokenIn.approve(address(swapRouter), amount);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: address(tokenIn),
      tokenOut: address(tokenOut),
      fee: fee,
      recipient: address(this),
      amountIn: amount,
      amountOutMinimum: amountOutMin,
      sqrtPriceLimitX96: 0
    });
    amountOut = swapRouter.exactInputSingle(params);
  }
}

// SPDX-License-Identifier: No License
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: No License
pragma solidity >= 0.8.10;

import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";

interface ICToken is IERC20 {
  // CERC20 functions
  function underlying() external view returns (IERC20);
  function mintForAccount(address account, uint256 mintAmount) external returns (uint256);
  function mint(uint256 mintAmount) external returns (uint256);
  function redeem(uint256 redeemTokens) external returns (uint256);
  function redeemForAccount(address account, uint256 redeemTokens) external returns (uint256);
  function redeemUnderlyingForAccount(address account, uint256 redeemAmount) external returns (uint256);

  function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
  function redeemUnderlyingForUser(uint256 redeemAmount, address user) external returns (uint256);
  function borrow(uint256 borrowAmount) external returns (uint256);
  function borrowForAccount(address account, uint256 borrowAmount) external returns (uint256);
  function repayForAccount(address borrower, uint256 repayAmount) external returns (uint256);
  function repayBorrow(uint256 repayAmount) external returns (uint256);
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);
  function liquidateBorrow(address borrower, uint256 repayAmount, address cTokenCollateral) external returns (uint256);
  function depositNFT(address _NFTAddress, uint256 _TokenID) external;
  function withdrawNFT(address _NFTAddress, uint256 _TokenID) external;
  function compound() external returns (uint256);

  // CToken functions
  function glpManager() external view returns (address);
  function gmxToken() external view returns (IERC20);
  function glpRewardRouter() external view returns (address);
  function stakedGLP() external view returns (address);
  function sbfGMX() external view returns (address);
  function stakedGmxTracker() external view returns (address);

  function _notEntered() external view returns (bool);

  function isGLP() external view returns (bool);
  function autocompound() external view returns (bool);
  function glpBlockDelta() external view returns (uint256);
  function lastGlpDepositAmount() external view returns (uint256);

  function comptroller() external view returns (address);
  function interestRateModel() external view returns (address);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function admin() external view returns (address);
  function pendingAdmin() external view returns (address);
  function initialExchangeRateMantissa() external view returns (uint256);
  function reserveFactorMantissa() external view returns (uint256);
  function accrualBlockNumber() external view returns (uint256);
  function borrowIndex() external view returns (uint256);
  function totalBorrows() external view returns (uint256);
  function totalReserves() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function withdrawFee() external view returns (uint256);
  function performanceFee() external view returns (uint256);
  function exchangeRateBefore() external view returns (uint256);
  function blocksBetweenRateChange() external view returns (uint256);
  function prevExchangeRate() external view returns (uint256);
  function depositsDuringLastInterval() external view returns (uint256);
  function isCToken() external view returns (bool);

  function performanceFeeMAX() external view returns (uint256);
  function withdrawFeeMAX() external view returns (uint256);
  function autoCompoundBlockThreshold() external view returns (uint256);

  event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);
  event Mint(address minter, uint256 mintAmount, uint256 mintTokens);
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);
  event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);
  event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);
  event LiquidateBorrow(
    address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens
  );
  event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
  event NewAdmin(address oldAdmin, address newAdmin);
  event NewComptroller(address oldComptroller, address newComptroller);
  event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);
  event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);
  event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);
  event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

  function transfer(address dst, uint256 amount) external returns (bool);
  function transferFrom(address src, address dst, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address owner) external view returns (uint256);
  function balanceOfUnderlying(address owner) external returns (uint256);
  function getAccountSnapshot(address account) external view returns (uint256, uint256, uint256, uint256);
  function borrowRatePerBlock() external view returns (uint256);
  function supplyRatePerBlock() external view returns (uint256);
  function totalBorrowsCurrent() external returns (uint256);
  function borrowBalanceCurrent(address account) external returns (uint256);
  function borrowBalanceStored(address account) external view returns (uint256);
  function exchangeRateCurrent() external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function getCash() external view returns (uint256);
  function accrueInterest() external returns (uint256);
  function seize(address liquidator, address borrower, uint256 seizeTokens) external returns (uint256);

  /**
   * Admin Functions **
   */
  function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);
  function _acceptAdmin() external returns (uint256);
  function _setComptroller(address newComptroller) external returns (uint256);
  function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);
  function _reduceReserves(uint256 reduceAmount) external returns (uint256);
  function _setInterestRateModel(address newInterestRateModel) external returns (uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.6.2;

interface IChainlinkPriceOracle {
  function decimals() external view returns (uint8);
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: No License
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: No License

pragma solidity >=0.8.10;

interface IV3SwapRouter {
  function uniswapV3SwapCallback(int amount0, int amount1, bytes calldata data) external;

  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}