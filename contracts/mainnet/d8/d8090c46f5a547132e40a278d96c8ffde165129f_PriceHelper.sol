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