// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/*

Coded for Reflexer and The Money God with 🥕 by

░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░░
░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗░
░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║░
░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║░
░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝░
░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░░

https://defi.sucks

*/

import {ISAFEEngine} from '@interfaces/ISAFEEngine.sol';
import {IODSafeManager} from '@interfaces/proxies/IODSafeManager.sol';

import {Authorizable, IAuthorizable} from '@contracts/utils/Authorizable.sol';
import {Modifiable} from '@contracts/utils/Modifiable.sol';
import {IModifiablePerCollateral, ModifiablePerCollateral} from '@contracts/utils/ModifiablePerCollateral.sol';
import {Disableable} from '@contracts/utils/Disableable.sol';

import {Encoding} from '@libraries/Encoding.sol';
import {Math, RAY} from '@libraries/Math.sol';
import {Assertions} from '@libraries/Assertions.sol';
import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

/**
 * @title  SAFEEngine
 * @notice Core contract that manages the state of the SAFE system
 */
contract SAFEEngine is Authorizable, Disableable, Modifiable, ModifiablePerCollateral, ISAFEEngine {
  using Math for uint256;
  using Encoding for bytes;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using Assertions for address;

  // --- Data ---

  /// @inheritdoc ISAFEEngine
  // solhint-disable-next-line private-vars-leading-underscore
  SAFEEngineParams public _params;
  /// @notice safe manager contract for verifying safe validity
  // solhint-disable-next-line private-vars-leading-underscore
  IODSafeManager public _odSafeManager;
  /// @inheritdoc ISAFEEngine
  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 _cType => SAFEEngineCollateralParams) public _cParams;
  /// @inheritdoc ISAFEEngine
  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 _cType => SAFEEngineCollateralData) public _cData;
  /// @inheritdoc ISAFEEngine
  // solhint-disable-next-line private-vars-leading-underscore
  mapping(bytes32 _cType => mapping(address _safe => SAFE)) public _safes;
  /// @inheritdoc ISAFEEngine
  mapping(address _caller => mapping(address _account => uint256 _isAllowed)) public safeRights;

  /// @inheritdoc ISAFEEngine
  function params() external view returns (SAFEEngineParams memory _safeEngineParams) {
    return _params;
  }

  /// @inheritdoc ISAFEEngine
  function cParams(bytes32 _cType) external view returns (SAFEEngineCollateralParams memory _safeEngineCParams) {
    return _cParams[_cType];
  }

  /// @inheritdoc ISAFEEngine
  function cData(bytes32 _cType) external view returns (SAFEEngineCollateralData memory _safeEngineCData) {
    return _cData[_cType];
  }

  /// @inheritdoc ISAFEEngine
  function safes(bytes32 _cType, address _safe) external view returns (SAFE memory _safeData) {
    return _safes[_cType][_safe];
  }

  /// @inheritdoc ISAFEEngine
  function odSafeManager() external view returns (address _safeManager) {
    return address(_odSafeManager);
  }

  // --- Balances ---

  /// @inheritdoc ISAFEEngine
  mapping(bytes32 _cType => mapping(address _safe => uint256 _wad)) public tokenCollateral;
  /// @inheritdoc ISAFEEngine
  mapping(address _safe => uint256 _rad) public coinBalance;
  /// @inheritdoc ISAFEEngine
  mapping(address _safe => uint256 _rad) public debtBalance;
  /// @inheritdoc ISAFEEngine
  uint256 public /* RAD */ globalDebt;
  /// @inheritdoc ISAFEEngine
  uint256 public /* RAD */ globalUnbackedDebt;

  // --- Init ---

  /**
   * @param  _safeEngineParams Initial SAFEEngine valid parameters struct
   */
  constructor(SAFEEngineParams memory _safeEngineParams) Authorizable(msg.sender) validParams {
    _params = _safeEngineParams;
  }

  function initializeSafeManager() external {
    if (address(_odSafeManager) == address(0)) _odSafeManager = IODSafeManager(msg.sender);
  }

  // --- Fungibility ---

  /// @inheritdoc ISAFEEngine
  function transferCollateral(
    bytes32 _cType,
    address _source,
    address _destination,
    uint256 _wad
  ) external isSAFEAllowed(_source, msg.sender) {
    tokenCollateral[_cType][_source] -= _wad;
    tokenCollateral[_cType][_destination] += _wad;
    emit TransferCollateral(_cType, _source, _destination, _wad);
  }

  /// @inheritdoc ISAFEEngine
  function transferInternalCoins(
    address _source,
    address _destination,
    uint256 _rad
  ) external isSAFEAllowed(_source, msg.sender) {
    coinBalance[_source] -= _rad;
    coinBalance[_destination] += _rad;
    emit TransferInternalCoins(_source, _destination, _rad);
  }

  /// @inheritdoc ISAFEEngine
  function modifyCollateralBalance(bytes32 _cType, address _account, int256 _wad) external isAuthorized {
    _modifyCollateralBalance(_cType, _account, _wad);
  }

  // --- SAFE Manipulation ---

  /// @inheritdoc ISAFEEngine
  function modifySAFECollateralization(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) external whenEnabled {
    if (_odSafeManager.safeHandlerToSafeId(_safe) == 0) revert SAFEEng_NotSAFEAllowed();
    SAFEEngineCollateralData storage __cData = _cData[_cType];
    // collateral type has been initialised
    if (__cData.accumulatedRate == 0) revert SAFEEng_CollateralTypeNotInitialized();

    _modifyCollateralBalance(_cType, _collateralSource, -_deltaCollateral);
    _emitTransferCollateral(_cType, address(0), _safe, _deltaCollateral);
    _modifySAFECollateralization(_cType, _safe, _deltaCollateral, _deltaDebt);
    __cData.debtAmount = __cData.debtAmount.add(_deltaDebt);
    __cData.lockedAmount = __cData.lockedAmount.add(_deltaCollateral);

    int256 _deltaAdjustedDebt = __cData.accumulatedRate.mul(_deltaDebt);
    _modifyInternalCoins(_debtDestination, _deltaAdjustedDebt);

    // --- Safety checks ---
    {
      SAFEEngineCollateralParams memory __cParams = _cParams[_cType];
      SAFE memory _safeData = _safes[_cType][_safe];
      uint256 _totalDebtIssued = __cData.accumulatedRate * _safeData.generatedDebt;

      // either debt is increased (generated) and debt ceilings are not exceeded, or debt destination consents
      if (_deltaDebt > 0) {
        if (globalDebt > _params.globalDebtCeiling) revert SAFEEng_GlobalDebtCeilingHit();
        if (__cData.debtAmount * __cData.accumulatedRate > __cParams.debtCeiling) {
          revert SAFEEng_CollateralDebtCeilingHit();
        }
        if (_safeData.generatedDebt > _params.safeDebtCeiling) revert SAFEEng_SAFEDebtCeilingHit();
      } else {
        if (!canModifySAFE(_debtDestination, msg.sender)) revert SAFEEng_NotDebtDstAllowed();
      }

      // either safe is less risky, or it is still safe and the owner consents
      if (_deltaDebt > 0 || _deltaCollateral < 0) {
        if (_totalDebtIssued > _safeData.lockedCollateral * __cData.safetyPrice) revert SAFEEng_SAFENotSafe();
        if (!canModifySAFE(_safe, msg.sender)) revert SAFEEng_NotSAFEAllowed();
      }

      // either collateral is decreased (returned), or collateral source consents
      if (_deltaCollateral > 0) {
        if (!canModifySAFE(_collateralSource, msg.sender)) revert SAFEEng_NotCollateralSrcAllowed();
      }

      // either safe has no debt, or a non-dusty amount
      if (_safeData.generatedDebt != 0 && _totalDebtIssued < __cParams.debtFloor) revert SAFEEng_DustySAFE();
    }

    emit ModifySAFECollateralization(_cType, _safe, _collateralSource, _debtDestination, _deltaCollateral, _deltaDebt);
  }

  // --- SAFE Fungibility ---

  /// @inheritdoc ISAFEEngine
  function transferSAFECollateralAndDebt(
    bytes32 _cType,
    address _src,
    address _dst,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) external isSAFEAllowed(_src, msg.sender) isSAFEAllowed(_dst, msg.sender) {
    _modifySAFECollateralization(_cType, _src, -_deltaCollateral, -_deltaDebt);
    _emitTransferCollateral(_cType, _src, _dst, _deltaCollateral);
    _modifySAFECollateralization(_cType, _dst, _deltaCollateral, _deltaDebt);

    // --- Safety checks ---
    {
      SAFE memory _srcSAFE = _safes[_cType][_src];
      SAFE memory _dstSAFE = _safes[_cType][_dst];
      SAFEEngineCollateralParams memory __cParams = _cParams[_cType];
      SAFEEngineCollateralData memory __cData = _cData[_cType];

      uint256 _srcTotalDebtIssued = _srcSAFE.generatedDebt * __cData.accumulatedRate;
      uint256 _dstTotalDebtIssued = _dstSAFE.generatedDebt * __cData.accumulatedRate;

      // both sides below debt ceiling
      if (_srcSAFE.generatedDebt > _params.safeDebtCeiling || _dstSAFE.generatedDebt > _params.safeDebtCeiling) {
        revert SAFEEng_SAFEDebtCeilingHit();
      }

      // both sides safe
      if (
        _srcTotalDebtIssued > _srcSAFE.lockedCollateral * __cData.safetyPrice
          || _dstTotalDebtIssued > _dstSAFE.lockedCollateral * __cData.safetyPrice
      ) revert SAFEEng_SAFENotSafe();

      // both sides non-dusty
      if (
        (_srcTotalDebtIssued < __cParams.debtFloor && _srcSAFE.generatedDebt != 0)
          || (_dstTotalDebtIssued < __cParams.debtFloor && _dstSAFE.generatedDebt != 0)
      ) revert SAFEEng_DustySAFE();
    }

    emit TransferSAFECollateralAndDebt(_cType, _src, _dst, _deltaCollateral, _deltaDebt);
  }

  // --- SAFE Confiscation ---

  /// @inheritdoc ISAFEEngine
  function confiscateSAFECollateralAndDebt(
    bytes32 _cType,
    address _safe,
    address _collateralSource,
    address _debtDestination,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) external isAuthorized {
    SAFEEngineCollateralData storage __cData = _cData[_cType];

    _modifyCollateralBalance(_cType, _collateralSource, -_deltaCollateral);
    _emitTransferCollateral(_cType, address(0), _safe, _deltaCollateral);
    _modifySAFECollateralization(_cType, _safe, _deltaCollateral, _deltaDebt);
    __cData.debtAmount = __cData.debtAmount.add(_deltaDebt);
    __cData.lockedAmount = __cData.lockedAmount.add(_deltaCollateral);

    int256 _deltaTotalIssuedDebt = __cData.accumulatedRate.mul(_deltaDebt);

    debtBalance[_debtDestination] = debtBalance[_debtDestination].sub(_deltaTotalIssuedDebt);
    globalUnbackedDebt = globalUnbackedDebt.sub(_deltaTotalIssuedDebt);

    emit ConfiscateSAFECollateralAndDebt(
      _cType, _safe, _collateralSource, _debtDestination, _deltaCollateral, _deltaDebt
    );
  }

  // --- Settlement ---

  /// @inheritdoc ISAFEEngine
  function settleDebt(uint256 _rad) external {
    address _account = msg.sender;
    debtBalance[_account] -= _rad;
    _modifyInternalCoins(_account, -_rad.toInt());
    globalUnbackedDebt -= _rad;
    emit SettleDebt(_account, _rad);
  }

  /// @inheritdoc ISAFEEngine
  function createUnbackedDebt(address _debtDestination, address _coinDestination, uint256 _rad) external isAuthorized {
    debtBalance[_debtDestination] += _rad;
    _modifyInternalCoins(_coinDestination, _rad.toInt());
    globalUnbackedDebt += _rad;
    emit CreateUnbackedDebt(_debtDestination, _coinDestination, _rad);
  }

  // --- Update ---

  /// @inheritdoc ISAFEEngine
  function updateAccumulatedRate(
    bytes32 _cType,
    address _surplusDst,
    int256 _rateMultiplier
  ) external isAuthorized whenEnabled {
    SAFEEngineCollateralData storage __cData = _cData[_cType];
    __cData.accumulatedRate = __cData.accumulatedRate.add(_rateMultiplier);
    int256 _deltaSurplus = __cData.debtAmount.mul(_rateMultiplier);
    _modifyInternalCoins(_surplusDst, _deltaSurplus);

    emit UpdateAccumulatedRate(_cType, _surplusDst, _rateMultiplier);
  }

  /// @inheritdoc ISAFEEngine
  function updateCollateralPrice(
    bytes32 _cType,
    uint256 _safetyPrice,
    uint256 _liquidationPrice
  ) external isAuthorized whenEnabled {
    _cData[_cType].safetyPrice = _safetyPrice;
    _cData[_cType].liquidationPrice = _liquidationPrice;
    emit UpdateCollateralPrice(_cType, _safetyPrice, _liquidationPrice);
  }

  // --- Authorization ---

  /**
   * @notice Add auth to an account
   * @param  _account Account to add auth to
   */

  /**
   * @dev    This overriden method avoids adding new authorizations after the contract has been disabled
   * @inheritdoc IAuthorizable
   */
  function addAuthorization(address _account) external override(Authorizable, IAuthorizable) isAuthorized whenEnabled {
    _addAuthorization(_account);
  }

  /**
   * @notice Remove auth from an account
   * @param  _account Account to remove auth from
   */
  function removeAuthorization(address _account)
    external
    override(Authorizable, IAuthorizable)
    isAuthorized
    whenEnabled
  {
    _removeAuthorization(_account);
  }

  /// @inheritdoc ISAFEEngine
  function approveSAFEModification(address _account) external {
    safeRights[msg.sender][_account] = 1;
    emit ApproveSAFEModification(msg.sender, _account);
  }

  /// @inheritdoc ISAFEEngine
  function denySAFEModification(address _account) external {
    safeRights[msg.sender][_account] = 0;
    emit DenySAFEModification(msg.sender, _account);
  }

  /// @inheritdoc ISAFEEngine
  function canModifySAFE(address _safe, address _account) public view returns (bool _canModifySafe) {
    return _safe == _account || safeRights[_safe][_account] == 1;
  }

  // --- Internals ---

  function _modifyCollateralBalance(bytes32 _cType, address _account, int256 _wad) internal {
    tokenCollateral[_cType][_account] = tokenCollateral[_cType][_account].add(_wad);
    _emitTransferCollateral(_cType, address(0), _account, _wad);
  }

  function _modifyInternalCoins(address _dst, int256 _rad) internal {
    coinBalance[_dst] = coinBalance[_dst].add(_rad);
    globalDebt = globalDebt.add(_rad);
    if (_rad > 0) emit TransferInternalCoins(address(0), _dst, uint256(_rad));
    else emit TransferInternalCoins(_dst, address(0), uint256(-_rad));
  }

  function _modifySAFECollateralization(
    bytes32 _cType,
    address _safe,
    int256 _deltaCollateral,
    int256 _deltaDebt
  ) internal {
    SAFE storage _safeData = _safes[_cType][_safe];
    _safeData.lockedCollateral = _safeData.lockedCollateral.add(_deltaCollateral);
    _safeData.generatedDebt = _safeData.generatedDebt.add(_deltaDebt);

    _emitTransferCollateral(_cType, _safe, address(this), _deltaCollateral);
  }

  function _emitTransferCollateral(bytes32 _cType, address _src, address _dst, int256 _deltaCollateral) internal {
    if (_deltaCollateral == 0) return;
    if (_deltaCollateral >= 0) {
      emit TransferCollateral(_cType, _src, _dst, uint256(_deltaCollateral));
    } else {
      emit TransferCollateral(_cType, _dst, _src, uint256(-_deltaCollateral));
    }
  }

  // --- Administration ---

  /// @inheritdoc ModifiablePerCollateral
  function _initializeCollateralType(bytes32 _cType, bytes memory _collateralParams) internal override whenEnabled {
    (SAFEEngineCollateralParams memory _safeEngineCParams) = abi.decode(_collateralParams, (SAFEEngineCollateralParams));
    _cData[_cType].accumulatedRate = RAY;
    _cParams[_cType] = _safeEngineCParams;
  }

  /// @inheritdoc Modifiable
  function _modifyParameters(bytes32 _param, bytes memory _data) internal override {
    uint256 _uint256 = _data.toUint256();

    if (_param == 'globalDebtCeiling') _params.globalDebtCeiling = _uint256;
    else if (_param == 'safeDebtCeiling') _params.safeDebtCeiling = _uint256;
    else if (_param == 'odSafeManager') _odSafeManager = IODSafeManager(_data.toAddress().assertNonNull());
    else revert UnrecognizedParam();
  }

  /// @inheritdoc ModifiablePerCollateral
  function _modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) internal override {
    uint256 _uint256 = _data.toUint256();

    if (!_collateralList.contains(_cType)) revert UnrecognizedCType();
    if (_param == 'debtCeiling') _cParams[_cType].debtCeiling = _uint256;
    else if (_param == 'debtFloor') _cParams[_cType].debtFloor = _uint256;
    else revert UnrecognizedParam();
  }

  // --- Modifiers ---

  modifier isSAFEAllowed(address _safe, address _account) {
    if (!canModifySAFE(_safe, _account)) revert SAFEEng_NotSAFEAllowed();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';
import {IModifiablePerCollateral} from '@interfaces/utils/IModifiablePerCollateral.sol';
import {IDisableable} from '@interfaces/utils/IDisableable.sol';

interface ISAFEEngine is IAuthorizable, IDisableable, IModifiable, IModifiablePerCollateral {
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

  /// @notice Throws when trying to modify parameters of an uninitialized collateral type
  error SAFEEng_CollateralTypeNotInitialized(); // 0xcc8fbb29
  /// @notice Throws when trying to modify a SAFE into an unsafe state
  error SAFEEng_SAFENotSafe(); // 0x1f441794
  /// @notice Throws when trying to modify a SAFE into a dusty safe (debt non-zero and below `debtFloor`)
  error SAFEEng_DustySAFE(); // 0xbc8beb5f
  /// @notice Throws when trying to generate debt that would put the system over the global debt ceiling
  error SAFEEng_GlobalDebtCeilingHit(); // 0x4d0b26ae
  /// @notice Throws when trying to generate debt that would put the system over the collateral debt ceiling
  error SAFEEng_CollateralDebtCeilingHit(); // 0x787cf02c
  /// @notice Throws when trying to generate debt that would put the SAFE over the SAFE debt ceiling
  error SAFEEng_SAFEDebtCeilingHit(); // 0x8c77698d
  /// @notice Throws when an account tries to modify a SAFE without the proper permissions
  error SAFEEng_NotSAFEAllowed(); // 0x4df694a1
  /// @notice Throws when an account tries to pull collateral from a SAFE without the proper permissions
  error SAFEEng_NotCollateralSrcAllowed(); // 0x3820cfbf
  /// @notice Throws when an account tries to push debt to a SAFE without the proper permissions
  error SAFEEng_NotDebtDstAllowed(); // 0x62c26e9a

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
   * @notice Getter for the address of the safe manager
   * @return _safeManager Address of safe manager
   */
  function odSafeManager() external view returns (address _safeManager);
  /**
   * @notice Getter for the unpacked collateral data struct
   * @param  _cType Bytes32 representation of the collateral type
   * @return _debtAmount Total amount of debt issued by a collateral type [wad]
   * @return _lockedAmount Total amount of collateral locked in all SAFEs of the collateral type [wad]
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

  /**
   * @notice called by ODSafeManager during deployment
   */
  function initializeSafeManager() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

interface IODSafeManager {
  // --- Events ---

  /// @notice Emitted when calling allowSAFE with the sender address and the method arguments
  event AllowSAFE(address indexed _sender, uint256 indexed _safe, address _usr, bool _ok);
  /// @notice Emitted when calling transferSAFEOwnership with the sender address and the method arguments
  event TransferSAFEOwnership(address indexed _sender, uint256 indexed _safe, address _dst);
  /// @notice Emitted when calling openSAFE with the sender address and the method arguments
  event OpenSAFE(address indexed _sender, address indexed _own, uint256 indexed _safe);
  /// @notice Emitted when calling modifySAFECollateralization with the sender address and the method arguments
  event ModifySAFECollateralization(
    address indexed _sender, uint256 indexed _safe, int256 _deltaCollateral, int256 _deltaDebt
  );
  /// @notice Emitted when calling transferCollateral with the sender address and the method arguments
  event TransferCollateral(address indexed _sender, uint256 indexed _safe, address _dst, uint256 _wad);
  /// @notice Emitted when calling transferCollateral (specifying cType) with the sender address and the method arguments
  event TransferCollateral(address indexed _sender, bytes32 _cType, uint256 indexed _safe, address _dst, uint256 _wad);
  /// @notice Emitted when calling transferInternalCoins with the sender address and the method arguments
  event TransferInternalCoins(address indexed _sender, uint256 indexed _safe, address _dst, uint256 _rad);
  /// @notice Emitted when calling quitSystem with the sender address and the method arguments
  event QuitSystem(address indexed _sender, uint256 indexed _safe, address _dst);
  /// @notice Emitted when calling moveSAFE with the sender address and the method arguments
  event MoveSAFE(address indexed _sender, uint256 indexed _safeSrc, uint256 indexed _safeDst);
  /// @notice Emitted when calling protectSAFE with the sender address and the method arguments
  event ProtectSAFE(address indexed _sender, uint256 indexed _safe, address _liquidationEngine, address _saviour);

  // --- Errors ---

  /// @notice Throws if the provided address is null
  error ZeroAddress();
  /// @notice Throws when trying to call a function not allowed for a given safe
  error SafeNotAllowed();
  /// @notice Throws when trying to call a function not allowed for a given handler
  error HandlerNotAllowed();
  /// @notice Throws when trying to transfer safe ownership to the current owner
  error AlreadySafeOwner();
  /// @notice Throws when trying to move a safe to another one with different collateral type
  error CollateralTypesMismatch();
  /// @notice Throws when trying to transfer collateral to an address that isn't a SAFEHandler
  error HandlerDoesNotExist();
  /// @notice Throws if anyone except the safe owner tries to call a function
  error OnlySafeOwner();

  // --- Structs ---

  struct SAFEData {
    // The current nonce of the safe - incremented each time it is transferred
    uint96 nonce;
    // Address of the safe owner
    address owner;
    // Address of the safe handler
    address safeHandler;
    // Collateral type of the safe
    bytes32 collateralType;
  }

  // --- Data ---

  /// @notice Address of the SAFEEngine
  function safeEngine() external view returns (address _safeEngine);

  /// @notice Mapping of owner and safe permissions to a caller permissions
  function safeCan(
    address _owner,
    uint256 _safeId,
    uint96 _safeNonce,
    address _caller
  ) external view returns (bool _ok);

  /// @notice Mapping of handler to the safeId
  function safeHandlerToSafeId(address _safeHandler) external view returns (uint256 _safeId);

  // --- Getters ---

  /**
   * @notice Getter for the list of safes owned by a user
   * @param  _usr Address of the user
   * @return _safes List of safe ids owned by the user
   */
  function getSafes(address _usr) external view returns (uint256[] memory _safes);

  /**
   * @notice Getter for the list of safes owned by a user for a given collateral type
   * @param  _usr Address of the user
   * @param  _cType Bytes32 representation of the collateral type
   * @return _safes List of safe ids owned by the user for the given collateral type
   */
  function getSafes(address _usr, bytes32 _cType) external view returns (uint256[] memory _safes);

  /**
   * @notice Getter for the details of the safes owned by a user
   * @param  _usr Address of the user
   * @return _safes List of safe ids owned by the user
   * @return _safeHandlers List of safe handlers addresses owned by the user
   * @return _cTypes List of collateral types of the safes owned by the user
   */
  function getSafesData(address _usr)
    external
    view
    returns (uint256[] memory _safes, address[] memory _safeHandlers, bytes32[] memory _cTypes);

  /**
   * @notice Getter for the details of the safe given a handler address
   * @param  _handler Address of the handler
   * @return _sData Struct with the safe data
   */
  function getSafeDataFromHandler(address _handler) external view returns (SAFEData memory _sData);

  /**
   * @notice Getter for the details of a SAFE
   * @param  _safe Id of the SAFE
   * @return _sData Struct with the safe data
   */
  function safeData(uint256 _safe) external view returns (SAFEData memory _sData);

  // --- Methods ---

  /**
   * @notice Allow/disallow a user address to manage the safe
   * @param  _safe Id of the SAFE
   * @param  _usr Address of the user to allow/disallow
   * @param  _ok Boolean state to allow/disallow
   */
  function allowSAFE(uint256 _safe, address _usr, bool _ok) external;

  /**
   * @notice Open a new safe for a user address
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _usr Address of the user to open the safe for
   * @return _id Id of the new SAFE
   */
  function openSAFE(bytes32 _cType, address _usr) external returns (uint256 _id);

  /**
   * @notice Transfer the ownership of a safe to a dst address
   * @param  _safe Id of the SAFE
   * @param  _dst Address of the dst address
   */
  function transferSAFEOwnership(uint256 _safe, address _dst) external;

  /**
   * @notice Modify a SAFE's collateralization ratio while keeping the generated COIN or collateral freed in the safe handler address
   * @param  _safe Id of the SAFE
   * @param  _deltaCollateral Delta of collateral to add/remove [wad]
   * @param  _deltaDebt Delta of debt to add/remove [wad]
   * @param  _nonSafeHandlerAddress Boolean flag to specify whether to not to use the safe handler address, if true, then we use proxy address
   */
  function modifySAFECollateralization(
    uint256 _safe,
    int256 _deltaCollateral,
    int256 _deltaDebt,
    bool _nonSafeHandlerAddress
  ) external;

  /**
   * @notice Transfer wad amount of safe collateral from the safe address to a dst address
   * @param  _safe Id of the SAFE
   * @param  _dst Address of the dst address
   * @param  _wad Amount of collateral to transfer [wad]
   */
  function transferCollateral(uint256 _safe, address _dst, uint256 _wad) external;

  /**
   * @notice Transfer wad amount of any type of collateral from the safe address to a dst address
   * @param  _cType Bytes32 representation of the collateral type
   * @param  _safe Id of the SAFE
   * @param  _dst Address of the dst address
   * @param  _wad Amount of collateral to transfer [wad]
   * @dev    This function has the purpose to take away collateral from the system that doesn't correspond to the safe but was sent there wrongly.
   */
  function transferCollateral(bytes32 _cType, uint256 _safe, address _dst, uint256 _wad) external;

  /**
   * @notice Transfer an amount of COIN from the safe address to a dst address [rad]
   * @param  _safe Id of the SAFE
   * @param  _dst Address of the dst address
   * @param  _rad Amount of COIN to transfer [rad]
   */
  function transferInternalCoins(uint256 _safe, address _dst, uint256 _rad) external;

  /**
   * @notice Quit the system, migrating the safe (lockedCollateral, generatedDebt) to the ODProxy address
   * @param  _safe Id of the SAFE
   */
  function quitSystem(uint256 _safe) external;

  /**
   * @notice Move a position from safeSrc handler to the safeDst handler
   * @param  _safeSrc Id of the source SAFE
   * @param  _safeDst Id of the destination SAFE
   */
  function moveSAFE(uint256 _safeSrc, uint256 _safeDst) external;

  /**
   * @notice Add a safe to the user's list of safes (doesn't set safe ownership)
   * @param  _safe Id of the SAFE
   * @dev    This function is meant to allow the user to add a safe to their list (if it was previously removed)
   */
  function addSAFE(uint256 _safe) external;

  /**
   * @notice Remove a safe from the user's list of safes (doesn't erase safe ownership)
   * @param  _safe Id of the SAFE
   * @dev    This function is meant to allow the user to remove a safe from their list (if it was added against their will)
   */
  function removeSAFE(uint256 _safe) external;

  /**
   * @notice Choose a safe saviour inside LiquidationEngine for the SAFE
   * @param  _safe Id of the SAFE
   * @param  _saviour Address of the saviour
   */
  function protectSAFE(uint256 _safe, address _saviour) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';

import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

/**
 * @title  Authorizable
 * @notice Implements authorization control for contracts
 * @dev    Authorization control is boolean and handled by `isAuthorized` modifier
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
    if (_account == address(0)) revert NullAddress();
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
pragma solidity 0.8.20;

import {IModifiable} from '@interfaces/utils/IModifiable.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';

/**
 * @title  Modifiable
 * @notice Allows inheriting contracts to modify parameters values
 * @dev    Requires inheriting contracts to override `_modifyParameters` virtual methods
 */
abstract contract Modifiable is Authorizable, IModifiable {
  // --- Constants ---

  /// @dev Used to emit a global parameter modification event
  bytes32 internal constant _GLOBAL_PARAM = bytes32(0);

  // --- External methods ---

  /// @inheritdoc IModifiable
  function modifyParameters(bytes32 _param, bytes memory _data) external isAuthorized validParams {
    emit ModifyParameters(_param, _GLOBAL_PARAM, _data);
    _modifyParameters(_param, _data);
  }

  // --- Internal virtual methods ---

  /**
   * @notice Internal function to be overriden with custom logic to modify parameters
   * @dev    This function is set to revert if not overriden
   */
  // solhint-disable-next-line no-unused-vars
  function _modifyParameters(bytes32 _param, bytes memory _data) internal virtual;

  /// @notice Internal function to be overriden with custom logic to validate parameters
  function _validateParameters() internal view virtual {}

  // --- Modifiers ---

  /// @notice Triggers a routine to validate parameters after a modification
  modifier validParams() {
    _;
    _validateParameters();
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IModifiablePerCollateral} from '@interfaces/utils/IModifiablePerCollateral.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';
import {EnumerableSet} from '@openzeppelin/utils/structs/EnumerableSet.sol';

/**
 * @title  ModifiablePerCollateral
 * @notice Allows inheriting contracts to modify parameters values and initialize collateral types
 * @dev    Requires inheriting contracts to override `_modifyParameters` virtual methods and implement `_initializeCollateralType`
 */
abstract contract ModifiablePerCollateral is Authorizable, IModifiablePerCollateral {
  using EnumerableSet for EnumerableSet.Bytes32Set;

  // --- Data ---
  EnumerableSet.Bytes32Set internal _collateralList;

  // --- Views ---
  /// @inheritdoc IModifiablePerCollateral
  function collateralList() external view returns (bytes32[] memory __collateralList) {
    return _collateralList.values();
  }

  // --- Methods ---

  /// @inheritdoc IModifiablePerCollateral
  function initializeCollateralType(
    bytes32 _cType,
    bytes memory _collateralParams
  ) public virtual isAuthorized validCParams(_cType) {
    if (!_collateralList.add(_cType)) revert CollateralTypeAlreadyInitialized();
    _initializeCollateralType(_cType, _collateralParams);
    emit InitializeCollateralType(_cType);
  }

  /// @inheritdoc IModifiablePerCollateral
  function modifyParameters(
    bytes32 _cType,
    bytes32 _param,
    bytes memory _data
  ) external isAuthorized validCParams(_cType) {
    _modifyParameters(_cType, _param, _data);
    emit ModifyParameters(_param, _cType, _data);
  }

  /**
   * @notice Set a new value for a collateral specific parameter
   * @param _cType String identifier of the collateral to modify
   * @param _param String identifier of the parameter to modify
   * @param _data Encoded data to modify the parameter
   */
  function _modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) internal virtual;

  /**
   * @notice Register a new collateral type in the SAFEEngine
   * @param _cType Collateral type to register
   * @param _collateralParams Collateral parameters
   */
  function _initializeCollateralType(bytes32 _cType, bytes memory _collateralParams) internal virtual;

  /// @notice Internal function to be overriden with custom logic to validate collateral parameters
  function _validateCParameters(bytes32 _cType) internal view virtual {}

  // --- Modifiers ---

  /// @notice Triggers a routine to validate collateral parameters after a modification
  modifier validCParams(bytes32 _cType) {
    _;
    _validateCParameters(_cType);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IDisableable} from '@interfaces/utils/IDisableable.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';

/**
 * @title  Disableable
 * @notice This abstract contract provides the ability to disable the inheriting contract,
 *         triggering (if implemented) an on-disable routine hook.
 * @dev    This contract also implements `whenEnabled` and `whenDisabled` modifiers to restrict
 *         the methods that can be called on each state.
 */
abstract contract Disableable is IDisableable, Authorizable {
  // --- Data ---

  /// @inheritdoc IDisableable
  bool public contractEnabled = true;

  // --- External methods ---

  /// @inheritdoc IDisableable
  function disableContract() external isAuthorized whenEnabled {
    contractEnabled = false;
    emit DisableContract();
    _onContractDisable();
  }

  // --- Internal virtual methods ---

  /**
   * @notice Internal virtual method to be called when the contract is disabled
   * @dev    This method is virtual and should be overriden to implement
   */
  function _onContractDisable() internal virtual {}

  /**
   * @notice Internal virtual view to check if the contract is enabled
   * @dev    This method is virtual and could be overriden for non-standard implementations
   */
  function _isEnabled() internal view virtual returns (bool _enabled) {
    return contractEnabled;
  }

  // --- Modifiers ---

  /// @notice Allows method calls only when the contract is enabled
  modifier whenEnabled() {
    if (!_isEnabled()) revert ContractIsDisabled();
    _;
  }

  /// @notice Allows method calls only when the contract is disabled
  modifier whenDisabled() {
    if (_isEnabled()) revert ContractIsEnabled();
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

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
pragma solidity 0.8.20;

/// @dev Max uint256 value that a RAD can represent without overflowing
uint256 constant MAX_RAD = type(uint256).max / RAY;
/// @dev Uint256 representation of 1 RAD
uint256 constant RAD = 10 ** 45;
/// @dev Uint256 representation of 1 RAY
uint256 constant RAY = 10 ** 27;
/// @dev Uint256 representation of 1 WAD
uint256 constant WAD = 10 ** 18;
/// @dev Uint256 representation of 1 year in seconds
uint256 constant YEAR = 365 days;
/// @dev Uint256 representation of 1 hour in seconds
uint256 constant HOUR = 3600;

/**
 * @title Math
 * @notice This library contains common math functions
 */
library Math {
  // --- Errors ---

  /// @dev Throws when trying to cast a uint256 to an int256 that overflows
  error IntOverflow();

  // --- Math ---

  /**
   * @notice Calculates the sum of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _add Unsigned sum of `_x` and `_y`
   */
  function add(uint256 _x, int256 _y) internal pure returns (uint256 _add) {
    if (_y >= 0) {
      return _x + uint256(_y);
    } else {
      return _x - uint256(-_y);
    }
  }

  /**
   * @notice Calculates the substraction of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _sub Unsigned substraction of `_x` and `_y`
   */
  function sub(uint256 _x, int256 _y) internal pure returns (uint256 _sub) {
    if (_y >= 0) {
      return _x - uint256(_y);
    } else {
      return _x + uint256(-_y);
    }
  }

  /**
   * @notice Calculates the substraction of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _sub Signed substraction of `_x` and `_y`
   */
  function sub(uint256 _x, uint256 _y) internal pure returns (int256 _sub) {
    return toInt(_x) - toInt(_y);
  }

  /**
   * @notice Calculates the multiplication of an unsigned integer and a signed integer
   * @param  _x Unsigned integer
   * @param  _y Signed integer
   * @return _mul Signed multiplication of `_x` and `_y`
   */
  function mul(uint256 _x, int256 _y) internal pure returns (int256 _mul) {
    return toInt(_x) * _y;
  }

  /**
   * @notice Calculates the multiplication of two unsigned RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Unsigned RAY integer
   * @return _rmul Unsigned multiplication of `_x` and `_y` in RAY precision
   */
  function rmul(uint256 _x, uint256 _y) internal pure returns (uint256 _rmul) {
    return (_x * _y) / RAY;
  }

  /**
   * @notice Calculates the multiplication of an unsigned and a signed RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Signed RAY integer
   * @return _rmul Signed multiplication of `_x` and `_y` in RAY precision
   */
  function rmul(uint256 _x, int256 _y) internal pure returns (int256 _rmul) {
    return (toInt(_x) * _y) / int256(RAY);
  }

  /**
   * @notice Calculates the multiplication of two unsigned WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Unsigned WAD integer
   * @return _wmul Unsigned multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(uint256 _x, uint256 _y) internal pure returns (uint256 _wmul) {
    return (_x * _y) / WAD;
  }

  /**
   * @notice Calculates the multiplication of an unsigned and a signed WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Signed WAD integer
   * @return _wmul Signed multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(uint256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (toInt(_x) * _y) / int256(WAD);
  }

  /**
   * @notice Calculates the multiplication of two signed WAD integers
   * @param  _x Signed WAD integer
   * @param  _y Signed WAD integer
   * @return _wmul Signed multiplication of `_x` and `_y` in WAD precision
   */
  function wmul(int256 _x, int256 _y) internal pure returns (int256 _wmul) {
    return (_x * _y) / int256(WAD);
  }

  /**
   * @notice Calculates the division of two unsigned RAY integers
   * @param  _x Unsigned RAY integer
   * @param  _y Unsigned RAY integer
   * @return _rdiv Unsigned division of `_x` by `_y` in RAY precision
   */
  function rdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _rdiv) {
    return (_x * RAY) / _y;
  }

  /**
   * @notice Calculates the division of two signed RAY integers
   * @param  _x Signed RAY integer
   * @param  _y Signed RAY integer
   * @return _rdiv Signed division of `_x` by `_y` in RAY precision
   */
  function rdiv(int256 _x, int256 _y) internal pure returns (int256 _rdiv) {
    return (_x * int256(RAY)) / _y;
  }

  /**
   * @notice Calculates the division of two unsigned WAD integers
   * @param  _x Unsigned WAD integer
   * @param  _y Unsigned WAD integer
   * @return _wdiv Unsigned division of `_x` by `_y` in WAD precision
   */
  function wdiv(uint256 _x, uint256 _y) internal pure returns (uint256 _wdiv) {
    return (_x * WAD) / _y;
  }

  /**
   * @notice Calculates the power of an unsigned RAY integer to an unsigned integer
   * @param  _x Unsigned RAY integer
   * @param  _n Unsigned integer exponent
   * @return _rpow Unsigned `_x` to the power of `_n` in RAY precision
   */
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

  /**
   * @notice Calculates the maximum of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _max Unsigned maximum of `_x` and `_y`
   */
  function max(uint256 _x, uint256 _y) internal pure returns (uint256 _max) {
    _max = (_x >= _y) ? _x : _y;
  }

  /**
   * @notice Calculates the minimum of two unsigned integers
   * @param  _x Unsigned integer
   * @param  _y Unsigned integer
   * @return _min Unsigned minimum of `_x` and `_y`
   */
  function min(uint256 _x, uint256 _y) internal pure returns (uint256 _min) {
    _min = (_x <= _y) ? _x : _y;
  }

  /**
   * @notice Casts an unsigned integer to a signed integer
   * @param  _x Unsigned integer
   * @return _int Signed integer
   * @dev    Throws if `_x` is too large to fit in an int256
   */
  function toInt(uint256 _x) internal pure returns (int256 _int) {
    _int = int256(_x);
    if (_int < 0) revert IntOverflow();
  }

  // --- PI Specific Math ---

  /**
   * @notice Calculates the Riemann sum of two signed integers
   * @param  _x Signed integer
   * @param  _y Signed integer
   * @return _riemannSum Riemann sum of `_x` and `_y`
   */
  function riemannSum(int256 _x, int256 _y) internal pure returns (int256 _riemannSum) {
    return (_x + _y) / 2;
  }

  /**
   * @notice Calculates the absolute value of a signed integer
   * @param  _x Signed integer
   * @return _z Unsigned absolute value of `_x`
   */
  function absolute(int256 _x) internal pure returns (uint256 _z) {
    _z = (_x < 0) ? uint256(-_x) : uint256(_x);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

/**
 * @title Assertions
 * @notice This library contains assertions for common requirement checks
 */
library Assertions {
  // --- Errors ---

  /// @dev Throws if `_x` is not greater than `_y`
  error NotGreaterThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not lesser than `_y`
  error NotLesserThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not greater than or equal to `_y`
  error NotGreaterOrEqualThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not lesser than or equal to `_y`
  error NotLesserOrEqualThan(uint256 _x, uint256 _y);
  /// @dev Throws if `_x` is not greater than `_y`
  error IntNotGreaterThan(int256 _x, int256 _y);
  /// @dev Throws if `_x` is not lesser than `_y`
  error IntNotLesserThan(int256 _x, int256 _y);
  /// @dev Throws if `_x` is not greater than or equal to `_y`
  error IntNotGreaterOrEqualThan(int256 _x, int256 _y);
  /// @dev Throws if `_x` is not lesser than or equal to `_y`
  error IntNotLesserOrEqualThan(int256 _x, int256 _y);
  /// @dev Throws if checked amount is null
  error NullAmount();
  /// @dev Throws if checked address is null
  error NullAddress();
  /// @dev Throws if checked address contains no code
  error NoCode(address _contract);

  // --- Assertions ---

  /// @dev Asserts that `_x` is greater than `_y` and returns `_x`
  function assertGt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x <= _y) revert NotGreaterThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is greater than `_y` and returns `_x`
  function assertGt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x <= _y) revert IntNotGreaterThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is greater than or equal to `_y` and returns `_x`
  function assertGtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x < _y) revert NotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is greater than or equal to `_y` and returns `_x`
  function assertGtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x < _y) revert IntNotGreaterOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than `_y` and returns `_x`
  function assertLt(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x >= _y) revert NotLesserThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than `_y` and returns `_x`
  function assertLt(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x >= _y) revert IntNotLesserThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than or equal to `_y` and returns `_x`
  function assertLtEq(uint256 _x, uint256 _y) internal pure returns (uint256 __x) {
    if (_x > _y) revert NotLesserOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is lesser than or equal to `_y` and returns `_x`
  function assertLtEq(int256 _x, int256 _y) internal pure returns (int256 __x) {
    if (_x > _y) revert IntNotLesserOrEqualThan(_x, _y);
    return _x;
  }

  /// @dev Asserts that `_x` is not null and returns `_x`
  function assertNonNull(uint256 _x) internal pure returns (uint256 __x) {
    if (_x == 0) revert NullAmount();
    return _x;
  }

  /// @dev Asserts that `_address` is not null and returns `_address`
  function assertNonNull(address _address) internal pure returns (address __address) {
    if (_address == address(0)) revert NullAddress();
    return _address;
  }

  /// @dev Asserts that `_address` contains code and returns `_address`
  function assertHasCode(address _address) internal view returns (address __address) {
    if (_address.code.length == 0) revert NoCode(_address);
    return _address;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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
pragma solidity 0.8.20;

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
  error AlreadyAuthorized(); // 0x6027d27e
  /// @notice Throws if the account is not authorized on `removeAuthorization`
  error NotAuthorized(); // 0xea8e4eb5
  /// @notice Throws if the account is not authorized and tries to call an `onlyAuthorized` method
  error Unauthorized(); // 0x82b42900
  /// @notice Throws if zero address is passed
  error NullAddress();

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
pragma solidity 0.8.20;

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface IModifiablePerCollateral is IAuthorizable, IModifiable {
  // --- Events ---
  /**
   * @notice Emitted when a new collateral type is registered
   * @param _cType Bytes32 representation of the collateral type
   */
  event InitializeCollateralType(bytes32 _cType);

  // --- Errors ---

  error CollateralTypeAlreadyInitialized();

  // --- Views ---

  /**
   * @notice List of all the collateral types registered in the OracleRelayer
   * @return __collateralList Array of all the collateral types registered
   */
  function collateralList() external view returns (bytes32[] memory __collateralList);

  // --- Methods ---

  /**
   * @notice Register a new collateral type in the SAFEEngine
   * @param _cType Collateral type to register
   * @param _collateralParams Collateral parameters
   */
  function initializeCollateralType(bytes32 _cType, bytes memory _collateralParams) external;

  /**
   * @notice Set a new value for a collateral specific parameter
   * @param _cType String identifier of the collateral to modify
   * @param _param String identifier of the parameter to modify
   * @param _data Encoded data to modify the parameter
   */
  function modifyParameters(bytes32 _cType, bytes32 _param, bytes memory _data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

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