// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IInstance.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProvider.sol";

interface IOracle is IOracleProvider, IInstance {
    // sig: 0xb9d5b7c9
    error OracleNotFactoryError();
    // sig: 0x8852e53b
    error OracleOutOfSyncError();
    // sig: 0x0f7338e5
    error OracleOutOfOrderCommitError();

    event OracleUpdated(IOracleProvider newProvider);

    /// @dev The state for a single epoch
    struct Epoch {
        /// @dev The oracle provider for this epoch
        IOracleProvider provider;

        /// @dev The last timestamp that this oracle provider is valid
        uint96 timestamp;
    }

    /// @dev The global state for oracle
    struct Global {
        /// @dev The current epoch
        uint128 current;

        /// @dev The latest epoch
        uint128 latest;
    }

    function initialize(IOracleProvider initialProvider) external;
    function update(IOracleProvider newProvider) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/attribute/interfaces/IFactory.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProviderFactory.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IMarket.sol";
import "./IOracle.sol";

interface IOracleFactory is IOracleProviderFactory, IFactory {
    event MaxClaimUpdated(UFixed6 newMaxClaim);
    event FactoryRegistered(IOracleProviderFactory factory);
    event CallerAuthorized(IFactory caller);

    // sig: 0xe7911099
    error OracleFactoryInvalidIdError();
    // sig: 0xe232e366
    error OracleFactoryAlreadyCreatedError();
    // sig: 0xbbfaa925
    error OracleFactoryNotRegisteredError();
    // sig: 0xfeb0e18c
    error OracleFactoryNotCreatedError();
    // sig: 0x4ddc5544
    error OracleFactoryClaimTooLargeError();

    function factories(IOracleProviderFactory factory) external view returns (bool);
    function initialize(Token18 incentive) external;
    function register(IOracleProviderFactory factory) external;
    function create(bytes32 id, IOracleProviderFactory factory) external returns (IOracle newOracle);
    function update(bytes32 id, IOracleProviderFactory factory) external;
    function updateMaxClaim(UFixed6 newClaimAmount) external;
    function maxClaim() external view returns (UFixed6);
    function claim(UFixed6 amount) external;
    function callers(IFactory caller) external view returns (bool);
    function fund(IMarket market) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/attribute/interfaces/IFactory.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProviderFactory.sol";
import "./IPythOracle.sol";
import "./IOracleFactory.sol";

interface IPythFactory is IOracleProviderFactory, IFactory {
    struct Granularity {
        uint64 latestGranularity;
        uint64 currentGranularity;
        uint128 effectiveAfter;
    }

    event GranularityUpdated(uint256 newGranularity, uint256 effectiveAfter);

    // sig: 0x3d225882
    error PythFactoryNotInstanceError();
    // sig: 0xa7cc0264
    error PythFactoryInvalidGranularityError();
    // sig: 0xf2f2ce54
    error PythFactoryAlreadyCreatedError();

    function initialize(IOracleFactory oracleFactory) external;
    function create(bytes32 id) external returns (IPythOracle oracle);
    function claim(UFixed6 amount) external;
    function current() external view returns (uint256);
    function granularity() external view returns (Granularity memory);
    function updateGranularity(uint256 newGranularity) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IInstance.sol";
import "@equilibria/root/attribute/interfaces/IKept.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProvider.sol";

interface IPythOracle is IOracleProvider, IInstance, IKept {
    // sig: 0xfd13d773
    error PythOracleInvalidPriceIdError(bytes32 id);
    // sig: 0x2dd6680d
    error PythOracleNoNewVersionToCommitError();
    // sig: 0xe28e1ef4
    error PythOracleVersionIndexTooLowError();
    // sig: 0x7c423d41
    error PythOracleGracePeriodHasNotExpiredError();
    // sig: 0x8260a7e8
    error PythOracleUpdateValidForPreviousVersionError();
    // sig: 0xf0db44e4
    error PythOracleNonIncreasingPublishTimes();
    // sig: 0xb9b9867d
    error PythOracleFailedToCalculateRewardError();
    // sig: 0x95110cb6
    error PythOracleFailedToSendRewardError();
    // sig: 0x9b4e67d3
    error PythOracleVersionOutsideRangeError();
    // sig: 0xbe244fc8
    error PythOracleNonRequestedTooRecentError();

    function initialize(bytes32 id_, AggregatorV3Interface chainlinkFeed_, Token18 dsu_) external;
    function commitRequested(uint256 versionIndex, bytes calldata updateData) external payable;
    function commit(uint256 versionIndex, uint256 oracleVersion, bytes calldata updateData) external payable;

