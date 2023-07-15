// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IPIDController} from '@interfaces/IPIDController.sol';

import {Authorizable} from '@contracts/utils/Authorizable.sol';
import {Modifiable} from '@contracts/utils/Modifiable.sol';

import {Encoding} from '@libraries/Encoding.sol';
import {Assertions} from '@libraries/Assertions.sol';
import {Math, WAD, RAY} from '@libraries/Math.sol';

/**
 * @title PIDController
 * @notice Redemption Rate Feedback Mechanism (RRFM) controller that implements a PI controller
 */
contract PIDController is Authorizable, Modifiable, IPIDController {
  using Math for uint256;
  using Math for int256;
  using Encoding for bytes;
  using Assertions for uint256;
  using Assertions for int256;
  using Assertions for address;

  uint256 internal constant _NEGATIVE_RATE_LIMIT = RAY - 1;
  uint256 internal constant _POSITIVE_RATE_LIMIT = uint256(type(int256).max);

  // --- Registry ---
  /// @inheritdoc IPIDController
  address public seedProposer;

  // --- Data ---
  // solhint-disable-next-line private-vars-leading-underscore
  PIDControllerParams public _params;

  function params() external view returns (PIDControllerParams memory _pidParams) {
    return _params;
  }

  // solhint-disable-next-line private-vars-leading-underscore
  DeviationObservation public _deviationObservation;

  /// @inheritdoc IPIDController
  function deviationObservation() external view returns (DeviationObservation memory __deviationObservation) {
    return _deviationObservation;
  }

  // -- Static & Default Variables ---
  // solhint-disable-next-line private-vars-leading-underscore
  ControllerGains public _controllerGains;

  /// @inheritdoc IPIDController
  function controllerGains() external view returns (ControllerGains memory _cGains) {
    return _controllerGains;
  }

  constructor(
    ControllerGains memory _cGains,
    PIDControllerParams memory _pidParams,
    DeviationObservation memory _importedState
  ) Authorizable(msg.sender) validParams {
    _params = _pidParams;
    _controllerGains = _cGains;

    if (_importedState.timestamp > 0) {
      _deviationObservation = DeviationObservation({
        timestamp: _importedState.timestamp.assertLtEq(block.timestamp),
        proportional: _importedState.proportional,
        integral: _importedState.integral
      });
    }
  }

  /// @inheritdoc IPIDController
  function getBoundedRedemptionRate(int256 _piOutput) external view returns (uint256 _newRedemptionRate) {
    return _getBoundedRedemptionRate(_piOutput);
  }

  function _getBoundedRedemptionRate(int256 _piOutput) internal view virtual returns (uint256 _newRedemptionRate) {
    int256 _boundedPIOutput = _getBoundedPIOutput(_piOutput);

    // feedbackOutputLowerBound will never be less than NEGATIVE_RATE_LIMIT : RAY - 1,
    // and feedbackOutputUpperBound will never be greater than POSITIVE_RATE_LIMIT : uint256(type(int256).max)
    // boundedPIOutput can be safely added to RAY
    _newRedemptionRate = _boundedPIOutput < -int256(RAY) ? _NEGATIVE_RATE_LIMIT : RAY.add(_boundedPIOutput);

    return _newRedemptionRate;
  }

  function _getBoundedPIOutput(int256 _piOutput) internal view virtual returns (int256 _boundedPIOutput) {
    _boundedPIOutput = _piOutput;
    if (_piOutput < _params.feedbackOutputLowerBound) {
      _boundedPIOutput = _params.feedbackOutputLowerBound;
    } else if (_piOutput > _params.feedbackOutputUpperBound.toInt()) {
      _boundedPIOutput = int256(_params.feedbackOutputUpperBound);
    }
    return _boundedPIOutput;
  }

  // --- Rate Validation/Calculation ---

  /// @inheritdoc IPIDController
  function computeRate(uint256 _marketPrice, uint256 _redemptionPrice) external returns (uint256 _newRedemptionRate) {
    if (msg.sender != seedProposer) revert PIDController_OnlySeedProposer();
    // Ensure that at least integralPeriodSize seconds passed since the last update or that this is the first update
    if (_timeSinceLastUpdate() < _params.integralPeriodSize && _deviationObservation.timestamp != 0) {
      revert PIDController_ComputeRateCooldown();
    }
    int256 _proportionalTerm = _getProportionalTerm(_marketPrice, _redemptionPrice);
    // Update the integral term by passing the proportional (current deviation) and the total leak that will be applied to the integral
    uint256 _accumulatedLeak = _params.perSecondCumulativeLeak.rpow(_timeSinceLastUpdate());
    int256 _integralTerm = _updateDeviation(_proportionalTerm, _accumulatedLeak);
    // Multiply P by Kp and I by Ki and then sum P & I in order to return the result
    int256 _piOutput = _getGainAdjustedPIOutput(_proportionalTerm, _integralTerm);
    // If the P * Kp + I * Ki output breaks the noise barrier, you can recompute a non null rate
    if (_breaksNoiseBarrier(Math.absolute(_piOutput), _redemptionPrice)) {
      // Get the new redemption rate by taking into account the feedbackOutputUpperBound and feedbackOutputLowerBound
      return _getBoundedRedemptionRate(_piOutput);
    } else {
      // If controller output is below noise barrier, return RAY
      return RAY;
    }
  }

  function _getProportionalTerm(
    uint256 _marketPrice,
    uint256 _redemptionPrice
  ) internal view virtual returns (int256 _proportionalTerm) {
    // Scale the market price by 10^9 so it also has 27 decimals like the redemption price
    uint256 _scaledMarketPrice = _marketPrice * 1e9;

    // Calculate the proportional term as (redemptionPrice - marketPrice) * RAY / redemptionPrice
    _proportionalTerm = _redemptionPrice.sub(_scaledMarketPrice).rdiv(int256(_redemptionPrice)); // safe cast: cannot overflow because minuend of sub

    return _proportionalTerm;
  }

  /// @inheritdoc IPIDController
  function breaksNoiseBarrier(uint256 _piSum, uint256 _redemptionPrice) external view virtual returns (bool _breaksNb) {
    return _breaksNoiseBarrier(_piSum, _redemptionPrice);
  }

  function _breaksNoiseBarrier(uint256 _piSum, uint256 _redemptionPrice) internal view virtual returns (bool _breaksNb) {
    if (_piSum == 0) return false;
    uint256 _deltaNoise = 2 * WAD - _params.noiseBarrier;
    return _piSum >= _redemptionPrice.wmul(_deltaNoise) - _redemptionPrice;
  }

  /// @inheritdoc IPIDController
  function getGainAdjustedPIOutput(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) external view returns (int256 _gainAdjustedPIOutput) {
    return _getGainAdjustedPIOutput(_proportionalTerm, _integralTerm);
  }

  function _getGainAdjustedPIOutput(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) internal view virtual returns (int256 _adjsutedPIOutput) {
    (int256 _adjustedProportional, int256 _adjustedIntegral) = _getGainAdjustedTerms(_proportionalTerm, _integralTerm);
    return (_adjustedProportional + _adjustedIntegral);
  }

  function _getGainAdjustedTerms(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) internal view virtual returns (int256 _ajustedProportionalTerm, int256 _adjustedIntegralTerm) {
    return (_controllerGains.kp.wmul(_proportionalTerm), _controllerGains.ki.wmul(_integralTerm));
  }

  /// @inheritdoc IPIDController
  function getGainAdjustedTerms(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) external view returns (int256 _ajustedProportionalTerm, int256 _adjustedIntegralTerm) {
    return _getGainAdjustedTerms(_proportionalTerm, _integralTerm);
  }

  /**
   * @notice Push new observations in deviationObservations while also updating priceDeviationCumulative
   * @param  _proportionalTerm The proportionalTerm
   * @param  _accumulatedLeak The total leak (similar to a negative interest rate) applied to priceDeviationCumulative before proportionalTerm is added to it
   */
  function _updateDeviation(
    int256 _proportionalTerm,
    uint256 _accumulatedLeak
  ) internal virtual returns (int256 _integralTerm) {
    int256 _appliedDeviation;
    (_integralTerm, _appliedDeviation) = _getNextDeviationCumulative(_proportionalTerm, _accumulatedLeak);
    // Update the last deviation observation
    _deviationObservation = DeviationObservation(block.timestamp, _proportionalTerm, _integralTerm);
    // Emit event to track the deviation history and the applied leak
    emit UpdateDeviation(_proportionalTerm, _integralTerm, _appliedDeviation);
  }

  /// @inheritdoc IPIDController
  function getNextDeviationCumulative(
    int256 _proportionalTerm,
    uint256 _accumulatedLeak
  ) external view returns (int256 _nextDeviationCumulative, int256 _appliedDeviation) {
    return _getNextDeviationCumulative(_proportionalTerm, _accumulatedLeak);
  }

  function _getNextDeviationCumulative(
    int256 _proportionalTerm,
    uint256 _accumulatedLeak
  ) internal view virtual returns (int256 _nextDeviationCumulative, int256 _appliedDeviation) {
    int256 _lastProportionalTerm = _deviationObservation.proportional;
    uint256 _timeElapsed = _timeSinceLastUpdate();
    int256 _newTimeAdjustedDeviation = _proportionalTerm.riemannSum(_lastProportionalTerm) * int256(_timeElapsed);
    int256 _leakedPriceCumulative = _accumulatedLeak.rmul(_deviationObservation.integral);

    return (_leakedPriceCumulative + _newTimeAdjustedDeviation, _newTimeAdjustedDeviation);
  }

  /**
   * @dev   This method is used to provide a view of the next redemption rate without updating the state of the controller
   * @inheritdoc IPIDController
   */
  function getNextRedemptionRate(
    uint256 _marketPrice,
    uint256 _redemptionPrice,
    uint256 _accumulatedLeak
  ) external view returns (uint256 _redemptionRate, int256 _proportionalTerm, int256 _integralTerm) {
    _proportionalTerm = _getProportionalTerm(_marketPrice, _redemptionPrice);
    (_integralTerm,) = _getNextDeviationCumulative(_proportionalTerm, _accumulatedLeak);
    int256 _piOutput = _getGainAdjustedPIOutput(_proportionalTerm, _integralTerm);
    if (_breaksNoiseBarrier(Math.absolute(_piOutput), _redemptionPrice)) {
      _redemptionRate = _getBoundedRedemptionRate(_piOutput);
      return (_redemptionRate, _proportionalTerm, _integralTerm);
    } else {
      return (RAY, _proportionalTerm, _integralTerm);
    }
  }

  /// @inheritdoc IPIDController
  function timeSinceLastUpdate() external view returns (uint256 _elapsed) {
    return _timeSinceLastUpdate();
  }

  function _timeSinceLastUpdate() internal view returns (uint256 _elapsed) {
    return _deviationObservation.timestamp == 0 ? 0 : block.timestamp - _deviationObservation.timestamp;
  }

  // --- Administration ---

  function _modifyParameters(bytes32 _param, bytes memory _data) internal override {
    uint256 _uint256 = _data.toUint256();
    int256 _int256 = _data.toInt256();

    if (_param == 'seedProposer') {
      seedProposer = _data.toAddress().assertNonNull();
    } else if (_param == 'noiseBarrier') {
      _params.noiseBarrier = _uint256;
    } else if (_param == 'integralPeriodSize') {
      _params.integralPeriodSize = _uint256;
    } else if (_param == 'feedbackOutputUpperBound') {
      _params.feedbackOutputUpperBound = _uint256;
    } else if (_param == 'feedbackOutputLowerBound') {
      _params.feedbackOutputLowerBound = _int256;
    } else if (_param == 'perSecondCumulativeLeak') {
      _params.perSecondCumulativeLeak = _uint256;
    } else if (_param == 'kp') {
      _controllerGains.kp = _int256;
    } else if (_param == 'ki') {
      _controllerGains.ki = _int256;
    } else if (_param == 'priceDeviationCumulative') {
      // Allows governance to set a starting value for the integral term (only when the integral gain is off)
      if (_controllerGains.ki != 0) revert PIDController_CannotSetPriceDeviationCumulative();
      _deviationObservation.integral = _int256;
    } else {
      revert UnrecognizedParam();
    }
  }

  function _validateParameters() internal view override {
    _params.integralPeriodSize.assertNonNull();
    _params.noiseBarrier.assertNonNull().assertLtEq(WAD);
    _params.feedbackOutputUpperBound.assertNonNull().assertLtEq(_POSITIVE_RATE_LIMIT);
    _params.feedbackOutputLowerBound.assertLt(0).assertGtEq(-int256(_NEGATIVE_RATE_LIMIT));
    _params.perSecondCumulativeLeak.assertLtEq(RAY);

    _controllerGains.kp.assertGtEq(-int256(WAD)).assertLtEq(int256(WAD));
    _controllerGains.ki.assertGtEq(-int256(WAD)).assertLtEq(int256(WAD));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IAuthorizable} from '@interfaces/utils/IAuthorizable.sol';
import {IModifiable} from '@interfaces/utils/IModifiable.sol';

interface IPIDController is IAuthorizable, IModifiable {
  // --- Events ---
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
    uint256 /* RAY */ perSecondCumulativeLeak;
    // The minimum percentage deviation from the redemption price that allows the contract to calculate a non null redemption rate
    uint256 /* WAD */ noiseBarrier;
    // The maximum value allowed for the redemption rate
    uint256 /* RAY */ feedbackOutputUpperBound;
    // The minimum value allowed for the redemption rate
    int256 /* RAY */ feedbackOutputLowerBound;
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
  function params() external view returns (PIDControllerParams memory _pidParams);
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
   * @notice Returns the last deviation observation, containting latest timestamp, proportional and integral terms
   */
  function deviationObservation() external view returns (DeviationObservation memory __deviationObservation);
  // solhint-disable-next-line private-vars-leading-underscore
  function _deviationObservation() external view returns (uint256 _timestamp, int256 _proportional, int256 _integral);

  /**
   * @notice Returns the Kp and Ki values used in this calculator
   * @dev    The values are expressed in WAD, Kp stands for proportional and Ki for integral terms
   */
  function controllerGains() external view returns (ControllerGains memory _cGains);
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
   */
  function computeRate(uint256 _marketPrice, uint256 _redemptionPrice) external returns (uint256 _redemptionRate);

  /**
   * @notice Apply Kp to the proportional term and Ki to the integral term (by multiplication) and then sum P and I
   * @param  _proportionalTerm The proportional term
   * @param  _integralTerm The integral term
   */
  function getGainAdjustedPIOutput(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) external view returns (int256 _piOutput);

  /**
   * @notice Independently return and calculate P * Kp and I * Ki
   * @param  _proportionalTerm The proportional term
   * @param  _integralTerm The integral term
   */
  function getGainAdjustedTerms(
    int256 _proportionalTerm,
    int256 _integralTerm
  ) external view returns (int256 _proportionalGain, int256 _integralGain);

  /**
   * @notice Compute a new priceDeviationCumulative (integral term)
   * @param  _proportionalTerm The proportional term (redemptionPrice - marketPrice)
   * @param  _accumulatedLeak The total leak applied to priceDeviationCumulative before it is summed with the new time adjusted deviation
   */
  function getNextDeviationCumulative(
    int256 _proportionalTerm,
    uint256 _accumulatedLeak
  ) external returns (int256 _priceDeviationCumulative, int256 _timeAdjustedDeviation);

  /**
   * @notice Returns whether the P + I sum exceeds the noise barrier
   * @param  _piSum Represents a sum between P + I
   * @param  _redemptionPrice The system coin redemption price
   */
  function breaksNoiseBarrier(uint256 _piSum, uint256 _redemptionPrice) external view returns (bool _breaksNb);

  /**
   * @notice Compute and return the upcoming redemption rate
   * @param _marketPrice The system coin market price
   * @param _redemptionPrice The system coin redemption price
   * @param _accumulatedLeak The total leak applied to priceDeviationCumulative before it is summed with the proportionalTerm
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
uint256 constant HOUR = 3600;
uint256 constant YEAR = 365 days;
uint256 constant HUNDRED = 100;

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
  error UnrecognizedCollateralType();

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