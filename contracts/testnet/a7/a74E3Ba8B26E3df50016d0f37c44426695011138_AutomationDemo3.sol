/**
 *Submitted for verification at Arbiscan.io on 2023-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface StreamsLookupCompatibleInterface {
    error StreamsLookup(
        string feedParamKey,
        string[] feeds,
        string timeParamKey,
        uint256 time,
        bytes extraData
    );

    function checkCallback(bytes[] memory values, bytes memory extraData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData);
}

interface ILogAutomation {
    function checkLog(Log calldata log, bytes memory checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
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

interface IVerifierProxy {
    function verify(bytes memory signedReport)
        external
        payable
        returns (bytes memory verifierResponse);
}

interface IReportHandler {
    function handleReport(bytes calldata report) external;
}

interface IOrder{
    function executeOrder(uint256 id, uint256 price)external;
}

pragma solidity ^0.8.18;

contract AutomationDemo3 is ILogAutomation, StreamsLookupCompatibleInterface {
    struct BasicReport {
        // v0.3 Basic
        bytes32 feedId; // The feed ID the report has data for
        uint32 lowerTimestamp; // Lower timestamp for validity of report
        uint32 observationsTimestamp; // The time the median value was observed on
        uint192 nativeFee; // Base ETH/WETH fee to verify report
        uint192 linkFee; // Base LINK fee to verify report
        uint64 upperTimestamp; // Upper timestamp for validity of report
        int192 benchmark; // The median value agreed in an OCR round
    }

    struct Quote {
        address quoteAddress;
    }


    event ReportVerified(BasicReport indexed report);
    event PriceUpdate(int192 price);

    IVerifierProxy public immutable verifier;

    address public immutable FEE_ADDRESS;
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDs";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "timestamp";
    string[] public feedsHex = [
        "0x00023496426b520583ae20a66d80484e0fc18544866a5b0bfee15ec771963274"
    ];
    address public sourceAddress ;

    constructor(address _verifier, address _feeAddress, address _sourceAddress) {
        verifier = IVerifierProxy(_verifier); //0xea9B98Be000FBEA7f6e88D08ebe70EbaAD10224c
        FEE_ADDRESS = _feeAddress; // 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3 (WETH)
        sourceAddress = _sourceAddress;
    }

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

    function checkCallback(bytes[] calldata values, bytes calldata extraData)
        external
        pure
        returns (bool, bytes memory)
    {
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external override {
        (bytes[] memory signedReports, bytes memory extraData) = abi.decode(
            performData,
            (bytes[], bytes)
        );

        bytes memory report = signedReports[0];

        // Add quote to the report and retrieve data
        bytes memory bundledReport = _bundleReport(report);
        BasicReport memory unverifiedReport = _getReportData(report);

        // Verify the report
        bytes memory verifiedReportData = verifier.verify{
            value: unverifiedReport.nativeFee
        }(bundledReport);

        // Decode verified report data into BasicReport struct
        BasicReport memory verifiedReport = abi.decode(
            verifiedReportData,
            (BasicReport)
        );

        // Log price from report
        emit PriceUpdate(verifiedReport.benchmark);
    }


    /**
     * @dev This is a helper function that aggregates the signed report data into an encoded report bundle.
     *      The process of bundling a report involves the following steps: 
     *      (1) Decode the report input into the key components (the report context, the report data, and the signatures)
     *      (2) Encode a data quote which includes the fee address
     *      (3) Encodes the report bundle
     * @param report The signed report that needs to be bundled.
     * @return bundledReport The aggregated or bundled report ready for being verified.
     */

    function _bundleReport(bytes memory report)
        internal
        view
        returns (bytes memory)
    {
        Quote memory quote;
        quote.quoteAddress = FEE_ADDRESS;
        (
            bytes32[3] memory reportContext,
            bytes memory reportData,
            bytes32[] memory rs,
            bytes32[] memory ss,
            bytes32 raw
        ) = abi.decode(
                report,
                (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
            );
        bytes memory bundledReport = abi.encode(
            reportContext,
            reportData,
            rs,
            ss,
            raw,
            abi.encode(quote)
        );
        return bundledReport;
    }

     /**
     * @dev This function extracts the main report data from a signed report.
     *      The process involves the below steps:
     *      (1) It decodes the input signed report into its key attributes, 
     *          with a focus on "reportData" because that's where the essential feed data sits.
     *      (2) It then re-decodes the "reportData" from its raw bytes format into a more 
     *          usable "BasicReport" struct format.
     *      It's to note that, the decoded report data will include essential attributes of 
     *      a report such as feed ID, timestamps, and fees, and the feed value agreed upon in OCR round.
     *      NOTE: these reports should always be passed into the verifier contract
     * @param signedReport A signed report instance in bytes format.
     * @return report The decoded report data in the form of a BasicReport struct.
     */
    function _getReportData(bytes memory signedReport)
        internal
        pure
        returns (BasicReport memory)
    {
        (, bytes memory reportData, , , ) = abi.decode(
            signedReport,
            (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
        );

        BasicReport memory report = abi.decode(reportData, (BasicReport));
        return report;
    }

    fallback() external payable {}
}