    function MIN_VALID_TIME_AFTER_VERSION() external view returns (uint256);
    function MAX_VALID_TIME_AFTER_VERSION() external view returns (uint256);
    function GRACE_PERIOD() external view returns (uint256);
    function KEEPER_REWARD_PREMIUM() external view returns (UFixed18);
    function KEEPER_BUFFER() external view returns (uint256);
    function versionList(uint256 versionIndex) external view returns (uint256);
    function versionListLength() external view returns (uint256);
    function nextVersionIndexToCommit() external view returns (uint256);
    function nextVersionToCommit() external view returns (uint256);
    function publishTimes(uint256 version) external view returns (uint256);
    function lastCommittedPublishTime() external view returns (uint256);
}

/// @dev PythStaticFee interface, this is not exposed in the AbstractPyth contract
interface IPythStaticFee {
    function singleUpdateFeeInWei() external view returns (uint);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@pythnetwork/pyth-sdk-solidity/AbstractPyth.sol";
import "@equilibria/root/attribute/Instance.sol";
import "@equilibria/root/attribute/Kept/Kept.sol";
import "../interfaces/IPythFactory.sol";

/// @title PythOracle
/// @notice Pyth implementation of the IOracle interface.
/// @dev One instance per Pyth price feed should be deployed. Multiple products may use the same
///      PythOracle instance if their payoff functions are based on the same underlying oracle.
///      This implementation only supports non-negative prices.
contract PythOracle is IPythOracle, Instance, Kept {
    /// @dev A Pyth update must come at least this long after a version to be valid
    uint256 constant public MIN_VALID_TIME_AFTER_VERSION = 4 seconds;

    /// @dev A Pyth update must come at most this long after a version to be valid
    uint256 constant public MAX_VALID_TIME_AFTER_VERSION = 10 seconds;

    /// @dev After this amount of time has passed for a version without being committed, the version can be invalidated.
    uint256 constant public GRACE_PERIOD = 1 minutes;

    /// @dev The multiplier for the keeper reward on top of cost
    UFixed18 constant public KEEPER_REWARD_PREMIUM = UFixed18.wrap(3e18);

    /// @dev The fixed gas buffer that is added to the keeper reward
    uint256 constant public KEEPER_BUFFER = 1_000_000;

    /// @dev Pyth contract
    AbstractPyth public immutable pyth;

    /// @dev Pyth price feed id
    bytes32 public id;

    /// @dev List of all requested oracle versions
    uint256[] public versionList;

    /// @dev Index in `versionList` of the next version a keeper should commit
    uint256 public nextVersionIndexToCommit;

    /// @dev Mapping from oracle version to oracle version data
    mapping(uint256 => Fixed6) private _prices;

    /// @dev Mapping from oracle version to when its VAA was published to Pyth
    mapping(uint256 => uint256) public publishTimes;

    /// @dev The time when the last committed update was published to Pyth
    uint256 public lastCommittedPublishTime;

    /// @dev The oracle version that was most recently committed
    /// @dev We assume that we cannot commit an oracle version of 0, so `_latestVersion` being 0 means that no version has been committed yet
    uint256 private _latestVersion;

    /// @notice Initializes the immutable contract state
    /// @param pyth_ Pyth contract
    constructor(AbstractPyth pyth_) {
        pyth = pyth_;
    }

    /// @notice Initializes the contract state
    /// @param id_ price ID for Pyth price feed
    /// @param chainlinkFeed_ Chainlink price feed for rewarding keeper in DSU
    /// @param dsu_ Token to pay the keeper reward in
    function initialize(bytes32 id_, AggregatorV3Interface chainlinkFeed_, Token18 dsu_) external initializer(1) {
        __Instance__initialize();
        __Kept__initialize(chainlinkFeed_, dsu_);

        if (!pyth.priceFeedExists(id_)) revert PythOracleInvalidPriceIdError(id_);

        id = id_;
    }

    function versionListLength() external view returns (uint256) {
        return versionList.length;
    }

    /// @notice Records a request for a new oracle version
    /// @dev Original sender to optionally use for callbacks
    function request(address) external onlyAuthorized {
        uint256 currentTimestamp = current();
        if (versionList.length == 0 || versionList[versionList.length - 1] != currentTimestamp) {
            versionList.push(currentTimestamp);
            emit OracleProviderVersionRequested(currentTimestamp);
        }
    }

    /// @notice Returns the latest synced oracle version and the current oracle version
    /// @return The latest synced oracle version
    /// @return The current oracle version collecting new orders
    function status() external view returns (OracleVersion memory, uint256) {
        return (latest(), current());
    }

    /// @notice Returns the latest synced oracle version
    /// @return latestVersion Latest oracle version
    function latest() public view returns (OracleVersion memory latestVersion) {
        if (_latestVersion == 0) return latestVersion;

        return latestVersion = OracleVersion(_latestVersion, _prices[_latestVersion], true);
    }

    /// @notice Returns the current oracle version accepting new orders
    /// @return Current oracle version
    function current() public view returns (uint256) {
        return IPythFactory(address(factory())).current();
    }

    /// @notice Returns the oracle version at version `version`
    /// @param timestamp The timestamp of which to lookup
    /// @return oracleVersion Oracle version at version `version`
    function at(uint256 timestamp) public view returns (OracleVersion memory oracleVersion) {
        Fixed6 price = _prices[timestamp];
        return OracleVersion(timestamp, price, !price.isZero());
    }

    /// @notice Returns the next oracle version to commit
    /// @return version The next oracle version to commit
    function nextVersionToCommit() external view returns (uint256 version) {
        if (versionList.length == 0 || nextVersionIndexToCommit >= versionList.length) return 0;
        return versionList[nextVersionIndexToCommit];
    }

    /// @notice Commits the price represented by `updateData` to the next version that needs to be committed
    /// @dev Will revert if there is an earlier versionIndex that could be committed with `updateData`
    /// @param versionIndex The index of the version to commit
    /// @param updateData The update data to commit
    function commitRequested(uint256 versionIndex, bytes calldata updateData)
        public
        payable
        keep(KEEPER_REWARD_PREMIUM, KEEPER_BUFFER, updateData, "")
    {
        // This check isn't necessary since the caller would not be able to produce a valid updateData
        // with an update time corresponding to a null version, but reverting with a specific error is
        // clearer.
        if (nextVersionIndexToCommit >= versionList.length) revert PythOracleNoNewVersionToCommitError();
        if (versionIndex < nextVersionIndexToCommit) revert PythOracleVersionIndexTooLowError();

        uint256 versionToCommit = versionList[versionIndex];
        PythStructs.Price memory pythPrice = _validateAndGetPrice(versionToCommit, updateData);

        // Price must be more recent than that of the most recently committed version
        if (pythPrice.publishTime <= lastCommittedPublishTime) revert PythOracleNonIncreasingPublishTimes();
        lastCommittedPublishTime = pythPrice.publishTime;

        // Ensure that the keeper is committing the earliest possible version
        if (versionIndex > nextVersionIndexToCommit) {
            uint256 previousVersion = versionList[versionIndex - 1];
            // We can only skip the previous version if the grace period has expired
            if (block.timestamp <= previousVersion + GRACE_PERIOD) revert PythOracleGracePeriodHasNotExpiredError();

            // If the update is valid for the previous version, we can't skip the previous version
            if (
                pythPrice.publishTime >= previousVersion + MIN_VALID_TIME_AFTER_VERSION &&
                pythPrice.publishTime <= previousVersion + MAX_VALID_TIME_AFTER_VERSION
            ) revert PythOracleUpdateValidForPreviousVersionError();
        }

        _recordPrice(versionToCommit, pythPrice);
        nextVersionIndexToCommit = versionIndex + 1;
        _latestVersion = versionToCommit;

        emit OracleProviderVersionFulfilled(versionToCommit);
    }

    /// @notice Commits the price to a non-requested version
    /// @dev This commit function may pay out a keeper reward if the committed version is valid
    ///      for the next requested version to commit. A proper `versionIndex` must be supplied in case we are
    ///      ahead of an invalidated requested version and need to verify that the provided version is valid.
    /// @param versionIndex The next committable index, taking into account any passed invalid requested versions
    /// @param oracleVersion The oracle version to commit
    /// @param updateData The update data to commit
    function commit(uint256 versionIndex, uint256 oracleVersion, bytes calldata updateData) external payable {
        // Must be before the next requested version to commit, if it exists
        // Otherwise, try to commit it as the next request version to commit
        if (
            versionList.length > versionIndex &&                // must be a requested version
            versionIndex >= nextVersionIndexToCommit &&         // must be the next (or later) requested version
            oracleVersion == versionList[versionIndex]          // must be the corresponding timestamp
        ) {
            commitRequested(versionIndex, updateData);
            return;
        }

        PythStructs.Price memory pythPrice = _validateAndGetPrice(oracleVersion, updateData);

        // Price must be more recent than that of the most recently committed version
        if (pythPrice.publishTime <= lastCommittedPublishTime) revert PythOracleNonIncreasingPublishTimes();
        lastCommittedPublishTime = pythPrice.publishTime;

        // Oracle version must be more recent than that of the most recently committed version
        uint256 minVersion = _latestVersion;
        uint256 maxVersion = versionList.length > versionIndex ? versionList[versionIndex] : current();

        if (versionIndex < nextVersionIndexToCommit) revert PythOracleVersionIndexTooLowError();
        if (versionIndex > nextVersionIndexToCommit && block.timestamp <= versionList[versionIndex - 1] + GRACE_PERIOD)
            revert PythOracleGracePeriodHasNotExpiredError();
        if (oracleVersion <= minVersion || oracleVersion >= maxVersion) revert PythOracleVersionOutsideRangeError();

        _recordPrice(oracleVersion, pythPrice);
        nextVersionIndexToCommit = versionIndex;
        _latestVersion = oracleVersion;
    }

    /// @notice Validates that update fees have been paid, and that the VAA represented by `updateData` is within `oracleVersion + MIN_VALID_TIME_AFTER_VERSION` and `oracleVersion + MAX_VALID_TIME_AFTER_VERSION`
    /// @param oracleVersion The oracle version to validate against
    /// @param updateData The update data to validate
    function _validateAndGetPrice(uint256 oracleVersion, bytes calldata updateData) private returns (PythStructs.Price memory price) {
        bytes[] memory updateDataList = new bytes[](1);
        updateDataList[0] = updateData;
        bytes32[] memory idList = new bytes32[](1);
        idList[0] = id;

        // Limit the value passed in the single update fee * number of updates to prevent packing the update data
        // with extra updates to increase the keeper fee. When Pyth updates their fee calculations
        // we will need to modify this to account for the new fee logic.
        return pyth.parsePriceFeedUpdates{value: IPythStaticFee(address(pyth)).singleUpdateFeeInWei() * idList.length}(
            updateDataList,
            idList,
            SafeCast.toUint64(oracleVersion + MIN_VALID_TIME_AFTER_VERSION),
            SafeCast.toUint64(oracleVersion + MAX_VALID_TIME_AFTER_VERSION)
        )[0].price;
    }

    /// @notice Records `price` as a Fixed6 at version `oracleVersion`
    /// @param oracleVersion The oracle version to record the price at
    /// @param price The price to record
    function _recordPrice(uint256 oracleVersion, PythStructs.Price memory price) private {
        int256 expo6Decimal = 6 + price.expo;
        _prices[oracleVersion] = (expo6Decimal < 0) ?
            Fixed6.wrap(price.price).div(Fixed6Lib.from(UFixed6Lib.from(10 ** uint256(-expo6Decimal)))) :
            Fixed6.wrap(price.price).mul(Fixed6Lib.from(UFixed6Lib.from(10 ** uint256(expo6Decimal))));
        publishTimes[oracleVersion] = price.publishTime;
    }

    /// @notice Pulls funds from the factory to reward the keeper
    /// @param keeperFee The keeper fee to pull
    function _raiseKeeperFee(UFixed18 keeperFee, bytes memory) internal virtual override {
        IPythFactory(address(factory())).claim(UFixed6Lib.from(keeperFee, true));
    }

    /// @dev Only allow authorized callers
    modifier onlyAuthorized {
        if (!IOracleProviderFactory(address(factory())).authorized(msg.sender)) revert OracleProviderUnauthorizedError();
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@equilibria/root/attribute/Kept/Kept_Arbitrum.sol";
import "./PythOracle.sol";

/// @title PythOracle_Arbitrum
/// @notice Arbitrum Kept Oracle implementation for Pyth price feeds.
/// @dev Additionally incentivizes keepers with L1 rollup fees according to the Arbitrum spec
contract PythOracle_Arbitrum is PythOracle, Kept_Arbitrum {
    constructor(AbstractPyth _pyth) PythOracle(_pyth) { }

    /// @dev Use the Kept_Arbitrum implementation for calculating the dynamic fee
    function _calculateDynamicFee(bytes memory callData) internal view override(Kept_Arbitrum, Kept) returns (UFixed18) {
        return Kept_Arbitrum._calculateDynamicFee(callData);
    }

    /// @dev Use the PythOracle implementation for raising the keeper fee
    function _raiseKeeperFee(UFixed18 amount, bytes memory data) internal override(PythOracle, Kept) {
        PythOracle._raiseKeeperFee(amount, data);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IInstance.sol";
import "@equilibria/root/number/types/UFixed6.sol";
import "@equilibria/root/token/types/Token18.sol";
import "./IOracleProvider.sol";
import "./IPayoffProvider.sol";
import "../types/OracleVersion.sol";
import "../types/MarketParameter.sol";
import "../types/RiskParameter.sol";
import "../types/Version.sol";
import "../types/Local.sol";
import "../types/Global.sol";
import "../types/Position.sol";

interface IMarket is IInstance {
    struct MarketDefinition {
        Token18 token;
        IOracleProvider oracle;
        IPayoffProvider payoff;
    }

    struct Context {
        ProtocolParameter protocolParameter;
        MarketParameter marketParameter;
        RiskParameter riskParameter;
        uint256 currentTimestamp;
        OracleVersion latestVersion;
        OracleVersion positionVersion;
        Global global;
        Local local;
        PositionContext currentPosition;
        PositionContext latestPosition;
    }

    struct PositionContext {
        Position global;
        Position local;
    }

    event Updated(address indexed sender, address indexed account, uint256 version, UFixed6 newMaker, UFixed6 newLong, UFixed6 newShort, Fixed6 collateral, bool protect);
    event PositionProcessed(uint256 indexed fromOracleVersion, uint256 indexed toOracleVersion, uint256 fromPosition, uint256 toPosition, VersionAccumulationResult accumulationResult);
    event AccountPositionProcessed(address indexed account, uint256 indexed fromOracleVersion, uint256 indexed toOracleVersion, uint256 fromPosition, uint256 toPosition, LocalAccumulationResult accumulationResult);
    event BeneficiaryUpdated(address newBeneficiary);
    event CoordinatorUpdated(address newCoordinator);
    event FeeClaimed(address indexed account, UFixed6 amount);
    event RewardClaimed(address indexed account, UFixed6 amount);
    event ParameterUpdated(MarketParameter newParameter);
    event RiskParameterUpdated(RiskParameter newRiskParameter);
    event RewardUpdated(Token18 newReward);

    // sig: 0x0fe90964
    error MarketInsufficientLiquidityError();
    // sig: 0x00e2b6a8
    error MarketInsufficientMarginError();
    // sig: 0xa8e7d409
    error MarketInsufficientMaintenanceError();
    // sig: 0x442145e5
    error MarketInsufficientCollateralError();
    // sig: 0xba555da7
    error MarketProtectedError();
    // sig: 0x6ed43d8e
    error MarketMakerOverLimitError();
    // sig: 0x29ab4c44
    error MarketClosedError();
    // sig: 0x07732aee
    error MarketCollateralBelowLimitError();
    // sig: 0x5bdace60
    error MarketOperatorNotAllowedError();
    // sig: 0x8a68c1dc
    error MarketNotSingleSidedError();
    // sig: 0x736f9fda
    error MarketOverCloseError();
    // sig: 0x935bdc21
    error MarketExceedsPendingIdLimitError();
    // sig: 0x473b50fd
    error MarketRewardAlreadySetError();
    // sig: 0x06fbf046
    error MarketInvalidRewardError();
    // sig: 0x9bca0625
    error MarketNotCoordinatorError();
    // sig: 0xb602d086
    error MarketNotBeneficiaryError();
    // sig: 0x534f7fe6
    error MarketInvalidProtectionError();
    // sig: 0xab1e3a00
    error MarketStalePriceError();
    // sig: 0x15f9ae70
    error MarketEfficiencyUnderLimitError();
    // sig: 0x7302d51a
    error MarketInvalidMarketParameterError(uint256 code);
    // sig: 0xc5f0e98a
    error MarketInvalidRiskParameterError(uint256 code);

    // sig: 0x2142bc27
    error GlobalStorageInvalidError();
    // sig: 0xc83d08ec
    error LocalStorageInvalidError();
    // sig: 0x7c53e926
    error MarketParameterStorageInvalidError();
    // sig: 0x98eb4898
    error PositionStorageLocalInvalidError();
    // sig: 0x7ecd083f
    error RiskParameterStorageInvalidError();
    // sig: 0xd2777e72
    error VersionStorageInvalidError();

    function initialize(MarketDefinition calldata definition_) external;
    function token() external view returns (Token18);
    function reward() external view returns (Token18);
    function oracle() external view returns (IOracleProvider);
    function payoff() external view returns (IPayoffProvider);
    function beneficiary() external view returns (address);
    function coordinator() external view returns (address);
    function positions(address account) external view returns (Position memory);
    function pendingPositions(address account, uint256 id) external view returns (Position memory);
    function locals(address account) external view returns (Local memory);
    function versions(uint256 timestamp) external view returns (Version memory);
    function pendingPosition(uint256 id) external view returns (Position memory);
    function position() external view returns (Position memory);
    function global() external view returns (Global memory);
    function update(address account, UFixed6 newMaker, UFixed6 newLong, UFixed6 newShort, Fixed6 collateral, bool protect) external;
    function updateBeneficiary(address newBeneficiary) external;
    function updateCoordinator(address newCoordinator) external;
    function updateReward(Token18 newReward) external;
    function parameter() external view returns (MarketParameter memory);
    function riskParameter() external view returns (RiskParameter memory);
    function updateParameter(MarketParameter memory newParameter) external;
    function updateRiskParameter(RiskParameter memory newRiskParameter) external;
    function claimFee() external;
    function claimReward() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../types/OracleVersion.sol";

/// @dev OracleVersion Invariants
///       - Each newly requested version must be increasing, but does not need to incrementing
///         - We recommend using something like timestamps or blocks for versions so that intermediary non-requested
///           versions may be posted for the purpose of expedient liquidations
///       - Versions are allowed to "fail" and will be marked as .valid = false
///       - Versions must be committed in order, i.e. all requested versions prior to latestVersion must be available
///       - Non-requested versions may be committed, but will not receive a keeper reward
///         - This is useful for immediately liquidating an account with a valid off-chain price in between orders
///         - Satisfying the above constraints, only versions more recent than the latest version may be committed
///       - Current must always be greater than Latest, never equal
///       - Request must register the same current version that was returned by Current within the same transaction
interface IOracleProvider {
    // sig: 0x652fafab
    error OracleProviderUnauthorizedError();

    event OracleProviderVersionRequested(uint256 indexed version);
    event OracleProviderVersionFulfilled(uint256 indexed version);

    function request(address account) external;
    function status() external view returns (OracleVersion memory, uint256);
    function latest() external view returns (OracleVersion memory);
    function current() external view returns (uint256);
    function at(uint256 timestamp) external view returns (OracleVersion memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../types/OracleVersion.sol";
import "./IOracleProvider.sol";

interface IOracleProviderFactory {
    event OracleCreated(IOracleProvider indexed oracle, bytes32 indexed id);

    function oracles(bytes32 id) external view returns (IOracleProvider);
    function authorized(address caller) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";

interface IPayoffProvider {
    function payoff(Fixed6 price) external pure returns (Fixed6 payoff);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/pid/types/PAccumulator6.sol";
import "./ProtocolParameter.sol";
import "./MarketParameter.sol";

/// @dev Global type
struct Global {
    /// @dev The current position ID
    uint256 currentId;

    /// @dev The latest position id
    uint256 latestId;

    /// @dev The accrued protocol fee
    UFixed6 protocolFee;

    /// @dev The accrued oracle fee
    UFixed6 oracleFee;

    /// @dev The accrued risk fee
    UFixed6 riskFee;

    /// @dev The accrued donation
    UFixed6 donation;

    /// @dev The current PAccumulator state
    PAccumulator6 pAccumulator;

    /// @dev The latest valid price
    Fixed6 latestPrice;
}
using GlobalLib for Global global;
struct GlobalStorage { uint256 slot0; uint256 slot1; }
using GlobalStorageLib for GlobalStorage global;

/// @title Global
/// @notice Holds the global market state
library GlobalLib {
    /// @notice Increments the fees by `amount` using current parameters
    /// @param self The Global object to update
    /// @param amount The amount to increment fees by
    /// @param keeper The amount to increment the keeper fee by
    /// @param marketParameter The current market parameters
    /// @param protocolParameter The current protocol parameters
    function incrementFees(
        Global memory self,
        UFixed6 amount,
        UFixed6 keeper,
        MarketParameter memory marketParameter,
        ProtocolParameter memory protocolParameter
    ) internal pure {
        UFixed6 protocolFeeAmount = amount.mul(protocolParameter.protocolFee);
        UFixed6 marketFeeAmount = amount.sub(protocolFeeAmount);

        UFixed6 oracleFeeAmount = marketFeeAmount.mul(marketParameter.oracleFee);
        UFixed6 riskFeeAmount = marketFeeAmount.mul(marketParameter.riskFee);
        UFixed6 donationAmount = marketFeeAmount.sub(oracleFeeAmount).sub(riskFeeAmount);

        self.protocolFee = self.protocolFee.add(protocolFeeAmount);
        self.oracleFee = self.oracleFee.add(keeper).add(oracleFeeAmount);
        self.riskFee = self.riskFee.add(riskFeeAmount);
        self.donation = self.donation.add(donationAmount);
    }

    /// @notice Updates the latest valid price
    /// @param self The Global object to update
    /// @param latestPrice The new latest valid price
    function update(Global memory self, uint256 latestId, Fixed6 latestPrice) internal pure {
        self.latestId = latestId;
        self.latestPrice = latestPrice;
    }
}

/// @dev Manually encodes and decodes the Global struct into storage.
///
///     struct StoredGlobal {
///         /* slot 0 */
///         uint32 currentId;           // <= 4.29b
///         uint32 latestId;            // <= 4.29b
///         uint48 protocolFee;         // <= 281m
///         uint48 oracleFee;           // <= 281m
///         uint48 riskFee;             // <= 281m
///         uint48 donation;            // <= 281m
///
///         /* slot 1 */
///         int32 pAccumulator.value;   // <= 214000%
///         int24 pAccumulator.skew;    // <= 838%
///         int64 latestPrice;          // <= 9.22t
///     }
///
library GlobalStorageLib {
    // sig: 0x2142bc27
    error GlobalStorageInvalidError();

    function read(GlobalStorage storage self) internal view returns (Global memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);
        return Global(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            uint256(slot0 << (256 - 32 - 32)) >> (256 - 32),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48 - 48 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48 - 48 - 48 - 48)) >> (256 - 48)),
            PAccumulator6(
                Fixed6.wrap(int256(slot1 << (256 - 32)) >> (256 - 32)),
                Fixed6.wrap(int256(slot1 << (256 - 32 - 24)) >> (256 - 24))
            ),
            Fixed6.wrap(int256(slot1 << (256 - 32 - 24 - 64)) >> (256 - 64))
        );
    }

    function store(GlobalStorage storage self, Global memory newValue) internal {
        if (newValue.currentId > uint256(type(uint32).max)) revert GlobalStorageInvalidError();
        if (newValue.latestId > uint256(type(uint32).max)) revert GlobalStorageInvalidError();
        if (newValue.protocolFee.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.oracleFee.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.riskFee.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.donation.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._value.gt(Fixed6.wrap(type(int32).max))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._value.lt(Fixed6.wrap(type(int32).min))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._skew.gt(Fixed6.wrap(type(int24).max))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._skew.lt(Fixed6.wrap(type(int24).min))) revert GlobalStorageInvalidError();
        if (newValue.latestPrice.gt(Fixed6.wrap(type(int64).max))) revert GlobalStorageInvalidError();
        if (newValue.latestPrice.lt(Fixed6.wrap(type(int64).min))) revert GlobalStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.currentId << (256 - 32)) >> (256 - 32) |
            uint256(newValue.latestId << (256 - 32)) >> (256 - 32 - 32) |
            uint256(UFixed6.unwrap(newValue.protocolFee) << (256 - 48)) >> (256 - 32 - 32 - 48) |
            uint256(UFixed6.unwrap(newValue.oracleFee) << (256 - 48)) >> (256 - 32 - 32 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.riskFee) << (256 - 48)) >> (256 - 32 - 32 - 48 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.donation) << (256 - 48)) >> (256 - 32 - 32 - 48 - 48 - 48 - 48);

        uint256 encoded1 =
            uint256(Fixed6.unwrap(newValue.pAccumulator._value) << (256 - 32)) >> (256 - 32) |
            uint256(Fixed6.unwrap(newValue.pAccumulator._skew) << (256 - 24)) >> (256 - 32 - 24) |
            uint256(Fixed6.unwrap(newValue.latestPrice) << (256 - 64)) >> (256 - 32 - 24 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";
import "./Position.sol";

/// @dev Invalidation type
struct Invalidation {
    /// @dev The change in the maker position
    Fixed6 maker;

    /// @dev The change in the long position
    Fixed6 long;

    /// @dev The change in the short position
    Fixed6 short;
}
using InvalidationLib for Invalidation global;

/// @title Invalidation
/// @notice Holds the state for an account's update invalidation
library InvalidationLib {
    /// @notice Increments the invalidation accumulator by an invalidation delta
    /// @param self The invalidation object to update
    /// @param latestPosition The latest position
    /// @param newPosition The pending position
    function increment(Invalidation memory self, Position memory latestPosition, Position memory newPosition) internal pure {
        self.maker = self.maker.add(Fixed6Lib.from(latestPosition.maker).sub(Fixed6Lib.from(newPosition.maker)));
        self.long = self.long.add(Fixed6Lib.from(latestPosition.long).sub(Fixed6Lib.from(newPosition.long)));
        self.short = self.short.add(Fixed6Lib.from(latestPosition.short).sub(Fixed6Lib.from(newPosition.short)));
    }

    /// @notice Returns the invalidation delta between two invalidation accumulators
    /// @param self The starting invalidation object
    /// @param invalidation The ending invalidation object
    /// @return delta The invalidation delta
    function sub(
        Invalidation memory self,
        Invalidation memory invalidation
    ) internal pure returns (Invalidation memory delta) {
        delta.maker = self.maker.sub(invalidation.maker);
        delta.long = self.long.sub(invalidation.long);
        delta.short = self.short.sub(invalidation.short);
    }

    /// @notice Replaces the invalidation with a new invalidation
    /// @param self The invalidation object to update
    /// @param newInvalidation The new invalidation object
    function update(Invalidation memory self, Invalidation memory newInvalidation) internal pure {
        (self.maker, self.long, self.short) = (newInvalidation.maker, newInvalidation.long, newInvalidation.short);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";
import "@equilibria/root/number/types/Fixed6.sol";
import "./Version.sol";
import "./Position.sol";

/// @dev Local type
struct Local {
    /// @dev The current position id
    uint256 currentId;

    /// @dev The latest position id
    uint256 latestId;

    /// @dev The collateral balance
    Fixed6 collateral;

    /// @dev The reward balance
    UFixed6 reward;

    /// @dev The protection status
    uint256 protection;
}
using LocalLib for Local global;
struct LocalStorage { uint256 slot0; }
using LocalStorageLib for LocalStorage global;

struct LocalAccumulationResult {
    Fixed6 collateralAmount;
    UFixed6 rewardAmount;
    UFixed6 positionFee;
    UFixed6 keeper;
}

/// @title Local
/// @notice Holds the local account state
library LocalLib {
    /// @notice Updates the collateral with the new collateral change
    /// @param self The Local object to update
    /// @param collateral The amount to update the collateral by
    function update(Local memory self, Fixed6 collateral) internal pure {
        self.collateral = self.collateral.add(collateral);
    }

    /// @notice Settled the local from its latest position to next position
    /// @param self The Local object to update
    /// @param fromPosition The previous latest position
    /// @param toPosition The next latest position
    /// @param fromVersion The previous latest version
    /// @param toVersion The next latest version
    /// @return values The accumulation result
    function accumulate(
        Local memory self,
        uint256 latestId,
        Position memory fromPosition,
        Position memory toPosition,
        Version memory fromVersion,
        Version memory toVersion
    ) internal pure returns (LocalAccumulationResult memory values) {
        values.collateralAmount = toVersion.makerValue.accumulated(fromVersion.makerValue, fromPosition.maker)
            .add(toVersion.longValue.accumulated(fromVersion.longValue, fromPosition.long))
            .add(toVersion.shortValue.accumulated(fromVersion.shortValue, fromPosition.short));
        values.rewardAmount = toVersion.makerReward.accumulated(fromVersion.makerReward, fromPosition.maker)
            .add(toVersion.longReward.accumulated(fromVersion.longReward, fromPosition.long))
            .add(toVersion.shortReward.accumulated(fromVersion.shortReward, fromPosition.short));
        values.positionFee = toPosition.fee;
        values.keeper = toPosition.keeper;

        Fixed6 feeAmount = Fixed6Lib.from(values.positionFee.add(values.keeper));
        self.collateral = self.collateral.add(values.collateralAmount).sub(feeAmount);
        self.reward = self.reward.add(values.rewardAmount);
        self.latestId = latestId;
    }

    /// @notice Updates the local to put it into a protected state for liquidation
    /// @param self The Local object to update
    /// @param latestPosition The latest position
    /// @param currentTimestamp The current timestamp
    /// @param tryProtect Whether to try to protect the local
    /// @return Whether the local was protected
    function protect(
        Local memory self,
        Position memory latestPosition,
        uint256 currentTimestamp,
        bool tryProtect
    ) internal pure returns (bool) {
        if (!tryProtect || self.protection > latestPosition.timestamp) return false;
        self.protection = currentTimestamp;
        return true;
    }

    /// @notice Clears the local's reward value
    /// @param self The Local object to update
    function clearReward(Local memory self) internal pure {
        self.reward = UFixed6Lib.ZERO;
    }
}

/// @dev Manually encodes and decodes the Local struct into storage.
///
///     struct StoredLocal {
///         /* slot 0 */
///         uint32 currentId;   // <= 4.29b
///         uint32 latestId;    // <= 4.29b
///         int64 collateral;   // <= 9.22t
///         uint64 reward;      // <= 18.44t
///         uint32 protection;  // <= 4.29b
///     }
///
library LocalStorageLib {
    // sig: 0xc83d08ec
    error LocalStorageInvalidError();

    function read(LocalStorage storage self) internal view returns (Local memory) {
        uint256 slot0 = self.slot0;
        return Local(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            uint256(slot0 << (256 - 32 - 32)) >> (256 - 32),
            Fixed6.wrap(int256(slot0 << (256 - 32 - 32 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 64 - 64)) >> (256 - 64)),
            (uint256(slot0) << (256 - 32 - 32 - 64 - 64 - 32)) >> (256 - 32)
        );
    }

    function store(LocalStorage storage self, Local memory newValue) internal {
        if (newValue.currentId > uint256(type(uint32).max)) revert LocalStorageInvalidError();
        if (newValue.latestId > uint256(type(uint32).max)) revert LocalStorageInvalidError();
        if (newValue.collateral.gt(Fixed6.wrap(type(int64).max))) revert LocalStorageInvalidError();
        if (newValue.collateral.lt(Fixed6.wrap(type(int64).min))) revert LocalStorageInvalidError();
        if (newValue.reward.gt(UFixed6.wrap(type(uint64).max))) revert LocalStorageInvalidError();
        if (newValue.protection > uint256(type(uint32).max)) revert LocalStorageInvalidError();

        uint256 encoded =
            uint256(newValue.currentId << (256 - 32)) >> (256 - 32) |
            uint256(newValue.latestId << (256 - 32)) >> (256 - 32 - 32) |
            uint256(Fixed6.unwrap(newValue.collateral) << (256 - 64)) >> (256 - 32 - 32 - 64) |
            uint256(UFixed6.unwrap(newValue.reward) << (256 - 64)) >> (256 - 32 - 32 - 64 - 64) |
            uint256(newValue.protection << (256 - 32)) >> (256 - 32 - 32 - 64 - 64 - 32);
        assembly {
            sstore(self.slot, encoded)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/number/types/UFixed6.sol";
import "@equilibria/root/utilization/types/UJumpRateUtilizationCurve6.sol";
import "@equilibria/root/pid/types/PController6.sol";
import "../interfaces/IOracleProvider.sol";
import "../interfaces/IPayoffProvider.sol";
import "./ProtocolParameter.sol";

/// @dev MarketParameter type
struct MarketParameter {
    /// @dev The fee that is taken out of funding
    UFixed6 fundingFee;

    /// @dev The fee that is taken out of interest
    UFixed6 interestFee;

    /// @dev The fee that is taken out of maker and taker fees
    UFixed6 positionFee;

    /// @dev The share of the collected fees that is paid to the oracle
    UFixed6 oracleFee;

    /// @dev The share of the collected fees that is paid to the risk coordinator
    UFixed6 riskFee;

    /// @dev The maximum amount of orders that can be pending at one time globally
    uint256 maxPendingGlobal;

    /// @dev The maximum amount of orders that can be pending at one time per account
    uint256 maxPendingLocal;

    /// @dev The rate at which the makers receives rewards (share / sec)
    UFixed6 makerRewardRate;

    /// @dev The rate at which the longs receives rewards (share / sec)
    UFixed6 longRewardRate;

    /// @dev The rate at which the shorts receives rewards (share / sec)
    UFixed6 shortRewardRate;

    /// @dev The fixed fee that is charge whenever an oracle request occurs
    UFixed6 settlementFee;

    /// @dev Whether longs and shorts can always close even when they'd put the market into socialization
    bool takerCloseAlways;

    /// @dev Whether makers can always close even when they'd put the market into socialization
    bool makerCloseAlways;

    /// @dev Whether the market is in close-only mode
    bool closed;
}
struct MarketParameterStorage { uint256 slot0; uint256 slot1; }
using MarketParameterStorageLib for MarketParameterStorage global;

/// @dev Manually encodes and decodes the MarketParameter struct into storage.
///
///    struct StoredMarketParameter {
///        /* slot 0 */
///        uint24 fundingFee;          // <= 1677%
///        uint24 interestFee;         // <= 1677%
///        uint24 positionFee;         // <= 1677%
///        uint24 oracleFee;           // <= 1677%
///        uint24 riskFee;             // <= 1677%
///        uint16 maxPendingGlobal;    // <= 65k
///        uint16 maxPendingLocal;     // <= 65k
///        uint48 settlementFee;       // <= 281m
///        uint8 flags;
///
///        /* slot 1 */
///        uint40 makerRewardRate;     // <= 281m / s
///        uint40 longRewardRate;      // <= 281m / s
///        uint40 shortRewardRate;     // <= 281m / s
///    }
///
library MarketParameterStorageLib {
    // sig: 0x7c53e926
    error MarketParameterStorageInvalidError();

    function read(MarketParameterStorage storage self) external view returns (MarketParameter memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);

        uint256 flags = uint256(slot0) >> (256 - 8);
        (bool takerCloseAlways, bool makerCloseAlways, bool closed) =
            (flags & 0x01 == 0x01, flags & 0x02 == 0x02, flags & 0x04 == 0x04);

        return MarketParameter(
            UFixed6.wrap(uint256(slot0 << (256 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 16)) >> (256 - 16),
            uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16)) >> (256 - 16),
            UFixed6.wrap(uint256(slot1 << (256 - 40)) >> (256 - 40)),
            UFixed6.wrap(uint256(slot1 << (256 - 40 - 40)) >> (256 - 40)),
            UFixed6.wrap(uint256(slot1 << (256 - 40 - 40 - 40)) >> (256 - 40)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16 - 48)) >> (256 - 48)),
            takerCloseAlways,
            makerCloseAlways,
            closed
        );
    }

    function validate(
        MarketParameter memory self,
        ProtocolParameter memory protocolParameter,
        Token18 reward
    ) public pure {
        if (self.settlementFee.gt(protocolParameter.maxFeeAbsolute)) revert MarketParameterStorageInvalidError();

        if (self.fundingFee.max(self.interestFee).max(self.positionFee).gt(protocolParameter.maxCut))
            revert MarketParameterStorageInvalidError();

        if (self.oracleFee.add(self.riskFee).gt(UFixed6Lib.ONE)) revert MarketParameterStorageInvalidError();

        if (
            reward.isZero() &&
            (!self.makerRewardRate.isZero() || !self.longRewardRate.isZero() || !self.shortRewardRate.isZero())
        ) revert MarketParameterStorageInvalidError();
    }

    function validateAndStore(
        MarketParameterStorage storage self,
        MarketParameter memory newValue,
        ProtocolParameter memory protocolParameter,
        Token18 reward
    ) external {
        validate(newValue, protocolParameter, reward);

        if (newValue.maxPendingGlobal > uint256(type(uint16).max)) revert MarketParameterStorageInvalidError();
        if (newValue.maxPendingLocal > uint256(type(uint16).max)) revert MarketParameterStorageInvalidError();
        if (newValue.makerRewardRate.gt(UFixed6.wrap(type(uint40).max))) revert MarketParameterStorageInvalidError();
        if (newValue.longRewardRate.gt(UFixed6.wrap(type(uint40).max))) revert MarketParameterStorageInvalidError();
        if (newValue.shortRewardRate.gt(UFixed6.wrap(type(uint40).max))) revert MarketParameterStorageInvalidError();

        _store(self, newValue);
    }

    function _store(MarketParameterStorage storage self, MarketParameter memory newValue) internal {
        uint256 flags = (newValue.takerCloseAlways ? 0x01 : 0x00) |
            (newValue.makerCloseAlways ? 0x02 : 0x00) |
            (newValue.closed ? 0x04 : 0x00);

        uint256 encoded0 =
            uint256(UFixed6.unwrap(newValue.fundingFee) << (256 - 24)) >> (256 - 24) |
            uint256(UFixed6.unwrap(newValue.interestFee) << (256 - 24)) >> (256 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.positionFee) << (256 - 24)) >> (256 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.oracleFee) << (256 - 24)) >> (256 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.riskFee) << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24) |
            uint256(newValue.maxPendingGlobal << (256 - 16)) >> (256 - 24 - 24 - 24 - 24 - 24 - 16) |
            uint256(newValue.maxPendingLocal << (256 - 16)) >> (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16) |
            uint256(UFixed6.unwrap(newValue.settlementFee) << (256 - 48)) >> (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16 - 48) |
            uint256(flags << (256 - 8)) >> (256 - 24 - 24 - 24 - 24 - 24 - 32 - 32 - 32 - 32 - 8);
        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.makerRewardRate) << (256 - 40)) >> (256 - 40) |
            uint256(UFixed6.unwrap(newValue.longRewardRate) << (256 - 40)) >> (256 - 40 - 40) |
            uint256(UFixed6.unwrap(newValue.shortRewardRate) << (256 - 40)) >> (256 - 40 - 40 - 40);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";

/// @dev A singular oracle version with its corresponding data
struct OracleVersion {
    /// @dev the timestamp of the oracle update
    uint256 timestamp;

    /// @dev The oracle price of the corresponding version
    Fixed6 price;

    /// @dev Whether the version is valid
    bool valid;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./OracleVersion.sol";
import "./RiskParameter.sol";
import "./MarketParameter.sol";
import "./Position.sol";

/// @dev Order type
struct Order {
    /// @dev The change in the maker position
    Fixed6 maker;

    /// @dev The change in the long position
    Fixed6 long;

    /// @dev The change in the short position
    Fixed6 short;

    /// @dev The change in the net position
    Fixed6 net;

    /// @dev The magnitude of the change in the skew
    UFixed6 skew;

    /// @dev The change of the magnitude in the skew
    Fixed6 impact;

    /// @dev The change in the utilization=
    Fixed6 utilization;

    /// @dev The change in the efficiency
    Fixed6 efficiency;

    /// @dev The fee for the order
    UFixed6 fee;

    /// @dev The fixed settlement fee for the order
    UFixed6 keeper;
}
using OrderLib for Order global;

/// @title Order
/// @notice Holds the state for an account's update order
library OrderLib {
    /// @notice Computes and sets the fee and keeper once an order is already created
    /// @param self The Order object to update
    /// @param latestVersion The latest oracle version
    /// @param marketParameter The market parameter
    /// @param riskParameter The risk parameter
    function registerFee(
        Order memory self,
        OracleVersion memory latestVersion,
        MarketParameter memory marketParameter,
        RiskParameter memory riskParameter
    ) internal pure {
        Fixed6 makerFee = Fixed6Lib.from(riskParameter.makerFee)
            .add(Fixed6Lib.from(riskParameter.makerImpactFee).mul(self.utilization))
            .max(Fixed6Lib.ZERO);
        Fixed6 takerFee = Fixed6Lib.from(riskParameter.takerFee)
            .add(Fixed6Lib.from(riskParameter.takerSkewFee.mul(self.skew)))
            .add(Fixed6Lib.from(riskParameter.takerImpactFee).mul(self.impact))
            .max(Fixed6Lib.ZERO);
        UFixed6 fee = self.maker.abs().mul(latestVersion.price.abs()).mul(UFixed6Lib.from(makerFee))
            .add(self.long.abs().add(self.short.abs()).mul(latestVersion.price.abs()).mul(UFixed6Lib.from(takerFee)));

        self.fee = marketParameter.closed ? UFixed6Lib.ZERO : fee;
        self.keeper = isEmpty(self) ? UFixed6Lib.ZERO : marketParameter.settlementFee;
    }

    /// @notice Returns whether the order increases any of the account's positions
    /// @return Whether the order increases any of the account's positions
    function increasesPosition(Order memory self) internal pure returns (bool) {
        return increasesMaker(self) || increasesTaker(self);
    }

    /// @notice Returns whether the order increases the account's long or short positions
    /// @return Whether the order increases the account's long or short positions
    function increasesTaker(Order memory self) internal pure returns (bool) {
        return self.long.gt(Fixed6Lib.ZERO) || self.short.gt(Fixed6Lib.ZERO);
    }

    /// @notice Returns whether the order increases the account's maker position
    /// @return Whether the order increases the account's maker positions
    function increasesMaker(Order memory self) internal pure returns (bool) {
        return self.maker.gt(Fixed6Lib.ZERO);
    }

    /// @notice Returns whether the order decreases the liquidity of the market
    /// @return Whether the order decreases the liquidity of the market
    function decreasesLiquidity(Order memory self) internal pure returns (bool) {
        return self.maker.lt(self.net);
    }

    /// @notice Returns the whether the position is single-sided
    /// @param self The position object to check
    /// @param currentPosition The current position to check
    /// @return Whether the position is single-sided
    function singleSided(Order memory self, Position memory currentPosition) internal pure returns (bool) {
        return (self.maker.isZero() && self.long.isZero() && currentPosition.maker.isZero() && currentPosition.long.isZero()) ||
            (self.long.isZero() && self.short.isZero() && currentPosition.long.isZero() && currentPosition.short.isZero()) ||
            (self.short.isZero() && self.maker.isZero() && currentPosition.short.isZero() && currentPosition.maker.isZero());
    }

    /// @notice Returns whether the order is applicable for liquidity checks
    /// @param self The Order object to check
    /// @param marketParameter The market parameter
    /// @return Whether the order is applicable for liquidity checks
    function liquidityCheckApplicable(
        Order memory self,
        MarketParameter memory marketParameter
    ) internal pure returns (bool) {
        return !marketParameter.closed &&
            ((self.maker.isZero()) || !marketParameter.makerCloseAlways || increasesMaker(self)) &&
            ((self.long.isZero() && self.short.isZero()) || !marketParameter.takerCloseAlways || increasesTaker(self));
    }

    /// @notice Returns the liquidation fee of the position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The liquidation fee of the position
    function liquidationFee(
        Order memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        UFixed6 magnitude = self.maker.abs().add(self.long.abs()).add(self.short.abs());
        if (magnitude.isZero()) return UFixed6Lib.ZERO;

        UFixed6 partialMaintenance = magnitude.mul(latestVersion.price.abs())
            .mul(riskParameter.maintenance)
            .max(riskParameter.minMaintenance);

        return partialMaintenance.mul(riskParameter.liquidationFee)
            .min(riskParameter.maxLiquidationFee)
            .max(riskParameter.minLiquidationFee);
    }

    /// @notice Returns whether the order has no position change
    /// @param self The Order object to check
    /// @return Whether the order has no position change
    function isEmpty(Order memory self) internal pure returns (bool) {
        return self.maker.abs().add(self.long.abs()).add(self.short.abs()).isZero();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./OracleVersion.sol";
import "./RiskParameter.sol";
import "./Order.sol";
import "./Global.sol";
import "./Local.sol";
import "./Invalidation.sol";

/// @dev Order type
struct Position {
    /// @dev The timestamp of the position
    uint256 timestamp;

    /// @dev The maker position size
    UFixed6 maker;

    /// @dev The long position size
    UFixed6 long;

    /// @dev The short position size
    UFixed6 short;

    /// @dev The fee for the position (only used for pending positions)
    UFixed6 fee;

    /// @dev The fixed settlement fee for the position (only used for pending positions)
    UFixed6 keeper;

    /// @dev The collateral at the time of the position settlement (only used for pending positions)
    Fixed6 collateral;

    /// @dev The change in collateral during this position (only used for pending positions)
    Fixed6 delta;

    /// @dev The value of the invalidation accumulator at the time of creation
    Invalidation invalidation;
}
using PositionLib for Position global;
struct PositionStorageGlobal { uint256 slot0; uint256 slot1; }
using PositionStorageGlobalLib for PositionStorageGlobal global;
struct PositionStorageLocal { uint256 slot0; uint256 slot1; }
using PositionStorageLocalLib for PositionStorageLocal global;

/// @title Position
/// @notice Holds the state for a position
library PositionLib {
    /// @notice Returns whether the position is ready to be settled
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @return Whether the position is ready to be settled
    function ready(Position memory self, OracleVersion memory latestVersion) internal pure returns (bool) {
        return latestVersion.timestamp >= self.timestamp;
    }

    /// @notice Replaces the position with the new latest position
    /// @param self The position object to update
    /// @param newPosition The new latest position
    function update(Position memory self, Position memory newPosition) internal pure {
        (self.timestamp, self.maker, self.long, self.short) = (
            newPosition.timestamp,
            newPosition.maker,
            newPosition.long,
            newPosition.short
        );
    }

    /// @notice Updates the current local position with a new order
    /// @param self The position object to update
    /// @param currentTimestamp The current timestamp
    /// @param newMaker The new maker position
    /// @param newLong The new long position
    /// @param newShort The new short position
    /// @return newOrder The new order
    function update(
        Position memory self,
        uint256 currentTimestamp,
        UFixed6 newMaker,
        UFixed6 newLong,
        UFixed6 newShort
    ) internal pure returns (Order memory newOrder) {
        (newOrder.maker, newOrder.long, newOrder.short) = (
            Fixed6Lib.from(newMaker).sub(Fixed6Lib.from(self.maker)),
            Fixed6Lib.from(newLong).sub(Fixed6Lib.from(self.long)),
            Fixed6Lib.from(newShort).sub(Fixed6Lib.from(self.short))
        );

        (self.timestamp, self.maker, self.long, self.short) =
            (currentTimestamp, newMaker, newLong, newShort);
    }

    /// @notice Updates the current global position with a new order
    /// @param self The position object to update
    /// @param currentTimestamp The current timestamp
    /// @param order The new order
    /// @param riskParameter The current risk parameter
    function update(
        Position memory self,
        uint256 currentTimestamp,
        Order memory order,
        RiskParameter memory riskParameter
    ) internal pure {
        // load the computed attributes of the latest position
        Fixed6 latestSkew = virtualSkew(self, riskParameter);
        (order.net, order.efficiency, order.utilization) =
            (Fixed6Lib.from(net(self)), Fixed6Lib.from(efficiency(self)), Fixed6Lib.from(utilization(self)));

        // update the position's attributes
        (self.timestamp, self.maker, self.long, self.short) = (
            currentTimestamp,
            UFixed6Lib.from(Fixed6Lib.from(self.maker).add(order.maker)),
            UFixed6Lib.from(Fixed6Lib.from(self.long).add(order.long)),
            UFixed6Lib.from(Fixed6Lib.from(self.short).add(order.short))
        );

        // update the order's delta attributes with the positions updated attributes
        (order.net, order.skew, order.impact, order.efficiency, order.utilization) = (
            Fixed6Lib.from(net(self)).sub(order.net),
            virtualSkew(self, riskParameter).sub(latestSkew).abs(),
            Fixed6Lib.from(virtualSkew(self, riskParameter).abs()).sub(Fixed6Lib.from(latestSkew.abs())),
            Fixed6Lib.from(efficiency(self)).sub(order.efficiency),
            Fixed6Lib.from(utilization(self)).sub(order.utilization)
        );
    }

    /// @notice prepares the position for the next id
    /// @param self The position object to update
    function prepare(Position memory self) internal pure {
        self.fee = UFixed6Lib.ZERO;
        self.keeper = UFixed6Lib.ZERO;
        self.collateral = Fixed6Lib.ZERO;
    }

    /// @notice Updates the collateral delta of the position
    /// @param self The position object to update
    /// @param collateralAmount The amount of collateral change that occurred
    function update(Position memory self, Fixed6 collateralAmount) internal pure {
        self.delta = self.delta.add(collateralAmount);
    }

    /// @notice Processes an invalidation of a position
    /// @dev Increments the invalidation accumulator by the new position's delta, and resets the fee
    /// @param self The position object to update
    /// @param newPosition The latest valid position
    function invalidate(Position memory self, Position memory newPosition) internal pure {
        self.invalidation.increment(self, newPosition);
        (newPosition.maker, newPosition.long, newPosition.short, newPosition.fee) =
            (self.maker, self.long, self.short, UFixed6Lib.ZERO);
    }

    // @notice Adjusts the position if any invalidations have occurred
    function adjust(Position memory self, Position memory latestPosition) internal pure {
        Invalidation memory invalidation = latestPosition.invalidation.sub(self.invalidation);
        (self.maker, self.long, self.short) = (
            UFixed6Lib.from(Fixed6Lib.from(self.maker).add(invalidation.maker)),
            UFixed6Lib.from(Fixed6Lib.from(self.long).add(invalidation.long)),
            UFixed6Lib.from(Fixed6Lib.from(self.short).add(invalidation.short))
        );
    }

    /// @notice Processes a sync of the position
    /// @dev Moves the timestamp forward to the latest version's timestamp, while resetting the fee and keeper
    /// @param self The position object to update
    /// @param latestVersion The latest oracle version
    function sync(Position memory self, OracleVersion memory latestVersion) internal pure {
        (self.timestamp, self.fee, self.keeper) = (latestVersion.timestamp, UFixed6Lib.ZERO, UFixed6Lib.ZERO);
    }

    /// @notice Registers the fees from a new order
    /// @param self The position object to update
    /// @param order The new order
    function registerFee(Position memory self, Order memory order) internal pure {
        self.fee = self.fee.add(order.fee);
        self.keeper = self.keeper.add(order.keeper);
    }

    /// @notice Returns the maximum position size
    /// @param self The position object to check
    /// @return The maximum position size
    function magnitude(Position memory self) internal pure returns (UFixed6) {
        return self.long.max(self.short).max(self.maker);
    }

    /// @notice Returns the maximum taker position size
    /// @param self The position object to check
    /// @return The maximum taker position size
    function major(Position memory self) internal pure returns (UFixed6) {
        return self.long.max(self.short);
    }

    /// @notice Returns the minimum maker position size
    /// @param self The position object to check
    /// @return The minimum maker position size
    function minor(Position memory self) internal pure returns (UFixed6) {
        return self.long.min(self.short);
    }

    /// @notice Returns the difference between the long and short positions
    /// @param self The position object to check
    /// @return The difference between the long and short positions
    function net(Position memory self) internal pure returns (UFixed6) {
        return Fixed6Lib.from(self.long).sub(Fixed6Lib.from(self.short)).abs();
    }

    /// @notice Returns the skew of the position
    /// @dev skew = (long - short) / max(long, short)
    /// @param self The position object to check
    /// @return The skew of the position
    function skew(Position memory self) internal pure returns (Fixed6) {
        return _skew(self, UFixed6Lib.ZERO);
    }

    /// @notice Returns the skew of the position taking into account the virtual taker
    /// @dev virtual skew = (long - short) / (max(long, short) + virtualTaker)
    /// @param self The position object to check
    /// @param riskParameter The current risk parameter
    /// @return The virtual skew of the position
    function virtualSkew(Position memory self, RiskParameter memory riskParameter) internal pure returns (Fixed6) {
        return _skew(self, riskParameter.virtualTaker);
    }

    /// @notice Returns the skew of the position taking into account position socialization
    /// @dev Used to calculate the portion of the position that is covered by the maker
    /// @param self The position object to check
    /// @return The socialized skew of the position
    function socializedSkew(Position memory self) internal pure returns (UFixed6) {
        return takerSocialized(self).isZero() ?
            UFixed6Lib.ZERO :
            takerSocialized(self).sub(minor(self)).div(takerSocialized(self));
    }

    /// @notice Helper function to return the skew of the position with an optional virtual taker
    /// @param self The position object to check
    /// @param virtualTaker The virtual taker to use in the calculation
    /// @return The virtual skew of the position
    function _skew(Position memory self, UFixed6 virtualTaker) internal pure returns (Fixed6) {
        return major(self).isZero() ?
            Fixed6Lib.ZERO :
            Fixed6Lib.from(self.long)
                .sub(Fixed6Lib.from(self.short))
                .div(Fixed6Lib.from(major(self).add(virtualTaker)));
    }

    /// @notice Returns the utilization of the position
    /// @dev utilization = major / (maker + minor)
    /// @param self The position object to check
    /// @return The utilization of the position
    function utilization(Position memory self) internal pure returns (UFixed6) {
        return major(self).unsafeDiv(self.maker.add(minor(self))).min(UFixed6Lib.ONE);
    }

    /// @notice Returns the long position with socialization taken into account
    /// @param self The position object to check
    /// @return The long position with socialization taken into account
    function longSocialized(Position memory self) internal pure returns (UFixed6) {
        return self.maker.add(self.short).min(self.long);
    }

    /// @notice Returns the short position with socialization taken into account
    /// @param self The position object to check
    /// @return The short position with socialization taken into account
    function shortSocialized(Position memory self) internal pure returns (UFixed6) {
        return self.maker.add(self.long).min(self.short);
    }

    /// @notice Returns the major position with socialization taken into account
    /// @param self The position object to check
    /// @return The major position with socialization taken into account
    function takerSocialized(Position memory self) internal pure returns (UFixed6) {
        return major(self).min(minor(self).add(self.maker));
    }

    /// @notice Returns the efficiency of the position
    /// @dev efficiency = maker / major
    /// @param self The position object to check
    /// @return The efficiency of the position
    function efficiency(Position memory self) internal pure returns (UFixed6) {
        return self.maker.unsafeDiv(major(self)).min(UFixed6Lib.ONE);
    }

    /// @notice Returns the whether the position is socialized
    /// @param self The position object to check
    /// @return Whether the position is socialized
    function socialized(Position memory self) internal pure returns (bool) {
        return self.maker.add(self.short).lt(self.long) || self.maker.add(self.long).lt(self.short);
    }

    /// @notice Returns the maintenance requirement of the position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The maintenance requirement of the position
    function maintenance(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        return _collateralRequirement(self, latestVersion, riskParameter.maintenance, riskParameter.minMaintenance);
    }

    /// @notice Returns the margin requirement of the position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The margin requirement of the position
    function margin(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        return _collateralRequirement(self, latestVersion, riskParameter.margin, riskParameter.minMargin);
    }

    function _collateralRequirement(
        Position memory self,
        OracleVersion memory latestVersion,
        UFixed6 requirementRatio,
        UFixed6 requirementFixed
    ) private pure returns (UFixed6) {
        if (magnitude(self).isZero()) return UFixed6Lib.ZERO;
        return magnitude(self).mul(latestVersion.price.abs()).mul(requirementRatio).max(requirementFixed);
    }

    /// @notice Returns the whether the position is maintained
    /// @dev shortfall is considered solvent for 0-position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @param collateral The current account's collateral
    /// @return Whether the position is maintained
    function maintained(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter,
        Fixed6 collateral
    ) internal pure returns (bool) {
        return collateral.max(Fixed6Lib.ZERO).gte(Fixed6Lib.from(maintenance(self, latestVersion, riskParameter)));
    }

    /// @notice Returns the whether the position is margined
    /// @dev shortfall is considered solvent for 0-position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @param collateral The current account's collateral
    /// @return Whether the position is margined
    function margined(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter,
        Fixed6 collateral
    ) internal pure returns (bool) {
        return collateral.max(Fixed6Lib.ZERO).gte(Fixed6Lib.from(margin(self, latestVersion, riskParameter)));
    }
}

/// @dev Manually encodes and decodes the global Position struct into storage.
///
///     struct StoredPositionGlobal {
///         /* slot 0 */
///         uint32 timestamp;
///         uint48 fee;
///         uint48 keeper;
///         uint64 long;
///         uint64 short;
///
///         /* slot 1 */
///         uint64 maker;
///         int64 invalidation.maker;
///         int64 invalidation.long;
///         int64 invalidation.short;
///     }
///
library PositionStorageGlobalLib {
    function read(PositionStorageGlobal storage self) internal view returns (Position memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);
        return Position(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            UFixed6.wrap(uint256(slot1 << (256 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48 - 48 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48 - 48 - 64 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48 - 48)) >> (256 - 48)),
            Fixed6Lib.ZERO,
            Fixed6Lib.ZERO,
            Invalidation(
                Fixed6.wrap(int256(slot1 << (256 - 64 - 64)) >> (256 - 64)),
                Fixed6.wrap(int256(slot1 << (256 - 64 - 64 - 64)) >> (256 - 64)),
                Fixed6.wrap(int256(slot1 << (256 - 64 - 64 - 64 - 64)) >> (256 - 64))
            )
        );
    }

    function store(PositionStorageGlobal storage self, Position memory newValue) internal {
        PositionStorageLib.validate(newValue);

        if (newValue.maker.gt(UFixed6.wrap(type(uint64).max))) revert PositionStorageLib.PositionStorageInvalidError();
        if (newValue.long.gt(UFixed6.wrap(type(uint64).max))) revert PositionStorageLib.PositionStorageInvalidError();
        if (newValue.short.gt(UFixed6.wrap(type(uint64).max))) revert PositionStorageLib.PositionStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.timestamp << (256 - 32)) >> (256 - 32) |
            uint256(UFixed6.unwrap(newValue.fee) << (256 - 48)) >> (256 - 32 - 48) |
            uint256(UFixed6.unwrap(newValue.keeper) << (256 - 48)) >> (256 - 32 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.long) << (256 - 64)) >> (256 - 32 - 48 - 48 - 64) |
            uint256(UFixed6.unwrap(newValue.short) << (256 - 64)) >> (256 - 32 - 48 - 48 - 64 - 64);
        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.maker) << (256 - 64)) >> (256 - 64) |
            uint256(Fixed6.unwrap(newValue.invalidation.maker) << (256 - 64)) >> (256 - 64 - 64) |
            uint256(Fixed6.unwrap(newValue.invalidation.long) << (256 - 64)) >> (256 - 64 - 64 - 64) |
            uint256(Fixed6.unwrap(newValue.invalidation.short) << (256 - 64)) >> (256 - 64 - 64 - 64 - 64);


        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

/// @dev Manually encodes and decodes the local Position struct into storage.
///
///     struct StoredPositionLocal {
///         /* slot 0 */
///         uint32 timestamp;
///         uint48 fee;
///         uint48 keeper;
///         int64 collateral;
///         int64 delta;
///
///         /* slot 1 */
///         uint2 direction;
///         uint62 magnitude;
///         int64 invalidation.maker;
///         int64 invalidation.long;
///         int64 invalidation.short;
///     }
///
library PositionStorageLocalLib {
    function read(PositionStorageLocal storage self) internal view returns (Position memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);

        uint256 direction = uint256(slot1 << (256 - 2)) >> (256 - 2);
        UFixed6 magnitude = UFixed6.wrap(uint256(slot1 << (256 - 2 - 62)) >> (256 - 62));

        return Position(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            direction == 0 ? magnitude : UFixed6Lib.ZERO,
            direction == 1 ? magnitude : UFixed6Lib.ZERO,
            direction == 2 ? magnitude : UFixed6Lib.ZERO,
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48 - 48)) >> (256 - 48)),
            Fixed6.wrap(int256(slot0 << (256 - 32 - 48 - 48 - 64)) >> (256 - 64)),
            Fixed6.wrap(int256(slot0 << (256 - 32 - 48 - 48 - 64 - 64)) >> (256 - 64)),
            Invalidation(
                Fixed6.wrap(int256(slot1 << (256 - 2 - 62 - 64)) >> (256 - 64)),
                Fixed6.wrap(int256(slot1 << (256 - 2 - 62 - 64 - 64)) >> (256 - 64)),
                Fixed6.wrap(int256(slot1 << (256 - 2 - 62 - 64 - 64 - 64)) >> (256 - 64))
            )
        );
    }

