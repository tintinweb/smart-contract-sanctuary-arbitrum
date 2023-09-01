pragma solidity 0.8.6;

import "../../../automation/interfaces/AutomationCompatibleInterface.sol";
import "../2_1/interfaces/FeedLookupCompatibleInterface.sol";
import "../../../ChainSpecificUtil.sol";

/*--------------------------------------------------------------------------------------------------------------------+
| Mercury + Automation                                                                                                |
| ________________                                                                                                    |
| This implementation allows for an on-chain registry of price feed data to be maintained and updated by Automation   |
| nodes. The upkeep provides the following advantages:                                                                |
|   - Node operator savings. The single committee of automation nodes is able to update all price feed data using     |
|     off-chain feed data.                                                                                            |
|   - Fetch batches of price data. All price feed data is held on the same contract, so a contract that needs         |
|     multiple sets of feed data can fetch them while paying for only one external call.                              |
|   - Scalability. Feeds can be added or removed from the contract with a single contract call, and the number of     |
|     feeds that the registry can store is unbounded.                                                                 |
|                                                                                                                     |
| Key Contracts:                                                                                                      |
|   - `MercuryRegistry.sol` - stores price feed data and implements core logic.                                       |
|   - `MercuryRegistryBatchUpkeep.sol` - enables batching for the registry.                                           |
|   - `MercuryRegistry.t.sol` - contains foundry tests to demonstrate various flows.                                  |
|                                                                                                                     |
| TODO:                                                                                                               |
|   - Access control. Specifically, the the ability to execute `performUpkeep`.                                       |
|   - Optimize gas consumption.                                                                                       |
-+---------------------------------------------------------------------------------------------------------------------*/
contract MercuryRegistry is AutomationCompatibleInterface, FeedLookupCompatibleInterface {
  error DuplicateFeed(string feedId);
  error FeedNotActive(string feedId);

  // Feed object used for storing feed data.
  // not included but contained in reports:
  // - blocknumberUpperBound
  // - upperBlockhash
  // - blocknumberLowerBound
  // - currentBlockTimestamp
  struct Feed {
    uint32 observationsTimestamp; // the timestamp of the most recent data assigned to this feed
    int192 price; // the current price of the feed
    int192 bid; // the current bid price of the feed
    int192 ask; // the current ask price of the feed
    string feedName; // the name of the feed
    string feedId; // the id of the feed (hex encoded)
    bool active; // true if the feed is being actively updated, otherwise false
  }

  // Report object obtained from off-chain Mercury server.
  struct Report {
    bytes32 feedId; // the feed Id of the report
    uint32 observationsTimestamp; // the timestamp of when the data was observed
    int192 price; // the median value of the OCR round
    int192 bid; // the median bid of the OCR round
    int192 ask; // the median ask if the OCR round
    uint64 blocknumberUpperBound; // the highest block observed at the time the report was generated
    bytes32 upperBlockhash; // the blockhash of the highest block observed
    uint64 blocknumberLowerBound; // the lowest block observed at the time the report was generated
    uint64 currentBlockTimestamp; // the timestamp of the highest block observed
  }

  event FeedUpdated(uint32 observationsTimestamp, int192 price, int192 bid, int192 ask, string feedId);

  string constant c_feedParamKey = "feedIdHex"; // for Mercury v0.2 - format by which feeds are identified
  string constant c_timeParamKey = "blockNumber"; // for Mercury v0.2 - format by which feeds are filtered to be sufficiently recent
  IVerifierProxy immutable i_verifier; // for Mercury v0.2 - verifies off-chain reports

  int192 constant scale = 1_000_000; // a scalar used for measuring deviation with precision
  int192 s_deviationPercentagePPM; // acceptable deviatoin threshold - 1.5% = 15_000, 100% = 1_000_000, etc..
  uint32 s_stalenessSeconds; // acceptable staleness threshold - 60 = 1 minute, 300 = 5 minutes, etc..

  string[] public s_feeds; // list of feed Ids
  mapping(string => Feed) public s_feedMapping; // mapping of feed Ids to stored feed data

  constructor(
    string[] memory feedIds,
    string[] memory feedNames,
    address verifier,
    int192 deviationPercentagePPM,
    uint32 stalenessSeconds
  ) {
    i_verifier = IVerifierProxy(verifier);

    // Store desired deviation threshold and staleness seconds.
    s_deviationPercentagePPM = deviationPercentagePPM;
    s_stalenessSeconds = stalenessSeconds;

    // Store desired feeds.
    setFeeds(feedIds, feedNames);
  }

  // Returns a user-defined batch of feed data, based on the on-chain state.
  function getLatestFeedData(string[] memory feedIds) external view returns (Feed[] memory) {
    Feed[] memory feeds = new Feed[](feedIds.length);
    for (uint256 i = 0; i < feedIds.length; i++) {
      feeds[i] = s_feedMapping[feedIds[i]];
    }

    return feeds;
  }

  // Invoke a feed lookup through the checkUpkeep function. Expected to run on a chron schedule.
  function checkUpkeep(bytes calldata /* data */) external view override returns (bool, bytes memory) {
    string[] memory feeds = s_feeds;
    return revertForFeedLookup(feeds);
  }

  // Extracted from `checkUpkeep` for batching purposes.
  function revertForFeedLookup(string[] memory feeds) public view returns (bool, bytes memory) {
    uint256 blockNumber = ChainSpecificUtil.getBlockNumber();
    revert FeedLookup(c_feedParamKey, feeds, c_timeParamKey, blockNumber, "EXTRA_DATA_FOR_FUTURE_FUNCTIONS_CALLS");
  }

  // Filter for feeds that have deviated sufficiently from their respective on-chain values, or where
  // the on-chain values are sufficiently stale.
  function checkCallback(
    bytes[] memory values,
    bytes memory lookupData
  ) external view override returns (bool, bytes memory) {
    bytes[] memory filteredValues = new bytes[](values.length);
    uint256 count = 0;
    for (uint256 i = 0; i < values.length; i++) {
      Report memory report = getReport(values[i]);
      string memory feedId = bytes32ToHexString(abi.encodePacked(report.feedId));
      Feed memory feed = s_feedMapping[feedId];
      if (
        (report.observationsTimestamp - feed.observationsTimestamp > s_stalenessSeconds) ||
        deviationExceedsThreshold(feed.price, report.price)
      ) {
        filteredValues[count] = values[i];
        count++;
      }
    }

    // Adjusts the lenght of the filteredValues array to `count` such that it
    // does not have extra empty slots, in case some items were filtered.
    assembly {
      mstore(filteredValues, count)
    }

    bytes memory performData = abi.encode(filteredValues, lookupData);
    return (filteredValues.length > 0, performData);
  }

  // Use deviated off-chain values to update on-chain state.
  // TODO:
  // - The implementation provided here is readable but crude. Remaining gas should be checked between iterations
  // of the for-loop, and the failure of a single item should not cause the entire batch to revert.
  function performUpkeep(bytes calldata performData) external override {
    (bytes[] memory values /* bytes memory lookupData */, ) = abi.decode(performData, (bytes[], bytes));
    for (uint256 i = 0; i < values.length; i++) {
      // Verify and decode report.
      Report memory report = abi.decode(i_verifier.verify(values[i]), (Report));
      string memory feedId = bytes32ToHexString(abi.encodePacked(report.feedId));

      // Feeds that have been removed between checkUpkeep and performUpkeep should not be updated.
      require(bytes(s_feedMapping[feedId].feedId).length > 0, "feed removed");

      // Sanity check. Stale reports should not get through, but ensure they do not cause a regression
      // in the registry.
      require(s_feedMapping[feedId].observationsTimestamp <= report.observationsTimestamp, "stale report");

      // Assign new values to state.
      s_feedMapping[feedId].bid = report.bid;
      s_feedMapping[feedId].ask = report.ask;
      s_feedMapping[feedId].price = report.price;
      s_feedMapping[feedId].observationsTimestamp = report.observationsTimestamp;

      // Emit log (not gas efficient to do this for each update).
      emit FeedUpdated(report.observationsTimestamp, report.price, report.bid, report.ask, feedId);
    }
  }

  // Decodes a mercury respone into an on-chain object. Thanks @mikestone!!
  function getReport(bytes memory signedReport) internal pure returns (Report memory) {
    /*
     * bytes32[3] memory reportContext,
     * bytes memory reportData,
     * bytes32[] memory rs,
     * bytes32[] memory ss,
     * bytes32 rawVs
     **/
    (, bytes memory reportData, , , ) = abi.decode(signedReport, (bytes32[3], bytes, bytes32[], bytes32[], bytes32));

    Report memory report = abi.decode(reportData, (Report));
    return report;
  }

  // Check if the off-chain value has deviated sufficiently from the on-chain value to justify an update.
  // `scale` is used to ensure precision is not lost.
  function deviationExceedsThreshold(int192 onChain, int192 offChain) public view returns (bool) {
    // Compute absolute difference between the on-chain and off-chain values.
    int192 scaledDifference = (onChain - offChain) * scale;
    if (scaledDifference < 0) {
      scaledDifference = -scaledDifference;
    }

    // Compare to the allowed deviation from the on-chain value.
    int192 deviationMax = ((onChain * scale) * s_deviationPercentagePPM) / scale;
    return scaledDifference > deviationMax;
  }

  // Helper function to reconcile a difference in formatting:
  // - Automation passes feedId into their off-chain lookup function as a string.
  // - Mercury stores feedId in their reports as a bytes32.
  function bytes32ToHexString(bytes memory buffer) internal pure returns (string memory) {
    bytes memory converted = new bytes(buffer.length * 2);
    bytes memory _base = "0123456789abcdef";
    for (uint256 i = 0; i < buffer.length; i++) {
      converted[i * 2] = _base[uint8(buffer[i]) / _base.length];
      converted[i * 2 + 1] = _base[uint8(buffer[i]) % _base.length];
    }
    return string(abi.encodePacked("0x", converted));
  }

  function addFeeds(string[] memory feedIds, string[] memory feedNames) external {
    for (uint256 i = 0; i < feedIds.length; i++) {
      string memory feedId = feedIds[i];
      if (s_feedMapping[feedId].active) {
        revert DuplicateFeed(feedId);
      }

      s_feedMapping[feedId].feedName = feedNames[i];
      s_feedMapping[feedId].feedId = feedId;
      s_feedMapping[feedId].active = true;

      s_feeds.push(feedId);
    }
  }

  function setFeeds(string[] memory feedIds, string[] memory feedNames) public {
    // Ensure correctly formatted constructor arguments.
    require(feedIds.length == feedNames.length, "incorrectly formatted feeds");

    // Clear prior feeds.
    for (uint256 i = 0; i < s_feeds.length; i++) {
      s_feedMapping[s_feeds[i]].active = false;
    }

    // Assign new feeds.
    for (uint256 i = 0; i < feedIds.length; i++) {
      string memory feedId = feedIds[i];
      if (s_feedMapping[feedId].active) {
        revert DuplicateFeed(feedId);
      }

      s_feedMapping[feedId].feedName = feedNames[i];
      s_feedMapping[feedId].feedId = feedId;
      s_feedMapping[feedId].active = true;
    }
    s_feeds = feedIds;
  }

  function setConfig(int192 deviationPercentagePPM, uint32 stalenessSeconds) external {
    s_stalenessSeconds = stalenessSeconds;
    s_deviationPercentagePPM = deviationPercentagePPM;
  }
}

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payload The encoded data to be verified, including the signed
   * report and any metadata for billing.
   * @return verifiedReport The encoded report from the verifier.
   */
  function verify(bytes calldata payload) external payable returns (bytes memory verifiedReport);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FeedLookupCompatibleInterface {
  error FeedLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize FeedLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from Mercury endpoint.
   * @param extraData context data from feed lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ArbSys} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import {ArbGasInfo} from "./vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";

