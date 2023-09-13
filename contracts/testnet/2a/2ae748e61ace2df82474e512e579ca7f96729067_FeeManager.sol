// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {TypeAndVersionInterface} from "../../interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../libraries/Common.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IWERC20} from "../../shared/interfaces/IWERC20.sol";
import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC20.sol";
import {Math} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/utils/math/Math.sol";
import {SafeERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

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
  address private immutable i_linkAddress;

  /// @notice the native token address
  address private immutable i_nativeAddress;

  /// @notice the proxy address
  address private immutable i_proxyAddress;

  /// @notice the reward manager address
  IRewardManager private immutable i_rewardManager;

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
  /// @param assetAddress Address of the asset withdrawn
  /// @param quantity Amount of the asset withdrawn
  event Withdraw(address adminAddress, address assetAddress, uint192 quantity);

  /// @notice Emits when a deficit has been cleared for a particular config digest
  /// @param configDigest Config digest of the deficit cleared
  /// @param linkQuantity Amount of LINK required to pay the deficit
  event LinkDeficitCleared(bytes32 indexed configDigest, uint256 linkQuantity);

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

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "FeeManager 0.0.1";
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == this.processFee.selector || interfaceId == this.processFeeBulk.selector;
  }

  /// @inheritdoc IFeeManager
  function processFee(bytes calldata payload, address subscriber) external payable override onlyOwnerOrProxy {
    (Common.Asset memory fee, Common.Asset memory reward) = _processFee(payload, subscriber);

    if (fee.amount == 0) {
      _tryReturnChange(subscriber, msg.value);
      return;
    }

    IFeeManager.FeeAndReward[] memory feeAndReward = new IFeeManager.FeeAndReward[](1);
    feeAndReward[0] = IFeeManager.FeeAndReward(bytes32(payload), fee, reward);

    if (fee.assetAddress == i_linkAddress) {
      _handleFeesAndRewards(subscriber, feeAndReward, 1, 0);
    } else {
      _handleFeesAndRewards(subscriber, feeAndReward, 0, 1);
    }
  }

  /// @inheritdoc IFeeManager
  function processFeeBulk(bytes[] calldata payloads, address subscriber) external payable override onlyOwnerOrProxy {
    FeeAndReward[] memory feesAndRewards = new IFeeManager.FeeAndReward[](payloads.length);

    //keep track of the number of fees to prevent over initialising the FeePayment array within _convertToLinkAndNativeFees
    uint256 numberOfLinkFees;
    uint256 numberOfNativeFees;

    uint256 feesAndRewardsIndex;
    for (uint256 i; i < payloads.length; ++i) {
      (Common.Asset memory fee, Common.Asset memory reward) = _processFee(payloads[i], subscriber);

      if (fee.amount != 0) {
        feesAndRewards[feesAndRewardsIndex++] = IFeeManager.FeeAndReward(bytes32(payloads[i]), fee, reward);

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
    Quote memory quote
  ) public view returns (Common.Asset memory, Common.Asset memory) {
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
      return (fee, reward);
    }

    //verify the quote payload is a supported token
    if (quote.quoteAddress != i_nativeAddress && quote.quoteAddress != i_linkAddress) {
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
    uint256 discount = s_subscriberDiscounts[subscriber][feedId][quote.quoteAddress];

    //the reward is always set in LINK
    reward.assetAddress = i_linkAddress;
    reward.amount = Math.ceilDiv(linkQuantity * (PERCENTAGE_SCALAR - discount), PERCENTAGE_SCALAR);

    //calculate either the LINK fee or native fee if it's within the report
    if (quote.quoteAddress == i_linkAddress) {
      fee.assetAddress = i_linkAddress;
      fee.amount = reward.amount;
    } else {
      uint256 surchargedFee = Math.ceilDiv(nativeQuantity * (PERCENTAGE_SCALAR + s_nativeSurcharge), PERCENTAGE_SCALAR);

      fee.assetAddress = i_nativeAddress;
      fee.amount = Math.ceilDiv(surchargedFee * (PERCENTAGE_SCALAR - discount), PERCENTAGE_SCALAR);
    }

    //return the fee
    return (fee, reward);
  }

  /// @inheritdoc IFeeManager
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
  function withdraw(address assetAddress, uint192 quantity) external onlyOwner {
    //address 0 is used to withdraw native in the context of withdrawing
    if (assetAddress == address(0)) {
      payable(owner()).transfer(quantity);
      return;
    }

    //withdraw the requested asset
    IERC20(assetAddress).safeTransfer(owner(), quantity);

    //emit event when funds are withdrawn
    emit Withdraw(msg.sender, assetAddress, quantity);
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
    address subscriber
  ) internal view returns (Common.Asset memory, Common.Asset memory) {
    if (subscriber == address(this)) revert InvalidAddress();

    //decode the report from the payload
    (, bytes memory report) = abi.decode(payload, (bytes32[3], bytes));

    //get the feedId from the report
    bytes32 feedId = bytes32(report);

    //v1 doesn't need a quote payload, so skip the decoding
    Quote memory quote;
    if (_getReportVersion(feedId) != REPORT_V1) {
      //all reports greater than v1 should have a quote payload
      (, , , , , bytes memory quoteBytes) = abi.decode(
        payload,
        // reportContext, report, rs, ss, raw, quote
        (bytes32[3], bytes, bytes32[], bytes32[], bytes32, bytes)
      );

      //decode the quote from the bytes
      (quote) = abi.decode(quoteBytes, (Quote));
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
    }

    //keep track of change in case of any over payment
    uint256 change;

    if (msg.value != 0) {
      //there must be enough to cover the fee
      if (totalNativeFee > msg.value) revert InvalidDeposit();

      //wrap the amount required to pay the fee & approve as the subscriber paid in unwrapped native
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
          s_linkDeficit[nativeFeeLinkRewards[i].poolId] += nativeFeeLinkRewards[i].amount;
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
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
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
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.0;

interface IWERC20 {
  function deposit() external payable;

  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
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
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}