// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC20.sol";
import {TypeAndVersionInterface} from "../../interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../libraries/Common.sol";
import {SafeERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FeeManager
 * @author Michael Fletcher
 * @author Austin Born
 * @notice This contract will be used to reward any configured recipients within a pool. Recipients will receive a share of their pool relative to their configured weight.
 */
contract RewardManager is IRewardManager, ConfirmedOwner, TypeAndVersionInterface {
  using SafeERC20 for IERC20;

  // @dev The mapping of total fees collected for a particular pot: s_totalRewardRecipientFees[poolId]
  mapping(bytes32 => uint256) public s_totalRewardRecipientFees;

  // @dev The mapping of fee balances for each pot last time the recipient claimed: s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient]
  mapping(bytes32 => mapping(address => uint256)) public s_totalRewardRecipientFeesLastClaimedAmounts;

  // @dev The mapping of RewardRecipient weights for a particular poolId: s_rewardRecipientWeights[poolId][rewardRecipient].
  mapping(bytes32 => mapping(address => uint256)) public s_rewardRecipientWeights;

  // @dev Keep track of the reward recipient weights that have been set to prevent duplicates
  mapping(bytes32 => bool) public s_rewardRecipientWeightsSet;

  // @dev Store a list of pool ids that have been registered, to make off chain lookups easier
  bytes32[] public s_registeredPoolIds;

  // @dev The address for the LINK contract
  address private immutable i_linkAddress;

  // The total weight of all RewardRecipients. 1e18 = 100% of the pool fees
  uint64 private constant PERCENTAGE_SCALAR = 1e18;

  // The fee manager address
  address public s_feeManagerAddress;

  // @notice Thrown whenever the RewardRecipient weights are invalid
  error InvalidWeights();

  // @notice Thrown when any given address is invalid
  error InvalidAddress();

  // @notice Thrown when the pool id is invalid
  error InvalidPoolId();

  // @notice Thrown when the calling contract is not within the authorized contracts
  error Unauthorized();

  // Events emitted upon state change
  event RewardRecipientsUpdated(bytes32 indexed poolId, Common.AddressAndWeight[] newRewardRecipients);
  event RewardsClaimed(bytes32 indexed poolId, address indexed recipient, uint192 quantity);
  event FeeManagerUpdated(address newFeeManagerAddress);
  event FeePaid(FeePayment[] payments, address payee);

  /**
   * @notice Constructor
   * @param linkAddress address of the wrapped LINK token
   */
  constructor(address linkAddress) ConfirmedOwner(msg.sender) {
    //ensure that the address ia not zero
    if (linkAddress == address(0)) revert InvalidAddress();

    i_linkAddress = linkAddress;
  }

  // @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "RewardManager 0.0.1";
  }

  // @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == this.onFeePaid.selector;
  }

  modifier onlyOwnerOrFeeManager() {
    if (msg.sender != owner() && msg.sender != s_feeManagerAddress) revert Unauthorized();
    _;
  }

  modifier onlyOwnerOrRecipientInPool(bytes32 poolId) {
    if (msg.sender != owner() && s_rewardRecipientWeights[poolId][msg.sender] == 0) revert Unauthorized();
    _;
  }

  /// @inheritdoc IRewardManager
  function onFeePaid(FeePayment[] calldata payments, address payee) external override onlyOwnerOrFeeManager {
    uint256 totalFeeAmount;
    for (uint256 i; i < payments.length; ++i) {
      unchecked {
        //the total amount for any ERC20 asset cannot exceed 2^256 - 1
        s_totalRewardRecipientFees[payments[i].poolId] += payments[i].amount;

        //tally the total payable fees
        totalFeeAmount += payments[i].amount;
      }
    }

    //transfer the fees to this contract
    IERC20(i_linkAddress).safeTransferFrom(payee, address(this), totalFeeAmount);

    emit FeePaid(payments, payee);
  }

  /// @inheritdoc IRewardManager
  function claimRewards(bytes32[] memory poolIds) external override {
    _claimRewards(msg.sender, poolIds);
  }

  // wrapper impl for claimRewards
  function _claimRewards(address recipient, bytes32[] memory poolIds) internal returns (uint256) {
    //get the total amount claimable for this recipient
    uint256 claimAmount;

    //loop and claim all the rewards in the poolId pot
    for (uint256 i; i < poolIds.length; ++i) {
      //get the poolId to be claimed
      bytes32 poolId = poolIds[i];

      //get the total fees for the pot
      uint256 totalFeesInPot = s_totalRewardRecipientFees[poolId];

      unchecked {
        //avoid unnecessary storage reads if there's no fees in the pot
        if (totalFeesInPot == 0) continue;

        //get the claimable amount for this recipient, this calculation will never exceed the amount in the pot
        uint256 claimableAmount = totalFeesInPot - s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient];

        //calculate the recipients share of the fees, which is their weighted share of the difference between the last amount they claimed and the current amount in the pot. This can never be more than the total amount in existence
        uint256 recipientShare = (claimableAmount * s_rewardRecipientWeights[poolId][recipient]) / PERCENTAGE_SCALAR;

        //if there's no fees to claim, continue as there's nothing to update
        if (recipientShare == 0) continue;

        //keep track of the total amount claimable, this can never be more than the total amount in existence
        claimAmount += recipientShare;

        //set the current total amount of fees in the pot as it's used to calculate future claims
        s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient] = totalFeesInPot;

        //emit event if the recipient has rewards to claim
        emit RewardsClaimed(poolIds[i], recipient, uint192(recipientShare));
      }
    }

    //check if there's any rewards to claim in the given poolId
    if (claimAmount != 0) {
      //transfer the reward to the recipient
      IERC20(i_linkAddress).safeTransfer(recipient, claimAmount);
    }

    return claimAmount;
  }

  /// @inheritdoc IRewardManager
  function setRewardRecipients(
    bytes32 poolId,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external override onlyOwnerOrFeeManager {
    //revert if there are no recipients to set
    if (rewardRecipientAndWeights.length == 0) revert InvalidAddress();

    //check that the weights have not been previously set
    if (s_rewardRecipientWeightsSet[poolId]) revert InvalidPoolId();

    //keep track of the registered poolIds to make off chain lookups easier
    s_registeredPoolIds.push(poolId);

    //keep track of which pools have had their reward recipients set
    s_rewardRecipientWeightsSet[poolId] = true;

    //set the reward recipients, this will only be called once and contain the full set of RewardRecipients with a total weight of 100%
    _setRewardRecipientWeights(poolId, rewardRecipientAndWeights, PERCENTAGE_SCALAR);

    emit RewardRecipientsUpdated(poolId, rewardRecipientAndWeights);
  }

  function _setRewardRecipientWeights(
    bytes32 poolId,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights,
    uint256 expectedWeight
  ) internal {
    //we can't update the weights if it contains duplicates
    if (Common.hasDuplicateAddresses(rewardRecipientAndWeights)) revert InvalidAddress();

    //loop all the reward recipients and validate the weight and address
    uint256 totalWeight;
    for (uint256 i; i < rewardRecipientAndWeights.length; ++i) {
      //get the weight
      uint256 recipientWeight = rewardRecipientAndWeights[i].weight;
      //get the address
      address recipientAddress = rewardRecipientAndWeights[i].addr;

      //ensure the reward recipient address is not zero
      if (recipientAddress == address(0)) revert InvalidAddress();
      //ensure the weight is not zero
      if (recipientWeight == 0) revert InvalidWeights();

      //save/overwrite the weight for the reward recipient
      s_rewardRecipientWeights[poolId][recipientAddress] = recipientWeight;

      unchecked {
        //keep track of the cumulative weight, this cannot overflow as the total weight is restricted at 1e18
        totalWeight += recipientWeight;
      }
    }

    //if total weight is not met, the fees will either be under or over distributed
    if (totalWeight != expectedWeight) revert InvalidWeights();
  }

  /// @inheritdoc IRewardManager
  function updateRewardRecipients(
    bytes32 poolId,
    Common.AddressAndWeight[] calldata newRewardRecipients
  ) external override onlyOwner {
    //create an array of poolIds to pass to _claimRewards if required
    bytes32[] memory poolIds = new bytes32[](1);
    poolIds[0] = poolId;

    //loop all the reward recipients and claim their rewards before updating their weights
    uint256 existingTotalWeight;
    for (uint256 i; i < newRewardRecipients.length; ++i) {
      //get the address
      address recipientAddress = newRewardRecipients[i].addr;
      //get the existing weight
      uint256 existingWeight = s_rewardRecipientWeights[poolId][recipientAddress];

      //if the existing weight is 0, the recipient isn't part of this configuration
      if (existingWeight == 0) revert InvalidAddress();

      //if a recipient is updated, the rewards must be claimed first as they can't claim previous fees at the new weight
      _claimRewards(newRewardRecipients[i].addr, poolIds);

      unchecked {
        //keep tally of the weights so that the expected collective weight is known
        existingTotalWeight += existingWeight;
      }
    }

    //update the reward recipients, if the new collective weight isn't equal to the previous collective weight, the fees will either be under or over distributed
    _setRewardRecipientWeights(poolId, newRewardRecipients, existingTotalWeight);

    //emit event
    emit RewardRecipientsUpdated(poolId, newRewardRecipients);
  }

  /// @inheritdoc IRewardManager
  function payRecipients(bytes32 poolId, address[] calldata recipients) external onlyOwnerOrRecipientInPool(poolId) {
    //convert poolIds to an array to match the interface of _claimRewards
    bytes32[] memory poolIdsArray = new bytes32[](1);
    poolIdsArray[0] = poolId;

    //loop each recipient and claim the rewards for each of the pools and assets
    for (uint256 i; i < recipients.length; ++i) {
      _claimRewards(recipients[i], poolIdsArray);
    }
  }

  /// @inheritdoc IRewardManager
  function setFeeManager(address newFeeManagerAddress) external onlyOwner {
    if (newFeeManagerAddress == address(0)) revert InvalidAddress();

    s_feeManagerAddress = newFeeManagerAddress;

    emit FeeManagerUpdated(newFeeManagerAddress);
  }

  /// @inheritdoc IRewardManager
  function getAvailableRewardPoolIds(address recipient) external view returns (bytes32[] memory) {
    //get the length of the pool ids which we will loop through and potentially return
    uint256 registeredPoolIdsLength = s_registeredPoolIds.length;

    //create a new array with the maximum amount of potential pool ids
    bytes32[] memory claimablePoolIds = new bytes32[](registeredPoolIdsLength);
    //we want the pools which a recipient has funds for to be sequential, so we need to keep track of the index
    uint256 poolIdArrayIndex;

    //loop all the pool ids, and check if the recipient has a registered weight and a claimable amount
    for (uint256 i; i < registeredPoolIdsLength; ++i) {
      //get the poolId
      bytes32 poolId = s_registeredPoolIds[i];
      //if the recipient has a weight, they are a recipient of this poolId
      if (s_rewardRecipientWeights[poolId][recipient] != 0) {
        //get the total in this pool
        uint256 totalPoolAmount = s_totalRewardRecipientFees[poolId];
        //if the recipient has any LINK, then add the poolId to the array
        unchecked {
          //s_totalRewardRecipientFeesLastClaimedAmounts can never exceed total pool amount, and the number of pools can't exceed the max array length
          if (totalPoolAmount - s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient] != 0) {
            claimablePoolIds[poolIdArrayIndex++] = poolId;
          }
        }
      }
    }

    return claimablePoolIds;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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