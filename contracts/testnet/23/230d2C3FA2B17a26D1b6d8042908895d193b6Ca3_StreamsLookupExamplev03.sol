/**
 *Submitted for verification at Arbiscan.io on 2023-09-27
*/

/**
 *Submitted for verification at Arbiscan.io on 2023-09-21
*/

pragma solidity ^0.8.19;

interface StreamsLookupCompatibleInterface {
    error StreamsLookup(
        string feedParamKey,
        string[] feeds,
        string timeParamKey,
        uint256 time,
        bytes extraData
    );

    /**
     * @notice any contract which wants to utilize FeedLookup feature needs to
     * implement this interface as well as the automation compatible interface.
     * @param values an array of bytes returned from Mercury endpoint.
     * @param extraData context data from feed lookup process.
     * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
     */
    function checkCallback(bytes[] memory values, bytes memory extraData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);
}

// File src/v0.8/automation/interfaces/ILogAutomation.sol

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
    function checkLog(Log calldata log, bytes memory checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

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

pragma solidity >=0.4.21 <0.9.0;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract StreamsLookupExamplev03 is
    ILogAutomation,
    StreamsLookupCompatibleInterface
{

    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDs";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "timestamp";

    address public FORWARDER_ADDRESS;

    event PerformingUpkeep(bytes blob1, bytes blob2);

    function checkLog(Log calldata log, bytes memory)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        string[] memory feedIds = new string[](2);
        feedIds[0] = "0x00023496426b520583ae20a66d80484e0fc18544866a5b0bfee15ec771963274";
        feedIds[1] ="0x0002f18a75a7750194a6476c9ab6d51276952471bd90404904211a9d47f34e64";
        revert StreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            feedIds,
            STRING_DATASTREAMS_QUERYLABEL,
            log.timestamp,
            ""
        );
    }

    function checkCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external override {
        //require(msg.sender == FORWARDER_ADDRESS, "Not permissioned");
        (bytes[] memory values, bytes memory extraData) = abi.decode(
            performData,
            (bytes[], bytes)
        );
        emit PerformingUpkeep(values[0],values[1]);
    }

    function setForwarderAddress(address forwarderAddress) public {
        FORWARDER_ADDRESS = forwarderAddress;
    }
}