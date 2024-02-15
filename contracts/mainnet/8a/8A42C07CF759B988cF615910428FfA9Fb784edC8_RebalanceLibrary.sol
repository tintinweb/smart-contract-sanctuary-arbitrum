// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexManager for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for transferring funds form vault to contract and vice versa 
           and swap tokens to and fro from BNB
 * @dev This contract includes functionalities:
 *      1. Deposit tokens to vault
 *      2. Withdraw tokens from vault
 *      3. Swap BNB for tokens
 *      4. Swap tokens for BNB
 */

pragma solidity 0.8.16;

import {IIndexSwap} from "../core/IIndexSwap.sol";

import {FunctionParameters} from "../FunctionParameters.sol";
import {IHandler} from "../handler/IHandler.sol";
import {ExchangeData} from "../handler/ExternalSwapHandler/Helper/ExchangeData.sol";

interface IExchange {
  function init(address _accessController, address _safe, address _oracle, address _tokenRegistry) external;

  /**
   * @return Checks if token is WETH
   */
  function isWETH(address _token, address _protocol) external view returns (bool);

  function _pullFromVault(address t, uint256 amount, address to) external;

  function _pullFromVaultRewards(address token, uint256 amount, address to) external;

  /**
   * @notice The function swaps ETH to a specific token
   * @param inputData includes the input parmas
   */
  function swapETHToToken(FunctionParameters.SwapETHToTokenPublicData calldata inputData) external payable;

  /**
   * @notice The function swaps a specific token to ETH
   * @dev Requires the tokens to be send to this contract address before swapping
   * @param inputData includes the input parmas
   * @return swapResult The outcome amount in ETH afer swapping
   */
  function _swapTokenToETH(
    FunctionParameters.SwapTokenToETHData calldata inputData
  ) external returns (uint256[] calldata);

  /**
   * @notice The function swaps a specific token to ETH
   * @dev Requires the tokens to be send to this contract address before swapping
   * @param inputData includes the input parmas
   * @return swapResult The outcome amount in ETH afer swapping
   */
  function _swapTokenToToken(FunctionParameters.SwapTokenToTokenData memory inputData) external returns (uint256);

  function _swapTokenToTokens(
    FunctionParameters.SwapTokenToTokensData memory inputData,uint256 balanceBefore
  ) external payable returns (uint256 investedAmountAfterSlippage);

  function _swapTokenToTokensOffChain(
    ExchangeData.InputData memory inputData,
    IIndexSwap index,
    uint256[] calldata _lpSlippage,
    address[] memory _tokens,
    uint256[] calldata _buyAmount,
    uint256 balanceBefore,
    address _toUser
  ) external returns (uint256 investedAmountAfterSlippage);

  function swapOffChainTokens(
    ExchangeData.IndexOperationData memory inputdata
  ) external returns (uint256 balanceInUSD, uint256 underlyingIndex);

  function claimTokens(IIndexSwap _index, address[] calldata _tokens) external;

