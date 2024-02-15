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

// HOP Official Docs: https://docs.hop.exchange/v/developer-docs/
// HOP GitHub: https://github.com/hop-protocol

/**
 * @title Handler for the Hop protocol
 * @author Velvet.Capital
 * @notice This contract is used to deposit and redeem assets
 *      to/from the Hop protocol.
 * @dev This contract includes functionalities:
 *      1. Deposit tokens to the Hop protocol
 *      2. Redeem tokens from the Hop protocol
 *      3. Get underlying asset address
 *      4. Get protocol token balance
 *      5. Get underlying asset balance
 */

pragma solidity 0.8.16;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/token/ERC20/IERC20Upgradeable.sol";
import {TransferHelper} from "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import {ISwap} from "./interfaces/ISwap.sol";
import {IHOPELP} from "./interfaces/IHOPELP.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

import {IHandler} from "../IHandler.sol";
import {ErrorLibrary} from "./../../library/ErrorLibrary.sol";
import {FunctionParameters} from "contracts/FunctionParameters.sol";
import {IPriceOracle} from "../../oracle/IPriceOracle.sol";

contract HopHandler is IHandler {
  IPriceOracle internal _oracle;

  event Deposit(address indexed user, address indexed token, uint256[] amounts, address indexed to);
  event Redeem(address indexed user, address indexed token, uint256 amount, address indexed to, bool isWETH);

  /**
   * @param _priceOracle address of price oracle
   */
  constructor(address _priceOracle) {
    if (_priceOracle == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    _oracle = IPriceOracle(_priceOracle);
  }

  /**
   * @notice This function deposits assets to the Venus protocol
   * @param _hopeLP Address of the protocol asset to be deposited
   * @param _amount Amount that is to be deposited
   * @param _lpSlippage LP slippage value passed to the function
   * @param _to Address that would receive the vTokens in return
   */
  function deposit(
    address _hopeLP,
    uint256[] calldata _amount,
    uint256 _lpSlippage,
    address _to,
    address user
  ) public payable override returns (uint256 _mintedAmount) {
    if (_hopeLP == address(0) || _to == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    IERC20Upgradeable underlyingToken = IERC20Upgradeable(getUnderlying(_hopeLP)[0]);

    IHOPELP hopeLP = IHOPELP(_hopeLP);
    address pool = hopeLP.swap();

    if (msg.value > 0) {
      if (address(underlyingToken) != _oracle.WETH()) revert ErrorLibrary.TokenNotETH();
      if (msg.value != _amount[0]) revert ErrorLibrary.WrongNativeValuePassed();
      IWETH(address(underlyingToken)).deposit{value: msg.value}();
    }
    TransferHelper.safeApprove(address(underlyingToken), pool, 0);
    TransferHelper.safeApprove(address(underlyingToken), pool, _amount[0]);
    uint256 mintAmount = getSlippage(_hopeLP, _amount[0], true, _lpSlippage, _to);
    uint256[] memory inputAmount = new uint256[](2);
    inputAmount[0] = _amount[0];
    inputAmount[1] = 0;
    uint256 liquidity = ISwap(pool).addLiquidity(inputAmount, mintAmount, block.timestamp);
    if (liquidity == 0) {
      revert ErrorLibrary.ZeroBalanceAmount();
    }
    TransferHelper.safeTransfer(_hopeLP, _to, liquidity);
    emit Deposit(msg.sender, _hopeLP, _amount, _to);
    _mintedAmount = (ISwap(pool).getVirtualPrice() * liquidity) / (10 ** hopeLP.decimals());
  }

  /**
   * @notice This function redeems assets from the Venus protocol
   */
  function redeem(FunctionParameters.RedeemData calldata inputData) public override {
    if (inputData._yieldAsset == address(0) || inputData._to == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    IHOPELP hopeLP = IHOPELP(inputData._yieldAsset);
    if (inputData._amount > hopeLP.balanceOf(address(this))) {
      revert ErrorLibrary.InsufficientBalance();
    }

    address pool = hopeLP.swap();
    IERC20Upgradeable underlyingToken = IERC20Upgradeable(getUnderlying(inputData._yieldAsset)[0]);

    TransferHelper.safeApprove(inputData._yieldAsset, pool, 0);
    TransferHelper.safeApprove(inputData._yieldAsset, pool, inputData._amount);
    uint256 underlyingAmount = ISwap(pool).removeLiquidityOneToken(
      inputData._amount,
      0,
      getSlippage(inputData._yieldAsset, inputData._amount, false, inputData._lpSlippage, inputData._to),
      block.timestamp
    );

    TransferHelper.safeTransfer(address(underlyingToken), inputData._to, underlyingAmount);
    emit Redeem(msg.sender, inputData._yieldAsset, inputData._amount, inputData._to, inputData.isWETH);
  }

  /**
   * @notice This function returns address of the underlying asset
   * @param _hopeLP Address of the protocol token whose underlying asset is needed
   * @return underlying Address of the underlying asset
   */
  function getUnderlying(address _hopeLP) public view override returns (address[] memory) {
    if (_hopeLP == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    address[] memory underlying = new address[](1);
    //Here we are considering only one token as underlying, because hop lp has two token one is base token and other is derivative
    underlying[0] = address(ISwap(IHOPELP(_hopeLP).swap()).getToken(0));
    return underlying;
  }

  /**
   * @notice This function returns the protocol token balance of the passed address
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param t Address of the protocol token
   * @return tokenBalance t token balance of the holder
   */
  function getTokenBalance(address _tokenHolder, address t) public view override returns (uint256 tokenBalance) {
    if (t == address(0) || _tokenHolder == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }

    tokenBalance = IERC20Upgradeable(t).balanceOf(_tokenHolder);
  }

  /**
   * @notice This function returns the underlying asset balance of the passed address
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param t Address of the protocol token
   * @return tokenBalance t token's underlying asset balance of the holder
   */
  function getUnderlyingBalance(address _tokenHolder, address t) public view override returns (uint256[] memory) {
    if (t == address(0) || _tokenHolder == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }

    uint256[] memory expectedAmount = new uint256[](1);
    uint256 tokenBalance = getTokenBalance(_tokenHolder, t);
    if (tokenBalance != 0) {
      expectedAmount[0] = getUnderlyingAmount(_tokenHolder, tokenBalance, t);
    }

    return expectedAmount;
  }


  /**
   * @notice This function returns the underlying asset balance of the passed address
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param _amount Amount of lp token
   * @param token address of lp token
   * @return underlyingAmount underlying amount in one token
   */
  function getUnderlyingAmount(address _tokenHolder, uint256 _amount, address token) public view returns (uint256) {
    //Here getting underlying token amount in one token
    return ISwap(IHOPELP(token).swap()).calculateRemoveLiquidityOneToken(_tokenHolder, _amount, 0);
  }

  /**
   * @notice This function returns the USD value of the asset
   * @param _tokenHolder Address whose balance is to be retrieved
   * @param t Address of the protocol token
   */
  function getTokenBalanceUSD(address _tokenHolder, address t) public view override returns (uint256) {
    if (t == address(0) || _tokenHolder == address(0)) {
      revert ErrorLibrary.InvalidAddress();
    }
    uint[] memory underlyingBalance = getUnderlyingBalance(_tokenHolder, t);
    address[] memory underlyingToken = getUnderlying(t);

    uint balanceUSD = _oracle.getPriceTokenUSD18Decimals(underlyingToken[0], underlyingBalance[0]);
    return balanceUSD;
  }

  /**
   * @notice This function is helper function for deposit and redeem
   * @param _hopeLP address of token
   * @param tokenAmount amount of token for slippage
   * @param _deposit boolean value to check whether deposit or redeem
   * @param _lpSlippage value of lpslippage input by user
   * @param _to address to sent token
   * @return slippage value of slippage to consider
   */
  function getSlippage(
    address _hopeLP,
    uint256 tokenAmount,
    bool _deposit,
    uint256 _lpSlippage,
    address _to
  ) internal view returns (uint256) {
    uint256 expectedAmount;
    if (_deposit) {
      uint256[] memory _amount = new uint256[](2);
      _amount[0] = tokenAmount;
      _amount[1] = 0;
      expectedAmount = ISwap(IHOPELP(_hopeLP).swap()).calculateTokenAmount(_to, _amount, true);
    } else {
      expectedAmount = ISwap(IHOPELP(_hopeLP).swap()).calculateRemoveLiquidityOneToken(_to, tokenAmount, 0);
    }
    return expectedAmount - ((expectedAmount * _lpSlippage) / 10000);
  }

  // function getToken() public returns()

  function getFairLpPrice(address _tokenHolder, address t) public view returns (uint) {}

  function encodeData(address t, uint256 _amount) public returns (bytes memory) {}

  function getRouterAddress() public view returns (address) {}

  function getClaimTokenCalldata(address _venusToken, address _holder) public pure returns (bytes memory, address) {}

  receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;
interface IHOPELP {

    function swap() external view returns(address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/token/ERC20/IERC20Upgradeable.sol";


interface ISwap {
    // pool data view functions
    function getA() external view returns (uint256);

    function getToken(uint8 index) external view returns (IERC20Upgradeable);

    function getTokenIndex(address tokenAddress) external view returns (uint8);

    function getTokenBalance(uint8 index) external view returns (uint256);

    function getVirtualPrice() external view returns (uint256);

    function isGuarded() external view returns (bool);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function calculateTokenAmount(address account,uint256[] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calculateRemoveLiquidity(uint256 amount)
        external
        view
        returns (uint256[] memory);

    function calculateRemoveLiquidityOneToken(
        address account,
        uint256 tokenAmount,
        uint8 tokenIndex
    ) external view returns (uint256 availableTokenAmount);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);

    function addLiquidity(
        uint256[] calldata amounts,
        uint256 minToMint,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidity(
        uint256 amount,
        uint256[] calldata minAmounts,
        uint256 deadline
    ) external returns (uint256[] memory);

    function removeLiquidityOneToken(
        uint256 tokenAmount,
        uint8 tokenIndex,
        uint256 minAmount,
        uint256 deadline
    ) external returns (uint256);

    function removeLiquidityImbalance(
        uint256[] calldata amounts,
        uint256 maxBurnAmount,
        uint256 deadline
    ) external returns (uint256);

    // withdraw fee update function
    function updateUserWithdrawFee(address recipient, uint256 transferAmount)
        external;
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