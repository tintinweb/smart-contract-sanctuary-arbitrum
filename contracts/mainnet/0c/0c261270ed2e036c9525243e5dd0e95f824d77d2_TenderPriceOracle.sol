// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import {SafeMath} from "oz/utils/math/SafeMath.sol";
import {Ownable} from "oz/access/Ownable.sol";
import {ICToken} from "../external/compound/ICToken.sol";
import {IChainlinkPriceOracle} from "../external/oracle/IChainlinkPriceOracle.sol";
import {ITenderPriceOracle} from "../external/oracle/ITenderPriceOracle.sol";
import {IERC20Metadata as IERC20} from "oz/interfaces/IERC20Metadata.sol";

contract TenderPriceOracle is ITenderPriceOracle, Ownable {
  using SafeMath for uint256;

  ICToken public constant tETH = ICToken(0x0706905b2b21574DEFcF00B5fc48068995FCdCdf);
  IERC20 public constant WETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

  mapping(IERC20 => IChainlinkPriceOracle) public Oracles;

  constructor() {
    Oracles[IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9)] =
      IChainlinkPriceOracle(0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7); // USDT
    Oracles[IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8)] =
      IChainlinkPriceOracle(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3); // USDC
    Oracles[IERC20(0xf97f4df75117a78c1A5a0DBb814Af92458539FB4)] =
      IChainlinkPriceOracle(0x86E53CF1B870786351Da77A57575e79CB55812CB); // LINK
    Oracles[IERC20(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F)] =
      IChainlinkPriceOracle(0x0809E3d38d1B4214958faf06D8b1B1a2b73f2ab8); // FRAX
    Oracles[IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f)] =
      IChainlinkPriceOracle(0x6ce185860a4963106506C203335A2910413708e9); // WBTC
    Oracles[IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1)] =
      IChainlinkPriceOracle(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612); // WETH
    Oracles[IERC20(0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0)] =
      IChainlinkPriceOracle(0x9C917083fDb403ab5ADbEC26Ee294f6EcAda2720); // UNI
    Oracles[IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1)] =
      IChainlinkPriceOracle(0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB); // DAI
    Oracles[IERC20(0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a)] =
      IChainlinkPriceOracle(0xDB98056FecFff59D032aB628337A4887110df3dB); // GMX
    Oracles[IERC20(0x539bdE0d7Dbd336b79148AA742883198BBF60342)] =
      IChainlinkPriceOracle(0x47E55cCec6582838E173f252D08Afd8116c2202d); // MAGIC
    Oracles[IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548)] =
      IChainlinkPriceOracle(0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6); // ARB
  }

  function getOracle(IERC20 token) public view returns (IChainlinkPriceOracle) {
    IChainlinkPriceOracle oracle = Oracles[token];
    require(address(oracle) != address(0), "Oracle not found for address");
    return oracle;
  }

  function setOracle(IERC20 underlying, IChainlinkPriceOracle oracle) public onlyOwner {
    Oracles[underlying] = oracle;
  }

  function getUnderlying(ICToken ctoken) public view returns (IERC20) {
    return (ctoken != tETH) ? ctoken.underlying() : WETH;
  }

  function getUnderlyingDecimals(ICToken ctoken) public view returns (uint256) {
    return IERC20(getUnderlying(ctoken)).decimals();
  }

  function getUnderlyingPrice(ICToken ctoken) public view returns (uint256) {
    return _getUnderlyingPrice(ctoken);
  }

  function _getUnderlyingPrice(ICToken ctoken) internal view returns (uint256) {
    IChainlinkPriceOracle oracle = getOracle(getUnderlying(ctoken));
    (, int256 answer,,,) = oracle.latestRoundData();
    require(answer > 0, "Oracle error");
    uint256 price = uint256(answer);
    // scale to USD value with 18 decimals
    uint256 totalDecimals = 36 - oracle.decimals();
    return price.mul(10 ** (totalDecimals - getUnderlyingDecimals(ctoken)));
  }

  function getOracleDecimals(IERC20 token) public view returns (uint256) {
    return getOracle(token).decimals();
  }

  function getUSDPrice(IERC20 token) public view returns (uint256) {
    (, int256 answer,,,) = getOracle(token).latestRoundData();
    require(answer > 0, "Oracle error");
    return uint256(answer);
  }
  // this will not be correct for compound but is used by vault for borrow calculations
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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