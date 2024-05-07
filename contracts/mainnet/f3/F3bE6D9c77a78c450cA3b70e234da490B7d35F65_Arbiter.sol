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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ConfirmedOwner} from "../shared/access/ConfirmedOwner.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC165.sol";
import {Common} from "./libraries/Common.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IWERC20} from "../shared/interfaces/IWERC20.sol";
import {IERC20} from "../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC20.sol";
import {Math} from "../vendor/openzeppelin-solidity/v4.8.3/contracts/utils/math/Math.sol";
import {SafeERC20} from "../vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVerifierFeeManager} from "./interfaces/IVerifierFeeManager.sol";

/**
 * @title FeeManager
 * @author Michael Fletcher
 * @author Austin Born
 * @notice This contract is used for the handling of fees required for users verifying reports.
 */
contract FeeManager is IFeeManager, ConfirmedOwner, TypeAndVersionInterface {
  using SafeERC20 for IERC20;

  /// @notice list of subscribers and their discounts subscriberDiscounts[subscriber][feedId][token]
  mapping(address => mapping(bytes32 => mapping(address => uint256))) public s_subscriberDiscounts;

  /// @notice keep track of any subsidised link that is owed to the reward manager.
  mapping(bytes32 => uint256) public s_linkDeficit;

  /// @notice the total discount that can be applied to a fee, 1e18 = 100% discount
  uint64 private constant PERCENTAGE_SCALAR = 1e18;

  /// @notice the LINK token address
  address public immutable i_linkAddress;

  /// @notice the native token address
  address public immutable i_nativeAddress;

  /// @notice the proxy address
  address public immutable i_proxyAddress;

  /// @notice the reward manager address
  IRewardManager public immutable i_rewardManager;

  // @notice the mask to apply to get the report version
  bytes32 private constant REPORT_VERSION_MASK = 0xffff000000000000000000000000000000000000000000000000000000000000;

  // @notice the different report versions
  bytes32 private constant REPORT_V1 = 0x0001000000000000000000000000000000000000000000000000000000000000;

  /// @notice the surcharge fee to be paid if paying in native
  uint256 public s_nativeSurcharge;

  /// @notice the error thrown if the discount or surcharge is invalid
  error InvalidSurcharge();

  /// @notice the error thrown if the discount is invalid
  error InvalidDiscount();

  /// @notice the error thrown if the address is invalid
  error InvalidAddress();

  /// @notice thrown if msg.value is supplied with a bad quote
  error InvalidDeposit();

  /// @notice thrown if a report has expired
  error ExpiredReport();

  /// @notice thrown if a report has no quote
  error InvalidQuote();

  // @notice thrown when the caller is not authorized
  error Unauthorized();

  // @notice thrown when trying to clear a zero deficit
  error ZeroDeficit();

  /// @notice thrown when trying to pay an address that cannot except funds
  error InvalidReceivingAddress();

  /// @notice Emitted whenever a subscriber's discount is updated
  /// @param subscriber address of the subscriber to update discounts for
  /// @param feedId Feed ID for the discount
  /// @param token Token address for the discount
  /// @param discount Discount to apply, in relation to the PERCENTAGE_SCALAR
  event SubscriberDiscountUpdated(address indexed subscriber, bytes32 indexed feedId, address token, uint64 discount);

  /// @notice Emitted when updating the native surcharge
  /// @param newSurcharge Surcharge amount to apply relative to PERCENTAGE_SCALAR
  event NativeSurchargeUpdated(uint64 newSurcharge);

  /// @notice Emits when this contract does not have enough LINK to send to the reward manager when paying in native
  /// @param rewards Config digest and link fees which could not be subsidised
  event InsufficientLink(IRewardManager.FeePayment[] rewards);

  /// @notice Emitted when funds are withdrawn
  /// @param adminAddress Address of the admin
  /// @param recipient Address of the recipient
  /// @param assetAddress Address of the asset withdrawn
  /// @param quantity Amount of the asset withdrawn
  event Withdraw(address adminAddress, address recipient, address assetAddress, uint192 quantity);

  /// @notice Emits when a deficit has been cleared for a particular config digest
  /// @param configDigest Config digest of the deficit cleared
  /// @param linkQuantity Amount of LINK required to pay the deficit
  event LinkDeficitCleared(bytes32 indexed configDigest, uint256 linkQuantity);

  /// @notice Emits when a fee has been processed
  /// @param configDigest Config digest of the fee processed
  /// @param subscriber Address of the subscriber who paid the fee
  /// @param fee Fee paid
  /// @param reward Reward paid
  /// @param appliedDiscount Discount applied to the fee
  event DiscountApplied(
    bytes32 indexed configDigest,
    address indexed subscriber,
    Common.Asset fee,
    Common.Asset reward,
    uint256 appliedDiscount
  );

  /**
   * @notice Construct the FeeManager contract
   * @param _linkAddress The address of the LINK token
   * @param _nativeAddress The address of the wrapped ERC-20 version of the native token (represents fee in native or wrapped)
   * @param _proxyAddress The address of the proxy contract
   * @param _rewardManagerAddress The address of the reward manager contract
   */
  constructor(
    address _linkAddress,
    address _nativeAddress,
    address _proxyAddress,
    address _rewardManagerAddress
  ) ConfirmedOwner(msg.sender) {
    if (
      _linkAddress == address(0) ||
      _nativeAddress == address(0) ||
      _proxyAddress == address(0) ||
      _rewardManagerAddress == address(0)
    ) revert InvalidAddress();

    i_linkAddress = _linkAddress;
    i_nativeAddress = _nativeAddress;
    i_proxyAddress = _proxyAddress;
    i_rewardManager = IRewardManager(_rewardManagerAddress);

    IERC20(i_linkAddress).approve(address(i_rewardManager), type(uint256).max);
  }

  modifier onlyOwnerOrProxy() {
    if (msg.sender != i_proxyAddress && msg.sender != owner()) revert Unauthorized();
    _;
  }

  modifier onlyProxy() {
    if (msg.sender != i_proxyAddress) revert Unauthorized();
    _;
  }

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "FeeManager 2.0.0";
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == this.processFee.selector || interfaceId == this.processFeeBulk.selector;
  }

  /// @inheritdoc IVerifierFeeManager
  function processFee(
    bytes calldata payload,
    bytes calldata parameterPayload,
    address subscriber
  ) external payable override onlyProxy {
    (Common.Asset memory fee, Common.Asset memory reward, uint256 appliedDiscount) = _processFee(
      payload,
      parameterPayload,
      subscriber
    );

    if (fee.amount == 0) {
      _tryReturnChange(subscriber, msg.value);
      return;
    }

    IFeeManager.FeeAndReward[] memory feeAndReward = new IFeeManager.FeeAndReward[](1);
    feeAndReward[0] = IFeeManager.FeeAndReward(bytes32(payload), fee, reward, appliedDiscount);

    if (fee.assetAddress == i_linkAddress) {
      _handleFeesAndRewards(subscriber, feeAndReward, 1, 0);
    } else {
      _handleFeesAndRewards(subscriber, feeAndReward, 0, 1);
    }
  }

  /// @inheritdoc IVerifierFeeManager
  function processFeeBulk(
    bytes[] calldata payloads,
    bytes calldata parameterPayload,
    address subscriber
  ) external payable override onlyProxy {
    FeeAndReward[] memory feesAndRewards = new IFeeManager.FeeAndReward[](payloads.length);

    //keep track of the number of fees to prevent over initialising the FeePayment array within _convertToLinkAndNativeFees
    uint256 numberOfLinkFees;
    uint256 numberOfNativeFees;

    uint256 feesAndRewardsIndex;
    for (uint256 i; i < payloads.length; ++i) {
      (Common.Asset memory fee, Common.Asset memory reward, uint256 appliedDiscount) = _processFee(
        payloads[i],
        parameterPayload,
        subscriber
      );

      if (fee.amount != 0) {
        feesAndRewards[feesAndRewardsIndex++] = IFeeManager.FeeAndReward(
          bytes32(payloads[i]),
          fee,
          reward,
          appliedDiscount
        );

        unchecked {
          //keep track of some tallys to make downstream calculations more efficient
          if (fee.assetAddress == i_linkAddress) {
            ++numberOfLinkFees;
          } else {
            ++numberOfNativeFees;
          }
        }
      }
    }

    if (numberOfLinkFees != 0 || numberOfNativeFees != 0) {
      _handleFeesAndRewards(subscriber, feesAndRewards, numberOfLinkFees, numberOfNativeFees);
    } else {
      _tryReturnChange(subscriber, msg.value);
    }
  }

  /// @inheritdoc IFeeManager
  function getFeeAndReward(
    address subscriber,
    bytes memory report,
    address quoteAddress
  ) public view returns (Common.Asset memory, Common.Asset memory, uint256) {
    Common.Asset memory fee;
    Common.Asset memory reward;

    //get the feedId from the report
    bytes32 feedId = bytes32(report);

    //the report needs to be a support version
    bytes32 reportVersion = _getReportVersion(feedId);

    //version 1 of the reports don't require quotes, so the fee will be 0
    if (reportVersion == REPORT_V1) {
      fee.assetAddress = i_nativeAddress;
      reward.assetAddress = i_linkAddress;
      return (fee, reward, 0);
    }

    //verify the quote payload is a supported token
    if (quoteAddress != i_nativeAddress && quoteAddress != i_linkAddress) {
      revert InvalidQuote();
    }

    //decode the report depending on the version
    uint256 linkQuantity;
    uint256 nativeQuantity;
    uint256 expiresAt;
    (, , , nativeQuantity, linkQuantity, expiresAt) = abi.decode(
      report,
      (bytes32, uint32, uint32, uint192, uint192, uint32)
    );

    //read the timestamp bytes from the report data and verify it has not expired
    if (expiresAt < block.timestamp) {
      revert ExpiredReport();
    }

    //get the discount being applied
    uint256 discount = s_subscriberDiscounts[subscriber][feedId][quoteAddress];

    //the reward is always set in LINK
    reward.assetAddress = i_linkAddress;
    reward.amount = Math.ceilDiv(linkQuantity * (PERCENTAGE_SCALAR - discount), PERCENTAGE_SCALAR);

    //calculate either the LINK fee or native fee if it's within the report
    if (quoteAddress == i_linkAddress) {
      fee.assetAddress = i_linkAddress;
      fee.amount = reward.amount;
    } else {
      uint256 surchargedFee = Math.ceilDiv(nativeQuantity * (PERCENTAGE_SCALAR + s_nativeSurcharge), PERCENTAGE_SCALAR);

      fee.assetAddress = i_nativeAddress;
      fee.amount = Math.ceilDiv(surchargedFee * (PERCENTAGE_SCALAR - discount), PERCENTAGE_SCALAR);
    }

    //return the fee
    return (fee, reward, discount);
  }

  /// @inheritdoc IVerifierFeeManager
  function setFeeRecipients(
    bytes32 configDigest,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external onlyOwnerOrProxy {
    i_rewardManager.setRewardRecipients(configDigest, rewardRecipientAndWeights);
  }

  /// @inheritdoc IFeeManager
  function setNativeSurcharge(uint64 surcharge) external onlyOwner {
    if (surcharge > PERCENTAGE_SCALAR) revert InvalidSurcharge();

    s_nativeSurcharge = surcharge;

    emit NativeSurchargeUpdated(surcharge);
  }

  /// @inheritdoc IFeeManager
  function updateSubscriberDiscount(
    address subscriber,
    bytes32 feedId,
    address token,
    uint64 discount
  ) external onlyOwner {
    //make sure the discount is not greater than the total discount that can be applied
    if (discount > PERCENTAGE_SCALAR) revert InvalidDiscount();
    //make sure the token is either LINK or native
    if (token != i_linkAddress && token != i_nativeAddress) revert InvalidAddress();

    s_subscriberDiscounts[subscriber][feedId][token] = discount;

    emit SubscriberDiscountUpdated(subscriber, feedId, token, discount);
  }

  /// @inheritdoc IFeeManager
  function withdraw(address assetAddress, address recipient, uint192 quantity) external onlyOwner {
    //address 0 is used to withdraw native in the context of withdrawing
    if (assetAddress == address(0)) {
      (bool success, ) = payable(recipient).call{value: quantity}("");

      if (!success) revert InvalidReceivingAddress();
      return;
    }

    //withdraw the requested asset
    IERC20(assetAddress).safeTransfer(recipient, quantity);

    //emit event when funds are withdrawn
    emit Withdraw(msg.sender, recipient, assetAddress, uint192(quantity));
  }

  /// @inheritdoc IFeeManager
  function linkAvailableForPayment() external view returns (uint256) {
    //return the amount of LINK this contact has available to pay rewards
    return IERC20(i_linkAddress).balanceOf(address(this));
  }

  /**
   * @notice Gets the current version of the report that is encoded as the last two bytes of the feed
   * @param feedId feed id to get the report version for
   */
  function _getReportVersion(bytes32 feedId) internal pure returns (bytes32) {
    return REPORT_VERSION_MASK & feedId;
  }

  function _processFee(
    bytes calldata payload,
    bytes calldata parameterPayload,
    address subscriber
  ) internal view returns (Common.Asset memory, Common.Asset memory, uint256) {
    if (subscriber == address(this)) revert InvalidAddress();

    //decode the report from the payload
    (, bytes memory report) = abi.decode(payload, (bytes32[3], bytes));

    //get the feedId from the report
    bytes32 feedId = bytes32(report);

    //v1 doesn't need a quote payload, so skip the decoding
    address quote;
    if (_getReportVersion(feedId) != REPORT_V1) {
      //decode the quote from the bytes
      (quote) = abi.decode(parameterPayload, (address));
    }

    //decode the fee, it will always be native or LINK
    return getFeeAndReward(subscriber, report, quote);
  }

  function _handleFeesAndRewards(
    address subscriber,
    FeeAndReward[] memory feesAndRewards,
    uint256 numberOfLinkFees,
    uint256 numberOfNativeFees
  ) internal {
    IRewardManager.FeePayment[] memory linkRewards = new IRewardManager.FeePayment[](numberOfLinkFees);
    IRewardManager.FeePayment[] memory nativeFeeLinkRewards = new IRewardManager.FeePayment[](numberOfNativeFees);

    uint256 totalNativeFee;
    uint256 totalNativeFeeLinkValue;

    uint256 linkRewardsIndex;
    uint256 nativeFeeLinkRewardsIndex;

    uint256 totalNumberOfFees = numberOfLinkFees + numberOfNativeFees;
    for (uint256 i; i < totalNumberOfFees; ++i) {
      if (feesAndRewards[i].fee.assetAddress == i_linkAddress) {
        linkRewards[linkRewardsIndex++] = IRewardManager.FeePayment(
          feesAndRewards[i].configDigest,
          uint192(feesAndRewards[i].reward.amount)
        );
      } else {
        nativeFeeLinkRewards[nativeFeeLinkRewardsIndex++] = IRewardManager.FeePayment(
          feesAndRewards[i].configDigest,
          uint192(feesAndRewards[i].reward.amount)
        );
        totalNativeFee += feesAndRewards[i].fee.amount;
        totalNativeFeeLinkValue += feesAndRewards[i].reward.amount;
      }

      if (feesAndRewards[i].appliedDiscount != 0) {
        emit DiscountApplied(
          feesAndRewards[i].configDigest,
          subscriber,
          feesAndRewards[i].fee,
          feesAndRewards[i].reward,
          feesAndRewards[i].appliedDiscount
        );
      }
    }

    //keep track of change in case of any over payment
    uint256 change;

    if (msg.value != 0) {
      //there must be enough to cover the fee
      if (totalNativeFee > msg.value) revert InvalidDeposit();

      //wrap the amount required to pay the fee & approve as the subscriber paid in wrapped native
      IWERC20(i_nativeAddress).deposit{value: totalNativeFee}();

      unchecked {
        //msg.value is always >= to fee.amount
        change = msg.value - totalNativeFee;
      }
    } else {
      if (totalNativeFee != 0) {
        //subscriber has paid in wrapped native, so transfer the native to this contract
        IERC20(i_nativeAddress).safeTransferFrom(subscriber, address(this), totalNativeFee);
      }
    }

    if (linkRewards.length != 0) {
      i_rewardManager.onFeePaid(linkRewards, subscriber);
    }

    if (nativeFeeLinkRewards.length != 0) {
      //distribute subsidised fees paid in Native
      if (totalNativeFeeLinkValue > IERC20(i_linkAddress).balanceOf(address(this))) {
        // If not enough LINK on this contract to forward for rewards, tally the deficit to be paid by out-of-band LINK
        for (uint256 i; i < nativeFeeLinkRewards.length; ++i) {
          unchecked {
            //we have previously tallied the fees, any overflows would have already reverted
            s_linkDeficit[nativeFeeLinkRewards[i].poolId] += nativeFeeLinkRewards[i].amount;
          }
        }

        emit InsufficientLink(nativeFeeLinkRewards);
      } else {
        //distribute the fees
        i_rewardManager.onFeePaid(nativeFeeLinkRewards, address(this));
      }
    }

    // a refund may be needed if the payee has paid in excess of the fee
    _tryReturnChange(subscriber, change);
  }

  function _tryReturnChange(address subscriber, uint256 quantity) internal {
    if (quantity != 0) {
      payable(subscriber).transfer(quantity);
    }
  }

  /// @inheritdoc IFeeManager
  function payLinkDeficit(bytes32 configDigest) external onlyOwner {
    uint256 deficit = s_linkDeficit[configDigest];

    if (deficit == 0) revert ZeroDeficit();

    delete s_linkDeficit[configDigest];

    IRewardManager.FeePayment[] memory deficitFeePayment = new IRewardManager.FeePayment[](1);

    deficitFeePayment[0] = IRewardManager.FeePayment(configDigest, uint192(deficit));

    i_rewardManager.onFeePaid(deficitFeePayment, address(this));

    emit LinkDeficitCleared(configDigest, deficit);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC165.sol";
import {Common} from "../libraries/Common.sol";
import {IVerifierFeeManager} from "./IVerifierFeeManager.sol";

interface IFeeManager is IERC165, IVerifierFeeManager {
  /**
   * @notice Calculate the applied fee and the reward from a report. If the sender is a subscriber, they will receive a discount.
   * @param subscriber address trying to verify
   * @param report report to calculate the fee for
   * @param quoteAddress address of the quote payment token
   * @return (fee, reward, totalDiscount) fee and the reward data with the discount applied
   */
  function getFeeAndReward(
    address subscriber,
    bytes memory report,
    address quoteAddress
  ) external returns (Common.Asset memory, Common.Asset memory, uint256);

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
   * @param assetAddress address of the asset to withdraw
   * @param recipientAddress address to withdraw to
   * @param quantity quantity to withdraw
   */
  function withdraw(address assetAddress, address recipientAddress, uint192 quantity) external;

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
   & @param appliedDiscount the discount applied to the reward
   */
  struct FeeAndReward {
    bytes32 configDigest;
    Common.Asset fee;
    Common.Asset reward;
    uint256 appliedDiscount;
  }

  /**
   * @notice The structure to hold quote metadata
   * @param quoteAddress the address of the quote
   */
  struct Quote {
    address quoteAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC165.sol";
import {Common} from "../libraries/Common.sol";

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
   * @param startIndex the index to start from
   * @param endIndex the index to stop at
   */
  function getAvailableRewardPoolIds(
    address recipient,
    uint256 startIndex,
    uint256 endIndex
  ) external view returns (bytes32[] memory);

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
pragma solidity 0.8.19;

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC165.sol";
import {Common} from "../libraries/Common.sol";

interface IVerifier is IERC165 {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @param sender The address that requested to verify the contract.
   * This is only used for logging purposes.
   * @dev Verification is typically only done through the proxy contract so
   * we can't just use msg.sender to log the requester as the msg.sender
   * contract will always be the proxy.
   * @return verifierResponse The encoded verified response.
   */
  function verify(bytes calldata signedReport, address sender) external returns (bytes memory verifierResponse);

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param feedId Feed ID to set config for
   * @param signers addresses with which oracles sign the reports
   * @param offchainTransmitters CSA key for the ith Oracle
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   * @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
   */
  function setConfig(
    bytes32 feedId,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) external;

  /**
   * @notice identical to `setConfig` except with args for sourceChainId and sourceAddress
   * @param feedId Feed ID to set config for
   * @param sourceChainId Chain ID of source config
   * @param sourceAddress Address of source config Verifier
   * @param newConfigCount Param to force the new config count
   * @param signers addresses with which oracles sign the reports
   * @param offchainTransmitters CSA key for the ith Oracle
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   * @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
   */
  function setConfigFromSource(
    bytes32 feedId,
    uint256 sourceChainId,
    address sourceAddress,
    uint32 newConfigCount,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) external;

  /**
   * @notice Activates the configuration for a config digest
   * @param feedId Feed ID to activate config for
   * @param configDigest The config digest to activate
   * @dev This function can be called by the contract admin to activate a configuration.
   */
  function activateConfig(bytes32 feedId, bytes32 configDigest) external;

  /**
   * @notice Deactivates the configuration for a config digest
   * @param feedId Feed ID to deactivate config for
   * @param configDigest The config digest to deactivate
   * @dev This function can be called by the contract admin to deactivate an incorrect configuration.
   */
  function deactivateConfig(bytes32 feedId, bytes32 configDigest) external;

  /**
   * @notice Activates the given feed
   * @param feedId Feed ID to activated
   * @dev This function can be called by the contract admin to activate a feed
   */
  function activateFeed(bytes32 feedId) external;

  /**
   * @notice Deactivates the given feed
   * @param feedId Feed ID to deactivated
   * @dev This function can be called by the contract admin to deactivate a feed
   */
  function deactivateFeed(bytes32 feedId) external;

  /**
   * @notice returns the latest config digest and epoch for a feed
   * @param feedId Feed ID to fetch data for
   * @return scanLogs indicates whether to rely on the configDigest and epoch
   * returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
  function latestConfigDigestAndEpoch(
    bytes32 feedId
  ) external view returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

  /**
   * @notice information about current offchain reporting protocol configuration
   * @param feedId Feed ID to fetch data for
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config
   */
  function latestConfigDetails(
    bytes32 feedId
  ) external view returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC165.sol";
import {Common} from "../libraries/Common.sol";

interface IVerifierFeeManager is IERC165 {
  /**
   * @notice Handles fees for a report from the subscriber and manages rewards
   * @param payload report to process the fee for
   * @param parameterPayload fee payload
   * @param subscriber address of the fee will be applied
   */
  function processFee(bytes calldata payload, bytes calldata parameterPayload, address subscriber) external payable;

  /**
   * @notice Processes the fees for each report in the payload, billing the subscriber and paying the reward manager
   * @param payloads reports to process
   * @param parameterPayload fee payload
   * @param subscriber address of the user to process fee for
   */
  function processFeeBulk(
    bytes[] calldata payloads,
    bytes calldata parameterPayload,
    address subscriber
  ) external payable;

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
pragma solidity 0.8.19;

import {Common} from "../libraries/Common.sol";
import {AccessControllerInterface} from "../../shared/interfaces/AccessControllerInterface.sol";
import {IVerifierFeeManager} from "./IVerifierFeeManager.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payload The encoded data to be verified, including the signed
   * report.
   * @param parameterPayload fee metadata for billing
   * @return verifierResponse The encoded report from the verifier.
   */
  function verify(
    bytes calldata payload,
    bytes calldata parameterPayload
  ) external payable returns (bytes memory verifierResponse);

  /**
   * @notice Bulk verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payloads The encoded payloads to be verified, including the signed
   * report.
   * @param parameterPayload fee metadata for billing
   * @return verifiedReports The encoded reports from the verifier.
   */
  function verifyBulk(
    bytes[] calldata payloads,
    bytes calldata parameterPayload
  ) external payable returns (bytes[] memory verifiedReports);

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
pragma solidity 0.8.19;

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
  function _hasDuplicateAddresses(Common.AddressAndWeight[] memory recipients) internal pure returns (bool) {
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
pragma solidity 0.8.19;

import {ConfirmedOwner} from "../shared/access/ConfirmedOwner.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {IVerifier} from "./interfaces/IVerifier.sol";
import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {AccessControllerInterface} from "../shared/interfaces/AccessControllerInterface.sol";
import {IERC165} from "../vendor/openzeppelin-solidity/v4.8.3/contracts/interfaces/IERC165.sol";
import {IVerifierFeeManager} from "./interfaces/IVerifierFeeManager.sol";
import {Common} from "./libraries/Common.sol";

/**
 * The verifier proxy contract is the gateway for all report verification requests
 * on a chain.  It is responsible for taking in a verification request and routing
 * it to the correct verifier contract.
 */
contract VerifierProxy is IVerifierProxy, ConfirmedOwner, TypeAndVersionInterface {
  /// @notice This event is emitted whenever a new verifier contract is set
  /// @param oldConfigDigest The config digest that was previously the latest config
  /// digest of the verifier contract at the verifier address.
  /// @param oldConfigDigest The latest config digest of the verifier contract
  /// at the verifier address.
  /// @param verifierAddress The address of the verifier contract that verifies reports for
  /// a given digest
  event VerifierSet(bytes32 oldConfigDigest, bytes32 newConfigDigest, address verifierAddress);

  /// @notice This event is emitted whenever a new verifier contract is initialized
  /// @param verifierAddress The address of the verifier contract that verifies reports
  event VerifierInitialized(address verifierAddress);

  /// @notice This event is emitted whenever a verifier is unset
  /// @param configDigest The config digest that was unset
  /// @param verifierAddress The Verifier contract address unset
  event VerifierUnset(bytes32 configDigest, address verifierAddress);

  /// @notice This event is emitted when a new access controller is set
  /// @param oldAccessController The old access controller address
  /// @param newAccessController The new access controller address
  event AccessControllerSet(address oldAccessController, address newAccessController);

  /// @notice This event is emitted when a new fee manager is set
  /// @param oldFeeManager The old fee manager address
  /// @param newFeeManager The new fee manager address
  event FeeManagerSet(address oldFeeManager, address newFeeManager);

  /// @notice This error is thrown whenever an address tries
  /// to exeecute a transaction that it is not authorized to do so
  error AccessForbidden();

  /// @notice This error is thrown whenever a zero address is passed
  error ZeroAddress();

  /// @notice This error is thrown when trying to set a verifier address
  /// for a digest that has already been initialized
  /// @param configDigest The digest for the verifier that has
  /// already been set
  /// @param verifier The address of the verifier the digest was set for
  error ConfigDigestAlreadySet(bytes32 configDigest, address verifier);

  /// @notice This error is thrown when trying to set a verifier address that has already been initialized
  error VerifierAlreadyInitialized(address verifier);

  /// @notice This error is thrown when the verifier at an address does
  /// not conform to the verifier interface
  error VerifierInvalid();

  /// @notice This error is thrown when the fee manager at an address does
  /// not conform to the fee manager interface
  error FeeManagerInvalid();

  /// @notice This error is thrown whenever a verifier is not found
  /// @param configDigest The digest for which a verifier is not found
  error VerifierNotFound(bytes32 configDigest);

  /// @notice This error is thrown whenever billing fails.
  error BadVerification();

  /// @notice Mapping of authorized verifiers
  mapping(address => bool) private s_initializedVerifiers;

  /// @notice Mapping between config digests and verifiers
  mapping(bytes32 => address) private s_verifiersByConfig;

  /// @notice The contract to control addresses that are allowed to verify reports
  AccessControllerInterface public s_accessController;

  /// @notice The contract to control fees for report verification
  IVerifierFeeManager public s_feeManager;

  constructor(AccessControllerInterface accessController) ConfirmedOwner(msg.sender) {
    s_accessController = accessController;
  }

  modifier checkAccess() {
    AccessControllerInterface ac = s_accessController;
    if (address(ac) != address(0) && !ac.hasAccess(msg.sender, msg.data)) revert AccessForbidden();
    _;
  }

  modifier onlyInitializedVerifier() {
    if (!s_initializedVerifiers[msg.sender]) revert AccessForbidden();
    _;
  }

  modifier onlyValidVerifier(address verifierAddress) {
    if (verifierAddress == address(0)) revert ZeroAddress();
    if (!IERC165(verifierAddress).supportsInterface(IVerifier.verify.selector)) revert VerifierInvalid();
    _;
  }

  modifier onlyUnsetConfigDigest(bytes32 configDigest) {
    address configDigestVerifier = s_verifiersByConfig[configDigest];
    if (configDigestVerifier != address(0)) revert ConfigDigestAlreadySet(configDigest, configDigestVerifier);
    _;
  }

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "VerifierProxy 2.0.0";
  }

  /// @inheritdoc IVerifierProxy
  function verify(
    bytes calldata payload,
    bytes calldata parameterPayload
  ) external payable checkAccess returns (bytes memory) {
    IVerifierFeeManager feeManager = s_feeManager;

    // Bill the verifier
    if (address(feeManager) != address(0)) {
      feeManager.processFee{value: msg.value}(payload, parameterPayload, msg.sender);
    }

    return _verify(payload);
  }

  /// @inheritdoc IVerifierProxy
  function verifyBulk(
    bytes[] calldata payloads,
    bytes calldata parameterPayload
  ) external payable checkAccess returns (bytes[] memory verifiedReports) {
    IVerifierFeeManager feeManager = s_feeManager;

    // Bill the verifier
    if (address(feeManager) != address(0)) {
      feeManager.processFeeBulk{value: msg.value}(payloads, parameterPayload, msg.sender);
    }

    //verify the reports
    verifiedReports = new bytes[](payloads.length);
    for (uint256 i; i < payloads.length; ++i) {
      verifiedReports[i] = _verify(payloads[i]);
    }

    return verifiedReports;
  }

  function _verify(bytes calldata payload) internal returns (bytes memory verifiedReport) {
    // First 32 bytes of the signed report is the config digest
    bytes32 configDigest = bytes32(payload);
    address verifierAddress = s_verifiersByConfig[configDigest];
    if (verifierAddress == address(0)) revert VerifierNotFound(configDigest);

    return IVerifier(verifierAddress).verify(payload, msg.sender);
  }

  /// @inheritdoc IVerifierProxy
  function initializeVerifier(address verifierAddress) external override onlyOwner onlyValidVerifier(verifierAddress) {
    if (s_initializedVerifiers[verifierAddress]) revert VerifierAlreadyInitialized(verifierAddress);

    s_initializedVerifiers[verifierAddress] = true;
    emit VerifierInitialized(verifierAddress);
  }

  /// @inheritdoc IVerifierProxy
  function setVerifier(
    bytes32 currentConfigDigest,
    bytes32 newConfigDigest,
    Common.AddressAndWeight[] calldata addressesAndWeights
  ) external override onlyUnsetConfigDigest(newConfigDigest) onlyInitializedVerifier {
    s_verifiersByConfig[newConfigDigest] = msg.sender;

    // Empty recipients array will be ignored and must be set off chain
    if (addressesAndWeights.length > 0) {
      if (address(s_feeManager) == address(0)) {
        revert ZeroAddress();
      }

      s_feeManager.setFeeRecipients(newConfigDigest, addressesAndWeights);
    }

    emit VerifierSet(currentConfigDigest, newConfigDigest, msg.sender);
  }

  /// @inheritdoc IVerifierProxy
  function unsetVerifier(bytes32 configDigest) external override onlyOwner {
    address verifierAddress = s_verifiersByConfig[configDigest];
    if (verifierAddress == address(0)) revert VerifierNotFound(configDigest);
    delete s_verifiersByConfig[configDigest];
    emit VerifierUnset(configDigest, verifierAddress);
  }

  /// @inheritdoc IVerifierProxy
  function getVerifier(bytes32 configDigest) external view override returns (address) {
    return s_verifiersByConfig[configDigest];
  }

  /// @inheritdoc IVerifierProxy
  function setAccessController(AccessControllerInterface accessController) external onlyOwner {
    address oldAccessController = address(s_accessController);
    s_accessController = accessController;
    emit AccessControllerSet(oldAccessController, address(accessController));
  }

  /// @inheritdoc IVerifierProxy
  function setFeeManager(IVerifierFeeManager feeManager) external onlyOwner {
    if (address(feeManager) == address(0)) revert ZeroAddress();

    if (
      !IERC165(feeManager).supportsInterface(IVerifierFeeManager.processFee.selector) ||
      !IERC165(feeManager).supportsInterface(IVerifierFeeManager.processFeeBulk.selector)
    ) revert FeeManagerInvalid();

    address oldFeeManager = address(s_feeManager);
    s_feeManager = IVerifierFeeManager(feeManager);
    emit FeeManagerSet(oldFeeManager, address(feeManager));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwnerWithProposal} from "./ConfirmedOwnerWithProposal.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOwnable} from "../interfaces/IOwnable.sol";

/// @title The ConfirmedOwner contract
/// @notice A contract with helpers for basic contract ownership.
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    // solhint-disable-next-line gas-custom-errors
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /// @notice Allows an owner to begin transferring ownership to a new address.
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /// @notice Allows an ownership transfer to be completed by the recipient.
  function acceptOwnership() external override {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /// @notice Get the current owner
  function owner() public view override returns (address) {
    return s_owner;
  }

  /// @notice validate, transfer ownership, and emit relevant events
  function _transferOwnership(address to) private {
    // solhint-disable-next-line gas-custom-errors
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /// @notice validate access
  function _validateOwnership() internal view {
    // solhint-disable-next-line gas-custom-errors
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /// @notice Reverts if called by anyone other than the contract owner.
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
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
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
  function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
  function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
      if (value >= 10 ** 64) {
        value /= 10 ** 64;
        result += 64;
      }
      if (value >= 10 ** 32) {
        value /= 10 ** 32;
        result += 32;
      }
      if (value >= 10 ** 16) {
        value /= 10 ** 16;
        result += 16;
      }
      if (value >= 10 ** 8) {
        value /= 10 ** 8;
        result += 8;
      }
      if (value >= 10 ** 4) {
        value /= 10 ** 4;
        result += 4;
      }
      if (value >= 10 ** 2) {
        value /= 10 ** 2;
        result += 2;
      }
      if (value >= 10 ** 1) {
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
      return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {AutomationCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {StreamsLookupCompatibleInterface} from
    "@chainlink/contracts/src/v0.8/automation/interfaces/StreamsLookupCompatibleInterface.sol";
import {VerifierProxy} from "@chainlink/contracts/src/v0.8/llo-feeds/VerifierProxy.sol";
import {FeeManager} from "@chainlink/contracts/src/v0.8/llo-feeds/FeeManager.sol";
import {Common} from "@chainlink/contracts/src/v0.8/llo-feeds/libraries/Common.sol";
import {IERC20, IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Babylonian} from "./libraries/Babylonian.sol";
import {FullMath} from "./libraries/FullMath.sol";
import {IArbiter} from "./interfaces/IArbiter.sol";
import {IDexAdapter} from "./interfaces/IDexAdapter.sol";
import {IFlashLiquidityPair} from "./interfaces/IFlashLiquidityPair.sol";
import {Governable} from "flashliquidity-acs/contracts/Governable.sol";

/**
 * @title Arbiter
 * @author Oddcod3 (@oddcod3)
 * @dev An arbitrage bot designed for performing rebalancing operations and distributing profits to liquidity providers in FlashLiquidity self-balancing pools.
 *      It integrates with Chainlink Automation (via AutomationCompatibleInterface) for triggering rebalancing operations based on predefined conditions, and with Chainlink Data Feeds/Data Streams for fetching price data necessary for these operations.
 * @notice The contract is Governable, implying that certain functionalities are restricted to the contract's governor.
 */
contract Arbiter is IArbiter, AutomationCompatibleInterface, StreamsLookupCompatibleInterface, Governable {
    using SafeERC20 for IERC20;
    ///////////////////////
    // Errors            //
    ///////////////////////

    error Arbiter__InvalidPool();
    error Arbiter__NotManager();
    error Arbiter__InconsistentParamsLength();
    error Arbiter__NotPermissionedPair();
    error Arbiter__InvalidProfitToReservesRatio();
    error Arbiter__InsufficentProfit();
    error Arbiter__NotFromArbiter();
    error Arbiter__NotFromForwarder();
    error Arbiter__DataFeedNotSet();
    error Arbiter__InvalidPrice();
    error Arbiter__StalenessTooHigh();
    error Arbiter__OutOfBound();

    ///////////////////////
    // Types             //
    ///////////////////////

    struct ArbiterJobConfig {
        address rewardVault; // Address of the vault where rebalancing profits are deposited.
        uint96 reserveToMinProfit; // The minimum ratio between reserve and profit below which the rebalancing operation reverts.
        address automationForwarder; // Intermediary between the Chainlink Automation Registry and the Arbiter.
        uint96 reserveToTriggerProfit; // The minimum ratio between reserve and profit required to trigger a rebalancing operation.
        address tokenIn; // Address of the input token for the rebalancing trade.
        uint8 tokenInDecimals; // Decimal count of the input token.
        address tokenOut; // Address of the output token for the rebalancing trade.
        uint8 tokenOutDecimals; // Decimal count of the output token.
    }

    struct ArbiterCall {
        address selfBalancingPool; // Address of the self-balancing pool involved in the trade.
        uint256 amountIn; // Amount of the input token to be used in the trade.
        uint256 amountOut; // Expected amount of the output token from the trade.
        uint256 adapterIndex; // Index of the chosen DEX adapter for the trade.
        bytes extraArgs; // Additional arguments required by the DEX adapter, encoded in bytes.
        bool zeroToOne; // Direction of the swap; true for tokenIn to tokenOut, false for tokenOut to tokenIn.
    }

    struct CallbackData {
        address token0; // Address of the first token in the swap pair.
        address token1; // Address of the second token in the swap pair.
        address rewardVault; // Address of the rewards vault to send profit to.
        uint256 minProfitTokenIn; // The minimum profit denominated in tokenIn below which the rebalancing operation reverts.
        uint256 adapterIndex; // Index of the adapter used for the swap.
        uint256 amountDebt; // Amount of the debt that needs to be returned to the self-balancing pool.
        bytes extraArgs; // Additional encoded arguments required for post-swap operations.
        bool zeroToOne; // Direction of the swap; true for token0 to token1, false for token1 to token0.
    }

    struct PremiumReport {
        bytes32 feedId; // The feed ID the report has data for.
        uint32 validFromTimestamp; // Earliest timestamp for which price is applicable.
        uint32 observationsTimestamp; // Latest timestamp for which price is applicable.
        uint192 nativeFee; // Base cost to validate a transaction using the report, denominated in the chain’s native token (WETH/ETH).
        uint192 linkFee; // Base cost to validate a transaction using the report, denominated in LINK.
        uint32 expiresAt; // Latest timestamp where the report can be verified onchain.
        int192 price; // DON consensus median price, carried to 8 decimal places.
        int192 bid; // Simulated price impact of a buy order up to the X% depth of liquidity utilisation.
        int192 ask; // Simulated price impact of a sell order up to the X% depth of liquidity utilisation.
    }

    struct RebalancingInfo {
        bool zeroToOne; // Direction of the rebalancing swap; true for tokenIn to tokenOut, false otherwise.
        uint256 amountIn; // Amount of the input token to be swapped.
        uint256 amountOut; // Amount of the output token expected from the swap.
    }

    ///////////////////////
    // State Variables   //
    ///////////////////////

    /// @dev FlashLiquidity self-balancing pool fee numerator, set to 9994 to represent a fee of 6 basis points.
    uint24 public constant FL_FEE_NUMERATOR = 9994;
    /// @dev FlashLiquidity self-balancing pool fee denominator, set to 10000 for fee calculation.
    uint24 public constant FL_FEE_DENOMINATOR = 10000;
    /// @dev The address of the Chainlink Data Streams verifier proxy used for verifying signed reports.
    address private s_verifierProxy;
    /// @dev The address that is permissioned for flashLiquidityCall callback verification. Set to a default value.
    address private s_permissionedPairAddress = address(1);
    /// @dev The address of LINK token used to pay for Data Streams reports verification.
    address private immutable i_linkToken;
    /// @dev Maximum staleness allowed for price data in seconds. Prices older than this will be considered invalid.
    uint32 private s_priceMaxStaleness;
    /// @dev Minimum Arbiter LINK balance required to request data streams reports. If the balance falls below this threshold, data feeds will be used instead.
    uint64 private s_minLinkDataStreams;
    /// @dev Array of DEX adapter interfaces used for handling token swaps.
    IDexAdapter[] private s_adapters;
    /// @dev Mapping from each self-balancing pool address to its corresponding Arbiter job configuration.
    mapping(address selfBalancingPool => ArbiterJobConfig jobConfig) private s_jobConfig;
    /// @dev Mapping of token addresses to their respective Chainlink Data Feeds interfaces.
    mapping(address token => AggregatorV3Interface dataFeed) private s_dataFeeds;
    /// @dev Mapping of token addresses to their respective Chainlink Data Streams IDs.
    mapping(address token => string feedID) private s_dataStreams;

    ///////////////////////
    // Events            //
    ///////////////////////

    event VerifierProxyChanged(address verifierProxy);
    event PriceMaxStalenessChanged(uint256 newStaleness);
    event MinLinkDataStreamsChanged(uint256 newMinLink);
    event ArbiterJobChanged(address indexed selfBalancingPool, address indexed rewardVault);
    event ArbiterJobRemoved(address indexed selfBalancingPool);
    event DexAdapterAdded(address adapter);
    event DexAdapterRemoved(address adapter);
    event DataFeedsChanged(address[] tokens, address[] dataFeeds);
    event DataStreamsChanged(address[] tokens, string[] feedIDs);

    ////////////////////////
    // Functions          //
    ////////////////////////

    constructor(
        address governor,
        address verifierProxy,
        address linkToken,
        uint32 priceMaxStaleness,
        uint64 minLinkDataStreams
    ) Governable(governor) {
        _setVerifierProxy(verifierProxy);
        _setPriceMaxStaleness(priceMaxStaleness);
        _setMinLinkDataStreams(minLinkDataStreams);
        i_linkToken = linkToken;
    }

    ////////////////////////
    // External Functions //
    ////////////////////////

    /// @inheritdoc IArbiter
    function setVerifierProxy(address verifierProxy) external onlyGovernor {
        _setVerifierProxy(verifierProxy);
    }

    /// @inheritdoc IArbiter
    function setPriceMaxStaleness(uint32 priceMaxStaleness) external onlyGovernor {
        _setPriceMaxStaleness(priceMaxStaleness);
    }

    /// @inheritdoc IArbiter
    function setMinLinkDataStreams(uint64 minLinkDataStreams) external onlyGovernor {
        _setMinLinkDataStreams(minLinkDataStreams);
    }

    /// @inheritdoc IArbiter
    function setDataFeeds(address[] calldata tokens, address[] calldata dataFeeds) external onlyGovernor {
        uint256 tokensLen = tokens.length;
        if (tokensLen != dataFeeds.length) revert Arbiter__InconsistentParamsLength();
        for (uint256 i; i < tokensLen;) {
            s_dataFeeds[tokens[i]] = AggregatorV3Interface(dataFeeds[i]);
            unchecked {
                ++i;
            }
        }
        emit DataFeedsChanged(tokens, dataFeeds);
    }

    /// @inheritdoc IArbiter
    function setDataStreams(address[] calldata tokens, string[] calldata feedIDs) external onlyGovernor {
        uint256 tokensLen = tokens.length;
        if (tokensLen != feedIDs.length) revert Arbiter__InconsistentParamsLength();
        for (uint256 i; i < tokensLen;) {
            s_dataStreams[tokens[i]] = feedIDs[i];
            unchecked {
                ++i;
            }
        }
        emit DataStreamsChanged(tokens, feedIDs);
    }

    /// @inheritdoc IArbiter
    function setArbiterJob(
        address selfBalancingPool,
        address rewardVault,
        address automationForwarder,
        uint96 reserveToMinProfit,
        uint96 reserveToTriggerProfit,
        uint8 forceToken0Decimals,
        uint8 forceToken1Decimals
    ) external onlyGovernor {
        IFlashLiquidityPair flPool = IFlashLiquidityPair(selfBalancingPool);
        (address token0, address token1) = (flPool.token0(), flPool.token1());
        if (token0 == address(0) || token1 == address(0)) revert Arbiter__InvalidPool();
        if (flPool.manager() != address(this)) revert Arbiter__NotManager();
        if (address(s_dataFeeds[token0]) == address(0) || address(s_dataFeeds[token1]) == address(0)) {
            revert Arbiter__DataFeedNotSet();
        }
        if (reserveToMinProfit == 0 || reserveToTriggerProfit == 0 || reserveToMinProfit > reserveToTriggerProfit) {
            revert Arbiter__InvalidProfitToReservesRatio();
        }
        if (reserveToMinProfit < reserveToTriggerProfit - reserveToTriggerProfit / 10) {
            revert Arbiter__InvalidProfitToReservesRatio();
        }
        s_jobConfig[selfBalancingPool] = ArbiterJobConfig({
            rewardVault: rewardVault,
            reserveToMinProfit: reserveToMinProfit,
            automationForwarder: automationForwarder,
            reserveToTriggerProfit: reserveToTriggerProfit,
            tokenIn: token0,
            tokenInDecimals: forceToken0Decimals > 0 ? forceToken0Decimals : IERC20Metadata(token0).decimals(),
            tokenOut: token1,
            tokenOutDecimals: forceToken1Decimals > 0 ? forceToken1Decimals : IERC20Metadata(token1).decimals()
        });
        emit ArbiterJobChanged(selfBalancingPool, rewardVault);
    }

    /// @inheritdoc IArbiter
    function deleteArbiterJob(address selfBalancingPool) external onlyGovernor {
        delete s_jobConfig[selfBalancingPool];
        emit ArbiterJobRemoved(selfBalancingPool);
    }

    /// @inheritdoc IArbiter
    function pushDexAdapter(address adapter) external onlyGovernor {
        s_adapters.push(IDexAdapter(adapter));
        emit DexAdapterAdded(adapter);
    }

    /// @inheritdoc IArbiter
    function removeDexAdapter(uint256 adapterIndex) external onlyGovernor {
        uint256 adaptersLen = s_adapters.length;
        if (adaptersLen == 0 || adapterIndex >= adaptersLen) revert Arbiter__OutOfBound();
        address dexAdapter = address(s_adapters[adapterIndex]);
        if (adapterIndex < adaptersLen - 1) {
            s_adapters[adapterIndex] = s_adapters[adaptersLen - 1];
        }
        s_adapters.pop();
        emit DexAdapterRemoved(dexAdapter);
    }

    /// @inheritdoc IArbiter
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external onlyGovernor {
        uint256 tokensLen = tokens.length;
        if (tokensLen != amounts.length) revert Arbiter__InconsistentParamsLength();
        for (uint256 i; i < tokensLen;) {
            IERC20(tokens[i]).safeTransfer(to, amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc IArbiter
     * @dev This function is called post-flash swap inside performUpkeep call to handle the received tokens.
     *
     * The function performs the following operations:
     * 1. Decodes the `data` to retrieve `CallbackData` which contains swap details and profit targets.
     * 2. Determines the direction of the swap and sets the corresponding token amounts for the swap.
     * 3. Executes the swap via the specified DEX adapter using the amounts and parameters from `CallbackData`.
     * 4. Calculates the profit from the swap and ensures it meets the minimum profit threshold specified in `CallbackData`.
     * 5. Distributes the profit to the designated `rewardVault` and returns the borrowed amount to the self-balancing pool.
     *
     * Reverts if:
     * - The call is not from the expected permissioned pair address (`msg.sender` check).
     * - The sender is not the Arbiter contract itself.
     * - The calculated profit does not meet the minimum required profit threshold.
     *
     */
    function flashLiquidityCall(address sender, uint256 amount0, uint256 amount1, bytes memory data) external {
        if (msg.sender != s_permissionedPairAddress) revert Arbiter__NotPermissionedPair();
        if (sender != address(this)) revert Arbiter__NotFromArbiter();
        CallbackData memory info = abi.decode(data, (CallbackData));
        (IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn) = info.zeroToOne
            ? (IERC20(info.token1), IERC20(info.token0), amount1)
            : (IERC20(info.token0), IERC20(info.token1), amount0);
        IDexAdapter adapter = s_adapters[info.adapterIndex];
        tokenIn.forceApprove(address(adapter), amountIn);
        uint256 amoutOut = adapter.swap(address(tokenIn), address(tokenOut), address(this), amountIn, 0, info.extraArgs);
        uint256 profit = amoutOut - info.amountDebt;
        if (profit < info.minProfitTokenIn) revert Arbiter__InsufficentProfit();
        tokenOut.safeTransfer(info.rewardVault, profit);
        tokenOut.safeTransfer(msg.sender, info.amountDebt);
    }

    /**
     * @inheritdoc AutomationCompatibleInterface
     * @dev Executes the upkeep routine as part of the Chainlink Automation integration.
     * @param performData Encoded data necessary for the upkeep, which includes signed reports and Arbiter call details.
     *
     * In the function:
     * 1. It decodes `performData` to extract signed reports and the ArbiterCall struct.
     * 2. Retrieves the job configuration for the self-balancing pool involved in the call.
     * 3. Sets the permissioned pair address to the self-balancing pool address for validation.
     * 4. Prepares callback data for the swap operation.
     * 5. Verifies data stream reports if present.
     * 6. Performs the swap operation via the self-balancing pool.
     * 7. Resets the permissioned pair address.
     *
     * @notice This function is crucial for the automated rebalancing of pools and is triggered by Chainlink Automation.
     * @notice It ensures that each swap is profitable and adheres to the configured parameters of the job.
     */
    function performUpkeep(bytes calldata performData) external override {
        (bytes[] memory signedReports, ArbiterCall memory call) = abi.decode(performData, (bytes[], ArbiterCall));
        ArbiterJobConfig memory jobConfig = s_jobConfig[call.selfBalancingPool];
        if (msg.sender != jobConfig.automationForwarder) revert Arbiter__NotFromForwarder();
        if (signedReports.length != 0) _verifyDataStreamReports(signedReports);
        s_permissionedPairAddress = call.selfBalancingPool;
        (uint256 reserve0, uint256 reserve1,) = IFlashLiquidityPair(call.selfBalancingPool).getReserves();
        (uint256 amount0, uint256 amount1, uint256 reserveTokenIn) =
            call.zeroToOne ? (uint256(0), call.amountOut, reserve0) : (call.amountOut, uint256(0), reserve1);
        CallbackData memory callbackData = CallbackData({
            token0: jobConfig.tokenIn,
            token1: jobConfig.tokenOut,
            rewardVault: jobConfig.rewardVault,
            minProfitTokenIn: reserveTokenIn / jobConfig.reserveToMinProfit,
            adapterIndex: call.adapterIndex,
            amountDebt: call.amountIn,
            extraArgs: call.extraArgs,
            zeroToOne: call.zeroToOne
        });
        IFlashLiquidityPair(call.selfBalancingPool).swap(amount0, amount1, address(this), abi.encode(callbackData));
        s_permissionedPairAddress = address(1);
    }

    ////////////////////////
    // Private Functions  //
    ////////////////////////

    /// @param verifierProxy The address of the new verifier proxy.
    function _setVerifierProxy(address verifierProxy) private {
        s_verifierProxy = verifierProxy;
        emit VerifierProxyChanged(verifierProxy);
    }

    /// @param priceMaxStaleness The new maximum duration (in seconds) that price data is considered valid.
    function _setPriceMaxStaleness(uint32 priceMaxStaleness) private {
        s_priceMaxStaleness = priceMaxStaleness;
        emit PriceMaxStalenessChanged(priceMaxStaleness);
    }

    /// @param minLinkDataStreams The new minimum Arbiter LINK balance balance for requesting data streams report.
    function _setMinLinkDataStreams(uint64 minLinkDataStreams) private {
        s_minLinkDataStreams = minLinkDataStreams;
        emit MinLinkDataStreamsChanged(minLinkDataStreams);
    }

    /**
     * @dev Verifies an array of two encoded Chainlink Data Streams reports.
     * @param signedReports An array of exactly two encoded Chainlink Data Streams reports that need to be verified.
     * @notice This function is specifically designed to handle and validate a pair of Chainlink Data Streams reports.
     */
    function _verifyDataStreamReports(bytes[] memory signedReports) private {
        VerifierProxy verifierProxy = VerifierProxy(s_verifierProxy);
        (, bytes memory report0Data) = abi.decode(signedReports[0], (bytes32[3], bytes));
        (, bytes memory report1Data) = abi.decode(signedReports[1], (bytes32[3], bytes));
        FeeManager feeManager = FeeManager(address(verifierProxy.s_feeManager()));
        (Common.Asset memory fee0,,) = feeManager.getFeeAndReward(address(this), report0Data, i_linkToken);
        (Common.Asset memory fee1,,) = feeManager.getFeeAndReward(address(this), report1Data, i_linkToken);
        IERC20(i_linkToken).approve(address(feeManager.i_rewardManager()), fee0.amount + fee1.amount);
        verifierProxy.verifyBulk(signedReports, abi.encode(i_linkToken));
    }

    /////////////////////////////
    // Private View Functions  //
    /////////////////////////////

    /**
     * @dev Calculates the necessary trade information for rebalancing a given self-balancing pool based on the prices of token0 and token1.
     * @param price0 The price of token0 in USD.
     * @param price1 The price of token1 in USD.
     * @param reserveIn The self-balancing pool reserve of token0.
     * @param reserveOut The self-balancing pool reserve of token1.
     * @param token0Decimals The number of decimals of token0.
     * @param token1Decimals The number of decimals of token1.
     * @return tradeInfo A struct containing the information for the rebalancing trade, including amounts to trade in and out.
     * @notice This function performs a series of calculations to determine how much of each token should be traded to achieve rebalancing.
     *         It takes into account the current reserves, prices, and decimal precision of the tokens.
     */
    function _computeRebalancingTrade(
        uint256 price0,
        uint256 price1,
        uint256 reserveIn,
        uint256 reserveOut,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) private pure returns (RebalancingInfo memory tradeInfo) {
        (uint256 rateTokenIn, uint256 rateTokenOut) = price0 < price1
            ? (10 ** token0Decimals, FullMath.mulDiv(price0, 10 ** token1Decimals, price1))
            : (FullMath.mulDiv(price1, 10 ** token0Decimals, price0), 10 ** token1Decimals);
        tradeInfo.zeroToOne = FullMath.mulDiv(reserveIn, rateTokenOut, reserveOut) < rateTokenIn;
        if (!tradeInfo.zeroToOne) {
            (reserveIn, reserveOut, rateTokenIn, rateTokenOut) = (reserveOut, reserveIn, rateTokenOut, rateTokenIn);
        }
        uint256 leftSide = Babylonian.sqrt(
            FullMath.mulDiv(reserveIn * reserveOut, rateTokenIn * FL_FEE_DENOMINATOR, rateTokenOut * FL_FEE_NUMERATOR)
        );
        uint256 rightSide = reserveIn * FL_FEE_DENOMINATOR / FL_FEE_NUMERATOR;
        if (leftSide <= rightSide || reserveIn == 0 || reserveOut == 0) return tradeInfo;
        tradeInfo.amountIn = leftSide - rightSide;
        uint256 amountInWithFee = tradeInfo.amountIn * FL_FEE_NUMERATOR;
        tradeInfo.amountOut = amountInWithFee * reserveOut / ((reserveIn * FL_FEE_DENOMINATOR) + amountInWithFee);
    }

    /**
     * @dev Identifies the best route for a swap operation based on the input token, output token, and input amount.
     *      This function iterates through a list of available dex adapters to find the one offering the best output amount for the swap.
     * @param tokenIn The address of the input token for the swap.
     * @param tokenOut The address of the output token from the swap.
     * @param amountIn The amount of the input token for the swap.
     * @return maxOutput The maximum output amount for the output token that can be obtained from the swap.
     * @return adapterIndex The index of the dex adapter in the adapters array where the swap will yield the best output.
     * @return extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     */
    function _findBestRoute(address tokenIn, address tokenOut, uint256 amountIn)
        private
        view
        returns (uint256 maxOutput, uint256 adapterIndex, bytes memory extraArgs)
    {
        uint256 adaptersLen = s_adapters.length;
        uint256 tempOutput;
        bytes memory tempExtraArgs;
        for (uint256 i; i < adaptersLen;) {
            (tempOutput, tempExtraArgs) = s_adapters[i].getMaxOutput(tokenIn, tokenOut, amountIn);
            if (tempOutput > maxOutput) {
                adapterIndex = i;
                maxOutput = tempOutput;
                extraArgs = tempExtraArgs;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Determines whether a rebalancing trade is necessary for a given self-balancing pool based on current prices and configuration.
     * @param selfBalancingPool The address of the self-balancing pool under consideration.
     * @param priceTokenIn The current price of the input token.
     * @param priceTokenOut The current price of the output token.
     * @param jobConfig Configuration parameters for the Arbiter job, including token decimals and minimum profit threshold.
     * @return rebalancingNeeded A boolean indicating whether a rebalancing trade is necessary based on the profit potential and pool conditions.
     * @return arbiterCall An ArbiterCall struct containing the details of the rebalancing trade if one is needed.
     * @notice This function evaluates whether a rebalancing operation is profitable and necessary. It considers the current token prices, the best pool for the trade, and the configured minimum profit threshold.
     *         If the conditions are met for a profitable trade, it returns true for 'rebalancingNeeded' along with the 'arbiterCall' data necessary to perform the rebalancing operation.
     */
    function _isRebalancingNeeded(
        address selfBalancingPool,
        uint256 priceTokenIn,
        uint256 priceTokenOut,
        ArbiterJobConfig memory jobConfig
    ) private view returns (bool rebalancingNeeded, ArbiterCall memory arbiterCall) {
        (uint256 reserveIn, uint256 reserveOut,) = IFlashLiquidityPair(selfBalancingPool).getReserves();
        RebalancingInfo memory rebalancing = _computeRebalancingTrade(
            priceTokenIn, priceTokenOut, reserveIn, reserveOut, jobConfig.tokenInDecimals, jobConfig.tokenOutDecimals
        );
        if (!rebalancing.zeroToOne) {
            (jobConfig.tokenIn, jobConfig.tokenOut, priceTokenIn, jobConfig.tokenInDecimals) =
                (jobConfig.tokenOut, jobConfig.tokenIn, priceTokenOut, jobConfig.tokenOutDecimals);
        }
        if (rebalancing.amountIn == 0 || rebalancing.amountOut == 0) return (false, arbiterCall);
        (uint256 maxOutput, uint256 adapterIndex, bytes memory extraArgs) =
            _findBestRoute(jobConfig.tokenOut, jobConfig.tokenIn, rebalancing.amountOut);
        if (maxOutput > rebalancing.amountIn) {
            uint256 profitTrigger = rebalancing.zeroToOne ? reserveIn : reserveOut;
            profitTrigger = profitTrigger / jobConfig.reserveToTriggerProfit;
            if (maxOutput - rebalancing.amountIn >= profitTrigger) {
                rebalancingNeeded = true;
                arbiterCall = ArbiterCall({
                    selfBalancingPool: selfBalancingPool,
                    amountIn: rebalancing.amountIn,
                    amountOut: rebalancing.amountOut,
                    adapterIndex: adapterIndex,
                    extraArgs: extraArgs,
                    zeroToOne: rebalancing.zeroToOne
                });
            }
        }
    }

    /**
     * @dev Retrieves the latest price for a given token from its assigned Chainlink data feed, ensuring the price data is within an acceptable staleness threshold.
     * @param token The address of the token for which the price is to be fetched.
     * @param priceMaxStaleness The maximum acceptable staleness for price data in seconds. If the latest price data is older than this threshold, the function will revert.
     * @return The latest price of the token as a uint256.
     * @notice The function first checks if the token has an associated data feed. If not, it reverts with 'Arbiter__DataFeedNotSet'.
     * @notice It then fetches the latest price and its update timestamp. If the price is invalid (non-positive) or too stale (older than 'priceMaxStaleness'), the function reverts with 'Arbiter__InvalidPrice' or 'Arbiter__StalenessTooHigh', respectively.
     */
    function _getPriceFromDataFeed(address token, uint256 priceMaxStaleness) private view returns (uint256) {
        AggregatorV3Interface priceFeed = s_dataFeeds[token];
        if (address(priceFeed) == address(0)) revert Arbiter__DataFeedNotSet();
        (, int256 price,, uint256 priceUpdatedAt,) = priceFeed.latestRoundData();
        if (price <= int256(0)) revert Arbiter__InvalidPrice();
        if (block.timestamp - priceUpdatedAt > priceMaxStaleness) revert Arbiter__StalenessTooHigh();
        return uint256(price);
    }

    /////////////////////////////
    // External View Functions //
    /////////////////////////////

    /**
     * @inheritdoc AutomationCompatibleInterface
     * @dev Checks if an upkeep is needed for a given self-balancing pool. This function is part of the Chainlink Automation integration.
     * @param checkData Encoded data specifying the self-balancing pool to check for potential rebalancing.
     * @return upkeepNeeded A boolean indicating whether rebalancing is needed for the specified pool.
     * @return performData Data to be used for the rebalancing operation if upkeep is needed.
     *
     * In the function:
     * 1. Decodes `checkData` to extract the self-balancing pool address.
     * 2. Fetches the job configuration for the specified pool.
     * 3. Checks if data streams are set for the pool's tokens. If not, it fetches prices from data feeds and determines if rebalancing is required.
     * 4. If data streams are set, it reverts with StreamsLookup error and Automation network will use this revert to trigger fetching of the specified reports.
     *
     * @notice This function determines the need for upkeep by comparing token prices and the configured job parameters.
     */
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address selfBalancingPool = abi.decode(checkData, (address));
        ArbiterJobConfig memory jobConfig = s_jobConfig[selfBalancingPool];
        string[] memory feedIDs = new string[](2);
        feedIDs[0] = s_dataStreams[jobConfig.tokenIn];
        feedIDs[1] = s_dataStreams[jobConfig.tokenOut];
        if (
            bytes(feedIDs[0]).length == 0 || bytes(feedIDs[1]).length == 0
                || IERC20(i_linkToken).balanceOf(address(this)) < s_minLinkDataStreams
        ) {
            uint256 maxPriceStaleness = s_priceMaxStaleness;
            uint256 priceTokenIn = _getPriceFromDataFeed(jobConfig.tokenIn, maxPriceStaleness);
            uint256 priceTokenOut = _getPriceFromDataFeed(jobConfig.tokenOut, maxPriceStaleness);
            ArbiterCall memory arbiterCall;
            (upkeepNeeded, arbiterCall) =
                _isRebalancingNeeded(selfBalancingPool, priceTokenIn, priceTokenOut, jobConfig);
            performData = abi.encode(new bytes[](0), arbiterCall);
        } else {
            revert StreamsLookup("feedIDs", feedIDs, "timestamp", block.timestamp, checkData);
        }
    }

    /**
     * @inheritdoc StreamsLookupCompatibleInterface
     * @dev Checks if rebalancing is needed for a self-balancing pool based on Chainlink Data Streams reports. Implements the StreamsLookupCompatibleInterface.
     * @param values An array of encoded Chainlink Data Streams reports.
     * @param extraData Encoded extra data, typically containing the address of the self-balancing pool.
     * @return upkeepNeeded A boolean indicating whether a rebalancing operation is needed.
     * @return performData Data to be used for the rebalancing operation if upkeep is needed.
     *
     * In the function:
     * 1. Decodes `extraData` to extract the self-balancing pool address.
     * 2. Decodes the first two elements of `values` to get the reports for tokenIn and tokenOut.
     * 3. Checks for valid prices in the reports. If any price is non-positive, it reverts with 'Arbiter__InvalidPrice'.
     * 4. Retrieves the job configuration for the specified pool.
     * 5. Extract the prices from the reports and checks if rebalancing is needed based on these prices and the job configuration.
     *
     * @notice This function is triggered by Chainlink Data Streams and is used to automate the rebalancing of pools based on external data.
     * @notice It ensures that the pool is rebalanced only when the conditions defined in the job configuration are met.
     */
    function checkCallback(bytes[] memory values, bytes memory extraData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address selfBalancingPool = abi.decode(extraData, (address));
        (, bytes memory reportDataTokenIn) = abi.decode(values[0], (bytes32[3], bytes));
        (, bytes memory reportDataTokenOut) = abi.decode(values[1], (bytes32[3], bytes));
        PremiumReport memory reportTokenIn = abi.decode(reportDataTokenIn, (PremiumReport));
        PremiumReport memory reportTokenOut = abi.decode(reportDataTokenOut, (PremiumReport));
        if (reportTokenIn.price <= int192(0) || reportTokenOut.price <= int192(0)) {
            revert Arbiter__InvalidPrice();
        }
        ArbiterCall memory arbiterCall;
        (upkeepNeeded, arbiterCall) = _isRebalancingNeeded(
            selfBalancingPool,
            uint192(reportTokenIn.price),
            uint192(reportTokenOut.price),
            s_jobConfig[selfBalancingPool]
        );
        performData = abi.encode(values, arbiterCall);
    }

    /**
     * @inheritdoc StreamsLookupCompatibleInterface
     * @dev This function is triggered by Chainlink Data Streams if the reports retrieval process fail, fallback to Chainlink Data Feeds to checks if rebalancing is needed.
     * @param extraData Encoded extra data, containing the address of the self-balancing pool.
     * @return upkeepNeeded A boolean indicating whether a rebalancing operation is needed.
     * @return performData Data to be used for the rebalancing operation if upkeep is needed.
     */
    function checkErrorHandler(uint256, bytes memory extraData)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address selfBalancingPool = abi.decode(extraData, (address));
        ArbiterJobConfig memory jobConfig = s_jobConfig[selfBalancingPool];
        uint256 maxPriceStaleness = s_priceMaxStaleness;
        uint256 priceTokenIn = _getPriceFromDataFeed(jobConfig.tokenIn, maxPriceStaleness);
        uint256 priceTokenOut = _getPriceFromDataFeed(jobConfig.tokenOut, maxPriceStaleness);
        ArbiterCall memory arbiterCall;
        (upkeepNeeded, arbiterCall) = _isRebalancingNeeded(selfBalancingPool, priceTokenIn, priceTokenOut, jobConfig);
        performData = abi.encode(new bytes[](0), arbiterCall);
    }

    /// @inheritdoc IArbiter
    function getVerifierProxy() external view returns (address) {
        return address(s_verifierProxy);
    }

    /// @inheritdoc IArbiter
    function getPriceMaxStaleness() external view returns (uint256) {
        return s_priceMaxStaleness;
    }

    /// @inheritdoc IArbiter
    function getMinLinkDataStreams() external view returns (uint256) {
        return s_minLinkDataStreams;
    }

    /// @inheritdoc IArbiter
    function getJobConfig(address selfBalancingPool)
        external
        view
        returns (address, uint96, address, uint96, address, uint8, address, uint8)
    {
        ArbiterJobConfig memory jobConfig = s_jobConfig[selfBalancingPool];
        return (
            jobConfig.rewardVault,
            jobConfig.reserveToMinProfit,
            jobConfig.automationForwarder,
            jobConfig.reserveToTriggerProfit,
            jobConfig.tokenIn,
            jobConfig.tokenInDecimals,
            jobConfig.tokenOut,
            jobConfig.tokenOutDecimals
        );
    }

    /// @inheritdoc IArbiter
    function getDataFeed(address token) external view returns (address) {
        return address(s_dataFeeds[token]);
    }

    /// @inheritdoc IArbiter
    function getDataStream(address token) external view returns (string memory) {
        return s_dataStreams[token];
    }

    /// @inheritdoc IArbiter
    function getDexAdapter(uint256 adapterIndex) external view returns (address) {
        return address(s_adapters[adapterIndex]);
    }

    /// @inheritdoc IArbiter
    function allAdaptersLength() external view returns (uint256) {
        return s_adapters.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IArbiter
 * @author Oddcod3 (@oddcod3)
 */
interface IArbiter {
    /**
     * @dev Sets the verifier proxy address for Chainlink Data Streams.
     * @param verifierProxy The address of the new verifier proxy.
     */
    function setVerifierProxy(address verifierProxy) external;

    /**
     * @dev Updates the maximum allowed staleness for price data from Chainlink Data Feeds.
     * @param priceMaxStaleness The new maximum duration (in seconds) that price data is considered valid.
     * @notice This function sets the threshold for how old the price data from Chainlink Data Feeds can be before it's considered stale.
     */
    function setPriceMaxStaleness(uint32 priceMaxStaleness) external;

    /**
     * @dev Updates the minimum Arbiter LINK balance to request data streams reports.
     * @param minLinkDataStreams The new minimum LINK balance.
     */
    function setMinLinkDataStreams(uint64 minLinkDataStreams) external;
    /**
     * @dev Registers Chainlink data feeds for specific tokens.
     * @param tokens An array of token addresses for which data feeds are to be registered.
     * @param dataFeeds An array of Chainlink data feed addresses, each corresponding to a token address in the 'tokens' array.
     * @notice This function is used to link each token with its respective Chainlink data feed.
     * @notice The 'tokens' and 'dataFeeds' arrays must have the same length, ensuring each data feed is mapped to its associated token address
     */
    function setDataFeeds(address[] calldata tokens, address[] calldata dataFeeds) external;

    /**
     * @dev Registers Chainlink data streams for specific tokens.
     * @param tokens An array of token addresses for which data streams are to be registered.
     * @param feedIDs An array of Chainlink data stream IDs, each corresponding to a token address in the 'tokens' array.
     * @notice This function establishes a link between each token and its corresponding Chainlink data stream.
     * @notice The 'tokens' and 'feedIDs' arrays must have the same length, ensuring each data stream ID is mapped to its associated token address.
     */
    function setDataStreams(address[] calldata tokens, string[] calldata feedIDs) external;

    /**
     * @dev Registers an Arbiter job to monitor a specific self-balancing pool for rebalancing needs.
     * @param selfBalancingPool The address of the self-balancing pool to be monitored.
     * @param rewardVault The address of the reward vault where rebalancing profits will be deposited.
     * @param automationForwarder The address of the forwarder for the upkeep associated with this rebalancing job.
     * @param reserveToMinProfit The minimum ratio between reserve and profit below which the rebalancing operation reverts.
     * @param reserveToTriggerProfit The minimum ratio between reserve and profit required to trigger a rebalancing operation.
     * @param forceToken0Decimals The decimal count to be used for token0, especially for non-standard ERC20 tokens that do not comply with the IERC20Metadata interface.
     * @param forceToken1Decimals The decimal count to be used for token1, especially for non-standard ERC20 tokens that do not comply with the IERC20Metadata interface.
     * @notice Set 'forceToken0Decimals' and 'forceToken1Decimals' to zero to default to the ERC20 decimal values provided by the decimals() function of each token.
     */
    function setArbiterJob(
        address selfBalancingPool,
        address rewardVault,
        address automationForwarder,
        uint96 reserveToMinProfit,
        uint96 reserveToTriggerProfit,
        uint8 forceToken0Decimals,
        uint8 forceToken1Decimals
    ) external;

    /**
     * @dev Removes a previously registered Arbiter job associated with a specific self-balancing pool.
     * @param selfBalancingPool The address of the self-balancing pool whose corresponding Arbiter job is to be deleted.
     * @notice This function is used to deregister an Arbiter job that is no longer needed.
     */
    function deleteArbiterJob(address selfBalancingPool) external;

    /**
     * @dev Adds a new adapter to the Arbiter's list of adapters.
     * @param adapter The address of the new adapter to be added.
     */
    function pushDexAdapter(address adapter) external;

    /**
     * @dev Removes an adapter from the Arbiter's list of adapters using its index.
     * @param adapterIndex The index (position) of the adapter in the Arbiter's adapter list that is to be removed.
     * @notice It's important to ensure that the index provided is correct, otherwise the wrong adapter will be removed.
     */
    function removeDexAdapter(uint256 adapterIndex) external;

    /**
     * @dev Allows for the recovery of ERC20 tokens from the contract.
     * @param to The address to which the recovered tokens will be sent.
     * @param tokens An array of ERC20 token addresses that are to be recovered.
     * @param amounts An array of amounts for each token to be recovered. The array index corresponds to the token address in the 'tokens' array.
     * @notice This function is typically used in cases where tokens are accidentally sent to the contract or for withdrawing excess tokens.
     */
    function recoverERC20(address to, address[] memory tokens, uint256[] memory amounts) external;

    /**
     * @dev Implements the callback function that is triggered by swap operations in FlashLiquidity pools.
     * @param sender The address that initiated the swap, thereby triggering this callback function.
     * @param amount0 The amount of token0 obtained as a result of the swap.
     * @param amount1 The amount of token1 obtained as a result of the swap.
     * @param data Encoded data in the form of a CallbackData struct, containing instructions for the rebalancing operation to be executed on another DEX.
     */
    function flashLiquidityCall(address sender, uint256 amount0, uint256 amount1, bytes memory data) external;

    /// @return verifierProxy The address of Chainlink Data Streams verifier proxy.
    function getVerifierProxy() external view returns (address verifierProxy);

    /// @return priceMaxStaleness The maximum duration (in seconds) that Chainlink Data Feed price data is considered valid.
    function getPriceMaxStaleness() external view returns (uint256 priceMaxStaleness);

    function getMinLinkDataStreams() external view returns (uint256 minLinkDataStreams);

    /**
     * @dev Retrieves information about a specific Arbiter job associated with a self-balancing pool.
     * @param selfBalancingPool The address of the self-balancing pool associated with the Arbiter job to be retrieved.
     * @return rewardVault The address of the reward vault where rebalancing profits are deposited.
     * @return reserveToMinProfit The minimum ratio between reserve and profit below which the rebalancing operation reverts.
     * @return automationForwarder The address of the forwarder for the upkeep associated with this rebalancing job.
     * @return reserveToTriggerProfit // The minimum ratio between reserve and profit required to trigger a rebalancing operation.
     * @return token0 The address of token0 in the self-balancing pool.
     * @return token0Decimals The number of decimals for token0.
     * @return token1 The address of token1 in the self-balancing pool.
     * @return token1Decimals The number of decimals for token1.
     * @notice This function provides detailed information about the configuration of a specific Arbiter job.
     */
    function getJobConfig(address selfBalancingPool)
        external
        view
        returns (
            address rewardVault,
            uint96 reserveToMinProfit,
            address automationForwarder,
            uint96 reserveToTriggerProfit,
            address token0,
            uint8 token0Decimals,
            address token1,
            uint8 token1Decimals
        );

    /// @param token The address of the token for which the Chainlink Data Feed address is to be retrieved.
    /// @return dataFeed The address of the Chainlink Data Feed associated with the specified 'token'.
    function getDataFeed(address token) external view returns (address dataFeed);

    /// @param token The address of the token for which the Chainlink Data Stream ID is to be retrieved.
    /// @return feedID The ID of the Chainlink Data Stream associated with the specified 'token'.
    function getDataStream(address token) external view returns (string memory feedID);

    /// @param adapterIndex The index (position) of the adapter in the Arbiter's adapters list.
    /// @return adapter The address of the adapter located at the specified 'adapterIndex' in the list.
    function getDexAdapter(uint256 adapterIndex) external view returns (address adapter);

    /// @return adaptersLength The number of adapters currently registered
    function allAdaptersLength() external view returns (uint256 adaptersLength);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IDexAdapter
 * @author Oddcod3 (@oddcod3)
 */
interface IDexAdapter {
    /**
     * @dev Executes a token swap in the specified pool using this adapter.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param to The recipient of the swap.
     * @param amountIn The amount of input tokens to be swapped.
     * @param amountOutMin The minimum amount out of output tokens below which the swap reverts.
     * @param extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @return amountOut The amount of output token received.
     */
    function swap(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory extraArgs
    ) external returns (uint256 amountOut);

    /**
     * @dev Identifies the optimal target pool that maximizes the amount of output tokens received.
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to be swapped.
     * @return maxOutput The maximum amount of output tokens that can be received.
     * @return extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @notice This function scans available pools to find the one that provides the highest return for the given input token and amount.
     */
    function getMaxOutput(address tokenIn, address tokenOut, uint256 amountIn)
        external
        view
        returns (uint256 maxOutput, bytes memory extraArgs);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @param amountIn The amount of input tokens to be swapped.
     * @param extraArgs Adapter specific encoded extra arguments, used for providing additional instructions or data required by the specific DEX adapter.
     * @return amountOut The amount of output tokens received.
     */
    function getOutputFromArgs(address tokenIn, address tokenOut, uint256 amountIn, bytes memory extraArgs)
        external
        view
        returns (uint256 amountOut);

    /**
     * @param tokenIn The address of the input token.
     * @param tokenOut The address of the output token.
     * @return adapterArgs Array of adapter extraArgs given the tokenIn and tokenOut.
     *
     */
    function getAdapterArgs(address tokenIn, address tokenOut) external view returns (bytes[] memory adapterArgs);

    /**
     * @return description A string containing the description and version of the adapter.
     * @notice This function returns a textual description and version number of the adapter,
     */
    function s_description() external view returns (string memory description);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IFlashLiquidityPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function manager() external view returns (address);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function setManager(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IGovernable} from "./interfaces/IGovernable.sol";

/**
 * @title Governable
 * @notice A 2-step governable contract with a delay between setting the pending governor and transferring governance.
 */
contract Governable is IGovernable {
    error Governable__ZeroAddress();
    error Governable__NotAuthorized();
    error Governable__TooEarly(uint64 timestampReady);

    address private s_governor;
    address private s_pendingGovernor;
    uint64 private s_govTransferReqTimestamp;
    uint32 public constant TRANSFER_GOVERNANCE_DELAY = 3 days;

    event GovernanceTrasferred(address indexed oldGovernor, address indexed newGovernor);
    event PendingGovernorChanged(address indexed pendingGovernor);

    modifier onlyGovernor() {
        _revertIfNotGovernor();
        _;
    }

    constructor(address governor) {
        s_governor = governor;
        emit GovernanceTrasferred(address(0), governor);
    }

    /// @inheritdoc IGovernable
    function setPendingGovernor(address pendingGovernor) external onlyGovernor {
        if (pendingGovernor == address(0)) revert Governable__ZeroAddress();
        s_pendingGovernor = pendingGovernor;
        s_govTransferReqTimestamp = uint64(block.timestamp);
        emit PendingGovernorChanged(pendingGovernor);
    }

    /// @inheritdoc IGovernable
    function transferGovernance() external {
        address newGovernor = s_pendingGovernor;
        address oldGovernor = s_governor;
        uint64 govTransferReqTimestamp = s_govTransferReqTimestamp;
        if (msg.sender != oldGovernor && msg.sender != newGovernor) revert Governable__NotAuthorized();
        if (newGovernor == address(0)) revert Governable__ZeroAddress();
        if (block.timestamp - govTransferReqTimestamp < TRANSFER_GOVERNANCE_DELAY) {
            revert Governable__TooEarly(govTransferReqTimestamp + TRANSFER_GOVERNANCE_DELAY);
        }
        s_pendingGovernor = address(0);
        s_governor = newGovernor;
        emit GovernanceTrasferred(oldGovernor, newGovernor);
    }

    function _revertIfNotGovernor() internal view {
        if (msg.sender != s_governor) revert Governable__NotAuthorized();
    }

    function _getGovernor() internal view returns (address) {
        return s_governor;
    }

    function _getPendingGovernor() internal view returns (address) {
        return s_pendingGovernor;
    }

    function _getGovTransferReqTimestamp() internal view returns (uint64) {
        return s_govTransferReqTimestamp;
    }

    function getGovernor() external view returns (address) {
        return _getGovernor();
    }

    function getPendingGovernor() external view returns (address) {
        return _getPendingGovernor();
    }

    function getGovTransferReqTimestamp() external view returns (uint64) {
        return _getGovTransferReqTimestamp();
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernable {
    /**
     * @param pendingGovernor The new pending governor address.
     * @notice A call to transfer governance is required to promote the new pending governor to the governor role.
     */
    function setPendingGovernor(address pendingGovernor) external;

    /// @notice Promote the pending governor to the governor role.
    function transferGovernance() external;

    function getGovernor() external view returns (address);

    function getPendingGovernor() external view returns (address);

    function getGovTransferReqTimestamp() external view returns (uint64);
}