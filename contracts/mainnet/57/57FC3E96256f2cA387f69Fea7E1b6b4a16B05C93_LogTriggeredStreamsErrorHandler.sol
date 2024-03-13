/**
 *Submitted for verification at Arbiscan.io on 2024-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

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

struct Log {
  uint256 index;
  uint256 timestamp;
  bytes32 txHash;
  uint256 blockNumber;
  bytes32 blockHash;
  address source;
  bytes32[] topics;
  bytes data;
}

interface StreamsLookupCompatibleInterface {
  error StreamsLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize StreamsLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from data streams endpoint.
   * @param extraData context data from streams lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice this is a new, optional function in streams lookup. It is meant to surface streams lookup errors.
   * @param errCode an uint value that represents the streams lookup error code.
   * @param extraData context data from streams lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkErrorHandler(
    uint256 errCode,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}

interface ILogAutomation {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param log the raw log data matching the filter that this contract has
   * registered as a trigger
   * @param checkData user-specified extra data to provide context to this upkeep
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkLog(
    Log calldata log,
    bytes memory checkData
  ) external returns (bool upkeepNeeded, bytes memory performData);

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

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @return verifierResponse The encoded response from the verifier.
   */
  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
}

contract LogTriggeredStreamsErrorHandler is ILogAutomation, StreamsLookupCompatibleInterface {
  event PerformingDataStreamsLookupUpkeep(
    address indexed from,
    uint256 orderId,
    uint256 amount,
    address exchange,
    int256 timestamp,
    bytes report,
    bytes verified
  );
  event LimitOrderExecuted(uint256 indexed orderId, uint256 indexed amount, address indexed exchange); // keccak(LimitOrderExecuted(uint256,uint256,address)) => 0xd1ffe9e45581c11d7d9f2ed5f75217cd4be9f8b7eee6af0f6d03f46de53956cd

  event PerformingFallbackDataFeeds(
    address indexed from,
    uint256 orderId,
    uint256 amount,
    address exchange,
    int256 timestamp,
    int256 answer,
    bytes32 errorCode
  );

  IVerifierProxy internal constant VERIFIER = IVerifierProxy(0x478Aa2aC9F6D65F84e09D9185d126c3a17c2a93C);

  // for log trigger
  bytes32 constant sentSig = 0x3e9c37b3143f2eb7e9a2a0f8091b6de097b62efcfe48e1f68847a832e521750a;
  bytes32 constant withdrawnSig = 0x0a71b8ed921ff64d49e4d39449f8a21094f38a0aeae489c3051aedd63f2c229f;
  bytes32 constant executedSig = 0xd1ffe9e45581c11d7d9f2ed5f75217cd4be9f8b7eee6af0f6d03f46de53956cd;

  // for mercury config
  bool public verify;
  bool public shouldFallbackToFeedOnError;
  string[] public feedsHex = ["0x00020d95813497a566307e6af5f59ca3cbbe8d8cd62672e5b3fc4e0d67787f23"];
  string public feedParamKey = "feedIDs";
  string public timeParamKey = "timestamp";
  uint256 public counter;
  int256 public timeDelta = -5;
  bytes32 public fallBackErrorCode = 0x00000000000000000000000000000000000000000000000000000000000C55D0;
  address public fallbackDataFeedAddress = 0x6ce185860a4963106506C203335A2910413708e9;
  AggregatorV3Interface internal fallbackDataFeed = AggregatorV3Interface(fallbackDataFeedAddress);
  address public owner;

  constructor(bool _verify) {
    verify = _verify;
    counter = 0;
    owner = tx.origin;
  }

  function start() public {
    // need an initial event to begin the cycle
    emit LimitOrderExecuted(1, 100, tx.origin);
  }

  function setTimeParamKey(string memory timeParam) external {
    timeParamKey = timeParam;
  }

  function setFeedParamKey(string memory feedParam) external {
    feedParamKey = feedParam;
  }

  function setFeedsHex(string[] memory newFeeds) external {
    feedsHex = newFeeds;
  }

  function setShouldFallbackToFeedOnError(bool value) public {
    shouldFallbackToFeedOnError = value;
  }

  function setTimeDelta(int256 value) public {
    timeDelta = value;
  }

  function setFallbackDataFeedAddress(address value) public {
    fallbackDataFeedAddress = value;
    fallbackDataFeed = AggregatorV3Interface(value);
  }

  function setFallbackErrorCode(bytes32 value) public {
    fallBackErrorCode = value;
  }

  function checkLog(
    Log calldata log,
    bytes memory
  ) external override returns (bool upkeepNeeded, bytes memory performData) {
    int256 blockTimestamp = getBlockTimestamp();

    // filter by event signature
    if (log.topics[0] == executedSig) {
      // filter by indexed parameters
      bytes memory t1 = abi.encodePacked(log.topics[1]); // bytes32 to bytes
      uint256 orderId = abi.decode(t1, (uint256));
      bytes memory t2 = abi.encodePacked(log.topics[2]);
      uint256 amount = abi.decode(t2, (uint256));
      bytes memory t3 = abi.encodePacked(log.topics[3]);
      address exchange = abi.decode(t3, (address));

      revert StreamsLookup(
        feedParamKey,
        feedsHex,
        timeParamKey,
        uint(blockTimestamp),
        abi.encode(orderId, amount, exchange, executedSig)
      );
    }
    revert("could not find matching event sig");
  }

  function performUpkeep(bytes calldata performData) external {
    (bool streamsLookupSuccess, bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bool, bytes[], bytes));
    (uint256 orderId, uint256 amount, address exchange, bytes32 logTopic0) = abi.decode(
      extraData,
      (uint256, uint256, address, bytes32)
    );

    if (exchange == owner) {
      if (!streamsLookupSuccess) {
        bytes32 value = abi.decode(values[0], (bytes32));
        if (value == fallBackErrorCode) {
            (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
            ) =  fallbackDataFeed.latestRoundData();
                emit PerformingFallbackDataFeeds(
                    tx.origin,
                    orderId,
                    amount,
                    exchange,
                    getBlockTimestamp(),
                    answer,
                    value
                );

            }
    } else {
        bytes memory verifiedResponse = "";
        if (verify) {
        verifiedResponse = VERIFIER.verify(values[0]);
        }

        counter = counter + 1;

        emit PerformingDataStreamsLookupUpkeep(
        tx.origin,
        orderId,
        amount,
        exchange,
        getBlockTimestamp(),
        values[0],
        verifiedResponse
        );
    }
    }
  }

  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external override  view returns (bool, bytes memory) {
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(true, values, extraData);
    return (true, performData);
  }

  function checkErrorHandler(
    uint256 errCode,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData) {
    bytes[] memory values = new bytes[](2);
    values[0] = abi.encode(errCode);
    values[1] = abi.encode(extraData);
    performData = abi.encode(false, values, extraData);
    return (shouldFallbackToFeedOnError, performData);
  }

  function getBlockTimestamp() internal view returns (int256) {
      return int(block.timestamp) + timeDelta;
  }
}