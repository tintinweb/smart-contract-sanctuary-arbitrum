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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFlashLoanRecipient {
  /**
   * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
   *
   * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
   * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
   * Vault, or else the entire flash loan will revert.
   *
   * `userData` is the same value passed in the `IVault.flashLoan` call.
   */
  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPloopy {
  struct UserData {
    address user;
    uint256 tokenAmount;
    IERC20 borrowedToken;
    uint256 borrowedAmount;
    IERC20 tokenToLoop; 
  }

  error UNAUTHORIZED(string);
  error INVALID_LEVERAGE();
  error INVALID_APPROVAL();
  error FAILED(string);
}

interface IGlpDepositor {
  function deposit(uint256 _amount) external;

  function redeem(uint256 _amount) external;

  function donate(uint256 _assets) external;
}

interface IRewardRouterV2 {
  function mintAndStakeGlp(
    address _token,
    uint256 _amount,
    uint256 _minUsdg,
    uint256 _minGlp
  ) external returns (uint256);
}

interface ICERC20Update {
  function borrowBehalf(uint256 borrowAmount, address borrowee) external returns (uint256);
}

interface ICERC20 is IERC20, ICERC20Update {
  // CToken
  /**
   * @notice Get the underlying balance of the `owner`
   * @dev This also accrues interest in a transaction
   * @param owner The address of the account to query
   * @return The amount of underlying owned by `owner`
   */
  function balanceOfUnderlying(address owner) external returns (uint256);

  /**
   * @notice Returns the current per-block borrow interest rate for this cToken
   * @return The borrow interest rate per block, scaled by 1e18
   */
  function borrowRatePerBlock() external view returns (uint256);

  /**
   * @notice Returns the current per-block supply interest rate for this cToken
   * @return The supply interest rate per block, scaled by 1e18
   */
  function supplyRatePerBlock() external view returns (uint256);

  /**
   * @notice Accrue interest then return the up-to-date exchange rate
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateCurrent() external returns (uint256);

  // Cerc20
  function mint(uint256 mintAmount) external returns (uint256);
}

interface ERC20 {
  // weth stuff
  function withdraw(uint256 amount) external returns (uint256);

  function deposit(uint256 payableAmount) external returns (uint256);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (uint256);
}


interface IPriceOracleProxyETH {
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.17;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IFlashLoanRecipient.sol';

interface IVault {
  /**
   * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
   * and then reverting unless the tokens plus a proportional protocol fee have been returned.
   *
   * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
   * for each token contract. `tokens` must be sorted in ascending order.
   *
   * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
   * `receiveFlashLoan` call.
   *
   * Emits `FlashLoan` events.
   */
  function flashLoan(
    IFlashLoanRecipient recipient,
    IERC20[] memory tokens,
    uint256[] memory amounts,
    bytes memory userData
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IFlashLoanRecipient.sol';
import './PloopyConstants.sol';

contract Ploopy is IPloopy, PloopyConstants, Ownable, IFlashLoanRecipient, ReentrancyGuard {
  // add mapping of token addresses to their decimal places
  mapping(IERC20 => uint8) public decimals;
  // add mapping to store the allowed tokens. Mapping provides faster access than array
  mapping(IERC20 => bool) public allowedTokens;
  // add mapping to store lToken contracts
  mapping(IERC20 => ICERC20) private lTokenMapping;

  constructor() {
    // initialize decimals for each token
    decimals[USDC] = 6;
    decimals[USDT] = 6;
    decimals[WBTC] = 8;
    decimals[DAI] = 18;
    decimals[FRAX] = 18;
    decimals[ETH] = 18;
    decimals[ARB] = 18;
    decimals[PLVGLP] = 18;

    // set the allowed tokens in the constructor
    // we can add/remove these with owner functions later
    allowedTokens[USDC] = true;
    allowedTokens[USDT] = true;
    allowedTokens[WBTC] = true;
    allowedTokens[DAI] = true;
    allowedTokens[FRAX] = true;
    allowedTokens[ETH] = true;
    allowedTokens[ARB] = true;
    allowedTokens[PLVGLP] = true;

    // map tokens to lTokens
    lTokenMapping[USDC] = lUSDC;
    lTokenMapping[USDT] = lUSDT;
    lTokenMapping[WBTC] = lWBTC;
    lTokenMapping[DAI] = lDAI;
    lTokenMapping[FRAX] = lFRAX;
    lTokenMapping[ETH] = lETH;
    lTokenMapping[ARB] = lARB;
    lTokenMapping[PLVGLP] = lPLVGLP;

    // approve glp contracts to spend USDC for minting GLP
    USDC.approve(address(REWARD_ROUTER_V2), type(uint256).max);
    USDC.approve(address(GLP), type(uint256).max);
    USDC.approve(address(GLP_MANAGER), type(uint256).max);
    // approve GlpDepositor to spend GLP for minting plvGLP
    sGLP.approve(address(GLP_DEPOSITOR), type(uint256).max);
    GLP.approve(address(GLP_DEPOSITOR), type(uint256).max);
    sGLP.approve(address(REWARD_ROUTER_V2), type(uint256).max);
    GLP.approve(address(REWARD_ROUTER_V2), type(uint256).max);
    // approve balancer vault
    USDC.approve(address(VAULT), type(uint256).max);
    ETH.approve(address(VAULT), type(uint256).max);
    // approve lTokens to be minted using underlying
    PLVGLP.approve(address(lPLVGLP), type(uint256).max);
    USDC.approve(address(lUSDC), type(uint256).max);
    ETH.approve(address(lETH), type(uint256).max);
  }

  // declare events
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Loan(uint256 value);
  event BalanceOf(uint256 balanceAmount, uint256 loanAmount);
  event Allowance(uint256 allowance, uint256 loanAmount);
  event UserDataEvent(address indexed from, uint256 tokenAmount, address borrowedToken, uint256 borrowedAmount, address tokenToLoop);
  event plvGLPBalance(uint256 balanceAmount);
  event lTokenBalance(uint256 balanceAmount);

  function addToken(IERC20 token) external onlyOwner {
      require(!allowedTokens[token], "token already allowed");
      allowedTokens[token] = true;
  }

  function removeToken(IERC20 token) external onlyOwner {
      require(allowedTokens[token], "token not allowed");
      allowedTokens[token] = false;
  }

  // allows users to loop to a desired leverage, within our pre-set ranges
  function loop(IERC20 _token, uint256 _amount, uint16 _leverage, uint16 _useWalletBalance) external {
    require(allowedTokens[_token], "token not allowed to loop");
    require(tx.origin == msg.sender, "not an EOA");
    require(_amount > 0, "amount must be greater than 0");
    require(_leverage >= DIVISOR && _leverage <= MAX_LEVERAGE, "invalid leverage, range must be between DIVISOR and MAX_LEVERAGE values");

    // if the user wants us to mint using their existing wallet balance (indiciated with 1), then do so.
    // otherwise, read their existing balance and flash loan to increase their position
    if (_useWalletBalance == 1) {
      // transfer tokens to this contract so we can mint in 1 go.
      _token.transferFrom(msg.sender, address(this), _amount);
      emit Transfer(msg.sender, address(this), _amount);
    }
    
    uint256 loanAmount;
    IERC20 _tokenToBorrow;

    if (_token == PLVGLP) {
      uint256 _tokenPriceInEth;
      uint256 _usdcPriceInEth;
      uint256 _computedAmount;

      // plvGLP borrows USDC to loop
      _tokenToBorrow = USDC;
      _tokenPriceInEth = PRICE_ORACLE.getUnderlyingPrice(address(lTokenMapping[_token]));
      _usdcPriceInEth = (PRICE_ORACLE.getUnderlyingPrice(address(lUSDC)) / 1e12);
      _computedAmount = (_amount * (_tokenPriceInEth / _usdcPriceInEth));

      loanAmount = getNotionalLoanAmountIn1e18(
        _computedAmount,
        _leverage
      );
    } else {
      // the rest of the contracts just borrow whatever token is supplied
      _tokenToBorrow = _token;
      loanAmount = getNotionalLoanAmountIn1e18(
        _amount, // we can just send over the exact amount, as we are either looping stables or eth
        _leverage
      );
    }

    if (_tokenToBorrow.balanceOf(address(BALANCER_VAULT)) < loanAmount) revert FAILED('balancer vault token balance < loan');
    emit Loan(loanAmount);
    emit BalanceOf(_tokenToBorrow.balanceOf(address(BALANCER_VAULT)), loanAmount);

    // check approval to spend USDC (for paying back flashloan).
    // possibly can omit to save gas as tx will fail with exceed allowance anyway.
    if (_tokenToBorrow.allowance(msg.sender, address(this)) < loanAmount) revert INVALID_APPROVAL();
    emit Allowance(_tokenToBorrow.allowance(msg.sender, address(this)), loanAmount);

    IERC20[] memory tokens = new IERC20[](1);
    tokens[0] = _tokenToBorrow;

    uint256[] memory loanAmounts = new uint256[](1);
    loanAmounts[0] = loanAmount;

    UserData memory userData = UserData({
      user: msg.sender,
      tokenAmount: _amount,
      borrowedToken: _tokenToBorrow,
      borrowedAmount: loanAmount,
      tokenToLoop: _token
    });
    emit UserDataEvent(msg.sender, _amount, address(_tokenToBorrow), loanAmount, address(_token));

    BALANCER_VAULT.flashLoan(IFlashLoanRecipient(this), tokens, loanAmounts, abi.encode(userData));
  }

  function receiveFlashLoan(
    IERC20[] memory tokens,
    uint256[] memory amounts,
    uint256[] memory feeAmounts,
    bytes memory userData
  ) external override nonReentrant {
    if (msg.sender != address(BALANCER_VAULT)) revert UNAUTHORIZED('balancer vault is not the sender');

    // additional checks?

    UserData memory data = abi.decode(userData, (UserData));
    if (data.borrowedAmount != amounts[0] || data.borrowedToken != tokens[0]) revert FAILED('borrowed amounts and/or borrowed tokens do not match initially set values');

    // sanity check: flashloan has no fees
    if (feeAmounts[0] > 0) revert FAILED('balancer fee > 0');

    // account for some plvGLP specific logic
    if (data.tokenToLoop == PLVGLP) {
      // mint GLP. approval needed.
      uint256 glpAmount = REWARD_ROUTER_V2.mintAndStakeGlp(
        address(data.borrowedToken),
        data.borrowedAmount,
        0,
        0
      );
      if (glpAmount == 0) revert FAILED('glp=0');

      // TODO whitelist this contract for plvGLP mint
      // mint plvGLP. approval needed.
      uint256 _oldPlvglpBal = PLVGLP.balanceOf(address(this));
      GLP_DEPOSITOR.deposit(glpAmount);

      // check new balances and confirm we properly minted
      uint256 _newPlvglpBal = PLVGLP.balanceOf(address(this));
      emit plvGLPBalance(_newPlvglpBal);
      require(_newPlvglpBal > _oldPlvglpBal, "glp deposit failed, new balance < old balance");
    }

    // mint our respective token by depositing it into Lodestar's respective lToken contract (approval needed)
    unchecked {
      // lets get eth instead of weth so we can properly mint
      if (data.tokenToLoop == ETH) {
        WETH.withdraw(data.borrowedAmount);
      }

      lTokenMapping[data.tokenToLoop].mint(data.tokenToLoop.balanceOf(address(this)));
      lTokenMapping[data.tokenToLoop].transfer(data.user, lTokenMapping[data.tokenToLoop].balanceOf(address(this)));

      uint256 _finalBal = lTokenMapping[data.tokenToLoop].balanceOf(address(this));
      emit lTokenBalance(_finalBal);
      require(_finalBal == 0, "lToken balance not 0 at the end of loop");
    }

    // call borrowBehalf to borrow tokens on behalf of user
    lTokenMapping[data.tokenToLoop].borrowBehalf(data.borrowedAmount, data.user);

    if (data.tokenToLoop == ETH) {
      WETH.deposit(data.borrowedAmount);
      // ensure we pay the loan back with weth
      WETH.transferFrom(data.user, msg.sender, data.borrowedAmount);
    } else {
      // repay loan, where msg.sender = vault
      data.tokenToLoop.transferFrom(data.user, msg.sender, data.borrowedAmount);
    }
  }

  function getNotionalLoanAmountIn1e18(
    uint256 _notionalTokenAmountIn1e18,
    uint16 _leverage
  ) private pure returns (uint256) {
    unchecked {
      return ((_leverage - DIVISOR) * _notionalTokenAmountIn1e18) / DIVISOR;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './interfaces/IVault.sol';
import { IPloopy, ICERC20, ERC20, IGlpDepositor, IRewardRouterV2, IPriceOracleProxyETH } from './interfaces/Interfaces.sol';

contract PloopyConstants {
  IVault internal constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  IERC20 internal constant USDC = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
  IERC20 internal constant ARB = IERC20(0x912CE59144191C1204E64559FE8253a0e49E6548);
  IERC20 internal constant WBTC = IERC20(0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f);
  IERC20 internal constant USDT = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
  IERC20 internal constant DAI = IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
  IERC20 internal constant FRAX = IERC20(0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F);
  IERC20 internal constant ETH = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  ERC20 internal constant WETH = ERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
  IERC20 internal constant PLVGLP = IERC20(0x5326E71Ff593Ecc2CF7AcaE5Fe57582D6e74CFF1);
  IERC20 internal constant GLP = IERC20(0x1aDDD80E6039594eE970E5872D247bf0414C8903);

  // GMX
  IERC20 internal constant VAULT = IERC20(0x489ee077994B6658eAfA855C308275EAd8097C4A);
  IERC20 internal constant GLP_MANAGER = IERC20(0x3963FfC9dff443c2A94f21b129D429891E32ec18);
  IERC20 internal constant sGLP = IERC20(0x2F546AD4eDD93B956C8999Be404cdCAFde3E89AE);
  IRewardRouterV2 internal constant REWARD_ROUTER_V2 =
    IRewardRouterV2(0xB95DB5B167D75e6d04227CfFFA61069348d271F5);

  // PLUTUS
  IGlpDepositor internal constant GLP_DEPOSITOR =
    IGlpDepositor(0xEAE85745232983CF117692a1CE2ECf3d19aDA683);

  // LODESTAR
  ICERC20 internal constant lUSDC = ICERC20(0xeF25968ECC2f13b6272a37312a409D429DEF70AB);

  // no testnet contracts, so putting main for now for future use
  ICERC20 internal constant lARB = ICERC20(0xe57390EB5F0dd76B545d7349845839Ad6A4faee8);
  ICERC20 internal constant lWBTC = ICERC20(0xd917d67f9dD5fA3A193f1e076C8c636867A3571b);
  ICERC20 internal constant lUSDT = ICERC20(0x2d5a5306E6Cd7133AE576eb5eDB2128D79D11A88);
  ICERC20 internal constant lDAI = ICERC20(0x8c7B5F470251fED433e38215a959eeEFc900d995);
  ICERC20 internal constant lFRAX = ICERC20(0xc9c043A7f80258d492121d2f34e829EB6517Eb17);
  ICERC20 internal constant lETH = ICERC20(0xFdEA956EA2D420571dEadEF18a3d38525e17361C);
  ICERC20 internal constant lPLVGLP = ICERC20(0xDFD276A2460eDb150DE2622f2D947EEa21C3EE48);
  IPriceOracleProxyETH internal constant PRICE_ORACLE =
    IPriceOracleProxyETH(0x569dd9Bc87c7eB5De658c912d21ccB661aA249bD);

  uint256 public constant DIVISOR = 1e4;
  uint16 public constant MAX_LEVERAGE = 30_000; // in {DIVISOR} terms. E.g. 30_000 = 3.0;
}