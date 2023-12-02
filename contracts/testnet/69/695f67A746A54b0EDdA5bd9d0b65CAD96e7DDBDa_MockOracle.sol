// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @member index the index of the log in the block. 0 for the first log
 * @member timestamp the timestamp of the block containing the log
 * @member txHash the hash of the transaction containing the log
 * @member blockNumber the number of the block containing the log
 * @member blockHash the hash of the block containing the log
 * @member source the address of the contract that emitted the log
 * @member topics the indexed topics of the log
 * @member data the data of the log
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// solhint-disable-next-line max-line-length
import {StreamsLookupCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/StreamsLookupCompatibleInterface.sol";
import {ILogAutomation, Log} from "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";

abstract contract DataStreamConsumer is
    ILogAutomation,
    StreamsLookupCompatibleInterface
{
    struct BasicReport {
        // The feed ID the report has data for
        bytes32 feedId;
        // Earliest timestamp for which price is applicable
        uint32 validFromTimestamp;
        // Latest timestamp for which price is applicable
        uint32 observationsTimestamp;
        // Base cost to validate a transaction using the report, denominated in the chain’s native token (WETH/ETH)
        uint192 nativeFee;
        // Base cost to validate a transaction using the report, denominated in LINK
        uint192 linkFee;
        // Latest timestamp where the report can be verified on-chain
        uint32 expiresAt;
        // DON consensus median price, carried to 8 decimal places
        int192 price;
    }

    string[] internal feedIds;

    string public constant DATASTREAMS_FEEDLABEL = "feedIDs";
    string public constant DATASTREAMS_QUERYLABEL = "timestamp";

    // Find a complete list of IDs and verifiers at https://docs.chain.link/data-streams/stream-ids
    constructor(string memory _feedId) {
        feedIds.push(_feedId);
    }

    function checkLog(
        Log calldata log,
        bytes memory
    ) external view returns (bool, bytes memory) {
        revert StreamsLookup(
            DATASTREAMS_FEEDLABEL,
            feedIds,
            DATASTREAMS_QUERYLABEL,
            log.timestamp,
            log.data
        );
    }

    function checkCallback(
        bytes[] calldata values,
        bytes calldata extraData
    ) external pure returns (bool, bytes memory) {
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
 * Asset Struct is copy pasted from "@chainlink/contracts/src/v0.8/libraries/Common.sol"
 * But with increased version
 */

struct IAsset {
    address assetAddress;
    uint256 amount;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IFakeOracle {
    function addFakeRequest(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {IAsset} from "./IAsset.sol";

interface IFeeManager {
    function getFeeAndReward(
        address subscriber,
        bytes memory unverifiedReport,
        address quoteAddress
    ) external returns (IAsset memory, IAsset memory, uint256);

    function i_linkAddress() external view returns (address);

    function i_nativeAddress() external view returns (address);

    function i_rewardManager() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IOracle {
    function addRequest(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external returns (bool);

    function fallbackCall(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

enum FeedType {
    DataStream,
    PriceFeed
}

struct ForwardData {
    int256 price;
    FeedType feedType;
    bytes forwardArguments;
}

interface IOracleConsumerContract {
    function consume(ForwardData memory forwardData) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

interface IRequestsManager {
    enum RequestStatus {
        Init,
        Pending,
        Fulfilled
    }

    struct RequestStats {
        RequestStatus status;
        uint256 blockNumber;
    }

    function addRequest(bytes32 _id) external;

    function fulfillRequest(bytes32 _id) external;

    function getRequest(
        bytes32 _id
    ) external view returns (RequestStats memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

// solhint-disable-next-line no-empty-blocks
interface IVerifierFeeManager is IERC165 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IVerifierFeeManager} from "./IVerifierFeeManager.sol";

// import {IVerifierFeeManager} from "@chainlink/contracts/src/v0.8/llo-feeds/interfaces/IVerifierFeeManager.sol";

// Custom interfaces for IVerifierProxy and IFeeManager
interface IVerifierProxy {
    function verify(
        bytes calldata payload,
        bytes calldata parameterPayload
    ) external payable returns (bytes memory verifierResponse);

    function s_feeManager() external view returns (IVerifierFeeManager);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library RequestLib {
    function generateId(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external pure returns (bytes32) {
        return
            keccak256(
                abi.encode(callbackContract, callbackArgs, nonce, sender)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Oracle} from "src/Oracle.sol";
import {IFakeOracle} from "src/interfaces/IFakeOracle.sol";
import {IRequestsManager} from "src/interfaces/IRequestsManager.sol";

contract MockOracle is IFakeOracle, Oracle {
    event FakeAutomationTrigger(
        address callBackContract,
        bytes callBackArgs,
        uint256 nonce,
        address sender
    );

    // Find a complete list of IDs and verifiers at https://docs.chain.link/data-streams/stream-ids
    constructor(
        address _verifier,
        string memory _dataStreamfeedId,
        address _priceFeedId,
        uint256 _requestTimeout
    ) Oracle(_verifier, _dataStreamfeedId, _priceFeedId, _requestTimeout) {}

    function addFakeRequest(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external returns (bool) {
        (
            bytes32 id,
            IRequestsManager.RequestStats memory reqStats
        ) = getRequestProps(callbackContract, callbackArgs, nonce, sender);
        // prevent duplicated request execution
        if (reqStats.status == IRequestsManager.RequestStatus.Fulfilled) {
            revert DuplicatedRequestCreation(id);
        }
        requestManager.addRequest(id);
        emit FakeAutomationTrigger(
            callbackContract,
            callbackArgs,
            nonce,
            sender
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Log} from "@chainlink/contracts/src/v0.8/automation/interfaces/ILogAutomation.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IAsset} from "./interfaces/IAsset.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IOracleConsumerContract, ForwardData, FeedType} from "./interfaces/IOracleCallBackContract.sol";
import {IRequestsManager} from "./interfaces/IRequestsManager.sol";

import {RequestLib} from "./libs/RequestLib.sol";

import {DataStreamConsumer} from "./DataStreamConsumer.sol";
import {PriceFeedConsumer} from "./PriceFeedConsumer.sol";
import {RequestsManager} from "./RequestsManager.sol";

contract Oracle is IOracle, DataStreamConsumer, PriceFeedConsumer {
    error DuplicatedRequestCreation(bytes32 id);
    error InvalidRequestsExecution(bytes32 id);
    error FailedRequestsConsumption(bytes32 id);

    event AutomationTrigger(
        address callBackContract,
        bytes callBackArgs,
        uint256 nonce,
        address sender
    );

    IVerifierProxy public immutable verifier;
    RequestsManager public immutable requestManager;
    // blocks from request initialization
    uint256 public immutable requestTimeout;

    // Find a complete list of IDs and verifiers at https://docs.chain.link/data-streams/stream-ids
    constructor(
        address _verifier,
        string memory _dataStreamfeedId,
        address _priceFeedId,
        uint256 _requestTimeout
    ) DataStreamConsumer(_dataStreamfeedId) PriceFeedConsumer(_priceFeedId) {
        verifier = IVerifierProxy(_verifier);
        requestManager = new RequestsManager();
        requestTimeout = _requestTimeout;
    }

    function addRequest(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external returns (bool) {
        (
            bytes32 id,
            IRequestsManager.RequestStats memory reqStats
        ) = getRequestProps(callbackContract, callbackArgs, nonce, sender);
        // prevent duplicated request execution
        if (reqStats.status == IRequestsManager.RequestStatus.Pending) {
            revert DuplicatedRequestCreation(id);
        }
        requestManager.addRequest(id);
        emit AutomationTrigger(callbackContract, callbackArgs, nonce, sender);
        return true;
    }

    function performUpkeep(bytes calldata performData) external override {
        // Decode the performData bytes passed in by CL Automation.
        // This contains the data returned by your implementation in checkCallback().
        (bytes[] memory signedReports, bytes memory extraData) = abi.decode(
            performData,
            (bytes[], bytes)
        );

        bytes memory unverifiedReport = signedReports[0];

        (
            address callbackContract,
            bytes memory callbackArgs,
            uint256 nonce,
            address sender
        ) = abi.decode(extraData, (address, bytes, uint256, address));

        (
            bytes32 id,
            IRequestsManager.RequestStats memory reqStats
        ) = getRequestProps(callbackContract, callbackArgs, nonce, sender);

        // prevent duplicated request execution
        if (reqStats.status != IRequestsManager.RequestStatus.Pending) {
            revert InvalidRequestsExecution(id);
        }

        (, /* bytes32[3] reportContextData */ bytes memory reportData) = abi
            .decode(unverifiedReport, (bytes32[3], bytes));

        // Report verification fees
        IFeeManager feeManager = IFeeManager(address(verifier.s_feeManager()));

        address feeTokenAddress = feeManager.i_linkAddress();
        (IAsset memory fee, , ) = feeManager.getFeeAndReward(
            address(this),
            reportData,
            feeTokenAddress
        );

        // Approve rewardManager to spend this contract's balance in fees
        IERC20(feeTokenAddress).approve(
            address(feeManager.i_rewardManager()),
            fee.amount
        );

        // Verify the report
        bytes memory verifiedReportData = verifier.verify(
            unverifiedReport,
            abi.encode(feeTokenAddress)
        );

        // Decode verified report data into BasicReport struct
        BasicReport memory report = abi.decode(
            verifiedReportData,
            (BasicReport)
        );

        bool success = IOracleConsumerContract(callbackContract).consume(
            ForwardData({
                price: report.price,
                feedType: FeedType.DataStream,
                forwardArguments: callbackArgs
            })
        );

        if (!success) {
            revert FailedRequestsConsumption(id);
        }

        requestManager.fulfillRequest(id);
    }

    function fallbackCall(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) external returns (bool) {
        (
            bytes32 id,
            IRequestsManager.RequestStats memory reqStats
        ) = getRequestProps(callbackContract, callbackArgs, nonce, sender);

        if (
            reqStats.status != IRequestsManager.RequestStatus.Pending ||
            reqStats.blockNumber + requestTimeout < block.number
        ) {
            revert InvalidRequestsExecution(id);
        }

        int256 price = getLatestPrice();

        bool success = IOracleConsumerContract(callbackContract).consume(
            ForwardData({
                price: price,
                feedType: FeedType.PriceFeed,
                forwardArguments: callbackArgs
            })
        );

        if (!success) {
            revert FailedRequestsConsumption(id);
        }

        requestManager.fulfillRequest(id);

        return true;
    }

    // Utils

    function getRequestProps(
        address callbackContract,
        bytes memory callbackArgs,
        uint256 nonce,
        address sender
    ) public view returns (bytes32, RequestsManager.RequestStats memory) {
        bytes32 id = RequestLib.generateId(
            callbackContract,
            callbackArgs,
            nonce,
            sender
        );

        return (id, requestManager.getRequest(id));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title The PriceConsumerV3 contract
 * @notice Returns latest price from Chainlink Price Feeds
 */
abstract contract PriceFeedConsumer {
    AggregatorV3Interface internal immutable PRICE_FEED;

    constructor(address _priceFeed) {
        PRICE_FEED = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice Returns the latest price
     *
     * @return latest price
     */
    function getLatestPrice() internal view returns (int256) {
        (
            ,
            /* uint80 roundID */
            int256 price /* uint256 startedAt */ /* uint256 timeStamp */,
            ,
            ,

        ) = PRICE_FEED.latestRoundData(); /* uint80 answeredInRound */
        return price;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

import {IRequestsManager} from "./interfaces/IRequestsManager.sol";

contract RequestsManager is IRequestsManager {
    event RequestAdded(address indexed emitter, uint256 blockNumber);
    event RequestFulfilled(address indexed emitter, uint256 blockNumber);

    // _id => RequestStats
    mapping(bytes32 => RequestStats) private _pendingRequests;

    function addRequest(bytes32 _id) external {
        _pendingRequests[_id] = RequestStats({
            status: IRequestsManager.RequestStatus.Pending,
            blockNumber: block.number
        });
        emit RequestAdded(msg.sender, block.number);
    }

    function fulfillRequest(bytes32 _id) external {
        _pendingRequests[_id] = RequestStats({
            status: IRequestsManager.RequestStatus.Fulfilled,
            blockNumber: block.number
        });
        emit RequestFulfilled(msg.sender, block.number);
    }

    function getRequest(
        bytes32 _id
    ) external view returns (RequestStats memory) {
        return _pendingRequests[_id];
    }
}