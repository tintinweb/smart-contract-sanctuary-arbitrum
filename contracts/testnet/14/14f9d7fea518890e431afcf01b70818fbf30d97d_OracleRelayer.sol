// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';
import {IOracleRelayer} from '@interfaces/IOracleRelayer.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';
import {Modifiable} from '@contracts/utils/Modifiable.sol';
import {Disableable} from '@contracts/utils/Disableable.sol';

import {Encoding} from '@libraries/Encoding.sol';
import {Assertions} from '@libraries/Assertions.sol';
import {Math, RAY, WAD} from '@libraries/Math.sol';
import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

contract OracleRelayer is Authorizable, Modifiable, Disableable, IOracleRelayer {
  using Encoding for bytes;
  using Math for uint256;
  using Assertions for uint256;
  using Assertions for address;
  using EnumerableSet for EnumerableSet.Bytes32Set;

  // --- Registry ---
  ISAFEEngine public safeEngine;
  IBaseOracle public systemCoinOracle;

  // --- Params ---
  // solhint-disable-next-line private-vars-leading-underscore
  OracleRelayerParams public _params;
  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 => OracleRelayerCollateralParams) public _cParams;

  function params() external view override returns (OracleRelayerParams memory _oracleRelayerParams) {
    return _params;
  }

  function cParams(bytes32 _cType) external view returns (OracleRelayerCollateralParams memory _oracleRelayerCParams) {
    return _cParams[_cType];
  }

  EnumerableSet.Bytes32Set internal _collateralList;

  // Virtual redemption price (not the most updated value)
  uint256 internal _redemptionPrice; // [ray]
  // The force that changes the system users' incentives by changing the redemption price
  uint256 public redemptionRate; // [ray]
  // Last time when the redemption price was changed
  uint256 public redemptionPriceUpdateTime; // [unix epoch time]

  // --- Init ---
  constructor(
    address _safeEngine,
    IBaseOracle _systemCoinOracle,
    OracleRelayerParams memory _oracleRelayerParams
  ) Authorizable(msg.sender) validParams {
    safeEngine = ISAFEEngine(_safeEngine.assertNonNull());
    systemCoinOracle = _systemCoinOracle;
    _redemptionPrice = RAY;
    redemptionRate = RAY;
    redemptionPriceUpdateTime = block.timestamp;
    _params = _oracleRelayerParams;
  }

  /**
   * @notice Fetch the market price from the system coin oracle
   */
  function marketPrice() external view returns (uint256 _marketPrice) {
    (uint256 _priceFeedValue, bool _hasValidValue) = systemCoinOracle.getResultWithValidity();
    if (_hasValidValue) return _priceFeedValue;
  }

  /**
   * @notice Fetch the last recorded redemptionPrice
   * @dev To be used when having the absolute latest redemptionPrice is irrelevant
   */
  function lastRedemptionPrice() external view returns (uint256 _lastRedemptionPrice) {
    return _redemptionPrice;
  }

  // --- Redemption Price Update ---
  /**
   * @notice Update the redemption price using the current redemption rate
   */
  function _updateRedemptionPrice() internal virtual returns (uint256 _updatedPrice) {
    // Update redemption price
    _updatedPrice = redemptionRate.rpow(block.timestamp - redemptionPriceUpdateTime).rmul(_redemptionPrice);
    if (_updatedPrice == 0) _updatedPrice = 1;
    _redemptionPrice = _updatedPrice;
    redemptionPriceUpdateTime = block.timestamp;
    emit UpdateRedemptionPrice(_updatedPrice);
  }

  /**
   * @notice Fetch the latest redemption price by first updating it
   */
  function redemptionPrice() external returns (uint256 _updatedPrice) {
    return _getRedemptionPrice();
  }

  function _getRedemptionPrice() internal virtual returns (uint256 _updatedPrice) {
    if (block.timestamp > redemptionPriceUpdateTime) return _updateRedemptionPrice();
    return _redemptionPrice;
  }

  // --- Update value ---
  /**
   * @notice Update the collateral price inside the system (inside SAFEEngine)
   * @param  _cType The collateral we want to update prices (safety and liquidation prices) for
   */
  function updateCollateralPrice(bytes32 _cType) external whenEnabled {
    (uint256 _priceFeedValue, bool _hasValidValue) = _cParams[_cType].oracle.getResultWithValidity();
    uint256 _updatedRedemptionPrice = _getRedemptionPrice();

    uint256 _safetyPrice = _hasValidValue
      ? (uint256(_priceFeedValue) * uint256(10 ** 9)).rdiv(_updatedRedemptionPrice).rdiv(_cParams[_cType].safetyCRatio)
      : 0;
    uint256 _liquidationPrice = _hasValidValue
      ? (uint256(_priceFeedValue) * uint256(10 ** 9)).rdiv(_updatedRedemptionPrice).rdiv(
        _cParams[_cType].liquidationCRatio
      )
      : 0;

    safeEngine.updateCollateralPrice(_cType, _safetyPrice, _liquidationPrice);
    emit UpdateCollateralPrice(_cType, _priceFeedValue, _safetyPrice, _liquidationPrice);
  }

  function updateRedemptionRate(uint256 _redemptionRate) external isAuthorized whenEnabled {
    if (block.timestamp != redemptionPriceUpdateTime) revert OracleRelayer_RedemptionPriceNotUpdated();

    if (_redemptionRate > _params.redemptionRateUpperBound) {
      _redemptionRate = _params.redemptionRateUpperBound;
    } else if (_redemptionRate < _params.redemptionRateLowerBound) {
      _redemptionRate = _params.redemptionRateLowerBound;
    }
    redemptionRate = _redemptionRate;
  }

  function initializeCollateralType(
    bytes32 _cType,
    OracleRelayerCollateralParams memory _oracleRelayerCParams
  ) external isAuthorized validCParams(_cType) {
    if (!_collateralList.add(_cType)) revert OracleRelayer_CollateralTypeAlreadyInitialized();
    _validateDelayedOracle(address(_oracleRelayerCParams.oracle));
    _cParams[_cType] = _oracleRelayerCParams;
  }

  // --- Shutdown ---
  /**
   * @notice Disable this contract (normally called by GlobalSettlement)
   */
  function _onContractDisable() internal override {
    redemptionRate = RAY;
  }

  // --- Views ---
  function collateralList() external view returns (bytes32[] memory __collateralList) {
    return _collateralList.values();
  }

  // --- Administration ---
  function _modifyParameters(bytes32 _param, bytes memory _data) internal override whenEnabled {
    uint256 _uint256 = _data.toUint256();

    if (_param == 'systemCoinOracle') systemCoinOracle = IBaseOracle(_data.toAddress().assertNonNull());
    else if (_param == 'redemptionRateUpperBound') _params.redemptionRateUpperBound = _uint256;
    else if (_param == 'redemptionRateLowerBound') _params.redemptionRateLowerBound = _uint256;
    else revert UnrecognizedParam();
  }

  function _modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) internal override whenEnabled {
    uint256 _uint256 = _data.toUint256();
    OracleRelayerCollateralParams storage __cParams = _cParams[_cType];

    if (!_collateralList.contains(_cType)) revert UnrecognizedCType();
    if (_param == 'safetyCRatio') __cParams.safetyCRatio = _uint256;
    else if (_param == 'liquidationCRatio') __cParams.liquidationCRatio = _uint256;
    else if (_param == 'oracle') __cParams.oracle = _validateDelayedOracle(_data.toAddress());
    else revert UnrecognizedParam();
  }

  function _validateDelayedOracle(address _oracle) internal view returns (IDelayedOracle _delayedOracle) {
    // Checks if the delayed oracle priceSource is implemented
    _delayedOracle = IDelayedOracle(_oracle.assertNonNull());
    _delayedOracle.priceSource();
  }

  function _validateParameters() internal view override {
    _params.redemptionRateUpperBound.assertGt(RAY);
    _params.redemptionRateLowerBound.assertGt(0).assertLt(RAY);
    address(systemCoinOracle).assertNonNull();
  }

  function _validateCParameters(bytes32 _cType) internal view override {
    OracleRelayerCollateralParams memory __cParams = _cParams[_cType];
    __cParams.safetyCRatio.assertGtEq(__cParams.liquidationCRatio);
    __cParams.liquidationCRatio.assertGtEq(RAY);
    address(__cParams.oracle).assertNonNull();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDisableable} from '@interfaces/utils/IDisableable.sol';