  function oracle() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwap for the Index
 * @author Velvet.Capital
 * @notice This contract is used by the user to invest and withdraw from the index
 * @dev This contract includes functionalities:
 *      1. Invest in the particular fund
 *      2. Withdraw from the fund
 */

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IIndexSwap {
  function vault() external view returns (address);

  function feeModule() external view returns (address);

  function exchange() external view returns (address);

  function tokenRegistry() external view returns (address);

  function accessController() external view returns (address);

  function paused() external view returns (bool);

  function TOTAL_WEIGHT() external view returns (uint256);

  function iAssetManagerConfig() external view returns (address);

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

  /**
   * @dev Token record data structure
   * @param lastDenormUpdate timestamp of last denorm change
   * @param denorm denormalized weight
   * @param index index of address in tokens array
   */
  struct Record {
    uint40 lastDenormUpdate;
    uint96 denorm;
    uint8 index;
  }

  /** @dev Emitted when public trades are enabled. */
  event LOG_PUBLIC_SWAP_ENABLED();

  function init(FunctionParameters.IndexSwapInitData calldata initData) external;

  /**
   * @dev Sets up the initial assets for the pool.
   * @param tokens Underlying tokens to initialize the pool with
   * @param denorms Initial denormalized weights for the tokens
   */
  function initToken(address[] calldata tokens, uint96[] calldata denorms) external;

  // For Minting Shares
  function mintShares(address _to, uint256 _amount) external;

  //For Burning Shares
  function burnShares(address _to, uint256 _amount) external;

  /**
     * @notice The function swaps BNB into the portfolio tokens after a user makes an investment
     * @dev The output of the swap is converted into USD to get the actual amount after slippage to calculate 
            the index token amount to mint
     * @dev (tokenBalance, vaultBalance) has to be calculated before swapping for the _mintShareAmount function 
            because during the swap the amount will change but the index token balance is still the same 
            (before minting)
     */
  function investInFund(uint256[] calldata _slippage, address _swapHandler) external payable;

  /**
     * @notice The function swaps the amount of portfolio tokens represented by the amount of index token back to 
               BNB and returns it to the user and burns the amount of index token being withdrawn
     * @param tokenAmount The index token amount the user wants to withdraw from the fund
     */
  function withdrawFund(uint256 tokenAmount, uint256[] calldata _slippage) external;

  /**
    @notice The function will pause the InvestInFund() and Withdrawal() called by the rebalancing contract.
    @param _state The state is bool value which needs to input by the Index Manager.
    */
  function setPaused(bool _state) external;

  function setRedeemed(bool _state) external;

  /**
    @notice The function will set lastRebalanced time called by the rebalancing contract.
    @param _time The time is block.timestamp, the moment when rebalance is done
  */
  function setLastRebalance(uint256 _time) external;

  /**
    @notice The function returns lastRebalanced time
  */
  function getLastRebalance() external view returns (uint256);

  /**
    @notice The function returns lastPaused time
  */
  function getLastPaused() external view returns (uint256);

  /**
   * @notice The function updates the record struct including the denorm information
   * @dev The token list is passed so the function can be called with current or updated token list
   * @param tokens The updated token list of the portfolio
   * @param denorms The new weights for for the portfolio
   */
  function updateRecords(address[] memory tokens, uint96[] memory denorms) external;

  /**
   * @notice This function update records with new tokenlist and weights
   * @param tokens Array of the tokens to be updated
   * @param _denorms Array of the updated denorm values
   */
  function updateTokenListAndRecords(address[] calldata tokens, uint96[] calldata _denorms) external;

  function getRedeemed() external view returns (bool);

  function getTokens() external view returns (address[] memory);

  function getRecord(address _token) external view returns (Record memory);

  function updateTokenList(address[] memory tokens) external;

  function deleteRecord(address t) external;

  function oracle() external view returns (address);

  function lastInvestmentTime(address owner) external view returns (uint256);

  function checkCoolDownPeriod(address _user) external view;

  function mintTokenAndSetCooldown(address _to, uint256 _mintAmount) external returns (uint256);

  function burnWithdraw(address _to, uint256 _mintAmount) external returns (uint256 exitFee);

  function setFlags(bool _pauseState, bool _redeemState) external;

  function reentrancyGuardEntered() external returns (bool);

  function nonReentrantBefore() external;

  function nonReentrantAfter() external;
}

// SPDX-License-Identifier: BUSL-1.1

/**
 * @title IndexSwapLibrary for a particular Index
 * @author Velvet.Capital
 * @notice This contract is used for all the calculations and also get token balance in vault
 * @dev This contract includes functionalities:
 *      1. Get tokens balance in the vault
 *      2. Calculate the swap amount needed while performing different operation
 */

pragma solidity 0.8.16;

import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/interfaces/IERC20Upgradeable.sol";

import {IPriceOracle} from "../oracle/IPriceOracle.sol";
import {IIndexSwap} from "./IIndexSwap.sol";
import {IAssetManagerConfig} from "../registry/IAssetManagerConfig.sol";
import {ITokenRegistry} from "../registry/ITokenRegistry.sol";

import {ISwapHandler} from "../handler/ISwapHandler.sol";
import {IExternalSwapHandler} from "../handler/IExternalSwapHandler.sol";
import {IFeeModule} from "../fee/IFeeModule.sol";

import {IExchange} from "./IExchange.sol";
import {IHandler, FunctionParameters} from "../handler/IHandler.sol";

import {ErrorLibrary} from "../library/ErrorLibrary.sol";

import {IWETH} from "../interfaces/IWETH.sol";

library IndexSwapLibrary {
  /**
     * @notice The function calculates the balance of each token in the vault and converts them to USD and 
               the sum of those values which represents the total vault value in USD
     * @return tokenXBalance A list of the value of each token in the portfolio in USD
     * @return vaultValue The total vault value in USD
     */
  function getTokenAndVaultBalance(
    IIndexSwap _index,
    address[] memory _tokens
  ) internal returns (uint256[] memory, uint256) {
    uint256[] memory tokenBalanceInUSD = new uint256[](_tokens.length);
    uint256 vaultBalance;
    ITokenRegistry registry = ITokenRegistry(_index.tokenRegistry());
    address vault = _index.vault();
    if (_index.totalSupply() > 0) {
      for (uint256 i = 0; i < _tokens.length; i++) {
        address _token = _tokens[i];
        IHandler handler = IHandler(registry.getTokenInformation(_token).handler);
        tokenBalanceInUSD[i] = handler.getTokenBalanceUSD(vault, _token);
        vaultBalance = vaultBalance + tokenBalanceInUSD[i];
      }
      return (tokenBalanceInUSD, vaultBalance);
    } else {
      return (new uint256[](0), 0);
    }
  }

  /**
   * @notice The function calculates the amount in BNB to swap from BNB to each token
   * @dev The amount for each token has to be calculated to ensure the ratio (weight in the portfolio) stays constant
   * @param tokenAmount The amount a user invests into the portfolio
   * @param tokenBalanceInUSD The balanace of each token in the portfolio converted to USD
   * @param vaultBalance The total vault value of all tokens converted to USD
   * @return A list of amounts that are being swapped into the portfolio tokens
   */
  function calculateSwapAmounts(
    IIndexSwap _index,
    uint256 tokenAmount,
    uint256[] memory tokenBalanceInUSD,
    uint256 vaultBalance,
    address[] memory _tokens
  ) internal view returns (uint256[] memory) {
    uint256[] memory amount = new uint256[](_tokens.length);
    if (_index.totalSupply() > 0) {
      for (uint256 i = 0; i < _tokens.length; i++) {
        uint256 balance = tokenBalanceInUSD[i];
        if (balance * tokenAmount < vaultBalance) revert ErrorLibrary.IncorrectInvestmentTokenAmount();
        amount[i] = (balance * tokenAmount) / vaultBalance;
      }
    }
    return amount;
  }

  /**
   * @notice This function transfers the token to swap handler and makes the token to token swap happen
   */
  function transferAndSwapTokenToToken(
    address tokenIn,
    ISwapHandler swapHandler,
    uint256 swapValue,
    uint256 slippage,
    address tokenOut,
    address to,
    bool isEnabled
  ) external returns (uint256 swapResult) {
    TransferHelper.safeTransfer(address(tokenIn), address(swapHandler), swapValue);
    swapResult = swapHandler.swapTokenToTokens(swapValue, slippage, tokenIn, tokenOut, to, isEnabled);
  }

  /**
   * @notice This function transfers the token to swap handler and makes the token to ETH (native BNB) swap happen
   */
  function transferAndSwapTokenToETH(
    address tokenIn,
    ISwapHandler swapHandler,
    uint256 swapValue,
    uint256 slippage,
    address to,
    bool isEnabled
  ) external returns (uint256 swapResult) {
    TransferHelper.safeTransfer(address(tokenIn), address(swapHandler), swapValue);
    swapResult = swapHandler.swapTokensToETH(swapValue, slippage, tokenIn, to, isEnabled);
  }

  /**
   * @notice This function calls the _pullFromVault() function of the IndexSwapLibrary
   */
  function pullFromVault(IExchange _exchange, address _token, uint256 _amount, address _to) external {
    _exchange._pullFromVault(_token, _amount, _to);
  }

  /**
   * @notice This function returns the token balance of the particular contract address
   * @param _token Token whose balance has to be found
   * @param _contract Address of the contract whose token balance is to be retrieved
   * @param _WETH Weth (native) token address
   * @return currentBalance Returns the current token balance of the passed contract address
   */
  function checkBalance(
    address _token,
    address _contract,
    address _WETH
  ) external view returns (uint256 currentBalance) {
    if (_token != _WETH) {
      currentBalance = IERC20Upgradeable(_token).balanceOf(_contract);
      // TransferHelper.safeApprove(_token, address(this), currentBalance);
    } else {
      currentBalance = _contract.balance;
    }
  }

  /**
     * @notice The function calculates the amount of index tokens the user can buy/mint with the invested amount.
     * @param _amount The invested amount after swapping ETH into portfolio tokens converted to USD to avoid 
                      slippage errors
     * @param sumPrice The total value in the vault converted to USD
     * @return Returns the amount of index tokens to be minted.
     */
  function _mintShareAmount(
    uint256 _amount,
    uint256 sumPrice,
    uint256 _indexTokenSupply
  ) external pure returns (uint256) {
    return (_amount * _indexTokenSupply) / sumPrice;
  }

  /**
   * @notice This function helps in multi-asset withdrawal from a portfolio
   */
  function withdrawMultiAssetORWithdrawToken(
    address _tokenRegistry,
    address _exchange,
    address _token,
    uint256 _tokenBalance
  ) external {
    if (_token == ITokenRegistry(_tokenRegistry).getETH()) {
      IExchange(_exchange)._pullFromVault(_token, _tokenBalance, address(this));
      IWETH(ITokenRegistry(_tokenRegistry).getETH()).withdraw(_tokenBalance);
      (bool success, ) = payable(msg.sender).call{value: _tokenBalance}("");
      if (!success) revert ErrorLibrary.ETHTransferFailed();
    } else {
      IExchange(_exchange)._pullFromVault(_token, _tokenBalance, msg.sender);
    }
  }

  /**
   * @notice This function puts some checks before an investment operation
   */
  function beforeInvestment(
    IIndexSwap _index,
    uint256 _slippageLength,
    uint256 _lpSlippageLength,
    address _to
  ) external {
    IAssetManagerConfig _assetManagerConfig = IAssetManagerConfig(_index.iAssetManagerConfig());
    address[] memory _tokens = _index.getTokens();
    if (!(_assetManagerConfig.publicPortfolio() || _assetManagerConfig.whitelistedUsers(_to))) {
      revert ErrorLibrary.UserNotAllowedToInvest();
    }
    if (ITokenRegistry(_index.tokenRegistry()).getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (_slippageLength != _tokens.length || _lpSlippageLength != _tokens.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
    if (_tokens.length == 0) {
      revert ErrorLibrary.NotInitialized();
    }
  }

  /**
   * @notice This function pulls from the vault, sends the tokens to the handler and then redeems it via the handler
   */
  function _pullAndRedeem(
    IExchange _exchange,
    address _token,
    address _to,
    uint256 _amount,
    uint256 _lpSlippage,
    bool isPrimary,
    IHandler _handler
  ) internal {
    if (!isPrimary) {
      _exchange._pullFromVault(_token, _amount, address(_handler));
      _handler.redeem(
        FunctionParameters.RedeemData(_amount, _lpSlippage, _to, _token, _exchange.isWETH(_token, address(_handler)))
      );
    } else {
      _exchange._pullFromVault(_token, _amount, _to);
    }
  }

  /**
   * @notice This function returns the rate of the Index token based on the Vault  and token balance
   */
  function getIndexTokenRate(IIndexSwap _index) external returns (uint256) {
    (, uint256 totalVaultBalance) = getTokenAndVaultBalance(_index, _index.getTokens());
    uint256 _totalSupply = _index.totalSupply();
    if (_totalSupply > 0 && totalVaultBalance > 0) {
      return (totalVaultBalance * (10 ** 18)) / _totalSupply;
    }
    return 10 ** 18;
  }

  /**
   * @notice This function calculates the swap amount for off-chain operations
   */
  function calculateSwapAmountsOffChain(IIndexSwap _index, uint256 tokenAmount) external returns (uint256[] memory) {
    uint256 vaultBalance;
    address[] memory _tokens = _index.getTokens();
    uint256 len = _tokens.length;
    uint256[] memory amount = new uint256[](len);
    uint256[] memory tokenBalanceInUSD = new uint256[](len);
    (tokenBalanceInUSD, vaultBalance) = getTokenAndVaultBalance(_index, _tokens);
    if (_index.totalSupply() == 0) {
      for (uint256 i = 0; i < len; i++) {
        uint256 _denorm = _index.getRecord(_tokens[i]).denorm;
        amount[i] = (tokenAmount * _denorm) / 10_000;
      }
    } else {
      for (uint256 i = 0; i < len; i++) {
        uint256 balance = tokenBalanceInUSD[i];
        if (balance * tokenAmount < vaultBalance) revert ErrorLibrary.IncorrectInvestmentTokenAmount();
        amount[i] = (balance * tokenAmount) / vaultBalance;
      }
    }
    return (amount);
  }

  /**
   * @notice This function applies checks from the asset manager config and token registry side before redeeming
   */
  function beforeRedeemCheck(IIndexSwap _index, uint256 _tokenAmount, address _token, bool _status) external {
    if (_status) {
      revert ErrorLibrary.TokenAlreadyRedeemed();
    }
    if (_tokenAmount > _index.balanceOf(msg.sender)) {
      revert ErrorLibrary.CallerNotHavingGivenTokenAmount();
    }
    address registry = _index.tokenRegistry();
    if (ITokenRegistry(registry).getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (
      !IAssetManagerConfig(_index.iAssetManagerConfig()).isTokenPermitted(_token) &&
      _token != ITokenRegistry(registry).getETH()
    ) {
      revert ErrorLibrary.InvalidToken();
    }
  }

  /**
   * @notice This function applies checks before withdrawal
   */
  function beforeWithdrawCheck(
    uint256 _slippage,
    uint256 _lpSlippage,
    address token,
    address owner,
    IIndexSwap index,
    uint256 tokenAmount
  ) external {
    ITokenRegistry registry = ITokenRegistry(index.tokenRegistry());
    address[] memory _tokens = index.getTokens();
    if (registry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }

    if (!IAssetManagerConfig(index.iAssetManagerConfig()).isTokenPermitted(token) && token != registry.getETH()) {
      revert ErrorLibrary.InvalidToken();
    }

    if (tokenAmount > index.balanceOf(owner)) {
      revert ErrorLibrary.CallerNotHavingGivenTokenAmount();
    }
    if (_slippage != _tokens.length || _lpSlippage != _tokens.length) {
      revert ErrorLibrary.InvalidSlippageLength();
    }
  }

  /**
   * @notice This function checks if the investment value is correct or not
   */
  function _checkInvestmentValue(uint256 _tokenAmount, IAssetManagerConfig _assetManagerConfig) external view {
    uint256 max = _assetManagerConfig.MAX_INVESTMENTAMOUNT();
    uint256 min = _assetManagerConfig.MIN_INVESTMENTAMOUNT();
    if (!(_tokenAmount <= max && _tokenAmount >= min)) {
      revert ErrorLibrary.WrongInvestmentAmount({minInvestment: max, maxInvestment: min});
    }
  }

  /**
   * @notice This function adds sanity check to the fee value as well as the _to address
   */
  function mintAndBurnCheck(
    uint256 _fee,
    address _to,
    address _tokenRegistry,
    address _assetManagerConfig
  ) external returns (bool) {
    return (_fee > 0 &&
      !(_to == IAssetManagerConfig(_assetManagerConfig).assetManagerTreasury() ||
        _to == ITokenRegistry(_tokenRegistry).velvetTreasury()));
  }

  /**
   * @notice This function checks if the token is permitted or not and if the token balance is optimum or not
   */
  function _checkPermissionAndBalance(
    address _token,
    uint256 _tokenAmount,
    IAssetManagerConfig _config,
    address _to
  ) external {
    if (!_config.isTokenPermitted(_token)) {
      revert ErrorLibrary.InvalidToken();
    }
    if (IERC20Upgradeable(_token).balanceOf(_to) < _tokenAmount) {
      revert ErrorLibrary.LowBalance();
    }
  }

  /**
   * @notice This function takes care of the checks required before init of the index
   */
  function _beforeInitCheck(IIndexSwap index, address token, uint96 denorm) external {
    IAssetManagerConfig config = IAssetManagerConfig(index.iAssetManagerConfig());
    if ((config.whitelistTokens() && !config.whitelistedToken(token))) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
    if (denorm <= 0) {
      revert ErrorLibrary.InvalidDenorms();
    }
    if (token == address(0)) {
      revert ErrorLibrary.InvalidTokenAddress();
    }
    if (!(ITokenRegistry(index.tokenRegistry()).isEnabled(token))) {
      revert ErrorLibrary.TokenNotApproved();
    }
  }

  /**
   * @notice The function converts the given token amount into USD
   * @param t The base token being converted to USD
   * @param amount The amount to convert to USD
   * @return amountInUSD The converted USD amount
   */
  function _getTokenAmountInUSD(
    address _oracle,
    address t,
    uint256 amount
  ) external view returns (uint256 amountInUSD) {
    amountInUSD = IPriceOracle(_oracle).getPriceTokenUSD18Decimals(t, amount);
  }

  /**
   * @notice The function calculates the balance of a specific token in the vault
   * @return tokenBalance of the specific token
   */
  function getTokenBalance(IIndexSwap _index, address t) external view returns (uint256 tokenBalance) {
    IHandler handler = IHandler(ITokenRegistry(_index.tokenRegistry()).getTokenInformation(t).handler);
    tokenBalance = handler.getTokenBalance(_index.vault(), t);
  }

  /**
   * @notice This function checks if the token is primary and also if the external swap handler is valid
   */
  function checkPrimaryAndHandler(ITokenRegistry registry, address[] calldata tokens, address handler) external view {
    if (!(registry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
    for (uint i = 0; i < tokens.length; i++) {
      if (!registry.getTokenInformation(tokens[i]).primary) {
        revert ErrorLibrary.NotPrimaryToken();
      }
    }
  }

  /**
   * @notice This function makes the necessary checks before an off-chain withdrawal
   */
  function beforeWithdrawOffChain(bool status, ITokenRegistry tokenRegistry, address handler) external {
    if (tokenRegistry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }

    if (!status) {
      revert ErrorLibrary.TokensNotRedeemed();
    }
    if (!(tokenRegistry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
  }

  /**
   * @notice This function charges the fees from the index via the Fee Module
   */
  function chargeFees(IIndexSwap index, IFeeModule feeModule) external returns (uint256 vaultBalance) {
    (, vaultBalance) = getTokenAndVaultBalance(index, index.getTokens());
    feeModule.chargeFeesFromIndex(vaultBalance);
  }

  /**
   * @notice This function gets the underlying balances of the input token
   */
  function getUnderlyingBalances(
    address _token,
    IHandler _handler,
    address _contract
  ) external view returns (uint256[] memory) {
    address[] memory underlying = _handler.getUnderlying(_token);
    uint256[] memory balances = new uint256[](underlying.length);
    for (uint256 i = 0; i < underlying.length; i++) {
      balances[i] = IERC20Upgradeable(underlying[i]).balanceOf(_contract);
    }
    return balances;
  }

  /// @notice Calculate lockup cooldown applied to the investor after pool deposit
  /// @param _currentUserBalance Investor's current pool tokens balance
  /// @param _mintedLiquidity Liquidity to be minted to investor after pool deposit
  /// @param _currentCooldownTime New cooldown lockup time
  /// @param _oldCooldownTime Last cooldown lockup time applied to investor
  /// @param _lastDepositTimestamp Timestamp when last pool deposit happened
  /// @return cooldown New lockup cooldown to be applied to investor address
  function calculateCooldownPeriod(
    uint256 _currentUserBalance,
    uint256 _mintedLiquidity,
    uint256 _currentCooldownTime,
    uint256 _oldCooldownTime,
    uint256 _lastDepositTimestamp
  ) external view returns (uint256 cooldown) {
    // Get timestamp when current cooldown ends
    uint256 prevCooldownEnd = _lastDepositTimestamp + _oldCooldownTime;
    // Current exit remaining cooldown
    uint256 prevCooldownRemaining = prevCooldownEnd < block.timestamp ? 0 : prevCooldownEnd - block.timestamp;
    // If it's first deposit with zero liquidity, no cooldown should be applied
    if (_currentUserBalance == 0 && _mintedLiquidity == 0) {
      cooldown = 0;
      // If it's first deposit, new cooldown should be applied
    } else if (_currentUserBalance == 0) {
      cooldown = _currentCooldownTime;
      // If zero liquidity or new cooldown reduces remaining cooldown, apply remaining
    } else if (_mintedLiquidity == 0 || _currentCooldownTime < prevCooldownRemaining) {
      cooldown = prevCooldownRemaining;
      // For the rest cases calculate cooldown based on current balance and liquidity minted
    } else {
      // If the user already owns liquidity, the additional lockup should be in proportion to their existing liquidity.
      // Aggregate additional and remaining cooldowns
      uint256 balanceBeforeMint = _currentUserBalance - _mintedLiquidity;
      uint256 averageCooldown = (_mintedLiquidity * _currentCooldownTime + balanceBeforeMint * prevCooldownRemaining) /
        _currentUserBalance;
      // Resulting value is capped at new cooldown time (shouldn't be bigger) and falls back to one second in case of zero
      cooldown = averageCooldown > _currentCooldownTime ? _currentCooldownTime : averageCooldown != 0
        ? averageCooldown
        : 1;
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface IFeeModule {
  function chargeFeesFromIndex(uint256 _vaultBalance) external;

  function init(
    address _indexSwap,
    address _assetManagerConfig,
    address _tokenRegistry,
    address _accessController
  ) external;

  function chargeFees() external;

  function chargeEntryFee(uint256 _mintAmount, uint256 _fee) external returns (uint256);

  function chargeExitFee(uint256 _mintAmount, uint256 _fee) external returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library FunctionParameters {
  /**
   * @notice Struct having the init data for a new IndexFactory creation
   * @param _indexSwapLibrary Address of the base IndexSwapLibrary
   * @param _baseIndexSwapAddress Address of the base IndexSwap
   * @param _baseRebalancingAddres Address of the base Rebalancing module
   * @param _baseOffChainRebalancingAddress Address of the base Offchain-Rebalance module
   * @param _baseRebalanceAggregatorAddress Address of the base Rebalance Aggregator module
   * @param _baseExchangeHandlerAddress Address of the base Exchange Handler
   * @param _baseAssetManagerConfigAddress Address of the baes AssetManager Config address
   * @param _baseOffChainIndexSwapAddress Address of the base Offchain-IndexSwap module
   * @param _feeModuleImplementationAddress Address of the base Fee Module implementation
   * @param _baseVelvetGnosisSafeModuleAddress Address of the base Gnosis-Safe module
   * @param _gnosisSingleton Address of the Gnosis Singleton
   * @param _gnosisFallbackLibrary Address of the Gnosis Fallback Library
   * @param _gnosisMultisendLibrary Address of the Gnosis Multisend Library
   * @param _gnosisSafeProxyFactory Address of the Gnosis Safe Proxy Factory
   * @param _priceOracle Address of the base Price Oracle to be used
   * @param _tokenRegistry Address of the Token Registry to be used
   * @param _velvetProtocolFee Fee cut that is being charged (eg: 25% of the fees)
   */
  struct IndexFactoryInitData {
    address _indexSwapLibrary;
    address _baseIndexSwapAddress;
    address _baseRebalancingAddres;
    address _baseOffChainRebalancingAddress;
    address _baseRebalanceAggregatorAddress;
    address _baseExchangeHandlerAddress;
    address _baseAssetManagerConfigAddress;
    address _baseOffChainIndexSwapAddress;
    address _feeModuleImplementationAddress;
    address _baseVelvetGnosisSafeModuleAddress;
    address _gnosisSingleton;
    address _gnosisFallbackLibrary;
    address _gnosisMultisendLibrary;
    address _gnosisSafeProxyFactory;
    address _priceOracle;
    address _tokenRegistry;
  }

  /**
   * @notice Data passed from the Factory for the init of IndexSwap module
   * @param _name Name of the Index Fund
   * @param _symbol Symbol to represent the Index Fund
   * @param _vault Address of the Vault associated with that Index Fund
   * @param _module Address of the Safe module  associated with that Index Fund
   * @param _oracle Address of the Price Oracle associated with that Index Fund
   * @param _accessController Address of the Access Controller associated with that Index Fund
   * @param _tokenRegistry Address of the Token Registry associated with that Index Fund
   * @param _exchange Address of the Exchange Handler associated with that Index Fund
   * @param _iAssetManagerConfig Address of the Asset Manager Config associated with that Index Fund
   * @param _feeModule Address of the Fee Module associated with that Index Fund
   */
  struct IndexSwapInitData {
    string _name;
    string _symbol;
    address _vault;
    address _module;
    address _oracle;
    address _accessController;
    address _tokenRegistry;
    address _exchange;
    address _iAssetManagerConfig;
    address _feeModule;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to ETH (native token) using the swap handler
   * @param _token Address of the token being swapped
   * @param _to Receiver address that is receiving the swapped result
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _swapAmount Amount of tokens to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapTokenToETHData {
    address _token;
    address _to;
    address _swapHandler;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _swapAmount Amount of tokens that is to be swapped
   */
  struct SwapETHToTokenData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
    uint256 _swapAmount;
  }

  /**
   * @notice Struct used to pass data when ETH (native token) is swapped to some other Token using the swap handler
   * @param _token Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   */
  struct SwapETHToTokenPublicData {
    address _token;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _slippage;
    uint256 _lpSlippage;
  }

  /**
   * @notice Struct used to pass data when a Token is swapped to another token using the swap handler
   * @param _tokenIn Address of the token being swapped from
   * @param _tokenOut Address of the token being swapped to
   * @param _to Receiver address that will receive the swapped tokens
   * @param _swapHandler Address of the swap handler being used for the swap
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _swapAmount Amount of tokens that is to be swapped
   * @param _slippage Slippage allowed for the swap
   * @param _lpSlippage LP Slippage allowed for the swap
   * @param _isInvesting Boolean parameter indicating if the swap is being done during investment or withdrawal
   */
  struct SwapTokenToTokenData {
    address _tokenIn;
    address _tokenOut;
    address _to;
    address _swapHandler;
    address _toUser;
    uint256 _swapAmount;
    uint256 _slippage;
    uint256 _lpSlippage;
    bool _isInvesting;
  }

  /**
   * @notice Struct having data for the swap of one token to another based on the input
   * @param _index Address of the IndexSwap associated with the swap tokens
   * @param _inputToken Address of the token being swapped from
   * @param _swapHandler Address of the swap handler being used
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   * @param _tokenAmount Investment amount that is being distributed into all the portfolio tokens
   * @param _totalSupply Total supply of the Index tokens
   * @param amount The swap amount (in case totalSupply != 0) value calculated from the IndexSwapLibrary
   * @param _slippage Slippage for providing the liquidity
   * @param _lpSlippage LP Slippage for providing the liquidity
   */
  struct SwapTokenToTokensData {
    address _index;
    address _inputToken;
    address _swapHandler;
    address _toUser;
    uint256 _tokenAmount;
    uint256 _totalSupply;
    uint256[] amount;
    uint256[] _slippage;
    uint256[] _lpSlippage;
  }

  /**
   * @notice Struct having the Offchain Investment data used for multiple functions
   * @param _offChainHandler Address of the off-chain handler being used
   * @param _buyAmount Array of amounts representing the distribution to all portfolio tokens; sum of this amount is the total investment amount
   * @param _buySwapData Array including the calldata which is required for the external swap handlers to swap ("buy") the portfolio tokens
   */
  struct ZeroExData {
    address _offChainHandler;
    uint256[] _buyAmount;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having the init data for a new Index Fund creation using the Factory
   * @param _assetManagerTreasury Address of the Asset Manager Treasury to be associated with the fund
   * @param _whitelistedTokens Array of tokens which limits the use of only those addresses as portfolio tokens in the fund
   * @param maxIndexInvestmentAmount Maximum Investment amount for the fund
   * @param maxIndexInvestmentAmount Minimum Investment amount for the fund
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee for investing into the fund
   * @param _exitFee Exit fee for withdrawal from the fund
   * @param _public Boolean parameter for is the fund eligible for public investment or only some whitelist users can invest
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or only to whitelisted users
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param name Name of the fund
   * @param symbol Symbol associated with the fund
   */
  struct IndexCreationInitData {
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    uint256 maxIndexInvestmentAmount;
    uint256 minIndexInvestmentAmount;
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    bool _public;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
    string name;
    string symbol;
  }

  /**
   * @notice Struct having data for the Enable Rebalance (1st transaction) during ZeroEx's `Update Weight` call
   * @param _lpSlippage Array of LP Slippage values passed to the function
   * @param _newWeights Array of new weights for the rebalance
   */
  struct EnableRebalanceData {
    uint256[] _lpSlippage;
    uint96[] _newWeights;
  }

  /**
   * @notice Struct having data for the init of Asset Manager Config
   * @param _managementFee Management fee (streaming fee) that the asset manager will receive for managing the fund
   * @param _performanceFee Fee that the asset manager will receive for managing the fund and if the portfolio performance well
   * @param _entryFee Entry fee associated with the config
   * @param _exitFee Exit fee associated with the config
   * @param _minInvestmentAmount Minimum investment amount specified as per the config
   * @param _maxInvestmentAmount Maximum investment amount specified as per the config
   * @param _tokenRegistry Address of the Token Registry associated with the config
   * @param _accessController Address of the Access Controller associated with the config
   * @param _assetManagerTreasury Address of the Asset Manager Treasury account
   * @param _whitelistTokens Boolean parameter which specifies if the asset manager can only choose portfolio tokens from the whitelisted array or not
   * @param _publicPortfolio Boolean parameter for is the portfolio eligible for public investment or not
   * @param _transferable Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _transferableToPublic Boolean parameter for is the Index tokens from the fund transferable to public or not
   * @param _whitelistTokens Boolean parameter for is the token whitelisting enabled for the fund or not
   */
  struct AssetManagerConfigInitData {
    uint256 _managementFee;
    uint256 _performanceFee;
    uint256 _entryFee;
    uint256 _exitFee;
    uint256 _minInvestmentAmount;
    uint256 _maxInvestmentAmount;
    address _tokenRegistry;
    address _accessController;
    address _assetManagerTreasury;
    address[] _whitelistedTokens;
    bool _publicPortfolio;
    bool _transferable;
    bool _transferableToPublic;
    bool _whitelistTokens;
  }

  /**
   * @notice Struct with data passed during the withdrawal from the Index Fund
   * @param _slippage Array of Slippage values passed for the withdrawal
   * @param _lpSlippage Array of LP Slippage values passed for the withdrawal
   * @param tokenAmount Amount of the Index Tokens that is to be withdrawn
   * @param _swapHandler Address of the swap handler being used for the withdrawal process
   * @param _token Address of the token being withdrawn to (must be a primary token)
   * @param isMultiAsset Boolean parameter for is the withdrawal being done in portfolio tokens (multi-token) or in the native token
   */
  struct WithdrawFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 tokenAmount;
    address _swapHandler;
    address _token;
    bool isMultiAsset;
  }

  /**
   * @notice Struct with data passed during the investment into the Index Fund
   * @param _slippage Array of Slippage values passed for the investment
   * @param _lpSlippage Array of LP Slippage values passed for the deposit into LP protocols
   * @param _tokenAmount Amount of token being invested
   * @param _to Address that would receive the index tokens post successful investment
   * @param _swapHandler Address of the swap handler being used for the investment process
   * @param _token Address of the token being made investment in
   */
  struct InvestFund {
    uint256[] _slippage;
    uint256[] _lpSlippage;
    uint256 _tokenAmount;
    address _swapHandler;
    address _token;
  }

  /**
   * @notice Struct passed with values for the updation of tokens via the Rebalancing module
   * @param tokens Array of the new tokens that is to be updated to 
   * @param _swapHandler Address of the swap handler being used for the token update
   * @param denorms Denorms of the new tokens
   * @param _slippageSell Slippage allowed for the sale of tokens
   * @param _slippageBuy Slippage allowed for the purchase of tokens
   * @param _lpSlippageSell LP Slippage allowed for the sale of tokens
   * @param _lpSlippageBuy LP Slippage allowed for the purchase of tokens
   */
  struct UpdateTokens {
    address[] tokens;
    address _swapHandler;
    uint96[] denorms;
    uint256[] _slippageSell;
    uint256[] _slippageBuy;
    uint256[] _lpSlippageSell;
    uint256[] _lpSlippageBuy;
  }

  /**
   * @notice Struct having data for the redeem of tokens using the handlers for different protocols
   * @param _amount Amount of protocol tokens to be redeemed using the handler
   * @param _lpSlippage LP Slippage allowed for the redeem process
   * @param _to Address that would receive the redeemed tokens
   * @param _yieldAsset Address of the protocol token that is being redeemed against
   * @param isWETH Boolean parameter for is the redeem being done for WETH (native token) or not
   */
  struct RedeemData {
    uint256 _amount;
    uint256 _lpSlippage;
    address _to;
    address _yieldAsset;
    bool isWETH;
  }

  /**
   * @notice Struct having data for the setup of different roles during an Index Fund creation
   * @param _exchangeHandler Addresss of the Exchange handler for the fund
   * @param _index Address of the IndexSwap for the fund
   * @param _tokenRegistry Address of the Token Registry for the fund
   * @param _portfolioCreator Address of the account creating/deploying the portfolio
   * @param _rebalancing Address of the Rebalancing module for the fund
   * @param _offChainRebalancing Address of the Offchain-Rebalancing module for the fund
   * @param _rebalanceAggregator Address of the Rebalance Aggregator for the fund
   * @param _feeModule Address of the Fee Module for the fund
   * @param _offChainIndexSwap Address of the OffChain-IndexSwap for the fund
   */
  struct AccessSetup {
    address _exchangeHandler;
    address _index;
    address _tokenRegistry;
    address _portfolioCreator;
    address _rebalancing;
    address _offChainRebalancing;
    address _rebalanceAggregator;
    address _feeModule;
    address _offChainIndexSwap;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IHandler} from "./../../IHandler.sol";
import {IIndexSwap} from "./../../../core/IIndexSwap.sol";

contract ExchangeData {
  /**
   * @notice Struct having data for the swap and deposit using the Meta Aggregator
   * @param sellAmount Amount of token being swapped
   * @param _lpSlippage LP Slippage value allowed for the swap
   * @param sellTokenAddress Address of the token being swapped from
   * @param buyTokenAddress Address of the token being swapped to
   * @param swapHandler Address of the swaphandler being used for the swap
   * @param portfolioToken Portfolio token for the deposit
   * @param callData Encoded data associated with the swap
   */
  struct ExSwapData {
    uint256[] sellAmount;
    uint256 _lpSlippage;
    address[] sellTokenAddress;
    address[] buyTokenAddress;
    address swapHandler;
    address portfolioToken;
    bytes[] callData;
  }

  /**
   * @notice Struct having data for the offchain investment values
   * @param buyAmount Amount to be invested
   * @param _buyToken Address of the token to be invested in
   * @param sellTokenAddress Address of the token in which the investment is being made
   * @param offChainHandler Address of the offchain handler being used
   * @param _buySwapData Encoded data for the investment
   */
  struct ZeroExData {
    uint256[] buyAmount;
    address[] _buyToken;
    address sellTokenAddress;
    address _offChainHandler;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having data for the offchain withdrawal values
   * @param sellAmount Amount of token to be withd
   * @param sellTokenAddress Address of the token being swapped from
   * @param offChainHandler Address of the offchain handler being used
   * @param buySwapData Encoded data for the withdrawal
   */
  struct ZeroExWithdraw {
    uint256[] sellAmount;
    address[] sellTokenAddress;
    address offChainHandler;
    bytes[] buySwapData;
  }

  /**
   * @notice Struct having data for pulling tokens and redeeming during withdrawal
   * @param tokenAmount Amount of token to be pulled and redeemed
   * @param _lpSlippage LP Slippage amount allowed for the operation
   * @param token Address of the token being pulled and redeemed
   */
  struct RedeemData {
    uint256 tokenAmount;
    uint256[] _lpSlippage;
    address token;
  }

  /**
   * @notice Struct having data for `IndexOperationsData` struct and also other functions like `SwapAndCalculate`
   * @param buyAmount Amount of the token to be purchased
   * @param sellTokenAddress Address of the token being swapped from
   * @param _offChainHanlder Address of the offchain handler being used
   * @param _buySwapData Encoded data for the swap
   */
  struct InputData {
    uint256[] buyAmount;
    address sellTokenAddress;
    address _offChainHandler;
    bytes[] _buySwapData;
  }

  /**
   * @notice Struct having data for the `swapOffChainTokens` function from the Exchange handler
   * @param inputData Struct having different input params
   * @param index IndexSwap instance of the current fund
   * @param indexValue Value of the IndexSwap whose inforamtion has to be obtained
   * @param balance Token balance passed during the offchain swap
   * @param _lpSlippage Amount of LP Slippage allowed for the swap
   * @param _buyAmount Amount of token being swapped to
   * @param _token Portoflio token to be invested in
   * @param _toUser Address used to return the dust amount accumulated while investment/withdrawal
   */
  struct IndexOperationData {
    ExchangeData.InputData inputData;
    IIndexSwap index;
    uint256 indexValue;
    uint256 _lpSlippage;
    uint256 _buyAmount;
    address _token;
    address _toUser;
  }

  /**
   * @notice Struct having data for the offchain withdrawal
   * @param sellAmount Amount of token being withdrawn
   * @param userAmount Amount of sell token that the user is holding
   * @param sellTokenAddress Address of the token being swapped from
   * @param offChainHandler Address of the offchain handler being used
   * @param buyToken Address of the token being swapped to
   * @param swapData Enocoded swap data for the withdraw
   */
  struct withdrawData {
    uint256 sellAmount;
    uint256 userAmount;
    address sellTokenAddress;
    address offChainHandler;
    address buyToken;
    bytes swapData;
  }

  /**
   * @notice Struct having data for the swap of tokens using the offchain handler
   * @param sellAmount Amount of token being swapped
   * @param sellTokenAddress Address of the token being swapped from
   * @param buyTokenAddress Address of the token being swapped to
   * @param swapHandler Address of the offchain swaphandler being used
   * @param callData Encoded calldata for the swap
   */
  struct MetaSwapData {
    uint256 sellAmount;
    address sellTokenAddress;
    address buyTokenAddress;
    address swapHandler;
    bytes callData;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {ExchangeData} from "../handler/ExternalSwapHandler/Helper/ExchangeData.sol";

interface IExternalSwapHandler {
  function swap(
    address sellTokenAddress,
    address buyTokenAddress,
    uint sellAmount,
    bytes memory callData,
    address _to
  ) external payable;

  function setAllowance(address _token, address _spender, uint _sellAmount) external;
}

// SPDX-License-Identifier: BUSL-1.1

// lend token
// redeem token
// claim token
// get token balance
// get underlying balance

pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IHandler {
  function deposit(address, uint256[] memory, uint256, address, address) external payable returns (uint256);

  function redeem(FunctionParameters.RedeemData calldata inputData) external;

  function getTokenBalance(address, address) external view returns (uint256);

  function getUnderlyingBalance(address, address) external returns (uint256[] memory);

  function getUnderlying(address) external view returns (address[] memory);

  function getRouterAddress() external view returns (address);

  function encodeData(address t, uint256 _amount) external returns (bytes memory);

  function getClaimTokenCalldata(address _alpacaToken, address _holder) external returns (bytes memory, address);

  function getTokenBalanceUSD(address _tokenHolder, address t) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

interface ISwapHandler {
  function getETH() external view returns (address);

  function getSwapAddress(uint256 _swapAmount, address _t) external view returns (address);

  function swapTokensToETH(uint256 _swapAmount, uint256 _slippage, address _t, address _to, bool isEnabled) external returns (uint256);

  function swapETHToTokens(uint256 _slippage, address _t, address _to) external payable returns (uint256);

  function swapTokenToTokens(
    uint256 _swapAmount,
    uint256 _slippage,
    address _tokenIn,
    address _tokenOut,
    address _to,
    bool isEnabled
  ) external returns (uint256 swapResult);

  function getPathForETH(address crypto) external view returns (address[] memory);

  function getPathForToken(address token) external view returns (address[] memory);

  function getSlippage(
    uint256 _amount,
    uint256 _slippage,
    address[] memory path
  ) external view returns (uint256 minAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint256 value) external returns (bool);

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

/**
 * @title ErrorLibrary
 * @author Velvet.Capital
 * @notice This is a library contract including custom defined errors
 */

library ErrorLibrary {
  error ContractPaused();
  /// @notice Thrown when caller is not rebalancer contract
  error CallerNotRebalancerContract();
  /// @notice Thrown when caller is not asset manager
  error CallerNotAssetManager();
  /// @notice Thrown when caller is not asset manager
  error CallerNotSuperAdmin();
  /// @notice Thrown when caller is not whitelist manager
  error CallerNotWhitelistManager();
  /// @notice Thrown when length of slippage array is not equal to tokens array
  error InvalidSlippageLength();
  /// @notice Thrown when length of tokens array is zero
  error InvalidLength();
  /// @notice Thrown when token is not permitted
  error TokenNotPermitted();
  /// @notice Thrown when user is not allowed to invest
  error UserNotAllowedToInvest();
  /// @notice Thrown when index token in not initialized
  error NotInitialized();
  /// @notice Thrown when investment amount is greater than or less than the set range
  error WrongInvestmentAmount(uint256 minInvestment, uint256 maxInvestment);
  /// @notice Thrown when swap amount is greater than BNB balance of the contract
  error NotEnoughBNB();
  /// @notice Thrown when the total sum of weights is not equal to 10000
  error InvalidWeights(uint256 totalWeight);
  /// @notice Thrown when balance is below set velvet min investment amount
  error BalanceCantBeBelowVelvetMinInvestAmount(uint256 minVelvetInvestment);
  /// @notice Thrown when caller is not holding underlying token amount being swapped
  error CallerNotHavingGivenTokenAmount();
  /// @notice Thrown when length of denorms array is not equal to tokens array
  error InvalidInitInput();
  /// @notice Thrown when the tokens are already initialized
  error AlreadyInitialized();
  /// @notice Thrown when the token is not whitelisted
  error TokenNotWhitelisted();
  /// @notice Thrown when denorms array length is zero
  error InvalidDenorms();
  /// @notice Thrown when token address being passed is zero
  error InvalidTokenAddress();
  /// @notice Thrown when token is not permitted
  error InvalidToken();
  /// @notice Thrown when token is not approved
  error TokenNotApproved();
  /// @notice Thrown when transfer is prohibited
  error Transferprohibited();
  /// @notice Thrown when transaction caller balance is below than token amount being invested
  error LowBalance();
  /// @notice Thrown when address is already approved
  error AddressAlreadyApproved();
  /// @notice Thrown when swap handler is not enabled inside token registry
  error SwapHandlerNotEnabled();
  /// @notice Thrown when swap amount is zero
  error ZeroBalanceAmount();
  /// @notice Thrown when caller is not index manager
  error CallerNotIndexManager();
  /// @notice Thrown when caller is not fee module contract
  error CallerNotFeeModule();
  /// @notice Thrown when lp balance is zero
  error LpBalanceZero();
  /// @notice Thrown when desired swap amount is greater than token balance of this contract
  error InvalidAmount();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInAlpacaProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValue();
  /// @notice Thrown when the mint function returned 0 for success & 1 for failure
  error MintProcessFailed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInApeSwap();
  /// @notice Thrown when the redeeming was success(0) or failure(1)
  error RedeemingCTokenFailed();
  /// @notice Thrown when native BNB is sent for any vault other than mooVenusBNB
  error PleaseDepositUnderlyingToken();
  /// @notice Thrown when redeem amount is greater than tokenBalance of protocol
  error NotEnoughBalanceInBeefyProtocol();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBeefy();
  /// @notice Thrown when the deposit amount of underlying token A is more than contract balance
  error InsufficientTokenABalance();
  /// @notice Thrown when the deposit amount of underlying token B is more than contract balance
  error InsufficientTokenBBalance();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInBiSwapProtocol();
  //Not enough funds
  error InsufficientFunds(uint256 available, uint256 required);
  //Not enough eth for protocol fee
  error InsufficientFeeFunds(uint256 available, uint256 required);
  //Order success but amount 0
  error ZeroTokensSwapped();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInLiqeeProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountMustBeEqualToValuePassed();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInPancakeProtocol();
  /// @notice Thrown when Pid passed is not equal to Pid stored in Pid map
  error InvalidPID();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error InsufficientBalance();
  /// @notice Thrown when the redeem function returns 1 for fail & 0 for success
  error RedeemingFailed();
  /// @notice Thrown when the token passed in getUnderlying is not cToken
  error NotcToken();
  /// @notice Thrown when the redeem amount is more than protocol balance
  error NotEnoughBalanceInWombatProtocol();
  /// @notice Thrown when the mint amount is not equal to token amount passed
  error MintAmountNotEqualToPassedValue();
  /// @notice Thrown when slippage value passed is greater than 100
  error SlippageCannotBeGreaterThan100();
  /// @notice Thrown when tokens are already staked
  error TokensStaked();
  /// @notice Thrown when contract is not paused
  error ContractNotPaused();
  /// @notice Thrown when offchain handler is not valid
  error OffHandlerNotValid();
  /// @notice Thrown when offchain handler is not enabled
  error OffHandlerNotEnabled();
  /// @notice Thrown when swapHandler is not enabled
  error SwaphandlerNotEnabled();
  /// @notice Thrown when account other than asset manager calls
  error OnlyAssetManagerCanCall();
  /// @notice Thrown when already redeemed
  error AlreadyRedeemed();
  /// @notice Thrown when contract is not paused
  error NotPaused();
  /// @notice Thrown when token is not index token
  error TokenNotIndexToken();
  /// @notice Thrown when swaphandler is invalid
  error SwapHandlerNotValid();
  /// @notice Thrown when token that will be bought is invalid
  error BuyTokenAddressNotValid();
  /// @notice Thrown when not redeemed
  error NotRedeemed();
  /// @notice Thrown when caller is not asset manager
  error CallerIsNotAssetManager();
  /// @notice Thrown when account other than asset manager is trying to pause
  error OnlyAssetManagerCanCallUnpause();
  /// @notice Thrown when trying to redeem token that is not staked
  error TokensNotStaked();
  /// @notice Thrown when account other than asset manager is trying to revert or unpause
  error FifteenMinutesNotExcedeed();
  /// @notice Thrown when swapping weight is zero
  error WeightNotGreaterThan0();
  /// @notice Thrown when dividing by zero
  error DivBy0Sumweight();
  /// @notice Thrown when lengths of array are not equal
  error LengthsDontMatch();
  /// @notice Thrown when contract is not paused
  error ContractIsNotPaused();
  /// @notice Thrown when set time period is not over
  error TimePeriodNotOver();
  /// @notice Thrown when trying to set any fee greater than max allowed fee
  error InvalidFee();
  /// @notice Thrown when zero address is passed for treasury
  error ZeroAddressTreasury();
  /// @notice Thrown when assetManagerFee or performaceFee is set zero
  error ZeroFee();
  /// @notice Thrown when trying to enable an already enabled handler
  error HandlerAlreadyEnabled();
  /// @notice Thrown when trying to disable an already disabled handler
  error HandlerAlreadyDisabled();
  /// @notice Thrown when zero is passed as address for oracle address
  error InvalidOracleAddress();
  /// @notice Thrown when zero is passed as address for handler address
  error InvalidHandlerAddress();
  /// @notice Thrown when token is not in price oracle
  error TokenNotInPriceOracle();
  /// @notice Thrown when address is not approved
  error AddressNotApproved();
  /// @notice Thrown when minInvest amount passed is less than minInvest amount set
  error InvalidMinInvestmentAmount();
  /// @notice Thrown when maxInvest amount passed is greater than minInvest amount set
  error InvalidMaxInvestmentAmount();
  /// @notice Thrown when zero address is being passed
  error InvalidAddress();
  /// @notice Thrown when caller is not the owner
  error CallerNotOwner();
  /// @notice Thrown when out asset address is zero
  error InvalidOutAsset();
  /// @notice Thrown when protocol is not paused
  error ProtocolNotPaused();
  /// @notice Thrown when protocol is paused
  error ProtocolIsPaused();
  /// @notice Thrown when proxy implementation is wrong
  error ImplementationNotCorrect();
  /// @notice Thrown when caller is not offChain contract
  error CallerNotOffChainContract();
  /// @notice Thrown when user has already redeemed tokens
  error TokenAlreadyRedeemed();
  /// @notice Thrown when user has not redeemed tokens
  error TokensNotRedeemed();
  /// @notice Thrown when user has entered wrong amount
  error InvalidSellAmount();
  /// @notice Thrown when trasnfer fails
  error WithdrawTransferFailed();
  /// @notice Thrown when caller is not having minter role
  error CallerNotMinter();
  /// @notice Thrown when caller is not handler contract
  error CallerNotHandlerContract();
  /// @notice Thrown when token is not enabled
  error TokenNotEnabled();
  /// @notice Thrown when index creation is paused
  error IndexCreationIsPause();
  /// @notice Thrown denorm value sent is zero
  error ZeroDenormValue();
  /// @notice Thrown when asset manager is trying to input token which already exist
  error TokenAlreadyExist();
  /// @notice Thrown when cool down period is not passed
  error CoolDownPeriodNotPassed();
  /// @notice Thrown When Buy And Sell Token Are Same
  error BuyAndSellTokenAreSame();
  /// @notice Throws arrow when token is not a reward token
  error NotRewardToken();
  /// @notice Throws arrow when MetaAggregator Swap Failed
  error SwapFailed();
  /// @notice Throws arrow when Token is Not  Primary
  error NotPrimaryToken();
  /// @notice Throws when the setup is failed in gnosis
  error ModuleNotInitialised();
  /// @notice Throws when threshold is more than owner length
  error InvalidThresholdLength();
  /// @notice Throws when no owner address is passed while fund creation
  error NoOwnerPassed();
  /// @notice Throws when length of underlying token is greater than 1
  error InvalidTokenLength();
  /// @notice Throws when already an operation is taking place and another operation is called
  error AlreadyOngoingOperation();
  /// @notice Throws when wrong function is executed for revert offchain fund
  error InvalidExecution();
  /// @notice Throws when Final value after investment is zero
  error ZeroFinalInvestmentValue();
  /// @notice Throws when token amount after swap / token amount to be minted comes out as zero
  error ZeroTokenAmount();
  /// @notice Throws eth transfer failed
  error ETHTransferFailed();
  /// @notice Thorws when the caller does not have a default admin role
  error CallerNotAdmin();
  /// @notice Throws when buyAmount is not correct in offchainIndexSwap
  error InvalidBuyValues();
  /// @notice Throws when token is not primary
  error TokenNotPrimary();
  /// @notice Throws when tokenOut during withdraw is not permitted in the asset manager config
  error _tokenOutNotPermitted();
  /// @notice Throws when token balance is too small to be included in index
  error BalanceTooSmall();
  /// @notice Throws when a public fund is tried to made transferable only to whitelisted addresses
  error PublicFundToWhitelistedNotAllowed();
  /// @notice Throws when list input by user is invalid (meta aggregator)
  error InvalidInputTokenList();
  /// @notice Generic call failed error
  error CallFailed();
  /// @notice Generic transfer failed error
  error TransferFailed();
  /// @notice Throws when handler underlying token is not ETH
  error TokenNotETH();  
   /// @notice Thrown when the token passed in getUnderlying is not vToken
  error NotVToken();
  /// @notice Throws when incorrect token amount is encountered during offchain/onchain investment
  error IncorrectInvestmentTokenAmount();
  /// @notice Throws when final invested amount after slippage is 0
  error ZeroInvestedAmountAfterSlippage();
  /// @notice Throws when the slippage trying to be set is in incorrect range
  error IncorrectSlippageRange();
  /// @notice Throws when invalid LP slippage is passed
  error InvalidLPSlippage();
  /// @notice Throws when invalid slippage for swapping is passed
  error InvalidSlippage();
  /// @notice Throws when msg.value is less than the amount passed into the handler
  error WrongNativeValuePassed();
  /// @notice Throws when there is an overflow during muldiv full math operation
  error FULLDIV_OVERFLOW();
  /// @notice Throws when the oracle price is not updated under set timeout
  error PriceOracleExpired();
  /// @notice Throws when the oracle price is returned 0
  error PriceOracleInvalid();
  /// @notice Throws when the initToken or updateTokenList function of IndexSwap is having more tokens than set by the Registry
  error TokenCountOutOfLimit(uint256 limit);
  /// @notice Throws when the array lenghts don't match for adding price feed or enabling tokens
  error IncorrectArrayLength();
  /// @notice Common Reentrancy error for IndexSwap and IndexSwapOffChain
  error ReentrancyGuardReentrantCall();
  /// @notice Throws when user calls updateFees function before proposing a new fee
  error NoNewFeeSet();
  /// @notice Throws when wrong asset is supplied to the Compound v3 Protocol
  error WrongAssetBeingSupplied();
  /// @notice Throws when wrong asset is being withdrawn from the Compound v3 Protocol
  error WrongAssetBeingWithdrawn();
  /// @notice Throws when sequencer is down
  error SequencerIsDown();
  /// @notice Throws when sequencer threshold is not crossed
  error SequencerThresholdNotCrossed();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IPriceOracle {
  function WETH() external returns(address);

  function _addFeed(address base, address quote, AggregatorV2V3Interface aggregator) external;

  function decimals(address base, address quote) external view returns (uint8);

  function latestRoundData(address base, address quote) external view returns (int256);

  function getUsdEthPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getEthUsdPrice(uint256 amountIn) external view returns (uint256 amountOut);

  function getPrice(address base, address quote) external view returns (int256);

  function getPriceForAmount(address token, uint256 amount, bool ethPath) external view returns (uint256 amountOut);

  function getPriceForTokenAmount(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) external view returns (uint256 amountOut);

  function getPriceTokenUSD18Decimals(address _base, uint256 amountIn) external view returns (uint256 amountOut);

  function getPriceForOneTokenInUSD(address _base) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;
import {IIndexSwap} from "../core/IIndexSwap.sol";
import {IExchange} from "../core/IExchange.sol";
import {IndexSwapLibrary, IAssetManagerConfig, ITokenRegistry, ErrorLibrary} from "../core/IndexSwapLibrary.sol";
import {IHandler, FunctionParameters} from "../handler/IHandler.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/interfaces/IERC20Upgradeable.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import {IExternalSwapHandler} from "../handler/IExternalSwapHandler.sol";

library RebalanceLibrary {
  /**
   * @notice The function evaluates new denorms after updating the token list
   * @param tokens The new portfolio tokens
   * @param denorms The new token weights for the updated token list
   * @return A list of updated denorms for the new token list
   */
  function evaluateNewDenorms(
    IIndexSwap index,
    address[] memory tokens,
    uint96[] memory denorms
  ) public view returns (uint256[] memory) {
    address[] memory token = index.getTokens();
    uint256[] memory newDenorms = new uint256[](token.length);
    for (uint256 i = 0; i < token.length; i++) {
      for (uint256 j = 0; j < tokens.length; j++) {
        if (token[i] == tokens[j]) {
          newDenorms[i] = denorms[j];
          break;
        }
      }
    }
    return newDenorms;
  }

  function getSwapAmount(
    IIndexSwap index,
    address _token,
    uint256 _amountA,
    uint256 _amountB
  ) external view returns (uint256 amount) {
    uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, _token);
    amount = (tokenBalance * _amountA) / _amountB;
  }

  function getAmountToSwap(
    IIndexSwap index,
    address _token,
    uint256 newWeight,
    uint256 oldWeight
  ) external view returns (uint256 amount) {
    uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, _token);

    uint256 weightDiff = oldWeight - newWeight;
    uint256 swapAmount = (tokenBalance * weightDiff) / oldWeight;
    return swapAmount;
  }

  /**
   * @notice The function updates record for the metaAggregatorSwap
   * @param index Index address whose tokens weight needs to be found
   * @param tokens Array of token addresses passed to the function
   * @return Array of the current weights returned
   */

  function getCurrentWeights(
    IIndexSwap index,
    address[] calldata tokens,
    uint256 _vaultBalance
  ) external returns (uint96[] memory) {
    uint96[] memory oldWeights = new uint96[](tokens.length);

    uint256[] memory tokenBalanceInUSD = new uint256[](tokens.length);

    (tokenBalanceInUSD, ) = IndexSwapLibrary.getTokenAndVaultBalance(index, tokens);

    for (uint256 i = 0; i < tokens.length; i++) {
      oldWeights[i] = uint96(
        (_vaultBalance == 0) ? _vaultBalance : (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / _vaultBalance
      );
    }
    return oldWeights;
  }

  function getRebalanceSwapData(
    uint256[] calldata newWeights,
    IIndexSwap index
  ) external returns (address[] memory, uint256[] memory) {
    address[] memory tokens = index.getTokens();
    address[] memory sellTokens = new address[](tokens.length);
    uint256[] memory swapAmounts = new uint256[](tokens.length);
    uint256 vaultBalance;

    uint256[] memory tokenBalanceInUSD = new uint256[](tokens.length);

    (tokenBalanceInUSD, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(index, tokens);
    for (uint256 i = 0; i < tokens.length; i++) {
      address _token = tokens[i];
      uint256 oldWeight = (vaultBalance == 0)
        ? vaultBalance
        : (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance;
      uint256 _newWeight = newWeights[i];
      if (_newWeight < oldWeight) {
        uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, _token);
        uint256 weightDiff = oldWeight - _newWeight;
        swapAmounts[i] = (tokenBalance * weightDiff) / oldWeight;
        sellTokens[i] = _token;
      }
    }
    return (sellTokens, swapAmounts);
  }

  function getUpdateTokenData(
    IIndexSwap index,
    address[] calldata newTokens,
    uint96[] calldata newWeights
  ) external view returns (address[] memory, uint256[] memory) {
    address[] memory tokens = index.getTokens();
    uint256[] memory newDenorms = evaluateNewDenorms(index, newTokens, newWeights);
    uint256[] memory swapAmounts = new uint256[](tokens.length);
    address[] memory tokenSell = new address[](tokens.length);
    for (uint256 i = 0; i < tokens.length; i++) {
      if (newDenorms[i] == 0) {
        swapAmounts[i] = IndexSwapLibrary.getTokenBalance(index, tokens[i]);
        tokenSell[i] = tokens[i];
      }
    }
    return (tokenSell, swapAmounts);
  }

  function getUpdateWeightTokenData(
    IIndexSwap index,
    address[] calldata newTokens,
    uint96[] calldata newWeights
  ) external returns (address[] memory, uint256[] memory) {
    address[] memory sellTokens = new address[](newTokens.length);
    uint256[] memory sellAmount = new uint256[](newTokens.length);
    uint256 vaultBalance;
    uint256[] memory tokenBalanceInUSD = new uint256[](newTokens.length);
    (, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(index, index.getTokens());
    (tokenBalanceInUSD, ) = IndexSwapLibrary.getTokenAndVaultBalance(index, newTokens);  
    for (uint256 i = 0; i < newTokens.length; i++) {
      uint256 oldWeight = (vaultBalance == 0)
        ? vaultBalance
        : (tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance;
      if (newWeights[i] < oldWeight) {
        uint256 tokenBalance = IndexSwapLibrary.getTokenBalance(index, newTokens[i]);
        uint256 weightDiff = oldWeight - newWeights[i];
        sellAmount[i] = (tokenBalance * weightDiff) / oldWeight;
        sellTokens[i] = newTokens[i];
      }
    }
    return (sellTokens, sellAmount);
  }

  function getNewTokens(address[] calldata tokens, address portfolioToken) external pure returns (address[] memory) {
    address[] memory newTokens = new address[](tokens.length + 1);
    for (uint i = 0; i < tokens.length; i++) {
      if (tokens[i] == portfolioToken) {
        return tokens;
      }
      newTokens[i] = tokens[i];
    }
    newTokens[tokens.length] = portfolioToken;
    return newTokens;
  }

  /**
   * @notice The function updates record for the metaAggregatorSwap
   * @param index Index address whose record needs to be updated
   * @param _tokens Array of all tokens of the index
   * @param portfolioToken The portfolio token which needs to be updated
   */
  function setRecord(IIndexSwap index, address[] memory _tokens, address portfolioToken) external {
    uint96[] memory oldWeights = new uint96[](_tokens.length);

    uint256[] memory tokenBalanceInUSD = new uint256[](_tokens.length);
    uint256 vaultBalance;
    uint256 bTokenIndex;
    uint256 count;

    if (index.totalSupply() > 0) {
      (tokenBalanceInUSD, vaultBalance) = IndexSwapLibrary.getTokenAndVaultBalance(IIndexSwap(index), _tokens);

      uint256 sum;

      for (uint256 i = 0; i < _tokens.length; i++) {
        oldWeights[i] = uint96((tokenBalanceInUSD[i] * index.TOTAL_WEIGHT()) / vaultBalance);
        sum += oldWeights[i];
        if (oldWeights[i] != 0) {
          count++;
        }
        if (_tokens[i] == portfolioToken) {
          bTokenIndex = i;
          if (oldWeights[i] == 0) {
            count++;
          }
        }
      }

      if (sum != index.TOTAL_WEIGHT()) {
        uint256 diff = index.TOTAL_WEIGHT() - sum;
        oldWeights[bTokenIndex] = oldWeights[bTokenIndex] + uint96(diff);
      }

      if (oldWeights[bTokenIndex] == 0) {
        revert ErrorLibrary.BalanceTooSmall();
      }
      uint256 j;

      address[] memory tempTokens = new address[](count);
      uint96[] memory tempWeights = new uint96[](count);

      for (uint256 i = 0; i < _tokens.length; i++) {
        if (oldWeights[i] != 0) {
          tempTokens[j] = _tokens[i];
          tempWeights[j] = oldWeights[i];
          j++;
        } else {
          index.deleteRecord(_tokens[i]);
        }
      }

      index.updateTokenListAndRecords(tempTokens, tempWeights);

      index.setRedeemed(false);
      index.setPaused(false);
    }
  }

  function updateTokensCheck(address tokenRegistry, address assetManagerConfig, address _token) external {
    if (!(ITokenRegistry(tokenRegistry).isEnabled(_token))) {
      revert ErrorLibrary.TokenNotApproved();
    }

    if (
      !(!IAssetManagerConfig(assetManagerConfig).whitelistTokens() ||
        IAssetManagerConfig(assetManagerConfig).whitelistedToken(_token))
    ) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
  }

  /**
   * @notice This function gets the underlying balances of the input token
   * @param _token Address of the token whose underlying balance is to be calculated
   * @param _handler Address of the handler of the token passed
   * @param _contract Address of the contract whose underlying balance is to be calculated
   * @return Array of underlying balances for the passed tokens
   */
  function getUnderlyingBalances(
    address _token,
    IHandler _handler,
    address _contract
  ) external view returns (uint256[] memory) {
    address[] memory underlying = _handler.getUnderlying(_token);
    uint256[] memory balances = new uint256[](underlying.length);
    for (uint256 i = 0; i < underlying.length; i++) {
      balances[i] = IERC20Upgradeable(underlying[i]).balanceOf(_contract);
    }
    return balances;
  }

  function checkPrimary(IIndexSwap index, address[] calldata tokens) external view {
    for (uint i = 0; i < tokens.length; i++) {
      if (!ITokenRegistry(index.tokenRegistry()).getTokenInformation(tokens[i]).primary) {
        revert ErrorLibrary.NotPrimaryToken();
      }
    }
  }

  function beforeExternalRebalance(IIndexSwap index, ITokenRegistry tokenRegistry,address offchainHandler) external {
    if (!(index.paused())) {
      revert ErrorLibrary.ContractNotPaused();
    }
    if (!index.getRedeemed()) {
      revert ErrorLibrary.TokensStaked();
    }
    if (tokenRegistry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (!tokenRegistry.isExternalSwapHandler(offchainHandler)) {
      revert ErrorLibrary.OffHandlerNotEnabled();
    }
  }

  function beforeExternalSell(IIndexSwap index, ITokenRegistry tokenRegistry, address handler) external view {
    if (!(tokenRegistry.isExternalSwapHandler(handler))) {
      revert ErrorLibrary.OffHandlerNotValid();
    }
    if (!index.getRedeemed()) {
      revert ErrorLibrary.TokensStaked();
    }
  }

  function beforePullAndRedeem(IIndexSwap index, IAssetManagerConfig config, address token) external {
    if (!(index.paused())) {
      revert ErrorLibrary.ContractNotPaused();
    }
    if (!(!config.whitelistTokens() || config.whitelistedToken(token))) {
      revert ErrorLibrary.TokenNotWhitelisted();
    }
  }

  function getOldWeights(IIndexSwap index, address[] calldata tokens) external view returns (uint96[] memory) {
    uint96[] memory oldWeight = new uint96[](tokens.length);
    for (uint i = 0; i < tokens.length; i++) {
      oldWeight[i] = index.getRecord(tokens[i]).denorm;
    }
    return oldWeight;
  }

  function beforeRevertCheck(IIndexSwap index) external view {
    if (!(index.paused())) {
      revert ErrorLibrary.ContractNotPaused();
    }
    if (!index.getRedeemed()) {
      revert ErrorLibrary.TokensStaked();
    }
  }

  function getEthBalance(
    address _eth,
    address[] memory _underlying,
    uint256[] calldata _amount
  ) external returns (uint256, uint256) {
    if (_underlying[0] == _eth) {
      IWETH(_eth).withdraw(_amount[0]);
      return (_amount[0], 1);
    }
    IWETH(_eth).withdraw(_amount[1]);
    return (_amount[1], 0);
  }

  function validateEnableRebalance(IIndexSwap _index, ITokenRegistry _registry, bool isRedeemed) external {
    if (_registry.getProtocolState()) {
      revert ErrorLibrary.ProtocolIsPaused();
    }
    if (_index.paused()) {
      revert ErrorLibrary.ContractPaused();
    }
    if (isRedeemed) {
      revert ErrorLibrary.AlreadyOngoingOperation();
    }
  }

  function validateUpdateRecord(
    address[] memory _newTokens,
    IAssetManagerConfig config,
    ITokenRegistry registry
  ) external {
    for (uint256 i = 0; i < _newTokens.length; i++) {
      if ((config.whitelistTokens() && !config.whitelistedToken(_newTokens[i]))) {
        revert ErrorLibrary.TokenNotWhitelisted();
      }
      if (!registry.isEnabled(_newTokens[i])) {
        revert ErrorLibrary.InvalidToken();
      }
    }
  }

  /**
   * @notice This function is used to validate that user input token address is same as underlying token address
   */
  function verifyAddress(
    address[] memory _redeemedTokensUnderlying,
    address[] memory _portfolioTokenUnderlying,
    address[] memory _sellTokens,
    address[] memory _buyTokens
  ) external pure {
    uint256 _maxLength = _redeemedTokensUnderlying.length > _portfolioTokenUnderlying.length
      ? _redeemedTokensUnderlying.length
      : _portfolioTokenUnderlying.length;

    if (_sellTokens.length != _buyTokens.length || _sellTokens.length != _maxLength) {
      revert ErrorLibrary.InvalidTokenLength();
    }
    _checkUnderlyingCounter(_redeemedTokensUnderlying, _sellTokens, _maxLength);
    _checkUnderlyingCounter(_portfolioTokenUnderlying, _buyTokens, _maxLength);
  }

  /**
   * @notice This function checks for the number of underlying tokens present
   */
  function _checkUnderlyingCounter(
    address[] memory _tokensUnderlying,
    address[] memory _userInputToken,
    uint256 _maxLength
  ) internal pure {
    uint tokenCounter;
    for (uint i = 0; i < _tokensUnderlying.length; i++) {
      for (uint j = 0; j < _maxLength; j++) {
        if (_tokensUnderlying[i] == _userInputToken[j]) {
          tokenCounter++;
        }
      }
    }
    if (tokenCounter != _maxLength) {
      revert ErrorLibrary.InvalidInputTokenList();
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {FunctionParameters} from "../FunctionParameters.sol";

interface IAssetManagerConfig {
  function init(FunctionParameters.AssetManagerConfigInitData calldata initData) external;

  function managementFee() external view returns (uint256);

  function performanceFee() external view returns (uint256);

  function entryFee() external view returns (uint256);

  function exitFee() external view returns (uint256);

  function MAX_INVESTMENTAMOUNT() external view returns (uint256);

  function MIN_INVESTMENTAMOUNT() external view returns (uint256);

  function assetManagerTreasury() external returns (address);

  function whitelistedToken(address) external returns (bool);

  function whitelistedUsers(address) external returns (bool);

  function publicPortfolio() external returns (bool);

  function transferable() external returns (bool);

  function transferableToPublic() external returns (bool);

  function whitelistTokens() external returns (bool);

  function setPermittedTokens(address[] calldata _newTokens) external;

  function deletePermittedTokens(address[] calldata _newTokens) external;

  function isTokenPermitted(address _token) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ITokenRegistry {
  struct TokenRecord {
    bool primary;
    bool enabled;
    address handler;
    address[] rewardTokens;
  }

  function enableToken(address _oracle, address _token) external;

  function isEnabled(address _token) external view returns (bool);

  function isSwapHandlerEnabled(address swapHandler) external view returns (bool);

  function isOffChainHandlerEnabled(address offChainHandler) external view returns (bool);

  function disableToken(address _token) external;

  function checkNonDerivative(address handler) external view returns (bool);

  function getTokenInformation(address) external view returns (TokenRecord memory);

  function enableExternalSwapHandler(address swapHandler) external;

  function disableExternalSwapHandler(address swapHandler) external;

  function isExternalSwapHandler(address swapHandler) external view returns (bool);

  function isRewardToken(address) external view returns (bool);

  function velvetTreasury() external returns (address);

  function IndexOperationHandler() external returns (address);

  function WETH() external returns (address);

  function protocolFee() external returns (uint256);

  function protocolFeeBottomConstraint() external returns (uint256);

  function maxManagementFee() external returns (uint256);

  function maxPerformanceFee() external returns (uint256);

  function maxEntryFee() external returns (uint256);

  function maxExitFee() external returns (uint256);

  function exceptedRangeDecimal() external view returns(uint256);

  function MIN_VELVET_INVESTMENTAMOUNT() external returns (uint256);

  function MAX_VELVET_INVESTMENTAMOUNT() external returns (uint256);

  function enablePermittedTokens(address[] calldata _newTokens) external;

  function setIndexCreationState(bool _state) external;

  function setProtocolPause(bool _state) external;

  function setExceptedRangeDecimal(uint256 _newRange) external ;

  function getProtocolState() external returns (bool);

  function disablePermittedTokens(address[] calldata _tokens) external;

  function isPermitted(address _token) external returns (bool);

  function getETH() external view returns (address);

  function COOLDOWN_PERIOD() external view returns (uint256);

  function setMaxAssetLimit(uint256) external;

  function getMaxAssetLimit() external view returns (uint256);
}