//@dev A library that abstracts out opcodes that behave differently across chains.
//@dev The methods below return values that are pertinent to the given chain.
//@dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);
  address private constant ARBGAS_ADDR = address(0x000000000000000000000000000000000000006C);
  ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);
  uint256 private constant ARB_MAINNET_CHAIN_ID = 0; // 42161, disabled for Forge testing
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 0; // 421613, disabled for Forge testing

  function getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      if ((getBlockNumber() - blockNumber) > 256 || blockNumber >= getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  function getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }

  function getCurrentTxL1GasFees() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      return ARBGAS.getCurrentTxL1GasFees();
    }
    return 0;
  }

  /**
   * @notice Returns the gas cost in wei of calldataSizeBytes of calldata being posted
   * @notice to L1.
   */
  function getL1CalldataGasCost(uint256 calldataSizeBytes) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (chainid == ARB_MAINNET_CHAIN_ID || chainid == ARB_GOERLI_TESTNET_CHAIN_ID) {
      (, uint256 l1PricePerByte, , , , ) = ARBGAS.getPricesInWei();
      // see https://developer.arbitrum.io/devs-how-tos/how-to-estimate-gas#where-do-we-get-all-this-information-from
      // for the justification behind the 140 number.
      return l1PricePerByte * (calldataSizeBytes + 140);
    }
    return 0;
  }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns(uint);
}