    function store(PositionStorageLocal storage self, Position memory newValue) internal {
        PositionStorageLib.validate(newValue);

        if (newValue.maker.gt(UFixed6.wrap(2 ** 62 - 1))) revert PositionStorageLib.PositionStorageInvalidError();
        if (newValue.long.gt(UFixed6.wrap(2 ** 62 - 1))) revert PositionStorageLib.PositionStorageInvalidError();
        if (newValue.short.gt(UFixed6.wrap(2 ** 62 - 1))) revert PositionStorageLib.PositionStorageInvalidError();

        uint256 direction = newValue.long.isZero() ? (newValue.short.isZero() ? 0 : 2) : 1;

        uint256 encoded0 =
            uint256(newValue.timestamp << (256 - 32)) >> (256 - 32) |
            uint256(UFixed6.unwrap(newValue.fee) << (256 - 48)) >> (256 - 32 - 48) |
            uint256(UFixed6.unwrap(newValue.keeper) << (256 - 48)) >> (256 - 32 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.collateral) << (256 - 64)) >> (256 - 32 - 48 - 48 - 64) |
            uint256(Fixed6.unwrap(newValue.delta) << (256 - 64)) >> (256 - 32 - 48 - 48 - 64 - 64);
        uint256 encoded1 =
            uint256(direction << (256 - 2)) >> (256 - 2) |
            uint256(UFixed6.unwrap(newValue.magnitude()) << (256 - 62)) >> (256 - 2 - 62) |
            uint256(Fixed6.unwrap(newValue.invalidation.maker) << (256 - 64)) >> (256 - 2 - 62 - 64) |
            uint256(Fixed6.unwrap(newValue.invalidation.long) << (256 - 64)) >> (256 - 2 - 62 - 64 - 64) |
            uint256(Fixed6.unwrap(newValue.invalidation.short) << (256 - 64)) >> (256 - 2 - 62 - 64 - 64 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

library PositionStorageLib {
    // sig: 0x52a8a97f
    error PositionStorageInvalidError();

    function validate(Position memory newValue) internal pure {
        if (newValue.timestamp > type(uint32).max) revert PositionStorageInvalidError();
        if (newValue.fee.gt(UFixed6.wrap(type(uint48).max))) revert PositionStorageInvalidError();
        if (newValue.keeper.gt(UFixed6.wrap(type(uint48).max))) revert PositionStorageInvalidError();
        if (newValue.collateral.gt(Fixed6.wrap(type(int64).max))) revert PositionStorageInvalidError();
        if (newValue.collateral.lt(Fixed6.wrap(type(int64).min))) revert PositionStorageInvalidError();
        if (newValue.delta.gt(Fixed6.wrap(type(int64).max))) revert PositionStorageInvalidError();
        if (newValue.delta.lt(Fixed6.wrap(type(int64).min))) revert PositionStorageInvalidError();
        if (newValue.invalidation.maker.gt(Fixed6.wrap(type(int64).max))) revert PositionStorageInvalidError();
        if (newValue.invalidation.maker.lt(Fixed6.wrap(type(int64).min))) revert PositionStorageInvalidError();
        if (newValue.invalidation.long.gt(Fixed6.wrap(type(int64).max))) revert PositionStorageInvalidError();
        if (newValue.invalidation.long.lt(Fixed6.wrap(type(int64).min))) revert PositionStorageInvalidError();
        if (newValue.invalidation.short.gt(Fixed6.wrap(type(int64).max))) revert PositionStorageInvalidError();
        if (newValue.invalidation.short.lt(Fixed6.wrap(type(int64).min))) revert PositionStorageInvalidError();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed6.sol";

/// @dev ProtocolParameter type
struct ProtocolParameter {
    /// @dev The share of the market fees that are retained by the protocol before being distributed
    UFixed6 protocolFee;

    /// @dev The maximum for market fee parameters
    UFixed6 maxFee;

    /// @dev The maximum for market absolute fee parameters
    UFixed6 maxFeeAbsolute;

    /// @dev The maximum for market cut parameters
    UFixed6 maxCut;

    /// @dev The maximum for market rate parameters
    UFixed6 maxRate;

    /// @dev The minimum for market maintenance parameters
    UFixed6 minMaintenance;

    /// @dev The minimum for market efficiency parameters
    UFixed6 minEfficiency;
}
struct StoredProtocolParameter {
    /* slot 0 */
    uint24 protocolFee;        // <= 1677%
    uint24 maxFee;             // <= 1677%
    uint48 maxFeeAbsolute;     // <= 281m
    uint24 maxCut;             // <= 1677%
    uint32 maxRate;            // <= 429496%
    uint24 minMaintenance;     // <= 1677%
    uint24 minEfficiency;      // <= 1677%
}
struct ProtocolParameterStorage { StoredProtocolParameter value; }
using ProtocolParameterStorageLib for ProtocolParameterStorage global;

library ProtocolParameterStorageLib {
    // sig: 0x4dc1bc59
    error ProtocolParameterStorageInvalidError();

    function read(ProtocolParameterStorage storage self) internal view returns (ProtocolParameter memory) {
        StoredProtocolParameter memory value = self.value;
        return ProtocolParameter(
            UFixed6.wrap(uint256(value.protocolFee)),
            UFixed6.wrap(uint256(value.maxFee)),
            UFixed6.wrap(uint256(value.maxFeeAbsolute)),
            UFixed6.wrap(uint256(value.maxCut)),
            UFixed6.wrap(uint256(value.maxRate)),
            UFixed6.wrap(uint256(value.minMaintenance)),
            UFixed6.wrap(uint256(value.minEfficiency))
        );
    }

    function validate(ProtocolParameter memory self) internal pure {
        if (self.protocolFee.gt(self.maxCut)) revert ProtocolParameterStorageInvalidError();
        if (self.maxCut.gt(UFixed6Lib.ONE)) revert ProtocolParameterStorageInvalidError();
    }

    function validateAndStore(ProtocolParameterStorage storage self, ProtocolParameter memory newValue) internal {
        validate(newValue);

        if (newValue.maxFee.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.maxFeeAbsolute.gt(UFixed6.wrap(type(uint48).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.maxRate.gt(UFixed6.wrap(type(uint32).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.minMaintenance.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.minEfficiency.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();

        self.value = StoredProtocolParameter(
            uint24(UFixed6.unwrap(newValue.protocolFee)),
            uint24(UFixed6.unwrap(newValue.maxFee)),
            uint48(UFixed6.unwrap(newValue.maxFeeAbsolute)),
            uint24(UFixed6.unwrap(newValue.maxCut)),
            uint32(UFixed6.unwrap(newValue.maxRate)),
            uint24(UFixed6.unwrap(newValue.minMaintenance)),
            uint24(UFixed6.unwrap(newValue.minEfficiency))
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed6.sol";
import "@equilibria/root/utilization/types/UJumpRateUtilizationCurve6.sol";
import "@equilibria/root/pid/types/PController6.sol";
import "../interfaces/IOracleProvider.sol";
import "../interfaces/IPayoffProvider.sol";
import "./ProtocolParameter.sol";

/// @dev RiskParameter type
struct RiskParameter {
    /// @dev The minimum amount of collateral required to open a new position as a percentage of notional
    UFixed6 margin;

    /// @dev The minimum amount of collateral that must be maintained as a percentage of notional
    UFixed6 maintenance;

    /// @dev The percentage fee on the notional that is charged when a long or short position is open or closed
    UFixed6 takerFee;

    /// @dev The additional percentage that is added scaled by the change in skew
    UFixed6 takerSkewFee;

    /// @dev The additional percentage that is added scaled by the change in impact
    UFixed6 takerImpactFee;

    /// @dev The percentage fee on the notional that is charged when a maker position is open or closed
    UFixed6 makerFee;

    /// @dev The additional percentage that is added scaled by the change in utilization
    UFixed6 makerImpactFee;

    /// @dev The maximum amount of maker positions that opened
    UFixed6 makerLimit;

    /// @dev The minimum limit of the efficiency metric
    UFixed6 efficiencyLimit;

    /// @dev The percentage fee on the notional that is charged when a position is liquidated
    UFixed6 liquidationFee;

    /// @dev The minimum fixed amount that is charged when a position is liquidated
    UFixed6 minLiquidationFee;

    /// @dev The maximum fixed amount that is charged when a position is liquidated
    UFixed6 maxLiquidationFee;

    /// @dev The utilization curve that is used to compute maker interest
    UJumpRateUtilizationCurve6 utilizationCurve;

    /// @dev The p controller that is used to compute long-short funding
    PController6 pController;

    /// @dev The minimum fixed amount that is required to open a position
    UFixed6 minMargin;

    /// @dev The minimum fixed amount that is required for maintenance
    UFixed6 minMaintenance;

    /// @dev A virtual amount that is added to long and short for the purposes of skew calculation
    UFixed6 virtualTaker;

    /// @dev The maximum amount of time since the latest oracle version that update may still be called
    uint256 staleAfter;

    /// @dev Whether or not the maker should always receive positive funding
    bool makerReceiveOnly;
}
struct RiskParameterStorage { uint256 slot0; uint256 slot1; uint256 slot2; }
using RiskParameterStorageLib for RiskParameterStorage global;

//    struct StoredRiskParameter {
//        /* slot 0 */
//        uint24 margin;                              // <= 1677%
//        uint24 maintenance;                         // <= 1677%
//        uint24 takerFee;                            // <= 1677%
//        uint24 takerSkewFee;                        // <= 1677%
//        uint24 takerImpactFee;                      // <= 1677%
//        uint24 makerFee;                            // <= 1677%
//        uint24 makerImpactFee;                      // <= 1677%
//        uint64 makerLimit;                          // <= 18.44t
//        uint24 efficiencyLimit;                     // <= 1677%
//
//        /* slot 1 */
//        uint24 liquidationFee;                      // <= 1677%
//        uint48 minLiquidationFee;                   // <= 281mn
//        uint64 virtualTaker;                        // <= 18.44t
//        uint32 utilizationCurveMinRate;             // <= 214748%
//        uint32 utilizationCurveMaxRate;             // <= 214748%
//        uint32 utilizationCurveTargetRate;          // <= 214748%
//        uint24 utilizationCurveTargetUtilization;   // <= 1677%
//
//        /* slot 2 */
//        uint48 pControllerK;                        // <= 281m
//        uint32 pControllerMax;                      // <= 214748%
//        uint48 minMargin;                           // <= 281m
//        uint48 minMaintenance;                      // <= 281m
//        uint48 maxLiquidationFee;                   // <= 281mn
//        uint24 staleAfter;                          // <= 16m s
//        bool makerReceiveOnly;
//    }
library RiskParameterStorageLib {
    // sig: 0x7ecd083f
    error RiskParameterStorageInvalidError();

    function read(RiskParameterStorage storage self) external view returns (RiskParameter memory) {
        (uint256 slot0, uint256 slot1, uint256 slot2) = (self.slot0, self.slot1, self.slot2);
        return RiskParameter(
            UFixed6.wrap(uint256(       slot0 << (256 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 64 - 24)) >> (256 - 24)),

            UFixed6.wrap(uint256(       slot1 << (256 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot1 << (256 - 24 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(       slot2 << (256 - 48 - 32 - 48 - 48 - 48)) >> (256 - 48)),
            UJumpRateUtilizationCurve6(
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 64 - 32)) >> (256 - 32)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 64 - 32 - 32)) >> (256 - 32)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 64 - 32 - 32 - 32)) >> (256 - 32)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 64 - 32 - 32 - 32 - 24)) >> (256 - 24))
            ),

            PController6(
                UFixed6.wrap(uint256(   slot2 << (256 - 48)) >> (256 - 48)),
                UFixed6.wrap(uint256(   slot2 << (256 - 48 - 32)) >> (256 - 32))
            ),
            UFixed6.wrap(uint256(       slot2 << (256 - 48 - 32 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(       slot2 << (256 - 48 - 32 - 48 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(       slot1 << (256 - 24 - 48 - 64)) >> (256 - 64)),
                         uint256(       slot2 << (256 - 48 - 32 - 48 - 48 - 48 - 24)) >> (256 - 24),
            0 !=        (uint256(       slot2 << (256 - 48 - 32 - 48 - 48 - 48 - 24 - 8)) >> (256 - 8))
        );
    }

    function validate(RiskParameter memory self, ProtocolParameter memory protocolParameter) public pure {
        if (
            self.takerFee.max(self.takerSkewFee).max(self.takerImpactFee).max(self.makerFee).max(self.makerImpactFee)
            .gt(protocolParameter.maxFee)
        ) revert RiskParameterStorageInvalidError();

        if (
            self.minLiquidationFee.max(self.maxLiquidationFee).max(self.minMargin).max(self.minMaintenance)
            .gt(protocolParameter.maxFeeAbsolute)
        ) revert RiskParameterStorageInvalidError();

        if (self.liquidationFee.gt(protocolParameter.maxCut)) revert RiskParameterStorageInvalidError();

        if (
            self.utilizationCurve.minRate.max(self.utilizationCurve.maxRate).max(self.utilizationCurve.targetRate).max(self.pController.max)
            .gt(protocolParameter.maxRate)
        ) revert RiskParameterStorageInvalidError();

        if (self.maintenance.lt(protocolParameter.minMaintenance)) revert RiskParameterStorageInvalidError();

        if (self.margin.lt(self.maintenance)) revert RiskParameterStorageInvalidError();

        if (self.efficiencyLimit.lt(protocolParameter.minEfficiency)) revert RiskParameterStorageInvalidError();

        if (self.utilizationCurve.targetUtilization.gt(UFixed6Lib.ONE)) revert RiskParameterStorageInvalidError();

        if (self.minMaintenance.lt(self.minLiquidationFee)) revert RiskParameterStorageInvalidError();

        if (self.minMargin.lt(self.minMaintenance)) revert RiskParameterStorageInvalidError();
    }

    function validateAndStore(
        RiskParameterStorage storage self,
        RiskParameter memory newValue,
        ProtocolParameter memory protocolParameter
    ) external {
        validate(newValue, protocolParameter);

        if (newValue.margin.gt(UFixed6.wrap(type(uint24).max))) revert RiskParameterStorageInvalidError();
        if (newValue.efficiencyLimit.gt(UFixed6.wrap(type(uint24).max))) revert RiskParameterStorageInvalidError();
        if (newValue.makerLimit.gt(UFixed6.wrap(type(uint64).max))) revert RiskParameterStorageInvalidError();
        if (newValue.pController.k.gt(UFixed6.wrap(type(uint48).max))) revert RiskParameterStorageInvalidError();
        if (newValue.virtualTaker.gt(UFixed6.wrap(type(uint64).max))) revert RiskParameterStorageInvalidError();
        if (newValue.staleAfter > uint256(type(uint24).max)) revert RiskParameterStorageInvalidError();

        uint256 encoded0 =
            uint256(UFixed6.unwrap(newValue.margin)             << (256 - 24)) >> (256 - 24) |
            uint256(UFixed6.unwrap(newValue.maintenance)        << (256 - 24)) >> (256 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.takerFee)           << (256 - 24)) >> (256 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.takerSkewFee)       << (256 - 24)) >> (256 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.takerImpactFee)     << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.makerFee)           << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.makerImpactFee)     << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.makerLimit)         << (256 - 64)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 64) |
            uint256(UFixed6.unwrap(newValue.efficiencyLimit)    << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 64 - 24);

        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.liquidationFee)                     << (256 - 24)) >> (256 - 24) |
            uint256(UFixed6.unwrap(newValue.minLiquidationFee)                  << (256 - 48)) >> (256 - 24 - 48) |
            uint256(UFixed6.unwrap(newValue.virtualTaker)                       << (256 - 64)) >> (256 - 24 - 48 - 64) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.minRate)           << (256 - 32)) >> (256 - 24 - 48 - 64 - 32) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.maxRate)           << (256 - 32)) >> (256 - 24 - 48 - 64 - 32 - 32) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.targetRate)        << (256 - 32)) >> (256 - 24 - 48 - 64 - 32 - 32 - 32) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.targetUtilization) << (256 - 24)) >> (256 - 24 - 48 - 64 - 32 - 32 - 32 - 24);

        uint256 encoded2 =
            uint256(UFixed6.unwrap(newValue.pController.k)                  << (256 - 48)) >> (256 - 48) |
            uint256(UFixed6.unwrap(newValue.pController.max)                << (256 - 32)) >> (256 - 48 - 32) |
            uint256(UFixed6.unwrap(newValue.minMargin)                      << (256 - 48)) >> (256 - 48 - 32 - 48) |
            uint256(UFixed6.unwrap(newValue.minMaintenance)                 << (256 - 48)) >> (256 - 48 - 32 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.maxLiquidationFee)              << (256 - 48)) >> (256 - 48 - 32 - 48 - 48 - 48) |
            uint256(newValue.staleAfter                                     << (256 - 24)) >> (256 - 48 - 32 - 48 - 48 - 48 - 24) |
            uint256((newValue.makerReceiveOnly ? uint256(1) : uint256(0))   << (256 - 8))  >> (256 - 48 - 32 - 48 - 48 - 48 - 24 - 8);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
            sstore(add(self.slot, 2), encoded2)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/accumulator/types/Accumulator6.sol";
