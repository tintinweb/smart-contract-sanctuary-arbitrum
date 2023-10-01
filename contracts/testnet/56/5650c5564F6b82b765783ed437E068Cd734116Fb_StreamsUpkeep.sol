// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/*
 * @title Common
 * @author Michael Fletcher
 * @notice Common functions and structs
 */
library Common {
  // @notice The asset struct to hold the address of an asset and amount
  struct Asset {
    address assetAddress;
    uint256 amount;
  }

  // @notice Struct to hold the address and its associated weight
  struct AddressAndWeight {
    address addr;
    uint64 weight;
  }

  /**
   * @notice Checks if an array of AddressAndWeight has duplicate addresses
   * @param recipients The array of AddressAndWeight to check
   * @return bool True if there are duplicates, false otherwise
   */
  function hasDuplicateAddresses(Common.AddressAndWeight[] memory recipients) internal pure returns (bool) {
    for (uint256 i = 0; i < recipients.length; ) {
      for (uint256 j = i + 1; j < recipients.length; ) {
        if (recipients[i].addr == recipients[j].addr) {
          return true;
        }
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../../libraries/Common.sol";
import {IVerifierFeeManager} from "../../interfaces/IVerifierFeeManager.sol";

interface IFeeManager is IERC165, IVerifierFeeManager {
  struct Quote {
    address quoteAddress;
  }

  /**
   * @notice Processes the fee for a report, billing the subscriber and paying the reward manager
   * @param payload report and quote data to process the fee for
   * @param subscriber address of the user to process fee for
   */
  function processFee(bytes calldata payload, address subscriber) external payable;

  /**
   * @notice Processes the fees for each report in the payload, billing the subscriber and paying the reward manager
   * @param payloads reports and quotes to process
   * @param subscriber address of the user to process fee for
   */
  function processFeeBulk(bytes[] calldata payloads, address subscriber) external payable;

  /**
   * @notice Calculate the applied fee and the reward from a report. If the sender is a subscriber, they will receive a discount.
   * @param subscriber address trying to verify
   * @param report report to calculate the fee for
   * @param quote any metadata required to fetch the fee
   * @return (fee, reward) fee and the reward data
   */
  function getFeeAndReward(
    address subscriber,
    bytes memory report,
    Quote memory quote
  ) external returns (Common.Asset memory, Common.Asset memory);

  /**
   * @notice Sets the fee recipients within the reward manager
   * @param configDigest digest of the configuration
   * @param rewardRecipientAndWeights the address and weights of all the recipients to receive rewards
   */
  function setFeeRecipients(
    bytes32 configDigest,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external;

  /**
   * @notice Sets the native surcharge
   * @param surcharge surcharge to be paid if paying in native
   */
  function setNativeSurcharge(uint64 surcharge) external;

  /**
   * @notice Adds a subscriber to the fee manager
   * @param subscriber address of the subscriber
   * @param feedId feed id to apply the discount to
   * @param token token to apply the discount to
   * @param discount discount to be applied to the fee
   */
  function updateSubscriberDiscount(address subscriber, bytes32 feedId, address token, uint64 discount) external;

  /**
   * @notice Withdraws any native or LINK rewards to the owner address
   * @param quantity quantity of tokens to withdraw, address(0) is native
   * @param quantity quantity to withdraw
   */
  function withdraw(address assetAddress, uint192 quantity) external;

  /**
   * @notice Returns the link balance of the fee manager
   * @return link balance of the fee manager
   */
  function linkAvailableForPayment() external returns (uint256);

  /**
   * @notice Admin function to pay the LINK deficit for a given config digest
   * @param configDigest the config digest to pay the deficit for
   */
  function payLinkDeficit(bytes32 configDigest) external;

  /**
   * @notice The structure to hold a fee and reward to verify a report
   * @param digest the digest linked to the fee and reward
   * @param fee the fee paid to verify the report
   * @param reward the reward paid upon verification
   */
  struct FeeAndReward {
    bytes32 configDigest;
    Common.Asset fee;
    Common.Asset reward;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../../libraries/Common.sol";

interface IRewardManager is IERC165 {
  /**
   * @notice Record the fee received for a particular pool
   * @param payments array of structs containing pool id and amount
   * @param payee the user the funds should be retrieved from
   */
  function onFeePaid(FeePayment[] calldata payments, address payee) external;

  /**
   * @notice Claims the rewards in a specific pool
   * @param poolIds array of poolIds to claim rewards for
   */
  function claimRewards(bytes32[] calldata poolIds) external;

  /**
   * @notice Set the RewardRecipients and weights for a specific pool. This should only be called once per pool Id. Else updateRewardRecipients should be used.
   * @param poolId poolId to set RewardRecipients and weights for
   * @param rewardRecipientAndWeights array of each RewardRecipient and associated weight
   */
  function setRewardRecipients(bytes32 poolId, Common.AddressAndWeight[] calldata rewardRecipientAndWeights) external;

  /**
   * @notice Updates a subset the reward recipients for a specific poolId. The collective weight of the recipients should add up to the recipients existing weights. Any recipients with a weight of 0 will be removed.
   * @param poolId the poolId to update
   * @param newRewardRecipients array of new reward recipients
   */
  function updateRewardRecipients(bytes32 poolId, Common.AddressAndWeight[] calldata newRewardRecipients) external;

  /**
   * @notice Pays all the recipients for each of the pool ids
   * @param poolId the pool id to pay recipients for
   * @param recipients array of recipients to pay within the pool
   */
  function payRecipients(bytes32 poolId, address[] calldata recipients) external;

  /**
   * @notice Sets the fee manager. This needs to be done post construction to prevent a circular dependency.
   * @param newFeeManager address of the new verifier proxy
   */
  function setFeeManager(address newFeeManager) external;

  /**
   * @notice Gets a list of pool ids which have reward for a specific recipient.
   * @param recipient address of the recipient to get pool ids for
   */
  function getAvailableRewardPoolIds(address recipient) external view returns (bytes32[] memory);

  /**
   * @notice The structure to hold a fee payment notice
   * @param poolId the poolId receiving the payment
   * @param amount the amount being paid
   */
  struct FeePayment {
    bytes32 poolId;
    uint192 amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../libraries/Common.sol";

interface IVerifierFeeManager is IERC165 {
  /**
   * @notice Handles fees for a report from the subscriber and manages rewards
   * @param payload report and quote to process the fee for
   * @param subscriber address of the fee will be applied
   */
  function processFee(bytes calldata payload, address subscriber) external payable;

  /**
   * @notice Processes the fees for each report in the payload, billing the subscriber and paying the reward manager
   * @param payloads reports and quotes to process
   * @param subscriber address of the user to process fee for
   */
  function processFeeBulk(bytes[] calldata payloads, address subscriber) external payable;

  /**
   * @notice Sets the fee recipients according to the fee manager
   * @param configDigest digest of the configuration
   * @param rewardRecipientAndWeights the address and weights of all the recipients to receive rewards
   */
  function setFeeRecipients(
    bytes32 configDigest,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Common} from "../../libraries/Common.sol";
import {AccessControllerInterface} from "../../interfaces/AccessControllerInterface.sol";
import {IVerifierFeeManager} from "./IVerifierFeeManager.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payload The encoded data to be verified, including the signed
   * report and any metadata for billing.
   * @return verifierResponse The encoded report from the verifier.
   */
  function verify(bytes calldata payload) external payable returns (bytes memory verifierResponse);

  /**
   * @notice Bulk verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payloads The encoded payloads to be verified, including the signed
   * report and any metadata for billing.
   * @return verifiedReports The encoded reports from the verifier.
   */
  function verifyBulk(bytes[] calldata payloads) external payable returns (bytes[] memory verifiedReports);

  /**
   * @notice Sets the verifier address initially, allowing `setVerifier` to be set by this Verifier in the future
   * @param verifierAddress The address of the verifier contract to initialize
   */
  function initializeVerifier(address verifierAddress) external;

  /**
   * @notice Sets a new verifier for a config digest
   * @param currentConfigDigest The current config digest
   * @param newConfigDigest The config digest to set
   * @param addressesAndWeights The addresses and weights of reward recipients
   * reports for a given config digest.
   */
  function setVerifier(
    bytes32 currentConfigDigest,
    bytes32 newConfigDigest,
    Common.AddressAndWeight[] memory addressesAndWeights
  ) external;

  /**
   * @notice Removes a verifier for a given config digest
   * @param configDigest The config digest of the verifier to remove
   */
  function unsetVerifier(bytes32 configDigest) external;

  /**
   * @notice Retrieves the verifier address that verifies reports
   * for a config digest.
   * @param configDigest The config digest to query for
   * @return verifierAddress The address of the verifier contract that verifies
   * reports for a given config digest.
   */
  function getVerifier(bytes32 configDigest) external view returns (address verifierAddress);

  /**
   * @notice Called by the admin to set an access controller contract
   * @param accessController The new access controller to set
   */
  function setAccessController(AccessControllerInterface accessController) external;

  /**
   * @notice Updates the fee manager
   * @param feeManager The new fee manager
   */
  function setFeeManager(IVerifierFeeManager feeManager) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IVerifierProxy} from "@chainlink/contracts/src/v0.8/llo-feeds/interfaces/IVerifierProxy.sol";
import {IFeeManager} from "@chainlink/contracts/src/v0.8/llo-feeds/dev/interfaces/IFeeManager.sol";
import {IRewardManager} from "@chainlink/contracts/src/v0.8/llo-feeds/dev/interfaces/IRewardManager.sol";
import {Common as ChainlinkCommon} from "@chainlink/contracts/src/v0.8/libraries/Common.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

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
    function checkCallback(
        bytes[] memory values,
        bytes memory extraData
    ) external view returns (bool upkeepNeeded, bytes memory performData);
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

contract StreamsUpkeep is
    ILogAutomation,
    StreamsLookupCompatibleInterface
    //TODO: IFeeManager
{
    //TODO: always ensure you use the latest report struct (schema) which can be found here {placeholder}
    struct BasicReport {
        bytes32 feedId; // The feed ID the report has data for
        uint32 lowerTimestamp; // Lower timestamp for validity of report
        uint32 observationsTimestamp; // The time the median value was observed on
        uint192 nativeFee; // Base ETH/WETH fee to verify report
        uint192 linkFee; // Base LINK fee to verify report
        uint64 upperTimestamp; // Upper timestamp for validity of report
        int192 benchmark; // The median value agreed in an OCR round
    }

    struct PremiumReport {
        bytes32 feedId; // The feed ID the report has data for
        uint32 lowerTimestamp; // Lower timestamp for validity of report
        uint32 observationsTimestamp; // The time the median value was observed on
        uint192 nativeFee; // Base ETH/WETH fee to verify report
        uint192 linkFee; // Base LINK fee to verify report
        uint64 upperTimestamp; // Upper timestamp for validity of report
        int192 benchmark; // The median value agreed in an OCR round
        int192 bid; // The best bid value agreed in an OCR round
        int192 ask; // The best ask value agreed in an OCR round
    }

    struct BlockPremiumReport {
        bytes32 feedId; // The feed ID the report has data for
        uint32 observationsTimestamp; // The time the median value was observed on
        int192 benchmark; // The median value agreed in an OCR round
        int192 bid; // The best bid value agreed in an OCR round
        int192 ask; // The best ask value agreed in an OCR round
        uint upperBlocknumber;
        bytes32 upperBlockhash;
        uint lowerBlocknumber;
        uint64 upperBlockTimestamp; // Upper timestamp for validity of report
    }

    address public feeToken;
    // Chain Config
    // bool public s_arbitrumChain; // Configures the contract to handle chain-specific logic
    // Data Streams Config
    IVerifierProxy public s_verifierProxy; // Data Streams contract that provides the verification interface
    address public s_feeManagerAddress;
    address public s_rewardManagerAddress;
    address public s_linkTokenAddress;
    bytes public s_lookupURL; // Must be accessible to client (ex. 'https://<mercury host>/')
    // Report Schema Config
    bytes32 private constant REPORT_VERSION_MASK =
        0xffff000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant REPORT_V1 =
        0x0001000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant REPORT_V2 =
        0x0002000000000000000000000000000000000000000000000000000000000000;
    bytes32 private constant REPORT_V3 =
        0x0003000000000000000000000000000000000000000000000000000000000000;
    // Automation Config
    address public FORWARDER_ADDRESS;
    string public constant STRING_DATASTREAMS_FEEDLABEL = "feedIDs";
    string public constant STRING_DATASTREAMS_QUERYLABEL = "timestamp";

    event PerformingUpkeep();

    constructor(
        address verifierProxyAddress,
        address feeManagerAddress,
        address rewardManagerAddress,
        address linkTokenAddress
    ) {
        s_verifierProxy = IVerifierProxy(verifierProxyAddress);
        s_feeManagerAddress = feeManagerAddress;
        s_rewardManagerAddress = rewardManagerAddress;
        s_linkTokenAddress = linkTokenAddress;
    }

    function checkLog(
        Log calldata log,
        bytes memory
    ) external override returns (bool upkeepNeeded, bytes memory performData) {
        string[] memory feedIds = new string[](1);
        feedIds[
            0
        ] = "0x00023496426b520583ae20a66d80484e0fc18544866a5b0bfee15ec771963274";
        revert StreamsLookup(
            STRING_DATASTREAMS_FEEDLABEL,
            feedIds,
            STRING_DATASTREAMS_QUERYLABEL,
            log.timestamp,
            ""
        );
    }

    function checkCallback(
        bytes[] calldata values,
        bytes calldata extraData
    ) external pure returns (bool, bytes memory) {
        return (true, abi.encode(values, extraData));
    }

    function performUpkeep(bytes calldata performData) external override {
        IFeeManager feeManager = IFeeManager(s_feeManagerAddress);
        IRewardManager rewardManager = IRewardManager(s_rewardManagerAddress);
        address linkAddress = s_linkTokenAddress;

        IFeeManager.Quote memory quote;
        quote.quoteAddress = linkAddress;

        require(msg.sender == FORWARDER_ADDRESS, "Not permissioned");
        (bytes[] memory chainlinkReports, bytes memory extraData) = abi.decode(
            performData,
            (bytes[], bytes)
        );

        // Fee calculation
        uint256 totalFee = 0;
        uint256 msgValue = 0;
        for (uint8 i = 0; i < chainlinkReports.length; i++) {
            bytes memory chainlinkReport = chainlinkReports[i];
            (, bytes memory reportData) = abi.decode(
                chainlinkReport,
                (bytes32[3], bytes)
            );
            bytes memory reportDataForFeeAndReward = chainlinkReports[i];

            (ChainlinkCommon.Asset memory fee, ) = IFeeManager(feeManager)
                .getFeeAndReward(msg.sender, reportDataForFeeAndReward, quote);
            totalFee += fee.amount;
        }
        IERC20(linkAddress).approve(address(rewardManager), totalFee);

        // Pack reports with desired quote address
        bytes[] memory reportDataList = new bytes[](chainlinkReports.length);
        for (uint8 i = 0; i < chainlinkReports.length; i++) {
            (
                bytes32[3] memory reportContext,
                bytes memory report,
                bytes32[] memory rs,
                bytes32[] memory ss,
                bytes32 raw
            ) = abi.decode(
                    chainlinkReports[i],
                    (bytes32[3], bytes, bytes32[], bytes32[], bytes32)
                );
            reportDataList[i] = abi.encode(reportContext, report, rs, ss, raw);
        }

        // Report verification
        if (chainlinkReports.length == 1) {
            IVerifierProxy(s_verifierProxy).verify{value: msgValue}(
                reportDataList[0]
            );
        } else {
            IVerifierProxy(s_verifierProxy).verifyBulk{value: msgValue}(
                reportDataList
            );
        }

        // Commitment validations

        int8 reportSchema = _getReportSchema(reportDataList[0]);
        if (reportSchema == 1) {
            BlockPremiumReport memory report = abi.decode(
                reportDataList[0],
                (BlockPremiumReport)
            );
            /*
                    report.feedId,
                    report.observationsTimestamp,
                    report.benchmark,
                    report.bid,
                    report.ask,
                    report.upperBlocknumber,
                    report.upperBlockhash,
                    report.lowerBlocknumber,
                    report.upperBlockTimestamp
                */
        } else if (reportSchema == 2) {
            BasicReport memory report = abi.decode(
                reportDataList[0],
                (BasicReport)
            );
            /*
                    report.feedId,
                    report.lowerTimestamp,
                    report.observationsTimestamp,
                    report.nativeFee,
                    report.linkFee,
                    report.upperTimestamp,
                    report.benchmark
                */
        } else {
            // reportSchema == ReportSchema.V3
            PremiumReport memory report = abi.decode(
                reportDataList[0],
                (PremiumReport)
            );
            /*
                    report.feedId,
                    report.lowerTimestamp,
                    report.observationsTimestamp,
                    report.nativeFee,
                    report.linkFee,
                    report.upperTimestamp,
                    report.benchmark,
                    report.bid,
                    report.ask
                */
        }

        emit PerformingUpkeep();
    }

    function setForwarderAddress(address forwarderAddress) public {
        FORWARDER_ADDRESS = forwarderAddress;
    }

    function _getReportSchema(
        bytes memory reportData
    ) private pure returns (int8 reportSchema) {
        bytes32 schemaPrefix = REPORT_VERSION_MASK & bytes32(reportData);
        if (schemaPrefix == REPORT_V2) {
            return 2;
        } else if (schemaPrefix == REPORT_V3) {
            return 3;
        } else {
            return 1;
        }
    }
}