import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface ISAFEEngine is IAuthorizable, IModifiable, IDisableable {
  // --- Events ---
  event ApproveSAFEModification(address _sender, address _account);
  event DenySAFEModification(address _sender, address _account);
  event InitializeCollateralType(bytes32 _cType);
  event TransferCollateral(bytes32 indexed _cType, address indexed _src, address indexed _dst, uint256 _wad);
  event TransferInternalCoins(address indexed _src, address indexed _dst, uint256 _rad);
  event ModifySAFECollateralization(
    bytes32 indexed _cType,
    address indexed _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  );
  event TransferSAFECollateralAndDebt(
    bytes32 indexed _cType, address indexed _src, address indexed _dst, int256 _deltaCollateral, int256 _deltaDebt
  );
  event ConfiscateSAFECollateralAndDebt(
    bytes32 indexed _cType,
    address indexed _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  );
  event SettleDebt(address indexed _account, uint256 _rad);
  event CreateUnbackedDebt(address indexed _debtDestination, address indexed _coinDestination, uint256 _rad);
  event UpdateAccumulatedRate(bytes32 indexed _cType, address _surplusDst, int256 _rateMultiplier);
  event UpdateCollateralPrice(bytes32 indexed _cType, uint256 _safetyPrice, uint256 _liquidationPrice);

  // --- Errors ---
  error SAFEEng_CollateralTypeAlreadyExists();
  error SAFEEng_CollateralTypeNotInitialized();
  error SAFEEng_SAFENotSafe();
  error SAFEEng_DustySAFE();
  error SAFEEng_GlobalDebtCeilingHit();
  error SAFEEng_CollateralDebtCeilingHit();
  error SAFEEng_SAFEDebtCeilingHit();
  error SAFEEng_NotSAFEAllowed();
  error SAFEEng_NotCollateralSrcAllowed();
  error SAFEEng_NotDebtDstAllowed();

  // --- Structs ---
  /**
   * @param lockedCollateral Total amount of collateral locked in a SAFE
   * @param generatedDebt Total amount of debt generated by a SAFE
   */
  struct SAFE {
    uint256 /* WAD */ lockedCollateral;
    uint256 /* WAD */ generatedDebt;
  }

  /**
   * @param safeDebtCeiling Total amount of debt that a single safe can generate
   * @param globalDebtCeiling Maximum amount of debt that can be issued
   */
  struct SAFEEngineParams {
    uint256 /* WAD */ safeDebtCeiling;
    uint256 /* RAD */ globalDebtCeiling;
  }

  /**
   * @param debtAmount Total amount of debt issued by a collateral type
   * @param accumulatedRate Accumulated rate of a collateral type
   * @param safetyPrice Floor price at which a SAFE is allowed to generate debt
   * @param liquidationPrice Price at which a SAFE gets liquidated
   */
  struct SAFEEngineCollateralData {
    uint256 /* WAD */ debtAmount;
    uint256 /* WAD */ lockedAmount;
    uint256 /* RAY */ accumulatedRate;
    uint256 /* RAY */ safetyPrice;
    uint256 /* RAY */ liquidationPrice;
  }

  /**
   * @param debtCeiling Maximum amount of debt that can be generated with this collateral type
   * @param debtFloor Minimum amount of debt that must be generated by a SAFE using this collateral
   */
  struct SAFEEngineCollateralParams {
    uint256 /* RAD */ debtCeiling;
    uint256 /* RAD */ debtFloor;
  }

  function coinBalance(address _coinAddress) external view returns (uint256 _balance);
  function debtBalance(address _coinAddress) external view returns (uint256 _debtBalance);
  function settleDebt(uint256 _rad) external;
  function transferInternalCoins(address _source, address _destination, uint256 _rad) external;
  function transferCollateral(bytes32 _cType, address _source, address _destination, uint256 _wad) external;
  function canModifySAFE(address _safe, address _account) external view returns (bool _allowed);
  function approveSAFEModification(address _account) external;
  function denySAFEModification(address _acount) external;
  function createUnbackedDebt(address _debtDestination, address _coinDestination, uint256 _rad) external;

  function params() external view returns (SAFEEngineParams memory _safeEngineParams);
  // solhint-disable-next-line private-vars-leading-underscore
  function _params() external view returns (uint256 _safeDebtCeiling, uint256 _globalDebtCeiling);

  function cParams(bytes32 _cType) external view returns (SAFEEngineCollateralParams memory _safeEngineCParams);
  // solhint-disable-next-line private-vars-leading-underscore
  function _cParams(bytes32 _cType) external view returns (uint256 _debtCeiling, uint256 _debtFloor);

  function cData(bytes32 _cType) external view returns (SAFEEngineCollateralData memory _safeEngineCData);
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

  function safes(bytes32 _cType, address _safeAddress) external view returns (SAFE memory _safeData);
  // solhint-disable-next-line private-vars-leading-underscore
  function _safes(
    bytes32 _cType,
    address _safeAddress
  ) external view returns (uint256 _lockedCollateral, uint256 _generatedDebt);

  function collateralList() external view returns (bytes32[] memory __collateralList);

  function globalDebt() external returns (uint256 _globalDebt);
  function confiscateSAFECollateralAndDebt(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) external;
  function updateAccumulatedRate(bytes32 _cType, address _surplusDst, int256 _rateMultiplier) external;
  function updateCollateralPrice(bytes32 _cType, uint256 _safetyPrice, uint256 _liquidationPrice) external;

  function initializeCollateralType(bytes32 _cType, SAFEEngineCollateralParams memory _collateralParams) external;
  function modifyCollateralBalance(bytes32 _cType, address _account, int256 _wad) external;
  function modifySAFECollateralization(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 /* WAD */ _deltaCollateral,
    int256 /* WAD */ _deltaDebt
  ) external;

  function transferSAFECollateralAndDebt(
    bytes32 _cType,
    address _src,
    address _dst,
    int256 /* WAD */ _deltaCollateral,
    int256 /* WAD */ _deltaDebt
  ) external;

  function tokenCollateral(bytes32 _cType, address _account) external view returns (uint256 _tokenCollateral);
  function globalUnbackedDebt() external view returns (uint256 _globalUnbackedDebt);
  function safeRights(address _account, address _safe) external view returns (uint256 _safeRights);
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

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';

interface IDelayedOracle is IBaseOracle {
  // --- Events ---
  event UpdateResult(uint256 _newMedian, uint256 _lastUpdateTime);

  // --- Errors ---
  error DelayedOracle_NullPriceSource();
  error DelayedOracle_NullDelay();
  error DelayedOracle_DelayHasNotElapsed();
  error DelayedOracle_NoCurrentValue();

  // --- Structs ---
  struct Feed {
    uint256 value;
    bool isValid;
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

  /**
   * @notice The delay in seconds that should elapse between updates
   */
  function updateDelay() external view returns (uint256 _updateDelay);

  /**
   * @notice The timestamp of the last update
   */
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

import {IBaseOracle} from '@interfaces/oracles/IBaseOracle.sol';
import {IDelayedOracle} from '@interfaces/oracles/IDelayedOracle.sol';
import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface IOracleRelayer is IAuthorizable, IModifiable, IDisableable {
  // --- Events ---
  event UpdateRedemptionPrice(uint256 _redemptionPrice);
  event UpdateCollateralPrice(
    bytes32 indexed _cType, uint256 _priceFeedValue, uint256 _safetyPrice, uint256 _liquidationPrice
  );

  // --- Errors ---
  error OracleRelayer_RedemptionPriceNotUpdated();
  error OracleRelayer_CollateralTypeAlreadyInitialized();

  // --- Structs ---
  struct OracleRelayerParams {
    // Upper bound for the per-second redemption rate
    uint256 redemptionRateUpperBound; // [ray]
    // Lower bound for the per-second redemption rate
    uint256 redemptionRateLowerBound; // [ray]
  }

  struct OracleRelayerCollateralParams {
    // Usually an oracle security module that enforces delays to fresh price feeds
    IDelayedOracle oracle;
    // CRatio used to compute the 'safePrice' - the price used when generating debt in SAFEEngine
    uint256 safetyCRatio;
    // CRatio used to compute the 'liquidationPrice' - the price used when liquidating SAFEs
    uint256 liquidationCRatio;
  }

  // --- Registry ---
  function safeEngine() external view returns (ISAFEEngine _safeEngine);

  /**
   * @notice The oracle used to fetch the system coin market price
   */
  function systemCoinOracle() external view returns (IBaseOracle _systemCoinOracle);

  // --- Params ---
  function params() external view returns (OracleRelayerParams memory _oracleRelayerParams);
  // solhint-disable-next-line private-vars-leading-underscore
  function _params() external view returns (uint256 _redemptionRateUpperBound, uint256 _redemptionRateLowerBound);

  function cParams(bytes32) external view returns (OracleRelayerCollateralParams memory _oracleRelayerCParams);
  // solhint-disable-next-line private-vars-leading-underscore
  function _cParams(bytes32)
    external
    view
    returns (IDelayedOracle _oracle, uint256 _safetyCRatio, uint256 _liquidationCRatio);

  // --- Data ---
  function lastRedemptionPrice() external view returns (uint256 _redemptionPrice);
  function marketPrice() external view returns (uint256 _marketPrice);
  function redemptionRate() external view returns (uint256 _redemptionRate);
  function redemptionPriceUpdateTime() external view returns (uint256 _redemptionPriceUpdateTime);

  // --- Methods ---
  function redemptionPrice() external returns (uint256 _redemptionPrice);
  function updateCollateralPrice(bytes32 _cType) external;
  function updateRedemptionRate(uint256 _redemptionRate) external;
  function initializeCollateralType(bytes32 _cType, OracleRelayerCollateralParams memory _collateralParams) external;

  // --- Views ---
  function collateralList() external view returns (bytes32[] memory __collateralList);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

abstract contract Authorizable is IAuthorizable {
  using EnumerableSet for EnumerableSet.AddressSet;

  // --- Data ---
  EnumerableSet.AddressSet internal _authorizedAccounts;

  // --- Init ---
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
   * @param _account Account to add auth to
   */
  function addAuthorization(address _account) external virtual isAuthorized {
    _addAuthorization(_account);
  }

  /**
   * @notice Remove auth from an account
   * @param _account Account to remove auth from
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
 * @title Modifiable
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

  /**
   * @notice Internal function to be overriden with custom logic to validate parameters
   */
  function _validateParameters() internal view virtual {}

  /**
   * @notice Internal function to be overriden with custom logic to validate collateral parameters
   */
  function _validateCParameters(bytes32 _cType) internal view virtual {}

  // --- Modifiers ---
  modifier validParams() {
    _;
    _validateParameters();
  }

  modifier validCParams(bytes32 _cType) {
    _;
    _validateCParameters(_cType);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IDisableable} from '@interfaces/utils/IDisableable.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';

abstract contract Disableable is IDisableable, Authorizable {
  // --- Data ---
  bool public contractEnabled = true;

  // --- External methods ---
  function disableContract() external isAuthorized whenEnabled {
    contractEnabled = false;
    _onContractDisable();
    emit DisableContract();
  }

  // --- Internal virtual methods ---

  /// @dev Method is instantiated, if not overriden it will just return
  function _onContractDisable() internal virtual {}

  function _isEnabled() internal view virtual returns (bool _enabled) {
    return contractEnabled;
  }

  // --- Modifiers ---
  modifier whenEnabled() {
    if (!_isEnabled()) revert ContractIsDisabled();
    _;
  }

  modifier whenDisabled() {
    if (_isEnabled()) revert ContractIsEnabled();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

library Encoding {
  function toUint256(bytes memory _data) internal pure returns (uint256 _uint256) {
    assembly {
      _uint256 := mload(add(_data, 0x20))
    }
  }

  function toInt256(bytes memory _data) internal pure returns (int256 _int256) {
    assembly {
      _int256 := mload(add(_data, 0x20))
    }
  }

  function toAddress(bytes memory _data) internal pure returns (address _address) {
    assembly {
      _address := mload(add(_data, 0x20))
    }
  }

  function toBool(bytes memory _data) internal pure returns (bool _bool) {
    assembly {
      _bool := mload(add(_data, 0x20))
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

library Assertions {
  error NotGreaterThan(uint256 _x, uint256 _y);
  error NotLesserThan(uint256 _x, uint256 _y);
  error NotGreaterOrEqualThan(uint256 _x, uint256 _y);
  error NotLesserOrEqualThan(uint256 _x, uint256 _y);
  error IntNotGreaterThan(int256 _x, int256 _y);
  error IntNotLesserThan(int256 _x, int256 _y);
  error IntNotGreaterOrEqualThan(int256 _x, int256 _y);
  error IntNotLesserOrEqualThan(int256 _x, int256 _y);
  error NullAmount();
  error NullAddress();

  // --- Assertions ---

  function assertGt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x <= _y) revert NotGreaterThan(_x, _y);
    return _x;
  }

  function assertGt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x <= _y) revert IntNotGreaterThan(_x, _y);
    return _x;
  }

  function assertGtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x < _y) revert NotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  function assertGtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x < _y) revert IntNotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  function assertLt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x >= _y) revert NotLesserThan(_x, _y);
    return _x;
  }

  function assertLt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x >= _y) revert IntNotLesserThan(_x, _y);
    return _x;
  }

  function assertLtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x > _y) revert NotLesserOrEqualThan(_x, _y);
    return _x;
  }

  function assertLtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x > _y) revert IntNotLesserOrEqualThan(_x, _y);
    return _x;
  }

  function assertNonNull(uint256 _x) internal pure returns (uint256 __x) {
    if (_x == 0) revert NullAmount();
    return _x;
  }

  function assertNonNull(address _address) internal pure returns (address __address) {
    if (_address == address(0)) revert NullAddress();
    return _address;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

uint256 constant MAX_RAD = type(uint256).max / RAY;
uint256 constant RAD = 10 ** 45;
uint256 constant RAY = 10 ** 27;
uint256 constant WAD = 10 ** 18;
uint256 constant YEAR = 365 days;
uint256 constant HOUR = 3600;

library Math {
  error IntOverflow();

  function add(uint256 _x, int256 _y) internal pure returns (uint256 _add) {
    if (_y >= 0) {
      return _x + uint256(_y);
    } else {
      return _x - uint256(-_y);
    }
  }

  function sub(uint256 _x, int256 _y) internal pure returns (uint256 _sub) {
    if (_y >= 0) {
      return _x - uint256(_y);
    } else {
      return _x + uint256(-_y);
    }
  }

  function sub(uint256 _x, uint256 _y) internal pure returns (int256 _sub) {
    return toInt(_x) - toInt(_y);
  }

  function mul(uint256 _x, int256 _y) internal pure returns (int256 _mul) {
    return toInt(_x) * _y;
  }

  function rmul(uint256 _x, uint256 _y) internal pure returns (uint256 _rmul) {
    return (_x * _y) / RAY;
  }

  function rmul(uint256 _x, int256 y) internal pure returns (int256 _rmul) {
    return (toInt(_x) * y) / int256(RAY);
  }

  function wmul(uint256 _x, uint256 _y) internal pure returns (uint256 _wmul) {
    return (_x * _y) / WAD;
  }

  function wmul(uint256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (toInt(_x) * _y) / int256(WAD);
  }

  function wmul(int256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (_x * _y) / int256(WAD);
  }

  function rdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _rdiv) {
    return (_x * RAY) / _y;
  }

  function rdiv(int256 _x, int256 _y) internal pure returns (int256 _rdiv) {
    return (_x * int256(RAY)) / _y;
  }

  function wdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _wdiv) {
    return (_x * WAD) / _y;
  }

  function rpow(uint256 _x, uint256 _n) internal pure returns (uint256 _rpow) {
    assembly {
      switch _x
      case 0 {
        switch _n
        case 0 { _rpow := RAY }
        default { _rpow := 0 }
      }
      default {
        switch mod(_n, 2)
        case 0 { _rpow := RAY }
        default { _rpow := _x }
        let half := div(RAY, 2) // for rounding.
        for { _n := div(_n, 2) } _n { _n := div(_n, 2) } {
          let _xx := mul(_x, _x)
          if iszero(eq(div(_xx, _x), _x)) { revert(0, 0) }
          let _xxRound := add(_xx, half)
          if lt(_xxRound, _xx) { revert(0, 0) }
          _x := div(_xxRound, RAY)
          if mod(_n, 2) {
            let _zx := mul(_rpow, _x)
            if and(iszero(iszero(_x)), iszero(eq(div(_zx, _x), _rpow))) { revert(0, 0) }
            let _zxRound := add(_zx, half)
            if lt(_zxRound, _zx) { revert(0, 0) }
            _rpow := div(_zxRound, RAY)
          }
        }
      }
    }
  }

  function max(uint256 _x, uint256 _y) internal pure returns (uint256 _max) {
    _max = (_x >= _y) ? _x : _y;
  }

  function min(uint256 _x, uint256 _y) internal pure returns (uint256 _min) {
    _min = (_x <= _y) ? _x : _y;
  }

  function toInt(uint256 _x) internal pure returns (int256 _int) {
    _int = int256(_x);
    if (_int < 0) revert IntOverflow();
  }

  // --- PI Specific Math ---
  function riemannSum(int256 _x, int256 _y) internal pure returns (int256 _riemannSum) {
    return (_x + _y) / 2;
  }

  function absolute(int256 _x) internal pure returns (uint256 _z) {
    _z = (_x < 0) ? uint256(-_x) : uint256(_x);
  }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

interface IDisableable is IAuthorizable {
  // --- Events ---
  event DisableContract();

  // --- Errors ---
  error ContractIsEnabled();
  error ContractIsDisabled();
  error NonDisableable();

  // --- Data ---
  function contractEnabled() external view returns (bool _contractEnabled);

  // --- Shutdown ---
  function disableContract() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IAuthorizable {
  // --- Events ---
  event AddAuthorization(address _account);
  event RemoveAuthorization(address _account);

  // --- Errors ---
  error AlreadyAuthorized();
  error NotAuthorized();
  error Unauthorized();

  // --- Data ---
  function authorizedAccounts(address _account) external view returns (bool _authorized);
  function authorizedAccounts() external view returns (address[] memory _accounts);

  // --- Administration ---
  function addAuthorization(address _account) external;
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