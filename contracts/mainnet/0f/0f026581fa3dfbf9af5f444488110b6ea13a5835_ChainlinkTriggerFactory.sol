// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ChainlinkTrigger} from "./ChainlinkTrigger.sol";
import {FixedPriceAggregator} from "./FixedPriceAggregator.sol";
import {TriggerState} from "./structs/StateEnums.sol";
import {TriggerMetadata} from "./structs/Triggers.sol";
import {IChainlinkTrigger} from "./interfaces/IChainlinkTrigger.sol";
import {IChainlinkTriggerFactory} from "./interfaces/IChainlinkTriggerFactory.sol";

/**
 * @notice Deploys Chainlink triggers that ensure two oracles stay within the given price
 * tolerance. It also supports creating a fixed price oracle to use as the truth oracle, useful
 * for e.g. ensuring stablecoins maintain their peg.
 */
contract ChainlinkTriggerFactory is IChainlinkTriggerFactory {
  /// @notice Maps the triggerConfigId to the number of triggers created with those configs.
  mapping(bytes32 => uint256) public triggerCount;

  // We use a fixed salt because:
  //   (a) FixedPriceAggregators are just static, owner-less contracts,
  //   (b) there are no risks of bad actors taking them over on other chains,
  //   (c) it would be nice to have these aggregators deployed to the same
  //       address on each chain, and
  //   (d) it saves gas.
  // This is just the 32 bytes you get when you keccak256(abi.encode(42)).
  bytes32 internal constant FIXED_PRICE_ORACLE_SALT = 0xbeced09521047d05b8960b7e7bcc1d1292cf3e4b2a6b63f48335cbde5f7545d2;

  /// @dev Thrown when the truthOracle and trackingOracle prices cannot be directly compared.
  error InvalidOraclePair();

  /// @notice Call this function to deploy a ChainlinkTrigger.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param _metadata See TriggerMetadata for more info.
  function deployTrigger(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance,
    TriggerMetadata memory _metadata
  ) public returns (IChainlinkTrigger _trigger) {
    if (_truthOracle.decimals() != _trackingOracle.decimals()) revert InvalidOraclePair();

    bytes32 _configId = triggerConfigId(
      _truthOracle, _trackingOracle, _priceTolerance, _truthFrequencyTolerance, _trackingFrequencyTolerance
    );

    uint256 _triggerCount = triggerCount[_configId]++;

    // We use _triggerCount as the salt so that the address is the same across chains for
    // trigger contracts deployed with the same parameters.
    bytes32 _salt = _getSalt(_triggerCount);

    _trigger = IChainlinkTrigger(
      address(
        new ChainlinkTrigger{salt: _salt}(
          _truthOracle, _trackingOracle, _priceTolerance, _truthFrequencyTolerance, _trackingFrequencyTolerance
        )
      )
    );

    emit TriggerDeployed(
      address(_trigger),
      _configId,
      address(_truthOracle),
      address(_trackingOracle),
      _priceTolerance,
      _truthFrequencyTolerance,
      _trackingFrequencyTolerance,
      _metadata.name,
      _metadata.description,
      _metadata.logoURI,
      _metadata.extraData
    );
  }

  /// @notice Call this function to deploy a ChainlinkTrigger with a
  /// FixedPriceAggregator as its truthOracle. This is useful if you were
  /// configuring a safety module in which you wanted to track whether or not a stablecoin
  /// asset had become depegged.
  /// @param _price The fixed price, or peg, with which to compare the trackingOracle price.
  /// @param _decimals The number of decimals of the fixed price. This should
  /// match the number of decimals used by the desired _trackingOracle.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _frequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param _metadata See TriggerMetadata for more info.
  function deployTrigger(
    int256 _price,
    uint8 _decimals,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _frequencyTolerance,
    TriggerMetadata memory _metadata
  ) public returns (IChainlinkTrigger _trigger) {
    AggregatorV3Interface _truthOracle = deployFixedPriceAggregator(_price, _decimals);

    return deployTrigger(
      _truthOracle,
      _trackingOracle,
      _priceTolerance,
      // For the truth FixedPriceAggregator peg oracle, we use a frequency
      // tolerance of 0 since it should always return block.timestamp as the
      // updatedAt timestamp.
      0,
      _frequencyTolerance,
      _metadata
    );
  }

  /// @notice Call this function to determine the address at which a trigger
  /// with the supplied configuration would be deployed.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger would
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger would
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger would
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param _triggerCount The zero-indexed ordinal of the trigger with respect to its
  /// configuration, e.g. if this were to be the fifth trigger deployed with
  /// these configs, then _triggerCount should be 4.
  function computeTriggerAddress(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance,
    uint256 _triggerCount
  ) public view returns (address _address) {
    bytes memory _triggerConstructorArgs =
      abi.encode(_truthOracle, _trackingOracle, _priceTolerance, _truthFrequencyTolerance, _trackingFrequencyTolerance);

    // https://eips.ethereum.org/EIPS/eip-1014
    bytes32 _bytecodeHash = keccak256(bytes.concat(type(ChainlinkTrigger).creationCode, _triggerConstructorArgs));
    // We use _triggerCount as the salt so that the address is the same across chains for
    // trigger contracts deployed with the same parameters.
    bytes32 _salt = _getSalt(_triggerCount);
    bytes32 _data = keccak256(bytes.concat(bytes1(0xff), bytes20(address(this)), _salt, _bytecodeHash));
    _address = address(uint160(uint256(_data)));
  }

  /// @notice Call this function to find triggers with the specified
  /// configurations that can be used for new safety module configurations.
  /// @dev If this function returns the zero address, that means that an
  /// available trigger was not found with the supplied configuration. Use
  /// `deployTrigger` to deploy a new one.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function findAvailableTrigger(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) public view returns (address) {
    bytes32 _counterId = triggerConfigId(
      _truthOracle, _trackingOracle, _priceTolerance, _truthFrequencyTolerance, _trackingFrequencyTolerance
    );
    uint256 _triggerCount = triggerCount[_counterId];

    for (uint256 i = 0; i < _triggerCount; i++) {
      address _computedAddr = computeTriggerAddress(
        _truthOracle, _trackingOracle, _priceTolerance, _truthFrequencyTolerance, _trackingFrequencyTolerance, i
      );

      ChainlinkTrigger _trigger = ChainlinkTrigger(_computedAddr);
      if (_trigger.state() != TriggerState.TRIGGERED) return _computedAddr;
    }

    return address(0); // If none is found, return zero address.
  }

  /// @notice Call this function to determine the identifier of the supplied trigger
  /// configuration. This identifier is used both to track the number of
  /// triggers deployed with this configuration (see `triggerCount`) and is
  /// emitted at the time triggers with that configuration are deployed.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function triggerConfigId(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) public pure returns (bytes32) {
    bytes memory _triggerConstructorArgs =
      abi.encode(_truthOracle, _trackingOracle, _priceTolerance, _truthFrequencyTolerance, _trackingFrequencyTolerance);
    return keccak256(_triggerConstructorArgs);
  }

  /// @notice Call this function to deploy a FixedPriceAggregator contract,
  /// which behaves like a Chainlink oracle except that it always returns the
  /// same price.
  /// @dev If the specified contract is already deployed, we return it's address
  /// instead of reverting to avoid duplicate aggregators
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function deployFixedPriceAggregator(
    int256 _price, // An int (instead of uint256) because that's what's used by Chainlink.
    uint8 _decimals
  ) public returns (AggregatorV3Interface) {
    address _oracleAddress = computeFixedPriceAggregatorAddress(_price, _decimals);
    if (_oracleAddress.code.length > 0) return AggregatorV3Interface(_oracleAddress);
    return new FixedPriceAggregator{salt: FIXED_PRICE_ORACLE_SALT}(_decimals, _price);
  }

  /// @notice Call this function to compute the address that a
  /// FixedPriceAggregator contract would be deployed to with the provided args.
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function computeFixedPriceAggregatorAddress(
    int256 _price, // An int (instead of uint256) because that's what's used by Chainlink.
    uint8 _decimals
  ) public view returns (address) {
    bytes memory _aggregatorConstructorArgs = abi.encode(_decimals, _price);
    bytes32 _bytecodeHash = keccak256(bytes.concat(type(FixedPriceAggregator).creationCode, _aggregatorConstructorArgs));
    bytes32 _data =
      keccak256(bytes.concat(bytes1(0xff), bytes20(address(this)), FIXED_PRICE_ORACLE_SALT, _bytecodeHash));
    return address(uint160(uint256(_data)));
  }

  function _getSalt(uint256 _triggerCount) private pure returns (bytes32) {
    return keccak256(bytes.concat(bytes32(_triggerCount)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {BaseTrigger} from "./abstract/BaseTrigger.sol";
import {TriggerState} from "./structs/StateEnums.sol";

/**
 * @notice A trigger contract that takes two addresses: a truth oracle and a tracking oracle.
 * This trigger ensures the two oracles always stay within the given price tolerance; the delta
 * in prices can be equal to but not greater than the price tolerance.
 */
contract ChainlinkTrigger is BaseTrigger {
  using FixedPointMathLib for uint256;

  uint256 internal constant ZOC = 1e4;

  /// @notice The canonical oracle, assumed to be correct.
  AggregatorV3Interface public immutable truthOracle;

  /// @notice The oracle we expect to diverge.
  AggregatorV3Interface public immutable trackingOracle;

  /// @notice The maximum percent delta between oracle prices that is allowed, expressed as a zoc.
  /// For example, a 0.2e4 priceTolerance would mean the trackingOracle price is
  /// allowed to deviate from the truthOracle price by up to +/- 20%, but no more.
  /// Note that if the truthOracle returns a price of 0, we treat the priceTolerance
  /// as having been exceeded, no matter what price the trackingOracle returns.
  uint256 public immutable priceTolerance;

  /// @notice The maximum amount of time we allow to elapse before the truth oracle's price is deemed stale.
  uint256 public immutable truthFrequencyTolerance;

  /// @notice The maximum amount of time we allow to elapse before the tracking oracle's price is deemed stale.
  uint256 public immutable trackingFrequencyTolerance;

  /// @notice The scale factor to apply to the oracle with less decimals if the oracles do not have the same amount
  /// of decimals.
  uint256 public immutable scaleFactor;

  /// @notice Specifies the oracle price to scale upwards if the oracles do not have the same amount of decimals.
  OracleToScale public immutable oracleToScale;

  enum OracleToScale {
    NONE,
    TRUTH,
    TRACKING
  }

  /// @dev Thrown when the `oracle`s price is negative.
  error InvalidPrice();

  /// @dev Thrown when the `priceTolerance` is greater than or equal to `ZOC`.
  error InvalidPriceTolerance();

  /// @dev Thrown when the `oracle`s price timestamp is greater than the block's timestamp.
  error InvalidTimestamp();

  /// @dev Thrown when the `oracle`s last update is more than `frequencyTolerance` seconds ago.
  error StaleOraclePrice();

  /// @param _truthOracle The canonical oracle, assumed to be correct.
  /// @param _trackingOracle The oracle we expect to diverge.
  /// @param _priceTolerance The maximum percent delta between oracle prices that is allowed, as a zoc.
  /// @param _truthFrequencyTolerance The maximum amount of time we allow to elapse before the truth oracle's price is
  /// deemed stale.
  /// @param _trackingFrequencyTolerance The maximum amount of time we allow to elapse before the tracking oracle's
  /// price is deemed stale.
  constructor(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) BaseTrigger() {
    if (_priceTolerance >= ZOC) revert InvalidPriceTolerance();
    truthOracle = _truthOracle;
    trackingOracle = _trackingOracle;
    priceTolerance = _priceTolerance;
    truthFrequencyTolerance = _truthFrequencyTolerance;
    trackingFrequencyTolerance = _trackingFrequencyTolerance;

    OracleToScale _oracleToScale;
    uint256 _scaleFactor;
    uint256 _truthOracleDecimals = truthOracle.decimals();
    uint256 _trackingOracleDecimals = trackingOracle.decimals();
    if (_trackingOracleDecimals < _truthOracleDecimals) {
      _oracleToScale = OracleToScale.TRACKING;
      _scaleFactor = 10 ** (_truthOracleDecimals - _trackingOracleDecimals);
    } else if (_truthOracleDecimals < _trackingOracleDecimals) {
      _oracleToScale = OracleToScale.TRUTH;
      _scaleFactor = 10 ** (_trackingOracleDecimals - _truthOracleDecimals);
    }
    oracleToScale = _oracleToScale;
    scaleFactor = _scaleFactor;

    runProgrammaticCheck();
  }

  /// @notice Compares the oracle's price to the reference oracle and toggles the trigger if required.
  /// @dev This method executes the `programmaticCheck()` and makes the required state changes in the trigger.
  function runProgrammaticCheck() public returns (TriggerState) {
    // Rather than revert if not active, we simply return the state and exit.
    // Both behaviors are acceptable, but returning is friendlier to the caller
    // as they don't need to handle a revert and can simply parse the
    // transaction's logs to know if the call resulted in a state change.
    if (state != TriggerState.ACTIVE) return state;
    if (programmaticCheck()) return _updateTriggerState(TriggerState.TRIGGERED);
    return state;
  }

  /// @dev Executes logic to programmatically determine if the trigger should be toggled.
  function programmaticCheck() internal view returns (bool) {
    uint256 _truePrice = _oraclePrice(truthOracle, truthFrequencyTolerance);
    uint256 _trackingPrice = _oraclePrice(trackingOracle, trackingFrequencyTolerance);

    // If one of the oracles has fewer decimals than the other, we scale up the lower decimal price.
    if (oracleToScale == OracleToScale.TRUTH) _truePrice = _truePrice * scaleFactor;
    else if (oracleToScale == OracleToScale.TRACKING) _trackingPrice = _trackingPrice * scaleFactor;

    uint256 _priceDelta = _truePrice > _trackingPrice ? _truePrice - _trackingPrice : _trackingPrice - _truePrice;

    // We round up when calculating the delta percentage to accommodate for precision loss to
    // ensure that the state becomes triggered when the delta is greater than the price tolerance.
    // When the delta is less than or exactly equal to the price tolerance, the resulting rounded
    // up value will not be greater than the price tolerance, as expected.
    return _truePrice > 0 ? _priceDelta.mulDivUp(ZOC, _truePrice) > priceTolerance : true;
  }

  /// @dev Returns the current price of the specified `_oracle`.
  function _oraclePrice(AggregatorV3Interface _oracle, uint256 _frequencyTolerance)
    internal
    view
    returns (uint256 _price)
  {
    (, int256 _priceInt,, uint256 _updatedAt,) = _oracle.latestRoundData();
    if (_updatedAt > block.timestamp) revert InvalidTimestamp();
    if (block.timestamp - _updatedAt > _frequencyTolerance) revert StaleOraclePrice();
    if (_priceInt < 0) revert InvalidPrice();
    _price = uint256(_priceInt);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @notice An aggregator that does one thing: return a fixed price, in fixed decimals, as set
 * in the constructor.
 */
contract FixedPriceAggregator is AggregatorV3Interface {
  /// @notice The number of decimals the fixed price is represented in.
  uint8 public immutable decimals;

  /// @notice The fixed price, in the decimals indicated, returned by this oracle.
  int256 private immutable price;

  /// @param _decimals The number of decimals the fixed price is represented in.
  /// @param _price The fixed price, in the decimals indicated, to be returned by this oracle.
  constructor(uint8 _decimals, int256 _price) {
    price = _price;
    decimals = _decimals;
  }

  /// @notice A description indicating this is a fixed price oracle.
  function description() external pure returns (string memory) {
    return "Fixed price oracle";
  }

  /// @notice A version number of 0.
  function version() external pure returns (uint256) {
    return 0;
  }

  /// @notice Returns data for the specified round.
  /// @param _roundId This parameter is ignored.
  /// @return roundId 0
  /// @return answer The fixed price returned by this oracle, represented in appropriate decimals.
  /// @return startedAt 0
  /// @return updatedAt Since price is fixed, we always return the current block timestamp.
  /// @return answeredInRound 0
  function getRoundData(uint80 _roundId)
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    _roundId; // Silence unused variable compiler warning.
    return (uint80(0), price, uint256(0), block.timestamp, uint80(0));
  }

  /// @notice Returns data for the latest round.
  /// @return roundId 0
  /// @return answer The fixed price returned by this oracle, represented in appropriate decimals.
  /// @return startedAt 0
  /// @return updatedAt Since price is fixed, we always return the current block timestamp.
  /// @return answeredInRound 0
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return (uint80(0), price, uint256(0), block.timestamp, uint80(0));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

enum TriggerState {
  ACTIVE,
  TRIGGERED,
  FROZEN
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct TriggerMetadata {
  // The name that should be used for safety modules that use the trigger.
  string name;
  // A human-readable description of the trigger.
  string description;
  // The URI of a logo image to represent the trigger.
  string logoURI;
  // Extra metadata for the trigger.
  string extraData;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @notice A trigger contract that takes two addresses: a truth oracle and a tracking oracle.
 * This trigger ensures the two oracles always stay within the given price tolerance; the delta
 * in prices can be equal to but not greater than the price tolerance.
 */
interface IChainlinkTrigger {
  /// @dev Emitted when a trigger's state is updated.
  event TriggerStateUpdated(TriggerState indexed state);

  /// @notice The canonical oracle, assumed to be correct.
  function truthOracle() external view returns (AggregatorV3Interface);

  /// @notice The oracle we expect to diverge.
  function trackingOracle() external view returns (AggregatorV3Interface);

  /// @notice The current trigger state. This should never return PAUSED.
  function state() external returns (TriggerState);

  /// @notice The maximum percent delta between oracle prices that is allowed, expressed as a zoc.
  /// For example, a 0.2e4 priceTolerance would mean the trackingOracle price is
  /// allowed to deviate from the truthOracle price by up to +/- 20%, but no more.
  /// Note that if the truthOracle returns a price of 0, we treat the priceTolerance
  /// as having been exceeded, no matter what price the trackingOracle returns.
  function priceTolerance() external view returns (uint256);

  /// @notice The maximum amount of time we allow to elapse before the truth oracle's price is deemed stale.
  function truthFrequencyTolerance() external view returns (uint256);

  /// @notice The maximum amount of time we allow to elapse before the tracking oracle's price is deemed stale.
  function trackingFrequencyTolerance() external view returns (uint256);

  /// @notice Compares the oracle's price to the reference oracle and toggles the trigger if required.
  /// @dev This method executes the `programmaticCheck()` and makes the
  /// required state changes both in the trigger and the sets.
  function runProgrammaticCheck() external returns (TriggerState);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IChainlinkTrigger} from "./IChainlinkTrigger.sol";
import {TriggerMetadata} from "../structs/Triggers.sol";

/**
 * @notice Deploys Chainlink triggers that ensure two oracles stay within the given price
 * tolerance. It also supports creating a fixed price oracle to use as the truth oracle, useful
 * for e.g. ensuring stablecoins maintain their peg.
 */
interface IChainlinkTriggerFactory {
  /// @dev Emitted when the factory deploys a trigger.
  /// @param trigger Address at which the trigger was deployed.
  /// @param triggerConfigId Unique identifier of the trigger based on its configuration.
  /// @param truthOracle The address of the desired truthOracle for the trigger.
  /// @param trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param priceTolerance The priceTolerance that the deployed trigger will have. See
  /// `ChainlinkTrigger.priceTolerance()` for more information.
  /// @param truthFrequencyTolerance The frequencyTolerance that the deployed trigger will have for the truth oracle. See
  /// `ChainlinkTrigger.truthFrequencyTolerance()` for more information.
  /// @param trackingFrequencyTolerance The frequencyTolerance that the deployed trigger will have for the tracking
  /// oracle. See `ChainlinkTrigger.trackingFrequencyTolerance()` for more information.
  /// @param name The name of the trigger.
  /// @param description A human-readable description of the trigger.
  /// @param logoURI The URI of a logo image to represent the trigger.
  /// For other attributes, see the docs for the params of `deployTrigger` in
  /// this contract.
  /// @param extraData Extra metadata for the trigger.
  event TriggerDeployed(
    address trigger,
    bytes32 indexed triggerConfigId,
    address indexed truthOracle,
    address indexed trackingOracle,
    uint256 priceTolerance,
    uint256 truthFrequencyTolerance,
    uint256 trackingFrequencyTolerance,
    string name,
    string description,
    string logoURI,
    string extraData
  );

  /// @notice Maps the triggerConfigId to the number of triggers created with those configs.
  function triggerCount(bytes32) external view returns (uint256);

  /// @notice Call this function to deploy a ChainlinkTrigger.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function deployTrigger(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance,
    TriggerMetadata memory _metadata
  ) external returns (IChainlinkTrigger _trigger);

  /// @notice Call this function to deploy a ChainlinkTrigger with a
  /// FixedPriceAggregator as its truthOracle. This is useful if you were
  /// building a safety module in which you wanted to track whether or not a stablecoin
  /// asset had become depegged.
  /// @param _price The fixed price, or peg, with which to compare the trackingOracle price.
  /// @param _decimals The number of decimals of the fixed price. This should
  /// match the number of decimals used by the desired _trackingOracle.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _frequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function deployTrigger(
    int256 _price,
    uint8 _decimals,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _frequencyTolerance,
    TriggerMetadata memory _metadata
  ) external returns (IChainlinkTrigger _trigger);

  /// @notice Call this function to determine the address at which a trigger
  /// with the supplied configuration would be deployed.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger would
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger would
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger would
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  /// @param _triggerCount The zero-indexed ordinal of the trigger with respect to its
  /// configuration, e.g. if this were to be the fifth trigger deployed with
  /// these configs, then _triggerCount should be 4.
  function computeTriggerAddress(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance,
    uint256 _triggerCount
  ) external view returns (address _address);

  /// @notice Call this function to find triggers with the specified
  /// configurations that can be used for safety module configuration.
  /// @dev If this function returns the zero address, that means that an
  /// available trigger was not found with the supplied configuration. Use
  /// `deployTrigger` to deploy a new one.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function findAvailableTrigger(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) external view returns (address);

  /// @notice Call this function to determine the identifier of the supplied trigger
  /// configuration. This identifier is used both to track the number of
  /// triggers deployed with this configuration (see `triggerCount`) and is
  /// emitted at the time triggers with that configuration are deployed.
  /// @param _truthOracle The address of the desired truthOracle for the trigger.
  /// @param _trackingOracle The address of the desired trackingOracle for the trigger.
  /// @param _priceTolerance The priceTolerance that the deployed trigger will
  /// have. See ChainlinkTrigger.priceTolerance() for more information.
  /// @param _truthFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the truth oracle. See ChainlinkTrigger.truthFrequencyTolerance() for more information.
  /// @param _trackingFrequencyTolerance The frequency tolerance that the deployed trigger will
  /// have for the tracking oracle. See ChainlinkTrigger.trackingFrequencyTolerance() for more information.
  function triggerConfigId(
    AggregatorV3Interface _truthOracle,
    AggregatorV3Interface _trackingOracle,
    uint256 _priceTolerance,
    uint256 _truthFrequencyTolerance,
    uint256 _trackingFrequencyTolerance
  ) external view returns (bytes32);

  /// @notice Call this function to deploy a FixedPriceAggregator contract,
  /// which behaves like a Chainlink oracle except that it always returns the
  /// same price.
  /// @dev If the specified contract is already deployed, we return it's address
  /// instead of reverting to avoid duplicate aggregators
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function deployFixedPriceAggregator(int256 _price, uint8 _decimals) external returns (AggregatorV3Interface);

  /// @notice Call this function to compute the address that a
  /// FixedPriceAggregator contract would be deployed to with the provided args.
  /// @param _price The fixed price, in the decimals indicated, returned by the deployed oracle.
  /// @param _decimals The number of decimals of the fixed price.
  function computeFixedPriceAggregatorAddress(int256 _price, uint8 _decimals) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import {ITrigger} from "../interfaces/ITrigger.sol";
import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @dev Core trigger interface and implementation. All triggers should inherit from this to ensure they conform
 * to the required trigger interface.
 */
abstract contract BaseTrigger is ITrigger {
  /// @notice Current trigger state.
  TriggerState public state;

  /// @dev Thrown when a state update results in an invalid state transition.
  error InvalidStateTransition();

  /// @dev Child contracts should use this function to handle Trigger state transitions.
  function _updateTriggerState(TriggerState _newState) internal returns (TriggerState) {
    if (!_isValidTriggerStateTransition(state, _newState)) revert InvalidStateTransition();
    state = _newState;
    emit TriggerStateUpdated(_newState);
    return _newState;
  }

  /// @dev Reimplement this function if different state transitions are needed.
  function _isValidTriggerStateTransition(TriggerState _oldState, TriggerState _newState)
    internal
    virtual
    returns (bool)
  {
    // | From / To | ACTIVE      | FROZEN      | PAUSED   | TRIGGERED |
    // | --------- | ----------- | ----------- | -------- | --------- |
    // | ACTIVE    | -           | true        | false    | true      |
    // | FROZEN    | true        | -           | false    | true      |
    // | PAUSED    | false       | false       | -        | false     | <-- PAUSED is a safety module-level state
    // | TRIGGERED | false       | false       | false    | -         | <-- TRIGGERED is a terminal state

    if (_oldState == TriggerState.TRIGGERED) return false;
    // If oldState == newState, return true since the safety module will convert that into a no-op.
    if (_oldState == _newState) return true;
    if (_oldState == TriggerState.ACTIVE && _newState == TriggerState.FROZEN) return true;
    if (_oldState == TriggerState.FROZEN && _newState == TriggerState.ACTIVE) return true;
    if (_oldState == TriggerState.ACTIVE && _newState == TriggerState.TRIGGERED) return true;
    if (_oldState == TriggerState.FROZEN && _newState == TriggerState.TRIGGERED) return true;
    return false;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TriggerState} from "../structs/StateEnums.sol";

/**
 * @dev The minimal functions a trigger must implement to work with the Cozy Safety Module protocol.
 */
interface ITrigger {
  /// @dev Emitted when a trigger's state is updated.
  event TriggerStateUpdated(TriggerState indexed state);

  /// @notice The current trigger state.
  function state() external returns (TriggerState);
}