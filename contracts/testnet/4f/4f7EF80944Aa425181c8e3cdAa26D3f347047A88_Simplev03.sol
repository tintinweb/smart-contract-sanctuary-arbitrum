/**
 *Submitted for verification at Arbiscan.io on 2023-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface StreamsLookupCompatibleInterface {
  error StreamsLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);
    function checkCallback(bytes[] memory values, bytes memory extraData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);
}
pragma solidity ^0.8.0;

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

interface ILogAutomation {
    function checkLog(Log calldata log, bytes memory checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}
pragma solidity >=0.4.21 <0.9.0;

contract Simplev03 is ILogAutomation, StreamsLookupCompatibleInterface {
    event Update(bytes indexed clBlob);
    event Recieved();
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDs";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "timestamp";
    string[] public feedsHex = ["0x00023496426b520583ae20a66d80484e0fc18544866a5b0bfee15ec771963274"];

    function checkLog(Log calldata log, bytes memory)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {   
        revert StreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            feedsHex,
            STRING_DATASTREAMS_QUERYLABEL,
            log.timestamp,
            ""
        );
    }

    function performUpkeep(bytes calldata performData) external override {
        (bytes[] memory values, /*bytes memory extraData*/) = abi.decode(
            performData,
            (bytes[], bytes)
        );
        bytes memory report = values[0];
        emit Update(report);
        emit Recieved();
    }

    function checkCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

}