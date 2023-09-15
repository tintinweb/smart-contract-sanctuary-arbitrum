// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IOracleJob} from '@interfaces/jobs/IOracleJob.sol';
import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';
import {IPIDRateSetter} from '@interfaces/IPIDRateSetter.sol';
import {IStabilityFeeTreasury} from '@interfaces/IStabilityFeeTreasury.sol';

import {Job} from '@contracts/jobs/Job.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';
import {Modifiable} from '@contracts/utils/Modifiable.sol';

import {Encoding} from '@libraries/Encoding.sol';

/**
 * @title  OracleJob
 * @notice This contract contains rewarded methods to handle the oracle relayer and the PID rate setter updates
 */
contract OracleJob is Job, Authorizable, Modifiable, IOracleJob {
  using Encoding for bytes;

  // --- Data ---

  /// @inheritdoc IOracleJob
  bool public shouldWorkUpdateCollateralPrice;
  /// @inheritdoc IOracleJob
  bool public shouldWorkUpdateRate;

  // --- Registry ---

  /// @inheritdoc IOracleJob
  IOracleRelayer public oracleRelayer;
  /// @inheritdoc IOracleJob
  IPIDRateSetter public pidRateSetter;

  // --- Init ---

  /**
   * @param  _oracleRelayer Address of the OracleRelayer contract
   * @param  _pidRateSetter Address of the PIDRateSetter contract
   * @param  _stabilityFeeTreasury Address of the StabilityFeeTreasury contract
   * @param  _rewardAmount Amount of tokens to reward per job transaction [wad]
   */
  constructor(
    address _oracleRelayer,
    address _pidRateSetter,
    address _stabilityFeeTreasury,
    uint256 _rewardAmount
  ) Job(_stabilityFeeTreasury, _rewardAmount) Authorizable(msg.sender) {
    oracleRelayer = IOracleRelayer(_oracleRelayer);
    pidRateSetter = IPIDRateSetter(_pidRateSetter);

    shouldWorkUpdateCollateralPrice = true;
    shouldWorkUpdateRate = true;
  }

  // --- Job ---

  /// @inheritdoc IOracleJob
  function workUpdateCollateralPrice(bytes32 _cType) external reward {
    if (!shouldWorkUpdateCollateralPrice) revert NotWorkable();

    IDelayedOracle _delayedOracle = IDelayedOracle(address(oracleRelayer.cParams(_cType).oracle));
    if (!_delayedOracle.updateResult()) revert OracleJob_InvalidPrice();

    oracleRelayer.updateCollateralPrice(_cType);
  }

  /// @inheritdoc IOracleJob
  function workUpdateRate() external reward {
    if (!shouldWorkUpdateRate) revert NotWorkable();
    pidRateSetter.updateRate();
  }

  // --- Administration ---

  /// @inheritdoc Modifiable
  function _modifyParameters(bytes32 _param, bytes memory _data) internal override {
    address _address = _data.toAddress();
    bool _bool = _data.toBool();

    if (_param == 'oracleRelayer') oracleRelayer = IOracleRelayer(_address);
    else if (_param == 'pidRateSetter') pidRateSetter = IPIDRateSetter(_address);
    else if (_param == 'stabilityFeeTreasury') stabilityFeeTreasury = IStabilityFeeTreasury(_address);
    else if (_param == 'shouldWorkUpdateCollateralPrice') shouldWorkUpdateCollateralPrice = _bool;
    else if (_param == 'shouldWorkUpdateRate') shouldWorkUpdateRate = _bool;
    else if (_param == 'rewardAmount') rewardAmount = _data.toUint256();
    else revert UnrecognizedParam();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';
import {IPIDRateSetter} from '@interfaces/IPIDRateSetter.sol';

import {IJob, IStabilityFeeTreasury} from '@interfaces/jobs/IJob.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface IOracleJob is IJob, IAuthorizable, IModifiable {
  // --- Errors ---

  /// @notice Throws when trying to update an invalid collateral price
  error OracleJob_InvalidPrice();

  // --- Data ---

  /// @notice Whether the update collateral price job should be worked
  function shouldWorkUpdateCollateralPrice() external view returns (bool _shouldWorkUpdateCollateralPrice);
  /// @notice Whether the update rate job should be worked
  function shouldWorkUpdateRate() external view returns (bool _shouldWorkUpdateRate);

  // --- Registry ---

  /// @notice Address of the OracleRelayer contract
  function oracleRelayer() external view returns (IOracleRelayer _oracleRelayer);
  /// @notice Address of the PIDRateSetter contract
  function pidRateSetter() external view returns (IPIDRateSetter _pidRateSetter);

  // --- Job ---

  /**
   * @notice Rewarded method to update a collateral price
   * @param _cType Bytes32 representation of the collateral type
   */
  function workUpdateCollateralPrice(bytes32 _cType) external;

  /// @notice Rewarded method to update the redemption rate
  function workUpdateRate() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface IOracleRelayer is IAuthorizable, IModifiable, IDisableable {
  // --- Events ---

  /**
   * @notice Emitted when the redemption price is updated
   * @param _redemptionPrice The new redemption price [ray]
   */
  event UpdateRedemptionPrice(uint256 _redemptionPrice);

  /**
   * @notice Emitted when a collateral type price is updated
   * @param _cType Bytes32 representation of the collateral type
   * @param _priceFeedValue The new collateral price [wad]
   * @param _safetyPrice The new safety price [ray]
   * @param _liquidationPrice The new liquidation price [ray]
   */
  event UpdateCollateralPrice(
    bytes32 indexed _cType, uint256 _priceFeedValue, uint256 _safetyPrice, uint256 _liquidationPrice
  );

  // --- Errors ---

  /// @notice Throws if the redemption price is not updated when updating the rate
  error OracleRelayer_RedemptionPriceNotUpdated();
  /// @notice Throws when trying to initialize a collateral type that is already initialized
  error OracleRelayer_CollateralTypeAlreadyInitialized();

  // --- Structs ---

  struct OracleRelayerParams {
    // Upper bound for the per-second redemption rate
    uint256 /* RAY */ redemptionRateUpperBound;
    // Lower bound for the per-second redemption rate
    uint256 /* RAY */ redemptionRateLowerBound;
  }

  struct OracleRelayerCollateralParams {
    // Usually a DelayedOracle that enforces delays to fresh price feeds
    IDelayedOracle /* */ oracle;
    // CRatio used to compute the 'safePrice' - the price used when generating debt in SAFEEngine
    uint256 /* RAY    */ safetyCRatio;
    // CRatio used to compute the 'liquidationPrice' - the price used when liquidating SAFEs
    uint256 /* RAY    */ liquidationCRatio;
  }

  // --- Registry ---

  /**
   * @notice The SAFEEngine is called to update the price of the collateral in the system
   * @return _safeEngine Address of the contract that handles the state of the SAFEs
   */
  function safeEngine() external view returns (ISAFEEngine _safeEngine);

  /**
   * @notice The oracle used to fetch the system coin market price
   * @return _systemCoinOracle Address of the contract that provides the system coin price
   */
  function systemCoinOracle() external view returns (IBaseOracle _systemCoinOracle);

  // --- Params ---

  /**
   * @notice Getter for the contract parameters struct
   * @dev    Returns a OracleRelayerParams struct
   */
  function params() external view returns (OracleRelayerParams memory _oracleRelayerParams);

  /**
   * @notice Getter for the unpacked contract parameters struct
   * @param _redemptionRateUpperBound Upper bound for the per-second redemption rate [ray]
   * @param _redemptionRateLowerBound Lower bound for the per-second redemption rate [ray]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _params() external view returns (uint256 _redemptionRateUpperBound, uint256 _redemptionRateLowerBound);

  /**
   * @notice Getter for the collateral parameters struct
   * @param  _cType Bytes32 representation of the collateral type
   * @dev    Returns a OracleRelayerCollateralParams struct
   */
  function cParams(bytes32 _cType) external view returns (OracleRelayerCollateralParams memory _oracleRelayerCParams);

  /**
   * @notice Getter for the unpacked collateral parameters struct
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _oracle Usually a DelayedOracle that enforces delays to fresh price feeds
   * @param  _safetyCRatio CRatio used to compute the 'safePrice' - the price used when generating debt in SAFEEngine [ray]
   * @param  _liquidationCRatio CRatio used to compute the 'liquidationPrice' - the price used when liquidating SAFEs [ray]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _cParams(bytes32 _cType)
    external
    view
    returns (IDelayedOracle _oracle, uint256 _safetyCRatio, uint256 _liquidationCRatio);

  // --- Data ---

  /**
   * @notice View method to fetch the current redemption price
   * @return _redemptionPrice The current calculated redemption price [ray]
   */
  function calcRedemptionPrice() external view returns (uint256 _redemptionPrice);

  /**
   * @notice The current system coin market price
   * @return _marketPrice The current system coin market price [ray]
   */
  function marketPrice() external view returns (uint256 _marketPrice);

  /**
   * @notice The redemption rate is the rate at which the redemption price changes over time
   * @return _redemptionRate The current updated redemption rate [ray]
   * @dev    By changing the redemption rate, it changes the incentives of the system users
   * @dev    The redemption rate is a per-second rate [ray]
   */
  function redemptionRate() external view returns (uint256 _redemptionRate);

  /**
   * @notice Last time when the redemption price was changed
   * @return _redemptionPriceUpdateTime The last time when the redemption price was changed [unix timestamp]
   * @dev    Used to calculate the current redemption price
   */
  function redemptionPriceUpdateTime() external view returns (uint256 _redemptionPriceUpdateTime);

  // --- Methods ---

  /**
   * @notice Fetch the latest redemption price by first updating it
   * @return _updatedPrice The newly updated redemption price [ray]
   */
  function redemptionPrice() external returns (uint256 _updatedPrice);

  /**
   * @notice Update the collateral price inside the system (inside SAFEEngine)
   * @dev    Usually called by a keeper, incentivized by the system to keep the prices up to date
   * @param  _cType Bytes32 representation of the collateral type
   */
  function updateCollateralPrice(bytes32 _cType) external;

  /**
   * @notice Update the system redemption rate, the rate at which the redemption price changes over time
   * @dev    Usually called by the PIDRateSetter
   * @param  _redemptionRate The newly calculated redemption rate [ray]
   */
  function updateRedemptionRate(uint256 _redemptionRate) external;

  /**
   * @notice Register a new collateral type in the OracleRelayer
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _collateralParams OracleRelayerCollateralParams valid struct containing the collateral parameters
   */
  function initializeCollateralType(bytes32 _cType, OracleRelayerCollateralParams memory _collateralParams) external;

  // --- Views ---

  /**
   * @notice List of all the collateral types registered in the OracleRelayer
   * @return __collateralList Array of all the collateral types registered
   */
  function collateralList() external view returns (bytes32[] memory __collateralList);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

interface IDelayedOracle is IBaseOracle {
  // --- Events ---

  /**
   * @notice Emitted when the oracle is updated
   * @param _newMedian The new median value
   * @param _lastUpdateTime The timestamp of the update
   */
  event UpdateResult(uint256 _newMedian, uint256 _lastUpdateTime);

  // --- Errors ---

  /// @notice Throws if the provided price source address is null
  error DelayedOracle_NullPriceSource();
  /// @notice Throws if the provided delay is null
  error DelayedOracle_NullDelay();
  /// @notice Throws when trying to update the oracle before the delay has elapsed
  error DelayedOracle_DelayHasNotElapsed();
  /// @notice Throws when trying to read the current value and it is invalid
  error DelayedOracle_NoCurrentValue();

  // --- Structs ---

  struct Feed {
    // The value of the price feed
    uint256 /* WAD */ value;
    // Whether the value is valid or not
    bool /* bool   */ isValid;
  }

  /**
   * @notice Address of the non-delayed price source
   * @dev    Assumes that the price source is a valid IBaseOracle
   */
  function priceSource() external view returns (IBaseOracle _priceSource);

  /**
   * @notice The next valid price feed, taking effect at the next updateResult call
   * @return _result The value in 18 decimals format of the next price feed
   * @return _validity Whether the next price feed is valid or not
   */
  function getNextResultWithValidity() external view returns (uint256 _result, bool _validity);

  /// @notice The delay in seconds that should elapse between updates
  function updateDelay() external view returns (uint256 _updateDelay);

  /// @notice The timestamp of the last update
  function lastUpdateTime() external view returns (uint256 _lastUpdateTime);

  /**
   * @notice Indicates if a delay has passed since the last update
   * @return _ok Whether the oracle should be updated or not
   */
  function shouldUpdate() external view returns (bool _ok);

  /**
   * @notice Updates the current price with the last next price, and reads the next price feed
   * @dev    Will revert if the delay since last update has not elapsed
   * @return _success Whether the update was successful or not
   */
  function updateResult() external returns (bool _success);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IPIDController} from '@interfaces/IPIDController.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface IPIDRateSetter is IAuthorizable, IModifiable {
  // --- Events ---

  /**
   * @notice Emitted when the redemption rate is updated
   * @param _marketPrice Computed price of the system coin
   * @param _redemptionPrice Redemption price of the system coin
   * @param _redemptionRate Resulting new redemption rate
   */
  event UpdateRedemptionRate(uint256 _marketPrice, uint256 _redemptionPrice, uint256 _redemptionRate);

  // --- Errors ---

  /// @notice Throws if the market price feed returns an invalid value
  error PIDRateSetter_InvalidPriceFeed();
  /// @notice Throws if the call to `updateRate` is too soon since last update
  error PIDRateSetter_RateSetterCooldown();

  // --- Structs ---

  struct PIDRateSetterParams {
    // Enforced gap between calls
    uint256 /* seconds */ updateRateDelay;
  }

  // --- Registry ---

  /**
   * @notice The oracle relayer where the redemption price and rate are stored
   */
  function oracleRelayer() external view returns (IOracleRelayer _oracleRelayer);

  /**
   * @notice The PID calculator used to compute the redemption rate
   */
  function pidCalculator() external view returns (IPIDController _pidCalculator);

  // --- Params ---

  /**
   * @notice Getter for the contract parameters struct
   * @return _pidRateSetterParams PIDRateSetter parameters struct
   */
  function params() external view returns (PIDRateSetterParams memory _pidRateSetterParams);

  /**
   * @notice Getter for the unpacked contract parameters struct
   * @return _updateRateDelay Enforced gap between calls
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _params() external view returns (uint256 _updateRateDelay);

  // --- Data ---

  /**
   * @notice The timestamp of the last update
   */
  function lastUpdateTime() external view returns (uint256 _lastUpdateTime);

  // --- Methods ---

  /**
   * @notice Compute and set a new redemption rate
   */
  function updateRate() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {ICoinJoin} from '@interfaces/utils/ICoinJoin.sol';
import {ISystemCoin} from '@interfaces/tokens/ISystemCoin.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface IStabilityFeeTreasury is IAuthorizable, IModifiable, IDisableable {
  // --- Events ---

  /**
   * @notice Emitted when an account's total allowance is modified
   * @param  _account The account whose allowance was modified
   * @param  _rad The new total allowance [rad]
   */
  event SetTotalAllowance(address indexed _account, uint256 _rad);

  /**
   * @notice Emitted when an account's per hour allowance is modified
   * @param  _account The account whose allowance was modified
   * @param  _rad The new per hour allowance [rad]
   */
  event SetPerHourAllowance(address indexed _account, uint256 _rad);

  /**
   * @notice Emitted when governance gives funds to an account
   * @param  _account The account that received funds
   * @param  _rad The amount of funds that were given [rad]
   */
  event GiveFunds(address indexed _account, uint256 _rad);

  /**
   * @notice Emitted when governance takes funds from an account
   * @param  _account The account from which the funds are taken
   * @param  _rad The amount of funds that were taken [rad]
   */
  event TakeFunds(address indexed _account, uint256 _rad);

  /**
   * @notice Emitted when an account pulls funds from the treasury
   * @param  _sender The account that triggered the pull
   * @param  _dstAccount The account that received funds
   * @param  _rad The amount of funds that were pulled [rad]
   */
  event PullFunds(address indexed _sender, address indexed _dstAccount, uint256 _rad);

  /**
   * @notice Emitted when surplus funds are transferred to the extraSurplusReceiver
   * @param  _extraSurplusReceiver The account that received the surplus funds
   * @param  _fundsToTransfer The amount of funds that were transferred [rad]
   */
  event TransferSurplusFunds(address _extraSurplusReceiver, uint256 _fundsToTransfer);

  /**
   * @notice Emitted when ERC20 coins are joined into the system
   * @param  _wad The amount of ERC20 coins that were joined [wad]
   */
  event JoinCoins(uint256 _wad);

  /**
   * @notice Emitted when treasury coins are used to settle debt
   * @param  _rad The amount of internal system coins and debt that were destroyed [rad]
   */
  event SettleDebt(uint256 _rad);

  // --- Errors ---

  /// @notice Throws when trying to pull/give/take funds from/to the treasury itself
  error SFTreasury_AccountCannotBeTreasury();
  /// @notice Throws when trying to transfer surplus funds without having settled all debt
  error SFTreasury_OutstandingBadDebt();
  /// @notice Throws when trying to transfer more funds than the treasury has
  error SFTreasury_NotEnoughFunds();
  /// @notice Throws when trying to pull funds above the account's total allowance
  error SFTreasury_NotAllowed();
  /// @notice Throws when trying to pull funds above the account's per hour allowance
  error SFTreasury_PerHourLimitExceeded();
  /// @notice Throws when trying to pull funds to the accounting contract
  error SFTreasury_DstCannotBeAccounting();
  /// @notice Throws when trying to transfer a null amount of funds
  error SFTreasury_NullTransferAmount();
  /// @notice Throws when trying to pull funds while the coin balance is below the minimum threshold
  error SFTreasury_BelowPullFundsMinThreshold();
  /// @notice Throws when trying to transfer surplus funds before the cooldown period has passed
  error SFTreasury_TransferCooldownNotPassed();
  /// @notice Throws when trying to transfer surplus funds while the treasury is below capacity
  error SFTreasury_NotEnoughSurplus();

  // --- Structs ---

  struct StabilityFeeTreasuryParams {
    // Maximum amount of internal coins that the treasury can hold
    uint256 /* RAD     */ treasuryCapacity;
    // Minimum amount of internal coins that the treasury must hold in order to allow pulling funds
    uint256 /* RAD     */ pullFundsMinThreshold;
    // Minimum amount of time that must pass between surplus transfers
    uint256 /* seconds */ surplusTransferDelay;
  }

  struct Allowance {
    // Total allowance for the given account
    uint256 /* RAD */ total;
    // Per hour allowance for the given account
    uint256 /* RAD */ perHour;
  }

  /**
   * @notice Getter for the allowance struct of a given account
   * @param  _account The account to query
   * @return __allowance Data structure containing total and per hour allowance for the given account
   */
  function allowance(address _account) external view returns (Allowance memory __allowance);

  /**
   * @notice Getter for the unpacked allowance struct of a given account
   * @param  _account The account to query
   * @return _total Total allowance for the given account
   * @return _perHour Per hour allowance for the given account
   * @dev    A null per hour allowance means that the account has no per hour limit
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _allowance(address _account) external view returns (uint256 _total, uint256 _perHour);

  /**
   * @notice Modify an address' total allowance in order to withdraw SF from the treasury
   * @param  _account The approved address
   * @param  _rad The total approved amount of SF to withdraw [rad]
   */
  function setTotalAllowance(address _account, uint256 _rad) external;

  /**
   * @notice Modify an address' per hour allowance in order to withdraw SF from the treasury
   * @param  _account The approved address
   * @param  _rad The per hour approved amount of SF to withdraw [rad]
   */
  function setPerHourAllowance(address _account, uint256 _rad) external;

  /**
   * @notice Governance transfers SF to an address
   * @param  _account Address to transfer SF to
   * @param  _rad Amount of internal system coins to transfer [rad]
   */
  function giveFunds(address _account, uint256 _rad) external;

  /**
   * @notice Governance takes funds from an address
   * @param  _account Address to take system coins from
   * @param  _rad Amount of internal system coins to take from the account [rad]
   */
  function takeFunds(address _account, uint256 _rad) external;

  /**
   * @notice Pull stability fees from the treasury
   * @param  _dstAccount Address to transfer funds to
   * @param  _wad Amount of system coins (SF) to transfer [wad]
   * @dev    The caller of this method needs to have enough allowance in order to pull funds
   */
  function pullFunds(address _dstAccount, uint256 _wad) external;

  /**
   * @notice Transfer surplus stability fees to the extraSurplusReceiver. This is here to make sure that the treasury
   *         doesn't accumulate fees that it doesn't even need in order to pay for allowances. It ensures
   *         that there are enough funds left in the treasury to account for posterior expenses
   */
  function transferSurplusFunds() external;

  /**
   * @notice Settle as much bad debt as possible (if this contract has any)
   * @return _coinBalance Amount of internal system coins that this contract has after settling debt
   * @return _debtBalance Amount of bad debt that this contract has after settling debt
   */
  function settleDebt() external returns (uint256 _coinBalance, uint256 _debtBalance);

  // --- Registry ---

  /// @notice Address of the SAFEEngine contract
  function safeEngine() external view returns (ISAFEEngine _safeEngine);
  /// @notice Address of the CoinJoin contract
  function coinJoin() external view returns (ICoinJoin _coinJoin);
  /// @notice Address that receives surplus funds when treasury exceeds capacity (or is disabled)
  function extraSurplusReceiver() external view returns (address _extraSurplusReceiver);
  /// @notice Address of the SystemCoin contract
  function systemCoin() external view returns (ISystemCoin _systemCoin);

  // --- Data ---

  /// @notice Timestamp of the last time that surplus funds were transferred
  function latestSurplusTransferTime() external view returns (uint256 _latestSurplusTransferTime);

  /**
   * @notice Amount of internal coins a given account has pulled from the treasury in a given block hour
   * @param  _account The account to query
   * @param  _blockHour The block hour to query
   * @return _pulledPerHour Amount of coins pulled from the treasury by the account in the given block hour [rad]
   */
  function pulledPerHour(address _account, uint256 _blockHour) external view returns (uint256 _pulledPerHour);

  /**
   * @notice Getter for the contract parameters struct
   * @return _sfTreasuryParams StabilityFee parameters struct
   */
  function params() external view returns (StabilityFeeTreasuryParams memory _sfTreasuryParams);

  /**
   * @notice Getter for the unpacked contract parameters struct
   * @return _treasuryCapacity Maximum amount of internal coins that the treasury can hold [rad]
   * @return _pullFundsMinThreshold Minimum amount of internal coins that the treasury must hold in order to allow pulling funds [rad]
   * @return _surplusTransferDelay Minimum amount of time that must pass between surplus transfers [seconds]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _params()
    external
    view
    returns (uint256 _treasuryCapacity, uint256 _pullFundsMinThreshold, uint256 _surplusTransferDelay);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IJob} from '@interfaces/jobs/IJob.sol';
import {IStabilityFeeTreasury} from '@interfaces/IStabilityFeeTreasury.sol';

/**
 * @title  Job Abstract Contract
 * @notice This abstract contract is inherited by all jobs to add a reward modifier
 */
abstract contract Job is IJob {
  // --- Data ---

  /// @inheritdoc IJob
  uint256 public rewardAmount;

  // --- Registry ---

  /// @inheritdoc IJob
  IStabilityFeeTreasury public stabilityFeeTreasury;

  // --- Init ---

  /**
   *
   * @param  _stabilityFeeTreasury Address of the StabilityFeeTreasury contract
   * @param  _rewardAmount Amount of tokens to reward per job transaction [wad]
   */
  constructor(address _stabilityFeeTreasury, uint256 _rewardAmount) {
    stabilityFeeTreasury = IStabilityFeeTreasury(_stabilityFeeTreasury);
    rewardAmount = _rewardAmount;
  }

  // --- Reward ---

  /// @notice Modifier to reward the caller for calling the function
  modifier reward() {
    _;
    stabilityFeeTreasury.pullFunds(msg.sender, rewardAmount);
    emit Rewarded(msg.sender, rewardAmount);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

/**
 * @title  Authorizable
 * @notice Implements authorization control for contracts
 * @dev    Authorization control is boolean and handled by `onlyAuthorized` modifier
 */
abstract contract Authorizable is IAuthorizable {
  using EnumerableSet for EnumerableSet.AddressSet;

  // --- Data ---

  /// @notice EnumerableSet of authorized accounts
  EnumerableSet.AddressSet internal _authorizedAccounts;

  // --- Init ---

  /**
   * @param  _account Initial account to add authorization to
   */
  constructor(address _account) {
    _addAuthorization(_account);
  }

  // --- Views ---

  /**
   * @notice Checks whether an account is authorized
   * @return _authorized Whether the account is authorized or not
   */
  function authorizedAccounts(address _account) external view returns (bool _authorized) {
    return _isAuthorized(_account);
  }

  /**
   * @notice Getter for the authorized accounts
   * @return _accounts Array of authorized accounts
   */
  function authorizedAccounts() external view returns (address[] memory _accounts) {
    return _authorizedAccounts.values();
  }

  // --- Methods ---

  /**
   * @notice Add auth to an account
   * @param  _account Account to add auth to
   */
  function addAuthorization(address _account) external virtual isAuthorized {
    _addAuthorization(_account);
  }

  /**
   * @notice Remove auth from an account
   * @param  _account Account to remove auth from
   */
  function removeAuthorization(address _account) external virtual isAuthorized {
    _removeAuthorization(_account);
  }

  // --- Internal methods ---
  function _addAuthorization(address _account) internal {
    if (_authorizedAccounts.add(_account)) {
      emit AddAuthorization(_account);
    } else {
      revert AlreadyAuthorized();
    }
  }

  function _removeAuthorization(address _account) internal {
    if (_authorizedAccounts.remove(_account)) {
      emit RemoveAuthorization(_account);
    } else {
      revert NotAuthorized();
    }
  }

  function _isAuthorized(address _account) internal view virtual returns (bool _authorized) {
    return _authorizedAccounts.contains(_account);
  }

  // --- Modifiers ---

  /**
   * @notice Checks whether msg.sender can call an authed function
   * @dev    Will revert with `Unauthorized` if the sender is not authorized
   */
  modifier isAuthorized() {
    if (!_isAuthorized(msg.sender)) revert Unauthorized();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IModifiable} from '@interfaces/utils/IModifiable.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';

/**
 * @title  Modifiable
 * @notice Allows inheriting contracts to modify parameters values
 * @dev    Requires inheriting contracts to override `_modifyParameters` virtual methods
 */
abstract contract Modifiable is IModifiable, Authorizable {
  // --- Constants ---

  /// @dev Used to emit a global parameter modification event
  bytes32 internal constant _GLOBAL_PARAM = bytes32(0);

  // --- External methods ---

  /// @inheritdoc IModifiable
  function modifyParameters(bytes32 _param, bytes memory _data) external isAuthorized validParams {
    _modifyParameters(_param, _data);
    emit ModifyParameters(_param, _GLOBAL_PARAM, _data);
  }

  /// @inheritdoc IModifiable
  function modifyParameters(
    bytes32 _cType,
    bytes32 _param,
    bytes memory _data
  ) external isAuthorized validCParams(_cType) {
    _modifyParameters(_cType, _param, _data);
    emit ModifyParameters(_param, _cType, _data);
  }

  // --- Internal virtual methods ---

  /**
   * @notice Internal function to be overriden with custom logic to modify parameters
   * @dev    This function is set to revert if not overriden
   */
  // solhint-disable-next-line no-unused-vars
  function _modifyParameters(bytes32 _param, bytes memory _data) internal virtual {
    revert UnrecognizedParam();
  }

  /**
   * @notice Internal function to be overriden with custom logic to modify collateral parameters
   * @dev    This function is set to revert if not overriden
   */
  // solhint-disable-next-line no-unused-vars
  function _modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) internal virtual {
    revert UnrecognizedParam();
  }

  /// @notice Internal function to be overriden with custom logic to validate parameters
  function _validateParameters() internal view virtual {}

  /// @notice Internal function to be overriden with custom logic to validate collateral parameters
  function _validateCParameters(bytes32 _cType) internal view virtual {}

  // --- Modifiers ---

  /// @notice Triggers a routine to validate parameters after a modification
  modifier validParams() {
    _;
    _validateParameters();
  }

  /// @notice Triggers a routine to validate collateral parameters after a modification
  modifier validCParams(bytes32 _cType) {
    _;
    _validateCParameters(_cType);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title Encoding
 * @notice This library contains functions for decoding data into common types
 */
library Encoding {
  // --- Methods ---

  /// @dev Decodes a bytes array into a uint256
  function toUint256(bytes memory _data) internal pure returns (uint256 _uint256) {
    assembly {
      _uint256 := mload(add(_data, 0x20))
    }
  }

  /// @dev Decodes a bytes array into an int256
  function toInt256(bytes memory _data) internal pure returns (int256 _int256) {
    assembly {
      _int256 := mload(add(_data, 0x20))
    }
  }

  /// @dev Decodes a bytes array into an address
  function toAddress(bytes memory _data) internal pure returns (address _address) {
    assembly {
      _address := mload(add(_data, 0x20))
    }
  }

  /// @dev Decodes a bytes array into a bool
  function toBool(bytes memory _data) internal pure returns (bool _bool) {
    assembly {
      _bool := mload(add(_data, 0x20))
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IStabilityFeeTreasury} from '@interfaces/IStabilityFeeTreasury.sol';

interface IJob {
  // --- Events ---

  /**
   * @notice Emitted when a reward is issued
   * @param _rewardedAccount Account that received the reward
   * @param _rewardAmount Amount of reward issued [wad]
   */
  event Rewarded(address _rewardedAccount, uint256 _rewardAmount);

  // --- Errors ---

  /// @notice Throws when trying to call a not-workable job function
  error NotWorkable();

  // --- Data ---

  /// @notice Amount of tokens to reward per job transaction [wad]
  function rewardAmount() external view returns (uint256 _rewardAmount);

  // --- Registry ---

  /// @notice Address of the StabilityFeeTreasury contract
  function stabilityFeeTreasury() external view returns (IStabilityFeeTreasury _stabilityFeeTreasury);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IAuthorizable {
  // --- Events ---

  /**
   * @notice Emitted when an account is authorized
   * @param _account Account that is authorized
   */
  event AddAuthorization(address _account);

  /**
   * @notice Emitted when an account is unauthorized
   * @param _account Account that is unauthorized
   */
  event RemoveAuthorization(address _account);

  // --- Errors ---
  /// @notice Throws if the account is already authorized on `addAuthorization`
  error AlreadyAuthorized();
  /// @notice Throws if the account is not authorized on `removeAuthorization`
  error NotAuthorized();
  /// @notice Throws if the account is not authorized and tries to call an `onlyAuthorized` method
  error Unauthorized();

  // --- Data ---

  /**
   * @notice Checks whether an account is authorized on the contract
   * @param  _account Account to check
   * @return _authorized Whether the account is authorized or not
   */
  function authorizedAccounts(address _account) external view returns (bool _authorized);

  /**
   * @notice Getter for the authorized accounts
   * @return _accounts Array of authorized accounts
   */
  function authorizedAccounts() external view returns (address[] memory _accounts);

  // --- Administration ---

  /**
   * @notice Add authorization to an account
   * @param  _account Account to add authorization to
   * @dev    Method will revert if the account is already authorized
   */
  function addAuthorization(address _account) external;

  /**
   * @notice Remove authorization from an account
   * @param  _account Account to remove authorization from
   * @dev    Method will revert if the account is not authorized
   */
  function removeAuthorization(address _account) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface IModifiable is IAuthorizable {
  // --- Events ---
  /// @dev Event topic 1 is always a parameter, topic 2 can be empty (global params)
  event ModifyParameters(bytes32 indexed _param, bytes32 indexed _cType, bytes _data);

  // --- Errors ---
  error UnrecognizedParam();
  error UnrecognizedCType();

  // --- Administration ---
  /**
   * @notice Set a new value for a global specific parameter
   * @param _param String identifier of the parameter to modify
   * @param _data Encoded data to modify the parameter
   */
  function modifyParameters(bytes32 _param, bytes memory _data) external;

  /**
   * @notice Set a new value for a collateral specific parameter
   * @param _cType String identifier of the collateral to modify
   * @param _param String identifier of the parameter to modify
   * @param _data Encoded data to modify the parameter
   */
  function modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

/**
 * @title IBaseOracle
 * @notice Basic interface for a system price feed
 *         All price feeds should be translated into an 18 decimals format
 */
interface IBaseOracle {
  // --- Errors ---
  error InvalidPriceFeed();

  /**
   * @notice Symbol of the quote: token / baseToken (e.g. 'ETH / USD')
   */
  function symbol() external view returns (string memory _symbol);

  /**
   * @notice Fetch the latest oracle result and whether it is valid or not
   * @dev    This method should never revert
   */
  function getResultWithValidity() external view returns (uint256 _result, bool _validity);

  /**
   * @notice Fetch the latest oracle result
   * @dev    Will revert if is the price feed is invalid
   */
  function read() external view returns (uint256 _value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface ISAFEEngine is IAuthorizable, IModifiable, IDisableable {
  // --- Events ---

  /**
   * @notice Emitted when an address authorizes another address to modify its SAFE
   * @param _sender Address that sent the authorization
   * @param _account Address that is authorized to modify the SAFE
   */
  event ApproveSAFEModification(address _sender, address _account);

  /**
   * @notice Emitted when an address denies another address to modify its SAFE
   * @param _sender Address that sent the denial
   * @param _account Address that is denied to modify the SAFE
   */
  event DenySAFEModification(address _sender, address _account);

  /**
   * @notice Emitted when a new collateral type is registered
   * @param _cType Bytes32 representation of the collateral type
   */
  event InitializeCollateralType(bytes32 _cType);

  /**
   * @notice Emitted when collateral is transferred between accounts
   * @param _cType Bytes32 representation of the collateral type
   * @param _src Address that sent the collateral
   * @param _dst Address that received the collateral
   * @param _wad Amount of collateral transferred
   */
  event TransferCollateral(bytes32 indexed _cType, address indexed _src, address indexed _dst, uint256 _wad);

  /**
   * @notice Emitted when internal coins are transferred between accounts
   * @param _src Address that sent the coins
   * @param _dst Address that received the coins
   * @param _rad Amount of coins transferred
   */
  event TransferInternalCoins(address indexed _src, address indexed _dst, uint256 _rad);

  /**
   * @notice Emitted when the SAFE state is modified by the owner or authorized accounts
   * @param _cType Bytes32 representation of the collateral type
   * @param _safe Address of the SAFE
   * @param _collateralSource Address that sent/receives the collateral
   * @param _debtDestination Address that sent/receives the debt
   * @param _deltaCollateral Amount of collateral added/extracted from the SAFE [wad]
   * @param _deltaDebt Amount of debt to generate/repay [wad]
   */
  event ModifySAFECollateralization(
    bytes32 indexed _cType,
    address indexed _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  );

  /**
   * @notice Emitted when collateral and/or debt is transferred between SAFEs
   * @param _cType Bytes32 representation of the collateral type
   * @param _src Address that sent the collateral
   * @param _dst Address that received the collateral
   * @param _deltaCollateral Amount of collateral to take/add into src and give/take from dst [wad]
   * @param _deltaDebt Amount of debt to take/add into src and give/take from dst [wad]
   */
  event TransferSAFECollateralAndDebt(
    bytes32 indexed _cType, address indexed _src, address indexed _dst, int256 _deltaCollateral, int256 _deltaDebt
  );

  /**
   * @notice Emitted when collateral and debt is confiscated from a SAFE
   * @param _cType Bytes32 representation of the collateral type
   * @param _safe Address of the SAFE
   * @param _collateralSource Address that sent/receives the collateral
   * @param _debtDestination Address that sent/receives the debt
   * @param _deltaCollateral Amount of collateral added/extracted from the SAFE [wad]
   * @param _deltaDebt Amount of debt to generate/repay [wad]
   */
  event ConfiscateSAFECollateralAndDebt(
    bytes32 indexed _cType,
    address indexed _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  );

  /**
   * @notice Emitted when an account's debt is settled with coins
   * @dev    Accounts (not SAFEs) can only settle unbacked debt
   * @param _account Address of the account
   * @param _rad Amount of debt & coins to destroy
   */
  event SettleDebt(address indexed _account, uint256 _rad);

  /**
   * @notice Emitted when an unbacked debt is created to an account
   * @param _debtDestination Address that received the newly created debt
   * @param _coinDestination Address that received the newly created coins
   * @param _rad Amount of debt to create
   */
  event CreateUnbackedDebt(address indexed _debtDestination, address indexed _coinDestination, uint256 _rad);

  /**
   * @notice Emit when the accumulated rate of a collateral type is updated
   * @param _cType Bytes32 representation of the collateral type
   * @param _surplusDst Address that received the newly created surplus
   * @param _rateMultiplier Delta of the accumulated rate [ray]
   */
  event UpdateAccumulatedRate(bytes32 indexed _cType, address _surplusDst, int256 _rateMultiplier);

  /**
   * @notice Emitted when the safety price and liquidation price of a collateral type is updated
   * @param _cType Bytes32 representation of the collateral type
   * @param _safetyPrice New price at which a SAFE is allowed to generate debt [ray]
   * @param _liquidationPrice New price at which a SAFE gets liquidated [ray]
   */
  event UpdateCollateralPrice(bytes32 indexed _cType, uint256 _safetyPrice, uint256 _liquidationPrice);

  // --- Errors ---

  /// @notice Throws when trying to initialize a collateral type that already exists
  error SAFEEng_CollateralTypeAlreadyExists();
  /// @notice Throws when trying to modify parameters of an uninitialized collateral type
  error SAFEEng_CollateralTypeNotInitialized();
  /// @notice Throws when trying to modify a SAFE into an unsafe state
  error SAFEEng_SAFENotSafe();
  /// @notice Throws when trying to modify a SAFE into a dusty safe (debt non-zero and below `debtFloor`)
  error SAFEEng_DustySAFE();
  /// @notice Throws when trying to generate debt that would put the system over the global debt ceiling
  error SAFEEng_GlobalDebtCeilingHit();
  /// @notice Throws when trying to generate debt that would put the system over the collateral debt ceiling
  error SAFEEng_CollateralDebtCeilingHit();
  /// @notice Throws when trying to generate debt that would put the SAFE over the SAFE debt ceiling
  error SAFEEng_SAFEDebtCeilingHit();
  /// @notice Throws when an account tries to modify a SAFE without the proper permissions
  error SAFEEng_NotSAFEAllowed();
  /// @notice Throws when an account tries to pull collateral from a SAFE without the proper permissions
  error SAFEEng_NotCollateralSrcAllowed();
  /// @notice Throws when an account tries to push debt to a SAFE without the proper permissions
  error SAFEEng_NotDebtDstAllowed();

  // --- Structs ---

  struct SAFE {
    // Total amount of collateral locked in a SAFE
    uint256 /* WAD */ lockedCollateral;
    // Total amount of debt generated by a SAFE
    uint256 /* WAD */ generatedDebt;
  }

  struct SAFEEngineParams {
    // Total amount of debt that a single safe can generate
    uint256 /* WAD */ safeDebtCeiling;
    // Maximum amount of debt that can be issued across all safes
    uint256 /* RAD */ globalDebtCeiling;
  }

  struct SAFEEngineCollateralData {
    // Total amount of debt issued by the collateral type
    uint256 /* WAD */ debtAmount;
    // Total amount of collateral locked in SAFEs using the collateral type
    uint256 /* WAD */ lockedAmount;
    // Accumulated rate of the collateral type
    uint256 /* RAY */ accumulatedRate;
    // Floor price at which a SAFE is allowed to generate debt
    uint256 /* RAY */ safetyPrice;
    // Price at which a SAFE gets liquidated
    uint256 /* RAY */ liquidationPrice;
  }

  struct SAFEEngineCollateralParams {
    // Maximum amount of debt that can be generated with the collateral type
    uint256 /* RAD */ debtCeiling;
    // Minimum amount of debt that must be generated by a SAFE using the collateral
    uint256 /* RAD */ debtFloor;
  }

  // --- Data ---

  /**
   * @notice Getter for the contract parameters struct
   * @dev    Returns a SAFEEngineParams struct
   */
  function params() external view returns (SAFEEngineParams memory _safeEngineParams);

  /**
   * @notice Getter for the unpacked contract parameters struct
   * @return _safeDebtCeiling Total amount of debt that a single safe can generate [wad]
   * @return _globalDebtCeiling Maximum amount of debt that can be issued [rad]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _params() external view returns (uint256 _safeDebtCeiling, uint256 _globalDebtCeiling);

  /**
   * @notice Getter for the collateral parameters struct
   * @param  _cType Bytes32 representation of the collateral type
   * @dev    Returns a SAFEEngineCollateralParams struct
   */
  function cParams(bytes32 _cType) external view returns (SAFEEngineCollateralParams memory _safeEngineCParams);

  /**
   * @notice Getter for the unpacked collateral parameters struct
   * @param  _cType Bytes32 representation of the collateral type
   * @return _debtCeiling Maximum amount of debt that can be generated with this collateral type
   * @return _debtFloor Minimum amount of debt that must be generated by a SAFE using this collateral
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _cParams(bytes32 _cType) external view returns (uint256 _debtCeiling, uint256 _debtFloor);

  /**
   * @notice Getter for the collateral data struct
   * @param  _cType Bytes32 representation of the collateral type
   * @dev    Returns a SAFEEngineCollateralData struct
   */
  function cData(bytes32 _cType) external view returns (SAFEEngineCollateralData memory _safeEngineCData);

  /**
   * @notice Getter for the unpacked collateral data struct
   * @param  _cType Bytes32 representation of the collateral type
   * @return _debtAmount Total amount of debt issued by a collateral type [wad]
   * @return _lockedAmount Total amount of collateral locked in a SAFE [wad]
   * @return _accumulatedRate Accumulated rate of a collateral type [ray]
   * @return _safetyPrice Floor price at which a SAFE is allowed to generate debt [ray]
   * @return _liquidationPrice Price at which a SAFE gets liquidated [ray]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _cData(bytes32 _cType)
    external
    view
    returns (
      uint256 _debtAmount,
      uint256 _lockedAmount,
      uint256 _accumulatedRate,
      uint256 _safetyPrice,
      uint256 _liquidationPrice
    );

  /**
   * @notice Data about each SAFE
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _safeAddress Address of the SAFE
   * @dev    Returns a SAFE struct
   */
  function safes(bytes32 _cType, address _safeAddress) external view returns (SAFE memory _safeData);

  /**
   * @notice Unpacked data about each SAFE
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _safeAddress Address of the SAFE
   * @return _lockedCollateral Total amount of collateral locked in a SAFE [wad]
   * @return _generatedDebt Total amount of debt generated by a SAFE [wad]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _safes(
    bytes32 _cType,
    address _safeAddress
  ) external view returns (uint256 _lockedCollateral, uint256 _generatedDebt);

  /**
   * @notice Who can transfer collateral & debt in/out of a SAFE
   * @param  _caller Address to check for SAFE permissions for
   * @param  _account Account to check if caller has permissions for
   * @return _safeRights Numerical representation of the SAFE rights (0/1)
   */
  function safeRights(address _caller, address _account) external view returns (uint256 _safeRights);

  // --- Balances ---

  /**
   * @notice Balance of each collateral type
   * @param  _cType Bytes32 representation of the collateral type to check balance for
   * @param  _account Account to check balance for
   * @return _collateralBalance Collateral balance of the account [wad]
   */
  function tokenCollateral(bytes32 _cType, address _account) external view returns (uint256 _collateralBalance);

  /**
   * @notice Internal balance of system coins held by an account
   * @param  _account Account to check balance for
   * @return _balance Internal coin balance of the account [rad]
   */
  function coinBalance(address _account) external view returns (uint256 _balance);

  /**
   * @notice Amount of debt held by an account
   * @param  _account Account to check balance for
   * @return _debtBalance Debt balance of the account [rad]
   */
  function debtBalance(address _account) external view returns (uint256 _debtBalance);

  /**
   * @notice Total amount of debt (coins) currently issued
   * @dev    Returns the global debt [rad]
   */
  function globalDebt() external returns (uint256 _globalDebt);

  /**
   * @notice 'Bad' debt that's not covered by collateral
   * @dev    Returns the global unbacked debt [rad]
   */
  function globalUnbackedDebt() external view returns (uint256 _globalUnbackedDebt);

  // --- Init ---

  /**
   * @notice Register a new collateral type in the SAFEEngine
   * @param _cType Collateral type to register
   * @param _collateralParams Collateral parameters
   */
  function initializeCollateralType(bytes32 _cType, SAFEEngineCollateralParams memory _collateralParams) external;

  // --- Fungibility ---

  /**
   * @notice Transfer collateral between accounts
   * @param _cType Collateral type transferred
   * @param _source Collateral source
   * @param _destination Collateral destination
   * @param _wad Amount of collateral transferred
   */
  function transferCollateral(bytes32 _cType, address _source, address _destination, uint256 _wad) external;

  /**
   * @notice Transfer internal coins (does not affect external balances from Coin.sol)
   * @param  _source Coins source
   * @param  _destination Coins destination
   * @param  _rad Amount of coins transferred
   */
  function transferInternalCoins(address _source, address _destination, uint256 _rad) external;

  /**
   * @notice Join/exit collateral into and and out of the system
   * @param _cType Collateral type to join/exit
   * @param _account Account that gets credited/debited
   * @param _wad Amount of collateral
   */
  function modifyCollateralBalance(bytes32 _cType, address _account, int256 _wad) external;

  // --- SAFE Manipulation ---

  /**
   * @notice Add/remove collateral or put back/generate more debt in a SAFE
   * @param _cType Type of collateral to withdraw/deposit in and from the SAFE
   * @param _safe Target SAFE
   * @param _collateralSource Account we take collateral from/put collateral into
   * @param _debtDestination Account from which we credit/debit coins and debt
   * @param _deltaCollateral Amount of collateral added/extracted from the SAFE [wad]
   * @param _deltaDebt Amount of debt to generate/repay [wad]
   */
  function modifySAFECollateralization(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 /* WAD */ _deltaCollateral,
    int256 /* WAD */ _deltaDebt
  ) external;

  // --- SAFE Fungibility ---

  /**
   * @notice Transfer collateral and/or debt between SAFEs
   * @param _cType Collateral type transferred between SAFEs
   * @param _src Source SAFE
   * @param _dst Destination SAFE
   * @param _deltaCollateral Amount of collateral to take/add into src and give/take from dst [wad]
   * @param _deltaDebt Amount of debt to take/add into src and give/take from dst [wad]
   */
  function transferSAFECollateralAndDebt(
    bytes32 _cType,
    address _src,
    address _dst,
    int256 /* WAD */ _deltaCollateral,
    int256 /* WAD */ _deltaDebt
  ) external;

  // --- SAFE Confiscation ---

  /**
   * @notice Normally used by the LiquidationEngine in order to confiscate collateral and
   *      debt from a SAFE and give them to someone else
   * @param _cType Collateral type the SAFE has locked inside
   * @param _safe Target SAFE
   * @param _collateralSource Who we take/give collateral to
   * @param _debtDestination Who we take/give debt to
   * @param _deltaCollateral Amount of collateral taken/added into the SAFE [wad]
   * @param _deltaDebt Amount of debt taken/added into the SAFE [wad]
   */
  function confiscateSAFECollateralAndDebt(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) external;

  // --- Settlement ---

  /**
   * @notice Nullify an amount of coins with an equal amount of debt
   * @dev    Coins & debt are like matter and antimatter, they nullify each other
   * @param  _rad Amount of debt & coins to destroy
   */
  function settleDebt(uint256 _rad) external;

  /**
   * @notice Allows an authorized contract to create debt without collateral
   * @param _debtDestination The account that will receive the newly created debt
   * @param _coinDestination The account that will receive the newly created coins
   * @param _rad Amount of debt to create
   * @dev   Usually called by DebtAuctionHouse in order to terminate auctions prematurely post settlement
   */
  function createUnbackedDebt(address _debtDestination, address _coinDestination, uint256 _rad) external;

  // --- Update ---

  /**
   * @notice Allows an authorized contract to accrue interest on a specific collateral type
   * @param _cType Collateral type we accrue interest for
   * @param _surplusDst Destination for the newly created surplus
   * @param _rateMultiplier Multiplier applied to the debtAmount in order to calculate the surplus [ray]
   * @dev   The rateMultiplier is usually calculated by the TaxCollector contract
   */
  function updateAccumulatedRate(bytes32 _cType, address _surplusDst, int256 _rateMultiplier) external;

  /**
   * @notice Allows an authorized contract to update the safety price and liquidation price of a collateral type
   * @param _cType Collateral type we update the prices for
   * @param _safetyPrice New safety price [ray]
   * @param _liquidationPrice New liquidation price [ray]
   */
  function updateCollateralPrice(bytes32 _cType, uint256 _safetyPrice, uint256 _liquidationPrice) external;

  // --- Authorization ---

  /**
   * @notice Allow an address to modify your SAFE
   * @param _account Account to give SAFE permissions to
   */
  function approveSAFEModification(address _account) external;

  /**
   * @notice Deny an address the rights to modify your SAFE
   * @param _account Account that is denied SAFE permissions
   */
  function denySAFEModification(address _account) external;

  /**
   * @notice Checks whether msg.sender has the right to modify a SAFE
   */
  function canModifySAFE(address _safe, address _account) external view returns (bool _allowed);

  // --- Views ---

  /**
   * @notice List all collateral types registered in the SAFEEngine
   */
  function collateralList() external view returns (bytes32[] memory __collateralList);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface IDisableable is IAuthorizable {
  // --- Events ---

  /// @notice Emitted when the inheriting contract is disabled
  event DisableContract();

  // --- Errors ---

  /// @notice Throws when trying to call a `whenDisabled` method when the contract is enabled
  error ContractIsEnabled();
  /// @notice Throws when trying to call a `whenEnabled` method when the contract is disabled
  error ContractIsDisabled();
  /// @notice Throws when trying to disable a contract that cannot be disabled
  error NonDisableable();

  // --- Data ---

  /**
   * @notice Check if the contract is enabled
   * @return _contractEnabled True if the contract is enabled
   */
  function contractEnabled() external view returns (bool _contractEnabled);

  // --- Methods ---

  /**
   * @notice External method to trigger the contract disablement
   * @dev    Triggers an internal call to `_onContractDisable` virtual method
   */
  function disableContract() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface IPIDController is IAuthorizable, IModifiable {
  // --- Events ---

  /**
   * @notice Emitted when the state of the controller is updated
   * @param _proportionalDeviation The new proportional term
   * @param _integralDeviation The new integral term
   * @param _deltaIntegralDeviation The delta between the new and the previous integral term
   */
  event UpdateDeviation(int256 _proportionalDeviation, int256 _integralDeviation, int256 _deltaIntegralDeviation);

  // --- Errors ---

  /// @notice Throws if the caller of `updateRate` is not the seed proposer
  error PIDController_OnlySeedProposer();
  /// @notice Throws if the call to `updateRate` is too soon since last update
  error PIDController_ComputeRateCooldown();
  /// @notice Throws when trying to set the integral term with the integral gain set on
  error PIDController_CannotSetPriceDeviationCumulative();

  // --- Structs ---

  struct PIDControllerParams {
    // The minimum delay between two computeRate calls
    uint256 /* seconds */ integralPeriodSize;
    // The per second leak applied to priceDeviationCumulative before the latest deviation is added
    uint256 /* RAY     */ perSecondCumulativeLeak;
    // The minimum percentage deviation from the redemption price that allows the contract to calculate a non null redemption rate
    uint256 /* WAD     */ noiseBarrier;
    // The maximum value allowed for the redemption rate
    uint256 /* RAY     */ feedbackOutputUpperBound;
    // The minimum value allowed for the redemption rate
    int256 /*  RAY     */ feedbackOutputLowerBound;
  }

  struct DeviationObservation {
    // The timestamp when this observation was stored
    uint256 timestamp;
    // The proportional term stored in this observation
    int256 proportional;
    // The integral term stored in this observation
    int256 integral;
  }

  struct ControllerGains {
    // This value is multiplied with the proportional term
    int256 /* WAD */ kp;
    // This value is multiplied with priceDeviationCumulative
    int256 /* WAD */ ki;
  }

  // --- Registry ---

  /**
   * @notice Returns the address allowed to call computeRate method
   */
  function seedProposer() external view returns (address _seedProposer);

  // --- Data ---

  /**
   * @notice Getter for the contract parameters struct
   * @return _pidParams The PID controller parameters struct
   */
  function params() external view returns (PIDControllerParams memory _pidParams);

  /**
   * @notice Getter for the unpacked contract parameters struct
   * @return _integralPeriodSize The minimum delay between two computeRate calls
   * @return _perSecondCumulativeLeak The per second leak applied to priceDeviationCumulative before the latest deviation is added [ray]
   * @return _noiseBarrier The minimum percentage deviation from the redemption price that allows the contract to calculate a non null redemption rate [wad]
   * @return _feedbackOutputUpperBound The maximum value allowed for the redemption rate [ray]
   * @return _feedbackOutputLowerBound The minimum value allowed for the redemption rate [ray]
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _params()
    external
    view
    returns (
      uint256 _integralPeriodSize,
      uint256 _perSecondCumulativeLeak,
      uint256 _noiseBarrier,
      uint256 _feedbackOutputUpperBound,
      int256 _feedbackOutputLowerBound
    );

  /**
   * @notice Returns the last deviation observation, containing latest timestamp, proportional and integral terms
   * @return __deviationObservation The last deviation observation struct
   */
  function deviationObservation() external view returns (DeviationObservation memory __deviationObservation);

  /**
   * @notice Raw data about the last deviation observation
   * @return _timestamp The timestamp when this observation was stored
   * @return _proportional The proportional term stored in this observation
   * @return _integral The integral term stored in this observation
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _deviationObservation() external view returns (uint256 _timestamp, int256 _proportional, int256 _integral);

  /**
   * @notice Returns the Kp and Ki values used in this calculator
   * @dev    The values are expressed in WAD, Kp stands for proportional and Ki for integral terms
   */
  function controllerGains() external view returns (ControllerGains memory _cGains);

  /**
   * @notice Raw data about the Kp and Ki values used in this calculator
   * @return _kp This value is multiplied with the proportional term
   * @return _ki This value is multiplied with priceDeviationCumulative
   */
  // solhint-disable-next-line private-vars-leading-underscore
  function _controllerGains() external view returns (int256 _kp, int256 _ki);

  /**
   * @notice Return a redemption rate bounded by feedbackOutputLowerBound and feedbackOutputUpperBound as well as the
   *         timeline over which that rate will take effect
   * @param  _piOutput The raw redemption rate computed from the proportional and integral terms
   * @return _redemptionRate The bounded redemption rate
   */
  function getBoundedRedemptionRate(int256 _piOutput) external view returns (uint256 _redemptionRate);

  /**
   * @notice Compute a new redemption rate
   * @param  _marketPrice The system coin market price
   * @param  _redemptionPrice The system coin redemption price
   * @return _redemptionRate The computed redemption rate
   */
  function computeRate(uint256 _marketPrice, uint256 _redemptionPrice) external returns (uint256 _redemptionRate);

  /**
   * @notice Apply Kp to the proportional term and Ki to the integral term (by multiplication) and then sum P and I
   * @param  _proportionalTerm The proportional term
   * @param  _integralTerm The integral term
   * @return _piOutput The sum of P and I
   */
  function getGainAdjustedPIOutput(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) external view returns (int256 _piOutput);

  /**
   * @notice Independently return and calculate P * Kp and I * Ki
   * @param  _proportionalTerm The proportional term
   * @param  _integralTerm The integral term
   * @return _proportionalGain The proportional gain
   * @return _integralGain The integral gain
   */
  function getGainAdjustedTerms(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) external view returns (int256 _proportionalGain, int256 _integralGain);

  /**
   * @notice Compute a new priceDeviationCumulative (integral term)
   * @param  _proportionalTerm The proportional term (redemptionPrice - marketPrice)
   * @param  _accumulatedLeak The total leak applied to priceDeviationCumulative before it is summed with the new time adjusted deviation
   * @return _priceDeviationCumulative The new priceDeviationCumulative
   * @return _timeAdjustedDeviation The new time adjusted deviation
   */
  function getNextDeviationCumulative(
    int256 _proportionalTerm,
    uint256 _accumulatedLeak
  ) external returns (int256 _priceDeviationCumulative, int256 _timeAdjustedDeviation);

  /**
   * @notice Returns whether the P + I sum exceeds the noise barrier
   * @param  _piSum Represents a sum between P + I
   * @param  _redemptionPrice The system coin redemption price
   * @return _breaksNb Whether the P + I sum exceeds the noise barrier
   */
  function breaksNoiseBarrier(uint256 _piSum, uint256 _redemptionPrice) external view returns (bool _breaksNb);

  /**
   * @notice Compute and return the upcoming redemption rate
   * @param _marketPrice The system coin market price
   * @param _redemptionPrice The system coin redemption price
   * @param _accumulatedLeak The total leak applied to priceDeviationCumulative before it is summed with the proportionalTerm
   * @return _redemptionRate The upcoming redemption rate
   * @return _proportionalTerm The upcoming proportional term
   * @return _integralTerm The upcoming integral term
   */
  function getNextRedemptionRate(
    uint256 _marketPrice,
    uint256 _redemptionPrice,
    uint256 _accumulatedLeak
  ) external view returns (uint256 _redemptionRate, int256 _proportionalTerm, int256 _integralTerm);

  /**
   * @notice Returns the time elapsed since the last computeRate call
   */
  function timeSinceLastUpdate() external view returns (uint256 _timeSinceLastValue);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {ISystemCoin} from '@interfaces/tokens/ISystemCoin.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface ICoinJoin is IAuthorizable, IDisableable {
  // --- Events ---

  /**
   * @notice Emitted when an account joins coins into the system
   * @param _sender Address of the account that called the function (sent the ERC20 coins)
   * @param _account Address of the account that received the coins
   * @param _wad Amount of coins joined [wad]
   */
  event Join(address _sender, address _account, uint256 _wad);

  /**
   * @notice Emitted when an account exits coins from the system
   * @param _sender Address of the account that called the function (sent the internal coins)
   * @param _account Address of the account that received the ERC20 coins
   * @param _wad Amount of coins exited [wad]
   */
  event Exit(address _sender, address _account, uint256 _wad);

  // --- Registry ---

  /// @notice Address of the SAFEEngine contract
  function safeEngine() external view returns (ISAFEEngine _safeEngine);
  /// @notice Address of the SystemCoin contract
  function systemCoin() external view returns (ISystemCoin _systemCoin);

  // --- Data ---

  /// @notice Number of decimals the coin has
  function decimals() external view returns (uint256 _decimals);

  // --- Methods ---

  /**
   * @notice Join system coins in the system
   * @param _account Account that will receive the joined coins
   * @param _wad Amount of external coins to join [wad]
   * @dev    Exited coins have 18 decimals but inside the system they have 45 [rad] decimals.
   *         When we join, the amount [wad] is multiplied by 10**27 [ray]
   */
  function join(address _account, uint256 _wad) external;

  /**
   * @notice Exit system coins from the system
   * @dev    New coins cannot be minted after the system is disabled
   * @param _account Account that will receive the exited coins
   * @param _wad Amount of internal coins to join (18 decimal number)
   * @dev    Inside the system, coins have 45 decimals [rad] but outside of it they have 18 decimals [wad].
   *         When we exit, we specify a wad amount of coins and then the contract automatically multiplies
   *         wad by 10**27 to move the correct 45 decimal coin amount to this adapter
   */
  function exit(address _account, uint256 _wad) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from '@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol';
import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface ISystemCoin is IERC20Metadata, IAuthorizable {
  /**
   * @notice Mint an amount of tokens to an account
   * @param _account Address of the account to mint tokens to
   * @param _amount Amount of tokens to mint [wad]
   * @dev   Only authorized addresses can mint tokens
   */
  function mint(address _account, uint256 _amount) external;

  /**
   * @notice Burn an amount of tokens from an account
   * @param _account Address of the account to burn tokens from
   * @param _amount Amount of tokens to burn [wad]
   * @dev   Only authorized addresses can burn tokens from an account
   */
  function burn(address _account, uint256 _amount) external;

  /**
   * @notice Burn an amount of tokens from the sender
   * @param _amount Amount of tokens to burn [wad]
   */
  function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}