import "@equilibria/root/accumulator/types/UAccumulator6.sol";
import "./ProtocolParameter.sol";
import "./MarketParameter.sol";
import "./RiskParameter.sol";
import "./Global.sol";
import "./Position.sol";

/// @dev Version type
struct Version {
    /// @dev whether this version had a valid oracle price
    bool valid;

    /// @dev The maker accumulator value
    Accumulator6 makerValue;

    /// @dev The long accumulator value
    Accumulator6 longValue;

    /// @dev The short accumulator value
    Accumulator6 shortValue;

    /// @dev The maker reward accumulator value
    UAccumulator6 makerReward;

    /// @dev The long reward accumulator value
    UAccumulator6 longReward;

    /// @dev The short reward accumulator value
    UAccumulator6 shortReward;
}
using VersionLib for Version global;
struct VersionStorage { uint256 slot0; uint256 slot1; }
using VersionStorageLib for VersionStorage global;

/// @dev Individual accumulation values
struct VersionAccumulationResult {
    UFixed6 positionFeeMaker;
    UFixed6 positionFeeFee;

    Fixed6 fundingMaker;
    Fixed6 fundingLong;
    Fixed6 fundingShort;
    UFixed6 fundingFee;

    Fixed6 interestMaker;
    Fixed6 interestLong;
    Fixed6 interestShort;
    UFixed6 interestFee;

