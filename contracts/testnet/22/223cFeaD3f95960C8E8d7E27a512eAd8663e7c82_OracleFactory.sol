// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../access/OwnerIsCreator.sol";
import "../BinanceAggregator.sol";
import "../access/SignatureWriteAccessController.sol";
import "../access/PairReadAccessController.sol";
import "../access/AggregatorReadWriteAccessController.sol";
import "../OnChainOracle.sol";
import "../FeedRegistry.sol";
import "../FeedAdapter.sol";
import "../interfaces/OracleFactoryInterface.sol";

/**
 * The OracleFactory owns all the deployed contracts and performs deployment related tasks
 *
 */
contract OracleFactory is OracleFactoryInterface, OwnerIsCreator {
  FeedRegistry public immutable REGISTRY;
  OnChainOracle public immutable ORACLE;
  AggregatorReadWriteAccessController public immutable AGG_ACCESS_CONTROLLER;
  PairReadAccessController public immutable REGISTRY_ACCESS_CONTROLLER;

  constructor(
    FeedRegistry registry,
    OnChainOracle oracle,
    AggregatorReadWriteAccessController aggregatorAccessController,
    PairReadAccessController registryAccessController
  ) {
    require(
      address(registry) != address(0) &&
        address(oracle) != address(0) &&
        address(aggregatorAccessController) != address(0) &&
        address(registryAccessController) != address(0),
      "Must provide proper addresses of deployed contracts"
    );
    REGISTRY = registry;
    ORACLE = oracle;
    AGG_ACCESS_CONTROLLER = aggregatorAccessController;
    REGISTRY_ACCESS_CONTROLLER = registryAccessController;
  }

  modifier isOwnerOfAllDeployedContracts() {
    require(
      ORACLE.owner() == address(this) &&
        REGISTRY.owner() == address(this) &&
        AGG_ACCESS_CONTROLLER.owner() == address(this) &&
        REGISTRY_ACCESS_CONTROLLER.owner() == address(this),
      "Oracle factory is not the current owner of all the deployed contracts"
    );
    _;
  }

  function acceptAllOwnerships() external override onlyOwner {
    REGISTRY.acceptOwnership();
    ORACLE.acceptOwnership();
    REGISTRY_ACCESS_CONTROLLER.acceptOwnership();
    AGG_ACCESS_CONTROLLER.acceptOwnership();
  }

  /**
   * Transfer all base contract ownerships to a newly created OracleFactory
   */
  function transferOwnershipToNewOracleFactory(OracleFactoryInterface newOracleFactoryAddress)
    external
    onlyOwner
    isOwnerOfAllDeployedContracts
  {
    REGISTRY.transferOwnership(address(newOracleFactoryAddress));
    ORACLE.transferOwnership(address(newOracleFactoryAddress));
    REGISTRY_ACCESS_CONTROLLER.transferOwnership(address(newOracleFactoryAddress));
    AGG_ACCESS_CONTROLLER.transferOwnership(address(newOracleFactoryAddress));
  }

  function setUpBasicAccessControl() external onlyOwner isOwnerOfAllDeployedContracts {
    AGG_ACCESS_CONTROLLER.addWriteAccess(address(ORACLE));
    AGG_ACCESS_CONTROLLER.addReadAccess(address(REGISTRY));
  }

  // Add a new pair. Overwrites pair configuration if it already exists
  function addNewTradingPair(
    string memory pair_,
    string memory baseAsString_,
    string memory quoteAsString_,
    address base_,
    address quote_,
    uint8 decimals_,
    string memory description_,
    bool storeHistoricalData_
  ) external onlyOwner {
    BinanceAggregator agg = new BinanceAggregator(pair_, decimals_, description_, storeHistoricalData_);
    ORACLE.addAggregatorForPair(pair_, agg);
    REGISTRY.proposeFeed(base_, quote_, address(agg));
    REGISTRY.confirmFeed(base_, quote_, address(agg));
    FeedAdapter adapter = new FeedAdapter(REGISTRY, base_, quote_);
    //Remove pair from registry if exists
    if (REGISTRY.exists(baseAsString_, quoteAsString_)) {
      REGISTRY.removePair(baseAsString_, quoteAsString_);
    }
    REGISTRY.insertPair(baseAsString_, quoteAsString_, base_, quote_, address(adapter));
    agg.setAccessController(AGG_ACCESS_CONTROLLER);
    adapter.setAccessController(REGISTRY_ACCESS_CONTROLLER);
    REGISTRY_ACCESS_CONTROLLER.addGlobalAccess(address(adapter));
  }

  /***************************************************************************
   * Section: Access control
   **************************************************************************/
  function giveSignatureAccessToOracle(address user) external onlyOwner {
    require(user != address(0));
    ORACLE.addSigner(user);
  }

  function removeSignatureAccessToOracle(address user) external onlyOwner {
    require(user != address(0));
    ORACLE.removeSigner(user);
  }

  function giveWriteAccessToOracle(address user) external onlyOwner {
    require(user != address(0));
    ORACLE.addAccess(user);
  }

  function removeWriteAccessToOracle(address user) external onlyOwner {
    require(user != address(0));
    ORACLE.removeAccess(user);
  }

  function addGlobalReadAccessToRegistry(address user) external onlyOwner {
    require(user != address(0));
    REGISTRY_ACCESS_CONTROLLER.addGlobalAccess(user);
  }

  function removeGlobalReadAccessToRegistry(address user) external onlyOwner {
    require(user != address(0));
    REGISTRY_ACCESS_CONTROLLER.removeGlobalAccess(user);
  }

  function addPairReadAccessToRegistry(
    address user,
    address base,
    address quote
  ) external onlyOwner {
    require(user != address(0));
    REGISTRY_ACCESS_CONTROLLER.addLocalAccess(user, base, quote);
  }

  function removePairReadAccessToRegistry(
    address user,
    address base,
    address quote
  ) external onlyOwner {
    require(user != address(0));
    REGISTRY_ACCESS_CONTROLLER.removeLocalAccess(user, base, quote);
  }

  function addPairOpenAccessToRegistry(address base, address quote) external onlyOwner {
    REGISTRY_ACCESS_CONTROLLER.addPairToOpenAccess(base, quote);
  }

  function removePairOpenAccessToRegistry(address base, address quote) external onlyOwner {
    REGISTRY_ACCESS_CONTROLLER.removePairFromOpenAccess(base, quote);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./interfaces/AggregatorV2V3Interface.sol";
import "./access/OwnerIsCreator.sol";
import "./access/ReadWriteAccessControlled.sol";
import "./interfaces/OracleUpdatableInterface.sol";

/**
 * @title Aggregator for a pair
 * @dev This aggregator receives price from a single permitted oracle and creates a new round or overwrites previous round depending
   on the 'storeHistoricalData' flag. This contract does not perform any aggregation and as such is a centralized aggregator
 * @author Sri Krishna Mannem
 */
contract BinanceAggregator is OracleUpdatableInterface, AggregatorV2V3Interface, ReadWriteAccessControlled {
  /***************************************************************************
   * Section: Variables used in multiple other sections
   **************************************************************************/

  /// @dev Transmission records an update request from the OnChainOracle
  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 observationsTimestamp; // when were observations made offchain
    uint64 transmissionTimestamp; // when was report received onchain
  }

  /// @dev which pair this aggregator updates. Ex: 'BTC/USD'
  string internal PAIR_NAME;
  string internal AGGREGATOR_DESCRIPTION;

  /// @dev The aggregator roundId to transmission map
  mapping(uint32 => Transmission) internal s_transmissions;

  /// @dev the next roundId to report. Latest roundId is s_reportingRoundId - 1
  uint32 internal s_reportingRoundId;

  /// @dev answers are stored in fixed-point format, with this many digits of precision
  uint8 public immutable override decimals;

  /// @notice aggregator contract version
  uint256 public constant override version = 6;

  /// @notice if true, stores all historical updates. Otherwise only stores latest data
  bool public immutable storeHistoricalData;

  /***************************************************************************
   * Section: Constructor and modifiers
   **************************************************************************/

  /**
   * @param pair_ pair this aggregator updates. Ex: 'BTC/USD'
   * @param decimals_ answers are stored in fixed-point format, with this many digits of precision
   * @param description_ short human-readable description of observable this contract's answers pertain to
   * @param storeHistoricalData_ if true, stores all historical updates. Otherwise only stores latest data
   */
  constructor(
    string memory pair_,
    uint8 decimals_,
    string memory description_,
    bool storeHistoricalData_
  ) {
    PAIR_NAME = pair_;
    decimals = decimals_;
    AGGREGATOR_DESCRIPTION = description_;
    storeHistoricalData = storeHistoricalData_;
  }

  /**
   * @dev reverts if the caller does not have write access granted by the accessController contract
   * @dev mandates a access controller contract to be set
   */
  modifier checkWriteAccess() {
    require(address(s_accessController) != address(0), "Access controller not set");
    require(s_accessController.hasWriteAccess(msg.sender), "No write access");
    _;
  }

  /**
   * @dev reverts if the caller does not have read access granted by the accessController contract
   */
  modifier checkReadAccess() {
    require(
      address(s_accessController) == address(0) || s_accessController.hasReadAccess(msg.sender),
      "No read access"
    );
    _;
  }

  /***************************************************************************
   * Section: Updater
   **************************************************************************/

  /**
   * @notice Transmit price updates for a particular pair from OnChainOracle
   * @dev When the aggregator is paused, it overwrites the latest round data
   *
   */
  function transmit(uint64 timestamp_, int192 newPrice_) external override checkWriteAccess {
    Transmission memory prior = s_transmissions[_getLatestRoundId()];
    require(timestamp_ > prior.observationsTimestamp, "Aggregator: Unexpected timestamp");
    require(block.timestamp < timestamp_ + 60 minutes, "Aggregator: Update expired");
    s_transmissions[s_reportingRoundId] = Transmission({
      answer: newPrice_,
      observationsTimestamp: timestamp_,
      transmissionTimestamp: uint32(block.timestamp)
    });
    //Store historical records when not paused
    if (storeHistoricalData) {
      s_reportingRoundId++;
    }
  }

  /**
   * @notice Pair this aggregator handles
   */
  function getPair() external view returns (string memory) {
    return PAIR_NAME;
  }

  /***************************************************************************
   * Section: v2 AggregatorInterface
   **************************************************************************/

  /**
   * @notice median from the most recent report
   */
  function latestAnswer() external view virtual override checkReadAccess returns (int256) {
    return s_transmissions[_getLatestRoundId()].answer;
  }

  /**
   * @notice timestamp of block in which last report was transmitted
   */
  function latestTimestamp() external view virtual override checkReadAccess returns (uint256) {
    return s_transmissions[_getLatestRoundId()].transmissionTimestamp;
  }

  /**
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted
   */
  function latestRound() external view virtual override checkReadAccess returns (uint256) {
    return _getLatestRoundId();
  }

  /**
   * @notice price of the asset at this round
   * @param roundId the aggregator round of the target report
   */
  function getAnswer(uint256 roundId) external view virtual override checkReadAccess returns (int256) {
    require(storeHistoricalData, "Historical data not stored");
    if (roundId > type(uint32).max) {
      return 0;
    }
    return s_transmissions[uint32(roundId)].answer;
  }

  /**
   * @notice timestamp of block in which report from given aggregator round was transmitted
   * @param roundId round to retrieve the timestamp for
   */
  function getTimestamp(uint256 roundId) external view virtual override checkReadAccess returns (uint256) {
    require(storeHistoricalData, "Historical data not stored");
    if (roundId > type(uint32).max) {
      return 0;
    }
    return s_transmissions[uint32(roundId)].transmissionTimestamp;
  }

  /***************************************************************************
   * Section: v3 AggregatorInterface
   **************************************************************************/

  /**
   * @notice human-readable description of observable this contract is reporting on
   */
  function description() external view virtual override returns (string memory) {
    return AGGREGATOR_DESCRIPTION;
  }

  /**
   * @notice details for the given aggregator round
   * @param roundId_ round to retrieve the data for
   * @return roundId roundId
   * @return answer price of the pair at this round
   * @return startedAt timestamp of when observations were made offchain
   * @return updatedAt timestamp of block in which report from given roundId was transmitted
   * @return answeredInRound roundId
   */
  function getRoundData(uint80 roundId_)
    external
    view
    virtual
    override
    checkReadAccess
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    require(storeHistoricalData, "Historical data not stored");
    if (roundId_ > type(uint32).max) {
      return (0, 0, 0, 0, 0);
    }
    Transmission memory transmission = s_transmissions[uint32(roundId_)];
    return (
      roundId_,
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp,
      roundId_
    );
  }

  /**
   * @notice aggregator details for the most recently transmitted report
   * @return roundId round to get the data for
   * @return answer price of the pair at this round
   * @return startedAt timestamp of when observations were made offchain
   * @return updatedAt timestamp of block containing latest report
   * @return answeredInRound aggregator round of latest report
   */
  function latestRoundData()
    external
    view
    virtual
    override
    checkReadAccess
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    Transmission memory transmission = s_transmissions[_getLatestRoundId()];
    return (
      _getLatestRoundId(),
      transmission.answer,
      transmission.observationsTimestamp,
      transmission.transmissionTimestamp,
      _getLatestRoundId()
    );
  }

  function _getLatestRoundId() internal view returns (uint32) {
    return s_reportingRoundId == 0 ? 0 : s_reportingRoundId - 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./EOAContext.sol";
import "../interfaces/PairReadAccessControllerInterface.sol";
import "./ConfirmedOwner.sol";

/**
 * @title PairReadAccessController
 * @notice Controls read access for FeedRegistry and FeedAdapter
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list (global access)
 * - accounts for specific pairs (local access)
 * - some pairs open to everybody
 */
contract PairReadAccessController is PairReadAccessControllerInterface, EOAContext, ConfirmedOwner(msg.sender) {
  bool private s_checkEnabled = true;
  mapping(address => bool) internal s_globalAccessList;
  mapping(address => mapping(address => mapping(address => bool))) internal s_localAccessList;
  mapping(address => mapping(address => bool)) internal s_openAccessList;

  event GlobalAccessAdded(address user);
  event GlobalAccessRemoved(address user);
  event PairAccessAdded(address user, address base, address quote);
  event PairAccessRemoved(address user, address base, address quote);
  event OpenAccessAdded(address base, address quote);
  event OpenAccessRemoved(address base, address quote);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  /**
   * @notice Returns the access of an address to an base / quote pair
   * @param user The address to whitelist
   */
  function hasGlobalAccess(address user) external view override returns (bool) {
    return !s_checkEnabled || s_globalAccessList[user] || _isEOA(user);
  }

  /**
   * @notice Checks if the pair is allowed for the given user
   * @param user The querying contract/ EOA address
   * @param base base token canonical address
   * @param quote quote token canonical address
   */
  function hasPairAccess(
    address user,
    address base,
    address quote
  ) external view override returns (bool) {
    return
      !s_checkEnabled ||
      s_globalAccessList[user] ||
      s_localAccessList[user][base][quote] ||
      s_openAccessList[base][quote] ||
      _isEOA(user);
  }

  function checkEnabled() external view returns (bool) {
    return s_checkEnabled;
  }

  /**
   * @notice Adds an address to the global access list
   * @param user The address to add
   */
  function addGlobalAccess(address user) external onlyOwner {
    _addGlobalAccess(user);
  }

  /**
   * @notice Adds an address+ pair data to the local access list
   * @param user The address to add
   * @param base base token canonical address
   * @param quote quote token canonical address
   */
  function addLocalAccess(
    address user,
    address base,
    address quote
  ) external onlyOwner {
    _addLocalAccess(user, base, quote);
  }

  /**
   * @notice Adds an address+ pair data to the local access list
   * @param base base token canonical address
   * @param quote quote token canonical address
   */
  function addPairToOpenAccess(address base, address quote) external onlyOwner {
    _addOpenAccess(base, quote);
  }

  /**
   * @notice Removes an address from the global access list
   * @param user The address to remove
   */
  function removeGlobalAccess(address user) external onlyOwner {
    _removeGlobalAccess(user);
  }

  /**
   * @notice Removes an address+ pair data from the local access list
   * @param user The address to remove
   * @param base base token canonical address
   * @param quote quote token canonical address
   */
  function removeLocalAccess(
    address user,
    address base,
    address quote
  ) external onlyOwner {
    _removeLocalAccess(user, base, quote);
  }

  /**
   * @notice Removes a pair from the open access list
   * @param base base token canonical address
   * @param quote quote token canonical address
   */
  function removePairFromOpenAccess(address base, address quote) external onlyOwner {
    _removeOpenAccess(base, quote);
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck() external onlyOwner {
    _enableAccessCheck();
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck() external onlyOwner {
    _disableAccessCheck();
  }

  function _enableAccessCheck() internal {
    if (!s_checkEnabled) {
      s_checkEnabled = true;
      emit CheckAccessEnabled();
    }
  }

  function _disableAccessCheck() internal {
    if (s_checkEnabled) {
      s_checkEnabled = false;
      emit CheckAccessDisabled();
    }
  }

  function _addGlobalAccess(address user) internal {
    if (!s_globalAccessList[user]) {
      s_globalAccessList[user] = true;
      emit GlobalAccessAdded(user);
    }
  }

  function _removeGlobalAccess(address user) internal {
    if (s_globalAccessList[user]) {
      s_globalAccessList[user] = false;
      emit GlobalAccessRemoved(user);
    }
  }

  function _addLocalAccess(
    address user,
    address base,
    address quote
  ) internal {
    if (!s_localAccessList[user][base][quote]) {
      s_localAccessList[user][base][quote] = true;
      emit PairAccessAdded(user, base, quote);
    }
  }

  function _removeLocalAccess(
    address user,
    address base,
    address quote
  ) internal {
    if (s_localAccessList[user][base][quote]) {
      s_localAccessList[user][base][quote] = false;
      emit PairAccessRemoved(user, base, quote);
    }
  }

  function _addOpenAccess(address base, address quote) internal {
    if (!s_openAccessList[base][quote]) {
      s_openAccessList[base][quote] = true;
      emit OpenAccessAdded(base, quote);
    }
  }

  function _removeOpenAccess(address base, address quote) internal {
    if (s_openAccessList[base][quote]) {
      s_openAccessList[base][quote] = false;
      emit OpenAccessRemoved(base, quote);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/FeedRegistryInterface.sol";
import "./interfaces/TypeAndVersionInterface.sol";
import "./access/OwnerIsCreator.sol";
import "./library/EnumerableTradingPairMap.sol";
import "./Denominations.sol";
import "./access/PairReadAccessControlled.sol";

/**
 * @notice An on-chain registry of trading pairs
 * @notice This contract provides a consistent address for consumers but delegates where it reads from to the owner, who is
 * trusted to update it. This registry contract works for multiple feeds, not just a single aggregator.
 * @notice Contract addresses with access can only read from the registry
 */
contract FeedRegistry is FeedRegistryInterface, TypeAndVersionInterface, PairReadAccessControlled {
  uint256 private constant PHASE_OFFSET = 64;
  uint256 private constant PHASE_SIZE = 16;
  uint256 private constant MAX_ID = 2**(PHASE_OFFSET + PHASE_SIZE) - 1;

  mapping(address => bool) private s_isAggregatorEnabled;
  mapping(address => mapping(address => AggregatorV2V3Interface)) private s_proposedAggregators;
  mapping(address => mapping(address => uint16)) private s_currentPhaseId;
  mapping(address => mapping(address => mapping(uint16 => AggregatorV2V3Interface))) private s_phaseAggregators;
  mapping(address => mapping(address => mapping(uint16 => Phase))) private s_phases;
  Denominations internal s_denominations;

  constructor() {
    s_denominations = new Denominations();
  }

  /**
   * @dev Checks if a new aggregator has been proposed for a pair
   */
  modifier hasProposal(address base, address quote) {
    require(address(s_proposedAggregators[base][quote]) != address(0), "No proposed aggregator present");
    _;
  }

  /**
   * @dev reverts if the caller does not have access to the base / quote pair
   */
  modifier checkPairAccess(address base, address quote) {
    require(_hasPairAccess(base, quote));
    _;
  }

  /**
   * @dev reverts if the caller does not have global access
   */
  modifier checkGlobalAccess() {
    require(address(s_accessController) == address(0) || s_accessController.hasGlobalAccess(msg.sender), "No access");
    _;
  }

  /***************************************************************************
   * Section: Denominations interface
   **************************************************************************/
  /**
   * @notice Total number of pairs available to query through FeedRegister
   */
  function totalPairsAvailable() external view override returns (uint256) {
    return s_denominations.totalPairsAvailable();
  }

  /**
   * @notice Retrieve all pairs available to query though FeedRegister. Each pair is (base, quote)
   */
  function getAllPairs() external view override returns (EnumerableTradingPairMap.Pair[] memory) {
    return s_denominations.getAllPairs();
  }

  /**
   * @notice check if a pair exists
   * @param base base asset name
   * @param quote quote asset name
   */
  function exists(string calldata base, string calldata quote) external view override returns (bool) {
    return s_denominations.exists(base, quote);
  }

  /**
   * @notice Retrieve details of a trading pair
   * @param base  base asset name
   * @param quote quote asset name
   */
  function getTradingPairDetails(string calldata base, string calldata quote)
    external
    view
    override
    returns (
      address,
      address,
      address
    )
  {
    return s_denominations.getTradingPairDetails(base, quote);
  }

  /**
   * @notice explicitly remove a key
   * @dev key to remove must exist.
   * @param base base asset name to remove
   * @param quote quote asset name to remove
   */
  function removePair(string calldata base, string calldata quote) external override onlyOwner {
    s_denominations.removePair(base, quote);
  }

  /**
   * @notice explicitly insert a key.
   * @dev duplicate keys are not permitted.
   * @param base base asset to insert
   * @param quote quote asset to insert
   * @param baseAssetAddress canonical address of base asset
   * @param quoteAssetAddress canonical address of quote asset
   * @param feedAdapterAddress Address of Feed Adapter contract for this pair
   */
  function insertPair(
    string calldata base,
    string calldata quote,
    address baseAssetAddress,
    address quoteAssetAddress,
    address feedAdapterAddress
  ) external override onlyOwner {
    s_denominations.insertPair(base, quote, baseAssetAddress, quoteAssetAddress, feedAdapterAddress);
  }

  /***************************************************************************
   * Section: FeedRegistry interface
   **************************************************************************/

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   */
  function decimals(address base, address quote) external view override returns (uint8) {
    return _decimals(base, quote);
  }

  /**
   * @notice represents the number of decimals the aggregator responses represent.
   * @notice inverse pairs have same precision as standard pairs and synthetic pairs have precision
   *  (p1 + p2) where p1, p2 are the precisions of the base pairs
   * @param base the base asset string name
   * @param quote the quote asset string name
   */
  function decimalsByName(string memory base, string memory quote) external view override returns (uint8) {
    if (s_denominations.exists(base, quote)) {
      (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(base, quote);
      return _decimals(baseAddress, quoteAddress);
    } else if (s_denominations.exists(quote, base)) {
      // assume user flipped the quote and base symbol
      // rename the quote symbol as 'baseAddress' and the base symbol as 'qouteAddress' from here
      (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(quote, base);
      return _decimals(baseAddress, quoteAddress);
    } else {
      (address baseAddress, address USDAddress) = s_denominations.getTradingPairAddresses(base, "USD");
      (address quoteAddress, ) = s_denominations.getTradingPairAddresses(quote, "USD");
      return _decimals(quoteAddress, USDAddress) + _decimals(baseAddress, USDAddress);
    }
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   */
  function description(address base, address quote) external view override returns (string memory) {
    return _description(base, quote);
  }

  /**
   * @notice returns the description of the aggregator the proxy points to.
   * @param base the base asset string name
   * @param quote the quote asset string name
   */
  function descriptionByName(string memory base, string memory quote) external view override returns (string memory) {
    (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(base, quote);
    return _description(baseAddress, quoteAddress);
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   */
  function version(address base, address quote) external view override returns (uint256) {
    return _version(base, quote);
  }

  /**
   * @notice the version number representing the type of aggregator the proxy
   * points to.
   * @param base the base asset string name
   * @param quote the quote asset string name
   */
  function versionByName(string memory base, string memory quote) external view override returns (uint256) {
    (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(base, quote);
    return _version(baseAddress, quoteAddress);
  }

  /**
   * @notice get data about the latest round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * @param base base asset address
   * @param quote quote asset address
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function latestRoundData(address base, address quote)
    external
    view
    override
    checkPairAccess(base, quote)
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return _latestRoundData(base, quote);
  }

  /**
   * @notice Same as latestRoundData, but with string inputs
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   */
  function latestRoundDataByName(string memory base, string memory quote)
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(base, quote);
    require(_hasPairAccess(baseAddress, quoteAddress));
    return _latestRoundData(baseAddress, quoteAddress);
  }

  /**
   * @notice Return RoundData simultaneously for multiple pairs. Need global access to
   *  use this function
   * @param bases the base asset string names
   * @param quotes the quote asset string names
   * @return answer is the answer for the given round
   */
  function getMultipleLatestRoundData(string[] memory bases, string[] memory quotes)
    external
    view
    override
    checkGlobalAccess
    returns (RoundData[] memory)
  {
    require(bases.length == quotes.length, "Base and quote counts are unequal");
    RoundData[] memory multipleRoundData = new RoundData[](bases.length);

    for (uint256 idx = 0; idx < bases.length; idx++) {
      (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(bases[idx], quotes[idx]);
      uint16 currentPhaseId = s_currentPhaseId[baseAddress][quoteAddress];
      AggregatorV2V3Interface aggregator = _getFeed(baseAddress, quoteAddress);
      require(address(aggregator) != address(0), "Feed not found");
      (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) = aggregator
        .latestRoundData();
      RoundData memory data;
      (data.roundId, data.answer, data.startedAt, data.updatedAt, data.answeredInRound) = _addPhaseIds(
        roundId,
        answer,
        startedAt,
        updatedAt,
        answeredInRound,
        currentPhaseId
      );
      multipleRoundData[idx] = data;
    }

    return multipleRoundData;
  }

  /**
   * @notice get data about a round. Consumers are encouraged to check
   * that they're receiving fresh data by inspecting the updatedAt and
   * answeredInRound return values.
   * @param base base asset address
   * @param quote quote asset address
   * @param _roundId the proxy round id number to retrieve the round data for
   * @return roundId is the round ID from the aggregator for which the data was
   * retrieved combined with a phase to ensure that round IDs get larger as
   * time moves forward.
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @dev Note that answer and updatedAt may change between queries.
   */
  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    override
    checkPairAccess(base, quote)
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(_roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(base, quote, phaseId);
    require(address(aggregator) != address(0), "Feed not found");
    (roundId, answer, startedAt, updatedAt, answeredInRound) = aggregator.getRoundData(aggregatorRoundId);
    return _addPhaseIds(roundId, answer, startedAt, updatedAt, answeredInRound, phaseId);
  }

  /**
   * @notice Reads the current answer for an base / quote pair's aggregator.
   * @notice This method does not return the price of a synthetic pair
   * @param base base asset address
   * @param quote quote asset address
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @return answer
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestAnswer(address base, address quote)
    external
    view
    override
    checkPairAccess(base, quote)
    returns (int256 answer)
  {
    return _getLatestAnswer(base, quote);
  }

  /**
   * @notice Return the latest price for standard pairs(USD denominated) as well as synthetic pairs (Coin denominated)
   * @notice If a standard pair is available(through CEXs or DEXs) directly return it, otherwise synthesize the
   * answer from the available pairs. Revert if not available
   * @notice Please query decimals() to receive fixed point decimals for any pair
   * @param base the base asset string name
   * @param quote the quote asset string name
   * @return answer is the answer for the given round
   */
  function latestAnswerByName(string calldata base, string calldata quote)
    external
    view
    override
    returns (int256 answer)
  {
    if (s_denominations.exists(base, quote)) {
      (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(base, quote);
      require(_hasPairAccess(baseAddress, quoteAddress));
      return _getLatestAnswer(baseAddress, quoteAddress);
    } else if (s_denominations.exists(quote, base)) {
      // assume user flipped the quote and base symbol
      // rename the quote symbol as 'baseAddress' and the base symbol as 'quoteAddress' from here
      (address baseAddress, address quoteAddress) = s_denominations.getTradingPairAddresses(quote, base);
      require(_hasPairAccess(baseAddress, quoteAddress));
      require(_getLatestAnswer(baseAddress, quoteAddress) != 0, "Divided by zero error");
      uint256 lower = _decimals(baseAddress, quoteAddress);
      return int256(10**(2 * lower)) / _getLatestAnswer(baseAddress, quoteAddress);
    } else {
      (address baseAddress, address USDAddress) = s_denominations.getTradingPairAddresses(base, "USD");
      (address quoteAddress, ) = s_denominations.getTradingPairAddresses(quote, "USD");
      require(_hasPairAccess(baseAddress, USDAddress) && _hasPairAccess(quoteAddress, USDAddress));
      require(_getLatestAnswer(quoteAddress, USDAddress) != 0, "Divided by zero error");
      uint256 lower = _decimals(quoteAddress, USDAddress);
      return
        (int256(10**(2 * lower)) * _getLatestAnswer(baseAddress, USDAddress)) /
        _getLatestAnswer(quoteAddress, USDAddress);
    }
  }

  /**
   * @notice get the latest completed timestamp where the answer was updated.
   * @param base base asset address
   * @param quote quote asset address
   * @return timestamp
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestTimestamp(address base, address quote)
    external
    view
    override
    checkPairAccess(base, quote)
    returns (uint256 timestamp)
  {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.latestTimestamp();
  }

  /**
   * @notice get the latest completed round where the answer was updated
   * @param base base asset address
   * @param quote quote asset address
   * @notice We advise to use latestRoundData() instead because it returns more in-depth information.
   * @dev Use latestRoundData instead. This does not error if no
   * answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended latestRoundData
   * instead which includes better verification information.
   */
  function latestRound(address base, address quote)
    external
    view
    override
    checkPairAccess(base, quote)
    returns (uint256 roundId)
  {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return _addPhase(currentPhaseId, uint64(aggregator.latestRound()));
  }

  /**
   * @notice get past rounds answers
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the proxy round id number to retrieve the answer for
   * @return answer
   * @notice We advise to use getRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view override checkPairAccess(base, quote) returns (int256 answer) {
    if (roundId > MAX_ID) return 0;
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(base, quote, phaseId);
    if (address(aggregator) == address(0)) return 0;
    return aggregator.getAnswer(aggregatorRoundId);
  }

  /**
   * @notice get block timestamp when an answer was last updated
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the proxy round id number to retrieve the updated timestamp for
   * @notice We advise to use getRoundData() instead because it returns more in-depth information.
   * @dev This does not error if no answer has been reached, it will simply return 0. Either wait to point to
   * an already answered Aggregator or use the recommended getRoundData
   * instead which includes better verification information.
   */
  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view override checkPairAccess(base, quote) returns (uint256 timestamp) {
    if (roundId > MAX_ID) return 0;
    (uint16 phaseId, uint64 aggregatorRoundId) = _parseIds(roundId);
    AggregatorV2V3Interface aggregator = _getPhaseFeed(base, quote, phaseId);
    if (address(aggregator) == address(0)) return 0;
    return aggregator.getTimestamp(aggregatorRoundId);
  }

  /***************************************************************************
   * Section: Convenience methods
   **************************************************************************/

  /**
   * @notice Retrieve the aggregator of an base / quote pair in the current phase
   * @param base base asset address
   * @param quote quote asset address
   * @return aggregator
   */
  function getFeed(address base, address quote) external view override returns (AggregatorV2V3Interface aggregator) {
    aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
  }

  /**
   * @notice retrieve the aggregator of an base / quote pair at a specific phase
   * @param base base asset address
   * @param quote quote asset address
   * @param phaseId phase ID
   * @return aggregator
   */
  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view override returns (AggregatorV2V3Interface aggregator) {
    aggregator = _getPhaseFeed(base, quote, phaseId);
    require(address(aggregator) != address(0), "Feed not found for phase");
  }

  /**
   * @notice returns true if a aggregator is enabled for any pair
   * @param aggregator aggregator address
   */
  function isFeedEnabled(address aggregator) external view override returns (bool) {
    return s_isAggregatorEnabled[aggregator];
  }

  /**
   * @notice returns a phase by id. A Phase contains the starting and ending aggregator round ids.
   * endingAggregatorRoundId will be 0 if the phase is the current phase
   * @dev reverts if the phase does not exist
   * @param base base asset address
   * @param quote quote asset address
   * @param phaseId phase id
   * @return phase
   */
  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view override returns (Phase memory phase) {
    phase = _getPhase(base, quote, phaseId);
    require(_phaseExists(phase), "Phase does not exist");
  }

  /**
   * @notice retrieve the aggregator of an base / quote pair at a specific round id
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the proxy round id
   */
  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view override returns (AggregatorV2V3Interface aggregator) {
    uint16 phaseId = _getPhaseIdByRoundId(base, quote, roundId);
    aggregator = _getPhaseFeed(base, quote, phaseId);
    require(address(aggregator) != address(0), "Feed not found for round");
  }

  /**
   * @notice returns the range of proxy round ids of a phase
   * @param base base asset address
   * @param quote quote asset address
   * @param phaseId phase id
   * @return startingRoundId
   * @return endingRoundId
   */
  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view override returns (uint80 startingRoundId, uint80 endingRoundId) {
    Phase memory phase = _getPhase(base, quote, phaseId);
    require(_phaseExists(phase), "Phase does not exist");

    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    if (phaseId == currentPhaseId) return _getLatestRoundRange(base, quote, currentPhaseId);
    return _getPhaseRange(base, quote, phaseId);
  }

  /**
   * @notice return the previous round id of a given round
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the round id number to retrieve the updated timestamp for
   * @dev Note that this is not the aggregator round id, but the proxy round id
   * To get full ranges of round ids of different phases, use getPhaseRange()
   * @return previousRoundId
   */
  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view override returns (uint80 previousRoundId) {
    uint16 phaseId = _getPhaseIdByRoundId(base, quote, roundId);
    return _getPreviousRoundId(base, quote, phaseId, roundId);
  }

  /**
   * @notice return the next round id of a given round
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the round id number to retrieve the updated timestamp for
   * @dev Note that this is not the aggregator round id, but the proxy round id
   * To get full ranges of round ids of different phases, use getPhaseRange()
   * @return nextRoundId
   */
  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view override returns (uint80 nextRoundId) {
    uint16 phaseId = _getPhaseIdByRoundId(base, quote, roundId);
    return _getNextRoundId(base, quote, phaseId, roundId);
  }

  /**
   * @notice Allows the owner to propose a new address for the aggregator
   * @param base base asset address
   * @param quote quote asset address
   * @param aggregator The new aggregator contract address
   */
  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external override onlyOwner {
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(base, quote);
    require(aggregator != address(currentPhaseAggregator), "Cannot propose current aggregator");
    address proposedAggregator = address(_getProposedFeed(base, quote));
    if (proposedAggregator != aggregator) {
      s_proposedAggregators[base][quote] = AggregatorV2V3Interface(aggregator);
      emit FeedProposed(base, quote, aggregator, address(currentPhaseAggregator), msg.sender);
    }
  }

  /**
   * @notice Allows the owner to confirm and change the address
   * to the proposed aggregator
   * @dev Reverts if the given address doesn't match what was previously
   * proposed
   * @param base base asset address
   * @param quote quote asset address
   * @param aggregator The new aggregator contract address
   */
  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external override onlyOwner {
    (uint16 nextPhaseId, address previousAggregator) = _setFeed(base, quote, aggregator);
    delete s_proposedAggregators[base][quote];
    s_isAggregatorEnabled[aggregator] = true;
    s_isAggregatorEnabled[previousAggregator] = false;
    emit FeedConfirmed(base, quote, aggregator, previousAggregator, nextPhaseId, msg.sender);
  }

  /**
   * @notice Returns the proposed aggregator for an base / quote pair
   * returns a zero address if there is no proposed aggregator for the pair
   * @param base base asset address
   * @param quote quote asset address
   * @return proposedAggregator
   */
  function getProposedFeed(address base, address quote)
    external
    view
    override
    returns (AggregatorV2V3Interface proposedAggregator)
  {
    return _getProposedFeed(base, quote);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param base base asset address
   * @param quote quote asset address
   * @param roundId the round ID to retrieve the round data for
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   */
  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    virtual
    override
    hasProposal(base, quote)
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregators[base][quote].getRoundData(roundId);
  }

  /**
   * @notice Used if an aggregator contract has been proposed.
   * @param base base asset address
   * @param quote quote asset address
   * @return id is the round ID for which data was retrieved
   * @return answer is the answer for the given round
   * @return startedAt is the timestamp when the round was started.
   * (Only some AggregatorV3Interface implementations return meaningful values)
   * @return updatedAt is the timestamp when the round last was updated (i.e.
   * answer was last computed)
   * @return answeredInRound is the round ID of the round in which the answer
   * was computed.
   */
  function proposedLatestRoundData(address base, address quote)
    external
    view
    virtual
    override
    hasProposal(base, quote)
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return s_proposedAggregators[base][quote].latestRoundData();
  }

  function getCurrentPhaseId(address base, address quote) external view override returns (uint16 currentPhaseId) {
    return s_currentPhaseId[base][quote];
  }

  /*
   * @notice Versioning
   */
  function typeAndVersion() external pure virtual override returns (string memory) {
    return "BinanceFeedRegistry 1.0";
  }

  /***************************************************************************
   * Section: Core functionality (Internal functions)
   **************************************************************************/

  function _decimals(address base, address quote) internal view returns (uint8) {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.decimals();
  }

  function _description(address base, address quote) internal view returns (string memory) {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.description();
  }

  function _version(address base, address quote) internal view returns (uint256) {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.version();
  }

  function _latestRoundData(address base, address quote)
    internal
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    (roundId, answer, startedAt, updatedAt, answeredInRound) = aggregator.latestRoundData();
    return _addPhaseIds(roundId, answer, startedAt, updatedAt, answeredInRound, currentPhaseId);
  }

  function _addPhase(uint16 phase, uint64 roundId) internal pure returns (uint80) {
    return uint80((uint256(phase) << PHASE_OFFSET) | roundId);
  }

  function _parseIds(uint256 roundId) internal pure returns (uint16, uint64) {
    uint16 phaseId = uint16(roundId >> PHASE_OFFSET);
    uint64 aggregatorRoundId = uint64(roundId);

    return (phaseId, aggregatorRoundId);
  }

  function _addPhaseIds(
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound,
    uint16 phaseId
  )
    internal
    pure
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    )
  {
    return (
      _addPhase(phaseId, uint64(roundId)),
      answer,
      startedAt,
      updatedAt,
      _addPhase(phaseId, uint64(answeredInRound))
    );
  }

  /**
   * @return phase
   */
  function _getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) internal view returns (Phase memory phase) {
    return s_phases[base][quote][phaseId];
  }

  function _phaseExists(Phase memory phase) internal pure returns (bool) {
    return phase.phaseId > 0;
  }

  /**
   * @return proposedAggregator
   */
  function _getProposedFeed(address base, address quote)
    internal
    view
    returns (AggregatorV2V3Interface proposedAggregator)
  {
    return s_proposedAggregators[base][quote];
  }

  /**
   * @return aggregator
   */
  function _getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) internal view returns (AggregatorV2V3Interface aggregator) {
    return s_phaseAggregators[base][quote][phaseId];
  }

  /**
   * @return aggregator
   */
  function _getFeed(address base, address quote) internal view returns (AggregatorV2V3Interface aggregator) {
    return _getPhaseFeed(base, quote, s_currentPhaseId[base][quote]);
  }

  /**
   * @return nextPhaseId
   * @return previousAggregator
   */
  function _setFeed(
    address base,
    address quote,
    address newAggregator
  ) internal returns (uint16 nextPhaseId, address previousAggregator) {
    require(newAggregator == address(s_proposedAggregators[base][quote]), "Invalid proposed aggregator");
    AggregatorV2V3Interface currentAggregator = _getFeed(base, quote);
    uint80 previousAggregatorEndingRoundId = _getLatestAggregatorRoundId(currentAggregator);
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    s_phases[base][quote][currentPhaseId].endingAggregatorRoundId = previousAggregatorEndingRoundId;

    nextPhaseId = currentPhaseId + 1;
    s_currentPhaseId[base][quote] = nextPhaseId;
    s_phaseAggregators[base][quote][nextPhaseId] = AggregatorV2V3Interface(newAggregator);
    uint80 startingRoundId = _getLatestAggregatorRoundId(AggregatorV2V3Interface(newAggregator));
    s_phases[base][quote][nextPhaseId] = Phase(nextPhaseId, startingRoundId, 0);

    return (nextPhaseId, address(currentAggregator));
  }

  function _getLatestAnswer(address base, address quote) internal view returns (int256 answer) {
    AggregatorV2V3Interface aggregator = _getFeed(base, quote);
    require(address(aggregator) != address(0), "Feed not found");
    return aggregator.latestAnswer();
  }

  function _getPreviousRoundId(
    address base,
    address quote,
    uint16 phaseId,
    uint80 roundId
  ) internal view returns (uint80) {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    for (uint16 pid = phaseId; pid > 0; pid--) {
      AggregatorV2V3Interface phaseAggregator = _getPhaseFeed(base, quote, pid);
      (uint80 startingRoundId, uint80 endingRoundId) = (pid == currentPhaseId)
        ? _getLatestRoundRange(base, quote, pid)
        : _getPhaseRange(base, quote, pid);
      if (address(phaseAggregator) == address(0)) continue;
      if (roundId <= startingRoundId) continue;
      if (roundId > startingRoundId && roundId <= endingRoundId) return roundId - 1;
      if (roundId > endingRoundId) return endingRoundId;
    }
    return 0; // Round not found
  }

  function _getNextRoundId(
    address base,
    address quote,
    uint16 phaseId,
    uint80 roundId
  ) internal view returns (uint80) {
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    for (uint16 pid = phaseId; pid <= currentPhaseId; pid++) {
      AggregatorV2V3Interface phaseAggregator = _getPhaseFeed(base, quote, pid);
      (uint80 startingRoundId, uint80 endingRoundId) = (pid == currentPhaseId)
        ? _getLatestRoundRange(base, quote, pid)
        : _getPhaseRange(base, quote, pid);
      if (address(phaseAggregator) == address(0)) continue;
      if (roundId >= endingRoundId) continue;
      if (roundId >= startingRoundId && roundId < endingRoundId) return roundId + 1;
      if (roundId < startingRoundId) return startingRoundId;
    }
    return 0; // Round not found
  }

  /**
   * @return startingRoundId
   * @return endingRoundId
   */
  function _getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) internal view returns (uint80 startingRoundId, uint80 endingRoundId) {
    Phase memory phase = _getPhase(base, quote, phaseId);
    return (_getStartingRoundId(phaseId, phase), _getEndingRoundId(phaseId, phase));
  }

  function _getLatestRoundRange(
    address base,
    address quote,
    uint16 currentPhaseId
  ) internal view returns (uint80 startingRoundId, uint80 endingRoundId) {
    Phase memory phase = s_phases[base][quote][currentPhaseId];
    return (_getStartingRoundId(currentPhaseId, phase), _getLatestRoundId(base, quote, currentPhaseId));
  }

  function _getStartingRoundId(uint16 phaseId, Phase memory phase) internal pure returns (uint80 startingRoundId) {
    return _addPhase(phaseId, uint64(phase.startingAggregatorRoundId));
  }

  function _getEndingRoundId(uint16 phaseId, Phase memory phase) internal pure returns (uint80 endingRoundId) {
    return _addPhase(phaseId, uint64(phase.endingAggregatorRoundId));
  }

  function _getLatestRoundId(
    address base,
    address quote,
    uint16 phaseId
  ) internal view returns (uint80 startingRoundId) {
    AggregatorV2V3Interface currentPhaseAggregator = _getFeed(base, quote);
    uint80 latestAggregatorRoundId = _getLatestAggregatorRoundId(currentPhaseAggregator);
    return _addPhase(phaseId, uint64(latestAggregatorRoundId));
  }

  function _getLatestAggregatorRoundId(AggregatorV2V3Interface aggregator) internal view returns (uint80 roundId) {
    if (address(aggregator) == address(0)) return uint80(0);
    return uint80(aggregator.latestRound());
  }

  function _getPhaseIdByRoundId(
    address base,
    address quote,
    uint80 roundId
  ) internal view returns (uint16 phaseId) {
    // Handle case where the round is in current phase
    uint16 currentPhaseId = s_currentPhaseId[base][quote];
    (uint80 startingCurrentRoundId, uint80 endingCurrentRoundId) = _getLatestRoundRange(base, quote, currentPhaseId);
    if (roundId >= startingCurrentRoundId && roundId <= endingCurrentRoundId) return currentPhaseId;

    // Handle case where the round is in past phases
    require(currentPhaseId > 0, "Invalid phase");
    for (uint16 pid = currentPhaseId - 1; pid > 0; pid--) {
      AggregatorV2V3Interface phaseAggregator = s_phaseAggregators[base][quote][pid];
      if (address(phaseAggregator) == address(0)) continue;
      (uint80 startingRoundId, uint80 endingRoundId) = _getPhaseRange(base, quote, pid);
      if (roundId >= startingRoundId && roundId <= endingRoundId) return pid;
      if (roundId > endingRoundId) break;
    }
    return 0;
  }

  /**
   * @dev reverts if the caller does not have access granted by the accessController contract
   * to the base / quote pair or is the contract itself.
   */
  function _hasPairAccess(address base, address quote) internal view returns (bool) {
    require(
      address(s_accessController) == address(0) ||
        s_accessController.hasGlobalAccess(msg.sender) ||
        s_accessController.hasPairAccess(msg.sender, base, quote),
      "No pair access"
    );
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./access/SignatureWriteAccessController.sol";
import "./interfaces/OnChainOracleInterface.sol";
import "./access/ECDSA.sol";
import "./interfaces/OracleUpdatableInterface.sol";

/**
 * @title Binance Oracle OnChain implementation
 * @notice OnChain acts as a staging area for price updates before sending them to the aggregators
 * @dev OnChainOracle is responsible for creating and owning aggregators when needed. It has two access controls
 * 1) Give write access control for off-chain nodes using msg.sender
 * 2) Check signature on the putBatch method
 * @author Sri Krishna Mannem
 */
contract OnChainOracle is SignatureWriteAccessController, OnChainOracleInterface {
  using ECDSA for bytes32;

  /// @notice Event with address of the last updater
  event Success(address leaderAddress);
  /// @notice Warn if a certain aggregator is not set
  event AggregatorNotSet(string pairName);

  /// @dev End aggregators to update. We need to create them manually if we add more pairs
  mapping(string => OracleUpdatableInterface) internal aggregators;

  /// @dev Current batchId. OnChain oracle only accepts next request with batchId + 1
  uint256 public batchId;

  /**
   *  @notice Signed batch update request from an authenticated off-chain Oracle
   */
  function putBatch(
    uint256 batchId_,
    bytes calldata message_,
    bytes calldata signature_
  ) external override checkAccess {
    require(batchId_ == batchId + 1, "Unexpected batchId received");

    (address source, uint64 timestamp, string[] memory pairs, int192[] memory prices) = _decodeBatchMessage(
      message_,
      signature_
    );
    require(isSignerValid(source), "Invalid signer");
    require(pairs.length == prices.length, "Unequal array lengths");

    for (uint256 i = 0; i < pairs.length; ++i) {
      if (address(aggregators[pairs[i]]) != address(0)) {
        aggregators[pairs[i]].transmit(timestamp, prices[i]);
      } else {
        emit AggregatorNotSet(pairs[i]);
      }
    }
    batchId++;
    emit Success(msg.sender); //emit already authenticated leader's address
  }

  /**
   * @dev Create an aggregator for a pair, replace if already exists
   * @param pair_  the trading pair for which to create an aggregator
   * @param aggregatorAddress  address of the aggregator for the pair
   */
  function addAggregatorForPair(string calldata pair_, OracleUpdatableInterface aggregatorAddress)
    external
    override
    onlyOwner
  {
    aggregators[pair_] = aggregatorAddress;
  }

  /**
   * Retrieve the current writable aggregator for a pair
   * @param pair_  pair to get address of the aggregator
   * @return aggregator The current mapping of aggregators
   */
  function getAggregatorForPair(string calldata pair_) external view override returns (address) {
    return address(aggregators[pair_]);
  }

  function _decodeBatchMessage(bytes calldata message_, bytes calldata signature_)
    internal
    pure
    returns (
      address,
      uint64,
      string[] memory,
      int192[] memory
    )
  {
    address source = _getSource(message_, signature_);

    // Decode the message and check the version
    (string memory version, uint64 timestamp, string[] memory pairs, int192[] memory prices) = abi.decode(
      message_,
      (string, uint64, string[], int192[])
    );
    require(keccak256(abi.encodePacked(version)) == keccak256(abi.encodePacked("v1")), "Version of data must be 'v1'");
    return (source, timestamp, pairs, prices);
  }

  /**
   * @dev Recovers the source address which signed a message
   */
  function _getSource(bytes memory message_, bytes memory signature_) internal pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = abi.decode(signature_, (bytes32, bytes32, uint8));
    return keccak256(message_).toEthSignedMessageHash().recover(v, r, s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./access/OwnerIsCreator.sol";
import "./interfaces/FeedRegistryInterface.sol";
import "./interfaces/FeedAdapterInterface.sol";
import "./access/PairReadAccessControlled.sol";

/**
 * @title Feed Adapter which conforms to ChainLink's AggregatorV2V3Interface
 * @dev Calls Feed Register to route the request
 * @author Sri Krishna Mannem
 */
contract FeedAdapter is FeedAdapterInterface, PairReadAccessControlled {
  /// @notice canonical addresses of assets and feed name
  address public immutable BASE;
  address public immutable QUOTE;

  /// @dev FeedRegistry to route requests to
  FeedRegistryInterface immutable feedRegistry;

  /// @dev answers are stored in fixed-point format, with this many digits of precision
  uint8 public immutable override decimals;

  /// @notice aggregator contract version
  uint256 public constant override version = 6;

  constructor(
    FeedRegistryInterface feedRegistry_,
    address base_,
    address quote_
  ) {
    require(base_ != address(0) && quote_ != address(0));
    feedRegistry = feedRegistry_;
    BASE = base_;
    QUOTE = quote_;
    decimals = feedRegistry_.decimals(base_, quote_);
  }

  /**
   * @dev reverts if the caller does not have read access granted by the accessController contract
   */
  modifier checkReadAccess() {
    require(
      address(s_accessController) == address(0) ||
        s_accessController.hasGlobalAccess(msg.sender) ||
        s_accessController.hasPairAccess(msg.sender, BASE, QUOTE),
      "No read access"
    );
    _;
  }

  /***************************************************************************
   * Section: v2 AggregatorInterface
   **************************************************************************/
  /**
   * @notice median from the most recent report
   */
  function latestAnswer() external view virtual override checkReadAccess returns (int256) {
    return feedRegistry.latestAnswer(BASE, QUOTE);
  }

  /**
   * @notice timestamp of block in which last report was transmitted
   */
  function latestTimestamp() external view virtual override checkReadAccess returns (uint256) {
    return feedRegistry.latestTimestamp(BASE, QUOTE);
  }

  /**
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted
   */
  function latestRound() external view virtual override checkReadAccess returns (uint256) {
    return feedRegistry.latestRound(BASE, QUOTE);
  }

  /**
   * @notice median of report from given aggregator round (NOT OCR round)
   * @param roundId the aggregator round of the target report
   */
  function getAnswer(uint256 roundId) external view virtual override checkReadAccess returns (int256) {
    return feedRegistry.getAnswer(BASE, QUOTE, roundId);
  }

  /**
   * @notice timestamp of block in which report from given aggregator round was transmitted
   * @param roundId aggregator round (NOT OCR round) of target report
   */
  function getTimestamp(uint256 roundId) external view virtual override checkReadAccess returns (uint256) {
    return feedRegistry.getTimestamp(BASE, QUOTE, roundId);
  }

  /***************************************************************************
   * Section: v3 AggregatorInterface
   **************************************************************************/

  /**
   * @notice human-readable description of observable this contract is reporting on
   */
  function description() external view virtual override returns (string memory) {
    return feedRegistry.description(BASE, QUOTE);
  }

  /**
   * @notice details for the given aggregator round
   * @param roundId target aggregator round (NOT OCR round). Must fit in uint32
   * @return roundId_ roundId
   * @return answer price of the pair at this round
   * @return startedAt timestamp of when observations were made offchain
   * @return updatedAt timestamp of block in which report from given roundId was transmitted
   * @return answeredInRound roundId
   */
  function getRoundData(uint80 roundId)
    external
    view
    virtual
    override
    checkReadAccess
    returns (
      uint80 roundId_,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return feedRegistry.getRoundData(BASE, QUOTE, roundId);
  }

  /**
   * @notice aggregator details for the most recently transmitted report
   * @return roundId aggregator round of latest report (NOT OCR round)
   * @return answer price of the pair at this round
   * @return startedAt timestamp of when observations were made offchain
   * @return updatedAt timestamp of block containing latest report
   * @return answeredInRound aggregator round of latest report
   */
  function latestRoundData()
    external
    view
    virtual
    override
    checkReadAccess
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return feedRegistry.latestRoundData(BASE, QUOTE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./OwnerIsCreator.sol";
import "../interfaces/AccessControllerInterface.sol";
import "../interfaces/SignatureAccessControllerInterface.sol";

/**
 * @title SignatureWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev Two types of accesses are controlled
 * 1) Senders of the transaction ie msg.sender
 * 2) Signers of the transaction (wallet addresses)
 */
contract SignatureWriteAccessController is
  AccessControllerInterface,
  SignatureAccessControllerInterface,
  OwnerIsCreator
{
  mapping(address => bool) internal s_accessList;
  mapping(address => bool) internal s_validSignersList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event AddedSigner(address wallet);
  event RemovedSigner(address wallet);

  /***************************************************************************
   * Section: Transaction sender access
   **************************************************************************/
  /**
   * @notice Returns the access of an address
   * @param user The address to query
   */
  function hasAccess(address user, bytes memory) public view virtual override returns (bool) {
    return s_accessList[user];
  }

  /**
   * @notice Adds an address to the access list
   * @param user The address to add
   */
  function addAccess(address user) external onlyOwner {
    if (!s_accessList[user]) {
      s_accessList[user] = true;

      emit AddedAccess(user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param user The address to remove
   */
  function removeAccess(address user) external onlyOwner {
    if (s_accessList[user]) {
      s_accessList[user] = false;

      emit RemovedAccess(user);
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }

  /***************************************************************************
   * Section: Signature access
   **************************************************************************/
  /**
   * @notice Returns the access of a signing wallet
   * @dev Signature restriction cannot be disabled
   * @param signingWallet The address to query
   */
  function isSignerValid(address signingWallet) public view virtual override returns (bool) {
    return s_validSignersList[signingWallet];
  }

  /**
   * @notice Adds a signer to the allowed signatures list
   * @param signingWallet The wallet address to allow
   */
  function addSigner(address signingWallet) external onlyOwner {
    if (!s_validSignersList[signingWallet]) {
      s_validSignersList[signingWallet] = true;
      emit AddedSigner(signingWallet);
    }
  }

  /**
   * @notice Removes a signer to the allowed signatures list
   * @param signingWallet The wallet address to remove access
   */
  function removeSigner(address signingWallet) external onlyOwner {
    if (s_validSignersList[signingWallet]) {
      s_validSignersList[signingWallet] = false;
      emit RemovedSigner(signingWallet);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ConfirmedOwner.sol";
import "../interfaces/ReadWriteAccessControllerInterface.sol";

/**
 * @title ReadWriteAccessController
 * @notice Grants read and write permissions to the aggregator
 * @dev does not make any special permissions for EOAs, see
 * ReadAccessController for that.
 */
contract AggregatorReadWriteAccessController is ReadWriteAccessControllerInterface, ConfirmedOwner(msg.sender) {
  mapping(address => bool) internal s_readAccessList;
  mapping(address => bool) internal s_writeAccessList;

  event ReadAccessAdded(address user, address sender);
  event ReadAccessRemoved(address user, address sender);
  event WriteAccessAdded(address user, address sender);
  event WriteAccessRemoved(address user, address sender);

  /**
   * @notice Returns the read access of an address
   * @param user The address to query
   */
  function hasReadAccess(address user) external view virtual override returns (bool) {
    return s_readAccessList[user];
  }

  /**
   * @notice Returns the write access of an address
   * @param user The address to query
   */
  function hasWriteAccess(address user) external view virtual override returns (bool) {
    return s_writeAccessList[user];
  }

  /**
   * @notice Revokes read access of a address if  already added
   * @param user The address to remove
   */
  function removeReadAccess(address user) external onlyOwner {
    _removeReadAccess(user);
  }

  /**
   * @notice Provide read access to a address
   * @param user The address to add
   */
  function addReadAccess(address user) external onlyOwner {
    _addReadAccess(user);
  }

  /**
   * @notice Revokes write access of a address if already added
   * @param user The address to remove
   */
  function removeWriteAccess(address user) external onlyOwner {
    _removeWriteAccess(user);
  }

  /**
   * @notice Provide write access to a address
   * @param user The address to add
   */
  function addWriteAccess(address user) external onlyOwner {
    _addWriteAccess(user);
  }

  function _addReadAccess(address user) internal {
    if (!s_readAccessList[user]) {
      s_readAccessList[user] = true;
      emit ReadAccessAdded(user, msg.sender);
    }
  }

  function _removeReadAccess(address user) internal {
    if (s_readAccessList[user]) {
      s_readAccessList[user] = false;
      emit ReadAccessRemoved(user, msg.sender);
    }
  }

  function _addWriteAccess(address user) internal {
    if (!s_writeAccessList[user]) {
      s_writeAccessList[user] = true;
      emit WriteAccessAdded(user, msg.sender);
    }
  }

  function _removeWriteAccess(address user) internal {
    if (s_writeAccessList[user]) {
      s_writeAccessList[user] = false;
      emit WriteAccessRemoved(user, msg.sender);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

interface OracleFactoryInterface {
  function acceptAllOwnerships() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ConfirmedOwner.sol";
import "../interfaces/ReadWriteAccessControllerInterface.sol";
import "../interfaces/ReadWriteAccessControlledInterface.sol";

contract ReadWriteAccessControlled is ReadWriteAccessControlledInterface, ConfirmedOwner(msg.sender) {
  ReadWriteAccessControllerInterface internal s_accessController;

  function setAccessController(ReadWriteAccessControllerInterface _accessController) external override onlyOwner {
    require(address(_accessController) != address(s_accessController), "Access controller is already set");
    s_accessController = _accessController;
    emit AccessControllerSet(address(_accessController), msg.sender);
  }

  function getAccessController() external view override returns (ReadWriteAccessControllerInterface) {
    return s_accessController;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface OracleUpdatableInterface {
  function transmit(uint64 timestamp_, int192 newPrice_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ReadWriteAccessControllerInterface.sol";

/**
 *  @notice Getters and setters for access controller
 */
interface ReadWriteAccessControlledInterface {
  event AccessControllerSet(address indexed accessController, address indexed sender);

  function setAccessController(ReadWriteAccessControllerInterface _accessController) external;

  function getAccessController() external view returns (ReadWriteAccessControllerInterface);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ReadWriteAccessControllerInterface {
  function hasReadAccess(address user) external view returns (bool);

  function hasWriteAccess(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");
    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) external override onlyOwner {
    require(to != address(0), "Cannot set owner to zero");
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() external view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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
pragma solidity 0.8.4;

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
pragma solidity 0.8.4;

interface PairReadAccessControllerInterface {
  function hasGlobalAccess(address user) external view returns (bool);

  function hasPairAccess(
    address user,
    address base,
    address quote
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/*
 * @dev Provides information about the current execution context, specifically on if an account is an EOA on that chain.
 * Different chains have different account abstractions, so this contract helps to switch behaviour between chains.
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract EOAContext {
  function _isEOA(address account) internal view virtual returns (bool) {
    return account == tx.origin; // solhint-disable-line avoid-tx-origin
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./access/OwnerIsCreator.sol";
import "./interfaces/DenominationsInterface.sol";
import "./library/EnumerableTradingPairMap.sol";

/**
 * @notice Provides functionality for maintaining trading pairs
 * @author Sri Krishna mannem
 */
contract Denominations is OwnerIsCreator, DenominationsInterface {
  using EnumerableTradingPairMap for EnumerableTradingPairMap.EnumerableMap;
  EnumerableTradingPairMap.EnumerableMap private m;

  /**
   * @notice insert a key.
   * @dev duplicate keys are not permitted.
   * @param base base asset string to insert
   * @param quote quote asset string to insert
   * @param baseAssetAddress canonical address of base asset
   * @param quoteAssetAddress canonical address of quote asset
   * @param feedAdapterAddress Address of Feed Adapter contract for this pair
   */
  function insertPair(
    string calldata base,
    string calldata quote,
    address baseAssetAddress,
    address quoteAssetAddress,
    address feedAdapterAddress
  ) external override onlyOwner {
    require(
      baseAssetAddress != address(0) && quoteAssetAddress != address(0) && feedAdapterAddress != address(0),
      "Addresses should not be null"
    );
    EnumerableTradingPairMap.TradingPairDetails memory value = EnumerableTradingPairMap.TradingPairDetails(
      baseAssetAddress,
      quoteAssetAddress,
      feedAdapterAddress
    );
    EnumerableTradingPairMap.insert(m, base, quote, value);
  }

  /**
   * @notice remove a key
   * @dev key to remove must exist.
   * @param base base asset to remove
   * @param quote quote asset to remove
   */
  function removePair(string calldata base, string calldata quote) external override onlyOwner {
    EnumerableTradingPairMap.remove(m, base, quote);
  }

  /**
   * @notice Retrieve details of a trading pair
   * @param base base asset string
   * @param quote quote asset string
   */
  function getTradingPairDetails(string calldata base, string calldata quote)
    external
    view
    override
    returns (
      address,
      address,
      address
    )
  {
    EnumerableTradingPairMap.TradingPairDetails memory details = EnumerableTradingPairMap.getTradingPair(
      m,
      base,
      quote
    );
    return (details.baseAssetAddress, details.quoteAssetAddress, details.feedAddress);
  }

  /**
   * @notice Total number of pairs available to query through FeedRegister
   */
  function totalPairsAvailable() external view override returns (uint256) {
    return EnumerableTradingPairMap.count(m);
  }

  /**
   * @notice Retrieve all pairs available to query though FeedRegister. Each pair is (base, quote)
   */
  function getAllPairs() external view override returns (EnumerableTradingPairMap.Pair[] memory) {
    return EnumerableTradingPairMap.getAllPairs(m);
  }

  /**
   * @notice Retrieve only base and quote addresses
   * @param base  base asset string
   * @param quote quote asset string
   * @return base asset address
   * @return quote asset address
   */
  function getTradingPairAddresses(string memory base, string memory quote) external view returns (address, address) {
    EnumerableTradingPairMap.TradingPairDetails memory details = EnumerableTradingPairMap.getTradingPair(
      m,
      base,
      quote
    );
    return (details.baseAssetAddress, details.quoteAssetAddress);
  }

  /**
   * @param base base asset string
   * @param quote quote asset string
   * @return bool true if a pair exists
   */
  function exists(string calldata base, string calldata quote) external view override returns (bool) {
    return EnumerableTradingPairMap.exists(m, base, quote);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AggregatorV2V3Interface.sol";
import "./DenominationsInterface.sol";

/**
 * @dev Feed registry must expose AggregatorV2V3Interface to be able to serve FeedAdapters for backward compatibility
 */
interface FeedRegistryInterface is DenominationsInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }
  struct RoundData {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
  }
  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  //Latest interface to query prices through FeedRegistry
  function decimalsByName(string memory base, string memory quote) external view returns (uint8);

  function descriptionByName(string memory base, string memory quote) external view returns (string memory);

  function versionByName(string memory base, string memory quote) external view returns (uint256);

  function latestRoundDataByName(string memory base, string memory quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestAnswerByName(string memory base, string memory quote) external view returns (int256 answer);

  function getMultipleLatestRoundData(string[] memory bases, string[] memory quotes)
    external
    view
    returns (RoundData[] memory);

  // V3 AggregatorInterface
  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 *  @notice Library providing database functionality for trading pairs
 *  @author Sri Krishna Mannem
 */
library EnumerableTradingPairMap {
  struct TradingPairDetails {
    address baseAssetAddress;
    address quoteAssetAddress;
    address feedAddress;
  }
  struct Pair {
    string baseAsset;
    string quoteAsset;
  }

  struct EnumerableMap {
    Pair[] keyList;
    mapping(bytes32 => mapping(bytes32 => uint256)) keyPointers;
    mapping(bytes32 => mapping(bytes32 => TradingPairDetails)) values;
  }

  /**
   * @notice insert a key.
   * @dev duplicate keys are not permitted.
   * @param self storage space for pairs
   * @param base base asset to insert
   * @param quote quote asset to insert
   * @param value details of the pair to insert
   */
  function insert(
    EnumerableMap storage self,
    string memory base,
    string memory quote,
    TradingPairDetails memory value
  ) internal {
    require(!exists(self, base, quote), "Key already exists");
    self.keyList.push(Pair(base, quote));
    self.keyPointers[toBytes32(base)][toBytes32(quote)] = self.keyList.length - 1;
    self.values[toBytes32(base)][toBytes32(quote)] = value;
  }

  /**
   * @notice remove a key
   * @dev key to remove must exist.
   * @param self storage space for pairs
   * @param base base asset to insert
   * @param quote quote asset to insert
   */
  function remove(
    EnumerableMap storage self,
    string memory base,
    string memory quote
  ) internal {
    require(exists(self, base, quote), "Key does not exist");
    uint256 last = count(self) - 1;
    uint256 indexToReplace = self.keyPointers[toBytes32(base)][toBytes32(quote)];
    if (indexToReplace != last) {
      Pair memory keyToMove = self.keyList[last];
      self.keyPointers[toBytes32(keyToMove.baseAsset)][toBytes32(keyToMove.quoteAsset)] = indexToReplace;
      self.keyList[indexToReplace] = keyToMove;
    }
    delete self.keyPointers[toBytes32(base)][toBytes32(quote)];
    self.keyList.pop(); //Purge last element
    delete self.values[toBytes32(base)][toBytes32(quote)];
  }

  /**
   * @notice Get trading pair details
   * @param self storage space for pairs
   * @param base base asset of pair
   * @param quote quote asset of pair
   * @return trading pair details (base address, quote address, feedAdapter address)
   */
  function getTradingPair(
    EnumerableMap storage self,
    string memory base,
    string memory quote
  ) external view returns (TradingPairDetails memory) {
    require(exists(self, base, quote), "Key does not exist");
    return self.values[toBytes32(base)][toBytes32(quote)];
  }

  /*
   * @param self storage space for pairs
   * @return all the pairs in memory (base address, quote address)
   */
  function getAllPairs(EnumerableMap storage self) external view returns (Pair[] memory) {
    return self.keyList;
  }

  /*
   * @param self storage space for pairs
   * @return total number of available pairs
   */
  function count(EnumerableMap storage self) internal view returns (uint256) {
    return (self.keyList.length);
  }

  /**
   * @notice check if a key is in the Set.
   * @param self storage space for pairs
   * @param base base asset to insert
   * @param quote quote asset to insert
   * @return bool true if a pair exists
   */
  function exists(
    EnumerableMap storage self,
    string memory base,
    string memory quote
  ) internal view returns (bool) {
    if (self.keyList.length == 0) return false;
    return
      pairToBytes32(self.keyList[self.keyPointers[toBytes32(base)][toBytes32(quote)]]) ==
      pairToBytes32(Pair(base, quote));
  }

  /**
   * @dev Compute the hash of an asset string
   */
  function toBytes32(string memory s) private pure returns (bytes32) {
    return (keccak256(bytes(s)));
  }

  /**
   * @dev Compute the hash of a trading pair
   */
  function pairToBytes32(Pair memory p) private pure returns (bytes32) {
    return keccak256(abi.encode(p.baseAsset, "/", p.quoteAsset));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ConfirmedOwner.sol";
import "../interfaces/PairReadAccessControlledInterface.sol";

contract PairReadAccessControlled is PairReadAccessControlledInterface, ConfirmedOwner(msg.sender) {
  PairReadAccessControllerInterface internal s_accessController;

  function setAccessController(PairReadAccessControllerInterface _accessController) external override onlyOwner {
    require(address(_accessController) != address(s_accessController), "Access controller is already set");
    s_accessController = _accessController;
    emit PairAccessControllerSet(address(_accessController), msg.sender);
  }

  function getAccessController() external view override returns (PairReadAccessControllerInterface) {
    return s_accessController;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface TypeAndVersionInterface {
  function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../library/EnumerableTradingPairMap.sol";

interface DenominationsInterface {
  function totalPairsAvailable() external view returns (uint256);

  function getAllPairs() external view returns (EnumerableTradingPairMap.Pair[] memory);

  function getTradingPairDetails(string calldata base, string calldata quote)
    external
    view
    returns (
      address,
      address,
      address
    );

  function insertPair(
    string calldata base,
    string calldata quote,
    address baseAssetAddress,
    address quoteAssetAddress,
    address feedAdapterAddress
  ) external;

  function removePair(string calldata base, string calldata quote) external;

  function exists(string calldata base, string calldata quote) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./PairReadAccessControllerInterface.sol";

/**
 *  @notice Getters and setters for access controller
 */
interface PairReadAccessControlledInterface {
  event PairAccessControllerSet(address indexed accessController, address indexed sender);

  function setAccessController(PairReadAccessControllerInterface _accessController) external;

  function getAccessController() external view returns (PairReadAccessControllerInterface);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "./OracleUpdatableInterface.sol";

/**
 * @title Binance Oracle OnChain
 * @notice OnChain acts as a staging area for price updates before sending them to the aggregators
 * @dev OnChainOracle is responsible for creating and owning aggregators when needed
 * @author Sri Krishna Mannem
 */
interface OnChainOracleInterface {
  /**
   *  @notice Signed batch update request from an authenticated off-chain Oracle
   */
  function putBatch(
    uint256 batchId_,
    bytes calldata message_,
    bytes calldata signature_
  ) external;

  /**
   * @dev Create an aggregator for a pair, replace if already exists
   * @param pair_  the trading pair for which to create an aggregator
   * @param aggregatorAddress  address of the aggregator for the pair
   */
  function addAggregatorForPair(string calldata pair_, OracleUpdatableInterface aggregatorAddress) external;

  /**
   * @param pair_  pair to get address of the aggregator
   * @return address The current mapping of aggregators
   */
  function getAggregatorForPair(string calldata pair_) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity 0.8.4;

import "../utils/Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
  enum RecoverError {
    NoError,
    InvalidSignature,
    InvalidSignatureLength,
    InvalidSignatureS,
    InvalidSignatureV // Deprecated in v4.8
  }

  function _throwError(RecoverError error) private pure {
    if (error == RecoverError.NoError) {
      return; // no error: do nothing
    } else if (error == RecoverError.InvalidSignature) {
      revert("ECDSA: invalid signature");
    } else if (error == RecoverError.InvalidSignatureLength) {
      revert("ECDSA: invalid signature length");
    } else if (error == RecoverError.InvalidSignatureS) {
      revert("ECDSA: invalid signature 's' value");
    }
  }

  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature` or error string. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   *
   * Documentation for signature generation:
   * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
   * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
   *
   * _Available since v4.3._
   */
  function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;
      // ecrecover takes the signature parameters, and the only way to get them
      // currently is to use assembly.
      /// @solidity memory-safe-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }
      return tryRecover(hash, v, r, s);
    } else {
      return (address(0), RecoverError.InvalidSignatureLength);
    }
  }

  /**
   * @dev Returns the address that signed a hashed message (`hash`) with
   * `signature`. This address can then be used for verification purposes.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that
   * recover to arbitrary addresses for non-hashed data. A safe way to ensure
   * this is by receiving a hash of the original message (which may otherwise
   * be too long), and then calling {toEthSignedMessageHash} on it.
   */
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, signature);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
   *
   * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
   *
   * _Available since v4.3._
   */
  function tryRecover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address, RecoverError) {
    bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    uint8 v = uint8((uint256(vs) >> 255) + 27);
    return tryRecover(hash, v, r, s);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
   *
   * _Available since v4.2._
   */
  function recover(
    bytes32 hash,
    bytes32 r,
    bytes32 vs
  ) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, r, vs);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
   * `r` and `s` signature fields separately.
   *
   * _Available since v4.3._
   */
  function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address, RecoverError) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return (address(0), RecoverError.InvalidSignatureS);
    }

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
      return (address(0), RecoverError.InvalidSignature);
    }

    return (signer, RecoverError.NoError);
  }

  /**
   * @dev Overload of {ECDSA-recover} that receives the `v`,
   * `r` and `s` signature fields separately.
   */
  function recover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) internal pure returns (address) {
    (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
    _throwError(error);
    return recovered;
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from a `hash`. This
   * produces hash corresponding to the one signed with the
   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
   * JSON-RPC method as part of EIP-191.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }

  /**
   * @dev Returns an Ethereum Signed Message, created from `s`. This
   * produces hash corresponding to the one signed with the
   * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
   * JSON-RPC method as part of EIP-191.
   *
   * See {recover}.
   */
  function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
  }

  /**
   * @dev Returns an Ethereum Signed Typed Data, created from a
   * `domainSeparator` and a `structHash`. This produces hash corresponding
   * to the one signed with the
   * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
   * JSON-RPC method as part of EIP-712.
   *
   * See {recover}.
   */
  function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface SignatureAccessControllerInterface {
  function isSignerValid(address walletAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity 0.8.4;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  /**
   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
   */
  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AggregatorV2V3Interface.sol";

interface FeedAdapterInterface is AggregatorV2V3Interface {}