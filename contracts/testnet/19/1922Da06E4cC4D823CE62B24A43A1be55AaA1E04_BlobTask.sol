/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

/**
 *Submitted for verification at Arbiscan.io on 2023-08-14
 */

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File src/v0.8/dev/automation/2_1/interfaces/FeedLookupCompatibleInterface.sol
pragma solidity ^0.8.0;

library EventUtils {
    struct EmitPositionDecreaseParams {
        bytes32 key;
        address account;
        address market;
        address collateralToken;
        bool isLong;
    }

    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }

    function initItems(AddressItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.AddressKeyValue[](size);
    }

    function initArrayItems(AddressItems memory items, uint256 size)
        internal
        pure
    {
        items.arrayItems = new EventUtils.AddressArrayKeyValue[](size);
    }

    function setItem(
        AddressItems memory items,
        uint256 index,
        string memory key,
        address value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        AddressItems memory items,
        uint256 index,
        string memory key,
        address[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(UintItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.UintKeyValue[](size);
    }

    function initArrayItems(UintItems memory items, uint256 size)
        internal
        pure
    {
        items.arrayItems = new EventUtils.UintArrayKeyValue[](size);
    }

    function setItem(
        UintItems memory items,
        uint256 index,
        string memory key,
        uint256 value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        UintItems memory items,
        uint256 index,
        string memory key,
        uint256[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(IntItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.IntKeyValue[](size);
    }

    function initArrayItems(IntItems memory items, uint256 size) internal pure {
        items.arrayItems = new EventUtils.IntArrayKeyValue[](size);
    }

    function setItem(
        IntItems memory items,
        uint256 index,
        string memory key,
        int256 value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        IntItems memory items,
        uint256 index,
        string memory key,
        int256[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(BoolItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.BoolKeyValue[](size);
    }

    function initArrayItems(BoolItems memory items, uint256 size)
        internal
        pure
    {
        items.arrayItems = new EventUtils.BoolArrayKeyValue[](size);
    }

    function setItem(
        BoolItems memory items,
        uint256 index,
        string memory key,
        bool value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        BoolItems memory items,
        uint256 index,
        string memory key,
        bool[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(Bytes32Items memory items, uint256 size) internal pure {
        items.items = new EventUtils.Bytes32KeyValue[](size);
    }

    function initArrayItems(Bytes32Items memory items, uint256 size)
        internal
        pure
    {
        items.arrayItems = new EventUtils.Bytes32ArrayKeyValue[](size);
    }

    function setItem(
        Bytes32Items memory items,
        uint256 index,
        string memory key,
        bytes32 value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        Bytes32Items memory items,
        uint256 index,
        string memory key,
        bytes32[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(BytesItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.BytesKeyValue[](size);
    }

    function initArrayItems(BytesItems memory items, uint256 size)
        internal
        pure
    {
        items.arrayItems = new EventUtils.BytesArrayKeyValue[](size);
    }

    function setItem(
        BytesItems memory items,
        uint256 index,
        string memory key,
        bytes memory value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        BytesItems memory items,
        uint256 index,
        string memory key,
        bytes[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }

    function initItems(StringItems memory items, uint256 size) internal pure {
        items.items = new EventUtils.StringKeyValue[](size);
    }

    function initArrayItems(StringItems memory items, uint256 size)
        internal
        pure
    {
        items.arrayItems = new EventUtils.StringArrayKeyValue[](size);
    }

    function setItem(
        StringItems memory items,
        uint256 index,
        string memory key,
        string memory value
    ) internal pure {
        items.items[index].key = key;
        items.items[index].value = value;
    }

    function setItem(
        StringItems memory items,
        uint256 index,
        string memory key,
        string[] memory value
    ) internal pure {
        items.arrayItems[index].key = key;
        items.arrayItems[index].value = value;
    }
}

pragma solidity ^0.8.19;

interface FeedLookupCompatibleInterface {
    error FeedLookup(
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

// File src/v0.8/dev/automation/2_1/interfaces/ILogAutomation.sol

pragma solidity ^0.8.0;

struct Log {
    uint256 index;
    uint256 txIndex;
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

// File src/v0.8/vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */

// File src/v0.8/dev/automation/tests/LogTriggeredFeedLookup.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IVerifierProxy {
    /**
     * @notice Verifies that the data encoded has been signed
     * correctly by routing to the correct verifier.
     * @param signedReport The encoded data to be verified.
     * @return verifierResponse The encoded response from the verifier.
     */
    function verify(bytes memory signedReport)
        external
        returns (bytes memory verifierResponse);
}

contract BlobTask is ILogAutomation, FeedLookupCompatibleInterface {
    event EventLog1(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        EventUtils.EventLogData eventData
    );

    // 0x468a25a7ba624ceea6e540ad6f49171b52495b648417ae91bca21676d8a24dc5
    event EventLog2(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        EventUtils.EventLogData eventData
    );
    event Update(bytes indexed clBlob);

    event PriceData(int192 indexed price);

    event Recieved();

    error LibGMXEventLogDecoder_IncorrectLogSelector(bytes32 logSelector);
    error MarketAutomation_IncorrectEventName(
        string eventName,
        string expectedEventName
    );
        error MarketAutomation_IncorrectOrderType(uint256 orderType);

    struct Report {
        // The feed ID the report has data for
        bytes32 feedId;
        // The time the median value was observed on
        uint32 observationsTimestamp;
        // The median value agreed in an OCR round
        int192 median;
        // The best bid value agreed in an OCR round
        int192 bid;
        // The best ask value agreed in an OCR round
        int192 ask;
        // The upper bound of the block range the median value was observed within
        uint64 blocknumberUpperBound;
        // The blockhash for the upper bound of block range (ensures correct blockchain)
        bytes32 upperBlockhash;
        // The lower bound of the block range the median value was observed within
        uint64 blocknumberLowerBound;
        // The timestamp of the current (upperbound) block number
        uint64 currentBlockTimestamp;
    }

    // CONSTANTS
    string public constant EXPECTED_LOG_EVENTNAME = "OrderCreated";
    // Market Swap = 0, Market Increase = 2, Market Decrease = 4
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_0 = 0;
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_2 = 2;
    uint256 public constant EXPECTED_LOG_EVENTDATA_ORDERTYPE_4 = 4;
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIdHex";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "blockNumber";

    uint256 public counter;

    string[] public feedsHex = [
        "0x4ce52cf28e49f4673198074968aeea280f13b5f897c687eb713bcfc1eeab89ba"
    ];


    function checkLog(Log calldata log, bytes memory)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (
            ,
            //msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        ) = decodeEventLog(log);

        if (
            keccak256(abi.encode(eventName)) !=
            keccak256(abi.encode(EXPECTED_LOG_EVENTNAME))
        ) {
            revert MarketAutomation_IncorrectEventName(
                eventName,
                EXPECTED_LOG_EVENTNAME
            );
        }

                // Decode the EventData struct to retrieve relevant data
        (bytes32 key, address market, uint256 orderType, address[] memory swapPath,,) = decodeEventData(eventData);

        if (
            orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_0 &&
            orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_2 &&
            orderType != EXPECTED_LOG_EVENTDATA_ORDERTYPE_4
        ) {
            revert MarketAutomation_IncorrectOrderType(orderType);
        }

        revert FeedLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            feedsHex,
            STRING_DATASTREAMS_QUERYLABEL,
            log.blockNumber,
            ""
        );
    }

    function decodeEventLog(Log memory log)
        internal
        pure
        returns (
            address msgSender,
            string memory eventName,
            EventUtils.EventLogData memory eventData
        )
    {
        // Ensure that the log is an EventLog1 or EventLog2 event
        if (
            log.topics[0] != EventLog1.selector &&
            log.topics[0] != EventLog2.selector
        ) {
            revert LibGMXEventLogDecoder_IncorrectLogSelector(log.topics[0]);
        }

        (msgSender, eventName, eventData) = abi.decode(
            log.data,
            (address, string, EventUtils.EventLogData)
        );
    }

    function performUpkeep(bytes calldata performData) external override {
        (bytes[] memory values, bytes memory extraData) = abi.decode(
            performData,
            (bytes[], bytes)
        );
        bytes memory report = values[0];
        emit Update(report);
        Report memory reportData = getReport(report);
        emit PriceData(reportData.median);

        emit Recieved();
    }

    function checkCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }

    function bytes32ToUint(bytes32 _uint) public pure returns (uint256) {
        return uint256(_uint);
    }

    function getReport(bytes memory signedReport)
        internal
        pure
        returns (Report memory)
    {
        (
            bytes32[3] memory reportContext,
            bytes memory reportData,
            bytes32[] memory rs,
            bytes32[] memory ss,
            bytes32 rawVs
        ) = abi.decode(
                signedReport,
                (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
            );

        Report memory report = abi.decode(reportData, (Report));
        return report;
    }

    function updateFeed(string calldata feedId) external {
        feedsHex[0] = feedId;
    }

        function decodeEventData(EventUtils.EventLogData memory eventData)
        internal
        pure
        returns (
            bytes32 key,
            address market,
            uint256 orderType,
            address[] memory swapPath,
            address[] memory longTokenSwapPath,
            address[] memory shortTokenSwapPath
        )
    {
        // Get the key from the eventData bytes32 items
        EventUtils.Bytes32KeyValue[] memory bytes32Items = eventData.bytes32Items.items;
        for (uint256 i = 0; i < bytes32Items.length; i++) {
            if (keccak256(abi.encode(bytes32Items[i].key)) == keccak256(abi.encode("key"))) {
                key = bytes32Items[i].value;
                break;
            }
        }

        // Extract the market from the event data address items
        EventUtils.AddressKeyValue[] memory addressItems = eventData.addressItems.items;
        for (uint256 i = 0; i < addressItems.length; i++) {
            if (keccak256(abi.encode(addressItems[i].key)) == keccak256(abi.encode("market"))) {
                market = addressItems[i].value;
                break;
            }
        }

        // Extract the orderType from the event data uint items
        EventUtils.UintKeyValue[] memory uintItems = eventData.uintItems.items;
        for (uint256 i = 0; i < uintItems.length; i++) {
            if (keccak256(abi.encode(uintItems[i].key)) == keccak256(abi.encode("orderType"))) {
                orderType = uintItems[i].value;
                break;
            }
        }

        // Extract the swapPath, longTokenSwapPath and shortTokenSwapPath from the event data address array items
        EventUtils.AddressArrayKeyValue[] memory addressArrayItems = eventData.addressItems.arrayItems;
        for (uint256 i = 0; i < addressArrayItems.length; i++) {
            if (keccak256(abi.encode(addressArrayItems[i].key)) == keccak256(abi.encode("swapPath"))) {
                swapPath = addressArrayItems[i].value;
            }
            if (keccak256(abi.encode(addressArrayItems[i].key)) == keccak256(abi.encode("longTokenSwapPath"))) {
                longTokenSwapPath = addressArrayItems[i].value;
            }
            if (keccak256(abi.encode(addressArrayItems[i].key)) == keccak256(abi.encode("shortTokenSwapPath"))) {
                shortTokenSwapPath = addressArrayItems[i].value;
            }
        }
    }
}