    Fixed6 pnlMaker;
    Fixed6 pnlLong;
    Fixed6 pnlShort;

    UFixed6 rewardMaker;
    UFixed6 rewardLong;
    UFixed6 rewardShort;
}

///@title Version
/// @notice Library that manages global versioned accumulator state.
/// @dev Manages two accumulators: value and reward. The value accumulator measures the change in position value
///      over time, while the reward accumulator measures the change in position ownership over time.
library VersionLib {
    /// @notice Accumulates the global state for the period from `fromVersion` to `toOracleVersion`
    /// @param self The Version object to update
    /// @param global The global state
    /// @param fromPosition The previous latest position
    /// @param toPosition The next latest position
    /// @param fromOracleVersion The previous latest oracle version
    /// @param toOracleVersion The next latest oracle version
    /// @param marketParameter The market parameter
    /// @param riskParameter The risk parameter
    /// @return values The accumulation result
    /// @return totalFee The total fee accumulated
    function accumulate(
        Version memory self,
        Global memory global,
        Position memory fromPosition,
        Position memory toPosition,
        OracleVersion memory fromOracleVersion,
        OracleVersion memory toOracleVersion,
        MarketParameter memory marketParameter,
        RiskParameter memory riskParameter
    ) internal pure returns (VersionAccumulationResult memory values, UFixed6 totalFee) {
        // record validity
        self.valid = toOracleVersion.valid;

        // accumulate position fee
        (values.positionFeeMaker, values.positionFeeFee) =
            _accumulatePositionFee(self, fromPosition, toPosition, marketParameter);

        // if closed, don't accrue anything else
        if (marketParameter.closed) return (values, values.positionFeeFee);

        // accumulate funding
        _FundingValues memory fundingValues = _accumulateFunding(
            self,
            global,
            fromPosition,
            toPosition,
            fromOracleVersion,
            toOracleVersion,
            marketParameter,
            riskParameter
        );
        (values.fundingMaker, values.fundingLong, values.fundingShort, values.fundingFee) = (
            fundingValues.fundingMaker,
            fundingValues.fundingLong,
            fundingValues.fundingShort,
            fundingValues.fundingFee
        );

        // accumulate interest
        (values.interestMaker, values.interestLong, values.interestShort, values.interestFee) =
            _accumulateInterest(self, fromPosition, fromOracleVersion, toOracleVersion, marketParameter, riskParameter);

        // accumulate P&L
        (values.pnlMaker, values.pnlLong, values.pnlShort) =
            _accumulatePNL(self, fromPosition, fromOracleVersion, toOracleVersion);

        // accumulate reward
        (values.rewardMaker, values.rewardLong, values.rewardShort) =
            _accumulateReward(self, fromPosition, fromOracleVersion, toOracleVersion, marketParameter);

        return (values, values.positionFeeFee.add(values.fundingFee).add(values.interestFee));
    }

    /// @notice Globally accumulates position fees since last oracle update
    /// @param self The Version object to update
    /// @param fromPosition The previous latest position
    /// @param toPosition The next latest position
    /// @param marketParameter The market parameter
    /// @return positionFeeMaker The maker's position fee
    /// @return positionFeeFee The protocol's position fee
    function _accumulatePositionFee(
        Version memory self,
        Position memory fromPosition,
        Position memory toPosition,
        MarketParameter memory marketParameter
    ) private pure returns (UFixed6 positionFeeMaker, UFixed6 positionFeeFee) {
        // If there are no makers to distribute the taker's position fee to, give it to the protocol
        if (fromPosition.maker.isZero()) return (UFixed6Lib.ZERO, toPosition.fee);

        positionFeeFee = marketParameter.positionFee.mul(toPosition.fee);
        positionFeeMaker = toPosition.fee.sub(positionFeeFee);

        self.makerValue.increment(Fixed6Lib.from(positionFeeMaker), fromPosition.maker);
    }

    /// @dev Internal struct to bypass stack depth limit
    struct _FundingValues {
        Fixed6 fundingMaker;
        Fixed6 fundingLong;
        Fixed6 fundingShort;
        UFixed6 fundingFee;
    }

    /// @notice Globally accumulates all long-short funding since last oracle update
    /// @param self The Version object to update
    /// @param global The global state
    /// @param fromPosition The previous latest position
    /// @param toPosition The next latest position
    /// @param fromOracleVersion The previous latest oracle version
    /// @param toOracleVersion The next latest oracle version
    /// @param marketParameter The market parameter
    /// @param riskParameter The risk parameter
    /// @return fundingValues The funding values accumulated
    function _accumulateFunding(
        Version memory self,
        Global memory global,
        Position memory fromPosition,
        Position memory toPosition,
        OracleVersion memory fromOracleVersion,
        OracleVersion memory toOracleVersion,
        MarketParameter memory marketParameter,
        RiskParameter memory riskParameter
    ) private pure returns (_FundingValues memory fundingValues) {
        // Compute long-short funding rate
        Fixed6 funding = global.pAccumulator.accumulate(
            riskParameter.pController,
            toPosition.virtualSkew(riskParameter),
            fromOracleVersion.timestamp,
            toOracleVersion.timestamp,
            fromPosition.takerSocialized().mul(fromOracleVersion.price.abs())
        );

        // Handle maker receive-only status
        if (riskParameter.makerReceiveOnly && funding.sign() != fromPosition.skew().sign())
            funding = funding.mul(Fixed6Lib.NEG_ONE);

        // Initialize long and short funding
        (fundingValues.fundingLong, fundingValues.fundingShort) = (Fixed6Lib.NEG_ONE.mul(funding), funding);

        // Compute fee spread
        fundingValues.fundingFee = funding.abs().mul(marketParameter.fundingFee);
        Fixed6 fundingSpread = Fixed6Lib.from(fundingValues.fundingFee).div(Fixed6Lib.from(2));

        // Adjust funding with spread
        (fundingValues.fundingLong, fundingValues.fundingShort) = (
            fundingValues.fundingLong.sub(Fixed6Lib.from(fundingValues.fundingFee)).add(fundingSpread),
            fundingValues.fundingShort.sub(fundingSpread)
        );

        // Redirect net portion of minor's side to maker
        if (fromPosition.long.gt(fromPosition.short)) {
            fundingValues.fundingMaker = fundingValues.fundingShort.mul(Fixed6Lib.from(fromPosition.socializedSkew()));
            fundingValues.fundingShort = fundingValues.fundingShort.sub(fundingValues.fundingMaker);
        }
        if (fromPosition.short.gt(fromPosition.long)) {
            fundingValues.fundingMaker = fundingValues.fundingLong.mul(Fixed6Lib.from(fromPosition.socializedSkew()));
            fundingValues.fundingLong = fundingValues.fundingLong.sub(fundingValues.fundingMaker);
        }

        self.makerValue.increment(fundingValues.fundingMaker, fromPosition.maker);
        self.longValue.increment(fundingValues.fundingLong, fromPosition.long);
        self.shortValue.increment(fundingValues.fundingShort, fromPosition.short);
    }

    /// @notice Globally accumulates all maker interest since last oracle update
    /// @param self The Version object to update
    /// @param position The previous latest position
    /// @param fromOracleVersion The previous latest oracle version
    /// @param toOracleVersion The next latest oracle version
    /// @param marketParameter The market parameter
    /// @param riskParameter The risk parameter
    /// @return interestMaker The total interest accrued by makers
    /// @return interestLong The total interest accrued by longs
    /// @return interestShort The total interest accrued by shorts
    /// @return interestFee The total fee accrued from interest accumulation
    function _accumulateInterest(
        Version memory self,
        Position memory position,
        OracleVersion memory fromOracleVersion,
        OracleVersion memory toOracleVersion,
        MarketParameter memory marketParameter,
        RiskParameter memory riskParameter
    ) private pure returns (Fixed6 interestMaker, Fixed6 interestLong, Fixed6 interestShort, UFixed6 interestFee) {
        UFixed6 notional = position.long.add(position.short).min(position.maker).mul(fromOracleVersion.price.abs());

        // Compute maker interest
        UFixed6 interest = riskParameter.utilizationCurve.accumulate(
            position.utilization(),
            fromOracleVersion.timestamp,
            toOracleVersion.timestamp,
            notional
        );

        // Compute fee
        interestFee = interest.mul(marketParameter.interestFee);

        // Adjust long and short funding with spread
        interestLong = Fixed6Lib.from(
            position.major().isZero() ?
            interest :
            interest.muldiv(position.long, position.long.add(position.short))
        );
        interestShort = Fixed6Lib.from(interest).sub(interestLong);
        interestMaker = Fixed6Lib.from(interest.sub(interestFee));

        interestLong = interestLong.mul(Fixed6Lib.NEG_ONE);
        interestShort = interestShort.mul(Fixed6Lib.NEG_ONE);
        self.makerValue.increment(interestMaker, position.maker);
        self.longValue.increment(interestLong, position.long);
        self.shortValue.increment(interestShort, position.short);
    }

    /// @notice Globally accumulates position profit & loss since last oracle update
    /// @param self The Version object to update
    /// @param position The previous latest position
    /// @param fromOracleVersion The previous latest oracle version
    /// @param toOracleVersion The next latest oracle version
    /// @return pnlMaker The total pnl accrued by makers
    /// @return pnlLong The total pnl accrued by longs
    /// @return pnlShort The total pnl accrued by shorts
    function _accumulatePNL(
        Version memory self,
        Position memory position,
        OracleVersion memory fromOracleVersion,
        OracleVersion memory toOracleVersion
    ) private pure returns (Fixed6 pnlMaker, Fixed6 pnlLong, Fixed6 pnlShort) {
        pnlLong = toOracleVersion.price.sub(fromOracleVersion.price)
            .mul(Fixed6Lib.from(position.longSocialized()));
        pnlShort = fromOracleVersion.price.sub(toOracleVersion.price)
            .mul(Fixed6Lib.from(position.shortSocialized()));
        pnlMaker = pnlLong.add(pnlShort).mul(Fixed6Lib.NEG_ONE);

        self.longValue.increment(pnlLong, position.long);
        self.shortValue.increment(pnlShort, position.short);
        self.makerValue.increment(pnlMaker, position.maker);
    }

    /// @notice Globally accumulates position's reward share since last oracle update
    /// @param self The Version object to update
    /// @param position The previous latest position
    /// @param fromOracleVersion The previous latest oracle version
    /// @param toOracleVersion The next latest oracle version
    /// @param marketParameter The market parameter
    /// @return rewardMaker The total reward accrued by makers
    /// @return rewardLong The total reward accrued by longs
    /// @return rewardShort The total reward accrued by shorts
    function _accumulateReward(
        Version memory self,
        Position memory position,
        OracleVersion memory fromOracleVersion,
        OracleVersion memory toOracleVersion,
        MarketParameter memory marketParameter
    ) private pure returns (UFixed6 rewardMaker, UFixed6 rewardLong, UFixed6 rewardShort) {
        UFixed6 elapsed = UFixed6Lib.from(toOracleVersion.timestamp - fromOracleVersion.timestamp);

        if (!position.maker.isZero()) {
            rewardMaker = elapsed.mul(marketParameter.makerRewardRate);
            self.makerReward.increment(rewardMaker, position.maker);
        }
        if (!position.long.isZero()) {
            rewardLong = elapsed.mul(marketParameter.longRewardRate);
            self.longReward.increment(rewardLong, position.long);
        }
        if (!position.short.isZero()) {
            rewardShort = elapsed.mul(marketParameter.shortRewardRate);
            self.shortReward.increment(rewardShort, position.short);
        }
    }
}

