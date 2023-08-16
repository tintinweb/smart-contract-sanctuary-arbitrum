// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ITaxCollector} from '@interfaces/ITaxCollector.sol';
import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';
import {Modifiable} from '@contracts/utils/Modifiable.sol';

import {Assertions} from '@libraries/Assertions.sol';
import {Encoding} from '@libraries/Encoding.sol';
import {Math, RAY, WAD} from '@libraries/Math.sol';
import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

contract TaxCollector is Authorizable, Modifiable, ITaxCollector {
  using Math for uint256;
  using Encoding for bytes;
  using Assertions for uint256;
  using Assertions for address;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;

  // --- Registry ---
  ISAFEEngine public safeEngine;

  // --- Data ---
  // solhint-disable-next-line private-vars-leading-underscore
  TaxCollectorParams public _params;

  function params() external view returns (TaxCollectorParams memory _taxCollectorParams) {
    return _params;
  }

  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 => TaxCollectorCollateralParams) public _cParams;

  function cParams(bytes32 _cType) external view returns (TaxCollectorCollateralParams memory _taxCollectorCParams) {
    return _cParams[_cType];
  }

  // Data about each collateral type
  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 => TaxCollectorCollateralData) public _cData;

  function cData(bytes32 _cType) external view returns (TaxCollectorCollateralData memory _taxCollectorCData) {
    return _cData[_cType];
  }

  // Each collateral type that sends SF to a specific tax receiver
  mapping(address => EnumerableSet.Bytes32Set) internal _secondaryReceiverRevenueSources;
  // Tax receiver data
  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 => mapping(address => TaxReceiver)) public _secondaryTaxReceivers;

  function secondaryTaxReceivers(
    bytes32 _cType,
    address _receiver
  ) external view returns (TaxReceiver memory _secondaryTaxReceiver) {
    return _secondaryTaxReceivers[_cType][_receiver];
  }

  // All collateral types
  EnumerableSet.Bytes32Set internal _collateralList;
  // Enumerable set with tax receiver data
  EnumerableSet.AddressSet internal _secondaryReceivers;

  // --- Init ---
  constructor(address _safeEngine, TaxCollectorParams memory _taxCollectorParams) Authorizable(msg.sender) validParams {
    safeEngine = ISAFEEngine(_safeEngine.assertNonNull());
    _params = _taxCollectorParams;
    _setPrimaryTaxReceiver(_taxCollectorParams.primaryTaxReceiver);
  }

  /**
   * @notice Initialize a brand new collateral type
   * @param _cType Collateral type name (e.g ETH-A, TBTC-B)
   * @param _taxCollectorCParams Collateral type parameters
   */
  function initializeCollateralType(
    bytes32 _cType,
    TaxCollectorCollateralParams memory _taxCollectorCParams
  ) external isAuthorized validCParams(_cType) {
    if (!_collateralList.add(_cType)) revert TaxCollector_CollateralTypeAlreadyInitialized();
    _cData[_cType] =
      TaxCollectorCollateralData({nextStabilityFee: RAY, updateTime: block.timestamp, secondaryReceiverAllotedTax: 0});
    _cParams[_cType] = _taxCollectorCParams;

    emit InitializeCollateralType(_cType);
  }

  // --- Tax Collection Utils ---
  /**
   * @notice Check if multiple collateral types are up to date with taxation
   */
  function collectedManyTax(uint256 _start, uint256 _end) public view returns (bool _ok) {
    if (_start > _end || _end >= _collateralList.length()) revert TaxCollector_InvalidIndexes();
    for (uint256 _i = _start; _i <= _end; ++_i) {
      if (block.timestamp > _cData[_collateralList.at(_i)].updateTime) {
        _ok = false;
        return _ok;
      }
    }
    _ok = true;
  }

  /**
   * @notice Check how much SF will be charged (to collateral types between indexes 'start' and 'end'
   *         in the collateralList) during the next taxation
   * @param _start Index in collateralList from which to start looping and calculating the tax outcome
   * @param _end Index in collateralList at which we stop looping and calculating the tax outcome
   */
  function taxManyOutcome(uint256 _start, uint256 _end) public view returns (bool _ok, int256 _rad) {
    if (_start > _end || _end >= _collateralList.length()) revert TaxCollector_InvalidIndexes();
    int256 _primaryReceiverBalance = -safeEngine.coinBalance(_params.primaryTaxReceiver).toInt();
    int256 _deltaRate;
    uint256 _debtAmount;

    bytes32 _cType;
    for (uint256 _i = _start; _i <= _end; ++_i) {
      _cType = _collateralList.at(_i);

      if (block.timestamp > _cData[_cType].updateTime) {
        _debtAmount = safeEngine.cData(_cType).debtAmount;
        (, _deltaRate) = taxSingleOutcome(_cType);
        _rad = _rad + _debtAmount.mul(_deltaRate);
      }
    }
    if (_rad < 0) {
      _ok = _rad >= _primaryReceiverBalance;
    } else {
      _ok = true;
    }
  }

  /**
   * @notice Get how much SF will be distributed after taxing a specific collateral type
   * @param _cType Collateral type to compute the taxation outcome for
   * @return _newlyAccumulatedRate The newly accumulated rate
   * @return _deltaRate The delta between the new and the last accumulated rates
   */
  function taxSingleOutcome(bytes32 _cType) public view returns (uint256 _newlyAccumulatedRate, int256 _deltaRate) {
    uint256 _lastAccumulatedRate = safeEngine.cData(_cType).accumulatedRate;

    TaxCollectorCollateralData memory __cData = _cData[_cType];
    _newlyAccumulatedRate =
      __cData.nextStabilityFee.rpow(block.timestamp - __cData.updateTime).rmul(_lastAccumulatedRate);
    return (_newlyAccumulatedRate, _newlyAccumulatedRate.sub(_lastAccumulatedRate));
  }

  // --- Tax Receiver Utils ---
  /**
   * @notice Get the secondary tax receiver list length
   */
  function secondaryReceiversListLength() public view returns (uint256 _secondaryReceiversListLength) {
    return _secondaryReceivers.length();
  }

  /**
   * @notice Get the collateralList length
   */
  function collateralListLength() public view returns (uint256 _collateralListLength) {
    return _collateralList.length();
  }

  /**
   * @notice Check if a tax receiver is at a certain position in the list
   */
  function isSecondaryReceiver(address _receiver) public view returns (bool _isSecondaryReceiver) {
    return _secondaryReceivers.contains(_receiver);
  }

  // --- Views ---
  function collateralList() external view returns (bytes32[] memory __collateralList) {
    return _collateralList.values();
  }

  function secondaryReceiversList() external view returns (address[] memory _secondaryReceiversList) {
    return _secondaryReceivers.values();
  }

  function secondaryReceiverRevenueSourcesList(address _secondaryReceiver)
    external
    view
    returns (bytes32[] memory _secondaryReceiverRevenueSourcesList)
  {
    return _secondaryReceiverRevenueSources[_secondaryReceiver].values();
  }

  // --- Tax (Stability Fee) Collection ---
  /**
   * @notice Collect tax from multiple collateral types at once
   * @param _start Index in collateralList from which to start looping and calculating the tax outcome
   * @param _end Index in collateralList at which we stop looping and calculating the tax outcome
   */
  function taxMany(uint256 _start, uint256 _end) external {
    if (_start > _end || _end >= _collateralList.length()) revert TaxCollector_InvalidIndexes();
    for (uint256 _i = _start; _i <= _end; ++_i) {
      taxSingle(_collateralList.at(_i));
    }
  }

  /**
   * @notice Collect tax from a single collateral type
   * @param _cType Collateral type to tax
   */
  function taxSingle(bytes32 _cType) public returns (uint256 _latestAccumulatedRate) {
    TaxCollectorCollateralData memory __cData = _cData[_cType];

    if (block.timestamp <= __cData.updateTime) {
      _latestAccumulatedRate = safeEngine.cData(_cType).accumulatedRate;
      _cData[_cType].nextStabilityFee = _getNextStabilityFee(_cType);
      return _latestAccumulatedRate;
    }
    (, int256 _deltaRate) = taxSingleOutcome(_cType);
    // Check how much debt has been generated for collateralType
    uint256 _debtAmount = safeEngine.cData(_cType).debtAmount;
    _splitTaxIncome(_cType, _debtAmount, _deltaRate);
    _latestAccumulatedRate = safeEngine.cData(_cType).accumulatedRate;
    __cData.updateTime = block.timestamp;
    __cData.nextStabilityFee = _getNextStabilityFee(_cType);
    _cData[_cType] = __cData;

    emit CollectTax(_cType, _latestAccumulatedRate, _deltaRate);
    return _latestAccumulatedRate;
  }

  function _getNextStabilityFee(bytes32 _cType) internal view returns (uint256 _nextStabilityFee) {
    _nextStabilityFee = _params.globalStabilityFee.rmul(_cParams[_cType].stabilityFee);
    if (_nextStabilityFee < RAY - _params.maxStabilityFeeRange) return RAY - _params.maxStabilityFeeRange;
    if (_nextStabilityFee > RAY + _params.maxStabilityFeeRange) return RAY + _params.maxStabilityFeeRange;
  }

  /**
   * @notice Split SF between all tax receivers
   * @param _cType Collateral type to distribute SF for
   * @param _deltaRate Difference between the last and the latest accumulate rates for the collateralType
   */
  function _splitTaxIncome(bytes32 _cType, uint256 _debtAmount, int256 _deltaRate) internal {
    // Start looping from the oldest tax receiver
    address _secondaryReceiver;
    uint256 _secondaryReceiversListLength = _secondaryReceivers.length();
    // Loop through the entire tax receiver list
    for (uint256 _i; _i < _secondaryReceiversListLength; ++_i) {
      _secondaryReceiver = _secondaryReceivers.at(_i);
      // If the current tax receiver should receive SF from collateralType
      if (_secondaryReceiverRevenueSources[_secondaryReceiver].contains(_cType)) {
        _distributeTax(_cType, _secondaryReceiver, _debtAmount, _deltaRate);
      }
    }
    // Distribute to primary receiver
    _distributeTax(_cType, _params.primaryTaxReceiver, _debtAmount, _deltaRate);
  }

  /**
   * @notice Give/withdraw SF from a tax receiver
   * @param _cType Collateral type to distribute SF for
   * @param _receiver Tax receiver address
   * @param _debtAmount Total debt currently issued
   * @param _deltaRate Difference between the latest and the last accumulated rates for the collateralType
   */
  function _distributeTax(bytes32 _cType, address _receiver, uint256 _debtAmount, int256 _deltaRate) internal {
    // Check how many coins the receiver has and negate the value
    int256 _coinBalance = -safeEngine.coinBalance(_receiver).toInt();
    int256 __debtAmount = _debtAmount.toInt();

    TaxReceiver memory _taxReceiver = _secondaryTaxReceivers[_cType][_receiver];
    // Compute the % out of SF that should be allocated to the receiver
    int256 _currentTaxCut = _receiver == _params.primaryTaxReceiver
      ? (WAD - _cData[_cType].secondaryReceiverAllotedTax).wmul(_deltaRate)
      : _taxReceiver.taxPercentage.wmul(_deltaRate);

    /**
     * If SF is negative and a tax receiver doesn't have enough coins to absorb the loss,
     *           compute a new tax cut that can be absorbed
     */
    _currentTaxCut = __debtAmount * _currentTaxCut < 0 && _coinBalance > __debtAmount * _currentTaxCut
      ? _coinBalance / __debtAmount
      : _currentTaxCut;

    /**
     * If the tax receiver's tax cut is not null and if the receiver accepts negative SF
     *         offer/take SF to/from them
     */
    if (_currentTaxCut != 0) {
      if (_receiver == _params.primaryTaxReceiver || (_deltaRate >= 0 || _taxReceiver.canTakeBackTax)) {
        safeEngine.updateAccumulatedRate(_cType, _receiver, _currentTaxCut);
        emit DistributeTax(_cType, _receiver, _currentTaxCut);
      }
    }
  }

  // --- Administration ---
  function _modifyParameters(bytes32 _param, bytes memory _data) internal override {
    uint256 _uint256 = _data.toUint256();

    if (_param == 'primaryTaxReceiver') _setPrimaryTaxReceiver(_data.toAddress());
    else if (_param == 'globalStabilityFee') _params.globalStabilityFee = _uint256;
    else if (_param == 'maxStabilityFeeRange') _params.maxStabilityFeeRange = _uint256;
    else if (_param == 'maxSecondaryReceivers') _params.maxSecondaryReceivers = _uint256;
    else revert UnrecognizedParam();
  }

  function _modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) internal override {
    if (!_collateralList.contains(_cType)) revert UnrecognizedCType();
    if (_param == 'stabilityFee') _cParams[_cType].stabilityFee = _data.toUint256();
    else if (_param == 'secondaryTaxReceiver') _setSecondaryTaxReceiver(_cType, abi.decode(_data, (TaxReceiver)));
    else revert UnrecognizedParam();
  }

  function _validateParameters() internal view override {
    _params.primaryTaxReceiver.assertNonNull();
    _params.maxStabilityFeeRange.assertGt(0).assertLt(RAY);
    _params.globalStabilityFee.assertGtEq(RAY - _params.maxStabilityFeeRange).assertLtEq(
      RAY + _params.maxStabilityFeeRange
    );
  }

  function _validateCParameters(bytes32 _cType) internal view override {
    _cParams[_cType].stabilityFee.assertGtEq(RAY - _params.maxStabilityFeeRange).assertLtEq(
      RAY + _params.maxStabilityFeeRange
    );
  }

  /**
   * @notice Sets the primary tax receiver, the address that receives the unallocated SF from all collateral types
   * @param _primaryTaxReceiver Address of the primary tax receiver
   */
  function _setPrimaryTaxReceiver(address _primaryTaxReceiver) internal {
    _params.primaryTaxReceiver = _primaryTaxReceiver;
    emit SetPrimaryReceiver(_GLOBAL_PARAM, _primaryTaxReceiver);
  }

  /**
   * @notice Add a new secondary tax receiver or update data (add a new SF source or modify % of SF taken from a collateral type)
   * @param _cType Collateral type that will give SF to the tax receiver
   * @param _data Encoded data containing the receiver, tax percentage, and whether it supports negative tax
   */
  function _setSecondaryTaxReceiver(bytes32 _cType, TaxReceiver memory _data) internal {
    if (_data.receiver == address(0)) revert TaxCollector_NullAccount();
    if (_data.receiver == _params.primaryTaxReceiver) revert TaxCollector_PrimaryReceiverCannotBeSecondary();
    if (!_collateralList.contains(_cType)) revert TaxCollector_CollateralTypeNotInitialized();

    if (_secondaryReceivers.add(_data.receiver)) {
      // receiver is a new secondary receiver

      if (_secondaryReceivers.length() > _params.maxSecondaryReceivers) revert TaxCollector_ExceedsMaxReceiverLimit();
      if (_data.taxPercentage == 0) revert TaxCollector_NullSF();
      if (_cData[_cType].secondaryReceiverAllotedTax + _data.taxPercentage > WAD) {
        revert TaxCollector_TaxCutExceedsHundred();
      }

      _cData[_cType].secondaryReceiverAllotedTax += _data.taxPercentage;
      _secondaryReceiverRevenueSources[_data.receiver].add(_cType);
      _secondaryTaxReceivers[_cType][_data.receiver] = _data;
    } else {
      // receiver is already a secondary receiver

      if (_data.taxPercentage == 0) {
        // deletes the existing receiver

        _cData[_cType].secondaryReceiverAllotedTax -= _secondaryTaxReceivers[_cType][_data.receiver].taxPercentage;

        _secondaryReceiverRevenueSources[_data.receiver].remove(_cType);
        if (_secondaryReceiverRevenueSources[_data.receiver].length() == 0) {
          _secondaryReceivers.remove(_data.receiver);
        }

        delete(_secondaryTaxReceivers[_cType][_data.receiver]);
      } else {
        // modifies the information on the existing receiver

        uint256 _secondaryReceiverAllotedTax = (
          _cData[_cType].secondaryReceiverAllotedTax - _secondaryTaxReceivers[_cType][_data.receiver].taxPercentage
        ) + _data.taxPercentage;
        if (_secondaryReceiverAllotedTax > WAD) revert TaxCollector_TaxCutTooBig();

        _cData[_cType].secondaryReceiverAllotedTax = _secondaryReceiverAllotedTax;
        _secondaryTaxReceivers[_cType][_data.receiver] = _data;
        // NOTE: if it was already added it just ignores it
        _secondaryReceiverRevenueSources[_data.receiver].add(_cType);
      }
    }

    emit SetSecondaryReceiver(_cType, _data.receiver, _data.taxPercentage, _data.canTakeBackTax);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface ITaxCollector is IAuthorizable, IModifiable {
  // --- Events ---
  event InitializeCollateralType(bytes32 _cType);
  event SetPrimaryReceiver(bytes32 indexed _cType, address indexed _receiver);
  // NOTE: (taxPercentage, canTakeBackTax) = (0, false) means that the receiver is removed
  event SetSecondaryReceiver(
    bytes32 indexed _cType, address indexed _receiver, uint256 _taxPercentage, bool _canTakeBackTax
  );
  event CollectTax(bytes32 indexed _cType, uint256 _latestAccumulatedRate, int256 _deltaRate);
  event DistributeTax(bytes32 indexed _cType, address indexed _target, int256 _taxCut);

  // --- Errors ---
  error TaxCollector_CollateralTypeAlreadyInitialized();
  error TaxCollector_InvalidIndexes();
  error TaxCollector_NullAccount();
  error TaxCollector_PrimaryReceiverCannotBeSecondary();
  error TaxCollector_CollateralTypeNotInitialized();
  error TaxCollector_ExceedsMaxReceiverLimit();
  error TaxCollector_NullSF();
  error TaxCollector_TaxCutExceedsHundred();
  error TaxCollector_TaxCutTooBig();

  // --- Data ---
  struct TaxCollectorParams {
    address primaryTaxReceiver;
    uint256 /* RAY */ globalStabilityFee;
    uint256 /* RAY */ maxStabilityFeeRange;
    uint256 maxSecondaryReceivers;
  }

  struct TaxCollectorCollateralParams {
    uint256 stabilityFee;
  }

  struct TaxCollectorCollateralData {
    // Per second borrow rate for this specific collateral type to be applied at the next taxation
    uint256 nextStabilityFee;
    // When Stability Fee was last collected for this collateral type
    uint256 updateTime;
    // Percentage of each collateral's SF that goes to other addresses apart from the primary receiver
    uint256 secondaryReceiverAllotedTax; // [wad%]
  }

  // SF receiver
  struct TaxReceiver {
    address receiver;
    // Whether this receiver can accept a negative rate (taking SF from it)
    bool canTakeBackTax; // [bool]
    // Percentage of SF allocated to this receiver
    uint256 taxPercentage; // [wad%]
  }

  function params() external view returns (TaxCollectorParams memory _taxCollectorParams);
  // solhint-disable-next-line private-vars-leading-underscore
  function _params()
    external
    view
    returns (
      address _primaryTaxReceiver,
      uint256 _globalStabilityFee,
      uint256 _maxStabilityFeeRange,
      uint256 _maxSecondaryReceivers
    );

  function cParams(bytes32 _cType) external view returns (TaxCollectorCollateralParams memory _taxCollectorCParams);
  // solhint-disable-next-line private-vars-leading-underscore
  function _cParams(bytes32 _cType) external view returns (uint256 _stabilityFee);

  function cData(bytes32 _cType) external view returns (TaxCollectorCollateralData memory _taxCollectorCData);
  // solhint-disable-next-line private-vars-leading-underscore
  function _cData(bytes32 _cType)
    external
    view
    returns (uint256 _nextStabilityFee, uint256 _updateTime, uint256 _secondaryReceiverAllotedTax);

  function secondaryTaxReceivers(
    bytes32 _cType,
    address _receiver
  ) external view returns (TaxReceiver memory _secondaryTaxReceiver);
  // solhint-disable-next-line private-vars-leading-underscore
  function _secondaryTaxReceivers(
    bytes32 _cType,
    address _receiver
  ) external view returns (address _secondaryReceiver, bool _canTakeBackTax, uint256 _taxPercentage);

  function safeEngine() external view returns (ISAFEEngine _safeEngine);

  // --- Administration ---
  function initializeCollateralType(bytes32 _cType, TaxCollectorCollateralParams memory _collateralParams) external;

  // --- Tax Collection Utils ---
  function collectedManyTax(uint256 _start, uint256 _end) external view returns (bool _ok);
  function taxManyOutcome(uint256 _start, uint256 _end) external view returns (bool _ok, int256 _rad);
  function taxSingleOutcome(bytes32 _cType) external view returns (uint256 _newlyAccumulatedRate, int256 _deltaRate);

  // --- Tax Receiver Utils ---
  function secondaryReceiversListLength() external view returns (uint256 _secondaryReceiversListLength);
  function collateralListLength() external view returns (uint256 _collateralListLength);
  function isSecondaryReceiver(address _receiver) external view returns (bool _isSecondaryReceiver);

  // --- Views ---
  function collateralList() external view returns (bytes32[] memory _collateralList);
  function secondaryReceiversList() external view returns (address[] memory _secondaryReceiversList);
  function secondaryReceiverRevenueSourcesList(address _secondaryReceiver)
    external
    view
    returns (bytes32[] memory _secondaryReceiverRevenueSourcesList);

  // --- Tax (Stability Fee) Collection ---
  function taxMany(uint256 _start, uint256 _end) external;
  function taxSingle(bytes32 _cType) external returns (uint256 _latestAccumulatedRate);
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