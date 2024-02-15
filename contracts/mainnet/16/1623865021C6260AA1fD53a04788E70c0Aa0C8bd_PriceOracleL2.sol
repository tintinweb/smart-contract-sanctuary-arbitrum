// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable-4.3.2/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {AggregatorV2V3Interface, AggregatorInterface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {Denominations} from "@chainlink/contracts/src/v0.8/Denominations.sol";
import {ErrorLibrary} from "../library/ErrorLibrary.sol";

contract PriceOracleL2 is Ownable {
  /// @notice Thrown when aggregator already exists in price oracle
  error AggregatorAlreadyExists();
  /// @notice Thrown when zero address is passed in aggregator
  error FeedNotFound();

  struct AggregatorInfo {
    mapping(address => AggregatorV2V3Interface) aggregatorInterfaces;
  }

  address public WETH;

  mapping(address => AggregatorInfo) internal aggregatorAddresses;

  uint256 public oracleExpirationThreshold;
  uint256 public sequencerThreshold;
  AggregatorV2V3Interface public sequencerUptimeFeed;

  // Events
  event addFeed(address[] base, address[] quote, AggregatorV2V3Interface[] aggregator);
  event updateFeed(address base, address quote, address aggregator);

  constructor(address _WETH, AggregatorV2V3Interface _sequencerUptimeFeed) {
    WETH = _WETH;
    oracleExpirationThreshold = 90000; // 25 hours
    sequencerThreshold = 3600; //1hours
    sequencerUptimeFeed = _sequencerUptimeFeed;
  }

  /**
   * @notice Retrieve the aggregator of an base / quote pair in the current phase
   * @param base base asset address
   * @param quote quote asset address
   * @return aggregator
   */
  function _getFeed(address base, address quote) internal view returns (AggregatorV2V3Interface aggregator) {
    aggregator = aggregatorAddresses[base].aggregatorInterfaces[quote];
  }

  /**
   * @notice Add a new aggregator of an base / quote pair
   * @param base base asset address
   * @param quote quote asset address
   * @param aggregator aggregator
   */
  function _addFeed(
    address[] memory base,
    address[] memory quote,
    AggregatorV2V3Interface[] memory aggregator
  ) public onlyOwner {
    if (!((base.length == quote.length) && (quote.length == aggregator.length)))
      revert ErrorLibrary.IncorrectArrayLength();

    for (uint256 i = 0; i < base.length; i++) {
      if (base[i] == address(0)) revert ErrorLibrary.InvalidAddress();
      if (quote[i] == address(0)) revert ErrorLibrary.InvalidAddress();
      if ((address(aggregator[i])) == address(0)) revert ErrorLibrary.InvalidAddress();

      if (aggregatorAddresses[base[i]].aggregatorInterfaces[quote[i]] != AggregatorInterface(address(0))) {
        revert AggregatorAlreadyExists();
      }
      aggregatorAddresses[base[i]].aggregatorInterfaces[quote[i]] = aggregator[i];
    }
    emit addFeed(base, quote, aggregator);
  }

  /**
   * @notice Updatee an existing feed
   * @param base base asset address
   * @param quote quote asset address
   * @param aggregator aggregator
   */
  function _updateFeed(address base, address quote, AggregatorV2V3Interface aggregator) public onlyOwner {
    if (base == address(0)) revert ErrorLibrary.InvalidAddress();
    if (quote == address(0)) revert ErrorLibrary.InvalidAddress();
    if ((address(aggregator)) == address(0)) revert ErrorLibrary.InvalidAddress();

    aggregatorAddresses[base].aggregatorInterfaces[quote] = aggregator;
    emit updateFeed(base, quote, address(aggregator));
  }

  /**
   * @notice Returns the decimals of a token pair price feed
   * @param base base asset address
   * @param quote quote asset address
   * @return Decimals of the token pair
   */
  function decimals(address base, address quote) public view returns (uint8) {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    if (address(aggregator) == address(0)) {
      revert FeedNotFound();
    }
    return aggregator.decimals();
  }

  /**
   * @notice Returns the latest price
   * @param base base asset address
   * @param quote quote asset address
   * @return The latest token price of the pair
   */
  function latestRoundData(address base, address quote) internal view returns (int256) {
    (
      ,
      /*uint80 roundID*/ int256 answer,
      uint256 startedAt /*uint256 updatedAt*/ /*uint80 answeredInRound*/,
      ,

    ) = sequencerUptimeFeed.latestRoundData();

    //Checking whether sequencer is up or not
    bool isSequencerUp = answer == 0;
    if (!isSequencerUp) {
      revert ErrorLibrary.SequencerIsDown();
    }

    //Checking Whether Sequncer Threshold Is Crossed After Uptime
    if (block.timestamp - startedAt <= sequencerThreshold) {
      revert ErrorLibrary.SequencerThresholdNotCrossed();
    }

    (
      ,
      /*uint80 roundID*/
      int256 price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
      ,
      uint256 updatedAt,

    ) = aggregatorAddresses[base].aggregatorInterfaces[quote].latestRoundData();

    if (updatedAt + oracleExpirationThreshold < block.timestamp) {
      revert ErrorLibrary.PriceOracleExpired();
    }

    if (price == 0) {
      revert ErrorLibrary.PriceOracleInvalid();
    }

    return price;
  }

  /**
   * @notice Returns the latest ETH price for a specific token amount
   * @param amountIn The amount of base tokens to be converted to ETH
   * @return amountOut The latest ETH token price of the base token
   */
  function getUsdEthPrice(uint256 amountIn) public view returns (uint256 amountOut) {
    uint256 price = uint256(latestRoundData(Denominations.ETH, Denominations.USD));
    uint256 decimal = decimals(Denominations.ETH, Denominations.USD);
    amountOut = (amountIn * (10 ** decimal)) / (price);
  }

  /**
   * @notice Returns the latest USD price for a specific token amount
   * @param amountIn The amount of base tokens to be converted to ETH
   * @return amountOut The latest USD token price of the base token
   */
  function getEthUsdPrice(uint256 amountIn) public view returns (uint256 amountOut) {
    uint256 price = uint256(latestRoundData(Denominations.ETH, Denominations.USD));
    uint256 decimal = decimals(Denominations.ETH, Denominations.USD);
    amountOut = (amountIn * price) / (10 ** decimal);
  }

  /**
   * @notice Returns the latest price
   * @param base base asset address
   * @param quote quote asset address
   * @return The latest token price of the pair
   */
  function getPrice(address base, address quote) public view returns (int256) {
    int256 price = latestRoundData(base, quote);
    return price;
  }

  /**
   * @notice Returns the latest price for a specific amount
   * @param token token asset address
   * @param amount token amount
   * @param ethPath boolean parameter for is the path for ETH (native token)
   * @return amountOut The latest token price of the pair
   */
  function getPriceForAmount(address token, uint256 amount, bool ethPath) public view returns (uint256 amountOut) {
    // token / eth
    if (ethPath) {
      // getPriceTokenUSD18Decimals returns usd amount in 18 decimals
      uint256 price = getPriceTokenUSD18Decimals(token, amount);
      amountOut = getUsdEthPrice(price);
    } else {
      // eth will be in 18 decimals, price and decimal2 is also 18 decimals
      uint256 price = uint256(latestRoundData(Denominations.ETH, Denominations.USD));
      uint256 decimal2 = decimals(Denominations.ETH, Denominations.USD);
      // getPriceUSDToken returns the amount in decimals of token (out)
      amountOut = getPriceUSDToken(token, (price * amount) / (10 ** decimal2));
    }
  }

  /**
   * @notice Returns the latest price for a specific amount
   * @param tokenIn token asset address
   * @param tokenOut token asset address
   * @param amount token amount
   * @return amountOut The latest token price of the pair
   */

  function getPriceForTokenAmount(
    address tokenIn,
    address tokenOut,
    uint256 amount
  ) public view returns (uint256 amountOut) {
    // getPriceTokenUSD18Decimals returns usd amount in 18 decimals
    uint256 price = getPriceTokenUSD18Decimals(tokenIn, amount);
    // getPriceUSDToken returns the amount in decimals of token (out)
    amountOut = getPriceUSDToken(tokenOut, price);
  }

  /**
   * @notice Returns the latest USD price for a specific token and amount
   * @param _base base asset address
   * @param amountIn The amount of base tokens to be converted to USD
   * @return amountOut The latest USD token price of the base token
   */
  function getPriceTokenUSD18Decimals(address _base, uint256 amountIn) public view returns (uint256 amountOut) {
    uint256 output = uint256(getPrice(_base, Denominations.USD));
    uint256 decimalChainlink = decimals(_base, Denominations.USD);
    IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(_base);
    uint8 decimal = token.decimals();

    uint256 diff = uint256(18) - (decimal);

    amountOut = (output * amountIn * (10 ** diff)) / (10 ** decimalChainlink);
  }

  /**
   * @notice Returns the latest token price for a specific USD amount
   * @param _base base asset address
   * @param amountIn The amount of base tokens to be converted to USD
   * @return amountOut The latest USD token price of the base token
   */
  function getPriceUSDToken(address _base, uint256 amountIn) public view returns (uint256 amountOut) {
    uint256 output = uint256(getPrice(_base, Denominations.USD));
    uint256 decimal = decimals(_base, Denominations.USD);

    uint8 tokenOutDecimal = IERC20MetadataUpgradeable(_base).decimals();
    uint256 diff = uint256(18) - (tokenOutDecimal);

    amountOut = ((amountIn * (10 ** decimal)) / output) / (10 ** diff);
  }

  /**
   * @notice Returns the latest token price for a specific token for 1 unit
   * @param _base base asset address
   * @return amountOut The latest USD token price of the base token in 18 decimals
   */
  function getPriceForOneTokenInUSD(address _base) public view returns (uint256 amountOut) {
    uint256 amountIn = 10 ** IERC20MetadataUpgradeable(_base).decimals();
    amountOut = getPriceTokenUSD18Decimals(_base, amountIn);
  }

  /**
   * @notice Updates the oracle timeout threshold
   * @param _newTimeout New timeout threshold set by owner
   */
  function updateOracleExpirationThreshold(uint256 _newTimeout) public onlyOwner {
    oracleExpirationThreshold = _newTimeout;
  }

}