/// @dev Manually encodes and decodes the Version struct into storage.
///
///     struct StoredVersion {
///         /* slot 0 */
///         bool valid;
///         int64 makerValue;
///         int64 longValue;
///         int64 shortValue;
///
///         /* slot 1 */
///         uint64 makerReward;
///         uint64 longReward;
///         uint64 shortReward;
///     }
///
library VersionStorageLib {
    // sig: 0xd2777e72
    error VersionStorageInvalidError();

    function read(VersionStorage storage self) internal view returns (Version memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);
        return Version(
            (uint256(slot0 << (256 - 8)) >> (256 - 8)) != 0,
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64)) >> (256 - 64))),
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64 - 64)) >> (256 - 64))),
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64 - 64 - 64)) >> (256 - 64))),
            UAccumulator6(UFixed6.wrap(uint256(slot1 << (256 - 64)) >> (256 - 64))),
            UAccumulator6(UFixed6.wrap(uint256(slot1 << (256 - 64 - 64)) >> (256 - 64))),
            UAccumulator6(UFixed6.wrap(uint256(slot1 << (256 - 64 - 64 - 64)) >> (256 - 64)))
        );
    }

    function store(VersionStorage storage self, Version memory newValue) internal {
        if (newValue.makerValue._value.gt(Fixed6.wrap(type(int64).max))) revert VersionStorageInvalidError();
        if (newValue.makerValue._value.lt(Fixed6.wrap(type(int64).min))) revert VersionStorageInvalidError();
        if (newValue.longValue._value.gt(Fixed6.wrap(type(int64).max))) revert VersionStorageInvalidError();
        if (newValue.longValue._value.lt(Fixed6.wrap(type(int64).min))) revert VersionStorageInvalidError();
        if (newValue.shortValue._value.gt(Fixed6.wrap(type(int64).max))) revert VersionStorageInvalidError();
        if (newValue.shortValue._value.lt(Fixed6.wrap(type(int64).min))) revert VersionStorageInvalidError();
        if (newValue.makerReward._value.gt(UFixed6.wrap(type(uint64).max))) revert VersionStorageInvalidError();
        if (newValue.longReward._value.gt(UFixed6.wrap(type(uint64).max))) revert VersionStorageInvalidError();
        if (newValue.shortReward._value.gt(UFixed6.wrap(type(uint64).max))) revert VersionStorageInvalidError();

        uint256 encoded0 =
            uint256((newValue.valid ? uint256(1) : uint256(0)) << (256 - 8)) >> (256 - 8) |
            uint256(Fixed6.unwrap(newValue.makerValue._value) << (256 - 64)) >> (256 - 8 - 64) |
            uint256(Fixed6.unwrap(newValue.longValue._value) << (256 - 64)) >> (256 - 8 - 64 - 64) |
            uint256(Fixed6.unwrap(newValue.shortValue._value) << (256 - 64)) >> (256 - 8 - 64 - 64 - 64);
        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.makerReward._value) << (256 - 64)) >> (256 - 64) |
            uint256(UFixed6.unwrap(newValue.longReward._value) << (256 - 64)) >> (256 - 64 - 64) |
            uint256(UFixed6.unwrap(newValue.shortReward._value) << (256 - 64)) >> (256 - 64 - 64 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";
import "../../number/types/UFixed6.sol";

/// @dev Accumulator6 type
struct Accumulator6 {
    Fixed6 _value;
}

using Accumulator6Lib for Accumulator6 global;
struct StoredAccumulator6 {
    int256 _value;
}
struct Accumulator6Storage { StoredAccumulator6 value; }
using Accumulator6StorageLib for Accumulator6Storage global;


/**
 * @title Accumulator6Lib
 * @notice Library that surfaces math operations for the signed Accumulator type.
 * @dev This accumulator tracks cumulative changes to a value over time. Using the `accumulated` function, one
 * can determine how much a value has changed between two points in time. The `increment` and `decrement` functions
 * can be used to update the accumulator.
 */
library Accumulator6Lib {
    /**
     * Returns how much has been accumulated between two accumulators
     * @param self The current point of the accumulation to compare with `from`
     * @param from The starting point of the accumulation
     * @param total Demoninator of the ratio (see `increment` and `decrement` functions)
     */
    function accumulated(Accumulator6 memory self, Accumulator6 memory from, UFixed6 total) internal pure returns (Fixed6) {
        return _mul(self._value.sub(from._value), total);
    }

    /**
     * @notice Increments an accumulator by a given ratio
     * @dev Always rounds down in order to prevent overstating the accumulated value
     * @param self The accumulator to increment
     * @param amount Numerator of the ratio
     * @param total Denominator of the ratio
     */
    function increment(Accumulator6 memory self, Fixed6 amount, UFixed6 total) internal pure {
        if (amount.isZero()) return;
        self._value = self._value.add(_div(amount, total));
    }

    /**
     * @notice Decrements an accumulator by a given ratio
     * @dev Always rounds down in order to prevent overstating the accumulated value
     * @param self The accumulator to decrement
     * @param amount Numerator of the ratio
     * @param total Denominator of the ratio
     */
    function decrement(Accumulator6 memory self, Fixed6 amount, UFixed6 total) internal pure {
        if (amount.isZero()) return;
        self._value = self._value.add(_div(amount.mul(Fixed6Lib.NEG_ONE), total));
    }

    function _div(Fixed6 amount, UFixed6 total) private pure returns (Fixed6) {
        return amount.sign() == -1 ? amount.divOut(Fixed6Lib.from(total)) : amount.div(Fixed6Lib.from(total));
    }

    function _mul(Fixed6 amount, UFixed6 total) private pure returns (Fixed6) {
        return amount.sign() == -1 ? amount.mulOut(Fixed6Lib.from(total)) : amount.mul(Fixed6Lib.from(total));
    }
}

library Accumulator6StorageLib {
    function read(Accumulator6Storage storage self) internal view returns (Accumulator6 memory) {
        StoredAccumulator6 memory storedValue = self.value;
        return Accumulator6(Fixed6.wrap(int256(storedValue._value)));
    }

    function store(Accumulator6Storage storage self, Accumulator6 memory newValue) internal {
        self.value = StoredAccumulator6(Fixed6.unwrap(newValue._value));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/UFixed6.sol";

/// @dev UAccumulator6 type
struct UAccumulator6 {
    UFixed6 _value;
}

using UAccumulator6Lib for UAccumulator6 global;
struct StoredUAccumulator6 {
    uint256 _value;
}
struct UAccumulator6Storage { StoredUAccumulator6 value; }
using UAccumulator6StorageLib for UAccumulator6Storage global;


/**
 * @title UAccumulator6Lib
 * @notice Library that surfaces math operations for the unsigned Accumulator type.
 * @dev This accumulator tracks cumulative changes to a monotonically increasing value over time. Using the `accumulated` function, one
 * can determine how much a value has changed between two points in time. The `increment` function can be used to update the accumulator.
 */
library UAccumulator6Lib {
    /**
     * Returns how much has been accumulated between two accumulators
     * @param self The current point of the accumulation to compare with `from`
     * @param from The starting point of the accumulation
     * @param total Demoninator of the ratio (see `increment` function)
     */
    function accumulated(UAccumulator6 memory self, UAccumulator6 memory from, UFixed6 total) internal pure returns (UFixed6) {
        return self._value.sub(from._value).mul(total);
    }

    /**
     * @notice Increments an accumulator by a given ratio
     * @dev Always rounds down in order to prevent overstating the accumulated value
     * @param self The accumulator to increment
     * @param amount Numerator of the ratio
     * @param total Denominator of the ratio
     */
    function increment(UAccumulator6 memory self, UFixed6 amount, UFixed6 total) internal pure {
        if (amount.isZero()) return;
        self._value = self._value.add(amount.div(total));
    }
}

library UAccumulator6StorageLib {
    function read(UAccumulator6Storage storage self) internal view returns (UAccumulator6 memory) {
        StoredUAccumulator6 memory storedValue = self.value;
        return UAccumulator6(UFixed6.wrap(uint256(storedValue._value)));
    }

    function store(UAccumulator6Storage storage self, UAccumulator6 memory newValue) internal {
        self.value = StoredUAccumulator6(UFixed6.unwrap(newValue._value));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IInitializable.sol";
import "../storage/Storage.sol";

/**
 * @title Initializable
 * @notice Library to manage the initialization lifecycle of upgradeable contracts
 * @dev `Initializable.sol` allows the creation of pseudo-constructors for upgradeable contracts. One
 *      `initializer` should be declared per top-level contract. Child contracts can use the `onlyInitializer`
 *      modifier to tag their internal initialization functions to ensure that they can only be called
 *      from a top-level `initializer` or a constructor.
 */
abstract contract Initializable is IInitializable {
    /// @dev The initialized flag
    Uint256Storage private constant _version = Uint256Storage.wrap(keccak256("equilibria.root.Initializable.version"));

    /// @dev The initializing flag
    BoolStorage private constant _initializing = BoolStorage.wrap(keccak256("equilibria.root.Initializable.initializing"));

    /// @dev Can only be called once per version, `version` is 1-indexed
    modifier initializer(uint256 version) {
        if (version == 0) revert InitializableZeroVersionError();
        if (_version.read() >= version) revert InitializableAlreadyInitializedError(version);

        _version.store(version);
        _initializing.store(true);

        _;

        _initializing.store(false);
        emit Initialized(version);
    }

    /// @dev Can only be called from an initializer or constructor
    modifier onlyInitializer() {
        if (!_constructing() && !_initializing.read()) revert InitializableNotInitializingError();
        _;
    }

    /**
     * @notice Returns whether the contract is currently being constructed
     * @dev {Address.isContract} returns false for contracts currently in the process of being constructed
     * @return Whether the contract is currently being constructed
     */
    function _constructing() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../storage/Storage.sol";
import "./interfaces/IInstance.sol";
import "./Initializable.sol";

/// @title Instance
/// @notice An abstract contract that is created and managed by a factory
abstract contract Instance is IInstance, Initializable {
    /// @dev The factory address storage slot
    AddressStorage private constant _factory = AddressStorage.wrap(keccak256("equilibria.root.Instance.factory"));

    /// @notice Returns the factory that created this instance
    /// @return The factory that created this instance
    function factory() public view returns (IFactory) { return IFactory(_factory.read()); }

    /// @notice Initializes the contract setting `msg.sender` as the factory
    function __Instance__initialize() internal onlyInitializer {
        _factory.store(msg.sender);
    }

    /// @notice Only allow the owner defined by the factory to call the function
    modifier onlyOwner {
        if (msg.sender != factory().owner()) revert InstanceNotOwnerError(msg.sender);
        _;
    }

    /// @notice Only allow the function to be called when the factory is not paused
    modifier whenNotPaused {
        if (factory().paused()) revert InstancePausedError();
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../Initializable.sol";
import "../interfaces/IKept.sol";
import "../../storage/Storage.sol";

/// @title Kept
/// @notice Library to manage keeper incentivization.
/// @dev Surfaces a keep() modifier that handles measuring job gas costs and paying out rewards the keeper.
abstract contract Kept is IKept, Initializable {
    /// @dev The legacy Chainlink feed that is used to convert price ETH relative to the keeper token
    AddressStorage private constant _ethTokenOracleFeed = AddressStorage.wrap(keccak256("equilibria.root.Kept.ethTokenOracleFeed"));
    function ethTokenOracleFeed() public view returns (AggregatorV3Interface) { return AggregatorV3Interface(_ethTokenOracleFeed.read()); }

    /// @dev The token that the keeper is paid in
    Token18Storage private constant _keeperToken = Token18Storage.wrap(keccak256("equilibria.root.Kept.keeperToken"));
    function keeperToken() public view returns (Token18) { return _keeperToken.read(); }

    /// @notice Initializes the contract
    /// @param ethTokenOracleFeed_ The legacy Chainlink feed that is used to convert price ETH relative to the keeper token
    /// @param keeperToken_ The token that the keeper is paid in
    function __Kept__initialize(
        AggregatorV3Interface ethTokenOracleFeed_,
        Token18 keeperToken_
    ) internal onlyInitializer {
        _ethTokenOracleFeed.store(address(ethTokenOracleFeed_));
        _keeperToken.store(keeperToken_);
    }

    /// @notice Called by the keep modifier to raise the optionally raise the keeper fee
    /// @param amount The amount of keeper fee to raise
    /// @param data Arbitrary data passed in from the keep modifier
    function _raiseKeeperFee(UFixed18 amount, bytes memory data) internal virtual { }

    /// @dev Hook for inheriting contracts to perform logic to calculate the dynamic fee
    /// @param callData The calldata that will be used to price the dynamic fee
    function _calculateDynamicFee(bytes memory callData) internal view virtual returns (UFixed18) { }

    /// @notice Placed on a functon to incentivize keepers to call it
    /// @param multiplier The multiplier to apply to the gas used
    /// @param buffer The fixed gas amount to add to the gas used
    /// @param data Arbitrary data to pass to the _raiseKeeperFee function
    modifier keep(UFixed18 multiplier, uint256 buffer, bytes memory dynamicCalldata, bytes memory data) {
        uint256 startGas = gasleft();

        _;

        uint256 gasUsed = startGas - gasleft();
        UFixed18 keeperFee = UFixed18Lib.from(gasUsed)
            .mul(multiplier)
            .add(UFixed18Lib.from(buffer))
            .mul(UFixed18.wrap(block.basefee))
            .add(_calculateDynamicFee(dynamicCalldata))
            .mul(_etherPrice());
        _raiseKeeperFee(keeperFee, data);

        keeperToken().push(msg.sender, keeperFee);

        emit KeeperCall(msg.sender, gasUsed, multiplier, buffer, keeperFee);
    }

    /// @notice Returns the price of ETH in terms of the keeper token
    /// @return The price of ETH in terms of the keeper token
    function _etherPrice() private view returns (UFixed18) {
        (, int256 answer, , ,) = ethTokenOracleFeed().latestRoundData();
        return UFixed18Lib.from(Fixed18Lib.ratio(answer, 1e8)); // chainlink eth-usd feed uses 8 decimals
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Kept.sol";

// https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbGasInfo.sol#L93
interface ArbGasInfo {
    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256);
}

/// @dev Arbitrum Kept implementation
abstract contract Kept_Arbitrum is Kept {
    ArbGasInfo constant ARB_GAS = ArbGasInfo(0x000000000000000000000000000000000000006C);
    uint256 public constant ARB_GAS_MULTIPLIER = 16;
    uint256 public constant ARB_FIXED_OVERHEAD = 140;

    // https://docs.arbitrum.io/devs-how-tos/how-to-estimate-gas#breaking-down-the-formula
    // Tx Fee = block.baseFee * l2GasUsed + ArbGasInfo.getL1BaseFeeEstimate() * 16 * (calldataLength + fixedOverhead)
    // Dynamic buffer = (ArbGasInfo.getL1BaseFeeEstimate() * 16 * (calldataLength + fixedOverhead))
    function _calculateDynamicFee(bytes memory callData) internal view virtual override returns (UFixed18) {
        return UFixed18.wrap(
            ARB_GAS.getL1BaseFeeEstimate() * ARB_GAS_MULTIPLIER * (callData.length + ARB_FIXED_OVERHEAD)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "./IPausable.sol";
import "./IInstance.sol";

interface IFactory is IBeacon, IOwnable, IPausable {
    event InstanceRegistered(IInstance indexed instance);

    error FactoryNotInstanceError();

    function instances(IInstance instance) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IInitializable {
    error InitializableZeroVersionError();
    error InitializableAlreadyInitializedError(uint256 version);
    error InitializableNotInitializingError();

    event Initialized(uint256 version);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IFactory.sol";
import "./IInitializable.sol";

interface IInstance is IInitializable {
    error InstanceNotOwnerError(address sender);
    error InstancePausedError();

    function factory() external view returns (IFactory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IInitializable.sol";
import "../../number/types/UFixed18.sol";
import "../../token/types/Token18.sol";

interface IKept is IInitializable {
    event KeeperCall(address indexed sender, uint256 gasUsed, UFixed18 multiplier, uint256 buffer, UFixed18 keeperFee);

    function ethTokenOracleFeed() external view returns (AggregatorV3Interface);
    function keeperToken() external view returns (Token18);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IInitializable.sol";

interface IOwnable is IInitializable {
    event OwnerUpdated(address indexed newOwner);
    event PendingOwnerUpdated(address indexed newPendingOwner);

    error OwnableNotOwnerError(address sender);
    error OwnableNotPendingOwnerError(address sender);

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function updatePendingOwner(address newPendingOwner) external;
    function acceptOwner() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IInitializable.sol";
import "./IOwnable.sol";

interface IPausable is IInitializable, IOwnable {
    event PauserUpdated(address indexed newPauser);
    event Paused();
    event Unpaused();

    error PausablePausedError();
    error PausableNotPauserError(address sender);

    function pauser() external view returns (address);
    function paused() external view returns (bool);
    function updatePauser(address newPauser) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

/**
 * @title NumberMath
 * @notice Library for additional math functions that are not included in the OpenZeppelin libraries.
 */
library NumberMath {
    error DivisionByZero();

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return Math.ceilDiv(a, b);
    }

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(int256 a, int256 b) internal pure returns (int256) {
        return sign(a) * sign(b) * int256(divOut(SignedMath.abs(a), SignedMath.abs(b)));
    }

    /**
     * @notice Returns the sign of an int256
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a int256 to find the sign of
     * @return Sign of the int256
     */
    function sign(int256 a) internal pure returns (int256) {
        if (a > 0) return 1;
        if (a < 0) return -1;
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
type Fixed18Storage is bytes32;
using Fixed18StorageLib for Fixed18Storage global;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);
    Fixed18 public constant MAX = Fixed18.wrap(type(int256).max);
    Fixed18 public constant MIN = Fixed18.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed18.wrap(-1 * Fixed18.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldiv(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldivOut(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / Fixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), Fixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.min(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.max(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(SignedMath.abs(Fixed18.unwrap(a)));
    }
}

library Fixed18StorageLib {
    function read(Fixed18Storage self) internal view returns (Fixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed18Storage self, Fixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev Fixed6 type
type Fixed6 is int256;
using Fixed6Lib for Fixed6 global;
type Fixed6Storage is bytes32;
using Fixed6StorageLib for Fixed6Storage global;

/**
 * @title Fixed6Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed6Lib {
    error Fixed6OverflowError(uint256 value);

    int256 private constant BASE = 1e6;
    Fixed6 public constant ZERO = Fixed6.wrap(0);
    Fixed6 public constant ONE = Fixed6.wrap(BASE);
    Fixed6 public constant NEG_ONE = Fixed6.wrap(-1 * BASE);
    Fixed6 public constant MAX = Fixed6.wrap(type(int256).max);
    Fixed6 public constant MIN = Fixed6.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (Fixed6) {
        uint256 value = UFixed6.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed6OverflowError(value);
        return Fixed6.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed6 m) internal pure returns (Fixed6) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed6.wrap(-1 * Fixed6.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a, bool roundOut) internal pure returns (Fixed6) {
        return roundOut ? Fixed6.wrap(NumberMath.divOut(Fixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed6 a) internal pure returns (bool) {
        return Fixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) + Fixed6.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) - Fixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * BASE / Fixed6.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldiv(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldivOut(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / Fixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), Fixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed6 a, Fixed6 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed6.unwrap(a), Fixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.min(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.max(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed6 a) internal pure returns (int256) {
        return Fixed6.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed6 a) internal pure returns (int256) {
        if (Fixed6.unwrap(a) > 0) return 1;
        if (Fixed6.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed6 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(SignedMath.abs(Fixed6.unwrap(a)));
    }
}

library Fixed6StorageLib {
    function read(Fixed6Storage self) internal view returns (Fixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed6Storage self, Fixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;
using UFixed18Lib for UFixed18 global;
type UFixed18Storage is bytes32;
using UFixed18StorageLib for UFixed18Storage global;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);
    UFixed18 public constant MAX = UFixed18.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * BASE, UFixed18.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldiv(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldivOut(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / UFixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), UFixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.min(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.max(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

library UFixed18StorageLib {
    function read(UFixed18Storage self) internal view returns (UFixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed18Storage self, UFixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev UFixed6 type
type UFixed6 is uint256;
using UFixed6Lib for UFixed6 global;
type UFixed6Storage is bytes32;
using UFixed6StorageLib for UFixed6Storage global;

/**
 * @title UFixed6Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed6Lib {
    error UFixed6UnderflowError(int256 value);

    uint256 private constant BASE = 1e6;
    UFixed6 public constant ZERO = UFixed6.wrap(0);
    UFixed6 public constant ONE = UFixed6.wrap(BASE);
    UFixed6 public constant MAX = UFixed6.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (UFixed6) {
        int256 value = Fixed6.unwrap(a);
        if (value < 0) revert UFixed6UnderflowError(value);
        return UFixed6.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a, bool roundOut) internal pure returns (UFixed6) {
        return roundOut ? UFixed6.wrap(NumberMath.divOut(UFixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed6 a) internal pure returns (bool) {
        return UFixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) + UFixed6.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) - UFixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * BASE / UFixed6.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * BASE, UFixed6.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldiv(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldivOut(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / UFixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), UFixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed6 a, UFixed6 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed6.unwrap(a), UFixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.min(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.max(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed6 a) internal pure returns (uint256) {
        return UFixed6.unwrap(a) / BASE;
    }
}

library UFixed6StorageLib {
    function read(UFixed6Storage self) internal view returns (UFixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed6Storage self, UFixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";
import "./PController6.sol";

/// @dev PAccumulator6 type
struct PAccumulator6 {
    Fixed6 _value;
    Fixed6 _skew;
}
using PAccumulator6Lib for PAccumulator6 global;

/// @title PAccumulator6Lib
/// @notice Accumulator for a the fixed 6-decimal PID controller. This holds the "last seen state" of the PID controller
///         and works in conjunction with the PController6 to compute the current rate.
/// @dev This implementation is specifically a P controller, with I_k and D_k both set to 0. In between updates, it
///      continues to accumulate at a linear rate based on the previous skew, but the rate is capped at the max value.
///      Once the rate hits the max value, it will continue to accumulate at the max value until the next update.
library PAccumulator6Lib {
    /// @notice Accumulates the rate against notional given the prior and current state
    /// @param self The controller accumulator
    /// @param controller The controller configuration
    /// @param skew The current skew
    /// @param fromTimestamp The timestamp of the prior accumulation
    /// @param toTimestamp The current timestamp
    /// @param notional The notional to accumulate against
    /// @return accumulated The total accumulated amount
    function accumulate(
        PAccumulator6 memory self,
        PController6 memory controller,
        Fixed6 skew,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        UFixed6 notional
    ) internal pure returns (Fixed6 accumulated) {
        // compute new value and intercept
        (Fixed6 newValue, UFixed6 interceptTimestamp) =
            controller.compute(self._value, self._skew, fromTimestamp, toTimestamp);

        // accumulate rate within max
        accumulated = _accumulate(
            self._value.add(newValue),
            UFixed6Lib.from(fromTimestamp),
            interceptTimestamp,
            notional
        ).div(Fixed6Lib.from(2)); // rate = self._value + newValue / 2 -> divide here for added precision

        // accumulate rate outside of max
        accumulated = _accumulate(
            newValue,
            interceptTimestamp,
            UFixed6Lib.from(toTimestamp),
            notional
        ).add(accumulated);

        // update values
        self._value = newValue;
        self._skew = skew;
    }

    /// @notice Helper function to accumulate a singular rate against notional
    /// @param rate The rate to accumulate
    /// @param fromTimestamp The timestamp to accumulate from
    /// @param toTimestamp The timestamp to accumulate to
    /// @param notional The notional to accumulate against
    /// @return The accumulated amount
    function _accumulate(
        Fixed6 rate,
        UFixed6 fromTimestamp,
        UFixed6 toTimestamp,
        UFixed6 notional
    ) private pure returns (Fixed6) {
        return rate
            .mul(Fixed6Lib.from(toTimestamp.sub(fromTimestamp)))
            .mul(Fixed6Lib.from(notional))
            .div(Fixed6Lib.from(365 days));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";

/// @dev PController6 type
struct PController6 {
    UFixed6 k;
    UFixed6 max;
}
using PController6Lib for PController6 global;

/// @title PController6Lib
/// @notice Configuration for a the fixed 6-decimal PID controller.
/// @dev Each second, the PID controller's value is incremented by `skew / k`, with `max` as the maximum value.
library PController6Lib {
    /// @notice compute the new value and intercept timestamp based on the prior controller state
    /// @dev `interceptTimestamp` will never exceed `toTimestamp`
    /// @param self the controller configuration
    /// @param value the prior value
    /// @param skew The prior skew
    /// @param fromTimestamp The prior timestamp
    /// @param toTimestamp The current timestamp
    /// @return newValue the new value
    /// @return interceptTimestamp the timestamp at which the value will be at the max
    function compute(
        PController6 memory self,
        Fixed6 value,
        Fixed6 skew,
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (Fixed6 newValue, UFixed6 interceptTimestamp) {
        // compute the new value without considering the max
        Fixed6 newValueUncapped = value.add(
            Fixed6Lib.from(int256(toTimestamp - fromTimestamp))
                .mul(skew)
                .div(Fixed6Lib.from(self.k))
        );

        // cap the new value at the max
        newValue = Fixed6Lib.from(newValueUncapped.sign(), self.max.min(newValueUncapped.abs()));

        // compute distance and range to the resultant value
        (UFixed6 distance, Fixed6 range) = (UFixed6Lib.from(toTimestamp - fromTimestamp), newValueUncapped.sub(value));

        // compute the amount of buffer into the value is outside the max
        UFixed6 buffer = value.abs().gt(self.max) ?
            UFixed6Lib.ZERO :
            Fixed6Lib.from(range.sign(), self.max).sub(value).abs();

        // compute the timestamp at which the value will be at the max
        interceptTimestamp = range.isZero() ?
            UFixed6Lib.from(toTimestamp) :
            UFixed6Lib.from(fromTimestamp).add(distance.muldiv(buffer, range.abs())).min(UFixed6Lib.from(toTimestamp));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed18.sol";

/// @dev Stored boolean slot
type BoolStorage is bytes32;
using BoolStorageLib for BoolStorage global;

/// @dev Stored uint256 slot
type Uint256Storage is bytes32;
using Uint256StorageLib for Uint256Storage global;

/// @dev Stored int256 slot
type Int256Storage is bytes32;
using Int256StorageLib for Int256Storage global;

/// @dev Stored address slot
type AddressStorage is bytes32;
using AddressStorageLib for AddressStorage global;

/// @dev Stored bytes32 slot
type Bytes32Storage is bytes32;
using Bytes32StorageLib for Bytes32Storage global;

/**
 * @title BoolStorageLib
 * @notice Library to manage storage and retrieval of a boolean at a fixed storage slot
 */
library BoolStorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored bool value
     */
    function read(BoolStorage self) internal view returns (bool value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value boolean value to store
     */
    function store(BoolStorage self, bool value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title Uint256StorageLib
 * @notice Library to manage storage and retrieval of an uint256 at a fixed storage slot
 */
library Uint256StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored uint256 value
     */
    function read(Uint256Storage self) internal view returns (uint256 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value uint256 value to store
     */
    function store(Uint256Storage self, uint256 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title Int256StorageLib
 * @notice Library to manage storage and retrieval of an int256 at a fixed storage slot
 */
library Int256StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored int256 value
     */
    function read(Int256Storage self) internal view returns (int256 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value int256 value to store
     */
    function store(Int256Storage self, int256 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title AddressStorageLib
 * @notice Library to manage storage and retrieval of an address at a fixed storage slot
 */
library AddressStorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored address value
     */
    function read(AddressStorage self) internal view returns (address value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value address value to store
     */
    function store(AddressStorage self, address value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

/**
 * @title Bytes32StorageLib
 * @notice Library to manage storage and retrieval of a bytes32 at a fixed storage slot
 */
library Bytes32StorageLib {
    /**
     * @notice Retrieves the stored value
     * @param self Storage slot
     * @return value Stored bytes32 value
     */
    function read(Bytes32Storage self) internal view returns (bytes32 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    /**
     * @notice Stores the value at the specific slot
     * @param self Storage slot
     * @param value bytes32 value to store
     */
    function store(Bytes32Storage self, bytes32 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../number/types/UFixed18.sol";

/// @dev Token18
type Token18 is address;
using Token18Lib for Token18 global;
type Token18Storage is bytes32;
using Token18StorageLib for Token18Storage global;

/**
 * @title Token18Lib
 * @notice Library to manage 18-decimal ERC20s that is compliant with the fixed-decimal types.
 * @dev Maintains significant gas savings over other Token implementations since no conversion take place
 */
library Token18Lib {
    using SafeERC20 for IERC20;

    Token18 public constant ZERO = Token18.wrap(address(0));

    /**
     * @notice Returns whether a token is the zero address
     * @param self Token to check for
     * @return Whether the token is the zero address
     */
    function isZero(Token18 self) internal pure returns (bool) {
        return Token18.unwrap(self) == Token18.unwrap(ZERO);
    }

    /**
     * @notice Returns whether the two tokens are equal
     * @param a First token to compare
     * @param b Second token to compare
     * @return Whether the two tokens are equal
     */
    function eq(Token18 a, Token18 b) internal pure returns (bool) {
        return Token18.unwrap(a) ==  Token18.unwrap(b);
    }

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @dev Uses `approve` rather than `safeApprove` since the race condition
     *      in safeApprove does not apply when going to an infinite approval
     * @param self Token to grant approval
     * @param grantee Address to allow spending
     */
    function approve(Token18 self, address grantee) internal {
        IERC20(Token18.unwrap(self)).approve(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @dev There are important race conditions to be aware of when using this function
            with values other than 0. This will revert if moving from non-zero to non-zero amounts
            See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a55b7d13722e7ce850b626da2313f3e66ca1d101/contracts/token/ERC20/IERC20.sol#L57
     * @param self Token to grant approval
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token18 self, address grantee, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeApprove(grantee, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token18 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token18 self, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransfer(recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token18 self, address benefactor, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, address(this), UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token18 self, address benefactor, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token18 self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token18 self, address account) internal view returns (UFixed18) {
        return UFixed18.wrap(IERC20(Token18.unwrap(self)).balanceOf(account));
    }
}

library Token18StorageLib {
    function read(Token18Storage self) internal view returns (Token18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Token18Storage self, Token18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed6.sol";
import "../number/types/Fixed6.sol";

/**
 * @title CurveMath6
 * @notice Library for managing math operations for utilization curves.
 */
library CurveMath6 {
    error CurveMath6OutOfBoundsError();

    /**
     * @notice Computes a linear interpolation between two points
     * @param startX First point's x-coordinate
     * @param startY First point's y-coordinate
     * @param endX Second point's x-coordinate
     * @param endY Second point's y-coordinate
     * @param targetX x-coordinate to interpolate
     * @return y-coordinate for `targetX` along the line from (`startX`, `startY`) -> (`endX`, `endY`)
     */
    function linearInterpolation(
        UFixed6 startX,
        Fixed6 startY,
        UFixed6 endX,
        Fixed6 endY,
        UFixed6 targetX
    ) internal pure returns (Fixed6) {
        if (targetX.lt(startX) || targetX.gt(endX)) revert CurveMath6OutOfBoundsError();

        UFixed6 xRange = endX.sub(startX);
        Fixed6 yRange = endY.sub(startY);
        UFixed6 xRatio = targetX.sub(startX).div(xRange);
        return yRange.mul(Fixed6Lib.from(xRatio)).add(startY);
    }

    /**
     * @notice Computes a linear interpolation between two points
     * @param startX First point's x-coordinate
     * @param startY First point's y-coordinate
     * @param endX Second point's x-coordinate
     * @param endY Second point's y-coordinate
     * @param targetX x-coordinate to interpolate
     * @return y-coordinate for `targetX` along the line from (`startX`, `startY`) -> (`endX`, `endY`)
     */
    function linearInterpolation(
        UFixed6 startX,
        UFixed6 startY,
        UFixed6 endX,
        UFixed6 endY,
        UFixed6 targetX
    ) internal pure returns (UFixed6) {
        return UFixed6Lib.from(linearInterpolation(startX, Fixed6Lib.from(startY), endX, Fixed6Lib.from(endY), targetX));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../CurveMath6.sol";
import "../../number/types/UFixed6.sol";

/// @dev UJumpRateUtilizationCurve6 type
struct UJumpRateUtilizationCurve6 {
    UFixed6 minRate;
    UFixed6 maxRate;
    UFixed6 targetRate;
    UFixed6 targetUtilization;
}
using UJumpRateUtilizationCurve6Lib for UJumpRateUtilizationCurve6 global;

/**
 * @title UJumpRateUtilizationCurve6Lib
 * @notice Library for the unsigned base-6 Jump Rate utilization curve type
 */
library UJumpRateUtilizationCurve6Lib {
    /**
     * @notice Computes the corresponding rate for a utilization ratio
     * @param utilization The utilization ratio
     * @return The corresponding rate
     */
    function compute(UJumpRateUtilizationCurve6 memory self, UFixed6 utilization) internal pure returns (UFixed6) {
        if (utilization.lt(self.targetUtilization)) {
            return CurveMath6.linearInterpolation(
                UFixed6Lib.ZERO,
                self.minRate,
                self.targetUtilization,
                self.targetRate,
                utilization
            );
        }
        if (utilization.lt(UFixed6Lib.ONE)) {
            return CurveMath6.linearInterpolation(
                self.targetUtilization,
                self.targetRate,
                UFixed6Lib.ONE,
                self.maxRate,
                utilization
            );
        }
        return self.maxRate;
    }

    function accumulate(
        UJumpRateUtilizationCurve6 memory self,
        UFixed6 utilization,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        UFixed6 notional
    ) internal pure returns (UFixed6) {
        return compute(self, utilization)
            .mul(UFixed6Lib.from(toTimestamp - fromTimestamp))
            .mul(notional)
            .div(UFixed6Lib.from(365 days));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPyth.sol";
import "./PythErrors.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
    function queryPriceFeed(
        bytes32 id
    ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(
        bytes32 id
    ) public view virtual returns (bool exists);

    function getValidTimePeriod()
        public
        view
        virtual
        override
        returns (uint validTimePeriod);

    function getPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function getEmaPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    // Access modifier is overridden to public to be able to call it locally.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable virtual override;

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable virtual override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; i++) {
            if (
                !priceFeedExists(priceIds[i]) ||
                queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}